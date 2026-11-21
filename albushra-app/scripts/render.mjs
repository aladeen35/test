// HTML for albushra.app: an app-store style home page and one store listing
// per app. Pure functions of the registry; build.mjs writes the files.
//
// Both languages are rendered into the page and CSS shows the active one, so
// switching is instant, there is no flash, and search engines see both.

export function createRenderer({ company, categories, apps, APEX }) {
  const esc = (s = "") => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const t2 = (o) => (o && typeof o === "object" ? o : { ar: o || "", en: o || "" });
  const bi = (o, tag = "span", cls = "") => {
    const x = t2(o);
    const c = cls ? ` ${cls}` : "";
    return `<${tag} lang="ar" class="l-ar${c}">${esc(x.ar)}</${tag}><${tag} lang="en" class="l-en${c}">${esc(x.en)}</${tag}>`;
  };
  const byId = Object.fromEntries(apps.map((a) => [a.id, a]));
  const pick = (ids) => (ids || []).map((id) => byId[id]).filter(Boolean);
  const cat = (id) => categories.find((c) => c.id === id) || { id, name: { ar: id, en: id } };
  const appUrl = (a) => (a.subdomain ? `https://${a.subdomain}.${APEX}/` : a.links?.web || "#");
  const icon = (a, base) => (a.icon ? `${base}icons/${a.icon}` : `${base}brand/mark-192.png`);
  const page = (a, base) => `${base}apps/${a.id}/`;
  const store = company.store || {};

  const STATUS = {
    live: { ar: "منشور", en: "Live" },
    beta: { ar: "تجريبي", en: "Beta" },
    prototype: { ar: "نموذج أولي", en: "Prototype" },
    soon: { ar: "قريبًا", en: "Coming soon" },
    archived: { ar: "مؤرشف", en: "Archived" },
  };

  // ---------- icons (inline SVG, stroke = currentColor) ----------
  const P = {
    faith: '<path d="M12 3c-2 2.5-5 3-5 7a5 5 0 0 0 10 0c0-4-3-4.5-5-7z"/><path d="M5 21h14M7 21v-4M17 21v-4"/>',
    education: '<path d="M2 9l10-5 10 5-10 5z"/><path d="M6 11v5c0 1.5 3 3 6 3s6-1.5 6-3v-5"/>',
    community: '<path d="M12 21s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 5.6-7 10-7 10z"/>',
    quality: '<path d="M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z"/><path d="M9 12l2 2 4-4"/>',
    media: '<rect x="3" y="5" width="18" height="12" rx="2"/><path d="M10 9l4 2-4 2z"/><path d="M8 21h8"/>',
    kids: '<circle cx="12" cy="12" r="9"/><path d="M8.5 14a4 4 0 0 0 7 0"/><path d="M9 9.5h.01M15 9.5h.01"/>',
    games: '<rect x="2.5" y="7" width="19" height="11" rx="5"/><path d="M7 12.5h4M9 10.5v4M15.5 11.5h.01M17.5 13.5h.01"/>',
    commerce: '<path d="M4 7h16l-1.5 12a2 2 0 0 1-2 1.8h-9a2 2 0 0 1-2-1.8z"/><path d="M9 10V6a3 3 0 0 1 6 0v4"/>',
    tools: '<path d="M14.5 6.5a4 4 0 0 0-5.3 5.3L4 17l3 3 5.2-5.2a4 4 0 0 0 5.3-5.3l-2.5 2.5-2.5-.5-.5-2.5z"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>',
    home: '<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/>',
    grid: '<rect x="4" y="4" width="7" height="7" rx="2"/><rect x="13" y="4" width="7" height="7" rx="2"/><rect x="4" y="13" width="7" height="7" rx="2"/><rect x="13" y="13" width="7" height="7" rx="2"/>',
    flask: '<path d="M9 3h6M10 3v6l-5 9a2 2 0 0 0 1.8 3h10.4a2 2 0 0 0 1.8-3l-5-9V3"/><path d="M7.5 15h9"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
    moon: '<path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/>',
    play: '<path d="M5 3.5l14 8.5-14 8.5z"/>',
    open: '<path d="M14 4h6v6"/><path d="M20 4l-9 9"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/>',
    download: '<path d="M12 4v11"/><path d="M7 10l5 5 5-5"/><path d="M5 20h14"/>',
    users: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 14a6 6 0 0 1 3.5 6"/>',
    check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    arrow: '<path d="M15 6l-6 6 6 6"/>',
    code: '<path d="M8 7l-5 5 5 5"/><path d="M16 7l5 5-5 5"/><path d="M14 4l-4 16"/>',
    ai: '<path d="M9 4a3 3 0 0 0-3 3 3 3 0 0 0-2 5 3 3 0 0 0 2 5 3 3 0 0 0 6 1V5a2 2 0 0 0-3-1z"/><path d="M15 4a3 3 0 0 1 3 3 3 3 0 0 1 2 5 3 3 0 0 1-2 5 3 3 0 0 1-6 1"/>',
    cloud: '<path d="M7 18h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 9a4.5 4.5 0 0 0 1 9z"/>',
    phone: '<rect x="7" y="2.5" width="10" height="19" rx="2"/><path d="M11 18.5h2"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a14 14 0 0 1 0 18a14 14 0 0 1 0-18"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3.5 6l8.5 7 8.5-7"/>',
    infra: '<rect x="4" y="4" width="16" height="6" rx="1.5"/><rect x="4" y="14" width="16" height="6" rx="1.5"/><path d="M8 7h.01M8 17h.01"/>',
  };
  const svg = (name, size = 22, cls = "") =>
    `<svg class="ic${cls ? " " + cls : ""}" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[name] || P.grid}</svg>`;

  // ---------- the one action a store tile offers ----------
  function primary(a, base) {
    const L = a.links || {};
    const isApp = a.route?.mode === "proxy" || a.route?.mode === "dns" || L.web;
    if (L.play) return { url: L.play, ext: true, ic: "play", label: { ar: "تثبيت", en: "Install" } };
    if (L.testing) return { url: `${page(a, base)}#test`, ic: "flask", label: { ar: "جرّب", en: "Test" } };
    if (isApp) return { url: appUrl(a), ext: true, ic: "open", label: { ar: "افتح", en: "Open" } };
    if (L.apk) return { url: L.apk, ext: true, ic: "download", label: { ar: "تنزيل", en: "Get" } };
    return { url: page(a, base), ic: "info", label: { ar: "التفاصيل", en: "Details" } };
  }
  const getBtn = (a, base, cls = "get") => {
    const p = primary(a, base);
    return `<a class="${cls}" href="${esc(p.url)}"${p.ext ? ' rel="noopener"' : ""}>${bi(p.label)}</a>`;
  };
  const platforms = (a) => (a.platforms || ["Web"]).join(" · ");

  // ---------- shared chrome ----------
  function layout({ title, description, canonical, body, base = "/", jsonld = null, image = null }) {
    return `<!doctype html>
<html lang="ar" dir="rtl" data-lang="ar">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<link rel="canonical" href="${esc(canonical)}">
<link rel="alternate" hreflang="ar" href="${esc(canonical)}">
<link rel="alternate" hreflang="en" href="${esc(canonical)}?lang=en">
<meta property="og:type" content="website">
<meta property="og:site_name" content="${esc(company.name.en)} | ${esc(company.name.ar)}">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:url" content="${esc(canonical)}">
<meta property="og:image" content="${esc(image || `https://${APEX}/brand/og.jpg`)}">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#040d26">
<link rel="icon" href="${base}brand/mark-192.png" type="image/png">
<link rel="apple-touch-icon" href="${base}brand/mark-192.png">
<link rel="manifest" href="${base}manifest.webmanifest">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Alexandria:wght@500;600;700;800&family=IBM+Plex+Sans+Arabic:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="${base}assets/site.css">
<script>(function(){var d=document.documentElement;d.classList.add('js');try{var q=new URLSearchParams(location.search).get('lang');var l=q||localStorage.getItem('ab-lang');if(l==='en'){d.setAttribute('data-lang','en');d.lang='en';d.dir='ltr';}var th=localStorage.getItem('ab-theme');if(th)d.setAttribute('data-theme',th);}catch(e){}})();</script>
${jsonld ? `<script type="application/ld+json">${JSON.stringify(jsonld)}</script>` : ""}
</head>
<body>
<a class="skip" href="#main">${bi({ ar: "تخطَّ إلى المحتوى", en: "Skip to content" })}</a>
<div class="bg-deco" aria-hidden="true"><span class="slant s1"></span><span class="slant s2"></span><span class="orb o1"></span><span class="orb o2"></span></div>
${header(base)}
<main id="main">
${body}
</main>
${footer(base)}
${tabbar(base)}
<script src="${base}assets/site.js" defer></script>
</body>
</html>`;
  }

  function header(base) {
    return `<header class="topbar">
  <div class="wrap topbar-in">
    <a class="brand" href="${base}" aria-label="${esc(company.name.ar)} — ${esc(company.name.en)}">
      <img src="${base}brand/mark-192.png" width="40" height="40" alt="">
      <span class="brand-txt">${bi(company.name)}<small>ALBUSHRA TECHNOLOGY</small></span>
    </a>
    <form class="top-search" role="search" action="${base}" data-top-search>
      ${svg("search", 18)}
      <label class="sr" for="q-top">${bi({ ar: "ابحث في التطبيقات", en: "Search apps" })}</label>
      <input id="q-top" name="q" type="search" placeholder="ابحث عن تطبيق أو لعبة… / Search" autocomplete="off">
    </form>
    <nav class="nav" aria-label="main">
      <a href="${base}#apps">${bi({ ar: "التطبيقات", en: "Apps" })}</a>
      <a href="${base}#cat-games">${bi({ ar: "الألعاب", en: "Games" })}</a>
      <a href="${base}#testers">${bi({ ar: "المختبرون", en: "Testers" })}</a>
      <a href="${base}#about">${bi({ ar: "من نحن", en: "About" })}</a>
    </nav>
    <div class="tools">
      <button class="btn-ghost" type="button" data-toggle-lang aria-label="Language / اللغة">${bi({ ar: "EN", en: "ع" })}</button>
      <button class="btn-ghost" type="button" data-toggle-theme aria-label="Theme / المظهر">${svg("moon", 18)}</button>
    </div>
  </div>
</header>`;
  }

  // Store-style bottom tab bar on phones.
  function tabbar(base) {
    const t = [
      ["home", base, { ar: "الرئيسية", en: "Home" }],
      ["grid", `${base}#apps`, { ar: "التطبيقات", en: "Apps" }],
      ["games", `${base}#cat-games`, { ar: "الألعاب", en: "Games" }],
      ["flask", `${base}#testers`, { ar: "المختبرون", en: "Testers" }],
      ["info", `${base}#about`, { ar: "من نحن", en: "About" }],
    ];
    return `<nav class="tabbar" aria-label="tabs">${t.map(([i, u, l]) => `<a href="${u}">${svg(i, 22)}${bi(l)}</a>`).join("")}</nav>`;
  }

  function footer(base) {
    const used = categories.filter((k) => apps.some((a) => a.category === k.id));
    return `<footer class="footer">
  <div class="wrap footer-in">
    <div class="f-brand">
      <img src="${base}brand/mark-192.png" width="56" height="56" alt="" loading="lazy">
      <b>${bi(company.name)}</b>
      <p class="muted">${bi(company.tagline)}</p>
      <span class="dots" aria-hidden="true"><i></i><i></i><i></i></span>
    </div>
    <div>
      <h3>${bi({ ar: "الأقسام", en: "Categories" })}</h3>
      <ul>${used.map((k) => `<li><a href="${base}#cat-${k.id}">${bi(k.name)}</a></li>`).join("")}</ul>
    </div>
    <div>
      <h3>${bi({ ar: "روابط", en: "Links" })}</h3>
      <ul>
        <li><a href="${base}#testers">${bi({ ar: "برنامج المختبرين", en: "Testers program" })}</a></li>
        <li><a href="${base}registry.json">${bi({ ar: "سجل الإصدارات (JSON)", en: "Release registry (JSON)" })}</a></li>
        ${company.contact?.email ? `<li><a href="mailto:${esc(company.contact.email)}">${esc(company.contact.email)}</a></li>` : ""}
      </ul>
    </div>
  </div>
  <p class="wrap copy">© ${new Date().getFullYear()} ${bi(company.name)} · albushra.app</p>
</footer>`;
  }

  // ---------- store building blocks ----------
  // Compact store tile: icon, name, category, one action.
  function tile(a, base, opts = {}) {
    return `<article class="tile${opts.rank ? " ranked" : ""}" data-app="${esc(a.id)}" data-cat="${esc(a.category)}" style="--accent:${esc(a.color || "#2f6bff")}" ${opts.reveal === false ? "" : "data-reveal"}>
  ${opts.rank ? `<span class="rank" aria-hidden="true"></span>` : ""}
  <a class="tile-link" href="${page(a, base)}"><span class="sr">${esc(t2(a.name).ar)} — ${esc(t2(a.name).en)}</span></a>
  <img class="app-icon" src="${icon(a, base)}" width="64" height="64" alt="" loading="lazy">
  <div class="tile-txt">
    <h3>${bi(a.name)}</h3>
    <p>${bi(cat(a.category).name)}${(a.platforms || []).includes("Android") ? ` · ${bi({ ar: "أندرويد", en: "Android" })}` : ""}${(a.platforms || []).includes("Web") ? ` · ${bi({ ar: "ويب", en: "Web" })}` : ""}</p>
  </div>
  ${getBtn(a, base)}
</article>`;
  }

  // Large card for "new releases" (like the old site's cards, with the ribbon).
  function bigCard(a, base) {
    const v = a.resolvedVersion?.value;
    const isNew = a.status === "beta" || a.links?.testing;
    return `<article class="bcard" data-app="${esc(a.id)}" style="--accent:${esc(a.color || "#2f6bff")}" data-reveal>
  ${isNew ? `<span class="ribbon">${bi({ ar: "جديد", en: "New" })}</span>` : ""}
  <a class="tile-link" href="${page(a, base)}"><span class="sr">${esc(t2(a.name).ar)}</span></a>
  <div class="bcard-top">
    <img class="app-icon" src="${icon(a, base)}" width="72" height="72" alt="" loading="lazy">
    <div>
      <h3>${bi(a.name)}</h3>
      <div class="chips"><span class="chip">${bi(cat(a.category).name)}</span>${v ? `<span class="chip gold">v${esc(v)}</span>` : ""}${a.links?.testing ? `<span class="chip chip-test">${bi({ ar: "تجربة Google Play", en: "Play testing" })}</span>` : ""}</div>
    </div>
  </div>
  <p class="clamp3">${bi(a.description || a.tagline)}</p>
  ${getBtn(a, base, "btn wide")}
</article>`;
  }

  // Featured slide: brand-coloured banner with a phone showing the real app.
  function slide(a, base, i) {
    const shot = a.screenshots?.[0];
    return `<article class="slide" data-app="${esc(a.id)}" style="--accent:${esc(a.color || "#2f6bff")}" aria-roledescription="slide" aria-label="${i + 1}">
  <div class="slide-txt">
    <span class="eyebrow">${svg(a.category, 16)}${bi(cat(a.category).name)}</span>
    <div class="slide-id"><img class="app-icon" src="${icon(a, base)}" width="64" height="64" alt="" ${i ? 'loading="lazy"' : ""}><h3>${bi(a.name)}</h3></div>
    <p>${bi(a.tagline)}</p>
    <div class="cta">${getBtn(a, base, "btn")}<a class="btn btn-alt" href="${page(a, base)}">${bi({ ar: "التفاصيل", en: "Details" })}</a></div>
  </div>
  ${shot ? `<div class="phone" aria-hidden="true"><img src="${base}shots/${esc(shot)}" width="390" height="844" alt="" ${i ? 'loading="lazy"' : ""}></div>` : `<div class="slide-mark" aria-hidden="true"><img src="${icon(a, base)}" width="160" height="160" alt="" loading="lazy"></div>`}
</article>`;
  }

  const shelf = (id, title, sub, inner, cls = "") => `<section class="shelf wrap ${cls}" id="${id}">
  <div class="sec-head" data-reveal>
    <h2>${bi(title)}</h2>
    ${sub ? `<p class="muted">${bi(sub)}</p>` : ""}
  </div>
  ${inner}
</section>`;
  const row = (list, fn, base) => `<div class="row" data-row>${list.map((a) => fn(a, base)).join("")}</div>`;

  function testersBox(list, base) {
    const g = company.testers?.group;
    if (!g || !list.length) return "";
    return `<div class="testers" data-reveal>
  <ol>
    <li><span class="step">1</span><div><b>${bi({ ar: "انضم لقروب المختبرين (خطوة أساسية)", en: "Join the testers group (required)" })}</b>
      <p class="muted">${bi({ ar: "بنفس حساب Google الموجود على هاتفك.", en: "With the same Google account as your phone." })}</p>
      <a class="btn" href="${esc(g)}" rel="noopener">${svg("users", 18)}${bi({ ar: "الانضمام للقروب", en: "Join the group" })}</a></div></li>
    <li><span class="step">2</span><div><b>${bi(list.length > 1 ? { ar: "حمّل وجرّب التطبيقات", en: "Install and try the apps" } : { ar: "انضم للتجربة وحمّل التطبيق", en: "Opt in and install the app" })}</b>
      <div class="tester-apps">${list
        .map((a) => `<a class="tester-app" data-app="${esc(a.id)}" href="${esc(a.links.testing)}" rel="noopener" style="--accent:${esc(a.color || "#2f6bff")}"><img src="${icon(a, base)}" width="44" height="44" alt="" loading="lazy"><span><b>${bi(a.name)}</b><small>${bi(a.tagline)}</small></span>${svg("play", 16, "go")}</a>`)
        .join("")}</div></div></li>
  </ol>
