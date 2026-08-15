/*
 CAP-COLLEGE DATABASE
 File: database/319_publish_mathematics_5e_lot_07.sql
 Purpose: Publish Mathematics 5e lot M5-FRAC-01 after 40 grade-A validations.
 Idempotent: Yes.
*/

begin;

do $block$
declare
  question_count integer;
  approved_count integer;
begin
  select count(*) into question_count
  from public.questions
  where legacy_id between 5000201 and 5000240;

  if question_count <> 40 then
    raise exception
      'Publication annulée : 40 questions attendues, % trouvées.',
      question_count;
  end if;

  with current_versions as (
    select question_version.id
    from public.questions question
    join public.question_versions question_version
      on question_version.question_id = question.id
     and question_version.version_number = question.current_version_number
    where question.legacy_id between 5000201 and 5000240
  ),
  latest_reviews as (
    select distinct on (review.question_version_id)
      review.question_version_id,
      review.grade,
      review.status
    from public.question_reviews review
    join current_versions current_version
      on current_version.id = review.question_version_id
    where review.campaign_id is null
    order by
      review.question_version_id,
      review.reviewed_at desc,
      review.id desc
  )
  select count(*) into approved_count
  from latest_reviews
  where grade = 'A'
    and status = 'approved';

  if approved_count <> 40 then
    raise exception
      'Publication annulée : seulement % validations A sur 40.',
      approved_count;
  end if;
end;
$block$;

with current_versions as (
  select question_version.id
  from public.questions question
  join public.question_versions question_version
    on question_version.question_id = question.id
   and question_version.version_number = question.current_version_number
  where question.legacy_id between 5000201 and 5000240
)
update public.question_versions question_version
set review_status = 'approved'::public.review_status,
    published_at = coalesce(
      question_version.published_at,
      statement_timestamp()
    )
from current_versions current_version
where question_version.id = current_version.id;

update public.questions
set status = 'published'::public.question_status,
    active = true,
    updated_at = statement_timestamp()
where legacy_id between 5000201 and 5000240;

commit;
