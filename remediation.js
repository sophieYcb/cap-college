const STORAGE_RESULT=
  localStorage.getItem('capCollegeV43Result')?'capCollegeV43Result':
  localStorage.getItem('capCollegeV41Result')?'capCollegeV41Result':
  'capCollegeV4Result';

const raw=localStorage.getItem(STORAGE_RESULT);
const target=document.getElementById('remediationList');

if(!raw){
  target.innerHTML='<div class="notice">Aucun diagnostic enregistré. Commence par réaliser l’évaluation.</div><div class="actions"><a class="btn btn-primary" href="evaluation.html">Commencer le diagnostic</a></div>';
}else{
  const r=JSON.parse(raw);
  const minimum=r.minimumAnswersPerSkill||3;

  const arr=Object.entries(r.stats)
    .map(([name,s])=>({
      name,
      ...s,
      pending:s.pending===true || s.total<minimum,
      p:s.total?Math.round(s.ok/s.total*100):0
    }))
    .filter(x=>!x.pending && x.p<80)
    .sort((a,b)=>a.p-b.p);

  const pendingCount=Object.values(r.stats)
    .filter(s=>s.pending===true || s.total<minimum).length;

  if(!arr.length){
    target.innerHTML=
      '<div class="notice">Aucune compétence suffisamment évaluée ne nécessite actuellement de remise à niveau.</div>'+
      (pendingCount?`<p class="small">${pendingCount} thème${pendingCount>1?'s sont':' est'} encore en attente d’évaluation.</p>`:'');
  }else{
    target.innerHTML=arr.map((x,i)=>`
      <article class="result">
        <div class="result-head"><span>${i+1}. ${x.name}</span><span>${x.p} %</span></div>
        <p><strong>Rappel :</strong> ${SKILL_LESSONS[x.name]||'Revoir la règle et refaire des exercices ciblés.'}</p>
        <p class="small">Domaine : ${x.domain} — ${x.total} réponses prises en compte</p>
      </article>`).join('');
  }
}
