const logoutButton = document.getElementById("learnerLogoutButton");
CapCollegeSupabase.getLearnerSession()
  .then(profile => {
    if (!profile) {
      location.replace("connexion-enfant.html");
      return;
    }
    document.getElementById("learnerGreeting").textContent =
      `Bonjour ${profile.displayName} !`;
    document.getElementById("learnerLevel").textContent =
      `Niveau ${profile.levelName}`;
  })
  .catch(() => location.replace("connexion-enfant.html"));
logoutButton.addEventListener("click", async () => {
  logoutButton.disabled = true;
  await CapCollegeSupabase.closeLearnerSession();
  location.replace("connexion-enfant.html");
});