-- =====================================================================
-- FAZAT DAM — workflows (RPC). Every function:
--   * is SECURITY DEFINER with a pinned search_path,
--   * checks the caller (auth.uid()) and their role itself,
--   * raises short machine-readable error codes the UI translates:
--       not_authenticated, not_authorized, account_inactive, rate_limited,
--       not_found, invalid_input, invalid_transition, country_mismatch,
--       consent_required, too_many_open_requests, blocked
-- MEDICAL SAFETY: matching only identifies candidates (same country, same
-- city, same declared ABO/Rh group, available). It never decides clinical
-- compatibility or donor eligibility — the blood bank does.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Internals
-- ---------------------------------------------------------------------
create or replace function public._require_user()
returns uuid language plpgsql stable security definer set search_path = public as $$
declare _uid uuid := auth.uid();
begin
  if _uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if not exists (select 1 from public.profiles where id = _uid and account_status = 'active') then
    raise exception 'account_inactive' using errcode = '42501';
  end if;
  return _uid;
end $$;

create or replace function public._rate_limit(_action text, _max integer, _window interval)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := auth.uid(); _n integer;
begin
  if _uid is null or public.is_admin() then return; end if;
  select count(*) into _n from public.rate_limit_events
   where user_id = _uid and action = _action and created_at > now() - _window;
  if _n >= _max then raise exception 'rate_limited' using errcode = '54000'; end if;
  insert into public.rate_limit_events (user_id, action) values (_uid, _action);
end $$;

create or replace function public._code(_len integer default 5)
returns text language sql volatile as $$
  -- Crockford-style alphabet: no 0/O/1/I confusion
  select string_agg(substr('23456789ABCDEFGHJKLMNPQRSTUVWXYZ', 1 + floor(random() * 32)::int, 1), '')
  from generate_series(1, _len);
$$;

create or replace function public._setting(_key text, _path text, _default numeric)
returns numeric language sql stable security definer set search_path = public as $$
  select coalesce((select (value ->> _path)::numeric from public.app_settings where key = _key), _default);
$$;

create or replace function public._notify(
  _user uuid, _type text, _title_ar text, _title_en text,
  _body_ar text default null, _body_en text default null,
  _link text default null, _entity_type text default null, _entity_id uuid default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if _user is null then return; end if;
  insert into public.notifications (user_id, type, title_ar, title_en, body_ar, body_en, link, entity_type, entity_id)
  values (_user, _type, _title_ar, _title_en, _body_ar, _body_en, _link, _entity_type, _entity_id);
end $$;

create or replace function public._record_consent(_type public.consent_type, _granted boolean, _context jsonb default '{}')
returns void language sql security definer set search_path = public as $$
  insert into public.user_consents (user_id, consent_type, granted, context) values (auth.uid(), _type, _granted, _context);
$$;

create or replace function public._city_label(_city uuid, _lang text default 'ar')
returns text language sql stable security definer set search_path = public as $$
  select case when _lang = 'en' then name_en else name_ar end from public.cities where id = _city;
$$;

-- ---------------------------------------------------------------------
-- Onboarding & donor profile
-- ---------------------------------------------------------------------
create or replace function public.complete_onboarding(
  p_full_name text, p_country char(2), p_city uuid, p_language text, p_accept_privacy boolean
) returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user();
begin
  if not coalesce(p_accept_privacy, false) then raise exception 'consent_required'; end if;
  if not exists (select 1 from public.cities where id = p_city and country_code = p_country and is_active) then
    raise exception 'invalid_input';
  end if;
  update public.profiles
     set full_name = btrim(p_full_name), country_code = p_country, city_id = p_city,
         preferred_language = case when p_language = 'en' then 'en' else 'ar' end,
         onboarded_at = coalesce(onboarded_at, now())
   where id = _uid;
  perform public._record_consent('privacy_policy', true, jsonb_build_object('at', 'onboarding'));
  perform public._record_consent('data_processing', true, jsonb_build_object('at', 'onboarding'));
end $$;

create or replace function public.register_donor(
  p_full_name text, p_country char(2), p_city uuid, p_blood_group public.blood_group,
  p_availability public.availability_status, p_contact_method public.contact_method,
  p_language text, p_accept_privacy boolean,
  p_email text default null, p_preferred_facility text default null,
  p_last_donation_date date default null, p_show_first_name boolean default false,
  p_accepts_auto_matching boolean default true
) returns text language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); _alias text;
begin
  if not coalesce(p_accept_privacy, false) then raise exception 'consent_required'; end if;
  if not exists (select 1 from public.cities where id = p_city and country_code = p_country and is_active) then
    raise exception 'invalid_input';
  end if;
  if p_availability = 'temporarily_suspended' then p_availability := 'unavailable'; end if;

  update public.profiles
     set full_name = btrim(p_full_name), country_code = p_country, city_id = p_city,
         preferred_language = case when p_language = 'en' then 'en' else 'ar' end,
         email = coalesce(nullif(btrim(p_email), ''), email),
         onboarded_at = coalesce(onboarded_at, now())
   where id = _uid;

  select public_alias into _alias from public.donor_profiles where user_id = _uid;
  if _alias is null then
    loop
      _alias := 'D-' || public._code(5);
      exit when not exists (select 1 from public.donor_profiles where public_alias = _alias);
    end loop;
  end if;

  insert into public.donor_profiles (user_id, public_alias, blood_group, country_code, city_id, availability,
    contact_method, show_first_name, accepts_auto_matching, preferred_facility, last_donation_date)
  values (_uid, _alias, p_blood_group, p_country, p_city, p_availability, p_contact_method,
    coalesce(p_show_first_name, false), coalesce(p_accepts_auto_matching, true),
    nullif(btrim(p_preferred_facility), ''), p_last_donation_date)
  on conflict (user_id) do update set
    blood_group = excluded.blood_group, country_code = excluded.country_code, city_id = excluded.city_id,
    availability = excluded.availability, suspended_until = null, contact_method = excluded.contact_method,
    show_first_name = excluded.show_first_name, accepts_auto_matching = excluded.accepts_auto_matching,
    preferred_facility = excluded.preferred_facility, last_donation_date = excluded.last_donation_date;

  insert into public.user_roles (user_id, role) values (_uid, 'donor') on conflict do nothing;
  perform public._record_consent('privacy_policy', true, jsonb_build_object('at', 'donor_registration'));
  return _alias;
end $$;

