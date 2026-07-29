/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/138_verify_french_6e_lot_01_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify the complete rework of French 6e lot 01.
 Read-only    : Yes
===============================================================================
*/

with lot_questions as (
  select q.id, q.legacy_id, q.status, q.current_version_number
  from public.questions q
  where q.legacy_id between 1000001 and 1000040
),
current_versions as (
  select qv.id, qv.question_id, qv.change_comment
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
  'corrected_questions', (
    select count(*) from lot_questions where current_version_number = 2
  ),
  'questions_in_review', (
    select count(*) from lot_questions where status = 'in_review'
  ),
  'previous_versions_preserved', (
    select count(*)
    from lot_questions q
    where exists (
      select 1
      from public.question_versions qv
      where qv.question_id = q.id and qv.version_number = 1
    )
  ),
  'change_comments_saved', (
    select count(*) from current_versions where nullif(change_comment, '') is not null
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
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
