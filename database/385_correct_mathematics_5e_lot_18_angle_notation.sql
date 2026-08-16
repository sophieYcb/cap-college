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
    (5000551,1,E'[ANGLECROSS]68[/ANGLECROSS] Les angles â et ĉ sont opposés par le sommet. Si â mesure 68°, combien mesure ĉ ?',array['112°','34°','68°','136°'],3,'Deux angles opposés par le sommet ont la même mesure : ĉ mesure 68°.','Je suis d’accord : les lettres qui désignent les angles doivent porter un chapeau. La notation est corrigée dans l’énoncé et dans le schéma.'),
    (5000557,2,E'[ANGLECROSS]72[/ANGLECROSS] L’angle â mesure 72°. Quelle relation permet d’affirmer que l’angle ĉ mesure aussi 72° ?',array['Ils sont complémentaires.','Ils sont opposés par le sommet.','Ils sont supplémentaires.','Ils sont seulement adjacents.'],2,'Les angles â et ĉ sont opposés par le sommet, donc ils ont la même mesure.','Je suis d’accord avec la note B : même sans commentaire détaillé, les lettres a et c devaient porter un chapeau. La notation officielle est maintenant appliquée.'),
    (5000561,1,E'[PARALLELANGLES][/PARALLELANGLES] Quelle paire est formée d’angles alternes internes ?',array['â et ê','b̂ et ĥ','ĉ et f̂','d̂ et f̂'],4,'Les angles d̂ et f̂ sont situés entre les parallèles et de part et d’autre de la sécante.','Je suis d’accord : les chapeaux manquaient, le trait d’union ne correspondait pas au programme officiel et certaines lettres chevauchaient les droites. La notation, le texte et le schéma sont corrigés.'),
    (5000562,1,E'[PARALLELANGLES][/PARALLELANGLES] Quel angle forme avec l’angle â une paire d’angles correspondants ?',array['f̂','ê','ĝ','ĥ'],2,'Les angles â et ê occupent la même position aux deux intersections : ils sont correspondants. D’autres angles peuvent avoir la même mesure sans être correspondants entre eux.','Je suis partiellement d’accord : â, ĉ, ê et ĝ ont la même mesure lorsque les droites sont parallèles, mais seul ê est correspondant à â, car la correspondance dépend de la position. La question est reformulée pour rendre cette distinction explicite.'),
    (5000563,2,E'[PARALLELANGLES][/PARALLELANGLES] Si â mesure 65°, combien mesure l’angle correspondant ê ?',array['65°','115°','32,5°','130°'],1,'Les droites étant parallèles, les angles correspondants â et ê sont égaux.','Je suis d’accord avec la note B : la propriété était correcte, mais les angles devaient être écrits avec un chapeau. La notation est corrigée.'),
    (5000564,2,E'[PARALLELANGLES][/PARALLELANGLES] Si ĉ mesure 112°, combien mesure l’angle alterne interne ê ?',array['68°','56°','112°','224°'],3,'Les angles ĉ et ê sont alternes internes ; ils ont la même mesure.','Je suis d’accord avec la note B : les chapeaux sont ajoutés et « alterne interne » est désormais écrit sans trait d’union, conformément au programme officiel.'),
    (5000565,2,E'[PARALLELANGLES][/PARALLELANGLES] Quelle relation lie les angles d̂ et ê ?',array['Ils sont égaux dans tous les cas.','Ils sont supplémentaires.','Ils sont opposés par le sommet.','Ils sont correspondants.'],2,'Les angles d̂ et ê sont intérieurs et situés du même côté de la sécante ; lorsque les droites sont parallèles, ils sont supplémentaires.','Je suis d’accord avec la note B pour la notation : d̂ et ê doivent porter un chapeau. La relation mathématique proposée reste correcte.'),
    (5000566,2,E'[PARALLELANGLES][/PARALLELANGLES] Si f̂ mesure 73°, combien mesure l’angle alterne interne d̂ ?',array['107°','36,5°','146°','73°'],4,'Les angles d̂ et f̂ sont alternes internes, donc ils ont la même mesure.','Je suis d’accord avec la note B : les chapeaux sont ajoutés et le trait d’union de « alterne-interne » est supprimé.'),
    (5000567,2,E'[PARALLELANGLES][/PARALLELANGLES] Quelle paire est formée d’angles correspondants ?',array['â et ĝ','ĉ et ê','b̂ et f̂','d̂ et ê'],3,'Les angles b̂ et f̂ occupent la même position aux deux intersections : ils sont correspondants.','Je suis d’accord avec la note B pour la notation : toutes les lettres désignant les angles portent maintenant un chapeau. La réponse b̂ et f̂ reste correcte.'),
    (5000568,3,E'[PARALLELANGLES][/PARALLELANGLES] L’angle ĉ mesure 125°. Combien mesure l’angle intérieur f̂ situé du même côté de la sécante ?',array['55°','125°','65°','250°'],1,'Les angles ĉ et f̂ sont intérieurs du même côté de la sécante, donc supplémentaires : 180° − 125° = 55°.','Je suis d’accord avec la note B pour la notation : les angles ĉ et f̂ sont désormais correctement désignés avec un chapeau.'),
    (5000570,3,'Deux droites sont coupées par une sécante. Deux angles occupent la même position aux deux intersections : ce sont des angles correspondants. S’ils ont la même mesure, que peut-on conclure ?',array['Les deux droites sont parallèles.','Les deux droites sont perpendiculaires.','La sécante est une bissectrice.','On ne peut rien conclure.'],1,'Deux angles correspondants sont définis par leur position. S’ils ont la même mesure, alors les deux droites sont parallèles.','Je suis d’accord : « correspondants » désigne la même position aux deux intersections, ce que la question précédente n’expliquait pas. La définition est intégrée à l’énoncé avant d’utiliser la réciproque.')
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
      select 1
      from public.question_versions
      where id=source_id
        and prompt=c.prompt
        and change_comment=c.change_comment
    ) then
      continue;
    end if;

    target_number:=source_number+1;
    target_id:=md5('cap-college:mathematics-5e-lot-18-angle-notation:'||c.legacy_id||':v'||target_number)::uuid;

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
        md5('cap-college:mathematics-5e-lot-18-angle-notation:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,
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