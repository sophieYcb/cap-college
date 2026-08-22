begin;

do $block$
declare
  c record;
  qid uuid;
  source_number integer;
  source_id uuid;
  target_number integer;
  target_id uuid;
  a record;
begin
  for c in select * from (values
    (5000652,1,'Pour que ABCD soit un parallélogramme, après avoir placé A, B et D, quelle construction au compas permet de trouver C ?',array['Tracer seulement le cercle de centre A et de rayon AB','Tracer la médiatrice de [BD]','Tracer un cercle de centre A passant par D','Tracer les cercles de centre B et de rayon AD et de centre D et de rayon AB, puis choisir leur point d’intersection distinct de A'],4,'Les deux cercles passent par A. Leur autre point d’intersection C vérifie BC = AD et CD = AB, ce qui permet de construire le parallélogramme ABCD.','Je suis d’accord : l’objectif de construire le parallélogramme ABCD est maintenant explicite. Je précise aussi qu’il faut retenir le point d’intersection distinct de A, puisque les deux cercles passent déjà par A.'),
    (5000653,1,'Après avoir tracé les côtés adjacents [AB] et [AD], quelle étape permet de construire le parallélogramme ABCD ?',array['Tracer par B la parallèle à (AD) et par D la parallèle à (AB)','Tracer les médiatrices de [AB] et [AD]','Tracer deux perpendiculaires à (AB)','Choisir C sur la droite (BD)'],1,'Les deux parallèles se coupent en C ; les côtés opposés de ABCD sont alors parallèles deux à deux.','Je suis d’accord : l’énoncé précise désormais clairement que la construction attendue doit produire le parallélogramme ABCD.'),
    (5000654,2,E'[COORDINATES]A=1,1;B=5,1;D=2,4[/COORDINATES]\n[TOOLS]scratch[/TOOLS] Dans ce repère orthonormé, A(1 ; 1), B(5 ; 1) et D(2 ; 4) sont trois sommets du parallélogramme ABCD. Quelles sont les coordonnées de C ?',array['(4 ; 4)','(6 ; 4)','(6 ; 3)','(5 ; 5)'],2,'Pour passer de A à D, on ajoute (1 ; 3). En appliquant le même déplacement à B(5 ; 1), on obtient C(6 ; 4).','Je suis d’accord : un repère orthonormé avec les trois points A, B et D est ajouté pour rendre la construction du quatrième sommet plus accessible.'),
    (5000655,2,E'[COORDINATES]A=0,0;B=4,0;D=0,3[/COORDINATES]\nDans ce repère orthonormé, A(0 ; 0), B(4 ; 0) et D(0 ; 3) sont trois sommets du parallélogramme ABCD. Où se trouve C ?',array['(0 ; 4)','(3 ; 4)','(4 ; 3)','(4 ; 0)'],3,'C possède l’abscisse de B et l’ordonnée de D : C(4 ; 3).','Je suis d’accord avec la note B : même sans commentaire, cette question présente le même besoin d’illustration que la Q5000654. Un repère orthonormé avec A, B et D est donc ajouté.'),
    (5000657,2,'Un élève veut construire le parallélogramme ABCD. Il trace par B la parallèle à (AD) et par D la parallèle à (AB) ; ces droites se coupent en C. Pourquoi la construction est-elle correcte ?',array['Parce que les côtés opposés de ABCD sont parallèles deux à deux','Parce que AC = BD est garanti','Parce que les quatre angles sont droits','Parce que les quatre côtés sont égaux'],1,'On obtient (BC) parallèle à (AD) et (CD) parallèle à (AB) : ABCD possède donc ses côtés opposés parallèles deux à deux.','Je suis d’accord : l’énoncé annonce maintenant dès le début que l’élève cherche à construire le parallélogramme ABCD.'),
    (5000658,3,'Pour construire un parallélogramme ABCD, quel instrument permet de reporter précisément la longueur AD à partir de B ?',array['Un rapporteur','Un compas','Une calculatrice','Une règle non graduée seule'],2,'Le compas permet de reporter la longueur AD en traçant un cercle de centre B et de rayon AD.','Je suis partiellement d’accord avec la note B : la réponse était correcte, mais la question manquait de contexte. Elle est désormais directement reliée à la construction d’un parallélogramme ABCD.'),
    (5000675,2,E'[COORDINATES]A=1,2;C=7,6[/COORDINATES]\n[TOOLS]scratch[/TOOLS] Dans ce repère orthonormé, A(1 ; 2) et C(7 ; 6) sont les extrémités d’une diagonale. Quelles sont les coordonnées de son milieu O ?',array['(3 ; 2)','(8 ; 8)','(4 ; 4)','(6 ; 4)'],3,'Les coordonnées du milieu sont ((1 + 7) ÷ 2 ; (2 + 6) ÷ 2), soit O(4 ; 4).','Je suis d’accord avec la note B : même sans commentaire, une illustration est utile pour accompagner le calcul du milieu. Le repère orthonormé avec A et C est ajouté.'),
    (5000678,3,'Dans un rectangle, en plus de se couper en leur milieu comme dans tout parallélogramme, quelle propriété les diagonales possèdent-elles ?',array['Elles sont toujours perpendiculaires','Elles ont la même longueur','Elles sont parallèles','Elles ne se coupent pas'],2,'Les diagonales d’un rectangle se coupent en leur milieu et ont la même longueur.','Je suis entièrement d’accord : l’expression « propriété supplémentaire » était ambiguë. L’énoncé précise maintenant qu’il s’agit d’une propriété ajoutée à celle des diagonales de tout parallélogramme.'),
    (5000679,3,'Dans un losange, en plus de se couper en leur milieu comme dans tout parallélogramme, quelle propriété les diagonales possèdent-elles ?',array['Elles ont toujours la même longueur','Elles sont parallèles','Elles sont perpendiculaires','Elles ne se coupent jamais en leur milieu'],3,'Les diagonales d’un losange se coupent en leur milieu et sont perpendiculaires.','Je suis d’accord avec la note B : même sans commentaire, la formulation présentait la même ambiguïté que la Q5000678. Le point de comparaison est maintenant explicite.')
  ) as x(legacy_id,difficulty,prompt,choices,correct_position,explanation,change_comment)
  loop
    select q.id,q.current_version_number,v.id
      into qid,source_number,source_id
    from public.questions q
    join public.question_versions v
      on v.question_id=q.id
     and v.version_number=q.current_version_number
    where q.legacy_id=c.legacy_id;

    if qid is null then
      raise exception 'Question % introuvable.',c.legacy_id;
    end if;

    if exists(
      select 1 from public.question_versions
      where id=source_id
        and prompt=c.prompt
        and change_comment=c.change_comment
    ) then
      continue;
    end if;

    if source_number<>1 then
      raise exception 'Version inattendue pour la question % : %.',c.legacy_id,source_number;
    end if;

    target_number:=source_number+1;
    target_id:=md5('cap-college:mathematics-5e-lot-21-feedback:'||c.legacy_id||':v'||target_number)::uuid;

    insert into public.question_versions(
      id,question_id,version_number,prompt,correction_explanation,
      change_comment,review_status,authored_by
    ) values(
      target_id,qid,target_number,c.prompt,c.explanation,
      c.change_comment,'unreviewed'::public.review_status,auth.uid()
    );

    for a in
      select value content,ordinality::smallint sort_order
      from unnest(c.choices) with ordinality t(value,ordinality)
    loop
      insert into public.answer_choices(
        id,question_version_id,choice_key,content,is_correct,sort_order
      ) values(
        md5('cap-college:mathematics-5e-lot-21-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,
        target_id,chr(64+a.sort_order),a.content,a.sort_order=c.correct_position,a.sort_order
      );
    end loop;

    update public.questions
    set current_version_number=target_number,
        theoretical_difficulty=c.difficulty::text::public.difficulty_level,
        status='in_review'::public.question_status,
        updated_at=statement_timestamp()
    where id=qid;
  end loop;
end;
$block$;

commit;
