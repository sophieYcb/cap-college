/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/151_verify_french_6e_lot_04_publication.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify publication of French 6e lot F6-GRA-04.
 Read-only    : Yes
===============================================================================
*/

with lot_questions as (
  select id, current_version_number, status, active
  from public.questions
  where legacy_id between 1000081 and 1000120
),
current_versions as (
  select qv.id, qv.question_id, qv.review_status, qv.published_at
  from public.question_versions qv
  join lot_questions q
    on q.id = qv.question_id
   and q.current_version_number = qv.version_number
),
latest_reviews as (
  select distinct on (qr.question_version_id)
    qr.question_version_id,
    qr.grade,
    qr.status
  from public.question_reviews qr
  join current_versions cv
    on cv.id = qr.question_version_id
  where qr.campaign_id is null
  order by qr.question_version_id, qr.reviewed_at desc, qr.id desc
)
select jsonb_build_object(
  'questions', (select count(*) from lot_questions),
  'published_questions', (
    select count(*) from lot_questions
    where status = 'published' and active
  ),
  'published_current_versions', (
    select count(*) from current_versions
    where review_status = 'approved' and published_at is not null
  ),
  'latest_grade_a_reviews', (
    select count(*) from latest_reviews
    where grade = 'A' and status = 'approved'
  ),
  'version_1_questions', (
    select count(*) from lot_questions where current_version_number = 1
  )
) as verification;

