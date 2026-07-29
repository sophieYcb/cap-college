const fs=require("fs");
const path=require("path");
const root=path.resolve(__dirname,"..");
const lot=JSON.parse(fs.readFileSync(path.join(root,"contenus","maths-6e-lot-19-lecture-donnees.json"),"utf8"));
const originals=new Map(lot.questions.map(q=>[600000+Number(q.code.slice(3)),q]));
const corrections=[];

function choicesAt(position,correct,distractors){
  const choices=[...distractors];
  choices.splice(position,0,String(correct));
  return choices;
}
function add(id,prompt,correct,distractors,explanation,comment){
  const original=originals.get(id);
  const correctPosition=original.correctIndex;
  const choices=choicesAt(correctPosition,correct,distractors.map(String));
  if(choices.length!==4||new Set(choices).size!==4)throw new Error(`Choix invalides pour ${id}`);
  corrections.push({
    legacy_id:id,prompt,choices,correct_position:correctPosition+1,
    explanation,change_comment:comment
  });
}

const days=["lundi","mardi","mercredi","jeudi","vendredi","samedi","dimanche","lundi suivant","mardi suivant","mercredi suivant"];
for(let i=0;i<10;i++){
  const id=600641+i;
  const books=6+i*2;
  const games=3+i;
  const askBooks=i%2===0;
  const correct=askBooks?books:games;
  const label=askBooks?"livres":"jeux";
  add(
    id,
    `Observe le tableau :\n\nJour | Livres | Jeux\n${days[i][0].toUpperCase()+days[i].slice(1)} | ${books} | ${games}\n\nCombien de ${label} sont indiqués pour ${days[i]} ?`,
    correct,
    [askBooks?games:books,books+games,Math.max(0,correct-2)],
    `À l’intersection de la ligne « ${days[i]} » et de la colonne « ${askBooks?"Livres":"Jeux"} », on lit ${correct}.`,
    "La donnée demandée alterne désormais entre la colonne Livres et la colonne Jeux."
  );
}

for(let i=0;i<10;i++){
  const id=600651+i;
  const a=5+i;
  const b=9+i*2;
  const askA=i%2===0;
  const correct=askA?a:b;
  add(
    id,
    `Observe ce diagramme en barres :\n\nA | ${"█".repeat(a)} ${a}\nB | ${"█".repeat(b)} ${b}\n\nQuelle valeur représente la barre ${askA?"A":"B"} ?`,
    correct,
    [askA?b:a,correct+2,Math.max(0,correct-2)],
    `La barre ${askA?"A":"B"} atteint la graduation ${correct}.`,
    "La barre demandée alterne entre A et B afin d’éviter une série mécanique."
  );
}

const circlePrompts=[
  "Dans un diagramme circulaire, la moitié du disque est colorée. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, un quart du disque est coloré. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, trois quarts du disque sont colorés. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, le disque entier est coloré. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, un dixième du disque est coloré. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, deux quarts du disque sont colorés. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, un demi-disque est coloré. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, un secteur représentant 20 parts sur 100 est coloré. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, quatre quarts du disque sont colorés. Quelle proportion cela représente-t-il ?",
  "Dans un diagramme circulaire, un secteur représentant 5 parts sur 100 est coloré. Quelle proportion cela représente-t-il ?"
];
for(let i=0;i<10;i++){
  const id=600661+i;
  const original=originals.get(id);
  add(
    id,
    circlePrompts[i],
    original.choices[original.correctIndex],
    original.choices.filter((_,index)=>index!==original.correctIndex),
    original.explanation,
    "Le pourcentage écrit sous le diagramme a été supprimé ; seul le secteur coloré permet désormais la lecture visuelle."
  );
}

const curveSeries=[
  [[8,12],[9,15],[10,11],0],
  [[9,18],[10,14],[11,20],1],
  [[10,16],[11,21],[12,19],2],
  [[11,24],[12,20],[13,17],0],
  [[12,22],[13,27],[14,25],1],
  [[13,30],[14,26],[15,32],2],
  [[14,28],[15,34],[16,31],0],
  [[15,36],[16,33],[17,38],1],
  [[16,35],[17,40],[18,37],2],
  [[17,42],[18,38],[19,44],0]
];
for(let i=0;i<10;i++){
  const id=600671+i;
  const series=curveSeries[i];
  const target=series[series[3]];
  const points=series.slice(0,3).map(([hour,value])=>`${hour}=${value}`).join("; ");
  const otherValues=series.slice(0,3).map(item=>item[1]).filter(value=>value!==target[1]);
  const distractors=[...new Set([
    ...otherValues,target[1]+3,target[1]-3,target[1]+5
  ].filter(value=>value!==target[1]))].slice(0,3);
  add(
    id,
    `Observe cette courbe :\n[DONNÉES_COURBE] ${points}\n\nQuelle valeur lit-on à ${target[0]} h ?`,
    target[1],
    distractors,
    `À ${target[0]} h, le point de la courbe se trouve à la valeur ${target[1]}.`,
    "La courbe comporte trois points variés et l’heure demandée change dans la série."
  );
}

