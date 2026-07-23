/*
===============================================================================
 CAP-COLLEGE DATABASE — DIAGNOSTIC RESUME CHECK
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 27_resume_diagnostic_api.sql
 Purpose      : Verify that a saved session still belongs to the user and is active.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_my_diagnostic_session_state(
  requested_session_id uuid
)
returns table (
  session_status public.session_status,
  recorded_answers integer
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    ds.status,
    count(di.id)::integer
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  left join public.diagnostic_items di
    on di.session_id = ds.id
   and di.answered_at is not null
  where ds.id = requested_session_id
    and d.student_id = auth.uid()
  group by ds.id, ds.status;
$function$;

revoke all on function public.get_my_diagnostic_session_state(uuid)
  from public;
grant execute on function public.get_my_diagnostic_session_state(uuid)
  to authenticated;

commit;

