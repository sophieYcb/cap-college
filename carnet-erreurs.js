let notebookItems = [];
let showResolved = false;

function escapeNotebookHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function renderNotebook() {
  const current = notebookItems.filter((item) => !item.resolved);
  const resolved = notebookItems.filter((item) => item.resolved);
  const visible = showResolved ? resolved : current;
  const status = document.getElementById("notebookStatus");
  const list = document.getElementById("notebookList");

  document.getElementById("notebookSummary").innerHTML = `
    <div class="summary-box"><div class="summary-value">${current.length}</div><div class="small">à retravailler</div></div>
    <div class="summary-box"><div class="summary-value">${resolved.length}</div><div class="small">consolidées</div></div>
    <div class="summary-box"><div class="summary-value">${notebookItems.length}</div><div class="small">erreurs conservées</div></div>`;

  status.textContent = visible.length
    ? `${visible.length} erreur${visible.length > 1 ? "s" : ""} ${showResolved ? "consolidée" : "à retravailler"}${visible.length > 1 ? "s" : ""}.`
    : showResolved
      ? "Aucune erreur n’est encore classée comme consolidée."
      : "Aucune erreur à retravailler. Bravo !";

  list.innerHTML = visible.map((item) => `
    <article class="mistake-card">
      <div class="mistake-heading">
        <strong>${escapeNotebookHtml(item.skill)}</strong>
        <span class="small">${escapeNotebookHtml(item.domain)}</span>
      </div>
      <p class="mistake-question">${escapeNotebookHtml(item.prompt)}</p>
      <div class="answer-review wrong-answer">
        <span>Ta réponse</span>
        <strong>${escapeNotebookHtml(item.selectedAnswer)}</strong>
      </div>
      <div class="answer-review right-answer">
        <span>Bonne réponse</span>
        <strong>${escapeNotebookHtml(item.correctAnswer)}</strong>
      </div>
      ${item.explanation ? `
        <div class="correction-note">
          <strong>Explication</strong>
          <p>${escapeNotebookHtml(item.explanation)}</p>
        </div>` : ""}
      <p class="small">Niveau actuel estimé : ${Number(item.masteryScore)} % · ${Number(item.evidenceCount)} réponses prises en compte</p>
      ${item.resolved ? "" : `
        <a class="btn btn-secondary" href="remediation.html?skill=${encodeURIComponent(item.competenceId)}&minutes=5">
          Travailler cette compétence
        </a>`}
    </article>`).join("");
}

document.getElementById("currentErrorsButton").addEventListener("click", () => {
  showResolved = false;
  renderNotebook();
});

document.getElementById("resolvedErrorsButton").addEventListener("click", () => {
  showResolved = true;
  renderNotebook();
});

CapCollegeSupabase.bootstrap({ requireAuth: true })
  .then(async () => {
    notebookItems = await CapCollegeSupabase.getErrorNotebook();
    renderNotebook();
  })
  .catch(CapCollegeSupabase.showFatalError);

