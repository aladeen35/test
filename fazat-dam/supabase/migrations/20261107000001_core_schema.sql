-- =====================================================================
-- FAZAT DAM | فزعة دم — core schema
-- Tables, enums, constraints, indexes, timestamps.
-- Security (RLS) lives in 0002, workflows (RPCs) in 0003.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------
create type public.app_role as enum ('donor', 'requester', 'institution_staff', 'organizer', 'admin');
create type public.blood_group as enum ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-');
create type public.availability_status as enum ('available', 'unavailable', 'temporarily_suspended');
create type public.contact_method as enum ('in_app', 'phone_call', 'whatsapp', 'sms');
create type public.account_status as enum ('active', 'suspended', 'deleted');
create type public.request_status as enum (
  'submitted', 'under_review', 'verified', 'matching_donors', 'donors_responding',
  'donation_arranged', 'completed', 'rejected', 'cancelled', 'expired'
);
create type public.urgency_level as enum ('normal', 'urgent', 'critical');
create type public.match_method as enum ('automated', 'manual');
create type public.match_status as enum ('pending', 'accepted', 'declined', 'withdrawn', 'cancelled', 'expired');
create type public.donation_status as enum ('pending_confirmation', 'confirmed', 'not_completed');
create type public.institution_type as enum ('hospital', 'blood_bank');
create type public.approval_status as enum ('pending', 'approved', 'rejected', 'suspended');
create type public.initiative_status as enum ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'completed', 'archived');
create type public.initiative_category as enum (
  'blood_drive', 'medical_support', 'hospital_assistance', 'volunteer', 'awareness', 'partnership'
);
create type public.sponsor_type as enum ('corporate', 'community', 'hospital', 'blood_bank', 'humanitarian_org');
create type public.consent_type as enum (
  'privacy_policy', 'terms_of_use', 'data_processing', 'contact_sharing', 'push_notifications', 'request_declaration'
);
create type public.report_target as enum ('user', 'blood_request', 'initiative', 'message', 'institution');
create type public.report_status as enum ('open', 'reviewing', 'resolved', 'dismissed');

-- ---------------------------------------------------------------------
-- Shared trigger: updated_at
-- ---------------------------------------------------------------------
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- Geography. Countries use their ISO-3166 alpha-2 code as natural key
-- (the only non-UUID key in the schema). Two networks: SD and SA.
-- ---------------------------------------------------------------------
create table public.countries (
  code         char(2) primary key check (code ~ '^[A-Z]{2}$'),
  name_ar      text not null,
  name_en      text not null,
  phone_prefix text not null check (phone_prefix ~ '^\+[0-9]{1,4}$'),
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table public.cities (
  id           uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries(code),
  name_ar      text not null check (length(name_ar) between 2 and 80),
  name_en      text not null check (length(name_en) between 2 and 80),
  is_active    boolean not null default true,
  sort_order   integer not null default 100,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  -- lets every other table enforce "city belongs to this country" with a composite FK
  unique (id, country_code),
  unique (country_code, name_en)
);
create index cities_country_idx on public.cities (country_code, is_active, sort_order);

-- ---------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------
create table public.profiles (
  id                 uuid primary key references auth.users(id) on delete cascade,
  full_name          text check (full_name is null or length(full_name) between 2 and 120),
  phone              text check (phone is null or phone ~ '^\+?[0-9]{8,15}$'),  -- PRIVATE: never exposed except after mutual consent
  email              text check (email is null or email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  country_code       char(2) references public.countries(code),
  city_id            uuid,
  preferred_language text not null default 'ar' check (preferred_language in ('ar', 'en')),
  account_status     public.account_status not null default 'active',
  status_note        text,
  onboarded_at       timestamptz,
  deleted_at         timestamptz,
  is_demo            boolean not null default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  foreign key (city_id, country_code) references public.cities(id, country_code)
);
create index profiles_country_city_idx on public.profiles (country_code, city_id);
create index profiles_status_idx on public.profiles (account_status);

create table public.user_roles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  role       public.app_role not null,
  granted_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, role)
);
create index user_roles_role_idx on public.user_roles (role);

