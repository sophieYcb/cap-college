with expected as (
  select distinct
    ms.id micro_skill_id,
    ms.code micro_skill_code,
    sub.name subject_name,
    ms.student_name initial_title,
    coalesce(ms.lesson_reminder, '') initial_reminder,
    coalesce(ms.worked_example, '') initial_example
  from public.micro_skills ms
  join public.skills s on s.id = ms.skill_id and s.active
  join public.domains d on d.id = s.domain_id and d.active
  join public.subjects sub on sub.id = d.subject_id and sub.active
  join public.micro_skill_levels msl on msl.micro_skill_id = ms.id and msl.is_expected
  join public.levels l on l.id = msl.level_id and l.code = '6e' and l.active
  where ms.active
), resource_counts as (
  select lr.micro_skill_id,
    count(*) filter (where lr.active) active_resources,
    count(*) total_versions
  from public.learning_resources lr
  join expected e on e.micro_skill_id = lr.micro_skill_id
  group by lr.micro_skill_id
), effective as (
  select e.*,
    lr.id resource_id,
    lr.version_number resource_version,
    coalesce(nullif(btrim(lr.title), ''), e.initial_title) title,
    coalesce(nullif(btrim(lr.reminder), ''), nullif(btrim(e.initial_reminder), ''), '') reminder,
    coalesce(nullif(btrim(lr.worked_example), ''), nullif(btrim(e.initial_example), ''), '') worked_example,
    coalesce(rc.active_resources, 0) active_resources,
    coalesce(rc.total_versions, 0) total_versions
  from expected e
  left join resource_counts rc on rc.micro_skill_id = e.micro_skill_id
  left join lateral (
    select selected_resource.*
    from public.learning_resources selected_resource
    where selected_resource.micro_skill_id = e.micro_skill_id
      and selected_resource.active
    order by selected_resource.version_number desc, selected_resource.created_at desc
    limit 1
  ) lr on true
), fingerprinted as (
  select e.*,
    md5(concat_ws(E'\n', e.title, e.reminder, e.worked_example)) content_fingerprint
  from effective e
), audited as (
  select f.*,
    exists (
      select 1
      from public.course_summary_reviews csr
      where csr.micro_skill_id = f.micro_skill_id
        and csr.content_fingerprint = f.content_fingerprint
        and csr.grade = 'A'
    ) current_content_has_a,
    coalesce((
      select jsonb_object_agg(review_grade, review_count order by review_grade)
      from (
        select csr.grade::text review_grade, count(*) review_count
        from public.course_summary_reviews csr
        where csr.micro_skill_id = f.micro_skill_id
          and csr.content_fingerprint = f.content_fingerprint
        group by csr.grade
      ) grades
    ), '{}'::jsonb) current_grade_distribution
  from fingerprinted f
)
select jsonb_build_object('verification', jsonb_build_object(
  'expected_micro_skills', (select count(*) from audited),
  'subjects', coalesce((
    select jsonb_agg(jsonb_build_object(
      'subject', subject_name,
      'summaries', summaries,
      'complete', complete,
      'validated_a', validated_a
    ) order by subject_name)
    from (
      select subject_name,
        count(*) summaries,
        count(*) filter (where btrim(reminder) <> '' and btrim(worked_example) <> '') complete,
        count(*) filter (where current_content_has_a) validated_a
      from audited
      group by subject_name
    ) subject_totals
  ), '[]'::jsonb),
  'complete_summaries', (select count(*) from audited where btrim(reminder) <> '' and btrim(worked_example) <> ''),
  'current_contents_validated_a', (select count(*) from audited where current_content_has_a),
  'micro_skills_with_resource_history', (select count(*) from audited where total_versions > 1),
  'micro_skills_without_learning_resource', (select count(*) from audited where total_versions = 0),
  'multiple_active_resource_codes', coalesce((
    select jsonb_agg(micro_skill_code order by micro_skill_code)
    from audited where active_resources > 1
  ), '[]'::jsonb),
  'incomplete_summary_codes', coalesce((
    select jsonb_agg(micro_skill_code order by micro_skill_code)
    from audited where btrim(reminder) = '' or btrim(worked_example) = ''
  ), '[]'::jsonb),
  'missing_current_a_review_codes', coalesce((
    select jsonb_agg(jsonb_build_object(
      'code', micro_skill_code,
      'subject', subject_name,
      'version', resource_version,
      'current_grades', current_grade_distribution
    ) order by micro_skill_code)
    from audited where not current_content_has_a
  ), '[]'::jsonb),
  'audit_passed',
    (select count(*) = 159 from audited)
    and not exists (select 1 from audited where btrim(reminder) = '' or btrim(worked_example) = '')
    and not exists (select 1 from audited where active_resources > 1)
    and not exists (select 1 from audited where not current_content_has_a)
)) as verification;