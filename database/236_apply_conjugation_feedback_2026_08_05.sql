/*
 CAP-COLLEGE DATABASE
 File: database/236_apply_conjugation_feedback_2026_08_05.sql
 Purpose: Apply validator feedback to conjugation questions 172 and 176.
 Idempotent: Yes
*/

begin;

do $block$
declare
  correction record;
  question_record record;
  source_version record;
  source_choice record;
  target_version_number integer;
  target_version_id uuid;
  corrected_count integer := 0;
begin
  for correction in
    select *
    from (values
      (172, 4::smallint, 'sont parti'::text,
       'La proposition D reprend l''erreur d''accord demandée par la validation.'::text),
      (176, 1::smallint, 'avons choisis'::text,
       'La proposition A reprend l''erreur d''accord demandée par la validation.'::text)
    ) as data(legacy_id, choice_position, replacement_content, change_comment)
  loop
    select q.id, q.current_version_number
    into question_record
    from public.questions q
    where q.legacy_id = correction.legacy_id;

    if question_record.id is null then
      raise exception 'Question % introuvable.', correction.legacy_id;
    end if;

    select qv.*
    into source_version
    from public.question_versions qv
    where qv.question_id = question_record.id
      and qv.version_number = question_record.current_version_number;

    if exists (
      select 1
      from public.answer_choices choice
      where choice.question_version_id = source_version.id
        and choice.sort_order = correction.choice_position
        and choice.content = correction.replacement_content
    ) then
      continue;
    end if;

    target_version_number := question_record.current_version_number + 1;
    target_version_id := md5(
      'cap-college:conjugation-feedback-2026-08-05:'
      || correction.legacy_id
      || ':v' || target_version_number
    )::uuid;

    insert into public.question_versions (
      id, question_id, version_number, prompt, correction_explanation,
      change_comment, review_status, authored_by
    )
    values (
      target_version_id,
      question_record.id,
      target_version_number,
      source_version.prompt,
      source_version.correction_explanation,
      correction.change_comment,
      'unreviewed'::public.review_status,
      auth.uid()
    );

    for source_choice in
      select choice.*
      from public.answer_choices choice
      where choice.question_version_id = source_version.id
      order by choice.sort_order
    loop
      insert into public.answer_choices (
        id, question_version_id, choice_key, content, is_correct, sort_order
      )
      values (
        md5(
          'cap-college:conjugation-feedback-2026-08-05:'
          || correction.legacy_id
          || ':v' || target_version_number
          || ':' || source_choice.sort_order
        )::uuid,
        target_version_id,
        source_choice.choice_key,
        case
          when source_choice.sort_order = correction.choice_position
            then correction.replacement_content
          else source_choice.content
        end,
        source_choice.is_correct,
        source_choice.sort_order
      );
    end loop;

    update public.questions
    set current_version_number = target_version_number,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = question_record.id;

    corrected_count := corrected_count + 1;
  end loop;

  if corrected_count not in (0, 2) then
    raise exception 'Expected 0 or 2 corrections, % were prepared.', corrected_count;
  end if;
end;
$block$;

commit;
