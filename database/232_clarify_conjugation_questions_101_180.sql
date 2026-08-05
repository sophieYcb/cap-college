/*
 CAP-COLLEGE DATABASE
 File: database/232_clarify_conjugation_questions_101_180.sql
 Purpose: Explicitly state the requested tense in questions 101 through 180.
 Idempotent: Yes
*/

begin;

do $block$
declare
  question_record record;
  source_version record;
  source_choice record;
  target_version_number integer;
  target_version_id uuid;
  base_prompt text;
  desired_prompt text;
  tense_suffix text;
  corrected_count integer := 0;
begin
  for question_record in
    select q.id, q.legacy_id, q.current_version_number
    from public.questions q
    where q.legacy_id between 101 and 180
    order by q.legacy_id
  loop
    select qv.*
    into source_version
    from public.question_versions qv
    where qv.question_id = question_record.id
      and qv.version_number = question_record.current_version_number;

    if source_version.id is null then
      raise exception
        'Current version missing for question %.',
        question_record.legacy_id;
    end if;

    if source_version.prompt not like 'Conjugue le verbe %' then
      raise exception
        'Unexpected prompt for question %: %',
        question_record.legacy_id,
        source_version.prompt;
    end if;

    tense_suffix := case
      when question_record.legacy_id between 101 and 120
        then ' au présent de l''indicatif'
      when question_record.legacy_id between 121 and 140
        then ' à l''imparfait de l''indicatif'
      when question_record.legacy_id between 141 and 160
        then ' au futur simple de l''indicatif'
      when question_record.legacy_id between 161 and 180
        then ' au passé composé de l''indicatif'
    end;

    base_prompt := regexp_replace(
      source_version.prompt,
      '\s+(au présent de l''indicatif|à l''imparfait de l''indicatif|au futur simple de l''indicatif|au passé composé de l''indicatif)\.$',
      '.'
    );
    desired_prompt :=
      regexp_replace(base_prompt, '\.$', '')
      || tense_suffix || '.';

    if source_version.prompt = desired_prompt then
      continue;
    end if;

    target_version_number :=
      question_record.current_version_number + 1;
    target_version_id := md5(
      'cap-college:clarify-conjugation:'
      || question_record.legacy_id
      || ':v' || target_version_number
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
      question_record.id,
      target_version_number,
      desired_prompt,
      source_version.correction_explanation,
      'Le temps de conjugaison demandé est désormais explicite afin d''éviter plusieurs réponses grammaticalement possibles.',
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
        id,
        question_version_id,
        choice_key,
        content,
        is_correct,
        sort_order
      )
      values (
        md5(
          'cap-college:clarify-conjugation:'
          || question_record.legacy_id
          || ':v' || target_version_number
          || ':' || source_choice.sort_order
        )::uuid,
        target_version_id,
        source_choice.choice_key,
        source_choice.content,
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

  if corrected_count not in (0, 79) then
    raise exception
      'Expected 0 or 79 corrections, % were prepared.',
      corrected_count;
  end if;
end;
$block$;

commit;
