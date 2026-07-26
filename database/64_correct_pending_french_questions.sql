/*
===============================================================================
 CAP-COLLEGE DATABASE - PENDING FRENCH QUESTION CORRECTIONS
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/64_correct_pending_french_questions.sql
 Purpose      : Align sentence types with the 2025 cycle 3 curriculum and
                apply the remaining validator comments.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  correction record;
  selected_question_id uuid;
  target_version_id uuid;
  source_prompt text;
  source_explanation text;
  choice record;
begin
  for correction in
    select *
    from (
      values
        (61::bigint, 1, 2,
         'Laquelle de ces phrases est de type impératif ?',
         '["Ferme la fenêtre !","La fenêtre est fermée.","La fenêtre est-elle fermée ?","Comme cette fenêtre est grande !"]'::jsonb,
         1,
         'La phrase donne un ordre : elle est de type impératif.'),
        (62::bigint, 1, 2,
         'Laquelle de ces phrases est de type interrogatif ?',
         '["Tu vas à l’école.","Où vas-tu ?","Va à l’école.","Comme cette école est grande !"]'::jsonb,
         2,
         'La phrase pose une question : elle est de type interrogatif.'),
        (63::bigint, 1, 2,
         'Laquelle de ces phrases est de type déclaratif ?',
         '["Le soleil se couche-t-il ?","Regarde le soleil.","Le soleil se couche.","Quel beau coucher de soleil !"]'::jsonb,
         3,
         'La phrase donne une information : elle est de type déclaratif.'),
        (64::bigint, 1, 2,
         'Laquelle de ces phrases est de forme exclamative ?',
         '["Le paysage est beau.","Le paysage est-il beau ?","Regarde le paysage.","Comme ce paysage est beau !"]'::jsonb,
         4,
         'La phrase exprime une émotion et se termine par un point d’exclamation : elle est de forme exclamative.'),
        (65::bigint, 1, 2,
         'Laquelle de ces phrases est de type impératif ?',
         '["Ne courez pas dans le couloir.","Vous ne courez pas dans le couloir.","Courez-vous dans le couloir ?","Comme ce couloir est long !"]'::jsonb,
         1,
         'La phrase donne une interdiction : elle est de type impératif.'),
        (66::bigint, 1, 2,
         'Laquelle de ces phrases est de type interrogatif ?',
         '["Tu as terminé ton travail.","As-tu terminé ton travail ?","Termine ton travail.","Quel travail difficile !"]'::jsonb,
         2,
         'La phrase pose une question : elle est de type interrogatif.'),
        (67::bigint, 1, 2,
         'Laquelle de ces phrases est de type déclaratif ?',
         '["Partirons-nous demain matin ?","Partons demain matin.","Nous partirons demain matin.","Comme ce départ est matinal !"]'::jsonb,
         3,
         'La phrase donne une information : elle est de type déclaratif.'),
        (68::bigint, 1, 2,
         'Laquelle de ces phrases est de forme exclamative ?',
         '["La nouvelle est merveilleuse.","La nouvelle est-elle merveilleuse ?","Écoute cette nouvelle.","Quelle merveilleuse nouvelle !"]'::jsonb,
         4,
         'La phrase exprime une émotion et se termine par un point d’exclamation : elle est de forme exclamative.'),
        (69::bigint, 1, 2,
         'Laquelle de ces phrases est de type impératif ?',
         '["Prenez vos cahiers.","Vous prenez vos cahiers.","Prenez-vous vos cahiers ?","Quels beaux cahiers !"]'::jsonb,
         1,
         'La phrase donne un ordre : elle est de type impératif.'),
        (70::bigint, 1, 2,
         'Laquelle de ces phrases est de type interrogatif ?',
         '["Tu ris souvent.","Pourquoi ris-tu ?","Ris avec nous.","Comme tu ris fort !"]'::jsonb,
         2,
         'La phrase pose une question : elle est de type interrogatif.'),
        (71::bigint, 1, 2,
         'Laquelle de ces phrases est de type déclaratif ?',
         '["Le train entre-t-il en gare ?","Regardez le train.","Le train entre en gare.","Comme ce train est rapide !"]'::jsonb,
         3,
         'La phrase donne une information : elle est de type déclaratif.'),
        (72::bigint, 1, 2,
         'Laquelle de ces phrases est de forme exclamative ?',
         '["Cette musique est agréable.","Cette musique est-elle agréable ?","Écoute cette musique.","Que cette musique est agréable !"]'::jsonb,
         4,
         'La phrase exprime une émotion et se termine par un point d’exclamation : elle est de forme exclamative.'),
        (73::bigint, 1, 2,
         'Laquelle de ces phrases est de type impératif ?',
         '["N’oublie pas ton manteau.","Tu n’oublies pas ton manteau.","As-tu oublié ton manteau ?","Quel beau manteau !"]'::jsonb,
         1,
         'La phrase donne un conseil : elle est de type impératif.'),
        (74::bigint, 1, 2,
         'Laquelle de ces phrases est de type interrogatif ?',
         '["Le film commence bientôt.","Quand commence le film ?","Regardez le film.","Quel film passionnant !"]'::jsonb,
         2,
         'La phrase pose une question : elle est de type interrogatif.'),
        (75::bigint, 1, 2,
         'Laquelle de ces phrases est de type déclaratif ?',
         '["Quand ferme la bibliothèque ?","Fermez la bibliothèque.","La bibliothèque ferme à dix-huit heures.","Comme cette bibliothèque est calme !"]'::jsonb,
         3,
         'La phrase donne une information : elle est de type déclaratif.'),
        (76::bigint, 1, 2,
         'Laquelle de ces phrases est de forme exclamative ?',
         '["Cet exploit est incroyable.","Cet exploit est-il incroyable ?","Admirez cet exploit.","Quel incroyable exploit !"]'::jsonb,
         4,
         'La phrase exprime une émotion et se termine par un point d’exclamation : elle est de forme exclamative.'),
        (77::bigint, 1, 2,
         'Laquelle de ces phrases est de type impératif ?',
         '["Écoutez attentivement.","Vous écoutez attentivement.","Écoutez-vous attentivement ?","Quelle écoute attentive !"]'::jsonb,
         1,
         'La phrase donne un ordre : elle est de type impératif.'),
        (78::bigint, 1, 2,
         'Laquelle de ces phrases est de type interrogatif ?',
         '["Tu viens avec nous.","Est-ce que tu viens avec nous ?","Viens avec nous.","Comme cette sortie sera agréable !"]'::jsonb,
         2,
         'La phrase pose une question : elle est de type interrogatif.'),
        (79::bigint, 1, 2,
         'Laquelle de ces phrases est de type déclaratif ?',
         '["Ton frère joue-t-il au tennis ?","Joue au tennis.","Mon frère joue au tennis.","Quel beau match de tennis !"]'::jsonb,
         3,
         'La phrase donne une information : elle est de type déclaratif.'),
        (80::bigint, 1, 2,
         'Laquelle de ces phrases est de forme exclamative ?',
         '["Il fait froid aujourd’hui.","Fait-il froid aujourd’hui ?","Habille-toi chaudement.","Comme il fait froid aujourd’hui !"]'::jsonb,
         4,
         'La phrase exprime une émotion et se termine par un point d’exclamation : elle est de forme exclamative.'),
        (299::bigint, 2, 3, null::text,
         '["médames","mesdames","mes dames","madames"]'::jsonb,
         2, null::text),
        (325::bigint, 2, 3, null::text,
         '["entrouvrir","déverrouiller","débloquer","fermer"]'::jsonb,
         4, null::text),
        (478::bigint, 2, 3,
         'Complète au plus-que-parfait : « Ce matin, nous ___. »',
         '["sommes sortis","serons sortis","avions sortis","étions sortis"]'::jsonb,
         4, null::text),
        (504::bigint, 2, 3, null::text,
         '["-ais","-ait","-ai","-aient"]'::jsonb,
         1, null::text),
        (522::bigint, 2, 3, null::text,
         '["dévelopement","développement","développemment","dévelloppement"]'::jsonb,
         2, null::text),
        (527::bigint, 2, 3, null::text,
         '["diférent","differrent","différent","différant"]'::jsonb,
         3, null::text),
        (600058::bigint, 2, 3,
         'Lequel de ces nombres est un nombre décimal ?',
         '["7/25","2/15","5/18","8/21"]'::jsonb,
         1, null::text)
    ) as requested(
      legacy_id,
      source_version_number,
      target_version_number,
      replacement_prompt,
      choices,
      correct_position,
      replacement_explanation
    )
  loop
    select
      question.id,
      version.prompt,
      version.correction_explanation
    into
      selected_question_id,
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
        'cap-college:pending-french-correction:' ||
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
      coalesce(correction.replacement_prompt, source_prompt),
      coalesce(correction.replacement_explanation, source_explanation),
      case
        when correction.legacy_id between 61 and 80
          then 'Alignement sur les types déclaratif, interrogatif et impératif, avec la forme exclamative séparée.'
        else 'Correction issue de la nouvelle validation pédagogique.'
      end,
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

    for choice in
      select value #>> '{}' as content, ordinality::smallint as sort_order
      from jsonb_array_elements(correction.choices)
           with ordinality as answer(value, ordinality)
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
          'cap-college:pending-french-correction:' ||
          correction.legacy_id || ':v' ||
          correction.target_version_number || ':' || choice.sort_order
        )::uuid,
        target_version_id,
        chr(64 + choice.sort_order),
        choice.content,
        choice.sort_order = correction.correct_position,
        choice.sort_order
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
