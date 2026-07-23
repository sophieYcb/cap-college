const STORAGE_PROGRESS='capCollegeV43Progress';
const STORAGE_PROGRESS_BACKUP='capCollegeDiagnosticProgressBackup';
const STORAGE_RESULT='capCollegeV43Result';
const PROGRESS_FORMAT_VERSION='6.1';
const MIN_ANSWERS_PER_SKILL=3;
const BASE_PER_SKILL=MIN_ANSWERS_PER_SKILL;
const DIAGNOSTIC_SIZE=new Set(QUESTIONS.map(q=>q.competenceId)).size*MIN_ANSWERS_PER_SKILL;
const APPROXIMATE_QUESTIONS_PER_MINUTE=2;

let current=0;
let answers=[];
let answerResults=[];
let answerFeedback=[];
let diagnosticQuestions=[];
let autoAdvanceTimer=null;
let remoteSessionId=null;
let remoteDiagnosticId=null;
let plannedMinutes=30;
let diagnosticFinished=false;
let remoteSequenceOffset=0;
let discoveredRemoteSession=null;

function initialiseThemeSelector(){
  const select=document.getElementById('diagnosticSkill');
  const themes=[...new Map(QUESTIONS.map(q=>[q.competenceId,{id:q.competenceId,name:q.competence,domain:q.domaine}])).values()]
    .sort((a,b)=>a.domain.localeCompare(b.domain,'fr')||a.name.localeCompare(b.name,'fr'));
  select.innerHTML='<option value="all">Tous les thèmes — diagnostic complet</option>'+themes.map(theme=>{
    const count=QUESTIONS.filter(q=>q.competenceId===theme.id).length;
    return `<option value="${theme.id}">${theme.domain} · ${theme.name} (${count} questions)</option>`;
  }).join('');
  refreshDiagnosticSize();
}

function refreshDiagnosticSize(){
  const select=document.getElementById('diagnosticSkill');
  const selected=select.value;
  const hint=document.getElementById('themeSelectionHint');
  if(hint){
    hint.textContent=selected==='all'
      ?`${new Set(QUESTIONS.map(q=>q.competenceId)).size} thèmes disponibles · le diagnostic avancera progressivement`
      :`${select.options[select.selectedIndex].text} · séance ciblée sur ce thème`;
  }
}

function selectedDuration(){
  const selected=document.querySelector('input[name="sessionDuration"]:checked');
  return selected?Number(selected.value):30;
}

function refreshDurationSummary(){
  plannedMinutes=selectedDuration();
  document.getElementById('durationSummary').textContent=`${plannedMinutes} min`;
}

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
function buildBalancedDiagnostic(selectedSkill='all',limit=DIAGNOSTIC_SIZE){
  if(selectedSkill!=='all'){
    return prioritiseQuestions(
      QUESTIONS.filter(q=>q.competenceId===selectedSkill)
    ).slice(0,limit);
  }
  const groups={};
  QUESTIONS.forEach(q=>{
    if(!groups[q.competenceId])groups[q.competenceId]=[];
    groups[q.competenceId].push(q);
  });

  const prepared=Object.values(groups).map(group=>({
    attempts:group.reduce((total,q)=>total+(q.history?.attempts||0),0),
    random:Math.random(),
    questions:prioritiseQuestions(group).slice(0,BASE_PER_SKILL)
  })).sort((a,b)=>a.attempts-b.attempts||a.random-b.random);

  let selected=[];
  for(let round=0;round<BASE_PER_SKILL;round++){
    const roundQuestions=prepared.map(group=>group.questions[round]).filter(Boolean);
    selected.push(...roundQuestions);
  }

  const selectedIds=new Set(selected.map(q=>q.id));
  const remaining=shuffle(QUESTIONS.filter(q=>!selectedIds.has(q.id)));
  selected.push(...remaining.slice(0,DIAGNOSTIC_SIZE-selected.length));

  return selected.slice(0,Math.min(limit,DIAGNOSTIC_SIZE));
}

function prioritiseQuestions(questions){
  return questions
    .map(question=>({question,random:Math.random()}))
    .sort((a,b)=>{
      const aAttempts=a.question.history?.attempts||0;
      const bAttempts=b.question.history?.attempts||0;
      if(aAttempts!==bAttempts)return aAttempts-bAttempts;

      const aRate=aAttempts?(a.question.history?.correctAnswers||0)/aAttempts:0;
      const bRate=bAttempts?(b.question.history?.correctAnswers||0)/bAttempts:0;
      if(aRate!==bRate)return aRate-bRate;

      if(a.question.difficulte!==b.question.difficulte){
        return a.question.difficulte-b.question.difficulte;
      }
      return a.random-b.random;
    })
    .map(item=>item.question);
}

