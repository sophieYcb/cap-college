/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/133_verify_french_6e_reclassification_complete.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify complete French 6e atomic reclassification.
 Read-only    : Yes
===============================================================================
*/

with french_questions as (
  select q.id, q.legacy_id, q.status, ms.code, ms.teacher_name
  from public.questions q
  join public.micro_skills ms on ms.id = q.micro_skill_id
  where q.legacy_id between 1 and 590
),
atomic_counts as (
  select code, teacher_name, count(*) as question_count
  from french_questions
  where code like 'f6\_%' escape '\'
  group by code, teacher_name
),
all_atomic as (
  select ms.code, ms.teacher_name
  from public.micro_skills ms
  join public.micro_skill_levels msl on msl.micro_skill_id = ms.id
  join public.levels l on l.id = msl.level_id and l.code = '6e'
  where ms.code like 'f6\_%' escape '\'
    and msl.is_expected
)
select jsonb_build_object(
  'questions', (select count(*) from french_questions),
  'reclassified_questions', (
    select count(*) from french_questions
    where code like 'f6\_%' escape '\'
  ),
  'remaining_legacy_questions', (
    select count(*) from french_questions
    where code like 'legacy\_%' escape '\'
  ),
  'atomic_micro_skills', (select count(*) from all_atomic),
  'atomic_micro_skills_with_questions', (select count(*) from atomic_counts),
  'atomic_micro_skills_without_questions', (
    select count(*)
    from all_atomic a
    left join atomic_counts c on c.code = a.code
    where c.code is null
  ),
  'atomic_micro_skills_below_10', (
    select count(*) from atomic_counts where question_count < 10
  ),
  'questions_needed_to_reach_10', (
    select coalesce(sum(greatest(10 - coalesce(c.question_count, 0), 0)), 0)
    from all_atomic a
    left join atomic_counts c on c.code = a.code
  ),
  'incomplete_micro_skills', (
    select jsonb_object_agg(a.teacher_name, coalesce(c.question_count, 0))
    from all_atomic a
    left join atomic_counts c on c.code = a.code
    where coalesce(c.question_count, 0) < 10
  )
) as verification;
