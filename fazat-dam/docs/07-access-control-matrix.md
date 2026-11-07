# Access-control matrix

Derived from the RLS policies in `20261107000002_security.sql`, the storage policies in `…05_storage_and_jobs.sql` and the caller checks inside each function in `…03_workflows.sql`.

Columns are cumulative: **user** is any signed-in, active account (everyone has the `requester` role); **donor**, **staff** (`institution_staff`, active member of an *approved* institution), **organizer** and **admin** add to what *user* can do. Suspended or deleted accounts are refused by every workflow function (`account_inactive`).

Legend: ✅ allowed · ◐ allowed with a condition (see note) · — not allowed

## Data access (direct table reads)

| Table / view | anon | user | donor | staff | organizer | admin |
|---|---|---|---|---|---|---|
| `countries`, `cities` (active) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (incl. inactive, write) |
| `app_settings` | ✅ read | ✅ read | ✅ read | ✅ read | ✅ read | ✅ write |
| `profiles` | — | ◐ own row | ◐ own | ◐ own | ◐ own | ✅ all |
| `user_roles` | — | ◐ own | ◐ own | ◐ own | ◐ own | ✅ write |
| `donor_profiles` | — | — | ◐ own (update/delete) | — | — | ✅ |
| `institutions` | ◐ approved | ◐ approved + own submissions | ◐ same | ◐ + own institution (update) | ◐ same as user | ✅ |
| `institution_members` | — | ◐ own membership | ◐ own | ◐ own institution | ◐ own | ✅ write |
| `institution_documents` | — | ◐ institutions they created | ◐ same | ◐ upload for own institution | ◐ same | ✅ |
| `blood_requests` | — | ◐ own requests | ◐ own (+ reduced view of matched requests via `my_donation_requests`) | ◐ requests naming their institution | ◐ own | ✅ |
| `request_documents` | — | ◐ own requests (upload while submitted/under_review) | ◐ same | ◐ read for their institution | ◐ same | ✅ |
| `donor_matches`, `donor_responses` | — | ◐ matches on own requests | ◐ + own matches | ◐ matches on their institution's requests | ◐ as user | ✅ |
| `messages` | — | ◐ party to an accepted match with contact shared, no block | ◐ same | — | ◐ same | ✅ read |
| `donation_records` | — | ◐ records on own requests | ◐ + own donations | ◐ their institution | ◐ as user | ✅ |
| `humanitarian_initiatives` | ◐ approved/completed | ◐ + own (create; edit while draft/rejected) | ◐ same | ◐ same | ◐ same | ✅ |
| `initiative_documents` | — | ◐ own initiatives | ◐ same | ◐ same | ◐ same | ✅ |
| `initiative_updates` | ◐ of public initiatives | ◐ same | ◐ same | ◐ same | ◐ post while own initiative approved | ✅ |
| `sponsors` | ◐ approved | ◐ + submit (forced pending) | ◐ same | ◐ same | ◐ same | ✅ |
| `campaign_sponsorships` | ◐ approved with approved sponsor | ◐ same | ◐ same | ◐ same | ◐ same | ✅ |
| `notifications` | — | ◐ own, may set `read_at` only | ◐ own | ◐ own | ◐ own | ◐ own |
| `push_subscriptions` | — | ◐ own | ◐ own | ◐ own | ◐ own | ◐ own |
| `user_consents` | — | ◐ own (read, insert) | ◐ own | ◐ own | ◐ own | ✅ read |
| `reports` | — | ◐ create; read own | ◐ same | ◐ same | ◐ same | ✅ resolve |
| `user_blocks` | — | ◐ own | ◐ own | ◐ own | ◐ own | ◐ own |
| `audit_logs` | — | — | — | — | — | ✅ read only |
| `rate_limit_events` | — | — | — | — | — | — (internal) |

## Capabilities (workflow functions)

