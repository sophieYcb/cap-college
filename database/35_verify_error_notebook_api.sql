/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 File         : database/35_verify_error_notebook_api.sql
 Purpose      : Verify the authenticated student's error notebook API.
 Read only    : Yes
===============================================================================
*/

with notebook as (
  select public.get_my_error_notebook() as payload
), items as (
  select item.resolved
  from notebook
  cross join lateral jsonb_to_recordset(notebook.payload) as item(
    resolved boolean
  )
)
select
  jsonb_array_length((select payload from notebook)) as notebook_entries,
  count(*) filter (where not items.resolved) as errors_to_review,
  count(*) filter (where items.resolved) as resolved_errors
from items;
