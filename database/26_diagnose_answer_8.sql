/*
 CAP-COLLEGE — Diagnostic de l’échec à la huitième réponse
 Lecture seule.
*/

with latest_session as (
  select ds.id, ds.status, ds.started_at, ds.ended_at
  from public.diagnostic_sessions ds
  join public.diagnostics d on d.id = ds.diagnostic_id
  where d.student_id = '84f24c17-6349-4f1f-a4a5-c705a1925e1f'::uuid
  order by ds.started_at desc
  limit 1
)
select
  ls.id as latest_session_id,
  ls.status as latest_session_status,
  ls.started_at,
  ls.ended_at,
  count(di.id)::integer as recorded_answers,
  coalesce(array_agg(di.sequence_number order by di.sequence_number)
    filter (where di.sequence_number is not null), '{}') as recorded_sequences
from latest_session ls
left join public.diagnostic_items di on di.session_id = ls.id
group by ls.id, ls.status, ls.started_at, ls.ended_at;

select
  q.legacy_id,
  q.status,
  q.active,
  q.current_version_number,
  qv.id as current_question_version_id,
  count(ac.id)::integer as choices,
  count(ac.id) filter (where ac.is_correct)::integer as correct_choices
from public.questions q
join public.question_versions qv
  on qv.question_id = q.id
 and qv.version_number = q.current_version_number
left join public.answer_choices ac on ac.question_version_id = qv.id
where q.legacy_id = 147
group by
  q.legacy_id,
  q.status,
  q.active,
  q.current_version_number,
  qv.id;

