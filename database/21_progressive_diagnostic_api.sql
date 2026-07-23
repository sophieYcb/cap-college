/*
===============================================================================
 CAP-COLLEGE DATABASE — PROGRESSIVE DIAGNOSTIC HISTORY API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 21_progressive_diagnostic_api.sql
 Purpose      : Let the authenticated student continue a diagnostic over time.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_my_diagnostic_history()
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
    join public.diagnostic_sessions ds
      on ds.id = di.session_id
    join public.diagnostics d
      on d.id = ds.diagnostic_id
    where d.student_id = auth.uid()
      and di.answered_at is not null
    group by di.question_id
  ) history;
$function$;

revoke all on function public.get_my_diagnostic_history() from public;
grant execute on function public.get_my_diagnostic_history() to authenticated;

commit;

