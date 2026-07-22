const STORAGE_PROGRESS='capCollegeV43Progress';
const STORAGE_RESULT='capCollegeV43Result';
const DIAGNOSTIC_SIZE=100;
const BASE_PER_SKILL=5;
const MIN_ANSWERS_PER_SKILL=3;

let current=0;
let answers=[];
let diagnosticQuestions=[];

document.getElementById('qCount').textContent=DIAGNOSTIC_SIZE;

function shuffle(array){
  const copy=[...array];
  for(let i=copy.length-1;i>0;i--){
    const j=Math.floor(Math.random()*(i+1));
    [copy[i],copy[j]]=[copy[j],copy[i]];
  }
  return copy;
}

/*
  Le questionnaire est organisé en plusieurs tours.
  Chaque thème apparaît une fois par tour afin que les premières questions
  couvrent rapidement l'ensemble des compétences.
*/
function buildBalancedDiagnostic(){
  const groups={};
  QUESTIONS.forEach(q=>{
    if(!groups[q.competenceId])groups[q.competenceId]=[];
    groups[q.competenceId].push(q);
  });

  const prepared=Object.values(groups).map(group=>{
    const easy=shuffle(group.filter(q=>q.difficulte===1));
    const harder=shuffle(group.filter(q=>q.difficulte>=2));
    return shuffle([...easy.slice(0,3),...harder.slice(0,2)]).slice(0,BASE_PER_SKILL);
  });

  let selected=[];
  for(let round=0;round<BASE_PER_SKILL;round++){
    const roundQuestions=prepared.map(group=>group[round]).filter(Boolean);
    selected.push(...shuffle(roundQuestions));
  }

  const selectedIds=new Set(selected.map(q=>q.id));
  const remaining=shuffle(QUESTIONS.filter(q=>!selectedIds.has(q.id)));
  selected.push(...remaining.slice(0,DIAGNOSTIC_SIZE-selected.length));

  return selected.slice(0,DIAGNOSTIC_SIZE);
}

function showTest(){
  document.getElementById('intro').classList.add('hidden');
  document.getElementById('test').classList.remove('hidden');
  window.scrollTo(0,0);
}

function startTest(){
  diagnosticQuestions=buildBalancedDiagnostic();
  current=0;
  answers=Array(diagnosticQuestions.length).fill(null);
  saveProgress();
  showTest();
  renderQuestion();
}

function resumeTest(){
  const saved=localStorage.getItem(STORAGE_PROGRESS);
  if(!saved){startTest();return;}
  try{
    const data=JSON.parse(saved);
    const byId=new Map(QUESTIONS.map(q=>[q.id,q]));
    diagnosticQuestions=(data.questionIds||[]).map(id=>byId.get(id)).filter(Boolean);
    if(!diagnosticQuestions.length){startTest();return;}
    current=Math.min(Number.isInteger(data.current)?data.current:0,diagnosticQuestions.length-1);
    answers=Array.isArray(data.answers)?data.answers:Array(diagnosticQuestions.length).fill(null);
    while(answers.length<diagnosticQuestions.length)answers.push(null);
    showTest();
    renderQuestion();
  }catch(e){
    startTest();
  }
}

function saveProgress(){
  localStorage.setItem(STORAGE_PROGRESS,JSON.stringify({
    current,
    answers,
    questionIds:diagnosticQuestions.map(q=>q.id)
  }));
}

function selectAnswer(index){
  answers[current]=index;
  saveProgress();
  renderChoices();
}

function renderChoices(){
  const q=diagnosticQuestions[current];
  document.getElementById('choices').innerHTML=q.choix.map((choice,index)=>`
    <label class="choice ${answers[current]===index?'selected':''}">
      <input type="radio" name="answer" ${answers[current]===index?'checked':''} onchange="selectAnswer(${index})">
      ${choice}
    </label>`).join('');
}

