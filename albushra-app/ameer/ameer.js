// ameer.albushra.app client. Reads /api/state (owner-only, see worker/ameer.js)
// and renders: Claude's work (sessions, commits, PRs, log), repositories, CI,
// sites, computers, notes. No secrets ever reach this page.
(function () {
  "use strict";
  var root = document.documentElement;
  var $ = function (id) { return document.getElementById(id); };
  var lang = "ar";
  try { if (localStorage.getItem("ameer-lang") === "en") lang = "en"; } catch (e) {}
  var state = null, view = "overview", tlFilter = "all", wx = null;

  var T = {
    repos: ["المستودعات", "Repositories"], pipelines: ["مسارات النشر", "Pipelines"], metrics: ["المؤشرات", "Metrics"],
    sessions: ["جلسات Claude", "Claude sessions"], timeline: ["كل ما أنجزه Claude", "Everything Claude did"],
    sites: ["التطبيقات والمواقع", "Apps & sites"], devices: ["أجهزتي", "My devices"], notes: ["ملاحظاتي", "My notes"],
    add: ["أضف", "Add"], overview: ["نظرة عامة", "Overview"], claude: ["Claude", "Claude"], apps: ["التطبيقات", "Apps"],
    devicesTab: ["الأجهزة", "Devices"], notesTab: ["ملاحظات", "Notes"],
    morning: ["صباح الخير يا أمير", "Good morning, Ameer"], evening: ["مساء الخير يا أمير", "Good evening, Ameer"],
    appsUp: ["التطبيقات", "Apps"], ci: ["النشر", "CI"], devs: ["الأجهزة", "Devices"], claude7: ["Claude ٧ أيام", "Claude 7d"],
    nowWorking: ["آخر ما يعمل عليه Claude", "Claude is working on"], security: ["الأمان", "Security"],
    computer: ["الحاسوب", "Computer"], cloud: ["السحابة", "Cloud"],
    access: ["دخول Cloudflare", "Cloudflare login"], owner: ["الحساب", "Account"], locked: ["مقفل", "Locked"],
    fresh: ["آخر مزامنة", "Last sync"], ghToken: ["رمز GitHub", "GitHub token"], ok: ["سليم", "OK"],
    noData: ["لا توجد بيانات بعد. شغّل سير العمل «ameer» من GitHub Actions.", "No data yet. Run the “ameer” workflow in GitHub Actions."],
    stale: ["البيانات قديمة: آخر مزامنة منذ", "Data is stale: last sync"], commits: ["إيداعات", "commits"],
    commitsToday: ["إيداعات اليوم", "Commits today"], commits7: ["إيداعات ٧ أيام", "Commits 7d"], claudeShare: ["نصيب Claude", "Claude share"],
    openPRs: ["طلبات دمج مفتوحة", "Open PRs"], merged30: ["دُمج في ٣٠ يومًا", "Merged 30d"], latency: ["متوسط الاستجابة", "Avg latency"],
    failing: ["فاشل", "Failing"], passing: ["ناجح", "Passing"], running: ["قيد التشغيل", "Running"], queued: ["بالانتظار", "Queued"],
    cancelled: ["أُلغي", "Cancelled"], skipped: ["تُخطّي", "Skipped"], up: ["يعمل", "Up"], down: ["متوقف", "Down"],
    online: ["متصل", "Online"], offline: ["غير متصل", "Offline"], noDevices: ["لا يوجد جهاز متصل بعد. اتبع الخطوات بالأسفل.", "No device yet. Follow the steps below."],
    cpu: ["المعالج", "CPU"], mem: ["الذاكرة", "Memory"], disk: ["القرص", "Disk"], uptime: ["يعمل منذ", "Uptime"], battery: ["البطارية", "Battery"],
    lastSeen: ["آخر ظهور", "Last seen"], remove: ["حذف", "Remove"], open: ["فتح", "Open"], session: ["الجلسة", "Session"],
    all: ["الكل", "All"], onlyClaude: ["Claude فقط", "Claude only"], prs: ["طلبات الدمج", "Pull requests"], log: ["السجل", "Log"],
    noNotes: ["لا توجد ملاحظات.", "No notes."], notePh: ["اكتب مهمة أو ملاحظة…", "Write a task or note…"],
    branch: ["الفرع", "Branch"], private: ["خاص", "Private"], public: ["عام", "Public"], lastPush: ["آخر دفع", "Last push"],
    noSessions: ["لم تُرصد جلسات بعد.", "No sessions detected yet."], merged: ["دُمج", "Merged"], openS: ["مفتوح", "Open"], closed: ["مغلق", "Closed"],
    deviceOf: ["جهاز", "device"], hours: ["ساعة", "h"], router: ["الموجّه", "Router"], hub: ["الموقع الرئيسي", "Main site"],
    sitesUp: ["المواقع تعمل", "Sites up"], weather: ["الطقس", "Weather"], loadErr: ["تعذّر تحميل البيانات", "Could not load data"],
    setupTitle: ["ربط الكمبيوتر باللوحة", "Connect a computer"],
  };
  function t(k) { var v = T[k]; return v ? v[lang === "en" ? 1 : 0] : k; }
  function esc(s) { return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]; }); }
  function n(x) { return x == null || isNaN(x) ? "–" : Number(x).toLocaleString(lang === "en" ? "en-US" : "ar-EG"); }
  function ago(iso) {
    if (!iso) return "–";
    var s = (Date.now() - new Date(iso).getTime()) / 1000;
    try {
      var rtf = new Intl.RelativeTimeFormat(lang === "en" ? "en" : "ar", { numeric: "auto" });
      if (s < 60) return rtf.format(-Math.round(s), "second");
      if (s < 3600) return rtf.format(-Math.round(s / 60), "minute");
      if (s < 86400) return rtf.format(-Math.round(s / 3600), "hour");
      return rtf.format(-Math.round(s / 86400), "day");
    } catch (e) { return new Date(iso).toLocaleString(); }
  }

  // ---------- icons (inline SVG paths, 24x24) ----------
  var I = {
    repo: "M4 4a2 2 0 0 1 2-2h12v16H6a1 1 0 0 0 0 2h12v2H6a3 3 0 0 1-3-3V4zm4 2v2h7V6H8z",
    play: "M8 5v14l11-7z", pause: "M6 5h4v14H6zm8 0h4v14h-4z",
    lock: "M12 2a5 5 0 0 0-5 5v3H5v12h14V10h-2V7a5 5 0 0 0-5-5zm-3 8V7a3 3 0 0 1 6 0v3z",
    user: "M12 12a5 5 0 1 0 0-10 5 5 0 0 0 0 10zm0 2c-4 0-8 2-8 5v3h16v-3c0-3-4-5-8-5z",
    sync: "M17.65 6.35A8 8 0 1 0 19.73 14h-2.08A6 6 0 1 1 12 6c1.66 0 3.14.69 4.22 1.78L13 11h7V4z",
    key: "M7 14a3 3 0 1 1 0-6 3 3 0 0 1 0 6zm5.6-4A6 6 0 1 0 12.6 14H15v3h3v-3h3v-4z",
    pc: "M3 4h18v12H3zm6 14h6v2H9z", cloud: "M19 18H7a5 5 0 1 1 1-9.9A6 6 0 0 1 19.5 10 4 4 0 0 1 19 18z",
    check: "M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z", x: "M18.3 5.7 12 12l6.3 6.3-1.4 1.4L10.6 13.4 4.3 19.7 2.9 18.3 9.2 12 2.9 5.7 4.3 4.3l6.3 6.3 6.3-6.3z",
    bolt: "M13 2 3 14h7l-1 8 10-12h-7z", clock: "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm1 5h-2v6l5 3 1-1.7-4-2.3z",
    commit: "M12 7a5 5 0 0 1 4.9 4H22v2h-5.1a5 5 0 0 1-9.8 0H2v-2h5.1A5 5 0 0 1 12 7zm0 2a3 3 0 1 0 0 6 3 3 0 0 0 0-6z",
    pr: "M6 3a3 3 0 0 1 1 5.8v6.4A3 3 0 1 1 5 15.2V8.8A3 3 0 0 1 6 3zm12 12.2V9a2 2 0 0 0-2-2h-2v3L9 6l5-4v3h2a4 4 0 0 1 4 4v6.2a3 3 0 1 1-2 0z",
    spark: "M12 2l2.4 6.6L21 11l-6.6 2.4L12 20l-2.4-6.6L3 11l6.6-2.4z", globe: "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm6.9 6h-3a15 15 0 0 0-1.4-3.9A8 8 0 0 1 18.9 8zM12 4c.8 1.2 1.5 2.5 1.9 4h-3.8c.4-1.5 1.1-2.8 1.9-4zM4.3 14a8 8 0 0 1 0-4h3.4a16 16 0 0 0 0 4zm.8 2h3a15 15 0 0 0 1.4 3.9A8 8 0 0 1 5.1 16zm3-8h-3a8 8 0 0 1 4.4-3.9A15 15 0 0 0 8.1 8zM12 20c-.8-1.2-1.5-2.5-1.9-4h3.8c-.4 1.5-1.1 2.8-1.9 4zm2.3-6H9.7a14 14 0 0 1 0-4h4.6a14 14 0 0 1 0 4zm.3 5.9a15 15 0 0 0 1.4-3.9h3a8 8 0 0 1-4.4 3.9zm1.7-5.9a16 16 0 0 0 0-4h3.4a8 8 0 0 1 0 4z",
    grid: "M3 3h8v8H3zm10 0h8v8h-8zM3 13h8v8H3zm10 0h8v8h-8z", note: "M5 3h10l4 4v14H5zm9 1.5V8h3.5zM8 12h8v2H8zm0 4h8v2H8z",
    home: "M12 3 2 12h3v9h6v-6h2v6h6v-9h3z", log: "M4 5h16v2H4zm0 6h16v2H4zm0 6h10v2H4z", gauge: "M12 4a10 10 0 0 0-8.7 15h17.4A10 10 0 0 0 12 4zm1 10.7a2 2 0 1 1-2-3.4L16 7z",
    sun: "M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10zm0-5 1.5 3h-3zm0 20-1.5-3h3zM2 12l3-1.5v3zm20 0-3 1.5v-3z",
  };
  function ic(name) { return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="' + I[name] + '"/></svg>'; }
  var PAL = ["#ff4d6d", "#3ddc84", "#5b7cff", "#9b6bff", "#ff9f1c", "#22d3ee", "#facc15", "#f472b6"];
  function color(s) { var h = 0; s = String(s || ""); for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0; return PAL[h % PAL.length]; }

  // ---------- data ----------
  function load() {
    $("refresh").classList.add("spin");
    fetch("/api/state", { cache: "no-store", credentials: "same-origin" })
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (j) { state = j; render(); })
      .catch(function () { banner(t("loadErr")); })
      .finally(function () { $("refresh").classList.remove("spin"); });
  }
  function post(path, body, method) {
    return fetch(path, { method: method || "POST", credentials: "same-origin", headers: { "content-type": "application/json", "x-ameer": "1" }, body: body ? JSON.stringify(body) : undefined })
      .then(function (r) { return r.json(); });
  }
  function banner(msg) { var b = $("banner"); b.hidden = !msg; b.textContent = msg || ""; }

  function snap() { return (state && state.snapshot) || {}; }
  function gh() { return snap().github || {}; }
  function commits() { return gh().commits || []; }
  function within(iso, days) { return iso && Date.now() - new Date(iso).getTime() < days * 864e5; }
  function devicesOnline() {
    return ((state && state.devices) || []).filter(function (d) { return Date.now() - new Date(d.seen).getTime() < (d.every || 5) * 3 * 60e3; });
  }
  function runState(r) {
    if (!r) return { k: "skipped", c: "var(--mut)", i: "clock" };
    if (r.status && r.status !== "completed") return r.status === "queued" ? { k: "queued", c: "var(--orange)", i: "clock" } : { k: "running", c: "var(--blue)", i: "sync" };
    if (r.conclusion === "success") return { k: "passing", c: "var(--green)", i: "check" };
    if (r.conclusion === "failure" || r.conclusion === "timed_out" || r.conclusion === "startup_failure") return { k: "failing", c: "var(--red)", i: "x" };
    if (r.conclusion === "cancelled") return { k: "cancelled", c: "var(--orange)", i: "x" };
    return { k: "skipped", c: "var(--mut)", i: "clock" };
  }

  // ---------- header ----------
  function tick() {
    var d = new Date();
    $("time").textContent = d.toLocaleTimeString(lang === "en" ? "en-GB" : "ar-EG", { hour: "2-digit", minute: "2-digit", hour12: false });
    $("date").textContent = d.toLocaleDateString(lang === "en" ? "en-GB" : "ar-EG", { weekday: "long", day: "numeric", month: "long" });
    $("greet").textContent = t(d.getHours() < 12 ? "morning" : "evening");
  }
  function pills() {
    var sites = snap().sites || [];
    var up = sites.filter(function (s) { return s.ok; }).length;
    var runs = latestRuns();
    var bad = runs.filter(function (r) { return runState(r).k === "failing"; }).length;
    var c7 = commits().filter(function (c) { return c.claude && within(c.at, 7); }).length;
    var devs = devicesOnline().length;
    var h = "";
    if (wx) h += '<span class="pill wx">' + ic("sun").replace("<svg", '<svg width="18" height="18" style="fill:#facc15"') + '<span class="t num">' + Math.round(wx.temp) + "°</span><span class=\"muted\">" + esc(wx.label) + "</span></span>";
    h += pill(sites.length ? (up === sites.length ? "ok" : up >= sites.length * 0.8 ? "warn" : "bad") : "", t("appsUp"), sites.length ? n(up) + "/" + n(sites.length) : "–");
    h += pill(runs.length ? (bad ? "bad" : "ok") : "", t("ci"), runs.length ? (bad ? n(bad) + " " + t("failing") : t("ok")) : "–");
    h += pill(c7 ? "ok" : "", t("claude7"), n(c7));
    h += pill(devs ? "ok" : "", t("devs"), n(devs));
    $("pills").innerHTML = h;
  }
  function pill(cls, label, val) { return '<span class="pill"><span class="dot ' + cls + '"></span>' + esc(label) + " <b class=\"num\">" + esc(val) + "</b></span>"; }

  // ---------- overview ----------
  function latestRuns() {
    var out = [];
    (gh().repos || []).forEach(function (r) { (r.runs || []).forEach(function (x) { out.push(Object.assign({ repo: r.name }, x)); }); });
    // newest run per (repo, workflow)
    var seen = {}, res = [];
    out.sort(function (a, b) { return new Date(b.at) - new Date(a.at); }).forEach(function (x) { var k = x.repo + "|" + x.name; if (!seen[k]) { seen[k] = 1; res.push(x); } });
    return res;
  }
  function hero() {
    var s = gh().sessions || [];
    var cur = s[0];
    var lastLog = (state.log || [])[0];
    var h = '<article class="card glow now"><div class="kicker"><span class="dot ' + (cur && within(cur.last, 1 / 12) ? "bad" : "") + '"></span>' + t("nowWorking") + "</div>";
    if (cur || lastLog) {
      var title = cur ? cur.title : lastLog.title;
      var sub = cur ? cur.repos.join(" · ") : lastLog.repo;
      var at = cur ? cur.last : lastLog.at;
      var pct = cur ? Math.min(100, Math.round((cur.commits / Math.max(1, s.reduce(function (m, x) { return Math.max(m, x.commits); }, 1))) * 100)) : 100;
      h += "<h3>" + esc(title) + '</h3><div class="sub">' + esc(sub || "") + "</div>";
      h += '<div class="meta"><span class="chip red">' + ic("commit").replace("<svg", '<svg width="12" height="12" style="fill:currentColor"') + n(cur ? cur.commits : 1) + " " + t("commits") + "</span><span>" + esc(ago(at)) + "</span></div>";
      h += '<div class="bar"><a class="round" href="https://claude.ai/code" target="_blank" rel="noopener" aria-label="Claude">' + ic("spark") + "</a>";
      h += '<a class="round solid" ' + (cur && cur.url ? 'href="' + esc(cur.url) + '" target="_blank" rel="noopener"' : "") + ' aria-label="' + t("session") + '">' + ic(cur && within(cur.last, 1 / 12) ? "pause" : "play") + "</a>";
      h += '<span class="track"><i style="width:' + pct + '%"></i></span><span class="num muted" style="font-size:11px">' + esc(cur && cur.first ? new Date(cur.first).toLocaleDateString(lang === "en" ? "en-GB" : "ar-EG", { day: "numeric", month: "short" }) : "") + "</span></div>";
    } else h += '<p class="muted">' + esc(t("noData")) + "</p>";
    h += "</article>";

    // security
    var rec = snap().receivedAt;
    var fresh = rec && within(rec, 1 / 24);
    var rate = gh().rate;
    h += '<article class="card glow" style="--a:var(--orange)"><div class="kicker"><span class="dot warn"></span>' + t("security") + '</div><div class="rows">';
    h += row("lock", t("access"), t("locked"), "ok");
    h += row("user", t("owner"), state.me || "–", "ok");
    h += row("sync", t("fresh"), rec ? ago(rec) : "–", rec ? (fresh ? "ok" : "warn") : "bad");
    h += row("key", t("ghToken"), rate == null ? "–" : n(rate), rate == null ? "warn" : rate > 500 ? "ok" : "warn");
    h += "</div></article>";

    // computer
    var devs = (state.devices || []).slice().sort(function (a, b) { return new Date(b.seen) - new Date(a.seen); });
    var d = devs[0];
    var on = d && devicesOnline().indexOf(d) !== -1;
    h += '<article class="card glow" style="--a:var(--orange)"><div class="kicker"><span class="dot ' + (on ? "ok" : d ? "bad" : "") + '"></span>' + t("computer") + "</div>";
    if (d) {
      h += '<div class="gauge-wrap">' + gauge(d.cpu, "#ff9f1c", t("cpu")) + '<div class="kv"><b>' + esc(d.name) + "</b><span>" + t("mem") + ' <b class="num">' + n(d.mem) + "%</b></span><span>" + t("disk") + ' <b class="num">' + n(d.disk) + "%</b></span><span>" + esc(on ? t("online") : t("lastSeen") + " " + ago(d.seen)) + "</span></div></div>";
    } else h += '<p class="muted" style="font-size:12.5px">' + esc(t("noDevices")) + '</p><div class="btns"><button class="btn sm" data-go="devices">' + t("setupTitle") + "</button></div>";
    h += "</article>";

    // cloud
    var sites = snap().sites || [];
    var up = sites.filter(function (x) { return x.ok; }).length;
    var pct = sites.length ? Math.round((up / sites.length) * 100) : null;
    var router = snap().cloud && snap().cloud.router;
    h += '<article class="card glow" style="--a:var(--blue)"><div class="kicker"><span class="dot ' + (pct == null ? "" : pct === 100 ? "ok" : "warn") + '"></span>' + t("cloud") + '</div><div class="gauge-wrap">' + gauge(pct, "#5b7cff", t("sitesUp")) + '<div class="kv">';
    h += "<span>" + t("router") + " <b>" + (router ? (router.ok ? t("up") : t("down")) : "–") + "</b></span>";
    h += "<span>" + t("appsUp") + ' <b class="num">' + n(up) + "/" + n(sites.length) + "</b></span>";
    h += "<span>" + t("latency") + ' <b class="num">' + n(avgMs()) + " ms</b></span>";
    h += '<span><span class="chip green">' + esc(snap().generatedAt ? ago(snap().generatedAt) : "–") + "</span></span></div></div></article>";
    $("hero").innerHTML = h;
  }
  function row(icon, label, val, cls) { return '<div class="row">' + ic(icon) + '<span class="lbl">' + esc(label) + '</span><span class="val ' + cls + '">' + esc(val) + "</span></div>"; }
  function gauge(v, col, label) {
    var p = v == null ? 0 : Math.max(0, Math.min(100, v));
    var C = 2 * Math.PI * 40;
    return '<div class="gauge"><svg viewBox="0 0 92 92"><circle cx="46" cy="46" r="40" fill="none" stroke="rgba(255,255,255,.09)" stroke-width="7"/><circle cx="46" cy="46" r="40" fill="none" stroke="' + col +
      '" stroke-width="7" stroke-linecap="round" stroke-dasharray="' + C.toFixed(1) + '" stroke-dashoffset="' + (C * (1 - p / 100)).toFixed(1) + '" style="filter:drop-shadow(0 0 6px ' + col + ')"/></svg><div class="lab"><span class="num">' + (v == null ? "–" : n(Math.round(v)) + "%") + "<small>" + esc(label) + "</small></span></div></div>";
  }
  function avgMs() { var s = (snap().sites || []).filter(function (x) { return x.ok && x.ms; }); return s.length ? Math.round(s.reduce(function (a, x) { return a + x.ms; }, 0) / s.length) : null; }

  function rooms() {
    var repos = (gh().repos || []).slice().sort(function (a, b) { return new Date(b.pushedAt) - new Date(a.pushedAt); });
    if (!repos.length) { $("rooms").innerHTML = '<div class="empty" style="grid-column:1/-1">' + esc(t("noData")) + "</div>"; return; }
    $("rooms").innerHTML = repos.map(function (r) {
      var rs = runState((r.runs || [])[0]);
      var active = within(r.pushedAt, 1);
      return '<a class="card glow room" style="--a:' + color(r.name) + '" href="' + esc(r.url) + '" target="_blank" rel="noopener"><span class="ico">' + ic("repo") + "</span><h4>" + esc(r.name) + '</h4><span class="d">' +
        esc((r.lastCommit && r.lastCommit.msg) || r.language || "") + '</span><span class="s"><span class="dot ' + (rs.k === "failing" ? "bad" : active ? "ok" : "") + '"></span>' +
        esc(r.claudeCommits30 ? n(r.claudeCommits30) + " Claude · " + ago(r.pushedAt) : ago(r.pushedAt)) + "</span></a>";
    }).join("");
  }

  function runs() {
    var list = latestRuns().slice(0, 8);
    if (!list.length) { $("runs").innerHTML = '<div class="empty" style="grid-column:1/-1">–</div>'; return; }
    $("runs").innerHTML = list.map(function (r) {
      var s = runState(r);
      return '<article class="card run" style="--a:' + s.c + '"><span class="ring">' + ic(s.i) + '</span><div class="info"><h4>' + esc(r.name) + '</h4><div class="d" dir="ltr" style="text-align:start">' + esc(r.repo + " · " + (r.branch || "")) +
        '</div><div class="d">' + esc(ago(r.at)) + '</div></div><div class="side"><span class="chip" style="color:' + s.c + '">' + esc(t(s.k)) + '</span>' +
        (r.url ? '<a class="btn sm ghost" href="' + esc(r.url) + '" target="_blank" rel="noopener">' + t("open") + "</a>" : "") + "</div></article>";
    }).join("");
  }

  function tiles() {
    var c = commits();
    var today = c.filter(function (x) { return new Date(x.at).toDateString() === new Date().toDateString(); }).length;
    var c7 = c.filter(function (x) { return within(x.at, 7); });
    var cl7 = c7.filter(function (x) { return x.claude; }).length;
    var prs = gh().prs || [];
    var open = prs.filter(function (p) { return p.state === "open"; }).length;
    var merged = prs.filter(function (p) { return p.merged && within(p.at, 30); }).length;
    var share = c7.length ? Math.round((cl7 / c7.length) * 100) : null;
    var ms = avgMs();
    var list = [
      ["commit", "var(--orange)", n(today), t("commitsToday"), "", Math.min(100, today * 10)],
      ["spark", "var(--cyan)", n(c7.length), t("commits7"), "", Math.min(100, c7.length * 2)],
      ["bolt", "var(--orange)", share == null ? "–" : n(share) + "%", t("claudeShare"), "", share || 0],
      ["pr", "var(--cyan)", n(open), t("openPRs"), "", Math.min(100, open * 20)],
      ["check", "var(--orange)", n(merged), t("merged30"), "", Math.min(100, merged * 5)],
      ["globe", "var(--cyan)", ms == null ? "–" : n(ms) + "ms", t("latency"), "", ms ? Math.max(5, 100 - ms / 20) : 0],
    ];
    $("tiles").innerHTML = list.map(function (x) {
      return '<article class="card tile" style="--a:' + x[1] + '"><span class="ico">' + ic(x[0]) + '</span><div class="v num">' + esc(x[2]) + '</div><div class="k">' + esc(x[3]) + '</div><span class="track"><i style="width:' + x[5] + '%"></i></span></article>';
    }).join("");
  }

  // ---------- Claude ----------
  function sessions() {
    var s = gh().sessions || [];
    if (!s.length) { $("sessions").innerHTML = '<div class="empty" style="grid-column:1/-1">' + esc(t("noSessions")) + "</div>"; return; }
    $("sessions").innerHTML = s.slice(0, 12).map(function (x) {
      return '<article class="card glow sess" style="--a:' + color(x.id) + '"><div class="kicker"><span class="dot ' + (within(x.last, 1 / 12) ? "bad" : "ok") + '"></span>' + esc(ago(x.last)) + "</div><h4>" + esc(x.title) + '</h4><div class="d">' +
        esc(x.repos.join(" · ")) + '</div><div class="chips"><span class="chip red">' + n(x.commits) + " " + t("commits") + "</span>" +
        (x.prs ? '<span class="chip violet">' + n(x.prs) + " PR</span>" : "") +
        (x.url ? '<a class="chip blue" href="' + esc(x.url) + '" target="_blank" rel="noopener">' + t("session") + " ↗</a>" : "") + "</div></article>";
    }).join("");
  }
  function timeline() {
    var f = [["all", t("all")], ["claude", t("onlyClaude")], ["prs", t("prs")], ["log", t("log")]];
    $("tl-filters").innerHTML = f.map(function (x) { return '<button type="button" data-tl="' + x[0] + '" aria-pressed="' + (tlFilter === x[0]) + '">' + esc(x[1]) + "</button>"; }).join("");
    var ev = [];
    if (tlFilter === "all" || tlFilter === "claude") commits().forEach(function (c) { if (tlFilter === "all" || c.claude) ev.push({ at: c.at, kind: "commit", c: c }); });
    if (tlFilter === "all" || tlFilter === "prs") (gh().prs || []).forEach(function (p) { ev.push({ at: p.at, kind: "pr", p: p }); });
    if (tlFilter === "all" || tlFilter === "log") (state.log || []).forEach(function (l) { ev.push({ at: l.at, kind: "log", l: l }); });
    ev.sort(function (a, b) { return new Date(b.at) - new Date(a.at); });
    if (!ev.length) { $("timeline").innerHTML = '<li class="empty">' + esc(t("noData")) + "</li>"; return; }
    $("timeline").innerHTML = ev.slice(0, 150).map(function (e) {
      var col, icon, title, meta = [], url, detail = "";
      if (e.kind === "commit") {
        col = e.c.claude ? "var(--red)" : "var(--blue)"; icon = "commit"; title = e.c.msg; url = e.c.url;
        meta.push('<span dir="ltr">' + esc(e.c.repo) + "</span>", '<span dir="ltr">' + esc(e.c.branch || "") + "</span>");
        if (e.c.claude) meta.push('<span class="chip red">Claude</span>');
      } else if (e.kind === "pr") {
        col = "var(--violet)"; icon = "pr"; title = "#" + e.p.number + " " + e.p.title; url = e.p.url;
        meta.push('<span dir="ltr">' + esc(e.p.repo) + "</span>", '<span class="chip ' + (e.p.merged ? "violet" : e.p.state === "open" ? "green" : "") + '">' + t(e.p.merged ? "merged" : e.p.state === "open" ? "openS" : "closed") + "</span>");
      } else {
        col = "var(--orange)"; icon = "log"; title = e.l.title; url = e.l.url; detail = e.l.detail;
        if (e.l.repo) meta.push('<span dir="ltr">' + esc(e.l.repo) + "</span>");
        meta.push('<span class="chip orange">' + esc(e.l.source) + "</span>");
      }
      meta.unshift("<span>" + esc(ago(e.at)) + "</span>");
      return '<li class="card ev" style="--a:' + col + '"><span class="round">' + ic(icon) + '</span><div class="b"><div class="t">' + (url ? '<a href="' + esc(url) + '" target="_blank" rel="noopener">' + esc(title) + "</a>" : esc(title)) +
        '</div><div class="m">' + meta.join("") + "</div>" + (detail ? '<div class="detail">' + esc(detail) + "</div>" : "") + "</div></li>";
    }).join("");
  }

  // ---------- apps ----------
  function sites() {
    var s = snap().sites || [];
    if (!s.length) { $("sites").innerHTML = '<div class="empty" style="grid-column:1/-1">' + esc(t("noData")) + "</div>"; return; }
    $("sites").innerHTML = s.map(function (x) {
      var nm = x.name && typeof x.name === "object" ? x.name[lang] || x.name.ar : x.name || x.id;
      return '<a class="card site" href="' + esc(x.url) + '" target="_blank" rel="noopener">' + (x.icon ? '<img src="' + esc(x.icon) + '" alt="" loading="lazy">' : '<span class="round">' + ic("globe") + "</span>") +
        '<div class="b"><h4>' + esc(nm) + '</h4><div class="d">' + esc(x.url.replace(/^https:\/\//, "")) + '</div></div><span class="chip ' + (x.ok ? "green" : "red") + '">' + (x.ok ? (x.ms ? '<span class="num">' + n(x.ms) + "ms</span>" : t("up")) : t("down") + (x.status ? " " + x.status : "")) + "</span></a>";
    }).join("");
  }

  // ---------- devices ----------
  function devices() {
    var all = (state.devices || []).slice().sort(function (a, b) { return new Date(b.seen) - new Date(a.seen); });
    var onl = devicesOnline();
    $("devices").innerHTML = all.length ? all.map(function (d) {
      var on = onl.indexOf(d) !== -1;
      var m = function (k, v, c) { return '<div class="meter" style="--a:' + c + '"><div class="k">' + t(k) + '</div><div class="v num">' + (v == null ? "–" : n(v) + "%") + '</div><span class="track"><i style="width:' + (v || 0) + '%"></i></span></div>'; };
      return '<article class="card glow" style="--a:' + (on ? "var(--green)" : "var(--red)") + '"><div class="kicker"><span class="dot ' + (on ? "ok" : "bad") + '"></span>' + esc(on ? t("online") : t("offline")) + " · " + esc(ago(d.seen)) +
        '</div><div style="display:flex;align-items:center;gap:10px"><span class="round">' + ic("pc") + '</span><div style="flex:1;min-width:0"><b>' + esc(d.name) + '</b><div class="muted" style="font-size:12px">' + esc(d.os) +
        (d.uptimeH != null ? " · " + t("uptime") + " " + n(Math.round(d.uptimeH)) + " " + t("hours") : "") + (d.country ? " · " + esc(d.country) : "") + '</div></div><button class="btn sm ghost" data-del-dev="' + esc(d.id) + '">' + t("remove") + "</button></div>" +
        '<div class="meters">' + m("cpu", d.cpu, "var(--orange)") + m("mem", d.mem, "var(--cyan)") + m("disk", d.disk, "var(--violet)") + "</div>" +
        (d.battery != null ? '<div class="muted" style="font-size:12px;margin-top:8px">' + t("battery") + ' <span class="num">' + n(d.battery) + "%</span>" + (d.charging ? " ⚡" : "") + "</div>" : "") + "</article>";
    }).join("") : '<div class="empty" style="grid-column:1/-1">' + esc(t("noDevices")) + "</div>";

    var ar = lang !== "en";
    $("setup").innerHTML = "<h3>" + t("setupTitle") + "</h3><ol>" +
      (ar
        ? "<li>نزّل البرنامج المناسب: <a class=\"chip blue\" href=\"/agent/ameer-agent.ps1\" download>Windows (PowerShell)</a> أو <a class=\"chip blue\" href=\"/agent/ameer-agent.mjs\" download>Mac / Linux (Node.js)</a></li>" +
          "<li>افتح الملف وضع «رمز الإدخال» (AMEER_INGEST_TOKEN) مكان <code>PASTE_TOKEN_HERE</code>، واكتب اسمًا للجهاز.</li>" +
          "<li>شغّله مرة للتجربة؛ يظهر الجهاز هنا خلال دقيقة.</li>" +
          "<li>ليعمل تلقائيًا كل ٥ دقائق: في ويندوز شغّل الأمر بالأسفل مرة واحدة في PowerShell.</li>"
        : "<li>Download the agent: <a class=\"chip blue\" href=\"/agent/ameer-agent.ps1\" download>Windows (PowerShell)</a> or <a class=\"chip blue\" href=\"/agent/ameer-agent.mjs\" download>Mac / Linux (Node.js)</a></li>" +
          "<li>Open it, replace <code>PASTE_TOKEN_HERE</code> with your AMEER_INGEST_TOKEN and set a device name.</li>" +
          "<li>Run it once; the device appears here within a minute.</li>" +
          "<li>To run every 5 minutes on Windows, run the command below once in PowerShell.</li>") +
      "</ol><pre>schtasks /Create /SC MINUTE /MO 5 /TN AmeerAgent /TR \"powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File %USERPROFILE%\\ameer-agent.ps1\"</pre>" +
      '<pre>*/5 * * * * node ~/ameer-agent.mjs   # crontab -e (Mac / Linux)</pre>';
  }

  // ---------- notes ----------
  function notes() {
    $("note-text").placeholder = t("notePh");
    var list = state.notes || [];
    $("notes").innerHTML = list.length ? list.map(function (x) {
      return '<li class="card note' + (x.done ? " done" : "") + '"><button class="check" data-toggle="' + esc(x.id) + '" aria-pressed="' + !!x.done + '" aria-label="done">' + (x.done ? ic("check") : "") + '</button><span class="t">' + esc(x.text) +
        '<br><small class="muted">' + esc(ago(x.at)) + '</small></span><button class="btn sm ghost" data-del-note="' + esc(x.id) + '" aria-label="' + t("remove") + '">' + ic("x").replace("<svg", '<svg width="14" height="14" style="fill:currentColor"') + "</button></li>";
    }).join("") : '<li class="empty">' + esc(t("noNotes")) + "</li>";
  }

  // ---------- shell ----------
  var TABS = [["overview", "home", "overview"], ["claude", "spark", "claude"], ["apps", "grid", "apps"], ["devices", "pc", "devicesTab"], ["notes", "note", "notesTab"]];
  function dock() {
    $("dock").innerHTML = TABS.map(function (x) { return '<button type="button" data-go="' + x[0] + '"' + (view === x[0] ? ' aria-current="page"' : "") + ">" + ic(x[1]) + "<span>" + esc(t(x[2])) + "</span></button>"; }).join("");
  }
  function go(v) {
    view = v;
    document.querySelectorAll("[data-view]").forEach(function (s) { s.hidden = s.getAttribute("data-view") !== v; });
    try { history.replaceState(null, "", "#" + v); } catch (e) {}
    dock();
    window.scrollTo(0, 0);
  }
  function applyLang() {
    root.lang = lang; root.dir = lang === "en" ? "ltr" : "rtl"; root.setAttribute("data-lang", lang);
    document.querySelectorAll("[data-t]").forEach(function (el) { el.textContent = t(el.getAttribute("data-t")); });
  }
  function render() {
    applyLang(); tick(); dock();
    if (!state) return;
    var rec = snap().receivedAt;
    banner(!rec ? t("noData") : !within(rec, 1 / 8) ? t("stale") + " " + ago(rec) : "");
    pills(); hero(); rooms(); runs(); tiles(); sessions(); timeline(); sites(); devices(); notes();
    $("updated").textContent = rec ? "· " + t("fresh") + " " + ago(rec) : "";
  }

  document.addEventListener("click", function (e) {
    var el = e.target.closest("[data-go],[data-tl],[data-toggle],[data-del-note],[data-del-dev]");
    if (!el) return;
    if (el.dataset.go) return go(el.dataset.go);
    if (el.dataset.tl) { tlFilter = el.dataset.tl; return timeline(); }
    if (el.dataset.toggle) return post("/api/notes", { op: "toggle", id: el.dataset.toggle }).then(function (j) { if (j.ok) { state.notes = j.notes; notes(); } });
    if (el.dataset.delNote) return post("/api/notes", { op: "delete", id: el.dataset.delNote }).then(function (j) { if (j.ok) { state.notes = j.notes; notes(); } });
    if (el.dataset.delDev) {
      if (!confirm(t("remove") + "?")) return;
      return post("/api/device?id=" + encodeURIComponent(el.dataset.delDev), null, "DELETE").then(load);
    }
  });
  $("note-form").addEventListener("submit", function (e) {
    e.preventDefault();
    var v = $("note-text").value.trim();
    if (!v) return;
    post("/api/notes", { op: "add", text: v }).then(function (j) { if (j.ok) { state.notes = j.notes; $("note-text").value = ""; notes(); } });
  });
  $("refresh").addEventListener("click", load);
  $("lang").addEventListener("click", function () {
    lang = lang === "en" ? "ar" : "en";
    try { localStorage.setItem("ameer-lang", lang); } catch (e) {}
    weather(); render();
  });

  // Weather (Open-Meteo, no key). Uses the phone's location only if already allowed; else Riyadh.
  var WX = { 0: ["صحو", "Clear"], 1: ["صحو غالبًا", "Mostly clear"], 2: ["غائم جزئيًا", "Partly cloudy"], 3: ["غائم", "Cloudy"], 45: ["ضباب", "Fog"], 61: ["مطر", "Rain"], 63: ["مطر", "Rain"], 80: ["زخات", "Showers"], 95: ["عواصف", "Storm"] };
  function weather() {
    var get = function (lat, lon) {
      fetch("https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,weather_code")
        .then(function (r) { return r.json(); })
        .then(function (j) { var c = j.current || {}; if (typeof c.temperature_2m !== "number") return; var w = WX[c.weather_code] || WX[2]; wx = { temp: c.temperature_2m, label: w[lang === "en" ? 1 : 0] }; pills(); })
        .catch(function () {});
    };
    var fallback = function () { get(24.71, 46.68); };
    try {
      if (navigator.permissions && navigator.geolocation) {
        navigator.permissions.query({ name: "geolocation" }).then(function (p) {
          if (p.state === "granted") navigator.geolocation.getCurrentPosition(function (pos) { get(pos.coords.latitude.toFixed(2), pos.coords.longitude.toFixed(2)); }, fallback);
          else fallback();
        }, fallback);
      } else fallback();
    } catch (e) { fallback(); }
  }

  var h = (location.hash || "").slice(1);
  if (TABS.some(function (x) { return x[0] === h; })) view = h;
  go(view);
  render();
  setInterval(tick, 10000);
  setInterval(function () { if (state) { pills(); } }, 60000);
  setInterval(load, 5 * 60000);
  load();
  weather();
})();
