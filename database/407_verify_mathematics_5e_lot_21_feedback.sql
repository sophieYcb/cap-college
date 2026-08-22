with corrected as(
  select
    q.legacy_id,q.status,q.current_version_number,
    v.prompt,v.change_comment,
    count(a.id) choices,
    count(distinct a.content) distinct_choices,
    count(*) filter(where a.is_correct) correct_choices,
    (select count(*) from public.question_versions previous where previous.question_id=q.id) versions
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  join public.answer_choices a on a.question_version_id=v.id
  where q.legacy_id in(5000652,5000653,5000654,5000655,5000657,5000658,5000675,5000678,5000679)
  group by q.id,q.legacy_id,q.status,q.current_version_number,
           v.prompt,v.change_comment
)
select jsonb_build_object(
  'corrected_questions',count(*),
  'questions_in_review',count(*) filter(where status='in_review'),
  'current_versions_are_2',count(*) filter(where current_version_number=2),
  'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
  'distinct_change_comments_saved',count(distinct change_comment),
  'previous_versions_preserved',count(*) filter(where versions>=2),
  'questions_with_four_choices',count(*) filter(where choices=4),
  'questions_with_four_distinct_choices',count(*) filter(where distinct_choices=4),
  'questions_with_one_correct_choice',count(*) filter(where correct_choices=1),
  'coordinate_visuals_added',count(*) filter(where legacy_id in(5000654,5000655,5000675) and prompt like '%[COORDINATES]%'),
  'construction_goal_clarified',count(*) filter(where legacy_id in(5000652,5000653,5000657,5000658) and prompt ilike '%parallélogramme ABCD%'),
  'diagonal_comparison_clarified',count(*) filter(where legacy_id in(5000678,5000679) and prompt ilike '%comme dans tout parallélogramme%'),
  'question_5000661_unchanged',(
    select current_version_number=1
    from public.questions
    where legacy_id=5000661
  )
) verification
from corrected;
