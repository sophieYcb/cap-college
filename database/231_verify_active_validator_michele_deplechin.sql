select jsonb_build_object(
  'email', account.email,
  'validator_assigned', exists (
    select 1
    from public.user_roles assigned
    join public.roles role on role.id = assigned.role_id
    where assigned.user_id = account.id
      and role.code = 'validator'
  ),
  'active_role', active_role.code,
  'active_role_is_validator', active_role.code = 'validator'
) as verification
from auth.users account
left join public.user_active_roles selected
  on selected.user_id = account.id
left join public.roles active_role
  on active_role.id = selected.role_id
where lower(account.email) = 'michele.deplechin@gmail.com';
