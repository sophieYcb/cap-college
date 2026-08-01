/*
 CAP-COLLEGE DATABASE
 File: database/201_diagnose_french_6e_final_anomalies.sql
 Purpose: Diagnose remaining French 6e legacy-bank anomalies.
 Read-only: Yes
*/

with expected_micro_skills as (
  select ms.id, ms.code, ms.teacher_name
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
bank_questions as (
  select
    q.id,
    q.legacy_id,
    q.status,
    q.active,
    q.current_version_number,
    q.micro_skill_id,
    case
      when q.legacy_id between 1 and 590 then 'original'
      else 'complementary'
    end as bank_origin
  from public.questions q
  join expected_micro_skills e on e.id = q.micro_skill_id
),
current_versions as (
  select q.id as question_id, qv.id as question_version_id
  from bank_questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
),
choice_counts as (
  select
    q.id as question_id,
    q.legacy_id,
    q.status,
    q.active,
    q.bank_origin,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices
  from bank_questions q
  join current_versions cv on cv.question_id = q.id
  left join public.answer_choices ac
    on ac.question_version_id = cv.question_version_id
  group by
    q.id, q.legacy_id, q.status, q.active, q.bank_origin
),
micro_skill_counts as (
  select
    e.id,
    e.code,
    e.teacher_name,
    count(q.id) as questions
  from expected_micro_skills e
  left join bank_questions q on q.micro_skill_id = e.id
  group by e.id, e.code, e.teacher_name
)
select jsonb_build_object(
  'unpublished_questions', (
    select count(*) from bank_questions
    where status <> 'published' or not active
  ),
  'unpublished_by_origin_and_status', (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'origin', bank_origin,
          'status', status,
          'active', active,
          'questions', questions
        )
        order by bank_origin, status, active
      ),
      '[]'::jsonb
    )
    from (
      select bank_origin, status, active, count(*) as questions
      from bank_questions
      where status <> 'published' or not active
      group by bank_origin, status, active
    ) grouped
  ),
  'unpublished_legacy_ids', (
    select coalesce(jsonb_agg(legacy_id order by legacy_id), '[]'::jsonb)
    from bank_questions
    where status <> 'published' or not active
  ),
  'choice_count_distribution', (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'origin', bank_origin,
          'choices', choices,
          'questions', questions
        )
        order by bank_origin, choices
      ),
      '[]'::jsonb
    )
    from (
      select bank_origin, choices, count(*) as questions
      from choice_counts
      group by bank_origin, choices
    ) grouped
  ),
  'questions_without_four_choices_by_origin', (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'origin', bank_origin,
          'questions', questions
        )
        order by bank_origin
      ),
      '[]'::jsonb
    )
    from (
      select bank_origin, count(*) as questions
      from choice_counts
      where choices <> 4
      group by bank_origin
    ) grouped
  ),
  'questions_without_one_correct_choice', (
    select count(*) from choice_counts where correct_choices <> 1
  ),
  'empty_legacy_micro_skills', (
    select count(*) from micro_skill_counts
    where questions = 0 and code like 'legacy_%'
  ),
  'empty_non_legacy_micro_skills', (
    select count(*) from micro_skill_counts
    where questions = 0 and code not like 'legacy_%'
  ),
  'empty_legacy_micro_skill_codes', (
    select coalesce(jsonb_agg(code order by code), '[]'::jsonb)
    from micro_skill_counts
    where questions = 0 and code like 'legacy_%'
  )
) as verification;