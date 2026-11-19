// Builds everything from registry/apps.json (the Application Registry):
//   dist/site      -> albushra.app (home + one page per app, sitemap, robots)
//   dist/site/dash -> dash.albushra.app (served by the router from /dash/)
//   worker/routes.json -> the router's host table
//
// Versions: each app may declare version.source (a JSON URL, e.g. the app's
// own version.json). The build fetches it so a new release shows up on the
// site and dashboard on the next scheduled build without editing anything.
// Offline builds (or failing sources) fall back to version.current.
//
// Usage: node scripts/build.mjs [--offline]

import { readFile, writeFile, mkdir, cp, rm, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const OUT = join(ROOT, "dist", "site");
const OFFLINE = process.argv.includes("--offline");
// HUB_ORIGIN lets a local test point the router at a local copy of the site.
const HUB = process.env.HUB_ORIGIN || null;

const registry = JSON.parse(await readFile(join(ROOT, "registry", "apps.json"), "utf8"));
const { company, categories } = registry;
const APEX = company.domain;
const HUB_ORIGIN_FINAL = HUB || registry.hub.pagesOrigin;
const apps = registry.apps.filter((a) => a.status !== "hidden");

// ---------- versions ----------
async function resolveVersion(app) {
  const v = app.version || {};
  const result = { value: v.current || null, source: v.source || null, checkedAt: null, live: false };
  if (OFFLINE || !v.source) return result;
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 10000);
    const res = await fetch(v.source, { signal: ctrl.signal, headers: { "cache-control": "no-cache" } });
    clearTimeout(t);
    if (!res.ok) throw new Error(res.status);
    const data = await res.json();
    const val = (v.field || "version").split(".").reduce((o, k) => (o == null ? o : o[k]), data);
    if (val) Object.assign(result, { value: String(val), live: true, checkedAt: new Date().toISOString() });
  } catch (e) {
    console.warn(`version: ${app.id}: ${v.source} -> ${e.message || e}`);
  }
  return result;
}

for (const app of apps) app.resolvedVersion = await resolveVersion(app);

// ---------- helpers ----------
const esc = (s = "") => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const t2 = (o) => (o && typeof o === "object" ? o : { ar: o || "", en: o || "" });
// Both languages are rendered; CSS shows the active one (no flash, SEO sees both).
const bi = (o, tag = "span") => {
  const x = t2(o);
  return `<${tag} lang="ar" class="l-ar">${esc(x.ar)}</${tag}><${tag} lang="en" class="l-en">${esc(x.en)}</${tag}>`;
};
const appUrl = (a) => (a.subdomain ? `https://${a.subdomain}.${APEX}/` : a.links?.web || "#");
const cat = (id) => categories.find((c) => c.id === id) || { id, name: { ar: id, en: id } };
const STATUS = {
  live: { ar: "منشور", en: "Live" },
  beta: { ar: "تجريبي", en: "Beta" },
  prototype: { ar: "نموذج أولي", en: "Prototype" },
  soon: { ar: "قريبًا", en: "Coming soon" },
  archived: { ar: "مؤرشف", en: "Archived" },
};
const icon = (a, base) => (a.icon ? `${base}icons/${a.icon}` : `${base}brand/mark.png`);

function layout({ title, description, canonical, body, base = "/", lang = "ar", extraHead = "", jsonld = null }) {
  return `<!doctype html>
<html lang="${lang}" dir="rtl" data-lang="ar">
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
<meta property="og:image" content="https://${APEX}/brand/og.jpg">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#070d24" media="(prefers-color-scheme: dark)">
<meta name="theme-color" content="#f5f7ff" media="(prefers-color-scheme: light)">
<link rel="icon" href="${base}brand/mark-192.png" type="image/png">
<link rel="apple-touch-icon" href="${base}brand/mark-192.png">
<link rel="manifest" href="${base}manifest.webmanifest">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&family=Readex+Pro:wght@500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="${base}assets/site.css">
<script>(function(){try{var q=new URLSearchParams(location.search).get('lang');var l=q||localStorage.getItem('ab-lang');if(l==='en'){document.documentElement.setAttribute('data-lang','en');document.documentElement.lang='en';document.documentElement.dir='ltr';}var th=localStorage.getItem('ab-theme');if(th)document.documentElement.setAttribute('data-theme',th);}catch(e){}})();</script>
${jsonld ? `<script type="application/ld+json">${JSON.stringify(jsonld)}</script>` : ""}
${extraHead}
</head>
<body>
<a class="skip" href="#main">${bi({ ar: "تخطَّ إلى المحتوى", en: "Skip to content" })}</a>
${header(base)}
<main id="main">
${body}
</main>
${footer(base)}
<script src="${base}assets/site.js" defer></script>
</body>
</html>`;
}

