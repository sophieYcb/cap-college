/*
===============================================================================
 CAP-COLLEGE DATABASE — FIRST ADMINISTRATOR
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 14_setup_first_administrator.sql
 Purpose      : Grant administrator and validator roles to the only Auth user.
 Dependencies : One user created in Supabase Authentication, 10_seed.sql
 Idempotent   : Yes
===============================================================================

 Safety: the script aborts unless exactly one Auth user exists.
*/

begin;

do $block$
declare
  auth_user_count integer;
  first_user_id uuid;
begin
  select count(*), min(id::text)::uuid
  into auth_user_count, first_user_id
  from auth.users;

  if auth_user_count <> 1 then
    raise exception
      'Expected exactly one Auth user, found %; no role was granted.',
      auth_user_count;
  end if;

  insert into public.profiles (id)
  values (first_user_id)
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role_id, granted_by)
  select first_user_id, r.id, first_user_id
  from public.roles r
  where r.code in ('administrator', 'validator')
  on conflict (user_id, role_id) do nothing;
end
$block$;

commit;

select
  p.id,
  array_agg(r.code order by r.code) as roles
from public.profiles p
join public.user_roles ur on ur.user_id = p.id
join public.roles r on r.id = ur.role_id
group by p.id;
