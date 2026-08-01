const form = document.getElementById("learnerLoginForm");
const codeInput = document.getElementById("accessCode");
const pinInput = document.getElementById("learnerLoginPin");
const button = document.getElementById("learnerLoginButton");
const message = document.getElementById("learnerLoginMessage");

function formatAccessCode(value) {
  return String(value || "").toUpperCase().replace(/[^A-F0-9]/g, "")
    .slice(0, 12).replace(/(.{4})(?=.)/g, "$1-");
}
codeInput.addEventListener("input", () => {
  codeInput.value = formatAccessCode(codeInput.value);
});
form.addEventListener("submit", async event => {
  event.preventDefault();
  message.classList.add("hidden");
  button.disabled = true;
  button.textContent = "Connexion…";
  try {
    await CapCollegeSupabase.openLearnerSession(
      codeInput.value, pinInput.value
    );
    location.replace("espace-enfant.html");
  } catch (error) {
    message.textContent = error.message || "Connexion impossible.";
    message.classList.remove("hidden");
  } finally {
    button.disabled = false;
    button.textContent = "Me connecter";
  }
});
CapCollegeSupabase.getLearnerSession()
  .then(profile => {
    if (profile) location.replace("espace-enfant.html");
  })
  .catch(() => {});