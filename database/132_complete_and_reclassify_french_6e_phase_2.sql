/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/132_complete_and_reclassify_french_6e_phase_2.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Add 3 missing atomic skills and reclassify the final 90 questions.
 Idempotent   : Yes
 Safety       : Does not modify question content, versions, reviews or answers.
===============================================================================
*/

begin;

with additions(skill_code, code, name, sort_order) as (
  values
    ('f6_word_classes','f6_gra_identifier_conjonction','Identifier une conjonction',90),
    ('f6_word_classes','f6_gra_identifier_preposition','Identifier une préposition',100),
    ('f6_vocabulary_system','f6_voc_distinguer_mot_simple_derive','Distinguer mot simple et mot dérivé',130)
)
insert into public.micro_skills (
  id,
  skill_id,
  code,
  teacher_name,
  student_name,
  description,
  mastery_criteria,
  sort_order,
  active
)
select
  md5('cap-college:french-6e-micro-skill:' || a.code)::uuid,
  sk.id,
  a.code,
  a.name,
  a.name,
  'Micro-compétence atomique du programme de français 6e.',
  'Au moins 10 questions validées et des réussites suffisamment régulières.',
  a.sort_order,
  true
from additions a
join public.skills sk on sk.code = a.skill_code
on conflict (code) do update
set skill_id = excluded.skill_id,
    teacher_name = excluded.teacher_name,
    student_name = excluded.student_name,
    description = excluded.description,
    mastery_criteria = excluded.mastery_criteria,
    sort_order = excluded.sort_order,
    active = true,
    updated_at = statement_timestamp();

insert into public.micro_skill_levels (micro_skill_id, level_id, is_expected)
select ms.id, l.id, true
from public.micro_skills ms
cross join public.levels l
where ms.code in (
    'f6_gra_identifier_conjonction',
    'f6_gra_identifier_preposition',
    'f6_voc_distinguer_mot_simple_derive'
  )
  and l.code = '6e'
on conflict (micro_skill_id, level_id) do update
set is_expected = true;

create table if not exists public._french_reclassification_phase2 (
  question_id uuid primary key,
  new_micro_skill_id uuid not null
);

alter table public._french_reclassification_phase2 enable row level security;
revoke all on public._french_reclassification_phase2 from anon, authenticated;
truncate table public._french_reclassification_phase2;

