select jsonb_build_object(
  'progress_function',
    to_regprocedure('public.get_my_learner_progress()') is not null,
  'authenticated_can_execute',
    has_function_privilege(
      'authenticated',
      'public.get_my_learner_progress()',
      'EXECUTE'
    ),
  'learner_links_table', to_regclass(
    'public.learner_profile_adults'
  ) is not null,
  'diagnostics_table', to_regclass('public.diagnostics') is not null
) as verification;
