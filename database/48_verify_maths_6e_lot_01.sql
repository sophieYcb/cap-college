/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 48_verify_maths_6e_lot_01.sql
Objet   : Vérifier le premier lot de mathématiques 6e
-------------------------------------------------------
*/

with lot_questions as (
    select *
    from public.questions
    where legacy_id between 600001 and 600040
),
lot_versions as (
    select qv.*
    from public.question_versions qv
    join lot_questions q
      on q.id = qv.question_id
),
lot_choices as (
    select ac.*
    from public.answer_choices ac
    join lot_versions qv
      on qv.id = ac.question_version_id
)
select
    (select count(*) from lot_questions) as questions,
    (select count(*) from lot_versions) as versions,
    (select count(*) from lot_choices) as choices,
    (select count(*) from lot_choices where is_correct) as correct_choices,
    (select count(distinct micro_skill_id) from lot_questions) as micro_skills,
    (select count(*) from lot_questions where current_version_number = 1)
        as current_versions,
    (select array_agg(distinct status) from lot_questions) as statuses;
