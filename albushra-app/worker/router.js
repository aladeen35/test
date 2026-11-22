// Albushra Technology edge router (Cloudflare Worker).
//
// One Worker answers albushra.app and every *.albushra.app host. It reads the
// route table that scripts/build.mjs generates from registry/apps.json, so a
// new app only needs a registry entry: no new DNS record, no new Worker.
//
// Modes per route:
//   proxy    - serve the app from its existing host (GitHub Pages, Vercel,
//              Firebase Hosting, workers.dev...) under the subdomain, without
//              moving or rebuilding it. Redirects and absolute links that point
//              at the origin are rewritten back to the subdomain.
//   redirect - 302 to the app's current URL (for apps that can't be proxied
//              safely yet, e.g. OAuth flows bound to the old domain).
//   pages    - the hub itself (main site / dashboard) on Cloudflare Pages.
//
// Hosts not in the table get a friendly 404 that links back to the hub.

import ROUTES from "./routes.json";

const APEX = ROUTES.apex; // "albushra.app"

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    // Local tests only (wrangler dev --var DEV_HOST_OVERRIDE:1): pick the host from a header.
    const testHost = env && env.DEV_HOST_OVERRIDE ? request.headers.get("x-test-host") : null;
    if (testHost) url.hostname = testHost;
    const host = url.hostname.toLowerCase();

    if (host === `www.${APEX}`) {
      url.hostname = APEX;
      return Response.redirect(url.toString(), 301);
    }

    const sub = host === APEX ? "@" : host.endsWith(`.${APEX}`) ? host.slice(0, -APEX.length - 1) : null;
    const route = sub && ROUTES.hosts[sub];

    if (url.pathname === "/__router/health") {
      return json({ ok: true, host, sub, route: route ? route.mode : null, generated: ROUTES.generated });
    }

    if (!route) return notFound(host);

    // Owner API (dashboard only): which apps are hidden from the public site.
    if (sub === "dash" && url.pathname === "/__admin/visibility") {
      return visibilityApi(request, env);
    }

    // The dashboard lives on its own subdomain (behind Cloudflare Access).
    if (sub === "@" && (url.pathname === "/dash" || url.pathname.startsWith("/dash/"))) {
      return Response.redirect(`https://dash.${APEX}/`, 302);
    }

    // Apps the owner hid from the dashboard disappear from the public hub.
    const hidden = sub === "@" ? await getHidden(env) : [];
    if (sub === "@" && hidden.length) {
      const m = /^\/apps\/([^/]+)\/?/.exec(url.pathname);
      if (m && hidden.includes(decodeURIComponent(m[1]))) return Response.redirect(`https://${APEX}/#apps`, 302);
    }

    // About the developer & privacy policy, served on the app's own subdomain
    // (same origin = an internal link from inside the app). The pages are
    // built per app into the hub's /kit/<id>/ (scripts/kit.mjs).
    if (sub !== "@" && sub !== "dash" && /^\/_albushra\/(about|privacy)\/?$/.test(url.pathname)) {
      const page = url.pathname.includes("privacy") ? "privacy" : "about";
      const hub = new URL(ROUTES.hosts["@"].target);
      const r = await fetch(new URL(`/kit/${encodeURIComponent(route.id || sub)}/${page}.html`, hub.origin).toString());
      if (!r.ok) return Response.redirect(`https://${APEX}/${page}/`, 302);
      const h = new Headers({ "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300", "x-albushra-app": route.id || sub });
      return new Response(r.body, { status: 200, headers: h });
    }

    if (route.mode === "redirect") {
      const target = new URL(route.target);
      if (route.keepPath !== false) {
        target.pathname = joinPath(target.pathname, url.pathname);
        target.search = url.search;
      }
      return Response.redirect(target.toString(), 302);
    }

    // Apps that live on a path of a shared host (GitHub Pages project sites)
    // sometimes ask for absolute "/repo/..." URLs. Send those straight to the
    // origin host instead of nesting them under the app prefix.
    const origin = new URL(route.target);
    let upstream;
    const rootPrefixes = route.rootPrefixes || [];
    if (rootPrefixes.some((p) => url.pathname.startsWith(p))) {
      upstream = new URL(url.pathname + url.search, origin.origin);
    } else {
      upstream = new URL(origin.toString());
      upstream.pathname = joinPath(origin.pathname, url.pathname);
      upstream.search = url.search;
    }

    const headers = new Headers(request.headers);
    headers.set("Host", upstream.host);
    headers.set("X-Forwarded-Host", host);
    headers.delete("cf-connecting-ip");
    const init = { method: request.method, headers, redirect: "manual" };
    if (!["GET", "HEAD"].includes(request.method)) init.body = request.body;

    let res;
    try {
      res = await fetch(upstream.toString(), init);
    } catch (err) {
      return new Response(`Upstream unavailable: ${route.target}`, { status: 502 });
    }

    const out = new Response(res.body, res);
    const originBase = origin.origin + origin.pathname.replace(/\/$/, "");
    const publicBase = `https://${host}`;

    // Keep redirects on the subdomain.
    const loc = out.headers.get("Location");
    if (loc) {
      const abs = new URL(loc, upstream);
      if (abs.toString().startsWith(originBase)) {
        const rest = abs.toString().slice(originBase.length);
        out.headers.set("Location", publicBase + (rest.startsWith("/") ? rest : "/" + rest));
      } else if (abs.origin === origin.origin && origin.pathname !== "/" && abs.pathname.startsWith(origin.pathname)) {
        out.headers.set("Location", publicBase + "/" + abs.pathname.slice(origin.pathname.length) + abs.search);
      }
    }

    // GitHub Pages sends a short cache; let Cloudflare keep static assets longer.
    out.headers.set("X-Albushra-App", route.id || sub);
    out.headers.delete("x-github-request-id");

    const type = out.headers.get("content-type") || "";

    // Public registry: drop hidden apps.
    if (sub === "@" && hidden.length && url.pathname === "/registry.json" && type.includes("json")) {
      try {
        const reg = await out.json();
        reg.apps = (reg.apps || []).filter((a) => !hidden.includes(a.id));
        const h = new Headers(out.headers);
        // The body is re-serialised, so drop the origin's encoding/length/etag.
        for (const k of ["content-length", "content-encoding", "etag"]) h.delete(k);
        h.set("cache-control", "public, max-age=60");
        return new Response(JSON.stringify(reg, null, 2), { status: out.status, headers: h });
      } catch (e) {
        return new Response("registry unavailable", { status: 502 });
      }
    }

    if (!type.includes("text/html")) return out;

    const isHub = sub === "@" || sub === "dash";
    const button = !isHub && route.homeButton !== false;
    if (route.rewriteHtml === false && !button && !hidden.length) return out;

    let rw = new HTMLRewriter();
    if (route.rewriteHtml !== false) {
      rw = rw
        .on("a[href], link[href]", new AttrRewriter("href", originBase, publicBase))
        .on("script[src], img[src], source[src]", new AttrRewriter("src", originBase, publicBase))
        .on("meta[property='og:url'], link[rel='canonical']", new AttrRewriter("content", originBase, publicBase));
    }
    // Cards and tester links carry data-app="<id>" (scripts/build.mjs).
    if (sub === "@") for (const id of hidden) rw = rw.on(`[data-app="${cssEscape(id)}"]`, { element: (el) => el.remove() });
    if (button) rw = rw.on("body", { element: (el) => el.append(homeButton(route.homeButton), { html: true }) });
    if (sub === "@" && hidden.length) {
      out.headers.set("cache-control", "no-cache");
    }
    return rw.transform(out);
  },
};

