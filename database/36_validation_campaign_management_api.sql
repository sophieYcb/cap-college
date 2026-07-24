/*
===============================================================================
 CAP-COLLEGE DATABASE — VALIDATION CAMPAIGN MANAGEMENT
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/36_validation_campaign_management_api.sql
 Purpose      : Securely create, list, archive, reset and delete validator
                campaigns without exposing administrative tables.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_my_validation_campaigns()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select case
    when auth.uid() is null or not public.can_validate_content() then '[]'::jsonb
    else coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', vc.id,
          'name', vc.name,
          'description', vc.description,
          'status', vc.status,
          'createdAt', vc.created_at,
          'archivedAt', vc.archived_at,
          'sessions', coalesce(stats.session_count, 0),
          'answers', coalesce(stats.answer_count, 0),
          'correctAnswers', coalesce(stats.correct_count, 0)
        )
        order by
          (vc.status = 'active') desc,
          vc.created_at desc
      ),
      '[]'::jsonb
    )
  end
  from public.validation_campaigns vc
  left join lateral (
    select
      count(distinct ds.id)::integer as session_count,
      count(di.id) filter (where di.answered_at is not null)::integer as answer_count,
      count(di.id) filter (
        where di.answered_at is not null and di.is_correct
      )::integer as correct_count
    from public.diagnostic_sessions ds
    left join public.diagnostic_items di on di.session_id = ds.id
    where ds.validation_campaign_id = vc.id
  ) stats on true
  where vc.owner_id = auth.uid()
     or public.has_role('administrator');
$function$;

create or replace function public.create_validation_campaign(
  requested_name text,
  requested_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  new_campaign_id uuid;
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;
  if btrim(coalesce(requested_name, '')) = '' then
    raise exception 'Campaign name required';
  end if;

  insert into public.validation_campaigns (
    name, description, owner_id
  )
  values (
    left(btrim(requested_name), 120),
    nullif(left(btrim(coalesce(requested_description, '')), 500), ''),
    auth.uid()
  )
  returning id into new_campaign_id;

  return new_campaign_id;
end;
$function$;

create or replace function public.archive_my_validation_campaign(
  requested_campaign_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;

  update public.validation_campaigns
  set status = 'archived',
      archived_at = statement_timestamp()
  where id = requested_campaign_id
    and (owner_id = auth.uid() or public.has_role('administrator'))
    and status = 'active';

  if not found then
    raise exception 'Active campaign not available';
  end if;
end;
$function$;

create or replace function public.reset_my_validation_campaign(
  requested_campaign_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;
  if not exists (
    select 1
    from public.validation_campaigns vc
    where vc.id = requested_campaign_id
      and (vc.owner_id = auth.uid() or public.has_role('administrator'))
      and vc.status = 'active'
  ) then
    raise exception 'Active campaign not available';
  end if;

  delete from public.diagnostic_sessions ds
  where ds.validation_campaign_id = requested_campaign_id;
end;
$function$;

create or replace function public.delete_my_validation_campaign(
  requested_campaign_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;
  if not exists (
    select 1
    from public.validation_campaigns vc
    where vc.id = requested_campaign_id
      and (vc.owner_id = auth.uid() or public.has_role('administrator'))
  ) then
    raise exception 'Campaign not available';
  end if;

  delete from public.diagnostic_sessions ds
  where ds.validation_campaign_id = requested_campaign_id;

  delete from public.validation_campaigns vc
  where vc.id = requested_campaign_id
    and (vc.owner_id = auth.uid() or public.has_role('administrator'));
end;
$function$;

revoke all on function public.get_my_validation_campaigns() from public;
revoke all on function public.create_validation_campaign(text, text) from public;
revoke all on function public.archive_my_validation_campaign(uuid) from public;
revoke all on function public.reset_my_validation_campaign(uuid) from public;
revoke all on function public.delete_my_validation_campaign(uuid) from public;

grant execute on function public.get_my_validation_campaigns() to authenticated;
grant execute on function public.create_validation_campaign(text, text) to authenticated;
grant execute on function public.archive_my_validation_campaign(uuid) to authenticated;
grant execute on function public.reset_my_validation_campaign(uuid) to authenticated;
grant execute on function public.delete_my_validation_campaign(uuid) to authenticated;

commit;

