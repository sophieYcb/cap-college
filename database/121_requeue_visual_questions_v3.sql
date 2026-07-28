/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/121_requeue_visual_questions_v3.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Create a new reviewable version for the 70 questions whose
                tables and charts now use the structured visual renderer.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  selected record;
  answer record;
  target_version_id uuid;
begin
  for selected in
    select
      q.id as question_id,
      q.legacy_id,
      qv.prompt,
      qv.correction_explanation
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = 2
    where q.legacy_id between 600591 and 600600
       or q.legacy_id between 600611 and 600630
       or q.legacy_id between 600641 and 600680
    order by q.legacy_id
  loop
    target_version_id := md5(
      'cap-college:structured-visuals:' || selected.legacy_id || ':v3'
    )::uuid;

    insert into public.question_versions (
      id,
      question_id,
      version_number,
      prompt,
      correction_explanation,
      change_comment,
      review_status,
      authored_by
    )
    values (
      target_version_id,
      selected.question_id,
      3,
      selected.prompt,
      selected.correction_explanation,
      'Le tableau ou graphique est désormais rendu comme un véritable composant visuel structuré dans le diagnostic et le mode Validation.',
      'unreviewed'::public.review_status,
      auth.uid()
    )
    on conflict (question_id, version_number) do update
    set prompt = excluded.prompt,
        correction_explanation = excluded.correction_explanation,
        change_comment = excluded.change_comment,
        review_status = excluded.review_status
    returning id into target_version_id;

    delete from public.answer_choices
    where question_version_id = target_version_id;

    for answer in
      select content, is_correct, sort_order
      from public.answer_choices
      where question_version_id = (
        select id
        from public.question_versions
        where question_id = selected.question_id
          and version_number = 2
      )
      order by sort_order
    loop
      insert into public.answer_choices (
        id,
        question_version_id,
        choice_key,
        content,
        is_correct,
        sort_order
      )
      values (
        md5(
          'cap-college:structured-visuals:' ||
          selected.legacy_id || ':v3:' || answer.sort_order
        )::uuid,
        target_version_id,
        chr(64 + answer.sort_order),
        answer.content,
        answer.is_correct,
        answer.sort_order
      );
    end loop;

    update public.questions
    set current_version_number = 3,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected.question_id;
  end loop;
end;
$block$;

commit;
