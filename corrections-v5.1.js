/* Cap Collège V5.1 — corrections pédagogiques ciblées.
 * Les identifiants restent inchangés afin de préserver les annotations.
 */
const V51_CORRECTIONS = [
  {id:21, question:'Dans « Les oiseaux chantent dans l’arbre. », quel groupe est le sujet du verbe « chantent » ?', choix:['Les oiseaux','chantent','dans l’arbre','l’arbre'], reponse:0},
  {id:22, question:'Dans « Demain arrivera le facteur. », quel groupe est le sujet du verbe « arrivera » ?', choix:['Demain','arrivera','le facteur','Demain arrivera'], reponse:2},
  {id:23, question:'Dans « Marie et Paul préparent le repas dans la cuisine. », quel groupe est le sujet du verbe « préparent » ?', choix:['Marie et Paul','le repas','dans la cuisine','la cuisine'], reponse:0},
  {id:24, question:'Dans « Dans la cour jouent les enfants. », quel groupe est le sujet du verbe « jouent » ?', choix:['Dans la cour','la cour','jouent','les enfants'], reponse:3},
  {id:25, question:'Dans « Le petit chat noir dort sur le canapé. », quel groupe est le sujet du verbe « dort » ?', choix:['Le petit chat noir','dort','sur le canapé','le canapé'], reponse:0},
  {id:26, question:'Dans « Nous regardons un film au salon. », quel mot est le sujet du verbe « regardons » ?', choix:['Nous','regardons','un film','au salon'], reponse:0},
  {id:27, question:'Dans « Toi et moi partirons tôt demain. », quel groupe est le sujet du verbe « partirons » ?', choix:['Toi et moi','partirons','tôt','demain'], reponse:0},
  {id:28, question:'Dans « Au loin apparaît un bateau. », quel groupe est le sujet du verbe « apparaît » ?', choix:['Au loin','apparaît','un bateau','loin'], reponse:2},
  {id:29, question:'Dans « La pluie et le vent frappent les vitres. », quel groupe est le sujet du verbe « frappent » ?', choix:['La pluie et le vent','frappent','les vitres','le vent'], reponse:0},
  {id:30, question:'Dans « Qui a fermé la porte ce matin ? », quel mot est le sujet du verbe « a fermé » ?', choix:['Qui','la porte','ce matin','fermé'], reponse:0},
  {id:31, question:'Dans « Sous la table se cache une souris. », quel groupe est le sujet du verbe « se cache » ?', choix:['Sous la table','la table','se cache','une souris'], reponse:3},
  {id:32, question:'Dans « Mon frère, avec ses amis, organise la fête. », quel groupe est le sujet du verbe « organise » ?', choix:['Mon frère','avec ses amis','ses amis','la fête'], reponse:0},
  {id:33, question:'Dans « Chaque matin, le boulanger ouvre sa boutique. », quel groupe est le sujet du verbe « ouvre » ?', choix:['Chaque matin','le boulanger','sa boutique','matin'], reponse:1},
  {id:34, question:'Dans « Les élèves de cette classe travaillent sérieusement. », quel groupe est le sujet du verbe « travaillent » ?', choix:['Les élèves de cette classe','cette classe','travaillent','sérieusement'], reponse:0},
  {id:35, question:'Dans « Vous connaissez la réponse depuis hier. », quel mot est le sujet du verbe « connaissez » ?', choix:['Vous','la réponse','depuis hier','hier'], reponse:0},
  {id:36, question:'Dans « Le long de la route poussent des coquelicots. », quel groupe est le sujet du verbe « poussent » ?', choix:['Le long de la route','la route','poussent','des coquelicots'], reponse:3},
  {id:37, question:'Dans « Ma sœur ou mon cousin viendra me chercher. », quel groupe est le sujet du verbe « viendra » ?', choix:['Ma sœur ou mon cousin','mon cousin','me','chercher'], reponse:0},
  {id:38, question:'Dans « On entend un bruit étrange dehors. », quel mot est le sujet du verbe « entend » ?', choix:['On','un bruit étrange','dehors','entend'], reponse:0},
  {id:39, question:'Dans « Cette histoire me plaît beaucoup. », quel groupe est le sujet du verbe « plaît » ?', choix:['Cette histoire','me','plaît','beaucoup'], reponse:0},
  {id:40, question:'Dans « Les clés de la voiture sont sur la table. », quel groupe est le sujet du verbe « sont » ?', choix:['Les clés de la voiture','la voiture','sur la table','la table'], reponse:0},

  {id:41, question:'Dans « Lina mange une pomme au goûter. », quel groupe est le COD du verbe « mange » ?', choix:['Lina','mange','une pomme','au goûter'], reponse:2},
  {id:42, question:'Dans « Le chat attrape la souris dans le jardin. », quel groupe est le COD du verbe « attrape » ?', choix:['Le chat','attrape','la souris','dans le jardin'], reponse:2},
  {id:43, question:'Dans « Nous regardons le paysage depuis la terrasse. », quel groupe est le COD du verbe « regardons » ?', choix:['Nous','le paysage','depuis la terrasse','la terrasse'], reponse:1},
  {id:44, question:'Dans « Paul lit son livre chaque soir. », quel groupe est le COD du verbe « lit » ?', choix:['Paul','lit','son livre','chaque soir'], reponse:2},
  {id:45, question:'Dans « J’écoute cette chanson dans ma chambre. », quel groupe est le COD du verbe « écoute » ?', choix:["J’","cette chanson","dans ma chambre","ma chambre"], reponse:1},
  {id:46, question:'Dans « Ils construisent une cabane près du bois. », quel groupe est le COD du verbe « construisent » ?', choix:['Ils','une cabane','près du bois','du bois'], reponse:1},
  {id:47, question:'Dans « Tu connais la réponse depuis hier. », quel groupe est le COD du verbe « connais » ?', choix:['Tu','la réponse','depuis hier','hier'], reponse:1},
  {id:48, question:'Dans « Le professeur explique la leçon aux élèves. », quel groupe est le COD du verbe « explique » ?', choix:['Le professeur','la leçon','aux élèves','explique'], reponse:1},
  {id:49, question:'Dans « Ma sœur prépare un gâteau pour dimanche. », quel groupe est le COD du verbe « prépare » ?', choix:['Ma sœur','un gâteau','pour dimanche','dimanche'], reponse:1},
  {id:50, question:'Dans « Les enfants admirent les étoiles cette nuit. », quel groupe est le COD du verbe « admirent » ?', choix:['Les enfants','les étoiles','cette nuit','admirent'], reponse:1},
  {id:51, question:'Dans « Je rencontre mon voisin devant l’école. », quel groupe est le COD du verbe « rencontre » ?', choix:['Je','mon voisin',"devant l’école",'rencontre'], reponse:1},
  {id:52, question:'Dans « Elle ferme les volets avant la nuit. », quel groupe est le COD du verbe « ferme » ?', choix:['Elle','les volets','avant la nuit','la nuit'], reponse:1},
  {id:53, question:'Dans « Vous attendez le bus devant la mairie. », quel groupe est le COD du verbe « attendez » ?', choix:['Vous','le bus','devant la mairie','la mairie'], reponse:1},
  {id:54, question:'Dans « Le jardinier arrose les fleurs chaque matin. », quel groupe est le COD du verbe « arrose » ?', choix:['Le jardinier','les fleurs','chaque matin','arrose'], reponse:1},
  {id:55, question:'Dans « Nous avons perdu nos clés dans le parc. », quel groupe est le COD du verbe « avons perdu » ?', choix:['Nous','nos clés','dans le parc','le parc'], reponse:1},
  {id:56, question:'Dans « Léo dessine un dragon sur son cahier. », quel groupe est le COD du verbe « dessine » ?', choix:['Léo','un dragon','sur son cahier','son cahier'], reponse:1},
  {id:57, question:'Dans « Le chien suit son maître sur le chemin. », quel groupe est le COD du verbe « suit » ?', choix:['Le chien','son maître','sur le chemin','le chemin'], reponse:1},
  {id:58, question:'Dans « On entend un bruit dans le grenier. », quel groupe est le COD du verbe « entend » ?', choix:['On','un bruit','dans le grenier','le grenier'], reponse:1},
  {id:59, question:'Dans « Ils visitent le musée pendant les vacances. », quel groupe est le COD du verbe « visitent » ?', choix:['Ils','le musée','pendant les vacances','les vacances'], reponse:1},
  {id:60, question:'Dans « La tempête a cassé plusieurs branches cette nuit. », quel groupe est le COD du verbe « a cassé » ?', choix:['La tempête','plusieurs branches','cette nuit','a cassé'], reponse:1}
];

for (const correction of V51_CORRECTIONS) {
  const question = QUESTIONS.find((item) => item.id === correction.id);
  if (question) Object.assign(question, correction, {version: Math.max(2, (question.version || 1) + 1)});
}
