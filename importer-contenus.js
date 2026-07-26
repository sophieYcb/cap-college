let pendingContentPayload=null;

function escapeContent(value){
 return String(value).replace(/[&<>'"]/g,character=>({
  '&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'
 }[character]));
}

async function previewContentLot(event){
 const preview=document.getElementById('contentPreview');
 const button=document.getElementById('importContentButton');
 const status=document.getElementById('contentImportStatus');
 pendingContentPayload=null;
 button.disabled=true;
 status.textContent='';
 try{
  const file=event.target.files?.[0];
  if(!file)throw new Error('Aucun fichier sélectionné.');
  const payload=JSON.parse(await file.text());
  if(payload.format!=='cap-college-question-draft-v1'){
   throw new Error('Ce fichier n’est pas un lot Cap Collège reconnu.');
  }
  const questions=Array.isArray(payload.questions)?payload.questions:[];
  const microSkills=Array.isArray(payload.microSkills)?payload.microSkills:[];
  if(!questions.length||!microSkills.length){
   throw new Error('Le fichier ne contient pas de questions exploitables.');
  }
  pendingContentPayload=payload;
  preview.innerHTML=`
   <strong>${escapeContent(payload.lot||'Lot sans nom')}</strong>
   <p>${escapeContent(payload.subject)} · ${escapeContent(payload.level)}</p>
   <p>${microSkills.length} micro-compétence${microSkills.length>1?'s':''} · ${questions.length} question${questions.length>1?'s':''}</p>
   <p>Statut après import : <strong>à valider</strong></p>`;
  preview.classList.remove('hidden');
  button.disabled=false;
 }catch(error){
  preview.textContent=error.message||String(error);
  preview.classList.remove('hidden');
 }
}

async function importContentLot(){
 if(!pendingContentPayload)return;
 const button=document.getElementById('importContentButton');
 const status=document.getElementById('contentImportStatus');
 button.disabled=true;
 status.textContent='Import en cours…';
 try{
  const result=await CapCollegeSupabase.importDraftQuestionLot(
   pendingContentPayload
  );
  status.textContent=
   `Import terminé : ${result.imported_micro_skills} micro-compétences, `+
   `${result.imported_questions} questions et ${result.imported_choices} réponses.`;
 }catch(error){
  status.textContent=`Échec de l’import : ${error.message||error}`;
  button.disabled=false;
 }
}

CapCollegeSupabase.bootstrap({
 requireAuth:true,
 requiredRoles:['administrator'],
 loadQuestions:false
}).catch(CapCollegeSupabase.showFatalError);
