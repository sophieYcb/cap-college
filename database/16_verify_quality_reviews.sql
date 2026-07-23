/*
===============================================================================
 CAP-COLLEGE DATABASE — QUALITY REVIEW VERIFICATION
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 16_verify_quality_reviews.sql
 Purpose      : Read-only verification of the 590-question review campaign.
===============================================================================
*/

select
  count(*) as reviews,
  count(*) filter (where qr.grade = 'A') as grade_a,
  count(*) filter (where qr.grade = 'B') as grade_b,
  count(*) filter (where qr.grade = 'C') as grade_c,
  count(*) filter (where qr.grade = 'D') as grade_d,
  count(*) filter (where qr.grade is null) as without_grade,
  count(*) filter (where qr.comment is not null) as comments,
  (
    select count(*)
    from public.question_flags qf
    where qf.campaign_id = vc.id
      and qf.status = 'open'
  ) as open_flags,
  (
    select count(*)
    from public.questions q
    where q.legacy_id between 1 and 590
      and q.status = 'published'
  ) as published_questions,
  (
    select count(*)
    from public.questions q
    where q.legacy_id between 1 and 590
      and q.status = 'in_review'
  ) as questions_in_review
from public.validation_campaigns vc
join public.question_reviews qr on qr.campaign_id = vc.id
where vc.id = md5('cap-college:validation-campaign:2026-07-23')::uuid
group by vc.id;
