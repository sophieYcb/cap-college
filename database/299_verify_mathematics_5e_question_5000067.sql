/*
 CAP-COLLEGE DATABASE
 File: database/299_verify_mathematics_5e_question_5000067.sql
 Purpose: Verify the corrected Mathematics 5e question 5000067.
 Read-only: Yes.
*/

with corrected as (
  select
    question.id,
    question.status,
    question.current_version_number,
    version.id as version_id,
    version.prompt,
    version.change_comment,
    micro_skill.code as micro_skill_code
  from public.questions question
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = question.current_version_number
  join public.micro_skills micro_skill
    on micro_skill.id = question.micro_skill_id
  where question.legacy_id = 5000067
),
choice_counts as (
  select
    count(choice.id) as choices,
    count(*) filter (where choice.is_correct) as correct_choices,
    max(choice.sort_order) filter (where choice.is_correct) as correct_position,
    max(choice.content) filter (where choice.is_correct) as correct_answer
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
)
select jsonb_build_object(
  'question_in_review', corrected.status = 'in_review',
  'current_version_is_2', corrected.current_version_number = 2,
  'numeric_expression_prompt',
    corrected.prompt =
      'Une salle possède 12 rangées de 18 sièges, puis on ajoute 4 rangées de 15 sièges. Quelle expression donne le nombre total de sièges ?',
  'keeps_requested_micro_skill',
    corrected.micro_skill_code = 'm5_calc_translate_expression',
  'change_comment_saved',
    nullif(btrim(corrected.change_comment), '') is not null,
  'previous_version_preserved', exists (
    select 1
    from public.question_versions previous
    where previous.question_id = corrected.id
      and previous.version_number = 1
      and previous.prompt like '%largeur x%'
  ),
  'question_has_four_choices', choice_counts.choices = 4,
  'question_has_one_correct_choice', choice_counts.correct_choices = 1,
  'correct_answer_applied',
    choice_counts.correct_position = 3
    and choice_counts.correct_answer = '12 × 18 + 4 × 15'
) as verification
from corrected
cross join choice_counts;