create table public.donor_profiles (
  user_id                uuid primary key references public.profiles(id) on delete cascade,
  public_alias           text not null unique,             -- e.g. "D-7K3QX", shown instead of a name
  blood_group            public.blood_group not null,
  country_code           char(2) not null references public.countries(code),
  city_id                uuid not null,
  availability           public.availability_status not null default 'available',
  suspended_until        date,
  contact_method         public.contact_method not null default 'in_app',
  show_first_name        boolean not null default false,   -- privacy: alias only unless the donor opts in
  accepts_auto_matching  boolean not null default true,
  preferred_facility     text check (preferred_facility is null or length(preferred_facility) <= 160),
  last_donation_date     date check (last_donation_date is null or last_donation_date <= current_date),
  is_verified            boolean not null default false,   -- set only after an institution-confirmed donation
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  foreign key (city_id, country_code) references public.cities(id, country_code),
  check (availability <> 'temporarily_suspended' or suspended_until is not null)
);
create index donor_profiles_match_idx
  on public.donor_profiles (country_code, city_id, blood_group, availability);

-- ---------------------------------------------------------------------
-- Institutions (hospitals and blood banks share one table, typed)
-- ---------------------------------------------------------------------
create table public.institutions (
  id             uuid primary key default gen_random_uuid(),
  type           public.institution_type not null,
  name_ar        text not null check (length(name_ar) between 2 and 160),
  name_en        text check (name_en is null or length(name_en) between 2 and 160),
  country_code   char(2) not null references public.countries(code),
  city_id        uuid not null,
  license_number text check (license_number is null or length(license_number) <= 80),
  address        text check (address is null or length(address) <= 300),
  contact_phone  text check (contact_phone is null or contact_phone ~ '^\+?[0-9]{6,15}$'),
  contact_email  text,
  status         public.approval_status not null default 'pending',
  review_note    text,
  reviewed_by    uuid references public.profiles(id) on delete set null,
  reviewed_at    timestamptz,
  created_by     uuid references public.profiles(id) on delete set null,
  is_demo        boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  foreign key (city_id, country_code) references public.cities(id, country_code)
);
create index institutions_geo_idx on public.institutions (country_code, city_id, status);

create table public.institution_members (
  id             uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id        uuid not null references public.profiles(id) on delete cascade,
  title          text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (institution_id, user_id)
);
create index institution_members_user_idx on public.institution_members (user_id) where is_active;