function header(base) {
  return `<header class="topbar">
  <div class="wrap topbar-in">
    <a class="brand" href="${base}" aria-label="${esc(company.name.ar)}">
      <img src="${base}brand/mark-192.png" width="40" height="40" alt="">
      <span class="brand-txt">${bi(company.shortName)}<small>${bi({ ar: "تكنولوجي", en: "Technology" })}</small></span>
    </a>
    <nav class="nav" aria-label="main">
      <a href="${base}#apps">${bi({ ar: "التطبيقات", en: "Apps" })}</a>
      <a href="${base}#testers">${bi({ ar: "المختبرون", en: "Testers" })}</a>
      <a href="${base}#about">${bi({ ar: "عن الشركة", en: "About" })}</a>
      <a href="${base}#contact">${bi({ ar: "تواصل", en: "Contact" })}</a>
    </nav>
    <div class="tools">
      <button class="btn-ghost" type="button" data-toggle-lang aria-label="Language">${bi({ ar: "EN", en: "ع" })}</button>
      <button class="btn-ghost" type="button" data-toggle-theme aria-label="Theme"><svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9z"/></svg></button>
    </div>
  </div>
</header>`;
}

function footer(base) {
  const c = company.contact || {};
  return `<footer class="footer">
  <div class="wrap footer-in">
    <div>
      <img src="${base}brand/logo.png" width="96" height="96" alt="${esc(company.name.en)}" loading="lazy">
      <p class="muted">${bi(company.tagline)}</p>
    </div>
    <div>
      <h3>${bi({ ar: "التصنيفات", en: "Categories" })}</h3>
      <ul>${categories.filter((k) => apps.some((a) => a.category === k.id)).map((k) => `<li><a href="${base}#cat-${k.id}">${bi(k.name)}</a></li>`).join("")}</ul>
    </div>
    <div>
      <h3>${bi({ ar: "روابط", en: "Links" })}</h3>
      <ul>
        <li><a href="https://dash.${APEX}/">${bi({ ar: "لوحة التطبيقات", en: "Apps dashboard" })}</a></li>
        <li><a href="${base}registry.json">${bi({ ar: "سجل الإصدارات (JSON)", en: "Release registry (JSON)" })}</a></li>
        ${c.email ? `<li><a href="mailto:${esc(c.email)}">${esc(c.email)}</a></li>` : ""}
      </ul>
    </div>
  </div>
  <p class="wrap copy">© ${new Date().getFullYear()} ${bi(company.name)}</p>
</footer>`;
}

function card(a, base) {
  const v = a.resolvedVersion?.value;
  return `<article class="card" data-cat="${esc(a.category)}" data-status="${esc(a.status)}" style="--accent:${esc(a.color || "#3b82f6")}">
  <a class="card-link" href="${base}apps/${esc(a.id)}/" aria-label="${esc(t2(a.name).ar)} — ${esc(t2(a.name).en)}"></a>
  <div class="card-top">
    <img class="app-icon" src="${icon(a, base)}" width="56" height="56" alt="" loading="lazy">
    <span class="badge s-${esc(a.status)}">${bi(STATUS[a.status] || STATUS.live)}</span>
  </div>
  <h3>${bi(a.name)}</h3>
  <p>${bi(a.tagline)}</p>
  <div class="card-meta">
    <span class="chip">${bi(cat(a.category).name)}</span>
    ${v ? `<span class="chip mono">v${esc(v)}</span>` : ""}
    ${(a.platforms || []).map((p) => `<span class="chip">${esc(p)}</span>`).join("")}
  </div>
</article>`;
}