function showTest(){
  document.getElementById('intro').classList.add('hidden');
  document.getElementById('test').classList.remove('hidden');
  window.scrollTo(0,0);
}

async function startTest(){
  clearTimeout(autoAdvanceTimer);
  diagnosticFinished=false;
  const saved=readSavedProgress();
  if(saved){
    const answered=Array.isArray(saved.answers)?saved.answers.filter(answer=>answer!==null).length:0;
    const replace=confirm(`Un diagnostic en cours contient ${answered} réponse${answered>1?'s':''}.\n\nOK : l’effacer et recommencer.\nAnnuler : reprendre le diagnostic.`);
    if(!replace){resumeTest();return;}
  }
  const selectedSkill=document.getElementById('diagnosticSkill').value;
  plannedMinutes=selectedDuration();
  const questionLimit=plannedMinutes*APPROXIMATE_QUESTIONS_PER_MINUTE;
  diagnosticQuestions=buildBalancedDiagnostic(selectedSkill,questionLimit);
  current=0;
  answers=Array(diagnosticQuestions.length).fill(null);
  answerResults=Array(diagnosticQuestions.length).fill(null);
  answerFeedback=Array(diagnosticQuestions.length).fill(null);
  remoteSessionId=null;
  remoteDiagnosticId=null;
  remoteSequenceOffset=0;
  if(CapCollegeSupabase.configured()){
    try{
      const remote=await CapCollegeSupabase.startDiagnostic(plannedMinutes,selectedSkill);
      remoteSessionId=remote.session_id;
      remoteDiagnosticId=remote.diagnostic_id;
    }catch(error){
      alert('Le diagnostic en ligne n’a pas pu démarrer. Réessaie dans un instant.');
      return;
    }
  }
  saveProgress();
  showTest();
  renderQuestion();
}

async function resumeTest(){
  clearTimeout(autoAdvanceTimer);
  diagnosticFinished=false;
  const data=readSavedProgress();
  if(!data){
    const remote=discoveredRemoteSession||
      (CapCollegeSupabase.configured()
        ?await CapCollegeSupabase.getActiveDiagnosticSession():null);
    if(!remote){
      alert('Aucune séance active à reprendre.');
      refreshProgressUI();
      return;
    }
    plannedMinutes=Number(remote.planned_minutes)||30;
    remoteSequenceOffset=Number(remote.recorded_answers)||0;
    remoteSessionId=remote.session_id;
    remoteDiagnosticId=remote.diagnostic_id;
    const remoteSkill=remote.focus_competence_id||'all';
    const remaining=Math.max(
      1,
      plannedMinutes*APPROXIMATE_QUESTIONS_PER_MINUTE-remoteSequenceOffset
    );
    diagnosticQuestions=buildBalancedDiagnostic(remoteSkill,remaining);
    current=0;
    answers=Array(diagnosticQuestions.length).fill(null);
    answerResults=Array(diagnosticQuestions.length).fill(null);
    answerFeedback=Array(diagnosticQuestions.length).fill(null);
    const durationRadio=document.querySelector(`input[name="sessionDuration"][value="${plannedMinutes}"]`);
    if(durationRadio)durationRadio.checked=true;
    if(document.querySelector(`#diagnosticSkill option[value="${remoteSkill}"]`)){
      document.getElementById('diagnosticSkill').value=remoteSkill;
      refreshDiagnosticSize();
    }
    refreshDurationSummary();
    saveProgress();
    showTest();
    renderQuestion();
    return;
  }
  if(CapCollegeSupabase.configured()&&data.remoteSessionId){
    try{
      const remoteState=await CapCollegeSupabase.getDiagnosticSessionState(
        data.remoteSessionId
      );
      if(!remoteState||remoteState.session_status!=='active'){
        localStorage.removeItem(STORAGE_PROGRESS);
        localStorage.removeItem(STORAGE_PROGRESS_BACKUP);
        refreshProgressUI();
        alert('Cette séance est déjà terminée. La sauvegarde locale a été supprimée : commence un nouveau diagnostic.');
        return;
      }
    }catch(error){
      alert('Impossible de vérifier la séance enregistrée. Vérifie ta connexion puis réessaie.');
      return;
    }
  }
  try{
    const byId=new Map(QUESTIONS.map(q=>[q.id,q]));
    diagnosticQuestions=(data.questionIds||[]).map(id=>byId.get(id)).filter(Boolean);
    if(!diagnosticQuestions.length)throw new Error('Progression vide');
    current=Math.min(Number.isInteger(data.current)?data.current:0,diagnosticQuestions.length-1);
    answers=Array.isArray(data.answers)?data.answers:Array(diagnosticQuestions.length).fill(null);
    answerResults=Array.isArray(data.answerResults)?data.answerResults:Array(diagnosticQuestions.length).fill(null);
    answerFeedback=Array.isArray(data.answerFeedback)?data.answerFeedback:Array(diagnosticQuestions.length).fill(null);
    while(answers.length<diagnosticQuestions.length)answers.push(null);
    while(answerResults.length<diagnosticQuestions.length)answerResults.push(null);
    while(answerFeedback.length<diagnosticQuestions.length)answerFeedback.push(null);
    remoteSessionId=data.remoteSessionId||null;
    remoteDiagnosticId=data.remoteDiagnosticId||null;
    remoteSequenceOffset=Number(data.remoteSequenceOffset)||0;
    plannedMinutes=Number(data.plannedMinutes)||30;
    const durationRadio=document.querySelector(`input[name="sessionDuration"][value="${plannedMinutes}"]`);
    if(durationRadio)durationRadio.checked=true;
    refreshDurationSummary();
    const restoredSkill=data.selectedSkill||'all';
    if(document.querySelector(`#diagnosticSkill option[value="${restoredSkill}"]`)){
      document.getElementById('diagnosticSkill').value=restoredSkill;
      refreshDiagnosticSize();
    }
    showTest();
    renderQuestion();
  }catch(e){
    alert('La progression enregistrée est illisible. Elle n’a pas été écrasée. Tu peux tenter de réimporter une sauvegarde.');
  }
}

