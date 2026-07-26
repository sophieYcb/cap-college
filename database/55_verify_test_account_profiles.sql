with administrator_accounts as (
  select distinct ur.user_id
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id
  where r.code = 'administrator'
),
account_profiles as (
  select
    administrator.user_id,
    array_agg(r.code order by r.code) as assigned_roles,
    count(*) as assigned_role_count
  from administrator_accounts administrator
  join public.user_roles ur on ur.user_id = administrator.user_id
  join public.roles r on r.id = ur.role_id
  group by administrator.user_id
)
select jsonb_agg(
  jsonb_build_object(
    'user_id', account.user_id,
    'assigned_roles', account.assigned_roles,
    'assigned_role_count', account.assigned_role_count,
    'active_role', active_role.code,
    'question_reporting_assigned',
      account.assigned_roles && array['validator', 'administrator']
  )
  order by account.user_id
) as verification
from account_profiles account
left join public.user_active_roles selected
  on selected.user_id = account.user_id
left join public.roles active_role
  on active_role.id = selected.role_id;
