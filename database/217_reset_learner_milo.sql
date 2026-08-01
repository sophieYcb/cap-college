/*
 CAP-COLLEGE DATABASE
 File: database/217_reset_learner_milo.sql
 Purpose: Reset Milo diagnostic data without deleting the learner profile.
*/

begin;

do $block$
declare
  selected_learner_id uuid;
  matching_profiles integer;
begin
  select count(*)
  into matching_profiles
  from public.learner_profiles
  where lower(btrim(display_name)) = 'milo'
    and active;

  select id
  into selected_learner_id
  from public.learner_profiles
  where lower(btrim(display_name)) = 'milo'
    and active
  limit 1;

  if matching_profiles <> 1 then
    raise exception
      'Reset cancelled: exactly one active Milo profile expected, % found.',
      matching_profiles;
  end if;

  delete from public.learner_access_sessions
  where learner_profile_id = selected_learner_id;

  delete from public.diagnostics
  where learner_profile_id = selected_learner_id;
end;
$block$;

commit;
