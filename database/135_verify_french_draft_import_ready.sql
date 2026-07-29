/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/135_verify_french_draft_import_ready.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify that the draft importer accepts F6 lots.
 Read-only    : Yes
===============================================================================
*/

select jsonb_build_object(
  'draft_import_api_ready',
    to_regprocedure('public.import_draft_question_lot(jsonb)') is not null,
  'french_prefix_ready',
    position(
      'expected_question_prefix := ''F6'''
      in pg_get_functiondef(
        to_regprocedure('public.import_draft_question_lot(jsonb)')
      )
    ) > 0,
  'french_legacy_range_ready',
    position(
      'selected_legacy_base := 1000000'
      in pg_get_functiondef(
        to_regprocedure('public.import_draft_question_lot(jsonb)')
      )
    ) > 0,
  'existing_french_questions',
    (select count(*) from public.questions where legacy_id between 1 and 590),
  'existing_maths_questions',
    (select count(*) from public.questions where legacy_id between 600001 and 699999),
  'new_french_questions',
    (select count(*) from public.questions where legacy_id between 1000001 and 1099999)
) as verification;
