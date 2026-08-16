with corrected as(
 select q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment,count(a.id) choices,count(*) filter(where a.is_correct) correct_choices
 from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id in(5000448,5000450)
 group by q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
 'corrected_questions',count(*),'questions_in_review',count(*) filter(where status='in_review'),'change_comments_saved',count(*) filter(where change_comment is not null),
 'individual_agreement_comments_saved',count(distinct change_comment),'previous_versions_preserved',count(*) filter(where current_version_number=2),
 'origin_word_corrected',bool_and(position('par rapport à origine' in prompt)=0),'coordinate_visual_added',bool_or(legacy_id=5000450 and prompt like '%[COORDINATES]%'),
 'questions_with_four_choices',count(*) filter(where choices=4),'questions_with_one_correct_choice',count(*) filter(where correct_choices=1)
) verification from corrected;