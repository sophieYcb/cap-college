/*
 CAP-COLLEGE DATABASE
 File: database/206_verify_french_6e_legacy_micro_skills_cleanup.sql
 Purpose: Verify the French 6e referential cleanup.
 Read-only: Yes
*/

with french_6e_micro_skills as (
  select
    ms.id,
    ms.code,
    msl.is_expected
  from public.micro_skill_levels msl
  join public.micro_skills ms on ms.id = msl.micro_skill_id
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  join public.levels l on l.id = msl.level_id
  where s.code = 'french'
    and l.code = '6e'
    and ms.active
)
select jsonb_build_object(
  'expected_micro_skills', (
    select count(*) from french_6e_micro_skills where is_expected
  ),
  'expected_legacy_micro_skills', (
    select count(*) from french_6e_micro_skills
    where is_expected and code like 'legacy_%'
  ),
  'archived_legacy_micro_skills', (
    select count(*) from french_6e_micro_skills
    where not is_expected and code like 'legacy_%'
  ),
  'questions_referencing_legacy_micro_skills', (
    select count(*)
    from public.questions q
    join public.micro_skills ms on ms.id = q.micro_skill_id
    where ms.code like 'legacy_%'
  )
) as verification;