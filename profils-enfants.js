const form = document.getElementById("learnerProfileForm");
const statusMessage = document.getElementById("profileFormStatus");
const list = document.getElementById("learnerProfileList");
const count = document.getElementById("profileCount");

function escapeHtml(value) {
  const element = document.createElement("span");
  element.textContent = String(value || "");
  return element.innerHTML;
}
function formatProfileCode(value) {
  return String(value || "").replace(/(.{4})(?=.)/g, "$1-");
}
function clampPercent(value) {
  return Math.max(0, Math.min(100, Number(value) || 0));
}
function renderSubjectProgress(progress) {
  const percent = clampPercent(progress.progress_percent);
  const title = escapeHtml(progress.subject_name);
  if (!progress.has_diagnostic) {
    return `<div class="learner-subject-progress">
      <div class="learner-progress-heading"><strong>${title}</strong><span>Pas encore commencé</span></div>
      <div class="meter"><span class="pending-meter" style="width:0%"></span></div>
    </div>`;
  }
  const state = progress.diagnosis_ready
    ? "Diagnostic terminé"
    : `${percent} % · ${progress.assessed_skills}/${progress.total_skills} compétences évaluées`;
  const details = progress.diagnosis_ready
    ? `${progress.completed_sessions} séance${progress.completed_sessions > 1 ? "s" : ""} · bilan fiable disponible`
    : `${progress.completed_sessions} séance${progress.completed_sessions > 1 ? "s" : ""} · au moins ${progress.questions_remaining} question${progress.questions_remaining > 1 ? "s" : ""} restante${progress.questions_remaining > 1 ? "s" : ""}`;
  return `<div class="learner-subject-progress">
    <div class="learner-progress-heading"><strong>${title}</strong><span>${escapeHtml(state)}</span></div>
    <div class="meter"><span class="${progress.diagnosis_ready ? "green" : "pending-meter"}" style="width:${percent}%"></span></div>
    <p class="small">${escapeHtml(details)}</p>
  </div>`;
}
function renderProfiles(profiles, progressRows = []) {
  count.textContent = `${profiles.length} profil${profiles.length > 1 ? "s" : ""}`;
  if (!profiles.length) {
    list.innerHTML = '<p class="muted">Aucun profil créé pour le moment.</p>';
    return;
  }
  const progressByLearner = new Map();
  progressRows.forEach(progress => {
    const rows = progressByLearner.get(progress.learner_profile_id) || [];
    rows.push(progress);
    progressByLearner.set(progress.learner_profile_id, rows);
  });
  list.innerHTML = profiles.map(profile => {
    const progress = progressByLearner.get(profile.id) || [];
    return `<article class="learner-profile-card">
      <div class="learner-profile-main">
        <div class="learner-avatar">${escapeHtml(profile.display_name).charAt(0).toUpperCase()}</div>
        <div><strong>${escapeHtml(profile.display_name)}</strong><p>${escapeHtml(profile.level_name)} · ${profile.relationship_type === "teacher" ? "Élève" : "Enfant"}</p><p class="learner-access-code">Identifiant : <code>${formatProfileCode(profile.access_code)}</code></p></div>
        <span class="learner-pin-badge">PIN protégé</span>
        <a class="btn btn-secondary learner-detail-link" href="suivi-enfant.html?id=${encodeURIComponent(profile.id)}">Voir le détail</a>
      </div>
      <div class="learner-progress-summary">
        <h3>Progression</h3>
        ${progress.length
          ? progress.map(renderSubjectProgress).join("")
          : '<p class="muted">Aucun diagnostic disponible.</p>'}
      </div>
    </article>`;
  }).join("");
}
async function refreshProfiles() {
  const [profiles, progress] = await Promise.all([
    CapCollegeSupabase.getLearnerProfiles(),
    CapCollegeSupabase.getLearnerProgress()
  ]);
  renderProfiles(profiles, progress);
}
form.addEventListener("submit", async event => {
  event.preventDefault();
  const button = document.getElementById("createLearnerButton");
  const name = document.getElementById("learnerName").value.trim();
  const level = document.getElementById("learnerLevel").value;
  const pin = document.getElementById("learnerPin").value;
  const pinConfirmation = document.getElementById("learnerPinConfirmation").value;
  statusMessage.classList.remove("save-error");
  if (!/^\d{6}$/.test(pin)) {
    statusMessage.textContent = "Le PIN doit contenir exactement 6 chiffres.";
    statusMessage.classList.add("save-error");
    return;
  }
  if (pin !== pinConfirmation) {
    statusMessage.textContent = "Les deux PIN ne correspondent pas.";
    statusMessage.classList.add("save-error");
    return;
  }
  button.disabled = true;
  statusMessage.textContent = "Création en cours…";
  try {
    await CapCollegeSupabase.createLearnerProfile(name, level, pin);
    form.reset();
    document.getElementById("learnerLevel").value = "6e";
    statusMessage.textContent = "Le profil a bien été créé.";
    await refreshProfiles();
  } catch (error) {
    statusMessage.textContent = error.message || "Le profil n’a pas pu être créé.";
    statusMessage.classList.add("save-error");
  } finally {
    button.disabled = false;
  }
});
CapCollegeSupabase.bootstrap({requireAuth: true, requiredRoles: ["guardian", "teacher"]})
  .then(({ activeRole }) => {
    const isTeacher = activeRole === "teacher";
    document.getElementById("workspaceLabel").textContent = isTeacher ? "Espace enseignant" : "Espace parent";
    document.getElementById("pageTitle").textContent = isTeacher ? "Profils élèves" : "Profils enfants";
    document.getElementById("listTitle").textContent = isTeacher ? "Mes élèves" : "Mes enfants";
    return refreshProfiles();
  })
  .catch(CapCollegeSupabase.showFatalError);