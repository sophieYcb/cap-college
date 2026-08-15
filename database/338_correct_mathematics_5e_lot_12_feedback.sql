begin;
do $block$
declare c record; qid uuid; sn integer; sid uuid; tn integer; tid uuid; a record;
begin
 for c in select * from (values
  (5000371,1,array['3(x + 4)','3(x + 12)','4(x + 4)','12(x + 1)'],1,'3x + 12 = 3(x + 4).','Je suis d’accord avec la remarque : le coefficient 1 ne s’écrit pas devant une lettre. Toutes les écritures « 1x » de cette question sont remplacées par « x ».'),
  (5000374,1,array['6(x + 18)','7(x + 3)','18(x + 1)','6(x + 3)'],4,'6x + 18 = 6(x + 3).','Je suis d’accord avec la correction implicite déduite de la remarque voisine : « 1x » est remplacé par « x » dans toutes les propositions.'),
  (5000375,2,array['7(x + 2)','7(x + 14)','8(x + 2)','14(x + 1)'],1,'7x + 14 = 7(x + 2).','Je suis d’accord avec la correction implicite déduite de la remarque voisine : le coefficient 1 devant x est supprimé.'),
  (5000378,2,array['9(x + 27)','10(x + 3)','27(x + 1)','9(x + 3)'],4,'9x + 27 = 9(x + 3).','Je suis d’accord avec la correction implicite déduite de la remarque voisine : les écritures algébriques sont normalisées sans « 1x ».'),
  (5000379,3,array['4(x + 1)','4(x + 4)','5(x + 1)','2(2x + 4)'],1,'4x + 4 = 4(x + 1).','Je suis d’accord avec la correction implicite : « 1x » doit devenir « x ». Je corrige également la proposition D, qui était identique à la bonne réponse et créait deux réponses mathématiquement équivalentes.')
 ) as x(legacy_id,difficulty,choices,correct_position,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,sn,sid from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=sid and change_comment=c.change_comment) then continue; end if;
  tn:=sn+1;tid:=md5('cap-college:mathematics-5e-lot-12-feedback:'||c.legacy_id||':v'||tn)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  select tid,qid,tn,v.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid() from public.question_versions v where v.id=sid;
  for a in select value content,ordinality::smallint sort_order from unnest(c.choices) with ordinality t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order) values(md5('cap-college:mathematics-5e-lot-12-feedback:'||c.legacy_id||':v'||tn||':'||a.sort_order)::uuid,tid,chr(64+a.sort_order),a.content,a.sort_order=c.correct_position,a.sort_order);
  end loop;
  update public.questions set current_version_number=tn,theoretical_difficulty=c.difficulty::text::public.difficulty_level,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;$block$;
commit;
