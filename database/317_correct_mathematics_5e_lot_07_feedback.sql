/* Correct only the two justified validator remarks from Mathematics 5e lot 07. */
begin;
do $block$
declare c record; qid uuid; source_number integer; source_id uuid; target_number integer; target_id uuid; a record;
begin
 for c in select * from (values
  (5000231, 'Quelles fractions de dénominateur 6 sont respectivement égales à 1/2 et à 1/3 ?', array['2/6 et 3/6','1/6 et 1/6','3/6 et 2/6','4/6 et 3/6'], 3, '1/2 = 3/6 et 1/3 = 2/6.', 'Je suis d’accord avec la demande de reformulation : même si « réduire au même dénominateur » est correct, cette nouvelle formulation indique plus directement les deux fractions équivalentes attendues.'),
  (5000239, 'Quelles écritures de 2/5 et de 7/12 ont le dénominateur commun 60 ?', array['2/60 = 7/60','24/60 = 35/60','24/60 et 35/60','14/60 et 24/60'], 3, '2/5 = 24/60 et 7/12 = 35/60.', 'Je suis d’accord avec la remarque : le mot « égalité » était impropre puisque les propositions présentent deux écritures sans signe égal. La question demande désormais explicitement les deux écritures de dénominateur 60.')
 ) as x(legacy_id,prompt,choices,correct_position,explanation,change_comment)
 loop
  select q.id,q.current_version_number,v.id into qid,source_number,source_id from public.questions q join public.question_versions v on v.question_id=q.id and v.version_number=q.current_version_number where q.legacy_id=c.legacy_id;
  if qid is null then raise exception 'Question % introuvable.',c.legacy_id; end if;
  if exists(select 1 from public.question_versions where id=source_id and prompt=c.prompt and change_comment=c.change_comment) then continue; end if;
  target_number:=source_number+1;
  target_id:=md5('cap-college:mathematics-5e-lot-07-feedback:'||c.legacy_id||':v'||target_number)::uuid;
  insert into public.question_versions(id,question_id,version_number,prompt,correction_explanation,change_comment,review_status,authored_by)
  values(target_id,qid,target_number,c.prompt,c.explanation,c.change_comment,'unreviewed'::public.review_status,auth.uid());
  for a in select value as content,ordinality::smallint as sort_order from unnest(c.choices) with ordinality as t(value,ordinality) loop
   insert into public.answer_choices(id,question_version_id,choice_key,content,is_correct,sort_order)
   values(md5('cap-college:mathematics-5e-lot-07-feedback:'||c.legacy_id||':v'||target_number||':'||a.sort_order)::uuid,target_id,chr(64+a.sort_order),a.content,a.sort_order=c.correct_position,a.sort_order);
  end loop;
  update public.questions set current_version_number=target_number,status='in_review'::public.question_status,updated_at=statement_timestamp() where id=qid;
 end loop;
end;
$block$;
commit;
