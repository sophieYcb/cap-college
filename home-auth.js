const ROLE_NAMES = {
  administrator: "Administrateur",
  validator: "Validateur",
  teacher: "Enseignant",
  guardian: "Parent",
  student: "Élève"
};

const ROLE_ORDER = [
  "student",
  "guardian",
  "teacher",
  "validator",
  "administrator"
];

function configureProfileSwitcher(roles, activeRole) {
  const button = document.getElementById("changeProfileButton");
  const switcher = document.getElementById("profileSwitcher");
  const options = document.getElementById("profileOptions");
  const close = document.getElementById("closeProfileSwitcher");

  if (roles.length < 2) return;

  button.classList.remove("hidden");
  options.innerHTML = ROLE_ORDER
    .filter(role => roles.includes(role))
    .map(role => `
      <button
        class="profile-option${role === activeRole ? " active" : ""}"
        type="button"
        data-role="${role}"
        ${role === activeRole ? "disabled" : ""}
      >${ROLE_NAMES[role] || role}${role === activeRole ? " · actif" : ""}</button>
    `)
    .join("");

  button.addEventListener("click", () => {
    switcher.classList.toggle("hidden");
  });
  close.addEventListener("click", () => switcher.classList.add("hidden"));

  options.addEventListener("click", async event => {
    const option = event.target.closest("[data-role]");
    if (!option || option.disabled) return;
    option.disabled = true;
    try {
      await CapCollegeSupabase.setActiveRole(option.dataset.role);
      location.reload();
    } catch (error) {
      option.disabled = false;
      alert("Le profil n’a pas pu être changé. Réessaie dans un instant.");
    }
  });
}

CapCollegeSupabase.bootstrap()
  .then(({ session, roles, activeRole }) => {
    if (!session) return null;

    const loginLink = document.getElementById("loginLink");
    const logoutButton = document.getElementById("logoutButton");
    const activeRoleName = ROLE_NAMES[activeRole] || "Compte connecté";

    loginLink.textContent = `Profil actif · ${activeRoleName}`;
    loginLink.href = "evaluation.html";
    logoutButton.classList.remove("hidden");
    configureProfileSwitcher(roles, activeRole);

    if (activeRole === "student") {
      document.getElementById("errorNotebookLink").classList.remove("hidden");
    } else {
      document.getElementById("diagnosticStartLink").classList.add("hidden");
      document.getElementById("subjectsLink").classList.add("hidden");
      document.getElementById("matieres").classList.add("hidden");
    }
    if (activeRole === "validator" || activeRole === "administrator") {
      document.getElementById("pedagogicalTestLink").classList.remove("hidden");
      document.getElementById("contentImportLink").classList.remove("hidden");
    }
    if (activeRole === "guardian" || activeRole === "teacher") {
      const notice = document.getElementById("profileWorkspaceNotice");
      const profilesLink = document.getElementById("learnerProfilesLink");
      notice.textContent = activeRole === "guardian"
        ? "Créez ici les profils de vos enfants, sans adresse e-mail."
        : "Créez ici les profils de vos élèves, sans adresse e-mail.";
      profilesLink.textContent = activeRole === "guardian"
        ? "Gérer mes enfants"
        : "Gérer mes élèves";
      profilesLink.classList.remove("hidden");
      notice.classList.remove("hidden");
    }

    logoutButton.addEventListener("click", () => {
      CapCollegeSupabase.signOut();
    });

    return activeRole === "student"
      ? CapCollegeSupabase.getActiveDiagnosticSession()
      : null;
  })
  .then(activeSession => {
    if (!activeSession) return;
    document.getElementById("diagnosticStartLink").classList.add("hidden");
    const panel = document.getElementById("activeSessionHome");
    panel.classList.remove("hidden");
    document.getElementById("activeSessionTitle").textContent =
      activeSession.focus_name;
    document.getElementById("activeSessionDetails").textContent =
      `${activeSession.recorded_answers} réponse${activeSession.recorded_answers > 1 ? "s" : ""} enregistrée${activeSession.recorded_answers > 1 ? "s" : ""} · séance de ${activeSession.planned_minutes} min`;

    document.getElementById("chooseNewSessionButton")
      .addEventListener("click", async () => {
        const close = confirm(
          "Ta progression générale sera conservée, mais cette séance sera clôturée. Veux-tu choisir un nouveau thème et une nouvelle durée ?"
        );
        if (!close) return;
        try {
          await CapCollegeSupabase.closeDiagnosticSession(
            activeSession.session_id
          );
          location.href = "evaluation.html?new=1";
        } catch (error) {
          alert("La séance n’a pas pu être clôturée. Réessaie dans un instant.");
        }
      });
  })
  .catch(() => {
    const loginLink = document.getElementById("loginLink");
    loginLink.textContent = "Connexion à vérifier";
  });
