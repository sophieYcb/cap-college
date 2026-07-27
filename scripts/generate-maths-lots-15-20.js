const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const contentsDir = path.join(root, "contenus");
const databaseDir = path.join(root, "database");

function question(prompt, correct, distractors, explanation, difficulty = 2) {
  return { prompt, correct: String(correct), distractors: distractors.map(String), explanation, difficulty };
}

function placeAnswers(items, startLegacy) {
  return items.map((item, index) => {
    const correctIndex = index % 4;
    const choices = item.distractors.slice(0, 3);
    choices.splice(correctIndex, 0, item.correct);
    return {
      code: `M6-${String(startLegacy + index).padStart(4, "0")}`,
      microSkill: item.microSkill,
      difficulty: item.difficulty,
      prompt: item.prompt,
      choices,
      correctIndex,
      explanation: item.explanation
    };
  });
}

function tagged(code, items) {
  return items.map(item => ({ ...item, microSkill: code }));
}

const metadata = {
  m6_mes_convertir_duree: ["Convertir des durées", "Convertir des durées", "Une heure vaut 60 minutes et une minute vaut 60 secondes.", "2 h 30 min = 150 min.", "Convertir des heures, minutes et secondes."],
  m6_prop_definition: ["Reconnaître la définition de deux grandeurs proportionnelles", "Comprendre la proportionnalité", "Deux grandeurs sont proportionnelles lorsque l’on passe de l’une à l’autre en multipliant toujours par le même nombre.", "Si chaque carnet coûte 3 €, le prix est toujours le nombre de carnets multiplié par 3.", "Identifier la définition d’une relation de proportionnalité."],
  m6_prop_identifier: ["Identifier une situation de proportionnalité", "Reconnaître une situation proportionnelle", "Dans une situation proportionnelle, le même coefficient multiplicateur relie toutes les valeurs.", "À prix unitaire constant, le prix est proportionnel à la quantité.", "Identifier des situations usuelles de proportionnalité."],
  m6_prop_non_proportionnelle: ["Identifier une situation non proportionnelle", "Reconnaître une situation non proportionnelle", "Une situation n’est pas proportionnelle si le rapport entre les deux grandeurs n’est pas constant.", "L’âge et la taille d’une personne ne sont pas proportionnels.", "Identifier des situations qui ne relèvent pas de la proportionnalité."],
  m6_prop_linearite_multiplicative: ["Utiliser la linéarité multiplicative", "Multiplier dans un tableau de proportionnalité", "Dans une situation proportionnelle, si une quantité est multipliée par un nombre, la grandeur associée est multipliée par le même nombre.", "3 objets coûtent 12 € ; 6 objets coûtent 24 €.", "Utiliser un facteur multiplicatif pour compléter une situation proportionnelle."],
  m6_prop_linearite_additive: ["Utiliser la linéarité additive", "Additionner dans un tableau de proportionnalité", "Dans une situation proportionnelle, on peut additionner deux quantités et additionner leurs valeurs associées.", "2 objets coûtent 6 € et 3 objets coûtent 9 € ; 5 objets coûtent 15 €.", "Utiliser l’addition de colonnes dans une situation proportionnelle."],
  m6_prop_retour_unite: ["Résoudre par retour à l’unité", "Passer par la valeur pour une unité", "On cherche d’abord la valeur pour une unité, puis on la multiplie par la quantité demandée.", "5 cahiers coûtent 15 € : un cahier coûte 3 €, donc 8 cahiers coûtent 24 €.", "Résoudre une situation proportionnelle par retour à l’unité."],
  m6_prop_lire_tableau: ["Lire un tableau de proportionnalité", "Lire un tableau de proportionnalité", "Dans un tableau de proportionnalité, les valeurs d’une même colonne sont associées.", "Si la colonne indique 4 objets et 12 €, alors 4 objets coûtent 12 €.", "Lire une valeur ou une association dans un tableau proportionnel décrit par écrit."],
  m6_prop_completer_tableau: ["Compléter un tableau de proportionnalité", "Compléter un tableau de proportionnalité", "On utilise le même coefficient de proportionnalité dans toutes les colonnes.", "Si le prix vaut 4 fois la quantité, 7 objets coûtent 28 €.", "Calculer une valeur manquante dans un tableau proportionnel."],
  m6_prop_echelle: ["Résoudre un problème simple d’échelle", "Utiliser une échelle", "Une échelle indique la correspondance entre une longueur sur le dessin et la longueur réelle.", "À l’échelle 1 cm pour 5 m, 3 cm représentent 15 m.", "Calculer une longueur réelle ou représentée avec une échelle simple."],
  m6_data_lire_tableau: ["Lire une donnée dans un tableau", "Lire une information dans un tableau", "On repère la ligne et la colonne demandées, puis on lit la valeur à leur intersection.", "À la ligne Mardi et dans la colonne Livres, on lit le nombre de livres du mardi.", "Lire une valeur dans un tableau décrit clairement."],
  m6_data_lire_barres: ["Lire une donnée dans un diagramme en barres", "Lire un diagramme en barres", "La hauteur de chaque barre correspond à une valeur indiquée par l’axe gradué.", "Une barre atteignant la graduation 12 représente la valeur 12.", "Lire et comparer des valeurs dans un diagramme en barres décrit par écrit."],
  m6_data_lire_circulaire: ["Lire une donnée dans un diagramme circulaire", "Lire un diagramme circulaire", "Un disque entier représente 100 % ; un demi-disque 50 % et un quart de disque 25 %.", "Un demi-disque colorié représente 50 %.", "Lire des proportions simples dans un diagramme circulaire décrit par écrit."],
  m6_data_lire_courbe: ["Lire une donnée sur une courbe", "Lire une courbe", "On repère l’abscisse demandée puis on lit la valeur correspondante sur l’axe vertical.", "À 10 h, un point placé à 18 indique une valeur de 18.", "Lire et comparer des points sur une courbe décrite par écrit."],
  m6_data_planifier_enquete: ["Identifier les étapes d’une enquête", "Organiser une enquête", "On définit la question, recueille les réponses, organise les données puis présente les résultats.", "Questionner, recueillir, classer puis représenter.", "Reconnaître l’ordre et le rôle des étapes d’une enquête."],
  m6_data_construire_tableau: ["Choisir un tableau adapté à des données", "Choisir comment organiser des données", "Un tableau doit présenter des intitulés clairs et une ligne ou une colonne pour chaque catégorie utile.", "Pour comparer les sports par classe, on prévoit les classes et les sports dans les en-têtes.", "Choisir une organisation de tableau adaptée à une question."],
  m6_data_filtrer: ["Filtrer les données d’un tableau selon un critère", "Filtrer des données", "Filtrer consiste à ne conserver que les lignes qui respectent un critère donné.", "Pour garder les scores supérieurs à 10, on écarte 10 et les valeurs plus petites.", "Sélectionner les données correspondant à un ou plusieurs critères."],
  m6_proba_bornes: ["Savoir qu’une probabilité est comprise entre 0 et 1", "Connaître les valeurs possibles d’une probabilité", "Une probabilité est comprise entre 0 et 1 : 0 signifie impossible et 1 signifie certain.", "0,4 peut être une probabilité ; 1,4 ne le peut pas.", "Reconnaître une valeur possible de probabilité."],
  m6_proba_issues: ["Recenser les issues d’une expérience simple", "Lister les résultats possibles", "Une issue est un résultat possible de l’expérience aléatoire.", "Pour un dé à six faces, les issues sont 1, 2, 3, 4, 5 et 6.", "Recenser les issues d’expériences simples."],
  m6_proba_favorables: ["Identifier les issues favorables à un événement", "Repérer les résultats favorables", "Les issues favorables sont les résultats qui réalisent l’événement étudié.", "Pour obtenir un nombre pair sur un dé, les issues favorables sont 2, 4 et 6.", "Identifier les issues favorables parmi les issues possibles."],
  m6_proba_equiprobable: ["Calculer une probabilité en situation d’équiprobabilité", "Calculer une probabilité simple", "Lorsque les issues sont équiprobables, la probabilité vaut nombre d’issues favorables divisé par nombre total d’issues.", "Sur un dé, P(nombre pair) = 3/6 = 1/2.", "Calculer une probabilité simple avec des issues équiprobables."],
  m6_proba_fraction_decimal_pct: ["Passer entre fraction, décimal et pourcentage pour une probabilité", "Écrire une probabilité de plusieurs façons", "Une même probabilité peut s’écrire sous forme de fraction, de nombre décimal ou de pourcentage.", "1/2 = 0,5 = 50 %.", "Associer des écritures équivalentes d’une probabilité simple."],
  m6_proba_frequence: ["Comparer une fréquence observée à une probabilité", "Comparer expérience et probabilité", "La fréquence observée peut différer de la probabilité théorique ; elle tend à s’en rapprocher quand le nombre d’essais augmente.", "Sur 20 lancers, obtenir 8 piles donne une fréquence de 8/20 = 40 %.", "Calculer une fréquence et la comparer à une probabilité théorique."],
  m6_alg_nombre_inconnu: ["Représenter un nombre inconnu", "Représenter un nombre que l’on ne connaît pas", "Un nombre inconnu peut être représenté par une lettre, une case ou un symbole.", "Dans x + 5 = 12, x représente le nombre inconnu.", "Identifier ou choisir une représentation d’un nombre inconnu."]
};

