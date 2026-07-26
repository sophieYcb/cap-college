/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 48_verify_maths_6e_lot_01.sql
Objet   : Vérifier le premier lot de mathématiques 6e
-------------------------------------------------------
*/

with lot_questions as (
    select q.id, q.status, q.active, q.current_question_version_id
    from public.questions q
    where q.legacy_id between 600001 and 600040
),
lot_versions as (
    select qv.id, qv.question_id
    from public.question_versions qv
    join lot_questions q on q.id = qv.question_id
),
choice_counts as (
    select
        qv.question_id,
        count(qc.id) as choice_count,
        count(qc.id) filter (where qc.is_correct) as correct_choice_count
    from lot_versions qv
    left join public.question_choices qc
        on qc.question_version_id = qv.id
    group by qv.question_id
)
select jsonb_build_object(
    'mathematics_subject_ready',
        exists (select 1 from public.subjects where code = 'mathematics'),
    'numeration_skill_ready',
        exists (select 1 from public.skills where code = 'numeration'),
    'micro_skills', (
        select count(*)
        from public.micro_skills
        where code in (
            'm6_num_rang_entier',
            'm6_num_rang_decimal',
            'm6_num_unites',
            'm6_num_sous_unites'
        )
    ),
    'questions', (select count(*) from lot_questions),
    'versions', (select count(*) from lot_versions),
    'choices', (select coalesce(sum(choice_count), 0) from choice_counts),
    'questions_with_four_choices', (
        select count(*) from choice_counts where choice_count = 4
    ),
    'questions_with_one_correct_choice', (
        select count(*) from choice_counts where correct_choice_count = 1
    ),
    'questions_in_review', (
        select count(*) from lot_questions where status = 'in_review'
    ),
    'published_questions', (
        select count(*) from lot_questions where status = 'published'
    ),
    'current_versions_linked', (
        select count(*)
        from lot_questions
        where current_question_version_id is not null
    )
) as verification;
