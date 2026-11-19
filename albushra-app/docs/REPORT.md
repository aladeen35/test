# albushra.app: inventory and deployment report

Status date: 2026-11-19. Everything below was checked from the repositories and live HTTP probes. Nothing is claimed as deployed under albushra.app until the workflow has run with the Cloudflare secrets (see "Deployment status").

## 1. Starting point

- `albushra.app` is an **active Cloudflare zone** (nameservers `hera` / `pranab.ns.cloudflare.com`) with **no DNS records yet**, so nothing resolves.
- A previous company directory site exists: `https://aladeen35.github.io/Games/bushra-tech/` (catalog in a Worker + KV, `bushra-tech.aladeen35.workers.dev`). Its content, logos and contact details were carried into the new site; the old URL is left untouched.
- `fazatdam.albushra.app` was already chosen as Fazat Dam's official address (Vercel), but no DNS record exists for it yet.

## 2. Architecture

```
            Cloudflare zone albushra.app (DNS, SSL Full-strict, Always HTTPS)
  albushra.app ─┐  *.albushra.app ─┐   (proxied AAAA 100:: records)
                ▼                  ▼
          Worker "albushra-router"  ◄── worker/routes.json  ◄── registry/apps.json
                │
   ┌────────────┼──────────────────────────────┬──────────────────────┐
   ▼            ▼                              ▼                      ▼
Cloudflare   GitHub Pages                   Vercel                 302 → albushra.app/apps/<id>/
Pages        (mushaf, Maab, ameer-gift,     (fazat-dam)            (Android-only / not-yet-hosted apps)
(hub + dash)  albushra-news, test, Games)
```

- **Cloudflare is the domain/DNS/security layer only.** Apps stay where they are hosted today; the router serves them under their subdomain (proxy), rewriting redirects and absolute links back to the subdomain. No app was rebuilt or moved.
- **Application Registry** (`registry/apps.json`) is the single source of truth. The build turns it into the main site, one page per app, the dashboard data, a public `registry.json` (CORS-open, for future apps to read), sitemap and the router table. Versions are read live from each app's `version.source` on every build (every 6 h), so a new release appears with no manual edit.
- **One wildcard DNS record** covers every subdomain, so adding an app is one registry entry. An app can switch to `mode: "dns"` (e.g. a grey-cloud CNAME to Vercel) and the DNS sync adds that record.
- The dashboard is meant to sit behind **Cloudflare Access** (free, email one-time code). It holds no secrets: env var names only.

## 3. Application inventory

