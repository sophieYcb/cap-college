begin;

do $block$
declare
  qid uuid;
  source_number integer;
  source_id uuid;
  target_number integer;
  target_id uuid;
  new_prompt constant text := E'[CODEDTRIANGLE]isosceles[/CODEDTRIANGLE] Quelle égalité est indiquée par les deux traits identiques ?';
  new_explanation constant text := 'Les deux traits identiques sont placés sur [AB] et [AC] : ils indiquent que AB = AC.';
  new_comment constant text := 'Je suis d’accord : les mesures différentes levaient l’ambiguïté, mais elles donnaient un indice trop important. Elles sont retirées ; le triangle reste clairement non équilatéral et seuls les codages utiles sont conservés.';
begin
  select q.id,q.current_version_number,v.id
    into qid,source_number,source_id
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  where q.legacy_id=5000575;

  if qid is null then
    raise exception 'Question 5000575 introuvable.';
  end if;

  if exists(
    select 1
    from public.question_versions
    where id=source_id
      and prompt=new_prompt
      and change_comment=new_comment
  ) then
    return;
  end if;

  if source_number<>2 then
    raise exception 'Version inattendue pour la question 5000575 : %.',source_number;
  end if;

  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-19-feedback-round-2:5000575:v'||target_number)::uuid;

  insert into public.question_versions(
    id,question_id,version_number,prompt,correction_explanation,
    change_comment,review_status,authored_by
  ) values(
    target_id,qid,target_number,new_prompt,new_explanation,
    new_comment,'unreviewed'::public.review_status,auth.uid()
  );

  insert into public.answer_choices(
    id,question_version_id,choice_key,content,is_correct,sort_order
  )
  select
    md5('cap-college:mathematics-5e-lot-19-feedback-round-2:5000575:v'||target_number||':'||a.sort_order)::uuid,
    target_id,a.choice_key,a.content,a.is_correct,a.sort_order
  from public.answer_choices a
  where a.question_version_id=source_id
  order by a.sort_order;

  update public.questions
  set current_version_number=target_number,
      status='in_review'::public.question_status,
      updated_at=statement_timestamp()
  where id=qid;
end;
$block$;

commit;
