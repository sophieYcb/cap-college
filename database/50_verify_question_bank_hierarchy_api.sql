select jsonb_build_object(
  'published_bank_hierarchy_ready',
    position('subjectCode' in pg_get_functiondef(
      'public.get_published_question_bank()'::regprocedure
    )) > 0,
  'validation_bank_hierarchy_ready',
    position('subjectCode' in pg_get_functiondef(
      'public.get_validation_question_bank()'::regprocedure
    )) > 0
) as verification;