// ---------- "back to albushra.app" button on every app ----------
// A small fixed link added to every proxied app page. Opt out per route with
// "homeButton": false, or move it with "top-left" / "top-right" / "bottom-right".
// "middle-left" is a small icon-only tab on the left edge, for full-screen
// games whose corners are all taken by their own controls.
function homeButton(pos) {
  // A small "Albushra" pill (or a left-edge tab for full-screen games) that
  // opens a menu: the store, About the developer, Privacy policy. Pure
  // HTML/CSS (<details>), so it needs no script and cannot break the app.
  const side = pos === "middle-left";
  const corner = typeof pos === "string" && !side ? pos : "bottom-left";
  const v = side ? "top:50%;transform:translateY(-50%)" : corner.startsWith("top") ? "top:calc(10px + env(safe-area-inset-top,0px))" : "bottom:calc(10px + env(safe-area-inset-bottom,0px))";
  const h = side ? "left:0" : corner.endsWith("right") ? "right:10px" : "left:10px";
  const menuV = side ? "top:0" : corner.startsWith("top") ? "top:40px" : "bottom:40px";
  const menuH = corner.endsWith("right") && !side ? "right:0" : "left:0";
  const summary = side
    ? `padding:5px 5px 5px 3px;border-radius:0 12px 12px 0;background:rgba(7,13,36,.7);opacity:.8`
    : `display:inline-flex;align-items:center;gap:6px;padding:5px 11px 5px 5px;border-radius:999px;background:rgba(7,13,36,.86);color:#fff;font:600 12px/1 system-ui,-apple-system,'Segoe UI',sans-serif;box-shadow:0 4px 14px rgba(0,0,0,.3);opacity:.92`;
  const item = "display:block;padding:11px 14px;color:#eef4ff!important;text-decoration:none!important;border-radius:10px;font:600 14px/1.3 system-ui,-apple-system,'Segoe UI',Tahoma,sans-serif;white-space:nowrap";
  return `<details id="albushra-home" style="position:fixed;${v};${h};z-index:2147483646;direction:rtl;margin:0">` +
    `<summary aria-label="البشرى للتكنولوجيا — ${APEX}" style="list-style:none;cursor:pointer;line-height:0;${summary}"><img src="https://${APEX}/brand/mark-192.png" width="22" height="22" alt="" style="width:22px;height:22px;border-radius:50%;margin:0;padding:0;border:0">${side ? "" : `<span style="line-height:1">البشرى</span>`}</summary>` +
    `<nav style="position:absolute;${menuV};${menuH};${side ? "margin-left:34px;" : ""}min-width:210px;padding:6px;border-radius:14px;background:rgba(10,20,38,.97);border:1px solid rgba(255,255,255,.14);box-shadow:0 14px 40px rgba(0,0,0,.45)">` +
    `<a href="https://${APEX}/" style="${item}">🏠 متجر البشرى — ${APEX}</a>` +
    `<a href="/_albushra/about" style="${item}">ℹ️ عن المطور والمنظومة</a>` +
    `<a href="/_albushra/privacy" style="${item}">🛡️ سياسة الخصوصية</a>` +
    `</nav></details><style>#albushra-home summary::-webkit-details-marker{display:none}#albushra-home:not([open]) nav{display:none}#albushra-home a:hover{background:rgba(255,255,255,.08)}@media print{#albushra-home{display:none!important}}</style>`;
}