const durationPairs = [
  ["2 h","120 min"],["3 h 30 min","210 min"],["90 min","1 h 30 min"],["4 min","240 s"],["150 s","2 min 30 s"],
  ["1 h 15 min","75 min"],["300 min","5 h"],["2 h 05 min","125 min"],["3 600 s","1 h"],["1,5 h","90 min"]
];
const durationItems = durationPairs.map(([from,to],i)=>question(`Convertis ${from}.`,to,[i%2?"150 min":"60 min",i%3?"180 min":"2 h",i%2?"90 s":"200 min"],`${from} correspond à ${to}.`,i<3?1:i<7?2:3));

const proportionalDefinitions = [
  question("Quelle phrase définit deux grandeurs proportionnelles ?","On passe toujours de l’une à l’autre en multipliant par le même nombre.",["Elles augmentent toujours de 1.","Elles ont toujours la même unité.","Elles sont toujours égales."],"La présence d’un coefficient multiplicateur constant définit la proportionnalité.",1),
  question("Dans une situation proportionnelle, le coefficient de proportionnalité est…","constant",["variable","toujours égal à 1","une unité de longueur"],"Le même coefficient relie toutes les valeurs.",1),
  question("Si y est proportionnel à x, quelle relation convient ?","y = k × x",["y = x + k","y = x − k","y = k ÷ x"],"Une relation proportionnelle s’écrit y = k × x.",2),
  question("Dans un tableau de proportionnalité, comment passe-t-on d’une ligne à l’autre ?","En multipliant toutes les valeurs par un même nombre.",["En ajoutant toujours 1.","En changeant d’opération à chaque colonne.","En recopiant les valeurs."],"Le coefficient est identique dans toutes les colonnes.",2),
  question("Quel élément permet de vérifier une proportionnalité ?","Un rapport constant",["Une différence constante","Un total égal à 100","Une même unité"],"Les rapports entre valeurs associées doivent être constants.",2),
  question("Deux grandeurs sont proportionnelles si doubler l’une…","double l’autre",["ajoute 2 à l’autre","divise l’autre par 2","ne change pas l’autre"],"La multiplication d’une grandeur entraîne la même multiplication de l’autre.",2),
  question("Dans une proportionnalité, tripler une quantité revient à…","tripler la valeur associée",["ajouter 3 à la valeur","retirer 3 à la valeur","mettre la valeur au carré"],"La linéarité multiplicative conserve le même facteur.",2),
  question("Quel mot caractérise le nombre qui relie deux grandeurs proportionnelles ?","coefficient",["périmètre","reste","fréquence"],"On parle de coefficient de proportionnalité.",3),
  question("Si 1 unité correspond à k, alors n unités correspondent à…","n × k",["n + k","n − k","k ÷ n"],"On multiplie la valeur unitaire par la quantité.",3),
  question("Une relation proportionnelle signifie-t-elle que les valeurs augmentent toujours de 1 ?","Non, elles sont multipliées par un coefficient constant.",["Oui, elles augmentent toujours de 1.","Oui, les deux valeurs sont toujours identiques.","Non, car aucun coefficient n’existe."],"Ce qui compte est le coefficient multiplicateur constant, pas une augmentation constante de 1.",3)
];

