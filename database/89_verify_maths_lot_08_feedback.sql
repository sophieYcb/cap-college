with expected(
  legacy_id,
  version_number,
  expected_choices,
  correct_position
) as (
  values
    (
      600283::bigint,
      2,
      '["6/8","6/12","9/15","12/15"]'::jsonb,
      3
    ),
    (
      600285::bigint,
      2,
      '["4","3","6","9"]'::jsonb,
      1
    ),
    (
      600286::bigint,
      2,
      '["10","15","20","21"]'::jsonb,
      2
    )
),
corrected as (
  select
    e.*,
    q.id as question_id,
    q.status,
    q.current_version_number,
    qv.id as question_version_id
  from expected e
  left join public.questions q
    on q.legacy_id = e.legacy_id
  left join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = e.version_number
),
choice_data as (
  select
    c.question_id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.sort_order) filter (where ac.is_correct) as correct_position,
    jsonb_agg(to_jsonb(ac.content) order by ac.sort_order)
      filter (where ac.id is not null) as actual_choices
  from corrected c
  left join public.answer_choices ac
    on ac.question_version_id = c.question_version_id
  group by c.question_id
)
select jsonb_build_object(
  'corrected_questions', (
    select count(*) from corrected
    where question_id is not null
      and current_version_number = version_number
  ),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'questions_with_expected_choices', (
    select count(*)
    from corrected c
    join choice_data cd on cd.question_id = c.question_id
    where cd.actual_choices = c.expected_choices
  ),
  'correct_positions_preserved', (
    select count(*)
    from corrected c
    join choice_data cd on cd.question_id = c.question_id
    where cd.correct_position = c.correct_position
  ),
  'questions_with_four_choices', (
    select count(*) from choice_data where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_data where correct_choices = 1
  ),
  'previous_versions_preserved', (
    select count(*)
    from corrected c
    where exists (
      select 1
      from public.question_versions previous_version
      where previous_version.question_id = c.question_id
        and previous_version.version_number = 1
    )
  )
) as verification;
