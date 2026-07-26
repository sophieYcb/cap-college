/*
===============================================================================
 CAP-COLLEGE DATABASE - QUESTION BANK HIERARCHY API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/49_question_bank_hierarchy_api.sql
 Purpose      : Expose subject and category metadata to question selectors.
 Idempotent   : Yes
===============================================================================
*/

begin;

create or replace function public.get_published_question_bank()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.legacy_id,
        'questionId', q.id,
        'questionVersionId', qv.id,
        'subjectCode', subject.code,
        'subject', subject.name,
        'domainCode', d.code,
        'domaine', d.name,
        'competenceId', replace(ms.code, 'legacy_', ''),
        'competence', ms.student_name,
        'difficulte', q.theoretical_difficulty,
        'question', qv.prompt,
        'version', qv.version_number,
        'choix', (
          select jsonb_agg(
            jsonb_build_object(
              'id', ac.id,
              'texte', ac.content,
              'ordre', ac.sort_order
            )
            order by ac.sort_order
          )
          from public.answer_choices ac
          where ac.question_version_id = qv.id
        )
      )
      order by subject.sort_order, d.sort_order, ms.sort_order, q.legacy_id
    ),
    '[]'::jsonb
  )
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  join public.micro_skills ms on ms.id = q.micro_skill_id
  join public.skills s on s.id = ms.skill_id
  join public.domains d on d.id = s.domain_id
  join public.subjects subject on subject.id = d.subject_id
  where q.status = 'published'
    and q.active;
$function$;

create or replace function public.get_validation_question_bank()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  payload jsonb;
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.legacy_id,
        'questionId', q.id,
        'status', q.status,
        'active', q.active,
        'subjectCode', subject.code,
        'subject', subject.name,
        'domainCode', d.code,
        'domain', d.name,
        'competenceId', replace(ms.code, 'legacy_', ''),
        'competence', ms.student_name,
        'difficulty', q.theoretical_difficulty,
        'current', jsonb_build_object(
          'id', current_version.id,
          'number', current_version.version_number,
          'prompt', current_version.prompt,
          'explanation', current_version.correction_explanation,
          'choices', (
            select jsonb_agg(
              jsonb_build_object(
                'id', ac.id,
                'text', ac.content,
                'isCorrect', ac.is_correct
              )
              order by ac.sort_order
            )
            from public.answer_choices ac
            where ac.question_version_id = current_version.id
          )
        ),
        'previous', case when previous_version.id is null then null else
          jsonb_build_object(
            'id', previous_version.id,
            'number', previous_version.version_number,
            'prompt', previous_version.prompt,
            'explanation', previous_version.correction_explanation,
            'choices', (
              select jsonb_agg(
                jsonb_build_object(
                  'id', pac.id,
                  'text', pac.content,
                  'isCorrect', pac.is_correct
                )
                order by pac.sort_order
              )
              from public.answer_choices pac
              where pac.question_version_id = previous_version.id
            )
          )
        end,
        'review', case when latest_review.id is null then null else
          jsonb_build_object(
            'id', latest_review.id,
            'grade', latest_review.grade,
            'status', latest_review.status,
            'comment', latest_review.comment,
            'reviewedAt', latest_review.reviewed_at
          )
        end,
        'openFlags', (
          select count(*)::integer
          from public.question_flags qf
          where qf.question_id = q.id
            and qf.status in ('open', 'in_progress')
        )
      )
      order by subject.sort_order, d.sort_order, ms.sort_order, q.legacy_id
    ),
    '[]'::jsonb
  )
  into payload
  from public.questions q
  join public.question_versions current_version
    on current_version.question_id = q.id
   and current_version.version_number = q.current_version_number
  join public.micro_skills ms on ms.id = q.micro_skill_id
  join public.skills s on s.id = ms.skill_id
  join public.domains d on d.id = s.domain_id
  join public.subjects subject on subject.id = d.subject_id
  left join lateral (
    select qv.*
    from public.question_versions qv
    where qv.question_id = q.id
      and qv.version_number < q.current_version_number
    order by qv.version_number desc
    limit 1
  ) previous_version on true
  left join lateral (
    select qr.*
    from public.question_reviews qr
    where qr.question_version_id = current_version.id
      and (
        qr.reviewer_id = auth.uid()
        or public.has_role('administrator')
      )
    order by
      (qr.reviewer_id = auth.uid()) desc,
      qr.reviewed_at desc
    limit 1
  ) latest_review on true;

  return payload;
end;
$function$;

revoke all on function public.get_published_question_bank() from public;
revoke all on function public.get_validation_question_bank() from public;
grant execute on function public.get_published_question_bank()
  to authenticated;
grant execute on function public.get_validation_question_bank()
  to authenticated;

commit;
