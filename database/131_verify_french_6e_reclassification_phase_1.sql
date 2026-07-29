/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/131_verify_french_6e_reclassification_phase_1.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify phase 1 of the French 6e reclassification.
 Read-only    : Yes
===============================================================================
*/

with french_questions as (
  select
    q.id,
    q.legacy_id,
    q.status,
    ms.code as micro_skill_code,
    ms.teacher_name as micro_skill_name
  from public.questions q
  join public.micro_skills ms on ms.id = q.micro_skill_id
  where q.legacy_id between 1 and 590
),
atomic_counts as (
  select
    micro_skill_code,
    micro_skill_name,
    count(*) as question_count
  from french_questions
  where micro_skill_code like 'f6\_%' escape '\'
  group by micro_skill_code, micro_skill_name
),
legacy_counts as (
  select
    micro_skill_code,
    micro_skill_name,
    count(*) as question_count
  from french_questions
  where micro_skill_code like 'legacy\_%' escape '\'
  group by micro_skill_code, micro_skill_name
)
select jsonb_build_object(
  'questions', (select count(*) from french_questions),
  'reclassified_questions', (
    select count(*) from french_questions
    where micro_skill_code like 'f6\_%' escape '\'
  ),
  'remaining_legacy_questions', (
    select count(*) from french_questions
    where micro_skill_code like 'legacy\_%' escape '\'
  ),
  'atomic_micro_skills_with_questions', (select count(*) from atomic_counts),
  'atomic_micro_skills_below_10', (
    select count(*) from atomic_counts where question_count < 10
  ),
  'remaining_legacy_groups', (
    select jsonb_object_agg(micro_skill_name, question_count)
    from legacy_counts
  ),
  'examples_of_atomic_distribution', (
    select jsonb_object_agg(micro_skill_name, question_count)
    from atomic_counts
  )
) as verification;
