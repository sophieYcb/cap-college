begin;
do $block$
declare c record; qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid; a record;
begin
 for c in select * from (values
  (5000326,2,'L’âge actuel d’Ana est noté x. Quelle expression donnera son âge dans 5 ans ?',array['5x','x − 5','x/5','x + 5'],4,'Dans 5 ans, son âge actuel aura augmenté de 5 : il sera donc égal à x + 5.','Je suis d’accord avec la remarque : la variable a placée après le prénom Ana produisait la répétition illisible « Ana a a ans ». La variable devient x et sa signification est explicitée.'),
  (5000350,3,'Pour n = 6, l’égalité n(n + 1) = n² + 6 est-elle vraie ?',array['Non, car 42 ≠ 36.','Non, car 36 ≠ 12.','On ne peut pas tester une égalité avec n.','Oui, les deux membres valent 42.'],4,'Pour n = 6, 6 × 7 = 42 et 6² + 6 = 42 : l’égalité est vraie pour cette valeur.','Je suis partiellement d’accord avec la remarque : l’ancienne question était correcte pour tester n = 6, mais n(n + 1) = n² + n est une identité vraie pour toute valeur de n. Le second membre devient n² + 6 afin que la vérité de l’égalité dépende réellement de la valeur testée.')
 ) as x(legacy_id,difficulty,prompt,choices,correct_position,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=source_id and prompt=c.prompt and change_comment=c.change_comment) then continue; end if;
  target_number:=source_number+1; target_id:=md5('cap-college:mathematics-5e-lot-11-feedback:'||c.legacy_id||':v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by) values(target_id,qid,target_number,c.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid());
  for a in select value content,ordinality::smallint sort_order from unnest(c.choices) with ordinality t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order) values(md5('cap-college:mathematics-5e-lot-11-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,target_id,chr(64+a.sort_order),a.content,a.sort_order=c.correct_position,a.sort_order);
  end loop;
  update public.questions set current_version_number=target_number,theoretical_difficulty=c.difficulty::text::public.difficulty_level,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;$block$;
commit;