// ---------- visibility (Workers KV, key "hidden" = JSON array of app ids) ----------
async function getHidden(env) {
  if (!env || !env.VISIBILITY) return [];
  try {
    const v = await env.VISIBILITY.get("hidden", { type: "json", cacheTtl: 60 });
    return Array.isArray(v) ? v : [];
  } catch (e) {
    return [];
  }
}

async function visibilityApi(request, env) {
  const noStore = { "cache-control": "no-store" };
  if (!env || !env.VISIBILITY) return json({ ok: false, error: "VISIBILITY KV is not bound" }, 503, noStore);
  const who = await accessIdentity(request, env);
  if (!who) return json({ ok: false, error: "Cloudflare Access login required" }, 401, noStore);

  if (request.method === "GET") return json({ ok: true, hidden: await readHidden(env) }, 200, noStore);
  if (request.method !== "POST") return json({ ok: false, error: "method not allowed" }, 405, noStore);
  // Same-origin only: a custom header forces a CORS preflight that we never answer.
  if (request.headers.get("x-albushra-admin") !== "1") return json({ ok: false, error: "missing header" }, 400, noStore);

  let body;
  try {
    body = await request.json();
  } catch (e) {
    return json({ ok: false, error: "bad json" }, 400, noStore);
  }
  const id = String(body.id || "");
  if (!/^[a-z0-9][a-z0-9-]{0,62}$/.test(id) || !ROUTES.appIds.includes(id)) return json({ ok: false, error: "unknown app" }, 400, noStore);
  const set = new Set(await readHidden(env));
  if (body.hidden) set.add(id);
  else set.delete(id);
  const list = [...set].sort();
  await env.VISIBILITY.put("hidden", JSON.stringify(list), { metadata: { by: who, at: new Date().toISOString() } });
  return json({ ok: true, hidden: list }, 200, noStore);
}

