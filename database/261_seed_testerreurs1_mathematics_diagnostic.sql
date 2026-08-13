/*
 CAP-COLLEGE DATABASE
 File: database/261_seed_testerreurs1_mathematics_diagnostic.sql
 Purpose: Seed the dedicated TestErreurs1 learner with a complete mathematics
          diagnostic containing errors on approximately one third of skills.
 Idempotent: Yes
*/

begin;

do $block$
declare
  profile_ids uuid[];
  selected_profile_id uuid;
  selected_level_id smallint;
  selected_subject_id smallint;
  seeded_diagnostic_id uuid;
  expected_skill_count integer;
  minimum_question_count integer;
  progress_snapshot jsonb;
begin
  select array_agg(profile.id order by profile.created_at)
  into profile_ids
  from public.learner_profiles profile
  where lower(btrim(profile.display_name)) = 'testerreurs1'
    and profile.active;

  if coalesce(cardinality(profile_ids), 0) <> 1 then
    raise exception
      'Un unique profil actif TestErreurs1 est attendu, % trouvé(s).',
      coalesce(cardinality(profile_ids), 0);
  end if;

  selected_profile_id := profile_ids[1];

  select profile.level_id into selected_level_id
  from public.learner_profiles profile
  where profile.id = selected_profile_id;

  select subject.id into selected_subject_id
  from public.subjects subject
  where subject.code = 'mathematics' and subject.active;

  if selected_subject_id is null then
    raise exception 'La matière mathematics est introuvable.';
  end if;

  select count(*)::integer into expected_skill_count
  from public.micro_skill_levels level_link
  join public.micro_skills micro_skill
    on micro_skill.id = level_link.micro_skill_id
   and micro_skill.active
  join public.skills skill on skill.id = micro_skill.skill_id
  join public.domains domain
    on domain.id = skill.domain_id
   and domain.subject_id = selected_subject_id
  where level_link.level_id = selected_level_id
    and level_link.is_expected;

  select min(question_count)::integer into minimum_question_count
  from (
    select micro_skill.id, count(question.id) as question_count
    from public.micro_skill_levels level_link
    join public.micro_skills micro_skill
      on micro_skill.id = level_link.micro_skill_id
     and micro_skill.active
    join public.skills skill on skill.id = micro_skill.skill_id
    join public.domains domain
      on domain.id = skill.domain_id
     and domain.subject_id = selected_subject_id
    left join public.questions question
      on question.micro_skill_id = micro_skill.id
     and question.status = 'published'
     and question.active
    left join public.question_versions version
      on version.question_id = question.id
     and version.version_number = question.current_version_number
     and version.review_status = 'approved'
     and version.published_at is not null
    where level_link.level_id = selected_level_id
      and level_link.is_expected
      and (question.id is null or version.id is not null)
    group by micro_skill.id
  ) available;

  if expected_skill_count = 0 or minimum_question_count < 4 then
    raise exception
      'Données insuffisantes : % compétences, minimum % questions publiées.',
      expected_skill_count, coalesce(minimum_question_count, 0);
  end if;

  seeded_diagnostic_id := md5(
    'cap-college:testerreurs1:mathematics:' || selected_profile_id
  )::uuid;

  update public.diagnostic_sessions session
  set status = 'cancelled',
      ended_at = coalesce(session.ended_at, statement_timestamp())
  from public.diagnostics diagnostic
  where diagnostic.learner_profile_id = selected_profile_id
    and diagnostic.subject_id = selected_subject_id
    and diagnostic.status = 'active'
    and session.diagnostic_id = diagnostic.id;

  update public.diagnostics
  set status = 'abandoned',
      completed_at = coalesce(completed_at, statement_timestamp()),
      updated_at = statement_timestamp()
  where learner_profile_id = selected_profile_id
    and subject_id = selected_subject_id
    and status = 'active';

  delete from public.diagnostics
  where id = seeded_diagnostic_id;

  insert into public.diagnostics (
    id, student_id, learner_profile_id, subject_id, level_id,
    status, started_at, updated_at
  ) values (
    seeded_diagnostic_id, null, selected_profile_id,
    selected_subject_id, selected_level_id,
    'active', statement_timestamp() - interval '9 days',
    statement_timestamp()
  );

  insert into public.diagnostic_sessions (
    id, diagnostic_id, planned_minutes, status, started_at, ended_at
  )
  select
    md5(
      'cap-college:testerreurs1:mathematics:' || selected_profile_id
      || ':session:' || session_number
    )::uuid,
    seeded_diagnostic_id,
    20,
    'completed'::public.session_status,
    statement_timestamp() - interval '9 days'
      + session_number * interval '1 day',
    statement_timestamp() - interval '9 days'
      + session_number * interval '1 day' + interval '20 minutes'
  from generate_series(1, 8) session_number;

  with expected_skills as (
    select
      micro_skill.id,
      row_number() over (order by micro_skill.code, micro_skill.id)
        as skill_number
    from public.micro_skill_levels level_link
    join public.micro_skills micro_skill
      on micro_skill.id = level_link.micro_skill_id
     and micro_skill.active
    join public.skills skill on skill.id = micro_skill.skill_id
    join public.domains domain
      on domain.id = skill.domain_id
     and domain.subject_id = selected_subject_id
    where level_link.level_id = selected_level_id
      and level_link.is_expected
  ),
  ranked_questions as (
    select
      expected.id as micro_skill_id,
      expected.skill_number,
      question.id as question_id,
      version.id as question_version_id,
      row_number() over (
        partition by expected.id
        order by question.theoretical_difficulty, question.legacy_id, question.id
      ) as question_number
    from expected_skills expected
    join public.questions question
      on question.micro_skill_id = expected.id
     and question.status = 'published'
     and question.active
    join public.question_versions version
      on version.question_id = question.id
     and version.version_number = question.current_version_number
     and version.review_status = 'approved'
     and version.published_at is not null
  ),
  assigned as (
    select
      ranked.*,
      ((ranked.skill_number - 1) % 3 = 0) as intentional_error,
      case when ranked.question_number <= 2
        then ((ranked.skill_number - 1) % 4) + 1
        else ((ranked.skill_number - 1) % 4) + 5
      end::integer as session_number
    from ranked_questions ranked
    where ranked.question_number <= 4
  ),
  selected_answers as (
    select
      assigned.*,
      choice.id as selected_choice_id,
      not assigned.intentional_error as answer_is_correct
    from assigned
    join lateral (
      select answer.id
      from public.answer_choices answer
      where answer.question_version_id = assigned.question_version_id
        and answer.is_correct = not assigned.intentional_error
      order by answer.sort_order
      limit 1
    ) choice on true
  ),
  sequenced as (
    select
      selected_answers.*,
      row_number() over (
        partition by selected_answers.session_number
        order by selected_answers.skill_number,
          selected_answers.question_number
      )::integer as sequence_number
    from selected_answers
  )
  insert into public.diagnostic_items (
    session_id, question_id, question_version_id, selected_choice_id,
    sequence_number, is_correct, presented_at, answered_at
  )
  select
    md5(
      'cap-college:testerreurs1:mathematics:' || selected_profile_id
      || ':session:' || sequenced.session_number
    )::uuid,
    sequenced.question_id,
    sequenced.question_version_id,
    sequenced.selected_choice_id,
    sequenced.sequence_number,
    sequenced.answer_is_correct,
    statement_timestamp() - interval '9 days'
      + sequenced.session_number * interval '1 day'
      + sequenced.sequence_number * interval '10 seconds',
    statement_timestamp() - interval '9 days'
      + sequenced.session_number * interval '1 day'
      + sequenced.sequence_number * interval '10 seconds'
      + interval '5 seconds'
  from sequenced;

  progress_snapshot :=
    public.build_learner_diagnostic_snapshot(seeded_diagnostic_id);

  if not coalesce(
    (progress_snapshot ->> 'diagnosisReady')::boolean,
    false
  ) then
    raise exception 'Le diagnostic de test généré n’est pas complet.';
  end if;

  update public.diagnostics
  set status = 'completed',
      completed_at = statement_timestamp(),
      result_snapshot = progress_snapshot || jsonb_build_object(
        'diagnosticStatus', 'completed',
        'completedAt', statement_timestamp(),
        'testData', true,
        'testScenario', 'approximately-one-third-errors'
      ),
      completion_rule_version = 'test-errors-one-third-v1',
      updated_at = statement_timestamp()
  where id = seeded_diagnostic_id;
end;
$block$;

commit;
