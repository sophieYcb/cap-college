select jsonb_build_object(
  'finish_function', to_regprocedure(
    'public.finish_learner_diagnostic_session(text,uuid)'
  ) is not null,
  'reports_function', to_regprocedure(
    'public.get_my_learner_diagnostic_reports(uuid)'
  ) is not null,
  'result_snapshot_column', exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'diagnostics'
      and column_name = 'result_snapshot'
  ),
  'finish_uses_selected_subject', position(
    'get_learner_subject_diagnostic_progress'
    in pg_get_functiondef(
      'public.finish_learner_diagnostic_session(text,uuid)'::regprocedure
    )
  ) > 0,
  'reports_check_adult_link', position(
    'learner_profile_adults'
    in pg_get_functiondef(
      'public.get_my_learner_diagnostic_reports(uuid)'::regprocedure
    )
  ) > 0,
  'authenticated_can_read_reports', has_function_privilege(
    'authenticated',
    'public.get_my_learner_diagnostic_reports(uuid)',
    'EXECUTE'
  )
) as verification;
