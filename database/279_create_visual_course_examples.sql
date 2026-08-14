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
      ('m6_prop_linearite_additive',
       'Dans une situation proportionnelle, on peut additionner deux colonnes : on additionne les quantités et, de la même façon, leurs valeurs associées.',
       E'[TABLE]\nQuantité|2|3|5\nPrix (€)|6|9|15\n[/TABLE]\nLa troisième colonne est obtenue en additionnant les deux premières : 2 + 3 = 5 et 6 + 9 = 15.'),
      ('m6_frac_add_denominateurs_multiples',
       'Quand un dénominateur est un multiple de l’autre, on transforme une fraction pour obtenir le même dénominateur, puis on additionne les numérateurs.',
       '1/3 + 1/6 = 2/6 + 1/6 = 3/6. On a multiplié le numérateur et le dénominateur de 1/3 par 2.'),
      ('m6_frac_equivalentes',
       'On obtient une fraction égale en multipliant ou en divisant son numérateur et son dénominateur par un même nombre non nul.',
       'Une tablette contient 6 carrés, dont 4 colorés. La même part peut s’écrire 4/6 ou 2/3, car on divise 4 et 6 par 2.'),
      ('m6_calc_add_decimaux',
       'Pour additionner des nombres décimaux, on aligne les virgules et les chiffres de même rang. On peut ajouter des zéros à droite de la partie décimale.',
       E'[OPERATION]\n  12,40\n+  3,75\n────────\n  16,15\n[/OPERATION]\nLes virgules sont placées exactement l’une sous l’autre.'),
      ('m6_calc_soustraire_decimaux',
       'Pour soustraire des nombres décimaux, on aligne les virgules et les chiffres de même rang. On peut ajouter des zéros à droite de la partie décimale.',
       E'[OPERATION]\n   8,20\n−  3,45\n────────\n   4,75\n[/OPERATION]\nOn écrit 8,20 afin d’aligner les centièmes.'),
      ('m6_data_lire_tableau',
       'On repère la ligne et la colonne demandées, puis on lit la valeur située à leur intersection.',
       E'[TABLE]\nJour|Lundi|Mardi\nLivres lus|8|12\n[/TABLE]\nÀ l’intersection de la ligne « Livres lus » et de la colonne « Mardi », on lit 12.'),
      ('m6_data_construire_tableau',
       'Un tableau organise les données en lignes et en colonnes. Les intitulés doivent indiquer clairement ce que représente chaque ligne et chaque colonne.',
       E'[TABLE]\nClasse|6e A|6e B\nFootball|8|6\nNatation|5|7\n[/TABLE]\nCe tableau permet de comparer rapidement les sports choisis dans chaque classe.'),
      ('m6_mes_convertir_longueur',
       'Dans un tableau de conversion, chaque chiffre occupe la colonne de son unité. Vers une unité immédiatement plus petite, on multiplie par 10 ; vers une unité plus grande, on divise par 10.',
       E'[TABLE]\nkm|hm|dam|m|dm|cm|mm\n|||3|5|0|\n[/TABLE]\n3,5 m correspond à 350 cm.'),
      ('m6_mes_convertir_aire',
       'Dans un tableau d’aires, chaque unité occupe deux colonnes, car deux unités d’aire consécutives sont séparées par un facteur 100.',
       E'[TABLE]\nm²|m²|dm²|dm²|cm²|cm²\n0|3|0|0|0|0\n[/TABLE]\n3 m² = 300 dm² : on se déplace de deux colonnes.'),
      ('m6_data_lire_barres',
       'Dans un diagramme en barres, la hauteur de chaque barre correspond à une valeur indiquée sur l’axe gradué.',
       E'[BARS]Lundi=8;Mardi=12;Mercredi=6[/BARS]\nLa barre de mardi atteint 12 : la valeur du mardi est donc 12.'),
      ('m6_data_lire_circulaire',
       'Dans un diagramme circulaire, le disque entier représente 100 %. Un demi-disque représente 50 % et un quart de disque représente 25 %.',
       E'[PIE]25[/PIE]\nLe secteur coloré occupe un quart du disque : il représente 25 %.'),
      ('m6_data_lire_courbe',
       'Pour lire une courbe, on part de l’abscisse demandée, on rejoint la courbe puis on lit la valeur correspondante sur l’axe vertical.',
       E'[CURVE]8=12;10=18;12=15[/CURVE]\nÀ 10 h, le point de la courbe correspond à la valeur 18.'),
      ('m6_prop_lire_tableau',
       'Dans un tableau de proportionnalité, les valeurs placées dans une même colonne sont associées. Le même coefficient relie les deux lignes.',
       E'[TABLE]\nQuantité|2|4|6\nPrix (€)|6|12|18\n[/TABLE]\nDans la colonne du milieu, 4 objets sont associés à 12 €.'),
      ('m6_prop_completer_tableau',
       'Pour compléter un tableau de proportionnalité, on applique le même coefficient aux deux lignes ou on utilise les relations entre les colonnes.',
       E'[TABLE]\nQuantité|3|5|7\nPrix (€)|12|20|28\n[/TABLE]\nLe prix vaut 4 fois la quantité : pour 7 objets, 7 × 4 = 28 €.'),
      ('m6_prop_linearite_multiplicative',
       'Dans une situation proportionnelle, si une quantité est multipliée par un nombre, la grandeur associée est multipliée par le même nombre.',
       E'[TABLE]\nQuantité|3|6\nPrix (€)|12|24\n[/TABLE]\nDe 3 à 6, on multiplie par 2 ; on multiplie donc aussi 12 € par 2.'),
      ('m6_frac_soustraction_meme_denominateur',
       'Pour soustraire des fractions de même dénominateur, on conserve le dénominateur et on soustrait les numérateurs.',
       '5/7 − 2/7 = 3/7 : les parts sont toutes des septièmes, on retire donc 2 parts aux 5 parts de départ.')
    ) as proposed(micro_skill_code, reminder, worked_example)
  loop
    select ms.id, ms.student_name into selected_micro_skill_id, selected_title
    from public.micro_skills ms where ms.code = item.micro_skill_code and ms.active;
    if selected_micro_skill_id is null then
      raise exception 'Micro-skill not found: %', item.micro_skill_code;
    end if;
    select coalesce(max(lr.version_number), 0) + 1 into next_version
    from public.learning_resources lr where lr.micro_skill_id = selected_micro_skill_id;
    update public.learning_resources set active = false, updated_at = statement_timestamp()
    where micro_skill_id = selected_micro_skill_id and active;
    insert into public.learning_resources
      (micro_skill_id, title, reminder, worked_example, version_number, active)
    values
      (selected_micro_skill_id, selected_title, item.reminder, item.worked_example, next_version, true);
  end loop;
end;
$block$;

commit;
