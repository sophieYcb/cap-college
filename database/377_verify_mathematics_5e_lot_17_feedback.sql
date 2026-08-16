with corrected as(
 select q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment,
        string_agg(a.content,' | ' order by a.sort_order) choices_text,
        count(a.id) choices,count(*) filter(where a.is_correct) correct_choices
 from public.questions q
 join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id in(5000522,5000524,5000525,5000528,5000529,5000533,5000540)
 group by q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
 'corrected_questions',count(*),
 'questions_in_review',count(*) filter(where status='in_review'),
 'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
 'distinct_change_comments_saved',count(distinct change_comment),
 'previous_versions_preserved',count(*) filter(where current_version_number=2),
 'coordinate_questions_reframed',count(*) filter(where legacy_id in(5000522,5000524,5000528,5000529) and prompt like '%[COORDINATES]%'),
 'line_notation_corrected',bool_and(legacy_id not in(5000525,5000533,5000540) or position('(d)' in prompt||' '||choices_text)>0 or position('(BB’)' in choices_text)>0),
 'questions_with_four_choices',count(*) filter(where choices=4),
 'questions_with_one_correct_choice',count(*) filter(where correct_choices=1)
) verification from corrected;