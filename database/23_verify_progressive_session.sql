/*
 CAP-COLLEGE — Vérification de la continuité et de la clôture des séances
 Lecture seule : ce script ne modifie aucune donnée.
*/

select
  d.id as diagnostic_id,
  d.status as diagnostic_status,
  ds.id as session_id,
  ds.status as session_status,
  ds.planned_minutes,
  count(di.id)::integer as recorded_answers,
  ds.started_at,
  ds.ended_at
from public.diagnostics d
join public.diagnostic_sessions ds
  on ds.diagnostic_id = d.id
left join public.diagnostic_items di
  on di.session_id = ds.id
where d.student_id = '84f24c17-6349-4f1f-a4a5-c705a1925e1f'::uuid
group by
  d.id,
  d.status,
  ds.id,
  ds.status,
  ds.planned_minutes,
  ds.started_at,
  ds.ended_at
order by ds.started_at desc
limit 10;

