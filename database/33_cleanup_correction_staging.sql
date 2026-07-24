/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/33_cleanup_correction_staging.sql
 Purpose      : Remove the protected correction staging table after verification.
===============================================================================
*/

drop table if exists public._cap_college_correction_payload;
