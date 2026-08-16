begin;
do $block$
declare
  legacy integer;
  qid uuid;
  source_number integer;
  source_id uuid;
  target_number integer;
  target_id uuid;
  comment_text text;
  a record;
begin
 foreach legacy in array array[
  5000541,5000542,5000543,5000548,5000551,5000557,
  5000561,5000562,5000563,5000564,5000565,5000566,5000567,5000568
 ] loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id
  from public.questions q
  join public.question_versions v
    on v.question_id=q.id
   and v.version_number=q.current_version_number
  where q.legacy_id=legacy;

  if qid is null then raise exception 'Question % introuvable.',legacy; end if;

  comment_text:=format(
   'Je suis d’accord : la Q%s affichait sa balise graphique au lieu du schéma attendu. Le moteur d’affichage a été corrigé et cette nouvelle version permet de retester la question.',
   legacy
  );

  if exists(
   select 1 from public.question_versions
   where id=source_id and change_comment=comment_text
  ) then continue; end if;

  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-18-visual-retest:'||legacy||':v'||target_number)::uuid;

  insert into public.question_versions(
   id,question_id,version_number,prompt,correction_explanation,
   change_comment,review_status,authored_by
  )
  select
   target_id,qid,target_number,v.prompt,v.correction_explanation,
   comment_text,'unreviewed'::public.review_status,auth.uid()
  from public.question_versions v
  where v.id=source_id;

  for a in
   select content,is_correct,sort_order
   from public.answer_choices
   where question_version_id=source_id
   order by sort_order
  loop
   insert into public.answer_choices(
    id,question_version_id,choice_key,content,is_correct,sort_order
   )
   values(
    md5('cap-college:mathematics-5e-lot-18-visual-retest:'||legacy||':v'||target_number||':'||a.sort_order)::uuid,
    target_id,chr(64+a.sort_order),a.content,a.is_correct,a.sort_order
   );
  end loop;

  update public.questions
  set current_version_number=target_number,
      status='in_review'::public.question_status,
      updated_at=statement_timestamp()
  where id=qid;
 end loop;
end;
$block$;
commit;