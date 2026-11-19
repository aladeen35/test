# albushra.app — Albushra Technology

The main site, the apps dashboard, the Application Registry and the edge router for every `*.albushra.app` subdomain.

| Path | What |
|---|---|
| `registry/apps.json` | **Application Registry**: every app, its subdomain, routing, version source, hosting, backend, env var names. Single source of truth. |
| `scripts/build.mjs` | Builds `dist/site` (albushra.app + `/apps/<id>/` pages + `/dash/`), `registry.json`, sitemap, and `worker/routes.json`. Fetches live versions. |
| `worker/router.js` | Cloudflare Worker on `albushra.app/*` and `*.albushra.app/*`: proxies each subdomain to the app's current host, or redirects. |
| `scripts/dns-sync.mjs` | Adds the apex, wildcard and `www` records (and per-app records for `mode: "dns"`) and sets SSL Full-strict. Never deletes. |
| `scripts/verify.mjs` | Checks every subdomain (or, with `--origins`, every origin) over HTTPS. |
| `dash/` | Dashboard UI (live status + version per app). Put it behind Cloudflare Access. |
| `docs/OWNER-STEPS-AR.md` | Console steps for the owner (Arabic). |
| `docs/REPORT.md` | Inventory and deployment report. |

CI: `.github/workflows/albushra-app.yml` (build + test on every change, deploy from `main` and every 6 hours).

## Add an app

Add a block to `registry/apps.json` with `id`, `subdomain`, `name`/`tagline`/`description` (ar + en), `category`, `status`, `icon` (a file in `site/icons/`), and a `route`:

- `{ "mode": "proxy", "target": "https://host/path/" }` serves the app from where it is hosted.
- `{ "mode": "redirect", "target": "https://..." }` sends visitors to another URL.
- `{ "mode": "dns", "record": { "type": "CNAME", "content": "cname.vercel-dns.com", "proxied": false } }` creates its own DNS record (for hosts that must terminate TLS themselves).

Optional `version: { "source": "https://.../version.json", "field": "version" }` keeps the shown version current.

## Local

```bash
npm ci
npm test
npm run build            # or build:offline
npx wrangler dev --local --var DEV_HOST_OVERRIDE:1   # then: curl -H "x-test-host: quran.albushra.app" localhost:8787/
```
