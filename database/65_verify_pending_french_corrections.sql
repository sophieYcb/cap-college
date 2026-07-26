/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 65_verify_pending_french_corrections.sql
Objet   : Vérifier les corrections françaises en attente
-------------------------------------------------------
*/

with expected_versions(legacy_id, version_number) as (
  values
    (61,2),(62,2),(63,2),(64,2),(65,2),
    (66,2),(67,2),(68,2),(69,2),(70,2),
    (71,2),(72,2),(73,2),(74,2),(75,2),
    (76,2),(77,2),(78,2),(79,2),(80,2),
    (299,3),(325,3),(478,3),(504,3),(522,3),(527,3),
    (600058,3)
),
corrected as (
  select
    question.id,
    question.legacy_id,
    question.current_version_number,
    version.id as version_id
  from expected_versions expected
  join public.questions question
    on question.legacy_id = expected.legacy_id
  join public.question_versions version
    on version.question_id = question.id
   and version.version_number = expected.version_number
  where question.current_version_number = expected.version_number
),
choice_checks as (
  select
    corrected.legacy_id,
    count(choice.id) as choice_count,
    count(choice.id) filter (where choice.is_correct) as correct_count
  from corrected
  left join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
  group by corrected.legacy_id
),
type_series_answers as (
  select choice.sort_order
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
   and choice.is_correct
  where corrected.legacy_id between 61 and 80
)
select
  (select count(*) from corrected) as corrected_questions,
  (select count(*) from choice_checks where choice_count = 4)
    as questions_with_four_choices,
  (select count(*) from choice_checks where correct_count = 1)
    as questions_with_one_correct_choice,
  (select count(*) from type_series_answers where sort_order = 1)
    as type_series_answer_a,
  (select count(*) from type_series_answers where sort_order = 2)
    as type_series_answer_b,
  (select count(*) from type_series_answers where sort_order = 3)
    as type_series_answer_c,
  (select count(*) from type_series_answers where sort_order = 4)
    as type_series_answer_d,
  (
    select count(*)
    from public.question_versions version
    join public.questions question on question.id = version.question_id
    join expected_versions expected on expected.legacy_id = question.legacy_id
    where version.version_number = expected.version_number - 1
  ) as previous_versions_preserved;
