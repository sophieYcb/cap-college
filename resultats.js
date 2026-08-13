const RESULT_LEARNER_PROFILE=CapCollegeSupabase.getLearnerProfile();
const VALIDATION_RESULT_SUFFIX=window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID
  ?':validation:'+window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID
  :RESULT_LEARNER_PROFILE?':learner:'+RESULT_LEARNER_PROFILE.id:'';
const VALIDATION_RESULT_KEY=`capCollegeV43Result${VALIDATION_RESULT_SUFFIX}`;
const STORAGE_RESULT=RESULT_LEARNER_PROFILE
  ?VALIDATION_RESULT_KEY
  :localStorage.getItem(VALIDATION_RESULT_KEY)?VALIDATION_RESULT_KEY:
    localStorage.getItem('capCollegeV43Result')?'capCollegeV43Result':
    localStorage.getItem('capCollegeV41Result')?'capCollegeV41Result':
    'capCollegeV4Result';

const raw=localStorage.getItem(STORAGE_RESULT);

if(window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID){
  const restartLink=document.querySelector('a[href="evaluation.html"]');
  if(restartLink){
    restartLink.href=`evaluation.html?validationCampaign=${encodeURIComponent(window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID)}`;
    restartLink.textContent='Nouvelle séance dans cette campagne';
  }
}else if(RESULT_LEARNER_PROFILE){
  const restartLink=document.querySelector('a[href="evaluation.html"]');
  if(restartLink)restartLink.href='evaluation.html?mode=child';
}

if(!raw){
  document.getElementById('globalText').innerHTML='Aucun résultat enregistré. <a href="evaluation.html"><strong>Commencer le diagnostic</strong></a>.';
  document.getElementById('summary').innerHTML='';
  document.getElementById('priorities').innerHTML='';
  document.getElementById('skillsResults').innerHTML='';
}else{
  render(JSON.parse(raw));
}

function status(p){
  return p>=80?['Acquis','green']:p>=50?['À consolider','orange']:['Non acquis','red'];
}

function escapeHtml(value){
  return String(value??'')
    .replaceAll('&','&amp;')
    .replaceAll('<','&lt;')
    .replaceAll('>','&gt;')
    .replaceAll('"','&quot;')
    .replaceAll("'",'&#039;');
}

function renderMistakes(r){
  const mistakes=(r.reviewItems||[]).filter(item=>!item.isCorrect);
  const section=document.getElementById('mistakesSection');
  const count=document.getElementById('mistakesCount');
  const list=document.getElementById('mistakesList');

  count.textContent=`${mistakes.length} erreur${mistakes.length>1?'s':''}`;
  if(!mistakes.length){
    list.innerHTML='<p>Aucune erreur dans cette séance. Bravo !</p>';
    return;
  }

  list.innerHTML=mistakes.map((item,index)=>`
    <article class="mistake-card">
      <div class="mistake-heading">
        <strong>${index+1}. ${escapeHtml(item.skill)}</strong>
        <span class="small">${escapeHtml(item.domain)}</span>
      </div>
      <p class="mistake-question">${escapeHtml(item.prompt)}</p>
      <div class="answer-review wrong-answer">
        <span>Ta réponse</span>
        <strong>${escapeHtml(item.selectedAnswer)}</strong>
      </div>
      <div class="answer-review right-answer">
        <span>Bonne réponse</span>
        <strong>${escapeHtml(item.correctAnswer)}</strong>
      </div>
      ${item.explanation?`
        <div class="correction-note">
          <strong>Explication</strong>
          <p>${escapeHtml(item.explanation)}</p>
        </div>`:''}
    </article>
  `).join('');
}