// ---------- home ----------
function home() {
  const base = "/";
  const live = apps.filter((a) => ["live", "beta"].includes(a.status));
  const groups = categories
    .map((k) => ({ k, list: apps.filter((a) => a.category === k.id) }))
    .filter((g) => g.list.length);
  const stats = [
    { n: apps.length, l: { ar: "منتجًا رقميًا", en: "digital products" } },
    { n: live.length, l: { ar: "منشورة للمستخدمين", en: "live for users" } },
    { n: apps.filter((a) => (a.platforms || []).includes("Android")).length, l: { ar: "تطبيقات أندرويد", en: "Android apps" } },
    { n: categories.filter((k) => apps.some((a) => a.category === k.id)).length, l: { ar: "مجالات", en: "domains" } },
  ];
  const testers = (company.testers?.apps || []).map((id) => apps.find((a) => a.id === id)).filter((a) => a?.links?.testing);
  const body = `
<section class="hero">
  <div class="hero-bg" aria-hidden="true"><span class="orb o1"></span><span class="orb o2"></span><span class="grid-lines"></span></div>
  <div class="wrap hero-in">
    <div class="hero-txt">
      <p class="eyebrow">${bi({ ar: "البشرى للتكنولوجيا", en: "ALBUSHRA TECHNOLOGY" })}</p>
      <h1>${bi(company.headline)}</h1>
      <p class="lead">${bi(company.intro)}</p>
      <div class="cta">
        <a class="btn" href="#apps">${bi({ ar: "استكشف التطبيقات", en: "Explore the apps" })}</a>
        <a class="btn btn-alt" href="#about">${bi({ ar: "من نحن", en: "Who we are" })}</a>
      </div>
    </div>
    <div class="hero-art"><img src="${base}brand/logo.png" width="360" height="360" alt="${esc(company.name.en)}" fetchpriority="high"></div>
  </div>
  <div class="wrap stats">${stats.map((s) => `<div class="stat"><b>${s.n}</b>${bi(s.l)}</div>`).join("")}</div>
</section>

<section id="apps" class="wrap section">
  <div class="sec-head">
    <h2>${bi({ ar: "منظومة التطبيقات", en: "The app ecosystem" })}</h2>
    <p class="muted">${bi({ ar: "كل منتج على نطاقه الخاص تحت albushra.app، بأحدث إصدار منشور.", en: "Every product on its own subdomain of albushra.app, at its latest published version." })}</p>
  </div>
  <div class="filters" role="toolbar" aria-label="filter">
    <button class="pill is-on" data-filter="all" aria-pressed="true">${bi({ ar: "الكل", en: "All" })}</button>
    ${groups.map((g) => `<button class="pill" data-filter="${esc(g.k.id)}" aria-pressed="false">${bi(g.k.name)}</button>`).join("")}
  </div>
  <label class="search"><span class="sr">${bi({ ar: "بحث", en: "Search" })}</span>
    <input type="search" data-search placeholder="ابحث عن تطبيق… / Search apps…" autocomplete="off"></label>
  ${groups
    .map(
      (g) => `<div class="group" id="cat-${esc(g.k.id)}" data-group="${esc(g.k.id)}">
    <h3 class="group-title">${bi(g.k.name)} <span class="muted">${bi(g.k.desc)}</span></h3>
    <div class="cards">${g.list.map((a) => card(a, base)).join("")}</div>
  </div>`
    )
    .join("")}
</section>

${testers.length ? `<section id="testers" class="wrap section">
  <div class="sec-head">
    <h2>${bi({ ar: "كن من المختبرين", en: "Become a tester" })}</h2>
    <p class="muted">${bi({ ar: "جرّب تطبيقاتنا على Google Play قبل الجميع وساعدنا في تحسينها.", en: "Try our apps on Google Play before everyone else and help us improve them." })}</p>
  </div>
  ${testersBox(testers, base)}
</section>` : ""}

<section id="about" class="section about">
  <div class="wrap about-in">
    <div>
      <h2>${bi({ ar: "عن البشرى للتكنولوجيا", en: "About Albushra Technology" })}</h2>
      ${(company.about || []).map((p) => `<p>${bi(p)}</p>`).join("")}
    </div>
    <ul class="values">${(company.values || []).map((v) => `<li><b>${bi(v.title)}</b><span>${bi(v.text)}</span></li>`).join("")}</ul>
  </div>
</section>

<section id="contact" class="wrap section">
  <div class="sec-head"><h2>${bi({ ar: "تواصل ودعم", en: "Contact & support" })}</h2></div>
  <div class="contact">${(company.channels || [])
    .map((c) => `<a class="contact-item" href="${esc(c.url)}" rel="noopener"><b>${bi(c.label)}</b><span class="mono">${esc(c.display || c.url.replace(/^mailto:|^https?:\/\//, ""))}</span></a>`)
    .join("")}</div>
</section>`;
  return layout({
    title: `${company.name.ar} | ${company.name.en}`,
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

// ---------- Google Play testing ----------
// Closed testing needs two steps: join the Google Group, then opt in per app.
function testersBox(list, base) {
  const g = company.testers?.group;
  if (!g) return "";
  return `<div class="testers">
  <ol>
    <li><b>${bi({ ar: "انضم لقروب المختبرين (خطوة أساسية)", en: "Join the testers group (required)" })}</b>
      <a class="btn" href="${esc(g)}" rel="noopener">${bi({ ar: "الانضمام للقروب", en: "Join the group" })}</a></li>
    <li><b>${bi(list.length > 1 ? { ar: "حمّل وجرّب التطبيقات", en: "Install and try the apps" } : { ar: "انضم للتجربة وحمّل التطبيق", en: "Opt in and install the app" })}</b>
      <div class="tester-apps">${list
        .map((a) => `<a class="tester-app" href="${esc(a.links.testing)}" rel="noopener"><img src="${icon(a, base)}" width="40" height="40" alt="" loading="lazy"><span><b>${bi(a.name)}</b><small>${bi(a.tagline)}</small></span></a>`)
        .join("")}</div></li>
  </ol>
</div>`;
}

// ---------- app page ----------
function appPage(a) {
  const base = "../../";
  const v = a.resolvedVersion;
  const f = t2(a.features);
  const L = a.links || {};
  const actions = [
    // Redirect-mode subdomains point back at this page, so only link real apps.
    a.route?.mode === "proxy" || a.route?.mode === "dns" || L.web ? `<a class="btn" href="${esc(appUrl(a))}">${bi({ ar: "افتح التطبيق", en: "Open the app" })}</a>` : "",
    L.play ? `<a class="btn btn-alt" href="${esc(L.play)}" rel="noopener">${bi({ ar: "Google Play", en: "Google Play" })}</a>` : "",
    L.apk ? `<a class="btn btn-alt" href="${esc(L.apk)}" rel="noopener">${bi({ ar: "تنزيل APK", en: "Download APK" })}</a>` : "",
    ...(L.extra || []).map((x) => `<a class="btn btn-alt" href="${esc(x.url)}" rel="noopener">${bi(x.label)}</a>`),
  ].join("");
  const body = `
<section class="app-hero" style="--accent:${esc(a.color || "#3b82f6")}">
  <div class="wrap">
    <nav class="crumbs" aria-label="breadcrumb"><a href="${base}">${bi(company.shortName)}</a> / <a href="${base}#cat-${esc(a.category)}">${bi(cat(a.category).name)}</a></nav>
    <div class="app-head">
      <img class="app-icon lg" src="${icon(a, base)}" width="96" height="96" alt="">
      <div>
        <h1>${bi(a.name)}</h1>
        <p class="lead">${bi(a.tagline)}</p>
        <div class="card-meta">
          <span class="badge s-${esc(a.status)}">${bi(STATUS[a.status] || STATUS.live)}</span>
          ${v?.value ? `<span class="chip mono">v${esc(v.value)}</span>` : ""}
          ${(a.platforms || []).map((p) => `<span class="chip">${esc(p)}</span>`).join("")}
        </div>
      </div>
    </div>
    <div class="cta">${actions}</div>
    ${L.testing ? testersBox([a], base) : ""}
    ${a.subdomain ? `<p class="muted mono small">${esc(a.subdomain)}.${esc(APEX)}</p>` : ""}
  </div>
</section>
<section class="wrap section app-body">
  <div>
    <h2>${bi({ ar: "عن التطبيق", en: "About the app" })}</h2>
    <p>${bi(a.description)}</p>
    ${
      f.ar?.length || f.en?.length
        ? `<h2>${bi({ ar: "المزايا", en: "Features" })}</h2>
    <ul class="features l-ar" lang="ar">${(f.ar || []).map((x) => `<li>${esc(x)}</li>`).join("")}</ul>
    <ul class="features l-en" lang="en">${(f.en || []).map((x) => `<li>${esc(x)}</li>`).join("")}</ul>`
        : ""
    }
    ${
      a.screenshots?.length
        ? `<h2>${bi({ ar: "لقطات", en: "Screenshots" })}</h2>
    <div class="shots">${a.screenshots.map((s) => `<img src="${base}shots/${esc(s)}" alt="" loading="lazy">`).join("")}</div>`
        : ""
    }
  </div>
  <aside class="facts">
    <h2>${bi({ ar: "معلومات", en: "Details" })}</h2>
    <dl>
      <dt>${bi({ ar: "التصنيف", en: "Category" })}</dt><dd>${bi(cat(a.category).name)}</dd>
      <dt>${bi({ ar: "الإصدار", en: "Version" })}</dt><dd class="mono">${esc(v?.value || "—")}</dd>
      <dt>${bi({ ar: "المنصات", en: "Platforms" })}</dt><dd>${esc((a.platforms || []).join(" · ") || "Web")}</dd>
      ${a.audience ? `<dt>${bi({ ar: "الفئة", en: "Audience" })}</dt><dd>${bi(a.audience)}</dd>` : ""}
      ${L.privacy ? `<dt>${bi({ ar: "الخصوصية", en: "Privacy" })}</dt><dd><a href="${esc(L.privacy)}">${bi({ ar: "سياسة الخصوصية", en: "Privacy policy" })}</a></dd>` : ""}
    </dl>
    <a class="back" href="${base}#apps">${bi({ ar: "← كل التطبيقات", en: "← All apps" })}</a>
  </aside>
</section>`;
  return layout({
    title: `${t2(a.name).ar} | ${t2(a.name).en} — ${company.shortName.en}`,
    description: `${t2(a.tagline).ar} — ${t2(a.tagline).en}`,
    canonical: `https://${APEX}/apps/${a.id}/`,
    base,
    body,
    jsonld: {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      name: t2(a.name).en,
      alternateName: t2(a.name).ar,
      applicationCategory: a.schemaCategory || "EducationalApplication",
      operatingSystem: (a.platforms || ["Web"]).join(", "),
      softwareVersion: v?.value || undefined,
      url: appUrl(a),
      offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
      publisher: { "@type": "Organization", name: company.name.en, url: `https://${APEX}/` },
    },
  });
}

