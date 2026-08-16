with checked as(
  select
    q.status,q.current_version_number,v.prompt,v.change_comment,
    count(a.id) choices,
    count(distinct a.content) distinct_choices,
    count(*) filter(where a.is_correct) correct_choices,
    (select count(*) from public.question_versions previous where previous.question_id=q.id) versions
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  join public.answer_choices a on a.question_version_id=v.id
  where q.legacy_id=5000620
  group by q.id,q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
  'question_in_review',bool_and(status='in_review'),
  'change_comment_saved',bool_and(nullif(btrim(change_comment),'') is not null),
  'current_version_is_2',bool_and(current_version_number=2),
  'calculator_authorized',bool_and(prompt like '%[TOOLS]calculator[/TOOLS]%'),
  'previous_version_preserved',bool_and(versions>=2),
  'question_has_four_choices',bool_and(choices=4),
  'question_has_four_distinct_choices',bool_and(distinct_choices=4),
  'question_has_one_correct_choice',bool_and(correct_choices=1)
) verification
from checked;