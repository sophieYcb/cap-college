with target_comments as (
  select q.legacy_id, v.change_comment
  from public.questions q
  join public.question_versions v
    on v.question_id = q.id
   and v.version_number = q.current_version_number
  where q.legacy_id in (5000448, 5000450)
),
api as (
  select pg_get_functiondef(
    'public.get_validation_question_bank_v3()'::regprocedure
  ) definition
)
select jsonb_build_object(
  'change_comments_saved', (
    select count(*) from target_comments
    where nullif(btrim(change_comment), '') is not null
  ),
  'api_exposes_change_comment', (
    select position('changeComment' in definition) > 0 from api
  ),
  'two_distinct_comments', (
    select count(distinct change_comment) = 2 from target_comments
  )
) verification;