/*
 CAP-COLLEGE DATABASE
 File: database/247_audit_maths_6e_diagnostic_coverage.sql
 Purpose: Audit published maths 6e coverage used by the learner diagnostic.
 Read-only: Yes
*/

with maths_questions as (
  select
    q.id,
    q.legacy_id,
    q.status,
    q.active,
    q.micro_skill_id
  from public.questions q
  join public.micro_skills ms on ms.id = q.micro_skill_id
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  where s.code = 'mathematics'
),
expected_skills as (
  select
    ms.id,
    ms.code,
    ms.student_name
  from public.micro_skill_levels msl
  join public.micro_skills ms on ms.id = msl.micro_skill_id
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  join public.levels l on l.id = msl.level_id
  where s.code = 'mathematics'
    and l.code = '6e'
    and msl.is_expected
    and ms.active
),
coverage as (
  select
    es.id,
    es.code,
    es.student_name,
    count(mq.id) filter (
      where mq.status = 'published' and mq.active
    )::integer as published_questions
  from expected_skills es
  left join maths_questions mq on mq.micro_skill_id = es.id
  group by es.id, es.code, es.student_name
)
select jsonb_build_object(
  'total_mathematics_questions', (select count(*) from maths_questions),
  'published_mathematics_questions', (
    select count(*) from maths_questions
    where status = 'published' and active
  ),
  'questions_in_review', (
    select count(*) from maths_questions where status = 'in_review'
  ),
  'expected_micro_skills', (select count(*) from expected_skills),
  'expected_micro_skills_with_published_questions', (
    select count(*) from coverage where published_questions > 0
  ),
  'expected_micro_skills_without_published_questions', (
    select count(*) from coverage where published_questions = 0
  ),
  'missing_micro_skill_codes', coalesce(
    (select jsonb_agg(code order by code)
     from coverage where published_questions = 0),
    '[]'::jsonb
  ),
  'unpublished_legacy_ids', coalesce(
    (select jsonb_agg(legacy_id order by legacy_id)
     from maths_questions
     where status <> 'published' or not active),
    '[]'::jsonb
  )
) as verification;
