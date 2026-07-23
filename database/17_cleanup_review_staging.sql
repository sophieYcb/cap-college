/*
===============================================================================
 CAP-COLLEGE DATABASE — REVIEW IMPORT CLEANUP
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 17_cleanup_review_staging.sql
 Purpose      : Remove the protected review-import staging table.
 Dependencies : Successful 16_verify_quality_reviews.sql result
===============================================================================
*/

drop table if exists public._cap_college_review_import_payload;
