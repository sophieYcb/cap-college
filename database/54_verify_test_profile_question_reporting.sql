select jsonb_build_object(
  'question_reporting_ready',
    to_regprocedure('public.can_report_questions()') is not null,
  'question_flag_api_ready',
    to_regprocedure(
      'public.flag_question_for_review(uuid,uuid,uuid,text)'
    ) is not null,
  'can_report_questions',
    public.can_report_questions()
) as verification;
