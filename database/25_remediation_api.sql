/*
===============================================================================
 CAP-COLLEGE DATABASE — GUIDED REMEDIATION API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 25_remediation_api.sql
 Purpose      : Rule/example, practice with help, then practice without help.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_remediation_question_bank(
  requested_competence_id text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.legacy_id,
        'questionId', q.id,
        'questionVersionId', qv.id,
        'difficulte', q.theoretical_difficulty,
        'question', qv.prompt,
        'choix', (
          select jsonb_agg(
            jsonb_build_object(
              'id', ac.id,
              'texte', ac.content
            )
            order by ac.sort_order
          )
          from public.answer_choices ac
          where ac.question_version_id = qv.id
        )
      )
      order by q.theoretical_difficulty, q.legacy_id
    ),
    '[]'::jsonb
  )
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  join public.micro_skills ms on ms.id = q.micro_skill_id
  where replace(ms.code, 'legacy_', '') = requested_competence_id
    and q.status = 'published'
    and q.active;
$function$;

create or replace function public.start_remediation_session(
  requested_competence_id text,
  requested_minutes smallint
)
returns table (
  session_id uuid,
  competence text,
  reminder text,
  worked_example text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_micro_skill public.micro_skills%rowtype;
  selected_resource public.learning_resources%rowtype;
  new_session_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if requested_minutes not in (5, 10, 20) then
    raise exception 'Invalid remediation duration';
  end if;

  select ms.* into selected_micro_skill
  from public.micro_skills ms
  where replace(ms.code, 'legacy_', '') = requested_competence_id
    and ms.active
  limit 1;

  if selected_micro_skill.id is null then
    raise exception 'Unknown competency';
  end if;

  select lr.* into selected_resource
  from public.learning_resources lr
  where lr.micro_skill_id = selected_micro_skill.id
    and lr.active
  order by lr.version_number desc
  limit 1;

  insert into public.remediation_sessions (
    student_id,
    micro_skill_id,
    resource_id,
    planned_minutes
  )
  values (
    auth.uid(),
    selected_micro_skill.id,
    selected_resource.id,
    requested_minutes
  )
  returning id into new_session_id;

  return query
  select
    new_session_id,
    selected_micro_skill.student_name,
    coalesce(selected_resource.reminder, selected_micro_skill.lesson_reminder),
    coalesce(selected_resource.worked_example, selected_micro_skill.worked_example);
end;
$function$;

create or replace function public.submit_remediation_answer(
  requested_session_id uuid,
  requested_question_version_id uuid,
  requested_choice_id uuid,
  requested_assistance public.assistance_mode,
  requested_sequence_number integer
)
returns table (
  is_correct boolean,
  correct_choice_id uuid,
  correction_explanation text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_question_id uuid;
  expected_choice_id uuid;
  answer_is_correct boolean;
  explanation text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select q.id, qv.correction_explanation
  into selected_question_id, explanation
  from public.remediation_sessions rs
  join public.question_versions qv
    on qv.id = requested_question_version_id
  join public.questions q
    on q.id = qv.question_id
   and q.micro_skill_id = rs.micro_skill_id
  where rs.id = requested_session_id
    and rs.student_id = auth.uid()
    and rs.status = 'active'
    and q.status = 'published'
    and q.active;

  if selected_question_id is null then
    raise exception 'Question or remediation session is not available';
  end if;

  if not exists (
    select 1 from public.answer_choices ac
    where ac.id = requested_choice_id
      and ac.question_version_id = requested_question_version_id
  ) then
    raise exception 'Choice does not belong to this question';
  end if;

  select ac.id into expected_choice_id
  from public.answer_choices ac
  where ac.question_version_id = requested_question_version_id
    and ac.is_correct;

  answer_is_correct := requested_choice_id = expected_choice_id;

  insert into public.remediation_attempts (
    remediation_session_id,
    question_id,
    question_version_id,
    selected_choice_id,
    assistance,
    is_correct,
    sequence_number,
    answered_at
  )
  values (
    requested_session_id,
    selected_question_id,
    requested_question_version_id,
    requested_choice_id,
    requested_assistance,
    answer_is_correct,
    requested_sequence_number,
    statement_timestamp()
  )
  on conflict (remediation_session_id, sequence_number) do update
  set selected_choice_id = excluded.selected_choice_id,
      assistance = excluded.assistance,
      is_correct = excluded.is_correct,
      answered_at = excluded.answered_at;

  return query select answer_is_correct, expected_choice_id, explanation;
end;
$function$;

create or replace function public.finish_remediation_session(
  requested_session_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.remediation_sessions
  set status = 'completed',
      completed_at = coalesce(completed_at, statement_timestamp())
  where id = requested_session_id
    and student_id = auth.uid();

  if not found then
    raise exception 'Remediation session is not available';
  end if;
end;
$function$;

revoke all on function public.get_remediation_question_bank(text) from public;
revoke all on function public.start_remediation_session(text, smallint) from public;
revoke all on function public.submit_remediation_answer(
  uuid, uuid, uuid, public.assistance_mode, integer
) from public;
revoke all on function public.finish_remediation_session(uuid) from public;

grant execute on function public.get_remediation_question_bank(text)
  to authenticated;
grant execute on function public.start_remediation_session(text, smallint)
  to authenticated;
grant execute on function public.submit_remediation_answer(
  uuid, uuid, uuid, public.assistance_mode, integer
) to authenticated;
grant execute on function public.finish_remediation_session(uuid)
  to authenticated;

revoke insert, update, delete on public.remediation_sessions from authenticated;
revoke insert, update, delete on public.remediation_attempts from authenticated;

commit;

