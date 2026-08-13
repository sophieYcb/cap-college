/*
 CAP-COLLEGE DATABASE
 File: database/263_learner_targeted_exercises.sql
 Purpose: Allow supervised learner profiles to complete targeted exercise
          sessions without changing their completed diagnostic snapshot.
 Idempotent: Yes
*/

begin;

alter table public.remediation_sessions
  alter column student_id drop not null,
  add column if not exists learner_profile_id uuid
    references public.learner_profiles(id) on delete cascade,
  add column if not exists question_target smallint;

do $block$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'remediation_sessions_single_owner'
      and conrelid = 'public.remediation_sessions'::regclass
  ) then
    alter table public.remediation_sessions
      add constraint remediation_sessions_single_owner check (
        (student_id is not null and learner_profile_id is null)
        or (student_id is null and learner_profile_id is not null)
      );
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'remediation_sessions_question_target'
      and conrelid = 'public.remediation_sessions'::regclass
  ) then
    alter table public.remediation_sessions
      add constraint remediation_sessions_question_target check (
        question_target is null or question_target between 1 and 50
      );
  end if;
end;
$block$;

create index if not exists remediation_sessions_learner_idx
  on public.remediation_sessions (learner_profile_id, started_at desc);

create or replace function public.get_learner_remediation_question_bank(
  requested_token text,
  requested_competence_id text
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if public.learner_profile_for_token(requested_token) is null then
    raise exception 'Learner session required';
  end if;
  return public.get_remediation_question_bank(requested_competence_id);
end;
$function$;

create or replace function public.start_learner_remediation_session(
  requested_token text,
  requested_competence_id text,
  requested_question_count smallint
)
returns table (
  session_id uuid,
  competence text,
  reminder text,
  worked_example text,
  question_target smallint
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_micro_skill public.micro_skills%rowtype;
  selected_resource public.learning_resources%rowtype;
  new_session_id uuid;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;
  if requested_question_count not in (5, 10) then
    raise exception 'Exercise session must contain 5 or 10 questions';
  end if;

  select micro_skill.* into selected_micro_skill
  from public.learner_profiles learner
  join public.micro_skill_levels level_link
    on level_link.level_id = learner.level_id
   and level_link.is_expected
  join public.micro_skills micro_skill
    on micro_skill.id = level_link.micro_skill_id
  where replace(micro_skill.code, 'legacy_', '') = requested_competence_id
    and learner.id = selected_learner_id
    and micro_skill.active
  limit 1;

  if selected_micro_skill.id is null then
    raise exception 'Unknown competency';
  end if;

  select resource.* into selected_resource
  from public.learning_resources resource
  where resource.micro_skill_id = selected_micro_skill.id
    and resource.active
  order by resource.version_number desc
  limit 1;

  insert into public.remediation_sessions (
    student_id, learner_profile_id, micro_skill_id, resource_id,
    planned_minutes, question_target
  ) values (
    null, selected_learner_id, selected_micro_skill.id,
    selected_resource.id,
    case requested_question_count when 5 then 3 else 5 end,
    requested_question_count
  ) returning id into new_session_id;

  return query select
    new_session_id,
    selected_micro_skill.student_name,
    coalesce(
      selected_resource.reminder,
      selected_micro_skill.lesson_reminder
    ),
    coalesce(
      selected_resource.worked_example,
      selected_micro_skill.worked_example
    ),
    requested_question_count;
end;
$function$;

create or replace function public.submit_learner_remediation_answer(
  requested_token text,
  requested_session_id uuid,
  requested_question_version_id uuid,
  requested_choice_id uuid,
  requested_assistance public.assistance_mode,
  requested_sequence_number integer
)
returns table (
  is_correct boolean,
  correct_choice_id uuid,
  correction_explanation text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_question_id uuid;
  expected_choice_id uuid;
  answer_is_correct boolean;
  explanation text;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;
  if requested_sequence_number < 1 then
    raise exception 'Invalid sequence number';
  end if;

  select question.id, version.correction_explanation
  into selected_question_id, explanation
  from public.remediation_sessions session
  join public.question_versions version
    on version.id = requested_question_version_id
  join public.questions question
    on question.id = version.question_id
   and question.micro_skill_id = session.micro_skill_id
  where session.id = requested_session_id
    and session.learner_profile_id = selected_learner_id
    and session.status = 'active'
    and requested_sequence_number <= session.question_target
    and question.current_version_number = version.version_number
    and question.status = 'published'
    and question.active;

  if selected_question_id is null then
    raise exception 'Question or exercise session is not available';
  end if;

  if not exists (
    select 1 from public.answer_choices choice
    where choice.id = requested_choice_id
      and choice.question_version_id = requested_question_version_id
  ) then
    raise exception 'Choice does not belong to this question';
  end if;

  select choice.id into expected_choice_id
  from public.answer_choices choice
  where choice.question_version_id = requested_question_version_id
    and choice.is_correct;

  answer_is_correct := requested_choice_id = expected_choice_id;

  insert into public.remediation_attempts (
    remediation_session_id, question_id, question_version_id,
    selected_choice_id, assistance, is_correct,
    sequence_number, answered_at
  ) values (
    requested_session_id, selected_question_id,
    requested_question_version_id, requested_choice_id,
    requested_assistance, answer_is_correct,
    requested_sequence_number, statement_timestamp()
  )
  on conflict (remediation_session_id, sequence_number) do update
  set question_id = excluded.question_id,
      question_version_id = excluded.question_version_id,
      selected_choice_id = excluded.selected_choice_id,
      assistance = excluded.assistance,
      is_correct = excluded.is_correct,
      answered_at = excluded.answered_at;

  return query select answer_is_correct, expected_choice_id, explanation;
end;
$function$;

create or replace function public.finish_learner_remediation_session(
  requested_token text,
  requested_session_id uuid
)
returns table (answer_count integer, correct_count integer)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  update public.remediation_sessions
  set status = 'completed',
      completed_at = coalesce(completed_at, statement_timestamp())
  where id = requested_session_id
    and learner_profile_id = selected_learner_id
    and status in ('active', 'completed');

  if not found then
    raise exception 'Exercise session is not available';
  end if;

  return query
  select count(*)::integer,
    count(*) filter (where attempt.is_correct)::integer
  from public.remediation_attempts attempt
  where attempt.remediation_session_id = requested_session_id
    and attempt.answered_at is not null;
end;
$function$;

create or replace function public.get_my_learner_remediation_history(
  requested_learner_profile_id uuid
)
returns table (
  session_id uuid,
  subject_name text,
  domain_name text,
  competence_id text,
  competence text,
  question_target integer,
  answer_count integer,
  correct_count integer,
  session_status text,
  started_at timestamptz,
  completed_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    session.id,
    subject.name,
    domain.name,
    replace(micro_skill.code, 'legacy_', ''),
    micro_skill.student_name,
    coalesce(session.question_target, 0)::integer,
    count(attempt.id) filter (
      where attempt.answered_at is not null
    )::integer,
    count(attempt.id) filter (
      where attempt.answered_at is not null and attempt.is_correct
    )::integer,
    session.status::text,
    session.started_at,
    session.completed_at
  from public.remediation_sessions session
  join public.micro_skills micro_skill
    on micro_skill.id = session.micro_skill_id
  join public.skills skill on skill.id = micro_skill.skill_id
  join public.domains domain on domain.id = skill.domain_id
  join public.subjects subject on subject.id = domain.subject_id
  left join public.remediation_attempts attempt
    on attempt.remediation_session_id = session.id
  where session.learner_profile_id = requested_learner_profile_id
    and exists (
      select 1 from public.learner_profile_adults link
      where link.learner_profile_id = session.learner_profile_id
        and link.adult_user_id = auth.uid()
    )
  group by session.id, subject.name, domain.name,
    micro_skill.code, micro_skill.student_name
  order by session.started_at desc;
$function$;

revoke all on function public.get_learner_remediation_question_bank(text, text)
  from public;
revoke all on function public.start_learner_remediation_session(text, text, smallint)
  from public;
revoke all on function public.submit_learner_remediation_answer(
  text, uuid, uuid, uuid, public.assistance_mode, integer
) from public;
revoke all on function public.finish_learner_remediation_session(text, uuid)
  from public;
revoke all on function public.get_my_learner_remediation_history(uuid)
  from public;

grant execute on function public.get_learner_remediation_question_bank(text, text)
  to anon, authenticated;
grant execute on function public.start_learner_remediation_session(text, text, smallint)
  to anon, authenticated;
grant execute on function public.submit_learner_remediation_answer(
  text, uuid, uuid, uuid, public.assistance_mode, integer
) to anon, authenticated;
grant execute on function public.finish_learner_remediation_session(text, uuid)
  to anon, authenticated;
grant execute on function public.get_my_learner_remediation_history(uuid)
  to authenticated;

commit;
