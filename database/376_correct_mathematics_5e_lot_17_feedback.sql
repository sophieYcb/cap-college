begin;
do $block$
declare c record; qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid; a record;
begin
 for c in select * from (values
  (5000522,1,E'[COORDINATES]O=0,0;A=3,-2[/COORDINATES] Le point A a pour coordonnées (3 ; −2). Quelle est son image par la symétrie centrale de centre O, origine du repère ?',array['(3 ; 2)','(−3 ; 2)','(−3 ; −2)','(2 ; −3)'],2,'Par rapport à l’origine, les deux coordonnées changent de signe : A’(−3 ; 2).','Je suis d’accord : le repère doit laisser visible l’emplacement possible du point image. Son cadrage est désormais symétrique autour de O.'),
  (5000524,2,E'[COORDINATES]I=2,1;P=5,3[/COORDINATES] Quelle est l’image P’ du point P(5 ; 3) par la symétrie centrale de centre I(2 ; 1) ?',array['(3 ; 2)','(−5 ; −3)','(−3 ; −2)','(−1 ; −1)'],4,'I doit être le milieu de [PP’]. Ainsi P’(2 × 2 − 5 ; 2 × 1 − 3) = (−1 ; −1).','Je suis d’accord avec le rapprochement avec la Q5000522 : le cadrage inclut maintenant la position de P’ de l’autre côté de I.'),
  (5000525,1,'Le point B’ est l’image de B par la symétrie centrale de centre O. Quelle affirmation est nécessairement vraie ?',array['O est le milieu de [BB’].','OB est le double de OB’.','B, B’ et O forment un triangle.','(BB’) est perpendiculaire à toute droite passant par O.'],1,'Par définition, le centre O est le milieu du segment reliant un point à son image.','Je suis d’accord : la notation d’une droite est (BB’), tandis que [BB’] désigne un segment. Le distracteur est corrigé.'),
  (5000528,2,E'[COORDINATES]O=0,0;A=-4,1[/COORDINATES] Quelle est l’image de A(−4 ; 1) par la symétrie centrale de centre O, origine du repère ?',array['(−4 ; −1)','(4 ; 1)','(1 ; −4)','(4 ; −1)'],4,'Les coordonnées changent de signe : A’(4 ; −1).','Je suis d’accord : comme pour la Q5000522, le repère est recentré afin que la zone contenant A’ soit visible.'),
  (5000529,3,E'[COORDINATES]M=-1,2;A=3,-2[/COORDINATES] Le point M(−1 ; 2) est le milieu de [AA’] et A(3 ; −2). Quelles sont les coordonnées de A’ ?',array['(−5 ; 6)','(1 ; 0)','(−3 ; 2)','(5 ; −6)'],1,'A’(2 × (−1) − 3 ; 2 × 2 − (−2)) = (−5 ; 6).','Je suis d’accord : le cadrage doit être symétrique autour de M pour inclure la position recherchée de A’.'),
  (5000533,2,'Une droite (d) ne passe pas par le centre O d’une symétrie centrale. Quelle est son image (d’) ?',array['Une droite (d’) parallèle à (d)','Une droite (d’) perpendiculaire à (d)','Un cercle de centre O','La droite (d) elle-même dans tous les cas'],1,'L’image d’une droite (d) ne passant pas par le centre est une droite (d’) parallèle à (d).','Je suis d’accord : la notation conventionnelle d’une droite utilise des parenthèses. (d) et son image (d’) sont désormais notées correctement.'),
  (5000540,3,'Une droite (d) passe par le centre O d’une symétrie centrale. Quelle est son image ?',array['Une droite parallèle distincte','Une droite perpendiculaire','Un point','La droite (d) elle-même'],4,'Après un demi-tour autour de O, une droite (d) passant par O se superpose à elle-même.','Je suis d’accord : la notation (d) remplace la lettre d isolée dans l’énoncé, la réponse et l’explication.')
 ) as x(legacy_id,difficulty,prompt,choices,correct_position,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id
  from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
  where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=source_id and prompt=c.prompt and change_comment=c.change_comment) then continue; end if;
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-17-feedback:'||c.legacy_id||':v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  values(target_id,qid,target_number,c.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid());
  for a in select value content,ordinality::smallint sort_order from unnest(c.choices) with ordinality t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
   values(md5('cap-college:mathematics-5e-lot-17-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,target_id,chr(64+a.sort_order),a.content,a.sort_order=c.correct_position,a.sort_order);
  end loop;
  update public.questions set current_version_number=target_number,theoretical_difficulty=c.difficulty::text::public.difficulty_level,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;$block$;
commit;