function readSavedProgress(){
  for(const key of [STORAGE_PROGRESS,STORAGE_PROGRESS_BACKUP]){
    try{
      const raw=localStorage.getItem(key);
      if(!raw)continue;
      const data=JSON.parse(raw);
      if(
        CapCollegeSupabase.configured()&&
        data.remoteSessionId&&
        data.version!==PROGRESS_FORMAT_VERSION
      ){
        localStorage.removeItem(key);
        continue;
      }
      if(Array.isArray(data.questionIds)&&data.questionIds.length)return data;
    }catch(e){}
  }
  return null;
}

function saveProgress(){
  const payload={
    format:'cap-college-diagnostic-progress',
    version:PROGRESS_FORMAT_VERSION,
    current,
    answers,
    answerResults,
    answerFeedback,
    remoteSessionId,
    remoteDiagnosticId,
    remoteSequenceOffset,
    plannedMinutes,
    questionIds:diagnosticQuestions.map(q=>q.id),
    selectedSkill:document.getElementById('diagnosticSkill').value,
    savedAt:new Date().toISOString()
  };
  const serialized=JSON.stringify(payload);
  try{
    localStorage.setItem(STORAGE_PROGRESS,serialized);
    localStorage.setItem(STORAGE_PROGRESS_BACKUP,serialized);
  }catch(e){
    alert('Le navigateur bloque la sauvegarde locale. Exporte ta progression avant de quitter la page.');
  }
  refreshProgressUI();
}

function refreshProgressUI(){
  const data=readSavedProgress();
  const notice=document.getElementById('savedProgressNotice');
  const resume=document.getElementById('resumeDiagnosticBtn');
  const exportButton=document.getElementById('exportProgressBtn');
  if(!notice||!resume||!exportButton)return;
  if(!data){
    notice.classList.add('hidden');
    resume.disabled=true;
    exportButton.disabled=true;
    return;
  }
  const answered=(data.answers||[]).filter(answer=>answer!==null).length;
  const total=(data.questionIds||[]).length;
  const date=data.savedAt?new Date(data.savedAt).toLocaleString('fr-FR'):'date inconnue';
  notice.textContent=`Progression retrouvée : ${answered}/${total} réponses · sauvegardée le ${date}.`;
  notice.classList.remove('hidden');
  resume.disabled=false;
  exportButton.disabled=false;
}

function downloadProgress(content,name){
  const blob=new Blob([content],{type:'application/json;charset=utf-8'});
  const url=URL.createObjectURL(blob);
  const link=document.createElement('a');link.href=url;link.download=name;document.body.appendChild(link);link.click();link.remove();URL.revokeObjectURL(url);
}

