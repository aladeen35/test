-- =====================================================================
-- Rows created by demonstration accounts inherit the demo flag, so they
-- never count in public statistics (requests and donations created by
-- demo users were previously stored with is_demo = false).
-- =====================================================================
create or replace function public.tg_inherit_demo_flag()
returns trigger language plpgsql security definer set search_path = public as $$
declare _owner uuid;
begin
  -- read the owner column by name (each table names it differently)
  _owner := (to_jsonb(new) ->> case tg_table_name
    when 'blood_requests' then 'requester_id'
    when 'donation_records' then 'donor_id'
    when 'humanitarian_initiatives' then 'organizer_id'
    when 'institutions' then 'created_by'
    when 'sponsors' then 'submitted_by'
  end)::uuid;
  if _owner is not null and exists (select 1 from public.profiles where id = _owner and is_demo) then
    new.is_demo := true;
  end if;
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['blood_requests', 'donation_records', 'humanitarian_initiatives', 'institutions', 'sponsors'] loop
    execute format('create trigger inherit_demo_flag before insert on public.%I for each row execute function public.tg_inherit_demo_flag()', t);
  end loop;
end $$;

-- Backfill rows already created by demo accounts
update public.blood_requests r set is_demo = true from public.profiles p where p.id = r.requester_id and p.is_demo and not r.is_demo;
update public.donation_records d set is_demo = true from public.profiles p where p.id = d.donor_id and p.is_demo and not d.is_demo;
update public.humanitarian_initiatives i set is_demo = true from public.profiles p where p.id = i.organizer_id and p.is_demo and not i.is_demo;
update public.institutions i set is_demo = true from public.profiles p where p.id = i.created_by and p.is_demo and not i.is_demo;
update public.sponsors s set is_demo = true from public.profiles p where p.id = s.submitted_by and p.is_demo and not s.is_demo;

revoke execute on function public.tg_inherit_demo_flag() from public, anon, authenticated;
