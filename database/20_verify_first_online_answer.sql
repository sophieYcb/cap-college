/*
 CAP-COLLEGE — Vérification du premier diagnostic connecté
 Lecture seule : ce script ne modifie aucune donnée.
*/

select
  ds.id as session_id,
  d.student_id,
  ds.started_at,
  ds.planned_minutes,
  count(di.id)::integer as recorded_answers,
  max(di.answered_at) as last_answer_at
from public.diagnostic_sessions ds
join public.diagnostics d
  on d.id = ds.diagnostic_id
left join public.diagnostic_items di
  on di.session_id = ds.id
group by
  ds.id,
  d.student_id,
  ds.started_at,
  ds.planned_minutes
order by ds.started_at desc
limit 5;

