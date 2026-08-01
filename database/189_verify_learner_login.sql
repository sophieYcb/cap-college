select jsonb_build_object(
  'access_code_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'learner_profiles'
      and column_name = 'access_code'
  ),
  'profiles_with_access_code', (
    select count(*) = count(access_code) from public.learner_profiles
  ),
  'sessions_table', to_regclass('public.learner_access_sessions') is not null,
  'open_session_function',
    to_regprocedure('public.open_learner_session(text,text)') is not null,
  'read_session_function',
    to_regprocedure('public.get_learner_session(text)') is not null,
  'close_session_function',
    to_regprocedure('public.close_learner_session(text)') is not null
) as verification;