create or replace function public.set_donor_availability(p_status public.availability_status, p_until date default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user();
begin
  if p_status = 'temporarily_suspended' and (p_until is null or p_until <= current_date or p_until > current_date + 365) then
    raise exception 'invalid_input';
  end if;
  update public.donor_profiles
     set availability = p_status,
         suspended_until = case when p_status = 'temporarily_suspended' then p_until else null end
   where user_id = _uid;
  if not found then raise exception 'not_found'; end if;
end $$;

-- Effective availability (a suspension ends on its own)
create or replace function public._donor_is_available(d public.donor_profiles)
returns boolean language sql stable as $$
  select d.availability = 'available'
      or (d.availability = 'temporarily_suspended' and d.suspended_until is not null and d.suspended_until < current_date);
$$;

-- ---------------------------------------------------------------------
-- Public, anonymised reads
-- ---------------------------------------------------------------------
-- Donor directory for signed-in users. Never returns phone, full name or address.
create or replace function public.search_donors(
  p_country char(2), p_city uuid default null, p_blood_group public.blood_group default null,
  p_available_only boolean default true, p_limit integer default 30, p_offset integer default 0
) returns table (
  donor_id uuid, display_name text, blood_group public.blood_group, city_id uuid,
  city_ar text, city_en text, is_available boolean, is_verified boolean, is_demo boolean
) language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user();
begin
  perform public._rate_limit('search_donors', 120, interval '10 minutes');
  return query
  select d.user_id,
         case when d.show_first_name and p.full_name is not null
              then split_part(btrim(p.full_name), ' ', 1) || ' · ' || d.public_alias
              else d.public_alias end,
         d.blood_group, d.city_id, c.name_ar, c.name_en,
         public._donor_is_available(d), d.is_verified, p.is_demo
    from public.donor_profiles d
    join public.profiles p on p.id = d.user_id and p.account_status = 'active'
    join public.cities c on c.id = d.city_id
   where d.country_code = p_country
     and (p_city is null or d.city_id = p_city)
     and (p_blood_group is null or d.blood_group = p_blood_group)
     and (not p_available_only or public._donor_is_available(d))
     and d.user_id <> _uid
     and not public.is_blocked_between(_uid, d.user_id)
   order by public._donor_is_available(d) desc, d.is_verified desc, d.updated_at desc
   limit least(greatest(coalesce(p_limit, 30), 1), 50) offset greatest(coalesce(p_offset, 0), 0);
end $$;

-- Verified, open requests for the home feed. No patient data, no documents.
create or replace function public.public_emergency_requests(p_country char(2), p_limit integer default 10)
returns table (
  id uuid, reference text, blood_group public.blood_group, units smallint, city_ar text, city_en text,
  hospital_name text, urgency public.urgency_level, required_by timestamptz, status public.request_status,
  is_demo boolean
) language sql stable security definer set search_path = public as $$
  select r.id, r.reference, r.blood_group, r.units, c.name_ar, c.name_en, r.hospital_name, r.urgency,
         r.required_by, r.status, r.is_demo
    from public.blood_requests r join public.cities c on c.id = r.city_id
   where r.country_code = p_country
     and r.status in ('verified', 'matching_donors', 'donors_responding')
     and r.expires_at > now()
   order by case r.urgency when 'critical' then 0 when 'urgent' then 1 else 2 end, r.required_by
   limit least(greatest(coalesce(p_limit, 10), 1), 30);
$$;

-- Real counts only; demo rows excluded. Nothing is shown that did not happen.
create or replace function public.public_stats(p_country char(2) default null)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'registered_donors', (select count(*) from public.donor_profiles d join public.profiles p on p.id = d.user_id
                           where p.account_status = 'active' and not p.is_demo and (p_country is null or d.country_code = p_country)),
    'available_donors', (select count(*) from public.donor_profiles d join public.profiles p on p.id = d.user_id
                           where p.account_status = 'active' and not p.is_demo and public._donor_is_available(d)
                             and (p_country is null or d.country_code = p_country)),
    'verified_requests', (select count(*) from public.blood_requests r
                           where not r.is_demo and r.verified_at is not null and (p_country is null or r.country_code = p_country)),
    'confirmed_donations', (select count(*) from public.donation_records dr
                           left join public.blood_requests r on r.id = dr.request_id
                           where dr.status = 'confirmed' and not dr.is_demo and (p_country is null or r.country_code = p_country)),
    'approved_initiatives', (select count(*) from public.humanitarian_initiatives i
                           where i.status in ('approved', 'completed') and not i.is_demo and (p_country is null or i.country_code = p_country))
  );
$$;

-- ---------------------------------------------------------------------
-- Blood requests
-- ---------------------------------------------------------------------
create or replace function public.submit_blood_request(
  p_relation text, p_blood_group public.blood_group, p_units integer,
  p_country char(2), p_city uuid, p_hospital_name text, p_required_by timestamptz,
  p_urgency public.urgency_level, p_declaration boolean,
  p_patient_initials text default null, p_institution uuid default null, p_notes text default null
) returns table (id uuid, reference text) language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); _ref text; _id uuid; _open integer;
begin
  if not coalesce(p_declaration, false) then raise exception 'consent_required'; end if;
  if p_required_by < now() - interval '1 hour' or p_required_by > now() + interval '30 days' then
    raise exception 'invalid_input';
  end if;
  if not exists (select 1 from public.cities c where c.id = p_city and c.country_code = p_country and c.is_active) then
    raise exception 'invalid_input';
  end if;
  if p_institution is not null and not exists (
      select 1 from public.institutions i where i.id = p_institution and i.status = 'approved' and i.country_code = p_country) then
    raise exception 'country_mismatch';
  end if;
  select count(*) into _open from public.blood_requests r
   where r.requester_id = _uid and r.status not in ('completed', 'rejected', 'cancelled', 'expired');
  if _open >= public._setting('requests', 'max_open_per_user', 3) and not public.is_admin() then
    raise exception 'too_many_open_requests';
  end if;
  perform public._rate_limit('submit_request', public._setting('requests', 'max_per_day', 5)::int, interval '24 hours');

  loop
    _ref := 'FD-' || p_country || '-' || to_char(now(), 'YYMM') || '-' || public._code(5);
    exit when not exists (select 1 from public.blood_requests b where b.reference = _ref);
  end loop;

  insert into public.blood_requests (reference, requester_id, patient_initials, requester_relation, blood_group, units,
    country_code, city_id, institution_id, hospital_name, required_by, urgency, notes, declaration_accepted, expires_at)
  values (_ref, _uid, nullif(btrim(p_patient_initials), ''), p_relation, p_blood_group, p_units,
    p_country, p_city, p_institution, btrim(p_hospital_name), p_required_by, p_urgency, nullif(btrim(p_notes), ''), true,
    greatest(p_required_by, now()) + make_interval(hours => public._setting('requests', 'grace_hours', 24)::int))
  returning blood_requests.id into _id;

  perform public._record_consent('request_declaration', true, jsonb_build_object('request', _id));
  perform public._notify(_uid, 'request_submitted',
    'تم استلام طلبك ' || _ref, 'Request ' || _ref || ' received',
    'سيُراجع الطلب قبل إرساله للمتبرعين.', 'Your request will be reviewed before donors are contacted.',
    '/requests/' || _id, 'blood_request', _id);
  -- reviewers: staff of the chosen institution
  insert into public.notifications (user_id, type, title_ar, title_en, link, entity_type, entity_id)
  select m.user_id, 'request_needs_review', 'طلب جديد بانتظار التحقق ' || _ref, 'New request awaiting verification ' || _ref,
         '/admin/requests/' || _id, 'blood_request', _id
    from public.institution_members m where m.institution_id = p_institution and m.is_active;

  return query select _id, _ref;
