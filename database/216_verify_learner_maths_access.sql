select jsonb_build_object(
  'progress_function', to_regprocedure('public.get_learner_diagnostic_progress(text)') is not null,
  'latest_session_selects_subject', pg_get_functiondef('public.get_learner_diagnostic_progress(text)'::regprocedure) like '%select max(ds.started_at)%',
  'maths_available', exists (select 1 from public.subjects where code = 'maths' and active),
  'published_maths_questions', (select count(*) from public.questions q join public.micro_skills ms on ms.id=q.micro_skill_id join public.skills sk on sk.id=ms.skill_id join public.domains d on d.id=sk.domain_id join public.subjects s on s.id=d.subject_id where s.code='maths' and q.status='published' and q.active)
) as verification;
