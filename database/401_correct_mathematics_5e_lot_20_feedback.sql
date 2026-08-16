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
    (5000619,3,'Une base d’un triangle mesure 10 cm et la hauteur correspondante, située à l’extérieur du triangle, mesure 4 cm. Quelle est l’aire du triangle ?',array['20 cm²','40 cm²','14 cm²','28 cm²'],1,'Même située à l’extérieur du triangle, la hauteur correspondante s’utilise de la même façon : (10 × 4) ÷ 2 = 20 cm².','Je suis d’accord : préciser que le triangle est obtus n’est pas utile au calcul. La question indique directement que la hauteur correspondante est située à l’extérieur.'),
    (5000630,3,'Dans le triangle ABC, E appartient à [BC] et la droite (AE) est tracée, sans codage d’angle droit. Que peut-on conclure ?',array['La droite (AE) est forcément une hauteur','La droite (AE) est forcément une médiatrice','La demi-droite [AE) est forcément la bissectrice de l’angle BÂC','On ne peut pas affirmer que (AE) est une hauteur'],4,'Pour reconnaître une hauteur, il faut savoir que (AE) est perpendiculaire à (BC). Le dessin seul ne suffit pas.','Je suis d’accord : une hauteur est une droite et non le segment [AE]. La notation est corrigée, ainsi que celle de la demi-droite et de l’angle dans les distracteurs.'),
    (5000631,1,'Quelle définition correspond à une médiane d’un triangle ?',array['Une droite qui passe par un sommet et par le milieu du côté opposé','Une droite perpendiculaire à un côté en son milieu','Une demi-droite qui partage un angle en deux angles égaux','Une droite parallèle au côté opposé'],1,'Une médiane est une droite qui passe par un sommet et par le milieu du côté opposé.','Je suis d’accord après vérification : le programme officiel demande de définir et tracer les médianes, et la convention scolaire rigoureuse définit une médiane comme une droite passant par un sommet et le milieu du côté opposé.'),
    (5000632,1,E'[TRIANGLEAUX]median[/TRIANGLEAUX] Les deux traits indiquent que BM = MC. Que représente la droite (AM) ?',array['La hauteur issue de A','La médiane issue de A','La médiatrice de [BC]','La bissectrice de l’angle en B'],2,'M est le milieu de [BC] puisque BM = MC ; la droite (AM) passe par A et par le milieu du côté opposé.','Correction issue de l’audit demandé : la médiane est la droite (AM), et non le segment [AM].'),
    (5000635,2,'Dans le triangle ABC, (AM) est une médiane et BC = 10 cm. Quelles sont les longueurs BM et MC ?',array['BM = MC = 5 cm','BM = 4 cm et MC = 6 cm','BM = MC = 10 cm','On ne peut rien déterminer'],1,'M est le milieu de [BC], donc BM = MC = 10 ÷ 2 = 5 cm.','Correction issue de l’audit demandé : la notation (AM) remplace [AM] puisque la médiane est une droite.'),
    (5000636,2,'Dans le triangle ABC, N est le milieu de [AC]. Quelle est la médiane issue de B ?',array['La droite (AN)','La droite (BN)','La droite (CN)','La droite (BC)'],2,'La médiane issue de B est la droite (BN), qui passe par B et par le milieu N du côté opposé [AC].','Correction issue de l’audit demandé : toutes les propositions désignent désormais des droites et la réponse est écrite (BN).'),
    (5000637,2,'Quelle procédure permet de tracer la médiane issue de C dans le triangle ABC ?',array['Tracer la perpendiculaire à (AB) passant par C','Construire la médiatrice de [AB]','Construire le milieu I de [AB], puis tracer la droite (CI)','Construire le milieu de [AC], puis le relier à B'],3,'Le côté opposé à C est [AB] : on trouve son milieu I, puis on trace la droite (CI).','Correction issue de l’audit demandé : la procédure fait tracer la droite (CI), et non seulement le segment [CI].'),
    (5000638,2,'Laquelle de ces droites n’est pas, en général, une médiane du triangle ABC ?',array['La droite passant par A et le milieu de [BC]','La droite passant par B et le milieu de [AC]','La droite passant par C et le milieu de [AB]','La droite passant par les milieux de [AB] et [AC]'],4,'Une médiane doit passer par un sommet. La droite passant par deux milieux ne passe, en général, par aucun sommet.','Correction issue de l’audit demandé : l’énoncé et les quatre propositions parlent maintenant de droites, conformément à la définition d’une médiane.'),
    (5000640,3,'Dans le triangle ABC, (AM) est une médiane. Quelle information est garantie ?',array['AM = BM','BM = MC','(AM) est perpendiculaire à (BC)','Les angles BÂM et MÂC ont la même mesure'],2,'Puisque (AM) est une médiane, M est le milieu de [BC] : BM = MC. La perpendicularité et le partage de l’angle ne sont pas garantis.','Je suis d’accord : la médiane est notée (AM) et les angles sont désormais écrits BÂM et MÂC avec le sommet A clairement identifié par le chapeau.')
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
    target_id:=md5('cap-college:mathematics-5e-lot-20-feedback:'||c.legacy_id||':v'||target_number)::uuid;

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
        md5('cap-college:mathematics-5e-lot-20-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,
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