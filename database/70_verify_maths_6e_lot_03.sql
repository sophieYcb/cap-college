/*
===============================================================================
 CAP-COLLEGE DATABASE - VERIFY MATHS 6E LOT 03
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/70_verify_maths_6e_lot_03.sql
 Purpose      : Verify the third mathematics 6e lot after JSON import.
 Read only    : Yes
===============================================================================
*/

with lot_questions as (
  select
    question.id,
    question.legacy_id,
    question.current_version_number,
    question.status,
    question.micro_skill_id
  from public.questions question
  where question.legacy_id between 600081 and 600120
),
lot_versions as (
  select version.id, version.question_id
  from public.question_versions version
  join lot_questions question on question.id = version.question_id
  where version.version_number = question.current_version_number
),
choice_counts as (
  select
    version.question_id,
    count(choice.id) as choices,
    count(*) filter (where choice.is_correct) as correct_choices,
    max(choice.sort_order) filter (where choice.is_correct) as correct_position
  from lot_versions version
  join public.answer_choices choice
    on choice.question_version_id = version.id
  group by version.question_id
),
position_counts as (
  select
    count(*) filter (where correct_position = 1) as answer_a,
    count(*) filter (where correct_position = 2) as answer_b,
    count(*) filter (where correct_position = 3) as answer_c,
    count(*) filter (where correct_position = 4) as answer_d
  from choice_counts
)
select jsonb_build_object(
  'questions', (select count(*) from lot_questions),
  'versions', (select count(*) from lot_versions),
  'choices', (select coalesce(sum(choices), 0) from choice_counts),
  'correct_choices',
    (select coalesce(sum(correct_choices), 0) from choice_counts),
  'micro_skills',
    (select count(distinct micro_skill_id) from lot_questions),
  'current_versions',
    (
      select count(*)
      from lot_questions
      where current_version_number = 1
    ),
  'questions_with_four_choices',
    (select count(*) from choice_counts where choices = 4),
  'questions_with_one_correct_choice',
    (select count(*) from choice_counts where correct_choices = 1),
  'statuses',
    (select array_agg(distinct status order by status) from lot_questions),
  'answer_a', (select answer_a from position_counts),
  'answer_b', (select answer_b from position_counts),
  'answer_c', (select answer_c from position_counts),
  'answer_d', (select answer_d from position_counts)
) as verification;
