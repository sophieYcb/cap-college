/*
 CAP-COLLEGE DATABASE
 File: database/207_reliable_progressive_learner_diagnostic.sql
 Purpose: Build a reliable learner diagnostic over multiple sessions.
 Idempotent: Yes
*/

begin;

alter table public.diagnostics
  add column if not exists result_snapshot jsonb,
  add column if not exists completion_rule_version text;

create or replace function public.get_learner_diagnostic_progress(
  requested_token text
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_diagnostic_id uuid;
  selected_subject_id smallint;
  selected_level_id smallint;
  selected_status public.diagnostic_status;
  result jsonb;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  select d.id, d.subject_id, d.level_id, d.status
  into selected_diagnostic_id, selected_subject_id, selected_level_id,
    selected_status
  from public.diagnostics d
  where d.learner_profile_id = selected_learner_id
    and d.status in ('active', 'completed')
  order by (d.status = 'active') desc, d.started_at desc
  limit 1;

  if selected_diagnostic_id is null then
    return jsonb_build_object(
      'hasDiagnostic', false,
      'diagnosisReady', false,
      'progressPercent', 0,
      'assessedSkills', 0,
      'totalSkills', 0,
      'answeredQuestions', 0,
      'questionsRemaining', 0,
      'completedSessions', 0,
      'skills', '[]'::jsonb
    );
  end if;

  with expected_skills as (
    select
      ms.id,
      ms.code,
      ms.student_name,
      dmn.name as domain_name
    from public.micro_skills ms
    join public.skills sk on sk.id = ms.skill_id
    join public.domains dmn on dmn.id = sk.domain_id
    join public.micro_skill_levels msl on msl.micro_skill_id = ms.id
    where dmn.subject_id = selected_subject_id
      and msl.level_id = selected_level_id
      and msl.is_expected
      and ms.active
  ),
  evidence as (
    select
      q.micro_skill_id,
      count(di.id)::integer as evidence_count,
      count(*) filter (where di.is_correct)::integer as correct_count,
      count(distinct ds.id)::integer as session_count,
      max(di.answered_at) as last_assessed_at
    from public.diagnostic_items di
    join public.diagnostic_sessions ds on ds.id = di.session_id
    join public.questions q on q.id = di.question_id
    where ds.diagnostic_id = selected_diagnostic_id
      and ds.validation_campaign_id is null
      and ds.status <> 'cancelled'
      and di.answered_at is not null
    group by q.micro_skill_id
  ),
  skill_state as (
    select
      es.id,
      es.code,
      es.student_name,
      es.domain_name,
      coalesce(ev.evidence_count, 0) as evidence_count,
      coalesce(ev.correct_count, 0) as correct_count,
      coalesce(ev.session_count, 0) as session_count,
      ev.last_assessed_at,
      case
        when coalesce(ev.evidence_count, 0) >= 6
         and ev.correct_count::numeric / nullif(ev.evidence_count, 0)
             between 0.34 and 0.66
          then 8
        when coalesce(ev.evidence_count, 0) >= 4
         and ev.correct_count > 0
         and ev.correct_count < ev.evidence_count
          then 6
        else 4
      end as required_evidence
    from expected_skills es
    left join evidence ev on ev.micro_skill_id = es.id
  ),
  assessed as (
    select *,
      evidence_count >= required_evidence and session_count >= 2
        as sufficient_evidence,
      case
        when evidence_count = 0 then null
        else round(correct_count::numeric * 100 / evidence_count)
      end as mastery_score
    from skill_state
  ),
  totals as (
    select
      count(*)::integer as total_skills,
      count(*) filter (where sufficient_evidence)::integer as assessed_skills,
      coalesce(sum(evidence_count), 0)::integer as answered_questions,
      coalesce(sum(
        greatest(required_evidence - evidence_count, 0)
        + case
            when evidence_count >= required_evidence and session_count < 2
              then 1
            else 0
          end
      ), 0)::integer as questions_remaining,
      coalesce(round(
        100 * sum(
          least(evidence_count, required_evidence)::numeric
          * case when session_count >= 2 then 1 else 0.75 end
        ) / nullif(sum(required_evidence), 0)
      ), 0)::integer as progress_percent,
      coalesce(bool_and(sufficient_evidence), false) as diagnosis_ready
    from assessed
  )
  select jsonb_build_object(
    'hasDiagnostic', true,
    'diagnosticId', selected_diagnostic_id,
    'diagnosticStatus', selected_status,
    'diagnosisReady', totals.diagnosis_ready,
    'progressPercent', least(100, totals.progress_percent),
    'assessedSkills', totals.assessed_skills,
    'totalSkills', totals.total_skills,
    'answeredQuestions', totals.answered_questions,
    'questionsRemaining', totals.questions_remaining,
    'completedSessions', (
      select count(*)::integer
      from public.diagnostic_sessions ds
      where ds.diagnostic_id = selected_diagnostic_id
        and ds.validation_campaign_id is null
        and ds.status = 'completed'
    ),
    'ruleVersion', 'reliable-v1',
    'skills', (
      select coalesce(jsonb_agg(
        jsonb_build_object(
          'microSkillId', assessed.id,
          'competenceId', assessed.code,
          'competence', assessed.student_name,
          'domain', assessed.domain_name,
          'evidenceCount', assessed.evidence_count,
          'correctCount', assessed.correct_count,
          'sessionCount', assessed.session_count,
          'requiredEvidence', assessed.required_evidence,
          'sufficientEvidence', assessed.sufficient_evidence,
          'masteryScore', assessed.mastery_score,
          'level', case
            when not assessed.sufficient_evidence then 'insufficient'
            when assessed.mastery_score >= 80 then 'solid'
            when assessed.mastery_score >= 65 then 'probable'
            when assessed.mastery_score >= 40 then 'fragile'
            else 'not_mastered'
          end,
          'lastAssessedAt', assessed.last_assessed_at
        )
        order by assessed.domain_name, assessed.student_name
      ), '[]'::jsonb)
      from assessed
    )
  ) into result
  from totals;

  return result;
end;
$function$;

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
  progress_snapshot jsonb;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  select ds.diagnostic_id into selected_diagnostic_id
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  where ds.id = requested_session_id
    and d.learner_profile_id = selected_learner_id;

  if selected_diagnostic_id is null then
    raise exception 'Session is not available';
  end if;

  update public.diagnostic_sessions
  set status = 'completed',
      ended_at = coalesce(ended_at, statement_timestamp())
  where id = requested_session_id
    and status in ('active', 'completed');

  progress_snapshot :=
    public.get_learner_diagnostic_progress(requested_token);

  if coalesce((progress_snapshot ->> 'diagnosisReady')::boolean, false) then
    update public.diagnostics
    set status = 'completed',
        completed_at = coalesce(completed_at, statement_timestamp()),
        result_snapshot = progress_snapshot,
        completion_rule_version = 'reliable-v1',
        updated_at = statement_timestamp()
    where id = selected_diagnostic_id;
  else
    update public.diagnostics
    set result_snapshot = null,
        completion_rule_version = 'reliable-v1',
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

revoke all on function public.get_learner_diagnostic_progress(text)
  from public;
grant execute on function public.get_learner_diagnostic_progress(text)
  to anon, authenticated;

revoke all on function public.finish_learner_diagnostic_session(text, uuid)
  from public;
grant execute on function public.finish_learner_diagnostic_session(text, uuid)
  to anon, authenticated;

commit;