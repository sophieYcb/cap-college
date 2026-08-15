select jsonb_build_object('legacy_id',q.legacy_id,'current_version_number',q.current_version_number,'latest_grade',r.grade,'latest_status',r.status,'question_unchanged',q.current_version_number=1) verification
from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
join lateral(select x.grade,x.status from public.question_reviews x where x.question_version_id=v.id and x.campaign_id is null order by x.reviewed_at desc,x.id desc limit 1) r on true
where q.legacy_id=5000407;