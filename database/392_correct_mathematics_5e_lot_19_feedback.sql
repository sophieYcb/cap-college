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
    (5000571,1,E'[CODEDTRIANGLE]isosceles[/CODEDTRIANGLE] Quel nom est garanti par le codage de ce triangle ABC ?',array['Un triangle isocèle en A','Un triangle rectangle en A','Un triangle équilatéral','Un triangle quelconque'],1,'Les côtés [AB] et [AC] portent le même codage : AB = AC. Le triangle est isocèle en A.','Je suis d’accord : le premier dessin était presque équilatéral. Le triangle isocèle est désormais représenté avec une base nettement différente des deux côtés égaux.'),
    (5000575,2,E'[CODEDTRIANGLE]isosceles-measures[/CODEDTRIANGLE] Quelle égalité est indiquée par les deux traits identiques ?',array['AB = AC','AB = BC','AC = BC','Les trois côtés sont égaux'],1,'Les traits identiques sont placés sur [AB] et [AC] : AB = AC = 5 cm, tandis que BC mesure 7 cm.','Je suis d’accord : pour lever toute impression de triangle équilatéral, les longueurs AB = AC = 5 cm et BC = 7 cm sont maintenant indiquées sur le schéma.'),
    (5000594,1,'Pour construire un triangle ABC, on connaît BC = 6 cm, l’angle en B égal à 50° et l’angle en C égal à 60°. Ces données sont-elles suffisantes ?',array['Non, il faut obligatoirement connaître les trois côtés.','Non, il manque la longueur AB.','Oui, mais seulement si le triangle est rectangle.','Oui, un côté et les deux angles qui lui sont adjacents déterminent le triangle.'],4,'On trace [BC], puis un angle de 50° en B et un angle de 60° en C. L’intersection des deux demi-droites donne le sommet A.','Je suis d’accord : l’unicité à une symétrie près n’est pas une définition énoncée ainsi dans le programme et la question était trop abstraite. Elle est remplacée par une construction concrète utilisant un côté et ses deux angles adjacents.')
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

    target_number:=source_number+1;
    target_id:=md5('cap-college:mathematics-5e-lot-19-feedback:'||c.legacy_id||':v'||target_number)::uuid;

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
        md5('cap-college:mathematics-5e-lot-19-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,
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
