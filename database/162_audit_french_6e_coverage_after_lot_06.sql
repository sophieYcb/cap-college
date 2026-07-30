/*
 CAP-COLLEGE DATABASE
 File: database/162_audit_french_6e_coverage_after_lot_06.sql
 Purpose: Audit French 6e coverage after publication of lot F6-GRA-06.
 Read-only: Yes
*/

with expected_micro_skills as (
  select
    ms.id,
    ms.code,
    ms.teacher_name,
    sk.name as skill_name,
    d.name as domain_name
  from public.micro_skills ms
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  join public.micro_skill_levels msl on msl.micro_skill_id = ms.id
  join public.levels l on l.id = msl.level_id
  where s.code = 'french'
    and l.code = '6e'
    and msl.is_expected
    and ms.active
),
coverage as (
  select
    e.id,
    e.code,
    e.teacher_name,
    e.skill_name,
    e.domain_name,
    count(q.id) as question_count,
    count(q.id) filter (
      where q.status = 'published' and q.active
    ) as published_count
  from expected_micro_skills e
  left join public.questions q on q.micro_skill_id = e.id
  group by
    e.id,
    e.code,
    e.teacher_name,
    e.skill_name,
    e.domain_name
),
bank_totals as (
  select
    count(*) as total_questions,
    count(*) filter (where q.legacy_id between 1 and 590) as original_questions,
    count(*) filter (
      where q.legacy_id between 1000001 and 1000200
    ) as complementary_questions
  from public.questions q
  join expected_micro_skills e on e.id = q.micro_skill_id
)
select jsonb_build_object(
  'total_questions', (select total_questions from bank_totals),
  'original_questions', (select original_questions from bank_totals),
  'complementary_questions', (
    select complementary_questions from bank_totals
  ),
  'expected_micro_skills', (select count(*) from coverage),
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
  ),
  'micro_skills_above_10', (
    select count(*) from coverage where question_count > 10
  )
) as verification;
