/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/128_create_french_6e_atomic_referential.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Create the atomic French 6e language referential.
 Reference    : BO n° 16 du 17 avril 2025.
 Idempotent   : Yes
 Safety       : Does not reassign or modify any existing question.
===============================================================================
*/

begin;

do $block$
begin
  if not exists (select 1 from public.subjects where code = 'french') then
    raise exception 'Missing subject: french';
  end if;
  if not exists (select 1 from public.levels where code = '6e') then
    raise exception 'Missing level: 6e';
  end if;
end
$block$;

with skill_seed(domain_code, code, name, sort_order) as (
  values
    ('grammar',     'f6_sentence_types_forms', 'Types et formes de phrases', 10),
    ('grammar',     'f6_simple_sentence',      'Constituants de la phrase simple', 20),
    ('grammar',     'f6_word_classes',         'Classes grammaticales', 30),
    ('grammar',     'f6_noun_phrase',          'Groupe nominal', 40),
    ('grammar',     'f6_complex_sentence',     'Phrase complexe', 50),
    ('spelling',    'f6_noun_phrase_agreement','Accords dans le groupe nominal', 10),
    ('spelling',    'f6_verb_agreement',       'Accords autour du verbe', 20),
    ('spelling',    'f6_lexical_spelling',     'Orthographe lexicale', 30),
    ('conjugation', 'f6_tenses',               'Temps à maîtriser', 10),
    ('conjugation', 'f6_construction_usage',   'Construction et emploi des verbes', 20),
    ('vocabulary',  'f6_vocabulary_system',    'Système lexical et sens des mots', 10)
)
insert into public.skills (
  id,
  domain_id,
  code,
  name,
  description,
  sort_order,
  active
)
select
  md5('cap-college:french-6e-skill:' || ss.code)::uuid,
  d.id,
  ss.code,
  ss.name,
  'Référentiel atomique français 6e conforme au programme 2025.',
  ss.sort_order,
  true
from skill_seed ss
join public.domains d on d.code = ss.domain_code
join public.subjects s on s.id = d.subject_id and s.code = 'french'
on conflict (domain_id, code) do update
set name = excluded.name,
    description = excluded.description,
    sort_order = excluded.sort_order,
    active = true,
    updated_at = statement_timestamp();

