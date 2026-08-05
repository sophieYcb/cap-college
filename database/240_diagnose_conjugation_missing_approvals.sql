/*
 CAP-COLLEGE DATABASE
 File: database/240_diagnose_conjugation_missing_approvals.sql
 Purpose: List current conjugation versions without a latest grade-A approval.
 Read-only: Yes
*/

with current_versions as (
  select
    q.legacy_id,
    q.status as question_status,
    q.current_version_number,
    qv.id as question_version_id,
    qv.prompt
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 101 and 180
),
latest_reviews as (
  select distinct on (qr.question_version_id)
    qr.question_version_id,
    qr.grade,
    qr.status as review_status,
    qr.reviewed_at
  from public.question_reviews qr
  join current_versions cv
    on cv.question_version_id = qr.question_version_id
  where qr.campaign_id is null
  order by qr.question_version_id, qr.reviewed_at desc, qr.id desc
)
select
  cv.legacy_id,
  cv.current_version_number,
  cv.question_status,
  lr.grade,
  lr.review_status,
  lr.reviewed_at,
  cv.prompt
from current_versions cv
left join latest_reviews lr
  on lr.question_version_id = cv.question_version_id
where lr.grade is distinct from 'A'
   or lr.review_status is distinct from 'approved'
order by cv.legacy_id;
