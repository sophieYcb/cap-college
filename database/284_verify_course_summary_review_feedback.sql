with expected_codes(code) as (values
  ('f6_con_imparfait'),
  ('m6_mes_convertir_aire'),
  ('m6_calc_soustraire_decimaux'),
  ('m6_mes_calcul_horaire'),
  ('m6_frac_ordonner')
), latest as (
  select ms.code, lr.reminder, lr.worked_example, lr.active, lr.version_number,
    row_number() over (partition by ms.id order by lr.version_number desc) position
  from expected_codes ec
  join public.micro_skills ms on ms.code = ec.code
  join public.learning_resources lr on lr.micro_skill_id = ms.id
)
select jsonb_build_object('verification', jsonb_build_object(
  'corrected_summaries', (select count(*) from latest where position = 1 and active),
  'previous_versions_preserved', (select count(distinct code) from latest where position > 1),
  'rules_present', (select count(*) from latest where position = 1 and active and btrim(reminder) <> ''),
  'examples_present', (select count(*) from latest where position = 1 and active and btrim(worked_example) <> ''),
  'area_table_corrected', exists(select 1 from latest where code = 'm6_mes_convertir_aire' and position = 1 and worked_example like E'%|3|0|0||%'),
  'subtraction_statement_present', exists(select 1 from latest where code = 'm6_calc_soustraire_decimaux' and position = 1 and worked_example like '%8,2 − 3,45%'),
  'missing_codes', coalesce((select jsonb_agg(ec.code order by ec.code) from expected_codes ec
    where not exists (select 1 from latest l where l.code = ec.code and l.position = 1 and l.active)), '[]'::jsonb)
)) as verification;