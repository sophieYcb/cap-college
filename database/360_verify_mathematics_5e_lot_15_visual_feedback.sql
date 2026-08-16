with corrected as(
 select q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment,count(a.id) choices,count(*) filter(where a.is_correct) correct_choices
 from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id in(5000451,5000453,5000454,5000455,5000458,5000461,5000462,5000470)
 group by q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
 'corrected_questions',count(*),'questions_in_review',count(*) filter(where status='in_review'),
 'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
 'distinct_change_comments_saved',count(distinct change_comment),
 'current_versions_are_3',count(*) filter(where current_version_number=3),
 'previous_versions_preserved',count(*) filter(where current_version_number>=3),
 'dedicated_front_view',bool_or(legacy_id=5000454 and prompt like '%[CUBEVIEW]%'),
 'dedicated_top_view',bool_or(legacy_id=5000458 and prompt like '%[TOPVIEW]%'),
 'questions_with_four_choices',count(*) filter(where choices=4),
 'questions_with_one_correct_choice',count(*) filter(where correct_choices=1)
) verification from corrected;