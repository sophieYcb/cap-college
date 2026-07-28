with corrected as (
  select q.id, q.legacy_id, q.status, q.current_version_number, qv.id as version_id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = 2
  where q.legacy_id = any(array[600465,600549,600553,600557,600561,600562,600563,600564,600565,600566,600567,600568,600569,600570,600571,600572,600573,600574,600575,600576,600577,600578,600579,600580,600591,600592,600593,600594,600595,600596,600597,600598,600599,600600,600611,600612,600613,600614,600615,600616,600617,600618,600619,600620,600621,600622,600623,600624,600625,600626,600627,600628,600629,600630,600634,600637,600638,600639,600640,600641,600642,600643,600644,600645,600646,600647,600648,600649,600650,600651,600652,600653,600654,600655,600656,600657,600658,600659,600660,600661,600662,600663,600664,600665,600666,600667,600668,600669,600670,600671,600672,600673,600674,600675,600676,600677,600678,600679,600680,600681,600682,600683,600684,600685,600686,600687,600688,600689,600690])
),
counts as (
  select
    c.id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices
  from corrected c
  left join public.answer_choices ac on ac.question_version_id = c.version_id
  group by c.id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review', (select count(*) from corrected where status = 'in_review'),
  'questions_with_four_choices', (select count(*) from counts where choices = 4),
  'questions_with_one_correct_choice', (select count(*) from counts where correct_choices = 1),
  'previous_versions_preserved', (
    select count(*) from corrected c
    where exists (
      select 1 from public.question_versions old
      where old.question_id = c.id and old.version_number = 1
    )
  ),
  'visual_questions', (
    select count(*) from corrected c
    join public.question_versions qv on qv.id = c.version_id
    where qv.prompt like '%' || chr(10) || '%'
  )
) as verification;
