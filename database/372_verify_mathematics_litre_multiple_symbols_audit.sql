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
incorrect_symbols as (
 select legacy_id,
        full_text
 from mathematics_current_text
 where full_text ~ '(^|[^[:alnum:]])[0-9]+( [0-9]{3})*(,[0-9]+)?[[:space:]]+(cL|dL|daL|hL|CL|DL|DAL|HL)($|[^[:alpha:]])'
)
select jsonb_build_object(
 'audited_current_mathematics_questions',(select count(*) from mathematics_current_text),
 'questions_with_incorrect_cl_dl_dal_hl_symbols',(select count(*) from incorrect_symbols),
 'affected_legacy_ids',(select coalesce(jsonb_agg(legacy_id order by legacy_id),'[]'::jsonb) from incorrect_symbols),
 'audit_passed',not exists(select 1 from incorrect_symbols)
) verification;