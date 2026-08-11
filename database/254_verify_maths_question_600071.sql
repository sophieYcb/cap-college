with corrected as (
  select
    q.id,
    q.status,
    q.current_version_number,
    qv.id as version_id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id = 600071
),
choice_counts as (
  select
    count(choice.id) as choices,
    count(*) filter (where choice.is_correct) as correct_choices
  from corrected
  join public.answer_choices choice
    on choice.question_version_id = corrected.version_id
)
select jsonb_build_object(
  'question_in_review', (select status = 'in_review' from corrected),
  'distractor_corrected', exists (
    select 1
    from corrected
    join public.answer_choices choice
      on choice.question_version_id = corrected.version_id
    where choice.sort_order = 3
      and choice.content = '60/1 000'
      and not choice.is_correct
  ),
  'correct_answer_is_six_tenths', exists (
    select 1
    from corrected
    join public.answer_choices choice
      on choice.question_version_id = corrected.version_id
    where choice.content = '6/10'
      and choice.is_correct
  ),
  'previous_version_preserved', exists (
    select 1
    from corrected
    join public.question_versions previous on previous.question_id = corrected.id
    where previous.version_number < corrected.current_version_number
  ),
  'question_has_four_choices', (select choices = 4 from choice_counts),
  'question_has_one_correct_choice', (select correct_choices = 1 from choice_counts)
) as verification;