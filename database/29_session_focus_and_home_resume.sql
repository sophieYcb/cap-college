/*
===============================================================================
 CAP-COLLEGE DATABASE — SESSION FOCUS AND HOME RESUME
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 29_session_focus_and_home_resume.sql
 Purpose      : Display and manage the active session clearly from the home page.
 Idempotent   : Yes
===============================================================================
*/

begin;

alter table public.diagnostic_sessions
  add column if not exists focus_micro_skill_id uuid
  references public.micro_skills(id) on delete set null;

create or replace function public.start_diagnostic_session_v2(
  planned_minutes smallint,
  requested_subject_code text default 'french',
  requested_level_code text default '6e',
  requested_competence_id text default null
)
returns table (
  diagnostic_id uuid,
  session_id uuid,
  focus_competence_id text,
  focus_name text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  started record;
  selected_micro_skill_id uuid;
  selected_focus_name text;
begin
  if requested_competence_id is not null
     and requested_competence_id <> 'all' then
    select ms.id, ms.student_name
    into selected_micro_skill_id, selected_focus_name
    from public.micro_skills ms
    where replace(ms.code, 'legacy_', '') = requested_competence_id
      and ms.active
    limit 1;

    if selected_micro_skill_id is null then
      raise exception 'Unknown competency';
    end if;
  end if;

  select * into started
  from public.start_diagnostic_session(
    planned_minutes,
    requested_subject_code,
    requested_level_code
  );

  update public.diagnostic_sessions
  set focus_micro_skill_id = selected_micro_skill_id
  where id = started.session_id;

  return query
  select
    started.diagnostic_id,
    started.session_id,
    coalesce(requested_competence_id, 'all'),
    coalesce(selected_focus_name, 'Tous les thèmes');
end;
$function$;

create or replace function public.get_my_active_diagnostic_session_v2()
returns table (
  diagnostic_id uuid,
  session_id uuid,
  planned_minutes smallint,
  recorded_answers integer,
  focus_competence_id text,
  focus_name text
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
    count(di.id)::integer,
    coalesce(replace(ms.code, 'legacy_', ''), 'all'),
    coalesce(ms.student_name, 'Tous les thèmes')
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  left join public.micro_skills ms on ms.id = ds.focus_micro_skill_id
  left join public.diagnostic_items di
    on di.session_id = ds.id
   and di.answered_at is not null
  where d.student_id = auth.uid()
    and d.status = 'active'
    and ds.status = 'active'
  group by
    d.id,
    ds.id,
    ds.planned_minutes,
    ds.started_at,
    ms.code,
    ms.student_name
  order by ds.started_at desc
  limit 1;
$function$;

create or replace function public.close_my_diagnostic_session(
  requested_session_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.diagnostic_sessions ds
  set status = 'cancelled',
      ended_at = coalesce(ds.ended_at, statement_timestamp())
  from public.diagnostics d
  where ds.id = requested_session_id
    and d.id = ds.diagnostic_id
    and d.student_id = auth.uid()
    and ds.status = 'active';

  if not found then
    raise exception 'Active session is not available';
  end if;
end;
$function$;

revoke all on function public.start_diagnostic_session_v2(
  smallint, text, text, text
) from public;
revoke all on function public.get_my_active_diagnostic_session_v2()
  from public;
revoke all on function public.close_my_diagnostic_session(uuid)
  from public;

grant execute on function public.start_diagnostic_session_v2(
  smallint, text, text, text
) to authenticated;
grant execute on function public.get_my_active_diagnostic_session_v2()
  to authenticated;
grant execute on function public.close_my_diagnostic_session(uuid)
  to authenticated;

commit;

