select jsonb_build_object(
  'progress_function', to_regprocedure('public.get_learner_diagnostic_progress(text)') is not null,
  'interrupted_answers_preserved', pg_get_functiondef('public.get_learner_diagnostic_progress(text)'::regprocedure) not like '%ds.status <> ''cancelled''%'
) as verification;
