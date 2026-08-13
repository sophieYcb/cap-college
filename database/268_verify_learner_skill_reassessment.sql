select jsonb_build_object(
  'session_kind_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'remediation_sessions'
      and column_name = 'session_kind'
  ),
  'reassessment_result_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'remediation_sessions'
      and column_name = 'reassessment_passed'
  ),
  'readiness_function', to_regprocedure(
    'public.get_learner_reassessment_readiness(text,text)'
  ) is not null,
  'start_reassessment_function', to_regprocedure(
    'public.start_learner_reassessment_session(text,text)'
  ) is not null,
  'finish_v2_function', to_regprocedure(
    'public.finish_learner_remediation_session_v2(text,uuid)'
  ) is not null,
  'parent_history_v2_function', to_regprocedure(
    'public.get_my_learner_remediation_history_v2(uuid)'
  ) is not null,
  'requires_fifteen_answers', position(
    'practice_answers >= 15'
    in pg_get_functiondef(
      'public.get_learner_reassessment_readiness(text,text)'::regprocedure
    )
  ) > 0,
  'requires_three_sessions', position(
    'practice_sessions >= 3'
    in pg_get_functiondef(
      'public.get_learner_reassessment_readiness(text,text)'::regprocedure
    )
  ) > 0,
  'requires_no_help_successes', position(
    'without_reminder_successes >= 5'
    in pg_get_functiondef(
      'public.get_learner_reassessment_readiness(text,text)'::regprocedure
    )
  ) > 0,
  'passes_at_four_of_five', position(
    'counted_answers = 5 and counted_correct >= 4'
    in pg_get_functiondef(
      'public.finish_learner_remediation_session_v2(text,uuid)'::regprocedure
    )
  ) > 0
) as verification;
