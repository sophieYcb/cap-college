select jsonb_build_object(
  'question_in_review', q.status = 'in_review',
  'prompt_specifies_present', qv.prompt =
    'Conjugue le verbe « voir » avec « tu » au présent de l''indicatif.',
  'previous_version_preserved', q.current_version_number >= 2
    and exists (
      select 1 from public.question_versions previous
      where previous.question_id = q.id
        and previous.version_number < q.current_version_number
    ),
  'question_has_four_choices', count(ac.id) = 4,
  'question_has_one_correct_choice',
    count(*) filter (where ac.is_correct) = 1,
  'correct_answer_is_vois',
    max(ac.content) filter (where ac.is_correct) = 'vois'
) as verification
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
left join public.answer_choices ac on ac.question_version_id = qv.id
where q.legacy_id = 108
group by q.id, q.status, q.current_version_number, qv.prompt;