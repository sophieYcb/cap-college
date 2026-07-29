/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/127_audit_french_6e_coverage.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Audit current French 6e coverage before curriculum refactoring.
 Read-only    : Yes
 Reference    : BO n° 16 du 17 avril 2025, programme de français du cycle 3.
===============================================================================
*/

with french_6e_questions as (
  select
    q.id,
    q.status,
    q.active,
    q.current_version_number,
    ms.id as micro_skill_id,
    ms.code as micro_skill_code,
    ms.teacher_name as micro_skill_name,
    sk.id as skill_id,
    sk.code as skill_code,
    sk.name as skill_name,
    d.id as domain_id,
    d.code as domain_code,
    d.name as domain_name
  from public.questions q
  join public.micro_skills ms on ms.id = q.micro_skill_id
  join public.micro_skill_levels msl
    on msl.micro_skill_id = ms.id
   and msl.is_expected
  join public.levels l
    on l.id = msl.level_id
   and l.code = '6e'
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s
    on s.id = d.subject_id
   and s.code = 'french'
  where q.legacy_id between 1 and 590
),
micro_skill_counts as (
  select
    domain_code,
    domain_name,
    skill_code,
    skill_name,
    micro_skill_code,
    micro_skill_name,
    count(*) as question_count,
    count(*) filter (where status = 'published' and active) as published_count,
    count(*) filter (where status = 'in_review') as in_review_count
  from french_6e_questions
  group by
    domain_code,
    domain_name,
    skill_code,
    skill_name,
    micro_skill_code,
    micro_skill_name
),
domain_counts as (
  select
    domain_code,
    domain_name,
    count(distinct micro_skill_code) as micro_skill_count,
    sum(question_count) as question_count,
    min(question_count) as smallest_micro_skill,
    max(question_count) as largest_micro_skill
  from micro_skill_counts
  group by domain_code, domain_name
)
select jsonb_build_object(
  'official_reference',
  'BO n° 16 du 17 avril 2025 — programme de français du cycle 3, applicable en 6e depuis 2025-2026',
  'questions', (select count(*) from french_6e_questions),
  'published_questions', (
    select count(*) from french_6e_questions
    where status = 'published' and active
  ),
  'micro_skills', (select count(*) from micro_skill_counts),
  'micro_skills_with_10_questions', (
    select count(*) from micro_skill_counts where question_count = 10
  ),
  'micro_skills_with_20_questions', (
    select count(*) from micro_skill_counts where question_count = 20
  ),
  'other_question_counts', (
    select count(*) from micro_skill_counts where question_count not in (10, 20)
  ),
  'domains', (
    select jsonb_agg(
      jsonb_build_object(
        'code', domain_code,
        'name', domain_name,
        'micro_skills', micro_skill_count,
        'questions', question_count,
        'minimum', smallest_micro_skill,
        'maximum', largest_micro_skill
      )
      order by domain_name
    )
    from domain_counts
  ),
  'detail', (
    select jsonb_agg(
      jsonb_build_object(
        'domain', domain_name,
        'skill', skill_name,
        'code', micro_skill_code,
        'micro_skill', micro_skill_name,
        'questions', question_count,
        'published', published_count,
        'in_review', in_review_count
      )
      order by domain_name, skill_name, micro_skill_name
    )
    from micro_skill_counts
  )
) as verification;
