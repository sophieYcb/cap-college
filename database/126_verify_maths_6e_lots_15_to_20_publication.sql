/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/126_verify_maths_6e_lots_15_to_20_publication.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Verify publication of maths 6e lots 15 to 20.
 Read-only    : Yes
===============================================================================
*/

with lot_questions as (
  select id, legacy_id, current_version_number, status, active
  from public.questions
  where legacy_id between 600541 and 600700
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
  'lots', jsonb_build_object(
    'lot_15', (select count(*) from lot_questions where legacy_id between 600541 and 600550 and status = 'published'),
    'lot_16', (select count(*) from lot_questions where legacy_id between 600551 and 600590 and status = 'published'),
    'lot_17', (select count(*) from lot_questions where legacy_id between 600591 and 600630 and status = 'published'),
    'lot_18', (select count(*) from lot_questions where legacy_id between 600631 and 600640 and status = 'published'),
    'lot_19', (select count(*) from lot_questions where legacy_id between 600641 and 600680 and status = 'published'),
    'lot_20', (select count(*) from lot_questions where legacy_id between 600681 and 600700 and status = 'published')
  )
) as verification;
