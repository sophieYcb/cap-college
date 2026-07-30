/*
 CAP-COLLEGE DATABASE
 File: database/163_audit_atomic_french_6e_coverage.sql
 Purpose: Audit only active atomic f6_* French 6e micro-skills.
 Read-only: Yes
*/

with coverage as (
  select
    ms.code,
    ms.teacher_name,
    sk.name as skill_name,
    d.name as domain_name,
    count(q.id) as question_count,
    count(q.id) filter (
      where q.status = 'published' and q.active
    ) as published_count
  from public.micro_skills ms
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  join public.micro_skill_levels msl on msl.micro_skill_id = ms.id
  join public.levels l on l.id = msl.level_id
  left join public.questions q on q.micro_skill_id = ms.id
  where s.code = 'french'
    and l.code = '6e'
    and msl.is_expected
    and ms.active
    and ms.code like 'f6\_%' escape '\'
  group by ms.code, ms.teacher_name, sk.name, d.name
)
select jsonb_build_object(
  'expected_atomic_micro_skills', (select count(*) from coverage),
  'micro_skills_at_or_above_10', (
    select count(*) from coverage where question_count >= 10
  ),
  'micro_skills_below_10', (
    select count(*) from coverage where question_count < 10
  ),
  'micro_skills_without_questions', (
    select count(*) from coverage where question_count = 0
  ),
  'questions_needed_to_reach_10', (
    select coalesce(sum(greatest(10 - question_count, 0)), 0)
    from coverage
  ),
  'incomplete_micro_skills', (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'domain', domain_name,
          'skill', skill_name,
          'code', code,
          'micro_skill', teacher_name,
          'questions', question_count,
          'published', published_count,
          'missing_to_10', 10 - question_count
        )
        order by domain_name, skill_name, teacher_name
      ),
      '[]'::jsonb
    )
    from coverage
    where question_count < 10
  )
) as verification;
