/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/139_correct_french_6e_lot_01_second_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Apply the second validator feedback for French 6e lot 01.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  correction record;
  answer record;
  selected_question_id uuid;
  target_version_id uuid;
begin
  for correction in
    select *
    from (
      values
        (
          1000003,
          'Dans « Les touristes visitent Marseille demain », quel mot est un nom propre ?',
          array['touristes','visitent','Marseille','demain'],
          3,
          '« Marseille » est un nom propre, tandis que « touristes » est un nom commun.',
          'Le nom commun « touristes » remplace « Les » afin de constituer un distracteur plus pertinent.'
        ),
        (
          1000012,
          'Dans « Voyager permet de découvrir le monde », quel mot est un verbe à l’infinitif ?',
          array['permet','le','de','Voyager'],
          4,
          '« Voyager » est un verbe à l’infinitif, tandis que « permet » est un verbe conjugué.',
          'Le verbe conjugué « permet » remplace « monde » afin de mieux vérifier la reconnaissance de l’infinitif.'
        ),
        (
          1000021,
          'Dans « Il répond toujours poliment », quel mot est un adverbe de temps ?',
          array['toujours','répond','Il','poliment'],
          1,
          '« Toujours » situe l’action dans une continuité temporelle : c’est un adverbe de temps.',
          'Conformément au guide officiel « La grammaire du français du CP à la 6e », « toujours » est classé parmi les adverbes de temps.'
        )
    ) as data(
      legacy_id,
      prompt,
      choices,
      correct_position,
      explanation,
      change_comment
    )
  loop
    select q.id
    into selected_question_id
    from public.questions q
    where q.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % introuvable.', correction.legacy_id;
    end if;

    target_version_id := md5(
      'cap-college:french-lot-01-second-feedback:' ||
      correction.legacy_id || ':v3'
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
      correction.prompt,
      correction.explanation,
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
      select value as content, ordinality::smallint as sort_order
      from unnest(correction.choices) with ordinality as choice(value, ordinality)
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
          'cap-college:french-lot-01-second-feedback:' ||
          correction.legacy_id || ':v3:' || answer.sort_order
        )::uuid,
        target_version_id,
        chr(64 + answer.sort_order),
        answer.content,
        answer.sort_order = correction.correct_position,
        answer.sort_order
      );
    end loop;

    update public.questions
    set current_version_number = 3,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected_question_id;
  end loop;
end;
$block$;

commit;
