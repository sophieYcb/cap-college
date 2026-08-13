/*
 CAP-COLLEGE DATABASE
 File: database/267_learner_skill_reassessment.sql
 Purpose: Propose a five-question, no-help reassessment after sufficient
          targeted practice, without changing the original diagnostic.
 Idempotent: Yes
*/

begin;

alter table public.remediation_sessions
  add column if not exists session_kind text not null default 'practice',
  add column if not exists reassessment_passed boolean;

do $block$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'remediation_sessions_kind'
      and conrelid = 'public.remediation_sessions'::regclass
  ) then
    alter table public.remediation_sessions
      add constraint remediation_sessions_kind check (
        session_kind in ('practice', 'reassessment')
      );
  end if;
end;
$block$;

create or replace function public.get_learner_reassessment_readiness(
  requested_token text,
  requested_competence_id text
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_micro_skill_id uuid;
  practice_answers integer := 0;
  practice_sessions integer := 0;
  recent_ten_correct integer := 0;
  recent_ten_count integer := 0;
  recent_three_correct integer := 0;
  recent_three_count integer := 0;
  without_reminder_successes integer := 0;
  latest_practice_at timestamptz;
  latest_reassessment_at timestamptz;
  latest_reassessment_passed boolean;
  practice_since_reassessment integer := 0;
  criteria_met boolean;
  eligible boolean;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  select micro_skill.id into selected_micro_skill_id
  from public.learner_profiles learner
  join public.micro_skill_levels level_link
    on level_link.level_id = learner.level_id
   and level_link.is_expected
  join public.micro_skills micro_skill
    on micro_skill.id = level_link.micro_skill_id
   and micro_skill.active
  where learner.id = selected_learner_id
    and replace(micro_skill.code, 'legacy_', '') = requested_competence_id
  limit 1;

  if selected_micro_skill_id is null then
    raise exception 'Unknown competency';
  end if;

  with practice_attempts as (
    select attempt.*
    from public.remediation_sessions session
    join public.remediation_attempts attempt
      on attempt.remediation_session_id = session.id
     and attempt.answered_at is not null
    where session.learner_profile_id = selected_learner_id
      and session.micro_skill_id = selected_micro_skill_id
      and session.session_kind = 'practice'
      and session.status = 'completed'
  ),
  recent_ten as (
    select * from practice_attempts
    order by answered_at desc, id desc limit 10
  ),
  recent_three as (
    select * from practice_attempts
    order by answered_at desc, id desc limit 3
  )
  select
    (select count(*) from practice_attempts),
    (select count(distinct remediation_session_id) from practice_attempts),
    (select count(*) from recent_ten),
    (select count(*) filter (where is_correct) from recent_ten),
    (select count(*) from recent_three),
    (select count(*) filter (where is_correct) from recent_three),
    (select count(*) from practice_attempts
      where is_correct and assistance = 'without_reminder'),
    (select max(answered_at) from practice_attempts)
  into
    practice_answers,
    practice_sessions,
    recent_ten_count,
    recent_ten_correct,
    recent_three_count,
    recent_three_correct,
    without_reminder_successes,
    latest_practice_at;

  select session.completed_at, session.reassessment_passed
  into latest_reassessment_at, latest_reassessment_passed
  from public.remediation_sessions session
  where session.learner_profile_id = selected_learner_id
    and session.micro_skill_id = selected_micro_skill_id
    and session.session_kind = 'reassessment'
    and session.status = 'completed'
  order by session.completed_at desc, session.id desc
  limit 1;

  if latest_reassessment_at is not null then
    select count(*) into practice_since_reassessment
    from public.remediation_sessions session
    join public.remediation_attempts attempt
      on attempt.remediation_session_id = session.id
     and attempt.answered_at > latest_reassessment_at
    where session.learner_profile_id = selected_learner_id
      and session.micro_skill_id = selected_micro_skill_id
      and session.session_kind = 'practice'
      and session.status = 'completed';
  end if;

  criteria_met := practice_answers >= 15
    and practice_sessions >= 3
    and recent_ten_count = 10
    and recent_ten_correct >= 8
    and without_reminder_successes >= 5
    and recent_three_count = 3
    and recent_three_correct = 3;

  eligible := criteria_met
    and (
      latest_reassessment_at is null
      or (
        coalesce(latest_reassessment_passed, false) = false
        and practice_since_reassessment >= 5
      )
      or latest_practice_at > latest_reassessment_at
         and practice_since_reassessment >= 5
    );

  return jsonb_build_object(
    'eligible', eligible,
    'criteriaMet', criteria_met,
    'practiceAnswers', practice_answers,
    'practiceSessions', practice_sessions,
    'recentTenCorrect', recent_ten_correct,
    'withoutReminderSuccesses', without_reminder_successes,
    'recentThreeCorrect', recent_three_correct,
    'latestReassessmentPassed', latest_reassessment_passed,
    'practiceSinceReassessment', practice_since_reassessment,
    'questionsUntilReview', greatest(15 - practice_answers, 0)
  );
end;
$function$;

create or replace function public.start_learner_reassessment_session(
  requested_token text,
  requested_competence_id text
)
returns table (
  session_id uuid,
  competence text,
  reminder text,
  worked_example text,
  question_target smallint,
  initial_assistance text,
  session_kind text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_micro_skill public.micro_skills%rowtype;
  readiness jsonb;
  new_session_id uuid;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  readiness := public.get_learner_reassessment_readiness(
    requested_token, requested_competence_id
  );
  if not coalesce((readiness ->> 'eligible')::boolean, false) then
    raise exception 'This competency is not ready for reassessment';
  end if;

  select micro_skill.* into selected_micro_skill
  from public.learner_profiles learner
  join public.micro_skill_levels level_link
    on level_link.level_id = learner.level_id and level_link.is_expected
  join public.micro_skills micro_skill
    on micro_skill.id = level_link.micro_skill_id and micro_skill.active
  where learner.id = selected_learner_id
    and replace(micro_skill.code, 'legacy_', '') = requested_competence_id
  limit 1;

  insert into public.remediation_sessions (
    student_id, learner_profile_id, micro_skill_id,
    planned_minutes, question_target, session_kind
  ) values (
    null, selected_learner_id, selected_micro_skill.id,
    3, 5, 'reassessment'
  ) returning id into new_session_id;

  return query select
    new_session_id,
    selected_micro_skill.student_name,
    selected_micro_skill.lesson_reminder,
    selected_micro_skill.worked_example,
    5::smallint,
    'without_reminder'::text,
    'reassessment'::text;
end;
$function$;

create or replace function public.finish_learner_remediation_session_v2(
  requested_token text,
  requested_session_id uuid
)
returns table (
  answer_count integer,
  correct_count integer,
  session_kind text,
  reassessment_passed boolean
)
language plpgsql
security definer
set search_path = ''
as $function$
#variable_conflict use_column
declare
  selected_learner_id uuid;
  selected_kind text;
  counted_answers integer;
  counted_correct integer;
  passed boolean;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  select session.session_kind
  into selected_kind
  from public.remediation_sessions session
  where session.id = requested_session_id
    and session.learner_profile_id = selected_learner_id;

  if selected_kind is null then
    raise exception 'Exercise session is not available';
  end if;

  select count(*)::integer,
    count(*) filter (where attempt.is_correct)::integer
  into counted_answers, counted_correct
  from public.remediation_attempts attempt
  where attempt.remediation_session_id = requested_session_id
    and attempt.answered_at is not null;

  passed := selected_kind = 'reassessment'
    and counted_answers = 5 and counted_correct >= 4;

  update public.remediation_sessions
  set status = 'completed',
      completed_at = coalesce(completed_at, statement_timestamp()),
      reassessment_passed = case
        when selected_kind = 'reassessment' then passed
        else null
      end
  where id = requested_session_id;

  return query select
    counted_answers, counted_correct, selected_kind,
    case when selected_kind = 'reassessment' then passed else null end;
end;
$function$;

create or replace function public.get_my_learner_remediation_history_v2(
  requested_learner_profile_id uuid
)
returns table (
  session_id uuid, subject_name text, domain_name text,
  competence_id text, competence text, question_target integer,
  answer_count integer, correct_count integer, session_status text,
  session_kind text, reassessment_passed boolean,
  started_at timestamptz, completed_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select session.id, subject.name, domain.name,
    replace(micro_skill.code, 'legacy_', ''), micro_skill.student_name,
    coalesce(session.question_target, 0)::integer,
    count(attempt.id) filter (where attempt.answered_at is not null)::integer,
    count(attempt.id) filter (
      where attempt.answered_at is not null and attempt.is_correct
    )::integer,
    session.status::text, session.session_kind,
    session.reassessment_passed, session.started_at, session.completed_at
  from public.remediation_sessions session
  join public.micro_skills micro_skill on micro_skill.id = session.micro_skill_id
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
revoke all on function public.get_learner_reassessment_readiness(text, text)
  from public;
revoke all on function public.start_learner_reassessment_session(text, text)
  from public;
revoke all on function public.finish_learner_remediation_session_v2(text, uuid)
  from public;
revoke all on function public.get_my_learner_remediation_history_v2(uuid)
  from public;

grant execute on function public.get_learner_reassessment_readiness(text, text)
  to anon, authenticated;
grant execute on function public.start_learner_reassessment_session(text, text)
  to anon, authenticated;
grant execute on function public.finish_learner_remediation_session_v2(text, uuid)
  to anon, authenticated;
grant execute on function public.get_my_learner_remediation_history_v2(uuid)
  to authenticated;

commit;
