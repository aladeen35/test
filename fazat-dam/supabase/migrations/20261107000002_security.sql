-- =====================================================================
-- FAZAT DAM — security: role helpers, Row Level Security, column guards,
-- audit logging, and new-user bootstrap.
--
-- Principle: tables are readable only by the people a row concerns.
-- Anything shown to strangers (donor search, emergency feed, statistics)
-- goes through SECURITY DEFINER functions in 0003 that return a narrow,
-- anonymised projection. State changes that have rules (request status,
-- matching, consent, donation confirmation) also go through functions,
-- so there are deliberately no UPDATE policies on those tables.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Role helpers (SECURITY DEFINER so they can read user_roles under RLS)
-- ---------------------------------------------------------------------
create or replace function public.has_role(_role public.app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles r
    join public.profiles p on p.id = r.user_id
    where r.user_id = auth.uid() and r.role = _role and p.account_status = 'active'
  );
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select public.has_role('admin');
$$;

create or replace function public.is_active_user()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and account_status = 'active');
$$;

-- Approved institutions the caller is an active member of
create or replace function public.my_institution_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select m.institution_id
  from public.institution_members m
  join public.institutions i on i.id = m.institution_id
  where m.user_id = auth.uid() and m.is_active and i.status = 'approved'
    and public.has_role('institution_staff');
$$;

create or replace function public.is_institution_member(_institution uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select _institution is not null and _institution in (select public.my_institution_ids());
$$;

-- Can the caller act as a reviewer for this request? (admin, or staff of the named institution)
create or replace function public.can_review_request(_request uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists (
    select 1 from public.blood_requests r
    where r.id = _request and public.is_institution_member(r.institution_id)
  );
$$;

create or replace function public.is_blocked_between(_a uuid, _b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_blocks
    where (blocker_id = _a and blocked_id = _b) or (blocker_id = _b and blocked_id = _a)
  );
$$;

-- ---------------------------------------------------------------------
-- New user bootstrap: every auth user gets a profile and the base role.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, phone, email, preferred_language)
  values (
    new.id,
    nullif(regexp_replace(coalesce(new.phone, ''), '[^0-9+]', '', 'g'), ''),
    new.email,
    case when coalesce(new.raw_user_meta_data ->> 'lang', 'ar') = 'en' then 'en' else 'ar' end
  )
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role) values (new.id, 'requester')
  on conflict do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep the profile phone in sync when the verified auth phone changes.
create or replace function public.handle_user_phone_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.phone is distinct from old.phone then
    update public.profiles
      set phone = nullif(regexp_replace(coalesce(new.phone, ''), '[^0-9+]', '', 'g'), '')
      where id = new.id;
  end if;
  return new;
end $$;

create trigger on_auth_user_phone_changed
  after update of phone on auth.users
  for each row execute function public.handle_user_phone_change();

-- ---------------------------------------------------------------------
-- Column guards: non-admins cannot change moderation / verification fields
-- even on rows they are allowed to update.
-- ---------------------------------------------------------------------
-- SECURITY INVOKER on purpose: current_user tells API callers from trusted workflows
create or replace function public.tg_guard_profile()
returns trigger language plpgsql set search_path = public as $$
begin
  -- guards apply to API callers only; trusted workflow functions run as the table owner
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return new;
  end if;
  new.id := old.id;
  new.phone := old.phone;            -- phone is owned by Auth (OTP-verified)
  new.account_status := old.account_status;
  new.status_note := old.status_note;
  new.deleted_at := old.deleted_at;
  new.is_demo := old.is_demo;
  new.created_at := old.created_at;
  return new;
end $$;
create trigger guard_profile before update on public.profiles
  for each row execute function public.tg_guard_profile();

