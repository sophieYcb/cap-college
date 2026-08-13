select jsonb_build_object(
  'snapshot_builder', to_regprocedure(
    'public.build_learner_diagnostic_snapshot(uuid)'
  ) is not null,
  'finish_uses_diagnostic_id', position(
    'build_learner_diagnostic_snapshot(selected_diagnostic_id)'
    in pg_get_functiondef(
      'public.finish_learner_diagnostic_session(text,uuid)'::regprocedure
    )
  ) > 0,
  'completed_reports_missing', (
    select count(*)
    from public.diagnostics
    where status = 'completed' and result_snapshot is null
  ),
  'sophie_maths_report_saved', exists (
    select 1
    from public.diagnostics diagnostic
    join public.learner_profiles profile
      on profile.id = diagnostic.learner_profile_id
    join public.subjects subject on subject.id = diagnostic.subject_id
    where lower(profile.display_name) = 'sophie'
      and subject.code = 'mathematics'
      and diagnostic.status = 'completed'
      and diagnostic.result_snapshot is not null
      and coalesce(
        (diagnostic.result_snapshot ->> 'diagnosisReady')::boolean,
        false
      )
  )
) as verification;
