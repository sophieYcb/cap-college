/*
===============================================================================
 CAP-COLLEGE DATABASE - OPEN QUESTION FLAGS API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/42_open_question_flags_api.sql
 Purpose      : Show open flag comments in the validator interface.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_open_question_flags()
returns table (
  question_id uuid,
  flags jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;

  return query
  select
    qf.question_id,
    jsonb_agg(
      jsonb_build_object(
        'id', qf.id,
        'comment', qf.comment,
        'reportedAt', qf.reported_at,
        'reporter', coalesce(
          nullif(btrim(p.display_name), ''),
          nullif(btrim(concat_ws(' ', p.first_name, p.last_name)), ''),
          'Validateur'
        )
      )
      order by qf.reported_at desc
    ) as flags
  from public.question_flags qf
  join public.profiles p on p.id = qf.reported_by
  where qf.status in ('open', 'in_progress')
  group by qf.question_id;
end;
$function$;

revoke all on function public.get_open_question_flags() from public;
grant execute on function public.get_open_question_flags() to authenticated;

commit;
