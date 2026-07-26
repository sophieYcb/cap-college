/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 59_count_maths_6e_correct_answers.sql
Objet   : Répartir les bonnes réponses A/B/C/D des 80 questions de maths 6e
-------------------------------------------------------
*/

with correct_answers as (
  select
    q.legacy_id,
    ac.sort_order
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  join public.answer_choices ac
    on ac.question_version_id = qv.id
   and ac.is_correct
  where q.legacy_id between 600001 and 600080
)
select
  count(*) as total_correct_answers,
  count(*) filter (where sort_order = 1) as answer_a,
  count(*) filter (where sort_order = 2) as answer_b,
  count(*) filter (where sort_order = 3) as answer_c,
  count(*) filter (where sort_order = 4) as answer_d
from correct_answers;
