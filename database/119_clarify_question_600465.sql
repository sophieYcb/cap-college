/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/119_clarify_question_600465.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Make the perimeter expression explicit for sixth-grade pupils.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  selected_question_id uuid;
  target_version_id uuid := md5('cap-college:clarify:600465:v3')::uuid;
  answer record;
  choices jsonb := '["π × 12 cm","π + 12 cm","2 × 12 cm","12 × 12 cm"]'::jsonb;
begin
  select id into selected_question_id
  from public.questions
  where legacy_id = 600465;

  if selected_question_id is null then
    raise exception 'Question 600465 introuvable.';
  end if;

  insert into public.question_versions (
    id, question_id, version_number, prompt, correction_explanation,
    change_comment, review_status, authored_by
  )
  values (
    target_version_id,
    selected_question_id,
    3,
    'Un disque a un diamètre de 12 cm. Quelle expression donne son périmètre ?',
    'Le périmètre d’un disque vaut π multiplié par son diamètre, soit π × 12 cm.',
    'L’écriture π × 12 est utilisée à la place de 12π afin que la multiplication soit immédiatement compréhensible en 6e.',
    'unreviewed'::public.review_status,
    auth.uid()
  )
  on conflict (question_id, version_number) do update
  set prompt = excluded.prompt,
      correction_explanation = excluded.correction_explanation,
      change_comment = excluded.change_comment,
      review_status = excluded.review_status
  returning id into target_version_id;

  delete from public.answer_choices where question_version_id = target_version_id;

  for answer in
    select value #>> '{}' as content, ordinality::smallint as sort_order
    from jsonb_array_elements(choices) with ordinality as item(value, ordinality)
  loop
    insert into public.answer_choices (
      id, question_version_id, choice_key, content, is_correct, sort_order
    )
    values (
      md5('cap-college:clarify:600465:v3:' || answer.sort_order)::uuid,
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
