with milo as (
  select id, display_name, access_code, active
  from public.learner_profiles
  where lower(btrim(display_name)) = 'milo'
)
select jsonb_build_object(
  'profile_preserved', count(*) = 1,
  'profile_active', bool_and(milo.active),
  'access_code_preserved', bool_and(milo.access_code is not null),
  'diagnostics_remaining', (
    select count(*) from public.diagnostics d
    where d.learner_profile_id = min(milo.id)
  ),
  'access_sessions_remaining', (
    select count(*) from public.learner_access_sessions las
    where las.learner_profile_id = min(milo.id)
  )
) as verification
from milo;
