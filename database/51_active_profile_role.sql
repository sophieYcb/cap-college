/*
===============================================================================
 CAP-COLLEGE DATABASE - ACTIVE PROFILE ROLE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/51_active_profile_role.sql
 Purpose      : Use one active role at a time for accounts with several roles.
 Idempotent   : Yes
===============================================================================
*/

begin;

create table if not exists public.user_active_roles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  role_id smallint not null references public.roles(id) on delete restrict,
  selected_at timestamptz not null default statement_timestamp(),
  foreign key (user_id, role_id)
    references public.user_roles(user_id, role_id) on delete cascade
);

alter table public.user_active_roles enable row level security;
revoke all on public.user_active_roles from anon, authenticated;

-- The existing administrator account is also the product test account.
insert into public.user_roles (user_id, role_id, granted_by)
select administrator.user_id, role.id, administrator.user_id
from public.user_roles administrator
join public.roles administrator_role
  on administrator_role.id = administrator.role_id
 and administrator_role.code = 'administrator'
cross join public.roles role
where role.code in (
  'student', 'guardian', 'teacher', 'validator', 'administrator'
)
on conflict (user_id, role_id) do nothing;

-- Select a deterministic initial profile for every existing account.
insert into public.user_active_roles (user_id, role_id)
select distinct on (ur.user_id)
  ur.user_id,
  ur.role_id
from public.user_roles ur
join public.roles r on r.id = ur.role_id
order by
  ur.user_id,
  case r.code
    when 'administrator' then 1
    when 'validator' then 2
    when 'teacher' then 3
    when 'guardian' then 4
    when 'student' then 5
    else 99
  end
on conflict (user_id) do nothing;

create or replace function public.get_my_active_role()
returns text
language sql
stable
security definer
set search_path = ''
as $function$
  select r.code
  from public.user_active_roles active_role
  join public.roles r on r.id = active_role.role_id
  where active_role.user_id = auth.uid();
$function$;

create or replace function public.set_my_active_role(requested_role text)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_role_id smallint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select ur.role_id
  into selected_role_id
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id
  where ur.user_id = auth.uid()
    and r.code = requested_role;

  if selected_role_id is null then
    raise exception 'Role not assigned to this account';
  end if;

  insert into public.user_active_roles (user_id, role_id, selected_at)
  values (auth.uid(), selected_role_id, statement_timestamp())
  on conflict (user_id) do update
  set role_id = excluded.role_id,
      selected_at = excluded.selected_at;

  return requested_role;
end;
$function$;

create or replace function public.has_role(required_role text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.user_active_roles active_role
    join public.roles r on r.id = active_role.role_id
    where active_role.user_id = auth.uid()
      and r.code = required_role
  );
$function$;

create or replace function public.can_report_questions()
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.code in ('validator', 'administrator')
  );
$function$;

create or replace function public.flag_question_for_review(
  requested_question_id uuid,
  requested_question_version_id uuid default null,
  requested_campaign_id uuid default null,
  requested_comment text default null
)
returns table (
  flag_id uuid,
  flag_status public.flag_status,
  reported_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  saved_id uuid;
  saved_at timestamptz;
begin
  if auth.uid() is null or not public.can_report_questions() then
    raise exception 'Question reporting permission required';
  end if;

  if not exists (
    select 1 from public.questions q where q.id = requested_question_id
  ) then
    raise exception 'Unknown question';
  end if;

  if requested_question_version_id is not null and not exists (
    select 1
    from public.question_versions qv
    where qv.id = requested_question_version_id
      and qv.question_id = requested_question_id
  ) then
    raise exception 'Question version does not belong to question';
  end if;

  if requested_campaign_id is not null and not exists (
    select 1
    from public.validation_campaigns vc
    where vc.id = requested_campaign_id
      and (
        vc.owner_id = auth.uid()
        or public.has_role('administrator')
      )
  ) then
    raise exception 'Validation campaign unavailable';
  end if;

  insert into public.question_flags (
    question_id,
    question_version_id,
    campaign_id,
    reported_by,
    comment
  )
  values (
    requested_question_id,
    requested_question_version_id,
    requested_campaign_id,
    auth.uid(),
    nullif(btrim(requested_comment), '')
  )
  returning id, question_flags.reported_at
  into saved_id, saved_at;

  return query
  select saved_id, 'open'::public.flag_status, saved_at;
end;
$function$;

revoke all on function public.get_my_active_role() from public;
revoke all on function public.set_my_active_role(text) from public;
revoke all on function public.has_role(text) from public;
revoke all on function public.can_report_questions() from public;
revoke all on function public.flag_question_for_review(uuid, uuid, uuid, text)
  from public;
grant execute on function public.get_my_active_role() to authenticated;
grant execute on function public.set_my_active_role(text) to authenticated;
grant execute on function public.has_role(text) to authenticated;
grant execute on function public.can_report_questions() to authenticated;
grant execute on function public.flag_question_for_review(uuid, uuid, uuid, text)
  to authenticated;

comment on table public.user_active_roles is
  'Single role currently assumed by a multi-role account.';
comment on function public.set_my_active_role(text) is
  'Selects one of the roles already assigned to the signed-in account.';
comment on function public.can_report_questions() is
  'Account-level testing permission that remains available in student mode.';

commit;
