/*
 CAP-COLLEGE DATABASE
 File: database/230_activate_validator_michele_deplechin.sql
 Purpose: Select the validator role for michele.deplechin@gmail.com.
 Idempotent: Yes
*/

begin;

do $block$
declare
  target_user_id uuid;
  validator_role_id smallint;
begin
  select u.id
  into target_user_id
  from auth.users u
  where lower(u.email) = 'michele.deplechin@gmail.com'
  limit 1;

  if target_user_id is null then
    raise exception 'Validator authentication account not found.';
  end if;

  select ur.role_id
  into validator_role_id
  from public.user_roles ur
  join public.roles role on role.id = ur.role_id
  where ur.user_id = target_user_id
    and role.code = 'validator';

  if validator_role_id is null then
    raise exception 'Validator role is not assigned to this account.';
  end if;

  insert into public.user_active_roles (
    user_id,
    role_id,
    selected_at
  )
  values (
    target_user_id,
    validator_role_id,
    statement_timestamp()
  )
  on conflict (user_id) do update
  set role_id = excluded.role_id,
      selected_at = excluded.selected_at;
end;
$block$;

commit;
