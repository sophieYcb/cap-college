/*
 CAP-COLLEGE DATABASE
 File: database/257_final_learner_diagnostic_reports.sql
 Purpose: Save the completed learner diagnostic for the correct subject and
          expose dated final reports to linked guardians and teachers.
 Idempotent: Yes
*/

begin;

create or replace function public.finish_learner_diagnostic_session(
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
  selected_diagnostic_id uuid;
  selected_subject_code text;
  selected_subject_name text;
  selected_started_at timestamptz;
  progress_snapshot jsonb;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  select
    ds.diagnostic_id,
    subject.code,
    subject.name,
    diagnostic.started_at
  into
    selected_diagnostic_id,
    selected_subject_code,
    selected_subject_name,
    selected_started_at
  from public.diagnostic_sessions ds
  join public.diagnostics diagnostic on diagnostic.id = ds.diagnostic_id
  join public.subjects subject on subject.id = diagnostic.subject_id
  where ds.id = requested_session_id
    and diagnostic.learner_profile_id = selected_learner_id;

  if selected_diagnostic_id is null then
    raise exception 'Session is not available';
  end if;

  update public.diagnostic_sessions
  set status = 'completed',
      ended_at = coalesce(ended_at, statement_timestamp())
  where id = requested_session_id
    and status in ('active', 'completed');

  progress_snapshot := public.get_learner_subject_diagnostic_progress(
    requested_token,
    selected_subject_code
  );

  if coalesce(progress_snapshot ->> 'diagnosticId', '')
       <> selected_diagnostic_id::text then
    raise exception 'The subject report does not match the completed diagnostic';
  end if;

  if coalesce((progress_snapshot ->> 'diagnosisReady')::boolean, false) then
    progress_snapshot := progress_snapshot || jsonb_build_object(
      'subjectCode', selected_subject_code,
      'subjectName', selected_subject_name,
      'startedAt', selected_started_at,
      'completedAt', statement_timestamp(),
      'ruleVersion', 'reliable-v2-final-report'
    );

    update public.diagnostics
    set status = 'completed',
        completed_at = coalesce(completed_at, statement_timestamp()),
        result_snapshot = progress_snapshot,
        completion_rule_version = 'reliable-v2-final-report',
        updated_at = statement_timestamp()
    where id = selected_diagnostic_id;
  else
    update public.diagnostics
    set result_snapshot = null,
        completion_rule_version = 'reliable-v2-final-report',
        updated_at = statement_timestamp()
    where id = selected_diagnostic_id;
  end if;

  return query
  select
    count(*)::integer,
    count(*) filter (where di.is_correct)::integer
  from public.diagnostic_items di
  where di.session_id = requested_session_id
    and di.answered_at is not null;
end;
$function$;

create or replace function public.get_my_learner_diagnostic_reports(
  requested_learner_profile_id uuid
)
returns table (
  diagnostic_id uuid,
  subject_code text,
  subject_name text,
  started_at timestamptz,
  completed_at timestamptz,
  answered_questions integer,
  completed_sessions integer,
  report jsonb
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    diagnostic.id,
    subject.code,
    subject.name,
    diagnostic.started_at,
    diagnostic.completed_at,
    coalesce(
      (diagnostic.result_snapshot ->> 'answeredQuestions')::integer,
      0
    ),
    coalesce(
      (diagnostic.result_snapshot ->> 'completedSessions')::integer,
      0
    ),
    diagnostic.result_snapshot
      || jsonb_build_object(
        'diagnosticId', diagnostic.id,
        'subjectCode', subject.code,
        'subjectName', subject.name,
        'startedAt', diagnostic.started_at,
        'completedAt', diagnostic.completed_at
      )
  from public.diagnostics diagnostic
  join public.subjects subject on subject.id = diagnostic.subject_id
  where diagnostic.learner_profile_id = requested_learner_profile_id
    and diagnostic.status = 'completed'
    and diagnostic.result_snapshot is not null
    and exists (
      select 1
      from public.learner_profile_adults link
      where link.learner_profile_id = diagnostic.learner_profile_id
        and link.adult_user_id = auth.uid()
    )
  order by diagnostic.completed_at desc, diagnostic.started_at desc;
$function$;

revoke all on function public.finish_learner_diagnostic_session(text, uuid)
  from public;
grant execute on function public.finish_learner_diagnostic_session(text, uuid)
  to anon, authenticated;

revoke all on function public.get_my_learner_diagnostic_reports(uuid)
  from public;
grant execute on function public.get_my_learner_diagnostic_reports(uuid)
  to authenticated;

commit;
