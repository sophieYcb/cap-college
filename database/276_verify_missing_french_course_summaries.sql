with expected_codes(code) as (values
  ('f6_con_present'), ('f6_con_imparfait'), ('f6_con_futur'),
  ('f6_con_passe_compose'), ('f6_con_passe_simple'),
  ('f6_con_plus_que_parfait'), ('f6_con_imperatif_present'),
  ('f6_con_conditionnel_present'), ('f6_con_identifier_valeur_temps'),
  ('f6_gra_identifier_type_phrase'), ('f6_gra_identifier_forme_negative'),
  ('f6_gra_distinguer_phrase_simple_complexe'), ('f6_ort_realiser_chaine_gn'),
  ('f6_ort_former_feminin'), ('f6_ort_former_pluriel_particulier'),
  ('f6_ort_memoriser_mot_irregulier'), ('f6_ort_distinguer_a_a'),
  ('f6_ort_distinguer_et_est'), ('f6_ort_distinguer_son_sont'),
  ('f6_voc_identifier_synonyme'), ('f6_voc_identifier_antonyme'),
  ('f6_voc_identifier_famille_mots'), ('f6_voc_interpreter_polysemie'),
  ('f6_voc_distinguer_propre_figure'), ('f6_voc_distinguer_homonymes'),
  ('f6_voc_identifier_registre'), ('f6_voc_utiliser_etymologie')
), current_resources as (
  select ms.code, lr.reminder, lr.worked_example,
    row_number() over (partition by ms.id order by lr.version_number desc) as position
  from expected_codes ec
  join public.micro_skills ms on ms.code = ec.code
  join public.learning_resources lr on lr.micro_skill_id = ms.id and lr.active
)
select jsonb_build_object('verification', jsonb_build_object(
  'expected_summaries', (select count(*) from expected_codes),
  'active_summaries', (select count(*) from current_resources where position = 1),
  'summaries_with_rule', (select count(*) from current_resources where position = 1 and btrim(reminder) <> ''),
  'summaries_with_example', (select count(*) from current_resources where position = 1 and btrim(worked_example) <> ''),
  'missing_codes', coalesce((
    select jsonb_agg(ec.code order by ec.code) from expected_codes ec
    where not exists (
      select 1 from current_resources cr where cr.code = ec.code and cr.position = 1
        and btrim(cr.reminder) <> '' and btrim(cr.worked_example) <> ''
    )
  ), '[]'::jsonb)
)) as verification;