function exportProgress(){
  const data=readSavedProgress();
  if(!data){alert('Aucune progression à exporter.');return;}
  downloadProgress(JSON.stringify(data,null,2),`cap-college-progression-${new Date().toISOString().slice(0,10)}.json`);
}

async function importProgress(event){
  const file=event.target.files&&event.target.files[0];
  if(!file)return;
  try{
    const data=JSON.parse(await file.text());
    if(!data||!Array.isArray(data.questionIds)||!Array.isArray(data.answers)||!data.questionIds.length)throw new Error('Format invalide');
    const serialized=JSON.stringify(data);
    localStorage.setItem(STORAGE_PROGRESS,serialized);
    localStorage.setItem(STORAGE_PROGRESS_BACKUP,serialized);
    refreshProgressUI();
    resumeTest();
  }catch(e){
    alert('Ce fichier de progression n’est pas reconnu.');
  }finally{
    event.target.value='';
  }
}

async function selectAnswer(index){
  clearTimeout(autoAdvanceTimer);
  const q=diagnosticQuestions[current];
  if(q.source==='supabase'){
    if(!remoteSessionId){
      alert('Cette séance en ligne n’est plus disponible. Recommence le diagnostic.');
      return;
    }
    try{
      const result=await CapCollegeSupabase.submitAnswer(
        remoteSessionId,
        q.questionVersionId,
        q.choiceIds[index],
        remoteSequenceOffset+current+1
      );
      answerResults[current]=Boolean(result.is_correct);
      answerFeedback[current]={
        correctIndex:q.choiceIds.indexOf(result.correct_choice_id),
        explanation:result.correction_explanation||SKILL_LESSONS[q.competence]||''
      };
    }catch(error){
      const reason=String(error?.message||'Erreur inconnue');
      console.error('Enregistrement Supabase refusé :',error);
      if(/session|available|active/i.test(reason)){
        localStorage.removeItem(STORAGE_PROGRESS);
        localStorage.removeItem(STORAGE_PROGRESS_BACKUP);
        alert('Cette ancienne séance est déjà terminée. Sa sauvegarde locale vient d’être supprimée. Retourne à l’accueil du diagnostic et commence une nouvelle séance.');
      }else{
        alert(`La réponse n’a pas pu être enregistrée.\n\nDétail : ${reason}`);
      }
      return;
    }
  }else{
    answerResults[current]=index===q.reponse;
    answerFeedback[current]={
      correctIndex:q.reponse,
      explanation:SKILL_LESSONS[q.competence]||''
    };
  }
  answers[current]=index;
  saveProgress();
  renderChoices();
  if(current<diagnosticQuestions.length-1){
    autoAdvanceTimer=setTimeout(()=>{
      current++;
      saveProgress();
      renderQuestion();
      window.scrollTo(0,0);
    },350);
  }
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
  const displayedNumber=remoteSequenceOffset+current+1;
  const displayedAnswered=remoteSequenceOffset+answeredCount;
  document.getElementById('counter').textContent=`Question ${displayedNumber} · ${displayedAnswered} réponse${displayedAnswered>1?'s':''} enregistrée${displayedAnswered>1?'s':''}`;
  document.getElementById('topDomain').textContent=q.domaine;
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
  document.getElementById('nextBtn').textContent=current===diagnosticQuestions.length-1?'Terminer la séance':'Suivante';
  renderChoices();
}

function nextQuestion(){
  clearTimeout(autoAdvanceTimer);
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
  clearTimeout(autoAdvanceTimer);
  if(current>0){
    current--;
    saveProgress();
    renderQuestion();
    window.scrollTo(0,0);
  }
}

function pauseTest(){
  clearTimeout(autoAdvanceTimer);
  const answeredCount=answers.filter(answer=>answer!==null).length;
  saveProgress();
  document.getElementById('test').classList.add('hidden');
  document.getElementById('intro').classList.remove('hidden');
  refreshProgressUI();
  const notice=document.getElementById('savedProgressNotice');
  notice.textContent=`Séance mise en pause après ${remoteSequenceOffset+answeredCount} réponse${remoteSequenceOffset+answeredCount>1?'s':''}. Tu pourras reprendre exactement ici.`;
  notice.classList.remove('hidden');
  window.scrollTo(0,0);
}

