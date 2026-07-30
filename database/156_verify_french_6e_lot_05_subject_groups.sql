/*
 CAP-COLLEGE DATABASE
 File: database/156_verify_french_6e_lot_05_subject_groups.sql
 Purpose: Verify the clarified French 6e lot 05 corrections.
 Read-only: Yes
*/

with expected(
  legacy_id,
  correct_position,
  correct_content,
  distractor_position,
  distractor_content
) as (
  values
    (1000136, 4, 'Les clés de la maison', 1, 'Les clés'),
    (1000139, 3, 'La grande horloge du salon', 4, 'horloge')
),
corrected as (
  select q.id, q.legacy_id, q.status, qv.id as version_id, e.*
  from expected e
  join public.questions q on q.legacy_id = e.legacy_id
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = 3
  where q.current_version_number = 3
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'versions_1_and_2_preserved', (
    select count(*)
    from corrected c
    where (
      select count(distinct qv.version_number)
      from public.question_versions qv
      where qv.question_id = c.id
        and qv.version_number in (1, 2)
    ) = 2
  ),
  'complete_subject_groups_restored', (
    select count(*)
    from corrected c
    where exists (
      select 1
      from public.answer_choices ac
      where ac.question_version_id = c.version_id
        and ac.sort_order = c.correct_position
        and ac.content = c.correct_content
        and ac.is_correct
    )
  ),
  'subject_nuclei_are_distractors', (
    select count(*)
    from corrected c
    where exists (
      select 1
      from public.answer_choices ac
      where ac.question_version_id = c.version_id
        and ac.sort_order = c.distractor_position
        and ac.content = c.distractor_content
        and not ac.is_correct
    )
  )
) as verification;
