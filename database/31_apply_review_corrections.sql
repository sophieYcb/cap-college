/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/31_apply_review_corrections.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Create N+1 versions from the explicit review comments imported
                on 2026-07-23, without altering the historical versions.
 Dependencies : 00_extensions.sql through 30_validator_question_api.sql
 Idempotent   : Yes
===============================================================================
*/

begin;

create table if not exists public._cap_college_correction_payload (
  legacy_id bigint primary key,
  prompt text,
  choices jsonb not null,
  correct_index smallint not null,
  change_comment text not null
);

alter table public._cap_college_correction_payload enable row level security;
revoke all on public._cap_college_correction_payload from anon, authenticated;

insert into public._cap_college_correction_payload (
  legacy_id, prompt, choices, correct_index, change_comment
)
values
  (161, 'Choisis la forme du verbe « chanter » au passé composé avec « je ».',
    '["suis chanté","ai chanté","chantais","chanterai"]', 2,
    'Retrait du pronom dans les choix : l’élision de « j’ai » ne donne plus la réponse.'),
  (167, 'Choisis la forme du verbe « voir » au passé composé avec « je ».',
    '["suis vu","ai vu","voyais","verrai"]', 2,
    'Retrait du pronom dans les choix : l’élision de « j’ai » ne donne plus la réponse.'),
  (179, 'Choisis la forme du verbe « avoir » au passé composé avec « je ».',
    '["avais","ai eu","aurai","suis eu"]', 2,
    'Retrait du pronom dans les choix : l’élision de « j’ai » ne donne plus la réponse.'),
  (299, null,
    '["médames","mesdames","mèsdames","mézdames"]', 2,
    'Distracteurs remplacés par des graphies phonétiquement proches.'),
  (322, null,
    '["froid","tiède","brûlant","bouillant"]', 1,
    'Remplacement du dernier distracteur par un mot du même champ lexical.'),
  (325, null,
    '["entrouvrir","déverrouiller","ouvrir davantage","fermer"]', 4,
    'Remplacement du distracteur peu pertinent.'),
  (326, null,
    '["terminer","poursuivre","reprendre","démarrer"]', 1,
    'Remplacement du distracteur peu pertinent.'),
  (327, null,
    '["grimper","descendre","escalader","s’élever"]', 2,
    'Remplacement du distracteur peu pertinent.'),
  (328, null,
    '["net","lavé","sale","impeccable"]', 3,
    'Remplacement du distracteur peu pertinent.'),
  (329, null,
    '["simple","évident","aisé","difficile"]', 4,
    'Remplacement du distracteur peu pertinent.'),
  (330, null,
    '["silencieux","sonore","retentissant","assourdissant"]', 1,
    'Remplacement du distracteur peu pertinent.'),
  (331, null,
    '["vieux","récent","passé","antique"]', 2,
    'Remplacement du distracteur peu pertinent.'),
  (332, null,
    '["lumineux","brillant","sombre","éclatant"]', 3,
    'Remplacement du distracteur peu pertinent.'),
  (333, null,
    '["hardi","brave","audacieux","peureux"]', 4,
    'Remplacement du distracteur peu pertinent.'),
  (334, null,
    '["vide","rempli","chargé","complet"]', 1,
    'Remplacement du distracteur peu pertinent.'),
  (335, null,
    '["approuver","refuser","admettre","consentir"]', 2,
    'Remplacement du distracteur peu pertinent.'),
  (336, null,
    '["voisin","prochain","lointain","rapproché"]', 3,
    'Remplacement du distracteur peu pertinent.'),
  (338, null,
    '["méchant","aimable","doux","bienveillant"]', 1,
    'Remplacement du distracteur peu pertinent.'),
  (339, null,
    '["réussir","perdre","vaincre","triompher"]', 2,
    'Remplacement du distracteur peu pertinent.'),
  (340, null,
    '["apparent","voyant","invisible","perceptible"]', 3,
    'Remplacement du distracteur peu pertinent.'),
  (471, 'Complète au plus-que-parfait : « J’___ avant midi. »',
    '["avais terminé","ai terminé","aurai terminé","aurais terminé"]', 1,
    'Le participe passé est intégré aux propositions pour comparer des formes complètes.'),
  (472, 'Complète au plus-que-parfait : « Elle ___ avant nous. »',
    '["est partie","était partie","sera partie","serait partie"]', 2,
    'Application de la même règle : formes verbales complètes dans les propositions.'),
  (476, null,
    '["elle est allée","elle était allée","elle avait allé","elle était allé"]', 2,
    'Le dernier distracteur teste désormais l’accord du participe passé.'),
  (478, 'Complète au plus-que-parfait : « Nous ___ déjà. »',
    '["sommes sortis","serons sortis","avions sortis","étions sortis"]', 4,
    'Application de la même règle : formes verbales complètes dans les propositions.'),
  (504, 'Dans « je jouais », quelle est la terminaison du verbe ?',
    '["-ais","-ait","-ions","-iez"]', 1,
    'La question porte clairement sur la terminaison complète « -ais ».'),
  (506, 'Quelle forme complète correctement « vous ___ » au présent ?',
    '["chantons","chantez","chantent","chantes"]', 2,
    'Distracteurs rendus plausibles avec des terminaisons réellement rencontrées.'),
  (507, 'Quelle forme complète correctement « ils ___ » au présent ?',
    '["finissons","finissez","finissent","finis"]', 3,
    'Distracteurs rendus plausibles avec des terminaisons réellement rencontrées.'),
  (509, 'Dans « nous mangeons », pourquoi conserve-t-on le e ?',
    '["pour garder le son doux de g","pour marquer le pluriel","pour marquer le futur","parce que le verbe est irrégulier"]', 1,
    'Correction de la forme citée : le e est bien présent dans « mangeons ».'),
  (510, 'Dans « nous lançons », pourquoi écrit-on « ç » ?',
    '["pour marquer le passé","pour conserver le son [s]","pour marquer la personne","pour former un nom"]', 2,
    'Reformulation pour faire correspondre exactement l’énoncé et le mot étudié.'),
  (522, null,
    '["dévelopement","développement","développemment","développpement"]', 2,
    'Remplacement du dernier distracteur.'),
  (524, null,
    '["aujourdhui","aujourd-hui","aujourd’ui","aujourd’hui"]', 4,
    'Remplacement du troisième distracteur conformément au retour.'),
  (525, null,
    '["longtemps","longtemp","lontemps","long-temps"]', 1,
    'Remplacement du troisième distracteur conformément au retour.'),
  (526, null,
    '["maleureusement","malheureusement","malheuresement","malhereusement"]', 2,
    'Remplacement du dernier distracteur conformément au retour.'),
  (527, null,
    '["diférent","differrent","différent","différentt"]', 3,
    '« différend », qui est un mot correct, est remplacé par une graphie fautive.'),
  (529, null,
    '["immédiatement","imédiatement","immédiatemment","immèdiatement"]', 1,
    'Remplacement du troisième distracteur conformément au retour.'),
  (535, null,
    '["ancienne","anciene","encienne","anciennes"]', 1,
    'Remplacement du troisième distracteur conformément au retour.'),
  (542, null,
    '["rapide-","-ment","-ement","ra-"]', 2,
    'Remplacement du troisième distracteur conformément au retour.'),
  (581, null,
    '["port","porc","pore","por"]', 1,
    'Le distracteur non homophone est remplacé par une graphie homophone.'),
  (582, null,
    '["port","porc","pore","porre"]', 2,
    'Le distracteur non homophone est remplacé par une graphie homophone.'),
  (589, null,
    '["mer","mère","maire","mèr"]', 1,
    '« mare », possible dans le contexte et non homophone, est remplacé.')
