/*
 CAP-COLLEGE DATABASE
 File: database/259_rebuild_missing_final_diagnostic_reports.sql
 Purpose: Rebuild missing final reports from their own diagnostic evidence and
          make future completion independent from another active subject.
 Idempotent: Yes
*/

begin;

create or replace function public.build_learner_diagnostic_snapshot(
  requested_diagnostic_id uuid
) returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  with selected as (
    select
      diagnostic.id,
      diagnostic.subject_id,
      diagnostic.level_id,
      diagnostic.status,
      diagnostic.started_at,
      diagnostic.completed_at,
      subject.code as subject_code,
      subject.name as subject_name
    from public.diagnostics diagnostic
    join public.subjects subject on subject.id = diagnostic.subject_id
    where diagnostic.id = requested_diagnostic_id
  ),
  expected_skills as (
    select
      micro_skill.id,
      micro_skill.code,
      micro_skill.student_name,
      domain.name as domain_name
    from selected
    join public.micro_skill_levels level_link
      on level_link.level_id = selected.level_id
     and level_link.is_expected
    join public.micro_skills micro_skill
      on micro_skill.id = level_link.micro_skill_id
     and micro_skill.active
    join public.skills skill on skill.id = micro_skill.skill_id
    join public.domains domain
      on domain.id = skill.domain_id
     and domain.subject_id = selected.subject_id
  ),
  evidence as (
    select
      question.micro_skill_id,
      count(item.id)::integer as evidence_count,
      count(*) filter (where item.is_correct)::integer as correct_count,
      count(distinct session.id)::integer as session_count,
      max(item.answered_at) as last_assessed_at
    from public.diagnostic_sessions session
    join public.diagnostic_items item
      on item.session_id = session.id
     and item.answered_at is not null
    join public.questions question on question.id = item.question_id
    where session.diagnostic_id = requested_diagnostic_id
      and session.validation_campaign_id is null
      and session.status <> 'cancelled'
    group by question.micro_skill_id
  ),
  skill_state as (
    select
      expected.*,
      coalesce(evidence.evidence_count, 0) as evidence_count,
      coalesce(evidence.correct_count, 0) as correct_count,
      coalesce(evidence.session_count, 0) as session_count,
      evidence.last_assessed_at,
      case
        when coalesce(evidence.evidence_count, 0) >= 6
         and evidence.correct_count::numeric
             / nullif(evidence.evidence_count, 0) between 0.34 and 0.66
          then 8
        when coalesce(evidence.evidence_count, 0) >= 4
         and evidence.correct_count > 0
         and evidence.correct_count < evidence.evidence_count
          then 6
        else 4
      end as required_evidence
    from expected_skills expected
    left join evidence on evidence.micro_skill_id = expected.id
  ),
  assessed as (
    select
      skill_state.*,
      evidence_count >= required_evidence and session_count >= 2
        as sufficient_evidence,
      case when evidence_count = 0 then null
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
        + case when evidence_count >= required_evidence and session_count < 2
            then 1 else 0 end
      ), 0)::integer as questions_remaining,
      coalesce(bool_and(sufficient_evidence), false) as diagnosis_ready
    from assessed
  )
  select jsonb_build_object(
    'hasDiagnostic', true,
    'diagnosticId', selected.id,
    'diagnosticStatus', selected.status,
    'subjectCode', selected.subject_code,
    'subjectName', selected.subject_name,
    'startedAt', selected.started_at,
    'completedAt', selected.completed_at,
    'diagnosisReady', totals.diagnosis_ready,
    'progressPercent', case when totals.diagnosis_ready then 100 else
      least(100, round(100 * totals.assessed_skills::numeric
        / nullif(totals.total_skills, 0))) end,
    'assessedSkills', totals.assessed_skills,
    'totalSkills', totals.total_skills,
    'answeredQuestions', totals.answered_questions,
    'questionsRemaining', totals.questions_remaining,
    'completedSessions', (
      select count(*)::integer
      from public.diagnostic_sessions session
      where session.diagnostic_id = selected.id
        and session.validation_campaign_id is null
        and session.status = 'completed'
    ),
    'ruleVersion', 'reliable-v3-by-diagnostic',
    'skills', (
      select coalesce(jsonb_agg(jsonb_build_object(
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
      ) order by assessed.domain_name, assessed.student_name), '[]'::jsonb)
      from assessed
    )
  )
  from selected cross join totals;
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

  select session.diagnostic_id into selected_diagnostic_id
  from public.diagnostic_sessions session
  join public.diagnostics diagnostic on diagnostic.id = session.diagnostic_id
  where session.id = requested_session_id
    and diagnostic.learner_profile_id = selected_learner_id;

  if selected_diagnostic_id is null then
    raise exception 'Session is not available';
  end if;

  update public.diagnostic_sessions
  set status = 'completed', ended_at = coalesce(ended_at, statement_timestamp())
  where id = requested_session_id and status in ('active', 'completed');

  progress_snapshot :=
    public.build_learner_diagnostic_snapshot(selected_diagnostic_id);

  if coalesce((progress_snapshot ->> 'diagnosisReady')::boolean, false) then
    progress_snapshot := progress_snapshot || jsonb_build_object(
      'diagnosticStatus', 'completed',
      'completedAt', statement_timestamp()
    );
    update public.diagnostics
    set status = 'completed',
        completed_at = coalesce(completed_at, statement_timestamp()),
        result_snapshot = progress_snapshot,
        completion_rule_version = 'reliable-v3-by-diagnostic',
        updated_at = statement_timestamp()
    where id = selected_diagnostic_id;
  else
    update public.diagnostics
    set result_snapshot = null,
        completion_rule_version = 'reliable-v3-by-diagnostic',
        updated_at = statement_timestamp()
    where id = selected_diagnostic_id;
  end if;

  return query
  select count(*)::integer,
    count(*) filter (where item.is_correct)::integer
  from public.diagnostic_items item
  where item.session_id = requested_session_id
    and item.answered_at is not null;
end;
$function$;

do $block$
declare
  target record;
  rebuilt jsonb;
begin
  for target in
    select diagnostic.id, diagnostic.completed_at
    from public.diagnostics diagnostic
    where diagnostic.status = 'completed'
      and diagnostic.result_snapshot is null
  loop
    rebuilt := public.build_learner_diagnostic_snapshot(target.id);
    if coalesce((rebuilt ->> 'diagnosisReady')::boolean, false) then
      update public.diagnostics
      set result_snapshot = rebuilt || jsonb_build_object(
            'diagnosticStatus', 'completed',
            'completedAt', target.completed_at
          ),
          completion_rule_version = 'reliable-v3-rebuilt',
          updated_at = statement_timestamp()
      where id = target.id;
    end if;
  end loop;
end;
$block$;

revoke all on function public.build_learner_diagnostic_snapshot(uuid)
  from public;

revoke all on function public.finish_learner_diagnostic_session(text, uuid)
  from public;
grant execute on function public.finish_learner_diagnostic_session(text, uuid)
  to anon, authenticated;

commit;
