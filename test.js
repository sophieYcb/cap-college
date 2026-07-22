const REVIEW_KEY='capCollegeV50aReviews';
const APP_VERSION='6.0';
let reviews=loadReviews();
let filteredQuestions=[...QUESTIONS];
let currentIndex=0;

function loadReviews(){try{return JSON.parse(localStorage.getItem(REVIEW_KEY))||{};}catch(e){return {};}}
function persist(){localStorage.setItem(REVIEW_KEY,JSON.stringify(reviews));renderSummary();renderDashboard();}
function currentQuestion(){return filteredQuestions[currentIndex];}
function reviewFor(id){return reviews[String(id)]||{};}
function isCurrentReview(q,r=reviewFor(q.id)){
 return Boolean(r.rating)&&Number(r.questionVersion||1)===Number(q.version||1);
}

function initialise(){
 const skills=[...new Set(QUESTIONS.map(q=>q.competence))].sort((a,b)=>a.localeCompare(b,'fr'));
 document.getElementById('skillFilter').innerHTML+=""+skills.map(s=>`<option value="${escapeHtml(s)}">${escapeHtml(s)}</option>`).join('');
 const versions=[...new Set(QUESTIONS.map(q=>q.version||1))].sort((a,b)=>a-b);
 document.getElementById('versionFilter').innerHTML+=versions.map(v=>`<option value="${v}">Version ${v}</option>`).join('');
 applyFilters();
}
function escapeHtml(v){return String(v).replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));}
function applyFilters(){
 const status=document.getElementById('statusFilter').value;
 const skill=document.getElementById('skillFilter').value;
 const version=document.getElementById('versionFilter').value;
 const sortOrder=document.getElementById('sortOrder').value;
 const search=document.getElementById('searchFilter').value.trim().toLowerCase();
 const currentId=currentQuestion()?.id;
 filteredQuestions=QUESTIONS.filter(q=>{
   const r=reviewFor(q.id);
   const currentRating=isCurrentReview(q,r)?r.rating:'';
   const statusOk=status==='all'||(status==='unreviewed'&&!currentRating)||currentRating===status;
   const skillOk=skill==='all'||q.competence===skill;
   const versionOk=version==='all'||String(q.version||1)===version;
   const searchOk=!search||String(q.id)===search||q.question.toLowerCase().includes(search)||q.competence.toLowerCase().includes(search);
   return statusOk&&skillOk&&versionOk&&searchOk;
 });
 filteredQuestions.sort((a,b)=>{
   if(sortOrder==='version-desc') return (b.version||1)-(a.version||1)||a.id-b.id;
   if(sortOrder==='version-asc') return (a.version||1)-(b.version||1)||a.id-b.id;
   return a.id-b.id;
 });
 currentIndex=Math.max(0,filteredQuestions.findIndex(q=>q.id===currentId));
 if(currentIndex<0)currentIndex=0;
 renderQuestion();renderSummary();renderDashboard();
}
function renderQuestion(){
 const q=currentQuestion();
 const reviewPanel=document.querySelector('.review-panel');
 const navigation=document.querySelector('.quality-nav');
 if(!q){
  document.getElementById('testCounter').textContent='Aucune question';
  document.getElementById('questionIdentity').textContent='';
  document.getElementById('testProgress').style.width='0%';
  document.getElementById('testDomain').textContent='';
  document.getElementById('testSkill').textContent='';
  document.getElementById('testVersion').textContent='';
  document.getElementById('testQuestion').textContent='Aucune question ne correspond aux filtres.';
  document.getElementById('testChoices').innerHTML='';
  reviewPanel.hidden=true;
  navigation.hidden=true;
  return;
 }
 reviewPanel.hidden=false;
 navigation.hidden=false;
 const r=reviewFor(q.id);
 const currentReview=isCurrentReview(q,r);
 const staleReview=Boolean(r.rating)&&!currentReview;
 document.getElementById('testCounter').textContent=`Question ${currentIndex+1} / ${filteredQuestions.length}`;
 document.getElementById('questionIdentity').textContent=`ID permanent Q${q.id}`;
 document.getElementById('testProgress').style.width=`${((currentIndex+1)/filteredQuestions.length)*100}%`;
 document.getElementById('testDomain').textContent=q.domaine;
 document.getElementById('testSkill').textContent=q.competence;
 document.getElementById('testVersion').textContent=`Version ${q.version||1}`;
 document.getElementById('testQuestion').textContent=q.question;
 document.getElementById('testChoices').innerHTML=q.choix.map((c,i)=>`<div class="choice test-choice ${i===q.reponse?'correct-choice':''}"><span>${String.fromCharCode(65+i)}.</span> ${escapeHtml(c)} ${i===q.reponse?'<strong class="correct-marker">✓ réponse prévue</strong>':''}</div>`).join('');
 document.querySelectorAll('.rating').forEach(b=>b.classList.toggle('active',currentReview&&b.dataset.rating===r.rating));
 document.getElementById('reviewComment').value=r.comment||'';
 const staleNotice=document.getElementById('staleReviewNotice');
 staleNotice.classList.toggle('hidden',!staleReview);
 staleNotice.textContent=staleReview
  ?`Question modifiée : l'ancienne validation ${r.rating} (version ${r.questionVersion||1}) est conservée dans l'historique. Cette version doit être retestée.`
  :'';
 window.scrollTo({top:0,behavior:'smooth'});
}
function setRating(rating){
 const q=currentQuestion();if(!q)return;
 const old=reviewFor(q.id);
 const history=Array.isArray(old.history)?[...old.history]:[];
 if(old.rating&&!isCurrentReview(q,old)){
  const alreadySaved=history.some(item=>Number(item.questionVersion||1)===Number(old.questionVersion||1)&&item.rating===old.rating&&item.updatedAt===old.updatedAt);
  if(!alreadySaved)history.push({rating:old.rating,comment:old.comment||'',updatedAt:old.updatedAt||'',questionVersion:old.questionVersion||1});
 }
 reviews[String(q.id)]={...old,history,rating,updatedAt:new Date().toISOString(),questionVersion:q.version||1};
 persist();renderQuestion();
}
function saveComment(){
 const q=currentQuestion();if(!q)return;
 const comment=document.getElementById('reviewComment').value;
 const old=reviewFor(q.id);
 reviews[String(q.id)]={...old,comment,updatedAt:new Date().toISOString(),questionVersion:old.questionVersion||q.version||1};
 persist();
}
function nextTestQuestion(){if(currentIndex<filteredQuestions.length-1){currentIndex++;renderQuestion();}}
function previousTestQuestion(){if(currentIndex>0){currentIndex--;renderQuestion();}}
function renderSummary(){
 const counts={A:0,B:0,C:0,D:0};let tested=0;
 QUESTIONS.forEach(q=>{const r=reviewFor(q.id);if(isCurrentReview(q,r)){tested++;counts[r.rating]=(counts[r.rating]||0)+1;}});
 document.getElementById('qualitySummary').innerHTML=`
 <div class="summary-box"><div class="summary-value">${tested} / ${QUESTIONS.length}</div><div class="small">questions testées</div></div>
 <div class="summary-box"><div class="summary-value">${counts.A}</div><div class="small">A — excellentes</div></div>
 <div class="summary-box"><div class="summary-value">${counts.B}</div><div class="small">B — à améliorer</div></div>
 <div class="summary-box"><div class="summary-value">${counts.C}</div><div class="small">C — à réécrire</div></div>
 <div class="summary-box"><div class="summary-value">${counts.D}</div><div class="small">D — à supprimer</div></div>`;
}
function renderDashboard(){
 const groups={};QUESTIONS.forEach(q=>{if(!groups[q.competence])groups[q.competence]={total:0,tested:0,A:0,B:0,C:0,D:0};const g=groups[q.competence];g.total++;const r=reviewFor(q.id);if(isCurrentReview(q,r)){g.tested++;g[r.rating]++;}});
 document.getElementById('skillDashboard').innerHTML=Object.entries(groups).map(([name,g])=>`<div class="skill-quality"><div><strong>${escapeHtml(name)}</strong><span>${g.tested}/${g.total} testées</span></div><div class="mini-counts"><span>A ${g.A}</span><span>B ${g.B}</span><span>C ${g.C}</span><span>D ${g.D}</span></div><div class="meter"><span style="width:${g.tested/g.total*100}%"></span></div></div>`).join('');
}
function exportRows(){
 return QUESTIONS.filter(q=>{const r=reviewFor(q.id);return r.rating||r.comment;}).map(q=>{
  const r=reviewFor(q.id);return {applicationVersion:APP_VERSION,questionId:q.id,questionVersion:q.version||1,domaine:q.domaine,competenceId:q.competenceId,competence:q.competence,difficulte:q.difficulte,question:q.question,choix:q.choix,reponseIndex:q.reponse,reponseTexte:q.choix[q.reponse],note:isCurrentReview(q,r)?r.rating||'':'',statutValidation:isCurrentReview(q,r)?'validée':(r.rating?'à retester':'non testée'),ancienneNote:!isCurrentReview(q,r)&&r.rating?r.rating:'',ancienneVersion:!isCurrentReview(q,r)&&r.rating?r.questionVersion||1:'',commentaire:r.comment||'',dateModification:r.updatedAt||'',historique:r.history||[]};
 });
}
function download(content,type,name){const blob=new Blob([content],{type});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=name;document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);}
function exportJSON(){const payload={format:'cap-college-quality-review',applicationVersion:APP_VERSION,exportedAt:new Date().toISOString(),questionBankSize:QUESTIONS.length,reviews:exportRows()};download(JSON.stringify(payload,null,2),'application/json;charset=utf-8',`cap-college-retours-${new Date().toISOString().slice(0,10)}.json`);setExportStatus('Export JSON téléchargé.');}
function csvCell(v){const s=Array.isArray(v)?v.join(' | '):String(v??'');return '"'+s.replace(/"/g,'""')+'"';}
function exportCSV(){const rows=exportRows();const headers=['applicationVersion','questionId','questionVersion','domaine','competenceId','competence','difficulte','question','choix','reponseIndex','reponseTexte','note','statutValidation','ancienneNote','ancienneVersion','commentaire','dateModification'];const csv='\ufeff'+[headers.map(csvCell).join(';'),...rows.map(r=>headers.map(h=>csvCell(r[h])).join(';'))].join('\r\n');download(csv,'text/csv;charset=utf-8',`cap-college-retours-${new Date().toISOString().slice(0,10)}.csv`);setExportStatus('Export CSV téléchargé.');}
async function importJSONFile(event){
 const file=event.target.files&&event.target.files[0];
 if(!file)return;
 try{
  const payload=JSON.parse(await file.text());
  if(!payload||!Array.isArray(payload.reviews))throw new Error('Format invalide');
  const imported={};
  payload.reviews.forEach(row=>{
   if(!row||!Number.isFinite(Number(row.questionId)))return;
   imported[String(Number(row.questionId))]={
    rating:['A','B','C','D'].includes(row.note)?row.note:'',
    comment:row.commentaire||'',
    updatedAt:row.dateModification||new Date().toISOString(),
    questionVersion:Number(row.questionVersion)||1
   };
  });
  reviews={...reviews,...imported};
  persist();applyFilters();
  setExportStatus(`${Object.keys(imported).length} annotation${Object.keys(imported).length>1?'s':''} importée${Object.keys(imported).length>1?'s':''}.`);
 }catch(error){
  setExportStatus('Import impossible : ce fichier JSON n’est pas reconnu.');
 }finally{
  event.target.value='';
 }
}
function resetReviews(){if(confirm('Effacer définitivement toutes les notes et tous les commentaires enregistrés sur cet appareil ?')){reviews={};persist();applyFilters();}}

function setExportStatus(message){
 const el=document.getElementById('exportStatus');
 if(!el)return;
 el.textContent=message;
 clearTimeout(setExportStatus.timer);
 setExportStatus.timer=setTimeout(()=>{el.textContent='';},4500);
}

async function copyReviews(){
 const rows=exportRows();
 if(!rows.length){setExportStatus('Aucun retour à copier.');return;}
 const lines=rows.map(r=>[
  `Q${r.questionId} — ${r.competence} — note ${r.note||'sans note'}`,
  `Question : ${r.question}`,
  `Choix : ${Array.isArray(r.choix)?r.choix.join(' | '):r.choix}`,
  `Réponse prévue : ${r.reponseTexte}`,
  `Commentaire : ${r.commentaire||'—'}`
 ].join('\n')).join('\n\n------------------------------\n\n');
 try{
  await navigator.clipboard.writeText(lines);
  setExportStatus(`${rows.length} retour${rows.length>1?'s':''} copié${rows.length>1?'s':''} dans le presse-papiers.`);
 }catch(e){
  const area=document.createElement('textarea');
  area.value=lines;area.style.position='fixed';area.style.opacity='0';document.body.appendChild(area);area.select();
  const ok=document.execCommand('copy');area.remove();
  setExportStatus(ok?'Retours copiés dans le presse-papiers.':'Copie impossible sur ce navigateur. Utilise JSON, CSV ou HTML.');
 }
}

function exportHTMLReport(){
 const rows=exportRows();
 if(!rows.length){setExportStatus('Aucun retour à inclure dans le rapport.');return;}
 const esc=v=>escapeHtml(v??'');
 const cards=rows.map(r=>`<article class="item"><div class="head"><strong>Q${r.questionId} — ${esc(r.competence)}</strong><span class="grade grade-${esc(r.note||'N')}">${esc(r.note||'Sans note')}</span></div><p><b>Question :</b> ${esc(r.question)}</p><ol type="A">${r.choix.map(c=>`<li>${esc(c)}</li>`).join('')}</ol><p><b>Réponse prévue :</b> ${esc(r.reponseTexte)}</p><p><b>Commentaire :</b> ${esc(r.commentaire||'—')}</p><p class="meta">${esc(r.domaine)} · difficulté ${esc(r.difficulte)} · version Q${esc(r.questionVersion)}</p></article>`).join('');
 const html=`<!DOCTYPE html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Retours Cap Collège</title><style>body{font-family:Arial,sans-serif;max-width:980px;margin:24px auto;padding:0 16px;color:#1f2937}h1{margin-bottom:4px}.item{border:1px solid #d7dce4;border-radius:12px;padding:16px;margin:14px 0}.head{display:flex;justify-content:space-between;gap:12px}.grade{font-weight:700;border-radius:999px;padding:4px 10px;background:#e5e7eb}.grade-A{background:#dcfce7}.grade-B{background:#fef3c7}.grade-C{background:#ffedd5}.grade-D{background:#fee2e2}.meta{color:#667085;font-size:.88rem}li{margin:4px 0}@media print{body{margin:0}.item{break-inside:avoid}}</style></head><body><h1>Retours pédagogiques Cap Collège</h1><p>Export du ${new Date().toLocaleString('fr-FR')} — ${rows.length} question${rows.length>1?'s':''} annotée${rows.length>1?'s':''}</p>${cards}</body></html>`;
 download(html,'text/html;charset=utf-8',`cap-college-rapport-${new Date().toISOString().slice(0,10)}.html`);
 setExportStatus('Rapport HTML téléchargé.');
}

initialise();
