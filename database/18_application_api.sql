/*
===============================================================================
 CAP-COLLEGE DATABASE — APPLICATION API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 18_application_api.sql
 Purpose      : Secure browser API for authentication and diagnostic answers.
 Dependencies : Database pack 1.2.0
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_my_roles()
returns text[]
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(array_agg(r.code order by r.code), array[]::text[])
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id
  where ur.user_id = auth.uid();
$function$;

create or replace function public.get_published_question_bank()
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
        'competenceId', replace(ms.code, 'legacy_', ''),
        'domaine', d.name,
        'competence', ms.student_name,
        'difficulte', q.theoretical_difficulty,
        'question', qv.prompt,
        'version', qv.version_number,
        'choix', (
          select jsonb_agg(
            jsonb_build_object(
              'id', ac.id,
              'texte', ac.content,
              'ordre', ac.sort_order
            )
            order by ac.sort_order
          )
          from public.answer_choices ac
          where ac.question_version_id = qv.id
        )
      )
      order by q.legacy_id
    ),
    '[]'::jsonb
  )
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  join public.micro_skills ms on ms.id = q.micro_skill_id
  join public.skills s on s.id = ms.skill_id
  join public.domains d on d.id = s.domain_id
  where q.status = 'published'
    and q.active;
$function$;

create or replace function public.start_diagnostic_session(
  planned_minutes smallint,
  requested_subject_code text default 'french',
  requested_level_code text default '6e'
)
returns table (diagnostic_id uuid, session_id uuid)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  new_diagnostic_id uuid;
  new_session_id uuid;
  selected_subject_id smallint;
  selected_level_id smallint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if planned_minutes not between 1 and 180 then
    raise exception 'Invalid planned duration';
  end if;

  select id into selected_subject_id
  from public.subjects
  where code = requested_subject_code and active;

  select id into selected_level_id
  from public.levels
  where code = requested_level_code and active;

  if selected_subject_id is null or selected_level_id is null then
    raise exception 'Unknown subject or level';
  end if;

  insert into public.diagnostics (student_id, subject_id, level_id)
  values (auth.uid(), selected_subject_id, selected_level_id)
  returning id into new_diagnostic_id;

  insert into public.diagnostic_sessions (
    diagnostic_id,
    planned_minutes
  )
  values (new_diagnostic_id, planned_minutes)
  returning id into new_session_id;

  return query select new_diagnostic_id, new_session_id;
end;
$function$;

create or replace function public.submit_diagnostic_answer(
  requested_session_id uuid,
  requested_question_version_id uuid,
  requested_choice_id uuid,
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
  if requested_sequence_number < 1 then
    raise exception 'Invalid sequence number';
  end if;

  select q.id, qv.correction_explanation
  into selected_question_id, explanation
  from public.question_versions qv
  join public.questions q on q.id = qv.question_id
  join public.diagnostic_sessions ds on ds.id = requested_session_id
  join public.diagnostics d on d.id = ds.diagnostic_id
  where qv.id = requested_question_version_id
    and q.current_version_number = qv.version_number
    and q.status = 'published'
    and q.active
    and ds.status = 'active'
    and d.student_id = auth.uid();

  if selected_question_id is null then
    raise exception 'Question or session is not available';
  end if;

  if not exists (
    select 1
    from public.answer_choices ac
    where ac.id = requested_choice_id
      and ac.question_version_id = requested_question_version_id
  ) then
    raise exception 'Choice does not belong to this question';
  end if;

  select ac.id
  into expected_choice_id
  from public.answer_choices ac
  where ac.question_version_id = requested_question_version_id
    and ac.is_correct;

  answer_is_correct := requested_choice_id = expected_choice_id;

  insert into public.diagnostic_items (
    session_id,
    question_id,
    question_version_id,
    selected_choice_id,
    sequence_number,
    is_correct,
    answered_at
  )
  values (
    requested_session_id,
    selected_question_id,
    requested_question_version_id,
    requested_choice_id,
    requested_sequence_number,
    answer_is_correct,
    statement_timestamp()
  )
  on conflict (session_id, sequence_number) do update
  set question_id = excluded.question_id,
      question_version_id = excluded.question_version_id,
      selected_choice_id = excluded.selected_choice_id,
      is_correct = excluded.is_correct,
      answered_at = excluded.answered_at;

  return query
  select answer_is_correct, expected_choice_id, explanation;
end;
$function$;

revoke all on function public.get_my_roles() from public;
revoke all on function public.get_published_question_bank() from public;
revoke all on function public.start_diagnostic_session(smallint, text, text)
  from public;
revoke all on function public.submit_diagnostic_answer(uuid, uuid, uuid, integer)
  from public;

grant execute on function public.get_my_roles() to authenticated;
grant execute on function public.get_published_question_bank()
  to authenticated;
grant execute on function public.start_diagnostic_session(smallint, text, text)
  to authenticated;
grant execute on function public.submit_diagnostic_answer(uuid, uuid, uuid, integer)
  to authenticated;

-- Diagnostic evidence must only be written through the verified RPC above.
revoke insert, update, delete on public.diagnostic_items from authenticated;

commit;
