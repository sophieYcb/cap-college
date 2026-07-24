/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 File         : database/37_verify_validation_campaign_management.sql
 Purpose      : Verify that campaign management functions are installed.
 Read only    : Yes
===============================================================================
*/

select
  to_regprocedure('public.get_my_validation_campaigns()') is not null
    as list_campaigns_ready,
  to_regprocedure('public.create_validation_campaign(text,text)') is not null
    as create_campaign_ready,
  to_regprocedure('public.archive_my_validation_campaign(uuid)') is not null
    as archive_campaign_ready,
  to_regprocedure('public.reset_my_validation_campaign(uuid)') is not null
    as reset_campaign_ready,
  to_regprocedure('public.delete_my_validation_campaign(uuid)') is not null
    as delete_campaign_ready;

