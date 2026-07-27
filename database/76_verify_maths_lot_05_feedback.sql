/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY MATHS LOT 05 FEEDBACK
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/76_verify_maths_lot_05_feedback.sql
 Purpose      : Verify corrected questions 600163, 600167 and 600180.
 Read only    : Yes
===============================================================================
*/

with corrected as (
  select
    question.legacy_id,
    question.id question_id,
    question.current_version_number,
    question.status,
    version.id version_id,
    version.prompt
  from public.questions question
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = question.current_version_number
  where question.legacy_id in (600163, 600167, 600180)
),
answers as (
  select
    corrected.legacy_id,
    count(choice.id) choice_count,
    count(*) filter (where choice.is_correct) correct_count,
    max(choice.content) filter (where choice.is_correct) correct_answer,
    jsonb_agg(choice.content order by choice.sort_order) choices
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
  group by corrected.legacy_id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review',
    (select count(*) from corrected where status = 'in_review'),
  'current_version_2',
    (select count(*) from corrected where current_version_number = 2),
  'questions_with_four_choices',
    (select count(*) from answers where choice_count = 4),
  'questions_with_one_correct_choice',
    (select count(*) from answers where correct_count = 1),
  'question_600163_correct',
    (
      select prompt like '%12,096%'
        and correct_answer = '12,10'
      from corrected join answers using (legacy_id)
      where legacy_id = 600163
    ),
  'question_600167_correct',
    (
      select prompt like '%6,906%'
        and correct_answer = '6,91'
      from corrected join answers using (legacy_id)
      where legacy_id = 600167
    ),
  'question_600180_correct',
    (
      select choices = '["50","50,1","50,9","51"]'::jsonb
        and correct_answer = '51'
      from answers
      where legacy_id = 600180
    ),
  'previous_versions_preserved',
    (
      select count(*) = 3
      from corrected
      where exists (
        select 1
        from public.question_versions previous_version
        where previous_version.question_id = corrected.question_id
          and previous_version.version_number = 1
      )
    )
) verification;