-- SECURITY INVOKER on purpose: current_user tells API callers from trusted workflows
create or replace function public.tg_guard_donor_profile()
returns trigger language plpgsql set search_path = public as $$
begin
  -- guards apply to API callers only; trusted workflow functions run as the table owner
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.is_verified := false;
    return new;
  end if;
  new.user_id := old.user_id;
  new.public_alias := old.public_alias;
  new.is_verified := old.is_verified;
  return new;
end $$;
create trigger guard_donor_profile before insert or update on public.donor_profiles
  for each row execute function public.tg_guard_donor_profile();

-- SECURITY INVOKER on purpose: current_user tells API callers from trusted workflows
create or replace function public.tg_guard_institution()
returns trigger language plpgsql set search_path = public as $$
begin
  -- guards apply to API callers only; trusted workflow functions run as the table owner
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.review_note := null; new.reviewed_by := null; new.reviewed_at := null;
    new.created_by := auth.uid();
    new.is_demo := false;
    return new;
  end if;
  new.status := old.status;
  new.review_note := old.review_note;
  new.reviewed_by := old.reviewed_by;
  new.reviewed_at := old.reviewed_at;
  new.created_by := old.created_by;
  new.type := old.type;
  new.country_code := old.country_code;   -- network membership is fixed after approval
  new.is_demo := old.is_demo;
  return new;
end $$;
create trigger guard_institution before insert or update on public.institutions
  for each row execute function public.tg_guard_institution();

-- SECURITY INVOKER on purpose: current_user tells API callers from trusted workflows
create or replace function public.tg_guard_initiative()
returns trigger language plpgsql set search_path = public as $$
begin
  -- guards apply to API callers only; trusted workflow functions run as the table owner
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.organizer_id := auth.uid();
    if new.status not in ('draft', 'submitted') then new.status := 'submitted'; end if;
    new.review_note := null; new.reviewed_by := null; new.reviewed_at := null; new.published_at := null;
    new.is_demo := false;
    return new;
  end if;
  -- organisers may edit a draft or a rejected proposal and (re)submit it; nothing else
  if old.status not in ('draft', 'rejected') then
    raise exception 'initiative_locked' using errcode = '42501';
  end if;
  if new.status not in ('draft', 'submitted') then
    new.status := old.status;
  end if;
  new.organizer_id := old.organizer_id;
  new.review_note := old.review_note;
  new.reviewed_by := old.reviewed_by;
  new.reviewed_at := old.reviewed_at;
  new.published_at := old.published_at;
  new.is_demo := old.is_demo;
  return new;
end $$;
create trigger guard_initiative before insert or update on public.humanitarian_initiatives
  for each row execute function public.tg_guard_initiative();

-- SECURITY INVOKER on purpose: current_user tells API callers from trusted workflows
create or replace function public.tg_guard_sponsor()
returns trigger language plpgsql set search_path = public as $$
begin
  -- guards apply to API callers only; trusted workflow functions run as the table owner
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return new;
  end if;
  new.status := 'pending';
  new.review_note := null; new.reviewed_by := null; new.reviewed_at := null;
  new.submitted_by := auth.uid();
  new.is_demo := false;
  return new;
end $$;
create trigger guard_sponsor before insert on public.sponsors
  for each row execute function public.tg_guard_sponsor();

-- ---------------------------------------------------------------------
-- Audit logging. Personal contact fields are stripped before storage.
-- ---------------------------------------------------------------------
create or replace function public.tg_audit()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  _old jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end;
  _new jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end;
  _strip text[] := array['phone', 'email', 'full_name', 'contact_phone', 'contact_email', 'organizer_contact', 'body', 'p256dh', 'auth'];
  _id uuid;
