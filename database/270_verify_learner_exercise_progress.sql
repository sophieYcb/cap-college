select jsonb_build_object(
  'exercise_progress_function', to_regprocedure(
    'public.get_learner_exercise_progress(text,text)'
  ) is not null,
  'reads_reassessment_result', position(
    'reassessment_passed'
    in pg_get_functiondef(
      'public.get_learner_exercise_progress(text,text)'::regprocedure
    )
  ) > 0,
  'keeps_diagnostic_unchanged', position(
    'diagnostics'
    in pg_get_functiondef(
      'public.get_learner_exercise_progress(text,text)'::regprocedure
    )
  ) = 0,
  'scoped_to_learner', position(
    'session.learner_profile_id = selected_learner_id'
    in pg_get_functiondef(
      'public.get_learner_exercise_progress(text,text)'::regprocedure
    )
  ) > 0,
  'anonymous_can_execute', has_function_privilege(
    'anon',
    'public.get_learner_exercise_progress(text,text)',
    'EXECUTE'
  )
) as verification;
