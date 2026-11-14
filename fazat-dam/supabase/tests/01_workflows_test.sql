-- =====================================================================
-- End-to-end security & workflow tests. Run against a database with the
-- stub (00) + migrations 0001-0004 applied:  ./supabase/tests/run.sh
-- Every check raises on failure, so a clean run means all passed.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

create schema if not exists t;
grant usage on schema t to authenticated, anon;

create or replace function t.act(_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(_uid::text, ''), false);
  if _uid is null then execute 'set role anon'; else execute 'set role authenticated'; end if;
end $$;
create or replace function t.root() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claim.sub', '', false);
end $$;
create or replace function t.ok(_cond boolean, _msg text) returns void language plpgsql as $$
begin
  if not coalesce(_cond, false) then raise exception 'FAILED: %', _msg; end if;
  raise notice 'ok - %', _msg;
end $$;
-- run a statement as a user and assert that it fails with the given code
create or replace function t.fails(_uid uuid, _sql text, _code text, _msg text) returns void language plpgsql as $$
declare _err text;
begin
  perform t.act(_uid);
  begin
    execute _sql;
    _err := null;
  exception when others then _err := sqlerrm;
  end;
  perform t.root();
  if _err is null or position(_code in _err) = 0 then
    raise exception 'FAILED: % (expected "%", got "%")', _msg, _code, coalesce(_err, 'no error');
  end if;
  raise notice 'ok - %', _msg;
end $$;
grant execute on all functions in schema t to authenticated, anon;

set client_min_messages = notice;

do $$
declare
  riyadh uuid := (select id from public.cities where name_en = 'Riyadh');
  jeddah uuid := (select id from public.cities where name_en = 'Jeddah');
  khartoum uuid := (select id from public.cities where name_en = 'Khartoum');
  admin uuid; staff uuid; requester uuid; d1 uuid; d2 uuid; d3 uuid; dsd uuid; outsider uuid; organizer uuid;
  inst uuid; req uuid; ref text; n integer; m1 uuid; rec uuid; init uuid; x record; s jsonb; cnt integer;
