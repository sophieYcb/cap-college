/*
 CAP-COLLEGE DATABASE
 File: database/255_publish_maths_question_600071.sql
 Purpose: Publish the corrected current version of question 600071 after grade-A approval.
 Idempotent: Yes
*/

begin;

do $block$
declare
  current_version_id uuid;
  approved boolean;
begin
  select qv.id
  into current_version_id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id = 600071;

  if current_version_id is null then
    raise exception 'Publication annulée : question 600071 introuvable.';
  end if;

  select exists (
    select 1
    from public.question_reviews qr
    where qr.question_version_id = current_version_id
      and qr.campaign_id is null
      and qr.grade = 'A'
      and qr.status = 'approved'
  ) into approved;

  if not approved then
    raise exception 'Publication annulée : la version courante de la question 600071 n’est pas validée A.';
  end if;
end;
$block$;

update public.question_versions qv
set review_status = 'approved'::public.review_status,
    published_at = coalesce(qv.published_at, statement_timestamp())
from public.questions q
where q.legacy_id = 600071
  and qv.question_id = q.id
  and qv.version_number = q.current_version_number;

update public.questions
set status = 'published'::public.question_status,
    active = true,
    updated_at = statement_timestamp()
where legacy_id = 600071;

commit;
