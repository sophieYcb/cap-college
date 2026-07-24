const validationCampaignId =
  new URLSearchParams(location.search).get("validationCampaign");

if (validationCampaignId) {
  sessionStorage.setItem("capCollegeValidationCampaignId", validationCampaignId);
  window.CAP_COLLEGE_VALIDATION_CAMPAIGN_ID = validationCampaignId;
} else {
  sessionStorage.removeItem("capCollegeValidationCampaignId");
}

CapCollegeSupabase.bootstrap({
  requireAuth: true,
  requiredRoles: validationCampaignId ? ["validator", "administrator"] : [],
  loadQuestions: true,
  validationCampaignId
})
  .then(() => CapCollegeSupabase.appendScript("evaluation.js?v=5.3.11"))
  .catch(CapCollegeSupabase.showFatalError);
