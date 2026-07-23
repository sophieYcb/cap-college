/*
===============================================================================
 CAP-COLLEGE DATABASE - VALIDATOR QUESTION API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 30_validator_question_api.sql
 Purpose      : Load N/N-1 and save pedagogical reviews securely.
 Idempotent   : Yes
===============================================================================
*/

begin;

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
      order by q.legacy_id
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

create or replace function public.save_question_review(
  requested_question_version_id uuid,
  requested_grade text,
  requested_comment text default null
)
returns table (
  review_id uuid,
  review_status public.review_status,
  reviewed_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_status public.review_status;
  existing_review_id uuid;
  saved_review_id uuid;
  saved_reviewed_at timestamptz;
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;
  if requested_grade not in ('A', 'B', 'C', 'D') then
    raise exception 'Grade must be A, B, C or D';
  end if;

  selected_status := case requested_grade
    when 'A' then 'approved'::public.review_status
    when 'D' then 'rejected'::public.review_status
    else 'changes_requested'::public.review_status
  end;

  select qr.id into existing_review_id
  from public.question_reviews qr
  where qr.question_version_id = requested_question_version_id
    and qr.reviewer_id = auth.uid()
    and qr.campaign_id is null
  order by qr.reviewed_at desc
  limit 1;

  if existing_review_id is null then
    insert into public.question_reviews (
      question_version_id,
      reviewer_id,
      status,
      grade,
      comment
    )
    values (
      requested_question_version_id,
      auth.uid(),
      selected_status,
      requested_grade::char(1),
      nullif(btrim(requested_comment), '')
    )
    returning id, question_reviews.reviewed_at
    into saved_review_id, saved_reviewed_at;
  else
    update public.question_reviews
    set status = selected_status,
        grade = requested_grade::char(1),
        comment = nullif(btrim(requested_comment), ''),
        reviewed_at = statement_timestamp()
    where id = existing_review_id
    returning id, question_reviews.reviewed_at
    into saved_review_id, saved_reviewed_at;
  end if;

  return query select saved_review_id, selected_status, saved_reviewed_at;
end;
$function$;

revoke all on function public.get_validation_question_bank() from public;
revoke all on function public.save_question_review(uuid, text, text) from public;
grant execute on function public.get_validation_question_bank() to authenticated;
grant execute on function public.save_question_review(uuid, text, text) to authenticated;

commit;