</div>`;
  }

  // ---------- home ----------
  function home() {
    const base = "/";
    const featured = pick(store.featured);
    const fresh = pick(store.fresh);
    const picks = pick(store.picks);
    const testers = pick(company.testers?.apps).filter((a) => a.links?.testing);
    const groups = categories.map((k) => ({ k, list: apps.filter((a) => a.category === k.id) })).filter((g) => g.list.length);
    const stats = [
      { n: apps.length, l: { ar: "منتجًا رقميًا", en: "products" } },
      { n: apps.filter((a) => (a.platforms || []).includes("Android")).length, l: { ar: "تطبيق أندرويد", en: "Android apps" } },
      { n: apps.filter((a) => a.category === "games" || a.category === "kids").length, l: { ar: "لعبة", en: "games" } },
      { n: apps.filter((a) => a.subdomain && a.route?.mode === "proxy").length, l: { ar: "على الويب", en: "on the web" } },
    ];
    const services = [
      ["code", "Development"], ["ai", "AI Solutions"], ["cloud", "Cloud"], ["phone", "Mobile Apps"], ["globe", "Web Platforms"],
    ];

    const body = `
<section class="hero wrap">
  <div class="hero-id" data-reveal>
    <div class="hero-brand">
      <img class="hero-mark" src="${base}brand/mark-512.png" width="150" height="150" alt="" fetchpriority="high">
      <div>
        <h1>${bi(company.name)}</h1>
        <p class="hero-en">Al-<b>Bushra</b> Technology</p>
      </div>
    </div>
    <span class="dots" aria-hidden="true"><i></i><i></i><i></i></span>
    <p class="slogan">Building meaningful digital products</p>
    <p class="lead">${bi(company.headline)}</p>
    <div class="cta">
      <a class="btn" href="#apps">${bi({ ar: "تصفّح المتجر", en: "Browse the store" })}</a>
      <a class="btn btn-alt" href="#testers">${svg("flask", 18)}${bi({ ar: "كن من المختبرين", en: "Become a tester" })}</a>
    </div>
    <div class="services">${services.map(([i, l]) => `<div class="svc">${svg(i, 26)}<span>${l}</span></div>`).join("")}</div>
  </div>
  <div class="hero-visual" data-reveal>
    <img src="${base}brand/hero.webp" width="1000" height="973" alt="" fetchpriority="high">
    <div class="stats">${stats.map((s) => `<div class="stat"><b data-count="${s.n}">${s.n}</b>${bi(s.l)}</div>`).join("")}</div>
  </div>
