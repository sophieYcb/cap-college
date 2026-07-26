/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY OPEN QUESTION FLAGS API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/43_verify_open_question_flags_api.sql
 Purpose      : Read-only verification of flag comment retrieval.
===============================================================================
*/

select jsonb_build_object(
  'open_question_flags_api_ready',
  to_regprocedure('public.get_open_question_flags()') is not null,
  'open_flags_with_comments',
  (
    select count(*)
    from public.question_flags qf
    where qf.status in ('open', 'in_progress')
      and nullif(btrim(qf.comment), '') is not null
  )
) as verification;
