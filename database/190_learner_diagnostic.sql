begin;

alter table public.diagnostics
  alter column student_id drop not null,
  add column if not exists learner_profile_id uuid
    references public.learner_profiles(id) on delete cascade;

create index if not exists diagnostics_learner_profile_idx
  on public.diagnostics (learner_profile_id, started_at desc);

do $block$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'diagnostics_single_owner'
      and conrelid = 'public.diagnostics'::regclass
  ) then
    alter table public.diagnostics
      add constraint diagnostics_single_owner check (
        (student_id is not null and learner_profile_id is null)
        or (student_id is null and learner_profile_id is not null)
      );
  end if;
end;
$block$;

create or replace function public.learner_profile_for_token(
  requested_token text
) returns uuid
language sql stable security definer set search_path = ''
as $function$
  select session.learner_profile_id
  from public.learner_access_sessions session
  join public.learner_profiles learner
    on learner.id = session.learner_profile_id
  where session.token_hash = extensions.digest(
      coalesce(requested_token, ''), 'sha256'
    )
    and session.revoked_at is null
    and session.expires_at > statement_timestamp()
    and learner.active;
$function$;

create or replace function public.get_learner_diagnostic_history(
  requested_token text
) returns jsonb
language sql stable security definer set search_path = ''
as $function$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'questionId', history.question_id,
      'attempts', history.attempts,
      'correctAnswers', history.correct_answers,
      'lastAnsweredAt', history.last_answered_at
    ) order by history.last_answered_at desc
  ), '[]'::jsonb)
  from (
    select di.question_id,
      count(*)::integer as attempts,
      count(*) filter (where di.is_correct)::integer as correct_answers,
      max(di.answered_at) as last_answered_at
    from public.diagnostic_items di
    join public.diagnostic_sessions ds on ds.id = di.session_id
    join public.diagnostics d on d.id = ds.diagnostic_id
    where d.learner_profile_id =
        public.learner_profile_for_token(requested_token)
      and ds.validation_campaign_id is null
      and di.answered_at is not null
    group by di.question_id
  ) history;
$function$;

create or replace function public.start_learner_diagnostic_session(
  requested_token text,
  planned_minutes smallint,
  requested_subject_code text default 'french',
  requested_level_code text default '6e',
  requested_competence_id text default null
)
returns table (
  diagnostic_id uuid, session_id uuid,
  focus_competence_id text, focus_name text
)
language plpgsql security definer set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_subject_id smallint;
  selected_level_id smallint;
  active_diagnostic_id uuid;
  new_session_id uuid;
  selected_micro_skill_id uuid;
  selected_focus_name text;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then raise exception 'Learner session required'; end if;
  if planned_minutes not between 1 and 180 then raise exception 'Invalid planned duration'; end if;

  select id into selected_subject_id from public.subjects
  where code = requested_subject_code and active;
  select id into selected_level_id from public.levels
  where code = requested_level_code and active;
  if selected_subject_id is null or selected_level_id is null then
    raise exception 'Unknown subject or level';
  end if;

  if requested_competence_id is not null
     and requested_competence_id <> 'all' then
    select ms.id, ms.student_name
    into selected_micro_skill_id, selected_focus_name
    from public.micro_skills ms
    where replace(ms.code, 'legacy_', '') = requested_competence_id
      and ms.active limit 1;
    if selected_micro_skill_id is null then raise exception 'Unknown competency'; end if;
  end if;

  select d.id into active_diagnostic_id
  from public.diagnostics d
  where d.learner_profile_id = selected_learner_id
    and d.subject_id = selected_subject_id
    and d.level_id = selected_level_id
    and d.status = 'active'
  order by d.started_at limit 1;

  if active_diagnostic_id is null then
    insert into public.diagnostics (
      student_id, learner_profile_id, subject_id, level_id
    ) values (
      null, selected_learner_id, selected_subject_id, selected_level_id
    ) returning id into active_diagnostic_id;
  end if;

  update public.diagnostic_sessions
  set status = 'cancelled',
      ended_at = coalesce(ended_at, statement_timestamp())
  where diagnostic_id = active_diagnostic_id and status = 'active';

  insert into public.diagnostic_sessions (
    diagnostic_id, planned_minutes, focus_micro_skill_id
  ) values (
    active_diagnostic_id, planned_minutes, selected_micro_skill_id
  ) returning id into new_session_id;

  return query select
    active_diagnostic_id,
    new_session_id,
    coalesce(requested_competence_id, 'all'),
    coalesce(selected_focus_name, 'Tous les thèmes');
