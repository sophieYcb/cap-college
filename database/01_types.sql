/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/01_types.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Define stable shared data types and validated numeric domains.
 Dependencies : 00_extensions.sql
 Idempotent   : Yes
===============================================================================

 Roles are deliberately stored as data in a `roles` table, not as an ENUM.
 This lets Cap-College add a role without changing the database type.
*/

begin;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'question_status'
  ) then
    create type public.question_status as enum (
      'draft',
      'in_review',
      'published',
      'retired'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'review_status'
  ) then
    create type public.review_status as enum (
      'unreviewed',
      'approved',
      'changes_requested',
      'corrected_to_retest',
      'rejected'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'diagnostic_status'
  ) then
    create type public.diagnostic_status as enum (
      'active',
      'paused',
      'completed',
      'abandoned'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'session_status'
  ) then
    create type public.session_status as enum (
      'active',
      'completed',
      'cancelled'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'campaign_status'
  ) then
    create type public.campaign_status as enum (
      'active',
      'archived'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'flag_status'
  ) then
    create type public.flag_status as enum (
      'open',
      'in_progress',
      'resolved',
      'dismissed'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'mastery_status'
  ) then
    create type public.mastery_status as enum (
      'not_assessed',
      'assessing',
      'fragile',
      'developing',
      'mastered'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'learning_session_status'
  ) then
    create type public.learning_session_status as enum (
      'active',
      'completed',
      'cancelled'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'assistance_mode'
  ) then
    create type public.assistance_mode as enum (
      'with_reminder',
      'without_reminder'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'media_kind'
  ) then
    create type public.media_kind as enum (
      'image',
      'audio',
      'video',
      'document'
    );
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'difficulty_level'
  ) then
    create domain public.difficulty_level as smallint
      check (value between 1 and 5);
  end if;
end
$block$;

do $block$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'percentage_score'
  ) then
    create domain public.percentage_score as numeric(5, 2)
      check (value between 0 and 100);
  end if;
end
$block$;

comment on type public.question_status is
  'Publication lifecycle of a question.';
comment on type public.review_status is
  'Pedagogical validation state of a question version.';
comment on type public.mastery_status is
  'Readable mastery classification calculated for a micro-skill.';
comment on domain public.difficulty_level is
  'Difficulty from 1 (easiest) to 5 (hardest).';
comment on domain public.percentage_score is
  'Validated percentage value between 0 and 100.';

commit;
