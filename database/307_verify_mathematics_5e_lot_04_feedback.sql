/*
 CAP-COLLEGE DATABASE
 File: database/307_verify_mathematics_5e_lot_04_feedback.sql
 Purpose: Verify validator-feedback corrections for Mathematics 5e lot 04.
 Read-only: Yes.
*/

with expected(
  legacy_id,
  correct_position,
  correct_answer,
  expected_difficulty
) as (
  values
    (5000114, 2, 'perd 35 points', 1),
    (5000118, 2, 'inférieur à zéro', 2),
    (5000129, 1, '+7', 2),
    (5000134, 2, '−40 m', 1)
),
corrected as (
  select
    question.id,
    question.legacy_id,
    question.status,
    question.current_version_number,
    question.theoretical_difficulty,
    version.id as version_id,
    version.change_comment,
    expected.correct_position,
    expected.correct_answer,
    expected.expected_difficulty
  from expected
  join public.questions question on question.legacy_id = expected.legacy_id
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = question.current_version_number
  where question.current_version_number = 2
),
choice_counts as (
  select
    corrected.legacy_id,
    count(choice.id) as choices,
    count(*) filter (where choice.is_correct) as correct_choices,
    max(choice.sort_order) filter (where choice.is_correct) as correct_position,
    max(choice.content) filter (where choice.is_correct) as correct_answer
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
  group by corrected.legacy_id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'individual_change_comments_saved', (
    select count(*) from corrected
    where nullif(btrim(change_comment), '') is not null
  ),
  'distinct_change_comments_saved', (
    select count(distinct change_comment) from corrected
  ),
  'requested_difficulties_applied', (
    select count(*) from corrected
    where theoretical_difficulty::text::integer = expected_difficulty
  ),
  'previous_versions_preserved', (
    select count(*)
    from corrected
    where exists (
      select 1
      from public.question_versions previous
      where previous.question_id = corrected.id
        and previous.version_number = 1
    )
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
  ),
  'requested_answers_applied', (
    select count(*)
    from choice_counts
    join corrected using (legacy_id)
    where choice_counts.correct_position = corrected.correct_position
      and choice_counts.correct_answer = corrected.correct_answer
  )
) as verification;
