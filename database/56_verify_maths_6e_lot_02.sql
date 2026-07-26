/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 56_verify_maths_6e_lot_02.sql
Objet   : Vérifier le deuxième lot de mathématiques 6e
-------------------------------------------------------
*/

with lot_questions as (
    select *
    from public.questions
    where legacy_id between 600041 and 600080
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
),
question_choice_checks as (
    select
        q.id,
        count(ac.id) as choice_count,
        count(ac.id) filter (where ac.is_correct) as correct_choice_count
    from lot_questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number
    left join public.answer_choices ac
      on ac.question_version_id = qv.id
    group by q.id
)
select
    (select count(*) from lot_questions) as questions,
    (select count(*) from lot_versions) as versions,
    (select count(*) from lot_choices) as choices,
    (select count(*) from lot_choices where is_correct) as correct_choices,
    (select count(distinct micro_skill_id) from lot_questions) as micro_skills,
    (select count(*) from lot_questions where current_version_number = 1)
        as current_versions,
    (select count(*) from question_choice_checks where choice_count = 4)
        as questions_with_four_choices,
    (select count(*) from question_choice_checks where correct_choice_count = 1)
        as questions_with_one_correct_choice,
    (select array_agg(distinct status) from lot_questions) as statuses;
