/*
 CAP-COLLEGE DATABASE
 File: database/203_publish_french_6e_pending_originals.sql
 Purpose: Publish the 60 validated original French 6e questions.
 Idempotent: Yes
*/

begin;

do $block$
declare
  pending_count integer;
  approved_count integer;
begin
  select count(*) into pending_count
  from public.questions q
  where q.legacy_id between 1 and 590
    and q.status = 'in_review'
    and q.active;

  if pending_count <> 60 then
    raise exception
      'Publication cancelled: 60 pending questions expected, % found.',
      pending_count;
  end if;

  with current_versions as (
    select qv.id
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number
    where q.legacy_id between 1 and 590
      and q.status = 'in_review'
      and q.active
  ),
  latest_reviews as (
    select distinct on (qr.question_version_id)
      qr.question_version_id,
      qr.grade,
      qr.status
    from public.question_reviews qr
    join current_versions cv on cv.id = qr.question_version_id
    where qr.campaign_id is null
    order by qr.question_version_id, qr.reviewed_at desc, qr.id desc
  )
  select count(*) into approved_count
  from latest_reviews
  where grade = 'A' and status = 'approved';

  if approved_count <> pending_count then
    raise exception
      'Publication cancelled: only % grade-A approvals for % questions.',
      approved_count,
      pending_count;
  end if;
end;
$block$;

with current_versions as (
  select qv.id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 1 and 590
    and q.status = 'in_review'
    and q.active
)
update public.question_versions qv
set review_status = 'approved'::public.review_status,
    published_at = coalesce(qv.published_at, statement_timestamp())
from current_versions cv
where qv.id = cv.id;

update public.questions
set status = 'published'::public.question_status,
    active = true,
    updated_at = statement_timestamp()
where legacy_id between 1 and 590
  and status = 'in_review'
  and active;

commit;