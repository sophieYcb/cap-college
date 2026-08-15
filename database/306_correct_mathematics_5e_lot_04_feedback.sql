/*
 CAP-COLLEGE DATABASE
 File: database/306_correct_mathematics_5e_lot_04_feedback.sql
 Purpose: Apply validator feedback to Mathematics 5e lot 04.
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
        (5000114,
         1,
         'Dans un jeu, une variation de −35 points signifie que le joueur…',
         array[
           'gagne 35 points',
           'perd 35 points',
           'termine forcément avec −35 points',
           'ne change pas de score'
         ],
         2,
         'Une variation négative de −35 correspond à une perte de 35 points.',
         'Le vocabulaire bancaire « solde », « crédit » et « découvert », qui pouvait constituer un obstacle non mathématique en 5e, est remplacé par une situation de jeu familière. La notion évaluée reste l’interprétation du signe négatif.'),
        (5000118,
         2,
         'Dans le nombre −18, le signe − indique que le nombre est…',
         array[
           'situé à droite de zéro sur une droite graduée',
           'inférieur à zéro',
           'égal à zéro',
           'égal à +18'
         ],
         2,
         'Le signe − indique que −18 est inférieur à zéro.',
         'Les anciennes propositions A et D étaient ambiguës ou artificielles. Elles sont remplacées par des affirmations simples et comparables portant uniquement sur la position du nombre par rapport à zéro.'),
        (5000129,
         2,
         'Quel nombre faut-il ajouter à −7 pour obtenir 0 ?',
         array['+7','−7','0','14'],
         1,
         '−7 et +7 sont opposés ; leur somme est égale à zéro.',
         'La réponse −7 de la version précédente était exacte car la question portait sur un double opposé, mais cette formulation prêtait à confusion. La nouvelle question demande directement le nombre opposé qui complète la somme à zéro ; la bonne réponse est +7 et la difficulté passe de 3 à 2.'),
        (5000134,
         1,
         'Un randonneur descend de 40 m. Quelle variation d’altitude représente ce déplacement ?',
         array['+40 m','−40 m','0 m','−4 m'],
         2,
         'Une descente de 40 m correspond à une variation d’altitude de −40 m.',
         'La notion de dette, qui pouvait nécessiter un vocabulaire financier non maîtrisé, est remplacée par une variation d’altitude concrète. La compétence mathématique et la valeur −40 sont conservées.')
    ) as data(
      legacy_id,
      difficulty,
      prompt,
      choices,
      correct_position,
      explanation,
      change_comment
    )
  loop
    select question.id, question.current_version_number, version.id
    into selected_question_id, source_version_number, source_version_id
    from public.questions question
    join public.question_versions version
      on version.question_id = question.id
     and version.version_number = question.current_version_number
    where question.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % introuvable.', correction.legacy_id;
    end if;

    if exists (
      select 1
      from public.question_versions version
      where version.id = source_version_id
        and version.prompt = correction.prompt
        and version.change_comment = correction.change_comment
    ) then
      continue;
    end if;

    target_version_number := source_version_number + 1;
    target_version_id := md5(
      'cap-college:mathematics-5e-lot-04-feedback:' ||
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
          'cap-college:mathematics-5e-lot-04-feedback:' ||
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
        theoretical_difficulty = correction.difficulty::text::public.difficulty_level,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected_question_id;
  end loop;
end;
$block$;

commit;
