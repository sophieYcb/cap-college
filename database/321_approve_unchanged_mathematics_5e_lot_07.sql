/* Record the validator's confirmed approval of six unchanged questions. */
begin;
insert into public.question_reviews(question_version_id,reviewer_id,status,grade,comment)
select v.id,previous_review.reviewer_id,'approved'::public.review_status,'A',
       'Validation A confirmée après clarification : « réduire des fractions au même dénominateur » est une formulation mathématique correcte ; aucune modification de la question n’est nécessaire.'
from public.questions q
join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
join lateral (
  select r.reviewer_id from public.question_reviews r
  where r.question_version_id=v.id and r.campaign_id is null
  order by r.reviewed_at desc,r.id desc limit 1
) previous_review on true
where q.legacy_id in (5000232,5000234,5000235,5000236,5000238,5000240)
  and not exists (
    select 1 from public.question_reviews r
    where r.question_version_id=v.id and r.campaign_id is null
      and r.grade='A' and r.status='approved'
  );
commit;
