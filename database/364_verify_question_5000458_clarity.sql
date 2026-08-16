with state as(
 select q.status,q.current_version_number,v.prompt,v.change_comment,count(a.id) choices,count(*) filter(where a.is_correct) correct_choices,count(distinct a.content) distinct_choices
 from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id=5000458
 group by q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
 'question_in_review',status='in_review','current_version_is_5',current_version_number=5,
 'clear_wording_added',prompt like '%posé sur le quadrillage%',
 'change_comment_saved',nullif(btrim(change_comment),'') is not null,'previous_versions_preserved',current_version_number=5,
 'question_has_four_choices',choices=4,'question_has_four_distinct_choices',distinct_choices=4,'question_has_one_correct_choice',correct_choices=1
) verification from state;