/*
===============================================================================
 CAP-COLLEGE DATABASE - CORRECT MATHS LOT 05 FEEDBACK
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/75_correct_maths_lot_05_feedback.sql
 Purpose      : Remove ambiguous midpoint rounding and unnecessary zeros.
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
        (600163::bigint,
         'Quel est l’arrondi de 12,096 au centième ?',
         '["12,09","12,096","12,10","12,9"]'::jsonb,
         3::smallint,
         'Le chiffre des millièmes est 6 : le centième 9 augmente et le nombre s’arrondit à 12,10.',
         'Suppression d’un cas exactement à mi-chemin entre deux centièmes.'),
        (600167::bigint,
         'Quel est l’arrondi de 6,906 au centième ?',
         '["6,90","6,906","6,91","6,9"]'::jsonb,
         3::smallint,
         'Le chiffre des millièmes est 6 : le centième 0 devient 1.',
         'Suppression d’un cas exactement à mi-chemin entre deux centièmes.'),
        (600180::bigint,
         'Calcule 47,058 + 3,942.',
         '["50","50,1","50,9","51"]'::jsonb,
         4::smallint,
         '47,058 + 3,942 = 51.',
         'Suppression des zéros inutiles dans toutes les propositions.')
    ) as requested(
      legacy_id,
      replacement_prompt,
      choices,
      correct_position,
      replacement_explanation,
      change_comment
    )
  loop
    select question.id, version.correction_explanation
    into selected_question_id, source_explanation
    from public.questions question
    join public.question_versions version
      on version.question_id = question.id
     and version.version_number = 1
    where question.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % ou version source 1 introuvable',
        correction.legacy_id;
    end if;

    target_version_id :=
      md5(
        'cap-college:maths-lot-05-feedback:' ||
        correction.legacy_id || ':v2'
      )::uuid;

    insert into public.question_versions (
      id, question_id, version_number, prompt, correction_explanation,
      change_comment, review_status, authored_by
    )
    values (
      target_version_id,
      selected_question_id,
      2,
      correction.replacement_prompt,
      coalesce(correction.replacement_explanation, source_explanation),
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
      select value #>> '{}' content, ordinality::smallint sort_order
      from jsonb_array_elements(correction.choices)
           with ordinality as choice(value, ordinality)
    loop
      insert into public.answer_choices (
        id, question_version_id, choice_key, content, is_correct, sort_order
      )
      values (
        md5(
          'cap-college:maths-lot-05-feedback:' ||
          correction.legacy_id || ':v2:' || answer.sort_order
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
