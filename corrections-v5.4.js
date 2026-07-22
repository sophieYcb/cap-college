/* Cap Collège V5.4
 * - applique les 20 derniers retours pédagogiques ;
 * - répartit équitablement les bonnes réponses entre A, B, C et D ;
 * - conserve les identifiants permanents et le stockage des annotations.
 */
(function () {
  const contentChanged = new Set();
  const replace = (id, values) => {
    const question = QUESTIONS.find(item => item.id === id);
    if (!question) return;
    Object.assign(question, values);
    contentChanged.add(id);
  };

  replace(161,{
    question:'Conjugue le verbe « chanter » au passé composé avec « je ».',
    choix:["j’ai chanté","je suis chanté","je chantais","je chanterai"],reponse:0
  });
  replace(167,{
    question:'Conjugue le verbe « voir » au passé composé avec « je ».',
    choix:["j’ai vu","je suis vu","je voyais","je verrai"],reponse:0
  });
  replace(179,{
    question:'Conjugue le verbe « avoir » au passé composé avec « je ».',
    choix:["j’ai eu","j’avais","j’aurai","je suis eu"],reponse:0
  });
  replace(299,{
    choix:['mesdames','médames','mèsdames','médammes'],reponse:0
  });

  const antonymChoices={
    322:['froid','tiède','brûlant','humide'],
    325:['fermer','entrouvrir','déverrouiller','observer'],
    326:['terminer','poursuivre','reprendre','patienter'],
    327:['descendre','grimper','escalader','avancer'],
    328:['sale','net','lavé','humide'],
    329:['difficile','simple','évident','rapide'],
    330:['silencieux','sonore','retentissant','aigu'],
    331:['récent','vieux','passé','célèbre'],
    332:['sombre','lumineux','brillant','coloré'],
    333:['peureux','hardi','brave','prudent'],
    334:['vide','rempli','chargé','lourd'],
    335:['refuser','approuver','admettre','discuter'],
    336:['lointain','voisin','prochain','immense'],
    338:['méchant','aimable','doux','poli'],
    339:['perdre','réussir','vaincre','jouer'],
    340:['invisible','apparent','voyant','coloré']
  };
  Object.entries(antonymChoices).forEach(([id,choix])=>replace(Number(id),{choix,reponse:0}));

  // Toute question déjà corrigée est concernée. Q161 et Q179 viennent s’y ajouter.
  const candidates=QUESTIONS
    .filter(question=>(question.version||1)>1||question.id===161||question.id===179)
    .sort((a,b)=>a.id-b.id);
  const counters={};
  candidates.forEach(question=>{
    const count=question.choix.length;
    counters[count]=counters[count]||0;
    const target=counters[count]++%count;
    const previousVersion=question.version||1;
    const correct=question.choix[question.reponse];
    const reordered=question.choix.filter((_,index)=>index!==question.reponse);
    reordered.splice(target,0,correct);
    const orderChanged=target!==question.reponse;
    question.choix=reordered;
    question.reponse=target;
    if(orderChanged||contentChanged.has(question.id)) question.version=previousVersion+1;
  });
})();
