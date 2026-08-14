/*
 CAP-COLLEGE DATABASE
 File: database/298_correct_mathematics_5e_question_5000067.sql
 Purpose: Replace the misplaced literal-expression question in Mathematics 5e lot 02.
 Idempotent: Yes.
*/

begin;

do $block$
declare
  selected_question_id uuid;
  source_version_id uuid;
  source_version_number integer;
  target_version_id uuid;
  target_version_number integer;
  target_prompt constant text :=
    'Une salle possède 12 rangées de 18 sièges, puis on ajoute 4 rangées de 15 sièges. Quelle expression donne le nombre total de sièges ?';
  target_comment constant text :=
    'La question littérale, relevant du calcul algébrique, est remplacée par une traduction numérique adaptée à la micro-compétence évaluée.';
begin
  select question.id, question.current_version_number, version.id
  into selected_question_id, source_version_number, source_version_id
  from public.questions question
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = question.current_version_number
  where question.legacy_id = 5000067;

  if selected_question_id is null then
    raise exception 'Question 5000067 introuvable.';
  end if;

  if exists (
    select 1
    from public.question_versions version
    where version.id = source_version_id
      and version.prompt = target_prompt
      and version.change_comment = target_comment
  ) then
    return;
  end if;

  target_version_number := source_version_number + 1;
  target_version_id := md5(
    'cap-college:mathematics-5e-question-5000067:v' ||
    target_version_number
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
  ) values (
    target_version_id,
    selected_question_id,
    target_version_number,
    target_prompt,
    'Les sièges déjà présents sont représentés par 12 × 18 et les sièges ajoutés par 4 × 15 ; on additionne les deux produits.',
    target_comment,
    'unreviewed'::public.review_status,
    auth.uid()
  );

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
      'cap-college:mathematics-5e-question-5000067:v' ||
      target_version_number || ':' || answer.sort_order
    )::uuid,
    target_version_id,
    chr(64 + answer.sort_order),
    answer.content,
    answer.sort_order = 3,
    answer.sort_order
  from (
    values
      ('(12 + 18) × (4 + 15)', 1::smallint),
      ('12 × 18 × 4 × 15', 2::smallint),
      ('12 × 18 + 4 × 15', 3::smallint),
      ('12 + 18 + 4 + 15', 4::smallint)
  ) as answer(content, sort_order);

  update public.questions
  set current_version_number = target_version_number,
      status = 'in_review'::public.question_status,
      updated_at = statement_timestamp()
  where id = selected_question_id;
end;
$block$;

commit;
