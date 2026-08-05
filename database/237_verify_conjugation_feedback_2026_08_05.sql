with expected(legacy_id, choice_position, expected_content) as (
  values
    (172, 4::smallint, 'sont parti'::text),
    (176, 1::smallint, 'avons choisis'::text)
),
corrected as (
  select
    q.id,
    q.legacy_id,
    q.status,
    q.current_version_number,
    qv.id as version_id,
    qv.change_comment,
    expected.choice_position,
    expected.expected_content
  from expected
  join public.questions q on q.legacy_id = expected.legacy_id
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
),
choice_counts as (
  select
    corrected.legacy_id,
    count(choice.id) as choices,
    count(*) filter (where choice.is_correct) as correct_choices
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
  group by corrected.legacy_id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'change_comments_saved', (
    select count(*) from corrected where nullif(change_comment, '') is not null
  ),
  'requested_distractors_applied', (
    select count(*)
    from corrected
    join public.answer_choices choice
      on choice.question_version_id = corrected.version_id
     and choice.sort_order = corrected.choice_position
     and choice.content = corrected.expected_content
     and not choice.is_correct
  ),
  'previous_versions_preserved', (
    select count(*)
    from corrected
    where exists (
      select 1
      from public.question_versions previous
      where previous.question_id = corrected.id
        and previous.version_number < corrected.current_version_number
    )
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
  )
) as verification;
