/*
 CAP-COLLEGE DATABASE
 File: database/226_fix_adult_progress_available_level.sql
 Purpose: Read progress from the currently available 6e diagnostic banks.
 Idempotent: Yes
*/

begin;

create or replace function public.get_my_learner_progress()
returns table (
  learner_profile_id uuid,
  subject_code text,
  subject_name text,
  diagnostic_status text,
  has_diagnostic boolean,
  diagnosis_ready boolean,
  progress_percent integer,
  assessed_skills integer,
  total_skills integer,
  answered_questions integer,
  questions_remaining integer,
  completed_sessions integer
)
language sql
stable
security definer
set search_path = ''
as $function$
  with linked_learners as (
    select lp.id, diagnostic_level.id as level_id
    from public.learner_profile_adults link
    join public.learner_profiles lp
      on lp.id = link.learner_profile_id
    join public.levels diagnostic_level
      on diagnostic_level.code = '6e'
     and diagnostic_level.active
    where link.adult_user_id = auth.uid()
      and lp.active
  ),
  expected_skills as (
    select
      learner.id as learner_profile_id,
      learner.level_id,
      subject.id as subject_id,
      subject.code as subject_code,
      subject.name as subject_name,
      subject.sort_order,
      ms.id as micro_skill_id
    from linked_learners learner
    join public.micro_skill_levels msl
      on msl.level_id = learner.level_id
     and msl.is_expected
    join public.micro_skills ms
      on ms.id = msl.micro_skill_id
     and ms.active
    join public.skills skill on skill.id = ms.skill_id
    join public.domains domain on domain.id = skill.domain_id
    join public.subjects subject
      on subject.id = domain.subject_id
     and subject.active
  ),
  subject_scopes as (
    select distinct
      expected.learner_profile_id,
      expected.level_id,
      expected.subject_id,
      expected.subject_code,
      expected.subject_name,
      expected.sort_order
    from expected_skills expected
  ),
  selected_diagnostics as (
    select
      scope.*,
      selected.id as diagnostic_id,
      selected.status as diagnostic_status
    from subject_scopes scope
    left join lateral (
      select diagnostic.id, diagnostic.status
      from public.diagnostics diagnostic
      where diagnostic.learner_profile_id = scope.learner_profile_id
        and diagnostic.subject_id = scope.subject_id
        and diagnostic.level_id = scope.level_id
        and diagnostic.status in ('active', 'completed')
      order by
        (diagnostic.status = 'active') desc,
        (
          select max(session.started_at)
          from public.diagnostic_sessions session
          where session.diagnostic_id = diagnostic.id
        ) desc nulls last,
        diagnostic.started_at desc
      limit 1
    ) selected on true
  ),
  evidence as (
    select
      selected.learner_profile_id,
      selected.subject_id,
      question.micro_skill_id,
      count(item.id)::integer as evidence_count,
      count(*) filter (where item.is_correct)::integer as correct_count,
      count(distinct session.id)::integer as session_count
    from selected_diagnostics selected
    join public.diagnostic_sessions session
      on session.diagnostic_id = selected.diagnostic_id
     and session.validation_campaign_id is null
    join public.diagnostic_items item
      on item.session_id = session.id
     and item.answered_at is not null
    join public.questions question on question.id = item.question_id
    group by
      selected.learner_profile_id,
      selected.subject_id,
      question.micro_skill_id
  ),
  skill_state as (
    select
      expected.learner_profile_id,
      expected.subject_id,
      expected.micro_skill_id,
      selected.diagnostic_id,
      selected.diagnostic_status,
      coalesce(evidence.evidence_count, 0) as evidence_count,
      coalesce(evidence.correct_count, 0) as correct_count,
      coalesce(evidence.session_count, 0) as session_count,
      case
        when coalesce(evidence.evidence_count, 0) >= 6
         and evidence.correct_count::numeric
             / nullif(evidence.evidence_count, 0)
             between 0.34 and 0.66
          then 8
        when coalesce(evidence.evidence_count, 0) >= 4
         and evidence.correct_count > 0
         and evidence.correct_count < evidence.evidence_count
          then 6
        else 4
      end as required_evidence
    from expected_skills expected
    join selected_diagnostics selected
      on selected.learner_profile_id = expected.learner_profile_id
     and selected.subject_id = expected.subject_id
    left join evidence
      on evidence.learner_profile_id = expected.learner_profile_id
     and evidence.subject_id = expected.subject_id
     and evidence.micro_skill_id = expected.micro_skill_id
  ),
  assessed as (
    select
      state.*,
      state.evidence_count >= state.required_evidence
        and state.session_count >= 2 as sufficient_evidence
    from skill_state state
  ),
  summaries as (
    select
      assessed.learner_profile_id,
      assessed.subject_id,
      assessed.diagnostic_id,
      assessed.diagnostic_status,
      count(*)::integer as total_skills,
      count(*) filter (
        where assessed.sufficient_evidence
      )::integer as assessed_skills,
      coalesce(sum(assessed.evidence_count), 0)::integer
        as answered_questions,
      coalesce(sum(
        greatest(
          assessed.required_evidence - assessed.evidence_count,
          0
        )
        + case
            when assessed.evidence_count >= assessed.required_evidence
             and assessed.session_count < 2
              then 1
            else 0
          end
      ), 0)::integer as questions_remaining,
      case
        when assessed.diagnostic_id is null then 0
        else least(100, coalesce(round(
          100 * sum(
            least(
              assessed.evidence_count,
              assessed.required_evidence
            )::numeric
            * case
                when assessed.session_count >= 2 then 1
                else 0.75
              end
          ) / nullif(sum(assessed.required_evidence), 0)
        ), 0))::integer
      end as progress_percent,
      assessed.diagnostic_id is not null
        and coalesce(bool_and(assessed.sufficient_evidence), false)
        as diagnosis_ready
    from assessed
    group by
      assessed.learner_profile_id,
      assessed.subject_id,
      assessed.diagnostic_id,
      assessed.diagnostic_status
  )
  select
    summary.learner_profile_id,
    scope.subject_code,
    scope.subject_name,
    summary.diagnostic_status::text,
    summary.diagnostic_id is not null,
    summary.diagnosis_ready,
    summary.progress_percent,
    summary.assessed_skills,
    summary.total_skills,
    summary.answered_questions,
    summary.questions_remaining,
    case
      when summary.diagnostic_id is null then 0
      else (
        select count(*)::integer
        from public.diagnostic_sessions session
        where session.diagnostic_id = summary.diagnostic_id
          and session.validation_campaign_id is null
          and session.status = 'completed'
      )
    end
  from summaries summary
  join subject_scopes scope
    on scope.learner_profile_id = summary.learner_profile_id
   and scope.subject_id = summary.subject_id
  order by
    summary.learner_profile_id,
    scope.sort_order,
    scope.subject_name;
$function$;

revoke all on function public.get_my_learner_progress() from public;
grant execute on function public.get_my_learner_progress()
  to authenticated;

commit;