end $$;

create or replace function public._allowed_transition(_from public.request_status, _to public.request_status)
returns boolean language sql immutable as $$
  select case _from
    when 'submitted'         then _to in ('under_review', 'verified', 'rejected', 'cancelled', 'expired')
    when 'under_review'      then _to in ('verified', 'rejected', 'cancelled', 'expired')
    when 'verified'          then _to in ('matching_donors', 'rejected', 'cancelled', 'expired', 'completed')
    when 'matching_donors'   then _to in ('donors_responding', 'donation_arranged', 'cancelled', 'expired', 'completed')
    when 'donors_responding' then _to in ('matching_donors', 'donation_arranged', 'cancelled', 'expired', 'completed')
    when 'donation_arranged' then _to in ('donors_responding', 'completed', 'cancelled', 'expired')
    else false
  end;
$$;

-- Single choke point for status changes.
create or replace function public.transition_request(p_request uuid, p_status public.request_status, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); r public.blood_requests; _reviewer boolean;
begin
  select * into r from public.blood_requests where id = p_request for update;
  if not found then raise exception 'not_found'; end if;
  _reviewer := public.can_review_request(p_request);

  if p_status = 'cancelled' then
    if not (r.requester_id = _uid or _reviewer) then raise exception 'not_authorized'; end if;
  elsif p_status = 'expired' then
    if not public.is_admin() then raise exception 'not_authorized'; end if;
  elsif not _reviewer then
    raise exception 'not_authorized';
  end if;
  if not public._allowed_transition(r.status, p_status) then raise exception 'invalid_transition'; end if;
  if p_status = 'rejected' and coalesce(btrim(p_note), '') = '' then raise exception 'invalid_input'; end if;

  update public.blood_requests set
    status = p_status,
    review_note = coalesce(nullif(btrim(p_note), ''), review_note),
    verified_by = case when p_status = 'verified' then _uid else verified_by end,
    verified_at = case when p_status = 'verified' then now() else verified_at end,
    closed_at = case when p_status in ('completed', 'rejected', 'cancelled', 'expired') then now() else closed_at end
  where id = p_request;

  if p_status in ('completed', 'rejected', 'cancelled', 'expired') then
    -- tell donors still waiting, then close their matches
    insert into public.notifications (user_id, type, title_ar, title_en, link, entity_type, entity_id)
    select m.donor_id, 'request_closed',
           'لم يعد الطلب ' || r.reference || ' بحاجة لاستجابة', 'Request ' || r.reference || ' no longer needs a response',
           '/activity', 'blood_request', r.id
      from public.donor_matches m where m.request_id = p_request and m.status in ('pending', 'accepted');
    update public.donor_matches set status = case when p_status = 'expired' then 'expired'::public.match_status else 'cancelled' end
     where request_id = p_request and status = 'pending';
  end if;

  if r.requester_id is not null and r.requester_id <> _uid then
    perform public._notify(r.requester_id, 'request_status',
      'تحديث حالة الطلب ' || r.reference, 'Request ' || r.reference || ' updated',
      case p_status when 'verified' then 'تم التحقق من الطلب وسيُبحث عن متبرعين.'
                    when 'rejected' then 'تعذّر قبول الطلب: ' || coalesce(p_note, '')
                    when 'completed' then 'أُغلق الطلب كمكتمل.' else null end,
      case p_status when 'verified' then 'Your request was verified; matching donors will be contacted.'
                    when 'rejected' then 'Your request could not be accepted: ' || coalesce(p_note, '')
                    when 'completed' then 'The request was closed as completed.' else null end,
      '/requests/' || r.id, 'blood_request', r.id);
  end if;
end $$;

-- Lazy + scheduled expiry (also callable by pg_cron, see 0005)
create or replace function public.expire_overdue_requests()
returns integer language plpgsql security definer set search_path = public as $$
declare _n integer := 0; r record;
begin
  for r in select id, reference, requester_id from public.blood_requests
            where expires_at < now() and status not in ('completed', 'rejected', 'cancelled', 'expired')
            for update skip locked loop
    update public.blood_requests set status = 'expired', closed_at = now() where id = r.id;
    update public.donor_matches set status = 'expired' where request_id = r.id and status = 'pending';
    perform public._notify(r.requester_id, 'request_expired', 'انتهت صلاحية الطلب ' || r.reference,
      'Request ' || r.reference || ' expired', 'يمكنك إنشاء طلب جديد إن كانت الحاجة قائمة.',
      'You can create a new request if blood is still needed.', '/requests/' || r.id, 'blood_request', r.id);
    _n := _n + 1;
  end loop;
  return _n;
end $$;

