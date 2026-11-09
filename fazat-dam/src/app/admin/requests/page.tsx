import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { getCities, cityMap } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { cityName, fmtDate } from "@/lib/format";
import { REQUEST_STATUSES } from "@/lib/constants";
import { BloodChip, Chip, DemoBadge, Empty, PageHeader, StatusBadge } from "@/components/ui";
import { AdminFilters } from "../admin-filters";
import { sp, isUuid, isDate, isCountry } from "../params";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.requests };
}

export default async function AdminRequests({ searchParams }: PageProps<"/admin/requests">) {
  const { t, locale } = await getDict();
  await requireAdmin();
  const q = await searchParams;
  const f = { country: sp(q.country), city: sp(q.city), status: sp(q.status), from: sp(q.from), to: sp(q.to) };
  const supabase = await createClient();
  let query = supabase.from("blood_requests").select("id, reference, blood_group, units, status, urgency, hospital_name, city_id, created_at, required_by, is_demo").order("created_at", { ascending: false }).limit(100);
  if (isCountry(f.country)) query = query.eq("country_code", f.country!);
  if (isUuid(f.city)) query = query.eq("city_id", f.city!);
  if (f.status && (REQUEST_STATUSES as readonly string[]).includes(f.status)) query = query.eq("status", f.status);
  if (isDate(f.from)) query = query.gte("created_at", f.from!);
  if (isDate(f.to)) query = query.lte("created_at", `${f.to}T23:59:59`);
  const [{ data }, cities, cmap] = await Promise.all([query, getCities(true), cityMap()]);
  return (
    <div>
      <PageHeader title={t.admin.requests} />
      <AdminFilters cities={cities} values={f} showDates statuses={REQUEST_STATUSES.map((s) => ({ value: s, label: t.status[s] }))} />
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <ul className="flex flex-col gap-2">
          {data!.map((r) => (
            <li key={r.id}>
              <Link href={`/admin/requests/${r.id}`} className="card flex flex-wrap items-center gap-3 hover:ring-2 hover:ring-brand-400/30">
                <BloodChip group={r.blood_group} />
                <div className="flex min-w-40 flex-1 flex-col">
                  <span className="latin font-bold">{r.reference}</span>
                  <span className="text-xs text-muted">{r.hospital_name} · {cityName(cmap.get(r.city_id), locale)} · {fmtDate(r.created_at, locale)}</span>
                </div>
                <Chip tone={r.urgency === "critical" ? "red" : r.urgency === "urgent" ? "amber" : "navy"}>{t.request[`urgency_${r.urgency as "normal"}`]}</Chip>
                <StatusBadge status={r.status} t={t} />
                {r.is_demo && <DemoBadge t={t} />}
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
