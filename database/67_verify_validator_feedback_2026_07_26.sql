/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY VALIDATOR FEEDBACK 2026-07-26
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/67_verify_validator_feedback_2026_07_26.sql
 Purpose      : Verify the corrections without changing any data.
 Read only    : Yes
===============================================================================
*/

with expected(legacy_id, expected_version, expected_correct_position) as (
  values
    (504::bigint, 4, 1),
    (63::bigint, 3, 3),
    (67::bigint, 3, 3),
    (71::bigint, 3, 3),
    (75::bigint, 3, 3),
    (79::bigint, 3, 3),
    (299::bigint, 4, 2),
    (325::bigint, 4, 2),
    (600037::bigint, 2, 3),
    (600038::bigint, 2, 1),
    (600040::bigint, 2, 2)
),
corrected as (
  select
    question.legacy_id,
    question.id as question_id,
    question.current_version_number,
    question.status,
    version.id as version_id,
    expected.expected_correct_position
  from expected
  join public.questions question
    on question.legacy_id = expected.legacy_id
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = expected.expected_version
  where question.current_version_number = expected.expected_version
),
choice_counts as (
  select
    corrected.legacy_id,
    count(choice.id) as choice_count,
    count(*) filter (where choice.is_correct) as correct_count,
    max(choice.sort_order) filter (where choice.is_correct) as correct_position
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
  group by corrected.legacy_id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review',
    (select count(*) from corrected where status = 'in_review'),
  'questions_with_four_choices',
    (select count(*) from choice_counts where choice_count = 4),
  'questions_with_one_correct_choice',
    (select count(*) from choice_counts where correct_count = 1),
  'correct_positions_as_expected',
    (
      select count(*)
      from choice_counts
      join expected using (legacy_id)
      where choice_counts.correct_position = expected.expected_correct_position
    ),
  'previous_versions_preserved',
    (
      select count(*)
      from corrected
      where exists (
        select 1
        from public.question_versions previous_version
        where previous_version.question_id = corrected.question_id
          and previous_version.version_number =
              corrected.current_version_number - 1
      )
    ),
  'question_80_unchanged',
    (
      select current_version_number = 2
      from public.questions
      where legacy_id = 80
    ),
  'maths_sequence_600037_600038_600040', (
    select jsonb_agg(
      jsonb_build_object(
        'question', legacy_id,
        'correct_answer', chr(64 + correct_position)
      )
      order by legacy_id
    )
    from choice_counts
    where legacy_id in (600037, 600038, 600040)
  )
) as verification;
