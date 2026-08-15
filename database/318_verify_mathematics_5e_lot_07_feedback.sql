with corrected as (
 select q.legacy_id,q.status,q.current_version_number,v.change_comment,
        count(a.id) as choices,count(*) filter(where a.is_correct) as correct_choices
 from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id in (5000231,5000239)
 group by q.legacy_id,q.status,q.current_version_number,v.change_comment
)
select jsonb_build_object(
 'corrected_questions',count(*),
 'questions_in_review',count(*) filter(where status='in_review'),
 'change_comments_saved',count(*) filter(where change_comment is not null),
 'previous_versions_preserved',count(*) filter(where current_version_number=2),
 'questions_with_four_choices',count(*) filter(where choices=4),
 'questions_with_one_correct_choice',count(*) filter(where correct_choices=1)
) as verification from corrected;
