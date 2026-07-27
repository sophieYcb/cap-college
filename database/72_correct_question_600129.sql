/*
===============================================================================
 CAP-COLLEGE DATABASE - CORRECT QUESTION 600129
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/72_correct_question_600129.sql
 Purpose      : Align the wording with the two bounds shown in each answer.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  selected_question_id uuid;
  source_version_id uuid;
  target_version_id uuid;
  source_explanation text;
  answer record;
begin
  select
    question.id,
    version.id,
    version.correction_explanation
  into
    selected_question_id,
    source_version_id,
    source_explanation
  from public.questions question
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = 1
  where question.legacy_id = 600129;

  if selected_question_id is null then
    raise exception 'Question 600129 ou version source 1 introuvable';
  end if;

  target_version_id :=
    md5('cap-college:correct-question-600129:v2')::uuid;

  insert into public.question_versions (
    id,
    question_id,
    version_number,
    prompt,
    correction_explanation,
    change_comment,
    review_status,
    authored_by
  )
  values (
    target_version_id,
    selected_question_id,
    2,
    'Quels nombres peuvent encadrer 6,999 au dixième ?',
    source_explanation,
    'Accord de l’énoncé avec les deux bornes proposées dans chaque réponse.',
    'unreviewed'::public.review_status,
    auth.uid()
  )
  on conflict (question_id, version_number) do update
  set prompt = excluded.prompt,
      correction_explanation = excluded.correction_explanation,
      change_comment = excluded.change_comment,
      review_status = excluded.review_status
  returning id into target_version_id;

  delete from public.answer_choices
  where question_version_id = target_version_id;

  for answer in
    select content, is_correct, sort_order
    from public.answer_choices
    where question_version_id = source_version_id
    order by sort_order
  loop
    insert into public.answer_choices (
      id,
      question_version_id,
      choice_key,
      content,
      is_correct,
      sort_order
    )
    values (
      md5(
        'cap-college:correct-question-600129:v2:' || answer.sort_order
      )::uuid,
      target_version_id,
      chr(64 + answer.sort_order),
      answer.content,
      answer.is_correct,
      answer.sort_order
    );
  end loop;

  update public.questions
  set current_version_number = 2,
      status = 'in_review'::public.question_status,
      updated_at = statement_timestamp()
  where id = selected_question_id;
end;
$block$;

commit;