const payload=JSON.stringify(corrections).replace(/'/g,"''");
const ids=corrections.map(item=>item.legacy_id);
const sql=`/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/123_correct_visual_series_2026_07_29.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Diversify table/chart questions and remove answer hints.
 Idempotent   : Yes
===============================================================================
*/
begin;
do $block$
declare
  correction jsonb;
  answer record;
  selected_question_id uuid;
  target_version_id uuid;
  corrections jsonb := '${payload}'::jsonb;
begin
  for correction in select value from jsonb_array_elements(corrections)
  loop
    select id into selected_question_id
    from public.questions
    where legacy_id=(correction->>'legacy_id')::integer;
    if selected_question_id is null then
      raise exception 'Question % introuvable.',correction->>'legacy_id';
    end if;
    target_version_id:=md5(
      'cap-college:visual-feedback-2026-07-29:'||(correction->>'legacy_id')||':v4'
    )::uuid;
    insert into public.question_versions(
      id,question_id,version_number,prompt,correction_explanation,
      change_comment,review_status,authored_by
    ) values(
      target_version_id,selected_question_id,4,correction->>'prompt',
      correction->>'explanation',correction->>'change_comment',
      'unreviewed'::public.review_status,auth.uid()
    )
    on conflict(question_id,version_number) do update
    set prompt=excluded.prompt,
        correction_explanation=excluded.correction_explanation,
        change_comment=excluded.change_comment,
        review_status=excluded.review_status
    returning id into target_version_id;
    delete from public.answer_choices where question_version_id=target_version_id;
    for answer in
      select value#>>'{}' as content,ordinality::smallint as sort_order
      from jsonb_array_elements(correction->'choices')
      with ordinality as item(value,ordinality)
    loop
      insert into public.answer_choices(
        id,question_version_id,choice_key,content,is_correct,sort_order
      ) values(
        md5(
          'cap-college:visual-feedback-2026-07-29:'||
          (correction->>'legacy_id')||':v4:'||answer.sort_order
        )::uuid,
        target_version_id,chr(64+answer.sort_order),answer.content,
        answer.sort_order=(correction->>'correct_position')::integer,
        answer.sort_order
      );
    end loop;
    update public.questions
    set current_version_number=4,
        status='in_review'::public.question_status,
        updated_at=statement_timestamp()
    where id=selected_question_id;
  end loop;
end;
$block$;
commit;
`;
const verify=`with selected as(
  select q.id,q.legacy_id,q.status,q.current_version_number,qv.id as version_id,qv.prompt
  from public.questions q
  join public.question_versions qv on qv.question_id=q.id and qv.version_number=4
  where q.legacy_id=any(array[${ids.join(",")}])
),counts as(
  select s.id,count(ac.id) choices,count(*) filter(where ac.is_correct) correct_choices
  from selected s left join public.answer_choices ac on ac.question_version_id=s.version_id
  group by s.id
)
select jsonb_build_object(
  'corrected_questions',(select count(*) from selected),
  'questions_in_review',(select count(*) from selected where status='in_review'),
  'version_4_questions',(select count(*) from selected where current_version_number=4),
  'questions_with_four_choices',(select count(*) from counts where choices=4),
  'questions_with_one_correct_choice',(select count(*) from counts where correct_choices=1),
  'previous_versions_preserved',(
    select count(*) from selected s where(
      select count(distinct old.version_number) from public.question_versions old
      where old.question_id=s.id and old.version_number in(1,2,3)
    )=3
  ),
  'circular_questions_without_written_percentage',(
    select count(*) from selected where legacy_id between 600661 and 600670
      and position('%' in prompt)=0
  ),
  'diversified_curve_questions',(
    select count(*) from selected where legacy_id between 600671 and 600680
      and prompt like '%[DONNÉES_COURBE]%'
  )
) verification;
`;
fs.writeFileSync(path.join(root,"database","123_correct_visual_series_2026_07_29.sql"),sql,"utf8");
fs.writeFileSync(path.join(root,"database","124_verify_visual_series_2026_07_29.sql"),verify,"utf8");
console.log(JSON.stringify({corrections:corrections.length}));
