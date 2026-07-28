const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const sourcePath = process.argv[2] || "C:\\Users\\mmsya\\Downloads\\cap-college-questions-a-corriger-2026-07-28.json";
const source = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
const byId = new Map(source.questions.map(item => [Number(item.questionId), item]));

function addMissingFromLot(fileName, ids) {
  const lot = JSON.parse(fs.readFileSync(path.join(root, "contenus", fileName), "utf8"));
  for (const q of lot.questions) {
    const id = 600000 + Number(q.code.slice(3));
    if (!ids.includes(id) || byId.has(id)) continue;
    byId.set(id, {
      questionId: id,
      versionActuelle: {
        numero: 1,
        question: q.prompt,
        choix: q.choices,
        reponseIndex: q.correctIndex,
        reponseTexte: q.choices[q.correctIndex]
      }
    });
  }
}

addMissingFromLot("maths-6e-lot-20-organisation-donnees.json", [681,682,683,684,685,686,687,688,689,690].map(n => 600000 + n));

const corrections = new Map();

function current(id) {
  const item = byId.get(id);
  if (!item) throw new Error(`Question ${id} absente des sources.`);
  return item.versionActuelle;
}

function replaceAt(values, position, correct, distractors) {
  const result = [...values];
  result[position] = String(correct);
  let cursor = 0;
  for (let i = 0; i < result.length; i += 1) {
    if (i !== position) result[i] = String(distractors[cursor++]);
  }
  return result;
}

function set(id, { prompt, correct, distractors, explanation, comment }) {
  const old = current(id);
  const correctPosition = old.reponseIndex;
  corrections.set(id, {
    legacy_id: id,
    prompt: prompt ?? old.question,
    choices: distractors
      ? replaceAt(old.choix, correctPosition, correct ?? old.reponseTexte, distractors)
      : old.choix,
    correct_position: correctPosition + 1,
    explanation: explanation || `La bonne réponse est « ${correct ?? old.reponseTexte} ».`,
    change_comment: comment || "Question clarifiée à la suite de la validation pédagogique du 28 juillet 2026."
  });
}

set(600465, {
  correct: "12π cm",
  distractors: ["14π cm", "24π cm", "144π cm"],
  explanation: "Le périmètre d’un disque vaut π × diamètre, soit 12π cm.",
  comment: "L’unité centimètre est désormais présente dans toutes les propositions."
});
set(600549, {
  distractors: ["60 s", "180 min", "200 min"],
  explanation: "3 600 secondes correspondent à 60 minutes, donc à 1 heure.",
  comment: "La proposition « 60 min », également exacte, a été remplacée."
});
set(600553, {
  prompt: "Un article coûte 4 €. Si x est le nombre d’articles et y le prix total, quelle relation convient ?",
  correct: "y = 4 × x",
  distractors: ["y = x + 4", "y = x − 4", "y = 4 ÷ x"],
  explanation: "À prix unitaire constant de 4 €, le prix total est égal à 4 multiplié par le nombre d’articles.",
  comment: "Le coefficient a été rendu concret pour lever toute ambiguïté sur la lettre k."
});
set(600557, {
  correct: "multiplier la valeur associée par 3",
  distractors: ["ajouter 3 à la valeur associée", "retirer 3 à la valeur associée", "mettre la valeur associée au carré"],
  explanation: "Dans une situation proportionnelle, multiplier une quantité par 3 multiplie aussi la valeur associée par 3.",
  comment: "La réponse ne reprend plus directement le verbe « tripler » de l’énoncé."
});

