/*
 CAP-COLLEGE DATABASE
 File: database/200_audit_french_6e_final.sql
 Purpose: Final audit of the complete French 6e question bank.
 Read-only: Yes
*/

with expected_micro_skills as (
  select ms.id, ms.code, ms.teacher_name, sk.name as skill_name,
    d.name as domain_name
  from public.micro_skills ms
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  join public.micro_skill_levels msl on msl.micro_skill_id = ms.id
  join public.levels l on l.id = msl.level_id
  where s.code = 'french' and l.code = '6e'
    and msl.is_expected and ms.active
),
bank_questions as (
  select q.id, q.legacy_id, q.status, q.active,
    q.current_version_number, q.micro_skill_id
  from public.questions q
  join expected_micro_skills e on e.id = q.micro_skill_id
),
current_versions as (
  select q.id as question_id, qv.id as question_version_id,
    qv.review_status, qv.published_at
  from bank_questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
),
choice_counts as (
  select cv.question_id, count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices
  from current_versions cv
  left join public.answer_choices ac
    on ac.question_version_id = cv.question_version_id
  group by cv.question_id
),
coverage as (
  select e.id, e.code, e.teacher_name, e.skill_name, e.domain_name,
    count(q.id) as question_count,
    count(q.id) filter (
      where q.status = 'published' and q.active
    ) as published_count
  from expected_micro_skills e
  left join bank_questions q on q.micro_skill_id = e.id
  group by e.id, e.code, e.teacher_name, e.skill_name, e.domain_name
)
select jsonb_build_object(
  'total_questions', (select count(*) from bank_questions),
  'original_questions', (
    select count(*) from bank_questions where legacy_id between 1 and 590
  ),
  'complementary_questions', (
    select count(*) from bank_questions
    where legacy_id between 1000001 and 1000508
  ),
  'published_questions', (
    select count(*) from bank_questions
    where status = 'published' and active
  ),
  'published_current_versions', (
    select count(*) from current_versions
    where review_status = 'approved' and published_at is not null
  ),
  'questions_with_current_version', (select count(*) from current_versions),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
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
          'domain', domain_name, 'skill', skill_name, 'code', code,
          'micro_skill', teacher_name, 'questions', question_count,
          'published', published_count, 'missing_to_10', 10 - question_count
        )
        order by domain_name, skill_name, teacher_name
      ),
      '[]'::jsonb
    )
    from coverage where question_count < 10
  )
) as verification;