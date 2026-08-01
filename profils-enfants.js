const form = document.getElementById("learnerProfileForm");
const statusMessage = document.getElementById("profileFormStatus");
const list = document.getElementById("learnerProfileList");
const count = document.getElementById("profileCount");

function escapeHtml(value) {
  const element = document.createElement("span");
  element.textContent = String(value || "");
  return element.innerHTML;
}
function renderProfiles(profiles) {
  count.textContent = `${profiles.length} profil${profiles.length > 1 ? "s" : ""}`;
  if (!profiles.length) {
    list.innerHTML = '<p class="muted">Aucun profil créé pour le moment.</p>';
    return;
  }
  list.innerHTML = profiles.map(profile => `
    <article class="learner-profile-card">
      <div class="learner-avatar">${escapeHtml(profile.display_name).charAt(0).toUpperCase()}</div>
      <div><strong>${escapeHtml(profile.display_name)}</strong><p>${escapeHtml(profile.level_name)} · ${profile.relationship_type === "teacher" ? "Élève" : "Enfant"}</p></div>
      <span class="learner-pin-badge">PIN protégé</span>
    </article>`).join("");
}
async function refreshProfiles() {
  renderProfiles(await CapCollegeSupabase.getLearnerProfiles());
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