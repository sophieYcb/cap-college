CapCollegeSupabase.bootstrap({ requireAuth: true })
  .then(async () => {
    try {
      window.CAP_COLLEGE_SKILL_PROFILE =
        await CapCollegeSupabase.getSkillProfile();
    } catch (error) {
      console.warn("Le profil cumulé n’a pas pu être chargé.", error);
      window.CAP_COLLEGE_SKILL_PROFILE = [];
    }
    await CapCollegeSupabase.appendScript("resultats.js");
  })
  .catch(CapCollegeSupabase.showFatalError);
