select jsonb_build_object(
  'mathematics_available', exists (
    select 1 from public.subjects
    where code = 'mathematics' and active
  ),
  'published_mathematics_questions', (
    select count(*)
    from public.questions q
    join public.micro_skills ms on ms.id = q.micro_skill_id
    join public.skills sk on sk.id = ms.skill_id
    join public.domains d on d.id = sk.domain_id
    join public.subjects s on s.id = d.subject_id
    where s.code = 'mathematics'
      and q.status = 'published'
      and q.active
  ),
  'expected_mathematics_micro_skills', (
    select count(*)
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
  )
) as verification;
