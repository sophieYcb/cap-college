const VALIDATION_CAMPAIGN_ID=window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID||null;
const LEARNER_PROFILE=CapCollegeSupabase.getLearnerProfile();
const STORAGE_SUFFIX=VALIDATION_CAMPAIGN_ID
  ?':validation:'+VALIDATION_CAMPAIGN_ID
  :LEARNER_PROFILE?':learner:'+LEARNER_PROFILE.id:'';
const STORAGE_PROGRESS=`capCollegeV43Progress${STORAGE_SUFFIX}`;
const STORAGE_PROGRESS_BACKUP=`capCollegeDiagnosticProgressBackup${STORAGE_SUFFIX}`;
const STORAGE_RESULT=`capCollegeV43Result${STORAGE_SUFFIX}`;
const PROGRESS_FORMAT_VERSION='7.0';
const MIN_ANSWERS_PER_SKILL=4;
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
let cumulativeDiagnosticProgress=null;
const CAN_FLAG_QUESTIONS=CapCollegeSupabase.canReportQuestions();

if(CAN_FLAG_QUESTIONS){
  document.getElementById('flagQuestionBtn').classList.remove('hidden');
}

if(VALIDATION_CAMPAIGN_ID){
  document.getElementById('validationModeNotice').classList.remove('hidden');
  document.getElementById('validationCampaignName').textContent=
    window.CAP_COLLEGE_VALIDATION_CAMPAIGN_NAME||'Campagne de validation';
  document.getElementById('evaluationModeBadge').textContent='Mode validation';
  document.querySelector('#intro h1').textContent='Diagnostic de validation';
  document.getElementById('startDiagnosticBtn').textContent='Commencer ce scénario';
  document.getElementById('resumeDiagnosticBtn').textContent='Reprendre ce scénario';
}

function initialiseThemeSelector(){
  const subjects=[...new Map(
    QUESTIONS.map(q=>[q.subjectCode||'french',q.subject||'Français'])
  ).entries()].sort((a,b)=>a[1].localeCompare(b[1],'fr'));
  document.getElementById('diagnosticSubject').innerHTML=subjects
    .map(([code,name])=>`<option value="${code}">${name}</option>`).join('');
  const requestedSubject=new URLSearchParams(location.search).get('subject');
  const subjectSelect=document.getElementById('diagnosticSubject');
  if(requestedSubject&&subjectSelect.querySelector(
    `option[value="${requestedSubject}"]`
  )){
    subjectSelect.value=requestedSubject;
  }
  updateDiagnosticDomains();
}

function updateDiagnosticDomains(){
  const subjectSelect=document.getElementById('diagnosticSubject');
  const subject=subjectSelect.value;
  if(!VALIDATION_CAMPAIGN_ID){
    const subjectName=subjectSelect.options[subjectSelect.selectedIndex]?.text||
      'Matière';
    document.querySelector('#intro h1').textContent=
      'Diagnostic '+subjectName+' 6e';
    document.getElementById('evaluationModeBadge').textContent=
      subjectName+' 6e';
    document.title='Diagnostic '+subjectName+' 6e — Cap Collège';
  }
  const domains=[...new Map(
    QUESTIONS.filter(q=>(q.subjectCode||'french')===subject)
      .map(q=>[q.domainCode||q.domaine,q.domaine])
  ).entries()].sort((a,b)=>a[1].localeCompare(b[1],'fr'));
  document.getElementById('diagnosticDomain').innerHTML=
    '<option value="all">Toutes les catégories</option>'+
    domains.map(([code,name])=>`<option value="${code}">${name}</option>`).join('');
  updateDiagnosticSkills();
}

function updateDiagnosticSkills(){
  const subject=document.getElementById('diagnosticSubject').value;
  const domain=document.getElementById('diagnosticDomain').value;
  const themes=[...new Map(
    QUESTIONS.filter(q=>(q.subjectCode||'french')===subject)
      .filter(q=>domain==='all'||(q.domainCode||q.domaine)===domain)
      .map(q=>[q.subcategoryCode||q.competenceId,q.subcategory||q.competence])
  ).entries()].sort((a,b)=>a[1].localeCompare(b[1],'fr'));
  document.getElementById('diagnosticSkill').innerHTML=
    '<option value="all">Toutes les sous-catégories</option>'+
    themes.map(([id,name])=>`<option value="${id}">${name}</option>`).join('');
  refreshDiagnosticSize();
}

