/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/125_publish_maths_6e_lots_14_to_20.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Publish maths 6e lots 14 to 20 after grade-A validation.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  expected_question_count constant integer := 200;
  lot_question_count integer;
  approved_question_count integer;
begin
  select count(*)
  into lot_question_count
  from public.questions
  where legacy_id between 600501 and 600700;

  if lot_question_count <> expected_question_count then
    raise exception
      'Publication cancelled: expected % questions, found %.',
      expected_question_count,
      lot_question_count;
  end if;

  with current_versions as (
    select qv.id as question_version_id
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number
    where q.legacy_id between 600501 and 600700
  ),
  latest_reviews as (
    select distinct on (qr.question_version_id)
      qr.question_version_id,
      qr.grade,
      qr.status
    from public.question_reviews qr
    join current_versions cv
      on cv.question_version_id = qr.question_version_id
    where qr.campaign_id is null
    order by qr.question_version_id, qr.reviewed_at desc, qr.id desc
  )
  select count(*)
  into approved_question_count
  from latest_reviews
  where grade = 'A'
    and status = 'approved';

  if approved_question_count <> expected_question_count then
    raise exception
      'Publication cancelled: only % of % current versions have a latest grade-A approval.',
      approved_question_count,
      expected_question_count;
  end if;
end;
$block$;

with current_versions as (
  select qv.id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 600501 and 600700
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
where legacy_id between 600501 and 600700;

commit;
