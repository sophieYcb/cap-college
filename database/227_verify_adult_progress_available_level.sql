select jsonb_build_object(
  'progress_function',
    to_regprocedure('public.get_my_learner_progress()') is not null,
  'uses_available_diagnostic_level',
    pg_get_functiondef(
      'public.get_my_learner_progress()'::regprocedure
    ) like '%diagnostic_level.code = ''6e''%'
) as verification;
