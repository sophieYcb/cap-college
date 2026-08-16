with corrected as (
  select
    q.legacy_id,
    q.status,
    q.current_version_number,
    v.prompt,
    v.change_comment,
    count(a.id) choices,
    count(distinct a.content) distinct_choices,
    count(*) filter(where a.is_correct) correct_choices
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  join public.answer_choices a on a.question_version_id=v.id
  where q.legacy_id in(5000551,5000557,5000564,5000566,5000568)
  group by q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
  'corrected_questions',count(*),
  'questions_in_review',count(*) filter(where status='in_review'),
  'current_versions_are_4',count(*) filter(where current_version_number=4),
  'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
  'distinct_change_comments_saved',count(distinct change_comment),
  'questions_with_four_choices',count(*) filter(where choices=4),
  'questions_with_four_distinct_choices',count(*) filter(where distinct_choices=4),
  'questions_with_one_correct_choice',count(*) filter(where correct_choices=1),
  'crossing_angle_values_preserved',count(*) filter(where legacy_id in(5000551,5000557) and (prompt like '%68°%' or prompt like '%72°%')),
  'acute_c_values_applied',count(*) filter(where legacy_id in(5000564,5000568) and prompt like '%ĉ mesure 55°%'),
  'obtuse_f_value_applied',count(*) filter(where legacy_id=5000566 and prompt like '%f̂ mesure 125°%')
) verification
from corrected;