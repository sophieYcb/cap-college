/*
 CAP-COLLEGE DATABASE
 File: database/294_verify_mathematics_5e_lot_01_feedback.sql
 Purpose: Verify validator-feedback corrections for Mathematics 5e lot 01.
 Read-only: Yes.
*/

with expected(legacy_id, prompt, correct_position, correct_answer) as (
  values
    (5000027,
     'On forme un nombre à trois chiffres commençant par 47. Quel chiffre des unités faut-il choisir pour que ce nombre soit divisible par 3 ?',
     3,
     '7'),
    (5000030,
     'Sans effectuer la division, pourquoi 8 415 est-il divisible par 3 ?',
     2,
     'La somme de ses chiffres vaut 18, et 18 est divisible par 3.')
),
corrected as (
  select
    question.id,
    question.legacy_id,
    question.status,
    question.current_version_number,
    version.id as version_id,
    version.prompt,
    version.change_comment,
    expected.correct_position,
    expected.correct_answer
  from expected
  join public.questions question on question.legacy_id = expected.legacy_id
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = question.current_version_number
  where version.prompt = expected.prompt
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
  'change_comments_saved', (
    select count(*) from corrected
    where nullif(btrim(change_comment), '') is not null
  ),
  'previous_versions_preserved', (
    select count(*)
    from corrected
    where exists (
      select 1
      from public.question_versions previous
      where previous.question_id = corrected.id
        and previous.version_number < corrected.current_version_number
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
  ),
  'display_symbol_removed', (
    select count(*) = 1
    from corrected
    where legacy_id = 5000027
      and prompt not like '%□%'
  )
) as verification;
