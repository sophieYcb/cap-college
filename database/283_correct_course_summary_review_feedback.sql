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
      ('f6_con_imparfait',
       'Pour former l’imparfait, on prend le radical de la forme « nous » au présent : on enlève la terminaison -ons, puis on ajoute -ais, -ais, -ait, -ions, -iez, -aient. Le verbe être est une exception : son radical est ét-.',
       'Nous chantons → on enlève -ons pour obtenir le radical chant- → je chantais, nous chantions. Avec être : vous étiez.'),
      ('m6_mes_convertir_aire',
       'Dans un tableau d’aires, chaque unité occupe deux colonnes, car deux unités d’aire consécutives sont séparées par un facteur 100.',
       E'[TABLE]\nm²|m²|dm²|dm²|cm²|cm²\n|3|0|0||\n[/TABLE]\n3 m² = 300 dm² : les deux zéros occupent les deux colonnes des dm².'),
      ('m6_calc_soustraire_decimaux',
       'Pour soustraire des nombres décimaux, on aligne les virgules et les chiffres de même rang. On peut ajouter des zéros à droite de la partie décimale.',
       E'[OPERATION]\n   8,20\n−  3,45\n────────\n   4,75\n[/OPERATION]\nPour calculer 8,2 − 3,45, on écrit 8,20 afin d’aligner les centièmes.'),
      ('m6_mes_calcul_horaire',
       'Pour trouver une heure d’arrivée, on ajoute la durée à l’heure de départ. Pour trouver une heure de départ, on retire la durée de l’heure d’arrivée. On calcule séparément les heures et les minutes.',
       'Départ à 14 h 20, trajet de 35 min : 14 h + (20 min + 35 min) = 14 h + 55 min = 14 h 55.'),
      ('m6_frac_ordonner',
       'Pour ranger plusieurs fractions, on les écrit si possible avec un même dénominateur, puis on compare leurs numérateurs.',
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