async function finishTest(stoppedEarly=false){
  diagnosticFinished=true;
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

    if(answerResults[index]===true){
      stats[q.competence].ok++;
      totalOk++;
    }
  });

  Object.values(stats).forEach(s=>{
    s.pending=s.total<MIN_ANSWERS_PER_SKILL;
  });

  const result={
    version:'6.0',
    bankSize:QUESTIONS.length,
    stats,
    totalOk,
    total:answeredTotal,
    plannedTotal:diagnosticQuestions.length,
    stoppedEarly,
    minimumAnswersPerSkill:MIN_ANSWERS_PER_SKILL,
    answers,
    answerResults,
    reviewItems:diagnosticQuestions.map((q,index)=>{
      if(answers[index]===null)return null;
      const feedback=answerFeedback[index]||{};
      return {
        questionId:q.id,
        domain:q.domaine,
        skill:q.competence,
        prompt:q.question,
        selectedAnswer:q.choix[answers[index]],
        correctAnswer:q.choix[feedback.correctIndex],
        explanation:feedback.explanation||'',
        isCorrect:answerResults[index]===true
      };
    }).filter(Boolean),
    questionIds:diagnosticQuestions.map(q=>q.id),
    date:new Date().toISOString()
  };

  localStorage.setItem(STORAGE_RESULT,JSON.stringify(result));
  localStorage.setItem('capCollegeV41Result',JSON.stringify(result));
  localStorage.setItem('capCollegeV4Result',JSON.stringify(result));
  localStorage.removeItem(STORAGE_PROGRESS);
  localStorage.removeItem(STORAGE_PROGRESS_BACKUP);
  if(remoteSessionId){
    try{
      await CapCollegeSupabase.finishDiagnostic(remoteSessionId);
    }catch(error){
      console.warn('La séance distante n’a pas pu être clôturée.',error);
    }
  }
  window.location.href='resultats.html';
}

window.addEventListener('pagehide',()=>{
  if(!diagnosticFinished&&diagnosticQuestions.length&&document.getElementById('test')&&!document.getElementById('test').classList.contains('hidden'))saveProgress();
});
document.addEventListener('visibilitychange',()=>{
  if(!diagnosticFinished&&document.visibilityState==='hidden'&&diagnosticQuestions.length)saveProgress();
});
refreshProgressUI();
initialiseThemeSelector();
document.querySelectorAll('input[name="sessionDuration"]').forEach(input=>{
  input.addEventListener('change',refreshDurationSummary);
});
refreshDurationSummary();

async function discoverRemoteResume(){
  const wantsImmediateResume=new URLSearchParams(location.search).get('resume')==='1';
  if(!CapCollegeSupabase.configured()){
    if(wantsImmediateResume&&readSavedProgress())await resumeTest();
    return;
  }
  try{
    discoveredRemoteSession=await CapCollegeSupabase.getActiveDiagnosticSession();
    if(!discoveredRemoteSession)return;
    const resume=document.getElementById('resumeDiagnosticBtn');
    const notice=document.getElementById('savedProgressNotice');
    const panel=document.getElementById('activeSessionIntro');
    document.getElementById('newSessionConfiguration').classList.add('hidden');
    panel.classList.remove('hidden');
    document.getElementById('activeSessionIntroTitle').textContent=
      discoveredRemoteSession.focus_name;
    document.getElementById('activeSessionIntroDetails').textContent=
      `${discoveredRemoteSession.recorded_answers} réponse${discoveredRemoteSession.recorded_answers>1?'s':''} enregistrée${discoveredRemoteSession.recorded_answers>1?'s':''} · séance de ${discoveredRemoteSession.planned_minutes} min`;
    resume.disabled=false;
    notice.textContent=`Séance en ligne retrouvée : ${discoveredRemoteSession.focus_name}.`;
    notice.classList.remove('hidden');
    document.getElementById('continueActiveSessionButton').onclick=resumeTest;
    document.getElementById('closeActiveSessionButton').onclick=async()=>{
      const close=confirm('Ta progression générale sera conservée, mais cette séance sera clôturée. Veux-tu choisir un nouveau thème et une nouvelle durée ?');
      if(!close)return;
      await CapCollegeSupabase.closeDiagnosticSession(discoveredRemoteSession.session_id);
      localStorage.removeItem(STORAGE_PROGRESS);
      localStorage.removeItem(STORAGE_PROGRESS_BACKUP);
      discoveredRemoteSession=null;
      panel.classList.add('hidden');
      document.getElementById('newSessionConfiguration').classList.remove('hidden');
      refreshProgressUI();
    };
    if(wantsImmediateResume)await resumeTest();
  }catch(error){
    console.warn('Recherche de séance active impossible.',error);
  }
}
discoverRemoteResume();