end;
$function$;

create or replace function public.submit_learner_diagnostic_answer(
  requested_token text,
  requested_session_id uuid,
  requested_question_version_id uuid,
  requested_choice_id uuid,
  requested_sequence_number integer
)
returns table (
  is_correct boolean,
  correct_choice_id uuid,
  correction_explanation text
)
language plpgsql security definer set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_question_id uuid;
  expected_choice_id uuid;
  answer_is_correct boolean;
  explanation text;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then raise exception 'Learner session required'; end if;
  if requested_sequence_number < 1 then raise exception 'Invalid sequence number'; end if;

  select q.id, qv.correction_explanation
  into selected_question_id, explanation
  from public.question_versions qv
  join public.questions q on q.id = qv.question_id
  join public.diagnostic_sessions ds on ds.id = requested_session_id
  join public.diagnostics d on d.id = ds.diagnostic_id
  where qv.id = requested_question_version_id
    and q.current_version_number = qv.version_number
    and q.status = 'published' and q.active
    and ds.status = 'active'
    and d.learner_profile_id = selected_learner_id;

  if selected_question_id is null then
    raise exception 'Question or session is not available';
  end if;
  if not exists (
    select 1 from public.answer_choices ac
    where ac.id = requested_choice_id
      and ac.question_version_id = requested_question_version_id
  ) then raise exception 'Choice does not belong to this question'; end if;

  select ac.id into expected_choice_id
  from public.answer_choices ac
  where ac.question_version_id = requested_question_version_id
    and ac.is_correct;

  answer_is_correct := requested_choice_id = expected_choice_id;

  insert into public.diagnostic_items (
    session_id, question_id, question_version_id, selected_choice_id,
    sequence_number, is_correct, answered_at
  ) values (
    requested_session_id, selected_question_id,
    requested_question_version_id, requested_choice_id,
    requested_sequence_number, answer_is_correct, statement_timestamp()
  )
  on conflict (session_id, sequence_number) do update
  set question_id = excluded.question_id,
      question_version_id = excluded.question_version_id,
      selected_choice_id = excluded.selected_choice_id,
      is_correct = excluded.is_correct,
      answered_at = excluded.answered_at;

  return query select answer_is_correct, expected_choice_id, explanation;
end;
$function$;

create or replace function public.finish_learner_diagnostic_session(
  requested_token text,
  requested_session_id uuid
)
returns table (answer_count integer, correct_count integer)
language plpgsql security definer set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_diagnostic_id uuid;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then raise exception 'Learner session required'; end if;

  select ds.diagnostic_id into selected_diagnostic_id
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  where ds.id = requested_session_id
    and d.learner_profile_id = selected_learner_id;
  if selected_diagnostic_id is null then raise exception 'Session is not available'; end if;

  update public.diagnostic_sessions
  set status = 'completed',
      ended_at = coalesce(ended_at, statement_timestamp())
  where id = requested_session_id;
  update public.diagnostics set updated_at = statement_timestamp()
  where id = selected_diagnostic_id;

  return query select count(*)::integer,
    count(*) filter (where di.is_correct)::integer
  from public.diagnostic_items di
  where di.session_id = requested_session_id
    and di.answered_at is not null;
end;
$function$;

create or replace function public.get_learner_diagnostic_session_state(
  requested_token text,
  requested_session_id uuid
)
returns table (
  session_status public.session_status,
  recorded_answers integer
)
language sql stable security definer set search_path = ''
as $function$
  select ds.status, count(di.id)::integer
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  left join public.diagnostic_items di
    on di.session_id = ds.id and di.answered_at is not null
  where ds.id = requested_session_id
    and d.learner_profile_id =
      public.learner_profile_for_token(requested_token)
  group by ds.id, ds.status;
$function$;

create or replace function public.get_learner_active_diagnostic_session(
  requested_token text
)
returns table (
  diagnostic_id uuid, session_id uuid, planned_minutes smallint,
  recorded_answers integer, focus_competence_id text, focus_name text
)
language sql stable security definer set search_path = ''
as $function$
  select d.id, ds.id, ds.planned_minutes, count(di.id)::integer,
    coalesce(replace(ms.code, 'legacy_', ''), 'all'),
    coalesce(ms.student_name, 'Tous les thèmes')
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  left join public.micro_skills ms on ms.id = ds.focus_micro_skill_id
  left join public.diagnostic_items di
    on di.session_id = ds.id and di.answered_at is not null
  where d.learner_profile_id =
      public.learner_profile_for_token(requested_token)
    and d.status = 'active' and ds.status = 'active'
    and ds.validation_campaign_id is null
  group by d.id, ds.id, ds.planned_minutes, ds.started_at, ms.code, ms.student_name
  order by ds.started_at desc limit 1;
