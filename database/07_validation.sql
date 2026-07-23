/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/07_validation.sql
 Purpose      : Test campaigns, pedagogical reviews and question flags.
 Dependencies : 00_extensions.sql through 06_diagnostics.sql
 Idempotent   : Yes
===============================================================================
*/

begin;

create table if not exists public.validation_campaigns (
  id uuid primary key default extensions.gen_random_uuid(),
  name text not null,
  description text,
  owner_id uuid not null references public.profiles(id) on delete restrict,
  status public.campaign_status not null default 'active',
  created_at timestamptz not null default statement_timestamp(),
  archived_at timestamptz,
  constraint validation_campaigns_name_nonempty check (btrim(name) <> ''),
  constraint validation_campaigns_archive_consistency check (
    (status = 'active' and archived_at is null)
    or (status = 'archived' and archived_at is not null)
  )
);

alter table public.diagnostic_sessions
  add column if not exists validation_campaign_id uuid
  references public.validation_campaigns(id) on delete set null;

create table if not exists public.question_reviews (
  id uuid primary key default extensions.gen_random_uuid(),
  campaign_id uuid references public.validation_campaigns(id) on delete cascade,
  question_version_id uuid not null
    references public.question_versions(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete restrict,
  status public.review_status not null,
  grade char(1),
  comment text,
  reviewed_at timestamptz not null default statement_timestamp(),
  constraint question_reviews_grade check (
    grade is null or grade in ('A', 'B', 'C', 'D')
  )
);

create table if not exists public.question_flags (
  id uuid primary key default extensions.gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  question_version_id uuid
    references public.question_versions(id) on delete set null,
  campaign_id uuid references public.validation_campaigns(id) on delete set null,
  reported_by uuid not null references public.profiles(id) on delete restrict,
  comment text,
  status public.flag_status not null default 'open',
  reported_at timestamptz not null default statement_timestamp(),
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  resolution_comment text,
  constraint question_flags_resolution_consistency check (
    (status in ('open', 'in_progress') and resolved_at is null)
    or (status in ('resolved', 'dismissed') and resolved_at is not null)
  )
);

create index if not exists validation_campaigns_owner_idx
  on public.validation_campaigns (owner_id, created_at desc);
create index if not exists diagnostic_sessions_campaign_idx
  on public.diagnostic_sessions (validation_campaign_id)
  where validation_campaign_id is not null;
create index if not exists question_reviews_version_idx
  on public.question_reviews (question_version_id, reviewed_at desc);
create index if not exists question_flags_status_idx
  on public.question_flags (status, reported_at);

comment on table public.validation_campaigns is
  'Independent test histories that can be archived, reset or removed without polluting student data.';
comment on table public.question_reviews is
  'A/B/C/D review and comment for a precise version of a question.';
comment on table public.question_flags is
  'Quick admin or validator signal raised during a real diagnostic.';

commit;
