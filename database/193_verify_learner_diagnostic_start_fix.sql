select jsonb_build_object(
  'start_function_found', to_regprocedure(
    'public.start_learner_diagnostic_session(text,smallint,text,text,text)'
  ) is not null,
  'column_conflict_rule_applied', exists (
    select 1
    from pg_proc procedure
    join pg_namespace namespace on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'public'
      and procedure.proname = 'start_learner_diagnostic_session'
      and procedure.prosrc like '%#variable_conflict use_column%'
  )
) as verification;