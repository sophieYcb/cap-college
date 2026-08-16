with mathematics_current_text as (
 select q.legacy_id,
        v.prompt || ' ' || coalesce(v.correction_explanation,'') || ' ' ||
        coalesce(string_agg(a.content,' ' order by a.sort_order),'') as full_text
 from public.questions q
 join public.question_versions v
   on v.question_id=q.id
  and v.version_number=q.current_version_number
 join public.micro_skills micro_skill on micro_skill.id=q.micro_skill_id
 join public.skills skill on skill.id=micro_skill.skill_id
 join public.domains domain on domain.id=skill.domain_id
 join public.subjects subject on subject.id=domain.subject_id
 left join public.answer_choices a on a.question_version_id=v.id
 where subject.code='mathematics'
 group by q.legacy_id,v.prompt,v.correction_explanation
),
remaining as (
 select legacy_id
 from mathematics_current_text
 where full_text ~ '(^|[^[:alnum:]])[0-9]+( [0-9]{3})*(,[0-9]+)?[[:space:]]+(mL|L)($|[^[:alpha:]])'
),
corrected as (
 select q.status,q.current_version_number,v.prompt,v.change_comment,
        count(a.id) choices,count(*) filter(where a.is_correct) correct_choices
 from public.questions q
 join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 join public.answer_choices a on a.question_version_id=v.id
 where q.legacy_id=5000489
 group by q.status,q.current_version_number,v.prompt,v.change_comment
)
select jsonb_build_object(
 'audited_current_mathematics_questions',(select count(*) from mathematics_current_text),
 'questions_still_using_uppercase_litre_symbol',(select count(*) from remaining),
 'remaining_legacy_ids',(select coalesce(jsonb_agg(legacy_id order by legacy_id),'[]'::jsonb) from remaining),
 'question_5000489_in_review',(select status='in_review' from corrected),
 'question_5000489_version_is_3',(select current_version_number=3 from corrected),
 'change_comment_saved',(select nullif(btrim(change_comment),'') is not null from corrected),
 'question_has_four_choices',(select choices=4 from corrected),
 'question_has_one_correct_choice',(select correct_choices=1 from corrected)
) verification;