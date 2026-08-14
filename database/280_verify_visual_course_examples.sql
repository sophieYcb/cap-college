with expected_codes(code) as (values
  ('m6_prop_linearite_additive'), ('m6_frac_add_denominateurs_multiples'),
  ('m6_frac_equivalentes'), ('m6_calc_add_decimaux'),
  ('m6_calc_soustraire_decimaux'), ('m6_data_lire_tableau'),
  ('m6_data_construire_tableau'), ('m6_mes_convertir_longueur'),
  ('m6_mes_convertir_aire'), ('m6_data_lire_barres'),
  ('m6_data_lire_circulaire'), ('m6_data_lire_courbe'),
  ('m6_prop_lire_tableau'), ('m6_prop_completer_tableau'),
  ('m6_prop_linearite_multiplicative'), ('m6_frac_soustraction_meme_denominateur')
), latest as (
  select ms.code, lr.reminder, lr.worked_example, lr.active,
    row_number() over (partition by ms.id order by lr.version_number desc) position
  from expected_codes ec
  join public.micro_skills ms on ms.code = ec.code
  join public.learning_resources lr on lr.micro_skill_id = ms.id
)
select jsonb_build_object('verification', jsonb_build_object(
  'expected_visual_summaries', (select count(*) from expected_codes),
  'active_latest_resources', (select count(*) from latest where position = 1 and active),
  'structured_visual_examples', (select count(*) from latest where position = 1 and active
    and worked_example ~ '\[(TABLE|OPERATION|BARS|PIE|CURVE)\]'),
  'fraction_examples', (select count(*) from latest where position = 1 and active
    and code like 'm6_frac_%' and worked_example ~ '[0-9]+/[0-9]+'),
  'missing_codes', coalesce((select jsonb_agg(ec.code order by ec.code) from expected_codes ec
    where not exists (select 1 from latest l where l.code = ec.code and l.position = 1 and l.active
      and btrim(l.reminder) <> '' and btrim(l.worked_example) <> '')), '[]'::jsonb)
)) as verification;
