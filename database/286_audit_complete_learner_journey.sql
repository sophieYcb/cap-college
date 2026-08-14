with function_checks as (
  select
    to_regprocedure('public.open_learner_session(text,text)') is not null learner_login,
    to_regprocedure('public.get_learner_session(text)') is not null learner_session_read,
    to_regprocedure('public.start_learner_diagnostic_session(text,smallint,text,text,text)') is not null diagnostic_start,
    to_regprocedure('public.submit_learner_diagnostic_answer(text,uuid,uuid,uuid,integer)') is not null diagnostic_answer,
    to_regprocedure('public.finish_learner_diagnostic_session(text,uuid)') is not null diagnostic_finish,
    to_regprocedure('public.get_learner_subject_diagnostic_progress(text,text)') is not null subject_progress,
    to_regprocedure('public.get_my_learner_diagnostic_reports(uuid)') is not null parent_reports,
    to_regprocedure('public.start_learner_remediation_session_v2(text,text,smallint)') is not null exercise_start,
    to_regprocedure('public.submit_learner_remediation_answer(text,uuid,uuid,uuid,public.assistance_mode,integer)') is not null exercise_answer,
    to_regprocedure('public.finish_learner_remediation_session_v2(text,uuid)') is not null exercise_finish,
    to_regprocedure('public.get_learner_reassessment_readiness(text,text)') is not null reassessment_readiness,
    to_regprocedure('public.start_learner_reassessment_session(text,text)') is not null reassessment_start,
    to_regprocedure('public.get_learner_exercise_progress(text,text)') is not null exercise_progress,
    to_regprocedure('public.get_my_learner_remediation_history_v2(uuid)') is not null parent_exercise_history
), permission_checks as (
  select
    has_function_privilege('anon', 'public.open_learner_session(text,text)', 'execute') learner_login_anon,
    has_function_privilege('anon', 'public.start_learner_diagnostic_session(text,smallint,text,text,text)', 'execute') diagnostic_start_anon,
    has_function_privilege('anon', 'public.submit_learner_diagnostic_answer(text,uuid,uuid,uuid,integer)', 'execute') diagnostic_answer_anon,
    has_function_privilege('anon', 'public.start_learner_remediation_session_v2(text,text,smallint)', 'execute') exercise_start_anon,
    has_function_privilege('anon', 'public.start_learner_reassessment_session(text,text)', 'execute') reassessment_start_anon,
    has_function_privilege('authenticated', 'public.get_my_learner_diagnostic_reports(uuid)', 'execute') parent_reports_authenticated,
    has_function_privilege('authenticated', 'public.get_my_learner_remediation_history_v2(uuid)', 'execute') parent_exercise_history_authenticated
), behavior_checks as (
  select
    position('subject.code = requested_subject_code' in pg_get_functiondef(
      'public.get_learner_subject_diagnostic_progress(text,text)'::regprocedure
    )) > 0 subject_progress_is_filtered,
    position('build_learner_diagnostic_snapshot(selected_diagnostic_id)' in pg_get_functiondef(
      'public.finish_learner_diagnostic_session(text,uuid)'::regprocedure
    )) > 0 finish_uses_exact_diagnostic,
    position('domain.subject_id = selected.subject_id' in pg_get_functiondef(
      'public.build_learner_diagnostic_snapshot(uuid)'::regprocedure
    )) > 0 snapshot_filters_diagnostic_subject,
    position('session.diagnostic_id = requested_diagnostic_id' in pg_get_functiondef(
      'public.build_learner_diagnostic_snapshot(uuid)'::regprocedure
    )) > 0 snapshot_filters_diagnostic_sessions,
    position('learner_profile_adults' in pg_get_functiondef(
      'public.get_my_learner_diagnostic_reports(uuid)'::regprocedure
    )) > 0 reports_check_adult_link,
    position('practice_answers >= 15' in pg_get_functiondef(
      'public.get_learner_reassessment_readiness(text,text)'::regprocedure
    )) > 0 reassessment_requires_fifteen_answers,
    position('practice_sessions >= 3' in pg_get_functiondef(
      'public.get_learner_reassessment_readiness(text,text)'::regprocedure
    )) > 0 reassessment_requires_three_sessions,
    position('without_reminder_successes >= 5' in pg_get_functiondef(
      'public.get_learner_reassessment_readiness(text,text)'::regprocedure
    )) > 0 reassessment_requires_independence,
    position('counted_answers = 5 and counted_correct >= 4' in pg_get_functiondef(
      'public.finish_learner_remediation_session_v2(text,uuid)'::regprocedure
    )) > 0 reassessment_passes_at_four_of_five,
    position('reassessment_passed' in pg_get_functiondef(
      'public.get_learner_exercise_progress(text,text)'::regprocedure
    )) > 0 progress_reads_reassessment
), integrity_checks as (
  select
    not exists (
      select 1 from public.diagnostics d
      where d.learner_profile_id is not null
        and d.status = 'completed'
        and d.result_snapshot is null
    ) completed_diagnostics_have_reports,
    not exists (
      select 1 from public.learner_profiles lp
      where lp.active and (lp.access_code is null or lp.pin_hash is null)
    ) active_profiles_have_credentials,
    exists (
      select 1 from pg_constraint
      where conname = 'diagnostics_single_owner'
        and conrelid = 'public.diagnostics'::regclass
    ) diagnostic_owner_constraint,
    exists (
      select 1 from pg_constraint
      where conname = 'remediation_sessions_single_owner'
        and conrelid = 'public.remediation_sessions'::regclass
    ) exercise_owner_constraint
), published_bank as (
  select sub.code subject_code, sub.name subject_name,
    count(distinct q.id) published_questions,
    count(distinct ms.id) micro_skills_with_questions
  from public.questions q
  join public.micro_skills ms on ms.id = q.micro_skill_id and ms.active
  join public.skills s on s.id = ms.skill_id and s.active
  join public.domains d on d.id = s.domain_id and d.active
  join public.subjects sub on sub.id = d.subject_id and sub.active
  join public.micro_skill_levels msl on msl.micro_skill_id = ms.id and msl.is_expected
  join public.levels l on l.id = msl.level_id and l.code = '6e' and l.active
  where q.active and q.status = 'published'
  group by sub.code, sub.name
), test_profile as (
  select lp.id
  from public.learner_profiles lp
  where lower(btrim(lp.display_name)) = 'testerreurs1'
  order by lp.created_at desc
  limit 1
), test_evidence as (
  select
    (select count(*) from public.diagnostics d join test_profile tp on tp.id = d.learner_profile_id) diagnostics,
    (select count(*) from public.diagnostics d join test_profile tp on tp.id = d.learner_profile_id where d.status = 'completed' and d.result_snapshot is not null) completed_reports,
    (select count(*) from public.remediation_sessions rs join test_profile tp on tp.id = rs.learner_profile_id where rs.session_kind = 'practice') practice_sessions,
    (select count(*) from public.remediation_sessions rs join test_profile tp on tp.id = rs.learner_profile_id where rs.session_kind = 'reassessment') reassessment_sessions,
    (select count(*) from public.remediation_sessions rs join test_profile tp on tp.id = rs.learner_profile_id where rs.session_kind = 'reassessment' and rs.reassessment_passed) passed_reassessments
)
select jsonb_build_object('verification', jsonb_build_object(
  'audit_version', 2,
  'learner_connection', jsonb_build_object(
    'functions_ready', fc.learner_login and fc.learner_session_read,
    'anonymous_access_ready', pc.learner_login_anon,
    'active_profiles_have_credentials', ic.active_profiles_have_credentials
  ),
  'diagnostic', jsonb_build_object(
    'functions_ready', fc.diagnostic_start and fc.diagnostic_answer and fc.diagnostic_finish and fc.subject_progress,
    'anonymous_access_ready', pc.diagnostic_start_anon and pc.diagnostic_answer_anon,
    'progress_separated_by_subject', bc.subject_progress_is_filtered and bc.finish_uses_exact_diagnostic and bc.snapshot_filters_diagnostic_subject and bc.snapshot_filters_diagnostic_sessions,
    'completed_reports_preserved', ic.completed_diagnostics_have_reports,
    'owner_constraint', ic.diagnostic_owner_constraint
  ),
  'targeted_exercises', jsonb_build_object(
    'functions_ready', fc.exercise_start and fc.exercise_answer and fc.exercise_finish and fc.exercise_progress,
    'anonymous_access_ready', pc.exercise_start_anon,
    'owner_constraint', ic.exercise_owner_constraint
  ),
  'reassessment', jsonb_build_object(
    'functions_ready', fc.reassessment_readiness and fc.reassessment_start,
    'anonymous_access_ready', pc.reassessment_start_anon,
    'requires_15_answers', bc.reassessment_requires_fifteen_answers,
    'requires_3_sessions', bc.reassessment_requires_three_sessions,
    'requires_5_successes_without_help', bc.reassessment_requires_independence,
    'passes_at_4_of_5', bc.reassessment_passes_at_four_of_five,
    'updates_exercise_progress', bc.progress_reads_reassessment
  ),
  'parent_follow_up', jsonb_build_object(
    'diagnostic_reports_ready', fc.parent_reports and pc.parent_reports_authenticated,
    'exercise_history_ready', fc.parent_exercise_history and pc.parent_exercise_history_authenticated,
    'checks_adult_link', bc.reports_check_adult_link
  ),
  'published_question_banks', coalesce((
    select jsonb_agg(jsonb_build_object(
      'subject_code', subject_code,
      'subject', subject_name,
      'published_questions', published_questions,
      'micro_skills_with_questions', micro_skills_with_questions
    ) order by subject_name) from published_bank
  ), '[]'::jsonb),
  'test_profile_evidence', (select to_jsonb(te) from test_evidence te),
  'audit_passed',
    fc.learner_login and fc.learner_session_read
    and fc.diagnostic_start and fc.diagnostic_answer and fc.diagnostic_finish and fc.subject_progress
    and fc.parent_reports
    and fc.exercise_start and fc.exercise_answer and fc.exercise_finish and fc.exercise_progress
    and fc.reassessment_readiness and fc.reassessment_start
    and fc.parent_exercise_history
    and pc.learner_login_anon and pc.diagnostic_start_anon and pc.diagnostic_answer_anon
    and pc.exercise_start_anon and pc.reassessment_start_anon
    and pc.parent_reports_authenticated and pc.parent_exercise_history_authenticated
    and bc.subject_progress_is_filtered and bc.finish_uses_exact_diagnostic
    and bc.snapshot_filters_diagnostic_subject and bc.snapshot_filters_diagnostic_sessions
    and bc.reports_check_adult_link
    and bc.reassessment_requires_fifteen_answers and bc.reassessment_requires_three_sessions
    and bc.reassessment_requires_independence and bc.reassessment_passes_at_four_of_five
    and bc.progress_reads_reassessment
    and ic.completed_diagnostics_have_reports and ic.active_profiles_have_credentials
    and ic.diagnostic_owner_constraint and ic.exercise_owner_constraint
    and (select count(*) >= 2 from published_bank where published_questions > 0)
  )
) as verification
from function_checks fc
cross join permission_checks pc
cross join behavior_checks bc
cross join integrity_checks ic;