// ---------- public registry ----------
// Only public fields leave the build. Hosting internals stay for the dashboard.
function publicRegistry() {
  return {
    generated: new Date().toISOString(),
    company: { name: company.name, domain: APEX, testers: company.testers || null },
    categories,
    apps: apps.map((a) => ({
      id: a.id,
      name: a.name,
      tagline: a.tagline,
      category: a.category,
      status: a.status,
      platforms: a.platforms || [],
      url: appUrl(a),
      subdomain: a.subdomain ? `${a.subdomain}.${APEX}` : null,
      version: a.resolvedVersion?.value || null,
      versionCheckedAt: a.resolvedVersion?.checkedAt || null,
      links: a.links || {},
      icon: a.icon ? `https://${APEX}/icons/${a.icon}` : null,
    })),
  };
}

// The dashboard gets the operational view: hosting, origin, repo, backend.
// It is still free of secrets (only env var NAMES), and it is meant to sit
// behind Cloudflare Access (see docs/OWNER-STEPS-AR.md).
function dashRegistry() {
  return {
    generated: new Date().toISOString(),
    apex: APEX,
    categories,
    apps: registry.apps.map((a) => ({
      ...a,
      resolvedVersion: a.resolvedVersion || null,
      url: appUrl(a),
    })),
  };
}

