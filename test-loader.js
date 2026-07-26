CapCollegeSupabase.bootstrap({
  requireAuth: true,
  requiredRoles: ["validator", "administrator"],
  loadQuestions: false
})
  .then(async () => {
    window.VALIDATION_QUESTIONS =
      await CapCollegeSupabase.getValidationQuestionBank();
    await CapCollegeSupabase.appendScript("test.js?v=5.3.16");
  })
  .catch(CapCollegeSupabase.showFatalError);
