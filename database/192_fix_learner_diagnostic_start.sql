begin;

create or replace function public.start_learner_diagnostic_session(
  requested_token text,
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
#variable_conflict use_column
declare
  selected_learner_id uuid;
  selected_subject_id smallint;
  selected_level_id smallint;
  active_diagnostic_id uuid;
  new_session_id uuid;
  selected_micro_skill_id uuid;
  selected_focus_name text;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;
  if planned_minutes not between 1 and 180 then
    raise exception 'Invalid planned duration';
  end if;

  select subject.id into selected_subject_id
  from public.subjects subject
  where subject.code = requested_subject_code and subject.active;

  select level.id into selected_level_id
  from public.levels level
  where level.code = requested_level_code and level.active;

  if selected_subject_id is null or selected_level_id is null then
    raise exception 'Unknown subject or level';
  end if;

  if requested_competence_id is not null
     and requested_competence_id <> 'all' then
    select micro_skill.id, micro_skill.student_name
    into selected_micro_skill_id, selected_focus_name
    from public.micro_skills micro_skill
    where replace(micro_skill.code, 'legacy_', '') = requested_competence_id
      and micro_skill.active
    limit 1;
    if selected_micro_skill_id is null then
      raise exception 'Unknown competency';
    end if;
  end if;

  select diagnostic.id into active_diagnostic_id
  from public.diagnostics diagnostic
  where diagnostic.learner_profile_id = selected_learner_id
    and diagnostic.subject_id = selected_subject_id
    and diagnostic.level_id = selected_level_id
    and diagnostic.status = 'active'
  order by diagnostic.started_at
  limit 1;

  if active_diagnostic_id is null then
    insert into public.diagnostics (
      student_id,
      learner_profile_id,
      subject_id,
      level_id
    )
    values (
      null,
      selected_learner_id,
      selected_subject_id,
      selected_level_id
    )
    returning diagnostics.id into active_diagnostic_id;
  end if;

  update public.diagnostic_sessions existing_session
  set status = 'cancelled',
      ended_at = coalesce(existing_session.ended_at, statement_timestamp())
  where existing_session.diagnostic_id = active_diagnostic_id
    and existing_session.status = 'active';

  insert into public.diagnostic_sessions (
    diagnostic_id,
    planned_minutes,
    focus_micro_skill_id
  )
  values (
    active_diagnostic_id,
    planned_minutes,
    selected_micro_skill_id
  )
  returning diagnostic_sessions.id into new_session_id;

  return query
  select
    active_diagnostic_id,
    new_session_id,
    coalesce(requested_competence_id, 'all'),
    coalesce(selected_focus_name, 'Tous les thèmes');
end;
$function$;

revoke all on function public.start_learner_diagnostic_session(
  text, smallint, text, text, text
) from public;
grant execute on function public.start_learner_diagnostic_session(
  text, smallint, text, text, text
) to anon, authenticated;

commit;