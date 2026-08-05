/*
 CAP-COLLEGE DATABASE
 File: database/241_publish_clarified_conjugation_questions_v2.sql
 Purpose: Publish conjugation questions 101 through 180 after accepting either
          a current grade-A approval or an already approved published version.
 Idempotent: Yes
*/

begin;

do $block$
declare
  question_count integer;
  ready_count integer;
begin
  select count(*) into question_count
  from public.questions
  where legacy_id between 101 and 180;

  if question_count <> 80 then
    raise exception
      'Publication annulée : 80 questions attendues, % trouvées.',
      question_count;
  end if;

  with current_versions as (
    select
      qv.id,
      q.status as question_status,
      q.active,
      qv.review_status as version_review_status,
      qv.published_at
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number
    where q.legacy_id between 101 and 180
  ),
  latest_reviews as (
    select distinct on (qr.question_version_id)
      qr.question_version_id,
      qr.grade,
      qr.status
    from public.question_reviews qr
    join current_versions cv on cv.id = qr.question_version_id
    where qr.campaign_id is null
    order by qr.question_version_id, qr.reviewed_at desc, qr.id desc
  )
  select count(*) into ready_count
  from current_versions cv
  left join latest_reviews lr on lr.question_version_id = cv.id
  where (lr.grade = 'A' and lr.status = 'approved')
     or (
       cv.question_status = 'published'
       and cv.active
       and cv.version_review_status = 'approved'
       and cv.published_at is not null
     );

  if ready_count <> 80 then
    raise exception
      'Publication annulée : seulement % versions validées ou déjà publiées sur 80.',
      ready_count;
  end if;
end;
$block$;

with current_versions as (
  select qv.id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 101 and 180
)
update public.question_versions qv
set review_status = 'approved'::public.review_status,
    published_at = coalesce(qv.published_at, statement_timestamp())
from current_versions cv
where qv.id = cv.id;

update public.questions
set status = 'published'::public.question_status,
    active = true,
    updated_at = statement_timestamp()
where legacy_id between 101 and 180;

commit;
