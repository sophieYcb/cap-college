/*
 CAP-COLLEGE DATABASE
 File: database/244_check_maths_6e_lot_20_publication_readiness.sql
 Purpose: Check publication readiness of maths 6e lot 20.
 Read-only: Yes
*/

with current_versions as (
  select
    q.id,
    q.legacy_id,
    q.status as question_status,
    q.active,
    q.current_version_number,
    qv.id as question_version_id,
    qv.review_status as version_review_status,
    qv.published_at
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 600681 and 600710
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
),
readiness as (
  select
    cv.*,
    lr.grade,
    lr.status as latest_review_status,
    (
      (lr.grade = 'A' and lr.status = 'approved')
      or (
        cv.question_status = 'published'
        and cv.active
        and cv.version_review_status = 'approved'
        and cv.published_at is not null
      )
    ) as ready
  from current_versions cv
  left join latest_reviews lr
    on lr.question_version_id = cv.question_version_id
)
select jsonb_build_object(
  'questions', count(*),
  'published_questions', count(*) filter (
    where question_status = 'published' and active
  ),
  'questions_in_review', count(*) filter (
    where question_status = 'in_review'
  ),
  'latest_grade_a_reviews', count(*) filter (
    where grade = 'A' and latest_review_status = 'approved'
  ),
  'ready_to_publish', count(*) filter (where ready),
  'not_ready_legacy_ids', coalesce(
    jsonb_agg(legacy_id order by legacy_id) filter (where not ready),
    '[]'::jsonb
  )
) as verification
from readiness;
