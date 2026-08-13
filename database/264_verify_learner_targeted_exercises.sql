select jsonb_build_object(
  'learner_profile_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'remediation_sessions'
      and column_name = 'learner_profile_id'
  ),
  'question_target_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'remediation_sessions'
      and column_name = 'question_target'
  ),
  'owner_constraint', exists (
    select 1 from pg_constraint
    where conname = 'remediation_sessions_single_owner'
      and conrelid = 'public.remediation_sessions'::regclass
  ),
  'learner_bank_function', to_regprocedure(
    'public.get_learner_remediation_question_bank(text,text)'
  ) is not null,
  'learner_start_function', to_regprocedure(
    'public.start_learner_remediation_session(text,text,smallint)'
  ) is not null,
  'learner_answer_function', to_regprocedure(
    'public.submit_learner_remediation_answer(text,uuid,uuid,uuid,public.assistance_mode,integer)'
  ) is not null,
  'learner_finish_function', to_regprocedure(
    'public.finish_learner_remediation_session(text,uuid)'
  ) is not null,
  'parent_history_function', to_regprocedure(
    'public.get_my_learner_remediation_history(uuid)'
  ) is not null,
  'parent_history_checks_link', position(
    'learner_profile_adults'
    in pg_get_functiondef(
      'public.get_my_learner_remediation_history(uuid)'::regprocedure
    )
  ) > 0
) as verification;
