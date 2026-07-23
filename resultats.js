const STORAGE_RESULT=
  localStorage.getItem('capCollegeV43Result')?'capCollegeV43Result':
  localStorage.getItem('capCollegeV41Result')?'capCollegeV41Result':
  'capCollegeV4Result';

const raw=localStorage.getItem(STORAGE_RESULT);

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

function renderRecommendation(){
  const profile=Array.isArray(window.CAP_COLLEGE_SKILL_PROFILE)
    ?window.CAP_COLLEGE_SKILL_PROFILE:[];
  const target=document.getElementById('recommendation');
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

function render(r){
  const minimum=r.minimumAnswersPerSkill||3;
  const answeredTotal=r.total||0;
  const global=answeredTotal?Math.round(r.totalOk/answeredTotal*100):0;

  const arr=Object.entries(r.stats).map(([name,s])=>{
    const pending=s.pending===true || s.total<minimum;
    return {
      name,
      ...s,
      pending,
      p:pending?null:Math.round(s.ok/s.total*100)
    };
  });

  const evaluated=arr.filter(x=>!x.pending);
  const pending=arr.filter(x=>x.pending);
  const acquired=evaluated.filter(x=>x.p>=80).length;
  const weak=evaluated.filter(x=>x.p<80).sort((a,b)=>a.p-b.p);

  const partialText=r.stoppedEarly
    ? `Le test a été arrêté volontairement après <strong>${answeredTotal} réponse${answeredTotal>1?'s':''}</strong>. `
    : `Le diagnostic porte sur <strong>${answeredTotal} réponse${answeredTotal>1?'s':''}</strong>. `;

  document.getElementById('globalText').innerHTML=
    `${partialText}Score global sur les questions répondues : <strong>${global} %</strong>. `+
    `Le diagnostic général reste actif et continuera lors des prochaines séances.`;

  document.getElementById('summary').innerHTML=`
    <div class="summary-box"><div class="summary-value">${answeredTotal}</div><div class="small">réponses données</div></div>
    <div class="summary-box"><div class="summary-value">${r.totalOk}</div><div class="small">bonnes réponses</div></div>
    <div class="summary-box"><div class="summary-value">${answeredTotal-r.totalOk}</div><div class="small">erreurs à revoir</div></div>`;

  document.getElementById('priorities').innerHTML=weak.length
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
      if(x.pending){
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
  renderRecommendation();
  renderMistakes(r);
}
