# Development roadmap

Status key: ✅ done in this repo · 🟡 in progress / partial · ⬜ not started · 🔧 needs configuration outside the code

> This status was written while the app layer (`src/`) was being built. The README and later commits are the current source of truth for UI progress. Database items marked ✅ are covered by `supabase/tests/01_workflows_test.sql`.

## Phase 1 — MVP

| Item | Database / rules | App UI |
|---|---|---|
| Registration and login (phone OTP) | ✅ `handle_new_user`, profiles, base role | ✅ `/login`, `/onboarding`; 🔧 SMS provider in Supabase |
| User profiles | ✅ RLS, column guards, consent ledger | ✅ `/profile` |
| Donor registration and availability | ✅ `register_donor`, `set_donor_availability` | ✅ `/donate` |
| Manual donor search | ✅ `search_donors`, `send_manual_match` | ✅ `/donors` (list view) |
| Blood request submission | ✅ `submit_blood_request`, caps, reference | ✅ `/requests/new` (with offline draft) |
| Supporting document upload | ✅ bucket + policies | ✅ upload in the request form and request page |
| Admin verification | ✅ `transition_request` state machine | ✅ `/admin/requests`, `/admin/requests/[id]` |
| Automated matching | ✅ `run_auto_matching` | ✅ button on request review |
| Donor responses | ✅ `respond_to_match` | ✅ `/activity` |
| Privacy-controlled contact | ✅ mutual consent, `get_match_contact`, audit, blocks | ✅ request page and donor inbox |
| In-app messaging | ✅ `messages` + policies | ✅ `/messages/[matchId]` |
| In-app notifications | ✅ bilingual `notifications` | ✅ `/notifications` |
| Basic admin dashboard | ✅ `admin_stats`, `admin_find_user`, role/status RPCs | ✅ `/admin` (filters by date, country, city) |
| Arabic/English, RTL/LTR | — | ✅ dictionaries + `lang` cookie |
| PWA (manifest, icons, service worker, offline page) | — | ✅ manifest, icons from client logo, `public/sw.js`, `/offline` |
| Request expiry | ✅ `expire_overdue_requests` | 🔧 pg_cron enabled on the project |
| Reports and blocks | ✅ tables + `resolve_report` | ✅ report/block on each match (`report_match_party`, `block_match_party`), `/admin/reports` |

## Phase 2

| Item | Status |
|---|---|
| Hospital and blood bank accounts | ✅ database (`institutions`, members, review) · ✅ `/institution` and `/admin/institutions` UI |
| Institution document upload UI | ✅ bucket/policies · ✅ UI |
| Donation confirmation | ✅ `record_donation`, `confirm_donation` · ✅ `/admin/donations` and `/institution` queues |
| Appointments | ✅ `schedule_appointment` · ✅ UI |
| Web Push notifications | ✅ `push_subscriptions`, `pushed_at` · ✅ subscribe toggle + `/api/push/dispatch` · 🔧 VAPID keys + dispatch secret |
| Maps (donor/facility map view) | ⬜ not built; needs provider choice (Google Maps or OpenStreetMap/MapLibre) and a decision on showing only city-level locations |
| Donation history | ✅ data · ✅ `/activity` history |
| Advanced reports (export, trends over time) | ⬜ |
| Admin broadcast | ✅ `admin_broadcast` · ✅ `/admin/notifications` |

## Phase 3

| Item | Status |
|---|---|
| Humanitarian initiatives (submit, approve, publish, updates) | ✅ database + guards · ✅ `/initiatives*`, `/admin/initiatives` |
| Campaign management and progress updates | ✅ `initiative_updates` · ✅ UI on the initiative page |
| Sponsors and partnerships | ✅ `sponsors`, `campaign_sponsorships`, `review_sponsor` · ✅ `/sponsors`, `/admin/sponsors` (approval, logo upload, link to initiative) |
| Campaign analytics | 🟡 counts in `admin_stats.initiatives` · ⬜ per-campaign analytics |
| Expanded institutional features (stock alerts, campaign hosting) | ⬜ |

## Pre-launch checklist

- [ ] **Legal review**: Saudi PDPL (health data = sensitive data, consent, data subject rights, transfer rules), Ministry of Health rules, applicable Sudanese laws; privacy policy and terms approved by counsel.
- [ ] **Hosting region / data residency** decided with the legal review.
- [ ] **SMS provider** configured for phone OTP in both networks (+966, +249); delivery tested on Sudanese carriers; OTP rate limits set in Supabase Auth.
- [ ] **Security review** of RLS policies and every `SECURITY DEFINER` function; Supabase security advisors clean.
- [ ] **Penetration test** by an independent party (IDOR on requests/matches, contact leakage, upload abuse, rate limits).
- [ ] **Backups** and point-in-time recovery enabled; restore drill done.
- [ ] **Monitoring**: error tracking for the app, Postgres logs/alerts, uptime check, alert on spikes of `rate_limited` and reports.
- [ ] **pg_cron** enabled and jobs visible (`fazat-expire-requests`, `fazat-prune-rate-limits`).
- [ ] **VAPID keys** generated and stored as secrets; push tested on Android Chrome and iOS (installed PWA, iOS 16.4+).
- [ ] **First admins** granted by SQL; admin accounts protected with strong device security.
- [ ] **Institution partners** onboarded (at least one approved blood bank per launch city) before opening requests in that city.
- [ ] **Demo data** removed ([09-test-data-policy.md](09-test-data-policy.md)).
- [ ] **Accessibility and performance**: Lighthouse mobile ≥ 90 on Home and request form, throttled 3G test, screen-reader pass in Arabic and English.
- [ ] **Vector logo masters** obtained from the designer for print.
- [ ] **Moderation runbook**: who reviews requests at night, response-time targets, how fraud reports are escalated.