| # | Application | Latest version | Source (repo / branch) | Current hosting / URL | Backend | Proposed domain | Decision |
|---|---|---|---|---|---|---|---|
| 1 | Bushra — Quran, Hadith, Ruqyah, Adhan | 2.9.1 (2026-11-16) | FSM `claude/quran-app-reader-ce921a` → built into `mushaf` | GitHub Pages `aladeen35.github.io/mushaf/`, Play `sa.mushaf.albushra` | Worker `bushra-sync` + KV | quran | proxy |
| 2 | Khulood — Prophets encyclopedia | 1.0.0 | mushaf `khulood/` | GitHub Pages | Firebase `alwasoog-e2d17` | khulood | proxy |
| 3 | Maab Quran Academy | 0.1.0 | Maab `main` | Pages demo; Vercel live **404** | Supabase (live mode) | maab | proxy demo |
| 4 | Albushra Education (academy demo) | demo | bushra-academy-demo | GitHub Pages | none | education | proxy |
| 5 | Altafaoul | 0.1.0 | altafaoul `main` | **not deployed** (`altafaoul.pages.dev` does not exist) | Supabase (not applied) | altafaoul | page, until deployed |
| 6 | Nibras | 0.8 (branch) / 0.5 (main) | Games `ccr-47f528f1` | APK sent privately (font licence) | none | nibras | page only |
| 7 | Fazat Dam | 1.0.0 | test `fazat-dam/` | Vercel `fazat-dam-51e1.vercel.app` | Supabase + Web Push | fazatdam | proxy (dns later) |
| 8 | Quality Lamp — Eng. Alaeldeen ("Misbah al-Quality") | 2.0.0 | test `alaeldeen/` | GitHub Pages `/test/alaeldeen/` | Supabase | quality | proxy |
| 9 | Quality Eye — AI Food Guardian | 2.0.0 (Android) | FSM `main` | **self-hosted only** (Docker) | Laravel, Postgres, Redis, MinIO, inference | foodguard | page only |
| 10 | Al-Bushra News | rolling | albushra-news | GitHub Pages (rebuilt every 5 min) | static build; optional FastAPI | news | proxy |
| 11 | Albushra Video & IPTV | 1.6.0 app / 1.5 web | Games `ccr-fe24ce26` | GitHub Pages `/Games/bushra-player/` | none | video | proxy |
| 12 | Ameer Gift — 3D memory museums | 1.0.0 | ameer-gift `main` | GitHub Pages | Firebase `ameer-gift` | amir | proxy |
| 13 | Albushra Store | 0.1.0 | Albushra-store | **not deployed** (D1 not created) | Workers + D1 + R2 | store | page only |
| 14 | Jenan's World of Colours | 1.0 | Games `main` | APK on Pages | none | jenan | page + APK |
| 15 | Our Kids Games (Atheer & Bushra) | 3.0 public / 7.6 branch | Games `ccr-85c475b1` | APK | none | kids | page + APK |
| 16 | Abu Janan Heritage Games | 1.5.1 | Games `claude/sudanese-dog-jump-game-hmiama` | GitHub Pages `/Games/nut-alkalb/` | Supabase | abujanan | proxy |
| 17 | Abu Janan Keyboard Challenge | 2.1 public / 2.2 branch | Games `claude/new-session-leujen` | APK | Node server (not deployed) | keyboard | page + APK |
| 18 | Full Mark | 1.1 | test `fullmark/` | GitHub Pages + Google Play | PeerJS | fullmark | proxy |
| 19 | Wolaat | 1.0 | Games `wolaat/` | GitHub Pages | PeerJS | wolaat | proxy |
| 20 | Ameer Tools | 1.4.0 | test `ccr-56d19381` `amir_tools/` | Pages landing `/test/` + releases | none | tools | proxy |
| 21 | Hamli pregnancy calculator | 1.0 | Games | GitHub Pages `/Games/` | none | hamli | proxy |
| 22 | Secondary certificate portal | 2026 season | Games `claude/new-website-branch-9nbvza` | Netlify (URL unknown) | Netlify Functions | — | archived page |

Kept in the registry as **hidden** (dashboard only): bushra-sync worker, old bushra-tech site, AI proxy worker (never deployed), Madrasatuna (404), Family Game (3 duplicate copies), Baynana, Khartoum 3D, Rug Empire, Ding Dong Dash, Salamah, Bushra Company OS, CarDash. Half Million tools (visit planner, HMVP AI Studio scaffold, orders prototype, Netlaqa video pipelines) belong to the employer and are deliberately not published.

Duplicates resolved in favour of the newest stable build: Bushra (FSM source → mushaf build), Maab (`mushaf@maab-study` copy is older), Abu Janan heritage over the older hub, Family Game branch over `game/` and `family-game.html`, Jinan root over the `9nbvza` copy.

## 4. Verification done in this session

- Router run locally (`wrangler dev`, workerd) against the **real origins** for every host: all 14 proxied apps return 200 with their own titles, and every sampled CSS/JS/icon asset loads through the subdomain (including absolute `/Maab/_next/...` paths). Redirect hosts return 302, unknown hosts the branded 404, `www` → apex 301.
- Hub, an app page, the dashboard, Maab, Ameer Gift and the Quran web app rendered in Chromium at 390×844 through the router: no page errors, no 4xx, no horizontal scroll.
- `npm test`: registry checks (unique ids/subdomains, valid routes, both languages, no secret patterns) pass.
- Origin check (`npm run verify:origins`): 14/14 app origins up; the hub origin does not exist until the first deploy.

