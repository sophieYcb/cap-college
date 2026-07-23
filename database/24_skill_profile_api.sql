/*
===============================================================================
 CAP-COLLEGE DATABASE — CUMULATIVE SKILL PROFILE API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 24_skill_profile_api.sql
 Purpose      : Build the progressive competency profile used for recommendations.
 Idempotent   : Yes
===============================================================================

 Scoring follows the validated rule:
 - easy:   correct +10, incorrect -20
 - medium: correct +15, incorrect -10
 - hard:   correct +25, incorrect  -5
 Response speed is never used.
*/

begin;

create or replace function public.get_my_skill_profile()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  with evidence as (
    select
      ms.id as micro_skill_id,
      replace(ms.code, 'legacy_', '') as competence_id,
      ms.student_name as competence,
      dmn.name as domain,
      count(*)::integer as evidence_count,
      count(*) filter (where di.is_correct)::integer as correct_count,
      sum(
        case
          when di.is_correct and q.theoretical_difficulty = 1 then 10
          when di.is_correct and q.theoretical_difficulty = 2 then 15
          when di.is_correct then 25
          when not di.is_correct and q.theoretical_difficulty = 1 then -20
          when not di.is_correct and q.theoretical_difficulty = 2 then -10
          else -5
        end
      )::integer as point_delta,
      max(di.answered_at) as last_assessed_at
    from public.diagnostic_items di
    join public.diagnostic_sessions ds on ds.id = di.session_id
    join public.diagnostics diagnostic on diagnostic.id = ds.diagnostic_id
    join public.questions q on q.id = di.question_id
    join public.micro_skills ms on ms.id = q.micro_skill_id
    join public.skills s on s.id = ms.skill_id
    join public.domains dmn on dmn.id = s.domain_id
    where diagnostic.student_id = auth.uid()
      and di.answered_at is not null
    group by ms.id, ms.code, ms.student_name, dmn.name
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
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
      )
      order by
        (evidence_count >= 5) desc,
        greatest(0, least(100, 50 + point_delta)),
        evidence_count desc
    ),
    '[]'::jsonb
  )
  from evidence;
$function$;

revoke all on function public.get_my_skill_profile() from public;
grant execute on function public.get_my_skill_profile() to authenticated;

commit;

