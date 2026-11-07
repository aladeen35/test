# User journeys

All diagrams use the real function names and statuses from `supabase/migrations`.

## 1. Sign-up and donor registration

```mermaid
flowchart TD
  A[Open app — Arabic by default] --> B{Signed in?}
  B -- no --> C[/login: enter phone with +249 or +966/]
  C --> D[Supabase Auth sends OTP by SMS]
  D --> E[Enter 6-digit code]
  E --> F[auth.users row created]
  F --> G[[handle_new_user: profile + role requester]]
  G --> H{Profile complete?}
  B -- yes --> H
  H -- no --> I[/onboarding: name, country, city, language, privacy consent/]
  I --> J[[complete_onboarding → user_consents]]
  H -- yes --> K[Home]
  J --> K
  K --> L[/donate: blood group, availability, contact method, optional facility & last donation/]
  L --> M{Privacy consent ticked?}
  M -- no --> L
  M -- yes --> N[[register_donor → alias D-XXXXX, role donor]]
  N --> O[Donor card: alias, group, city, availability toggle]
  O --> P[[set_donor_availability: available / unavailable / suspended until date]]
```

## 2. Request status lifecycle

Exactly the transitions allowed by `public._allowed_transition`. `matching_donors` and `donors_responding` are also set automatically by `run_auto_matching`, `send_manual_match` and `respond_to_match`; `donation_arranged` by `schedule_appointment`; `expired` by `expire_overdue_requests` (pg_cron every 15 min).

```mermaid
stateDiagram-v2
  [*] --> submitted: submit_blood_request
  submitted --> under_review
  submitted --> verified
  submitted --> rejected
  submitted --> cancelled
  submitted --> expired
  under_review --> verified
  under_review --> rejected
  under_review --> cancelled
  under_review --> expired
  verified --> matching_donors
  verified --> rejected
  verified --> cancelled
  verified --> expired
  verified --> completed
  matching_donors --> donors_responding
  matching_donors --> donation_arranged
  matching_donors --> cancelled
  matching_donors --> expired
  matching_donors --> completed
  donors_responding --> matching_donors
  donors_responding --> donation_arranged
  donors_responding --> cancelled
  donors_responding --> expired
  donors_responding --> completed
  donation_arranged --> donors_responding
  donation_arranged --> completed
  donation_arranged --> cancelled
  donation_arranged --> expired
  completed --> [*]
  rejected --> [*]
  cancelled --> [*]
  expired --> [*]
```

Who may move it:

| Target | Allowed caller |
|---|---|
| `cancelled` | the requester, or a reviewer (admin / staff of the named institution) |
| `expired` | admin, or the scheduled job |
| anything else | reviewer only; `rejected` needs a note |

On a terminal status, pending matches are closed and donors who were still waiting get a notification.

## 3. Emergency request → matching → donation

```mermaid
sequenceDiagram
  autonumber
  actor R as Requester
  participant App as PWA
  participant DB as Postgres (RPC + RLS)
  actor S as Staff / Admin
  actor D as Donor

  R->>App: Fill request form (+ declaration)
  App->>DB: submit_blood_request(...)
  DB-->>R: reference FD-SA-YYMM-XXXXX, status submitted
  DB-->>S: notification "request_needs_review" (institution staff)
  R->>App: Upload documents (private bucket)
  S->>DB: transition_request(id, 'under_review')
  S->>DB: transition_request(id, 'verified', note)
  DB-->>R: notification: verified
  S->>DB: run_auto_matching(id)
  Note over DB: same country + same city + same declared group<br/>+ available + accepts_auto_matching<br/>+ not blocked + not already matched (max 25)
  DB-->>D: notification "match_request" (eligibility decided by blood bank)
  DB-->>R: "matching_started", N donors notified
  D->>DB: respond_to_match(match, accept=true, share_contact?)
  DB-->>R: "donor_accepted"; status donors_responding
  R->>DB: set_contact_consent(match, true)
  D->>DB: set_contact_consent(match, true)
  DB-->>R: "contact_shared"
  R->>DB: get_match_contact(match)
  DB-->>R: donor name, phone, preferred method (audited)
  R->>DB: schedule_appointment(match, time, note)
  DB-->>D: "appointment" with hospital
  Note over D,S: Screening, grouping, crossmatch happen at the facility
  D->>DB: record_donation(match, date) → pending_confirmation
  S->>DB: confirm_donation(record, true)
  DB-->>D: "donation_confirmed"; donor is_verified = true
  S->>DB: transition_request(id, 'completed')
```

A donor may decline (`respond_to_match(..., false)`) or later withdraw an acceptance. Either side may withdraw contact consent; contacts disappear again. A block between the two hides contact and stops messaging.

## 4. Manual search

```mermaid
flowchart TD
  A[/donors/] --> B[Country selector — defaults to my network]
  B --> C[City, blood group, available-only filters]
  C --> D[[search_donors — signed-in only, 120 per 10 min]]
  D --> E[Cards: alias or first name + alias, group, city, availability, verified badge]
  E --> F{Has a verified open request<br/>in this country?}
  F -- no --> G[Prompt: create a request first]
  F -- yes --> H[Choose request → Send donation request]
  H --> I[[send_manual_match]]
  I -->|different country| X1[country_mismatch]
  I -->|donor unavailable / other group| X2[invalid_input]
  I -->|ok| J[Donor notified; continues as journey 3 from step 12]
```

Requesters may only send to the **same blood group** and are limited to 20 manual requests per day. Staff and admins may choose any group.

## 5. Humanitarian initiative

```mermaid
flowchart TD
  A[/initiatives/new/] --> B[Category, titles, description, objectives,<br/>beneficiaries, organizer, country/city, dates]
  B --> C{Save as}
  C -- draft --> D[draft — editable]
  C -- submit --> E[submitted — locked]
  D --> E
  E --> F[Admin: review_initiative under_review]
  F --> G{Decision}
  E --> G
  G -- approved --> H[Public page + organizer role]
  G -- rejected + note --> I[rejected — organizer edits and resubmits]
  I --> E
  H --> J[Organizer posts initiative_updates]
  H --> K[Admin links approved sponsors — campaign_sponsorships]
  H --> L[Admin: completed / archived]
```

Expatriates in Saudi Arabia support Sudan through these initiatives — never through direct donor matching to a request in Sudan.

## 6. Institution onboarding

```mermaid
sequenceDiagram
  actor U as Staff member
  participant DB as Postgres
  actor A as Admin
  U->>DB: insert institutions (type, names, country, city, licence)
  Note over DB: tg_guard_institution forces status = pending, created_by = caller
  U->>DB: upload licence to institution-documents/<id>/
  A->>DB: review_institution(id, approve, note)
  DB-->>U: notification + membership (owner) + role institution_staff
  A->>DB: set_institution_member(id, other_user, true)
  Note over U: Now sees requests that name this institution,<br/>can verify, match, schedule and confirm donations
```