const proportionalSituations = [
  ["À la boulangerie, chaque baguette coûte 1,20 €. Le prix total est-il proportionnel au nombre de baguettes ?", "Oui, car chaque baguette a le même prix.", ["Non, car le prix change.", "Oui, car on ajoute toujours 1,20 au nombre de baguettes.", "On ne peut pas le savoir sans connaître le prix de dix baguettes."]],
  ["Une voiture roule à vitesse constante. La distance parcourue est-elle proportionnelle à la durée du trajet ?", "Oui, car la même distance est parcourue pendant chaque unité de temps.", ["Non, car la durée augmente.", "Oui, uniquement si le trajet dure une heure.", "Non, car distance et durée n’ont pas la même unité."]],
  ["Des pommes sont vendues 3 € le kilogramme, sans réduction. Le prix est-il proportionnel à la masse achetée ?", "Oui, le prix est toujours la masse multipliée par 3.", ["Non, car une masse ne se mesure pas en euros.", "Oui, car le prix augmente toujours de 3 €, quelle que soit la masse ajoutée.", "On ne peut le savoir qu’après avoir acheté 3 kg."]],
  ["Une recette pour 4 personnes utilise 200 g de farine. Si les quantités sont adaptées à l’identique, la farine est-elle proportionnelle au nombre de personnes ?", "Oui, car toutes les quantités sont multipliées par le même facteur.", ["Non, car le nombre de personnes est entier.", "Oui, parce qu’il faut toujours ajouter 200 g.", "Non, car la farine se mesure en grammes."]],
  ["On remplit un réservoir à débit constant, vide au départ. Le volume versé est-il proportionnel à la durée ?", "Oui, car le débit reste constant et le réservoir est vide au départ.", ["Non, car le volume augmente.", "Oui, même si le débit change.", "Non, car une durée ne se mesure pas en litres."]],
  ["Le périmètre d’un carré est-il proportionnel à la longueur de son côté ?", "Oui, car le périmètre vaut toujours quatre fois la longueur du côté.", ["Non, car un carré a quatre côtés.", "Oui, car on ajoute toujours 4 cm.", "Non, car le périmètre dépend aussi de l’aire."]],
  ["Tous les billets d’entrée coûtent 8 €. Le prix total est-il proportionnel au nombre de billets ?", "Oui, le prix total vaut 8 fois le nombre de billets.", ["Non, car le nombre de billets est entier.", "Oui, car le prix total augmente toujours de 1 €.", "On ne peut pas le savoir pour plus de dix billets."]],
  ["Une location coûte 6 € par heure, sans frais de départ. Le coût est-il proportionnel à la durée ?", "Oui, car il n’y a pas de frais fixe et le tarif horaire est constant.", ["Non, car une heure ne vaut pas un euro.", "Oui, même si un forfait de départ est ajouté.", "Non, car la durée peut comporter des minutes."]],
  ["Chaque tour de piste mesure 400 m. La distance parcourue est-elle proportionnelle au nombre de tours ?", "Oui, la distance vaut 400 m multipliés par le nombre de tours.", ["Non, car un tour revient au point de départ.", "Oui, parce qu’on ajoute 1 au nombre de mètres.", "Non, car 400 est supérieur au nombre de tours."]],
  ["Chaque boîte contient 12 craies. Le nombre total de craies est-il proportionnel au nombre de boîtes ?", "Oui, le total vaut 12 fois le nombre de boîtes.", ["Non, car les boîtes et les craies sont différentes.", "Oui, car on ajoute toujours une craie.", "On ne peut pas le savoir sans ouvrir toutes les boîtes."]]
];
proportionalSituations.forEach(([prompt, correct, distractors], index) => set(600561 + index, {
  prompt, correct, distractors,
  explanation: correct,
  comment: "Énoncé et distracteurs diversifiés pour évaluer réellement l’identification d’une situation proportionnelle."
}));

const nonProportional = [
  ["L’âge d’une personne permet-il de calculer sa taille avec un coefficient constant ?", "Non, deux personnes du même âge peuvent avoir des tailles différentes."],
  ["L’aire d’un carré est-elle proportionnelle à la longueur de son côté ?", "Non, l’aire dépend du carré de la longueur du côté."],
  ["La température extérieure est-elle proportionnelle à l’heure de la journée ?", "Non, aucun coefficient constant ne relie l’heure et la température."],
  ["La pointure d’un enfant est-elle proportionnelle à son âge ?", "Non, la pointure n’augmente pas selon un coefficient constant."],
  ["Une course de taxi comprend 4 € de prise en charge puis 2 € par kilomètre. Le prix est-il proportionnel à la distance ?", "Non, le forfait de départ empêche la proportionnalité."],
  ["L’âge moyen d’un groupe est-il proportionnel au nombre de personnes ?", "Non, il dépend des âges des personnes, pas seulement de leur nombre."],
  ["Pour une distance fixée, la durée est-elle proportionnelle à la vitesse ?", "Non, quand la vitesse augmente, la durée diminue."],
  ["L’aire d’un disque est-elle proportionnelle à son rayon ?", "Non, l’aire dépend du carré du rayon."],
  ["Dans un livre de 200 pages, le nombre de pages restantes est-il proportionnel au nombre de pages lues ?", "Non, pages restantes = 200 − pages lues."],
  ["Sans modèle précis, la température est-elle proportionnelle à l’altitude ?", "Non, on ne dispose pas d’un coefficient constant valable dans toute situation."]
];
nonProportional.forEach(([prompt, correct], index) => set(600571 + index, {
  prompt,
  correct,
  distractors: ["Oui, car les deux grandeurs peuvent varier.", "Oui, car on peut toujours calculer un rapport.", "On peut l’affirmer à partir d’une seule mesure."],
  explanation: correct,
  comment: "La question demande désormais explicitement si un coefficient constant relie les grandeurs."
}));

