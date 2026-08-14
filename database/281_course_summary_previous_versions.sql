begin;

create or replace function public.get_validation_course_summaries()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare payload jsonb;
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;

  with base as (
    select ms.id micro_skill_id, ms.code micro_skill_code,
      sub.code subject_code, sub.name subject_name,
      d.code domain_code, d.name domain_name,
      s.code skill_code, s.name skill_name,
      ms.student_name initial_title,
      coalesce(ms.lesson_reminder, '') initial_reminder,
      coalesce(ms.worked_example, '') initial_example,
      lr.id resource_id, lr.title resource_title,
      lr.reminder resource_reminder, lr.worked_example resource_example,
      lr.version_number resource_version,
      previous_lr.id previous_resource_id,
      previous_lr.title previous_resource_title,
      previous_lr.reminder previous_resource_reminder,
      previous_lr.worked_example previous_resource_example,
      previous_lr.version_number previous_resource_version,
      sub.sort_order subject_order, d.sort_order domain_order,
      s.sort_order skill_order, ms.sort_order micro_skill_order
    from public.micro_skills ms
    join public.skills s on s.id = ms.skill_id and s.active
    join public.domains d on d.id = s.domain_id and d.active
    join public.subjects sub on sub.id = d.subject_id and sub.active
    join public.micro_skill_levels msl on msl.micro_skill_id = ms.id and msl.is_expected
    join public.levels l on l.id = msl.level_id and l.code = '6e' and l.active
    left join lateral (
      select selected_resource.*
      from public.learning_resources selected_resource
      where selected_resource.micro_skill_id = ms.id and selected_resource.active
      order by selected_resource.version_number desc, selected_resource.created_at desc
      limit 1
    ) lr on true
    left join lateral (
      select older_resource.*
      from public.learning_resources older_resource
      where older_resource.micro_skill_id = ms.id
        and lr.id is not null
        and older_resource.version_number < lr.version_number
      order by older_resource.version_number desc, older_resource.created_at desc
      limit 1
    ) previous_lr on true
    where ms.active
  ), effective as (
    select b.*,
      coalesce(nullif(btrim(b.resource_title), ''), b.initial_title) title,
      coalesce(nullif(btrim(b.resource_reminder), ''), nullif(btrim(b.initial_reminder), ''), '') reminder,
      coalesce(nullif(btrim(b.resource_example), ''), nullif(btrim(b.initial_example), ''), '') worked_example,
      case when b.resource_id is null then 'micro_skill' else 'learning_resource' end content_source,
      md5(concat_ws(E'\n',
        coalesce(nullif(btrim(b.resource_title), ''), b.initial_title),
        coalesce(nullif(btrim(b.resource_reminder), ''), nullif(btrim(b.initial_reminder), ''), ''),
        coalesce(nullif(btrim(b.resource_example), ''), nullif(btrim(b.initial_example), ''), '')
      )) content_fingerprint,
      case when b.resource_id is null then null
        else coalesce(nullif(btrim(b.previous_resource_title), ''), b.initial_title) end previous_title,
      case when b.resource_id is null then null
        else coalesce(nullif(btrim(b.previous_resource_reminder), ''), nullif(btrim(b.initial_reminder), ''), '') end previous_reminder,
      case when b.resource_id is null then null
        else coalesce(nullif(btrim(b.previous_resource_example), ''), nullif(btrim(b.initial_example), ''), '') end previous_example,
      case when b.resource_id is null then null
        else md5(concat_ws(E'\n',
          coalesce(nullif(btrim(b.previous_resource_title), ''), b.initial_title),
          coalesce(nullif(btrim(b.previous_resource_reminder), ''), nullif(btrim(b.initial_reminder), ''), ''),
          coalesce(nullif(btrim(b.previous_resource_example), ''), nullif(btrim(b.initial_example), ''), '')
        )) end previous_fingerprint
    from base b
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'microSkillId', e.micro_skill_id, 'microSkillCode', e.micro_skill_code,
    'subjectCode', e.subject_code, 'subjectName', e.subject_name,
    'domainCode', e.domain_code, 'domainName', e.domain_name,
    'skillCode', e.skill_code, 'skillName', e.skill_name,
    'title', e.title, 'reminder', e.reminder, 'workedExample', e.worked_example,
    'resourceId', e.resource_id, 'resourceVersion', e.resource_version,
    'contentSource', e.content_source, 'fingerprint', e.content_fingerprint,
    'review', case when current_review.id is null then null else jsonb_build_object(
      'grade', current_review.grade, 'comment', current_review.comment,
      'reviewedAt', current_review.reviewed_at
    ) end,
    'previous', case when e.resource_id is null then null else jsonb_build_object(
      'title', e.previous_title,
      'reminder', e.previous_reminder,
      'workedExample', e.previous_example,
      'resourceId', e.previous_resource_id,
      'resourceVersion', e.previous_resource_version,
      'source', case when e.previous_resource_id is null then 'micro_skill' else 'learning_resource' end,
      'fingerprint', e.previous_fingerprint,
      'review', case when previous_review.id is null then null else jsonb_build_object(
        'grade', previous_review.grade, 'comment', previous_review.comment,
        'reviewedAt', previous_review.reviewed_at
      ) end
    ) end
  ) order by e.subject_order, e.domain_order, e.skill_order, e.micro_skill_order, e.title), '[]'::jsonb)
  into payload
  from effective e
  left join public.course_summary_reviews current_review
    on current_review.micro_skill_id = e.micro_skill_id
   and current_review.reviewer_id = auth.uid()
   and current_review.content_fingerprint = e.content_fingerprint
  left join public.course_summary_reviews previous_review
    on previous_review.micro_skill_id = e.micro_skill_id
   and previous_review.reviewer_id = auth.uid()
   and previous_review.content_fingerprint = e.previous_fingerprint;

  return payload;
end;
$function$;

revoke all on function public.get_validation_course_summaries() from public;
grant execute on function public.get_validation_course_summaries() to authenticated;

commit;
