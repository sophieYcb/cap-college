/*
 CAP-COLLEGE DATABASE
 File: database/222_grant_validator_michele_deplechin.sql
 Purpose: Grant the validator role to michele.deplechin@gmail.com.
 Idempotent: Yes
*/

begin;

do $block$
declare
  target_user_id uuid;
  granting_admin_id uuid;
begin
  select u.id
  into target_user_id
  from auth.users u
  where lower(u.email) = 'michele.deplechin@gmail.com'
  limit 1;

  if target_user_id is null then
    raise exception
      'Create michele.deplechin@gmail.com in Supabase Authentication first.';
  end if;

  select ur.user_id
  into granting_admin_id
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id
  where r.code = 'administrator'
  order by ur.granted_at
  limit 1;

  if granting_admin_id is null then
    raise exception 'No administrator is available to grant this role.';
  end if;

  insert into public.profiles (id)
  values (target_user_id)
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role_id, granted_by)
  select target_user_id, r.id, granting_admin_id
  from public.roles r
  where r.code = 'validator'
  on conflict (user_id, role_id) do nothing;
end;
$block$;

commit;