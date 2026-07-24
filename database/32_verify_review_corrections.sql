/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/32_verify_review_corrections.sql
 Purpose      : Read-only verification of the review correction batch.
===============================================================================
*/

select
  count(*) as corrected_questions,
  count(*) filter (
    where q.status = 'in_review'
      and qv.review_status = 'corrected_to_retest'
  ) as ready_to_retest,
  count(*) filter (
    where (
      select count(*)
      from public.answer_choices ac
      where ac.question_version_id = qv.id
    ) between 3 and 4
  ) as valid_choice_counts,
  count(*) filter (
    where (
      select count(*)
      from public.answer_choices ac
      where ac.question_version_id = qv.id
        and ac.is_correct
    ) = 1
  ) as exactly_one_correct_answer,
  count(*) filter (
    where exists (
      select 1
      from public.question_versions previous
      where previous.question_id = q.id
        and previous.version_number = qv.version_number - 1
    )
  ) as with_previous_version
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
where qv.id::text in (
  select md5('cap-college:review-correction:2026-07-24:' || n)::uuid::text
  from unnest(array[
    161,167,179,299,322,325,326,327,328,329,330,331,332,333,334,335,336,
    338,339,340,471,472,476,478,504,506,507,509,510,522,524,525,526,527,
    529,535,542,581,582,589
  ]::bigint[]) as n
);

