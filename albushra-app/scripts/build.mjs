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
import { createRenderer } from "./render.mjs";

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

// ---------- pages ----------
const appUrl = (a) => (a.subdomain ? `https://${a.subdomain}.${APEX}/` : a.links?.web || "#");
const { home, appPage } = createRenderer({ company, categories, apps, APEX });

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
  // Ids the dashboard may hide/show on the public site.
  const appIds = apps.map((a) => a.id);
  return { apex: APEX, generated: new Date().toISOString(), appIds, hosts };
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