// ---------- routes for the Worker ----------
function routes() {
  const hosts = {
    "@": { id: "hub", mode: "proxy", target: HUB_ORIGIN_FINAL + "/" },
    // The dashboard page uses absolute /assets, /brand, /icons and /dash URLs.
    dash: { id: "dash", mode: "proxy", target: HUB_ORIGIN_FINAL + "/dash/", rootPrefixes: ["/assets/", "/brand/", "/icons/", "/dash/"] },
  };
  for (const a of registry.apps) {
    if (!a.subdomain || !a.route || a.route.mode === "dns" || a.status === "hidden") continue;
    const r = { id: a.id, ...a.route };
    delete r.expect;
    // GitHub Pages project sites: absolute "/<repo>/..." URLs go to the origin root.
    const m = /^https:\/\/[^/]+\.github\.io\/([^/]+)\//.exec(r.target || "");
    if (r.mode === "proxy" && m) r.rootPrefixes = [...new Set([...(r.rootPrefixes || []), `/${m[1]}/`])];
    hosts[a.subdomain] = r;
  }
  return { apex: APEX, generated: new Date().toISOString(), hosts };
}

// ---------- write ----------
await rm(join(ROOT, "dist"), { recursive: true, force: true });
await mkdir(OUT, { recursive: true });
await cp(join(ROOT, "site"), OUT, { recursive: true });
await cp(join(ROOT, "dash"), join(OUT, "dash"), { recursive: true });

