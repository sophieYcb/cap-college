/*
 CAP-COLLEGE DATABASE
 File: database/211_clarify_question_108_present_tense.sql
 Purpose: Clarify the tense requested by original French question 108.
 Idempotent: Yes
*/

begin;

do $block$
declare
  selected_question_id uuid;
  source_version_number integer;
  target_version_number integer;
  source_version_id uuid;
  target_version_id uuid;
begin
  select q.id, q.current_version_number
  into selected_question_id, source_version_number
  from public.questions q
  where q.legacy_id = 108;

  if selected_question_id is null then
    raise exception 'Question 108 not found';
  end if;

  target_version_number := source_version_number + 1;

  if exists (
    select 1
    from public.question_versions qv
    where qv.question_id = selected_question_id
      and qv.prompt =
        'Conjugue le verbe « voir » avec « tu » au présent de l''indicatif.'
  ) then
    return;
  end if;

  select qv.id into source_version_id
  from public.question_versions qv
  where qv.question_id = selected_question_id
    and qv.version_number = source_version_number;

  target_version_id := md5(
    'cap-college:question-108:clarify-present:v'
    || target_version_number
  )::uuid;

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
  select
    target_version_id,
    selected_question_id,
    target_version_number,
    'Conjugue le verbe « voir » avec « tu » au présent de l''indicatif.',
    source.correction_explanation,
    'Le temps demandé est désormais explicite afin d''éviter plusieurs réponses grammaticalement possibles.',
    'unreviewed'::public.review_status,
    auth.uid()
  from public.question_versions source
  where source.id = source_version_id;

  insert into public.answer_choices (
    id,
    question_version_id,
    choice_key,
    content,
    is_correct,
    sort_order
  )
  select
    md5(
      'cap-college:question-108:clarify-present:v'
      || target_version_number || ':' || source_choice.sort_order
    )::uuid,
    target_version_id,
    source_choice.choice_key,
    source_choice.content,
    source_choice.is_correct,
    source_choice.sort_order
  from public.answer_choices source_choice
  where source_choice.question_version_id = source_version_id
  order by source_choice.sort_order;

  update public.questions
  set current_version_number = target_version_number,
      status = 'in_review'::public.question_status,
      updated_at = statement_timestamp()
  where id = selected_question_id;
end;
$block$;

commit;