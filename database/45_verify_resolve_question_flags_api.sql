/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY RESOLVE QUESTION FLAGS API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/45_verify_resolve_question_flags_api.sql
 Purpose      : Read-only verification of flag resolution support.
===============================================================================
*/

select jsonb_build_object(
  'resolve_question_flags_api_ready',
  to_regprocedure('public.resolve_question_flags(uuid,text)') is not null,
  'open_flags',
  (
    select count(*)
    from public.question_flags qf
    where qf.status in ('open', 'in_progress')
  ),
  'resolved_flags',
  (
    select count(*)
    from public.question_flags qf
    where qf.status = 'resolved'
  )
) as verification;
