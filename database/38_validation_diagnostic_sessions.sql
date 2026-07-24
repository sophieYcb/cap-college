/*
===============================================================================
 CAP-COLLEGE DATABASE — VALIDATION DIAGNOSTIC SESSIONS
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/38_validation_diagnostic_sessions.sql
 Purpose      : Start and resume diagnostics isolated inside a validator
                campaign.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.start_validation_diagnostic_session(
  requested_campaign_id uuid,
  planned_minutes smallint,
  requested_subject_code text default 'french',
  requested_level_code text default '6e',
  requested_competence_id text default null
)
returns table (
  diagnostic_id uuid,
  session_id uuid,
  focus_competence_id text,
  focus_name text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_subject_id smallint;
  selected_level_id smallint;
  selected_micro_skill_id uuid;
  selected_focus_name text;
  selected_diagnostic_id uuid;
  new_session_id uuid;
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;
  if planned_minutes not between 1 and 180 then
    raise exception 'Invalid planned duration';
  end if;
  if not exists (
    select 1
    from public.validation_campaigns vc
    where vc.id = requested_campaign_id
      and vc.status = 'active'
      and (vc.owner_id = auth.uid() or public.has_role('administrator'))
  ) then
    raise exception 'Active campaign not available';
  end if;

  select id into selected_subject_id
  from public.subjects
  where code = requested_subject_code and active;

  select id into selected_level_id
  from public.levels
  where code = requested_level_code and active;

  if selected_subject_id is null or selected_level_id is null then
    raise exception 'Unknown subject or level';
  end if;

  if requested_competence_id is not null
     and requested_competence_id <> 'all' then
    select ms.id, ms.student_name
    into selected_micro_skill_id, selected_focus_name
    from public.micro_skills ms
    where replace(ms.code, 'legacy_', '') = requested_competence_id
      and ms.active
    limit 1;

    if selected_micro_skill_id is null then
      raise exception 'Unknown competency';
    end if;
  end if;

  select d.id
  into selected_diagnostic_id
  from public.diagnostics d
  join public.diagnostic_sessions ds on ds.diagnostic_id = d.id
  where d.student_id = auth.uid()
    and d.subject_id = selected_subject_id
    and d.level_id = selected_level_id
    and ds.validation_campaign_id = requested_campaign_id
  order by d.started_at
  limit 1;

  if selected_diagnostic_id is null then
    insert into public.diagnostics (
      student_id, subject_id, level_id
    )
    values (
      auth.uid(), selected_subject_id, selected_level_id
    )
    returning id into selected_diagnostic_id;
  end if;

  update public.diagnostic_sessions
  set status = 'cancelled',
      ended_at = coalesce(ended_at, statement_timestamp())
  where validation_campaign_id = requested_campaign_id
    and status = 'active';

  insert into public.diagnostic_sessions (
    diagnostic_id,
    planned_minutes,
    validation_campaign_id,
    focus_micro_skill_id
  )
  values (
    selected_diagnostic_id,
    planned_minutes,
    requested_campaign_id,
    selected_micro_skill_id
  )
  returning id into new_session_id;

  return query
  select
    selected_diagnostic_id,
    new_session_id,
    coalesce(requested_competence_id, 'all'),
    coalesce(selected_focus_name, 'Tous les thèmes');
end;
$function$;

create or replace function public.get_my_validation_diagnostic_history(
  requested_campaign_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'questionId', history.question_id,
        'attempts', history.attempts,
        'correctAnswers', history.correct_answers,
        'lastAnsweredAt', history.last_answered_at
      )
      order by history.last_answered_at desc
    ),
    '[]'::jsonb
  )
  from (
    select
      di.question_id,
      count(*)::integer as attempts,
      count(*) filter (where di.is_correct)::integer as correct_answers,
      max(di.answered_at) as last_answered_at
    from public.diagnostic_items di
    join public.diagnostic_sessions ds on ds.id = di.session_id
    join public.validation_campaigns vc
      on vc.id = ds.validation_campaign_id
    where ds.validation_campaign_id = requested_campaign_id
      and (vc.owner_id = auth.uid() or public.has_role('administrator'))
      and di.answered_at is not null
    group by di.question_id
  ) history;
$function$;

create or replace function public.get_my_active_validation_session(
  requested_campaign_id uuid
)
returns table (
  diagnostic_id uuid,
  session_id uuid,
  planned_minutes smallint,
  recorded_answers integer,
  focus_competence_id text,
  focus_name text
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    d.id,
    ds.id,
    ds.planned_minutes,
    count(di.id)::integer,
    coalesce(replace(ms.code, 'legacy_', ''), 'all'),
    coalesce(ms.student_name, 'Tous les thèmes')
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  join public.validation_campaigns vc
    on vc.id = ds.validation_campaign_id
  left join public.micro_skills ms on ms.id = ds.focus_micro_skill_id
  left join public.diagnostic_items di
    on di.session_id = ds.id
   and di.answered_at is not null
  where ds.validation_campaign_id = requested_campaign_id
    and ds.status = 'active'
    and (vc.owner_id = auth.uid() or public.has_role('administrator'))
  group by d.id, ds.id, ds.planned_minutes, ds.started_at, ms.code, ms.student_name
  order by ds.started_at desc
  limit 1;
$function$;

revoke all on function public.start_validation_diagnostic_session(
  uuid, smallint, text, text, text
) from public;
revoke all on function public.get_my_validation_diagnostic_history(uuid)
  from public;
revoke all on function public.get_my_active_validation_session(uuid)
  from public;

grant execute on function public.start_validation_diagnostic_session(
  uuid, smallint, text, text, text
) to authenticated;
grant execute on function public.get_my_validation_diagnostic_history(uuid)
  to authenticated;
grant execute on function public.get_my_active_validation_session(uuid)
  to authenticated;

commit;

