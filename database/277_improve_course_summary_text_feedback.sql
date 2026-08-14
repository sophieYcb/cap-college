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
      ('f6_con_distinguer_temps_chronologique_verbal',
       'Le temps chronologique situe l’action dans le passé, le présent ou l’avenir. Le temps verbal est la forme grammaticale du verbe. Un indicateur de temps peut donc situer l’action à un autre moment que celui suggéré par la forme verbale.',
       'Dans « Demain, je pars », l’action se déroulera dans l’avenir grâce à l’indicateur « demain », mais le verbe « pars » est conjugué au présent.'),
      ('f6_gra_distinguer_attribut_cod',
       'L’attribut caractérise le sujet après un verbe attributif comme être, sembler ou devenir. Le COD complète directement un verbe d’action : pour le repérer, on peut poser la question « qui ? » ou « quoi ? » après le verbe.',
       '« La mer devient calme » : calme caractérise la mer, c’est un attribut. « Les marins observent la mer » : ils observent quoi ? la mer, qui est COD.'),
      ('f6_ort_participe_passe_avoir',
       'Avec l’auxiliaire avoir, le participe passé s’accorde avec le COD seulement lorsque ce COD est placé avant le verbe. On repère le COD, sa place, puis son genre et son nombre.',
       '« Les lettres que j’ai écrites » : j’ai écrit quoi ? « que », qui reprend « les lettres ». Ce COD féminin pluriel est placé avant « ai écrit » ; on écrit donc « écrites ».'),
      ('f6_voc_identifier_prefixe',
       'Le préfixe se place avant le mot de base et en modifie le sens. re- exprime souvent la répétition, pré- l’antériorité, dé-/dés- la séparation ou le contraire, in-/im- la négation et anti- l’opposition.',
       'Dans « refaire », re- signifie « de nouveau » ; dans « impossible », im- donne le sens contraire de possible.'),
      ('m6_num_arrondir_centieme',
       'Pour arrondir au centième, on garde deux chiffres après la virgule et on observe le chiffre des millièmes. S’il vaut 0, 1, 2, 3 ou 4, le centième ne change pas. S’il vaut 5, 6, 7, 8 ou 9, on augmente le centième d’une unité.',
       '5,263 est plus proche de 5,26. Pour 5,265, le chiffre suivant est 5 : selon la règle d’arrondi scolaire, on obtient 5,27.'),
      ('m6_num_arrondir_dixieme',
       'Pour arrondir au dixième, on garde un chiffre après la virgule et on observe le chiffre des centièmes. De 0 à 4, le dixième ne change pas ; de 5 à 9, on augmente le dixième d’une unité.',
       '7,43 est plus proche de 7,4. Pour 7,45, le chiffre suivant est 5 : selon la règle d’arrondi scolaire, on obtient 7,5.'),
      ('m6_num_arrondir_unite',
       'Pour arrondir à l’unité, on observe le chiffre des dixièmes. De 0 à 4, on garde l’unité ; de 5 à 9, on choisit l’unité supérieure.',
       '12,36 est plus proche de 12. Pour 12,5, le chiffre des dixièmes est 5 : selon la règle d’arrondi scolaire, on obtient 13.'),
      ('m6_mes_aire_rectangle',
       'L’aire d’un rectangle est le produit de sa longueur par sa largeur : A = longueur × largeur. Les deux longueurs doivent être exprimées dans la même unité et l’aire s’écrit dans l’unité correspondante au carré : cm², m², etc.',
       'Pour un rectangle de 8 cm sur 3 cm : A = 8 × 3 = 24 cm².'),
      ('m6_mes_aire_carre',
       'L’aire d’un carré est le produit de la longueur de son côté par elle-même : A = côté × côté. L’aire s’exprime dans une unité au carré : cm², m², etc.',
       'Pour un carré de 5 cm de côté : A = 5 × 5 = 25 cm².'),
      ('m6_mes_prefixes',
       'Par rapport à l’unité : kilo = 1 000 ; hecto = 100 ; déca = 10 ; déci = 0,1 ; centi = 0,01 ; milli = 0,001.',
       '1 km = 1 000 m ; 1 dm = 0,1 m ; 1 cm = 0,01 m et 1 mm = 0,001 m.'),
      ('m6_mes_perimetre_disque_formule',
       'Le tour, ou périmètre, d’un disque se calcule avec P = diamètre × π, ou P = 2 × rayon × π. On utilise souvent π ≈ 3,14.',
       'Pour un disque de rayon 4 cm : P = 2 × 4 × π = 8π cm, soit environ 25,12 cm.'),
      ('m6_mes_convertir_duree',
       'Pour convertir une durée, on utilise 1 h = 60 min et 1 min = 60 s. On convertit séparément chaque partie, puis on additionne.',
       '2 h 30 min = (2 × 60) min + 30 min = 120 min + 30 min = 150 min.'),
      ('m6_calc_diviser_10_100_1000',
       'Diviser par 10, 100 ou 1 000 rend le nombre 10, 100 ou 1 000 fois plus petit : chaque chiffre prend respectivement un, deux ou trois rangs vers la droite dans le tableau de numération. À l’écrit, cela donne l’impression que la virgule se déplace vers la gauche.',
       '403,7 ÷ 100 : chaque chiffre change de deux rangs, donc 403,7 ÷ 100 = 4,037.'),
      ('m6_data_planifier_enquete',
       'Pour organiser une enquête, on définit une question précise, on choisit les personnes interrogées, on recueille les réponses, on les classe dans un tableau puis on présente les résultats.',
       'Pour connaître le moyen de transport des élèves, on interroge chaque élève, on compte les réponses « à pied », « vélo », « bus » et « voiture », puis on les rassemble dans un tableau.'),
      ('m6_calc_multiplier_decimal',
       'Pour multiplier deux nombres décimaux, on calcule d’abord comme avec des entiers. On compte ensuite le nombre total de chiffres placés après les virgules dans les deux facteurs et on place la virgule du résultat en conservant ce même total.',
       '2,4 × 1,5 : on calcule 24 × 15 = 360. Il y a deux chiffres décimaux au total, donc le résultat est 3,60, soit 3,6.'),
      ('m6_prop_retour_unite',
       'Pour passer par l’unité, on cherche d’abord la valeur correspondant à une seule unité en divisant, puis on multiplie cette valeur par la quantité demandée.',
       '5 cahiers coûtent 15 €. Un cahier coûte 15 ÷ 5 = 3 €. Donc 8 cahiers coûtent 8 × 3 = 24 €.'),
      ('m6_mes_perimetre_disque_calcul',
       'Cette compétence consiste à appliquer la formule du tour d’un disque à des mesures données. On repère si l’on connaît le diamètre ou le rayon, on choisit P = diamètre × π ou P = 2 × rayon × π, puis on calcule avec π ≈ 3,14.',
       'Diamètre 10 cm : P ≈ 10 × 3,14 = 31,4 cm. Si le rayon vaut 5 cm, on retrouve P ≈ 2 × 5 × 3,14 = 31,4 cm.'),
      ('m6_num_comparer_decimaux',
       'On compare d’abord les parties entières, puis les dixièmes, les centièmes et les millièmes. On peut ajouter des zéros à droite de la partie décimale, donc après la virgule, sans changer la valeur du nombre.',
       '5,37 = 5,370. On compare alors 5,370 et 5,309 : 5,370 > 5,309, donc 5,37 > 5,309.'),
      ('m6_mes_calcul_horaire',
       'Pour trouver une heure d’arrivée, on ajoute la durée à l’heure de départ. Pour trouver une heure de départ, on retire la durée de l’heure d’arrivée. On peut décomposer la durée pour franchir plus facilement une heure entière.',
       'Départ à 14 h 20, trajet de 35 min : 14 h 20 + 30 min = 14 h 50, puis + 5 min = 14 h 55.'),
      ('m6_calc_multiplier_10_100_1000',
       'Multiplier par 10, 100 ou 1 000 rend le nombre 10, 100 ou 1 000 fois plus grand : chaque chiffre prend respectivement un, deux ou trois rangs vers la gauche dans le tableau de numération. À l’écrit, cela donne l’impression que la virgule se déplace vers la droite.',
       '4,037 × 100 : chaque chiffre change de deux rangs, donc 4,037 × 100 = 403,7.'),
      ('m6_calc_division_decimale',
       'Diviser un nombre décimal, c’est chercher combien vaut chaque part. On effectue la division en respectant les rangs des chiffres, puis on vérifie le quotient en le multipliant par le diviseur.',
       '12,6 ÷ 3 : 12 ÷ 3 = 4 et 0,6 ÷ 3 = 0,2 ; donc 12,6 ÷ 3 = 4,2. Vérification : 4,2 × 3 = 12,6.'),
      ('m6_pct_exprimer_proportion',
       'Pour exprimer une proportion en pourcentage, on cherche une fraction équivalente dont le dénominateur est 100, ou on multiplie la proportion par 100.',
       'Pour 3 sur 4, on multiplie le numérateur et le dénominateur par 25 : 3/4 = 75/100, donc 75 %.'),
      ('m6_frac_ordonner',
       'Pour ranger plusieurs fractions, on les écrit si possible avec un même dénominateur, puis on compare leurs numérateurs. On peut aussi les situer par rapport à 0, 1/2 et 1.',
       'Pour ranger 1/4, 1/2 et 3/4, on écrit 1/2 = 2/4. On compare alors 1/4, 2/4 et 3/4 : donc 1/4 < 1/2 < 3/4.')
    ) as proposed(micro_skill_code, reminder, worked_example)
  loop
    select ms.id, ms.student_name into selected_micro_skill_id, selected_title
    from public.micro_skills ms
    where ms.code = item.micro_skill_code and ms.active;

    if selected_micro_skill_id is null then
      raise exception 'Micro-skill not found: %', item.micro_skill_code;
    end if;

    select coalesce(max(lr.version_number), 0) + 1 into next_version
    from public.learning_resources lr
    where lr.micro_skill_id = selected_micro_skill_id;

    update public.learning_resources
    set active = false, updated_at = statement_timestamp()
    where micro_skill_id = selected_micro_skill_id and active;

    insert into public.learning_resources
      (micro_skill_id, title, reminder, worked_example, version_number, active)
    values
      (selected_micro_skill_id, selected_title, item.reminder, item.worked_example, next_version, true);
  end loop;
end;
$block$;

commit;
