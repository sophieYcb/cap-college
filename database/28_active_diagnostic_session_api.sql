/*
===============================================================================
 CAP-COLLEGE DATABASE — ACTIVE DIAGNOSTIC DISCOVERY
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 28_active_diagnostic_session_api.sql
 Purpose      : Resume from Supabase when the browser has no local backup.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_my_active_diagnostic_session()
returns table (
  diagnostic_id uuid,
  session_id uuid,
  planned_minutes smallint,
  recorded_answers integer
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    d.id,
    ds.id,
    ds.planned_minutes,
    count(di.id)::integer
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  left join public.diagnostic_items di
    on di.session_id = ds.id
   and di.answered_at is not null
  where d.student_id = auth.uid()
    and d.status = 'active'
    and ds.status = 'active'
  group by d.id, ds.id, ds.planned_minutes, ds.started_at
  order by ds.started_at desc
  limit 1;
$function$;

revoke all on function public.get_my_active_diagnostic_session() from public;
grant execute on function public.get_my_active_diagnostic_session()
  to authenticated;

commit;

