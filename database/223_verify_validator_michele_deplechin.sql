select jsonb_build_object(
  'auth_account_exists', target.id is not null,
  'profile_exists', exists (
    select 1 from public.profiles p where p.id = target.id
  ),
  'validator_role', exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = target.id and r.code = 'validator'
  ),
  'administrator_role', exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = target.id and r.code = 'administrator'
  ),
  'email', target.email
) as verification
from (
  select u.id, u.email
  from auth.users u
  where lower(u.email) = 'michele.deplechin@gmail.com'
  limit 1
) target;