/*
===============================================================================
 CAP-COLLEGE DATABASE — IMPORT CLEANUP
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 13_cleanup_import_staging.sql
 Purpose      : Remove the protected staging table after successful verification.
 Dependencies : Successful 12_verify_french_6e_import.sql result
===============================================================================
*/

drop table if exists public._cap_college_import_payload;