const additiveData = [
  [2,6,3,9,5,15],[4,12,5,15,9,27],[3,8,6,16,9,24],[5,20,2,8,7,28],[7,14,3,6,10,20],
  [4,10,8,20,12,30],[6,18,5,15,11,33],[9,27,4,12,13,39],[12,30,8,20,20,50],[15,45,7,21,22,66]
];
additiveData.forEach(([q1,p1,q2,p2,total,answer], index) => set(600591 + index, {
  prompt: `Dans un tableau de proportionnalité :\n${q1} objets → ${p1} €\n${q2} objets → ${p2} €\n\nSans passer par l’unité, déduis le prix de ${total} objets.`,
  correct: `${answer} €`,
  distractors: [`${answer + 1} €`, `${answer - 1} €`, `${total + answer} €`],
  explanation: `${total} = ${q1} + ${q2}, donc le prix associé vaut ${p1} + ${p2} = ${answer} €.`,
  comment: "L’énoncé met explicitement en évidence la linéarité additive."
}));

for (let id = 600611; id <= 600620; id += 1) {
  const q = current(id);
  const match = q.question.match(/quantité ([\d,]+) → prix ([\d,]+) € ; quantité ([\d,]+) → prix ([\d,]+) €.*quantité ([\d,]+)/);
  if (!match) throw new Error(`Lecture de tableau impossible pour ${id}.`);
  const [, q1, p1, q2, p2, asked] = match;
  set(id, {
    prompt: `Lis ce tableau de proportionnalité :\n\nQuantité | ${q1} | ${q2}\nPrix (€) | ${p1} | ${p2}\n\nQuel prix correspond à la quantité ${asked} ?`,
    explanation: `Dans la colonne de la quantité ${asked}, on lit directement le prix associé.`,
    comment: "Un tableau lisible est désormais affiché dans l’énoncé."
  });
}

for (let id = 600621; id <= 600630; id += 1) {
  const q = current(id);
  const match = q.question.match(/: ([\d,]+) correspond à ([\d,]+).*à ([\d,]+)/);
  if (!match) throw new Error(`Tableau à compléter impossible pour ${id}.`);
  const [, q1, value1, asked] = match;
  set(id, {
    prompt: `Complète ce tableau de proportionnalité :\n\nPremière ligne | ${q1} | ${asked}\nDeuxième ligne | ${value1} | ?\n\nQuelle valeur remplace le point d’interrogation ?`,
    explanation: `Le même coefficient de proportionnalité relie les deux lignes du tableau.`,
    comment: "Le couple de lignes est présenté sous la forme d’un véritable petit tableau."
  });
}

for (const id of [600634,600637,600638,600639,600640]) {
  let prompt = current(id).question;
  prompt = prompt.replace("2 cm représente", "2 cm représentent")
    .replace("5 cm représente", "5 cm représentent")
    .replace("4 cm représente", "4 cm représentent")
    .replace("Que représentent 1,6 cm", "Que représente 1,6 cm");
  set(id, {
    prompt,
    explanation: current(id).reponseTexte + " est la longueur réelle obtenue par proportionnalité.",
    comment: "Accord corrigé : singulier pour une quantité inférieure à 2, pluriel à partir de 2."
  });
}

for (let id = 600641; id <= 600650; id += 1) {
  const q = current(id);
  const match = q.question.match(/pour (.+?) : ([\d,]+) livres et ([\d,]+) jeux/);
  if (!match) throw new Error(`Tableau de données impossible pour ${id}.`);
  const [, day, books, games] = match;
  set(id, {
    prompt: `Observe le tableau :\n\nJour | Livres | Jeux\n${day[0].toUpperCase() + day.slice(1)} | ${books} | ${games}\n\nCombien de livres sont indiqués pour ${day} ?`,
    explanation: `À l’intersection de la ligne « ${day} » et de la colonne « Livres », on lit ${books}.`,
    comment: "Le tableau est maintenant visible directement dans l’énoncé."
  });
}

