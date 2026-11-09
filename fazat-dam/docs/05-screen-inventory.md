# Screen inventory

Roles: **anon** = not signed in, **user** = any signed-in active account (requester), **donor**, **staff** = institution_staff, **org** = organizer, **admin**. Phase = delivery phase from the master prompt.

## Public and member screens

| Route | Purpose | Roles | Data / RPCs | Key components | Empty / error states | Phase |
|---|---|---|---|---|---|---|
| `/` | Home: logo, welcome, selected country/city, emergency feed, "I need blood" / "I want to donate", donor search entry, approved initiatives, awareness, statistics | all | `public_emergency_requests`, `public_stats`, `humanitarian_initiatives` (approved) | Network switcher, two large action buttons, request cards, stat tiles, awareness cards | No verified requests → "No open emergency requests in this network right now"; stats show real zeros | 1 |
| `/login` | Phone OTP sign-in | anon | Supabase Auth `signInWithOtp`, `verifyOtp` | Country prefix select, phone field, 6-digit code input, resend timer | Invalid number, wrong/expired code, SMS rate limit | 1 |
| `/onboarding` | Complete profile + consent | user (not onboarded) | `complete_onboarding`, `cities` | Country/city selects, language, privacy checkbox | Consent missing, city not in country | 1 |
| `/donors` | Find a donor (manual search) | user (anon sees sign-in prompt) | `search_donors`, own open requests, `send_manual_match` | Filters (country, city, group, available), donor cards, "send request" sheet | No results → widen city / turn off available-only; `rate_limited`; `country_mismatch` | 1 (map view: 2) |
| `/donate` | Register / edit donor profile, availability | user / donor | `register_donor`, `set_donor_availability`, `donor_profiles` (own) | Blood-group picker, availability toggle, suspension date, contact method, privacy | Consent missing, invalid suspension date | 1 |
| `/requests/new` | Emergency request form | user | `submit_blood_request`, `institutions` (approved), Storage upload | Stepper, urgency chips, date-time picker, declaration, document upload, local draft | `too_many_open_requests`, `rate_limited`, offline → draft saved | 1 |
| `/requests/[id]` | Track own request | requester, reviewers | `blood_requests` (RLS), `request_matches`, `set_contact_consent`, `get_match_contact`, `schedule_appointment`, `record_donation`, `transition_request('cancelled')` | Status timeline (10 statuses), matched donor list, consent buttons, revealed contact card, appointment form, cancel | Not found / not authorised; no donors yet | 1 |
| `/activity` | My activity: donor inbox + my requests + donation history | user | `my_donation_requests`, `respond_to_match`, `set_contact_consent`, own `blood_requests`, `donation_records` | Tabs, match cards with accept/decline, appointment, donation status | Nothing yet → links to donate / request | 1 (history detail: 2) |
| `/notifications` | Inbox | user | `notifications`, `mark_all_notifications_read` | List with unread dot, mark all read, push opt-in | No notifications | 1 (push: 2) |
| `/profile` | Personal info, donor status, privacy, language, blocks, delete account | user | `profiles` (own), `donor_profiles`, `user_blocks`, `user_consents`, `delete_my_account` | Forms, language switch, consent history, danger zone | Confirm-before-delete dialog | 1 |
| `/initiatives` | Approved humanitarian initiatives | all | `humanitarian_initiatives` (approved/completed) | Filters by country/category, cards | None approved yet | 3 |
| `/initiatives/new` | Submit / edit proposal | user | insert/update `humanitarian_initiatives`, `initiative_documents` | Form, save draft / submit, status chip | Locked after submit (`initiative_locked`) | 3 |
| `/initiatives/[id]` | Initiative page, updates, sponsors | all (own drafts: organizer) | `humanitarian_initiatives`, `initiative_updates`, `campaign_sponsorships` | Header, objectives, updates timeline, sponsor logos, report button | Not public / not found | 3 |
| `/sponsors` | Sponsors & partners + transparency statement | all | `sponsors` (approved), apply form (insert pending) | Logo grid by type, "platform is free, data never sold, sponsorship never prioritises requests" | No approved sponsors yet | 3 |
| `/institution` | Institution registration and staff workspace | user / staff | `institutions`, `institution_documents`, requests naming the institution, `confirm_donation` | Registration form, status, review queue | Pending approval notice | 2 |
| `/privacy` | Privacy policy (AR/EN) | all | static | | | 1 |
| `/terms` | Terms of use + medical disclaimer | all | static | | | 1 |
| `/about` | About, medical safety statement, awareness | all | static | | | 1 |
| `/offline` | Offline fallback | all | cached by service worker | Retry button | | 1 |

## Administration

All admin routes require `admin`, except that institution staff use `/admin/requests` and `/admin/donations` scoped to their institution (RLS returns only their rows).

| Route | Purpose | Data / RPCs | Empty / error | Phase |
|---|---|---|---|---|
| `/admin` | Overview: users, active/available donors, requests (total, verified, completed, unfulfilled, pending review), confirmed donations, by city, by country, blood-group distribution, initiatives, institutions, open reports; filters date/country/city, include-demo toggle | `admin_stats` | Zeros shown as zeros | 1 (advanced reports: 2) |
| `/admin/requests` | Review queue with status filters | `blood_requests` (RLS) | No requests in filter | 1 |
| `/admin/requests/[id]` | Verify/reject, documents (signed URLs), run matching, manual match, matches list, appointment, record/confirm donation, close | `transition_request`, `run_auto_matching`, `send_manual_match`, `request_matches`, `record_donation`, `confirm_donation` | `invalid_transition` explained | 1 |
| `/admin/users` | Find user, roles, suspend/restore | `admin_find_user`, `admin_set_role`, `admin_set_account_status` | Query < 3 chars | 1 |
| `/admin/donors` | Donor list by network/city/group | `donor_profiles` (admin RLS) | | 1 |
| `/admin/institutions` | Hospitals and blood banks: approve/reject, members, documents | `institutions`, `review_institution`, `set_institution_member` | | 2 |
| `/admin/initiatives` | Campaign approvals | `humanitarian_initiatives`, `review_initiative` | Rejection needs a note | 3 |
| `/admin/sponsors` | Approve sponsors, link to initiatives | `sponsors`, `review_sponsor`, `campaign_sponsorships` | | 3 |
| `/admin/donations` | Pending confirmations | `donation_records`, `confirm_donation` | None pending | 2 |
| `/admin/reports` | Moderation queue | `reports`, `resolve_report` | | 1 |
| `/admin/notifications` | Broadcast announcement to a network | `admin_broadcast` | | 2 |
| `/admin/settings` | Countries, cities, matching/request limits | `countries`, `cities`, `app_settings` | | 1 |
| `/admin/audit` | Audit log, filter by entity/actor | `audit_logs` | | 1 |

## Navigation

- Mobile bottom navigation (5 items): Home · Find donor · Request (red, centre) · My activity · Account.
- Header: logo, network/city chip, notifications bell with unread count, language switch.
- Admin: side navigation on desktop, collapsible on mobile.
