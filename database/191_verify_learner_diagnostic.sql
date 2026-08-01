select jsonb_build_object(
  'learner_profile_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'diagnostics'
      and column_name = 'learner_profile_id'
  ),
  'owner_constraint', exists (
    select 1 from pg_constraint where conname = 'diagnostics_single_owner'
      and conrelid = 'public.diagnostics'::regclass
  ),
  'history_function', to_regprocedure(
    'public.get_learner_diagnostic_history(text)'
  ) is not null,
  'start_function', to_regprocedure(
    'public.start_learner_diagnostic_session(text,smallint,text,text,text)'
  ) is not null,
  'answer_function', to_regprocedure(
    'public.submit_learner_diagnostic_answer(text,uuid,uuid,uuid,integer)'
  ) is not null,
  'finish_function', to_regprocedure(
    'public.finish_learner_diagnostic_session(text,uuid)'
  ) is not null,
  'active_session_function', to_regprocedure(
    'public.get_learner_active_diagnostic_session(text)'
  ) is not null,
  'skill_profile_function', to_regprocedure(
    'public.get_learner_skill_profile(text)'
  ) is not null
) as verification;