function refreshDiagnosticSize(){
  const select=document.getElementById('diagnosticSkill');
  const selected=select.value;
  const hint=document.getElementById('themeSelectionHint');
  if(hint){
    hint.textContent=selected==='all'
      ?`${select.options.length-1} sous-catégories disponibles · le diagnostic avancera progressivement`
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
  const subject=document.getElementById('diagnosticSubject')?.value||'french';
  const domain=document.getElementById('diagnosticDomain')?.value||'all';
  const scopedQuestions=QUESTIONS
    .filter(q=>(q.subjectCode||'french')===subject)
    .filter(q=>domain==='all'||(q.domainCode||q.domaine)===domain);
  const progressBySkill=new Map(
    (cumulativeDiagnosticProgress?.skills||[])
      .map(skill=>[skill.competenceId,skill])
  );
  const candidateQuestions=scopedQuestions.filter(
    q=>!progressBySkill.get(q.competenceId)?.sufficientEvidence
  );
  if(selectedSkill!=='all'){
    return prioritiseQuestions(
      candidateQuestions.filter(q=>(q.subcategoryCode||q.competenceId)===selectedSkill)
    ).slice(0,limit);
  }
  const groups={};
  candidateQuestions.forEach(q=>{
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
  const targetSize=Math.min(limit,candidateQuestions.length);
  const remaining=shuffle(candidateQuestions.filter(q=>!selectedIds.has(q.id)));
  selected.push(...remaining.slice(0,targetSize-selected.length));

  return selected.slice(0,targetSize);
}

function restoreDiagnosticSelection(skillId='all',subjectCode=null){
  const matching=skillId==='all'
    ?QUESTIONS.find(q=>(q.subjectCode||'french')===(subjectCode||'french'))
    :QUESTIONS.find(q=>(q.subcategoryCode||q.competenceId)===skillId);
  const subject=subjectCode||matching?.subjectCode||'french';
  const subjectSelect=document.getElementById('diagnosticSubject');
  if(subjectSelect.querySelector(`option[value="${subject}"]`)){
    subjectSelect.value=subject;
    updateDiagnosticDomains();
  }
  if(matching){
    const domain=matching.domainCode||matching.domaine;
    const domainSelect=document.getElementById('diagnosticDomain');
    if(domainSelect.querySelector(`option[value="${domain}"]`)){
      domainSelect.value=domain;
      updateDiagnosticSkills();
    }
  }
  const skillSelect=document.getElementById('diagnosticSkill');
  if(skillSelect.querySelector(`option[value="${skillId}"]`)){
    skillSelect.value=skillId;
  }
  refreshDiagnosticSize();
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
  const selectedSubject=document.getElementById('diagnosticSubject').value;
  plannedMinutes=selectedDuration();
  const questionLimit=plannedMinutes*APPROXIMATE_QUESTIONS_PER_MINUTE;
  remoteSessionId=null;
  remoteDiagnosticId=null;
  remoteSequenceOffset=0;
  if(CapCollegeSupabase.configured()){
    try{
      const remote=await CapCollegeSupabase.startDiagnostic(
        plannedMinutes,
        selectedSkill,
        VALIDATION_CAMPAIGN_ID,
        selectedSubject
      );
      remoteSessionId=remote.session_id;
      remoteDiagnosticId=remote.diagnostic_id;
    }catch(error){
      const reason=String(error?.message||error||'Erreur inconnue');
      console.error('Démarrage du diagnostic refusé :',error);
      alert(`Le diagnostic en ligne n’a pas pu démarrer.\n\nDétail : ${reason}`);
      return;
    }
  }
  if(LEARNER_PROFILE&&!VALIDATION_CAMPAIGN_ID){
    try{
      cumulativeDiagnosticProgress=
        await CapCollegeSupabase.getDiagnosticProgress();
    }catch(error){
      console.warn('Progression cumulée indisponible.',error);
    }
  }
  diagnosticQuestions=buildBalancedDiagnostic(selectedSkill,questionLimit);
  if(!diagnosticQuestions.length){
    alert('Toutes les compétences de ce périmètre sont déjà suffisamment évaluées.');
    return;
  }
  current=0;
  answers=Array(diagnosticQuestions.length).fill(null);
  answerResults=Array(diagnosticQuestions.length).fill(null);
  answerFeedback=Array(diagnosticQuestions.length).fill(null);
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
        ?await CapCollegeSupabase.getActiveDiagnosticSession(VALIDATION_CAMPAIGN_ID):null);
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
    restoreDiagnosticSelection(remoteSkill);
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
    restoreDiagnosticSelection(restoredSkill,data.selectedSubject||null);
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
    selectedSubject:document.getElementById('diagnosticSubject').value,
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
  document.getElementById('skillBadge').textContent=`Sous-catégorie : ${q.subcategory||q.competence}`;

  const tense=document.getElementById('tenseBadge');
  tense.textContent='';
  tense.classList.add('hidden');
  CapCollegeQuestionVisuals.render(
    document.getElementById('questionText'),
    document.getElementById('questionVisual'),
    q.question
  );

  document.getElementById('prevBtn').disabled=current===0;
  document.getElementById('nextBtn').textContent=current===diagnosticQuestions.length-1?'Terminer la séance':'Suivante';
  closeQuestionFlagPanel();
  renderChoices();
}

function openQuestionFlagPanel(){
  document.getElementById('questionFlagComment').value='';
  document.getElementById('questionFlagStatus').textContent='';
  document.getElementById('questionFlagPanel').classList.remove('hidden');
  document.getElementById('questionFlagComment').focus();
}

function closeQuestionFlagPanel(){
  document.getElementById('questionFlagPanel').classList.add('hidden');
  document.getElementById('questionFlagStatus').textContent='';
}

async function saveQuestionFlag(){
  const question=diagnosticQuestions[current];
  const button=document.getElementById('saveQuestionFlagBtn');
  const status=document.getElementById('questionFlagStatus');
  button.disabled=true;
  status.textContent='Enregistrement…';
  try{
    await CapCollegeSupabase.flagQuestion(
      question.questionId,
      question.questionVersionId,
      VALIDATION_CAMPAIGN_ID,
      document.getElementById('questionFlagComment').value
    );
    status.textContent='Question signalée. Tu peux poursuivre le diagnostic.';
    setTimeout(closeQuestionFlagPanel,900);
  }catch(error){
    status.textContent=`Le signalement n’a pas été enregistré : ${error.message||error}`;
  }finally{
    button.disabled=false;
  }
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
  let authoritativeProgress=cumulativeDiagnosticProgress;
  if(remoteSessionId){
    try{
      await CapCollegeSupabase.finishDiagnostic(remoteSessionId);
      if(LEARNER_PROFILE&&!VALIDATION_CAMPAIGN_ID){
        authoritativeProgress=await CapCollegeSupabase.getDiagnosticProgress();
        cumulativeDiagnosticProgress=authoritativeProgress;
      }
    }catch(error){
      console.warn('La séance distante n’a pas pu être clôturée.',error);
    }
  }
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
    diagnosticProgress:authoritativeProgress,
    diagnosisReady:Boolean(authoritativeProgress?.diagnosisReady),
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
  if(!VALIDATION_CAMPAIGN_ID&&!LEARNER_PROFILE){
    localStorage.setItem('capCollegeV41Result',JSON.stringify(result));
    localStorage.setItem('capCollegeV4Result',JSON.stringify(result));
  }
  localStorage.removeItem(STORAGE_PROGRESS);
  localStorage.removeItem(STORAGE_PROGRESS_BACKUP);
  window.location.href=VALIDATION_CAMPAIGN_ID
    ?`resultats.html?validationCampaign=${encodeURIComponent(VALIDATION_CAMPAIGN_ID)}`
    :LEARNER_PROFILE?'resultats.html?mode=child':'resultats.html';
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

async function refreshOverallDiagnosticProgress(){
  const target=document.getElementById('diagnosticOverallProgress');
  if(!target||!LEARNER_PROFILE||VALIDATION_CAMPAIGN_ID)return;
  try{
    cumulativeDiagnosticProgress=
      await CapCollegeSupabase.getDiagnosticProgress();
    if(!cumulativeDiagnosticProgress?.hasDiagnostic)return;
    const progress=cumulativeDiagnosticProgress;
    target.textContent=progress.diagnosisReady
      ?'Diagnostic terminé : le bilan final est disponible.'
      :'Diagnostic en cours : '+progress.progressPercent+' % · '+
        progress.assessedSkills+'/'+progress.totalSkills+
        ' compétences suffisamment évaluées · au moins '+
        progress.questionsRemaining+' question'+
        (progress.questionsRemaining>1?'s':'')+' restante'+
        (progress.questionsRemaining>1?'s':'')+'.';
    target.classList.remove('hidden');
  }catch(error){
    console.warn('Progression globale indisponible.',error);
  }
}

async function discoverRemoteResume(){
  const wantsImmediateResume=new URLSearchParams(location.search).get('resume')==='1';
  if(!CapCollegeSupabase.configured()){
    if(wantsImmediateResume&&readSavedProgress())await resumeTest();
    return;
  }
  try{
    discoveredRemoteSession=await CapCollegeSupabase.getActiveDiagnosticSession(
      VALIDATION_CAMPAIGN_ID
    );
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
refreshOverallDiagnosticProgress();
discoverRemoteResume();
