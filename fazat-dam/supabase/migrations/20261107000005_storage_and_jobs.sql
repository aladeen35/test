-- =====================================================================
-- FAZAT DAM — Supabase Storage buckets/policies and scheduled jobs.
-- Supabase-specific (needs the storage schema and pg_cron).
--
-- Path convention (first folder = owning entity id):
--   request-documents/<request_id>/<uuid>.<ext>      private
--   initiative-documents/<initiative_id>/<uuid>.<ext> private
--   institution-documents/<institution_id>/<uuid>.<ext> private
--   sponsor-logos/<sponsor_id>/<uuid>.<ext>           public read, admin write
-- Private files are only ever served through short-lived signed URLs.
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('request-documents', 'request-documents', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']),
  ('initiative-documents', 'initiative-documents', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']),
  ('institution-documents', 'institution-documents', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']),
  ('sponsor-logos', 'sponsor-logos', true, 1048576, array['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])
on conflict (id) do nothing;

create or replace function public._storage_entity(_name text)
returns uuid language sql immutable as $$
  select case when split_part(_name, '/', 1) ~ '^[0-9a-f-]{36}$' then split_part(_name, '/', 1)::uuid end;
$$;

-- request documents: requester uploads while the request is in review; reviewers read
create policy "request docs upload" on storage.objects for insert to authenticated with check (
  bucket_id = 'request-documents' and exists (
    select 1 from public.blood_requests r where r.id = public._storage_entity(name)
      and r.requester_id = auth.uid() and r.status in ('submitted', 'under_review')
  )
);
create policy "request docs read" on storage.objects for select to authenticated using (
  bucket_id = 'request-documents' and exists (
    select 1 from public.blood_requests r where r.id = public._storage_entity(name)
      and (r.requester_id = auth.uid() or public.can_review_request(r.id))
  )
);

create policy "initiative docs upload" on storage.objects for insert to authenticated with check (
  bucket_id = 'initiative-documents' and exists (
    select 1 from public.humanitarian_initiatives i where i.id = public._storage_entity(name)
      and i.organizer_id = auth.uid() and i.status in ('draft', 'submitted', 'rejected')
  )
);
create policy "initiative docs read" on storage.objects for select to authenticated using (
  bucket_id = 'initiative-documents' and (public.is_admin() or exists (
    select 1 from public.humanitarian_initiatives i where i.id = public._storage_entity(name) and i.organizer_id = auth.uid()
  ))
);

create policy "institution docs upload" on storage.objects for insert to authenticated with check (
  bucket_id = 'institution-documents' and exists (
    select 1 from public.institutions i where i.id = public._storage_entity(name) and i.created_by = auth.uid()
  )
);
create policy "institution docs read" on storage.objects for select to authenticated using (
  bucket_id = 'institution-documents' and (public.is_admin() or exists (
    select 1 from public.institutions i where i.id = public._storage_entity(name) and i.created_by = auth.uid()
  ))
);

create policy "sponsor logos admin write" on storage.objects for insert to authenticated
  with check (bucket_id = 'sponsor-logos' and public.is_admin());
create policy "sponsor logos admin delete" on storage.objects for delete to authenticated
  using (bucket_id = 'sponsor-logos' and public.is_admin());

-- Scheduled maintenance (pg_cron). Safe to skip if the extension is unavailable.
do $$
begin
  create extension if not exists pg_cron;
  perform cron.schedule('fazat-expire-requests', '*/15 * * * *', 'select public.expire_overdue_requests()');
  perform cron.schedule('fazat-prune-rate-limits', '17 3 * * *',
    $q$delete from public.rate_limit_events where created_at < now() - interval '2 days'$q$);
exception when others then
  raise notice 'pg_cron not available (%): schedule expire_overdue_requests() another way', sqlerrm;
end $$;

revoke execute on function public._storage_entity(text) from public, anon;
grant execute on function public._storage_entity(text) to authenticated;

-- Pin search_path on the remaining helper functions (Supabase security advisor).
alter function public._storage_entity(text) set search_path = public;
alter function public._request_contact_open(public.request_status, timestamptz) set search_path = public;
alter function public._allowed_transition(public.request_status, public.request_status) set search_path = public;
alter function public.tg_set_updated_at() set search_path = public;
alter function public._code(integer) set search_path = public;
alter function public.tg_guard_notification() set search_path = public;
alter function public._donor_is_available(public.donor_profiles) set search_path = public;
