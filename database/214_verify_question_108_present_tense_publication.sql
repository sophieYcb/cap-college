select jsonb_build_object(
  'legacy_id', q.legacy_id,
  'question_published', q.status = 'published' and q.active,
  'current_version_published',
    qv.review_status = 'approved' and qv.published_at is not null,
  'prompt', qv.prompt,
  'correct_answer',
    max(ac.content) filter (where ac.is_correct),
  'four_choices', count(ac.id) = 4,
  'one_correct_choice', count(*) filter (where ac.is_correct) = 1
) as verification
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
left join public.answer_choices ac on ac.question_version_id = qv.id
where q.legacy_id = 108
group by q.id, q.legacy_id, q.status, q.active,
  qv.review_status, qv.published_at, qv.prompt;