with selected as(
  select q.id,q.legacy_id,q.status,q.current_version_number,qv.id as version_id,qv.prompt
  from public.questions q
  join public.question_versions qv on qv.question_id=q.id and qv.version_number=4
  where q.legacy_id=any(array[600641,600642,600643,600644,600645,600646,600647,600648,600649,600650,600651,600652,600653,600654,600655,600656,600657,600658,600659,600660,600661,600662,600663,600664,600665,600666,600667,600668,600669,600670,600671,600672,600673,600674,600675,600676,600677,600678,600679,600680])
),counts as(
  select s.id,count(ac.id) choices,count(*) filter(where ac.is_correct) correct_choices
  from selected s left join public.answer_choices ac on ac.question_version_id=s.version_id
  group by s.id
)
select jsonb_build_object(
  'corrected_questions',(select count(*) from selected),
  'questions_in_review',(select count(*) from selected where status='in_review'),
  'version_4_questions',(select count(*) from selected where current_version_number=4),
  'questions_with_four_choices',(select count(*) from counts where choices=4),
  'questions_with_one_correct_choice',(select count(*) from counts where correct_choices=1),
  'previous_versions_preserved',(
    select count(*) from selected s where(
      select count(distinct old.version_number) from public.question_versions old
      where old.question_id=s.id and old.version_number in(1,2,3)
    )=3
  ),
  'circular_questions_without_written_percentage',(
    select count(*) from selected where legacy_id between 600661 and 600670
      and position('%' in prompt)=0
  ),
  'diversified_curve_questions',(
    select count(*) from selected where legacy_id between 600671 and 600680
      and prompt like '%[DONNÉES_COURBE]%'
  )
) verification;
