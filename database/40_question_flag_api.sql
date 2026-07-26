/*
===============================================================================
 CAP-COLLEGE DATABASE - QUESTION FLAG API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/40_question_flag_api.sql
 Purpose      : Flag a question during a diagnostic without interrupting it.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.flag_question_for_review(
  requested_question_id uuid,
  requested_question_version_id uuid default null,
  requested_campaign_id uuid default null,
  requested_comment text default null
)
returns table (
  flag_id uuid,
  flag_status public.flag_status,
  reported_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  saved_id uuid;
  saved_at timestamptz;
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;

  if not exists (
    select 1 from public.questions q where q.id = requested_question_id
  ) then
    raise exception 'Unknown question';
  end if;

  if requested_question_version_id is not null and not exists (
    select 1
    from public.question_versions qv
    where qv.id = requested_question_version_id
      and qv.question_id = requested_question_id
  ) then
    raise exception 'Question version does not belong to question';
  end if;

  if requested_campaign_id is not null and not exists (
    select 1
    from public.validation_campaigns vc
    where vc.id = requested_campaign_id
      and (vc.owner_id = auth.uid() or public.has_role('administrator'))
  ) then
    raise exception 'Validation campaign unavailable';
  end if;

  insert into public.question_flags (
    question_id, question_version_id, campaign_id, reported_by, comment
  )
  values (
    requested_question_id,
    requested_question_version_id,
    requested_campaign_id,
    auth.uid(),
    nullif(btrim(requested_comment), '')
  )
  returning id, question_flags.reported_at into saved_id, saved_at;

  return query
  select saved_id, 'open'::public.flag_status, saved_at;
end;
$function$;

revoke all on function public.flag_question_for_review(uuid, uuid, uuid, text)
  from public;
grant execute on function public.flag_question_for_review(uuid, uuid, uuid, text)
  to authenticated;

commit;
