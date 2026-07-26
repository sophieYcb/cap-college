const validationCampaignId =
  new URLSearchParams(location.search).get("validationCampaign");

if (validationCampaignId) {
  sessionStorage.setItem("capCollegeValidationCampaignId", validationCampaignId);
  window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID = validationCampaignId;
  window.CAP_COLLEGE_VALIDATION_CAMPAIGN_NAME =
    sessionStorage.getItem("capCollegeValidationCampaignName") ||
    "Campagne de validation";
} else {
  sessionStorage.removeItem("capCollegeValidationCampaignId");
  sessionStorage.removeItem("capCollegeValidationCampaignName");
}

CapCollegeSupabase.bootstrap({
  requireAuth: true,
  requiredRoles: validationCampaignId ? ["validator", "administrator"] : [],
  loadQuestions: true,
  validationCampaignId
})
  .then(() => CapCollegeSupabase.appendScript("evaluation.js?v=5.3.20"))
  .catch(CapCollegeSupabase.showFatalError);
