/*
 CAP-COLLEGE DATABASE
 File: database/265_persist_learner_exercise_assistance.sql
 Purpose: Preserve the learner's assistance level between exercise sessions
          for the same micro-skill.
 Idempotent: Yes
*/

begin;

create or replace function public.start_learner_remediation_session_v2(
  requested_token text,
  requested_competence_id text,
  requested_question_count smallint
)
returns table (
  session_id uuid,
  competence text,
  reminder text,
  worked_example text,
  question_target smallint,
  initial_assistance text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_micro_skill public.micro_skills%rowtype;
  selected_resource public.learning_resources%rowtype;
  new_session_id uuid;
  successful_recent_attempts boolean := false;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;
  if requested_question_count not in (5, 10) then
    raise exception 'Exercise session must contain 5 or 10 questions';
  end if;

  select micro_skill.* into selected_micro_skill
  from public.learner_profiles learner
  join public.micro_skill_levels level_link
    on level_link.level_id = learner.level_id
   and level_link.is_expected
  join public.micro_skills micro_skill
    on micro_skill.id = level_link.micro_skill_id
  where replace(micro_skill.code, 'legacy_', '') = requested_competence_id
    and learner.id = selected_learner_id
    and micro_skill.active
  limit 1;

  if selected_micro_skill.id is null then
    raise exception 'Unknown competency';
  end if;

  select resource.* into selected_resource
  from public.learning_resources resource
  where resource.micro_skill_id = selected_micro_skill.id
    and resource.active
  order by resource.version_number desc
  limit 1;

  select count(*) = 3 and bool_and(recent.is_correct)
  into successful_recent_attempts
  from (
    select attempt.is_correct
    from public.remediation_sessions previous_session
    join public.remediation_attempts attempt
      on attempt.remediation_session_id = previous_session.id
     and attempt.answered_at is not null
    where previous_session.learner_profile_id = selected_learner_id
      and previous_session.micro_skill_id = selected_micro_skill.id
    order by attempt.answered_at desc, attempt.id desc
    limit 3
  ) recent;

  insert into public.remediation_sessions (
    student_id, learner_profile_id, micro_skill_id, resource_id,
    planned_minutes, question_target
  ) values (
    null, selected_learner_id, selected_micro_skill.id,
    selected_resource.id,
    case requested_question_count when 5 then 3 else 5 end,
    requested_question_count
  ) returning id into new_session_id;

  return query select
    new_session_id,
    selected_micro_skill.student_name,
    coalesce(
      selected_resource.reminder,
      selected_micro_skill.lesson_reminder
    ),
    coalesce(
      selected_resource.worked_example,
      selected_micro_skill.worked_example
    ),
    requested_question_count,
    case when successful_recent_attempts
      then 'without_reminder' else 'with_reminder' end;
end;
$function$;

revoke all on function public.start_learner_remediation_session_v2(
  text, text, smallint
) from public;
grant execute on function public.start_learner_remediation_session_v2(
  text, text, smallint
) to anon, authenticated;

commit;
