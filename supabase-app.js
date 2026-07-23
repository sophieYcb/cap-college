(function () {
  let client = null;
  let session = null;
  let roles = [];
  let diagnosticHistory = [];

  function configured() {
    const config = window.CAP_COLLEGE_CONFIG || {};
    return Boolean(config.supabaseUrl && config.publishableKey);
  }

  function getClient() {
    if (client) return client;
    if (!configured()) return null;
    if (!window.supabase || typeof window.supabase.createClient !== "function") {
      throw new Error("Le client Supabase n’a pas pu être chargé.");
    }
    const config = window.CAP_COLLEGE_CONFIG;
    client = window.supabase.createClient(
      config.supabaseUrl,
      config.publishableKey,
      {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true
        }
      }
    );
    return client;
  }

  async function loadSession() {
    const supabaseClient = getClient();
    if (!supabaseClient) return null;
    const { data, error } = await supabaseClient.auth.getSession();
    if (error) throw error;
    session = data.session;
    return session;
  }

  async function loadRoles() {
    if (!session) {
      roles = [];
      return roles;
    }
    const { data, error } = await getClient().rpc("get_my_roles");
    if (error) throw error;
    roles = Array.isArray(data) ? data : [];
    return roles;
  }

  async function loadPublishedQuestions() {
    const { data, error } = await getClient().rpc(
      "get_published_question_bank"
    );
    if (error) throw error;
    if (!Array.isArray(data)) {
      throw new Error("La banque de questions reçue est invalide.");
    }
    QUESTIONS = data.map((question) => ({
      id: Number(question.id),
      questionId: question.questionId,
      questionVersionId: question.questionVersionId,
      competenceId: question.competenceId,
      domaine: question.domaine,
      competence: question.competence,
      difficulte: Number(question.difficulte),
      question: question.question,
      choix: question.choix.map((choice) => choice.texte),
      choiceIds: question.choix.map((choice) => choice.id),
      reponse: null,
      version: Number(question.version),
      source: "supabase"
    }));
  }

  async function loadDiagnosticHistory() {
    const { data, error } = await getClient().rpc(
      "get_my_diagnostic_history"
    );
    if (error) throw error;
    diagnosticHistory = Array.isArray(data) ? data : [];
    const historyByQuestion = new Map(
      diagnosticHistory.map((item) => [item.questionId, item])
    );
    QUESTIONS.forEach((question) => {
      const history = historyByQuestion.get(question.questionId);
      question.history = history || {
        attempts: 0,
        correctAnswers: 0,
        lastAnsweredAt: null
      };
    });
  }

  function redirectToLogin() {
    const next = encodeURIComponent(
      location.pathname.split("/").pop() || "index.html"
    );
    location.replace(`login.html?next=${next}`);
  }

  async function bootstrap(options = {}) {
    const {
      requireAuth = false,
      requiredRoles = [],
      loadQuestions = false
    } = options;

    if (!configured()) {
      document.documentElement.dataset.dataSource = "local";
      return { mode: "local", session: null, roles: [] };
    }

    document.documentElement.dataset.dataSource = "supabase";
    await loadSession();

    if (requireAuth && !session) {
      redirectToLogin();
      return new Promise(() => {});
    }

    if (session) await loadRoles();

    if (
      requiredRoles.length &&
      !requiredRoles.some((role) => roles.includes(role))
    ) {
      throw new Error("Ce compte n’a pas accès à cet espace.");
    }

    if (loadQuestions) {
      await loadPublishedQuestions();
      await loadDiagnosticHistory();
    }
    return { mode: "supabase", session, roles };
  }

  async function signIn(email, password) {
    const supabaseClient = getClient();
    if (!supabaseClient) {
      throw new Error("La connexion Supabase n’est pas encore configurée.");
    }
    const { data, error } = await supabaseClient.auth.signInWithPassword({
      email,
      password
    });
    if (error) throw error;
    session = data.session;
    await loadRoles();
    return data;
  }

  async function signOut() {
    if (getClient()) await getClient().auth.signOut();
    session = null;
    roles = [];
    location.replace("index.html");
  }

  async function startDiagnostic(plannedMinutes, competenceId = "all") {
    if (!configured()) return null;
    const { data, error } = await getClient().rpc(
      "start_diagnostic_session_v2",
      {
        planned_minutes: plannedMinutes,
        requested_subject_code: "french",
        requested_level_code: "6e",
        requested_competence_id: competenceId
      }
    );
    if (error) throw error;
    return Array.isArray(data) ? data[0] : data;
  }

  async function submitAnswer(
    sessionId,
    questionVersionId,
    choiceId,
    sequenceNumber
  ) {
    if (!configured()) return null;
    const { data, error } = await getClient().rpc(
      "submit_diagnostic_answer",
      {
        requested_session_id: sessionId,
        requested_question_version_id: questionVersionId,
        requested_choice_id: choiceId,
        requested_sequence_number: sequenceNumber
      }
    );
    if (error) throw error;
    return Array.isArray(data) ? data[0] : data;
  }

  async function finishDiagnostic(sessionId) {
    if (!configured() || !sessionId) return null;
    const { data, error } = await getClient().rpc(
      "finish_diagnostic_session",
      { requested_session_id: sessionId }
    );
    if (error) throw error;
    return Array.isArray(data) ? data[0] : data;
  }

  async function getSkillProfile() {
    if (!configured()) return [];
    const { data, error } = await getClient().rpc("get_my_skill_profile");
    if (error) throw error;
    return Array.isArray(data) ? data : [];
  }

  async function getDiagnosticSessionState(sessionId) {
    if (!configured() || !sessionId) return null;
    const { data, error } = await getClient().rpc(
      "get_my_diagnostic_session_state",
      { requested_session_id: sessionId }
    );
    if (error) throw error;
    return Array.isArray(data) ? (data[0] || null) : data;
  }

  async function getActiveDiagnosticSession() {
    if (!configured()) return null;
    const { data, error } = await getClient().rpc(
      "get_my_active_diagnostic_session_v2"
    );
    if (error) throw error;
    return Array.isArray(data) ? (data[0] || null) : data;
  }

  async function closeDiagnosticSession(sessionId) {
    const { error } = await getClient().rpc(
      "close_my_diagnostic_session",
      { requested_session_id: sessionId }
    );
    if (error) throw error;
  }

  async function getRemediationQuestions(competenceId) {
    const { data, error } = await getClient().rpc(
      "get_remediation_question_bank",
      { requested_competence_id: competenceId }
    );
    if (error) throw error;
    return (Array.isArray(data) ? data : []).map((question) => ({
      id: Number(question.id),
      questionId: question.questionId,
      questionVersionId: question.questionVersionId,
      difficulte: Number(question.difficulte),
      question: question.question,
      choix: question.choix.map((choice) => choice.texte),
      choiceIds: question.choix.map((choice) => choice.id)
    }));
  }

  async function startRemediation(competenceId, minutes) {
    const { data, error } = await getClient().rpc(
      "start_remediation_session",
      {
        requested_competence_id: competenceId,
        requested_minutes: minutes
      }
    );
    if (error) throw error;
    return Array.isArray(data) ? data[0] : data;
  }

  async function submitRemediationAnswer(
    sessionId,
    questionVersionId,
    choiceId,
    assistance,
    sequenceNumber
  ) {
    const { data, error } = await getClient().rpc(
      "submit_remediation_answer",
      {
        requested_session_id: sessionId,
        requested_question_version_id: questionVersionId,
        requested_choice_id: choiceId,
        requested_assistance: assistance,
        requested_sequence_number: sequenceNumber
      }
    );
    if (error) throw error;
    return Array.isArray(data) ? data[0] : data;
  }

  async function finishRemediation(sessionId) {
    const { error } = await getClient().rpc(
      "finish_remediation_session",
      { requested_session_id: sessionId }
    );
    if (error) throw error;
  }

  async function getValidationQuestionBank() {
    const { data, error } = await getClient().rpc(
      "get_validation_question_bank"
    );
    if (error) throw error;
    if (!Array.isArray(data)) {
      throw new Error("La banque de validation reçue est invalide.");
    }
    return data;
  }

  async function saveQuestionReview(questionVersionId, grade, comment) {
    const { data, error } = await getClient().rpc(
      "save_question_review",
      {
        requested_question_version_id: questionVersionId,
        requested_grade: grade,
        requested_comment: comment || null
      }
    );
    if (error) throw error;
    return Array.isArray(data) ? data[0] : data;
  }

  function appendScript(source) {
    return new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = source;
      script.onload = resolve;
      script.onerror = () => reject(new Error(`Chargement impossible : ${source}`));
      document.body.appendChild(script);
    });
  }

  function showFatalError(error) {
    const main = document.querySelector("main") || document.body;
    main.innerHTML = `
      <section class="card connection-error">
        <h1>Connexion impossible</h1>
        <p>${String(error.message || error)}</p>
        <a class="btn btn-secondary" href="index.html">Retour à l’accueil</a>
      </section>`;
  }

  window.CapCollegeSupabase = {
    appendScript,
    bootstrap,
    closeDiagnosticSession,
    configured,
    getClient,
    getDiagnosticHistory: () => [...diagnosticHistory],
    getActiveDiagnosticSession,
    getDiagnosticSessionState,
    getSkillProfile,
    getValidationQuestionBank,
    getRemediationQuestions,
    getRoles: () => [...roles],
    getSession: () => session,
    showFatalError,
    saveQuestionReview,
    signIn,
    signOut,
    finishDiagnostic,
    finishRemediation,
    startDiagnostic,
    startRemediation,
    submitAnswer,
    submitRemediationAnswer
  };
})();
