/* Cap Collège V6.0 — complément du programme officiel de français 6e (2025).
 * 21 compétences nouvelles, 10 questions relues par compétence.
 */
(function(){
 const addTheme=(competenceId,domaine,competence,lesson,rows)=>{
  SKILL_LESSONS[competence]=lesson;
  rows.forEach((row,index)=>{
   const [question,correct,wrong]=row;
   const target=index%(wrong.length+1);
   const choix=[...wrong];choix.splice(target,0,correct);
   QUESTIONS.push({id:QUESTIONS.length+1,competenceId,domaine,competence,difficulte:index<5?1:2,question,choix,reponse:target,version:1});
  });
 };

 // Correction de la compétence existante : trois types officiels seulement.
 const typeRows=[
  ['« Le train arrive à huit heures. »','Déclarative',['Interrogative','Injonctive']],
  ['« Où as-tu rangé ton cahier ? »','Interrogative',['Déclarative','Injonctive']],
  ['« Fermez doucement la porte. »','Injonctive',['Déclarative','Interrogative']],
  ['« Nous visiterons le musée demain. »','Déclarative',['Interrogative','Injonctive']],
  ['« Pourquoi le ciel devient-il rouge ? »','Interrogative',['Déclarative','Injonctive']],
  ['« Prenez vos affaires et sortez. »','Injonctive',['Déclarative','Interrogative']],
  ['« Cette nouvelle est vraiment étonnante ! »','Déclarative',['Interrogative','Injonctive']],
  ['« Ne courez pas dans l’escalier. »','Injonctive',['Déclarative','Interrogative']],
  ['« Est-ce que vous connaissez la réponse ? »','Interrogative',['Déclarative','Injonctive']],
  ['« Comme ce paysage est magnifique ! »','Déclarative',['Interrogative','Injonctive']],
  ['« Le vent souffle depuis ce matin. »','Déclarative',['Interrogative','Injonctive']],
  ['« Avez-vous entendu ce bruit ? »','Interrogative',['Déclarative','Injonctive']],
  ['« Écris ton nom en haut de la feuille. »','Injonctive',['Déclarative','Interrogative']],
  ['« Quel merveilleux spectacle ! »','Déclarative',['Interrogative','Injonctive']],
  ['« Quand reviendras-tu nous voir ? »','Interrogative',['Déclarative','Injonctive']],
  ['« N’oubliez pas votre rendez-vous. »','Injonctive',['Déclarative','Interrogative']],
  ['« Les hirondelles reviennent au printemps. »','Déclarative',['Interrogative','Injonctive']],
  ['« Qui souhaite répondre à cette question ? »','Interrogative',['Déclarative','Injonctive']],
  ['« Range immédiatement ta chambre ! »','Injonctive',['Déclarative','Interrogative']],
  ['« Cette histoire se termine bien. »','Déclarative',['Interrogative','Injonctive']]
 ];
 QUESTIONS.filter(q=>q.competenceId==='g_types').forEach((q,index)=>{
  const [sentence,correct,wrong]=typeRows[index];const target=index%3;const choix=[...wrong];choix.splice(target,0,correct);
  Object.assign(q,{question:`Quel est le type de la phrase ${sentence}`,choix,reponse:target,version:(q.version||1)+1});
 });

 addTheme('g_coi','Grammaire','COI','Le COI complète le verbe avec une préposition, souvent à ou de.',[
  ['Quel est le COI dans « Léa parle à sa sœur » ?','à sa sœur',['Léa','parle','sa sœur']],
  ['Quel est le COI dans « Nous rêvons de vacances » ?','de vacances',['Nous','rêvons','vacances']],
  ['Quel est le COI dans « Il téléphone à son médecin » ?','à son médecin',['Il','téléphone','son médecin']],
  ['Quel est le COI dans « Vous obéissez aux consignes » ?','aux consignes',['Vous','obéissez','les consignes']],
  ['Quel est le COI dans « Je me souviens de cette histoire » ?','de cette histoire',['Je','me souviens','cette histoire']],
  ['Quel groupe complète indirectement le verbe dans « Paul écrit à son ami » ?','à son ami',['Paul','écrit','son ami']],
  ['Quel est le COI dans « Les élèves profitent de la récréation » ?','de la récréation',['Les élèves','profitent','la récréation']],
  ['Quel est le COI dans « Tu réponds au professeur » ?','au professeur',['Tu','réponds','le professeur']],
  ['Quel est le COI dans « Elle doute de sa réponse » ?','de sa réponse',['Elle','doute','sa réponse']],
  ['Quel est le COI dans « Nous pensons à notre projet » ?','à notre projet',['Nous','pensons','notre projet']]
 ]);
 addTheme('g_attribut','Grammaire','Attribut du sujet','L’attribut caractérise le sujet après un verbe d’état.',[
  ['Quel est l’attribut du sujet dans « Le ciel devient sombre » ?','sombre',['Le ciel','devient','ciel']],
  ['Quel est l’attribut dans « Ma sœur est médecin » ?','médecin',['Ma sœur','est','sœur']],
  ['Quel est l’attribut dans « Ces exercices semblent faciles » ?','faciles',['Ces exercices','semblent','exercices']],
  ['Quel est l’attribut dans « Paul reste silencieux » ?','silencieux',['Paul','reste','silence']],
  ['Quel est l’attribut dans « Cette histoire paraît vraie » ?','vraie',['Cette histoire','paraît','histoire']],
  ['Dans « Les enfants sont heureux », quel mot caractérise le sujet ?','heureux',['Les enfants','sont','enfants']],
  ['Quel est l’attribut dans « Le gagnant demeure modeste » ?','modeste',['Le gagnant','demeure','gagnant']],
  ['Quel est l’attribut dans « Cette route semble dangereuse » ?','dangereuse',['Cette route','semble','route']],
  ['Quel est l’attribut dans « Son père est un excellent cuisinier » ?','un excellent cuisinier',['Son père','est','excellent']],
  ['Quel est l’attribut dans « Les feuilles deviennent jaunes » ?','jaunes',['Les feuilles','deviennent','feuilles']]
 ]);
 addTheme('g_cc','Grammaire','Compléments circonstanciels','Un complément circonstanciel précise notamment le lieu, le temps ou la cause.',[
  ['Dans « Demain, nous partirons », quel groupe indique le temps ?','Demain',['nous','partirons','nous partirons']],
  ['Dans « Le chat dort sous la table », quel groupe indique le lieu ?','sous la table',['Le chat','dort','la table']],
  ['Dans « Il tremble à cause du froid », quel groupe indique la cause ?','à cause du froid',['Il','tremble','du froid']],
  ['Dans « Chaque matin, elle court au parc », quel groupe indique le temps ?','Chaque matin',['elle','court','au parc']],
  ['Dans « Les enfants jouent dans la cour », quel groupe indique le lieu ?','dans la cour',['Les enfants','jouent','la cour']],
  ['Dans « Puisqu’il pleut, nous restons à l’abri », quel groupe indique la cause ?','Puisqu’il pleut',['nous','restons','à l’abri']],
  ['Dans « Nous déjeunerons à midi », quel groupe indique le temps ?','à midi',['Nous','déjeunerons','midi']],
  ['Dans « Le bateau avance vers le port », quel groupe indique le lieu ?','vers le port',['Le bateau','avance','le port']],
  ['Dans « Elle sourit de joie », quel groupe indique la cause ?','de joie',['Elle','sourit','joie']],
  ['Dans « Après le repas, ils sortiront dehors », quel groupe indique le temps ?','Après le repas',['ils','sortiront','dehors']]
 ]);
 addTheme('g_pronoms','Grammaire','Pronoms personnels et antécédents','Le pronom remplace un nom ou un groupe nominal appelé antécédent.',[
  ['Dans « Léa arrive ; elle sourit », quel est l’antécédent de « elle » ?','Léa',['arrive','sourit','elle']],
  ['Remplace « Paul et moi » dans « Paul et moi partons » par un pronom.','Nous',['Ils','Vous','On']],
  ['Dans « Je les regarde », quelle est la fonction de « les » ?','COD',['Sujet','COI','Complément circonstanciel']],
  ['Dans « Je lui parle », quelle est la fonction de « lui » ?','COI',['Sujet','COD','Attribut']],
  ['Dans « Les oiseaux chantent ; ils sont nombreux », quel est l’antécédent de « ils » ?','Les oiseaux',['chantent','nombreux','ils']],
  ['Quel pronom remplace « la voiture » dans « Je regarde la voiture » ?','la',['lui','elle-même','leur']],
  ['Quel pronom remplace « à mes amis » dans « Je parle à mes amis » ?','leur',['les','ils','eux-mêmes']],
  ['Dans « Tu nous appelles », quelle est la fonction de « nous » ?','COD',['Sujet','Attribut','Complément circonstanciel']],
  ['Dans « Marie prend son livre et le range », que remplace « le » ?','son livre',['Marie','range','prend']],
  ['Dans « Le professeur leur répond », quelle est la fonction de « leur » ?','COI',['Sujet','COD','Épithète']]
 ]);
 addTheme('g_expansions','Grammaire','Épithète et complément du nom','L’épithète est un adjectif lié au nom ; le complément du nom est généralement un groupe prépositionnel.',[
  ['Dans « une grande maison », quel mot est épithète ?','grande',['une','maison','grande maison']],
  ['Dans « la porte du jardin », quel groupe est complément du nom ?','du jardin',['la porte','porte','jardin']],
  ['Dans « un ciel bleu », quel mot est épithète ?','bleu',['un','ciel','un ciel']],
  ['Dans « une tasse de thé », quel groupe est complément du nom ?','de thé',['une tasse','tasse','thé']],
  ['Dans « ce vieux château », quel mot est épithète ?','vieux',['ce','château','ce château']],
  ['Dans « le livre de mon frère », quel groupe complète le nom « livre » ?','de mon frère',['le livre','mon frère','frère']],
  ['Dans « une histoire passionnante », quel mot est épithète ?','passionnante',['une','histoire','une histoire']],
  ['Dans « les rues de Paris », quel groupe est complément du nom ?','de Paris',['les rues','rues','Paris']],
  ['Dans « une légère brise », quel mot est épithète ?','légère',['une','brise','une brise']],
  ['Dans « un collier en argent », quel groupe est complément du nom ?','en argent',['un collier','collier','argent']]
 ]);
 addTheme('g_propositions','Grammaire','Propositions et articulation','Les propositions peuvent être juxtaposées, coordonnées ou subordonnées.',[
  ['Combien de propositions contient « Le soleil brille et les oiseaux chantent » ?','Deux',['Une','Trois','Quatre']],
  ['Dans « Il pleut, je prends mon parapluie », les propositions sont…','juxtaposées',['coordonnées','subordonnées','indépendantes sans lien']],
  ['Dans « Il pleut donc je reste », les propositions sont…','coordonnées',['juxtaposées','subordonnées','sans verbe']],
  ['Dans « Je pars quand la cloche sonne », « quand la cloche sonne » est…','subordonnée',['juxtaposée','coordonnée','une phrase sans proposition']],
  ['Quel mot coordonne dans « Paul lit mais Léa écrit » ?','mais',['lit','Léa','écrit']],
  ['Quel mot subordonne dans « Je crois que tu as raison » ?','que',['crois','tu','raison']],
  ['Dans « Le vent se lève ; la mer grossit », le point-virgule marque une…','juxtaposition',['coordination','subordination','négation']],
  ['Dans « Tu viens ou tu restes », quel mot relie les propositions ?','ou',['viens','tu','restes']],
  ['Combien de propositions contient « Lorsque tu arriveras, nous mangerons » ?','Deux',['Une','Trois','Aucune']],
  ['Dans « Elle sourit parce qu’elle est contente », le lien est une…','subordination',['juxtaposition','coordination','interrogation']]
 ]);
 addTheme('g_formes','Grammaire','Formes de phrases','Une phrase peut être affirmative ou négative, neutre ou exclamative.',[
  ['« Il ne vient jamais » est à la forme…','négative',['affirmative']],
  ['« Nous partirons demain » est à la forme…','affirmative',['négative']],
  ['« Quel beau spectacle ! » est à la forme…','exclamative',['neutre']],
  ['« Le spectacle commence » est à la forme…','neutre',['exclamative']],
  ['« Personne ne répond » est à la forme…','négative',['affirmative']],
  ['« Comme tu as grandi ! » est à la forme…','exclamative',['neutre']],
  ['« Je n’ai rien oublié » est à la forme…','négative',['affirmative']],
  ['« Cette histoire est incroyable ! » est à la forme…','exclamative',['neutre']],
  ['« Elle connaît la réponse » est à la forme…','affirmative',['négative']],
  ['« Le train est déjà parti » est à la forme…','neutre',['exclamative']]
 ]);

 addTheme('c_imperatif','Conjugaison','Impératif présent','L’impératif exprime un ordre ou un conseil et s’emploie sans sujet exprimé.',[
  ['Conjugue « fermer » à la 2e personne du singulier.','Ferme !',['Fermes !','Fermez !','Fermera !']],
  ['Conjugue « finir » à la 1re personne du pluriel.','Finissons !',['Finissont !','Finissez !','Finirons !']],
  ['Conjugue « prendre » à la 2e personne du pluriel.','Prenez !',['Prennent !','Prenais !','Prendez !']],
  ['Conjugue « aller » à la 2e personne du singulier.','Va !',['Vas !','Allez !','Iras !']],
  ['Conjugue « être » à la 1re personne du pluriel.','Soyons !',['Sommes !','Soyez !','Serons !']],
  ['Conjugue « avoir » à la 2e personne du pluriel.','Ayez !',['Avez !','Ayons !','Auriez !']],
  ['Conjugue « faire » à la 2e personne du singulier.','Fais !',['Fait !','Faisez !','Ferais !']],
  ['Conjugue « venir » à la 1re personne du pluriel.','Venons !',['Venez !','Viennons !','Viendrons !']],
  ['Conjugue « choisir » à la 2e personne du pluriel.','Choisissez !',['Choisisez !','Choisissons !','Choisirez !']],
  ['Conjugue « dire » à la 2e personne du pluriel.','Dites !',['Disez !','Disons !','Direz !']]
 ]);
 addTheme('c_conditionnel','Conjugaison','Conditionnel présent','Le conditionnel présent utilise le radical du futur et les terminaisons de l’imparfait.',[
  ['Conjugue « être » avec « je » au conditionnel présent.','je serais',['je serai','j’étais','je sois']],
  ['Conjugue « avoir » avec « nous » au conditionnel présent.','nous aurions',['nous aurons','nous avions','nous ayons']],
  ['Conjugue « venir » avec « tu » au conditionnel présent.','tu viendrais',['tu viendras','tu venais','tu viennes']],
  ['Conjugue « faire » avec « ils » au conditionnel présent.','ils feraient',['ils feront','ils faisaient','ils fassent']],
  ['Conjugue « pouvoir » avec « vous » au conditionnel présent.','vous pourriez',['vous pourrez','vous pouviez','vous puissiez']],
  ['Conjugue « voir » avec « elle » au conditionnel présent.','elle verrait',['elle verra','elle voyait','elle voie']],
  ['Conjugue « choisir » avec « nous » au conditionnel présent.','nous choisirions',['nous choisirons','nous choisissions','nous choisissons']],
  ['Conjugue « aller » avec « je » au conditionnel présent.','j’irais',['j’irai','j’allais','j’aille']],
  ['Conjugue « vouloir » avec « tu » au conditionnel présent.','tu voudrais',['tu voudras','tu voulais','tu veuilles']],
  ['Conjugue « prendre » avec « ils » au conditionnel présent.','ils prendraient',['ils prendront','ils prenaient','ils prennent']]
 ]);
 addTheme('c_pqp','Conjugaison','Plus-que-parfait','Le plus-que-parfait se forme avec être ou avoir à l’imparfait et le participe passé.',[
  ['Complète : « J’___ terminé avant midi. »','avais',['ai','aurai','aurais']],
  ['Complète : « Elle ___ partie avant nous. »','était',['est','sera','serait']],
  ['Conjugue « finir » avec « nous » au plus-que-parfait.','nous avions fini',['nous avons fini','nous aurons fini','nous finissions']],
  ['Conjugue « venir » avec « ils » au plus-que-parfait.','ils étaient venus',['ils sont venus','ils viendraient','ils avaient venu']],
  ['Conjugue « voir » avec « tu » au plus-que-parfait.','tu avais vu',['tu as vu','tu aurais vu','tu voyais']],
  ['Conjugue « aller » avec « elle » au plus-que-parfait.','elle était allée',['elle est allée','elle avait allé','elle irait']],
  ['Conjugue « prendre » avec « vous » au plus-que-parfait.','vous aviez pris',['vous avez pris','vous aurez pris','vous preniez']],
  ['Complète : « Nous ___ déjà sortis. »','étions',['sommes','serons','avions']],
  ['Conjugue « écrire » avec « il » au plus-que-parfait.','il avait écrit',['il a écrit','il écrivait','il aurait écrit']],
  ['Conjugue « naître » avec « elles » au plus-que-parfait.','elles étaient nées',['elles sont nées','elles avaient né','elles naissaient']]
 ]);
 addTheme('c_passe_simple','Conjugaison','Passé simple','Le passé simple est un temps du récit écrit.',[
  ['Conjugue « marcher » avec « il » au passé simple.','il marcha',['il marchait','il a marché','il marchera']],
  ['Conjugue « finir » avec « ils » au passé simple.','ils finirent',['ils finissaient','ils ont fini','ils finiront']],
  ['Conjugue « prendre » avec « elle » au passé simple.','elle prit',['elle prenait','elle a pris','elle prendra']],
  ['Conjugue « être » avec « nous » au passé simple.','nous fûmes',['nous étions','nous avons été','nous serons']],
  ['Conjugue « avoir » avec « ils » au passé simple.','ils eurent',['ils avaient','ils ont eu','ils auront']],
  ['Conjugue « venir » avec « il » au passé simple.','il vint',['il venait','il est venu','il viendra']],
  ['Conjugue « voir » avec « elles » au passé simple.','elles virent',['elles voyaient','elles ont vu','elles verront']],
  ['Conjugue « faire » avec « je » au passé simple.','je fis',['je faisais','j’ai fait','je ferai']],
  ['Conjugue « dire » avec « vous » au passé simple.','vous dîtes',['vous disiez','vous avez dit','vous direz']],
  ['Conjugue « pouvoir » avec « il » au passé simple.','il put',['il pouvait','il a pu','il pourra']]
 ]);
 addTheme('c_valeurs','Conjugaison','Valeurs des temps','Les temps situent les actions et peuvent exprimer durée, habitude ou action de premier plan.',[
  ['Dans « Chaque été, nous allions à la mer », l’imparfait exprime…','une habitude passée',['une action future','un ordre','une action soudaine']],
  ['Dans « Soudain, le loup surgit », le passé simple exprime…','une action de premier plan',['une habitude','une description','un conseil']],
  ['Dans « Le château dominait la vallée », l’imparfait sert à…','décrire',['ordonner','annoncer le futur','poser une question']],
  ['Dans « Demain, nous partirons », le futur situe l’action…','après le moment où l’on parle',['avant','au même moment','hors du temps']],
  ['Dans « Je lis chaque soir », le présent exprime…','une habitude actuelle',['une action passée','un ordre','une hypothèse']],
  ['Dans « L’eau bout à 100 °C », le présent exprime…','une vérité générale',['un souvenir','un projet','une action achevée']],
  ['Dans « Il avait fermé la porte avant de sortir », le plus-que-parfait marque…','une action antérieure à une autre action passée',['une action future','un ordre','une habitude actuelle']],
  ['Dans « Pourrais-tu m’aider ? », le conditionnel exprime…','une demande polie',['une certitude passée','un ordre direct','une habitude']],
  ['Dans « Ferme la fenêtre », l’impératif exprime…','un ordre',['un récit passé','une hypothèse','une description']],
  ['Dans « Hier, elle a terminé son livre », le passé composé exprime…','une action passée achevée',['une action future','une vérité générale','un ordre']]
 ]);
 addTheme('c_marques','Conjugaison','Radical et terminaisons','Une forme verbale comprend un radical et une terminaison portant des marques de temps et de personne.',[
  ['Dans « chantions », quel est le radical ?','chant-',['-ions','chanti-','-ons']],
  ['Dans « finirez », quelle terminaison marque la personne ?','-ez',['fin-','-ir-','fini-']],
  ['Dans « marcherons », quelle lettre marque le futur ?','r',['m','ch','s']],
  ['Dans « jouais », quelle partie marque principalement l’imparfait ?','-ai-',['jou-','-s','-ou-']],
  ['Quel est le radical de « prenons » ?','pren-',['pre-','-ons','preno-']],
  ['Dans « vous chantez », quelle terminaison correspond à « vous » ?','-ez',['-ons','-ent','-es']],
  ['Dans « ils finissent », quelle terminaison marque la 3e personne du pluriel ?','-ent',['-ons','-ez','-es']],
  ['Quel est le radical de « viendrait » ?','viendr-',['ven-','vien-','-ait']],
  ['Dans « nous mangions », pourquoi conserve-t-on le e ?','pour garder le son doux de g',['pour marquer le pluriel','pour marquer le futur','parce que le verbe est irrégulier']],
  ['Dans « vous lancez », pourquoi écrit-on ç dans « nous lançons » ?','pour conserver le son [s]',['pour marquer le passé','pour marquer la personne','pour former un nom']]
 ]);

 addTheme('o_participe','Orthographe','Accord du participe passé','Avec être, le participe passé s’accorde avec le sujet ; avec avoir, il s’accorde avec le COD placé avant.',[
  ['Complète : « Elle est ___ tôt. » (partir)','partie',['parti','parties','partis']],
  ['Complète : « Ils sont ___ hier. » (arriver)','arrivés',['arrivé','arrivée','arrivées']],
  ['Complète : « Les lettres que j’ai ___ sont longues. » (écrire)','écrites',['écrit','écrits','écrite']],
  ['Complète : « Marie et Léa sont ___ ensemble. » (venir)','venues',['venu','venue','venus']],
  ['Complète : « La pomme que tu as ___ était mûre. » (manger)','mangée',['mangé','mangés','mangées']],
  ['Complète : « Nous sommes ___ à midi. » (sortir, groupe féminin)','sorties',['sorti','sortis','sortie']],
  ['Complète : « Les films qu’il a ___ sont célèbres. » (voir)','vus',['vu','vue','vues']],
  ['Complète : « Paul est ___ chez lui. » (rester)','resté',['restée','restés','restées']],
  ['Complète : « Les chansons que nous avons ___ sont belles. » (entendre)','entendues',['entendu','entendus','entendue']],
  ['Complète : « Elles sont ___ en avance. » (naître)','nées',['né','née','nés']]
 ]);
 addTheme('o_lexicale','Orthographe','Orthographe lexicale','L’orthographe lexicale concerne l’écriture correcte des mots fréquents.',[
  ['Quelle orthographe est correcte ?','appartement',['apartement','appartemment','apartemment']],
  ['Quelle orthographe est correcte ?','développement',['dévelopement','développemment','dévelopementt']],
  ['Quelle orthographe est correcte ?','nécessaire',['nécéssaire','nécesaire','nècessaire']],
  ['Quelle orthographe est correcte ?','aujourd’hui',['aujourdhui','aujourd-hui','aujoud’hui']],
  ['Quelle orthographe est correcte ?','longtemps',['longtemp','longetemps','long-temps']],
  ['Quelle orthographe est correcte ?','malheureusement',['maleureusement','malheuresement','malheureusementt']],
  ['Quelle orthographe est correcte ?','différent',['diférent','differrent','différend']],
  ['Quelle orthographe est correcte pour désigner une occasion favorable ?','opportunité',['oportunité','opporttunité','opportunitée']],
  ['Quelle orthographe est correcte ?','immédiatement',['imédiatement','immédiatementt','immèdiatement']],
  ['Quelle orthographe est correcte ?','renseignement',['renseignment','renseignemment','rensegnement']]
 ]);
 addTheme('o_feminin','Orthographe','Féminin des noms et adjectifs','Le féminin se forme régulièrement ou selon des formes particulières à mémoriser.',[
  ['Quel est le féminin de « heureux » ?','heureuse',['heureuxe','heureuxse','heureuses']],
  ['Quel est le féminin de « sportif » ?','sportive',['sportiffe','sportifve','sportives']],
  ['Quel est le féminin de « boulanger » ?','boulangère',['boulangèreuse','boulangeuse','boulangeresse']],
  ['Quel est le féminin de « acteur » ?','actrice',['acteure','acteuresse','acteuse']],
  ['Quel est le féminin de « ancien » ?','ancienne',['anciene','anciennne','anciennes']],
  ['Quel est le féminin de « doux » ?','douce',['dousse','douxe','douces']],
  ['Quel est le féminin de « lecteur » ?','lectrice',['lecteuse','lecteure','lectoresse']],
  ['Quel est le féminin de « gardien » ?','gardienne',['gardiene','gardienneuse','gardiène']],
  ['Quel est le féminin de « neuf » ?','neuve',['neuffe','neufe','neuves']],
  ['Quel est le féminin de « héros » ?','héroïne',['hérosse','héroesse','héroineux']]
 ]);

 addTheme('v_formation','Vocabulaire','Formation des mots','Les mots peuvent être simples, dérivés par affixes ou composés.',[
  ['Le mot « impossible » contient quel préfixe ?','im-',['-possible','in-','-ible']],
  ['Le mot « rapidement » contient quel suffixe ?','-ment',['rapide-','-ementer','ra-']],
  ['« porte-monnaie » est un mot…','composé',['simple','dérivé uniquement par suffixe','sans radical']],
  ['« chat » est un mot…','simple',['composé','préfixé','suffixé']],
  ['Quel mot est dérivé de « fleur » ?','fleuriste',['fleuve','flèche','flamme']],
  ['Quel préfixe donne le sens contraire dans « malheureux » ?','mal-',['-eux','heur-','ma-']],
  ['Quel suffixe sert à former « lavage » à partir de « laver » ?','-age',['la-','-aver','-ge']],
  ['Quel mot est composé ?','arc-en-ciel',['archer','céleste','coloré']],
  ['Quel mot contient un préfixe signifiant « de nouveau » ?','relire',['liseur','lisible','lecture']],
  ['Quel mot contient un suffixe désignant un métier ?','jardinier',['jardinet','jardinage','jardiner']]
 ]);
 addTheme('v_polysemie','Vocabulaire','Polysémie','Un mot polysémique possède plusieurs sens selon le contexte.',[
  ['Dans « une feuille de papier », quel sens a « feuille » ?','morceau de papier',['partie d’une plante','lame métallique','page internet']],
  ['Dans « la feuille tombe de l’arbre », quel sens a « feuille » ?','partie d’une plante',['morceau de papier','liste de calcul','plaque de verre']],
  ['Dans « le pied de la table », « pied » désigne…','le support inférieur',['une partie du corps','une unité de poésie','un sentier']],
  ['Dans « il s’est blessé au pied », « pied » désigne…','une partie du corps',['un support de meuble','le bas d’une montagne','une mesure de temps']],
  ['Dans « la souris de l’ordinateur », « souris » désigne…','un appareil de commande',['un petit animal','une personne timide','un morceau de tissu']],
  ['Dans « une clé USB », « clé » désigne…','un dispositif de stockage',['un outil pour serrure','une solution musicale','une poignée']],
  ['Dans « la clé du problème », « clé » désigne…','la solution essentielle',['un outil métallique','une note de musique','une serrure']],
  ['Dans « le cœur de la ville », « cœur » désigne…','le centre',['un organe','un sentiment amoureux','une forme dessinée']],
  ['Dans « une chaîne de montagnes », « chaîne » désigne…','une succession de montagnes',['un bijou','un programme télévisé','un lien métallique']],
  ['Dans « la manche du pull », « manche » désigne…','la partie couvrant le bras',['une partie de jeu','une poignée','un passage maritime']]
 ]);
 addTheme('v_etymologie','Vocabulaire','Étymologie','L’étymologie étudie l’origine et l’évolution des mots.',[
  ['Le préfixe grec « télé- » signifie…','à distance',['autour','contre','petit']],
  ['Le radical grec « bio » renvoie à…','la vie',['la terre','le son','la lumière']],
  ['Le radical grec « chrono » renvoie…','au temps',['à la couleur','au corps','à l’écriture']],
  ['Le préfixe latin « aqua- » renvoie…','à l’eau',['au feu','à l’air','à la pierre']],
  ['Le mot « bibliothèque » contient « biblio », qui signifie…','livre',['image','musique','maison']],
  ['Le radical « graph » renvoie à l’idée…','d’écrire',['de compter','de voir','de marcher']],
  ['Le préfixe « mono- » signifie…','un seul',['plusieurs','deux','sans']],
  ['Le préfixe « anti- » signifie…','contre',['avant','avec','après']],
  ['Le radical « géo » renvoie…','à la Terre',['au ciel','au temps','à la mer']],
  ['Le préfixe « pré- » signifie…','avant',['après','à nouveau','sous']]
 ]);
 addTheme('v_registres','Vocabulaire','Registres de langue','On distingue notamment les registres familier, courant et soutenu.',[
  ['Quel mot est familier pour dire « voiture » ?','bagnole',['automobile','véhicule','berline']],
  ['Quel mot est soutenu pour dire « maison » ?','demeure',['baraque','maison','chez-moi']],
  ['« Il a du bol » appartient au registre…','familier',['courant','soutenu','scientifique']],
  ['« Cet individu demeure silencieux » appartient plutôt au registre…','soutenu',['familier','argotique','enfantin']],
  ['Quel verbe courant correspond à « bouffer » ?','manger',['se restaurer','déguster','festoyer']],
  ['Quel mot familier signifie « enfant » ?','gamin',['descendant','mineur','élève']],
  ['« Je suis très fatigué » appartient au registre…','courant',['familier','soutenu','argotique']],
  ['Quel verbe soutenu signifie « demander » ?','solliciter',['quémander un truc','causer','bosser']],
  ['« Il s’est tiré » appartient au registre…','familier',['courant','soutenu','administratif']],
  ['Quel terme courant remplace « fric » ?','argent',['monnaie fiduciaire','pognon','oseille']]
 ]);
 addTheme('v_homonymes','Vocabulaire','Homonymes','Des homonymes se prononcent ou s’écrivent de la même façon mais ont des sens différents.',[
  ['Quel mot complète « Le bateau quitte le ___ » ?','port',['porc','pore','tors']],
  ['Quel mot complète « Le ___ mange dans la ferme » ?','porc',['port','pore','pont']],
  ['Quel mot complète « Il boit dans un ___ » ?','verre',['vert','vers','ver']],
  ['Quel mot complète « Le jardin est très ___ » ?','vert',['verre','vers','ver']],
  ['Quel mot complète « Elle compte jusqu’à ___ » ?','cent',['sang','sans','sens']],
  ['Quel mot complète « Il marche ___ bruit » ?','sans',['sang','cent','sens']],
  ['Quel mot complète « La ___ du château est haute » ?','tour',['tours','tourd','toure']],
  ['Quel mot complète « C’est à ton ___ de jouer » ?','tour',['tours','toure','tourt']],
  ['Quel mot complète « Le pêcheur se tient près de la ___ » ?','mer',['mère','maire','mare']],
  ['Quel mot complète « La ___ accompagne son enfant » ?','mère',['mer','maire','mèr']]
 ]);
})();
