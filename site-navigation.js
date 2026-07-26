(function () {
  const page = location.pathname.split("/").pop() || "index.html";
  if (page === "index.html") return;

  const validationMode =
    page === "evaluation.html" &&
    new URLSearchParams(location.search).has("validationCampaign");

  const routes = {
    "login.html": {
      parent: "index.html",
      crumbs: [["index.html", "Accueil"], [null, "Connexion"]]
    },
    "evaluation.html": validationMode
      ? {
          parent: "campagnes-validation.html",
          crumbs: [
            ["index.html", "Accueil"],
            ["campagnes-validation.html", "Campagnes de validation"],
            [null, "Diagnostic de validation"]
          ]
        }
      : {
          parent: "index.html",
          crumbs: [["index.html", "Accueil"], [null, "Diagnostic"]]
        },
    "resultats.html": {
      parent: "evaluation.html",
      crumbs: [
        ["index.html", "Accueil"],
        ["evaluation.html", "Diagnostic"],
        [null, "Bilan"]
      ]
    },
    "remediation.html": {
      parent: "resultats.html",
      crumbs: [
        ["index.html", "Accueil"],
        ["resultats.html", "Bilan"],
        [null, "Remise à niveau"]
      ]
    },
    "carnet-erreurs.html": {
      parent: "index.html",
      crumbs: [["index.html", "Accueil"], [null, "Carnet d’erreurs"]]
    },
    "campagnes-validation.html": {
      parent: "index.html",
      crumbs: [
        ["index.html", "Accueil"],
        [null, "Campagnes de validation"]
      ]
    },
    "test.html": {
      parent: "campagnes-validation.html",
      crumbs: [
        ["index.html", "Accueil"],
        ["campagnes-validation.html", "Campagnes de validation"],
        [null, "Validation des questions"]
      ]
    },
    "importer-contenus.html": {
      parent: "test.html",
      crumbs: [
        ["index.html", "Accueil"],
        ["test.html", "Validation des questions"],
        [null, "Importer des contenus"]
      ]
    }
  };

  const route = routes[page];
  const main = document.querySelector("main");
  if (!route || !main) return;

  const escapeHtml = value =>
    String(value).replace(/[&<>'"]/g, character => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      "'": "&#39;",
      '"': "&quot;"
    })[character]);

  const breadcrumbs = route.crumbs.map(([href, label], index) => {
    const current = index === route.crumbs.length - 1;
    const content = href && !current
      ? `<a href="${escapeHtml(href)}">${escapeHtml(label)}</a>`
      : `<span${current ? ' aria-current="page"' : ""}>${escapeHtml(label)}</span>`;
    return `${index ? '<span class="breadcrumb-separator" aria-hidden="true">›</span>' : ""}${content}`;
  }).join("");

  const navigation = document.createElement("div");
  navigation.className = "page-navigation";
  navigation.innerHTML = `
    <nav class="breadcrumbs" aria-label="Fil d’Ariane">${breadcrumbs}</nav>
    <div class="page-navigation-actions">
      <button class="nav-button" type="button" id="sharedBackButton">← Retour</button>
      <a class="nav-button" href="index.html">⌂ Accueil</a>
    </div>
  `;

  const header = main.querySelector(":scope > .topbar");
  if (header) header.insertAdjacentElement("afterend", navigation);
  else main.insertAdjacentElement("afterbegin", navigation);

  navigation.querySelector("#sharedBackButton").addEventListener("click", () => {
    const referrer = document.referrer;
    if (history.length > 1 && referrer && new URL(referrer).origin === location.origin) {
      history.back();
    } else {
      location.href = route.parent;
    }
  });
})();