function renderRecommendation(diagnosticProgress=null){
  const profile=Array.isArray(window.CAP_COLLEGE_SKILL_PROFILE)
    ?window.CAP_COLLEGE_SKILL_PROFILE:[];
  const target=document.getElementById('recommendation');
  if(RESULT_LEARNER_PROFILE&&diagnosticProgress&&!diagnosticProgress.diagnosisReady){
    target.innerHTML='<div class="notice">Le diagnostic est encore en cours ('+
      diagnosticProgress.progressPercent+
      ' %). Aucune priorité définitive ne sera proposée avant que toutes les compétences soient suffisamment évaluées.</div>';
    return;
  }
  if(RESULT_LEARNER_PROFILE){
    const priorities=(diagnosticProgress?.skills||[])
      .filter(item=>item.sufficientEvidence&&Number(item.masteryScore)<80)
      .sort((a,b)=>Number(a.masteryScore)-Number(b.masteryScore));
    if(diagnosticProgress?.diagnosisReady&&priorities.length){
      target.innerHTML=`<article class="recommendation-card">
        <span class="small">Ton premier objectif</span>
        <h3>${escapeHtml(priorities[0].competence)}</h3>
        <p>Commence par cette compétence, puis avance sur les deux priorités suivantes. Deux petites séances de 20 questions par semaine suffisent pour progresser régulièrement.</p>
      </article>`;
    }else{
      target.innerHTML='<div class="notice">Bravo, aucune priorité importante ne ressort de ce diagnostic. Continue à t’entraîner régulièrement.</div>';
    }
    return;
  }
  if(window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID){
    target.innerHTML='<div class="notice">Campagne de validation : ces réponses sont isolées du profil réel.</div>';
    return;
  }
  const eligible=profile
    .filter(item=>item.sufficientEvidence && item.masteryScore<80)
    .sort((a,b)=>a.masteryScore-b.masteryScore||b.confidenceScore-a.confidenceScore);

  if(!eligible.length){
    const strongestEvidence=profile.reduce(
      (maximum,item)=>Math.max(maximum,item.evidenceCount||0),0
    );
    target.innerHTML=`
      <div class="notice">
        Le diagnostic continue à apprendre à te connaître.
        ${strongestEvidence
          ?`La compétence la plus explorée possède ${strongestEvidence} réponse${strongestEvidence>1?'s':''} sur les 5 nécessaires.`
          :'Réponds encore à quelques questions pour obtenir une recommandation fiable.'}
      </div>`;
    return;
  }

  const recommendation=eligible[0];
  const skillId=encodeURIComponent(recommendation.competenceId);
  target.innerHTML=`
    <article class="recommendation-card">
      <div>
        <span class="small">${escapeHtml(recommendation.domain)}</span>
        <h3>${escapeHtml(recommendation.competence)}</h3>
        <p>Cette compétence est actuellement la priorité la plus fiable :
          ${recommendation.evidenceCount} réponses prises en compte,
          niveau estimé à ${recommendation.masteryScore} %.
        </p>
      </div>
      <strong>Combien de temps veux-tu travailler ?</strong>
      <div class="training-duration-options">
        <a href="remediation.html?skill=${skillId}&minutes=5">5 min</a>
        <a href="remediation.html?skill=${skillId}&minutes=10">10 min</a>
        <a href="remediation.html?skill=${skillId}&minutes=20">20 min</a>
      </div>
    </article>`;
}

function finalSkillStatus(score){
  return score>=80?['Point fort','green']:
    score>=50?['À consolider','orange']:['Prioritaire','red'];
}