await writeFile(join(OUT, "index.html"), home());
for (const a of apps) {
  await mkdir(join(OUT, "apps", a.id), { recursive: true });
  await writeFile(join(OUT, "apps", a.id, "index.html"), appPage(a));
}
await writeFile(join(OUT, "registry.json"), JSON.stringify(publicRegistry(), null, 2));
await writeFile(join(OUT, "dash", "registry.json"), JSON.stringify(dashRegistry(), null, 2));
await writeFile(join(ROOT, "worker", "routes.json"), JSON.stringify(routes(), null, 2) + "\n");

const urls = [`https://${APEX}/`, ...apps.map((a) => `https://${APEX}/apps/${a.id}/`)];
await writeFile(
  join(OUT, "sitemap.xml"),
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.map((u) => `  <url><loc>${u}</loc></url>`).join("\n")}\n</urlset>\n`
);
await writeFile(join(OUT, "robots.txt"), `User-agent: *\nAllow: /\nDisallow: /dash/\nSitemap: https://${APEX}/sitemap.xml\n`);
await writeFile(
  join(OUT, "_headers"),
  `/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  X-Frame-Options: SAMEORIGIN
/assets/*
  Cache-Control: public, max-age=86400
/icons/*
  Cache-Control: public, max-age=604800
/registry.json
  Access-Control-Allow-Origin: *
  Cache-Control: public, max-age=300
/dash/*
  X-Robots-Tag: noindex
  Cache-Control: no-store
`
);

const n = (await readdir(join(OUT, "apps"))).length;
console.log(`built ${n} app pages, ${Object.keys(routes().hosts).length} routes -> dist/site`);
if (!existsSync(join(OUT, "brand", "logo.png"))) console.warn("warning: site/brand/logo.png missing");
