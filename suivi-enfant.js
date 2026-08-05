const learnerId = new URLSearchParams(location.search).get("id");
const progressTarget = document.getElementById("followupProgress");
const historyTarget = document.getElementById("sessionHistory");

function escapeHtml(value) {
  const element = document.createElement("span");
  element.textContent = String(value || "");
  return element.innerHTML;
}
function formatDate(value, withTime = true) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("fr-FR", withTime
    ? {dateStyle: "medium", timeStyle: "short"}
    : {dateStyle: "medium"}
  ).format(new Date(value));
}
function statusLabel(status) {
  if (status === "completed") return "Terminée";
  if (status === "active") return "En cours";
  return "Interrompue";
}
function renderProgress(rows) {
  if (!rows.length) {
    progressTarget.innerHTML =
      '<p class="muted">Aucun diagnostic commencé.</p>';
    return;
  }
  progressTarget.innerHTML = rows.map(row => {
    const percent = Math.max(0, Math.min(100,
      Number(row.progress_percent) || 0));
    const label = row.diagnosis_ready
      ? "Diagnostic terminé"
      : percent + " % · " + row.assessed_skills + "/" +
        row.total_skills + " compétences évaluées";
    return `<article class="learner-followup-subject">
      <div class="learner-progress-heading">
        <strong>${escapeHtml(row.subject_name)}</strong>
        <span>${escapeHtml(label)}</span>
      </div>
      <div class="meter"><span class="${row.diagnosis_ready ? "green" : "pending-meter"}" style="width:${percent}%"></span></div>
      <p class="small">${row.completed_sessions} séance${row.completed_sessions > 1 ? "s" : ""} terminée${row.completed_sessions > 1 ? "s" : ""} · au moins ${row.questions_remaining} question${row.questions_remaining > 1 ? "s" : ""} restante${row.questions_remaining > 1 ? "s" : ""}</p>
    </article>`;
  }).join("");
}
function renderHistory(rows) {
  const usefulRows = rows.filter(row =>
    Number(row.answer_count) > 0 || row.session_status === "completed"
  );
  const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
  const completedThisWeek = usefulRows.filter(row =>
    row.session_status === "completed" &&
    new Date(row.started_at).getTime() >= sevenDaysAgo
  );
  document.getElementById("weekSessions").textContent =
    completedThisWeek.length;
  document.getElementById("weekMinutes").textContent =
    completedThisWeek.reduce(
      (total, row) => total + Number(row.planned_minutes || 0), 0
    ) + " min";
  document.getElementById("lastActivity").textContent =
    usefulRows.length ? formatDate(usefulRows[0].started_at, false) : "—";

  if (!usefulRows.length) {
    historyTarget.innerHTML =
      '<p class="muted">Aucune séance réalisée pour le moment.</p>';
    return;
  }
  historyTarget.innerHTML = usefulRows.map(row => `
    <article class="learner-session-row">
      <div>
        <strong>${formatDate(row.started_at)}</strong>
        <p>${escapeHtml(row.subject_name)} · séance de ${row.planned_minutes} min</p>
      </div>
      <div class="learner-session-meta">
        <span class="tag ${row.session_status === "completed" ? "green" : "orange"}">${statusLabel(row.session_status)}</span>
        <span class="small">${row.answer_count} réponse${row.answer_count > 1 ? "s" : ""}</span>
      </div>
    </article>
  `).join("");
}
async function loadFollowup() {
  if (!learnerId) throw new Error("Profil enfant manquant.");
  const [profiles, progress, history] = await Promise.all([
    CapCollegeSupabase.getLearnerProfiles(),
    CapCollegeSupabase.getLearnerProgress(),
    CapCollegeSupabase.getLearnerSessionHistory(learnerId)
  ]);
  const profile = profiles.find(item => item.id === learnerId);
  if (!profile) throw new Error("Ce profil enfant n’est pas accessible.");
  document.getElementById("followupTitle").textContent =
    "Progression de " + profile.display_name;
  document.getElementById("followupLevel").textContent =
    "Niveau scolaire : " + profile.level_name;
  renderProgress(progress.filter(
    item => item.learner_profile_id === learnerId
  ));
  renderHistory(history);
}
CapCollegeSupabase.bootstrap({
  requireAuth: true,
  requiredRoles: ["guardian", "teacher"]
})
  .then(loadFollowup)
  .catch(CapCollegeSupabase.showFatalError);
