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

    // The dashboard lives on its own subdomain (behind Cloudflare Access).
    if (sub === "@" && (url.pathname === "/dash" || url.pathname.startsWith("/dash/"))) {
      return Response.redirect(`https://dash.${APEX}/`, 302);
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
    if (type.includes("text/html") && route.rewriteHtml !== false) {
      return new HTMLRewriter()
        .on("a[href], link[href]", new AttrRewriter("href", originBase, publicBase))
        .on("script[src], img[src], source[src]", new AttrRewriter("src", originBase, publicBase))
        .on("meta[property='og:url'], link[rel='canonical']", new AttrRewriter("content", originBase, publicBase))
        .transform(out);
    }
    return out;
  },
};

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

function json(obj) {
  return new Response(JSON.stringify(obj, null, 2), { headers: { "content-type": "application/json; charset=utf-8" } });
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
