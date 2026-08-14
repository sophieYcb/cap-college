/*
 CAP-COLLEGE DATABASE
 File: database/288_verify_mathematics_5e_atomic_referential.sql
 Purpose: Verify the atomic Mathematics 5e referential.
 Read-only: Yes.
*/

with expected_domains(code, expected_micro_skills) as (
  values
    ('cycle4_numbers_calculation', 42),
    ('cycle4_space_geometry', 30),
    ('cycle4_data_probability', 10),
    ('cycle4_proportionality_functions', 12),
    ('cycle4_computational_thinking', 6)
),
expected_skills(code, expected_micro_skills) as (
  values
    ('m5_operations', 11),
    ('m5_relative_numbers', 9),
    ('m5_rational_numbers', 6),
    ('m5_powers', 5),
    ('m5_algebra', 11),
    ('m5_coordinate_geometry', 3),
    ('m5_space_representation', 7),
    ('m5_transformations', 2),
    ('m5_angles', 3),
    ('m5_triangles', 7),
    ('m5_parallelograms', 8),
    ('m5_statistics', 6),
    ('m5_probability', 4),
    ('m5_proportionality', 7),
    ('m5_functions', 5),
    ('m5_computational_thinking', 6)
),
target_domains as (
  select domain.id, domain.code, domain.name
  from public.domains domain
  join public.subjects subject on subject.id = domain.subject_id
  join expected_domains expected on expected.code = domain.code
  where subject.code = 'mathematics'
    and domain.active
),
target_skills as (
  select skill.id, skill.code, skill.name, domain.code as domain_code
  from public.skills skill
  join target_domains domain on domain.id = skill.domain_id
  where skill.active
),
target_micro_skills as (
  select
    micro_skill.id,
    micro_skill.code,
    micro_skill.teacher_name,
    micro_skill.student_name,
    skill.code as skill_code,
    skill.domain_code
  from public.micro_skills micro_skill
  join target_skills skill on skill.id = micro_skill.skill_id
  where micro_skill.active
    and micro_skill.code like 'm5\_%' escape '\'
),
linked_to_5e as (
  select distinct link.micro_skill_id
  from public.micro_skill_levels link
  join public.levels level on level.id = link.level_id
  where level.code = '5e'
    and link.is_expected
),
linked_to_other_levels as (
  select distinct link.micro_skill_id
  from public.micro_skill_levels link
  join public.levels level on level.id = link.level_id
  where level.code <> '5e'
    and link.is_expected
),
domain_counts as (
  select
    expected.code,
    expected.expected_micro_skills,
    count(micro_skill.id)::integer as actual_micro_skills
  from expected_domains expected
  left join target_micro_skills micro_skill on micro_skill.domain_code = expected.code
  group by expected.code, expected.expected_micro_skills
),
skill_counts as (
  select
    expected.code,
    expected.expected_micro_skills,
    count(micro_skill.id)::integer as actual_micro_skills
  from expected_skills expected
  left join target_micro_skills micro_skill on micro_skill.skill_code = expected.code
  group by expected.code, expected.expected_micro_skills
)
select jsonb_build_object(
  'categories', (select count(*) from target_domains),
  'subcategories', (select count(*) from target_skills),
  'micro_skills', (select count(*) from target_micro_skills),
  'linked_to_5e', (
    select count(*)
    from target_micro_skills micro_skill
    join linked_to_5e link on link.micro_skill_id = micro_skill.id
  ),
  'incorrectly_linked_to_other_levels', (
    select count(*)
    from target_micro_skills micro_skill
    join linked_to_other_levels link on link.micro_skill_id = micro_skill.id
  ),
  'questions', (
    select count(*)
    from public.questions question
    join target_micro_skills micro_skill on micro_skill.id = question.micro_skill_id
  ),
  'categories_with_expected_count', (
    select count(*) from domain_counts
    where actual_micro_skills = expected_micro_skills
  ),
  'subcategories_with_expected_count', (
    select count(*) from skill_counts
    where actual_micro_skills = expected_micro_skills
  ),
  'by_category', (
    select jsonb_agg(
      jsonb_build_object(
        'code', code,
        'micro_skills', actual_micro_skills,
        'expected', expected_micro_skills
      ) order by code
    )
    from domain_counts
  ),
  'by_subcategory', (
    select jsonb_agg(
      jsonb_build_object(
        'code', code,
        'micro_skills', actual_micro_skills,
        'expected', expected_micro_skills
      ) order by code
    )
    from skill_counts
  ),
  'audit_passed', (
    (select count(*) = 5 from target_domains)
    and (select count(*) = 16 from target_skills)
    and (select count(*) = 100 from target_micro_skills)
    and (select count(*) = 100
         from target_micro_skills micro_skill
         join linked_to_5e link on link.micro_skill_id = micro_skill.id)
    and not exists (select 1 from domain_counts where actual_micro_skills <> expected_micro_skills)
    and not exists (select 1 from skill_counts where actual_micro_skills <> expected_micro_skills)
    and not exists (
      select 1
      from target_micro_skills
      where nullif(btrim(teacher_name), '') is null
         or nullif(btrim(student_name), '') is null
    )
  )
) as verification;