const propSituations = [
  ["À prix unitaire fixe, le prix et le nombre de cahiers.","proportionnelle"],
  ["La distance parcourue à vitesse constante et la durée.","proportionnelle"],
  ["La masse de pommes et leur prix au kilogramme fixe.","proportionnelle"],
  ["Le nombre de recettes identiques et la quantité de farine.","proportionnelle"],
  ["Le nombre de litres versés et le volume total obtenu.","proportionnelle"],
  ["Le côté d’un carré et son périmètre.","proportionnelle"],
  ["Le nombre de billets identiques et leur prix total.","proportionnelle"],
  ["La durée d’une location sans forfait fixe et son coût horaire.","proportionnelle"],
  ["Le nombre de tours identiques et la distance parcourue.","proportionnelle"],
  ["Le nombre de boîtes identiques et le nombre total d’objets.","proportionnelle"]
].map(([s,c],i)=>question(`La situation suivante est-elle proportionnelle ? ${s}`,c,["non proportionnelle","impossible à étudier","toujours égale"],`Le même coefficient relie les deux grandeurs.`,i<3?1:i<7?2:3));

const nonPropSituations = [
  "L’âge d’une personne et sa taille.",
  "Le côté d’un carré et son aire.",
  "La température extérieure et l’heure de la journée.",
  "Le nombre d’années et la pointure d’un enfant.",
  "Le prix d’une course de taxi avec un forfait de départ.",
  "Le nombre de personnes et leur âge moyen.",
  "La durée d’un trajet et la vitesse lorsque la distance est fixe.",
  "Le rayon d’un disque et son aire.",
  "Le nombre de pages lues et le nombre de pages restant dans un livre.",
  "L’altitude et la température sans règle constante."
].map((s,i)=>question(`Quelle qualification convient ? ${s}`,"non proportionnelle",["proportionnelle","toujours égale","impossible à mesurer"],"Le rapport entre les deux grandeurs n’est pas constant.",i<3?1:i<7?2:3));

