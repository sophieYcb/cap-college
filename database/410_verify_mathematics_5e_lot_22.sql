with lot_questions as (
  select q.id,q.status,q.current_version_number,v.id version_id
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  where q.legacy_id between 5000681 and 5000720
), choice_counts as (
  select l.id,l.status,l.current_version_number,l.version_id,
         count(a.id) choices,
         count(*) filter(where a.is_correct) correct_choices,
         min(a.sort_order) filter(where a.is_correct) correct_position
  from lot_questions l
  left join public.answer_choices a on a.question_version_id=l.version_id
  group by l.id,l.status,l.current_version_number,l.version_id
)
select jsonb_build_object(
  'questions',count(*),
  'versions',count(distinct version_id),
  'choices',sum(choices),
  'correct_choices',sum(correct_choices),
  'micro_skills',(
    select count(distinct q.micro_skill_id)
    from public.questions q
    where q.legacy_id between 5000681 and 5000720
  ),
  'current_versions',count(*) filter(where current_version_number=1),
  'statuses',jsonb_agg(distinct status),
  'questions_with_four_choices',count(*) filter(where choices=4),
  'questions_with_one_correct_choice',count(*) filter(where correct_choices=1),
  'answer_a',count(*) filter(where correct_position=1),
  'answer_b',count(*) filter(where correct_position=2),
  'answer_c',count(*) filter(where correct_position=3),
  'answer_d',count(*) filter(where correct_position=4)
) verification
from choice_counts;
