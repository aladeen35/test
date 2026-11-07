# Test and demonstration data policy

FAZAT DAM handles real emergencies. A fake request, a fake donor or an inflated number can send a real person to the wrong hospital or mislead a family. These rules are mandatory.

## Rules

1. **Never publish fabricated donors, hospitals, blood requests, initiatives, sponsors or statistics** on a public or production environment.
2. **Never claim a donation happened** unless a `donation_records` row is `confirmed` by an institution member or an admin.
3. **Production seeds contain reference data only**: countries, cities and `app_settings` (migration 4). No people, no requests.
4. **Demo data is flagged.** Tables that can hold demo rows have `is_demo boolean not null default false`: `profiles`, `institutions`, `blood_requests`, `donation_records`, `humanitarian_initiatives`, `sponsors`. API callers cannot set the flag (column guards); only SQL run by the owner/admin can.
5. **Demo rows are labelled in the UI** with a grey badge «تجريبي · DEMO» on every card and detail page (the anonymised RPCs return `is_demo`).
6. **Demo rows never count.** `public_stats` excludes them; `admin_stats` excludes them unless the admin ticks "include demo data".
7. **Demo names are obviously fake** and marked: e.g. `[DEMO] متبرع تجريبي`, `مستشفى تجريبي (DEMO)`. Use test phone ranges that cannot reach a real person (Supabase test phone numbers), never real numbers.
8. **Demo data lives in a separate project** (staging/preview). If a demo row is ever created in production for a walkthrough, it is deleted the same day.
9. **Automated tests** (`supabase/tests/`) create their own users and data in a throwaway database that is dropped and recreated on every run.

## Checklist before a public launch

- [ ] `select count(*) from profiles where is_demo` = 0 (and the same for the other five tables)
- [ ] No rows with names containing `DEMO`, `test`, `تجريبي`
- [ ] Supabase test phone numbers removed from Auth settings
- [ ] Statistics on the home page match `public_stats()` and show real zeros if there is no activity yet
