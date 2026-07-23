/*
===============================================================================
 CAP-COLLEGE DATABASE — PROGRESSIVE SESSION LIFECYCLE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 22_progressive_session_lifecycle.sql
 Purpose      : Reuse a long-lived diagnostic and close each calm work session.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.start_diagnostic_session(
  planned_minutes smallint,
  requested_subject_code text default 'french',
  requested_level_code text default '6e'
)
returns table (diagnostic_id uuid, session_id uuid)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  active_diagnostic_id uuid;
  new_session_id uuid;
  selected_subject_id smallint;
  selected_level_id smallint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if planned_minutes not between 1 and 180 then
    raise exception 'Invalid planned duration';
  end if;

  select id into selected_subject_id
  from public.subjects
  where code = requested_subject_code and active;

  select id into selected_level_id
  from public.levels
  where code = requested_level_code and active;

  if selected_subject_id is null or selected_level_id is null then
    raise exception 'Unknown subject or level';
  end if;

  select d.id into active_diagnostic_id
  from public.diagnostics d
  where d.student_id = auth.uid()
    and d.subject_id = selected_subject_id
    and d.level_id = selected_level_id
    and d.status = 'active'
  order by d.started_at
  limit 1;

  if active_diagnostic_id is null then
    insert into public.diagnostics (student_id, subject_id, level_id)
    values (auth.uid(), selected_subject_id, selected_level_id)
    returning id into active_diagnostic_id;
  else
    update public.diagnostic_sessions ds
    set diagnostic_id = active_diagnostic_id
    where ds.diagnostic_id in (
      select duplicate.id
      from public.diagnostics duplicate
      where duplicate.student_id = auth.uid()
        and duplicate.subject_id = selected_subject_id
        and duplicate.level_id = selected_level_id
        and duplicate.status = 'active'
        and duplicate.id <> active_diagnostic_id
    );

    update public.diagnostics duplicate
    set status = 'abandoned',
        completed_at = coalesce(duplicate.completed_at, statement_timestamp())
    where duplicate.student_id = auth.uid()
      and duplicate.subject_id = selected_subject_id
      and duplicate.level_id = selected_level_id
      and duplicate.status = 'active'
      and duplicate.id <> active_diagnostic_id;
  end if;

  update public.diagnostic_sessions ds
  set status = 'cancelled',
      ended_at = coalesce(ds.ended_at, statement_timestamp())
  where ds.diagnostic_id = active_diagnostic_id
    and ds.status = 'active';

  insert into public.diagnostic_sessions (
    diagnostic_id,
    planned_minutes
  )
  values (active_diagnostic_id, planned_minutes)
  returning id into new_session_id;

  return query select active_diagnostic_id, new_session_id;
end;
$function$;

create or replace function public.finish_diagnostic_session(
  requested_session_id uuid
)
returns table (answer_count integer, correct_count integer)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_diagnostic_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select ds.diagnostic_id into selected_diagnostic_id
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  where ds.id = requested_session_id
    and d.student_id = auth.uid();

  if selected_diagnostic_id is null then
    raise exception 'Session is not available';
  end if;

  update public.diagnostic_sessions
  set status = 'completed',
      ended_at = coalesce(ended_at, statement_timestamp())
  where id = requested_session_id;

  update public.diagnostics
  set updated_at = statement_timestamp()
  where id = selected_diagnostic_id;

  return query
  select
    count(*)::integer,
    count(*) filter (where di.is_correct)::integer
  from public.diagnostic_items di
  where di.session_id = requested_session_id
    and di.answered_at is not null;
end;
$function$;

revoke all on function public.finish_diagnostic_session(uuid) from public;
grant execute on function public.finish_diagnostic_session(uuid)
  to authenticated;

commit;
