begin;

create table if not exists public.learner_profiles (
  id uuid primary key default extensions.gen_random_uuid(),
  display_name text not null,
  level_id smallint not null references public.levels(id) on delete restrict,
  pin_hash text not null,
  created_by uuid not null references public.profiles(id) on delete restrict,
  active boolean not null default true,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint learner_profiles_display_name_length
    check (char_length(btrim(display_name)) between 1 and 80)
);

create table if not exists public.learner_profile_adults (
  learner_profile_id uuid not null references public.learner_profiles(id) on delete cascade,
  adult_user_id uuid not null references public.profiles(id) on delete cascade,
  relationship_type text not null check (relationship_type in ('guardian', 'teacher')),
  is_primary boolean not null default false,
  created_at timestamptz not null default statement_timestamp(),
  primary key (learner_profile_id, adult_user_id)
);

create index if not exists learner_profile_adults_adult_idx
  on public.learner_profile_adults (adult_user_id, created_at desc);

drop trigger if exists set_learner_profiles_updated_at on public.learner_profiles;
create trigger set_learner_profiles_updated_at before update on public.learner_profiles
for each row execute function public.set_updated_at();

alter table public.learner_profiles enable row level security;
alter table public.learner_profile_adults enable row level security;
revoke all on public.learner_profiles from anon, authenticated;
revoke all on public.learner_profile_adults from anon, authenticated;

create or replace function public.create_my_learner_profile(
  requested_display_name text,
  requested_level_code text,
  requested_pin text
) returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  selected_relationship text;
  selected_level_id smallint;
  saved_profile_id uuid;
  normalized_name text := nullif(btrim(requested_display_name), '');
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;

  select r.code into selected_relationship
  from public.user_active_roles ar
  join public.roles r on r.id = ar.role_id
  where ar.user_id = auth.uid() and r.code in ('guardian', 'teacher');

  if selected_relationship is null then
    raise exception 'Guardian or teacher profile required';
  end if;
  if normalized_name is null or char_length(normalized_name) > 80 then
    raise exception 'Learner display name must contain 1 to 80 characters';
  end if;
  if requested_pin is null or requested_pin !~ '^[0-9]{6}$' then
    raise exception 'PIN must contain exactly 6 digits';
  end if;

  select id into selected_level_id from public.levels
  where code = requested_level_code and active;
  if selected_level_id is null then raise exception 'Unknown or inactive level'; end if;

  insert into public.learner_profiles (display_name, level_id, pin_hash, created_by)
  values (
    normalized_name,
    selected_level_id,
    extensions.crypt(requested_pin, extensions.gen_salt('bf', 10)),
    auth.uid()
  ) returning id into saved_profile_id;

  insert into public.learner_profile_adults
    (learner_profile_id, adult_user_id, relationship_type, is_primary)
  values (saved_profile_id, auth.uid(), selected_relationship, true);

  return saved_profile_id;
end;
$function$;

create or replace function public.get_my_learner_profiles()
returns table (
  id uuid, display_name text, level_code text, level_name text,
  relationship_type text, is_primary boolean, created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select lp.id, lp.display_name, l.code, l.name,
    link.relationship_type, link.is_primary, lp.created_at
  from public.learner_profile_adults link
  join public.learner_profiles lp on lp.id = link.learner_profile_id
  join public.levels l on l.id = lp.level_id
  where link.adult_user_id = auth.uid() and lp.active
  order by lp.display_name, lp.created_at;
$function$;

revoke all on function public.create_my_learner_profile(text, text, text) from public;
revoke all on function public.get_my_learner_profiles() from public;
grant execute on function public.create_my_learner_profile(text, text, text) to authenticated;
grant execute on function public.get_my_learner_profiles() to authenticated;

comment on table public.learner_profiles is
  'Supervised learners without Supabase Auth accounts or email addresses.';
comment on table public.learner_profile_adults is
  'Guardian and teacher links to supervised learner profiles.';

commit;