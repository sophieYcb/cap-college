with target as (
  select diagnostic.id, diagnostic.result_snapshot
  from public.diagnostics diagnostic
  join public.learner_profiles profile
    on profile.id = diagnostic.learner_profile_id
  join public.subjects subject on subject.id = diagnostic.subject_id
  where lower(btrim(profile.display_name)) = 'testerreurs1'
    and profile.active
    and subject.code = 'mathematics'
    and diagnostic.status = 'completed'
    and diagnostic.completion_rule_version = 'test-errors-one-third-v1'
),
evidence as (
  select
    question.micro_skill_id,
    count(item.id)::integer as answers,
    count(*) filter (where not item.is_correct)::integer as errors,
    count(distinct session.id)::integer as sessions
  from target
  join public.diagnostic_sessions session on session.diagnostic_id = target.id
  join public.diagnostic_items item on item.session_id = session.id
  join public.questions question on question.id = item.question_id
  where item.answered_at is not null
  group by question.micro_skill_id
)
select jsonb_build_object(
  'profile', 'TestErreurs1',
  'diagnostic_created', (select count(*) = 1 from target),
  'diagnosis_ready', (
    select coalesce(
      (result_snapshot ->> 'diagnosisReady')::boolean,
      false
    ) from target
  ),
  'completed_sessions', (
    select count(*)
    from target
    join public.diagnostic_sessions session
      on session.diagnostic_id = target.id
    where session.status = 'completed'
  ),
  'total_answers', (select sum(answers) from evidence),
  'micro_skills_evaluated', (select count(*) from evidence),
  'micro_skills_with_errors', (
    select count(*) from evidence where errors > 0
  ),
  'micro_skills_without_errors', (
    select count(*) from evidence where errors = 0
  ),
  'skills_with_four_answers', (
    select count(*) from evidence where answers = 4
  ),
  'skills_seen_in_at_least_two_sessions', (
    select count(*) from evidence where sessions >= 2
  ),
  'report_saved', (
    select result_snapshot is not null from target
  )
) as verification;
