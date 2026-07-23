const params=new URLSearchParams(location.search);
const competenceId=params.get('skill');
const plannedMinutes=Number(params.get('minutes'));
const questionTargets={5:6,10:10,20:20};

let sessionId=null;
let questions=[];
let currentIndex=0;
let assistedSuccesses=0;
let assistance='with_reminder';
let answered=false;
let correctAnswers=0;

function shuffle(items){
  const copy=[...items];
  for(let i=copy.length-1;i>0;i--){
    const j=Math.floor(Math.random()*(i+1));
    [copy[i],copy[j]]=[copy[j],copy[i]];
  }
  return copy;
}

function localLesson(skillName){
  return SKILL_LESSONS[skillName]||
    'Observe la règle, applique une seule étape, puis vérifie ton choix.';
}

function localExample(skillName){
  const example=QUESTIONS.find(question=>question.competence===skillName);
  if(!example)return 'Lis la règle puis applique-la directement à la question.';
  return `${example.question} → ${example.choix[example.reponse]}`;
}

function setAssistance(nextAssistance){
  assistance=nextAssistance;
  const lesson=document.getElementById('lessonPanel');
  const badge=document.getElementById('assistanceBadge');
  const message=document.getElementById('phaseMessage');
  if(assistance==='with_reminder'){
    lesson.classList.remove('hidden');
    badge.textContent='Avec le rappel';
    message.textContent='Applique simplement la règle affichée. Tu n’as rien à mémoriser tout de suite.';
  }else{
    lesson.classList.add('hidden');
    badge.textContent='Sans le rappel';
    message.textContent='Le rappel est masqué. Retrouve maintenant le même geste tout seul.';
  }
}

function renderQuestion(){
  const question=questions[currentIndex];
  answered=false;
  document.getElementById('remediationCounter').textContent=
    `Exercice ${currentIndex+1}`;
  document.getElementById('remediationQuestion').textContent=question.question;
  document.getElementById('remediationFeedback').classList.add('hidden');
  document.getElementById('nextRemediationButton').classList.add('hidden');
  document.getElementById('remediationChoices').innerHTML=question.choix
    .map((choice,index)=>`
      <button class="choice remediation-choice" type="button" data-choice="${index}">
        ${escapeHtml(choice)}
      </button>`)
    .join('');
  document.querySelectorAll('.remediation-choice').forEach(button=>{
    button.addEventListener('click',()=>answerQuestion(Number(button.dataset.choice)));
  });
}

function escapeHtml(value){
  return String(value??'')
    .replaceAll('&','&amp;')
    .replaceAll('<','&lt;')
    .replaceAll('>','&gt;')
    .replaceAll('"','&quot;')
    .replaceAll("'",'&#039;');
}

async function answerQuestion(choiceIndex){
  if(answered)return;
  const question=questions[currentIndex];
  document.querySelectorAll('.remediation-choice').forEach(button=>button.disabled=true);
  try{
    const result=await CapCollegeSupabase.submitRemediationAnswer(
      sessionId,
      question.questionVersionId,
      question.choiceIds[choiceIndex],
      assistance,
      currentIndex+1
    );
    answered=true;
    const correctIndex=question.choiceIds.indexOf(result.correct_choice_id);
    document.querySelectorAll('.remediation-choice').forEach((button,index)=>{
      if(index===correctIndex)button.classList.add('correct-choice');
      if(index===choiceIndex&&!result.is_correct)button.classList.add('incorrect-choice');
    });

    const feedback=document.getElementById('remediationFeedback');
    if(result.is_correct){
      correctAnswers++;
      if(assistance==='with_reminder')assistedSuccesses++;
      feedback.textContent='Oui, c’est exactement le bon geste.';
      feedback.className='notice success-notice';
    }else{
      feedback.textContent=`On remet le rappel pour reconstruire le geste. Bonne réponse : ${question.choix[correctIndex]}`;
      feedback.className='notice error-notice';
      assistedSuccesses=0;
      setAssistance('with_reminder');
    }
    feedback.classList.remove('hidden');
    document.getElementById('nextRemediationButton').classList.remove('hidden');
  }catch(error){
    document.querySelectorAll('.remediation-choice').forEach(button=>button.disabled=false);
    alert('La réponse n’a pas pu être enregistrée. Réessaie dans un instant.');
  }
}

async function nextQuestion(){
  if(!answered)return;
  if(assistance==='with_reminder'&&assistedSuccesses>=3){
    setAssistance('without_reminder');
  }
  currentIndex++;
  if(currentIndex>=questions.length){
    await finishSession();
    return;
  }
  renderQuestion();
  window.scrollTo(0,0);
}

async function finishSession(){
  try{
    await CapCollegeSupabase.finishRemediation(sessionId);
  }catch(error){
    console.warn('La séance de remédiation n’a pas pu être clôturée.',error);
  }
  document.getElementById('remediationSession').classList.add('hidden');
  document.getElementById('remediationComplete').classList.remove('hidden');
  document.getElementById('remediationSummary').textContent=
    `${correctAnswers} réussite${correctAnswers>1?'s':''} sur ${currentIndex+(answered?1:0)} exercice${currentIndex+(answered?1:0)>1?'s':''}. Le diagnostic conservera cette séance pour la suite.`;
  window.scrollTo(0,0);
}

async function initialise(){
  if(!competenceId||!questionTargets[plannedMinutes]){
    throw new Error('La compétence ou la durée de travail est manquante.');
  }
  await CapCollegeSupabase.bootstrap({requireAuth:true});
  const [session,bank]=await Promise.all([
    CapCollegeSupabase.startRemediation(competenceId,plannedMinutes),
    CapCollegeSupabase.getRemediationQuestions(competenceId)
  ]);
  if(!session||!bank.length)throw new Error('Aucun exercice disponible pour cette compétence.');

  sessionId=session.session_id;
  questions=shuffle(bank).slice(0,Math.min(questionTargets[plannedMinutes],bank.length));
  document.getElementById('remediationTitle').textContent=session.competence;
  document.getElementById('remediationDuration').textContent=`Séance choisie : ${plannedMinutes} min`;
  document.getElementById('lessonReminder').textContent=
    session.reminder||localLesson(session.competence);
  document.getElementById('workedExample').textContent=
    session.worked_example||localExample(session.competence);
  document.getElementById('remediationLoading').classList.add('hidden');
  document.getElementById('remediationSession').classList.remove('hidden');
  setAssistance('with_reminder');
  renderQuestion();
}

document.getElementById('nextRemediationButton').addEventListener('click',nextQuestion);
document.getElementById('stopRemediationButton').addEventListener('click',finishSession);
initialise().catch(CapCollegeSupabase.showFatalError);
