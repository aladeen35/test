-- =====================================================================
-- Email sign-in (now) alongside phone OTP (later).
-- profiles.phone stays the Auth-verified number. Users who sign in by
-- email give a contact number themselves: profiles.contact_phone
-- (unverified, private, revealed only after mutual consent like phone).
-- =====================================================================
alter table public.profiles
  add column if not exists contact_phone text check (contact_phone is null or contact_phone ~ '^\+?[0-9]{8,15}$');

create or replace function public.set_contact_phone(p_phone text)
returns void language plpgsql security definer set search_path = public as $$
declare _uid uuid := public._require_user(); _clean text := nullif(regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g'), '');
begin
  if _clean is not null and length(_clean) not between 8 and 15 then raise exception 'invalid_input'; end if;
  perform public._rate_limit('set_contact_phone', 10, interval '24 hours');
  update public.profiles set contact_phone = _clean where id = _uid;
end $$;

-- Reveal uses the verified number when there is one, otherwise the contact number.
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
  select p.full_name, coalesce(p.phone, p.contact_phone),
         coalesce((select d.contact_method from public.donor_profiles d where d.user_id = _other), 'phone_call'::public.contact_method)
    from public.profiles p where p.id = _other and p.account_status = 'active';
end $$;

-- Users may not write contact_phone directly (only through set_contact_phone)
create or replace function public.tg_guard_profile()
returns trigger language plpgsql set search_path = public as $$
begin
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return new;
  end if;
  new.id := old.id;
  new.phone := old.phone;
  new.contact_phone := old.contact_phone;
  new.account_status := old.account_status;
  new.status_note := old.status_note;
  new.deleted_at := old.deleted_at;
  new.is_demo := old.is_demo;
  new.created_at := old.created_at;
  return new;
end $$;

-- Account deletion also clears the contact number
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
  update public.profiles set full_name = null, phone = null, contact_phone = null, email = null, account_status = 'deleted', deleted_at = now()
   where id = _uid;
  insert into public.audit_logs (actor_id, action, entity_type, entity_id) values (_uid, 'account_deleted', 'profiles', _uid);
end $$;

revoke execute on function public.set_contact_phone(text) from public, anon;
grant execute on function public.set_contact_phone(text) to authenticated;
