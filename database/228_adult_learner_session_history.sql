/*
 CAP-COLLEGE DATABASE
 File: database/228_adult_learner_session_history.sql
 Purpose: Let linked adults read the dated session history of one learner.
 Idempotent: Yes
*/

begin;

create or replace function public.get_my_learner_session_history(
  requested_learner_profile_id uuid
)
returns table (
  session_id uuid,
  subject_code text,
  subject_name text,
  planned_minutes smallint,
  session_status text,
  started_at timestamptz,
  ended_at timestamptz,
  answer_count integer
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    session.id,
    subject.code,
    subject.name,
    session.planned_minutes,
    session.status::text,
    session.started_at,
    session.ended_at,
    count(item.id) filter (
      where item.answered_at is not null
    )::integer
  from public.learner_profile_adults link
  join public.learner_profiles learner
    on learner.id = link.learner_profile_id
  join public.diagnostics diagnostic
    on diagnostic.learner_profile_id = learner.id
  join public.subjects subject
    on subject.id = diagnostic.subject_id
  join public.diagnostic_sessions session
    on session.diagnostic_id = diagnostic.id
   and session.validation_campaign_id is null
  left join public.diagnostic_items item
    on item.session_id = session.id
  where link.adult_user_id = auth.uid()
    and learner.id = requested_learner_profile_id
    and learner.active
  group by
    session.id,
    subject.id,
    subject.code,
    subject.name,
    subject.sort_order,
    session.planned_minutes,
    session.status,
    session.started_at,
    session.ended_at
  order by session.started_at desc;
$function$;

revoke all on function public.get_my_learner_session_history(uuid)
  from public;
grant execute on function public.get_my_learner_session_history(uuid)
  to authenticated;

commit;
