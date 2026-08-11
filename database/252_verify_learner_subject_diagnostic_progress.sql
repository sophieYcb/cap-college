select jsonb_build_object(
  'subject_progress_function',
    to_regprocedure(
      'public.get_learner_subject_diagnostic_progress(text,text)'
    ) is not null,
  'anonymous_can_execute', has_function_privilege(
    'anon',
    'public.get_learner_subject_diagnostic_progress(text,text)',
    'execute'
  ),
  'authenticated_can_execute', has_function_privilege(
    'authenticated',
    'public.get_learner_subject_diagnostic_progress(text,text)',
    'execute'
  ),
  'filters_requested_subject', position(
    'subject.code = requested_subject_code' in
    pg_get_functiondef(
      'public.get_learner_subject_diagnostic_progress(text,text)'::regprocedure
    )
  ) > 0
) as verification;
