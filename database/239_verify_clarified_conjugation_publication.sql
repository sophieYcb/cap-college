/*
 CAP-COLLEGE DATABASE
 File: database/239_verify_clarified_conjugation_publication.sql
 Purpose: Verify publication of clarified conjugation questions 101 through 180.
 Read-only: Yes
*/

select
  count(*) as questions,
  count(*) filter (
    where q.status = 'published' and q.active
  ) as published_questions,
  count(*) filter (
    where qv.review_status = 'approved'
      and qv.published_at is not null
  ) as published_current_versions
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
where q.legacy_id between 101 and 180;