begin
  _old := _old - _strip;
  _new := _new - _strip;
  if tg_op = 'UPDATE' and _old = _new then
    return new;
  end if;
  _id := coalesce((_new ->> 'id'), (_old ->> 'id'), (_new ->> 'user_id'), (_old ->> 'user_id'))::uuid;
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, old_data, new_data)
  values (auth.uid(), lower(tg_op), tg_table_name, _id, _old, _new);
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'user_roles', 'donor_profiles', 'institutions', 'institution_members',
    'blood_requests', 'donor_matches', 'donation_records', 'humanitarian_initiatives',
    'sponsors', 'campaign_sponsorships', 'reports', 'cities', 'countries', 'app_settings'
  ] loop
    execute format('create trigger audit after insert or update or delete on public.%I for each row execute function public.tg_audit()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    -- ENABLE (not FORCE): the table owner, which runs the SECURITY DEFINER
    -- workflow functions below, bypasses RLS; API roles never do.
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Reference data: public read, admin write
create policy countries_read on public.countries for select using (is_active or public.is_admin());
create policy countries_admin on public.countries for all using (public.is_admin()) with check (public.is_admin());
create policy cities_read on public.cities for select using (is_active or public.is_admin());
create policy cities_admin on public.cities for all using (public.is_admin()) with check (public.is_admin());
create policy settings_read on public.app_settings for select using (true);
create policy settings_admin on public.app_settings for all using (public.is_admin()) with check (public.is_admin());

-- Profiles: you and admins only. Nobody else ever selects a profile row.
create policy profiles_self_read on public.profiles for select using (id = auth.uid() or public.is_admin());
create policy profiles_self_update on public.profiles for update
  using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());

create policy roles_read on public.user_roles for select using (user_id = auth.uid() or public.is_admin());
create policy roles_admin on public.user_roles for all using (public.is_admin()) with check (public.is_admin());

-- Donor profile: owner and admins. Search goes through search_donors().
create policy donor_self_read on public.donor_profiles for select using (user_id = auth.uid() or public.is_admin());
create policy donor_admin_update on public.donor_profiles for update
  using (public.is_admin()) with check (public.is_admin());
create policy donor_self_delete on public.donor_profiles for delete using (user_id = auth.uid() or public.is_admin());
-- insert/update happen in register_donor() and set_donor_availability()

-- Institutions: approved ones are a public directory
create policy institutions_read on public.institutions for select using (
  created_by = auth.uid() or public.is_institution_member(id) or public.is_admin()
);
create policy institutions_insert on public.institutions for insert
  with check (auth.uid() is not null and public.is_active_user());
create policy institutions_update on public.institutions for update
  using (public.is_institution_member(id) or (created_by = auth.uid() and status = 'pending') or public.is_admin())
  with check (public.is_institution_member(id) or created_by = auth.uid() or public.is_admin());
create policy institutions_admin_delete on public.institutions for delete using (public.is_admin());

create policy inst_members_read on public.institution_members for select
  using (user_id = auth.uid() or public.is_institution_member(institution_id) or public.is_admin());
create policy inst_members_admin on public.institution_members for all using (public.is_admin()) with check (public.is_admin());

create policy inst_docs_read on public.institution_documents for select using (
  public.is_admin() or exists (select 1 from public.institutions i where i.id = institution_id and i.created_by = auth.uid())
);
create policy inst_docs_insert on public.institution_documents for insert with check (
  uploaded_by = auth.uid() and exists (
    select 1 from public.institutions i where i.id = institution_id and (i.created_by = auth.uid() or public.is_institution_member(i.id))
  )
);

-- Blood requests: requester, reviewers of the named institution, admins.
-- Matched donors see a reduced projection through my_donation_requests().
create policy requests_read on public.blood_requests for select using (
  requester_id = auth.uid() or public.is_institution_member(institution_id) or public.is_admin()
);
-- insert/update via submit_blood_request() / transition_request()

create policy request_docs_read on public.request_documents for select using (
  public.is_admin() or exists (
    select 1 from public.blood_requests r where r.id = request_id
      and (r.requester_id = auth.uid() or public.is_institution_member(r.institution_id))
  )
);
create policy request_docs_insert on public.request_documents for insert with check (
  uploaded_by = auth.uid() and exists (
    select 1 from public.blood_requests r where r.id = request_id and r.requester_id = auth.uid()
      and r.status in ('submitted', 'under_review')
  )
);

