/*
 CAP-COLLEGE DATABASE
 File: database/204_verify_french_6e_pending_originals_publication.sql
 Purpose: Verify publication of all original French 6e questions.
 Read-only: Yes
*/

select
  count(*) as original_questions,
  count(*) filter (
    where q.status = 'published' and q.active
  ) as published_original_questions,
  count(*) filter (
    where qv.review_status = 'approved'
      and qv.published_at is not null
  ) as published_current_versions
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
where q.legacy_id between 1 and 590;