</section>

<section class="featured wrap" aria-label="featured" data-carousel>
  <div class="sec-head" data-reveal><h2>${bi({ ar: "مختارات البشري", en: "Albushra picks" })}</h2></div>
  <div class="slides" data-slides>${featured.map((a, i) => slide(a, base, i)).join("")}</div>
  <div class="slide-dots" role="tablist">${featured.map((a, i) => `<button type="button" role="tab" aria-label="${esc(t2(a.name).ar)}" data-app="${esc(a.id)}" data-dot="${i}"${i ? "" : ' aria-selected="true"'}><i></i></button>`).join("")}</div>
</section>

<section class="wrap cats" aria-label="categories">
  <div class="cat-grid">${groups
    .map(
      (g) => `<a class="cat" href="#cat-${g.k.id}" data-reveal>${svg(g.k.id, 26)}<b>${bi(g.k.name)}</b><span>${g.list.length}</span></a>`
    )
    .join("")}</div>
</section>

${shelf("new", { ar: "أحدث الإصدارات", en: "New releases" }, { ar: "تطبيقات وصلت حديثًا أو في مرحلة التجربة", en: "Just arrived or in testing" }, row(fresh, bigCard, base))}

${shelf("top", { ar: "اخترنا لك", en: "Top picks" }, { ar: "أبرز ما صنعناه", en: "The best of what we make" }, `<div class="charts">${picks.map((a, i) => tile(a, base, { rank: i + 1 })).join("")}</div>`)}