| Capability | Function | anon | user | donor | staff | organizer | admin |
|---|---|---|---|---|---|---|---|
| View emergency feed (verified only) | `public_emergency_requests` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| View platform statistics | `public_stats` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Complete onboarding | `complete_onboarding` | — | ✅ | ✅ | ✅ | ✅ | ✅ |
| Register / edit as donor | `register_donor` | — | ✅ | ✅ | ✅ | ✅ | ✅ |
| Set availability | `set_donor_availability` | — | — | ✅ | — | — | — |
| Search donors (anonymised) | `search_donors` | — | ✅ (rate-limited) | ✅ | ✅ | ✅ | ✅ |
| Submit blood request | `submit_blood_request` | — | ✅ (3 open, 5/day) | ✅ | ✅ | ✅ | ✅ (no caps) |
| Cancel request | `transition_request(…,'cancelled')` | — | ◐ own | ◐ own | ◐ + institution's | ◐ own | ✅ |
| Review / verify / reject / complete | `transition_request` | — | — | — | ◐ requests naming their institution | — | ✅ |
| Force-expire | `transition_request(…,'expired')` | — | — | — | — | — | ✅ (and pg_cron) |
| Run automated matching | `run_auto_matching` | — | — | — | ◐ their institution | — | ✅ |
| Send manual match | `send_manual_match` | — | ◐ own verified request, same group, 20/day | ◐ same | ◐ any group, their institution | ◐ as user | ✅ any group |
| See matched donors (aliases) | `request_matches` | — | ◐ own request | ◐ own | ◐ their institution | ◐ own | ✅ |
| Donor inbox | `my_donation_requests` | — | — | ✅ | — | — | — |
| Accept / decline / withdraw | `respond_to_match` | — | — | ◐ own match | — | — | — |
| Consent to share contact | `set_contact_consent` | — | ◐ requester of an accepted match | ◐ donor of an accepted match | — | — | — |
| Reveal contact | `get_match_contact` | — | ◐ after mutual consent, no block | ◐ same | — | — | — |
| Message the other party | `messages` insert | — | ◐ same as reveal | ◐ same | — | — | — |
| Schedule appointment | `schedule_appointment` | — | ◐ own request | ◐ as requester | ◐ their institution | — | ✅ |
| Record donation | `record_donation` | — | ◐ own request → pending | ◐ own match → pending | ◐ → confirmed | — | ✅ → confirmed |
| Confirm donation | `confirm_donation` | — | — | — | ◐ their institution | — | ✅ |
| Register institution | insert `institutions` | — | ✅ (pending) | ✅ | ✅ | ✅ | ✅ |
| Approve institution, manage staff | `review_institution`, `set_institution_member` | — | — | — | — | — | ✅ |
| Submit initiative | insert `humanitarian_initiatives` | — | ✅ (draft/submitted) | ✅ | ✅ | ✅ | ✅ |
| Approve / reject / complete initiative | `review_initiative` | — | — | — | — | — | ✅ |
| Post initiative update | insert `initiative_updates` | — | — | — | — | ◐ own approved | ✅ |
| Approve sponsor / sponsorship | `review_sponsor`, `campaign_sponsorships` | — | — | — | — | — | ✅ |
| Suspend / restore account | `admin_set_account_status` | — | — | — | — | — | ✅ (not self) |
| Grant / revoke roles | `admin_set_role` | — | — | — | — | — | ✅ (cannot drop own admin) |
| Find users (phone/name) | `admin_find_user` | — | — | — | — | — | ✅ |
| Dashboard statistics | `admin_stats` | — | — | — | — | — | ✅ |
| Broadcast announcement | `admin_broadcast` | — | — | — | — | — | ✅ |
| Resolve reports | `resolve_report` | — | — | — | — | — | ✅ |
| Report / block | `reports`, `user_blocks` | — | ✅ | ✅ | ✅ | ✅ | ✅ |
| Delete own account | `delete_my_account` | — | ✅ | ✅ | ✅ | ✅ | ✅ |

## Storage

| Bucket | anon | user | staff | organizer | admin |
|---|---|---|---|---|---|
| `request-documents` | — | ◐ upload/read for own request (upload only while submitted/under_review) | ◐ read for their institution | — | ✅ read |
| `initiative-documents` | — | ◐ own initiative (upload while draft/submitted/rejected) | — | ◐ same | ✅ read |
| `institution-documents` | — | ◐ institutions they created | ◐ same | — | ✅ read |
| `sponsor-logos` | ✅ read (public bucket) | ✅ read | ✅ read | ✅ read | ✅ write/delete |

## Column guards (API callers cannot change, even on their own rows)

| Table | Protected columns |
|---|---|
| `profiles` | `phone` (owned by Auth), `account_status`, `status_note`, `deleted_at`, `is_demo` |
| `donor_profiles` | `public_alias`, `is_verified` |
| `institutions` | `status`, review fields, `created_by`, `type`, `country_code`, `is_demo` |
| `humanitarian_initiatives` | status beyond draft/submitted, review/publish fields, `organizer_id`, `is_demo`; whole row locked once submitted |
| `sponsors` | status forced `pending` on insert |
| `notifications` | everything except `read_at` |
