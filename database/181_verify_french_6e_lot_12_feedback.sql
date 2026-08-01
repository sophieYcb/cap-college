/*
 CAP-COLLEGE DATABASE
 File: database/181_verify_french_6e_lot_12_feedback.sql
 Purpose: Verify validator-feedback corrections for French 6e lot F6-CON-12.
 Read-only: Yes
*/

with expected(legacy_id, correct_position) as (
  values
    (1000371,3),(1000373,1),(1000374,2),(1000377,1),
    (1000379,3),(1000380,4),(1000381,1),(1000382,2),
    (1000383,3),(1000384,4),(1000385,1),(1000386,2),
    (1000387,3),(1000388,4)
),
corrected as (
  select
    q.id,
    q.legacy_id,
    q.status,
    qv.id as version_id,
    qv.change_comment,
    e.correct_position
  from expected e
  join public.questions q on q.legacy_id = e.legacy_id
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = 2
  where q.current_version_number = 2
),
choice_counts as (
  select
    c.legacy_id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.sort_order) filter (where ac.is_correct) as correct_position
  from corrected c
  join public.answer_choices ac on ac.question_version_id = c.version_id
  group by c.legacy_id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'change_comments_saved', (
    select count(*) from corrected where nullif(change_comment, '') is not null
  ),
  'previous_versions_preserved', (
    select count(*) from corrected c
    where exists (
      select 1 from public.question_versions qv
      where qv.question_id = c.id and qv.version_number = 1
    )
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
  ),
  'requested_answers_applied', (
    select count(*)
    from choice_counts cc
    join corrected c using (legacy_id)
    where cc.correct_position = c.correct_position
  )
) as verification;