-- ---------------------------------------------------------------------
-- Matching
-- ---------------------------------------------------------------------
create or replace function public.run_auto_matching(p_request uuid, p_limit integer default null)
returns integer language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); r public.blood_requests; _n integer; _cap integer;
begin
  if not exists (select 1 from public.blood_requests where id = p_request) then raise exception 'not_found'; end if;
  if not public.can_review_request(p_request) then raise exception 'not_authorized'; end if;
  select * into r from public.blood_requests where id = p_request for update;
  if r.status not in ('verified', 'matching_donors', 'donors_responding') then raise exception 'invalid_transition'; end if;
  _cap := least(coalesce(p_limit, public._setting('matching', 'batch_size', 25)::int), 100);

  with candidates as (
    select d.user_id
      from public.donor_profiles d
      join public.profiles p on p.id = d.user_id and p.account_status = 'active'
     where d.country_code = r.country_code          -- country separation
       and d.city_id = r.city_id                    -- same city
       and d.blood_group = r.blood_group            -- declared group, preliminary only
       and d.accepts_auto_matching
       and public._donor_is_available(d)
       and d.user_id is distinct from r.requester_id
       and not public.is_blocked_between(d.user_id, r.requester_id)
       and not exists (select 1 from public.donor_matches m where m.request_id = r.id and m.donor_id = d.user_id)
     order by d.is_verified desc, random()
     limit _cap
  ), ins as (
    insert into public.donor_matches (request_id, donor_id, method, matched_by)
    select r.id, c.user_id, 'automated', _uid from candidates c
    returning donor_id
  )
  insert into public.notifications (user_id, type, title_ar, title_en, body_ar, body_en, link, entity_type, entity_id)
  select ins.donor_id, 'match_request',
         'طلب تبرع بفصيلة ' || r.blood_group::text || ' في ' || public._city_label(r.city_id, 'ar'),
         'Donation request for ' || r.blood_group::text || ' in ' || public._city_label(r.city_id, 'en'),
         r.hospital_name || ' — هل تستطيع المساعدة؟ الأهلية النهائية يحددها بنك الدم.',
         r.hospital_name || ' — can you help? Final eligibility is decided by the blood bank.',
         '/activity', 'blood_request', r.id
    from ins;
  get diagnostics _n = row_count;

  if r.status = 'verified' then
    update public.blood_requests set status = 'matching_donors' where id = r.id;
  end if;
  perform public._notify(r.requester_id, 'matching_started',
    'بدأ البحث عن متبرعين للطلب ' || r.reference, 'Donor matching started for ' || r.reference,
    'تم إشعار ' || _n || ' متبرعاً محتملاً.', _n || ' potential donors were notified.',
    '/requests/' || r.id, 'blood_request', r.id);
  return _n;
end $$;

-- Manual: requester (own verified request, same blood group), institution staff or admin.
create or replace function public.send_manual_match(p_request uuid, p_donor uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); r public.blood_requests; d public.donor_profiles; _id uuid; _reviewer boolean;
begin
  select * into r from public.blood_requests where id = p_request for update;
  if not found then raise exception 'not_found'; end if;
  _reviewer := public.can_review_request(p_request);
  if not (_reviewer or r.requester_id = _uid) then raise exception 'not_authorized'; end if;
  if r.status not in ('verified', 'matching_donors', 'donors_responding') then raise exception 'invalid_transition'; end if;

  select * into d from public.donor_profiles where user_id = p_donor;
  if not found or not exists (select 1 from public.profiles where id = p_donor and account_status = 'active') then
    raise exception 'not_found';
  end if;
  if d.country_code <> r.country_code then raise exception 'country_mismatch'; end if;
  if not public._donor_is_available(d) then raise exception 'invalid_input'; end if;
  if not _reviewer and d.blood_group <> r.blood_group then raise exception 'invalid_input'; end if;
  if d.user_id = r.requester_id then raise exception 'invalid_input'; end if;
  if public.is_blocked_between(d.user_id, r.requester_id) then raise exception 'blocked'; end if;
  if not _reviewer then
    perform public._rate_limit('manual_match', 20, interval '24 hours');
  end if;

  insert into public.donor_matches (request_id, donor_id, method, matched_by)
  values (r.id, d.user_id, 'manual', _uid)
  on conflict (request_id, donor_id) do nothing
  returning id into _id;
  if _id is null then raise exception 'invalid_input'; end if;

  perform public._notify(d.user_id, 'match_request',
    'طلب تبرع بفصيلة ' || r.blood_group::text || ' في ' || public._city_label(r.city_id, 'ar'),
    'Donation request for ' || r.blood_group::text || ' in ' || public._city_label(r.city_id, 'en'),
    r.hospital_name || ' — الأهلية النهائية يحددها بنك الدم.', r.hospital_name || ' — final eligibility is decided by the blood bank.',
    '/activity', 'blood_request', r.id);
  if r.status = 'verified' then
    update public.blood_requests set status = 'matching_donors' where id = r.id;
  end if;
  return _id;
end $$;

-- Donor's inbox: their matches with a reduced view of each request.
create or replace function public.my_donation_requests()
returns table (
  match_id uuid, match_status public.match_status, method public.match_method, matched_at timestamptz,
  donor_contact_consent boolean, requester_contact_consent boolean, contact_shared_at timestamptz,
  appointment_at timestamptz, appointment_note text,
  request_id uuid, reference text, blood_group public.blood_group, units smallint, city_ar text, city_en text,
  hospital_name text, urgency public.urgency_level, required_by timestamptz, request_status public.request_status,
  donation_status public.donation_status, is_demo boolean
) language sql stable security definer set search_path = public as $$
  select m.id, m.status, m.method, m.created_at, m.donor_contact_consent, m.requester_contact_consent, m.contact_shared_at,
         m.appointment_at, m.appointment_note,
         r.id, r.reference, r.blood_group, r.units, c.name_ar, c.name_en, r.hospital_name, r.urgency, r.required_by, r.status,
         dr.status, r.is_demo
    from public.donor_matches m
    join public.blood_requests r on r.id = m.request_id
    join public.cities c on c.id = r.city_id
    left join public.donation_records dr on dr.match_id = m.id
   where m.donor_id = auth.uid()
   order by (m.status = 'pending') desc, m.created_at desc
   limit 100;
$$;

-- Requester / reviewer view of the donors matched to one request (aliases only).
create or replace function public.request_matches(p_request uuid)
returns table (
  match_id uuid, donor_alias text, blood_group public.blood_group, is_verified boolean,
  status public.match_status, method public.match_method, responded_at timestamptz,
  donor_contact_consent boolean, requester_contact_consent boolean, contact_shared_at timestamptz,
  appointment_at timestamptz, appointment_note text, donation_id uuid, donation_status public.donation_status
) language plpgsql stable security definer set search_path = public as $$
begin
  if not exists (select 1 from public.blood_requests r where r.id = p_request
                 and (r.requester_id = auth.uid() or public.can_review_request(r.id))) then
    raise exception 'not_authorized';
  end if;
  return query
  select m.id, d.public_alias, d.blood_group, d.is_verified, m.status, m.method, m.responded_at,
         m.donor_contact_consent, m.requester_contact_consent, m.contact_shared_at, m.appointment_at, m.appointment_note,
         dr.id, dr.status
    from public.donor_matches m
    join public.donor_profiles d on d.user_id = m.donor_id
    left join public.donation_records dr on dr.match_id = m.id
   where m.request_id = p_request
   order by case m.status when 'accepted' then 0 when 'pending' then 1 else 2 end, m.created_at;
end $$;