create policy matches_read on public.donor_matches for select using (
  donor_id = auth.uid() or public.is_admin() or exists (
    select 1 from public.blood_requests r where r.id = request_id
      and (r.requester_id = auth.uid() or public.is_institution_member(r.institution_id))
  )
);

create policy responses_read on public.donor_responses for select using (
  donor_id = auth.uid() or public.is_admin() or exists (
    select 1 from public.donor_matches m join public.blood_requests r on r.id = m.request_id
    where m.id = match_id and (r.requester_id = auth.uid() or public.is_institution_member(r.institution_id))
  )
);

-- Contact/messaging stays open while the request is live and for 7 days after completion.
create or replace function public._request_contact_open(_status public.request_status, _closed timestamptz)
returns boolean language sql stable as $$
  select _status not in ('rejected', 'cancelled', 'expired')
     and (_status <> 'completed' or _closed is null or _closed > now() - interval '7 days');
$$;

create or replace function public.is_match_party(_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.donor_matches m join public.blood_requests r on r.id = m.request_id
    where m.id = _match and (m.donor_id = auth.uid() or r.requester_id = auth.uid())
  );
$$;

create or replace function public.can_message(_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.donor_matches m join public.blood_requests r on r.id = m.request_id
    where m.id = _match
      and m.contact_shared_at is not null
      and m.status = 'accepted'
      and public._request_contact_open(r.status, r.closed_at)
      and (m.donor_id = auth.uid() or r.requester_id = auth.uid())
      and not public.is_blocked_between(m.donor_id, r.requester_id)
  ) and public.is_active_user();
$$;

create policy messages_read on public.messages for select using (public.is_match_party(match_id) or public.is_admin());
create policy messages_insert on public.messages for insert with check (sender_id = auth.uid() and public.can_message(match_id));

create policy donations_read on public.donation_records for select using (
  donor_id = auth.uid() or public.is_institution_member(institution_id) or public.is_admin() or exists (
    select 1 from public.blood_requests r where r.id = request_id and r.requester_id = auth.uid()
  )
);
-- writes via record_donation() / confirm_donation()

-- Initiatives: only approved/completed are public
create policy initiatives_read on public.humanitarian_initiatives for select using (
  organizer_id = auth.uid() or public.is_admin()
);
create policy initiatives_insert on public.humanitarian_initiatives for insert
  with check (auth.uid() is not null and public.is_active_user());
create policy initiatives_update on public.humanitarian_initiatives for update
  using (organizer_id = auth.uid() or public.is_admin())
  with check (organizer_id = auth.uid() or public.is_admin());
create policy initiatives_admin_delete on public.humanitarian_initiatives for delete
  using (public.is_admin() or (organizer_id = auth.uid() and status = 'draft'));

create policy init_docs_read on public.initiative_documents for select using (
  public.is_admin() or exists (select 1 from public.humanitarian_initiatives i where i.id = initiative_id and i.organizer_id = auth.uid())
);
create policy init_docs_insert on public.initiative_documents for insert with check (
  uploaded_by = auth.uid() and exists (
    select 1 from public.humanitarian_initiatives i where i.id = initiative_id and i.organizer_id = auth.uid()
      and i.status in ('draft', 'submitted', 'rejected')
  )
);

create or replace function public.initiative_visible(_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.humanitarian_initiatives i where i.id = _id
                 and (i.status in ('approved', 'completed') or i.organizer_id = auth.uid()));
$$;
create policy init_updates_read on public.initiative_updates for select using (
  public.initiative_visible(initiative_id) or public.is_admin()
);
create policy init_updates_insert on public.initiative_updates for insert with check (
  author_id = auth.uid() and (public.is_admin() or exists (
    select 1 from public.humanitarian_initiatives i where i.id = initiative_id
      and i.organizer_id = auth.uid() and i.status = 'approved'
  ))
);

