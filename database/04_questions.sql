/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/04_questions.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Versioned question bank and answer choices.
 Dependencies : 00_extensions.sql through 03_program.sql
 Idempotent   : Yes
===============================================================================
*/

begin;

create table if not exists public.questions (
  id uuid primary key default extensions.gen_random_uuid(),
  legacy_id bigint unique,
  micro_skill_id uuid not null
    references public.micro_skills(id) on delete restrict,
  status public.question_status not null default 'draft',
  theoretical_difficulty public.difficulty_level not null default 1,
  current_version_number integer,
  active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint questions_legacy_id_positive check (
    legacy_id is null or legacy_id > 0
  ),
  constraint questions_current_version_positive check (
    current_version_number is null or current_version_number > 0
  )
);

create table if not exists public.question_versions (
  id uuid primary key default extensions.gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  version_number integer not null,
  prompt text not null,
  correction_explanation text,
  change_comment text,
  review_status public.review_status not null default 'unreviewed',
  authored_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default statement_timestamp(),
  published_at timestamptz,
  unique (question_id, version_number),
  unique (id, question_id),
  constraint question_versions_number_positive check (version_number > 0),
  constraint question_versions_prompt_nonempty check (btrim(prompt) <> '')
);

create table if not exists public.answer_choices (
  id uuid primary key default extensions.gen_random_uuid(),
  question_version_id uuid not null
    references public.question_versions(id) on delete cascade,
  choice_key text not null,
  content text not null,
  is_correct boolean not null default false,
  sort_order smallint not null,
  unique (question_version_id, choice_key),
  unique (question_version_id, sort_order),
  constraint answer_choices_key_format check (
    choice_key ~ '^[A-Z][A-Z0-9_]*$'
  ),
  constraint answer_choices_content_nonempty check (btrim(content) <> ''),
  constraint answer_choices_sort_order_positive check (sort_order > 0)
);

create unique index if not exists answer_choices_one_correct_idx
  on public.answer_choices (question_version_id)
  where is_correct;

create table if not exists public.tags (
  id uuid primary key default extensions.gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  active boolean not null default true,
  created_at timestamptz not null default statement_timestamp(),
  constraint tags_code_format check (code ~ '^[a-z][a-z0-9_]*$')
);

create table if not exists public.question_tags (
  question_id uuid not null references public.questions(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  primary key (question_id, tag_id)
);

create table if not exists public.media_assets (
  id uuid primary key default extensions.gen_random_uuid(),
  kind public.media_kind not null,
  storage_bucket text not null,
  storage_path text not null,
  alt_text text,
  mime_type text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default statement_timestamp(),
  unique (storage_bucket, storage_path)
);

create table if not exists public.question_version_media (
  question_version_id uuid not null
    references public.question_versions(id) on delete cascade,
  media_id uuid not null references public.media_assets(id) on delete cascade,
  placement text not null default 'prompt',
  sort_order smallint not null default 1,
  primary key (question_version_id, media_id),
  constraint question_version_media_placement check (
    placement in ('prompt', 'choice', 'explanation')
  )
);

create index if not exists questions_micro_skill_id_idx
  on public.questions (micro_skill_id, status);
create index if not exists question_versions_question_id_idx
  on public.question_versions (question_id, version_number desc);
create index if not exists answer_choices_version_id_idx
  on public.answer_choices (question_version_id, sort_order);
create index if not exists question_tags_tag_id_idx
  on public.question_tags (tag_id);

drop trigger if exists set_questions_updated_at on public.questions;
create trigger set_questions_updated_at
before update on public.questions
for each row execute function public.set_updated_at();

comment on table public.questions is
  'Stable question identity linked to exactly one atomic micro-skill.';
comment on column public.questions.legacy_id is
  'Identifier preserved from the JavaScript V5.1 question bank.';
comment on table public.question_versions is
  'Chronological, non-themed history of every question modification.';
comment on table public.answer_choices is
  'Version-specific choices; a partial unique index permits at most one correct choice.';

commit;