create or replace function public.respond_to_match(p_match uuid, p_accept boolean, p_reason text default null, p_share_contact boolean default false)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); m public.donor_matches; r public.blood_requests;
begin
  select * into m from public.donor_matches where id = p_match for update;
  if not found or m.donor_id <> _uid then raise exception 'not_authorized'; end if;
  select * into r from public.blood_requests where id = m.request_id for update;
  if r.status not in ('verified', 'matching_donors', 'donors_responding', 'donation_arranged') then
    raise exception 'invalid_transition';
  end if;
  if m.status not in ('pending', 'accepted') or (m.status = 'accepted' and p_accept) then
    raise exception 'invalid_transition';
  end if;

  update public.donor_matches set
    status = case when p_accept then 'accepted'::public.match_status
                  when m.status = 'accepted' then 'withdrawn' else 'declined' end,
    responded_at = now(),
    donor_contact_consent = p_accept and coalesce(p_share_contact, false),
    contact_shared_at = null
  where id = p_match;

  insert into public.donor_responses (match_id, donor_id, response, reason)
  values (p_match, _uid, case when p_accept then 'accepted' when m.status = 'accepted' then 'withdrawn' else 'declined' end,
          nullif(btrim(p_reason), ''));

  if p_accept and coalesce(p_share_contact, false) then
    perform public._record_consent('contact_sharing', true, jsonb_build_object('match', p_match));
  end if;

  if p_accept and r.status = 'matching_donors' then
    update public.blood_requests set status = 'donors_responding' where id = r.id;
  end if;

  perform public._notify(r.requester_id, case when p_accept then 'donor_accepted' else 'donor_declined' end,
    case when p_accept then 'متبرع وافق على طلبك ' || r.reference else 'تحديث على الطلب ' || r.reference end,
    case when p_accept then 'A donor accepted your request ' || r.reference else 'Update on request ' || r.reference end,
    case when p_accept then 'يمكنك الآن طلب تبادل وسيلة التواصل.' else null end,
    case when p_accept then 'You can now ask to exchange contact details.' else null end,
    '/requests/' || r.id, 'blood_request', r.id);
end $$;

-- Either party grants (or withdraws) consent to share contact details for one match.
create or replace function public.set_contact_consent(p_match uuid, p_consent boolean)
returns boolean language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); m public.donor_matches; r public.blood_requests; _shared boolean;
begin
  select * into m from public.donor_matches where id = p_match for update;
  if not found then raise exception 'not_found'; end if;
  select * into r from public.blood_requests where id = m.request_id;
  if _uid not in (m.donor_id, coalesce(r.requester_id, '00000000-0000-0000-0000-000000000000'::uuid)) then
    raise exception 'not_authorized';
  end if;
  if m.status <> 'accepted' then raise exception 'invalid_transition'; end if;
  if public.is_blocked_between(m.donor_id, r.requester_id) then raise exception 'blocked'; end if;

  if _uid = m.donor_id then
    update public.donor_matches set donor_contact_consent = p_consent where id = p_match;
  else
    update public.donor_matches set requester_contact_consent = p_consent where id = p_match;
  end if;
  perform public._record_consent('contact_sharing', p_consent, jsonb_build_object('match', p_match));

  select donor_contact_consent and requester_contact_consent into _shared from public.donor_matches where id = p_match;
  update public.donor_matches set contact_shared_at = case when _shared then coalesce(contact_shared_at, now()) else null end
   where id = p_match;

  if p_consent then
    perform public._notify(case when _uid = m.donor_id then r.requester_id else m.donor_id end,
      case when _shared then 'contact_shared' else 'contact_requested' end,
      case when _shared then 'تم تبادل وسائل التواصل' else 'طلب تبادل وسيلة التواصل' end,
      case when _shared then 'Contact details exchanged' else 'Contact exchange requested' end,
      case when _shared then 'الطلب ' || r.reference else 'وافق عليه لتظهر وسيلة التواصل للطرفين — الطلب ' || r.reference end,
      case when _shared then 'Request ' || r.reference else 'Approve it to reveal contact details to both sides — request ' || r.reference end,
      case when _uid = m.donor_id then '/requests/' || r.id else '/activity' end, 'donor_match', p_match);
  end if;
  return coalesce(_shared, false);
end $$;

-- Reveal the other party's contact — only after mutual consent. Every reveal is audited.
create or replace function public.get_match_contact(p_match uuid)
returns table (name text, phone text, contact_method public.contact_method)
language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); m public.donor_matches; r public.blood_requests; _other uuid;
begin
  select * into m from public.donor_matches where id = p_match;
  if not found or m.contact_shared_at is null or m.status <> 'accepted' then raise exception 'not_authorized'; end if;
  select * into r from public.blood_requests where id = m.request_id;
  if not public._request_contact_open(r.status, r.closed_at) then raise exception 'invalid_transition'; end if;
  if _uid = m.donor_id then _other := r.requester_id;
  elsif _uid = r.requester_id then _other := m.donor_id;
  else raise exception 'not_authorized'; end if;
  if public.is_blocked_between(_uid, _other) then raise exception 'blocked'; end if;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, new_data)
  values (_uid, 'contact_revealed', 'donor_matches', p_match, jsonb_build_object('other_party', _other));

  return query
  select p.full_name, p.phone,
         coalesce((select d.contact_method from public.donor_profiles d where d.user_id = _other), 'phone_call'::public.contact_method)
    from public.profiles p where p.id = _other and p.account_status = 'active';
end $$;

create or replace function public.schedule_appointment(p_match uuid, p_at timestamptz, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); m public.donor_matches; r public.blood_requests;
begin
  select * into m from public.donor_matches where id = p_match for update;
  if not found then raise exception 'not_found'; end if;
  select * into r from public.blood_requests where id = m.request_id for update;
  if not (r.requester_id = _uid or public.can_review_request(r.id)) then raise exception 'not_authorized'; end if;
  if m.status <> 'accepted' then raise exception 'invalid_transition'; end if;
  if p_at < now() - interval '1 hour' or p_at > now() + interval '30 days' then raise exception 'invalid_input'; end if;

  update public.donor_matches set appointment_at = p_at, appointment_note = nullif(btrim(p_note), '') where id = p_match;
  if r.status in ('matching_donors', 'donors_responding') then
    update public.blood_requests set status = 'donation_arranged' where id = r.id;
  end if;
  perform public._notify(m.donor_id, 'appointment',
    'موعد التبرع: ' || to_char(p_at at time zone case r.country_code when 'SD' then 'Africa/Khartoum' else 'Asia/Riyadh' end, 'YYYY-MM-DD HH24:MI'),
    'Donation appointment: ' || to_char(p_at at time zone case r.country_code when 'SD' then 'Africa/Khartoum' else 'Asia/Riyadh' end, 'YYYY-MM-DD HH24:MI'),
    r.hospital_name || ' — الفحص والتوافق يجريهما بنك الدم.', r.hospital_name || ' — screening and crossmatch are done by the blood bank.',
    '/activity', 'donor_match', p_match);
