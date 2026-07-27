with corrected as (
  select
    q.id as question_id,
    q.status,
    q.current_version_number,
    qv.id as question_version_id,
    qv.prompt,
    qv.change_comment
  from public.questions q
  left join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = 2
  where q.legacy_id = 600382
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
      and current_version_number = 2
  ),
  'questions_in_review', (
    select count(*) from corrected where status = 'in_review'
  ),
  'wording_preserved', (
    select count(*) from corrected
    where prompt = 'Quelle fraction sur 100 correspond à 40 % ?'
  ),
  'choices_corrected', (
    select count(*) from choice_data
    where actual_choices = '["4/100","40/100","60/100","100/100"]'::jsonb
  ),
  'correct_answer_b', (
    select count(*) from choice_data where correct_position = 2
  ),
  'questions_with_four_choices', (
    select count(*) from choice_data where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from choice_data where correct_choices = 1
  ),
  'previous_version_preserved', (
    select count(*)
    from corrected c
    where exists (
      select 1
      from public.question_versions previous_version
      where previous_version.question_id = c.question_id
        and previous_version.version_number = 1
    )
  ),
  'change_comment_saved', (
    select count(*) from corrected
    where nullif(btrim(change_comment), '') is not null
  )
) as verification;
