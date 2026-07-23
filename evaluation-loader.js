CapCollegeSupabase.bootstrap({
  requireAuth: true,
  loadQuestions: true
})
  .then(() => CapCollegeSupabase.appendScript("evaluation.js"))
  .catch(CapCollegeSupabase.showFatalError);
