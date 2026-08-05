with target_questions as (
  select
    q.id,
    q.legacy_id,
    q.status,
    q.current_version_number,
    qv.id as version_id,
    qv.prompt
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 101 and 180
),
choice_counts as (
  select
    target.id,
    count(choice.id) as choices,
    count(*) filter (where choice.is_correct) as correct_choices
  from target_questions target
  join public.answer_choices choice
    on choice.question_version_id = target.version_id
  group by target.id
)
select jsonb_build_object(
  'questions', (select count(*) from target_questions),
  'present_prompts', (
    select count(*) from target_questions
    where legacy_id between 101 and 120
      and prompt like '% au présent de l''indicatif.'
  ),
  'imperfect_prompts', (
    select count(*) from target_questions
    where legacy_id between 121 and 140
      and prompt like '% à l''imparfait de l''indicatif.'
  ),
  'future_prompts', (
    select count(*) from target_questions
    where legacy_id between 141 and 160
      and prompt like '% au futur simple de l''indicatif.'
  ),
  'past_compound_prompts', (
    select count(*) from target_questions
    where legacy_id between 161 and 180
      and prompt like '%passé composé%'
  ),
  'questions_in_review', (
    select count(*) from target_questions
    where status = 'in_review'
  ),
  'question_108_published', (
    select status = 'published'
    from target_questions where legacy_id = 108
  ),
  'previous_versions_preserved', (
    select count(*)
    from target_questions target
    where exists (
      select 1
      from public.question_versions previous
      where previous.question_id = target.id
        and previous.version_number < target.current_version_number
    )
  ),
  'questions_with_four_choices', (
    select count(*) from choice_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_counts where correct_choices = 1
  )
) as verification;
