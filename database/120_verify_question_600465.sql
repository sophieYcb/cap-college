with selected as (
  select q.id, q.status, q.current_version_number, qv.id as version_id, qv.prompt
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = 3
  where q.legacy_id = 600465
),
answers as (
  select
    s.id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.content) filter (where ac.is_correct) as correct_answer
  from selected s
  left join public.answer_choices ac on ac.question_version_id = s.version_id
  group by s.id
)
select jsonb_build_object(
  'question_found', exists(select 1 from selected),
  'current_version_3', (select count(*) from selected where current_version_number = 3),
  'question_in_review', (select count(*) from selected where status = 'in_review'),
  'four_choices', (select count(*) from answers where choices = 4),
  'one_correct_choice', (select count(*) from answers where correct_choices = 1),
  'explicit_multiplication', (select count(*) from answers where correct_answer = 'π × 12 cm'),
  'previous_versions_preserved', (
    select count(*) from selected s
    where exists (
      select 1 from public.question_versions old
      where old.question_id = s.id and old.version_number in (1,2)
      group by old.question_id
      having count(distinct old.version_number) = 2
    )
  )
) as verification;
