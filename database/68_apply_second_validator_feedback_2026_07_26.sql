/*
===============================================================================
 CAP-COLLEGE DATABASE - SECOND VALIDATOR FEEDBACK 2026-07-26
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/68_apply_second_validator_feedback_2026_07_26.sql
 Purpose      : Restore question 299 version 3 content and revise question 325.
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
  source_prompt text;
  source_explanation text;
  answer record;
begin
  for correction in
    select *
    from (
      values
        (
          299::bigint,
          3,
          5,
          '["médames","mesdames","mes dames","madames"]'::jsonb,
          2::smallint,
          'Restauration demandée du contenu de la version 3.'
        ),
        (
          325::bigint,
          4,
          5,
          '["entrouvrir","fermer","écarter","déverrouiller"]'::jsonb,
          2::smallint,
          'Remplacement du distracteur C après la seconde validation.'
        )
    ) as requested(
      legacy_id,
      source_version_number,
      target_version_number,
      choices,
      correct_position,
      change_comment
    )
  loop
    select
      question.id,
      version.id,
      version.prompt,
      version.correction_explanation
    into
      selected_question_id,
      source_version_id,
      source_prompt,
      source_explanation
    from public.questions question
    join public.question_versions version
      on version.question_id = question.id
     and version.version_number = correction.source_version_number
    where question.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % ou version source % introuvable',
        correction.legacy_id,
        correction.source_version_number;
    end if;

    target_version_id :=
      md5(
        'cap-college:second-validator-feedback:2026-07-26:' ||
        correction.legacy_id || ':v' || correction.target_version_number
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
      source_prompt,
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
          'cap-college:second-validator-feedback:2026-07-26:' ||
          correction.legacy_id || ':v' ||
          correction.target_version_number || ':' || answer.sort_order
        )::uuid,
        target_version_id,
        chr(64 + answer.sort_order),
        answer.content,
        answer.sort_order = correction.correct_position,
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
