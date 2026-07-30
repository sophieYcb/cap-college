/*
 CAP-COLLEGE DATABASE
 File: database/169_verify_french_6e_lot_08_publication.sql
 Purpose: Verify publication of French 6e lot F6-GRA-08.
 Read-only: Yes
*/

select
  count(*) as questions,
  count(*) filter (
    where q.status = 'published' and q.active
  ) as published_questions,
  count(*) filter (
    where exists (
      select 1
      from public.question_versions qv
      where qv.question_id = q.id
        and qv.version_number = q.current_version_number
        and qv.review_status = 'approved'
        and qv.published_at is not null
    )
  ) as published_current_versions
from public.questions q
where q.legacy_id between 1000231 and 1000270;
