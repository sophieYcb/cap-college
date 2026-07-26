/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY SECOND VALIDATOR FEEDBACK 2026-07-26
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/69_verify_second_validator_feedback_2026_07_26.sql
 Purpose      : Verify questions 299 and 325 without changing data.
 Read only    : Yes
===============================================================================
*/

with corrected as (
  select
    question.legacy_id,
    question.id as question_id,
    question.current_version_number,
    question.status,
    version.id as version_id
  from public.questions question
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = question.current_version_number
  where question.legacy_id in (299, 325)
),
answers as (
  select
    corrected.legacy_id,
    count(choice.id) as choice_count,
    count(*) filter (where choice.is_correct) as correct_count,
    max(choice.content) filter (where choice.is_correct) as correct_answer,
    jsonb_agg(choice.content order by choice.sort_order) as choices
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
  group by corrected.legacy_id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review',
    (select count(*) from corrected where status = 'in_review'),
  'current_versions',
    (
      select jsonb_object_agg(legacy_id::text, current_version_number)
      from corrected
    ),
  'questions_with_four_choices',
    (select count(*) from answers where choice_count = 4),
  'questions_with_one_correct_choice',
    (select count(*) from answers where correct_count = 1),
  'correct_answers',
    (
      select jsonb_object_agg(legacy_id::text, correct_answer)
      from answers
    ),
  'question_299_restores_version_3_content',
    (
      select choices =
        '["médames","mesdames","mes dames","madames"]'::jsonb
      from answers
      where legacy_id = 299
    ),
  'question_325_choice_c_changed',
    (
      select choices ->> 2 = 'écarter'
      from answers
      where legacy_id = 325
    ),
  'all_previous_versions_preserved',
    (
      select count(*) = 2
      from corrected
      where exists (
        select 1
        from public.question_versions previous_version
        where previous_version.question_id = corrected.question_id
          and previous_version.version_number =
              corrected.current_version_number - 1
      )
    )
) as verification;
