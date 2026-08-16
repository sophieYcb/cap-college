begin;
do $block$
declare c record; qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid; a record;
begin
 for c in select * from (values
  (5000491,1,'Convertis 2 dm³ en litres.',array['2 l','20 l','200 l','0,2 l'],1,'Comme 1 dm³ = 1 l, 2 dm³ = 2 l.','Je suis d’accord : dans la convention éditoriale française retenue, le symbole du litre est écrit « l » minuscule.'),
  (5000492,1,'Convertis 750 cm³ en millilitres.',array['75 ml','7 500 ml','750 ml','0,75 ml'],3,'Comme 1 cm³ = 1 ml, 750 cm³ = 750 ml.','Je suis d’accord avec la remarque générale : le symbole du millilitre est harmonisé en « ml » minuscule.'),
  (5000493,1,'Convertis 1,5 l en centimètres cubes.',array['150 cm³','1 500 cm³','15 000 cm³','1,5 cm³'],2,'1 l = 1 000 cm³, donc 1,5 l = 1 500 cm³.','Je suis d’accord : le symbole du litre est corrigé en « l » minuscule dans l’énoncé et la correction.'),
  (5000494,2,'Convertis 0,4 m³ en litres.',array['40 l','4 l','4 000 l','400 l'],4,'1 m³ = 1 000 l, donc 0,4 m³ = 400 l.','Je suis d’accord : les propositions et l’explication utilisent désormais « l » minuscule.'),
  (5000496,2,'[TOOLS]scratch[/TOOLS] Une cuve contient 0,018 m³ d’eau. Quel volume cela représente-t-il en litres ?',array['18 l','1,8 l','180 l','18 000 l'],1,'1 m³ = 1 000 l, donc 0,018 m³ = 18 l.','Je suis d’accord : cette question était presque identique à la Q5000489 sur l’aquarium. Elle est remplacée par une conversion directe de mètres cubes en litres.'),
  (5000497,2,'Quel volume en centimètres cubes correspond à 3 l et 250 ml ?',array['3 025 cm³','325 cm³','32 500 cm³','3 250 cm³'],4,'3 l = 3 000 cm³ et 250 ml = 250 cm³, soit 3 250 cm³.','Je suis d’accord avec l’harmonisation demandée : « l » et « ml » sont écrits en minuscules.'),
  (5000498,2,'Compare 0,002 m³ et 2 l.',array['0,002 m³ est plus grand.','2 l est plus grand.','Les deux volumes sont égaux.','On ne peut pas les comparer.'],3,'0,002 m³ = 0,002 × 1 000 l = 2 l.','Je suis d’accord : le symbole du litre est corrigé en « l » dans toute la question.'),
  (5000500,3,'[TOOLS]scratch[/TOOLS] Un récipient de 12 l contient déjà 8 500 cm³ d’eau. Quel volume peut-on encore ajouter ?',array['2,5 l','3,5 l','4,5 l','8,5 l'],2,'8 500 cm³ = 8,5 l ; il reste 12 − 8,5 = 3,5 l.','Je suis d’accord : toutes les occurrences du symbole du litre passent en minuscule.'),
  (5000511,1,'Quelle formule donne le volume V d’un cylindre de rayon r et de hauteur h ?',array['V = 2 × π × r × h','V = π × r² + h','V = π × r² × h','V = π × r × h²'],3,'Le volume est l’aire de la base, π × r², multipliée par la hauteur h : V = π × r² × h.','Je suis d’accord : les signes de multiplication rendent les facteurs π, r² et h nettement plus lisibles.'),
  (5000518,3,'[TOOLS]calculator[/TOOLS] Un récipient cylindrique a un rayon intérieur de 10 cm et une hauteur de 20 cm. Quelle est sa capacité approchée, avec π ≈ 3,14 ?',array['6,28 l','62,8 l','0,628 l','628 l'],1,'V ≈ 3,14 × 10² × 20 = 6 280 cm³ = 6,28 l.','Je suis d’accord : le symbole du litre est corrigé en « l » minuscule dans les réponses et l’explication.')
 ) as x(legacy_id,difficulty,prompt,choices,correct_position,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id
  from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number
  where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=source_id and prompt=c.prompt and change_comment=c.change_comment) then continue; end if;
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-16-feedback:'||c.legacy_id||':v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  values(target_id,qid,target_number,c.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid());
  for a in select value content,ordinality::smallint sort_order from unnest(c.choices) with ordinality t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
   values(md5('cap-college:mathematics-5e-lot-16-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,target_id,chr(64+a.sort_order),a.content,a.sort_order=c.correct_position,a.sort_order);
  end loop;
  update public.questions set current_version_number=target_number,theoretical_difficulty=c.difficulty::text::public.difficulty_level,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;$block$;
commit;