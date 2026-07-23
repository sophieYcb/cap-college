/*
===============================================================================
 CAP-COLLEGE DATABASE — APPLICATION API VERIFICATION
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 19_verify_application_api.sql
 Purpose      : Verify the browser API after running 18_application_api.sql.
 Read-only    : Yes
===============================================================================
*/

select
  to_regprocedure('public.get_my_roles()') is not null
    as roles_api_ready,
  to_regprocedure('public.get_published_question_bank()') is not null
    as question_bank_api_ready,
  to_regprocedure(
    'public.start_diagnostic_session(smallint,text,text)'
  ) is not null as diagnostic_start_api_ready,
  to_regprocedure(
    'public.submit_diagnostic_answer(uuid,uuid,uuid,integer)'
  ) is not null as answer_api_ready,
  jsonb_array_length(public.get_published_question_bank())
    as published_questions_available,
  public.get_my_roles()
    as my_roles;

