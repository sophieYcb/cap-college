begin;
do $block$
declare qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid; a record;
begin
 select q.id,q.current_version_number,v.id into qid,source_number,source_id
 from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
 where q.legacy_id=5000458;
 if qid is null then raise exception 'Question 5000458 introuvable.'; end if;
 if not exists(select 1 from public.question_versions where id=source_id and change_comment='Je suis d’accord : sans quadrillage ni repères avant/arrière, la représentation restait ambiguë. Le dessin est désormais repéré et les propositions sont formulées en toutes lettres.') then
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-15-clarity-feedback:5000458:v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  values(target_id,qid,target_number,E'[CUBESTACK]1,2,1;0,3,2[/CUBESTACK]\nObserve l’empilement posé sur le quadrillage. Quelle proposition décrit sa vue de dessus ? Une case est occupée dès qu’au moins un cube y est posé.',
   'Vue de dessus, les hauteurs ne comptent plus : on regarde seulement si chaque case porte au moins un cube. La case arrière gauche est vide ; les deux autres cases arrière et les trois cases avant sont occupées.',
   'Je suis d’accord : sans quadrillage ni repères avant/arrière, la représentation restait ambiguë. Le dessin est désormais repéré et les propositions sont formulées en toutes lettres.',
   'unreviewed'::public.review_status,auth.uid());
  for a in select value content,ordinality::smallint sort_order from unnest(array[
   'Rangée arrière : 3 cases occupées ; rangée avant : 3 cases occupées.',
   'Rangée arrière : cases gauche et droite occupées ; rangée avant : cases du centre et de droite occupées.',
   'Rangée arrière : 3 cases occupées ; rangée avant : cases du centre et de droite occupées.',
   'Rangée arrière : cases du centre et de droite occupées ; rangée avant : 3 cases occupées.'
  ]) with ordinality t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
   values(md5('cap-college:mathematics-5e-lot-15-clarity-feedback:5000458:v'||target_number||':'||a.sort_order)::uuid,target_id,chr(64+a.sort_order),a.content,a.sort_order=4,a.sort_order);
  end loop;
  update public.questions set current_version_number=target_number,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end if;
end;$block$;
commit;