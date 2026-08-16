begin;
do $block$
declare qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid;
begin
 select q.id,q.current_version_number,v.id into qid,source_number,source_id
 from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 where q.legacy_id=5000489;
 if qid is null then raise exception 'Question 5000489 introuvable.'; end if;
 if not exists(select 1 from public.question_versions where id=source_id and change_comment='Je suis d’accord : la règle d’utilisation du matériel doit être explicite. Cette question conseille désormais le brouillon, sans autoriser la calculatrice car le calcul mental 40 × 25 = 1 000 fait partie de la stratégie attendue.') then
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-15-tools:5000489:v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  select target_id,qid,target_number,E'[TOOLS]scratch[/TOOLS]\nUn aquarium en forme de pavé droit mesure 40 cm sur 25 cm sur 30 cm. Quelle est sa capacité maximale ? On rappelle que 1 L = 1 000 cm³.',v.correction_explanation,
   'Je suis d’accord : la règle d’utilisation du matériel doit être explicite. Cette question conseille désormais le brouillon, sans autoriser la calculatrice car le calcul mental 40 × 25 = 1 000 fait partie de la stratégie attendue.','unreviewed'::public.review_status,auth.uid()
  from public.question_versions v where v.id=source_id;
  insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
  select md5('cap-college:mathematics-5e-lot-15-tools:5000489:v'||target_number||':'||a.sort_order)::uuid,target_id,a.choice_key,a.content,a.is_correct,a.sort_order
  from public.answer_choices a where a.question_version_id=source_id;
  update public.questions set current_version_number=target_number,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end if;
end;$block$;
commit;