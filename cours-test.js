const SUMMARIES = Array.isArray(window.COURSE_SUMMARIES) ? window.COURSE_SUMMARIES : [];
let filtered = [], index = 0, saveTimer = null;
const byId = id => document.getElementById(id);
const current = () => filtered[index] || null;
const unique = items => [...new Set(items.filter(Boolean))];
const escapeHtml = value => String(value ?? "").replace(/[&<>"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"})[c]);

function fillSelect(select, values, label) {
  const selected = select.value;
  select.innerHTML = `<option value="all">${label}</option>` + values.map(value => `<option value="${escapeHtml(value)}">${escapeHtml(value)}</option>`).join("");
  select.value = values.includes(selected) ? selected : "all";
}
function updateDomains() {
  const subject = byId("subjectFilter").value;
  const rows = subject === "all" ? SUMMARIES : SUMMARIES.filter(x => x.subjectName === subject);
  fillSelect(byId("domainFilter"), unique(rows.map(x => x.domainName)), "Toutes les catégories");
  applyFilters();
}
function applyFilters() {
  const activeId = current()?.microSkillId;
  const subject = byId("subjectFilter").value, domain = byId("domainFilter").value, status = byId("statusFilter").value;
  filtered = SUMMARIES.filter(x => (subject === "all" || x.subjectName === subject) && (domain === "all" || x.domainName === domain) && (status === "all" || (status === "unreviewed" ? !x.review?.grade : x.review?.grade === status)));
  const existing = filtered.findIndex(x => x.microSkillId === activeId);
  index = existing >= 0 ? existing : 0;
  render();
}
function render() {
  const item = current(), panel = document.querySelector(".review-panel");
  if (!item) {
    byId("courseCounter").textContent = "Aucun résumé"; byId("courseCode").textContent = "";
    byId("courseTitle").textContent = "Aucun résumé ne correspond aux filtres.";
    byId("courseReminder").textContent = ""; byId("courseExample").textContent = ""; panel.hidden = true; renderSummary(); return;
  }
  panel.hidden = false;
  byId("courseCounter").textContent = `${index + 1} / ${filtered.length}`;
  byId("courseCode").textContent = item.microSkillCode;
  byId("courseProgress").style.width = `${Math.round(((index + 1) / filtered.length) * 100)}%`;
  byId("courseDomain").textContent = `${item.subjectName} · ${item.domainName}`;
  byId("courseSkill").textContent = item.skillName; byId("courseTitle").textContent = item.title;
  byId("courseReminder").textContent = item.reminder || "Résumé manquant";
  byId("courseReminder").classList.toggle("course-content-missing", !item.reminder);
  byId("courseExample").textContent = item.workedExample || "Exemple manquant";
  byId("courseExample").classList.toggle("course-content-missing", !item.workedExample);
  byId("reviewComment").value = item.review?.comment || "";
  document.querySelectorAll(".rating").forEach(button => button.classList.toggle("active", button.dataset.rating === item.review?.grade));
  byId("reviewSaveStatus").textContent = item.review?.grade ? `Note ${item.review.grade} enregistrée.` : "Non testé";
  renderSummary();
}
async function save(grade = current()?.review?.grade) {
  const item = current(); if (!item || !grade) return;
  byId("reviewSaveStatus").textContent = "Enregistrement…";
  try {
    const saved = await CapCollegeSupabase.saveCourseSummaryReview(item.microSkillId, item.fingerprint, grade, byId("reviewComment").value);
    item.review = {grade, comment: byId("reviewComment").value, reviewedAt: saved?.reviewed_at || new Date().toISOString()};
    byId("reviewSaveStatus").textContent = `Note ${grade} enregistrée.`; renderSummary();
  } catch (error) { byId("reviewSaveStatus").textContent = `Échec : ${error.message || error}`; }
}
function move(delta) { if (!filtered.length) return; index = (index + delta + filtered.length) % filtered.length; render(); window.scrollTo({top:0,behavior:"smooth"}); }
function nextUnreviewed() {
  for (let offset = 1; offset <= filtered.length; offset++) { const candidate = (index + offset) % filtered.length; if (!filtered[candidate].review?.grade) { index = candidate; render(); return; } }
  byId("reviewSaveStatus").textContent = "Tous les résumés de ce filtre ont été testés.";
}
function renderSummary() {
  const counts = {A:0,B:0,C:0,D:0}; SUMMARIES.forEach(x => { if (x.review?.grade) counts[x.review.grade]++; });
  const tested = Object.values(counts).reduce((sum, value) => sum + value, 0);
  byId("qualitySummary").innerHTML = `<div class="summary-box"><div class="summary-value">${tested} / ${SUMMARIES.length}</div><div class="small">résumés testés</div></div>${Object.entries(counts).map(([grade,count]) => `<div class="summary-box"><div class="summary-value">${count}</div><div class="small">note ${grade}</div></div>`).join("")}`;
}
function downloadCorrections() {
  const summaries = SUMMARIES.filter(x => x.review && (x.review.grade !== "A" || x.review.comment)).map(x => ({microSkillId:x.microSkillId,microSkillCode:x.microSkillCode,subject:x.subjectName,domain:x.domainName,skill:x.skillName,title:x.title,reminder:x.reminder,workedExample:x.workedExample,contentFingerprint:x.fingerprint,grade:x.review.grade,comment:x.review.comment||""}));
  if (!summaries.length) { byId("reviewSaveStatus").textContent = "Aucun résumé à corriger."; return; }
  const blob = new Blob([JSON.stringify({format:"cap-college-course-summary-review",exportedAt:new Date().toISOString(),summaryCount:summaries.length,summaries},null,2)],{type:"application/json;charset=utf-8"});
  const link = document.createElement("a"); link.href = URL.createObjectURL(blob); link.download = `cap-college-resumes-cours-a-corriger-${new Date().toISOString().slice(0,10)}.json`; link.click(); URL.revokeObjectURL(link.href);
}
fillSelect(byId("subjectFilter"), unique(SUMMARIES.map(x => x.subjectName)), "Toutes les matières"); updateDomains();
byId("subjectFilter").addEventListener("change", updateDomains); byId("domainFilter").addEventListener("change", applyFilters); byId("statusFilter").addEventListener("change", applyFilters);
byId("previousButton").addEventListener("click", () => move(-1)); byId("nextButton").addEventListener("click", () => move(1)); byId("nextUnreviewedButton").addEventListener("click", nextUnreviewed); byId("exportButton").addEventListener("click", downloadCorrections);
document.querySelectorAll(".rating").forEach(button => button.addEventListener("click", () => save(button.dataset.rating).then(render)));
byId("reviewComment").addEventListener("input", () => { clearTimeout(saveTimer); saveTimer = setTimeout(() => save(), 700); });
document.addEventListener("keydown", event => { if (/^(INPUT|TEXTAREA|SELECT)$/.test(event.target.tagName)) return; const key = event.key.toUpperCase(); if (["A","B","C","D"].includes(key)) save(key).then(render); if (event.key === "ArrowLeft") move(-1); if (event.key === "ArrowRight") move(1); });
