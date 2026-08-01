/*
 CAP-COLLEGE DATABASE
 File: database/213_publish_question_108_present_tense.sql
 Purpose: Publish the validated correction of French question 108.
 Idempotent: Yes
*/

begin;

do $block$
declare
  approved_count integer;
begin
  with current_version as (
    select qv.id
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number
    where q.legacy_id = 108
      and q.status = 'in_review'
  ),
  latest_review as (
    select distinct on (qr.question_version_id)
      qr.question_version_id,
      qr.grade,
      qr.status
    from public.question_reviews qr
    join current_version cv on cv.id = qr.question_version_id
    where qr.campaign_id is null
    order by qr.question_version_id, qr.reviewed_at desc, qr.id desc
  )
  select count(*) into approved_count
  from latest_review
  where grade = 'A' and status = 'approved';

  if approved_count <> 1 then
    raise exception
      'Publication cancelled: question 108 needs one grade-A approval.';
  end if;
end;
$block$;

with current_version as (
  select qv.id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id = 108
)
update public.question_versions qv
set review_status = 'approved'::public.review_status,
    published_at = coalesce(qv.published_at, statement_timestamp())
from current_version cv
where qv.id = cv.id;

update public.questions
set status = 'published'::public.question_status,
    active = true,
    updated_at = statement_timestamp()
where legacy_id = 108;

commit;