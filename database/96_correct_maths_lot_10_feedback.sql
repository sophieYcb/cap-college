/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/96_correct_maths_lot_10_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Apply validator feedback to question 600382.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  selected_question_id uuid;
  source_explanation text;
  target_version_id uuid;
  answer record;
  corrected_choices jsonb :=
    '["4/100","40/100","60/100","100/100"]'::jsonb;
begin
  select q.id, qv.correction_explanation
  into selected_question_id, source_explanation
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = 1
  where q.legacy_id = 600382;

  if selected_question_id is null then
    raise exception 'Question 600382 ou version source 1 introuvable.';
  end if;

  target_version_id := md5(
    'cap-college:maths-lot-10-feedback:600382:v2'
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
  values (
    target_version_id,
    selected_question_id,
    2,
    'Quelle fraction sur 100 correspond à 40 % ?',
    source_explanation,
    'Toutes les propositions sont désormais des fractions de dénominateur 100, conformément à l’énoncé.',
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
    select
      value #>> '{}' as content,
      ordinality::smallint as sort_order
    from jsonb_array_elements(corrected_choices)
         with ordinality as choice(value, ordinality)
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
        'cap-college:maths-lot-10-feedback:600382:v2:' ||
        answer.sort_order
      )::uuid,
      target_version_id,
      chr(64 + answer.sort_order),
      answer.content,
      answer.sort_order = 2,
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
