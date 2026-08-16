with retests as(
 select q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment,
        count(a.id) choices,count(*) filter(where a.is_correct) correct_choices
 from public.questions q
 join public.question_versions v
   on v.question_id=q.id
  and v.version_number=q.current_version_number
 join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id in(
  5000541,5000542,5000543,5000548,5000551,5000557,
  5000561,5000562,5000563,5000564,5000565,5000566,5000567,5000568
 )
 group by q.legacy_id,q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
 'visual_questions_to_retest',count(*),
 'questions_in_review',count(*) filter(where status='in_review'),
 'current_versions_are_2',count(*) filter(where current_version_number=2),
 'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
 'distinct_change_comments_saved',count(distinct change_comment),
 'angle_tags_preserved',count(*) filter(where prompt like '%[ANGLE]%' or prompt like '%[ANGLECROSS]%' or prompt like '%[PARALLELANGLES]%'),
 'questions_with_four_choices',count(*) filter(where choices=4),
 'questions_with_one_correct_choice',count(*) filter(where correct_choices=1)
) verification from retests;