/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/140_verify_french_6e_lot_01_second_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify the second feedback corrections for French 6e lot 01.
 Read-only    : Yes
===============================================================================
*/

with expected(legacy_id, expected_version, expected_correct_position) as (
  values
    (1000003, 3, 3),
    (1000012, 3, 4),
    (1000021, 3, 1)
),
corrected as (
  select
    q.id,
    q.legacy_id,
    q.status,
    q.current_version_number,
    qv.id as version_id,
    qv.prompt,
    qv.change_comment,
    e.expected_correct_position
  from expected e
  join public.questions q on q.legacy_id = e.legacy_id
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = e.expected_version
  where q.current_version_number = e.expected_version
),
choice_counts as (
  select
    c.legacy_id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.sort_order) filter (where ac.is_correct) as correct_position
  from corrected c
  join public.answer_choices ac on ac.question_version_id = c.version_id
  group by c.legacy_id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'previous_versions_preserved', (
    select count(*)
    from corrected c
    where exists (
      select 1
      from public.question_versions qv
      where qv.question_id = c.id and qv.version_number in (1, 2)
      group by qv.question_id
      having count(distinct qv.version_number) = 2
    )
  ),
  'change_comments_saved', (
    select count(*) from corrected where nullif(change_comment, '') is not null
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
  ),
  'correct_positions_preserved', (
    select count(*)
    from choice_counts cc
    join corrected c using (legacy_id)
    where cc.correct_position = c.expected_correct_position
  ),
  'touristes_distractor_saved', (
    select count(*)
    from corrected c
    join public.answer_choices ac on ac.question_version_id = c.version_id
    where c.legacy_id = 1000003 and ac.content = 'touristes' and not ac.is_correct
  ),
  'permet_distractor_saved', (
    select count(*)
    from corrected c
    join public.answer_choices ac on ac.question_version_id = c.version_id
    where c.legacy_id = 1000012 and ac.content = 'permet' and not ac.is_correct
  ),
  'toujours_classified_as_time', (
    select count(*)
    from corrected
    where legacy_id = 1000021 and prompt ilike '%adverbe de temps%'
  )
) as verification;