for (let id = 600651; id <= 600660; id += 1) {
  const q = current(id);
  const match = q.question.match(/barre A atteint (\d+) et la barre B atteint (\d+)/);
  const a = Number(match[1]);
  const b = Number(match[2]);
  set(id, {
    prompt: `Observe ce diagramme en barres :\n\nA | ${"█".repeat(a)} ${a}\nB | ${"█".repeat(b)} ${b}\n\nQuelle valeur représente la barre B ?`,
    explanation: `La barre B atteint la graduation ${b}.`,
    comment: "Le diagramme est représenté visuellement dans l’énoncé."
  });
}

const circleSymbols = ["◐","◔","◕","●","○  (1 secteur sur 10)","◐","◐","○  (20 secteurs sur 100)","●","○  (5 secteurs sur 100)"];
for (let id = 600661; id <= 600670; id += 1) {
  const q = current(id);
  set(id, {
    prompt: `${circleSymbols[id - 600661]}  ${q.question}`,
    explanation: q.reponseTexte + " du disque est coloré.",
    comment: "Un pictogramme circulaire accompagne désormais la description."
  });
}

for (let id = 600671; id <= 600680; id += 1) {
  const q = current(id);
  const match = q.question.match(/\((\d+) h ; (\d+)\)/);
  const hour = Number(match[1]);
  const value = Number(match[2]);
  set(id, {
    prompt: `Observe cet extrait de courbe :\n\nValeur\n${value} ┤          ●\n${value - 3} ┤      ● ╱\n    └────────────\n      ${hour - 1} h   ${hour} h\n\nQuelle valeur lit-on à ${hour} h ?`,
    explanation: `À l’abscisse ${hour} h, le point de la courbe se trouve à la valeur ${value}.`,
    comment: "Un repère et un extrait de courbe rendent la lecture concrète."
  });
}

const surveyDistractors = {
  600681: ["Choisir les personnes à interroger", "Préparer un tableau de résultats", "Formuler une conclusion"],
  600682: ["Choisir les catégories de classement", "Préparer la représentation graphique", "Rédiger la conclusion"],
  600683: ["Vérifier la question de départ", "Choisir une représentation", "Interpréter les résultats"],
  600684: ["Vérifier la question de départ", "Recueillir de nouvelles réponses", "Rédiger le questionnaire"],
  600685: ["Présenter uniquement les données", "Décrire la méthode de recueil", "Ajouter une nouvelle question"],
  600686: ["Questionner, organiser, recueillir, représenter", "Recueillir, questionner, représenter, organiser", "Questionner, représenter, recueillir, organiser"],
  600687: ["Pour faciliter la représentation finale", "Pour réduire le nombre de réponses", "Pour modifier les résultats obtenus"],
  600688: ["Que les catégories sont déjà remplies", "Que les réponses donnent toutes le même résultat", "Que le graphique final est déjà choisi"],
  600689: ["Pour calculer correctement les effectifs", "Pour obtenir davantage de réponses", "Pour rendre toutes les catégories égales"],
  600690: ["Choisir une autre population", "Modifier les catégories après coup", "Recueillir une seconde fois les mêmes réponses"]
};
for (let id = 600681; id <= 600690; id += 1) {
  set(id, {
    distractors: surveyDistractors[id],
    explanation: current(id).reponseTexte + " est l’étape adaptée.",
    comment: "Les distracteurs sont désormais plausibles et correspondent à d’autres étapes possibles d’une enquête."
  });
}

