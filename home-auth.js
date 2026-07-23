CapCollegeSupabase.bootstrap()
  .then(({ session, roles }) => {
    if (!session) return;

    const loginLink = document.getElementById("loginLink");
    const logoutButton = document.getElementById("logoutButton");
    const roleNames = {
      administrator: "Administrateur",
      validator: "Validateur",
      teacher: "Enseignant",
      parent: "Parent",
      student: "Élève"
    };
    const visibleRole = roles
      .map((role) => roleNames[role])
      .filter(Boolean)
      .join(" · ");

    loginLink.textContent = visibleRole
      ? `Connecté · ${visibleRole}`
      : "Compte connecté";
    loginLink.href = "evaluation.html";
    logoutButton.classList.remove("hidden");
    logoutButton.addEventListener("click", () => {
      CapCollegeSupabase.signOut();
    });
    return CapCollegeSupabase.getActiveDiagnosticSession();
  })
  .then((activeSession) => {
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
