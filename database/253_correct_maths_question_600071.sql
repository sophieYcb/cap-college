/*
 CAP-COLLEGE DATABASE
 File: database/253_correct_maths_question_600071.sql
 Purpose: Remove the second mathematically correct answer from question 600071.
 Idempotent: Yes
*/

begin;

do $block$
declare
  question_record record;
  source_version record;
  source_choice record;
  target_version_number integer;
  target_version_id uuid;
begin
  select q.id, q.current_version_number
  into question_record
  from public.questions q
  where q.legacy_id = 600071;

  if question_record.id is null then
    raise exception 'Question 600071 introuvable.';
  end if;

  select qv.*
  into source_version
  from public.question_versions qv
  where qv.question_id = question_record.id
    and qv.version_number = question_record.current_version_number;

  if exists (
    select 1
    from public.answer_choices choice
    where choice.question_version_id = source_version.id
      and choice.sort_order = 3
      and choice.content = '60/1 000'
      and not choice.is_correct
  ) then
    return;
  end if;

  target_version_number := question_record.current_version_number + 1;
  target_version_id := md5(
    'cap-college:correct-maths-question-600071:v' || target_version_number
  )::uuid;

  insert into public.question_versions (
    id, question_id, version_number, prompt, correction_explanation,
    change_comment, review_status, authored_by
  )
  values (
    target_version_id,
    question_record.id,
    target_version_number,
    source_version.prompt,
    source_version.correction_explanation,
    'Remplacement de 60/100, également égal à 0,6, par un distracteur faux.',
    'unreviewed'::public.review_status,
    auth.uid()
  );

  for source_choice in
    select choice.*
    from public.answer_choices choice
    where choice.question_version_id = source_version.id
    order by choice.sort_order
  loop
    insert into public.answer_choices (
      id, question_version_id, choice_key, content, is_correct, sort_order
    )
    values (
      md5(
        'cap-college:correct-maths-question-600071:v'
        || target_version_number || ':' || source_choice.sort_order
      )::uuid,
      target_version_id,
      source_choice.choice_key,
      case when source_choice.sort_order = 3 then '60/1 000' else source_choice.content end,
      source_choice.is_correct,
      source_choice.sort_order
    );
  end loop;

  update public.questions
  set current_version_number = target_version_number,
      status = 'in_review'::public.question_status,
      updated_at = statement_timestamp()
  where id = question_record.id;
end;
$block$;

commit;