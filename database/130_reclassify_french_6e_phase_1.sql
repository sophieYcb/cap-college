/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/130_reclassify_french_6e_phase_1.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Reclassify the first 500 unambiguous French 6e questions.
 Idempotent   : Yes
 Safety       : Only changes questions.micro_skill_id.
===============================================================================
*/

begin;

do $block$
declare
  atomic_micro_skill_count integer;
begin
  select count(*)
  into atomic_micro_skill_count
  from public.micro_skills
  where code like 'f6\_%' escape '\';

  if atomic_micro_skill_count <> 85 then
    raise exception
      'Reclassification cancelled: expected 85 atomic micro-skills, found %.',
      atomic_micro_skill_count;
  end if;
end
$block$;

create temporary table _french_reclassification_phase1
on commit drop
as
with direct_mapping(old_code, new_code) as (
  values
    ('legacy_c_conditionnel',  'f6_con_conditionnel_present'),
    ('legacy_c_futur',         'f6_con_futur'),
    ('legacy_c_imparfait',     'f6_con_imparfait'),
    ('legacy_c_imperatif',     'f6_con_imperatif_present'),
    ('legacy_c_passe_compose', 'f6_con_passe_compose'),
    ('legacy_c_passe_simple',  'f6_con_passe_simple'),
    ('legacy_c_pqp',           'f6_con_plus_que_parfait'),
    ('legacy_c_present',       'f6_con_present'),
    ('legacy_c_valeurs',       'f6_con_identifier_valeur_temps'),

    ('legacy_g_attribut',      'f6_gra_identifier_attribut_sujet'),
    ('legacy_g_cod',           'f6_gra_identifier_cod'),
    ('legacy_g_coi',           'f6_gra_identifier_coi'),
    ('legacy_g_formes',        'f6_gra_identifier_forme_negative'),
    ('legacy_g_phrase',        'f6_gra_distinguer_phrase_simple_complexe'),

    ('legacy_o_gn',            'f6_ort_realiser_chaine_gn'),
    ('legacy_o_feminin',       'f6_ort_former_feminin'),
    ('legacy_o_a_a',           'f6_ort_distinguer_a_a'),
    ('legacy_o_et_est',        'f6_ort_distinguer_et_est'),
    ('legacy_o_son_sont',      'f6_ort_distinguer_son_sont'),
    ('legacy_o_lexicale',      'f6_ort_memoriser_mot_irregulier'),
    ('legacy_o_pluriel',       'f6_ort_former_pluriel_particulier'),

    ('legacy_v_antonymes',     'f6_voc_identifier_antonyme'),
    ('legacy_v_etymologie',    'f6_voc_utiliser_etymologie'),
    ('legacy_v_familles',      'f6_voc_identifier_famille_mots'),
    ('legacy_v_homonymes',     'f6_voc_distinguer_homonymes'),
    ('legacy_v_polysemie',     'f6_voc_interpreter_polysemie'),
    ('legacy_v_registres',     'f6_voc_identifier_registre'),
    ('legacy_v_sens',          'f6_voc_distinguer_propre_figure'),
    ('legacy_v_synonymes',     'f6_voc_identifier_synonyme')
),
question_targets as (
  select q.id as question_id, dm.new_code
  from public.questions q
  join public.micro_skills old_ms on old_ms.id = q.micro_skill_id
  join direct_mapping dm
    on old_ms.code in (dm.old_code, dm.new_code)
  where q.legacy_id between 1 and 590

  union all

  select
    q.id,
    case
      when q.legacy_id in (22, 24, 28, 31, 36)
        then 'f6_gra_identifier_sujet_inverse'
      else 'f6_gra_identifier_sujet'
    end
  from public.questions q
  join public.micro_skills old_ms on old_ms.id = q.micro_skill_id
  where old_ms.code in (
      'legacy_g_sujet',
      'f6_gra_identifier_sujet',
      'f6_gra_identifier_sujet_inverse'
    )
    and q.legacy_id between 21 and 40

  union all

  select
    q.id,
    case
      when q.legacy_id in (67, 70, 74)
        then 'f6_gra_identifier_forme_exclamative'
      else 'f6_gra_identifier_type_phrase'
    end
  from public.questions q
  join public.micro_skills old_ms on old_ms.id = q.micro_skill_id
  where old_ms.code in (
      'legacy_g_types',
      'f6_gra_identifier_type_phrase',
      'f6_gra_identifier_forme_exclamative'
    )
    and q.legacy_id between 61 and 80

  union all

  select
    q.id,
    case
      when q.legacy_id in (401, 404, 407, 410)
        then 'f6_gra_identifier_cc_temps'
      when q.legacy_id in (402, 405, 408)
        then 'f6_gra_identifier_cc_lieu'
      else 'f6_gra_identifier_cc_cause'
    end
  from public.questions q
  join public.micro_skills old_ms on old_ms.id = q.micro_skill_id
  where old_ms.code in (
      'legacy_g_cc',
      'f6_gra_identifier_cc_temps',
      'f6_gra_identifier_cc_lieu',
      'f6_gra_identifier_cc_cause'
    )
    and q.legacy_id between 401 and 410

  union all

  select
    q.id,
    case
      when q.legacy_id in (421, 423, 425, 427, 429)
        then 'f6_gra_identifier_epithete'
      else 'f6_gra_identifier_complement_nom'
    end
  from public.questions q
  join public.micro_skills old_ms on old_ms.id = q.micro_skill_id
  where old_ms.code in (
      'legacy_g_expansions',
      'f6_gra_identifier_epithete',
      'f6_gra_identifier_complement_nom'
    )
    and q.legacy_id between 421 and 430
)
select qt.question_id, new_ms.id as new_micro_skill_id
from question_targets qt
join public.micro_skills new_ms on new_ms.code = qt.new_code;

do $block$
declare
  mapping_count integer;
  unique_question_count integer;
begin
  select count(*), count(distinct question_id)
  into mapping_count, unique_question_count
  from _french_reclassification_phase1;

  if mapping_count <> 500 or unique_question_count <> 500 then
    raise exception
      'Reclassification cancelled: expected 500 unique mappings, found % mappings for % questions.',
      mapping_count,
      unique_question_count;
  end if;
end
$block$;

update public.questions q
set micro_skill_id = vt.new_micro_skill_id,
    updated_at = statement_timestamp()
from _french_reclassification_phase1 vt
where q.id = vt.question_id
  and q.micro_skill_id is distinct from vt.new_micro_skill_id;

commit;