on conflict (legacy_id) do update
set prompt = excluded.prompt,
    choices = excluded.choices,
    correct_index = excluded.correct_index,
    change_comment = excluded.change_comment;

with source as (
  select
    p.*,
    q.id as question_id,
    q.current_version_number,
    qv.prompt as previous_prompt,
    coalesce(q.created_by, vc.owner_id) as author_id,
    md5('cap-college:review-correction:2026-07-24:' || p.legacy_id)::uuid as version_id
  from public._cap_college_correction_payload p
  join public.questions q on q.legacy_id = p.legacy_id
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  cross join public.validation_campaigns vc
  where vc.id = md5('cap-college:validation-campaign:2026-07-23')::uuid
), inserted_versions as (
  insert into public.question_versions (
    id, question_id, version_number, prompt, correction_explanation,
    change_comment, review_status, authored_by
  )
  select
    s.version_id,
    s.question_id,
    s.current_version_number + 1,
    coalesce(s.prompt, s.previous_prompt),
    previous.correction_explanation,
    s.change_comment,
    'corrected_to_retest'::public.review_status,
    s.author_id
  from source s
  join public.question_versions previous
    on previous.question_id = s.question_id
   and previous.version_number = s.current_version_number
  on conflict (id) do nothing
  returning id
)
insert into public.answer_choices (
  id, question_version_id, choice_key, content, is_correct, sort_order
)
select
  md5('cap-college:review-correction-choice:2026-07-24:' ||
      p.legacy_id || ':' || choice.ordinality)::uuid,
  md5('cap-college:review-correction:2026-07-24:' || p.legacy_id)::uuid,
  chr(64 + choice.ordinality::integer),
  choice.content,
  choice.ordinality = p.correct_index,
  choice.ordinality
from public._cap_college_correction_payload p
cross join lateral jsonb_array_elements_text(p.choices)
  with ordinality as choice(content, ordinality)
join public.question_versions qv
  on qv.id = md5('cap-college:review-correction:2026-07-24:' || p.legacy_id)::uuid
on conflict (id) do nothing;

update public.questions q
set current_version_number = qv.version_number,
    status = 'in_review',
    updated_at = statement_timestamp()
from public._cap_college_correction_payload p
join public.question_versions qv
  on qv.id = md5('cap-college:review-correction:2026-07-24:' || p.legacy_id)::uuid
where q.legacy_id = p.legacy_id;

update public.question_flags qf
set status = 'in_progress'
from public._cap_college_correction_payload p
join public.questions q on q.legacy_id = p.legacy_id
where qf.question_id = q.id
  and qf.status = 'open';

commit;
