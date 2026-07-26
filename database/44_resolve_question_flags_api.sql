/*
===============================================================================
 CAP-COLLEGE DATABASE - RESOLVE QUESTION FLAGS API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/44_resolve_question_flags_api.sql
 Purpose      : Close open flags after a validator has handled the question,
                while retaining the complete history.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.resolve_question_flags(
  requested_question_id uuid,
  requested_resolution_comment text default null
)
returns table (
  resolved_flags integer,
  resolved_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  affected integer;
  resolution_time timestamptz := statement_timestamp();
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;

  if not exists (
    select 1 from public.questions q where q.id = requested_question_id
  ) then
    raise exception 'Unknown question';
  end if;

  update public.question_flags qf
  set status = 'resolved'::public.flag_status,
      resolved_by = auth.uid(),
      resolved_at = resolution_time,
      resolution_comment = coalesce(
        nullif(btrim(requested_resolution_comment), ''),
        'Question vérifiée dans le mode Validation.'
      )
  where qf.question_id = requested_question_id
    and qf.status in ('open', 'in_progress');

  get diagnostics affected = row_count;
  return query select affected, resolution_time;
end;
$function$;

revoke all on function public.resolve_question_flags(uuid, text) from public;
grant execute on function public.resolve_question_flags(uuid, text)
  to authenticated;

commit;