end $$;

-- ---------------------------------------------------------------------
-- Donation records. Self-reports stay "pending_confirmation" until an
-- institution member or admin confirms them.
-- ---------------------------------------------------------------------
create or replace function public.record_donation(p_match uuid, p_donated_on date, p_units integer default 1, p_notes text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); m public.donor_matches; r public.blood_requests; _reviewer boolean; _id uuid;
begin
  select * into m from public.donor_matches where id = p_match for update;
  if not found then raise exception 'not_found'; end if;
  select * into r from public.blood_requests where id = m.request_id;
  _reviewer := public.can_review_request(r.id);
  if not (_reviewer or _uid = m.donor_id or _uid = r.requester_id) then raise exception 'not_authorized'; end if;
  if m.status <> 'accepted' then raise exception 'invalid_transition'; end if;
  if p_donated_on > current_date or p_donated_on < current_date - 60 then raise exception 'invalid_input'; end if;

  insert into public.donation_records (request_id, match_id, donor_id, institution_id, status, donated_on, units, notes,
                                       recorded_by, confirmed_by, confirmed_at)
  values (r.id, m.id, m.donor_id, r.institution_id,
          case when _reviewer then 'confirmed'::public.donation_status else 'pending_confirmation' end,
          p_donated_on, coalesce(p_units, 1), nullif(btrim(p_notes), ''), _uid,
          case when _reviewer then _uid end, case when _reviewer then now() end)
  on conflict (match_id) do nothing
  returning id into _id;
  if _id is null then raise exception 'invalid_input'; end if;

  if _reviewer then
    perform public._after_donation_confirmed(_id);
  else
    insert into public.notifications (user_id, type, title_ar, title_en, link, entity_type, entity_id)
    select m2.user_id, 'donation_needs_confirmation', 'تبرع بانتظار التأكيد ' || r.reference,
           'Donation awaiting confirmation ' || r.reference, '/admin/donations', 'donation_record', _id
      from public.institution_members m2 where m2.institution_id = r.institution_id and m2.is_active;
  end if;
  return _id;
end $$;

create or replace function public._after_donation_confirmed(_record uuid)
returns void language plpgsql security definer set search_path = public as $$
declare d public.donation_records; _ref text;
begin
  select * into d from public.donation_records where id = _record;
  update public.donor_profiles set is_verified = true,
         last_donation_date = greatest(coalesce(last_donation_date, d.donated_on), d.donated_on)
   where user_id = d.donor_id;
  select reference into _ref from public.blood_requests where id = d.request_id;
  perform public._notify(d.donor_id, 'donation_confirmed', 'تم تأكيد تبرعك — شكراً لفزعتك',
    'Your donation was confirmed — thank you', 'الطلب ' || coalesce(_ref, ''), 'Request ' || coalesce(_ref, ''),
    '/activity', 'donation_record', _record);
end $$;

create or replace function public.confirm_donation(p_record uuid, p_confirm boolean, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); d public.donation_records;
begin
  select * into d from public.donation_records where id = p_record for update;
  if not found then raise exception 'not_found'; end if;
  if not (public.is_admin() or public.is_institution_member(d.institution_id)) then raise exception 'not_authorized'; end if;
  if d.status <> 'pending_confirmation' then raise exception 'invalid_transition'; end if;
  update public.donation_records set
    status = case when p_confirm then 'confirmed'::public.donation_status else 'not_completed' end,
    confirmed_by = case when p_confirm then _uid end,
    confirmed_at = case when p_confirm then now() end,
    notes = coalesce(nullif(btrim(p_note), ''), notes)
  where id = p_record;
  if p_confirm then perform public._after_donation_confirmed(p_record); end if;
end $$;

-- ---------------------------------------------------------------------
-- Administration
-- ---------------------------------------------------------------------
create or replace function public._require_admin()
returns uuid language plpgsql stable security definer set search_path = public as $$
declare _uid uuid := public._require_user();
begin
  if not public.is_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  return _uid;
end $$;

