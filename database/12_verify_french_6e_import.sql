/*
===============================================================================
 CAP-COLLEGE DATABASE — CONTENT VERIFICATION
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : 12_verify_french_6e_import.sql
 Purpose      : Read-only verification of the French 6e content migration.
 Dependencies : 11_import_french_6e.sql
 Mutates data : No
===============================================================================
*/

with imported_questions as (
  select q.*
  from public.questions q
  where q.legacy_id between 1 and 590
),
imported_versions as (
  select qv.*
  from public.question_versions qv
  join imported_questions q on q.id = qv.question_id
),
imported_choices as (
  select ac.*
  from public.answer_choices ac
  join imported_versions qv on qv.id = ac.question_version_id
)
select
  (select count(*) from public.domains d
    join public.subjects s on s.id = d.subject_id
    where s.code = 'french') as domains,
  (select count(*) from public.micro_skills
    where code like 'legacy_%') as provisional_micro_skills,
  (select count(*) from imported_questions) as questions,
  (select count(*) from imported_versions) as versions,
  (select count(*) from imported_choices) as choices,
  (select count(*) from imported_choices where is_correct) as correct_choices,
  (select count(*) from imported_questions
    where status = 'in_review') as questions_to_review,
  (select count(*) from imported_questions
    where current_version_number > 1) as questions_with_history;