function multiplicativeItems() {
  const data=[[3,12,6,24],[4,10,12,30],[5,15,20,60],[2,7,10,35],[6,18,12,36],[3,8,15,40],[7,21,28,84],[5,12,25,60],[8,14,40,70],[9,27,63,189]];
  return data.map(([a,b,c,d],i)=>question(`${a} objets correspondent à ${b} unités. Par multiplication, à combien correspondent ${c} objets ?`,d,[d/2,d+a,d+b],`${c} = ${a} × ${c/a}, donc ${b} × ${c/a} = ${d}.`,i<3?1:i<7?2:3));
}
function additiveItems() {
  const data=[[2,6,3,9,5,15],[4,12,5,15,9,27],[3,8,6,16,9,24],[5,20,2,8,7,28],[7,14,3,6,10,20],[4,10,8,20,12,30],[6,18,5,15,11,33],[9,27,4,12,13,39],[12,30,8,20,20,50],[15,45,7,21,22,66]];
  return data.map(([a,b,c,d,e,f],i)=>question(`${a} objets coûtent ${b} € et ${c} objets coûtent ${d} €. Combien coûtent ${e} objets ?`,`${f} €`,[`${b+d+1} €`,`${f-e} €`,`${f+e} €`],`On additionne les colonnes : ${a} + ${c} = ${e} et ${b} + ${d} = ${f}.`,i<3?1:i<7?2:3));
}
function unitItems() {
  const data=[[5,15,8,24],[4,20,7,35],[6,18,10,30],[8,32,3,12],[5,12.5,12,30],[9,27,14,42],[7,21,20,60],[12,48,5,20],[15,30,22,44],[25,75,16,48]];
  return data.map(([n,p,w,r],i)=>question(`${n} objets coûtent ${String(p).replace(".",",")} €. Combien coûtent ${w} objets ?`,`${String(r).replace(".",",")} €`,[`${String(r+n).replace(".",",")} €`,`${String(r-n).replace(".",",")} €`,`${String(p).replace(".",",")} €`],`Une unité coûte ${String(p/n).replace(".",",")} €, puis on multiplie par ${w}.`,i<3?1:i<7?2:3));
}
function readTableItems() {
  const data=[[2,6,5,15],[3,12,7,28],[4,10,8,20],[5,20,9,36],[6,18,11,33],[7,14,15,30],[8,24,12,36],[9,45,13,65],[10,25,18,45],[12,36,20,60]];
  return data.map(([a,b,c,d],i)=>question(`Tableau : quantité ${a} → prix ${b} € ; quantité ${c} → prix ${d} €. Quel prix est associé à la quantité ${c} ?`,`${d} €`,[`${b} €`,`${c} €`,`${a+d} €`],`Dans la colonne de la quantité ${c}, on lit le prix ${d} €.`,i<3?1:i<7?2:3));
}
function completeTableItems() {
  const data=[[2,6,7,21],[3,12,8,32],[4,10,12,30],[5,20,9,36],[6,18,14,42],[7,14,25,50],[8,24,15,45],[9,45,16,80],[10,25,22,55],[12,36,30,90]];
  return data.map(([a,b,c,d],i)=>question(`Tableau proportionnel : ${a} correspond à ${b}. Quelle valeur correspond à ${c} ?`,d,[d+a,d-a,b+c],`Le coefficient vaut ${b/a}; ${c} × ${b/a} = ${d}.`,i<3?1:i<7?2:3));
}
function scaleItems() {
  const data=[[1,5,3,15],[1,10,4,40],[1,20,6,120],[2,10,7,35],[1,50,2.5,125],[1,100,3.2,320],[2,5,12,30],[5,20,8,32],[1,250,1.6,400],[4,100,7,175]];
  return data.map(([map,real,len,result],i)=>question(`Sur un plan, ${map} cm représente ${real} m. Que représentent ${String(len).replace(".",",")} cm ?`,`${String(result).replace(".",",")} m`,[`${String(result+real).replace(".",",")} m`,`${String(result/2).replace(".",",")} m`,`${String(len*real).replace(".",",")} cm`],`On applique la même proportion : ${String(len).replace(".",",")} cm représentent ${String(result).replace(".",",")} m.`,i<3?1:i<7?2:3));
}

