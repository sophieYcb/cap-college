begin;

do $block$
declare
  item record;
  selected_micro_skill_id uuid;
  selected_title text;
  next_version integer;
begin
  for item in
    select * from (values
      ('f6_con_present',
       'Au présent de l’indicatif, la terminaison dépend du groupe du verbe et du sujet. Pour les verbes en -er : -e, -es, -e, -ons, -ez, -ent. Certains verbes fréquents, comme être, avoir, aller ou faire, ont des formes particulières.',
       'Avec « chanter » : je chante, tu chantes, il chante, nous chantons, vous chantez, ils chantent.'),
      ('f6_con_imparfait',
       'Pour former l’imparfait, on part généralement de la forme « nous » au présent, on enlève -ons puis on ajoute : -ais, -ais, -ait, -ions, -iez, -aient. Le verbe être utilise le radical ét-.',
       'Nous chantons → radical chant- → je chantais, nous chantions. Avec être : vous étiez.'),
      ('f6_con_futur',
       'Au futur simple, on ajoute à l’infinitif les terminaisons -ai, -as, -a, -ons, -ez, -ont. Pour un verbe en -re, on retire le e final. Certains verbes ont un radical particulier.',
       'Finir → tu finiras. Prendre → nous prendrons. Aller → j’irai.'),
      ('f6_con_passe_compose',
       'Le passé composé se forme avec l’auxiliaire avoir ou être au présent, suivi du participe passé. Avec être, le participe passé s’accorde généralement avec le sujet.',
       'Nous avons terminé. Léa est arrivée ; Tom et Léa sont arrivés.'),
      ('f6_con_passe_simple',
       'Le passé simple raconte des actions brèves et achevées, surtout dans les récits écrits. Les verbes en -er prennent souvent -ai, -as, -a, -âmes, -âtes, -èrent ; d’autres verbes prennent notamment les séries en -is ou en -us.',
       'Il entra, regarda autour de lui puis aperçut une lumière.'),
      ('f6_con_plus_que_parfait',
       'Le plus-que-parfait se forme avec l’auxiliaire avoir ou être à l’imparfait, suivi du participe passé. Il exprime souvent une action accomplie avant une autre action passée.',
       'Quand le bus arriva, les élèves avaient déjà rangé leurs affaires.'),
      ('f6_con_imperatif_present',
       'L’impératif présent sert à donner un ordre, un conseil ou une interdiction. Il se conjugue seulement avec tu, nous et vous, sans pronom sujet exprimé.',
       'Ferme la porte. Prenons le temps de vérifier. Ne courez pas.'),
      ('f6_con_conditionnel_present',
       'Le conditionnel présent se forme avec le radical du futur et les terminaisons de l’imparfait : -ais, -ais, -ait, -ions, -iez, -aient. Il peut exprimer une possibilité, un souhait ou une demande polie.',
       'Avec plus de temps, nous terminerions. Pourriez-vous m’aider ?'),
      ('f6_con_identifier_valeur_temps',
       'La valeur d’un temps est le sens qu’il prend dans le contexte. Un même temps peut exprimer une action en cours, une habitude, une vérité générale, une description ou un événement de premier plan.',
       'Dans « Chaque matin, il marche jusqu’au collège », le présent exprime une habitude.'),
      ('f6_gra_identifier_type_phrase',
       'Une phrase déclarative donne une information. Une phrase interrogative pose une question. Une phrase injonctive donne un ordre, un conseil ou une interdiction. Le sens et la ponctuation aident à les reconnaître.',
       '« Le train arrive. » est déclarative ; « Arrive-t-il ? » est interrogative ; « Attends ici. » est injonctive.'),
      ('f6_gra_identifier_forme_negative',
       'Une phrase négative contient généralement deux mots de négation autour du verbe conjugué : ne… pas, ne… plus, ne… jamais, ne… rien ou ne… personne.',
       '« Il vient encore » devient « Il ne vient plus » : ne et plus encadrent le verbe vient.'),
      ('f6_gra_distinguer_phrase_simple_complexe',
       'Une phrase simple contient un seul verbe conjugué et donc une seule proposition. Une phrase complexe contient plusieurs verbes conjugués et donc plusieurs propositions.',
       '« Le vent souffle » est simple. « Le vent souffle et les volets claquent » est complexe.'),
      ('f6_ort_realiser_chaine_gn',
       'Dans un groupe nominal, le déterminant, le nom et les adjectifs s’accordent en genre et en nombre. On repère d’abord le nom noyau, puis on reporte ses marques sur les mots qui l’accompagnent.',
       'Une petite chatte noire → des petites chattes noires : tous les mots s’accordent avec chattes.'),
      ('f6_ort_former_feminin',
       'On forme souvent le féminin en ajoutant un e. Certaines terminaisons changent : -er devient -ère, -eux devient -euse, -if devient -ive et certaines consonnes doublent. Quelques formes sont irrégulières.',
       'grand → grande ; léger → légère ; heureux → heureuse ; sportif → sportive ; beau → belle.'),
      ('f6_ort_former_pluriel_particulier',
       'La plupart des noms et adjectifs prennent un s au pluriel. Beaucoup de mots en -eau ou -eu prennent x ; beaucoup de mots en -al deviennent -aux. Il existe des exceptions qu’il faut mémoriser.',
       'un bateau → des bateaux ; un cheval → des chevaux ; un festival → des festivals.'),
      ('f6_ort_memoriser_mot_irregulier',
       'Les mots irréguliers ne s’écrivent pas entièrement comme ils se prononcent. Pour les mémoriser, on observe leurs lettres difficiles, on les rapproche de mots de la même famille et on les réemploie dans une phrase.',
       'Dans longtemps, on repère long et temps : « Il a longtemps attendu. »'),
      ('f6_ort_distinguer_a_a',
       'a sans accent est le verbe avoir au présent. On peut le remplacer par avait. à avec accent est une préposition et ne peut pas être remplacé par avait.',
       '« Lina a un vélo » → « Lina avait un vélo » : on écrit a. « Elle va à l’école » ne permet pas ce remplacement.'),
      ('f6_ort_distinguer_et_est',
       'et relie des mots ou des groupes de mots. est est le verbe être au présent et peut être remplacé par était.',
       '« Le ciel est clair et lumineux » → « Le ciel était clair et lumineux » : est est un verbe, et relie deux adjectifs.'),
      ('f6_ort_distinguer_son_sont',
       'son est un déterminant possessif placé devant un nom. sont est le verbe être au présent et peut être remplacé par étaient.',
       '« Ses amis sont dans son jardin » → « Ses amis étaient dans son jardin » : sont est un verbe ; son accompagne jardin.'),
      ('f6_voc_identifier_synonyme',
       'Des synonymes ont un sens proche, appartiennent à la même classe grammaticale et doivent convenir au contexte. Ils ne sont pas toujours interchangeables dans toutes les phrases.',
       'Dans « une immense maison », vaste peut remplacer immense : ce sont deux adjectifs adaptés au contexte.'),
      ('f6_voc_identifier_antonyme',
       'Des antonymes ont des sens opposés et appartiennent à la même classe grammaticale. Le contexte permet de choisir l’opposé qui convient.',
       'Rapide et lent sont deux adjectifs antonymes : « un train rapide », « un train lent ».'),
      ('f6_voc_identifier_famille_mots',
       'Les mots d’une même famille sont construits autour d’un radical commun et partagent une idée de sens. Une ressemblance de lettres ne suffit pas.',
       'terre, terrain, terrestre et enterrer appartiennent à la même famille.'),
      ('f6_voc_interpreter_polysemie',
       'Un mot polysémique possède plusieurs sens. Les autres mots de la phrase donnent des indices pour choisir le sens adapté au contexte.',
       'Dans « La souris grignote du fromage », souris désigne l’animal ; dans « Clique avec la souris », il désigne l’objet informatique.'),
      ('f6_voc_distinguer_propre_figure',
       'Le sens propre est le sens premier et concret d’un mot. Le sens figuré est une image qui permet d’exprimer une idée.',
       '« Il a le cœur qui bat vite » emploie cœur au sens propre ; « Il a le cœur sur la main » l’emploie au sens figuré.'),
      ('f6_voc_distinguer_homonymes',
       'Des homonymes se prononcent ou s’écrivent de la même façon mais ont des sens différents. Le contexte et parfois l’orthographe permettent de les distinguer.',
       'Dans « Le ver vert va vers le verre », chaque homonyme a un sens différent.'),
      ('f6_voc_identifier_registre',
       'Le registre familier s’emploie surtout entre proches, le registre courant dans la vie quotidienne et le registre soutenu dans une langue plus recherchée. La situation de communication guide le choix.',
       'Bouffer est familier, manger est courant et se restaurer appartient à un registre plus soutenu.'),
      ('f6_voc_utiliser_etymologie',
       'L’étymologie est l’origine d’un mot. Connaître une racine grecque ou latine aide à comprendre des mots inconnus et à rapprocher des mots de la même famille.',
       'Le grec télé signifie « loin » : téléphone, télévision et télescope désignent quelque chose qui agit ou se voit à distance.')
    ) as proposed(micro_skill_code, reminder, worked_example)
  loop
    select ms.id, ms.student_name
    into selected_micro_skill_id, selected_title
    from public.micro_skills ms
    where ms.code = item.micro_skill_code and ms.active;

    if selected_micro_skill_id is null then
      raise exception 'Micro-skill not found: %', item.micro_skill_code;
    end if;

    select coalesce(max(lr.version_number), 0) + 1
    into next_version
    from public.learning_resources lr
    where lr.micro_skill_id = selected_micro_skill_id;

    update public.learning_resources
    set active = false, updated_at = statement_timestamp()
    where micro_skill_id = selected_micro_skill_id and active;

    insert into public.learning_resources (
      micro_skill_id, title, reminder, worked_example, version_number, active
    ) values (
      selected_micro_skill_id, selected_title, item.reminder,
      item.worked_example, next_version, true
    );
  end loop;
end;
$block$;

commit;