-- Sponsors: shown publicly only once approved
create policy sponsors_read on public.sponsors for select using (submitted_by = auth.uid() or public.is_admin());
create policy sponsors_insert on public.sponsors for insert with check (auth.uid() is not null and public.is_active_user());
create policy sponsors_admin on public.sponsors for update using (public.is_admin()) with check (public.is_admin());
create policy sponsors_admin_delete on public.sponsors for delete using (public.is_admin());

create policy sponsorships_read on public.campaign_sponsorships for select using (public.is_admin());
create policy sponsorships_admin on public.campaign_sponsorships for all using (public.is_admin()) with check (public.is_admin());

-- Notifications & push: owner only
create policy notifications_read on public.notifications for select using (user_id = auth.uid());
create policy notifications_mark_read on public.notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy push_own on public.push_subscriptions for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy consents_read on public.user_consents for select using (user_id = auth.uid() or public.is_admin());
create policy consents_insert on public.user_consents for insert with check (user_id = auth.uid());

create policy reports_insert on public.reports for insert with check (reporter_id = auth.uid() and public.is_active_user());
create policy reports_read on public.reports for select using (reporter_id = auth.uid() or public.is_admin());
create policy reports_admin on public.reports for update using (public.is_admin()) with check (public.is_admin());

create policy blocks_own on public.user_blocks for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

create policy audit_admin_read on public.audit_logs for select using (public.is_admin());
-- rate_limit_events: no policies -> no direct access

-- Notifications: a user may only flip read_at on their own rows.
create or replace function public.tg_guard_notification()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.user_id := old.user_id; new.type := old.type;
    new.title_ar := old.title_ar; new.title_en := old.title_en;
    new.body_ar := old.body_ar; new.body_en := old.body_en;
    new.link := old.link; new.entity_type := old.entity_type; new.entity_id := old.entity_id;
    new.pushed_at := old.pushed_at; new.created_at := old.created_at;
  end if;
  return new;
end $$;
create trigger guard_notification before update on public.notifications
  for each row execute function public.tg_guard_notification();

-- ---------------------------------------------------------------------
-- Public projections. These views run with the owner's rights (no
-- security_invoker) on purpose: they expose ONLY approved rows and ONLY
-- non-sensitive columns (no review notes, creators, organiser contacts).
-- ---------------------------------------------------------------------
create view public.public_institutions as
  select id, type, name_ar, name_en, country_code, city_id, address, contact_phone, is_demo
    from public.institutions where status = 'approved';

create view public.public_initiatives as
  select id, category, title_ar, title_en, description, objectives, beneficiaries, organizer_name,
         country_code, city_id, start_date, end_date, status, published_at, is_demo, created_at
    from public.humanitarian_initiatives where status in ('approved', 'completed');

create view public.public_sponsors as
  select id, type, name_ar, name_en, description, website, logo_path, country_code, is_demo
    from public.sponsors where status = 'approved';

create view public.public_campaign_sponsors as
  select cs.initiative_id, s.id as sponsor_id, s.name_ar, s.name_en, s.logo_path, s.website, cs.contribution_note
    from public.campaign_sponsorships cs
    join public.sponsors s on s.id = cs.sponsor_id and s.status = 'approved'
    join public.humanitarian_initiatives i on i.id = cs.initiative_id and i.status in ('approved', 'completed')
   where cs.status = 'approved';

-- Table privileges (RLS still applies on top of these)
-- Supabase grants ALL to API roles by default: start from nothing, then grant what is needed
revoke all on all tables in schema public from anon, authenticated;
grant select on public.countries, public.cities, public.app_settings, public.initiative_updates,
  public.public_institutions, public.public_initiatives, public.public_sponsors, public.public_campaign_sponsors
  to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
revoke all on public.rate_limit_events from authenticated;
revoke insert, update, delete on public.audit_logs from authenticated;