const tableItems = Array.from({length:10},(_,i)=>{
  const days=["lundi","mardi","mercredi","jeudi","vendredi"];
  const day=days[i%5], books=6+i*2, games=3+i;
  return question(`Un tableau indique pour ${day} : ${books} livres et ${games} jeux. Combien de livres sont indiqués pour ${day} ?`,books,[games,books+games,books-2],`À la ligne ${day}, dans la colonne des livres, on lit ${books}.`,i<3?1:i<7?2:3);
});
const barItems = Array.from({length:10},(_,i)=>{
  const a=5+i,b=9+i*2;
  return question(`Dans un diagramme en barres, la barre A atteint ${a} et la barre B atteint ${b}. Quelle valeur représente la barre B ?`,b,[a,b-a,a+b],`La hauteur de la barre B atteint la graduation ${b}.`,i<3?1:i<7?2:3);
});
const circularItems = [
  ["La moitié du disque est colorée","50 %"],["Un quart du disque est coloré","25 %"],["Trois quarts du disque sont colorés","75 %"],["Le disque entier est coloré","100 %"],["Un dixième du disque est coloré","10 %"],
  ["Deux quarts du disque sont colorés","50 %"],["Un demi-disque est coloré","50 %"],["Un secteur représentant 20 parts sur 100 est coloré","20 %"],["Quatre quarts du disque sont colorés","100 %"],["Un secteur représentant 5 parts sur 100 est coloré","5 %"]
].map(([description,pct],i)=>question(`Dans un diagramme circulaire, ${description.toLowerCase()}. Quelle proportion cela représente-t-il ?`,pct,["10 %","20 %","80 %"].filter(x=>x!==pct).concat(["0 %"]).slice(0,3),`${description} : cela correspond à ${pct}.`,i<3?1:i<7?2:3));
const curveItems = Array.from({length:10},(_,i)=>{
  const hour=8+i, value=12+i*3;
  return question(`Une courbe passe par le point (${hour} h ; ${value}). Quelle valeur lit-on à ${hour} h ?`,value,[hour,value-3,value+3],`À l’abscisse ${hour} h, l’ordonnée vaut ${value}.`,i<3?1:i<7?2:3);
});
const surveyItems = [
  question("Quelle est la première étape d’une enquête ?","Définir la question étudiée",["Tracer un graphique","Inventer les résultats","Supprimer des réponses"],"On commence par définir précisément ce que l’on cherche.",1),
  question("Après avoir défini la question, que faut-il faire ?","Recueillir les données",["Publier une conclusion","Effacer le questionnaire","Choisir le résultat préféré"],"On recueille ensuite les réponses ou mesures.",1),
  question("Après le recueil, quelle étape facilite l’analyse ?","Organiser les données",["Modifier les réponses","Recommencer sans raison","Ignorer les catégories"],"Les données doivent être classées dans un tableau ou des catégories.",1),
  question("Quelle étape vient généralement après l’organisation des données ?","Les représenter",["Les cacher","Changer la question","Supprimer les valeurs élevées"],"Une représentation aide à communiquer les résultats.",2),
  question("À quoi sert une conclusion d’enquête ?","Répondre à la question de départ",["Ajouter des participants fictifs","Changer toutes les données","Choisir une couleur"],"La conclusion interprète les résultats pour répondre à la question.",2),
  question("Quel ordre est cohérent ?","Questionner, recueillir, organiser, représenter",["Représenter, inventer, questionner, effacer","Conclure, recueillir, questionner, modifier","Organiser, supprimer, inventer, conclure"],"C’est l’ordre logique d’une enquête.",2),
  question("Pourquoi définir les catégories avant de classer les réponses ?","Pour organiser les données de façon cohérente",["Pour obtenir toujours 100 réponses","Pour rendre toutes les réponses identiques","Pour éviter de poser une question"],"Des catégories claires permettent un classement fiable.",2),
  question("Avant de diffuser un questionnaire, que doit-on vérifier ?","Que les questions sont claires",["Que toutes les réponses seront identiques","Que le graphique est déjà terminé","Que la conclusion est écrite"],"Les questions doivent être compréhensibles et adaptées à l’objectif.",3),
  question("Pourquoi noter toutes les réponses recueillies ?","Pour ne pas fausser les résultats",["Pour obtenir le résultat souhaité","Pour réduire arbitrairement l’effectif","Pour éviter tout tableau"],"Écarter des réponses sans raison introduirait un biais.",3),
  question("Quelle action termine normalement l’enquête ?","Interpréter et communiquer les résultats",["Inventer de nouvelles données","Changer les réponses","Supprimer la question initiale"],"On termine par une conclusion et une présentation des résultats.",3)
];
const constructTableItems = [
  question("Pour organiser les sports préférés d’une classe, quel tableau est le plus adapté ?","Un tableau avec une ligne par sport et son effectif",["Un tableau sans titre ni en-têtes","Une seule case vide","Un tableau mélangeant sports et tailles"],"Chaque sport forme une catégorie à laquelle on associe un effectif.",1),
  question("Pour organiser les moyens de transport utilisés par les élèves, quels en-têtes conviennent ?","Moyen de transport et nombre d’élèves",["Prénom et température","Date et longueur","Prix et masse"],"Les en-têtes doivent nommer la catégorie étudiée et son effectif.",1),
  question("Pour noter le nombre de livres lus chaque mois, quels en-têtes conviennent ?","Mois et nombre de livres",["Couleur et masse","Élève et pointure","Jour et température"],"Le tableau associe chaque mois au nombre de livres lus.",1),
  question("Pour relever la température chaque jour, quels en-têtes conviennent ?","Date et température en °C",["Sport et effectif","Livre et prix","Distance et masse"],"Une série chronologique associe ici une date à une température.",2),
  question("Pour compter les animaux observés, quel tableau est adapté ?","Un tableau avec une ligne par espèce et son nombre d’observations",["Un tableau sans nom d’espèce","Une liste qui oublie les effectifs","Un tableau de températures"],"On associe chaque espèce à son effectif observé.",2),
  question("Pour comparer les repas choisis à la cantine, quels en-têtes conviennent ?","Repas et nombre de choix",["Heure et longueur","Classe et température","Prénom et masse"],"Chaque repas constitue une catégorie dont on compte les choix.",2),
  question("Pour noter le temps de trajet de chaque élève, quels en-têtes conviennent ?","Élève et durée du trajet en minutes",["Sport et effectif","Date et température","Livre et prix"],"Chaque élève doit être associé à une durée exprimée avec son unité.",2),
  question("Pour présenter les points obtenus par chaque équipe, quels en-têtes conviennent ?","Équipe et nombre de points",["Jour et température","Objet et masse","Prénom et durée"],"On associe le nom de chaque équipe à son score.",3),
  question("Pour suivre la taille d’une plante chaque semaine, quels en-têtes conviennent ?","Semaine et taille en centimètres",["Sport et nombre d’élèves","Couleur et prix","Livre et température"],"Le tableau associe chaque semaine à une mesure avec son unité.",3),
  question("Pour comparer les masses de déchets collectés selon leur type, quels en-têtes conviennent ?","Type de déchet et masse en kilogrammes",["Date et température","Élève et durée","Sport et effectif"],"Le tableau associe chaque type de déchet à une masse exprimée avec son unité.",3)
];
const filterItems = Array.from({length:10},(_,i)=>{
  const threshold=5+i;
  const values=[threshold-2,threshold,threshold+1,threshold+4];
  return question(`On conserve uniquement les valeurs strictement supérieures à ${threshold}. Laquelle est conservée ?`,threshold+1,[threshold-2,threshold,threshold-1],`${threshold+1} est strictement supérieur à ${threshold}.`,i<3?1:i<7?2:3);
});
const boundsItems = [
  ["0,4","possible"],["1,2","impossible"],["0","possible"],["1","possible"],["−0,1","impossible"],
  ["75 %","possible"],["120 %","impossible"],["1/2","possible"],["5/4","impossible"],["0,99","possible"]
].map(([v,result],i)=>question(`${v} peut-il représenter une probabilité ?`,result,result==="possible"?["impossible","seulement pour un dé","seulement en pourcentage"]:["possible","toujours certaine","toujours nulle"],`Une probabilité doit être comprise entre 0 et 1, soit entre 0 % et 100 %.`,i<3?1:i<7?2:3));
const issueItems = [
  ["une pièce","pile ou face"],["un dé à six faces","1, 2, 3, 4, 5 ou 6"],["une roue rouge, bleue, verte","rouge, bleu ou vert"],["un sac avec boules A et B","A ou B"],["un dé à quatre faces","1, 2, 3 ou 4"],
  ["deux pièces","pile-pile, pile-face, face-pile ou face-face"],["une carte numérotée de 1 à 5","1, 2, 3, 4 ou 5"],["un jour choisi parmi samedi et dimanche","samedi ou dimanche"],["une lettre choisie dans A, B, C","A, B ou C"],["un nombre choisi parmi 0, 1, 2","0, 1 ou 2"]
].map(([exp,outcomes],i)=>question(`Quelles sont les issues possibles de l’expérience suivante : ${exp} ?`,outcomes,["une seule issue","aucune issue","tous les nombres entiers"],`Les résultats possibles sont : ${outcomes}.`,i<3?1:i<7?2:3));
const favorableItems = [
  ["obtenir un nombre pair avec un dé","2, 4 et 6"],["obtenir plus de 4 avec un dé","5 et 6"],["obtenir pile avec une pièce","pile"],["tirer une voyelle parmi A, B, E, F","A et E"],["obtenir moins de 3 avec un dé","1 et 2"],
  ["tirer rouge parmi rouge, bleu, vert","rouge"],["obtenir un multiple de 3 avec un dé","3 et 6"],["choisir un nombre impair parmi 1 à 5","1, 3 et 5"],["obtenir au moins 5 avec un dé","5 et 6"],["tirer B parmi A, B, C","B"]
].map(([event,fav],i)=>question(`Quelles sont les issues favorables pour « ${event} » ?`,fav,["aucune","toutes les issues","une issue impossible"],`Les issues qui réalisent l’événement sont ${fav}.`,i<3?1:i<7?2:3));
const equiprobItems = [
  ["obtenir pile avec une pièce","1/2"],["obtenir 6 avec un dé","1/6"],["obtenir un nombre pair avec un dé","1/2"],["tirer rouge parmi 3 boules dont 1 rouge","1/3"],["obtenir plus de 4 avec un dé","1/3"],
  ["tirer une voyelle parmi A, B, E, F","1/2"],["choisir 1 parmi 5 numéros","1/5"],["obtenir un multiple de 3 avec un dé","1/3"],["tirer bleu parmi 4 boules dont 3 bleues","3/4"],["obtenir moins de 5 avec un dé","2/3"]
].map(([event,p],i)=>question(`Dans une situation équiprobable, quelle est la probabilité de ${event} ?`,p,["1","0","1/4"].filter(x=>x!==p).concat(["2"]).slice(0,3),`On divise le nombre d’issues favorables par le nombre total d’issues : ${p}.`,i<3?1:i<7?2:3));
const representationItems = [
  ["1/2","0,5","50 %"],["1/4","0,25","25 %"],["3/4","0,75","75 %"],["1/10","0,1","10 %"],["2/5","0,4","40 %"],
  ["3/5","0,6","60 %"],["1/5","0,2","20 %"],["4/5","0,8","80 %"],["9/10","0,9","90 %"],["1","1","100 %"]
].map(([f,d,p],i)=>question(`Quelle égalité est correcte pour la probabilité ${f} ?`,`${f} = ${d} = ${p}`,[`${f} = ${d} = 10 %`,`${f} = 0 = 0 %`,`${f} = 1 = 100 %`],`${f}, ${d} et ${p} sont trois écritures de la même probabilité.`,i<3?1:i<7?2:3));
const frequencyItems = [
  [20,8,"40 %"],[50,30,"60 %"],[100,47,"47 %"],[40,10,"25 %"],[25,5,"20 %"],
  [80,60,"75 %"],[10,7,"70 %"],[200,90,"45 %"],[60,30,"50 %"],[120,12,"10 %"]
].map(([n,k,p],i)=>question(`Lors de ${n} essais, l’événement se produit ${k} fois. Quelle est sa fréquence observée ?`,p,[`${k} %`,`${n-k} %`,`100 %`].filter(x=>x!==p),`La fréquence vaut ${k}/${n}, soit ${p}.`,i<3?1:i<7?2:3));
const unknownItems = [
  ["un nombre augmenté de 5","x + 5"],["le double d’un nombre","2 × x"],["un nombre diminué de 3","x − 3"],["la moitié d’un nombre","x ÷ 2"],["trois fois un nombre plus 1","3 × x + 1"],
  ["un nombre partagé en 4 parts égales","x ÷ 4"],["la somme de deux nombres inconnus","x + y"],["le carré d’un nombre","x × x"],["7 de moins qu’un nombre","x − 7"],["5 de plus que le double d’un nombre","2 × x + 5"]
].map(([phrase,expr],i)=>question(`Quelle expression peut représenter ${phrase} ?`,expr,["x = 0","x + x + x + x + x + x","1 ÷ x"].filter(x=>x!==expr),`La lettre x représente le nombre inconnu : ${expr}.`,i<3?1:i<7?2:3));

