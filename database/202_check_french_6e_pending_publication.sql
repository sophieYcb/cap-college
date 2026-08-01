/*
 CAP-COLLEGE DATABASE
 File: database/202_check_french_6e_pending_publication.sql
 Purpose: Check whether the 60 original French 6e questions can be republished.
 Read-only: Yes
*/

with expected_micro_skills as (
  select ms.id
  from public.micro_skills ms
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  join public.micro_skill_levels msl on msl.micro_skill_id = ms.id
  join public.levels l on l.id = msl.level_id
  where s.code = 'french'
    and l.code = '6e'
    and msl.is_expected
    and ms.active
),
pending_questions as (
  select
    q.id,
    q.legacy_id,
    q.current_version_number
  from public.questions q
  join expected_micro_skills e on e.id = q.micro_skill_id
  where q.legacy_id between 1 and 590
    and q.status = 'in_review'
    and q.active
),
current_versions as (
  select
    q.id as question_id,
    q.legacy_id,
    q.current_version_number,
    qv.id as question_version_id,
    qv.review_status,
    qv.published_at
  from pending_questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
),
latest_reviews as (
  select distinct on (cv.question_version_id)
    cv.question_id,
    cv.legacy_id,
    cv.current_version_number,
    cv.question_version_id,
    cv.review_status,
    cv.published_at,
    qr.grade,
    qr.status as review_record_status,
    qr.reviewed_at
  from current_versions cv
  left join public.question_reviews qr
    on qr.question_version_id = cv.question_version_id
   and qr.campaign_id is null
  order by
    cv.question_version_id,
    qr.reviewed_at desc nulls last,
    qr.id desc nulls last
),
review_summary as (
  select
    coalesce(grade::text, 'none') as grade,
    coalesce(review_record_status::text, 'none') as review_status,
    count(*) as questions
  from latest_reviews
  group by grade, review_record_status
)
select jsonb_build_object(
  'pending_questions', (select count(*) from pending_questions),
  'ready_to_publish', (
    select count(*) from latest_reviews
    where grade = 'A' and review_record_status = 'approved'
  ),
  'not_ready_to_publish', (
    select count(*) from latest_reviews
    where grade is distinct from 'A'
       or review_record_status is distinct from 'approved'
  ),
  'review_summary', (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'grade', grade,
          'status', review_status,
          'questions', questions
        )
        order by grade, review_status
      ),
      '[]'::jsonb
    )
    from review_summary
  ),
  'not_ready_legacy_ids', (
    select coalesce(jsonb_agg(legacy_id order by legacy_id), '[]'::jsonb)
    from latest_reviews
    where grade is distinct from 'A'
       or review_record_status is distinct from 'approved'
  ),
  'already_published_current_versions', (
    select count(*) from latest_reviews where published_at is not null
  )
) as verification;