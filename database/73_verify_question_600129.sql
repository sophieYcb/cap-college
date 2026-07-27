/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY QUESTION 600129
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/73_verify_question_600129.sql
 Purpose      : Verify the corrected wording and preserved answers.
 Read only    : Yes
===============================================================================
*/

with corrected as (
  select
    question.id as question_id,
    question.current_version_number,
    question.status,
    version.id as version_id,
    version.prompt
  from public.questions question
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = question.current_version_number
  where question.legacy_id = 600129
),
answers as (
  select
    count(choice.id) as choice_count,
    count(*) filter (where choice.is_correct) as correct_count,
    max(choice.sort_order) filter (where choice.is_correct) as correct_position
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
)
select jsonb_build_object(
  'question_found', (select count(*) = 1 from corrected),
  'current_version', (select current_version_number from corrected),
  'status', (select status from corrected),
  'wording_correct',
    (
      select prompt =
        'Quels nombres peuvent encadrer 6,999 au dixième ?'
      from corrected
    ),
  'choices', (select choice_count from answers),
  'correct_choices', (select correct_count from answers),
  'correct_answer', (select chr(64 + correct_position) from answers),
  'previous_version_preserved',
    (
      select exists (
        select 1
        from public.question_versions previous_version
        where previous_version.question_id = corrected.question_id
          and previous_version.version_number = 1
      )
      from corrected
    )
) as verification;
