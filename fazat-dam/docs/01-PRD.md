# FAZAT DAM | فزعة دم — Product Requirements Document

> فزعتك حياة.. وقطرتك أمل — *Your Support Saves Lives.*

| | |
|---|---|
| Product | FAZAT DAM (فزعة دم), bilingual Progressive Web App |
| Networks | Sudan (SD) and Saudi Arabia (SA), operated separately |
| Status | MVP in development (see [08-roadmap.md](08-roadmap.md)) |
| Owner | Product owner (Alaeldeen Omar) |

## 1. Problem

When a patient needs blood, families in Sudan and Sudanese families in Saudi Arabia usually fall back on WhatsApp chains and social media posts. Those posts:

- expose the patient's name, the family's phone number and sometimes medical documents to anyone;
- reach the wrong people (wrong city, wrong country, wrong blood group);
- are never closed, so donors keep calling after the need is met;
- give hospitals and blood banks no way to check that a request is real.

Donors who want to help have nowhere to say "I am in Jeddah, I am O+, I am available" without publishing their phone number.

## 2. Goals

1. Connect donors and recipients **in the same country and city**, through authorised local facilities.
2. Make an emergency request quick to file and easy to track.
3. Keep donor and requester phone numbers private until **both** sides agree to share them.
4. Let hospitals, blood banks and admins verify requests before donors are contacted, and confirm donations after they happen.
5. Give Sudanese expatriates in Saudi Arabia a safe way to support Sudan through approved humanitarian initiatives.
6. Give the administration honest, filterable reporting.

## 3. Non-goals

- **Not a medical service provider.** The platform does not assess eligibility, does not determine compatibility and gives no medical advice.
- **No cross-border blood.** A donor in Saudi Arabia is never matched to a request in Sudan, and the reverse is also blocked. No transport or logistics feature exists.
- **No sale of data.** Donor information is never sold, rented or shared with sponsors.
- **Sponsorship never buys priority.** Sponsors cannot change the order of requests, matching, or what is shown in the emergency feed.
- No payments or fundraising in the MVP. Initiatives describe support; they do not collect money in the app.
- No public profiles, no public phone numbers, no public patient data.

## 4. Personas (roles)

Roles are stored in `user_roles` (`app_role` enum). One account can hold several.

| Role (`app_role`) | Who | How they get it |
|---|---|---|
| `requester` | Any signed-in person: patient, family member, friend, ward staff | Automatically at sign-up (`handle_new_user`) |
| `donor` | A volunteer willing to donate | `register_donor()` |
| `institution_staff` | Staff of a hospital or blood bank | Admin approves the institution (`review_institution`) or adds a member (`set_institution_member`) |
| `organizer` | Person or group running a humanitarian initiative | Granted when an admin approves their initiative (`review_initiative`) |
| `admin` | Platform administration | Granted by another admin (`admin_set_role`) |

Example people:

- **Amna, 34, Riyadh.** Her father needs 2 units of O+ at a Riyadh hospital tomorrow. She wants to post once, see who responds, and not have strangers calling her.
- **Khalid, 27, Jeddah, O−.** Wants to help when he is free, but only through the app, and only with people in Jeddah.
- **Blood bank coordinator, Khartoum.** Needs to confirm that a request is real before anyone is contacted, and to record a donation once it is done.
- **Sudanese community group in Dammam.** Wants to run a blood drive in Port Sudan, with the platform's approval so people trust it.
- **Platform admin.** Approves institutions and initiatives, checks reports of fraud, watches the numbers per city.

## 5. Functional requirements

### 5.1 All users
- Sign in with phone number + one-time code (Supabase Auth phone OTP).
- Onboarding: full name, country, city, preferred language, privacy consent (`complete_onboarding`).
- Arabic by default; switch to English anywhere; the layout flips RTL/LTR.
- In-app notifications with optional Web Push.
- Report a user, request or initiative (`reports`), block a user (`user_blocks`).
- Delete account (`delete_my_account` + auth user removal by the server).

