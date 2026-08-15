/*
 CAP-COLLEGE DATABASE
 File: database/341_verify_mathematics_5e_lot_12_publication.sql
 Purpose: Verify publication of Mathematics 5e lot M5-ALG-02.
 Read-only: Yes.
*/

select
  count(*) as questions,
  count(*) filter (
    where question.status = 'published'
      and question.active
  ) as published_questions,
  count(*) filter (
    where exists (
      select 1
      from public.question_versions question_version
      where question_version.question_id = question.id
        and question_version.version_number = question.current_version_number
        and question_version.review_status = 'approved'
        and question_version.published_at is not null
    )
  ) as published_current_versions
from public.questions question
where question.legacy_id between 5000351 and 5000390;
