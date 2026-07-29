/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/129_verify_french_6e_atomic_referential.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify the atomic French 6e language referential.
 Read-only    : Yes
===============================================================================
*/

with target_skills as (
  select sk.id, sk.code, sk.name, d.code as domain_code, d.name as domain_name
  from public.skills sk
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id and s.code = 'french'
  where sk.code like 'f6\_%' escape '\'
),
target_micro_skills as (
  select
    ms.id,
    ms.code,
    ms.teacher_name,
    ts.domain_code,
    ts.domain_name,
    ts.code as skill_code
  from public.micro_skills ms
  join target_skills ts on ts.id = ms.skill_id
),
linked_levels as (
  select distinct msl.micro_skill_id
  from public.micro_skill_levels msl
  join public.levels l on l.id = msl.level_id
  where l.code = '6e' and msl.is_expected
)
select jsonb_build_object(
  'skills', (select count(*) from target_skills),
  'micro_skills', (select count(*) from target_micro_skills),
  'linked_to_6e', (
    select count(*)
    from target_micro_skills ms
    join linked_levels ll on ll.micro_skill_id = ms.id
  ),
  'existing_questions_reassigned', (
    select count(*)
    from public.questions q
    join target_micro_skills ms on ms.id = q.micro_skill_id
    where q.legacy_id between 1 and 590
  ),
  'by_domain', (
    select jsonb_object_agg(domain_name, micro_skill_count)
    from (
      select domain_name, count(*) as micro_skill_count
      from target_micro_skills
      group by domain_name
      order by domain_name
    ) counts
  )
) as verification;
