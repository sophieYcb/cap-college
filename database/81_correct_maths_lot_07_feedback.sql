/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/81_correct_maths_lot_07_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Apply validator feedback to questions 600241 and 600259.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  correction record;
  selected_question_id uuid;
  source_version_id uuid;
  target_version_id uuid;
  source_explanation text;
  answer record;
begin
  for correction in
    select *
    from (
      values
        (
          600241::bigint,
          2,
          'Quelle division correspond à la fraction 3/4 ?'::text,
          'Formulation simplifiée pour éviter de confondre résultat exact et écriture décimale.'::text
        ),
        (
          600259::bigint,
          2,
          'Quelle égalité est correcte ?'::text,
          'Consigne rendue plus directe, sans modifier la compétence évaluée.'::text
        )
    ) as corrections(
      legacy_id,
      target_version_number,
      prompt,
      change_comment
    )
  loop
    select
      q.id,
      qv.id,
      qv.correction_explanation
    into
      selected_question_id,
      source_version_id,
      source_explanation
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = 1
    where q.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception
        'Question % ou version source 1 introuvable.',
        correction.legacy_id;
    end if;

    target_version_id := md5(
      'cap-college:maths-lot-07-feedback:' ||
      correction.legacy_id || ':v' ||
      correction.target_version_number
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
      correction.target_version_number,
      correction.prompt,
      source_explanation,
      correction.change_comment,
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
          'cap-college:maths-lot-07-feedback:' ||
          correction.legacy_id || ':v' ||
          correction.target_version_number || ':' ||
          answer.sort_order
        )::uuid,
        target_version_id,
        chr(64 + answer.sort_order),
        answer.content,
        answer.is_correct,
        answer.sort_order
      );
    end loop;

    update public.questions
    set current_version_number = correction.target_version_number,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected_question_id;
  end loop;
end;
$block$;

commit;
