begin;
insert into public.question_reviews(question_version_id,reviewer_id,status,grade,comment)
select v.id,previous_review.reviewer_id,'approved'::public.review_status,'A',
'Je ne suis pas d’accord avec la remarque : préciser que x désigne le plus petit entier est nécessaire pour représenter les deux entiers consécutifs par x et x + 1. La question est conservée sans modification.'
from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
join lateral(select r.reviewer_id from public.question_reviews r where r.question_version_id=v.id and r.campaign_id is null order by r.reviewed_at desc,r.id desc limit 1) previous_review on true
where q.legacy_id=5000407 and not exists(select 1 from public.question_reviews r where r.question_version_id=v.id and r.campaign_id is null and r.grade='A' and r.status='approved');
commit;