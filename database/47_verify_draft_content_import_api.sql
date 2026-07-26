/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY DRAFT CONTENT IMPORT API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/47_verify_draft_content_import_api.sql
 Purpose      : Read-only verification of reusable content imports.
===============================================================================
*/

select jsonb_build_object(
  'draft_content_import_api_ready',
  to_regprocedure('public.import_draft_question_lot(jsonb)') is not null,
  'mathematics_subject_ready',
  exists (
    select 1 from public.subjects s
    where s.code = 'mathematics' and s.active
  ),
  'level_6e_ready',
  exists (
    select 1 from public.levels l
    where l.code = '6e' and l.active
  )
) as verification;