## 5. Deployment status

| Application | Final domain | Version | Deployment | SSL | Testing |
|---|---|---|---|---|---|
| Main site | albushra.app | — | Ready; waits for Cloudflare secrets | Cloudflare edge cert (auto) | Local + mobile screenshots ✔ |
| Dashboard | dash.albushra.app | — | Ready; waits for secrets + Access | auto | Local ✔ |
| Bushra Quran | quran.albushra.app | 2.9.1 | Router ready | auto | Through router ✔ |
| Khulood | khulood.albushra.app | 1.0.0 | Router ready | auto | ✔ |
| Maab (demo) | maab.albushra.app | 0.1.0 | Router ready | auto | ✔ |
| Albushra Education | education.albushra.app | demo | Router ready | auto | ✔ |
| Fazat Dam | fazatdam.albushra.app | 1.0.0 | Router ready (Vercel origin) | auto | ✔ |
| Quality Lamp | quality.albushra.app | 2.0.0 | Router ready | auto | ✔ |
| Al-Bushra News | news.albushra.app | rolling | Router ready | auto | ✔ |
| Albushra Video | video.albushra.app | 1.5 web | Router ready | auto | ✔ |
| Ameer Gift | amir.albushra.app | 1.0.0 | Router ready; Firebase domain needed for sign-in | auto | ✔ (browsing) |
| Abu Janan | abujanan.albushra.app | 1.5.1 | Router ready | auto | ✔ |
| Full Mark | fullmark.albushra.app | 1.1 | Router ready | auto | ✔ |
| Wolaat | wolaat.albushra.app | 1.0 | Router ready | auto | ✔ |
| Ameer Tools | tools.albushra.app | 1.4.0 | Router ready | auto | ✔ |
| Hamli | hamli.albushra.app | 1.0 | Router ready | auto | ✔ |
| Jenan / Kids / Keyboard / Nibras | jenan · kids · keyboard · nibras | 1.0 · 3.0 · 2.1 · 0.8 | 302 → app page (Android apps) | auto | ✔ |
| Altafaoul / Store / Quality Eye | altafaoul · store · foodguard | — | 302 → app page; app itself not hosted | auto | ✔ |

"Router ready" means: tested end-to-end locally against the live origin; it goes live on `albushra.app` the moment the workflow deploys with the two secrets. **Nothing is live on albushra.app yet.**

## 6. Needs more work

1. Owner: Cloudflare token + account id as GitHub secrets, merge to `main` (docs/OWNER-STEPS-AR.md §1–4).
2. Owner: Cloudflare Access on `dash.albushra.app`; Firebase authorized domains for `amir`/`khulood`; Supabase redirect URLs for `quality`/`fazatdam`.
3. Deploy Altafaoul (same two secrets in its repo), Albushra Store (create D1/R2), Maab live on Vercel, then switch their routes to `proxy`.
4. Quality Eye needs a server; decide on hosting and confirm ownership (`sa.halfm` package id).
5. Merge pending newer builds: Our Kids 7.6, Nibras 0.8, Keyboard 2.2, Bushra Video web 1.6.
6. Kids Games APK link points to a private repo (`github.com/.../raw/...`) and fails for visitors; host it publicly.
7. Security: the Bushra signing keystore password is committed in FSM; move it to secrets (do not change the key).

## 7. Limits of this session

- No browser or Cloudflare account access was available here, so Cloudflare changes are automated in the workflow rather than clicked; they run with the owner's token.
- The Android apps that wrap a domain (TWA: Ameer Gift, Maab, Fazat Dam) keep their current host until their `assetlinks.json` and manifests are moved deliberately. The router does not break them.

## 8. Recommended next steps

- After the first deploy, point the old bushra-tech page to `albushra.app` (a single redirect line) so there is one directory.
- Give each app a `version.json` like Bushra's so the hub shows releases automatically.
- Add Cloudflare Web Analytics (free, cookie-less) to the hub.
- Move APKs to a public release bucket (R2 or GitHub Releases on a public repo) with stable URLs `dl.albushra.app/<app>`.
