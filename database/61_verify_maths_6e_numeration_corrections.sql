/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 61_verify_maths_6e_numeration_corrections.sql
Objet   : Vérifier les corrections et la répartition A/B/C/D
-------------------------------------------------------
*/

with maths_questions as (
  select
    q.id,
    q.current_version_number,
    qv.id as question_version_id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 600001 and 600080
),
correct_answers as (
  select
    mq.id,
    choice.sort_order
  from maths_questions mq
  join public.answer_choices choice
    on choice.question_version_id = mq.question_version_id
   and choice.is_correct
),
choice_checks as (
  select
    mq.id,
    count(choice.id) as choice_count,
    count(choice.id) filter (where choice.is_correct) as correct_count
  from maths_questions mq
  left join public.answer_choices choice
    on choice.question_version_id = mq.question_version_id
  group by mq.id
)
select
  (select count(*) from maths_questions) as questions,
  (select count(*) from maths_questions where current_version_number = 2)
    as corrected_versions,
  (select count(*) from correct_answers where sort_order = 1) as answer_a,
  (select count(*) from correct_answers where sort_order = 2) as answer_b,
  (select count(*) from correct_answers where sort_order = 3) as answer_c,
  (select count(*) from correct_answers where sort_order = 4) as answer_d,
  (select count(*) from choice_checks where choice_count = 4)
    as questions_with_four_choices,
  (select count(*) from choice_checks where correct_count = 1)
    as questions_with_one_correct_choice,
  (
    select count(*)
    from public.question_versions version
    join public.questions question on question.id = version.question_id
    where question.legacy_id between 600001 and 600080
      and version.version_number = 1
  ) as previous_versions_preserved;
