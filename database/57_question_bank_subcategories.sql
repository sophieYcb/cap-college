/*
===============================================================================
 CAP-COLLEGE DATABASE - QUESTION BANK SUBCATEGORIES
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/57_question_bank_subcategories.sql
 Purpose      : Expose the skill level as the visible question subcategory.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_validation_question_bank_v2()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    jsonb_agg(
      source.item || jsonb_build_object(
        'subcategoryCode', skill.code,
        'subcategory', skill.name,
        'microSkillCode', micro_skill.code,
        'microSkill', micro_skill.student_name
      )
      order by source.ordinality
    ),
    '[]'::jsonb
  )
  from jsonb_array_elements(public.get_validation_question_bank())
       with ordinality as source(item, ordinality)
  join public.questions question
    on question.id = (source.item ->> 'questionId')::uuid
  join public.micro_skills micro_skill
    on micro_skill.id = question.micro_skill_id
  join public.skills skill
    on skill.id = micro_skill.skill_id;
$function$;

create or replace function public.get_published_question_bank_v2()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    jsonb_agg(
      source.item || jsonb_build_object(
        'subcategoryCode', skill.code,
        'subcategory', skill.name,
        'microSkillCode', micro_skill.code,
        'microSkill', micro_skill.student_name
      )
      order by source.ordinality
    ),
    '[]'::jsonb
  )
  from jsonb_array_elements(public.get_published_question_bank())
       with ordinality as source(item, ordinality)
  join public.questions question
    on question.id = (source.item ->> 'questionId')::uuid
  join public.micro_skills micro_skill
    on micro_skill.id = question.micro_skill_id
  join public.skills skill
    on skill.id = micro_skill.skill_id;
$function$;

revoke all on function public.get_validation_question_bank_v2() from public;
revoke all on function public.get_published_question_bank_v2() from public;
grant execute on function public.get_validation_question_bank_v2()
  to authenticated;
grant execute on function public.get_published_question_bank_v2()
  to anon, authenticated;

commit;
