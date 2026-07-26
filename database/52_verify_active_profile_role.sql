select jsonb_build_object(
  'active_role_table_ready', to_regclass('public.user_active_roles') is not null,
  'active_role_reader_ready',
    to_regprocedure('public.get_my_active_role()') is not null,
  'active_role_switcher_ready',
    to_regprocedure('public.set_my_active_role(text)') is not null,
  'question_reporting_ready',
    to_regprocedure('public.can_report_questions()') is not null,
  'can_report_questions', public.can_report_questions(),
  'assigned_roles', public.get_my_roles(),
  'active_role', public.get_my_active_role()
) as verification;
