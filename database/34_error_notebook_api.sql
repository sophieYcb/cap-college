/*
===============================================================================
 CAP-COLLEGE DATABASE — STUDENT ERROR NOTEBOOK API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/34_error_notebook_api.sql
 Purpose      : Return the authenticated student's durable error notebook.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_my_error_notebook()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  with evidence as (
    select
      q.micro_skill_id,
      count(*)::integer as evidence_count,
      sum(
        case
          when di.is_correct and q.theoretical_difficulty = 1 then 10
          when di.is_correct and q.theoretical_difficulty = 2 then 15
          when di.is_correct then 25
          when not di.is_correct and q.theoretical_difficulty = 1 then -20
          when not di.is_correct and q.theoretical_difficulty = 2 then -10
          else -5
        end
      )::integer as point_delta
    from public.diagnostic_items di
    join public.diagnostic_sessions ds on ds.id = di.session_id
    join public.diagnostics d on d.id = ds.diagnostic_id
    join public.questions q on q.id = di.question_id
    where d.student_id = auth.uid()
      and di.answered_at is not null
    group by q.micro_skill_id
  ), errors as (
    select
      di.id,
      di.answered_at,
      q.legacy_id,
      q.micro_skill_id,
      dmn.name as domain,
      ms.student_name as skill,
      replace(ms.code, 'legacy_', '') as competence_id,
      qv.prompt,
      selected.content as selected_answer,
      correct.content as correct_answer,
      qv.correction_explanation,
      coalesce(e.evidence_count, 0) as evidence_count,
      greatest(0, least(100, 50 + coalesce(e.point_delta, 0))) as mastery_score,
      (
        coalesce(e.evidence_count, 0) >= 5
        and greatest(0, least(100, 50 + coalesce(e.point_delta, 0))) >= 80
      ) as resolved
    from public.diagnostic_items di
    join public.diagnostic_sessions ds on ds.id = di.session_id
    join public.diagnostics diagnostic on diagnostic.id = ds.diagnostic_id
    join public.questions q on q.id = di.question_id
    join public.question_versions qv on qv.id = di.question_version_id
    join public.answer_choices selected on selected.id = di.selected_choice_id
    join public.answer_choices correct
      on correct.question_version_id = di.question_version_id
     and correct.is_correct
    join public.micro_skills ms on ms.id = q.micro_skill_id
    join public.skills s on s.id = ms.skill_id
    join public.domains dmn on dmn.id = s.domain_id
    left join evidence e on e.micro_skill_id = q.micro_skill_id
    where diagnostic.student_id = auth.uid()
      and di.is_correct is false
      and di.answered_at is not null
    order by di.answered_at desc
    limit 200
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'questionId', legacy_id,
        'microSkillId', micro_skill_id,
        'competenceId', competence_id,
        'domain', domain,
        'skill', skill,
        'prompt', prompt,
        'selectedAnswer', selected_answer,
        'correctAnswer', correct_answer,
        'explanation', correction_explanation,
        'answeredAt', answered_at,
        'evidenceCount', evidence_count,
        'masteryScore', mastery_score,
        'resolved', resolved
      )
      order by answered_at desc
    ),
    '[]'::jsonb
  )
  from errors;
$function$;

revoke all on function public.get_my_error_notebook() from public;
grant execute on function public.get_my_error_notebook() to authenticated;

commit;