const lots = [
  {number:15,file:"maths-6e-lot-15-durees.json",lot:"M6-MES-04",domain:["quantities_measurement","Grandeurs et mesures"],skill:["durations","Durées"],start:541,codes:["m6_mes_convertir_duree"],sets:[durationItems]},
  {number:16,file:"maths-6e-lot-16-proportionnalite-fondamentaux.json",lot:"M6-PROP-01",domain:["proportionality","Proportionnalité"],skill:["proportionality_basics","Fondamentaux de la proportionnalité"],start:551,codes:["m6_prop_definition","m6_prop_identifier","m6_prop_non_proportionnelle","m6_prop_linearite_multiplicative"],sets:[proportionalDefinitions,propSituations,nonPropSituations,multiplicativeItems()]},
  {number:17,file:"maths-6e-lot-17-proportionnalite-methodes.json",lot:"M6-PROP-02",domain:["proportionality","Proportionnalité"],skill:["proportionality_methods","Méthodes de proportionnalité"],start:591,codes:["m6_prop_linearite_additive","m6_prop_retour_unite","m6_prop_lire_tableau","m6_prop_completer_tableau"],sets:[additiveItems(),unitItems(),readTableItems(),completeTableItems()]},
  {number:18,file:"maths-6e-lot-18-echelles.json",lot:"M6-PROP-03",domain:["proportionality","Proportionnalité"],skill:["scales","Échelles"],start:631,codes:["m6_prop_echelle"],sets:[scaleItems()]},
  {number:19,file:"maths-6e-lot-19-lecture-donnees.json",lot:"M6-DATA-01",domain:["data_management","Organisation et gestion de données"],skill:["data_reading","Lecture de données"],start:641,codes:["m6_data_lire_tableau","m6_data_lire_barres","m6_data_lire_circulaire","m6_data_lire_courbe"],sets:[tableItems,barItems,circularItems,curveItems]},
  {number:20,file:"maths-6e-lot-20-organisation-donnees.json",lot:"M6-DATA-02",domain:["data_management","Organisation et gestion de données"],skill:["data_organization","Organisation de données"],start:681,codes:["m6_data_planifier_enquete","m6_data_construire_tableau","m6_data_filtrer"],sets:[surveyItems,constructTableItems,filterItems]}
];

