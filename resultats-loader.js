const resultLearnerMode =
  new URLSearchParams(location.search).get("mode") === "child";
const resultSubject =
  new URLSearchParams(location.search).get("subject");
CapCollegeSupabase.bootstrap({
  requireAuth: true,
  preferLearner: resultLearnerMode
})
  .then(async () => {
    const validationCampaignId =
      new URLSearchParams(location.search).get("validationCampaign");
    window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID = validationCampaignId;
    try {
      window.CAP_COLLEGE_SKILL_PROFILE = validationCampaignId
        ? []
        : await CapCollegeSupabase.getSkillProfile();
    } catch (error) {
      console.warn("Le profil cumulé n’a pas pu être chargé.", error);
      window.CAP_COLLEGE_SKILL_PROFILE = [];
    }
    try {
      window.CAP_COLLEGE_DIAGNOSTIC_PROGRESS = validationCampaignId
        ? null
        : await CapCollegeSupabase.getDiagnosticProgress(resultSubject);
    } catch (error) {
      console.warn("La progression du diagnostic n’a pas pu être chargée.", error);
      window.CAP_COLLEGE_DIAGNOSTIC_PROGRESS = null;
    }
    await CapCollegeSupabase.appendScript("resultats.js?v=5.3.42");
  })
  .catch(CapCollegeSupabase.showFatalError);
