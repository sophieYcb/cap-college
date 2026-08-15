/*
 CAP-COLLEGE DATABASE
 File: database/316_verify_mathematics_5e_lot_07.sql
 Purpose: Verify Mathematics 5e lot 07 after import.
 Read-only: Yes.
*/

with lot_questions as (
  select
    question.id,
    question.status,
    question.current_version_number,
    micro_skill.code as micro_skill_code
  from public.questions question
  join public.micro_skills micro_skill
    on micro_skill.id = question.micro_skill_id
  where question.legacy_id between 5000201 and 5000240
),
current_versions as (
  select question_version.id, question_version.question_id
  from public.question_versions question_version
  join lot_questions question
    on question.id = question_version.question_id
   and question.current_version_number = question_version.version_number
),
choice_counts as (
  select
    current_version.question_id,
    count(choice.id) as choices,
    count(*) filter (where choice.is_correct) as correct_choices,
    max(choice.sort_order) filter (where choice.is_correct) as correct_position
  from current_versions current_version
  join public.answer_choices choice
    on choice.question_version_id = current_version.id
  group by current_version.question_id
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
    select count(*)
    from lot_questions
    where current_version_number = 1
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
