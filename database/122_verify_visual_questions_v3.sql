with expected_questions as (
  select q.id, q.legacy_id, q.status, q.current_version_number
  from public.questions q
  where q.legacy_id between 600591 and 600600
     or q.legacy_id between 600611 and 600630
     or q.legacy_id between 600641 and 600680
),
versions as (
  select
    e.id,
    e.legacy_id,
    e.status,
    e.current_version_number,
    qv.id as version_id,
    qv.change_comment
  from expected_questions e
  left join public.question_versions qv
    on qv.question_id = e.id
   and qv.version_number = 3
),
answer_counts as (
  select
    v.id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices
  from versions v
  left join public.answer_choices ac
    on ac.question_version_id = v.version_id
  group by v.id
)
select jsonb_build_object(
  'expected_questions', (select count(*) from expected_questions),
  'version_3_questions', (
    select count(*) from versions
    where version_id is not null
      and current_version_number = 3
  ),
  'questions_in_review', (
    select count(*) from versions where status = 'in_review'
  ),
  'structured_visual_comment_saved', (
    select count(*) from versions
    where change_comment like '%véritable composant visuel structuré%'
  ),
  'questions_with_four_choices', (
    select count(*) from answer_counts where choices = 4
  ),
  'questions_with_one_correct_choice', (
    select count(*) from answer_counts where correct_choices = 1
  ),
  'versions_1_and_2_preserved', (
    select count(*)
    from expected_questions e
    where (
      select count(distinct old.version_number)
      from public.question_versions old
      where old.question_id = e.id
        and old.version_number in (1,2)
    ) = 2
  )
) as verification;
