select jsonb_build_object(
  'exercise_progress_function', to_regprocedure(
    'public.get_learner_exercise_progress(text,text)'
  ) is not null,
  'returns_reassessment_score', position(
    '''reassessmentScore'''
    in pg_get_functiondef(
      'public.get_learner_exercise_progress(text,text)'::regprocedure
    )
  ) > 0,
  'counts_reassessment_answers', position(
    'reassessment_answers'
    in pg_get_functiondef(
      'public.get_learner_exercise_progress(text,text)'::regprocedure
    )
  ) > 0
) as verification;
