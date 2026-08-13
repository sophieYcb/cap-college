/*
 CAP-COLLEGE DATABASE
 File: database/271_exercise_progress_reassessment_score.sql
 Purpose: Include the latest reassessment score in learner exercise progress.
 Idempotent: Yes
*/

begin;

create or replace function public.get_learner_exercise_progress(
  requested_token text,
  requested_subject_code text default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  selected_learner_id uuid;
  result jsonb;
begin
  selected_learner_id := public.learner_profile_for_token(requested_token);
  if selected_learner_id is null then
    raise exception 'Learner session required';
  end if;

  with relevant_skills as (
    select distinct
      micro_skill.id,
      replace(micro_skill.code, 'legacy_', '') as competence_id,
      micro_skill.student_name as competence,
      domain.name as domain_name,
      subject.code as subject_code
    from public.remediation_sessions session
    join public.micro_skills micro_skill on micro_skill.id = session.micro_skill_id
    join public.skills skill on skill.id = micro_skill.skill_id
    join public.domains domain on domain.id = skill.domain_id
    join public.subjects subject on subject.id = domain.subject_id
    where session.learner_profile_id = selected_learner_id
      and (requested_subject_code is null or subject.code = requested_subject_code)
  ),
  progress as (
    select
      relevant.*,
      practice.answer_count as practice_answers,
      practice.correct_count as practice_correct,
      reassessment.reassessment_passed,
      reassessment.answer_count as reassessment_answers,
      reassessment.correct_count as reassessment_correct,
      reassessment.completed_at as reassessed_at
    from relevant_skills relevant
    left join lateral (
      select
        count(attempt.id) filter (where attempt.answered_at is not null)::integer
          as answer_count,
        count(attempt.id) filter (
          where attempt.answered_at is not null and attempt.is_correct
        )::integer as correct_count
      from public.remediation_sessions session
      left join public.remediation_attempts attempt
        on attempt.remediation_session_id = session.id
      where session.learner_profile_id = selected_learner_id
        and session.micro_skill_id = relevant.id
        and session.session_kind = 'practice'
        and session.status = 'completed'
    ) practice on true
    left join lateral (
      select
        session.reassessment_passed,
        session.completed_at,
        count(attempt.id) filter (where attempt.answered_at is not null)::integer
          as answer_count,
        count(attempt.id) filter (
          where attempt.answered_at is not null and attempt.is_correct
        )::integer as correct_count
      from public.remediation_sessions session
      left join public.remediation_attempts attempt
        on attempt.remediation_session_id = session.id
      where session.learner_profile_id = selected_learner_id
        and session.micro_skill_id = relevant.id
        and session.session_kind = 'reassessment'
        and session.status = 'completed'
      group by session.id
      order by session.completed_at desc, session.id desc
      limit 1
    ) reassessment on true
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'microSkillId', progress.id,
    'competenceId', progress.competence_id,
    'competence', progress.competence,
    'domain', progress.domain_name,
    'subjectCode', progress.subject_code,
    'practiceAnswers', coalesce(progress.practice_answers, 0),
    'practiceCorrect', coalesce(progress.practice_correct, 0),
    'reassessmentPassed', progress.reassessment_passed,
    'reassessmentAnswers', coalesce(progress.reassessment_answers, 0),
    'reassessmentCorrect', coalesce(progress.reassessment_correct, 0),
    'reassessmentScore', case
      when coalesce(progress.reassessment_answers, 0) = 0 then null
      else round(
        progress.reassessment_correct::numeric * 100
        / progress.reassessment_answers
      )
    end,
    'reassessedAt', progress.reassessed_at
  ) order by progress.domain_name, progress.competence), '[]'::jsonb)
  into result
  from progress;

  return result;
end;
$function$;

revoke all on function public.get_learner_exercise_progress(text, text)
  from public;
grant execute on function public.get_learner_exercise_progress(text, text)
  to anon, authenticated;

commit;
