select jsonb_build_object('verification', jsonb_build_object(
  'reviews_table', to_regclass('public.course_summary_reviews') is not null,
  'list_function', to_regprocedure('public.get_validation_course_summaries()') is not null,
  'save_function', to_regprocedure('public.save_course_summary_review(uuid,text,text,text)') is not null,
  'expected_6e_micro_skills', (
    select count(distinct msl.micro_skill_id) from public.micro_skill_levels msl
    join public.levels l on l.id = msl.level_id
    join public.micro_skills ms on ms.id = msl.micro_skill_id
    where l.code = '6e' and l.active and msl.is_expected and ms.active
  ),
  'authenticated_can_list', has_function_privilege('authenticated', 'public.get_validation_course_summaries()', 'execute'),
  'authenticated_can_save', has_function_privilege('authenticated', 'public.save_course_summary_review(uuid,text,text,text)', 'execute')
)) as verification;
