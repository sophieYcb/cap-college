/*
 CAP-COLLEGE DATABASE
 File: database/208_verify_reliable_progressive_learner_diagnostic.sql
 Purpose: Verify the reliable progressive learner diagnostic API.
 Read-only: Yes
*/

select jsonb_build_object(
  'result_snapshot_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'diagnostics'
      and column_name = 'result_snapshot'
  ),
  'completion_rule_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'diagnostics'
      and column_name = 'completion_rule_version'
  ),
  'progress_function', to_regprocedure(
    'public.get_learner_diagnostic_progress(text)'
  ) is not null,
  'finish_function', to_regprocedure(
    'public.finish_learner_diagnostic_session(text,uuid)'
  ) is not null
) as verification;