/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/09_security.sql
 Purpose      : Supabase Row Level Security foundations.
 Dependencies : 00_extensions.sql through 08_statistics.sql
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.has_role(required_role text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.code = required_role
  );
$function$;

revoke all on function public.has_role(text) from public;
grant execute on function public.has_role(text) to authenticated;

create or replace function public.can_validate_content()
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select public.has_role('validator') or public.has_role('administrator');
$function$;

revoke all on function public.can_validate_content() from public;
grant execute on function public.can_validate_content() to authenticated;

alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
alter table public.guardian_students enable row level security;
alter table public.education_cycles enable row level security;
alter table public.levels enable row level security;
alter table public.subjects enable row level security;
alter table public.domains enable row level security;
alter table public.skills enable row level security;
alter table public.micro_skills enable row level security;
alter table public.micro_skill_levels enable row level security;
alter table public.micro_skill_prerequisites enable row level security;
alter table public.questions enable row level security;
alter table public.question_versions enable row level security;
alter table public.answer_choices enable row level security;
alter table public.tags enable row level security;
alter table public.question_tags enable row level security;
alter table public.media_assets enable row level security;
alter table public.question_version_media enable row level security;
alter table public.diagnostics enable row level security;
alter table public.diagnostic_sessions enable row level security;
alter table public.diagnostic_items enable row level security;
alter table public.student_micro_skill_mastery enable row level security;
alter table public.mastery_history enable row level security;
alter table public.learning_resources enable row level security;
alter table public.remediation_sessions enable row level security;
alter table public.remediation_attempts enable row level security;
alter table public.validation_campaigns enable row level security;
alter table public.question_reviews enable row level security;
alter table public.question_flags enable row level security;

drop policy if exists profiles_read_self_or_admin on public.profiles;
create policy profiles_read_self_or_admin on public.profiles
for select to authenticated
using (id = auth.uid() or public.has_role('administrator'));

drop policy if exists profiles_update_self_or_admin on public.profiles;
create policy profiles_update_self_or_admin on public.profiles
for update to authenticated
using (id = auth.uid() or public.has_role('administrator'))
with check (id = auth.uid() or public.has_role('administrator'));

drop policy if exists roles_read_authenticated on public.roles;
create policy roles_read_authenticated on public.roles
for select to authenticated using (true);

drop policy if exists user_roles_read_self_or_admin on public.user_roles;
create policy user_roles_read_self_or_admin on public.user_roles
for select to authenticated
using (user_id = auth.uid() or public.has_role('administrator'));

drop policy if exists curriculum_read_authenticated on public.education_cycles;
create policy curriculum_read_authenticated on public.education_cycles
for select to authenticated using (active);

drop policy if exists levels_read_authenticated on public.levels;
create policy levels_read_authenticated on public.levels
for select to authenticated using (active);

drop policy if exists subjects_read_authenticated on public.subjects;
create policy subjects_read_authenticated on public.subjects
for select to authenticated using (active);

drop policy if exists domains_read_authenticated on public.domains;
create policy domains_read_authenticated on public.domains
for select to authenticated using (active);

drop policy if exists skills_read_authenticated on public.skills;
create policy skills_read_authenticated on public.skills
for select to authenticated using (active);

drop policy if exists micro_skills_read_authenticated on public.micro_skills;
create policy micro_skills_read_authenticated on public.micro_skills
for select to authenticated using (active);

drop policy if exists micro_skill_levels_read_authenticated
  on public.micro_skill_levels;
create policy micro_skill_levels_read_authenticated
on public.micro_skill_levels
for select to authenticated using (true);

drop policy if exists prerequisites_read_authenticated
  on public.micro_skill_prerequisites;
create policy prerequisites_read_authenticated
on public.micro_skill_prerequisites
for select to authenticated using (true);

drop policy if exists curriculum_manage_admin on public.education_cycles;
create policy curriculum_manage_admin on public.education_cycles
for all to authenticated
using (public.has_role('administrator'))
with check (public.has_role('administrator'));

drop policy if exists levels_manage_admin on public.levels;
create policy levels_manage_admin on public.levels
for all to authenticated
using (public.has_role('administrator'))
with check (public.has_role('administrator'));

drop policy if exists subjects_manage_admin on public.subjects;
create policy subjects_manage_admin on public.subjects
for all to authenticated
using (public.has_role('administrator'))
with check (public.has_role('administrator'));

drop policy if exists domains_manage_admin on public.domains;
create policy domains_manage_admin on public.domains
for all to authenticated
using (public.has_role('administrator'))
with check (public.has_role('administrator'));

drop policy if exists skills_manage_admin on public.skills;
create policy skills_manage_admin on public.skills
for all to authenticated
using (public.has_role('administrator'))
with check (public.has_role('administrator'));

drop policy if exists micro_skills_manage_admin on public.micro_skills;
create policy micro_skills_manage_admin on public.micro_skills
for all to authenticated
using (public.has_role('administrator'))
with check (public.has_role('administrator'));

drop policy if exists questions_read_published_or_validator on public.questions;
create policy questions_read_published_or_validator on public.questions
for select to authenticated
using (
  (status = 'published' and active)
  or public.can_validate_content()
);

drop policy if exists questions_manage_admin on public.questions;
create policy questions_manage_admin on public.questions
for all to authenticated
using (public.has_role('administrator'))
with check (public.has_role('administrator'));