create or replace function public.review_institution(p_id uuid, p_approve boolean, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin(); i public.institutions;
begin
  update public.institutions set status = case when p_approve then 'approved'::public.approval_status else 'rejected' end,
         review_note = nullif(btrim(p_note), ''), reviewed_by = _uid, reviewed_at = now()
   where id = p_id returning * into i;
  if not found then raise exception 'not_found'; end if;
  if p_approve and i.created_by is not null then
    insert into public.institution_members (institution_id, user_id, title) values (i.id, i.created_by, 'owner')
    on conflict (institution_id, user_id) do update set is_active = true;
    insert into public.user_roles (user_id, role, granted_by) values (i.created_by, 'institution_staff', _uid) on conflict do nothing;
  end if;
  perform public._notify(i.created_by, 'institution_review',
    case when p_approve then 'تم اعتماد المنشأة ' || i.name_ar else 'لم يتم اعتماد المنشأة ' || i.name_ar end,
    case when p_approve then 'Institution approved: ' || coalesce(i.name_en, i.name_ar) else 'Institution not approved: ' || coalesce(i.name_en, i.name_ar) end,
    p_note, p_note, '/institution', 'institution', i.id);
end $$;

create or replace function public.set_institution_member(p_institution uuid, p_user uuid, p_active boolean, p_title text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin();
begin
  insert into public.institution_members (institution_id, user_id, title, is_active)
  values (p_institution, p_user, p_title, p_active)
  on conflict (institution_id, user_id) do update set is_active = excluded.is_active, title = coalesce(excluded.title, institution_members.title);
  if p_active then
    insert into public.user_roles (user_id, role, granted_by) values (p_user, 'institution_staff', _uid) on conflict do nothing;
  end if;
end $$;

create or replace function public.review_initiative(p_id uuid, p_status public.initiative_status, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin(); i public.humanitarian_initiatives;
begin
  if p_status not in ('under_review', 'approved', 'rejected', 'completed', 'archived') then raise exception 'invalid_input'; end if;
  if p_status = 'rejected' and coalesce(btrim(p_note), '') = '' then raise exception 'invalid_input'; end if;
  select * into i from public.humanitarian_initiatives where id = p_id for update;
  if not found then raise exception 'not_found'; end if;
  if p_status = 'approved' and i.status not in ('submitted', 'under_review') then raise exception 'invalid_transition'; end if;
  if p_status = 'completed' and i.status <> 'approved' then raise exception 'invalid_transition'; end if;

  update public.humanitarian_initiatives set status = p_status,
         review_note = coalesce(nullif(btrim(p_note), ''), review_note), reviewed_by = _uid, reviewed_at = now(),
         published_at = case when p_status = 'approved' then coalesce(published_at, now()) else published_at end
   where id = p_id;
  if p_status = 'approved' then
    insert into public.user_roles (user_id, role, granted_by) values (i.organizer_id, 'organizer', _uid) on conflict do nothing;
  end if;
  perform public._notify(i.organizer_id, 'initiative_review',
    case p_status when 'approved' then 'تم اعتماد مبادرتك ونشرها' when 'rejected' then 'لم يتم اعتماد مبادرتك' else 'تحديث على مبادرتك' end,
    case p_status when 'approved' then 'Your initiative was approved and published' when 'rejected' then 'Your initiative was not approved' else 'Update on your initiative' end,
    p_note, p_note, '/initiatives/' || i.id, 'initiative', i.id);
end $$;

create or replace function public.review_sponsor(p_id uuid, p_approve boolean, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin();
begin
  update public.sponsors set status = case when p_approve then 'approved'::public.approval_status else 'rejected' end,
         review_note = nullif(btrim(p_note), ''), reviewed_by = _uid, reviewed_at = now()
   where id = p_id;
  if not found then raise exception 'not_found'; end if;
end $$;

create or replace function public.admin_set_account_status(p_user uuid, p_status public.account_status, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin();
begin
  if p_user = _uid then raise exception 'invalid_input'; end if;
  update public.profiles set account_status = p_status, status_note = nullif(btrim(p_note), '') where id = p_user;
  if not found then raise exception 'not_found'; end if;
  if p_status <> 'active' then
    update public.donor_matches set status = 'withdrawn' where donor_id = p_user and status = 'pending';
  end if;
end $$;

create or replace function public.admin_set_role(p_user uuid, p_role public.app_role, p_grant boolean)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin();
begin
  if p_user = _uid and p_role = 'admin' and not p_grant then raise exception 'invalid_input'; end if;
  if p_grant then
    insert into public.user_roles (user_id, role, granted_by) values (p_user, p_role, _uid) on conflict do nothing;
  else
    delete from public.user_roles where user_id = p_user and role = p_role;
  end if;
end $$;

create or replace function public.resolve_report(p_id uuid, p_status public.report_status, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin();
begin
  update public.reports set status = p_status, resolved_by = _uid, resolution_note = nullif(btrim(p_note), '') where id = p_id;
  if not found then raise exception 'not_found'; end if;
end $$;

create or replace function public.admin_broadcast(p_country char(2), p_title_ar text, p_title_en text, p_body_ar text, p_body_en text, p_link text default null)
returns integer language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_admin(); _n integer;
begin
  insert into public.notifications (user_id, type, title_ar, title_en, body_ar, body_en, link)
  select p.id, 'announcement', p_title_ar, p_title_en, p_body_ar, p_body_en, p_link
    from public.profiles p where p.account_status = 'active' and (p_country is null or p.country_code = p_country);
  get diagnostics _n = row_count;
  insert into public.audit_logs (actor_id, action, entity_type, new_data)
  values (_uid, 'broadcast', 'notifications', jsonb_build_object('country', p_country, 'recipients', _n, 'title_en', p_title_en));
  return _n;
end $$;

-- Filtered statistics for the dashboard. Demo rows are included only if asked.
create or replace function public.admin_stats(
  p_country char(2) default null, p_city uuid default null, p_from date default null, p_to date default null,
  p_include_demo boolean default false
) returns jsonb language plpgsql stable security definer set search_path = public as $$
declare _uid uuid := public._require_admin(); _from timestamptz; _to timestamptz;
begin
  _from := coalesce(p_from, '2000-01-01')::timestamptz;
  _to := (coalesce(p_to, current_date) + 1)::timestamptz;
  return jsonb_build_object(
    'total_users', (select count(*) from public.profiles p where p.account_status <> 'deleted'
                    and (p_include_demo or not p.is_demo) and (p_country is null or p.country_code = p_country)
                    and (p_city is null or p.city_id = p_city) and p.created_at >= _from and p.created_at < _to),
    'active_donors', (select count(*) from public.donor_profiles d join public.profiles p on p.id = d.user_id
                    where p.account_status = 'active' and (p_include_demo or not p.is_demo)
                    and (p_country is null or d.country_code = p_country) and (p_city is null or d.city_id = p_city)),
    'available_donors', (select count(*) from public.donor_profiles d join public.profiles p on p.id = d.user_id
                    where p.account_status = 'active' and (p_include_demo or not p.is_demo) and public._donor_is_available(d)
                    and (p_country is null or d.country_code = p_country) and (p_city is null or d.city_id = p_city)),
    'requests', (select jsonb_build_object(
                    'total', count(*),
                    'verified', count(*) filter (where r.verified_at is not null),
                    'completed', count(*) filter (where r.status = 'completed'),
                    'unfulfilled', count(*) filter (where r.status in ('expired', 'cancelled')),
                    'open', count(*) filter (where r.status not in ('completed', 'rejected', 'cancelled', 'expired')),
                    'pending_review', count(*) filter (where r.status in ('submitted', 'under_review')))
                  from public.blood_requests r
                  where (p_include_demo or not r.is_demo) and (p_country is null or r.country_code = p_country)
                    and (p_city is null or r.city_id = p_city) and r.created_at >= _from and r.created_at < _to),
    'confirmed_donations', (select count(*) from public.donation_records dr join public.blood_requests r on r.id = dr.request_id
                    where dr.status = 'confirmed' and (p_include_demo or not dr.is_demo)
                    and (p_country is null or r.country_code = p_country) and (p_city is null or r.city_id = p_city)
                    and dr.donated_on >= _from::date and dr.donated_on < _to::date),
    'requests_by_city', (select coalesce(jsonb_agg(x order by x.total desc), '[]') from (
                    select c.name_ar, c.name_en, r.country_code, count(*) total
                      from public.blood_requests r join public.cities c on c.id = r.city_id
                     where (p_include_demo or not r.is_demo) and (p_country is null or r.country_code = p_country)
                       and (p_city is null or r.city_id = p_city) and r.created_at >= _from and r.created_at < _to
                     group by 1, 2, 3) x),
    'requests_by_country', (select coalesce(jsonb_object_agg(country_code, n), '{}') from (
                    select r.country_code, count(*) n from public.blood_requests r
                     where (p_include_demo or not r.is_demo) and r.created_at >= _from and r.created_at < _to
                       and (p_city is null or r.city_id = p_city)
                     group by 1) x),
    'blood_group_distribution', (select coalesce(jsonb_object_agg(bg, jsonb_build_object('donors', donors, 'requests', requests)), '{}') from (
                    select g.bg::text bg,
                      (select count(*) from public.donor_profiles d join public.profiles p on p.id = d.user_id
                        where d.blood_group = g.bg and p.account_status = 'active' and (p_include_demo or not p.is_demo)
                          and (p_country is null or d.country_code = p_country) and (p_city is null or d.city_id = p_city)) donors,
                      (select count(*) from public.blood_requests r where r.blood_group = g.bg and (p_include_demo or not r.is_demo)
                          and (p_country is null or r.country_code = p_country) and (p_city is null or r.city_id = p_city)
                          and r.created_at >= _from and r.created_at < _to) requests
                    from unnest(enum_range(null::public.blood_group)) g(bg)) x),
    'initiatives', (select jsonb_build_object(
                    'pending', count(*) filter (where i.status in ('submitted', 'under_review')),
                    'approved', count(*) filter (where i.status = 'approved'),
                    'completed', count(*) filter (where i.status = 'completed'),
                    'rejected', count(*) filter (where i.status = 'rejected'))
                  from public.humanitarian_initiatives i
                  where (p_include_demo or not i.is_demo) and (p_country is null or i.country_code = p_country)),
    'institutions', (select jsonb_build_object(
                    'approved_hospitals', count(*) filter (where i.status = 'approved' and i.type = 'hospital'),
                    'approved_blood_banks', count(*) filter (where i.status = 'approved' and i.type = 'blood_bank'),
                    'pending', count(*) filter (where i.status = 'pending'))
                  from public.institutions i
                  where (p_include_demo or not i.is_demo) and (p_country is null or i.country_code = p_country)),
    'open_reports', (select count(*) from public.reports where status in ('open', 'reviewing'))
  );
end $$;

create or replace function public.admin_find_user(p_query text)
returns table (id uuid, full_name text, phone text, country_code char(2), account_status public.account_status, roles public.app_role[])
language plpgsql stable security definer set search_path = public as $$
declare _uid uuid := public._require_admin(); _q text := btrim(coalesce(p_query, ''));
begin
  if length(_q) < 3 then raise exception 'invalid_input'; end if;
  return query
  select p.id, p.full_name, p.phone, p.country_code, p.account_status,
         array(select r.role from public.user_roles r where r.user_id = p.id order by r.role)
    from public.profiles p
   where p.phone like '%' || regexp_replace(_q, '[^0-9]', '', 'g') || '%' and regexp_replace(_q, '[^0-9]', '', 'g') <> ''
      or p.full_name ilike '%' || _q || '%'
      or p.id::text = _q
   order by p.created_at desc
   limit 25;
end $$;

-- Block the other party of a match without ever revealing who they are.
create or replace function public.block_match_party(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); m public.donor_matches; r public.blood_requests; _other uuid;
begin
  select * into m from public.donor_matches where id = p_match;
  if not found then raise exception 'not_found'; end if;
  select * into r from public.blood_requests where id = m.request_id;
  if _uid = m.donor_id then _other := r.requester_id;
  elsif _uid = r.requester_id then _other := m.donor_id;
  else raise exception 'not_authorized'; end if;
  if _other is null then raise exception 'not_found'; end if;
  insert into public.user_blocks (blocker_id, blocked_id) values (_uid, _other) on conflict do nothing;
  update public.donor_matches set donor_contact_consent = false, requester_contact_consent = false, contact_shared_at = null
   where id = p_match;
end $$;

-- Report the other party of a match (target stored server-side, never shown to the reporter).
create or replace function public.report_match_party(p_match uuid, p_reason text, p_details text default null)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); m public.donor_matches; r public.blood_requests; _other uuid;
begin
  select * into m from public.donor_matches where id = p_match;
  if not found then raise exception 'not_found'; end if;
  select * into r from public.blood_requests where id = m.request_id;
  if _uid = m.donor_id then _other := r.requester_id;
  elsif _uid = r.requester_id then _other := m.donor_id;
  else raise exception 'not_authorized'; end if;
  perform public._rate_limit('report', 10, interval '24 hours');
  insert into public.reports (reporter_id, target_type, target_id, reason, details)
  values (_uid, 'user', coalesce(_other, m.id), p_reason, nullif(btrim(p_details), ''));
end $$;

-- ---------------------------------------------------------------------
-- Account
-- ---------------------------------------------------------------------
create or replace function public.mark_all_notifications_read()
returns void language sql security definer set search_path = public as $$
  update public.notifications set read_at = now() where user_id = auth.uid() and read_at is null;
$$;

-- Anonymises the account. The auth user itself is deleted by the server
-- (service role) right after this call; history needed for audit is kept
-- without personal data.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := auth.uid();
begin
  if _uid is null then raise exception 'not_authenticated'; end if;
  update public.blood_requests set status = 'cancelled', closed_at = now()
   where requester_id = _uid and status not in ('completed', 'rejected', 'cancelled', 'expired');
  update public.donor_matches set status = 'withdrawn' where donor_id = _uid and status in ('pending', 'accepted');
  delete from public.donor_profiles where user_id = _uid;
  delete from public.push_subscriptions where user_id = _uid;
  delete from public.user_blocks where blocker_id = _uid;
  update public.profiles set full_name = null, phone = null, email = null, account_status = 'deleted', deleted_at = now()
   where id = _uid;
  insert into public.audit_logs (actor_id, action, entity_type, entity_id) values (_uid, 'account_deleted', 'profiles', _uid);
end $$;

-- ---------------------------------------------------------------------
-- Privileges: functions are callable by signed-in users unless noted.
-- ---------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
-- internals are not part of the API
revoke execute on function public._rate_limit(text, integer, interval), public._notify(uuid, text, text, text, text, text, text, text, uuid),
  public._record_consent(public.consent_type, boolean, jsonb), public._after_donation_confirmed(uuid),
  public.expire_overdue_requests(), public.handle_new_user(), public.handle_user_phone_change()
  from authenticated;
revoke execute on function public._require_user(), public._require_admin(), public._code(integer),
  public._setting(text, text, numeric), public._city_label(uuid, text),
  public._allowed_transition(public.request_status, public.request_status),
  public.tg_set_updated_at(), public.tg_audit(), public.tg_guard_notification()
  from authenticated;
-- anonymous visitors may read the public, anonymised feeds
grant execute on function public.public_emergency_requests(char, integer), public.public_stats(char),
  public._donor_is_available(public.donor_profiles), public.is_admin(), public.has_role(public.app_role),
  public.is_active_user(), public.my_institution_ids(), public.is_institution_member(uuid),
  public.initiative_visible(uuid)
  to anon;
