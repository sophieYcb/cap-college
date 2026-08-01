/*
 CAP-COLLEGE DATABASE
 File: database/180_correct_french_6e_lot_12_feedback.sql
 Purpose: Apply validator feedback for French 6e lot F6-CON-12.
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
        (1000371,
         'Si l’on conjugue « chanter » à l’imparfait avec « nous », quelle forme obtient-on ?',
         array['nous chantons','nous chanterons','nous chantions','nous chanterions'],
         3,
         'À l’imparfait, « chanter » se conjugue « nous chantions ».',
         'La question demande désormais de produire la forme à l’imparfait parmi quatre temps plausibles.'),
        (1000373,
         'Si l’on conjugue « danser » à l’imparfait avec « elle », quelle forme obtient-on ?',
         array['elle dansait','elle dansa','elle dansera','elle danserait'],
         1,
         'À l’imparfait, « danser » se conjugue « elle dansait ».',
         'La consigne suit la formulation demandée par la validation.'),
        (1000374,
         'Si l’on conjugue « finir » à l’imparfait avec « vous », quelle forme obtient-on ?',
         array['vous finissez','vous finissiez','vous finirez','vous finiriez'],
         2,
         'À l’imparfait, « finir » se conjugue « vous finissiez ».',
         'La comparaison de lettres évidente est remplacée par un choix entre quatre temps.'),
        (1000377,
         'Si l’on conjugue « aimer » au conditionnel présent avec « nous », quelle forme obtient-on ?',
         array['nous aimerions','nous aimions','nous aimerons','nous avons aimé'],
         1,
         'Au conditionnel présent, « aimer » se conjugue « nous aimerions ».',
         'La consigne demande désormais de conjuguer le verbe au temps indiqué.'),
        (1000379,
         'Dans « Elle a écrit une lettre », quel infinitif correspond au participe passé « écrit » ?',
         array['avoir','décrire','écrire','inscrire'],
         3,
         'Le participe passé « écrit » correspond ici au verbe « écrire » ; « a » appartient à l’auxiliaire avoir.',
         'L’auxiliaire avoir est ajouté aux distracteurs et le participe passé ciblé est précisé.'),
        (1000380,
         'Dans « Ils ont pris le train », quel infinitif correspond au participe passé « pris » ?',
         array['avoir','comprendre','apprendre','prendre'],
         4,
         'Le participe passé « pris » correspond ici au verbe « prendre » ; « ont » appartient à l’auxiliaire avoir.',
         'L’auxiliaire avoir est ajouté aux distracteurs.'),
        (1000381,
         'Dans « Elle est venue hier », quel infinitif correspond au participe passé « venue » ?',
         array['venir','être','devenir','revenir'],
         1,
         'Le participe passé « venue » correspond ici au verbe « venir » ; « est » appartient à l’auxiliaire être.',
         'L’auxiliaire être est ajouté aux distracteurs.'),
        (1000382,
         'Dans « Nous avons fait un gâteau », quel infinitif correspond au participe passé « fait » ?',
         array['avoir','faire','refaire','défaire'],
         2,
         'Le participe passé « fait » correspond ici au verbe « faire » ; « avons » appartient à l’auxiliaire avoir.',
         'L’auxiliaire avoir est ajouté aux distracteurs.'),
        (1000383,
         'Dans « Il avait lu ce roman », quel infinitif correspond au participe passé « lu » ?',
         array['avoir','relire','lire','élire'],
         3,
         'Le participe passé « lu » correspond ici au verbe « lire » ; « avait » appartient à l’auxiliaire avoir.',
         'L’auxiliaire avoir est ajouté aux distracteurs.'),
        (1000384,
         'Dans « Les enfants sont nés en juin », quel infinitif correspond au participe passé « nés » ?',
         array['être','vivre','nourrir','naître'],
         4,
         'Le participe passé « nés » correspond au verbe « naître » ; « sont » appartient à l’auxiliaire être.',
         'L’auxiliaire être est ajouté aux distracteurs.'),
        (1000385,
         'Dans « Tu as ouvert la fenêtre », quel infinitif correspond au participe passé « ouvert » ?',
         array['ouvrir','avoir','couvrir','offrir'],
         1,
         'Le participe passé « ouvert » correspond ici au verbe « ouvrir » ; « as » appartient à l’auxiliaire avoir.',
         'L’auxiliaire avoir est ajouté aux distracteurs.'),
        (1000386,
         'Dans « Ils étaient descendus au sous-sol », quel infinitif correspond au participe passé « descendus » ?',
         array['être','descendre','défendre','dépendre'],
         2,
         'Le participe passé « descendus » correspond au verbe « descendre » ; « étaient » appartient à l’auxiliaire être.',
         'L’auxiliaire être est ajouté aux distracteurs.'),
        (1000387,
         'Dans « Elle a voulu participer », quel infinitif correspond au participe passé « voulu » ?',
         array['avoir','pouvoir','vouloir','valoir'],
         3,
         'Le participe passé « voulu » correspond au verbe « vouloir » ; « a » appartient à l’auxiliaire avoir.',
         'L’auxiliaire avoir est ajouté aux distracteurs.'),
        (1000388,
         'Dans « Vous avez reçu un message », quel infinitif correspond au participe passé « reçu » ?',
         array['avoir','percevoir','apercevoir','recevoir'],
         4,
         'Le participe passé « reçu » correspond au verbe « recevoir » ; « avez » appartient à l’auxiliaire avoir.',
         'L’auxiliaire avoir est ajouté aux distracteurs.')
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
      'cap-college:french-lot-12-feedback:' || correction.legacy_id || ':v2'
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
          'cap-college:french-lot-12-feedback:' || correction.legacy_id ||
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
