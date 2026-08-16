with corrected as(
  select
    q.legacy_id,q.status,q.current_version_number,
    v.prompt,v.correction_explanation,v.change_comment,
    count(a.id) choices,
    count(distinct a.content) distinct_choices,
    count(*) filter(where a.is_correct) correct_choices,
    (select count(*) from public.question_versions previous where previous.question_id=q.id) versions
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  join public.answer_choices a on a.question_version_id=v.id
  where q.legacy_id in(5000619,5000630,5000631,5000632,5000635,5000636,5000637,5000638,5000640)
  group by q.id,q.legacy_id,q.status,q.current_version_number,
           v.prompt,v.correction_explanation,v.change_comment
)
select jsonb_build_object(
  'corrected_questions',count(*),
  'requested_feedback_questions',count(*) filter(where legacy_id in(5000619,5000630,5000631,5000640)),
  'audit_consistency_corrections',count(*) filter(where legacy_id in(5000632,5000635,5000636,5000637,5000638)),
  'questions_in_review',count(*) filter(where status='in_review'),
  'current_versions_are_2',count(*) filter(where current_version_number=2),
  'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
  'distinct_change_comments_saved',count(distinct change_comment),
  'previous_versions_preserved',count(*) filter(where versions>=2),
  'questions_with_four_choices',count(*) filter(where choices=4),
  'questions_with_four_distinct_choices',count(*) filter(where distinct_choices=4),
  'questions_with_one_correct_choice',count(*) filter(where correct_choices=1),
  'obsolete_segment_median_notation_removed',count(*) filter(where prompt not like '%[AM] est une médiane%' and prompt not like '%représente [AM]%' and prompt not ilike '%ces segments%n’est%une médiane%'),
  'angle_notation_corrected',count(*) filter(where legacy_id=5000640 and prompt like '%(AM)%' and exists(
    select 1
    from public.answer_choices answer_choice
    join public.question_versions current_version on current_version.id=answer_choice.question_version_id
    join public.questions question on question.id=current_version.question_id
    where question.legacy_id=5000640
      and current_version.version_number=question.current_version_number
      and answer_choice.content like '%BÂM%MÂC%'
  ))
) verification
from corrected;