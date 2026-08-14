select jsonb_build_object('verification', jsonb_build_object(
  'list_function', to_regprocedure('public.get_validation_course_summaries()') is not null,
  'returns_previous_content', position('''previous''' in pg_get_functiondef(
    'public.get_validation_course_summaries()'::regprocedure)) > 0,
  'returns_previous_review', position('previous_review' in pg_get_functiondef(
    'public.get_validation_course_summaries()'::regprocedure)) > 0,
  'micro_skills_with_resource_history', (
    select count(*) from (
      select micro_skill_id from public.learning_resources
      group by micro_skill_id having count(*) > 1
    ) history
  ),
  'authenticated_can_list', has_function_privilege(
    'authenticated', 'public.get_validation_course_summaries()', 'execute'
  )
)) as verification;
