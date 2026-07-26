/*
===============================================================================
 CAP-COLLEGE DATABASE - VALIDATOR FEEDBACK 2026-07-26
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/66_apply_validator_feedback_2026_07_26.sql
 Purpose      : Apply the reviewed corrections exported after validation.
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
        /* Radical et terminaison : distracteurs demandés par la validation. */
        (504::bigint, 3, 4, null::text,
         '["-ais","-is","-uais","-jou"]'::jsonb, 1::smallint,
         'Les lettres « -ais » constituent la terminaison ; « jou- » est le radical.',
         'Distracteurs revus pour mieux tester la séparation entre radical et terminaison.'),

        /*
         * Une phrase de forme exclamative peut rester de type déclaratif.
         * La proposition D devient donc impérative et exclamative afin que C
         * soit l'unique phrase de type déclaratif.
         */
        (63::bigint, 2, 3, null::text,
         '["Le soleil se couche-t-il ?","Regarde le soleil.","Le soleil se couche.","Admire ce beau coucher de soleil !"]'::jsonb,
         3::smallint, null::text,
         'Suppression de l’ambiguïté entre type déclaratif et forme exclamative.'),
        (67::bigint, 2, 3, null::text,
         '["Partirons-nous demain matin ?","Partons demain matin.","Nous partirons demain matin.","Partons dès demain matin !"]'::jsonb,
         3::smallint, null::text,
         'Suppression de l’ambiguïté entre type déclaratif et forme exclamative.'),
        (71::bigint, 2, 3, null::text,
         '["Le train entre-t-il en gare ?","Regardez le train.","Le train entre en gare.","Admirez la vitesse de ce train !"]'::jsonb,
         3::smallint, null::text,
         'Suppression de l’ambiguïté entre type déclaratif et forme exclamative.'),
        (75::bigint, 2, 3, null::text,
         '["Quand ferme la bibliothèque ?","Fermez la bibliothèque.","La bibliothèque ferme à dix-huit heures.","Entrez dans cette bibliothèque !"]'::jsonb,
         3::smallint, null::text,
         'La proposition B reste impérative ; la proposition D devient impérative et exclamative.'),
        (79::bigint, 2, 3, null::text,
         '["Ton frère joue-t-il au tennis ?","Joue au tennis.","Mon frère joue au tennis.","Admire ce beau match de tennis !"]'::jsonb,
         3::smallint, null::text,
         'Suppression de l’ambiguïté entre type déclaratif et forme exclamative.'),

        /* Les quatre graphies proposées se prononcent comme « mesdames ». */
        (299::bigint, 3, 4, null::text,
         '["médames","mesdames","mes dames","médame"]'::jsonb,
         2::smallint, null::text,
         'Tous les distracteurs sont désormais homophones de la bonne réponse.'),

        /* Déplacement de la bonne réponse D vers B. */
        (325::bigint, 3, 4, null::text,
         '["entrouvrir","fermer","débloquer","déverrouiller"]'::jsonb,
         2::smallint, null::text,
         'La bonne réponse n’est plus systématiquement placée en D.'),

        /* Rupture de la série B/B/B dans la même micro-compétence. */
        (600037::bigint, 1, 2, null::text,
         '["60","6 000","600","60 000"]'::jsonb,
         3::smallint, null::text,
         'Réordonnancement des choix pour varier la position de la bonne réponse.'),
        (600038::bigint, 1, 2, null::text,
         '["3,5","0,35","35","350"]'::jsonb,
         1::smallint, null::text,
         'Réordonnancement des choix pour varier la position de la bonne réponse.'),
        (600040::bigint, 1, 2, null::text,
         '["47,5","475","4 750","47 500"]'::jsonb,
         2::smallint, null::text,
         'Bonne réponse conservée en B pour obtenir une séquence C/A/B.')
    ) as requested(
      legacy_id,
      source_version_number,
      target_version_number,
      replacement_prompt,
      choices,
      correct_position,
      replacement_explanation,
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
        'cap-college:validator-feedback:2026-07-26:' ||
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
          'cap-college:validator-feedback:2026-07-26:' ||
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
