/*
 CAP-COLLEGE DATABASE
 File: database/293_correct_mathematics_5e_lot_01_feedback.sql
 Purpose: Apply validator feedback to Mathematics 5e lot 01.
 Idempotent: Yes.
*/

begin;

do $block$
declare
  correction record;
  answer record;
  selected_question_id uuid;
  source_version_id uuid;
  source_version_number integer;
  target_version_id uuid;
  target_version_number integer;
begin
  for correction in
    select *
    from (
      values
        (5000027,
         'On forme un nombre à trois chiffres commençant par 47. Quel chiffre des unités faut-il choisir pour que ce nombre soit divisible par 3 ?',
         array['0','2','7','5'],
         3,
         'Avec 7 comme chiffre des unités, la somme des chiffres vaut 4 + 7 + 7 = 18, qui est divisible par 3.',
         'Le symbole carré mal affiché est remplacé par une formulation entièrement textuelle.'),
        (5000030,
         'Sans effectuer la division, pourquoi 8 415 est-il divisible par 3 ?',
         array[
           'Il se termine par 5.',
           'La somme de ses chiffres vaut 18, et 18 est divisible par 3.',
           'Son chiffre des unités est impair.',
           'Il contient le chiffre 3.'
         ],
         2,
         '8 + 4 + 1 + 5 = 18, et 18 est divisible par 3.',
         'La bonne proposition énonce désormais le critère complet de divisibilité par 3.')
    ) as data(
      legacy_id,
      prompt,
      choices,
      correct_position,
      explanation,
      change_comment
    )
  loop
    select q.id, q.current_version_number, qv.id
    into selected_question_id, source_version_number, source_version_id
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number
    where q.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % introuvable.', correction.legacy_id;
    end if;

    if exists (
      select 1
      from public.question_versions qv
      where qv.id = source_version_id
        and qv.prompt = correction.prompt
        and qv.change_comment = correction.change_comment
    ) then
      continue;
    end if;

    target_version_number := source_version_number + 1;
    target_version_id := md5(
      'cap-college:mathematics-5e-lot-01-feedback:' ||
      correction.legacy_id || ':v' || target_version_number
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
      correction.prompt,
      correction.explanation,
      correction.change_comment,
      'unreviewed'::public.review_status,
      auth.uid()
    );

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
      ) values (
        md5(
          'cap-college:mathematics-5e-lot-01-feedback:' ||
          correction.legacy_id || ':v' || target_version_number || ':' ||
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
    set current_version_number = target_version_number,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected_question_id;
  end loop;
end;
$block$;

commit;
