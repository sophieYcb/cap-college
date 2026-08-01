/*
 CAP-COLLEGE DATABASE
 File: database/174_correct_french_6e_lot_11_feedback.sql
 Purpose: Apply validator feedback for French 6e lot F6-CON-11.
 Idempotent: Yes
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
        (1000317,
         'Pourquoi « était parti » est-il au plus-que-parfait ?',
         array['L’auxiliaire « être » est à l’imparfait.','Le participe passé est masculin.','Le verbe exprime toujours une action courte.','L’auxiliaire est au présent.'],
         1,
         'L’auxiliaire « être » est conjugué à l’imparfait dans « était parti ».',
         'La réponse A nomme désormais explicitement l’auxiliaire être.'),
        (1000320,
         'Dans « Ce soir, nous dînons chez Léa », quelle analyse est correcte ?',
         array['Temps verbal passé ; action présente','Temps verbal futur ; action passée','Temps verbal présent ; action passée','Temps verbal présent ; action future'],
         4,
         '« dînons » est au présent, mais « ce soir » situe ici l’action dans l’avenir.',
         'La phrase a été remplacée par un exemple naturel de présent à valeur de futur.'),
        (1000324,
         'Dans un récit historique, « En 1789, le peuple prend la Bastille », quelle analyse est correcte ?',
         array['Temps verbal passé ; action future','Temps verbal présent ; action présente','Temps verbal futur ; action passée','Temps verbal présent ; action passée'],
         4,
         '« prend » est au présent de narration, tandis que la date situe l’action dans le passé.',
         'La phrase a été remplacée par un exemple clair de présent de narration.'),
        (1000329,
         'Quelle phrase met « Elle a compris » à la forme négative avec « ne… pas » ?',
         array['Elle n’a pas compris.','Elle n’a jamais compris.','Elle n’a rien compris.','A-t-elle compris ?'],
         1,
         '« n’ » précède l’auxiliaire « a » et « pas » le suit.',
         'Les distracteurs sont désormais des phrases grammaticales exprimant des sens différents.'),
        (1000330,
         'Quelle phrase indique qu’à aucun moment ils n’étaient partis ?',
         array['Ils n’étaient pas encore partis.','Ils n’étaient jamais partis.','Ils étaient déjà partis.','Étaient-ils partis ?'],
         2,
         '« ne… jamais » encadre l’auxiliaire « étaient » et exprime l’absence à tout moment.',
         'Les distracteurs sont grammaticalement corrects et portent des sens distincts.'),
        (1000331,
         'Quelle phrase indique que nous n’avons terminé aucune chose ?',
         array['Nous n’avons pas encore fini.','Nous avons tout fini.','Nous n’avons rien fini.','Avons-nous fini ?'],
         3,
         '« n’… rien » encadre le temps composé et exprime qu’aucune chose n’est terminée.',
         'La question oppose plusieurs formulations grammaticales et plusieurs sens.'),
        (1000332,
         'Quelle phrase transforme « Tu es venu » en question négative ?',
         array['Es-tu venu ?','Tu n’es jamais venu.','Tu n’es plus venu.','N’es-tu pas venu ?'],
         4,
         'Dans la question négative, « n’… pas » encadre l’auxiliaire inversé avec le sujet.',
         'Les propositions sont désormais toutes grammaticales.'),
        (1000333,
         'Quelle phrase indique qu’à ce moment-là je n’avais pas encore entendu ?',
         array['Je n’avais pas encore entendu.','Je n’avais jamais entendu.','Je n’avais rien entendu.','Avais-je déjà entendu ?'],
         1,
         '« n’… pas encore » encadre l’auxiliaire et indique que l’action n’avait pas eu lieu à ce moment-là.',
         'Les distracteurs expriment des nuances négatives ou interrogatives crédibles.'),
        (1000334,
         'Complète pour indiquer qu’aucune réponse n’a été donnée à aucun moment : « Vous ___ répondu. »',
         array['avez déjà','n’avez jamais','n’avez pas encore','avez souvent'],
         2,
         '« n’avez jamais répondu » exprime qu’aucune réponse n’a été donnée à aucun moment.',
         'Les quatre compléments proposés sont grammaticalement possibles.'),
        (1000335,
         'Quelle phrase signifie simplement que nous ne sommes pas arrivés ?',
         array['On est déjà arrivé.','On n’est jamais arrivé.','On n’est pas arrivé.','Est-on arrivé ?'],
         3,
         '« n’… pas » encadre l’auxiliaire « est » et conserve le sens demandé.',
         'Les distracteurs sont naturels mais modifient le sens ou le type de phrase.'),
        (1000336,
         'Quelle phrase indique qu’elles n’avaient choisi aucune chose ?',
         array['Elles avaient tout choisi.','Elles n’avaient pas encore choisi.','Avaient-elles déjà choisi ?','Elles n’avaient rien choisi.'],
         4,
         '« n’… rien » encadre l’auxiliaire et signifie qu’aucune chose n’avait été choisie.',
         'Les distracteurs sont désormais des phrases grammaticales aux sens distincts.'),
        (1000337,
         'Quelle réécriture conserve le sens de « Il a pas rangé sa chambre » dans un écrit soigné ?',
         array['Il n’a pas rangé sa chambre.','Il n’a jamais rangé sa chambre.','Il n’a rien rangé dans sa chambre.','A-t-il rangé sa chambre ?'],
         1,
         'La négation complète « n’… pas » encadre l’auxiliaire sans modifier le sens.',
         'Les distracteurs sont corrects mais changent le sens ou transforment la phrase en question.'),
        (1000338,
         'Quelle phrase indique que Léa n’a effectué aucune lecture ?',
         array['Léa n’a pas encore lu ce livre.','Léa n’a rien lu.','Léa n’a jamais lu ce livre.','Léa a-t-elle lu ce livre ?'],
         2,
         '« n’… rien » encadre l’auxiliaire « a » et signifie qu’aucune lecture n’a été effectuée.',
         'La question de règle a été remplacée par une application avec quatre formulations crédibles.'),
        (1000340,
         'Dans « Elles étaient sorties », quelle analyse est correcte ?',
         array['« Elles » est l’auxiliaire et « étaient » le participe passé.','« sorties » est l’auxiliaire et « étaient » le participe passé.','« étaient sorties » est une forme verbale simple.','« étaient » est l’auxiliaire et « sorties » le participe passé.'],
         4,
         '« étaient » est l’auxiliaire conjugué et « sorties » le participe passé.',
         'Les propositions A et B ne sont plus de simples inversions équivalentes.')
    ) as data(
      legacy_id,
      prompt,
      choices,
      correct_position,
      explanation,
      change_comment
    )
  loop
    select q.id into selected_question_id
    from public.questions q
    where q.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % introuvable.', correction.legacy_id;
    end if;

    target_version_id := md5(
      'cap-college:french-lot-11-feedback:' || correction.legacy_id || ':v2'
    )::uuid;

    insert into public.question_versions (
      id, question_id, version_number, prompt,
      correction_explanation, change_comment, review_status, authored_by
    )
    values (
      target_version_id, selected_question_id, 2, correction.prompt,
      correction.explanation, correction.change_comment,
      'unreviewed'::public.review_status, auth.uid()
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
        id, question_version_id, choice_key, content, is_correct, sort_order
      )
      values (
        md5(
          'cap-college:french-lot-11-feedback:' || correction.legacy_id ||
          ':v2:' || answer.sort_order
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
