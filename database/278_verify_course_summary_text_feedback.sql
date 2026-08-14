with expected_codes(code) as (values
  ('f6_con_distinguer_temps_chronologique_verbal'), ('f6_gra_distinguer_attribut_cod'),
  ('f6_ort_participe_passe_avoir'), ('f6_voc_identifier_prefixe'),
  ('m6_num_arrondir_centieme'), ('m6_num_arrondir_dixieme'), ('m6_num_arrondir_unite'),
  ('m6_mes_aire_rectangle'), ('m6_mes_aire_carre'), ('m6_mes_prefixes'),
  ('m6_mes_perimetre_disque_formule'), ('m6_mes_convertir_duree'),
  ('m6_calc_diviser_10_100_1000'), ('m6_data_planifier_enquete'),
  ('m6_calc_multiplier_decimal'), ('m6_prop_retour_unite'),
  ('m6_mes_perimetre_disque_calcul'), ('m6_num_comparer_decimaux'),
  ('m6_mes_calcul_horaire'), ('m6_calc_multiplier_10_100_1000'),
  ('m6_calc_division_decimale'), ('m6_pct_exprimer_proportion'), ('m6_frac_ordonner')
), latest as (
  select ms.code, lr.reminder, lr.worked_example, lr.active,
    row_number() over (partition by ms.id order by lr.version_number desc) position
  from expected_codes ec
  join public.micro_skills ms on ms.code = ec.code
  join public.learning_resources lr on lr.micro_skill_id = ms.id
)
select jsonb_build_object('verification', jsonb_build_object(
  'expected_corrections', (select count(*) from expected_codes),
  'active_latest_resources', (select count(*) from latest where position = 1 and active),
  'rules_present', (select count(*) from latest where position = 1 and active and btrim(reminder) <> ''),
  'examples_present', (select count(*) from latest where position = 1 and active and btrim(worked_example) <> ''),
  'missing_codes', coalesce((select jsonb_agg(ec.code order by ec.code) from expected_codes ec
    where not exists (select 1 from latest l where l.code = ec.code and l.position = 1 and l.active
      and btrim(l.reminder) <> '' and btrim(l.worked_example) <> '')), '[]'::jsonb)
)) as verification;
