/*
 CAP-COLLEGE DATABASE
 File: database/155_restore_french_6e_lot_05_subject_groups.sql
 Purpose: Restore complete subject groups and keep their nuclei as distractors.
 Idempotent: Yes
*/

begin;

do $block$
declare
  r record;
  qid uuid;
  vid uuid;
begin
  for r in
    select * from (
      values
        (
          1000136,
          'Dans « Les clés de la maison sont dans ce tiroir », quel est le groupe sujet de « sont » ?',
          array['Les clés','dans ce tiroir','la maison','Les clés de la maison'],
          4,
          'Le groupe sujet complet est « Les clés de la maison ». « Les clés » est son noyau et sert de distracteur.'
        ),
        (
          1000139,
          'Dans « La grande horloge du salon sonne midi », quel est le groupe sujet de « sonne » ?',
          array['du salon','midi','La grande horloge du salon','horloge'],
          3,
          'Le groupe sujet complet est « La grande horloge du salon ». « horloge » est son noyau et sert de distracteur.'
        )
    ) as x(legacy_id, prompt, choices, correct_position, explanation)
  loop
    select id into qid
    from public.questions
    where legacy_id = r.legacy_id;

    if qid is null then
      raise exception 'Question % introuvable.', r.legacy_id;
    end if;

    vid := md5(
      'cap-college:french-lot-05-subject-groups:' ||
      r.legacy_id || ':v3'
    )::uuid;

    insert into public.question_versions (
      id, question_id, version_number, prompt, correction_explanation,
      change_comment, review_status, authored_by
    )
    values (
      vid, qid, 3, r.prompt, r.explanation,
      'Restauration du groupe sujet complet ; ajout de son noyau comme distracteur.',
      'unreviewed'::public.review_status, auth.uid()
    )
    on conflict (question_id, version_number) do update
    set prompt = excluded.prompt,
        correction_explanation = excluded.correction_explanation,
        change_comment = excluded.change_comment,
        review_status = excluded.review_status
    returning id into vid;

    delete from public.answer_choices
    where question_version_id = vid;

    insert into public.answer_choices (
      id, question_version_id, choice_key, content, is_correct, sort_order
    )
    select
      md5(
        'cap-college:french-lot-05-subject-groups:' ||
        r.legacy_id || ':v3:' || position
      )::uuid,
      vid,
      chr(64 + position::integer),
      answer,
      position = r.correct_position,
      position
    from unnest(r.choices)
      with ordinality as choice(answer, position);

    update public.questions
    set current_version_number = 3,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = qid;
  end loop;
end;
$block$;

commit;