begin
  -- ---------- users (as the auth service would create them)
  insert into auth.users (phone) values ('966500000001') returning id into admin;
  insert into auth.users (phone) values ('966500000002') returning id into staff;
  insert into auth.users (phone) values ('966500000003') returning id into requester;
  insert into auth.users (phone) values ('966500000004') returning id into d1;
  insert into auth.users (phone) values ('966500000005') returning id into d2;
  insert into auth.users (phone) values ('966500000006') returning id into d3;
  insert into auth.users (phone) values ('249900000007') returning id into dsd;
  insert into auth.users (phone) values ('966500000008') returning id into outsider;
  insert into auth.users (phone, raw_user_meta_data) values ('249900000009', '{"lang":"en"}') returning id into organizer;
  perform t.ok((select count(*) from public.profiles) = 9, 'profiles are created for new auth users');
  perform t.ok((select preferred_language from public.profiles where id = organizer) = 'en', 'language from signup metadata');
  perform t.ok((select bool_and(role = 'requester') from public.user_roles), 'base role is requester');
  insert into public.user_roles (user_id, role) values (admin, 'admin');

  -- ---------- donors register (three in Riyadh, one in Khartoum)
  perform t.act(d1);
  perform public.register_donor('Ahmed Ali', 'SA', riyadh, 'O+', 'available', 'whatsapp', 'ar', true);
  perform t.act(d2);
  perform public.register_donor('Omer Hassan', 'SA', riyadh, 'O+', 'unavailable', 'phone_call', 'ar', true);
  perform t.act(d3);
  perform public.register_donor('Sara Musa', 'SA', riyadh, 'A+', 'available', 'in_app', 'en', true, p_show_first_name => true);
  perform t.act(dsd);
  perform public.register_donor('Khalid Osman', 'SD', khartoum, 'O+', 'available', 'phone_call', 'ar', true);
  perform t.root();
  perform t.ok((select count(*) from public.donor_profiles) = 4, 'four donor profiles');
  perform t.ok((select count(*) from public.user_roles where role = 'donor') = 4, 'donor role granted');
  perform t.fails(d1, $q$select public.register_donor('X', 'SA', '$q$ || khartoum || $q$', 'O+', 'available', 'in_app', 'ar', true)$q$,
    'invalid_input', 'city must belong to the selected country');
  perform t.fails(d1, 'update public.donor_profiles set suspended_until = current_date + 5000, availability = ''temporarily_suspended'' where user_id = auth.uid(); select 1/(select count(*) from public.donor_profiles where suspended_until is not null)',
    'division by zero', 'donors cannot bypass set_donor_availability with direct updates');
  perform t.fails(d1, 'select public.set_donor_availability(''temporarily_suspended'', current_date + 5000)', 'invalid_input', 'suspension longer than a year is rejected');
  perform t.fails(d1, $q$select public.register_donor('X', 'SA', '$q$ || riyadh || $q$', 'O+', 'available', 'in_app', 'ar', false)$q$,
    'consent_required', 'privacy consent is mandatory');

  -- ---------- privacy of profiles
  perform t.act(outsider);
  perform t.ok((select count(*) from public.profiles) = 1, 'a user sees only their own profile row');
  perform t.ok((select count(*) from public.donor_profiles) = 0, 'donor_profiles not directly readable by others');
  select count(*) into cnt from public.search_donors('SA', riyadh, 'O+', true);
  perform t.ok(cnt = 1, 'search: only available O+ donors in Riyadh (got ' || cnt || ')');
  select count(*) into cnt from public.search_donors('SA', riyadh, 'O+', false);
  perform t.ok(cnt = 2, 'search: unavailable donors appear when filter is off');
  select * into x from public.search_donors('SA', riyadh, 'A+', true) limit 1;
  perform t.ok(x.display_name like 'Sara · D-%', 'opt-in donors show first name + alias only');
  select * into x from public.search_donors('SA', riyadh, 'O+', true) limit 1;
  perform t.ok(x.display_name ~ '^D-[A-Z0-9]{5}$', 'default donors show alias only');
  select count(*) into cnt from public.search_donors('SD', null, 'O+', true);
  perform t.ok(cnt = 1, 'Sudan network is searched separately');
  perform t.root();
  perform t.fails(null, 'select public.search_donors(''SA'')', 'permission denied', 'anonymous visitors cannot search donors');
  perform t.fails(outsider, 'update public.profiles set account_status = ''suspended'' where id = auth.uid(); select 1/(case when (select account_status from public.profiles where id = auth.uid()) = ''active'' then 0 else 1 end)',
    'division by zero', 'users cannot change their own account status');

  -- ---------- institution registration & approval
  perform t.act(staff);
  insert into public.institutions (type, name_ar, name_en, country_code, city_id, status)
  values ('blood_bank', 'بنك الدم المركزي (تجريبي)', 'Central Blood Bank (test)', 'SA', riyadh, 'approved') returning id into inst;
  perform t.root();
  perform t.ok((select status from public.institutions where id = inst) = 'pending', 'self-registered institution forced to pending');
  perform t.fails(staff, format('select public.review_institution(%L, true)', inst), 'not_authorized', 'only admins approve institutions');
  perform t.act(admin);
  perform public.review_institution(inst, true, null);
  perform t.root();
  perform t.ok(exists (select 1 from public.user_roles where user_id = staff and role = 'institution_staff'), 'approval grants staff role');

  -- ---------- blood request
  perform t.act(requester);
  perform public.complete_onboarding('Requester Test', 'SA', riyadh, 'ar', true);
  select r.id, r.reference into req, ref from public.submit_blood_request('family', 'O+', 2, 'SA', riyadh, 'King Fahad Hospital (test)',
    now() + interval '2 days', 'urgent', true, 'A.M.', inst, null) r;
  perform t.root();
  perform t.ok(ref ~ '^FD-SA-[0-9]{4}-[A-Z0-9]{5}$', 'request reference format ' || ref);
  perform t.ok((select status from public.blood_requests where id = req) = 'submitted', 'new request is submitted');
  perform t.ok(exists (select 1 from public.notifications where user_id = staff and entity_id = req), 'institution staff notified for review');
  perform t.fails(requester, format($q$select public.submit_blood_request('self','O+',1,'SA','%s','H', now()+interval '1 day','normal', false)$q$, riyadh),
    'consent_required', 'declaration is mandatory');
  perform t.fails(requester, format($q$select public.submit_blood_request('self','O+',1,'SD','%s','H', now()+interval '1 day','normal', true, null, '%s')$q$, khartoum, inst),
    'country_mismatch', 'institution must be in the request country');

  perform t.act(outsider);
  perform t.ok((select count(*) from public.blood_requests) = 0, 'outsiders cannot read requests');
  perform t.ok((select count(*) from public.public_emergency_requests('SA')) = 0, 'unverified requests are not in the public feed');
  perform t.root();
  perform t.act(staff);
  perform t.ok((select count(*) from public.blood_requests) = 1, 'staff of the named institution can read the request');
  perform t.root();

  perform t.fails(requester, format('select public.transition_request(%L, ''verified'')', req), 'not_authorized', 'requesters cannot verify');
  perform t.fails(outsider, format('select public.run_auto_matching(%L)', req), 'not_authorized', 'outsiders cannot run matching');
  perform t.fails(staff, format('select public.run_auto_matching(%L)', req), 'invalid_transition', 'matching needs a verified request');
  perform t.fails(staff, format('select public.transition_request(%L, ''rejected'')', req), 'invalid_input', 'rejection requires a reason');
  perform t.fails(staff, format('select public.transition_request(%L, ''completed'')', req), 'invalid_transition', 'cannot jump from submitted to completed');

  perform t.act(staff);
  perform public.transition_request(req, 'under_review', null);
  perform public.transition_request(req, 'verified', 'Checked with ward');
  n := public.run_auto_matching(req, null);
  perform t.root();
  perform t.ok(n = 1, 'auto matching: same country + city + group + available only (got ' || n || ')');
  perform t.ok((select donor_id from public.donor_matches where request_id = req) = d1, 'the available Riyadh O+ donor is matched');
  perform t.ok((select status from public.blood_requests where id = req) = 'matching_donors', 'status -> matching_donors');
  perform t.act(outsider);
  perform t.ok((select count(*) from public.public_emergency_requests('SA')) = 1, 'verified request appears in public feed');
  perform t.ok((select count(*) from public.public_emergency_requests('SD')) = 0, 'and not in the Sudan feed');
  perform t.root();

  -- manual matching rules
  perform t.fails(requester, format('select public.send_manual_match(%L, %L)', req, dsd), 'country_mismatch', 'no cross-border matching (SA request, SD donor)');
  perform t.fails(requester, format('select public.send_manual_match(%L, %L)', req, d2), 'invalid_input', 'unavailable donors cannot be requested');
  perform t.fails(requester, format('select public.send_manual_match(%L, %L)', req, d3), 'invalid_input', 'requesters can only request the same blood group');
  perform t.fails(outsider, format('select public.send_manual_match(%L, %L)', req, d1), 'not_authorized', 'outsiders cannot send match requests');

  -- ---------- donor response & privacy-preserving contact
  select id into m1 from public.donor_matches where request_id = req and donor_id = d1;
  perform t.fails(d3, format('select public.respond_to_match(%L, true)', m1), 'not_authorized', 'only the matched donor can respond');
  perform t.act(d1);
  perform t.ok((select count(*) from public.my_donation_requests()) = 1, 'donor sees the request in their inbox');
  perform t.ok((select count(*) from public.blood_requests) = 0, 'but cannot read the full request row');
  perform public.respond_to_match(m1, true, null, false);
  perform t.root();
  perform t.ok((select status from public.blood_requests where id = req) = 'donors_responding', 'status -> donors_responding');
  perform t.fails(requester, format('select * from public.get_match_contact(%L)', m1), 'not_authorized', 'no contact before mutual consent');
  perform t.act(requester);
  perform t.ok(not public.set_contact_consent(m1, true), 'requester consent alone does not share contacts');
  perform t.ok((select count(*) from public.request_matches(req)) = 1, 'requester sees matched donor aliases');
  perform t.root();
  perform t.fails(requester, format('select * from public.get_match_contact(%L)', m1), 'not_authorized', 'still hidden after one-sided consent');
  perform t.fails(requester, format('insert into public.messages (match_id, sender_id, body) values (%L, auth.uid(), ''hi'')', m1),
    'row-level security', 'no messaging before mutual consent');
  perform t.act(d1);
  perform t.ok(public.set_contact_consent(m1, true), 'donor consent completes the exchange');
  perform t.root();
  perform t.act(requester);
  select * into x from public.get_match_contact(m1);
  perform t.ok(x.phone = '966500000004' and x.contact_method = 'whatsapp', 'requester sees donor phone after mutual consent');
  insert into public.messages (match_id, sender_id, body) values (m1, requester, 'Thank you!');
  perform t.root();
  perform t.ok(exists (select 1 from public.audit_logs where action = 'contact_revealed' and entity_id = m1), 'contact reveal is audited');
  perform t.ok(not exists (select 1 from public.audit_logs where new_data ? 'phone' or old_data ? 'phone'), 'audit log never stores phone numbers');
  perform t.fails(outsider, format('select * from public.get_match_contact(%L)', m1), 'not_authorized', 'third parties never see contacts');
  -- blocking stops contact (donor blocks via the match, never learning the requester id)
  perform t.act(d1);
  perform public.block_match_party(m1);
  perform public.report_match_party(m1, 'spam', 'test');
  perform t.root();
  perform t.ok(exists (select 1 from public.user_blocks where blocker_id = d1 and blocked_id = requester), 'block_match_party blocks the other side');
  perform t.ok(exists (select 1 from public.reports where reporter_id = d1 and target_id = requester), 'report_match_party records the other side');
  perform t.fails(requester, format('select * from public.get_match_contact(%L)', m1), 'not_authorized', 'a block hides contact again');
  delete from public.user_blocks;
  perform t.act(d1); perform public.set_contact_consent(m1, true); perform t.root();
  perform t.act(requester); perform public.set_contact_consent(m1, true); perform t.root();

  -- ---------- appointment & donation confirmation
  perform t.act(requester);
  perform public.schedule_appointment(m1, now() + interval '1 day', 'Bring ID');
  perform t.root();
  perform t.ok((select status from public.blood_requests where id = req) = 'donation_arranged', 'status -> donation_arranged');
  perform t.act(d1);
  rec := public.record_donation(m1, current_date, 1, null);
  perform t.root();
  perform t.ok((select status from public.donation_records where id = rec) = 'pending_confirmation', 'self-reported donation is only pending');
  perform t.act(null);
  perform t.ok((public.public_stats('SA') ->> 'confirmed_donations')::int = 0, 'unconfirmed donations are not counted publicly');
  perform t.root();
  perform t.fails(d1, format('select public.confirm_donation(%L, true)', rec), 'not_authorized', 'donors cannot confirm their own donation');
  perform t.fails(requester, format('update public.donation_records set status = ''confirmed'' where id = %L; select 1/(select count(*) from public.donation_records where status=''confirmed'')', rec),
    'division by zero', 'donation records cannot be updated directly');
  perform t.act(staff);
  perform public.confirm_donation(rec, true, null);
  perform public.transition_request(req, 'completed', null);
  perform t.root();
  perform t.ok((select is_verified from public.donor_profiles where user_id = d1), 'confirmed donation verifies the donor');
  perform t.ok((public.public_stats('SA') ->> 'confirmed_donations')::int = 1, 'confirmed donation counted');
  perform t.fails(requester, format('select public.transition_request(%L, ''cancelled'')', req), 'invalid_transition', 'completed is terminal');

  perform t.fails(admin, 'select public.run_auto_matching(gen_random_uuid())', 'not_found', 'matching a missing request reports not_found');
  -- contact closes when a request is cancelled
  perform t.act(requester);
  select r.id into req from public.submit_blood_request('self', 'O+', 1, 'SA', riyadh, 'Hospital X (test)', now() + interval '1 day', 'normal', true, null, inst) r;
  perform t.root();
  perform t.act(staff);
  perform public.transition_request(req, 'verified', null);
  perform public.send_manual_match(req, d1);
  perform t.root();
  select id into m1 from public.donor_matches where request_id = req and donor_id = d1;
  perform t.act(d1); perform public.respond_to_match(m1, true, null, true); perform t.root();
  perform t.act(requester); perform public.set_contact_consent(m1, true); perform t.root();
  perform t.act(requester);
  perform t.ok((select count(*) from public.get_match_contact(m1)) = 1, 'contact visible while request is live');
  perform public.transition_request(req, 'cancelled', null);
  perform t.root();
  perform t.fails(requester, format('select * from public.get_match_contact(%L)', m1), 'invalid_transition', 'contact closes when the request is cancelled');
  perform t.fails(d1, format('insert into public.messages (match_id, sender_id, body) values (%L, auth.uid(), ''hi'')', m1),
    'row-level security', 'messaging closes when the request is cancelled');

  -- ---------- requester limits
  perform t.act(requester);
  for i in 1..3 loop
    perform public.submit_blood_request('self', 'B+', 1, 'SA', jeddah, 'Hospital ' || i, now() + interval '1 day', 'normal', true);
  end loop;
  perform t.root();
  perform t.fails(requester, format($q$select public.submit_blood_request('self','B+',1,'SA','%s','H', now()+interval '1 day','normal', true)$q$, jeddah),
    'too_many_open_requests', 'open request cap enforced');
  select id into req from public.blood_requests where requester_id = requester and status = 'submitted' limit 1;
  perform t.act(requester);
  perform public.transition_request(req, 'cancelled', null);
  perform t.root();
  perform t.ok((select status from public.blood_requests where id = req) = 'cancelled', 'requester can cancel own request');

  -- expiry
  update public.blood_requests set expires_at = now() - interval '1 minute' where requester_id = requester and status = 'submitted';
  perform t.ok(public.expire_overdue_requests() = 2, 'overdue requests expire');

  -- ---------- humanitarian initiatives
  perform t.act(organizer);
  insert into public.humanitarian_initiatives (category, title_ar, description, objectives, beneficiaries, country_code, start_date,
    organizer_name, status)
  values ('blood_drive', 'حملة تبرع تجريبية', 'وصف تجريبي لحملة تبرع بالدم في مدينة الخرطوم لاختبار النظام.', 'اختبار سير الاعتماد',
    'مرضى المستشفيات', 'SD', current_date, 'Test organizer', 'approved') returning id into init;
  perform t.root();
  perform t.ok((select status from public.humanitarian_initiatives where id = init) = 'submitted', 'organizer cannot self-approve (forced submitted)');
  perform t.act(null);
  perform t.ok((select count(*) from public.public_initiatives) = 0, 'unapproved initiatives are hidden from the public');
  perform t.root();
  perform t.fails(organizer, format('update public.humanitarian_initiatives set title_ar = ''تعديل العنوان'' where id = %L', init),
    'initiative_locked', 'submitted initiatives are locked for organisers');
  perform t.fails(admin, format('select public.review_initiative(%L, ''rejected'')', init), 'invalid_input', 'rejection needs a note');
  perform t.act(admin);
  perform public.review_initiative(init, 'approved', null);
  perform t.root();
  perform t.act(null);
  perform t.ok((select count(*) from public.public_initiatives) = 1, 'approved initiative is public');
  perform t.ok((select count(*) from public.initiative_updates) = 0, 'no updates yet');
  perform t.root();
  perform t.ok(exists (select 1 from public.user_roles where user_id = organizer and role = 'organizer'), 'approval grants organizer role');
  perform t.act(organizer);
  insert into public.initiative_updates (initiative_id, author_id, body) values (init, organizer, 'تم تجهيز موقع الحملة');
  perform t.root();

  -- sponsors
  perform t.act(outsider);
  insert into public.sponsors (type, name_ar, status) values ('corporate', 'شركة تجريبية', 'approved');
  perform t.root();
  perform t.act(null);
  perform t.ok((select count(*) from public.public_sponsors) = 0, 'unapproved sponsors are hidden');
  perform t.root();
  perform t.fails(null, 'select organizer_contact from public.humanitarian_initiatives', 'permission denied', 'anon cannot read raw initiative rows (organiser contact)');
  perform t.fails(null, 'select review_note from public.institutions', 'permission denied', 'anon cannot read raw institution rows');
  perform t.act(outsider);
  perform t.ok((select count(*) from public.humanitarian_initiatives) = 0, 'other users cannot read raw initiative rows');
  perform t.ok((select count(*) from public.public_institutions) = 1, 'approved institutions are listed publicly');
  perform t.root();

  -- ---------- notifications
  perform t.act(requester);
  update public.notifications set title_en = 'hacked', read_at = now() where user_id = requester;
  perform t.root();
  perform t.ok(not exists (select 1 from public.notifications where title_en = 'hacked'), 'notification text is immutable for users');
  perform t.ok(not exists (select 1 from public.notifications where user_id = requester and read_at is null), 'users can mark notifications read');
  perform t.act(outsider);
  perform t.ok((select count(*) from public.notifications where user_id <> outsider) = 0, 'users only see their own notifications');
  perform t.ok((select count(*) from public.audit_logs) = 0, 'audit log is admin-only');
  perform t.root();

  -- ---------- admin
  perform t.act(admin);
  s := public.admin_stats(null, null, null, null, false);
  perform t.root();
  perform t.ok((s -> 'requests' ->> 'total')::int = 5 and (s ->> 'confirmed_donations')::int = 1, 'admin stats ' || (s -> 'requests')::text);
  perform t.ok((s -> 'blood_group_distribution' -> 'O+' ->> 'donors')::int = 3, 'blood group distribution');
  perform t.fails(outsider, 'select public.admin_stats()', 'not_authorized', 'admin stats are admin-only');
  perform t.act(admin);
  perform public.admin_set_account_status(d3, 'suspended', 'test');
  perform t.root();
  perform t.fails(d3, 'select public.set_donor_availability(''available'')', 'account_inactive', 'suspended users cannot act');
  perform t.act(outsider);
  perform t.ok((select count(*) from public.search_donors('SA', riyadh, 'A+', false)) = 0, 'suspended donors disappear from search');
  perform t.root();

  -- ---------- demo accounts: their rows inherit the demo flag
  update public.profiles set is_demo = true where id = outsider;
  perform t.act(outsider);
  select r.id into req from public.submit_blood_request('self', 'AB-', 1, 'SA', riyadh, 'Demo Hospital', now() + interval '1 day', 'normal', true) r;
  perform t.root();
  perform t.ok((select is_demo from public.blood_requests where id = req), 'requests from demo accounts are flagged demo');
  update public.profiles set is_demo = false where id = outsider;

  -- ---------- email users: contact phone
  insert into auth.users (email) values ('mail-only@example.org') returning id into x;
  perform t.ok((select phone is null and email = 'mail-only@example.org' from public.profiles where id = x.id), 'email-only signup creates a profile without phone');
  perform t.act(x.id);
  perform public.set_contact_phone('+966 50 123 4567');
  perform t.root();
  perform t.ok((select contact_phone from public.profiles where id = x.id) = '966501234567', 'contact phone is normalised');
  perform t.fails(x.id, 'select public.set_contact_phone(''123'')', 'invalid_input', 'short contact phone rejected');
  perform t.fails(x.id, 'update public.profiles set contact_phone = ''999999999999'' where id = auth.uid(); select 1/(select count(*) from public.profiles where contact_phone = ''999999999999'')',
    'division by zero', 'contact phone cannot be written directly');

  -- ---------- account deletion
  perform t.act(dsd);
  perform public.delete_my_account();
  perform t.root();
  perform t.ok((select full_name is null and phone is null and account_status = 'deleted' from public.profiles where id = dsd), 'account deletion anonymises the profile');
  perform t.ok(not exists (select 1 from public.donor_profiles where user_id = dsd), 'donor profile removed on deletion');

  raise notice 'ALL TESTS PASSED';
end $$;
