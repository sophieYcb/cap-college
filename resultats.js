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
    `Un thème est évalué à partir de ${minimum} réponses ; sinon il reste en attente.`;

  document.getElementById('summary').innerHTML=`
    <div class="summary-box"><div class="summary-value">${global} %</div><div class="small">score sur les réponses données</div></div>
    <div class="summary-box"><div class="summary-value">${evaluated.length}</div><div class="small">thèmes évalués</div></div>
    <div class="summary-box"><div class="summary-value">${pending.length}</div><div class="small">thèmes en attente</div></div>`;

  document.getElementById('priorities').innerHTML=weak.length
    ? weak.slice(0,8).map((x,i)=>`<div class="priority"><strong>${i+1}. ${x.name}</strong><br><span class="small">${x.domain} — ${x.p} % (${x.total} réponses)</span></div>`).join('')
    : evaluated.length
      ? '<p>Tous les thèmes suffisamment évalués atteignent le seuil de maîtrise.</p>'
      : '<div class="notice">Aucun thème ne dispose encore d’assez de réponses pour être évalué.</div>';

  let html='';
  ['Grammaire','Conjugaison','Orthographe','Vocabulaire'].forEach(domain=>{
    const items=arr.filter(x=>x.domain===domain);
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
}
