/*
 CAP-COLLEGE DATABASE
 File: database/176_correct_french_6e_lot_11_feedback_round_2.sql
 Purpose: Apply the second validator feedback for question F6-0333.
 Idempotent: Yes
*/

begin;

do $block$
declare
  selected_question_id uuid;
  target_version_id uuid;
  answer record;
  choices text[] := array[
    'Je n’avais pas encore entendu cette chanson.',
    'Je n’avais jamais aimé cette chanson.',
    'Je n’avais rien dit sur cette chanson.',
    'Avais-je déjà entendu cette chanson ?'
  ];
begin
  select q.id into selected_question_id
  from public.questions q
  where q.legacy_id = 1000333;

  if selected_question_id is null then
    raise exception 'Question 1000333 introuvable.';
  end if;

  target_version_id := md5(
    'cap-college:french-lot-11-feedback:1000333:v3'
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
    3,
    'Quelle phrase indique que l’écoute de la chanson était prévue plus tard, mais n’avait pas encore eu lieu à ce moment du passé ?',
    '« n’avais pas encore entendu » indique qu’une action n’était pas accomplie à ce moment du passé, mais pouvait l’être ensuite.',
    'La consigne ne reprend plus la réponse attendue et s’appuie sur une situation temporelle.',
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
    select value as content, ordinality::smallint as sort_order
    from unnest(choices) with ordinality as choice(value, ordinality)
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
        'cap-college:french-lot-11-feedback:1000333:v3:' ||
        answer.sort_order
      )::uuid,
      target_version_id,
      chr(64 + answer.sort_order),
      answer.content,
      answer.sort_order = 1,
      answer.sort_order
    );
  end loop;

  update public.questions
  set current_version_number = 3,
      status = 'in_review'::public.question_status,
      updated_at = statement_timestamp()
  where id = selected_question_id;
end;
$block$;

commit;
