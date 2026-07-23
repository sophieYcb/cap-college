/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/08_statistics.sql
 Purpose      : Derived views for published content, errors and question quality.
 Dependencies : 00_extensions.sql through 07_validation.sql
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace view public.current_questions
with (security_invoker = true)
as
select
  q.id,
  q.legacy_id,
  q.micro_skill_id,
  q.status,
  q.theoretical_difficulty,
  q.current_version_number,
  qv.id as question_version_id,
  qv.prompt,
  qv.correction_explanation,
  qv.review_status,
  q.updated_at
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number;

create or replace view public.question_statistics
with (security_invoker = true)
as
select
  q.id as question_id,
  coalesce(performance.answered_count, 0) as answered_count,
  coalesce(performance.correct_count, 0) as correct_count,
  case
    when coalesce(performance.answered_count, 0) = 0 then null
    else round(
      100.0 * performance.correct_count / performance.answered_count,
      2
    )
  end as success_rate,
  coalesce(flags.open_flag_count, 0) as open_flag_count
from public.questions q
left join lateral (
  select
    count(*) filter (where di.answered_at is not null) as answered_count,
    count(*) filter (where di.is_correct) as correct_count
  from public.diagnostic_items di
  where di.question_id = q.id
) performance on true
left join lateral (
  select count(*) as open_flag_count
  from public.question_flags qf
  where qf.question_id = q.id
    and qf.status in ('open', 'in_progress')
) flags on true;

create or replace view public.student_error_notebook
with (security_invoker = true)
as
select
  d.student_id,
  di.id as diagnostic_item_id,
  di.question_id,
  di.question_version_id,
  q.micro_skill_id,
  qv.prompt,
  di.selected_choice_id,
  qv.correction_explanation,
  di.answered_at
from public.diagnostic_items di
join public.diagnostic_sessions ds on ds.id = di.session_id
join public.diagnostics d on d.id = ds.diagnostic_id
join public.questions q on q.id = di.question_id
join public.question_versions qv on qv.id = di.question_version_id
where di.is_correct is false;

comment on view public.current_questions is
  'Current version of every question; includes drafts subject to RLS.';
comment on view public.question_statistics is
  'Observed success and reporting indicators; response time is intentionally excluded.';
comment on view public.student_error_notebook is
  'Reviewable incorrect answers with the original response and correction.';

commit;