drop policy if exists question_versions_read_allowed on public.question_versions;
create policy question_versions_read_allowed on public.question_versions
for select to authenticated
using (
  public.can_validate_content()
  or exists (
    select 1 from public.questions q
    where q.id = question_id and q.status = 'published' and q.active
  )
);

drop policy if exists answer_choices_read_allowed on public.answer_choices;
create policy answer_choices_read_allowed on public.answer_choices
for select to authenticated
using (
  public.can_validate_content()
  or exists (
    select 1
    from public.question_versions qv
    join public.questions q on q.id = qv.question_id
    where qv.id = question_version_id
      and q.status = 'published'
      and q.active
  )
);

-- Students must never receive the answer key before answering. RLS controls
-- rows; these column privileges additionally hide corrections and is_correct.
revoke select on public.question_versions from anon, authenticated;
grant select (
  id,
  question_id,
  version_number,
  prompt,
  review_status,
  created_at,
  published_at
) on public.question_versions to authenticated;

revoke select on public.answer_choices from anon, authenticated;
grant select (
  id,
  question_version_id,
  choice_key,
  content,
  sort_order
) on public.answer_choices to authenticated;

drop policy if exists tags_read_authenticated on public.tags;
create policy tags_read_authenticated on public.tags
for select to authenticated using (active);

drop policy if exists question_tags_read_authenticated on public.question_tags;
create policy question_tags_read_authenticated on public.question_tags
for select to authenticated using (true);

drop policy if exists learning_resources_read_authenticated
  on public.learning_resources;
create policy learning_resources_read_authenticated
on public.learning_resources
for select to authenticated using (active);

drop policy if exists diagnostics_owner_access on public.diagnostics;
create policy diagnostics_owner_access on public.diagnostics
for all to authenticated
using (student_id = auth.uid() or public.can_validate_content())
with check (student_id = auth.uid() or public.can_validate_content());

drop policy if exists diagnostic_sessions_owner_access on public.diagnostic_sessions;
create policy diagnostic_sessions_owner_access on public.diagnostic_sessions
for all to authenticated
using (
  exists (
    select 1 from public.diagnostics d
    where d.id = diagnostic_id
      and (d.student_id = auth.uid() or public.can_validate_content())
  )
)
with check (
  exists (
    select 1 from public.diagnostics d
    where d.id = diagnostic_id
      and (d.student_id = auth.uid() or public.can_validate_content())
  )
);

drop policy if exists diagnostic_items_owner_access on public.diagnostic_items;
create policy diagnostic_items_owner_access on public.diagnostic_items
for all to authenticated
using (
  exists (
    select 1
    from public.diagnostic_sessions ds
    join public.diagnostics d on d.id = ds.diagnostic_id
    where ds.id = session_id
      and (d.student_id = auth.uid() or public.can_validate_content())
  )
)
with check (
  exists (
    select 1
    from public.diagnostic_sessions ds
    join public.diagnostics d on d.id = ds.diagnostic_id
    where ds.id = session_id
      and (d.student_id = auth.uid() or public.can_validate_content())
  )
);

drop policy if exists mastery_owner_read on public.student_micro_skill_mastery;
create policy mastery_owner_read on public.student_micro_skill_mastery
for select to authenticated
using (student_id = auth.uid() or public.has_role('administrator'));

drop policy if exists mastery_history_owner_read on public.mastery_history;
create policy mastery_history_owner_read on public.mastery_history
for select to authenticated
using (student_id = auth.uid() or public.has_role('administrator'));

drop policy if exists remediation_sessions_owner_access
  on public.remediation_sessions;
create policy remediation_sessions_owner_access
on public.remediation_sessions
for all to authenticated
using (student_id = auth.uid() or public.has_role('administrator'))
with check (student_id = auth.uid() or public.has_role('administrator'));

drop policy if exists remediation_attempts_owner_access
  on public.remediation_attempts;
create policy remediation_attempts_owner_access
on public.remediation_attempts
for all to authenticated
using (
  exists (
    select 1 from public.remediation_sessions rs
    where rs.id = remediation_session_id
      and (rs.student_id = auth.uid() or public.has_role('administrator'))
  )
)
with check (
  exists (
    select 1 from public.remediation_sessions rs
    where rs.id = remediation_session_id
      and (rs.student_id = auth.uid() or public.has_role('administrator'))
  )
);

drop policy if exists validation_campaigns_validator_access
  on public.validation_campaigns;
create policy validation_campaigns_validator_access
on public.validation_campaigns
for all to authenticated
using (owner_id = auth.uid() or public.can_validate_content())
with check (owner_id = auth.uid() and public.can_validate_content());

drop policy if exists question_reviews_validator_access on public.question_reviews;
create policy question_reviews_validator_access on public.question_reviews
for all to authenticated
using (reviewer_id = auth.uid() or public.has_role('administrator'))
with check (reviewer_id = auth.uid() and public.can_validate_content());

drop policy if exists question_flags_validator_access on public.question_flags;
create policy question_flags_validator_access on public.question_flags
for all to authenticated
using (reported_by = auth.uid() or public.can_validate_content())
with check (reported_by = auth.uid() and public.can_validate_content());

comment on function public.has_role(text) is
  'RLS-safe role lookup for the currently authenticated Supabase user.';

revoke all on public.current_questions from anon, authenticated;
revoke all on public.question_statistics from anon, authenticated;
revoke all on public.student_error_notebook from anon;
grant select on public.student_error_notebook to authenticated;

commit;
