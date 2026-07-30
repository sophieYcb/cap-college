/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/152_verify_french_6e_lot_05.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify French 6e lot F6-GRA-05 after import.
 Read-only    : Yes
===============================================================================
*/

with lot_questions as (
  select
    q.id,
    q.status,
    q.current_version_number,
    ms.code as micro_skill_code
  from public.questions q
  join public.micro_skills ms on ms.id = q.micro_skill_id
  where q.legacy_id between 1000121 and 1000160
),
current_versions as (
  select qv.id, qv.question_id
  from public.question_versions qv
  join lot_questions q
    on q.id = qv.question_id
   and q.current_version_number = qv.version_number
),
choice_counts as (
  select
    cv.question_id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.sort_order) filter (where ac.is_correct) as correct_position
  from current_versions cv
  join public.answer_choices ac on ac.question_version_id = cv.id
  group by cv.question_id
)
select jsonb_build_object(
  'questions', (select count(*) from lot_questions),
  'versions', (select count(*) from current_versions),
  'choices', (select coalesce(sum(choices), 0) from choice_counts),
  'correct_choices', (
    select coalesce(sum(correct_choices), 0) from choice_counts
  ),
  'micro_skills', (
    select count(distinct micro_skill_code) from lot_questions
  ),
  'current_versions', (
    select count(*) from lot_questions where current_version_number >= 1
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
  ),
  'statuses', (
    select array_agg(distinct status order by status) from lot_questions
  ),
  'answer_a', (
    select count(*) from choice_counts where correct_position = 1
  ),
  'answer_b', (
    select count(*) from choice_counts where correct_position = 2
  ),
  'answer_c', (
    select count(*) from choice_counts where correct_position = 3
  ),
  'answer_d', (
    select count(*) from choice_counts where correct_position = 4
  )
) as verification;