with micro_seed(skill_code, code, name, sort_order) as (
  values
    ('f6_sentence_types_forms','f6_gra_identifier_type_phrase','Identifier le type déclaratif, interrogatif ou injonctif',10),
    ('f6_sentence_types_forms','f6_gra_identifier_forme_negative','Identifier une phrase à la forme négative',20),
    ('f6_sentence_types_forms','f6_gra_identifier_forme_exclamative','Identifier une phrase à la forme exclamative',30),
    ('f6_sentence_types_forms','f6_gra_transformer_type_phrase','Transformer le type d’une phrase',40),
    ('f6_sentence_types_forms','f6_gra_transformer_forme_phrase','Transformer la forme d’une phrase',50),

    ('f6_simple_sentence','f6_gra_identifier_verbe_conjugue','Identifier le verbe conjugué',10),
    ('f6_simple_sentence','f6_gra_identifier_sujet','Identifier un sujet placé avant le verbe',20),
    ('f6_simple_sentence','f6_gra_identifier_sujet_inverse','Identifier un sujet inversé',30),
    ('f6_simple_sentence','f6_gra_identifier_cod','Identifier un COD',40),
    ('f6_simple_sentence','f6_gra_identifier_coi','Identifier un COI',50),
    ('f6_simple_sentence','f6_gra_distinguer_cod_coi','Distinguer COD et COI',60),
    ('f6_simple_sentence','f6_gra_identifier_attribut_sujet','Identifier l’attribut du sujet',70),
    ('f6_simple_sentence','f6_gra_distinguer_attribut_cod','Distinguer attribut du sujet et COD',80),
    ('f6_simple_sentence','f6_gra_identifier_cc_temps','Identifier un complément circonstanciel de temps',90),
    ('f6_simple_sentence','f6_gra_identifier_cc_lieu','Identifier un complément circonstanciel de lieu',100),
    ('f6_simple_sentence','f6_gra_identifier_cc_cause','Identifier un complément circonstanciel de cause',110),
    ('f6_simple_sentence','f6_gra_distinguer_objet_circonstanciel','Distinguer complément d’objet et complément circonstanciel',120),

    ('f6_word_classes','f6_gra_identifier_nom','Identifier un nom',10),
    ('f6_word_classes','f6_gra_identifier_determinant','Identifier un déterminant',20),
    ('f6_word_classes','f6_gra_identifier_adjectif','Identifier un adjectif',30),
    ('f6_word_classes','f6_gra_identifier_verbe','Identifier un verbe',40),
    ('f6_word_classes','f6_gra_identifier_adverbe','Identifier un adverbe',50),
    ('f6_word_classes','f6_gra_identifier_pronom_personnel','Identifier un pronom personnel',60),
    ('f6_word_classes','f6_gra_distinguer_pronom_sujet_objet','Distinguer pronom personnel sujet et objet',70),
    ('f6_word_classes','f6_gra_retrouver_antecedent_pronom','Retrouver l’antécédent d’un pronom',80),

    ('f6_noun_phrase','f6_gra_identifier_groupe_nominal','Identifier un groupe nominal',10),
    ('f6_noun_phrase','f6_gra_identifier_nom_noyau','Identifier le nom noyau',20),
    ('f6_noun_phrase','f6_gra_identifier_epithete','Identifier un adjectif épithète',30),
    ('f6_noun_phrase','f6_gra_identifier_complement_nom','Identifier un complément du nom',40),
    ('f6_noun_phrase','f6_gra_distinguer_epithete_complement_nom','Distinguer épithète et complément du nom',50),
    ('f6_noun_phrase','f6_gra_distinguer_epithete_attribut','Distinguer épithète et attribut du sujet',60),

    ('f6_complex_sentence','f6_gra_compter_propositions','Compter les propositions',10),
    ('f6_complex_sentence','f6_gra_distinguer_phrase_simple_complexe','Distinguer phrase simple et phrase complexe',20),
    ('f6_complex_sentence','f6_gra_identifier_juxtaposition','Identifier des propositions juxtaposées',30),
    ('f6_complex_sentence','f6_gra_identifier_coordination','Identifier des propositions coordonnées',40),
    ('f6_complex_sentence','f6_gra_identifier_subordination','Identifier une proposition subordonnée',50),
    ('f6_complex_sentence','f6_gra_distinguer_articulations','Distinguer juxtaposition, coordination et subordination',60),

    ('f6_noun_phrase_agreement','f6_ort_accorder_gn_genre','Réaliser les accords en genre dans le groupe nominal',10),
    ('f6_noun_phrase_agreement','f6_ort_accorder_gn_nombre','Réaliser les accords en nombre dans le groupe nominal',20),
    ('f6_noun_phrase_agreement','f6_ort_realiser_chaine_gn','Réaliser toute la chaîne d’accords du groupe nominal',30),
    ('f6_noun_phrase_agreement','f6_ort_former_feminin','Former le féminin des noms et des adjectifs',40),
    ('f6_noun_phrase_agreement','f6_ort_former_pluriel_regulier','Former un pluriel régulier',50),
    ('f6_noun_phrase_agreement','f6_ort_former_pluriel_particulier','Former un pluriel particulier',60),

    ('f6_verb_agreement','f6_ort_accorder_sujet_verbe_simple','Accorder un verbe avec un sujet simple antéposé',10),
    ('f6_verb_agreement','f6_ort_accorder_sujet_verbe_eloigne','Accorder malgré un élément placé entre sujet et verbe',20),
    ('f6_verb_agreement','f6_ort_accorder_sujet_verbe_inverse','Accorder un verbe avec un sujet inversé',30),
    ('f6_verb_agreement','f6_ort_accorder_sujet_compose','Accorder un verbe avec un sujet composé',40),
    ('f6_verb_agreement','f6_ort_accorder_sujet_attribut','Accorder l’attribut avec le sujet',50),
    ('f6_verb_agreement','f6_ort_participe_passe_etre','Accorder le participe passé employé avec être',60),
    ('f6_verb_agreement','f6_ort_participe_passe_avoir','Accorder le participe passé avec le COD placé avant',70),

    ('f6_lexical_spelling','f6_ort_utiliser_famille_mots','Utiliser une famille de mots pour orthographier',10),
    ('f6_lexical_spelling','f6_ort_memoriser_mot_irregulier','Orthographier les mots irréguliers fréquents',20),
    ('f6_lexical_spelling','f6_ort_distinguer_a_a','Distinguer a et à',30),
    ('f6_lexical_spelling','f6_ort_distinguer_et_est','Distinguer et et est',40),
    ('f6_lexical_spelling','f6_ort_distinguer_son_sont','Distinguer son et sont',50),

    ('f6_tenses','f6_con_present','Conjuguer au présent de l’indicatif',10),
    ('f6_tenses','f6_con_imparfait','Conjuguer à l’imparfait',20),
    ('f6_tenses','f6_con_futur','Conjuguer au futur simple',30),
    ('f6_tenses','f6_con_passe_compose','Conjuguer au passé composé',40),
    ('f6_tenses','f6_con_passe_simple','Conjuguer au passé simple',50),
    ('f6_tenses','f6_con_plus_que_parfait','Conjuguer au plus-que-parfait',60),
    ('f6_tenses','f6_con_imperatif_present','Conjuguer à l’impératif présent',70),
    ('f6_tenses','f6_con_conditionnel_present','Conjuguer au conditionnel présent',80),

    ('f6_construction_usage','f6_con_identifier_radical','Identifier le radical d’un verbe',10),
    ('f6_construction_usage','f6_con_identifier_marque_temps','Identifier une marque de temps',20),
    ('f6_construction_usage','f6_con_identifier_marque_personne','Identifier une marque de personne',30),
    ('f6_construction_usage','f6_con_variation_radical','Appliquer une variation du radical',40),
    ('f6_construction_usage','f6_con_identifier_temps_compose','Reconnaître les deux parties d’un temps composé',50),
    ('f6_construction_usage','f6_con_retrouver_infinitif_temps_compose','Retrouver l’infinitif d’un verbe à un temps composé',60),
    ('f6_construction_usage','f6_con_negation_temps_compose','Placer la négation à un temps composé',70),
    ('f6_construction_usage','f6_con_distinguer_passe_compose_pqp','Distinguer passé composé et plus-que-parfait',80),
    ('f6_construction_usage','f6_con_distinguer_temps_chronologique_verbal','Distinguer temps chronologique et temps verbal',90),
    ('f6_construction_usage','f6_con_identifier_valeur_temps','Identifier une valeur d’un temps dans un texte',100),

    ('f6_vocabulary_system','f6_voc_identifier_synonyme','Identifier un synonyme adapté au contexte',10),
    ('f6_vocabulary_system','f6_voc_identifier_antonyme','Identifier un antonyme de même classe grammaticale',20),
    ('f6_vocabulary_system','f6_voc_identifier_famille_mots','Identifier des mots d’une même famille',30),
    ('f6_vocabulary_system','f6_voc_identifier_prefixe','Identifier ou interpréter un préfixe',40),
    ('f6_vocabulary_system','f6_voc_identifier_suffixe','Identifier ou interpréter un suffixe',50),
    ('f6_vocabulary_system','f6_voc_identifier_mot_compose','Identifier la composition d’un mot',60),
    ('f6_vocabulary_system','f6_voc_interpreter_polysemie','Choisir le sens d’un mot polysémique en contexte',70),
    ('f6_vocabulary_system','f6_voc_distinguer_propre_figure','Distinguer sens propre et sens figuré',80),
    ('f6_vocabulary_system','f6_voc_distinguer_homonymes','Distinguer des homonymes grâce au contexte',90),
    ('f6_vocabulary_system','f6_voc_identifier_registre','Identifier un registre familier, courant ou soutenu',100),
    ('f6_vocabulary_system','f6_voc_lire_article_dictionnaire','Lire les informations d’un article de dictionnaire',110),
    ('f6_vocabulary_system','f6_voc_utiliser_etymologie','Utiliser l’origine d’un mot pour en comprendre le sens',120)
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
  md5('cap-college:french-6e-micro-skill:' || ms.code)::uuid,
  sk.id,
  ms.code,
  ms.name,
  ms.name,
  'Micro-compétence atomique du programme de français 6e.',
  'Au moins 10 questions validées et des réussites suffisamment régulières.',
  ms.sort_order,
  true
from micro_seed ms
join public.skills sk on sk.code = ms.skill_code
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
where ms.code like 'f6\_%' escape '\'
  and l.code = '6e'
on conflict (micro_skill_id, level_id) do update
set is_expected = true;

commit;
