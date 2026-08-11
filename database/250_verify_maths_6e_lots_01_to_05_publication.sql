/*
 CAP-COLLEGE DATABASE
 File: database/250_verify_maths_6e_lots_01_to_05_publication.sql
 Purpose: Verify publication of maths 6e lots 1 through 5.
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
where q.legacy_id between 600001 and 600200;