async function readHidden(env) {
  const v = await env.VISIBILITY.get("hidden", { type: "json" });
  return Array.isArray(v) ? v : [];
}

// Verifies the Cloudflare Access JWT (header or cookie) against the team's keys.
let certCache = null;
async function accessIdentity(request, env) {
  const team = env.ACCESS_TEAM_DOMAIN;
  const aud = env.ACCESS_AUD;
  if (!team || !aud) return null;
  const token = request.headers.get("cf-access-jwt-assertion") || cookie(request, "CF_Authorization");
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const header = JSON.parse(b64urlText(parts[0]));
    const payload = JSON.parse(b64urlText(parts[1]));
    const now = Math.floor(Date.now() / 1000);
    const auds = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
    if (!auds.includes(aud) || payload.iss !== `https://${team}` || !(payload.exp > now)) return null;
    if (!certCache || certCache.at < Date.now() - 3600e3) {
      const r = await fetch(`https://${team}/cdn-cgi/access/certs`);
      certCache = { at: Date.now(), keys: (await r.json()).keys || [] };
    }
    const jwk = certCache.keys.find((k) => k.kid === header.kid);
    if (!jwk) return null;
    const key = await crypto.subtle.importKey("jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"]);
    const ok = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", key, b64urlBytes(parts[2]), new TextEncoder().encode(parts[0] + "." + parts[1]));
    return ok ? payload.email || payload.sub || "access" : null;
  } catch (e) {
    return null;
  }
}

function cookie(request, name) {
  const c = request.headers.get("cookie") || "";
  const m = c.match(new RegExp("(?:^|;\\s*)" + name + "=([^;]+)"));
  return m ? m[1] : null;
}
function b64urlBytes(s) {
  const b = atob(s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4));
  return Uint8Array.from(b, (c) => c.charCodeAt(0));
}
function b64urlText(s) {
  return new TextDecoder().decode(b64urlBytes(s));
}
function cssEscape(s) {
  return String(s).replace(/["\\]/g, "\\$&");
}

class AttrRewriter {
  constructor(attr, from, to) {
    this.attr = attr;
    this.from = from;
    this.to = to;
  }
  element(el) {
    const v = el.getAttribute(this.attr);
    if (v && v.startsWith(this.from)) el.setAttribute(this.attr, this.to + v.slice(this.from.length));
  }
}

function joinPath(base, path) {
  const b = base.endsWith("/") ? base.slice(0, -1) : base;
  return b + (path.startsWith("/") ? path : "/" + path);
}

function json(obj, status = 200, extra = {}) {
  return new Response(JSON.stringify(obj, null, 2), { status, headers: { "content-type": "application/json; charset=utf-8", ...extra } });
}

function notFound(host) {
  const html = `<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>غير موجود — البشرى للتكنولوجيا</title>
<body style="margin:0;min-height:100vh;display:grid;place-items:center;background:#070d24;color:#e8eeff;font-family:system-ui,sans-serif;text-align:center;padding:16px">
<div><h1 style="font-size:22px">لا يوجد تطبيق على هذا العنوان بعد</h1><p style="opacity:.75">${escapeHtml(host)}</p>
<p><a style="color:#5cc8ff" href="https://${APEX}/">العودة إلى البشرى للتكنولوجيا ← ${APEX}</a></p></div></body></html>`;
  return new Response(html, { status: 404, headers: { "content-type": "text/html; charset=utf-8" } });
}

function escapeHtml(s) {
  return s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}
