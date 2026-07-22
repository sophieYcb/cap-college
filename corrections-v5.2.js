/* Cap Collège V5.2 — corrections issues du retour pédagogique du 22/07/2026.
 * Q21–Q60 ne sont volontairement pas modifiées ici : elles ont déjà été
 * corrigées dans corrections-v5.1.js. Les identifiants et clés de stockage
 * restent inchangés.
 */
(function () {
  const update = (id, values) => {
    const item = QUESTIONS.find((question) => question.id === id);
    if (item) Object.assign(item, values, {version: Math.max(2, (item.version || 1) + 1)});
  };

  // Phrase simple ou complexe : deux réponses seulement, conformément au retour.
  const complexAnswers = new Set([82,83,85,87,89,91,93,95,97,99]);
  for (let id = 81; id <= 100; id++) {
    update(id, {choix:['Phrase simple','Phrase complexe'], reponse:complexAnswers.has(id) ? 1 : 0});
  }

  // Conjugaison : distracteurs plausibles et répétitions supprimées.
  update(106,{choix:['viennent','vient','venaient','viendront'],reponse:0});
  update(148,{choix:['verras','verra','voyais','vois'],reponse:0});
  update(152,{question:'Conjugue le verbe « recevoir » au futur simple avec « ils ».',choix:['recevront','recevaient','reçoivent','recevraient'],reponse:0});
  update(156,{question:'Conjugue le verbe « tenir » au futur simple avec « nous ».',choix:['tiendrons','tenions','tenons','tiendrions'],reponse:0});
  update(157,{question:'Conjugue le verbe « envoyer » au futur simple avec « vous ».',choix:['enverrez','envoyiez','envoyez','enverriez'],reponse:0});
  update(162,{question:'Complète au passé composé : « Hier, tu ___ ton exercice avant midi. » (finir)',choix:['as fini','es fini','finissais','finiras'],reponse:0});
  update(163,{question:'Complète au passé composé : « Il ___ le livre posé sur la table. » (prendre)',choix:['a pris','est pris','prenait','prendra'],reponse:0});
  update(165,{question:'Complète au passé composé : « Vous ___ un gâteau pour la fête. » (faire)',choix:['avez fait','êtes faits','faisiez','ferez'],reponse:0});
  update(167,{question:'Complète au passé composé : « J’___ ce film samedi dernier. » (voir)',choix:['ai vu','suis vu','voyais','verrai'],reponse:0});
  update(174,{question:'Complète au passé composé : « Tu ___ les livres dans le sac. » (mettre)',choix:['as mis','es mis','mettais','mettras'],reponse:0});
  update(175,{question:'Complète au passé composé : « On ___ la fenêtre pour aérer. » (ouvrir)',choix:['a ouvert','est ouvert','ouvrait','ouvrira'],reponse:0});
  update(177,{question:'Complète au passé composé : « Vous ___ notre lettre hier matin. » (recevoir)',choix:['avez reçu','êtes reçus','receviez','recevrez'],reponse:0});

  // Homophones : seules les formes réellement évaluées sont proposées.
  const aAnswers = new Set([201,203,205,207,209,211,213,215,217,219]);
  for (let id=201; id<=220; id++) update(id,{choix:['a','à'],reponse:aAnswers.has(id)?0:1});
  const etAnswers = new Set([221,223,225,227,229,231,233,235,237,239]);
  for (let id=221; id<=240; id++) update(id,{choix:['et','est'],reponse:etAnswers.has(id)?0:1});
  const sontAnswers = new Set([241,243,245,247,249,251,253,255,257,259]);
  for (let id=241; id<=260; id++) update(id,{choix:['son','sont'],reponse:sontAnswers.has(id)?1:0});

  // Accord dans le groupe nominal : formes inventées et doublon supprimés.
  update(261,{choix:['rouge','rouges'],reponse:0});
  update(262,{question:'Choisis la forme correctement accordée : « des écharpes ___ »',choix:['bleues','bleue','bleus','bleu'],reponse:0});
  update(277,{choix:['heureux','heureuse','heureuses'],reponse:0});

  // Pluriels : erreurs plausibles fondées sur les règles de formation.
  const plurals = {
    281:['chevaux','chevals','chevaus','chevalles'],282:['journaux','journals','journeaux','journales'],
    283:['jeux','jeus','jeues','jeu'],284:['bateaux','bataux','bateaus','bateau'],
    285:['nez','nezs','nés','néz'],286:['travaux','travails','travailes','traveaux'],
    287:['choux','chous','chouxs','chou'],288:['bijoux','bijous','bijouxs','bijou'],
    289:['bals','baux','bales','balses'],290:['festivals','festivaux','festivales','festivalx'],
    291:['pneus','pneux','pneaux','pneu'],292:['landaus','landaux','landeaux','landau'],
    293:['animaux','animals','animeaux','animales'],294:['genoux','genous','genouxs','genou'],
    295:['cailloux','caillous','caillouxs','caillou'],296:['détails','détaux','détailses','détailx'],
    297:['yeux','œils','œillaux','yeus'],298:['messieurs','monsieurs','monsieures','monsieur'],
    299:['mesdames','madames','madamme','madammes'],300:['coraux','corails','coreaux','corales']
  };
  Object.entries(plurals).forEach(([id,choix])=>update(Number(id),{choix,reponse:0}));

  // Synonymes : quatre mots de même catégorie, sans distracteurs répétés.
  const synonyms = {
    301:['content','jaloux','inquiet','furieux'],302:['vite','lentement','rarement','doucement'],
    303:['débuter','continuer','achever','interrompre'],304:['observer','ignorer','cacher','éviter'],
    305:['crainte','colère','joie','fierté'],306:['habitation','boutique','atelier','monument'],
    307:['joli','terne','banal','laid'],308:['compliqué','évident','simple','rapide'],
    309:['épuisé','reposé','alerte','vigoureux'],310:['paisible','agité','bruyant','nerveux'],
    311:['vacarme','silence','murmure','musique'],312:['discuter','écouter','taire','écrire'],
    313:['immense','étroit','mince','bref'],314:['secourir','abandonner','gêner','observer'],
    315:['sélectionner','refuser','mélanger','ranger'],316:['dissimuler','révéler','montrer','exposer'],
    317:['vieux','récent','neuf','moderne'],318:['faute','réussite','preuve','réponse'],
    319:['solution','question','demande','hésitation'],320:['bizarre','ordinaire','familier','habituel']
  };
  Object.entries(synonyms).forEach(([id,choix])=>update(Number(id),{choix,reponse:0}));

  // Antonymes : Q323 et Q337 étaient déjà corrigées, elles restent intactes.
  const antonyms = {
    321:['petit','immense','haut','large'],322:['froid','tiède','brûlant','chaud'],
    324:['triste','joyeux','souriant','ravi'],325:['fermer','entrouvrir','déverrouiller','ouvrir'],
    326:['terminer','poursuivre','reprendre','commencer'],327:['descendre','grimper','escalader','monter'],
    328:['sale','net','lavé','propre'],329:['difficile','simple','évident','facile'],
    330:['silencieux','sonore','retentissant','bruyant'],331:['récent','vieux','passé','ancien'],
    332:['sombre','lumineux','brillant','clair'],333:['peureux','hardi','brave','courageux'],
    334:['vide','rempli','chargé','plein'],335:['refuser','approuver','admettre','accepter'],
    336:['lointain','voisin','prochain','proche'],338:['méchant','aimable','doux','gentil'],
    339:['perdre','réussir','vaincre','gagner'],340:['invisible','apparent','voyant','visible']
  };
  Object.entries(antonyms).forEach(([id,choix])=>update(Number(id),{choix,reponse:0}));

  // Familles de mots : Q341, Q351 et Q355 étaient validées A et restent intactes.
  const families = {
    342:['terrestre','terrible','terne','tendre'],343:['dentiste','dentelle','denrée','dense'],
    344:['fleuriste','fleuve','flèche','flamme'],345:['laitier','laideur','laisse','laine'],
    346:['marin','marron','matin','malin'],347:['journalier','joueur','jovial','jumeau'],
    348:['peureux','pierreux','heureux','paresseux'],349:['glacial','global','génial','gracieux'],
    350:['boisé','boisson','boîte','boiter'],352:['lecture','littoral','liaison','levure'],
    353:['écrivain','écrin','écran','écrasant'],354:['portable','portique','portion','portrait'],
    356:['nageur','nuageux','natif','narrateur'],357:['jardinier','gardien','journalier','joaillier'],
    358:['montagnard','montant','monteur','monture'],359:['ensoleillé','solitaire','solennel','solide'],
    360:['historique','hystérique','hivernal','hypothétique']
  };
  Object.entries(families).forEach(([id,choix])=>update(Number(id),{choix,reponse:0}));

  // Sens propre / figuré : question binaire, sans réponses hors sujet.
  const figurative = new Set([361,363,365,367,369,371,373,375,377,379]);
  for (let id=361; id<=380; id++) update(id,{choix:['Sens propre','Sens figuré'],reponse:figurative.has(id)?1:0});
})();
