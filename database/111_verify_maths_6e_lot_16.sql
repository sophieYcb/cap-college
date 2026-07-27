with lot_questions as (
  select id, current_version_number, status, micro_skill_id
  from public.questions
  where legacy_id between 600551 and 600590
),
versions as (
  select qv.id, qv.question_id
  from public.question_versions qv
  join lot_questions q on q.id = qv.question_id
    and q.current_version_number = qv.version_number
),
counts as (
  select v.question_id, count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.sort_order) filter (where ac.is_correct) as correct_position
  from versions v
  join public.answer_choices ac on ac.question_version_id = v.id
  group by v.question_id
)
select jsonb_build_object(
  'questions', (select count(*) from lot_questions),
  'versions', (select count(*) from versions),
  'choices', (select coalesce(sum(choices), 0) from counts),
  'correct_choices', (select coalesce(sum(correct_choices), 0) from counts),
  'micro_skills', (select count(distinct micro_skill_id) from lot_questions),
  'current_versions', (select count(*) from lot_questions where current_version_number = 1),
  'questions_with_four_choices', (select count(*) from counts where choices = 4),
  'questions_with_one_correct_choice', (select count(*) from counts where correct_choices = 1),
  'statuses', (select array_agg(distinct status order by status) from lot_questions),
  'answer_a', (select count(*) from counts where correct_position = 1),
  'answer_b', (select count(*) from counts where correct_position = 2),
  'answer_c', (select count(*) from counts where correct_position = 3),
  'answer_d', (select count(*) from counts where correct_position = 4)
) as verification;
