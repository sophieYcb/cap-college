/*
 CAP-COLLEGE DATABASE
 File: database/291_allow_skipped_diagnostic_questions.sql
 Purpose: Allow a learner to pass a diagnostic question without guessing.
 Idempotent: Yes.
*/

begin;
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

  if requested_choice_id is not null and not exists (
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

  answer_is_correct := requested_choice_id is not null and requested_choice_id = expected_choice_id;

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

create or replace function public.submit_learner_diagnostic_answer(
  requested_token text,
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
language plpgsql security definer set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  selected_question_id uuid;
  expected_choice_id uuid;
  answer_is_correct boolean;
  explanation text;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then raise exception 'Learner session required'; end if;
  if requested_sequence_number < 1 then raise exception 'Invalid sequence number'; end if;

  select q.id, qv.correction_explanation
  into selected_question_id, explanation
  from public.question_versions qv
  join public.questions q on q.id = qv.question_id
  join public.diagnostic_sessions ds on ds.id = requested_session_id
  join public.diagnostics d on d.id = ds.diagnostic_id
  where qv.id = requested_question_version_id
    and q.current_version_number = qv.version_number
    and q.status = 'published' and q.active
    and ds.status = 'active'
    and d.learner_profile_id = selected_learner_id;

  if selected_question_id is null then
    raise exception 'Question or session is not available';
  end if;
  if requested_choice_id is not null and not exists (
    select 1 from public.answer_choices ac
    where ac.id = requested_choice_id
      and ac.question_version_id = requested_question_version_id
  ) then raise exception 'Choice does not belong to this question'; end if;

  select ac.id into expected_choice_id
  from public.answer_choices ac
  where ac.question_version_id = requested_question_version_id
    and ac.is_correct;

  answer_is_correct := requested_choice_id is not null and requested_choice_id = expected_choice_id;

  insert into public.diagnostic_items (
    session_id, question_id, question_version_id, selected_choice_id,
    sequence_number, is_correct, answered_at
  ) values (
    requested_session_id, selected_question_id,
    requested_question_version_id, requested_choice_id,
    requested_sequence_number, answer_is_correct, statement_timestamp()
  )
  on conflict (session_id, sequence_number) do update
  set question_id = excluded.question_id,
      question_version_id = excluded.question_version_id,
      selected_choice_id = excluded.selected_choice_id,
      is_correct = excluded.is_correct,
      answered_at = excluded.answered_at;

  return query select answer_is_correct, expected_choice_id, explanation;
end;
$function$;
comment on function public.submit_diagnostic_answer(uuid, uuid, uuid, integer) is
  'Records an answer; a null choice means the learner deliberately passed the question.';
comment on function public.submit_learner_diagnostic_answer(text, uuid, uuid, uuid, integer) is
  'Records a learner answer; a null choice means the learner deliberately passed the question.';

commit;
