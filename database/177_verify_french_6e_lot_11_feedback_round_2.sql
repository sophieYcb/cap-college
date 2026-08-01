/*
 CAP-COLLEGE DATABASE
 File: database/177_verify_french_6e_lot_11_feedback_round_2.sql
 Purpose: Verify the second correction of question F6-0333.
 Read-only: Yes
*/

select jsonb_build_object(
  'current_version_is_3', q.current_version_number = 3,
  'question_in_review', q.status = 'in_review',
  'previous_versions_preserved', (
    select count(*) = 2
    from public.question_versions previous
    where previous.question_id = q.id
      and previous.version_number in (1, 2)
  ),
  'change_comment_saved', nullif(qv.change_comment, '') is not null,
  'question_has_four_choices', (
    select count(*) = 4
    from public.answer_choices ac
    where ac.question_version_id = qv.id
  ),
  'question_has_one_correct_choice', (
    select count(*) = 1
    from public.answer_choices ac
    where ac.question_version_id = qv.id
      and ac.is_correct
  ),
  'answer_not_copied_in_prompt',
    qv.prompt not ilike '%Je n’avais pas encore entendu cette chanson%'
) as verification
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
where q.legacy_id = 1000333;
