with expected(legacy_id, version_number, prompt, correct_position) as (
  values
    (
      600241::bigint,
      2,
      'Quelle division correspond à la fraction 3/4 ?'::text,
      1
    ),
    (
      600259::bigint,
      2,
      'Quelle égalité est correcte ?'::text,
      3
    )
),
corrected as (
  select
    e.*,
    q.id as question_id,
    q.status,
    q.current_version_number,
    qv.id as question_version_id,
    qv.prompt as actual_prompt
  from expected e
  left join public.questions q
    on q.legacy_id = e.legacy_id
  left join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = e.version_number
),
choice_counts as (
  select
    c.question_id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.sort_order) filter (where ac.is_correct) as correct_position
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
      and actual_prompt = prompt
  ),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
  ),
  'correct_positions_preserved', (
    select count(*)
    from corrected c
    join choice_counts cc on cc.question_id = c.question_id
    where cc.correct_position = c.correct_position
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
