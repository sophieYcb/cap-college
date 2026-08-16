with corrected as (
  select
    q.legacy_id,
    q.status,
    q.current_version_number,
    v.prompt,
    v.correction_explanation,
    v.change_comment,
    count(a.id) choices,
    count(distinct a.content) distinct_choices,
    count(*) filter(where a.is_correct) correct_choices
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  join public.answer_choices a on a.question_version_id=v.id
  where q.legacy_id in(
    5000551,5000557,5000561,5000562,5000563,5000564,
    5000565,5000566,5000567,5000568,5000570
  )
  group by q.legacy_id,q.status,q.current_version_number,
           v.prompt,v.correction_explanation,v.change_comment
)
select jsonb_build_object(
  'corrected_questions',count(*),
  'questions_in_review',count(*) filter(where status='in_review'),
  'current_versions_are_3',count(*) filter(where current_version_number=3),
  'change_comments_saved',count(*) filter(where nullif(btrim(change_comment),'') is not null),
  'distinct_change_comments_saved',count(distinct change_comment),
  'questions_with_four_choices',count(*) filter(where choices=4),
  'questions_with_four_distinct_choices',count(*) filter(where distinct_choices=4),
  'questions_with_one_correct_choice',count(*) filter(where correct_choices=1),
  'plain_angle_letters_removed',count(*) filter(where prompt !~* 'angles? [a-h]( |[,.?])'),
  'hyphenated_alternate_internal_removed',count(*) filter(where prompt not ilike '%alterne-interne%'),
  'corresponding_definition_added',count(*) filter(where legacy_id=5000570 and prompt ilike '%même position%'),
  'corresponding_pair_wording_clarified',count(*) filter(where legacy_id=5000562 and prompt ilike '%une paire d’angles correspondants%')
) verification
from corrected;