### 5.2 Donor
- Register: full name, mobile (from the verified login), country, city, blood group (A+, A−, B+, B−, AB+, AB−, O+, O−), preferred language, availability, preferred contact method, privacy consent. Optional: email, preferred facility, last donation date (`register_donor`).
- Shown publicly only as an alias such as `D-7K3QX`; optionally first name + alias (`show_first_name`).
- Availability: available / unavailable / temporarily suspended until a date (`set_donor_availability`). A suspension ends on its own.
- Opt out of automated matching (`accepts_auto_matching`).
- Receive matching requests, accept or decline, withdraw an acceptance (`respond_to_match`).
- Consent (or withdraw consent) to share contact details per match (`set_contact_consent`).
- See donation requests, appointments and donation history (`my_donation_requests`).
- Self-report a donation; it stays *pending confirmation* until a facility confirms it (`record_donation`).

Registration never implies medical eligibility. Every screen that leads to a donation repeats that the blood bank decides.

### 5.3 Requester
- Create a request: relation to patient, patient initials (optional, no full name), blood group, units (1–20), country, city, hospital name, optional approved institution, required date and time, urgency (normal / urgent / critical), notes, declaration (`submit_blood_request`). A reference such as `FD-SA-2611-7K3QX` is generated.
- Upload supporting documents (private storage bucket `request-documents`) while the request is `submitted` or `under_review`.
- Track status, see matched donors as aliases, see responses (`request_matches`).
- Search donors manually and send a request to an available donor of the same blood group in the same country (`search_donors`, `send_manual_match`).
- Ask to exchange contact details with a donor who accepted; see them only after both agree (`set_contact_consent`, `get_match_contact`).
- Schedule an appointment (`schedule_appointment`), cancel the request (`transition_request(..., 'cancelled')`).
- Limits: at most 3 open requests and 5 new requests per 24 h (configurable in `app_settings`).

### 5.4 Hospital / blood bank staff
- Register an institution (always created as `pending`), upload official documents (`institution-documents`).
- Review requests that name their institution: move to `under_review`, `verified` or `rejected` (with reason).
- Run automated matching, send manual matches (any blood group, at their professional discretion), schedule appointments.
- Record and confirm donations (`record_donation`, `confirm_donation`). Only a confirmation by staff or an admin makes a donation "confirmed".
- Maintain the institution profile.

### 5.5 Initiative organizer
- Submit a humanitarian initiative: category, title, description, objectives, beneficiaries, organizer details, country, city, start/end dates, supporting documents.
- Track status: `draft` → `submitted` → `under_review` → `approved` / `rejected` → `completed` / `archived`.
- Edit only while `draft` or `rejected`; post progress updates once `approved`.

### 5.6 Administrator
- Everything staff can do, for any request.
- Approve or reject institutions, initiatives, sponsors and campaign sponsorships.
- Suspend or restore accounts (`admin_set_account_status`), grant or revoke roles (`admin_set_role`).
- Manage countries, cities and settings (`countries`, `cities`, `app_settings`).
- Handle reports (`resolve_report`), send announcements (`admin_broadcast`).
- Dashboard with filters by date, country, city and status (`admin_stats`), audit log (`audit_logs`).

### 5.7 Public (not signed in)
- Home with emergency feed of **verified** open requests (`public_emergency_requests`): reference, blood group, units, city, hospital, urgency, time needed. No patient data, no documents.
- Real platform statistics (`public_stats`), demo rows excluded.
- Approved initiatives and approved sponsors, awareness content, privacy policy, terms.
- Donor search requires signing in.

## 6. Non-functional requirements

| Area | Requirement |
|---|---|
| Privacy | Phone numbers and names never appear in search or feeds. Contact details are revealed only by `get_match_contact` after mutual consent, and each reveal is audited. Data minimisation: patient initials only. |
| Security | Row Level Security on every table; all state changes through `SECURITY DEFINER` functions that check the caller; rate limits on search, requests and manual matches; audit log without personal contact fields. |
| Language | Arabic default, English available, one route tree, RTL/LTR switch, all UI strings in dictionaries. |
| Connectivity | Mobile-first, small bundles, self-hosted fonts, works on 3G. Offline: app shell and static assets cached; clear offline banner; form drafts kept locally and submitted when back online. |
| PWA | Installable on Android; "Add to Home Screen" on iOS Safari; manifest, icons, service worker. |
| Accessibility | WCAG 2.1 AA contrast, 44 px touch targets, visible focus, labelled forms, screen-reader status messages. |
| Availability | Hosted with HTTPS; database backups by Supabase; scheduled expiry of old requests (pg_cron). |

## 7. Medical safety statement

