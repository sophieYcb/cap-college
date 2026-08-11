select jsonb_build_object(
  'legacy_id', q.legacy_id,
  'question_published', q.status = 'published' and q.active,
  'current_version_number', q.current_version_number,
  'current_version_published',
    qv.review_status = 'approved' and qv.published_at is not null,
  'correct_answer', (
    select choice.content
    from public.answer_choices choice
    where choice.question_version_id = qv.id
      and choice.is_correct
  ),
  'four_choices', (
    select count(*) = 4
    from public.answer_choices choice
    where choice.question_version_id = qv.id
  ),
  'one_correct_choice', (
    select count(*) filter (where choice.is_correct) = 1
    from public.answer_choices choice
    where choice.question_version_id = qv.id
  )
) as verification
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
where q.legacy_id = 600071;
