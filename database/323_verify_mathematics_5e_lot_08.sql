/* Verify Mathematics 5e lot 08 after import. */
with lot_questions as (
 select q.id,q.status,q.current_version_number,m.code as micro_skill_code
 from public.questions q join public.micro_skills m on m.id=q.micro_skill_id
 where q.legacy_id between 5000241 and 5000260
), current_versions as (
 select v.id,v.question_id from public.question_versions v join lot_questions q on q.id=v.question_id and q.current_version_number=v.version_number
), choice_counts as (
 select v.question_id,count(a.id) choices,count(*) filter(where a.is_correct) correct_choices,max(a.sort_order) filter(where a.is_correct) correct_position
 from current_versions v join public.answer_choices a on a.question_version_id=v.id group by v.question_id
)
select jsonb_build_object(
 'questions',(select count(*) from lot_questions),'versions',(select count(*) from current_versions),
 'choices',(select coalesce(sum(choices),0) from choice_counts),'correct_choices',(select coalesce(sum(correct_choices),0) from choice_counts),
 'micro_skills',(select count(distinct micro_skill_code) from lot_questions),'current_versions',(select count(*) from lot_questions where current_version_number=1),
 'questions_with_four_choices',(select count(*) from choice_counts where choices=4),'questions_with_one_correct_choice',(select count(*) from choice_counts where correct_choices=1),
 'statuses',(select array_agg(distinct status order by status) from lot_questions),
 'answer_a',(select count(*) from choice_counts where correct_position=1),'answer_b',(select count(*) from choice_counts where correct_position=2),
 'answer_c',(select count(*) from choice_counts where correct_position=3),'answer_d',(select count(*) from choice_counts where correct_position=4)
) as verification;
