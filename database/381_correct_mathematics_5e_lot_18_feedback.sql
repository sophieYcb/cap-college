begin;
do $block$
declare c record; qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid; a record;
begin
 for c in select * from (values
  (5000569,3,'Deux droites sont coupées par une sécante. Deux angles alternes-internes ont la même mesure. Que peut-on conclure ?',array['Les deux droites sont parallèles.','Les deux droites sont perpendiculaires.','La sécante est une bissectrice.','On ne peut rien conclure.'],1,'Si deux angles alternes-internes ont la même mesure, alors les deux droites sont parallèles.','Je suis d’accord : la formulation « une paire d’angles est égale » était maladroite. On précise désormais que les deux angles ont la même mesure, puis on demande la conclusion.'),
  (5000570,3,'Deux droites coupées par une sécante ne sont pas parallèles. Leurs angles correspondants sont-ils nécessairement égaux ?',array['Oui, ils sont toujours égaux.','Non, ils ne sont pas nécessairement égaux.','Oui, mais seulement s’ils sont aigus.','Oui, mais seulement s’ils mesurent 90°.'],2,'Non. L’égalité des angles correspondants est garantie lorsque les deux droites sont parallèles.','Je suis d’accord : la question était mathématiquement juste mais posée de façon trop indirecte. Elle devient une question fermée, plus naturelle à lire.')
 ) as x(legacy_id,difficulty,prompt,choices,correct_position,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id
  from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
  where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=source_id and prompt=c.prompt and change_comment=c.change_comment) then continue; end if;
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-18-feedback:'||c.legacy_id||':v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  values(target_id,qid,target_number,c.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid());
  for a in select value content,ordinality::smallint sort_order from unnest(c.choices) with ordinality t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
   values(md5('cap-college:mathematics-5e-lot-18-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,target_id,chr(64+a.sort_order),a.content,a.sort_order=c.correct_position,a.sort_order);
  end loop;
  update public.questions set current_version_number=target_number,theoretical_difficulty=c.difficulty::text::public.difficulty_level,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;$block$;
commit;