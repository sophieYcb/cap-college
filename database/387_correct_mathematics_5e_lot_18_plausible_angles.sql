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
    (5000551,1,E'[ANGLECROSS]68[/ANGLECROSS] Les angles â et ĉ sont opposés par le sommet. Si â mesure 68°, combien mesure ĉ ?',array['112°','34°','68°','136°'],3,'Deux angles opposés par le sommet ont la même mesure : ĉ mesure 68°.','Je suis d’accord : l’ouverture dessinée ne correspondait pas aux 68° annoncés. Le schéma est désormais construit à partir de la mesure demandée, avec un arc qui matérialise précisément l’angle â.'),
    (5000557,2,E'[ANGLECROSS]72[/ANGLECROSS] L’angle â mesure 72°. Quelle relation permet d’affirmer que l’angle ĉ mesure aussi 72° ?',array['Ils sont complémentaires.','Ils sont opposés par le sommet.','Ils sont supplémentaires.','Ils sont seulement adjacents.'],2,'Les angles â et ĉ sont opposés par le sommet, donc ils ont la même mesure.','Je suis d’accord : l’angle â dessiné paraissait obtus alors que 72° est une mesure aiguë. Le schéma varie maintenant réellement selon la mesure indiquée.'),
    (5000564,2,E'[PARALLELANGLES][/PARALLELANGLES] Si ĉ mesure 55°, combien mesure l’angle alterne interne ê ?',array['125°','27,5°','55°','110°'],3,'Les angles ĉ et ê sont alternes internes ; ils ont la même mesure, soit 55°.','Je suis d’accord : dans le schéma, ĉ est aigu. Sa mesure devient 55° et l’angle alterne interne ê a donc également pour mesure 55°.'),
    (5000566,2,E'[PARALLELANGLES][/PARALLELANGLES] Si f̂ mesure 125°, combien mesure l’angle alterne interne d̂ ?',array['55°','62,5°','250°','125°'],4,'Les angles d̂ et f̂ sont alternes internes, donc ils ont la même mesure, soit 125°.','Je suis d’accord : dans le schéma, f̂ est obtus. Une mesure plausible de 125° est utilisée et l’angle alterne interne d̂ mesure lui aussi 125°.'),
    (5000568,3,E'[PARALLELANGLES][/PARALLELANGLES] L’angle ĉ mesure 55°. Combien mesure l’angle intérieur f̂ situé du même côté de la sécante ?',array['55°','125°','65°','250°'],2,'Les angles ĉ et f̂ sont intérieurs du même côté de la sécante, donc supplémentaires : 180° − 55° = 125°.','Je suis d’accord : ĉ est aigu sur le schéma. Sa mesure devient 55° et l’angle intérieur supplémentaire f̂ mesure 125°.')
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
    target_id:=md5('cap-college:mathematics-5e-lot-18-plausible-angles:'||c.legacy_id||':v'||target_number)::uuid;

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
        md5('cap-college:mathematics-5e-lot-18-plausible-angles:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,
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