${testers.length ? shelf("testers", { ar: "كن من المختبرين", en: "Become a tester" }, { ar: "جرّب تطبيقاتنا على Google Play قبل الجميع، وساعدنا في تحسينها.", en: "Try our apps on Google Play before everyone else and help us improve them." }, testersBox(testers, base), "testers-shelf") : ""}

<section id="apps" class="wrap shelf all">
  <div class="sec-head" data-reveal>
    <h2>${bi({ ar: "كل التطبيقات", en: "All apps" })} <span class="count">${apps.length}</span></h2>
    <p class="muted">${bi({ ar: "كل منتج على نطاقه الخاص تحت albushra.app، بأحدث إصدار منشور.", en: "Every product on its own albushra.app subdomain, at its latest version." })}</p>
  </div>
  <div class="filters" role="toolbar" aria-label="filter">
    <button class="pill is-on" data-filter="all" aria-pressed="true">${bi({ ar: "الكل", en: "All" })}</button>
    ${groups.map((g) => `<button class="pill" data-filter="${esc(g.k.id)}" aria-pressed="false">${bi(g.k.name)}</button>`).join("")}
  </div>
  <label class="search">${svg("search", 18)}<span class="sr">${bi({ ar: "بحث", en: "Search" })}</span>
    <input type="search" data-search placeholder="ابحث عن تطبيق أو لعبة… / Search apps…" autocomplete="off"></label>
  <p class="empty muted" data-empty hidden>${bi({ ar: "لا توجد نتائج.", en: "No results." })}</p>
  ${groups
    .map(
      (g) => `<div class="group" id="cat-${esc(g.k.id)}" data-group="${esc(g.k.id)}">
    <h3 class="group-title">${svg(g.k.id, 20)}${bi(g.k.name)} <span class="muted">${bi(g.k.desc)}</span></h3>
    <div class="tiles">${g.list.map((a) => tile(a, base)).join("")}</div>
  </div>`
    )
    .join("")}
