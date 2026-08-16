begin;
do $block$
declare qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid; a record;
begin
 select q.id,q.current_version_number,v.id into qid,source_number,source_id
 from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 where q.legacy_id=5000489;
 if qid is null then raise exception 'Question 5000489 introuvable.'; end if;
 if not exists(select 1 from public.question_versions where id=source_id and change_comment='Je suis d’accord : l’audit de toutes les banques de mathématiques a trouvé ici les dernières occurrences du symbole « L ». Elles sont harmonisées en « l » minuscule.') then
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-litre-symbol-audit:5000489:v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  values(target_id,qid,target_number,E'[TOOLS]scratch[/TOOLS]\nUn aquarium en forme de pavé droit mesure 40 cm sur 25 cm sur 30 cm. Quelle est sa capacité maximale ? On rappelle que 1 l = 1 000 cm³.',
   '40 × 25 × 30 = 30 000 cm³, soit 30 l.',
   'Je suis d’accord : l’audit de toutes les banques de mathématiques a trouvé ici les dernières occurrences du symbole « L ». Elles sont harmonisées en « l » minuscule.',
   'unreviewed'::public.review_status,auth.uid());
  for a in select value content,ordinality::smallint sort_order from unnest(array['3 l','12 l','30 l','300 l']) with ordinality t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
   values(md5('cap-college:mathematics-litre-symbol-audit:5000489:v'||target_number||':'||a.sort_order)::uuid,target_id,chr(64+a.sort_order),a.content,a.sort_order=3,a.sort_order);
  end loop;
  update public.questions set current_version_number=target_number,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end if;
end;$block$;
commit;