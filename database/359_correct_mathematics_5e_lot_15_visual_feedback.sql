begin;
do $block$
declare c record; qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid;
begin
 for c in select * from (values
  (5000451,E'[CUBESTACK]2,1;0,3[/CUBESTACK]\nObserve cet empilement. Combien contient-il de cubes ?','On compte 2 + 1 + 3 = 6 cubes.','Je suis d’accord : le rendu précédent masquait visuellement un cube et pouvait faire compter 5 au lieu de 6. Les colonnes sont désormais espacées pour rendre chaque cube visible.'),
  (5000453,E'[CUBESTACK]2,0,1;0,3,1[/CUBESTACK]\nCombien de colonnes de cubes cet empilement comporte-t-il ?','On repère quatre colonnes non vides dans l’empilement.','Je suis d’accord : la mention « Avant » et sa flèche étaient inutiles pour dénombrer les colonnes. Elles sont supprimées et les colonnes sont mieux séparées.'),
  (5000454,E'[CUBEVIEW]2,3,4[/CUBEVIEW]\nQuelles sont les hauteurs des colonnes visibles de gauche à droite ?','La vue de face montre des colonnes de hauteurs 2, 3 et 4.','Je suis d’accord : le dessin en perspective ne permettait pas de lire sans ambiguïté la vue de face attendue. Il est remplacé par une véritable vue de face en carrés.'),
  (5000455,E'[CUBESTACK]2,2;1,3[/CUBESTACK]\nCombien de cubes cet empilement contient-il au total ?','On compte 2 + 2 + 1 + 3 = 8 cubes.','Je suis d’accord : la rangée arrière était insuffisamment lisible. Le nouveau rendu espace nettement les rangées et évite les cubes masqués.'),
  (5000458,E'[TOPVIEW]1,1,1;0,1,1[/TOPVIEW]\nCombien de carrés comporte cette vue de dessus ?','La vue de dessus comporte cinq carrés.','Je suis d’accord : l’ancienne perspective pouvait laisser croire que seuls quatre emplacements étaient occupés. La question affiche désormais directement une vue de dessus non ambiguë.'),
  (5000461,E'[SOLIDS]A=cylinder;B=pyramid;C=cuboid;D=triangular-prism[/SOLIDS]\nQuel solide représenté est un pavé droit ?','Le solide C est un pavé droit : ses six faces sont rectangulaires.','Je suis d’accord : le pavé C manquait de profondeur et ses faces se superposaient mal. Son tracé en perspective est redessiné avec trois faces clairement distinctes.'),
  (5000462,E'[SOLIDS]A=pyramid;B=cylinder;C=cube;D=triangular-prism[/SOLIDS]\nQuel solide représenté est un prisme droit à base triangulaire ?','Le solide D possède deux bases triangulaires parallèles reliées par trois faces rectangulaires.','Je suis d’accord : le cube C était graphiquement confus. Le nouveau tracé distingue clairement la face avant, la face supérieure et la face latérale.'),
  (5000470,E'[SOLIDS]A=cube;B=triangular-prism;C=pyramid;D=cylinder[/SOLIDS]\nQuel solide représenté ne possède aucun sommet ?','Le cylindre, représenté par le solide D, ne possède aucun sommet.','Je suis d’accord : le cube A devait être amélioré pour ne pas gêner la comparaison entre les solides. Il bénéficie du nouveau dessin en perspective plus lisible.')
 ) as x(legacy_id,prompt,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id
  from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
  where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=source_id and change_comment=c.change_comment) then continue; end if;
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-15-visual-feedback:'||c.legacy_id||':v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  values(target_id,qid,target_number,c.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid());
  insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
  select md5('cap-college:mathematics-5e-lot-15-visual-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,target_id,a.choice_key,a.content,a.is_correct,a.sort_order
  from public.answer_choices a where a.question_version_id=source_id;
  update public.questions set current_version_number=target_number,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;$block$;
commit;