function renderFinalDiagnostic(r,diagnosticProgress){
  const skills=(diagnosticProgress.skills||[])
    .filter(item=>item.sufficientEvidence)
    .map(item=>({...item,masteryScore:Number(item.masteryScore)||0}));
  const strengths=skills.filter(item=>item.masteryScore>=80);
  const consolidating=skills.filter(item=>item.masteryScore>=50&&item.masteryScore<80);
  const priorities=skills
    .filter(item=>item.masteryScore<50)
    .sort((a,b)=>a.masteryScore-b.masteryScore);
  const subject=diagnosticProgress.subjectName||
    (diagnosticProgress.subjectCode==='mathematics'?'Mathématiques':'Français');

  document.querySelector('h1').textContent=`Bilan final — ${subject}`;
  const topBadge=document.querySelector('.topbar .badge');
  if(topBadge)topBadge.textContent='Diagnostic terminé';
  document.getElementById('globalText').innerHTML=
    `<strong>Bravo, ton diagnostic est terminé.</strong> Il s’appuie sur ${diagnosticProgress.answeredQuestions||0} réponses réparties sur ${diagnosticProgress.completedSessions||0} séances. Tu peux maintenant voir ce que tu maîtrises et ce que tu vas travailler en priorité.`;
  document.getElementById('summary').innerHTML=`
    <div class="summary-box"><div class="summary-value">${strengths.length}</div><div class="small">points forts</div></div>
    <div class="summary-box"><div class="summary-value">${consolidating.length}</div><div class="small">compétences à consolider</div></div>
    <div class="summary-box"><div class="summary-value">${priorities.length}</div><div class="small">priorités de travail</div></div>`;

  const orderedPriorities=[...priorities,...consolidating.sort((a,b)=>a.masteryScore-b.masteryScore)].slice(0,3);
  document.getElementById('priorities').innerHTML=orderedPriorities.length
    ?orderedPriorities.map((item,index)=>`<div class="priority"><strong>${index+1}. ${escapeHtml(item.competence)}</strong><br><span class="small">${escapeHtml(item.domain)} — à travailler en priorité</span></div>`).join('')
    :'<p>Tu as de très bonnes bases dans toutes les compétences évaluées.</p>';

  const domains=[...new Set(skills.map(item=>item.domain))];
  document.getElementById('skillsResults').innerHTML=domains.map(domain=>{
    const items=skills.filter(item=>item.domain===domain);
    return `<h3 class="domain-title">${escapeHtml(domain)}</h3>`+
      items.map(item=>{
        const [label,color]=finalSkillStatus(item.masteryScore);
        return `<div class="result">
          <div class="result-head"><span>${escapeHtml(item.competence)}</span><span class="tag ${color}">${label}</span></div>
          <div class="meter"><span class="${color}" style="width:${item.masteryScore}%"></span></div>
        </div>`;
      }).join('');
  }).join('');

  renderRecommendation(diagnosticProgress);
  renderMistakes(r);
}
function render(r){
  const minimum=r.minimumAnswersPerSkill||3;
  const answeredTotal=r.total||0;
  const global=answeredTotal?Math.round(r.totalOk/answeredTotal*100):0;
  const diagnosticProgress=r.diagnosticProgress||
    window.CAP_COLLEGE_DIAGNOSTIC_PROGRESS||null;
  const diagnosisReady=Boolean(diagnosticProgress?.diagnosisReady);

  if(RESULT_LEARNER_PROFILE&&diagnosisReady&&Array.isArray(diagnosticProgress.skills)){
    renderFinalDiagnostic(r,diagnosticProgress);
    return;
  }

  const arr=Object.entries(r.stats).map(([name,s])=>{
    const pending=s.pending===true || s.total<minimum;
    return {
      name,
      ...s,
      pending,
      p:pending?null:Math.round(s.ok/s.total*100)
    };
  });

  const evaluated=arr.filter(
    x=>!x.pending&&(!diagnosticProgress||diagnosisReady)
  );
  const pending=arr.filter(x=>x.pending);
  const acquired=evaluated.filter(x=>x.p>=80).length;
  const weak=evaluated.filter(x=>x.p<80).sort((a,b)=>a.p-b.p);

  const partialText=r.stoppedEarly
    ? `Le test a été arrêté volontairement après <strong>${answeredTotal} réponse${answeredTotal>1?'s':''}</strong>. `
    : `Le diagnostic porte sur <strong>${answeredTotal} réponse${answeredTotal>1?'s':''}</strong>. `;

  document.getElementById('globalText').innerHTML=diagnosticProgress
    ?diagnosisReady
      ?partialText+'<strong>Le diagnostic final est terminé.</strong> Toutes les compétences disposent de preuves suffisantes.'
      :partialText+'<strong>Diagnostic en cours : '+diagnosticProgress.progressPercent+
        ' %.</strong> '+diagnosticProgress.assessedSkills+'/'+
        diagnosticProgress.totalSkills+' compétences sont suffisamment évaluées. '+
        'Il reste au moins '+diagnosticProgress.questionsRemaining+
        ' question'+(diagnosticProgress.questionsRemaining>1?'s':'')+
        '. Aucun niveau définitif n’est encore établi.'
    :partialText+'Score global sur les questions répondues : <strong>'+
      global+' %</strong>. Le diagnostic général reste actif.';

  document.getElementById('summary').innerHTML=`
    <div class="summary-box"><div class="summary-value">${answeredTotal}</div><div class="small">réponses données</div></div>
    <div class="summary-box"><div class="summary-value">${r.totalOk}</div><div class="small">bonnes réponses</div></div>
    <div class="summary-box"><div class="summary-value">${answeredTotal-r.totalOk}</div><div class="small">erreurs à revoir</div></div>`;

  document.getElementById('priorities').innerHTML=
    diagnosticProgress&&!diagnosisReady
    ?'<div class="notice">Les priorités seront calculées lorsque le diagnostic sera terminé.</div>'
    :weak.length
    ? weak.slice(0,8).map((x,i)=>`<div class="priority"><strong>${i+1}. ${x.name}</strong><br><span class="small">${x.domain} — ${x.p} % (${x.total} réponses)</span></div>`).join('')
    : evaluated.length
      ? '<p>Tous les thèmes suffisamment évalués atteignent le seuil de maîtrise.</p>'
      : '<div class="notice">Aucun thème ne dispose encore d’assez de réponses pour être évalué.</div>';

  let html='';
  ['Grammaire','Conjugaison','Orthographe','Vocabulaire'].forEach(domain=>{
    const items=arr.filter(x=>x.domain===domain&&x.total>0);
    if(!items.length)return;
    html+=`<h3 class="domain-title">${domain}</h3>`;
    html+=items.map(x=>{
      if(x.pending||(diagnosticProgress&&!diagnosisReady)){
        return `<div class="result pending-result">
          <div class="result-head">
            <span>${x.name}</span>
            <span class="tag pending-tag">En attente d’évaluation</span>
          </div>
          <p class="small">${x.total} réponse${x.total>1?'s':''} sur ${minimum} minimum.</p>
          <div class="meter"><span class="pending-meter" style="width:${Math.min(100,(x.total/minimum)*100)}%"></span></div>
        </div>`;
      }

      const [label,color]=status(x.p);
      return `<div class="result">
        <div class="result-head"><span>${x.name}</span><span class="tag ${color}">${x.p} % — ${label}</span></div>
        <p class="small">${x.ok} bonne${x.ok>1?'s':''} réponse${x.ok>1?'s':''} sur ${x.total}</p>
        <div class="meter"><span class="${color}" style="width:${x.p}%"></span></div>
      </div>`;
    }).join('');
  });

  document.getElementById('skillsResults').innerHTML=html;
  renderRecommendation(diagnosticProgress);
  renderMistakes(r);
}
