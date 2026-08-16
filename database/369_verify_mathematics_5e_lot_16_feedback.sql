with corrected as(
 select q.legacy_id,q.status,q.current_version_number,v.prompt,v.correction_explanation,v.change_comment,
        string_agg(a.content,' | ' order by a.sort_order) choices_text,
        count(a.id) choices,count(*) filter(where a.is_correct) correct_choices
 from public.questions q
 join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id in(5000491,5000492,5000493,5000494,5000496,5000497,5000498,5000500,5000511,5000518)
 group by q.legacy_id,q.status,q.current_version_number,v.prompt,v.correction_explanation,v.change_comment
)
select jsonb_build_object(
 'corrected_questions',count(*),
 'questions_in_review',count(*) filter(where status='in_review'),
 'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
 'distinct_change_comments_saved',count(distinct change_comment),
 'previous_versions_preserved',count(*) filter(where current_version_number=2),
 'lowercase_litre_symbols',bool_and(position(' L' in prompt||' '||choices_text||' '||correction_explanation)=0 and position('mL' in prompt||' '||choices_text||' '||correction_explanation)=0),
 'duplicate_aquarium_removed',bool_and(legacy_id<>5000496 or position('aquarium' in lower(prompt))=0),
 'cylinder_formula_spaced',bool_and(legacy_id<>5000511 or position('π × r² × h' in choices_text)>0),
 'questions_with_four_choices',count(*) filter(where choices=4),
 'questions_with_one_correct_choice',count(*) filter(where correct_choices=1)
) verification from corrected;