const payload = [...corrections.values()].sort((a,b) => a.legacy_id - b.legacy_id);
for (const correction of payload) {
  if (correction.choices.length !== 4 || new Set(correction.choices).size !== 4) {
    throw new Error(`Les quatre choix de ${correction.legacy_id} doivent être distincts.`);
  }
  if (correction.correct_position < 1 || correction.correct_position > 4) {
    throw new Error(`Position correcte invalide pour ${correction.legacy_id}.`);
  }
}
if (new Set(payload.map(item => item.legacy_id)).size !== payload.length) {
  throw new Error("Un identifiant de question est présent plusieurs fois.");
}
const payloadJson = JSON.stringify(payload).replace(/'/g, "''");
const ids = payload.map(item => item.legacy_id);

const sql = `/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/116_correct_maths_feedback_2026_07_28.sql
 Target       : PostgreSQL / Supabase
 Purpose      : Apply the validator feedback exported on 28 July 2026.
 Idempotent   : Yes
===============================================================================
*/

begin;

do $block$
declare
  correction jsonb;
  answer record;
  selected_question_id uuid;
  source_explanation text;
  target_version_id uuid;
  target_version_number integer := 2;
  corrections jsonb := '${payloadJson}'::jsonb;
begin
  for correction in select value from jsonb_array_elements(corrections)
  loop
    select q.id, qv.correction_explanation
    into selected_question_id, source_explanation
    from public.questions q
    join public.question_versions qv
      on qv.question_id = q.id
     and qv.version_number = 1
    where q.legacy_id = (correction->>'legacy_id')::integer;

    if selected_question_id is null then
      raise exception 'Question % ou version source 1 introuvable.', correction->>'legacy_id';
    end if;

    target_version_id := md5(
      'cap-college:feedback-2026-07-28:' ||
      (correction->>'legacy_id') || ':v2'
    )::uuid;

    insert into public.question_versions (
      id, question_id, version_number, prompt, correction_explanation,
      change_comment, review_status, authored_by
    )
    values (
      target_version_id,
      selected_question_id,
      target_version_number,
      correction->>'prompt',
      coalesce(nullif(correction->>'explanation',''), source_explanation),
      correction->>'change_comment',
      'unreviewed'::public.review_status,
      auth.uid()
    )
    on conflict (question_id, version_number) do update
    set prompt = excluded.prompt,
        correction_explanation = excluded.correction_explanation,
        change_comment = excluded.change_comment,
        review_status = excluded.review_status
    returning id into target_version_id;

    delete from public.answer_choices where question_version_id = target_version_id;

    for answer in
      select value #>> '{}' as content, ordinality::smallint as sort_order
      from jsonb_array_elements(correction->'choices')
           with ordinality as choice(value, ordinality)
    loop
      insert into public.answer_choices (
        id, question_version_id, choice_key, content, is_correct, sort_order
      )
      values (
        md5(
          'cap-college:feedback-2026-07-28:' ||
          (correction->>'legacy_id') || ':v2:' || answer.sort_order
        )::uuid,
        target_version_id,
        chr(64 + answer.sort_order),
        answer.content,
        answer.sort_order = (correction->>'correct_position')::integer,
        answer.sort_order
      );
    end loop;

    update public.questions
    set current_version_number = target_version_number,
        status = 'in_review'::public.question_status,
        updated_at = statement_timestamp()
    where id = selected_question_id;
  end loop;
end;
$block$;

commit;
`;

const verify = `with corrected as (
  select q.id, q.legacy_id, q.status, q.current_version_number, qv.id as version_id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = 2
  where q.legacy_id = any(array[${ids.join(",")}])
),
counts as (
  select
    c.id,
    count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices
  from corrected c
  left join public.answer_choices ac on ac.question_version_id = c.version_id
  group by c.id
)
select jsonb_build_object(
  'corrected_questions', (select count(*) from corrected),
  'questions_in_review', (select count(*) from corrected where status = 'in_review'),
  'questions_with_four_choices', (select count(*) from counts where choices = 4),
  'questions_with_one_correct_choice', (select count(*) from counts where correct_choices = 1),
  'previous_versions_preserved', (
    select count(*) from corrected c
    where exists (
      select 1 from public.question_versions old
      where old.question_id = c.id and old.version_number = 1
    )
  ),
  'visual_questions', (
    select count(*) from corrected c
    join public.question_versions qv on qv.id = c.version_id
    where qv.prompt like '%' || chr(10) || '%'
  )
) as verification;
`;

fs.writeFileSync(path.join(root, "database", "116_correct_maths_feedback_2026_07_28.sql"), sql, "utf8");
fs.writeFileSync(path.join(root, "database", "117_verify_maths_feedback_2026_07_28.sql"), verify, "utf8");
console.log(JSON.stringify({ corrections: payload.length, min: ids[0], max: ids.at(-1) }));
