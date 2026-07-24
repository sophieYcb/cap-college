/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 File         : database/39_verify_validation_diagnostic_isolation.sql
 Purpose      : Verify validation-session APIs and isolation filters.
 Read only    : Yes
===============================================================================
*/

select
  to_regprocedure(
    'public.start_validation_diagnostic_session(uuid,smallint,text,text,text)'
  ) is not null as validation_start_ready,
  to_regprocedure(
    'public.get_my_validation_diagnostic_history(uuid)'
  ) is not null as validation_history_ready,
  to_regprocedure(
    'public.get_my_active_validation_session(uuid)'
  ) is not null as validation_resume_ready,
  position(
    'VALIDATION_CAMPAIGN_ID IS NULL' in
    upper(pg_get_functiondef(
      'public.get_my_diagnostic_history()'::regprocedure
    ))
  ) > 0 as normal_history_isolated,
  position(
    'VALIDATION_CAMPAIGN_ID IS NULL' in
    upper(pg_get_functiondef(
      'public.get_my_skill_profile()'::regprocedure
    ))
  ) > 0 as skill_profile_isolated,
  position(
    'VALIDATION_CAMPAIGN_ID IS NULL' in
    upper(pg_get_functiondef(
      'public.get_my_error_notebook()'::regprocedure
    ))
  ) > 0 as error_notebook_isolated;
