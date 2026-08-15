with current_versions as (
 select q.legacy_id,v.id from public.questions q join public.question_versions v
 on v.question_id=q.id and v.version_number=q.current_version_number
 where q.legacy_id between 5000201 and 5000240
), latest_reviews as (
 select distinct on(r.question_version_id) r.question_version_id,r.grade,r.status
 from public.question_reviews r join current_versions v on v.id=r.question_version_id
 where r.campaign_id is null order by r.question_version_id,r.reviewed_at desc,r.id desc
)
select jsonb_build_object(
 'questions',(select count(*) from current_versions),
 'ready_to_publish',(select count(*) from latest_reviews where grade='A' and status='approved'),
 'not_ready_legacy_ids',coalesce((select jsonb_agg(v.legacy_id order by v.legacy_id) from current_versions v left join latest_reviews r on r.question_version_id=v.id where r.grade is distinct from 'A' or r.status is distinct from 'approved'),'[]'::jsonb)
) as verification;