> The matching engine provides preliminary candidate identification only. It compares the **declared** ABO/Rh group, country, city and availability. It does not determine clinical compatibility and does not replace blood grouping confirmation, antibody screening, crossmatching, donor screening or any professional medical decision. Final transfusion suitability is decided by qualified healthcare professionals and authorised blood banks. Registration as a donor does not mean a person is medically eligible to donate.

This text appears in the request form, the donor inbox, the appointment notification and the About page.

## 8. Compliance

Before public operation the platform must be reviewed against:

- **Saudi Arabia:** Personal Data Protection Law (PDPL) and its implementing regulations (SDAIA), including health data as sensitive data, consent records, data subject rights, cross-border transfer rules for hosting; Ministry of Health rules on blood donation and on platforms that touch health information.
- **Sudan:** applicable data protection, telecommunications and health regulations, and the requirements of the National Blood Transfusion Service / Ministry of Health.
- Hosting region and data residency decision (the database region must be chosen with the legal review).

Consents are recorded in `user_consents` with a policy version (`app_settings.privacy.policy_version`).

## 9. Success metrics

| Metric | Source |
|---|---|
| Verified requests that reach `completed` | `admin_stats.requests.completed / verified` |
| Median time from `submitted` to `verified` | `blood_requests.created_at → verified_at` |
| Median time from `verified` to first donor acceptance | `donor_matches.responded_at` |
| Confirmed donations per month, per network | `donation_records` with `status = 'confirmed'` |
| Available donors per city and blood group | `admin_stats.blood_group_distribution` |
| Expired/cancelled share (unfulfilled) | `admin_stats.requests.unfulfilled` |
| Reports resolved within 48 h | `reports` |

## 10. Acceptance criteria → how they are met

| # | Criterion | Where it is enforced / proven |
|---|---|---|
| 1 | Users can register and log in | Supabase phone OTP; `handle_new_user` creates profile + `requester` role; `complete_onboarding`. Test: *profiles are created for new auth users*. |
| 2 | Donors can create and manage profiles | `register_donor` (upsert), `set_donor_availability`, `donor_self_update` policy. Tests: *four donor profiles*, *donor role granted*, *city must belong to the selected country*. |
| 3 | Recipients can submit blood requests | `submit_blood_request`. Tests: *request reference format*, *declaration is mandatory*, *open request cap enforced*. |
| 4 | Admins review and verify requests | `transition_request` + `can_review_request`. Tests: *requesters cannot verify*, *rejection requires a reason*, *cannot jump from submitted to completed*. |
| 5 | Automated and manual matching work | `run_auto_matching`, `search_donors`, `send_manual_match`. Tests: *auto matching: same country + city + group + available only*, *requesters can only request the same blood group*. |
| 6 | Donors accept or reject | `respond_to_match`. Tests: *only the matched donor can respond*, *status -> donors_responding*. |
| 7 | Phones private until mutual approval | `profiles_self_read` policy, `set_contact_consent`, `get_match_contact`. Tests: *no contact before mutual consent*, *still hidden after one-sided consent*, *requester sees donor phone after mutual consent*, *third parties never see contacts*, *a block hides contact again*. |
| 8 | Country separation | Composite FK `(city_id, country_code)`; country filters in matching and search. Tests: *no cross-border matching (SA request, SD donor)*, *and not in the Sudan feed*, *institution must be in the request country*. |
| 9 | Campaigns need admin approval | `tg_guard_initiative`, `initiatives_read` policy, `review_initiative`. Tests: *organizer cannot self-approve*, *unapproved initiatives are hidden from the public*. |
| 10 | Role permissions prevent unauthorised access | RLS on all tables + function checks; see [07-access-control-matrix.md](07-access-control-matrix.md). Tests: *outsiders cannot read requests*, *audit log is admin-only*, *admin stats are admin-only*, *suspended users cannot act*. |
| 11 | Arabic and English work | Dictionary-based i18n with `lang` cookie and `dir` switch; see [04-architecture.md](04-architecture.md). Checked by UI smoke test in both languages. |
| 12 | PWA installable | `app/manifest.ts`, icons, `public/sw.js`. Checked with Lighthouse / Chrome installability. |
| 13 | Security and functional testing | `supabase/tests/01_workflows_test.sql` (85 checks) + app build/lint + manual security review before launch (see roadmap checklist). |
| 14 | Usable on mobile and slow connections | Mobile-first layout, self-hosted fonts, static caching; checked with Lighthouse mobile + throttled network. |