</section>

<section id="about" class="section about">
  <div class="wrap about-in">
    <div data-reveal>
      <p class="eyebrow">${bi({ ar: "من نحن", en: "Who we are" })}</p>
      <h2>${bi({ ar: "عن البشري للتكنولوجيا", en: "About Albushra Technology" })}</h2>
      ${(company.about || []).map((p) => `<p>${bi(p)}</p>`).join("")}
    </div>
    <ul class="values">${(company.values || []).map((v) => `<li data-reveal><b>${bi(v.title)}</b><span>${bi(v.text)}</span></li>`).join("")}</ul>
  </div>
</section>

<section id="contact" class="wrap shelf">
  <div class="sec-head" data-reveal><h2>${bi({ ar: "تواصل ودعم", en: "Contact & support" })}</h2></div>
  <div class="contact">${(company.channels || [])
    .map((c) => `<a class="contact-item" href="${esc(c.url)}" rel="noopener" data-reveal>${svg(c.url.startsWith("mailto:") ? "mail" : "open", 22)}<span><b>${bi(c.label)}</b><small class="mono">${esc(c.display || c.url.replace(/^mailto:|^https?:\/\//, ""))}</small></span></a>`)
    .join("")}</div>
</section>`;

    return layout({
      title: `${company.name.ar} | ${company.name.en} — متجر التطبيقات`,
      description: `${t2(company.intro).ar} — ${t2(company.intro).en}`,
      canonical: `https://${APEX}/`,
      body,
      jsonld: {
        "@context": "https://schema.org",
        "@type": "Organization",
        name: company.name.en,
        alternateName: company.name.ar,
        url: `https://${APEX}/`,
        logo: `https://${APEX}/brand/logo.png`,
        email: company.contact?.email,
        sameAs: (company.channels || []).map((c) => c.url).filter((u) => u.startsWith("http")),
      },
    });
  }

  // ---------- app listing ----------
  function appPage(a) {
    const base = "../../";
    const v = a.resolvedVersion?.value;
    const f = t2(a.features);
    const L = a.links || {};
    const isApp = a.route?.mode === "proxy" || a.route?.mode === "dns" || L.web;
    const buttons = [
      L.play ? `<a class="btn" href="${esc(L.play)}" rel="noopener">${svg("play", 18)}${bi({ ar: "تثبيت من Google Play", en: "Install on Google Play" })}</a>` : "",
      !L.play && L.testing ? `<a class="btn" href="#test">${svg("flask", 18)}${bi({ ar: "انضم للتجربة", en: "Join the test" })}</a>` : "",
      isApp ? `<a class="btn${L.play || L.testing ? " btn-alt" : ""}" href="${esc(appUrl(a))}" rel="noopener">${svg("open", 18)}${bi({ ar: "افتح التطبيق", en: "Open the app" })}</a>` : "",
      L.apk ? `<a class="btn btn-alt" href="${esc(L.apk)}" rel="noopener">${svg("download", 18)}${bi({ ar: "تنزيل APK", en: "Download APK" })}</a>` : "",
      ...(L.extra || []).map((x) => `<a class="btn btn-alt" href="${esc(x.url)}" rel="noopener">${bi(x.label)}</a>`),
    ].join("");
    const facts = [
      [{ ar: "الإصدار", en: "Version" }, v ? `<b class="mono">${esc(v)}</b>` : "<b>—</b>"],
      [{ ar: "السعر", en: "Price" }, `<b>${bi({ ar: "مجاني", en: "Free" })}</b>`],
      [{ ar: "الحالة", en: "Status" }, `<b>${bi(STATUS[a.status] || STATUS.live)}</b>`],
      [{ ar: "المنصات", en: "Platforms" }, `<b>${esc(platforms(a))}</b>`],
    ];
    const same = apps.filter((x) => x.id !== a.id && x.category === a.category);
    const more = [...same, ...pick(store.picks).filter((x) => x.id !== a.id && !same.includes(x))].slice(0, 8);

    const body = `
<section class="listing wrap" style="--accent:${esc(a.color || "#2f6bff")}">
  <nav class="crumbs" aria-label="breadcrumb"><a href="${base}">${bi({ ar: "المتجر", en: "Store" })}</a>${svg("arrow", 14, "sep")}<a href="${base}#cat-${esc(a.category)}">${bi(cat(a.category).name)}</a></nav>
  <div class="listing-head" data-reveal>
    <img class="app-icon xl" src="${base}icons/${esc(a.icon || "bushra.webp")}" width="120" height="120" alt="">
    <div>
      <h1>${bi(a.name)}</h1>
      <p class="dev">${bi(company.name)}</p>
      <p class="lead">${bi(a.tagline)}</p>
    </div>
  </div>
  <dl class="facts-strip" data-reveal>${facts.map(([k, val]) => `<div><dt>${bi(k)}</dt><dd>${val}</dd></div>`).join("")}</dl>
  <div class="cta" data-reveal>${buttons}</div>
  ${a.subdomain && isApp ? `<p class="muted small mono domain">${svg("globe", 14)} ${esc(a.subdomain)}.${esc(APEX)}</p>` : ""}
</section>

${a.screenshots?.length ? `<section class="wrap shots-wrap" aria-label="screenshots"><div class="shots" data-row>${a.screenshots.map((s) => `<div class="phone sm"><img src="${base}shots/${esc(s)}" width="390" height="844" alt="" loading="lazy"></div>`).join("")}</div></section>` : ""}

${L.testing ? `<section class="wrap shelf" id="test">${testersBox([a], base)}</section>` : ""}

<section class="wrap shelf listing-body">
  <div data-reveal>
    <h2>${bi({ ar: "عن التطبيق", en: "About this app" })}</h2>
    <p class="prose">${bi(a.description)}</p>
    ${
      f.ar?.length || f.en?.length
        ? `<h2>${bi({ ar: "المزايا", en: "Features" })}</h2>
    <ul class="features l-ar" lang="ar">${(f.ar || []).map((x) => `<li>${svg("check", 18)}<span>${esc(x)}</span></li>`).join("")}</ul>
    <ul class="features l-en" lang="en">${(f.en || []).map((x) => `<li>${svg("check", 18)}<span>${esc(x)}</span></li>`).join("")}</ul>`
        : ""
    }
  </div>
  <aside class="facts" data-reveal>
    <h2>${bi({ ar: "معلومات", en: "Details" })}</h2>
    <dl>
      <dt>${bi({ ar: "المطوّر", en: "Developer" })}</dt><dd>${bi(company.name)}</dd>
      <dt>${bi({ ar: "التصنيف", en: "Category" })}</dt><dd>${bi(cat(a.category).name)}</dd>
      <dt>${bi({ ar: "الإصدار", en: "Version" })}</dt><dd class="mono">${esc(v || "—")}</dd>
      <dt>${bi({ ar: "المنصات", en: "Platforms" })}</dt><dd>${esc(platforms(a))}</dd>
      ${a.audience ? `<dt>${bi({ ar: "الفئة", en: "Audience" })}</dt><dd>${bi(a.audience)}</dd>` : ""}
      ${L.privacy ? `<dt>${bi({ ar: "الخصوصية", en: "Privacy" })}</dt><dd><a href="${esc(L.privacy)}">${bi({ ar: "سياسة الخصوصية", en: "Privacy policy" })}</a></dd>` : ""}
      ${company.contact?.email ? `<dt>${bi({ ar: "الدعم", en: "Support" })}</dt><dd><a href="mailto:${esc(company.contact.email)}">${esc(company.contact.email)}</a></dd>` : ""}
    </dl>
  </aside>
</section>

${more.length ? shelf("more", { ar: "قد يعجبك أيضًا", en: "You might also like" }, null, row(more, (x, b) => tile(x, b, { reveal: false }), base)) : ""}`;

    const shot = a.screenshots?.[0];
    return layout({
      title: `${t2(a.name).ar} | ${t2(a.name).en} — ${company.name.ar}`,
      description: `${t2(a.tagline).ar} — ${t2(a.tagline).en}`,
      canonical: `https://${APEX}/apps/${a.id}/`,
      base,
      body,
      image: shot ? `https://${APEX}/shots/${shot}` : null,
      jsonld: {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        name: t2(a.name).en,
        alternateName: t2(a.name).ar,
        applicationCategory: a.schemaCategory || "EducationalApplication",
        operatingSystem: (a.platforms || ["Web"]).join(", "),
        softwareVersion: v || undefined,
        url: appUrl(a),
        image: `https://${APEX}/icons/${a.icon || "bushra.webp"}`,
        screenshot: (a.screenshots || []).map((s) => `https://${APEX}/shots/${s}`),
        offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
        publisher: { "@type": "Organization", name: company.name.en, url: `https://${APEX}/` },
      },
    });
  }

  return { home, appPage };
}
