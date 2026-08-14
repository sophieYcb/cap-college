/*
 CAP-COLLEGE DATABASE
 File: database/292_verify_skipped_diagnostic_questions.sql
 Purpose: Verify support for deliberately skipped diagnostic questions.
 Read-only: Yes.
*/

with function_checks as (
  select
    to_regprocedure(
      'public.submit_diagnostic_answer(uuid,uuid,uuid,integer)'
    ) is not null as adult_function,
    to_regprocedure(
      'public.submit_learner_diagnostic_answer(text,uuid,uuid,uuid,integer)'
    ) is not null as learner_function,
    pg_get_functiondef(
      'public.submit_diagnostic_answer(uuid,uuid,uuid,integer)'::regprocedure
    ) like '%requested_choice_id is not null and not exists%'
      as adult_accepts_null_choice,
    pg_get_functiondef(
      'public.submit_learner_diagnostic_answer(text,uuid,uuid,uuid,integer)'::regprocedure
    ) like '%requested_choice_id is not null and not exists%'
      as learner_accepts_null_choice,
    pg_get_functiondef(
      'public.submit_diagnostic_answer(uuid,uuid,uuid,integer)'::regprocedure
    ) like '%answer_is_correct := requested_choice_id is not null%'
      as adult_skip_is_incorrect,
    pg_get_functiondef(
      'public.submit_learner_diagnostic_answer(text,uuid,uuid,uuid,integer)'::regprocedure
    ) like '%answer_is_correct := requested_choice_id is not null%'
      as learner_skip_is_incorrect
),
column_check as (
  select is_nullable = 'YES' as selected_choice_is_nullable
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'diagnostic_items'
    and column_name = 'selected_choice_id'
)
select jsonb_build_object(
  'adult_function', function_checks.adult_function,
  'learner_function', function_checks.learner_function,
  'adult_accepts_skipped_question', function_checks.adult_accepts_null_choice,
  'learner_accepts_skipped_question', function_checks.learner_accepts_null_choice,
  'skipped_questions_count_as_incorrect',
    function_checks.adult_skip_is_incorrect
    and function_checks.learner_skip_is_incorrect,
  'selected_choice_is_nullable', coalesce(column_check.selected_choice_is_nullable, false),
  'anonymous_can_execute', has_function_privilege(
    'anon',
    'public.submit_learner_diagnostic_answer(text,uuid,uuid,uuid,integer)',
    'execute'
  ),
  'authenticated_can_execute', has_function_privilege(
    'authenticated',
    'public.submit_diagnostic_answer(uuid,uuid,uuid,integer)',
    'execute'
  )
) as verification
from function_checks
left join column_check on true;
