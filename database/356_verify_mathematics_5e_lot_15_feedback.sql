with corrected as(
 select q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment,
        count(a.id) choices,count(*) filter(where a.is_correct) correct_choices
 from public.questions q
 join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id in(5000451,5000452,5000453,5000454,5000455,5000457,5000458,5000460,5000461,5000462,5000470,5000484,5000487,5000488)
 group by q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
 'corrected_questions',count(*),
 'questions_in_review',count(*) filter(where status='in_review'),
 'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
 'distinct_change_comments_saved',count(distinct change_comment),
 'previous_versions_preserved',count(*) filter(where current_version_number=2),
 'visual_questions',count(*) filter(where prompt like '%[CUBESTACK]%' or prompt like '%[SOLIDS]%'),
 'polyhedron_removed',bool_and(position('polyèdre' in lower(prompt))=0),
 'questions_with_four_choices',count(*) filter(where choices=4),
 'questions_with_one_correct_choice',count(*) filter(where correct_choices=1)
) verification from corrected;