create table public.institution_documents (
  id             uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  uploaded_by    uuid references public.profiles(id) on delete set null,
  storage_path   text not null unique,
  file_name      text not null,
  mime_type      text not null,
  size_bytes     integer not null check (size_bytes between 1 and 10485760),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Convenience views requested by the spec. security_invoker keeps RLS of the caller.
create view public.hospitals with (security_invoker = true) as
  select * from public.institutions where type = 'hospital';
create view public.blood_banks with (security_invoker = true) as
  select * from public.institutions where type = 'blood_bank';

-- ---------------------------------------------------------------------
-- Blood requests and the matching pipeline
-- ---------------------------------------------------------------------
create table public.blood_requests (
  id                   uuid primary key default gen_random_uuid(),
  reference            text not null unique,                -- e.g. FD-SA-2611-7K3QX
  requester_id         uuid references public.profiles(id) on delete set null,
  patient_initials     text check (patient_initials is null or length(patient_initials) <= 12), -- data minimisation: no full patient name
  requester_relation   text not null check (requester_relation in ('self', 'family', 'friend', 'medical_staff', 'other')),
  blood_group          public.blood_group not null,
  units                smallint not null check (units between 1 and 20),
  country_code         char(2) not null references public.countries(code),
  city_id              uuid not null,
  institution_id       uuid references public.institutions(id) on delete set null,
  hospital_name        text not null check (length(hospital_name) between 2 and 160),
  required_by          timestamptz not null,
  urgency              public.urgency_level not null default 'normal',
  status               public.request_status not null default 'submitted',
  notes                text check (notes is null or length(notes) <= 500),
  declaration_accepted boolean not null check (declaration_accepted),
  review_note          text,
  verified_by          uuid references public.profiles(id) on delete set null,
  verified_at          timestamptz,
  closed_at            timestamptz,
  expires_at           timestamptz not null,
  is_demo              boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  foreign key (city_id, country_code) references public.cities(id, country_code)
);
create index blood_requests_requester_idx on public.blood_requests (requester_id, created_at desc);
create index blood_requests_feed_idx on public.blood_requests (country_code, status, urgency, required_by);
create index blood_requests_city_idx on public.blood_requests (city_id, blood_group, status);
create index blood_requests_institution_idx on public.blood_requests (institution_id, status);
create index blood_requests_expiry_idx on public.blood_requests (expires_at)
  where status not in ('completed', 'rejected', 'cancelled', 'expired');

create table public.request_documents (
  id           uuid primary key default gen_random_uuid(),
  request_id   uuid not null references public.blood_requests(id) on delete cascade,
  uploaded_by  uuid references public.profiles(id) on delete set null,
  storage_path text not null unique,
  file_name    text not null,
  mime_type    text not null check (mime_type in ('application/pdf', 'image/jpeg', 'image/png', 'image/webp')),
  size_bytes   integer not null check (size_bytes between 1 and 10485760),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index request_documents_request_idx on public.request_documents (request_id);

create table public.donor_matches (
  id                        uuid primary key default gen_random_uuid(),
  request_id                uuid not null references public.blood_requests(id) on delete cascade,
  donor_id                  uuid not null references public.donor_profiles(user_id) on delete cascade,
  method                    public.match_method not null,
  status                    public.match_status not null default 'pending',
  matched_by                uuid references public.profiles(id) on delete set null,
  donor_contact_consent     boolean not null default false,
  requester_contact_consent boolean not null default false,
  contact_shared_at         timestamptz,
  appointment_at            timestamptz,
  appointment_note          text check (appointment_note is null or length(appointment_note) <= 300),
  responded_at              timestamptz,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  unique (request_id, donor_id)
);
create index donor_matches_donor_idx on public.donor_matches (donor_id, status, created_at desc);
create index donor_matches_request_idx on public.donor_matches (request_id, status);

create table public.donor_responses (
  id         uuid primary key default gen_random_uuid(),
  match_id   uuid not null references public.donor_matches(id) on delete cascade,
  donor_id   uuid not null references public.donor_profiles(user_id) on delete cascade,
  response   text not null check (response in ('accepted', 'declined', 'withdrawn')),
  reason     text check (reason is null or length(reason) <= 300),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index donor_responses_match_idx on public.donor_responses (match_id, created_at desc);

-- In-app messages: only between the two parties of a match after mutual contact consent.
create table public.messages (
  id         uuid primary key default gen_random_uuid(),
  match_id   uuid not null references public.donor_matches(id) on delete cascade,
  sender_id  uuid not null references public.profiles(id) on delete cascade,
  body       text not null check (length(body) between 1 and 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index messages_match_idx on public.messages (match_id, created_at);

-- A donation is only "confirmed" when an institution or an admin confirms it.
create table public.donation_records (
  id             uuid primary key default gen_random_uuid(),
  request_id     uuid references public.blood_requests(id) on delete set null,
  match_id       uuid unique references public.donor_matches(id) on delete set null,
  donor_id       uuid references public.profiles(id) on delete set null,
  institution_id uuid references public.institutions(id) on delete set null,
  status         public.donation_status not null default 'pending_confirmation',
  donated_on     date not null check (donated_on <= current_date),
  units          smallint not null default 1 check (units between 1 and 4),
  notes          text check (notes is null or length(notes) <= 300),
  recorded_by    uuid references public.profiles(id) on delete set null,
  confirmed_by   uuid references public.profiles(id) on delete set null,
  confirmed_at   timestamptz,
  is_demo        boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  check (status <> 'confirmed' or (confirmed_by is not null and confirmed_at is not null))
);
create index donation_records_donor_idx on public.donation_records (donor_id, donated_on desc);
create index donation_records_institution_idx on public.donation_records (institution_id, status);

-- ---------------------------------------------------------------------
-- Humanitarian initiatives, sponsors
-- ---------------------------------------------------------------------
create table public.humanitarian_initiatives (
  id                uuid primary key default gen_random_uuid(),
  organizer_id      uuid references public.profiles(id) on delete set null,
  organizer_name    text not null check (length(organizer_name) between 2 and 160),
  organizer_contact text check (organizer_contact is null or length(organizer_contact) <= 160),
  category          public.initiative_category not null,
  title_ar          text not null check (length(title_ar) between 4 and 160),
  title_en          text check (title_en is null or length(title_en) between 4 and 160),
  description       text not null check (length(description) between 20 and 4000),
  objectives        text not null check (length(objectives) between 10 and 2000),
  beneficiaries     text not null check (length(beneficiaries) between 4 and 1000),
  country_code      char(2) not null references public.countries(code),
  city_id           uuid,
  start_date        date not null,
  end_date          date,
  status            public.initiative_status not null default 'draft',
  review_note       text,
  reviewed_by       uuid references public.profiles(id) on delete set null,
  reviewed_at       timestamptz,
  published_at      timestamptz,
  is_demo           boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  foreign key (city_id, country_code) references public.cities(id, country_code),
  check (end_date is null or end_date >= start_date)
);
create index initiatives_public_idx on public.humanitarian_initiatives (status, country_code, start_date desc);
create index initiatives_organizer_idx on public.humanitarian_initiatives (organizer_id);

create table public.initiative_documents (
  id            uuid primary key default gen_random_uuid(),
  initiative_id uuid not null references public.humanitarian_initiatives(id) on delete cascade,
  uploaded_by   uuid references public.profiles(id) on delete set null,
  storage_path  text not null unique,
  file_name     text not null,
  mime_type     text not null,
  size_bytes    integer not null check (size_bytes between 1 and 10485760),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table public.initiative_updates (
  id            uuid primary key default gen_random_uuid(),
  initiative_id uuid not null references public.humanitarian_initiatives(id) on delete cascade,
  author_id     uuid references public.profiles(id) on delete set null,
  body          text not null check (length(body) between 4 and 2000),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index initiative_updates_idx on public.initiative_updates (initiative_id, created_at desc);

create table public.sponsors (
  id           uuid primary key default gen_random_uuid(),
  type         public.sponsor_type not null,
  name_ar      text not null check (length(name_ar) between 2 and 160),
  name_en      text,
  description  text check (description is null or length(description) <= 1000),
  website      text check (website is null or website ~* '^https://'),
  logo_path    text,
  country_code char(2) references public.countries(code),
  status       public.approval_status not null default 'pending',
  review_note  text,
  submitted_by uuid references public.profiles(id) on delete set null,
  reviewed_by  uuid references public.profiles(id) on delete set null,
  reviewed_at  timestamptz,
  is_demo      boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index sponsors_status_idx on public.sponsors (status, type);

create table public.campaign_sponsorships (
  id                uuid primary key default gen_random_uuid(),
  initiative_id     uuid not null references public.humanitarian_initiatives(id) on delete cascade,
  sponsor_id        uuid not null references public.sponsors(id) on delete cascade,
  contribution_note text check (contribution_note is null or length(contribution_note) <= 500),
  status            public.approval_status not null default 'pending',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (initiative_id, sponsor_id)
);

-- ---------------------------------------------------------------------
-- Notifications, consent, moderation, audit
-- ---------------------------------------------------------------------
create table public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  type        text not null,
  title_ar    text not null,
  title_en    text not null,
  body_ar     text,
  body_en     text,
  link        text check (link is null or link ~ '^/'),   -- in-app paths only
  entity_type text,
  entity_id   uuid,
  read_at     timestamptz,
  pushed_at   timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_unread_idx on public.notifications (user_id) where read_at is null;
create index notifications_push_idx on public.notifications (created_at) where pushed_at is null;

create table public.push_subscriptions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  endpoint   text not null unique check (endpoint ~ '^https://'),
  p256dh     text not null,
  auth       text not null,
  user_agent text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index push_subscriptions_user_idx on public.push_subscriptions (user_id);

create table public.user_consents (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  consent_type public.consent_type not null,
  version      text not null default '2026-11',
  granted      boolean not null,
  context      jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index user_consents_user_idx on public.user_consents (user_id, consent_type, created_at desc);

create table public.reports (
  id              uuid primary key default gen_random_uuid(),
  reporter_id     uuid references public.profiles(id) on delete set null,
  target_type     public.report_target not null,
  target_id       uuid not null,
  reason          text not null check (reason in ('fraud', 'spam', 'abuse', 'privacy', 'medical_misinformation', 'other')),
  details         text check (details is null or length(details) <= 1000),
  status          public.report_status not null default 'open',
  resolved_by     uuid references public.profiles(id) on delete set null,
  resolution_note text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index reports_status_idx on public.reports (status, created_at desc);

create table public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index user_blocks_blocked_idx on public.user_blocks (blocked_id);

create table public.audit_logs (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid,                 -- no FK: logs outlive accounts
  action      text not null,
  entity_type text not null,
  entity_id   uuid,
  old_data    jsonb,
  new_data    jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index audit_logs_entity_idx on public.audit_logs (entity_type, entity_id, created_at desc);
create index audit_logs_created_idx on public.audit_logs (created_at desc);
create index audit_logs_actor_idx on public.audit_logs (actor_id, created_at desc);

create table public.rate_limit_events (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null,
  action     text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index rate_limit_events_idx on public.rate_limit_events (user_id, action, created_at desc);

create table public.app_settings (
  key        text primary key,
  value      jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- updated_at triggers for every table that has the column
do $$
declare t text;
begin
  for t in
    select c.table_name from information_schema.columns c
    join information_schema.tables tb on tb.table_name = c.table_name and tb.table_schema = c.table_schema
    where c.table_schema = 'public' and c.column_name = 'updated_at' and tb.table_type = 'BASE TABLE'
  loop
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.tg_set_updated_at()', t);
  end loop;
end $$;
