begin;

create table if not exists public.course_summary_reviews (
  id uuid primary key default extensions.gen_random_uuid(),
  micro_skill_id uuid not null references public.micro_skills(id) on delete cascade,
  resource_id uuid references public.learning_resources(id) on delete set null,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  content_fingerprint text not null,
  grade char(1) not null check (grade in ('A', 'B', 'C', 'D')),
  comment text,
  reviewed_at timestamptz not null default statement_timestamp(),
  unique (reviewer_id, micro_skill_id, content_fingerprint)
);

alter table public.course_summary_reviews enable row level security;

create index if not exists course_summary_reviews_reviewer_idx
  on public.course_summary_reviews (reviewer_id, reviewed_at desc);

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

  with effective as (
    select ms.id micro_skill_id, ms.code micro_skill_code,
      sub.code subject_code, sub.name subject_name,
      d.code domain_code, d.name domain_name,
      s.code skill_code, s.name skill_name,
      coalesce(nullif(btrim(lr.title), ''), ms.student_name) title,
      coalesce(nullif(btrim(lr.reminder), ''), nullif(btrim(ms.lesson_reminder), ''), '') reminder,
      coalesce(nullif(btrim(lr.worked_example), ''), nullif(btrim(ms.worked_example), ''), '') worked_example,
      lr.id resource_id, lr.version_number resource_version,
      case when lr.id is null then 'micro_skill' else 'learning_resource' end content_source,
      md5(concat_ws(E'\n',
        coalesce(nullif(btrim(lr.title), ''), ms.student_name),
        coalesce(nullif(btrim(lr.reminder), ''), nullif(btrim(ms.lesson_reminder), ''), ''),
        coalesce(nullif(btrim(lr.worked_example), ''), nullif(btrim(ms.worked_example), ''), '')
      )) content_fingerprint,
      sub.sort_order subject_order, d.sort_order domain_order,
      s.sort_order skill_order, ms.sort_order micro_skill_order
    from public.micro_skills ms
    join public.skills s on s.id = ms.skill_id and s.active
    join public.domains d on d.id = s.domain_id and d.active
    join public.subjects sub on sub.id = d.subject_id and sub.active
    join public.micro_skill_levels msl on msl.micro_skill_id = ms.id and msl.is_expected
    join public.levels l on l.id = msl.level_id and l.code = '6e' and l.active
    left join lateral (
      select selected_resource.* from public.learning_resources selected_resource
      where selected_resource.micro_skill_id = ms.id and selected_resource.active
      order by selected_resource.version_number desc, selected_resource.created_at desc limit 1
    ) lr on true
    where ms.active
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'microSkillId', e.micro_skill_id, 'microSkillCode', e.micro_skill_code,
    'subjectCode', e.subject_code, 'subjectName', e.subject_name,
    'domainCode', e.domain_code, 'domainName', e.domain_name,
    'skillCode', e.skill_code, 'skillName', e.skill_name,
    'title', e.title, 'reminder', e.reminder, 'workedExample', e.worked_example,
    'resourceId', e.resource_id, 'resourceVersion', e.resource_version,
    'contentSource', e.content_source, 'fingerprint', e.content_fingerprint,
    'review', case when csr.id is null then null else jsonb_build_object(
      'grade', csr.grade, 'comment', csr.comment, 'reviewedAt', csr.reviewed_at
    ) end
  ) order by e.subject_order, e.domain_order, e.skill_order, e.micro_skill_order, e.title), '[]'::jsonb)
  into payload
  from effective e
  left join public.course_summary_reviews csr
    on csr.micro_skill_id = e.micro_skill_id
   and csr.reviewer_id = auth.uid()
   and csr.content_fingerprint = e.content_fingerprint;
  return payload;
end;
$function$;

create or replace function public.save_course_summary_review(
  requested_micro_skill_id uuid, requested_fingerprint text,
  requested_grade text, requested_comment text default null
)
returns table (grade char(1), reviewed_at timestamptz)
language plpgsql security definer set search_path = ''
as $function$
declare
  selected_resource_id uuid;
  current_fingerprint text;
  saved_grade char(1);
  saved_at timestamptz;
begin
  if auth.uid() is null or not public.can_validate_content() then
    raise exception 'Validator role required';
  end if;
  if requested_grade not in ('A', 'B', 'C', 'D') then
    raise exception 'Grade must be A, B, C or D';
  end if;

  select lr.id, md5(concat_ws(E'\n',
    coalesce(nullif(btrim(lr.title), ''), ms.student_name),
    coalesce(nullif(btrim(lr.reminder), ''), nullif(btrim(ms.lesson_reminder), ''), ''),
    coalesce(nullif(btrim(lr.worked_example), ''), nullif(btrim(ms.worked_example), ''), '')
  ))
  into selected_resource_id, current_fingerprint
  from public.micro_skills ms
  join public.skills s on s.id = ms.skill_id and s.active
  join public.domains d on d.id = s.domain_id and d.active
  join public.subjects sub on sub.id = d.subject_id and sub.active
  left join lateral (
    select selected_resource.* from public.learning_resources selected_resource
    where selected_resource.micro_skill_id = ms.id and selected_resource.active
    order by selected_resource.version_number desc, selected_resource.created_at desc limit 1
  ) lr on true
  where ms.id = requested_micro_skill_id and ms.active
    and exists (
      select 1 from public.micro_skill_levels msl
      join public.levels l on l.id = msl.level_id
      where msl.micro_skill_id = ms.id and msl.is_expected and l.code = '6e' and l.active
    );

  if current_fingerprint is null then raise exception 'Course summary not found'; end if;
  if current_fingerprint <> requested_fingerprint then
    raise exception 'Course summary changed; reload before reviewing';
  end if;

  insert into public.course_summary_reviews
    (micro_skill_id, resource_id, reviewer_id, content_fingerprint, grade, comment)
  values (requested_micro_skill_id, selected_resource_id, auth.uid(), current_fingerprint,
    requested_grade::char(1), nullif(btrim(requested_comment), ''))
  on conflict (reviewer_id, micro_skill_id, content_fingerprint)
  do update set resource_id = excluded.resource_id, grade = excluded.grade,
    comment = excluded.comment, reviewed_at = statement_timestamp()
  returning course_summary_reviews.grade, course_summary_reviews.reviewed_at
  into saved_grade, saved_at;
  return query select saved_grade, saved_at;
end;
$function$;

revoke all on table public.course_summary_reviews from public;
revoke all on function public.get_validation_course_summaries() from public;
revoke all on function public.save_course_summary_review(uuid, text, text, text) from public;
grant execute on function public.get_validation_course_summaries() to authenticated;
grant execute on function public.save_course_summary_review(uuid, text, text, text) to authenticated;
commit;
