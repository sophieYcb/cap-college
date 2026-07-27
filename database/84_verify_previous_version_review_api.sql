select jsonb_build_object(
  'previous_version_review_api_ready',
  to_regprocedure(
    'public.get_validation_question_bank_v3()'
  ) is not null,
  'question_600241_previous_review_visible',
  exists (
    select 1
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number - 1
    join public.question_reviews qr
      on qr.question_version_id = qv.id
    where q.legacy_id = 600241
      and qr.campaign_id is null
      and qr.grade = 'B'
      and nullif(btrim(qr.comment), '') is not null
  ),
  'question_600259_previous_review_visible',
  exists (
    select 1
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = q.current_version_number - 1
    join public.question_reviews qr
      on qr.question_version_id = qv.id
    where q.legacy_id = 600259
      and qr.campaign_id is null
      and qr.grade = 'B'
      and nullif(btrim(qr.comment), '') is not null
  )
) as verification;
