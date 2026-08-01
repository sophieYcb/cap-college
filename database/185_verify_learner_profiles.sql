select jsonb_build_object(
  'learner_profiles_table', to_regclass('public.learner_profiles') is not null,
  'adult_links_table', to_regclass('public.learner_profile_adults') is not null,
  'create_function', to_regprocedure('public.create_my_learner_profile(text,text,text)') is not null,
  'list_function', to_regprocedure('public.get_my_learner_profiles()') is not null,
  'pin_hash_column', exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'learner_profiles'
      and column_name = 'pin_hash'
  )
) as verification;