insert into public._french_reclassification_phase2 (
  question_id,
  new_micro_skill_id
)
with question_targets(legacy_id, new_code) as (
  values
    (1,'f6_gra_identifier_determinant'),
    (2,'f6_gra_identifier_determinant'),
    (3,'f6_gra_identifier_adverbe'),
    (4,'f6_gra_identifier_adjectif'),
    (5,'f6_gra_identifier_nom'),
    (6,'f6_gra_identifier_pronom_personnel'),
    (7,'f6_gra_identifier_verbe'),
    (8,'f6_gra_identifier_determinant'),
    (9,'f6_gra_identifier_pronom_personnel'),
    (10,'f6_gra_identifier_adjectif'),
    (11,'f6_gra_identifier_adverbe'),
    (12,'f6_gra_identifier_nom'),
    (13,'f6_gra_identifier_verbe'),
    (14,'f6_gra_identifier_determinant'),
    (15,'f6_gra_identifier_conjonction'),
    (16,'f6_gra_identifier_preposition'),
    (17,'f6_gra_identifier_adjectif'),
    (18,'f6_gra_identifier_adverbe'),
    (19,'f6_gra_identifier_determinant'),
    (20,'f6_gra_identifier_pronom_personnel'),

    (181,'f6_ort_accorder_sujet_verbe_simple'),
    (182,'f6_ort_accorder_sujet_compose'),
    (183,'f6_ort_accorder_sujet_verbe_eloigne'),
    (184,'f6_ort_accorder_sujet_verbe_simple'),
    (185,'f6_ort_accorder_sujet_verbe_simple'),
    (186,'f6_ort_accorder_sujet_verbe_simple'),
    (187,'f6_ort_accorder_sujet_verbe_simple'),
    (188,'f6_ort_accorder_sujet_compose'),
    (189,'f6_ort_accorder_sujet_compose'),
    (190,'f6_ort_accorder_sujet_verbe_simple'),
    (191,'f6_ort_accorder_sujet_verbe_eloigne'),
    (192,'f6_ort_accorder_sujet_verbe_eloigne'),
    (193,'f6_ort_accorder_sujet_verbe_eloigne'),
    (194,'f6_ort_accorder_sujet_compose'),
    (195,'f6_ort_accorder_sujet_verbe_simple'),
    (196,'f6_ort_accorder_sujet_verbe_simple'),
    (197,'f6_ort_accorder_sujet_verbe_simple'),
    (198,'f6_ort_accorder_sujet_verbe_eloigne'),
    (199,'f6_ort_accorder_sujet_compose'),
    (200,'f6_ort_accorder_sujet_verbe_eloigne'),

    (411,'f6_gra_retrouver_antecedent_pronom'),
    (412,'f6_gra_identifier_pronom_personnel'),
    (413,'f6_gra_distinguer_pronom_sujet_objet'),
    (414,'f6_gra_distinguer_pronom_sujet_objet'),
    (415,'f6_gra_retrouver_antecedent_pronom'),
    (416,'f6_gra_distinguer_pronom_sujet_objet'),
    (417,'f6_gra_distinguer_pronom_sujet_objet'),
    (418,'f6_gra_distinguer_pronom_sujet_objet'),
    (419,'f6_gra_retrouver_antecedent_pronom'),
    (420,'f6_gra_distinguer_pronom_sujet_objet'),

    (431,'f6_gra_compter_propositions'),
    (432,'f6_gra_identifier_juxtaposition'),
    (433,'f6_gra_identifier_coordination'),
    (434,'f6_gra_identifier_subordination'),
    (435,'f6_gra_identifier_coordination'),
    (436,'f6_gra_identifier_subordination'),
    (437,'f6_gra_identifier_juxtaposition'),
    (438,'f6_gra_identifier_coordination'),
    (439,'f6_gra_compter_propositions'),
    (440,'f6_gra_identifier_subordination'),

    (501,'f6_con_identifier_radical'),
    (502,'f6_con_identifier_marque_personne'),
    (503,'f6_con_identifier_marque_temps'),
    (504,'f6_con_identifier_marque_temps'),
    (505,'f6_con_identifier_radical'),
    (506,'f6_con_identifier_marque_personne'),
    (507,'f6_con_identifier_marque_personne'),
    (508,'f6_con_identifier_radical'),
    (509,'f6_con_variation_radical'),
    (510,'f6_con_variation_radical'),

    (511,'f6_ort_participe_passe_etre'),
    (512,'f6_ort_participe_passe_etre'),
    (513,'f6_ort_participe_passe_avoir'),
    (514,'f6_ort_participe_passe_etre'),
    (515,'f6_ort_participe_passe_avoir'),
    (516,'f6_ort_participe_passe_etre'),
    (517,'f6_ort_participe_passe_avoir'),
    (518,'f6_ort_participe_passe_etre'),
    (519,'f6_ort_participe_passe_avoir'),
    (520,'f6_ort_participe_passe_etre'),

    (541,'f6_voc_identifier_prefixe'),
    (542,'f6_voc_identifier_suffixe'),
    (543,'f6_voc_identifier_mot_compose'),
    (544,'f6_voc_distinguer_mot_simple_derive'),
    (545,'f6_voc_distinguer_mot_simple_derive'),
    (546,'f6_voc_identifier_prefixe'),
    (547,'f6_voc_identifier_suffixe'),
    (548,'f6_voc_identifier_mot_compose'),
    (549,'f6_voc_identifier_prefixe'),
    (550,'f6_voc_identifier_suffixe')
)
select q.id, ms.id
from question_targets qt
join public.questions q on q.legacy_id = qt.legacy_id
join public.micro_skills ms on ms.code = qt.new_code;

do $block$
declare
  mapping_count integer;
  unique_question_count integer;
begin
  select count(*), count(distinct question_id)
  into mapping_count, unique_question_count
  from public._french_reclassification_phase2;

  if mapping_count <> 90 or unique_question_count <> 90 then
    raise exception
      'Reclassification cancelled: expected 90 unique mappings, found % mappings for % questions.',
      mapping_count,
      unique_question_count;
  end if;
end
$block$;

update public.questions q
set micro_skill_id = m.new_micro_skill_id,
    updated_at = statement_timestamp()
from public._french_reclassification_phase2 m
where q.id = m.question_id
  and q.micro_skill_id is distinct from m.new_micro_skill_id;

drop table public._french_reclassification_phase2;

commit;
