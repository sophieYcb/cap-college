begin;
do $block$
declare c record; qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid;
begin
 for c in select * from (values
  (5000448,'Quel point est le symétrique de C(4 ; −3) par rapport à l’origine ?','La symétrie centrale par rapport à l’origine change le signe des deux coordonnées.','Je suis d’accord avec la remarque : l’article élidé « l’ » manquait devant « origine ». L’énoncé et l’explication sont corrigés sans changer la notion ni la réponse.'),
  (5000450,E'[COORDINATES]A=1,1;B=5,1;C=5,4[/COORDINATES]\nDans un repère, les points A(1 ; 1), B(5 ; 1) et C(5 ; 4) sont trois sommets d’un rectangle dont les côtés sont parallèles aux axes. Quelles sont les coordonnées du quatrième sommet D ?','Le quatrième sommet reprend l’abscisse de A et l’ordonnée de C : D(1 ; 4).','Je suis partiellement d’accord : un repère orthonormé n’est pas nécessaire pour déterminer le quatrième sommet, car les coordonnées et le parallélisme aux axes suffisent. En revanche, une illustration rend la question nettement plus accessible ; un repère avec les trois points est donc ajouté et l’énoncé est clarifié.')
 ) as x(legacy_id,prompt,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=source_id and change_comment=c.change_comment) then continue; end if;
  target_number:=source_number+1; target_id:=md5('cap-college:mathematics-5e-lot-14-feedback:'||c.legacy_id||':v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by) values(target_id,qid,target_number,c.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid());
  insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order) select md5('cap-college:mathematics-5e-lot-14-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,target_id,a.choice_key,a.content,a.is_correct,a.sort_order from public.answer_choices a where a.question_version_id=source_id;
  update public.questions set current_version_number=target_number,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;$block$;
commit;