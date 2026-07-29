/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/137_rework_french_6e_lot_01_feedback.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Rework all French 6e lot 01 questions after validator feedback.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  correction record;
  answer record;
  selected_question_id uuid;
  source_explanation text;
  target_version_id uuid;
begin
  for correction in
    select *
    from (
      values
        (1000001, 'Dans « Le navire quitte rapidement le port », quel mot est un nom ?', array['navire','quitte','rapidement','le'], 1),
        (1000002, 'Dans « Cette décision demande beaucoup de courage », quel mot est un nom ?', array['Cette','courage','demande','beaucoup'], 2),
        (1000003, 'Dans « Les touristes visitent Marseille demain », quel mot est un nom propre ?', array['Les','visitent','Marseille','demain'], 3),
        (1000004, 'Dans « La patience aide vraiment à progresser », quel mot est un nom ?', array['vraiment','aide','à','patience'], 4),
        (1000005, 'Dans « Un renard traverse lentement le chemin », quel mot est un nom ?', array['chemin','lentement','traverse','le'], 1),
        (1000006, 'Dans « Son arrivée surprend vraiment tout le monde », quel mot est un nom ?', array['Son','arrivée','vraiment','tout'], 2),
        (1000007, 'Dans « Le rire des enfants résonne joyeusement », quel mot est ici employé comme un nom ?', array['résonne','joyeusement','rire','des'], 3),
        (1000008, 'Dans « Une faible lueur apparaît soudain au loin », quel mot est un nom ?', array['faible','soudain','apparaît','lueur'], 4),

        (1000009, 'Dans « Les vagues frappent violemment la digue », quel mot est un verbe ?', array['frappent','vagues','violemment','la'], 1),
        (1000010, 'Dans « Il semble très inquiet », quel mot est un verbe ?', array['Il','semble','très','inquiet'], 2),
        (1000011, 'Dans « Nous partirons certainement demain », quel mot est un verbe ?', array['Nous','certainement','partirons','demain'], 3),
        (1000012, 'Dans « Voyager permet de découvrir le monde », quel mot est un verbe à l’infinitif ?', array['monde','le','de','Voyager'], 4),
        (1000013, 'Dans « Cette lampe éclaire vivement la pièce », quel mot est un verbe ?', array['éclaire','Cette','vivement','pièce'], 1),
        (1000014, 'Dans « Elles ont bien compris la consigne », quel mot est une forme du verbe « avoir » ?', array['Elles','ont','bien','consigne'], 2),
        (1000015, 'Dans « Le spectacle fut vraiment remarquable », quel mot est une forme du verbe « être » ?', array['spectacle','vraiment','fut','remarquable'], 3),
        (1000016, 'Dans « Vous pouvez entrer calmement », quel mot est un verbe à l’infinitif ?', array['Vous','calmement','pouvez','entrer'], 4),

        (1000017, 'Dans « Le train avance lentement », quel mot est un adverbe ?', array['lentement','train','avance','Le'], 1),
        (1000018, 'Dans « Nous partirons bientôt en voyage », quel mot est un adverbe ?', array['Nous','bientôt','voyage','en'], 2),
        (1000019, 'Dans « Elle habite ici depuis longtemps », quel mot est un adverbe de lieu ?', array['Elle','habite','ici','depuis'], 3),
        (1000020, 'Dans « Ce problème est très difficile », quel mot précise le sens de l’adjectif « difficile » ?', array['problème','est','difficile','très'], 4),
        (1000021, 'Dans « Il répond toujours poliment », quel mot est un adverbe de fréquence ?', array['toujours','répond','Il','poliment'], 1),
        (1000022, 'Dans « La rivière est assez profonde », quel mot est un adverbe ?', array['rivière','assez','profonde','La'], 2),
        (1000023, 'Dans « Soudain, la lourde porte s’ouvre », quel mot est un adverbe ?', array['lourde','porte','Soudain','s’ouvre'], 3),

        (1000024, 'Dans « Un épais brouillard recouvre la vallée », quel mot est un adjectif ?', array['brouillard','recouvre','vallée','épais'], 4),
        (1000025, 'Dans « La mer calme reflète le ciel bleu », quel mot est un adjectif qui précise « mer » ?', array['calme','mer','reflète','le'], 1),
        (1000026, 'Dans « Nous empruntons un sentier étroit », quel mot est un adjectif ?', array['empruntons','étroit','sentier','Nous'], 2),
        (1000027, 'Dans « Cette réponse paraît juste », quel mot est un adjectif ?', array['Cette','paraît','juste','réponse'], 3),
        (1000028, 'Dans « Les élèves attentifs comprennent rapidement », quel mot est un adjectif ?', array['élèves','comprennent','rapidement','attentifs'], 4),
        (1000029, 'Dans « Une histoire passionnante commence ici », quel mot est un adjectif ?', array['passionnante','commence','ici','Une'], 1),
        (1000030, 'Dans « Son regard devient soudain inquiet », quel mot est un adjectif ?', array['soudain','inquiet','devient','Son'], 2),

        (1000031, 'Dans « Plusieurs élèves répondent correctement », quel mot est un déterminant ?', array['élèves','correctement','Plusieurs','répondent'], 3),
        (1000032, 'Dans « Mon voisin jardine souvent », quel mot est un déterminant possessif ?', array['voisin','jardine','souvent','Mon'], 4),
        (1000033, 'Dans « Une étoile brillante apparaît », quel mot est un déterminant ?', array['Une','étoile','brillante','apparaît'], 1),
        (1000034, 'Dans « Quels exercices choisissez-vous aujourd’hui ? », quel mot est un déterminant interrogatif ?', array['exercices','Quels','choisissez','aujourd’hui'], 2),
        (1000035, 'Dans « Ces anciennes maisons sont solides », quel mot est un déterminant démonstratif ?', array['anciennes','maisons','Ces','solides'], 3),

        (1000036, 'Dans « Vous connaissez parfaitement la réponse », quel mot est un pronom personnel ?', array['connaissez','parfaitement','réponse','Vous'], 4),
        (1000037, 'Dans « Ils reviendront certainement demain », quel mot est un pronom personnel sujet ?', array['Ils','reviendront','certainement','demain'], 1),
        (1000038, 'Dans « Je leur réponds calmement », quel mot est un pronom personnel complément ?', array['Je','leur','réponds','calmement'], 2),
        (1000039, 'Dans « Le professeur nous écoute attentivement », quel mot est un pronom personnel complément ?', array['professeur','écoute','nous','attentivement'], 3),
        (1000040, 'Dans « Lina le range soigneusement dans son sac », quel mot est un pronom personnel complément ?', array['Lina','range','soigneusement','le'], 4)
    ) as data(legacy_id, prompt, choices, correct_position)
  loop
    select q.id, qv.correction_explanation
    into selected_question_id, source_explanation
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = 1
    where q.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % ou version source 1 introuvable.', correction.legacy_id;
    end if;

    target_version_id := md5(
      'cap-college:french-lot-01-feedback:' ||
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
      source_explanation,
      'La question demande désormais d’identifier le mot recherché parmi plusieurs mots de la phrase ; le nom de la micro-compétence ne donne plus directement la réponse.',
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
          'cap-college:french-lot-01-feedback:' ||
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
