const learnerId = new URLSearchParams(location.search).get("id");
const progressTarget = document.getElementById("followupProgress");
const historyTarget = document.getElementById("sessionHistory");
const reportsTarget = document.getElementById("diagnosticReports");
const remediationTarget = document.getElementById("remediationHistory");

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
function reportLevel(score) {
  if (score >= 80) return ["Maîtrisée", "green"];
  if (score >= 50) return ["À consolider", "orange"];
  return ["Prioritaire", "red"];
}
function renderDiagnosticReports(rows) {
  if (!rows.length) {
    reportsTarget.innerHTML =
      '<p class="muted">Aucun diagnostic terminé pour le moment.</p>';
    return;
  }
  reportsTarget.innerHTML = rows.map((row, reportIndex) => {
    const report = typeof row.report === "string"
      ? JSON.parse(row.report) : (row.report || {});
    const skills = (report.skills || [])
      .filter(item => item.sufficientEvidence)
      .map(item => ({...item, masteryScore: Number(item.masteryScore) || 0}));
    const strengths = skills.filter(item => item.masteryScore >= 80);
    const consolidating = skills.filter(item =>
      item.masteryScore >= 50 && item.masteryScore < 80
    );
    const priorities = skills.filter(item => item.masteryScore < 50)
      .sort((a, b) => a.masteryScore - b.masteryScore);
    const workPlan = [...priorities, ...consolidating
      .sort((a, b) => a.masteryScore - b.masteryScore)].slice(0, 3);
    const domains = [...new Set(skills.map(item => item.domain))];
    const domainHtml = domains.map(domain => {
      const items = skills.filter(item => item.domain === domain);
      const evidence = items.reduce((sum, item) =>
        sum + Number(item.evidenceCount || 0), 0);
      const correct = items.reduce((sum, item) =>
        sum + Number(item.correctCount || 0), 0);
      const score = evidence ? Math.round(correct * 100 / evidence) : 0;
      return `<details class="diagnostic-domain" ${reportIndex === 0 ? "open" : ""}>
        <summary>
          <strong>${escapeHtml(domain)}</strong>
          <span>${score} % · ${items.length} compétence${items.length > 1 ? "s" : ""}</span>
        </summary>
        <div class="diagnostic-skill-list">${items.map(item => {
          const [label, color] = reportLevel(item.masteryScore);
          return `<div class="diagnostic-skill-row">
            <div><strong>${escapeHtml(item.competence)}</strong><br>
              <span class="small">${item.correctCount}/${item.evidenceCount} réponses correctes · ${item.sessionCount} séances</span>
            </div>
            <span class="tag ${color}">${item.masteryScore} % · ${label}</span>
          </div>`;
        }).join("")}</div>
      </details>`;
    }).join("");
    return `<article class="diagnostic-report-card">
      <div class="diagnostic-report-heading">
        <div><span class="small">Bilan du ${formatDate(row.completed_at, false)}</span>
          <h3>${escapeHtml(row.subject_name)}</h3></div>
        <span class="tag green">Diagnostic terminé</span>
      </div>
      <p>${row.answered_questions} réponses sur ${row.completed_sessions} séances. Le bilan repose sur ${skills.length} compétences suffisamment évaluées.</p>
      <div class="diagnostic-report-counts">
        <span><strong>${strengths.length}</strong> maîtrisées</span>
        <span><strong>${consolidating.length}</strong> à consolider</span>
        <span><strong>${priorities.length}</strong> prioritaires</span>
      </div>
      <div class="diagnostic-work-plan">
        <strong>Programme conseillé</strong>
        ${workPlan.length
          ? `<ol>${workPlan.map(item => `<li>${escapeHtml(item.competence)}</li>`).join("")}</ol>
             <p class="small">Objectif proposé : deux séances de 20 questions par semaine, puis une nouvelle évaluation après entraînement.</p>`
          : '<p>Aucune priorité importante : entretien régulier conseillé.</p>'}
      </div>
      ${domainHtml}
    </article>`;
  }).join("");
}
function renderRemediationHistory(rows) {
  if (!rows.length) {
    remediationTarget.innerHTML =
      '<p class="muted">Aucun exercice réalisé pour le moment.</p>';
    return;
  }
  remediationTarget.innerHTML = rows.map(row => {
    const answers = Number(row.answer_count) || 0;
    const correct = Number(row.correct_count) || 0;
    const score = answers ? Math.round(correct * 100 / answers) : 0;
    const [label, color] = reportLevel(score);
    return `<article class="learner-session-row">
      <div>
        <strong>${escapeHtml(row.competence)}</strong>
        <p>${escapeHtml(row.subject_name)} · ${escapeHtml(row.domain_name)} · ${formatDate(row.started_at)}</p>
      </div>
      <div class="learner-session-meta">
        <span class="tag ${color}">${score} % · ${label}</span>
        <span class="small">${correct}/${answers} réponses correctes</span>
      </div>
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
      (total, row) => total + Number(row.planned_minutes || 0) * 2, 0
    );
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
        <p>${escapeHtml(row.subject_name)} · objectif de ${Number(row.planned_minutes || 0) * 2} questions</p>
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
  const [profiles, progress, history, reports, remediationHistory] = await Promise.all([
    CapCollegeSupabase.getLearnerProfiles(),
    CapCollegeSupabase.getLearnerProgress(),
    CapCollegeSupabase.getLearnerSessionHistory(learnerId),
    CapCollegeSupabase.getLearnerDiagnosticReports(learnerId),
    CapCollegeSupabase.getLearnerRemediationHistory(learnerId)
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
  renderDiagnosticReports(reports);
  renderRemediationHistory(remediationHistory);
}
CapCollegeSupabase.bootstrap({
  requireAuth: true,
  requiredRoles: ["guardian", "teacher"]
})
  .then(loadFollowup)
  .catch(CapCollegeSupabase.showFatalError);
