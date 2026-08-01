begin;

alter table public.learner_profiles
  add column if not exists access_code text,
  add column if not exists failed_pin_attempts smallint not null default 0,
  add column if not exists locked_until timestamptz;

do $block$
declare
  missing_profile record;
  candidate_code text;
begin
  for missing_profile in
    select id from public.learner_profiles where access_code is null
  loop
    loop
      candidate_code := upper(substr(
        encode(extensions.gen_random_bytes(6), 'hex'), 1, 12
      ));
      exit when not exists (
        select 1 from public.learner_profiles where access_code = candidate_code
      );
    end loop;
    update public.learner_profiles set access_code = candidate_code
    where id = missing_profile.id;
  end loop;
end;
$block$;

alter table public.learner_profiles
  alter column access_code set default
    upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 12)),
  alter column access_code set not null;

create unique index if not exists learner_profiles_access_code_key
  on public.learner_profiles (access_code);

create table if not exists public.learner_access_sessions (
  id uuid primary key default extensions.gen_random_uuid(),
  learner_profile_id uuid not null
    references public.learner_profiles(id) on delete cascade,
  token_hash bytea not null unique,
  created_at timestamptz not null default statement_timestamp(),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  constraint learner_access_sessions_expiry check (expires_at > created_at)
);

create index if not exists learner_access_sessions_profile_idx
  on public.learner_access_sessions (learner_profile_id, expires_at desc);

alter table public.learner_access_sessions enable row level security;
revoke all on public.learner_access_sessions from anon, authenticated;

drop function if exists public.get_my_learner_profiles();
create function public.get_my_learner_profiles()
returns table (
  id uuid, display_name text, level_code text, level_name text,
  relationship_type text, is_primary boolean, access_code text,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select lp.id, lp.display_name, l.code, l.name,
    link.relationship_type, link.is_primary, lp.access_code, lp.created_at
  from public.learner_profile_adults link
  join public.learner_profiles lp on lp.id = link.learner_profile_id
  join public.levels l on l.id = lp.level_id
  where link.adult_user_id = auth.uid() and lp.active
  order by lp.display_name, lp.created_at;
$function$;

create or replace function public.open_learner_session(
  requested_access_code text,
  requested_pin text
) returns jsonb
language plpgsql security definer set search_path = ''
as $function$
declare
  normalized_code text := upper(regexp_replace(
    coalesce(requested_access_code, ''), '[^A-Za-z0-9]', '', 'g'
  ));
  learner public.learner_profiles%rowtype;
  level_record public.levels%rowtype;
  plain_token text;
  next_attempts smallint;
begin
  select * into learner from public.learner_profiles
  where access_code = normalized_code and active for update;

  if learner.id is null then
    return jsonb_build_object('success', false,
      'message', 'Identifiant ou PIN incorrect.');
  end if;

  if learner.locked_until is not null
     and learner.locked_until <= statement_timestamp() then
    update public.learner_profiles
    set failed_pin_attempts = 0, locked_until = null where id = learner.id;
    learner.failed_pin_attempts := 0;
    learner.locked_until := null;
  end if;

  if learner.locked_until is not null then
    return jsonb_build_object('success', false,
      'message', 'Trop de tentatives. Réessaie dans 15 minutes.');
  end if;

  if requested_pin is null
     or requested_pin !~ '^[0-9]{6}$'
     or extensions.crypt(requested_pin, learner.pin_hash) <> learner.pin_hash then
    next_attempts := learner.failed_pin_attempts + 1;
    update public.learner_profiles
    set failed_pin_attempts = next_attempts,
        locked_until = case when next_attempts >= 5
          then statement_timestamp() + interval '15 minutes' else null end
    where id = learner.id;
    return jsonb_build_object(
      'success', false,
      'message', case when next_attempts >= 5
        then 'Trop de tentatives. Réessaie dans 15 minutes.'
        else 'Identifiant ou PIN incorrect.' end
    );
  end if;

  update public.learner_profiles
  set failed_pin_attempts = 0, locked_until = null where id = learner.id;

  select * into level_record from public.levels where id = learner.level_id;
  plain_token := encode(extensions.gen_random_bytes(32), 'hex');

  insert into public.learner_access_sessions
    (learner_profile_id, token_hash, expires_at)
  values (
    learner.id,
    extensions.digest(plain_token, 'sha256'),
    statement_timestamp() + interval '12 hours'
  );

  return jsonb_build_object(
    'success', true,
    'token', plain_token,
    'profile', jsonb_build_object(
      'id', learner.id,
      'displayName', learner.display_name,
      'levelCode', level_record.code,
      'levelName', level_record.name
    )
  );
end;
$function$;

create or replace function public.get_learner_session(requested_token text)
returns jsonb
language sql stable security definer set search_path = ''
as $function$
  select jsonb_build_object(
    'id', lp.id,
    'displayName', lp.display_name,
    'levelCode', l.code,
    'levelName', l.name,
    'expiresAt', session.expires_at
  )
  from public.learner_access_sessions session
  join public.learner_profiles lp on lp.id = session.learner_profile_id
  join public.levels l on l.id = lp.level_id
  where session.token_hash = extensions.digest(
      coalesce(requested_token, ''), 'sha256'
    )
    and session.revoked_at is null
    and session.expires_at > statement_timestamp()
    and lp.active;
$function$;

create or replace function public.close_learner_session(requested_token text)
returns void
language sql volatile security definer set search_path = ''
as $function$
  update public.learner_access_sessions
  set revoked_at = statement_timestamp()
  where token_hash = extensions.digest(
    coalesce(requested_token, ''), 'sha256'
  ) and revoked_at is null;
$function$;

revoke all on function public.get_my_learner_profiles() from public;
revoke all on function public.open_learner_session(text, text) from public;
revoke all on function public.get_learner_session(text) from public;
revoke all on function public.close_learner_session(text) from public;
grant execute on function public.get_my_learner_profiles() to authenticated;
grant execute on function public.open_learner_session(text, text) to anon, authenticated;
grant execute on function public.get_learner_session(text) to anon, authenticated;
grant execute on function public.close_learner_session(text) to anon, authenticated;

commit;