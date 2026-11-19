// dash.albushra.app — operational view of the Application Registry.
// Reads /dash/registry.json (built from registry/apps.json), then checks each
// app live from the browser: reachability + latency of its public URL, and
// its version.source for the newest published version.
(function () {
  var root = document.documentElement;
  var L = function () { return root.getAttribute("data-lang") === "en" ? "en" : "ar"; };
  var tx = function (o) { return o && typeof o === "object" ? o[L()] || o.ar || o.en || "" : o || ""; };
  var esc = function (s) { return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]; }); };
  var T = {
    apps: { ar: "تطبيقات", en: "Apps" }, live: { ar: "منشورة", en: "Live" }, up: { ar: "تستجيب الآن", en: "Responding now" },
    sub: { ar: "على نطاقات فرعية", en: "On subdomains" }, all: { ar: "الكل", en: "All" },
    open: { ar: "فتح", en: "Open" }, page: { ar: "صفحة التطبيق", en: "App page" }, admin: { ar: "الإدارة", en: "Admin" }, testing: { ar: "اختبار Play", en: "Play testing" },
    repo: { ar: "المستودع", en: "Repository" }, host: { ar: "الاستضافة", en: "Hosting" }, origin: { ar: "المصدر الأصلي", en: "Origin" },
    backend: { ar: "الخلفية", en: "Backend" }, env: { ar: "متغيرات البيئة (أسماء فقط)", en: "Env vars (names only)" },
    version: { ar: "الإصدار", en: "Version" }, route: { ar: "الربط", en: "Routing" }, notes: { ar: "ملاحظات", en: "Notes" },
    checking: { ar: "يفحص…", en: "checking…" }, down: { ar: "لا يستجيب", en: "Not responding" }, ok: { ar: "يعمل", en: "Up" },
    gen: { ar: "آخر بناء للسجل:", en: "Registry built:" }, newer: { ar: "إصدار أحدث منشور:", en: "Newer release published:" },
    shown: { ar: "ظاهر في albushra.app", en: "Shown on albushra.app" }, hiddenPub: { ar: "مخفي عن العامة", en: "Hidden from public" },
    hideIt: { ar: "إخفاء من الموقع العام", en: "Hide from the public site" }, showIt: { ar: "إظهار في الموقع العام", en: "Show on the public site" },
    visErr: { ar: "تعذّر حفظ الإظهار/الإخفاء", en: "Could not save visibility" }, visOff: { ar: "التحكم بالإظهار غير متاح", en: "Visibility control unavailable" },
  };
  var STATUS = { live: { ar: "منشور", en: "Live" }, beta: { ar: "تجريبي", en: "Beta" }, prototype: { ar: "نموذج أولي", en: "Prototype" }, soon: { ar: "قريبًا", en: "Soon" }, archived: { ar: "مؤرشف", en: "Archived" }, hidden: { ar: "مخفي", en: "Hidden" } };

  var data = null, filter = "all", health = {}, liveVer = {};
  // Public visibility, stored by the router (Workers KV). null = not loaded / unavailable.
  var vis = null, visBusy = {};

  function load() {
    fetch("/dash/registry.json", { cache: "no-store" }).then(function (r) { return r.json(); }).then(function (d) {
      data = d; render(); probeAll();
    }).catch(function () { document.getElementById("list").textContent = "registry.json unavailable"; });
    fetch("/__admin/visibility", { cache: "no-store", credentials: "same-origin" }).then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) { vis = j && j.ok ? j.hidden : null; render(); }).catch(function () { vis = null; render(); });
  }

  function setVisible(id, hide) {
    visBusy[id] = true; render();
    fetch("/__admin/visibility", {
      method: "POST", credentials: "same-origin", cache: "no-store",
      headers: { "content-type": "application/json", "x-albushra-admin": "1" },
      body: JSON.stringify({ id: id, hidden: hide }),
    }).then(function (r) { return r.json(); }).then(function (j) {
      if (!j || !j.ok) throw new Error(j && j.error);
      vis = j.hidden;
    }).catch(function () { alert(tx(T.visErr)); }).finally(function () { delete visBusy[id]; render(); });
  }

  function visControl(a) {
    if (a.status === "hidden") return "";
    if (!vis) return '<p class="vis-off small muted">' + esc(tx(T.visOff)) + "</p>";
    var isHidden = vis.indexOf(a.id) !== -1;
    return '<div class="vis' + (isHidden ? " is-hidden" : "") + '"><span class="vis-state">' +
      '<span class="dot ' + (isHidden ? "down" : "up") + '"></span>' + esc(tx(isHidden ? T.hiddenPub : T.shown)) + "</span>" +
      '<button type="button" class="btn btn-alt vis-btn" data-vis="' + esc(a.id) + '" data-hide="' + (isHidden ? "0" : "1") + '"' + (visBusy[a.id] ? " disabled" : "") +
      ' aria-pressed="' + isHidden + '">' + esc(tx(isHidden ? T.showIt : T.hideIt)) + "</button></div>";
  }

  function probe(app) {
    var url = app.url;
    if (!url || url === "#") return;
    health[app.id] = { state: "checking" };
    var t0 = performance.now();
    var ctrl = new AbortController();
    var timer = setTimeout(function () { ctrl.abort(); }, 12000);
    // no-cors: we only learn that the host answered, which is what we want.
    fetch(url, { mode: "no-cors", cache: "no-store", signal: ctrl.signal }).then(function () {
      health[app.id] = { state: "up", ms: Math.round(performance.now() - t0) };
    }).catch(function () { health[app.id] = { state: "down" }; }).finally(function () { clearTimeout(timer); render(); });

    var v = app.version || {};
    if (v.source) {
      fetch(v.source, { cache: "no-store" }).then(function (r) { return r.json(); }).then(function (j) {
        var val = (v.field || "version").split(".").reduce(function (o, k) { return o == null ? o : o[k]; }, j);
        if (val) { liveVer[app.id] = String(val); render(); }
      }).catch(function () {});
    }
  }
  function probeAll() { data.apps.forEach(probe); render(); }

  function kpis() {
    var apps = data.apps.filter(function (a) { return a.status !== "hidden"; });
    var up = apps.filter(function (a) { return (health[a.id] || {}).state === "up"; }).length;
    var items = [
      [apps.length, T.apps], [apps.filter(function (a) { return a.status === "live" || a.status === "beta"; }).length, T.live],
      [up, T.up], [apps.filter(function (a) { return a.subdomain; }).length, T.sub],
    ];
    document.getElementById("kpis").innerHTML = items.map(function (k) { return '<div class="stat"><b>' + k[0] + "</b><span>" + esc(tx(k[1])) + "</span></div>"; }).join("");
  }

  function filters() {
    var cats = data.categories.filter(function (c) { return data.apps.some(function (a) { return a.category === c.id; }); });
    var el = document.getElementById("filters");
    el.innerHTML = [{ id: "all", name: T.all }].concat(cats).map(function (c) {
      return '<button class="pill' + (filter === c.id ? " is-on" : "") + '" data-f="' + esc(c.id) + '" aria-pressed="' + (filter === c.id) + '">' + esc(tx(c.name)) + "</button>";
    }).join("");
    el.querySelectorAll("[data-f]").forEach(function (b) { b.onclick = function () { filter = b.dataset.f; render(); }; });
  }

  function row(a) {
    var h = health[a.id] || {};
    var hs = h.state === "up" ? '<span class="dot up"></span>' + esc(tx(T.ok)) + (h.ms ? ' <span class="mono">' + h.ms + "ms</span>" : "")
      : h.state === "down" ? '<span class="dot down"></span>' + esc(tx(T.down)) : '<span class="dot"></span>' + esc(tx(T.checking));
    var built = a.resolvedVersion && a.resolvedVersion.value;
    var lv = liveVer[a.id];
    var ver = lv || built || (a.version && a.version.current) || "—";
    var newer = lv && built && lv !== built ? '<div class="warn small">' + esc(tx(T.newer)) + " " + esc(lv) + "</div>" : "";
    var host = a.hosting || {};
    var links = [
      a.url && a.url !== "#" ? '<a class="btn" href="' + esc(a.url) + '" target="_blank" rel="noopener">' + esc(tx(T.open)) + "</a>" : "",
      '<a class="btn btn-alt" href="https://albushra.app/apps/' + esc(a.id) + '/" target="_blank" rel="noopener">' + esc(tx(T.page)) + "</a>",
      a.links && a.links.testing ? '<a class="btn btn-alt" href="' + esc(a.links.testing) + '" target="_blank" rel="noopener">' + esc(tx(T.testing)) + "</a>" : "",
      a.links && a.links.admin ? '<a class="btn btn-alt" href="' + esc(a.links.admin) + '" target="_blank" rel="noopener">' + esc(tx(T.admin)) + "</a>" : "",
      host.repo ? '<a class="btn btn-alt" href="https://github.com/' + esc(host.repo) + '" target="_blank" rel="noopener">' + esc(tx(T.repo)) + "</a>" : "",
    ].concat((host.consoles || []).map(function (c) { return '<a class="btn btn-alt" href="' + esc(c.url) + '" target="_blank" rel="noopener">' + esc(c.label) + "</a>"; })).join("");
    var r = a.route || {};
    return '<article class="dash-row" style="--accent:' + esc(a.color || "#3b82f6") + '">' +
      '<div class="dr-head"><img class="app-icon" src="' + (a.icon ? "/icons/" + esc(a.icon) : "/brand/mark-192.png") + '" width="48" height="48" alt="">' +
      "<div><h3>" + esc(tx(a.name)) + '</h3><div class="card-meta"><span class="badge s-' + esc(a.status) + '">' + esc(tx(STATUS[a.status] || STATUS.live)) + '</span><span class="chip mono">' + esc(a.subdomain ? a.subdomain + "." + data.apex : "—") + "</span></div></div>" +
      '<div class="health">' + hs + "</div></div>" + visControl(a) +
      '<dl class="dr-facts">' +
      "<dt>" + esc(tx(T.version)) + '</dt><dd class="mono">' + esc(ver) + newer + "</dd>" +
      "<dt>" + esc(tx(T.host)) + "</dt><dd>" + esc(host.provider || "—") + "</dd>" +
      "<dt>" + esc(tx(T.route)) + '</dt><dd class="mono small">' + esc(r.mode || "—") + (r.target ? " → " + esc(r.target) : "") + "</dd>" +
      "<dt>" + esc(tx(T.backend)) + "</dt><dd>" + esc(a.backend || "—") + "</dd>" +
      (a.envVars && a.envVars.length ? "<dt>" + esc(tx(T.env)) + '</dt><dd class="mono small">' + a.envVars.map(esc).join(" · ") + "</dd>" : "") +
      (a.notes ? "<dt>" + esc(tx(T.notes)) + "</dt><dd class=\"small\">" + esc(tx(a.notes)) + "</dd>" : "") +
      "</dl><div class=\"cta\">" + links + "</div></article>";
  }

  function render() {
    if (!data) return;
    kpis(); filters();
    var q = (document.getElementById("q").value || "").trim().toLowerCase();
    var list = data.apps.filter(function (a) {
      return (filter === "all" || a.category === filter) &&
        (!q || JSON.stringify([a.name, a.subdomain, a.id]).toLowerCase().indexOf(q) !== -1);
    });
    var listEl = document.getElementById("list");
    listEl.innerHTML = list.map(row).join("");
    listEl.querySelectorAll("[data-vis]").forEach(function (b) {
      b.onclick = function () { setVisible(b.dataset.vis, b.dataset.hide === "1"); };
    });
    document.getElementById("gen").textContent = tx(T.gen) + " " + new Date(data.generated).toLocaleString(L() === "ar" ? "ar" : "en");
  }

  document.getElementById("q").addEventListener("input", render);
  document.getElementById("refresh").addEventListener("click", function () { if (data) probeAll(); });
  new MutationObserver(render).observe(root, { attributes: true, attributeFilter: ["data-lang"] });
  load();
})();
