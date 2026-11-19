// Language + theme toggles, catalog filter and search. No dependencies.
(function () {
  var root = document.documentElement;
  function store(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  function setLang(l) {
    root.setAttribute("data-lang", l);
    root.lang = l;
    root.dir = l === "en" ? "ltr" : "rtl";
    store("ab-lang", l);
  }
  document.querySelectorAll("[data-toggle-lang]").forEach(function (b) {
    b.addEventListener("click", function () { setLang(root.getAttribute("data-lang") === "en" ? "ar" : "en"); });
  });
  document.querySelectorAll("[data-toggle-theme]").forEach(function (b) {
    b.addEventListener("click", function () {
      var cur = root.getAttribute("data-theme") || (matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark");
      var next = cur === "light" ? "dark" : "light";
      root.setAttribute("data-theme", next);
      store("ab-theme", next);
    });
  });

  var pills = document.querySelectorAll("[data-filter]");
  var search = document.querySelector("[data-search]");
  var active = "all";
  function apply() {
    var q = (search && search.value || "").trim().toLowerCase();
    document.querySelectorAll("[data-group]").forEach(function (g) {
      var shown = 0;
      g.querySelectorAll(".card").forEach(function (c) {
        var ok = (active === "all" || c.dataset.cat === active) && (!q || c.textContent.toLowerCase().indexOf(q) !== -1);
        c.classList.toggle("is-hidden", !ok);
        if (ok) shown++;
      });
      g.classList.toggle("is-hidden", shown === 0);
    });
  }
  pills.forEach(function (p) {
    p.addEventListener("click", function () {
      active = p.dataset.filter;
      pills.forEach(function (x) { x.classList.toggle("is-on", x === p); x.setAttribute("aria-pressed", String(x === p)); });
      apply();
    });
  });
  if (search) search.addEventListener("input", apply);
})();