function renderQuestion(){
  const q=diagnosticQuestions[current];
  const answeredCount=answers.filter(answer=>answer!==null).length;
  document.getElementById('counter').textContent=`Question ${current+1} / ${diagnosticQuestions.length} · ${answeredCount} répondue${answeredCount>1?'s':''}`;
  document.getElementById('topDomain').textContent=q.domaine;
  document.getElementById('progressBar').style.width=`${((current+1)/diagnosticQuestions.length)*100}%`;
  document.getElementById('domainBadge').textContent=`Domaine : ${q.domaine}`;
  document.getElementById('skillBadge').textContent=`Thème : ${q.competence}`;

  const tense=document.getElementById('tenseBadge');
  if(q.domaine==='Conjugaison'){
    tense.textContent=`Temps attendu : ${q.competence}`;
    tense.classList.remove('hidden');
    document.getElementById('questionText').textContent=`[${q.competence}] ${q.question}`;
  }else{
    tense.textContent='';
    tense.classList.add('hidden');
    document.getElementById('questionText').textContent=q.question;
  }

  document.getElementById('prevBtn').disabled=current===0;
  document.getElementById('nextBtn').textContent=current===diagnosticQuestions.length-1?'Voir le bilan':'Suivante';
  renderChoices();
}

function nextQuestion(){
  if(answers[current]===null){
    alert('Choisis une réponse avant de continuer.');
    return;
  }
  if(current<diagnosticQuestions.length-1){
    current++;
    saveProgress();
    renderQuestion();
    window.scrollTo(0,0);
  }else{
    finishTest(false);
  }
}

function prevQuestion(){
  if(current>0){
    current--;
    saveProgress();
    renderQuestion();
    window.scrollTo(0,0);
  }
}

function stopTest(){
  const answeredCount=answers.filter(answer=>answer!==null).length;
  if(answeredCount===0){
    alert('Réponds au moins à une question avant de demander un bilan.');
    return;
  }

  const message=
    `Tu as répondu à ${answeredCount} question${answeredCount>1?'s':''}.\n\n`+
    `Le bilan évaluera uniquement ces réponses. Les thèmes comportant moins de ${MIN_ANSWERS_PER_SKILL} réponses seront indiqués « En attente d’évaluation ».\n\n`+
    `Veux-tu arrêter maintenant ?`;

  if(confirm(message)){
    finishTest(true);
  }
}

function finishTest(stoppedEarly=false){
  const stats={};

  // Tous les thèmes existent dans le bilan, même ceux qui n'ont pas été suffisamment testés.
  QUESTIONS.forEach(q=>{
    if(!stats[q.competence]){
      stats[q.competence]={
        competenceId:q.competenceId,
        domain:q.domaine,
        ok:0,
        total:0,
        minimumRequired:MIN_ANSWERS_PER_SKILL
      };
    }
  });

  let totalOk=0;
  let answeredTotal=0;

  diagnosticQuestions.forEach((q,index)=>{
    if(answers[index]===null)return;

    stats[q.competence].total++;
    answeredTotal++;

    if(answers[index]===q.reponse){
      stats[q.competence].ok++;
      totalOk++;
    }
  });

  Object.values(stats).forEach(s=>{
    s.pending=s.total<MIN_ANSWERS_PER_SKILL;
  });

  const result={
    version:'4.3',
    bankSize:QUESTIONS.length,
    stats,
    totalOk,
    total:answeredTotal,
    plannedTotal:diagnosticQuestions.length,
    stoppedEarly,
    minimumAnswersPerSkill:MIN_ANSWERS_PER_SKILL,
    answers,
    questionIds:diagnosticQuestions.map(q=>q.id),
    date:new Date().toISOString()
  };

  localStorage.setItem(STORAGE_RESULT,JSON.stringify(result));
  localStorage.setItem('capCollegeV41Result',JSON.stringify(result));
  localStorage.setItem('capCollegeV4Result',JSON.stringify(result));
  localStorage.removeItem(STORAGE_PROGRESS);
  window.location.href='resultats.html';
}
