/* Eng. Alaeldeen | Quality & Safety — single-page app (hash routing, no build step). */
(function () {
  "use strict";
  const S = window.SITE, I = window.ICONS;
  const app = (window.APP = {});

  /* ---------- utilities ---------- */
  const store = {
    get(k, d) { try { const v = localStorage.getItem("ab:" + k); return v == null ? d : JSON.parse(v); } catch (e) { return d; } },
    set(k, v) { try { localStorage.setItem("ab:" + k, JSON.stringify(v)); return true; } catch (e) { toast(app.t("importFail"), "bad"); return false; } },
    del(k) { try { localStorage.removeItem("ab:" + k); } catch (e) { /* storage unavailable */ } },
  };
  let lang = store.get("lang", null) || ((navigator.language || "").toLowerCase().startsWith("en") ? "en" : "ar");
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const L = (x) => (x == null ? "" : typeof x === "string" ? x : x[lang] != null ? x[lang] : x.en);
  const t = (k) => { const v = k.split(".").reduce((o, p) => (o ? o[p] : undefined), window.I18N[lang]); return v == null ? k : v; };
  const $ = (sel, root) => (root || document).querySelector(sel);
  const $$ = (sel, root) => Array.from((root || document).querySelectorAll(sel));
  const fmtDate = (iso, opts) => { if (!iso) return ""; const d = new Date(iso.length === 7 ? iso + "-01" : iso); return isNaN(d) ? iso : d.toLocaleDateString(lang === "ar" ? "ar-SA-u-ca-gregory-nu-latn" : "en-GB", opts || { year: "numeric", month: "short", day: "numeric" }); };
  const norm = (s) => String(s || "").toLowerCase()
    .replace(/[ً-ٰٟـ]/g, "")
    .replace(/[أإآٱ]/g, "ا").replace(/ى/g, "ي").replace(/ة/g, "ه").replace(/ؤ/g, "و").replace(/ئ/g, "ي")
    .replace(/[^\p{L}\p{N}]+/gu, " ").trim();
  let toastTimer;
  function toast(msg, kind) {
    const el = $("#toast"); el.className = "toast show " + (kind || "ok"); el.innerHTML = (kind === "bad" ? I.alert : I.check).replace("<svg", '<svg width="18" height="18"') + "<span>" + esc(msg) + "</span>";
    clearTimeout(toastTimer); toastTimer = setTimeout(() => (el.className = "toast"), 2600);
  }
  function download(name, text, type) {
    const blob = new Blob([text], { type: type || "text/plain;charset=utf-8" });
    const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = name; document.body.appendChild(a); a.click();
    setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 500);
  }
  function csv(rows) { return "﻿" + rows.map((r) => r.map((c) => '"' + String(c == null ? "" : c).replace(/"/g, '""') + '"').join(",")).join("\r\n"); }
  const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
  Object.assign(app, { store, esc, L, t, $, $$, toast, download, csv, uid, fmtDate, norm, get lang() { return lang; } });

  /* ---------- learner progress ---------- */
  const prog = {
    get() { return store.get("progress", { done: {}, quiz: {}, favMods: [] }); },
    save(p) { store.set("progress", p); },
  };
  const favTerms = () => store.get("favTerms", []);
  app.prog = prog;

  /* ---------- shared fragments ---------- */
  const btn = (href, label, cls, icon) => `<a class="btn ${cls || "btn-gold"}" href="${href}">${icon ? I[icon] : ""}<span>${esc(label)}</span>${cls && cls.includes("noarrow") ? "" : I.arrow}</a>`;
  const crumbs = (items) => `<ol class="crumbs" aria-label="breadcrumb"><li><a href="#/">${esc(t("nav.home"))}</a></li>${items.map((it) => `<li>${it[1] ? `<a href="${it[1]}">${esc(it[0])}</a>` : `<span aria-current="page">${esc(it[0])}</span>`}</li>`).join("")}</ol>`;
  const pageHead = (title, sub, cr, cls, extra) => `<header class="ph ${cls || ""}"><div class="wrap">${cr ? crumbs(cr) : ""}${extra && extra.eyebrow ? `<span class="eyebrow">${esc(extra.eyebrow)}</span>` : ""}<h1 tabindex="-1">${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ""}${extra && extra.after ? extra.after : ""}</div></header>`;
  Object.assign(app, { crumbs, pageHead, btn });

  /* ---------- header / footer ---------- */
  const ext = (u) => (/^mailto:/.test(u) ? "" : ' target="_blank" rel="noopener"');
  const socialRow = () => S.links.social.map(([ic, n, u]) => `<a class="icon-btn" href="${u}"${ext(u)} aria-label="${esc(n)}" title="${esc(n)}">${I[ic]}</a>`).join("");
  const linksGrid = () => S.links.groups.map((g) => `<div class="link-group"><h3>${esc(L(g.t))}</h3><div class="grid">${g.items.map((it) => `<a class="card hover link-card" href="${it.u}"${ext(it.u)}><span class="ic">${I[it.icon] || I.globe}</span><span class="lc-t"><b>${esc(L(it.n))}</b><small dir="ltr">${esc(it.d)}</small></span>${I.external}</a>`).join("")}</div></div>`).join("");
  const videoBox = (b) => `<div class="video" data-yt="${b.video}"><img src="${b.cover}" alt="${esc(L(b.title))}" loading="lazy" width="${b.coverW}" height="${b.coverH}"><button type="button" class="play" aria-label="${esc(t("books.play"))}">${I.play}</button></div>`;
  app.scrollTo = (target, smooth) => {
    if (window.MOTION && window.MOTION.scrollTo) return window.MOTION.scrollTo(target, smooth);
    if (target === 0) window.scrollTo(0, 0); else if (target) target.scrollIntoView({ block: "start", behavior: smooth ? "smooth" : "auto" });
  };
  const yearsExp = () => new Date().getFullYear() - S.profile.careerStart;
  const NAV = [["home", "#/"], ["profile", "#/about"], ["lamp", "#/lamp"], ["tools", "#/tools"], ["dictionary", "#/dictionary"], ["knowledge", "#/knowledge"], ["library", "#/library"], ["projects", "#/projects"], ["contact", "#/contact"]];
  function renderChrome() {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    $("#skip").textContent = t("skip");
    const links = NAV.map(([k, h]) => `<a href="${h}" data-nav="${k}" class="${k === "lamp" ? "lamp-link" : ""}">${esc(t("nav." + k))}</a>`).join("");
    $("#hdr").innerHTML = `<div class="wrap">
      <a class="brand" href="#/" aria-label="Eng. Alaeldeen — ${esc(t("nav.home"))}"><img src="assets/logo-mark.png" alt="" width="46" height="36"><span class="bt"><b>Eng. <span>Alaeldeen</span></b><small>QUALITY &amp; SAFETY</small></span></a>
      <nav class="nav" aria-label="main">${links}</nav>
      <div class="hdr-act">
        <button class="icon-btn" id="openSearch" aria-label="${esc(t("search"))}" title="${esc(t("search"))} (/)">${I.search}</button>
        <div class="lang" role="group" aria-label="Language"><button data-lang="ar" aria-pressed="${lang === "ar"}" lang="ar">AR</button><button data-lang="en" aria-pressed="${lang === "en"}" lang="en">EN</button></div>
        <button class="icon-btn menu-btn" id="openMenu" aria-label="${esc(t("menu"))}" aria-expanded="false" aria-controls="drawer">${I.menu}</button>
      </div></div>`;
    $("#drawer").innerHTML = `<div class="scrim" data-close></div><div class="panel" role="dialog" aria-modal="true" aria-label="${esc(t("menu"))}"><button class="icon-btn close" data-close aria-label="${esc(t("close"))}">${I.x}</button>${links}</div>`;
    const yr = new Date().getFullYear();
    $("#ftr").innerHTML = `<div class="wrap"><div class="cols">
      <div><a class="brand" href="#/"><img src="assets/logo-mark.png" alt="" width="46" height="36"><span class="bt"><b>Eng. <span>Alaeldeen</span></b><small>QUALITY &amp; SAFETY</small></span></a>
        <p style="color:var(--muted);margin-top:14px;max-width:340px;font-size:14.5px">${esc(t("footerTag"))}</p>
        <div class="social">${socialRow()}</div></div>
      <div><h4>${esc(t("explore"))}</h4><ul><li><a href="#/about">${esc(t("nav.profile"))}</a></li><li><a href="#/experience">${esc(t("navLong.experience"))}</a></li><li><a href="#/certifications">${esc(t("navLong.certifications"))}</a></li><li><a href="#/projects">${esc(t("nav.projects"))}</a></li></ul></div>
      <div><h4>${esc(t("platform"))}</h4><ul><li><a href="#/lamp">${esc(t("nav.lamp"))}</a></li><li><a href="#/tools">${esc(t("toolsT"))}</a></li><li><a href="#/dictionary">${esc(t("dictT"))}</a></li><li><a href="#/knowledge">${esc(t("knowT"))}</a></li><li><a href="#/library">${esc(t("nav.library"))}</a></li><li><a href="#/books">${esc(t("books.t"))}</a></li><li><a href="#/assistant">${esc(lang === "ar" ? "مساعد الجودة الذكي" : "AI assistant")}</a></li></ul></div>
      <div><h4>${esc(t("connect"))}</h4><ul><li><a href="#/contact">${esc(t("contactMe"))}</a></li><li><a href="#/links">${esc(t("linksT"))}</a></li><li><a href="#/privacy">${esc(t("privacyT"))}</a></li></ul></div>
    </div><div class="base"><span>© ${yr} Eng. Alaeldeen — ${esc(t("rights"))}</span><span>${esc(t("footerNote"))}</span>
      <a class="credit" href="https://aladeen35.github.io/Games/bushra-tech/" target="_blank" rel="noopener"><img src="assets/bt-brand-mark.webp" alt="" width="30" height="29"><span>${esc(lang === "ar" ? "من إنتاج" : "Made by")} <b>${esc(lang === "ar" ? "البشري للتكنولوجيا" : "Al-Bushra Technology")}</b></span></a></div></div>`;
    if (!document.getElementById("askFab")) { const f = document.createElement("a"); f.id = "askFab"; f.className = "ask-fab"; f.href = "#/assistant"; document.body.appendChild(f); }
    const fab = document.getElementById("askFab"); fab.innerHTML = `${I.lamp}<span>${esc(lang === "ar" ? "اسأل المساعد" : "Ask the assistant")}</span>`; fab.setAttribute("aria-label", lang === "ar" ? "مساعد الجودة الذكي" : "Quality AI assistant");
    $("#searchDlg").innerHTML = `<div class="box" role="dialog" aria-modal="true" aria-label="${esc(t("search"))}"><div class="searchbar">${I.search}<input id="sq" type="search" placeholder="${esc(t("searchPh"))}" aria-label="${esc(t("search"))}" autocomplete="off"><button class="icon-btn" data-close aria-label="${esc(t("close"))}" style="border:0">${I.x}</button></div><div class="res" id="sres" role="listbox"><div class="hint">${esc(t("searchHint"))}</div></div></div>`;
  }
  function markNav(route) {
    const key = { "": "home", about: "profile", experience: "profile", certifications: "profile", books: "library" }[route] ?? route;
    const fab = document.getElementById("askFab"); if (fab) fab.hidden = route === "assistant";
    $$("[data-nav]").forEach((a) => { const on = a.dataset.nav === key; a.classList.toggle("on", on); on ? a.setAttribute("aria-current", "page") : a.removeAttribute("aria-current"); });
  }

  /* ---------- pages ---------- */
  const P = (app.pages = {});

  P.home = () => {
    const sp = t("spec"), icons = ["shield", "award", "gear", "hands", "flask", "leaf"];
    const b = S.books.find((x) => x.featured);
    const chapters = [
      ["qAbout", "#/about", "user", "wide", true], ["qLamp", "#/lamp", "lamp", "teal"], ["qTools", "#/tools", "tools"],
      ["qDict", "#/dictionary", "book"], ["qKnow", "#/knowledge", "stack"], ["qLib", "#/library", "shelf"], ["qProj", "#/projects", "trophy"],
    ];
    const mq = sp.map((x, i) => `<span class="mq-item ${i % 2 ? "" : "solid"}">${I[icons[i]]}${esc(x[0])}<small>${esc(x[1])}</small></span>`).join("");
    const nums = [[yearsExp(), "+", t("fYears")], [S.profile.experience.filter((e) => !e.training).length, "", t("fOrgs")], [S.profile.certs.length, "", t("fCerts")], [S.books.length, "", t("books.t")], [1, "", t("fPatent")]];
    return `
    <section class="hero" data-scene="hero"><canvas class="hero-gl" aria-hidden="true"></canvas><div class="swoosh"></div><div class="wrap">
      <div class="hero-copy">
        <p class="hero-kicker" data-intro>ENG. ALAELDEEN — QUALITY &amp; SAFETY</p>
        <h1 tabindex="-1"><span class="l1" data-split>${esc(t("heroH1a"))}</span><span class="g" data-split>${esc(t("heroH1b"))}</span></h1>
        <p class="role" data-intro>${esc(t("heroRole"))}</p><div class="rule" data-intro-rule></div>
        <p class="lead" data-intro>${esc(t("heroLead"))}</p>
        <div class="cta" data-intro-cta>${btn("#/about", t("ctaProfile"), "btn-gold")}${btn("#/tools", t("ctaTools"), "btn-line", "tools")}${btn("#/lamp", t("ctaLamp"), "btn-teal", "lamp")}</div>
      </div>
      <div class="hero-photo"><img src="assets/headshot.webp" alt="${esc(L(S.profile.name))}" width="640" height="916" fetchpriority="high" data-preload>
        <div class="hero-badge">${I.shield}<div><b>${esc(t("badgeT").replace("{y}", yearsExp()))}</b><small>${esc(t("badgeS"))}</small></div></div></div>
    </div><div class="scroll-cue" aria-hidden="true">SCROLL<i></i></div></section>

    <section class="marquee" aria-label="specialties" data-scene="marquee"><div class="mq-track">${mq}${mq}</div></section>

    <section class="chapters" data-scene="chapters">
      <div class="wrap ch-head"><span class="eyebrow">${esc(t("quick"))}</span><h2 data-split-scrub>${esc(t("quickSub"))}</h2></div>
      <div class="ch-pin"><div class="ch-track">${chapters.map(([k, href, icon, cls, photo], i) => { const v = t(k); return `
        <a class="ch-panel ${cls || ""}" href="${href}">${photo ? `<span class="ch-bg"><img src="assets/fullbody.jpg" alt="" width="620" height="970" loading="lazy"></span>` : ""}<span class="ch-glow"></span>
          <span class="ch-num">${String(i + 1).padStart(2, "0")}</span><span class="ch-ic">${I[icon]}</span>
          <h3>${esc(v[0])}</h3><p>${esc(v[1])}</p><span class="ch-go">${esc(v[2])} ${I.arrow}</span></a>`; }).join("")}</div></div>
    </section>

    <section class="numbers" data-scene="numbers"><div class="wrap">
      <span class="eyebrow">${esc(t("facts"))}</span><h2 class="mb-10 text-[clamp(26px,3vw,38px)]" data-split-scrub>${esc(L(S.profile.title))}</h2>
      <div class="row-n">${nums.map(([n, suf, lab]) => `<div class="n"><b data-count="${n}" data-suffix="${suf}">${n}${suf}</b><span>${esc(lab)}</span></div>`).join("")}</div>
      <p class="note mt-6">${esc(t("factsSub"))}</p></div></section>

    <section class="sec book-feature" data-scene="book"><div class="wrap book-grid">
      <div class="book-stage"><a class="book-cover" href="#/books" aria-label="${esc(L(b.title))}"><img src="${b.cover}" alt="${esc(L(b.title))} — ${esc(L(b.subtitle))}" loading="lazy" width="${b.coverW}" height="${b.coverH}"></a></div>
      <div class="book-copy"><span class="eyebrow">${esc(t("books.feat"))} · ${esc(L(b.kind))}</span><h2 class="book-title" data-split>${esc(L(b.title))}</h2><p class="book-sub">${esc(L(b.subtitle))}</p>
        <p style="color:#dcdcdc">${esc(L(b.blurb))}</p>
        <div class="chain">${b.chain.map((c, i) => `<span>${esc(L(c))}</span>${i < b.chain.length - 1 ? I.arrow : ""}`).join("")}</div>
        <div class="cta" style="justify-content:flex-start"><a class="btn btn-gold" href="${b.url}" target="_blank" rel="noopener">${I.play}<span>${esc(L(b.cta))}</span></a>${btn("#/books", t("books.more"), "btn-line")}</div></div>
    </div></section>

    <section class="manifesto" data-scene="quote"><div class="wrap"><p class="mf-text" data-read>${esc(t("quote"))}</p>${btn("#/contact", t("contactMe"), "btn-gold", "mail")}</div></section>`;
  };

  function duration(from, to) {
    const a = new Date(from + "-01"), b = to ? new Date(to + "-01") : new Date();
    let m = (b.getFullYear() - a.getFullYear()) * 12 + b.getMonth() - a.getMonth(); if (!to) m += 0; m = Math.max(1, m);
    const y = Math.floor(m / 12), r = m % 12;
    return [y ? `${y} ${t("yrs")}` : "", r ? `${r} ${t("months")}` : ""].filter(Boolean).join(" ");
  }
  P.about = (sub) => {
    const pr = S.profile;
    const certs = (g) => pr.certs.filter((c) => c.g === g).map((c) => `<div class="card cert"><span class="ic">${I.award}</span><div><h4>${esc(L(c.n))}</h4>${c.by ? `<small>${esc(L(c.by))}</small>` : ""}</div></div>`).join("");
    const html = `${pageHead(t("profileT"), t("profileSub"), [[t("nav.profile")]], "", { after: `<div class="cta" style="justify-content:flex-start"><a class="btn btn-gold" href="cv/Alaeldeen_Omer_CV_${lang === "ar" ? "AR" : "EN"}.pdf" download>${I.download}<span>${esc(t("downloadCV"))} — ${esc(lang === "ar" ? t("cvAr") : t("cvEn"))}</span></a><a class="btn btn-ghost" href="cv/Alaeldeen_Omer_CV_${lang === "ar" ? "EN" : "AR"}.pdf" download>${I.download}<span>${esc(lang === "ar" ? t("cvEn") : t("cvAr"))}</span></a><a class="btn btn-ghost" href="https://youtu.be/-ETJpZbi5O4" target="_blank" rel="noopener">${I.play}<span>${esc(t("aboutVideo"))}</span></a><a class="btn btn-ghost" href="https://linkedin.com/in/aladeen35/" target="_blank" rel="noopener">${I.linkedin}<span>LinkedIn</span></a></div>` })}
    <section class="sec" id="about"><div class="wrap profile-top">
      <div class="profile-photo"><img src="assets/fullbody-cut.webp" alt="${esc(L(pr.name))}" width="473" height="1385"></div>
      <div>
        <span class="eyebrow">${esc(t("summary"))}</span>
        <h2 style="font-size:30px">${esc(L(pr.name))}</h2>
        <p style="color:var(--gold);font-weight:600">${esc(L(pr.title))}</p>
        <p style="color:#dcdcdc">${esc(L(pr.summary))}</p>
        <div class="kv">
          <div><small>${esc(t("location"))}</small><b>${esc(L(pr.location))}</b></div>
          <div><small>${esc(t("languages"))}</small><b>${esc(L(pr.languages))}</b></div>
          <div><small>${esc(t("email"))}</small><b><a href="mailto:${pr.email}">${pr.email}</a></b></div>
          <div><small>${esc(t("phone"))}</small><b dir="ltr"><a href="tel:${pr.phone.replace(/\s/g, "")}">${pr.phone}</a></b></div>
        </div>
        <h3 style="margin-top:28px">${esc(t("competencies"))}</h3>
        <ul class="ticks">${pr.competencies.map((c) => `<li>${esc(L(c))}</li>`).join("")}</ul>
      </div></div></section>
    <section class="sec" id="experience" style="padding-top:0"><div class="wrap">
      <div class="sec-hd"><div><span class="eyebrow">${esc(t("navLong.experience"))}</span><h2>${esc(t("experience"))}</h2></div></div>
      <div class="timeline">${pr.experience.map((e) => `<div class="tl"><div class="card">
        <div class="meta"><span class="chip gold">${e.year ? esc(e.year) : `${esc(fmtDate(e.from, { year: "numeric", month: "short" }))} — ${esc(e.to ? fmtDate(e.to, { year: "numeric", month: "short" }) : t("present"))}`}</span>${e.year ? `<span class="chip">${esc(lang === "ar" ? "تدريب" : "Training")}</span>` : `<span class="chip">${esc(duration(e.from, e.to))}</span>`}</div>
        <h3>${esc(L(e.role))}</h3><span class="org">${esc(L(e.org))}</span>
        <ul class="ticks">${e.points.map((p) => `<li>${esc(L(p))}</li>`).join("")}</ul></div></div>`).join("")}</div>
    </div></section>
    <section class="sec" id="certifications" style="padding-top:0"><div class="wrap">
      <div class="sec-hd"><div><span class="eyebrow">${esc(t("navLong.certifications"))}</span><h2>${esc(t("education"))}</h2></div></div>
      <div class="card" style="display:flex;gap:16px;align-items:flex-start;margin-bottom:34px"><span class="ic" style="margin:0;flex-shrink:0">${I.book}</span><div><h3 style="margin-bottom:4px">${esc(L(pr.education.degree))}</h3><p style="margin:0 0 4px;color:var(--gold);font-weight:600">${esc(L(pr.education.school))} · ${pr.education.years}</p><p style="margin:0">${esc(L(pr.education.grade))}</p></div></div>
      <h3>${esc(t("certFS"))}</h3><div class="grid g3" style="margin-bottom:28px">${certs("fs")}</div>
      <h3>${esc(t("certPD"))}</h3><div class="grid g4" style="margin-bottom:34px">${certs("pd")}</div>
      <div class="grid g2">
        <div class="card"><h3>${esc(t("skills"))}</h3><div class="skills">${pr.skills.map((s) => `<span class="chip gold" dir="ltr">${esc(s)}</span>`).join("")}</div></div>
        <div class="card"><h3>${esc(t("achievements"))}</h3><ul class="ticks">${pr.achievements.map((a) => `<li>${esc(L(a))}</li>`).join("")}</ul></div>
      </div></div></section>`;
    return { html, after: () => { if (sub) { const el = document.getElementById(sub); if (el) setTimeout(() => app.scrollTo(el, false), 60); } } };
  };
  P.experience = () => P.about("experience");
  P.certifications = () => P.about("certifications");

  /* ----- Quality Lamp ----- */
  function lampStats() {
    const p = prog.get(); const ready = S.modules.filter((m) => m.status === "ready");
    const attempts = Object.values(p.quiz).flat();
    const avg = attempts.length ? Math.round(attempts.reduce((s, a) => s + (a.score / a.total) * 100, 0) / attempts.length) : 0;
    const badges = ready.filter((m) => p.done[m.id] && (p.quiz[m.id] || []).some((a) => a.score / a.total >= 0.75));
    return { p, ready, attempts, avg, badges };
  }
  P.lamp = (id) => {
    if (id) return P.lesson(id);
    const st = lampStats();
    const modCard = (m, i) => {
      const done = st.p.done[m.id], ready = m.status === "ready";
      return `<a class="card hover mod-card" href="#/lamp/${m.id}"><span class="num">${String(i + 1).padStart(2, "0")}</span><span class="ic teal">${I.lamp}</span>
        <span class="chip teal" style="align-self:flex-start;margin-bottom:8px" dir="ltr">${esc(m.code)}</span><h3>${esc(L(m.title))}</h3><p>${esc(L(m.blurb))}</p>
        <div class="foot">${ready ? `<span class="chip">${m.mins} ${esc(t("min"))}</span>${done ? `<span class="chip ok">${I.check.replace("<svg", '<svg width="14" height="14"')} ${esc(t("completed"))}</span>` : `<span class="more" style="color:var(--teal)">${esc(t("start"))} ${I.arrow}</span>`}` : `<span class="chip">${esc(t("soon"))}</span>`}</div></a>`;
    };
    const hist = st.attempts.length ? `<div class="table-wrap" style="margin-top:14px"><table class="t"><thead><tr><th>${esc(t("modules"))}</th><th>${esc(t("yourScore"))}</th><th>${esc(t("reportDate"))}</th></tr></thead><tbody>${Object.entries(st.p.quiz).flatMap(([mid, arr]) => arr.map((a) => [mid, a])).sort((a, b) => b[1].at - a[1].at).slice(0, 8).map(([mid, a]) => { const m = S.modules.find((x) => x.id === mid); return `<tr><td>${esc(m ? L(m.title) : mid)}</td><td><span class="chip ${a.score / a.total >= 0.75 ? "ok" : "warn"}">${a.score}/${a.total}</span></td><td>${esc(fmtDate(new Date(a.at).toISOString()))}</td></tr>`; }).join("")}</tbody></table></div>` : "";
    const html = `<div class="lamp-theme">${pageHead(t("lampT"), t("lampSub"), [[t("nav.lamp")]], "lamp", { eyebrow: t("lampTag"), after: `<div class="cta" style="justify-content:flex-start"><a class="btn btn-teal" href="#/lamp/${(st.ready.find((m) => !st.p.done[m.id]) || st.ready[0]).id}">${I.lamp}<span>${esc(st.attempts.length ? t("continue") : t("start"))}</span>${I.arrow}</a><a class="btn btn-ghost" href="#/dictionary">${I.book}<span>${esc(t("dictT"))}</span></a></div>` })}
      <section class="sec"><div class="wrap">
        <div class="sec-hd"><div><span class="eyebrow">${esc(t("dashboard"))}</span><h2>${esc(t("dashboard"))}</h2><p>${esc(t("dashSub"))}</p></div>${st.attempts.length || Object.keys(st.p.done).length ? `<button class="btn btn-ghost btn-sm" id="resetProg">${I.trash}<span>${esc(t("resetProgress"))}</span></button>` : ""}</div>
        <div class="dash">
          <div class="fact"><b>${Object.keys(st.p.done).length}/${st.ready.length}</b><span>${esc(t("dDone"))}</span><div class="progress" style="margin-top:10px"><i style="width:${(Object.keys(st.p.done).length / st.ready.length) * 100}%"></i></div></div>
          <div class="fact"><b>${st.attempts.length}</b><span>${esc(t("dQuiz"))}</span></div>
          <div class="fact"><b>${st.avg}%</b><span>${esc(t("dAvg"))}</span></div>
          <div class="fact"><b>${favTerms().length + st.p.favMods.length}</b><span>${esc(t("dFav"))}</span></div>
        </div>
        <div class="card" style="margin-top:16px"><h3>${esc(t("badges"))}</h3>${st.badges.length ? `<div class="skills">${st.badges.map((m) => `<span class="chip teal">${I.award.replace("<svg", '<svg width="16" height="16"')} ${esc(L(m.title))}</span>`).join("")}</div>` : `<p style="margin:0">${esc(t("noBadges"))}</p>`}<p class="note">${esc(t("badgesNote"))}</p>${hist ? `<h3 style="margin-top:18px">${esc(t("quizHistory"))}</h3>${hist}` : ""}</div>
      </div></section>
      <section class="sec" style="padding-top:0"><div class="wrap">
        <div class="sec-hd"><div><span class="eyebrow">${esc(t("modules"))}</span><h2>${esc(t("modules"))}</h2></div></div>
        <div class="grid g3">${S.modules.map(modCard).join("")}</div>
      </div></section>
      <section class="sec" style="padding-top:0"><div class="wrap grid g2">
        <div class="card"><h3>${esc(t("paths"))}</h3><div class="paths" style="margin-top:12px">${S.paths.map((p) => `<div class="card" style="background:var(--bg-2);padding:16px"><h4 style="font-size:15px;margin-bottom:8px">${esc(L(p.t))}</h4><ol style="margin:0;padding-inline-start:18px;color:var(--muted);font-size:14px">${p.mods.map((id) => { const m = S.modules.find((x) => x.id === id); return `<li><a href="#/lamp/${id}" style="color:inherit">${esc(L(m.title))}</a>${st.p.done[id] ? " ✓" : ""}</li>`; }).join("")}</ol></div>`).join("")}</div></div>
        <div class="card"><h3>${esc(t("lampAud"))}</h3><ul class="ticks">${t("lampAudList").map((x) => `<li>${esc(x)}</li>`).join("")}</ul></div>
      </div></section></div>`;
    return { html, after: () => { const r = $("#resetProg"); r && r.addEventListener("click", () => { if (confirm(t("confirmReset"))) { store.del("progress"); route(); } }); } };
  };

  P.lesson = (id) => {
    const m = S.modules.find((x) => x.id === id);
    if (!m) return P.notfound();
    if (m.status !== "ready") return `<div class="lamp-theme">${pageHead(L(m.title), L(m.blurb), [[t("nav.lamp"), "#/lamp"], [m.code]], "lamp", { eyebrow: m.code })}<section class="sec"><div class="wrap"><div class="empty">${esc(t("soonBody"))}<div class="cta" style="justify-content:center">${btn("#/lamp", t("modules"), "btn-teal")}</div></div></div></section></div>`;
    const ls = m.lesson, p = prog.get(), isFav = p.favMods.includes(m.id), done = !!p.done[m.id];
    const secs = [["def", t("lsDef")], ["why", t("lsWhy")], ["req", t("lsReq")], ["steps", t("lsSteps")], ["ex", t("lsEx")], ["pit", t("lsPit")], ["check", t("lsCheck")], ["case", t("lsCase")], ["quiz", t("lsQuiz")], ["refs", t("lsRefs")]];
    const n = (i) => `<span class="n">${i + 1}</span>`;
    const sh = (i, body) => app.shareBtn({ k: `${m.code} · ${secs[i][1]}`, t: L(m.title), b: body, h: "#/lamp/" + m.id }, t("lsShare"), "sm");
    const html = `<div class="lamp-theme">${pageHead(L(m.title), L(m.blurb), [[t("nav.lamp"), "#/lamp"], [m.code]], "lamp", { eyebrow: m.code + " · " + m.mins + " " + t("min"), after: `<div class="cta no-print" style="justify-content:flex-start"><button class="btn ${done ? "btn-ghost" : "btn-teal"}" id="markDone">${I.check}<span>${esc(done ? t("markedDone") : t("markDone"))}</span></button><button class="btn btn-ghost" id="favMod" aria-pressed="${isFav}">${isFav ? I.starF : I.star}<span>${esc(isFav ? t("unfav") : t("fav"))}</span></button>${app.shareBtn({ k: (lang === "ar" ? "مصباح الجودة · " : "Quality Lamp · ") + m.code, t: L(m.title), b: L(ls.def), h: "#/lamp/" + m.id })}${app.likeBtn("lesson:" + m.id)}</div>` })}
    <section class="sec"><div class="wrap lesson">
      <nav class="card toc" aria-label="contents">${secs.map(([k, l], i) => `<a href="#/lamp/${m.id}" data-jump="ls-${k}">${i + 1}. ${esc(l)}</a>`).join("")}</nav>
      <article>
        <div class="print-only print-head" style="display:none"><img src="assets/logo-mark.png" alt=""><b>${esc(L(m.title))}</b></div>
        <section class="lsec" id="ls-def"><h2>${n(0)}${esc(secs[0][1])}</h2>${sh(0, L(ls.def))}<p style="font-size:17px">${esc(L(ls.def))}</p></section>
        <section class="lsec" id="ls-why"><h2>${n(1)}${esc(secs[1][1])}</h2>${sh(1, L(ls.why))}<p>${esc(L(ls.why))}</p></section>
        <section class="lsec" id="ls-req"><h2>${n(2)}${esc(secs[2][1])}</h2>${sh(2, ls.reqs.map(L))}<ul class="ticks">${ls.reqs.map((r) => `<li>${esc(L(r))}</li>`).join("")}</ul></section>
        <section class="lsec" id="ls-steps"><h2>${n(3)}${esc(secs[3][1])}</h2>${sh(3, ls.steps.map(L))}<ol class="steps">${ls.steps.map((r) => `<li>${esc(L(r))}</li>`).join("")}</ol></section>
        <section class="lsec" id="ls-ex"><h2>${n(4)}${esc(secs[4][1])}</h2>${sh(4, ["factory", "kitchen", "cafe"].map((k) => t("ex" + k[0].toUpperCase() + k.slice(1)) + ": " + L(ls.examples[k])))}<div class="ex-grid">${["factory", "kitchen", "cafe"].map((k) => `<div class="card"><h4>${esc(t("ex" + k[0].toUpperCase() + k.slice(1)))}</h4><p>${esc(L(ls.examples[k]))}</p></div>`).join("")}</div></section>
        <section class="lsec" id="ls-pit"><h2>${n(5)}${esc(secs[5][1])}</h2>${sh(5, ls.pitfalls.map(L))}<div class="grid">${ls.pitfalls.map((r) => `<div class="card pitfall" style="padding:14px 16px"><p style="margin:0;color:#dcdcdc">${esc(L(r))}</p></div>`).join("")}</div></section>
        <section class="lsec avoid" id="ls-check"><h2>${n(6)}${esc(secs[6][1])}</h2>${sh(6, ls.checklist.map((r) => "☐ " + L(r)))}<ul class="checklist">${ls.checklist.map((r) => `<li><label><input type="checkbox"> <span>${esc(L(r))}</span></label></li>`).join("")}</ul><div class="row no-print" style="margin-top:12px"><button class="btn btn-ghost btn-sm" id="printCk">${I.printer}<span>${esc(t("printChecklist"))}</span></button></div></section>
        <section class="lsec" id="ls-case"><h2>${n(7)}${esc(secs[7][1])}</h2>${sh(7, L(ls.caseStudy))}<div class="card case"><p style="margin:0;color:#e6e6e6">${esc(L(ls.caseStudy))}</p></div></section>
        <section class="lsec no-print" id="ls-quiz"><h2>${n(8)}${esc(secs[8][1])}</h2><div id="quiz"></div></section>
        <section class="lsec" id="ls-refs"><h2>${n(9)}${esc(secs[9][1])}</h2><ol class="refs">${ls.refs.map((r) => `<li>${esc(L(r))}</li>`).join("")}</ol>
          <div class="review-note"><span>${esc(t("reviewedBy"))}</span><span>·</span><span>${esc(t("lastReview"))}: ${esc(fmtDate(S.REVIEWED))}</span><span>·</span><span>${esc(t("draftNote"))}</span></div></section>
        <div class="row" style="margin-top:24px">${(() => { const ready = S.modules.filter((x) => x.status === "ready"); const i = ready.indexOf(m); const prev = ready[i - 1], next = ready[i + 1]; return `${prev ? `<a class="btn btn-ghost" href="#/lamp/${prev.id}">${I.back}<span>${esc(L(prev.title))}</span></a>` : ""}<span class="spacer"></span>${next ? `<a class="btn btn-teal" href="#/lamp/${next.id}"><span>${esc(L(next.title))}</span>${I.arrow}</a>` : ""}`; })()}</div>
      </article></div></section></div>`;
    return {
      html, title: L(m.title),
      after: () => {
        $$("[data-jump]").forEach((a) => a.addEventListener("click", (e) => { e.preventDefault(); app.scrollTo(document.getElementById(a.dataset.jump), true); }));
        $("#markDone").addEventListener("click", () => { const p = prog.get(); if (p.done[m.id]) delete p.done[m.id]; else p.done[m.id] = Date.now(); prog.save(p); toast(t("saved")); route(); });
        $("#favMod").addEventListener("click", () => { const p = prog.get(); const i = p.favMods.indexOf(m.id); i >= 0 ? p.favMods.splice(i, 1) : p.favMods.push(m.id); prog.save(p); route(); });
        $("#printCk").addEventListener("click", () => window.print());
        renderQuiz(m);
      },
    };
  };

  function renderQuiz(m) {
    const box = $("#quiz"); const ans = new Array(m.quiz.length).fill(null); let checked = false;
    const draw = () => {
      const score = ans.reduce((s, a, i) => s + (a === m.quiz[i].a ? 1 : 0), 0);
      box.innerHTML = `<div class="quiz ${checked ? "done" : ""}">${m.quiz.map((q, qi) => `<div class="card q" role="group" aria-labelledby="q${qi}"><h4 id="q${qi}">${qi + 1}. ${esc(L(q.q))}</h4><div class="opts">${q.o.map((o, oi) => {
        let cls = ""; if (checked) { if (oi === q.a) cls = "right"; else if (ans[qi] === oi) cls = "wrong"; } else if (ans[qi] === oi) cls = "sel";
        return `<button type="button" class="opt ${cls}" data-q="${qi}" data-o="${oi}" aria-pressed="${ans[qi] === oi}" ${checked ? "disabled" : ""}><span class="dot"></span><span>${esc(L(o))}</span></button>`;
      }).join("")}</div><div class="why">${esc(L(q.why))}</div></div>`).join("")}
      ${checked ? `<div class="score" role="status"><b>${score}/${m.quiz.length}</b><span>${esc(score / m.quiz.length >= 0.75 ? t("passMsg") : t("failMsg"))}</span><span class="spacer"></span><button class="btn btn-ghost btn-sm" id="qRetry">${esc(t("retry"))}</button></div>` : `<div class="row"><button class="btn btn-teal" id="qCheck">${esc(t("submitQuiz"))}</button><span class="err" id="qErr" role="alert"></span></div>`}</div>`;
      $$(".opt", box).forEach((b) => b.addEventListener("click", () => { ans[+b.dataset.q] = +b.dataset.o; draw(); const nb = box.querySelector(`.opt[data-q="${b.dataset.q}"][data-o="${b.dataset.o}"]`); nb && nb.focus(); }));
      const c = $("#qCheck", box); c && c.addEventListener("click", () => {
        if (ans.some((a) => a === null)) { $("#qErr", box).textContent = t("answerAll"); return; }
        checked = true; const p = prog.get(); (p.quiz[m.id] = p.quiz[m.id] || []).push({ score: ans.reduce((s, a, i) => s + (a === m.quiz[i].a ? 1 : 0), 0), total: m.quiz.length, at: Date.now() }); p.quiz[m.id] = p.quiz[m.id].slice(-10); prog.save(p); draw();
      });
      const r = $("#qRetry", box); r && r.addEventListener("click", () => { ans.fill(null); checked = false; draw(); });
    };
    draw();
  }

  /* ----- Dictionary ----- */
  P.dictionary = (code) => {
    const html = `${pageHead(t("dictT"), t("dictSub"), [[t("nav.dictionary")]], "", { eyebrow: t("dictTag") })}
    <section class="sec"><div class="wrap">
      <div class="searchbar">${I.search}<input type="search" id="dq" placeholder="${esc(t("dictPh"))}" aria-label="${esc(t("dictPh"))}" autocomplete="off" value="${esc(code ? decodeURIComponent(code) : "")}"></div>
      <div class="filters" role="group" aria-label="filters"><button class="chip" data-cat="" aria-pressed="true">${esc(t("allCats"))}</button>${Object.entries(S.cats).map(([k, v]) => `<button class="chip" data-cat="${k}" aria-pressed="false">${esc(L(v))}</button>`).join("")}<button class="chip" data-cat="fav" aria-pressed="false">★ ${esc(t("favOnly"))}</button></div>
      <p class="note" id="dcount" aria-live="polite" style="margin:-8px 0 14px"></p>
      <div class="terms" id="terms"></div>
      <div class="row" style="margin-top:28px"><a class="btn btn-line" id="suggestBtn" href="#">${I.plus}<span>${esc(t("suggest"))}</span></a><span class="note" style="margin:0">${esc(t("suggestNote"))}</span></div>
      <p class="note">${esc(t("dictReview"))} · ${esc(t("lastReview"))}: ${esc(fmtDate(S.REVIEWED))}</p>
    </div></section>`;
    return {
      html, after: () => {
        let cat = ""; const q = $("#dq");
        const draw = () => {
          const nq = norm(q.value), favs = favTerms();
          const list = S.dict.filter((d) => (cat === "fav" ? favs.includes(d.code) : !cat || d.category === cat) && (!nq || norm([d.code, d.term_en, d.term_ar, d.simple_explanation_ar, d.simple_explanation_en].join(" ")).includes(nq)))
            .sort((a, b) => { if (!nq) return 0; const sa = norm(a.code) === nq || norm(a.term_en) === nq ? 0 : norm(a.code).startsWith(nq) ? 1 : 2, sb = norm(b.code) === nq || norm(b.term_en) === nq ? 0 : norm(b.code).startsWith(nq) ? 1 : 2; return sa - sb; });
          $("#dcount").textContent = `${list.length} ${t("termsCount")}`;
          $("#terms").innerHTML = list.length ? list.map((d) => { const f = favs.includes(d.code); return `<article class="card term" id="term-${esc(d.code.replace(/\W/g, ""))}">
            <div class="tools"><button class="icon-btn" data-say="${esc(d.term_en)}" aria-label="${esc(t("listen"))}: ${esc(d.term_en)}" title="${esc(t("listen"))}">${I.sound}</button><button class="icon-btn ${f ? "fav-on" : ""}" data-fav="${esc(d.code)}" aria-pressed="${f}" aria-label="${esc(f ? t("unfav") : t("fav"))}">${f ? I.starF : I.star}</button>${app.shareBtn({ k: (lang === "ar" ? "قاموس الجودة · " : "Quality Dictionary · ") + L(S.cats[d.category]), t: d.code + " — " + (lang === "ar" ? d.term_ar : d.term_en), b: [lang === "ar" ? d.term_en : d.term_ar, lang === "ar" ? d.simple_explanation_ar : d.simple_explanation_en, d.example_ar ? (t("example") + ": " + (lang === "ar" ? d.example_ar : d.example_en)) : ""].filter(Boolean), h: "#/dictionary/" + encodeURIComponent(d.code) }, t("share"), "icon")}</div>
            <span class="code">${esc(d.code)}</span><span class="en" lang="en">${esc(d.term_en)}</span><span class="ar" lang="ar" dir="rtl">${esc(d.term_ar)}</span>
            <p class="exp">${esc(lang === "ar" ? d.simple_explanation_ar : d.simple_explanation_en)}</p>
            ${d.example_ar ? `<div class="exm"><b>${esc(t("example"))}:</b> ${esc(lang === "ar" ? d.example_ar : d.example_en)}</div>` : ""}
            <div class="row" style="margin-top:6px;gap:6px"><span class="chip">${esc(L(S.cats[d.category]))}</span>${d.related.length ? `<span class="note" style="margin:0">${esc(t("related"))}:</span><span class="rel">${d.related.map((r) => `<button data-rel="${esc(r)}">${esc(r)}</button>`).join("")}</span>` : ""}</div></article>`; }).join("") : `<div class="empty" style="grid-column:1/-1">${esc(t("noResults"))}</div>`;
        };
        q.addEventListener("input", draw);
        $$(".filters .chip").forEach((b) => b.addEventListener("click", () => { cat = b.dataset.cat; $$(".filters .chip").forEach((x) => x.setAttribute("aria-pressed", x === b)); draw(); }));
        $("#terms").addEventListener("click", (e) => {
          const s = e.target.closest("[data-say]"), f = e.target.closest("[data-fav]"), r = e.target.closest("[data-rel]");
          if (s) { if ("speechSynthesis" in window) { const u = new SpeechSynthesisUtterance(s.dataset.say); u.lang = "en-US"; u.rate = 0.9; speechSynthesis.cancel(); speechSynthesis.speak(u); } else toast("Speech not supported", "bad"); }
          if (f) { const list = favTerms(); const i = list.indexOf(f.dataset.fav); i >= 0 ? list.splice(i, 1) : list.push(f.dataset.fav); store.set("favTerms", list); draw(); const nf = $(`[data-fav="${CSS.escape(f.dataset.fav)}"]`); nf && nf.focus(); }
          if (r) { q.value = r.dataset.rel; cat = ""; $$(".filters .chip").forEach((x) => x.setAttribute("aria-pressed", x.dataset.cat === "")); draw(); app.scrollTo(q, true); }
        });
        $("#suggestBtn").addEventListener("click", (e) => { e.preventDefault(); const sub = lang === "ar" ? "اقتراح مصطلح لقاموس الجودة" : "Quality Dictionary — term suggestion"; const body = lang === "ar" ? "الرمز/الاختصار:\nالمصطلح الإنجليزي:\nالمقابل العربي:\nالشرح المبسط:\nالمرجع:\n" : "Code / abbreviation:\nEnglish term:\nArabic term:\nPlain explanation:\nReference:\n"; location.href = `mailto:${S.profile.email}?subject=${encodeURIComponent(sub)}&body=${encodeURIComponent(body)}`; });
        draw();
      },
    };
  };

  /* ----- Knowledge ----- */
  const renderBody = (blocks) => blocks.map(([k, v]) => (k === "h" ? `<h2>${esc(v)}</h2>` : k === "ul" ? `<ul>${v.map((x) => `<li>${esc(x)}</li>`).join("")}</ul>` : `<p>${esc(v)}</p>`)).join("");
  P.knowledge = (id) => {
    if (id) {
      const a = S.articles.find((x) => x.id === id); if (!a) return P.notfound();
      return { title: L(a.title), html: `${pageHead(L(a.title), L(a.sum), [[t("nav.knowledge"), "#/knowledge"], [L(a.title)]], "", { eyebrow: a.type === "guide" ? t("typeGuide") : t("typeArticle") })}
      <section class="sec"><div class="wrap"><article class="article">
        <div class="byline"><span>${esc(t("author"))}: Eng. Alaeldeen</span><span>${esc(t("published"))}: ${esc(fmtDate(a.date))}</span><span>${esc(t("lastReview"))}: ${esc(fmtDate(S.REVIEWED))}</span><span>${a.mins} ${esc(t("readMin"))}</span></div><div class="row" style="margin:-8px 0 22px">${app.likeBtn("article:" + a.id)}${app.shareBtn({ k: a.type === "guide" ? t("typeGuide") : t("typeArticle"), t: L(a.title), b: L(a.sum), h: "#/knowledge/" + a.id })}</div>
        ${renderBody(a.body[lang])}
        <h2>${esc(t("refsT"))}</h2><ol class="refs">${a.refs.map((r) => `<li>${esc(L(r))}</li>`).join("")}</ol>
        <div class="row" style="margin-top:28px"><a class="btn btn-ghost" href="#/knowledge">${I.back}<span>${esc(t("knowT"))}</span></a><span class="spacer"></span><button class="btn btn-ghost no-print" onclick="window.print()">${I.printer}<span>${esc(t("print"))}</span></button></div>
      </article></div></section>` };
    }
    return `${pageHead(t("knowT"), t("knowSub"), [[t("nav.knowledge")]])}
    <section class="sec"><div class="wrap">
      <div class="grid g3">${S.articles.map((a) => `<a class="card hover" href="#/knowledge/${a.id}" style="display:flex;flex-direction:column"><span class="chip ${a.type === "guide" ? "teal" : "gold"}" style="align-self:flex-start;margin-bottom:12px">${esc(a.type === "guide" ? t("typeGuide") : t("typeArticle"))}</span><h3>${esc(L(a.title))}</h3><p>${esc(L(a.sum))}</p><div class="row" style="margin-top:auto"><span class="note" style="margin:0">${a.mins} ${esc(t("readMin"))} · ${esc(fmtDate(a.date))}</span><span class="spacer"></span><span class="more">${esc(t("read"))} ${I.arrow}</span></div></a>`).join("")}
        <a class="card hover" href="#/lamp" style="display:flex;flex-direction:column"><span class="chip teal" style="align-self:flex-start;margin-bottom:12px">${esc(t("lampT"))}</span><h3>${esc(t("lsCheck"))} · ${esc(t("lsCase"))}</h3><p>${esc(t("lampSub"))}</p><span class="more" style="margin-top:auto">${esc(t("open"))} ${I.arrow}</span></a>
      </div></div></section>
    <section class="sec" style="padding-top:0"><div class="wrap grid g2" style="align-items:start">
      <div><h2 style="font-size:24px">${esc(t("faqT"))}</h2>${S.faq.map((f) => `<details class="faq"><summary>${esc(L(f.q))}</summary><p>${esc(L(f.a))}</p></details>`).join("")}</div>
      <div><h2 style="font-size:24px">${esc(t("sourcesT"))}</h2><div class="grid">${S.sources.map((s) => `<a class="card hover" href="${s.u}" target="_blank" rel="noopener" style="padding:16px 18px;display:flex;align-items:center;gap:12px"><span class="ic" style="margin:0;width:38px;height:38px">${I.globe}</span><span style="flex:1"><b style="font-size:15px">${esc(s.n)}</b><small style="display:block;color:var(--dim);direction:ltr;text-align:start">${esc(s.u.replace(/^https?:\/\//, ""))}</small></span>${I.arrow.replace("<svg", '<svg width="18" height="18"')}</a>`).join("")}</div></div>
    </div></section>`;
  };

  /* ----- Projects ----- */
  P.books = () => ({
    html: `${pageHead(t("books.t"), t("books.sub"), [[t("nav.books")]])}
    <section class="sec"><div class="wrap">${S.books.map((b) => b.featured ? `<article class="card book-hero" id="${b.id}">
        ${videoBox(b)}
        <div class="bh-body"><span class="eyebrow">${esc(L(b.kind))}</span><h2 class="book-title">${esc(L(b.title))}</h2><p class="book-sub">${esc(L(b.subtitle))} · ${esc(t("books.by"))}</p>
          <p style="color:#dcdcdc">${esc(L(b.blurb))}</p>
          <div class="chain">${b.chain.map((c, i) => `<span>${esc(L(c))}</span>${i < b.chain.length - 1 ? I.arrow : ""}`).join("")}</div>
          <h3 style="font-size:16px;margin-top:18px">${esc(t("books.forWho"))}</h3><p>${esc(L(b.audience))}</p>
          <div class="cta" style="justify-content:flex-start"><a class="btn btn-gold" href="${b.url}" target="_blank" rel="noopener">${I.youtube}<span>${esc(L(b.cta))}</span></a></div><p class="note">${esc(t("books.vNote"))}</p></div></article>`
      : `<article class="card book-row" id="${b.id}"><a href="${b.url}" target="_blank" rel="noopener" class="book-thumb"><img src="${b.cover}" alt="${esc(L(b.title))}" loading="lazy" width="${b.coverW}" height="${b.coverH}"></a><div><span class="eyebrow">${esc(L(b.kind))}</span><h2 class="book-title" style="font-size:28px">${esc(L(b.title))}</h2><p class="book-sub">${esc(L(b.subtitle))}</p><p>${esc(L(b.blurb))}</p><a class="btn btn-line" href="${b.url}" target="_blank" rel="noopener">${I.book}<span>${esc(L(b.cta))}</span>${I.external}</a></div></article>`).join("")}
    </div></section>`,
    after: () => $$(".video[data-yt]").forEach((v) => v.querySelector(".play").addEventListener("click", () => {
      v.innerHTML = `<iframe src="https://www.youtube-nocookie.com/embed/${v.dataset.yt}?autoplay=1&rel=0" title="${esc(t("books.play"))}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>`;
    })),
  });
  P.links = () => `${pageHead(t("linksT"), t("linksSub"), [[t("linksT")]])}<section class="sec"><div class="wrap">${linksGrid()}</div></section>`;

  P.projects = () => `${pageHead(t("projT"), t("projSub"), [[t("nav.projects")]])}
    <section class="sec"><div class="wrap grid g2">${S.projects.map((p) => `<article class="card proj"><span class="chip gold" style="justify-self:start">${esc(L(p.tag))}</span><h3 style="margin:4px 0 0">${esc(L(p.title))}</h3>
      <dl>${[["pProblem", p.problem], ["pRole", p.role], ["pMethod", p.method], ["pResult", p.result], ["pLearned", p.learned]].map(([k, v]) => `<dt>${esc(t(k))}</dt><dd>${esc(L(v))}</dd>`).join("")}</dl></article>`).join("")}</div></section>`;

  /* ----- Contact ----- */
  P.contact = () => {
    const pr = S.profile;
    return {
      html: `${pageHead(t("contactT"), t("contactSub"), [[t("nav.contact")]])}
      <section class="sec"><div class="wrap grid g2" style="align-items:start">
        <form class="card" id="cform" novalidate><div class="form">
          <div class="field"><label class="req" for="cn">${esc(t("name"))}</label><input type="text" id="cn" autocomplete="name" required><span class="err" id="cn-e"></span></div>
          <div class="field"><label class="req" for="ce">${esc(t("yourEmail"))}</label><input type="email" id="ce" autocomplete="email" required dir="ltr"><span class="err" id="ce-e"></span></div>
          <div class="field full"><label for="cs">${esc(t("subject"))}</label><input type="text" id="cs"></div>
          <div class="field full"><label class="req" for="cm">${esc(t("message"))}</label><textarea id="cm" rows="6" required></textarea><span class="err" id="cm-e"></span></div>
          <div class="full row"><button class="btn btn-gold" type="submit">${I.mail}<span>${esc(t("send"))}</span></button><a class="btn btn-ghost" id="cwa" href="https://wa.me/${pr.whatsapp}" target="_blank" rel="noopener">${I.wa}<span>${esc(t("sendWa"))}</span></a></div>
          <p class="note full" style="margin:0">${esc(t("formNote"))}</p></div></form>
        <div class="grid">
          <a class="card hover cert" href="mailto:${pr.email}"><span class="ic">${I.mail}</span><div><h4>${esc(t("email"))}</h4><small dir="ltr">${pr.email}</small></div></a>
          <a class="card hover cert" href="https://wa.me/${pr.whatsapp}" target="_blank" rel="noopener"><span class="ic">${I.wa}</span><div><h4>WhatsApp</h4><small dir="ltr">${pr.phone}</small></div></a>
          <div class="card cert"><span class="ic">${I.pin}</span><div><h4>${esc(t("location"))}</h4><small>${esc(L(pr.location))}</small></div></div>
          <div class="card cert"><span class="ic">${I.download}</span><div><h4>${esc(t("downloadCV"))}</h4><small><a href="cv/Alaeldeen_Omer_CV_AR.pdf" download>${esc(t("cvAr"))}</a> · <a href="cv/Alaeldeen_Omer_CV_EN.pdf" download>${esc(t("cvEn"))}</a></small></div></div>
        </div></div></section>
      <section class="sec" style="padding-top:0" id="links"><div class="wrap"><div class="sec-hd"><div><span class="eyebrow">Linktree</span><h2>${esc(t("linksT"))}</h2><p>${esc(t("linksSub"))}</p></div></div>${linksGrid()}</div></section>`,
      after: () => {
        const f = $("#cform");
        const val = () => {
          let ok = true; const set = (id, msg) => { const el = $("#" + id); el.setAttribute("aria-invalid", msg ? "true" : "false"); $("#" + id + "-e").textContent = msg || ""; if (msg) ok = false; };
          set("cn", $("#cn").value.trim() ? "" : t("required"));
          const em = $("#ce").value.trim(); set("ce", !em ? t("required") : /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em) ? "" : t("badEmail"));
          set("cm", $("#cm").value.trim() ? "" : t("required"));
          return ok;
        };
        f.addEventListener("submit", (e) => {
          e.preventDefault(); if (!val()) { toast(t("fixErrors"), "bad"); const bad = $("[aria-invalid=true]", f); bad && bad.focus(); return; }
          const body = `${$("#cm").value.trim()}\n\n— ${$("#cn").value.trim()} <${$("#ce").value.trim()}>`;
          location.href = `mailto:${pr.email}?subject=${encodeURIComponent($("#cs").value.trim() || "Website contact")}&body=${encodeURIComponent(body)}`;
        });
        $("#cwa").addEventListener("click", (e) => { const m = $("#cm").value.trim(); if (m) { e.preventDefault(); window.open(`https://wa.me/${pr.whatsapp}?text=${encodeURIComponent(m + ($("#cn").value.trim() ? "\n— " + $("#cn").value.trim() : ""))}`, "_blank", "noopener"); } });
      },
    };
  };

  P.privacy = () => {
    const ar = lang === "ar";
    const eff = "2026-11-04";
    const sec = ar ? [
      ["من نحن", "هذا الموقع هو الموقع المهني للمهندس علاء الدين البشرى عمر، أخصائي جودة وسلامة الغذاء، ويضم منصة «مصباح الجودة» وأدوات الجودة والقاموس والمكتبة والمساعد الذكي. للتواصل في أي أمر يخص الخصوصية: aladeen35@gmail.com."],
      ["البيانات التي نجمعها", "لا نطلب منك إنشاء حساب ولا نجمع اسمك أو بريدك أو موقعك. لا نستخدم ملفات تعريف الارتباط (Cookies) للتتبع ولا أدوات تحليلات أو إعلانات."],
      ["ما يُحفظ على جهازك فقط", "ما تدخله في الأدوات (التفتيش، NCR، تحليل السبب الجذري، المخاطر، سجل الحرارة، خطط HACCP، نتائج CFU) وتقدمك في الدروس والمفضلة واللغة المختارة يُحفظ في متصفحك (التخزين المحلي) على جهازك فقط، ولا يصل إلينا. يمكنك حذفه من زر الحذف في كل أداة أو بمسح بيانات الموقع من إعدادات المتصفح."],
      ["الصور والتقارير", "الصور التي تضيفها إلى تقارير عدم المطابقة تُصغَّر وتبقى على جهازك. لا تضف صور منشأة أو تقاريرها دون موافقتها، ولا تضف صورًا تُظهر وجوه أشخاص دون إذنهم."],
      ["المساعد الذكي", "عند استخدام المساعد يُرسَل نص سؤالك ومحادثتك الحالية إلى مزود خدمة الذكاء الاصطناعي (Puter، أو خادم وسيط يتصل بخدمة Anthropic) لتوليد الرد، وتخضع لسياسات ذلك المزود. قد يطلب Puter موافقة أو تسجيل دخول مجاني. لا تكتب بيانات شخصية أو سرية أو معلومات داخلية لجهة عملك. تُحفظ المحادثة في متصفحك أثناء الجلسة فقط."],
      ["خدمات وروابط خارجية", "تُحمَّل الخطوط من Google Fonts. فيديو عرض الكتاب يعمل من YouTube (youtube-nocookie) فقط عند الضغط على التشغيل. روابط المكتبة والمصادر تفتح مواقع رسمية خارجية لها سياساتها الخاصة. الموقع مستضاف على GitHub Pages، وقد تحتفظ GitHub بسجلات تقنية (مثل عنوان IP) وفق سياستها."],
      ["نموذج التواصل", "نموذج التواصل يفتح تطبيق البريد أو واتساب لديك برسالة جاهزة؛ لا تمر الرسالة عبر خادم هذا الموقع."],
      ["المحتوى التعليمي", "الدروس والأدوات والقاموس والمساعد لأغراض تعليمية ومساندة، ولا تحل محل التشريعات ومتطلبات الجهات الرقابية (مثل الهيئة العامة للغذاء والدواء) والمواصفات المعتمدة ودراسات المنشأة. لا تقترح الأدوات حدودًا حرجة أو جرعات تعقيم عامة."],
      ["الأطفال", "الموقع موجه للمختصين والطلاب ولا يجمع أي بيانات عن الأطفال."],
      ["التعديلات", "قد نحدّث هذه السياسة عند إضافة خدمات جديدة، ويظهر تاريخ آخر تحديث أدناه."],
    ] : [
      ["Who we are", "This is the professional site of Eng. Alaeldeen Albushra Omer, a food quality & safety specialist. It includes the Quality Lamp platform, quality tools, dictionary, library and AI assistant. For any privacy question: aladeen35@gmail.com."],
      ["What we collect", "No account is needed and we don't collect your name, email or location. We use no tracking cookies, analytics or advertising tools."],
      ["What stays on your device", "What you enter in the tools (inspections, NCRs, root cause analysis, risks, temperature log, HACCP plans, CFU results), your lesson progress, favourites and language are kept in your browser's local storage on your device only and never reach us. Delete it with each tool's delete button or by clearing this site's data in your browser."],
      ["Photos and reports", "Photos added to NCRs are resized and stay on your device. Don't add photos or reports of a facility without its consent, or photos showing people's faces without their permission."],
      ["AI assistant", "When you use the assistant, your question and the current conversation are sent to the AI provider (Puter, or a relay server connected to Anthropic) to generate the reply, under that provider's policies. Puter may ask for approval or a free sign-in. Don't enter personal, confidential or internal company information. The conversation is kept in your browser for the session only."],
      ["External services and links", "Fonts load from Google Fonts. The book video plays from YouTube (youtube-nocookie) only when you press play. Library and source links open official external sites with their own policies. The site is hosted on GitHub Pages, which may keep technical logs (such as IP addresses) under its own policy."],
      ["Contact form", "The contact form opens your own email app or WhatsApp with the message ready; nothing passes through this site's server."],
      ["Educational content", "Lessons, tools, dictionary and assistant are educational and supportive. They don't replace regulations, authority requirements (such as SFDA), approved standards or your site's own studies. The tools never suggest general critical limits or sanitiser doses."],
      ["Children", "The site is meant for professionals and students and collects no data about children."],
      ["Changes", "We may update this policy when new services are added; the last update date is shown below."],
    ];
    return `${pageHead(t("privacyT"), ar ? "كيف نتعامل مع بياناتك، باختصار ووضوح." : "How your data is handled, in plain words.", [[t("privacyT")]])}<section class="sec"><div class="wrap article">${sec.map(([h, p]) => `<h2>${esc(h)}</h2><p>${esc(p)}</p>`).join("")}<p class="note">${esc(t("lastReview"))}: ${esc(fmtDate(eff))}</p></div></section>`;
  };

  P.notfound = () => `${pageHead(t("notFound"), "", null)}<section class="sec"><div class="wrap">${btn("#/", t("backHome"))}</div></section>`;

  /* ---------- global search ---------- */
  function searchIndex() {
    const items = [];
    const add = (type, title, sub, href, extra) => items.push({ type, title, sub, href, hay: norm([title, sub, extra].join(" ")) });
    NAV.forEach(([k, h]) => add("page", t("nav." + k), "", h));
    add("page", t("navLong.experience"), L(S.profile.title), "#/experience");
    add("page", t("navLong.certifications"), "", "#/certifications");
    S.modules.forEach((m) => add("lesson", L(m.title), m.code + " · " + L(m.blurb), "#/lamp/" + m.id, m.lesson ? [L(m.lesson.def), m.lesson.reqs.map(L).join(" ")].join(" ") : ""));
    (window.TOOLS ? window.TOOLS.list : []).forEach((x) => add("tool", L(x.t), L(x.d), "#/tools/" + x.id));
    S.dict.forEach((d) => add("term", d.code + " — " + (lang === "ar" ? d.term_ar : d.term_en), lang === "ar" ? d.term_en : d.term_ar, "#/dictionary/" + encodeURIComponent(d.code), d.simple_explanation_ar + " " + d.simple_explanation_en));
    S.articles.forEach((a) => add("article", L(a.title), L(a.sum), "#/knowledge/" + a.id, a.body[lang].map((b) => [].concat(b[1]).join(" ")).join(" ")));
    S.projects.forEach((p) => add("project", L(p.title), L(p.tag), "#/projects"));
    (app.searchExtra || []).forEach((f) => f(add));
    S.books.forEach((b) => add("book", L(b.title), L(b.subtitle), "#/books", L(b.blurb) + " Stolen Gold الذهب المسلوب"));
    S.links.groups.forEach((g) => g.items.forEach((it) => add("link", L(it.n), it.d, "#/links")));
    return items;
  }
  const typeLabel = { page: { ar: "صفحة", en: "Page" }, lesson: { ar: "درس", en: "Lesson" }, tool: { ar: "أداة", en: "Tool" }, term: { ar: "مصطلح", en: "Term" }, article: { ar: "مقال", en: "Article" }, project: { ar: "مشروع", en: "Project" }, book: { ar: "كتاب", en: "Book" }, link: { ar: "رابط", en: "Link" } };
  let lastFocus = null;
  function openSearch() {
    lastFocus = document.activeElement; const dlg = $("#searchDlg"); dlg.classList.add("open"); const q = $("#sq"); q.value = ""; $("#sres").innerHTML = `<div class="hint">${esc(t("searchHint"))}</div>`; q.focus();
    const idx = searchIndex(); let act = 0;
    const draw = () => {
      const nq = norm(q.value); if (nq.length < 2) { $("#sres").innerHTML = `<div class="hint">${esc(t("searchHint"))}</div>`; return; }
      const words = nq.split(" "); const res = idx.filter((x) => words.every((w) => x.hay.includes(w))).sort((a, b) => (norm(a.title).includes(nq) ? 0 : 1) - (norm(b.title).includes(nq) ? 0 : 1)).slice(0, 14);
      act = Math.min(act, Math.max(0, res.length - 1));
      $("#sres").innerHTML = res.length ? res.map((r, i) => `<a href="${r.href}" role="option" class="${i === act ? "act" : ""}" aria-selected="${i === act}"><span class="chip ${r.type === "lesson" ? "teal" : r.type === "term" ? "gold" : ""}">${esc(L(typeLabel[r.type]))}</span><span><b>${esc(r.title)}</b>${r.sub ? `<small>${esc(r.sub.slice(0, 110))}</small>` : ""}</span></a>`).join("") : `<div class="hint">${esc(t("noResults"))}</div>`;
    };
    q.oninput = () => { act = 0; draw(); };
    q.onkeydown = (e) => {
      const links = $$("#sres a");
      if (e.key === "ArrowDown") { e.preventDefault(); act = Math.min(act + 1, links.length - 1); draw(); }
      else if (e.key === "ArrowUp") { e.preventDefault(); act = Math.max(act - 1, 0); draw(); }
      else if (e.key === "Enter" && links[act]) { e.preventDefault(); location.hash = links[act].getAttribute("href"); closeSearch(); }
    };
  }
  function closeSearch() { $("#searchDlg").classList.remove("open"); lastFocus && lastFocus.focus && lastFocus.focus(); }

  /* ---------- router ---------- */
  function route() {
    const h = location.hash.replace(/^#\/?/, ""); const [path, ...rest] = h.split("/"); const sub = rest.join("/");
    const name = path || "home";
    let fn = P[name] || (name === "tools" && window.TOOLS && window.TOOLS.page);
    if (!fn) fn = P.notfound;
    let out = fn(sub || undefined);
    if (typeof out === "string") out = { html: out };
    const main = $("#app"); main.innerHTML = out.html;
    markNav(path || "");
    const pageTitle = out.title || (name === "home" ? "" : ((name === "links" ? t("linksT") : t("nav." + ({ about: "profile", experience: "profile", certifications: "profile" }[name] || name))) || ""));
    document.title = (pageTitle && !String(pageTitle).startsWith("nav.") ? pageTitle + " | " : "") + "Eng. Alaeldeen | Quality & Safety";
    app.scrollTo(0, false);
    out.after && out.after();
    window.MOTION && window.MOTION.apply(main);
    const h1 = $("h1", main); if (h1 && app._navigated) h1.focus({ preventScroll: true });
    app._navigated = true;
    closeDrawer();
  }
  app.route = route;
  function closeDrawer() { const d = $("#drawer"); if (d.classList.contains("open")) { d.classList.remove("open"); const b = $("#openMenu"); b && b.setAttribute("aria-expanded", "false"); } }

  function setLang(l) { if (l === lang) return; lang = l; store.set("lang", l); renderChrome(); route(); }

  /* ---------- boot ---------- */
  document.addEventListener("DOMContentLoaded", () => {
    renderChrome(); route();
    window.addEventListener("hashchange", route);
    document.addEventListener("click", (e) => {
      const lb = e.target.closest("[data-lang]"); if (lb) setLang(lb.dataset.lang);
      if (e.target.closest("#openMenu")) { $("#drawer").classList.add("open"); $("#openMenu").setAttribute("aria-expanded", "true"); setTimeout(() => $("#drawer .close").focus(), 10); }
      if (e.target.closest("#drawer [data-close]")) closeDrawer();
      if (e.target.closest("#drawer a")) closeDrawer();
      if (e.target.closest("#openSearch")) openSearch();
      if (e.target.closest("#searchDlg [data-close]") || e.target.id === "searchDlg") closeSearch();
      if (e.target.closest("#sres a")) closeSearch();
    });
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") { closeSearch(); closeDrawer(); }
      if (e.key === "/" && !/INPUT|TEXTAREA|SELECT/.test(document.activeElement.tagName)) { e.preventDefault(); openSearch(); }
    });
    if ("serviceWorker" in navigator && location.protocol === "https:") navigator.serviceWorker.register("sw.js").catch(() => {});
  });
})();