function microSkill(code) {
  const [teacherName, studentName, lessonReminder, workedExample, masteryCriteria] = metadata[code];
  return { code, teacherName, studentName, lessonReminder, workedExample, masteryCriteria };
}

function verificationSql(start, end) {
  return `with lot_questions as (
  select id, current_version_number, status, micro_skill_id
  from public.questions
  where legacy_id between 600${start} and 600${end}
),
versions as (
  select qv.id, qv.question_id
  from public.question_versions qv
  join lot_questions q on q.id = qv.question_id
    and q.current_version_number = qv.version_number
),
counts as (
  select v.question_id, count(ac.id) as choices,
    count(*) filter (where ac.is_correct) as correct_choices,
    max(ac.sort_order) filter (where ac.is_correct) as correct_position
  from versions v
  join public.answer_choices ac on ac.question_version_id = v.id
  group by v.question_id
)
select jsonb_build_object(
  'questions', (select count(*) from lot_questions),
  'versions', (select count(*) from versions),
  'choices', (select coalesce(sum(choices), 0) from counts),
  'correct_choices', (select coalesce(sum(correct_choices), 0) from counts),
  'micro_skills', (select count(distinct micro_skill_id) from lot_questions),
  'current_versions', (select count(*) from lot_questions where current_version_number = 1),
  'questions_with_four_choices', (select count(*) from counts where choices = 4),
  'questions_with_one_correct_choice', (select count(*) from counts where correct_choices = 1),
  'statuses', (select array_agg(distinct status order by status) from lot_questions),
  'answer_a', (select count(*) from counts where correct_position = 1),
  'answer_b', (select count(*) from counts where correct_position = 2),
  'answer_c', (select count(*) from counts where correct_position = 3),
  'answer_d', (select count(*) from counts where correct_position = 4)
) as verification;
`;
}

for (const lot of lots) {
  const rawQuestions = lot.sets.flatMap((set, index) => tagged(lot.codes[index], set));
  const questions = placeAnswers(rawQuestions, lot.start);
  const payload = {
    format: "cap-college-question-draft-v1",
    subject: "mathematics",
    level: "6e",
    domain: { code: lot.domain[0], name: lot.domain[1] },
    skill: { code: lot.skill[0], name: lot.skill[1] },
    lot: lot.lot,
    status: "draft",
    source: "Programme de mathématiques cycle 3, BO n°16 du 17 avril 2025",
    microSkills: lot.codes.map(microSkill),
    questions
  };
  fs.writeFileSync(path.join(contentsDir, lot.file), JSON.stringify(payload, null, 2) + "\n", "utf8");
  const sqlNumber = 110 + (lot.number - 15);
  fs.writeFileSync(
    path.join(databaseDir, `${sqlNumber}_verify_maths_6e_lot_${lot.number}.sql`),
    verificationSql(lot.start, lot.start + questions.length - 1),
    "utf8"
  );
}
