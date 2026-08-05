select jsonb_build_object(
  'history_function',
    to_regprocedure(
      'public.get_my_learner_session_history(uuid)'
    ) is not null,
  'authenticated_can_execute',
    has_function_privilege(
      'authenticated',
      'public.get_my_learner_session_history(uuid)',
      'EXECUTE'
    ),
  'adult_links_table',
    to_regclass('public.learner_profile_adults') is not null
) as verification;
