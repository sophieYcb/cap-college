/*
===============================================================================
 CAP-COLLEGE DATABASE - CORRECTIONS MATHS 6E / NUMERATION
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/60_correct_maths_6e_numeration.sql
 Purpose      : Apply validator feedback and rebalance correct answer positions.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  correction record;
  selected_question_id uuid;
  source_version_id uuid;
  target_version_id uuid;
  selected_explanation text;
  selected_prompt text;
  selected_target_position smallint;
  answer record;
  target_sort_order smallint;
  target_content text;
begin
  for correction in
    select *
    from (
      values
        (600003::bigint, null::text, 1::smallint),
        (600005::bigint, null::text, 4::smallint),
        (600007::bigint, null::text, 1::smallint),
        (600008::bigint, null::text, 4::smallint),
        (600011::bigint, 'Dans le nombre « 7,35 », quel est le rang du chiffre 3 ?', 1::smallint),
        (600012::bigint, 'Dans le nombre « 12,408 », quel est le rang du chiffre 8 ?', null::smallint),
        (600013::bigint, 'Dans le nombre « 5,72 », quelle est la valeur du chiffre 7 ?', 4::smallint),
        (600014::bigint, 'Dans le nombre « 48,063 », quelle est la valeur du chiffre 6 ?', 4::smallint),
        (600015::bigint, 'Dans le nombre « 0,529 », quel chiffre occupe le rang des centièmes ?', null::smallint),
        (600016::bigint, 'Dans le nombre « 103,407 », quelle est la valeur du chiffre 7 ?', null::smallint),
        (600019::bigint, 'Dans le nombre « 905,070 », quelle position occupe le premier chiffre 0 placé après la virgule ?', 4::smallint),
        (600022::bigint, null::text, 1::smallint),
        (600023::bigint, null::text, 4::smallint),
        (600024::bigint, null::text, 4::smallint),
        (600025::bigint, null::text, 1::smallint),
        (600026::bigint, null::text, 4::smallint),
        (600027::bigint, null::text, 4::smallint),
        (600031::bigint, null::text, 1::smallint),
        (600032::bigint, null::text, 4::smallint),
        (600033::bigint, null::text, 4::smallint),
        (600034::bigint, null::text, 1::smallint),
        (600035::bigint, null::text, 4::smallint),
        (600036::bigint, null::text, 4::smallint),
        (600053::bigint, null::text, 4::smallint),
        (600054::bigint, 'Quel résultat exact obtient-on en calculant 7 ÷ 20 ?', null::smallint),
        (600058::bigint, 'Lequel de ces quotients a une écriture à virgule qui s’arrête ?', 1::smallint),
        (600061::bigint, null::text, 4::smallint)
    ) as requested(legacy_id, replacement_prompt, correct_position)
  loop
    select
      question.id,
      version.id,
      version.prompt,
      version.correction_explanation
    into
      selected_question_id,
      source_version_id,
      selected_prompt,
      selected_explanation
    from public.questions question
    join public.question_versions version
      on version.question_id = question.id
     and version.version_number = 1
    where question.legacy_id = correction.legacy_id;

    if selected_question_id is null then
      raise exception 'Question % introuvable', correction.legacy_id;
    end if;

    target_version_id :=
      md5('cap-college:maths-6e-numeration-correction:v2:' ||
          correction.legacy_id)::uuid;

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
      selected_question_id,
      2,
      coalesce(correction.replacement_prompt, selected_prompt),
      selected_explanation,
      'Corrections après validation des 80 questions de numération et rééquilibrage A/B/C/D.',
      'unreviewed'::public.review_status,
      auth.uid()
    )
    on conflict (question_id, version_number) do update
    set prompt = excluded.prompt,
        correction_explanation = excluded.correction_explanation,
        change_comment = excluded.change_comment,
        review_status = excluded.review_status;

    select choice.sort_order
    into selected_target_position
    from public.answer_choices choice
    where choice.question_version_id = source_version_id
      and choice.is_correct;

    delete from public.answer_choices
    where question_version_id = target_version_id;

    for answer in
      select *
      from public.answer_choices
      where question_version_id = source_version_id
      order by sort_order
    loop
      target_sort_order := case
        when correction.correct_position is null then answer.sort_order
        when answer.is_correct then correction.correct_position
        when answer.sort_order = correction.correct_position
          then selected_target_position
        else answer.sort_order
      end;

      target_content := case
        when correction.legacy_id = 600019 and target_sort_order = 1 then 'unités'
        when correction.legacy_id = 600019 and target_sort_order = 2 then 'millièmes'
        when correction.legacy_id = 600019 and target_sort_order = 3 then 'centièmes'
        when correction.legacy_id = 600019 and target_sort_order = 4 then 'dixièmes'
        else answer.content
      end;

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
          'cap-college:maths-6e-numeration-correction:v2:' ||
          correction.legacy_id || ':' || target_sort_order
        )::uuid,
        target_version_id,
        chr(64 + target_sort_order),
        target_content,
        answer.is_correct,
        target_sort_order
      );
    end loop;

    update public.questions
    set current_version_number = 2,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected_question_id;
  end loop;
end;
$block$;

commit;
