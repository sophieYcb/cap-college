select jsonb_build_object(
  'start_v2_function', to_regprocedure(
    'public.start_learner_remediation_session_v2(text,text,smallint)'
  ) is not null,
  'reads_previous_attempts', position(
    'remediation_attempts'
    in pg_get_functiondef(
      'public.start_learner_remediation_session_v2(text,text,smallint)'::regprocedure
    )
  ) > 0,
  'scoped_to_same_learner', position(
    'previous_session.learner_profile_id = selected_learner_id'
    in pg_get_functiondef(
      'public.start_learner_remediation_session_v2(text,text,smallint)'::regprocedure
    )
  ) > 0,
  'scoped_to_same_micro_skill', position(
    'previous_session.micro_skill_id = selected_micro_skill.id'
    in pg_get_functiondef(
      'public.start_learner_remediation_session_v2(text,text,smallint)'::regprocedure
    )
  ) > 0,
  'anonymous_can_execute', has_function_privilege(
    'anon',
    'public.start_learner_remediation_session_v2(text,text,smallint)',
    'EXECUTE'
  )
) as verification;
