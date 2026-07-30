/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/153_correct_french_6e_lot_05_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Apply validator feedback for French 6e lot F6-GRA-05.
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
          1000136,
          'Dans « Les clés de la maison sont dans ce tiroir », quel nom est le noyau du groupe sujet de « sont » ?',
          array['clés','maison','tiroir','sont'],
          1,
          'Dans le groupe sujet « Les clés de la maison », le nom noyau est « clés ».',
          'Le retour de validation demande une réponse centrée sur « clés » en proposition A. La consigne précise désormais qu’il faut identifier le nom noyau du groupe sujet.'
        ),
        (
          1000139,
          'Dans « La grande horloge du salon sonne midi », quel nom est le noyau du groupe sujet de « sonne » ?',
          array['salon','midi','grande','horloge'],
          4,
          'Dans le groupe sujet « La grande horloge du salon », le nom noyau est « horloge ».',
          'Le retour de validation demande « horloge » en proposition D. La consigne précise désormais qu’il faut identifier le nom noyau du groupe sujet.'
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
      'cap-college:french-lot-05-feedback:' ||
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
      from unnest(correction.choices)
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
          'cap-college:french-lot-05-feedback:' ||
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
