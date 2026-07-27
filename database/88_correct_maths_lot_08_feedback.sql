/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/88_correct_maths_lot_08_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Apply validator feedback to questions 600283, 600285 and 600286.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  correction record;
  selected_question_id uuid;
  source_explanation text;
  target_version_id uuid;
  answer record;
begin
  for correction in
    select *
    from (
      values
        (
          600283::bigint,
          'Quelle fraction est égale à 3/5 ?'::text,
          '["6/8","6/12","9/15","12/15"]'::jsonb,
          3::smallint,
          'Suppression de la seconde réponse correcte 6/10.'::text
        ),
        (
          600285::bigint,
          'Complète : 1/3 = …/12.'::text,
          '["4","3","6","9"]'::jsonb,
          1::smallint,
          'Les propositions donnent uniquement le numérateur manquant.'::text
        ),
        (
          600286::bigint,
          'Complète : 5/8 = …/24.'::text,
          '["10","15","20","21"]'::jsonb,
          2::smallint,
          'Les propositions donnent uniquement le numérateur manquant.'::text
        )
    ) as corrections(
      legacy_id,
      prompt,
      choices,
      correct_position,
      change_comment
    )
  loop
    select q.id, qv.correction_explanation
    into selected_question_id, source_explanation
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
      'cap-college:maths-lot-08-feedback:' ||
      correction.legacy_id || ':v2'
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
      select
        value #>> '{}' as content,
        ordinality::smallint as sort_order
      from jsonb_array_elements(correction.choices)
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
          'cap-college:maths-lot-08-feedback:' ||
          correction.legacy_id || ':v2:' ||
          answer.sort_order
        )::uuid,
        target_version_id,
        chr(64 + answer.sort_order),
        answer.content,
        answer.sort_order = correction.correct_position,
        answer.sort_order
      );
    end loop;

    update public.questions
    set current_version_number = 2,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected_question_id;
  end loop;
end;
$block$;

commit;