$function$;

create or replace function public.close_learner_diagnostic_session(
  requested_token text,
  requested_session_id uuid
) returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  update public.diagnostic_sessions ds
  set status = 'cancelled',
      ended_at = coalesce(ds.ended_at, statement_timestamp())
  from public.diagnostics d
  where ds.id = requested_session_id
    and d.id = ds.diagnostic_id
    and d.learner_profile_id =
      public.learner_profile_for_token(requested_token)
    and ds.status = 'active';
  if not found then raise exception 'Active session is not available'; end if;
end;
$function$;

create or replace function public.get_learner_skill_profile(
  requested_token text
) returns jsonb
language sql stable security definer set search_path = ''
as $function$
  with evidence as (
    select ms.id as micro_skill_id,
      replace(ms.code, 'legacy_', '') as competence_id,
      ms.student_name as competence,
      dmn.name as domain,
      count(*)::integer as evidence_count,
      count(*) filter (where di.is_correct)::integer as correct_count,
      sum(case
        when di.is_correct and q.theoretical_difficulty = 1 then 10
        when di.is_correct and q.theoretical_difficulty = 2 then 15
        when di.is_correct then 25
        when not di.is_correct and q.theoretical_difficulty = 1 then -20
        when not di.is_correct and q.theoretical_difficulty = 2 then -10
        else -5 end)::integer as point_delta,
      max(di.answered_at) as last_assessed_at
    from public.diagnostic_items di
    join public.diagnostic_sessions ds on ds.id = di.session_id
    join public.diagnostics diagnostic on diagnostic.id = ds.diagnostic_id
    join public.questions q on q.id = di.question_id
    join public.micro_skills ms on ms.id = q.micro_skill_id
    join public.skills s on s.id = ms.skill_id
    join public.domains dmn on dmn.id = s.domain_id
    where diagnostic.learner_profile_id =
        public.learner_profile_for_token(requested_token)
      and ds.validation_campaign_id is null
      and di.answered_at is not null
    group by ms.id, ms.code, ms.student_name, dmn.name
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'microSkillId', micro_skill_id,
    'competenceId', competence_id,
    'competence', competence,
    'domain', domain,
    'evidenceCount', evidence_count,
    'correctCount', correct_count,
    'masteryScore', greatest(0, least(100, 50 + point_delta)),
    'confidenceScore', least(100, evidence_count * 15),
    'sufficientEvidence', evidence_count >= 5,
    'lastAssessedAt', last_assessed_at
  ) order by (evidence_count >= 5) desc,
    greatest(0, least(100, 50 + point_delta)), evidence_count desc),
    '[]'::jsonb)
  from evidence;
$function$;

revoke all on function public.learner_profile_for_token(text) from public;
revoke all on function public.get_learner_diagnostic_history(text) from public;
revoke all on function public.start_learner_diagnostic_session(text, smallint, text, text, text) from public;
revoke all on function public.submit_learner_diagnostic_answer(text, uuid, uuid, uuid, integer) from public;
revoke all on function public.finish_learner_diagnostic_session(text, uuid) from public;
revoke all on function public.get_learner_diagnostic_session_state(text, uuid) from public;
revoke all on function public.get_learner_active_diagnostic_session(text) from public;
revoke all on function public.close_learner_diagnostic_session(text, uuid) from public;
revoke all on function public.get_learner_skill_profile(text) from public;

grant execute on function public.get_learner_diagnostic_history(text) to anon, authenticated;
grant execute on function public.start_learner_diagnostic_session(text, smallint, text, text, text) to anon, authenticated;
grant execute on function public.submit_learner_diagnostic_answer(text, uuid, uuid, uuid, integer) to anon, authenticated;
grant execute on function public.finish_learner_diagnostic_session(text, uuid) to anon, authenticated;
grant execute on function public.get_learner_diagnostic_session_state(text, uuid) to anon, authenticated;
grant execute on function public.get_learner_active_diagnostic_session(text) to anon, authenticated;
grant execute on function public.close_learner_diagnostic_session(text, uuid) to anon, authenticated;
grant execute on function public.get_learner_skill_profile(text) to anon, authenticated;

commit;