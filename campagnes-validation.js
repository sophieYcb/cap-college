let validationCampaigns = [];

function campaignEscape(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function campaignStatus(message, error = false) {
  const target = document.getElementById("campaignStatus");
  target.textContent = message;
  target.classList.toggle("save-error", error);
}

function renderCampaigns() {
  const list = document.getElementById("campaignList");
  if (!validationCampaigns.length) {
    list.innerHTML = "<p>Aucune campagne. Crée ton premier scénario de validation.</p>";
    return;
  }
  list.innerHTML = validationCampaigns.map((campaign) => `
    <article class="campaign-card ${campaign.status === "archived" ? "campaign-archived" : ""}">
      <div class="result-head">
        <div>
          <span class="small">${campaign.status === "active" ? "Campagne active" : "Campagne archivée"}</span>
          <h3>${campaignEscape(campaign.name)}</h3>
        </div>
        <span class="badge">${Number(campaign.answers)} réponse${Number(campaign.answers) > 1 ? "s" : ""}</span>
      </div>
      ${campaign.description ? `<p>${campaignEscape(campaign.description)}</p>` : ""}
      <p class="small">${Number(campaign.sessions)} séance${Number(campaign.sessions) > 1 ? "s" : ""} · ${Number(campaign.correctAnswers)} bonne${Number(campaign.correctAnswers) > 1 ? "s" : ""} réponse${Number(campaign.correctAnswers) > 1 ? "s" : ""}</p>
      <div class="actions">
        ${campaign.status === "active" ? `
          <button class="btn btn-primary" onclick="chooseCampaign('${campaign.id}')">Utiliser cette campagne</button>
          <button class="btn btn-secondary" onclick="resetCampaign('${campaign.id}')">Réinitialiser</button>
          <button class="btn btn-secondary" onclick="archiveCampaign('${campaign.id}')">Archiver</button>` : ""}
        <button class="btn btn-secondary" onclick="deleteCampaign('${campaign.id}')">Supprimer</button>
      </div>
    </article>`).join("");
}

async function reloadCampaigns() {
  validationCampaigns = await CapCollegeSupabase.getValidationCampaigns();
  renderCampaigns();
}

document.getElementById("campaignForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const submitButton = event.submitter;
  if (submitButton) submitButton.disabled = true;
  campaignStatus("Création…");
  try {
    await CapCollegeSupabase.createValidationCampaign(
      document.getElementById("campaignName").value,
      document.getElementById("campaignDescription").value
    );
    event.target.reset();
    await reloadCampaigns();
    campaignStatus("Campagne créée.");
  } catch (error) {
    campaignStatus(`Création impossible : ${error.message}`, true);
  } finally {
    if (submitButton) submitButton.disabled = false;
  }
});

async function resetCampaign(id) {
  if (!confirm("Effacer toutes les réponses de cette campagne ?")) return;
  await CapCollegeSupabase.resetValidationCampaign(id);
  await reloadCampaigns();
}

async function archiveCampaign(id) {
  if (!confirm("Archiver cette campagne ?")) return;
  await CapCollegeSupabase.archiveValidationCampaign(id);
  await reloadCampaigns();
}

async function deleteCampaign(id) {
  if (!confirm("Supprimer définitivement cette campagne et ses réponses ?")) return;
  await CapCollegeSupabase.deleteValidationCampaign(id);
  await reloadCampaigns();
}

function chooseCampaign(id) {
  const campaign = validationCampaigns.find((item) => item.id === id);
  sessionStorage.setItem("capCollegeValidationCampaignId", id);
  sessionStorage.setItem(
    "capCollegeValidationCampaignName",
    campaign?.name || "Campagne de validation"
  );
  location.href = `evaluation.html?validationCampaign=${encodeURIComponent(id)}&v=5313`;
}

CapCollegeSupabase.bootstrap({ requiredRoles: ["validator", "administrator"] })
  .then(reloadCampaigns)
  .catch(CapCollegeSupabase.showFatalError);
