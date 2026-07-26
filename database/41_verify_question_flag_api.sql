/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY QUESTION FLAG API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/41_verify_question_flag_api.sql
 Purpose      : Read-only verification of the diagnostic flagging API.
===============================================================================
*/

select jsonb_build_object(
  'question_flag_api_ready',
  to_regprocedure(
    'public.flag_question_for_review(uuid,uuid,uuid,text)'
  ) is not null,
  'question_flags_rls_enabled',
  coalesce((
    select c.relrowsecurity
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'question_flags'
  ), false)
) as verification;
