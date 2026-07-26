/*
===============================================================================
 CAP-COLLEGE DATABASE - DRAFT CONTENT IMPORT API
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/46_draft_content_import_api.sql
 Purpose      : Reusable administrator import for versioned question lots.
 Idempotent   : Yes for a given question code.
===============================================================================
*/

begin;

create or replace function public.import_draft_question_lot(
  requested_payload jsonb
)
returns table (
  imported_micro_skills integer,
  imported_questions integer,
  imported_choices integer
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_subject_id smallint;
  selected_level_id smallint;
  selected_domain_id uuid;
  selected_skill_id uuid;
  micro_count integer;
  question_count integer;
  choice_count integer;
begin
  if auth.uid() is null or not public.has_role('administrator') then
    raise exception 'Administrator role required';
  end if;

  if requested_payload ->> 'format' <> 'cap-college-question-draft-v1' then
    raise exception 'Unsupported content format';
  end if;

  select s.id into selected_subject_id
  from public.subjects s
  where s.code = requested_payload ->> 'subject' and s.active;

  select l.id into selected_level_id
  from public.levels l
  where l.code = requested_payload ->> 'level' and l.active;

  if selected_subject_id is null or selected_level_id is null then
    raise exception 'Unknown subject or level';
  end if;

  if jsonb_array_length(coalesce(requested_payload -> 'microSkills', '[]')) = 0
     or jsonb_array_length(coalesce(requested_payload -> 'questions', '[]')) = 0 then
    raise exception 'The lot must contain micro-skills and questions';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(requested_payload -> 'questions') q(item)
    where (q.item ->> 'code') !~ '^M6-[0-9]{4,}$'
       or jsonb_array_length(q.item -> 'choices') <> 4
       or (q.item ->> 'correctIndex')::integer not between 0 and 3
       or (q.item ->> 'difficulty')::integer not between 1 and 3
  ) then
    raise exception 'Every question needs four choices, one valid answer and difficulty 1-3';
  end if;

  selected_domain_id :=
    md5(
      'cap-college:domain:' ||
      (requested_payload ->> 'subject') || ':' ||
      (requested_payload -> 'domain' ->> 'code')
    )::uuid;

  insert into public.domains (
    id, subject_id, code, name, description, sort_order, active
  )
  values (
    selected_domain_id,
    selected_subject_id,
    requested_payload -> 'domain' ->> 'code',
    requested_payload -> 'domain' ->> 'name',
    'Domaine du programme officiel importé par lot.',
    1,
    true
  )
  on conflict (subject_id, code) do update
  set name = excluded.name, active = true
  returning id into selected_domain_id;

  selected_skill_id :=
    md5(
      'cap-college:skill:' ||
      (requested_payload ->> 'subject') || ':' ||
      (requested_payload -> 'skill' ->> 'code')
    )::uuid;

  insert into public.skills (
    id, domain_id, code, name, description, sort_order, active
  )
  values (
    selected_skill_id,
    selected_domain_id,
    requested_payload -> 'skill' ->> 'code',
    requested_payload -> 'skill' ->> 'name',
    'Compétence structurée en micro-compétences atomiques.',
    1,
    true
  )
  on conflict (domain_id, code) do update
  set name = excluded.name, active = true
  returning id into selected_skill_id;

  insert into public.micro_skills (
    id, skill_id, code, teacher_name, student_name, description,
    lesson_reminder, worked_example, mastery_criteria, sort_order,
    active, created_by
  )
  select
    md5('cap-college:micro-skill:' || (m.item ->> 'code'))::uuid,
    selected_skill_id,
    m.item ->> 'code',
    m.item ->> 'teacherName',
    m.item ->> 'studentName',
    'Micro-compétence atomique de mathématiques 6e.',
    nullif(m.item ->> 'lessonReminder', ''),
    nullif(m.item ->> 'workedExample', ''),
    nullif(m.item ->> 'masteryCriteria', ''),
    m.ordinality::smallint,
    true,
    auth.uid()
  from jsonb_array_elements(requested_payload -> 'microSkills')
       with ordinality as m(item, ordinality)
  on conflict (code) do update
  set teacher_name = excluded.teacher_name,
      student_name = excluded.student_name,
      lesson_reminder = excluded.lesson_reminder,
      worked_example = excluded.worked_example,
      mastery_criteria = excluded.mastery_criteria,
      active = true;

  get diagnostics micro_count = row_count;

  insert into public.micro_skill_levels (micro_skill_id, level_id, is_expected)
  select ms.id, selected_level_id, true
  from public.micro_skills ms
  where ms.code in (
    select m.item ->> 'code'
    from jsonb_array_elements(requested_payload -> 'microSkills') m(item)
  )
  on conflict (micro_skill_id, level_id) do update
  set is_expected = true;

  insert into public.questions (
    id, legacy_id, micro_skill_id, status, theoretical_difficulty,
    current_version_number, active, created_by
  )
  select
    md5('cap-college:question:' || (q.item ->> 'code'))::uuid,
    (
      600000 +
      substring(q.item ->> 'code' from '([0-9]+)$')::bigint
    ),
    ms.id,
    'in_review'::public.question_status,
    (q.item ->> 'difficulty')::public.difficulty_level,
    1,
    true,
    auth.uid()
  from jsonb_array_elements(requested_payload -> 'questions') q(item)
  join public.micro_skills ms on ms.code = q.item ->> 'microSkill'
  on conflict (legacy_id) do update
  set micro_skill_id = excluded.micro_skill_id,
      theoretical_difficulty = excluded.theoretical_difficulty,
      active = true,
      updated_at = statement_timestamp();

  get diagnostics question_count = row_count;

  insert into public.question_versions (
    id, question_id, version_number, prompt, correction_explanation,
    change_comment, review_status, authored_by
  )
  select
    md5('cap-college:question-version:' || (q.item ->> 'code') || ':1')::uuid,
    question_row.id,
    1,
    q.item ->> 'prompt',
    nullif(q.item ->> 'explanation', ''),
    'Création depuis le lot ' || coalesce(requested_payload ->> 'lot', 'sans nom'),
    'unreviewed'::public.review_status,
    auth.uid()
  from jsonb_array_elements(requested_payload -> 'questions') q(item)
  join public.questions question_row
    on question_row.legacy_id =
       600000 + substring(q.item ->> 'code' from '([0-9]+)$')::bigint
  on conflict (question_id, version_number) do update
  set prompt = excluded.prompt,
      correction_explanation = excluded.correction_explanation,
      change_comment = excluded.change_comment;

  update public.answer_choices ac
  set is_correct = false
  where ac.question_version_id in (
    select
      md5(
        'cap-college:question-version:' || (q.item ->> 'code') || ':1'
      )::uuid
    from jsonb_array_elements(requested_payload -> 'questions') q(item)
  );

  insert into public.answer_choices (
    id, question_version_id, choice_key, content, is_correct, sort_order
  )
  select
    md5(
      'cap-college:choice:' || (q.item ->> 'code') || ':1:' ||
      choice_index::text
    )::uuid,
    qv.id,
    chr(65 + choice_index),
    q.item -> 'choices' ->> choice_index,
    choice_index = (q.item ->> 'correctIndex')::integer,
    (choice_index + 1)::smallint
  from jsonb_array_elements(requested_payload -> 'questions') q(item)
  cross join generate_series(0, 3) choice_index
  join public.question_versions qv
    on qv.id =
       md5('cap-college:question-version:' || (q.item ->> 'code') || ':1')::uuid
  on conflict (question_version_id, choice_key) do update
  set content = excluded.content,
      is_correct = excluded.is_correct,
      sort_order = excluded.sort_order;

  get diagnostics choice_count = row_count;

  return query select micro_count, question_count, choice_count;
end;
$function$;

revoke all on function public.import_draft_question_lot(jsonb) from public;
grant execute on function public.import_draft_question_lot(jsonb)
  to authenticated;

commit;
