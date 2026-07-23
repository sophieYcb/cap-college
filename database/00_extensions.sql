/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/00_extensions.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Install shared extensions and database-wide utility functions.
 Dependencies : None
 Idempotent   : Yes
===============================================================================
*/

begin;

create schema if not exists extensions;

comment on schema extensions is
  'Third-party PostgreSQL extensions used by Cap-College.';

create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;

/*
 Attaches to tables that contain an `updated_at timestamptz` column.

 Example:
   create trigger set_profiles_updated_at
   before update on public.profiles
   for each row execute function public.set_updated_at();
*/
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  new.updated_at := statement_timestamp();
  return new;
end;
$function$;

comment on function public.set_updated_at() is
  'Sets a row updated_at value to the current transaction timestamp.';

commit;
