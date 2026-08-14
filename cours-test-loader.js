CapCollegeSupabase.bootstrap({
  requireAuth: true,
  requiredRoles: ["validator", "administrator"],
  loadQuestions: false
}).then(async () => {
  window.COURSE_SUMMARIES = await CapCollegeSupabase.getValidationCourseSummaries();
  await CapCollegeSupabase.appendScript("cours-test.js?v=5.3.48");
}).catch(CapCollegeSupabase.showFatalError);
