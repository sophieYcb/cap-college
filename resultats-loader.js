const resultLearnerMode =
  new URLSearchParams(location.search).get("mode") === "child";
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
    await CapCollegeSupabase.appendScript("resultats.js?v=5.3.12");
  })
  .catch(CapCollegeSupabase.showFatalError);
