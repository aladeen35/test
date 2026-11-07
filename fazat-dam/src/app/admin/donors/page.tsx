import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { getCities, cityMap } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { cityName, fmtDate } from "@/lib/format";
import { BloodChip, Chip, Empty, PageHeader } from "@/components/ui";
import { AdminFilters } from "../admin-filters";
import { sp, isUuid, isCountry } from "../params";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.donors };
}

export default async function AdminDonors({ searchParams }: PageProps<"/admin/donors">) {
  const { t, locale } = await getDict();
  await requireAdmin();
  const q = await searchParams;
  const f = { country: sp(q.country), city: sp(q.city), status: sp(q.status) };
  const supabase = await createClient();
  let query = supabase.from("donor_profiles").select("user_id, public_alias, blood_group, city_id, availability, is_verified, last_donation_date, created_at").order("created_at", { ascending: false }).limit(200);
  if (isCountry(f.country)) query = query.eq("country_code", f.country!);
  if (isUuid(f.city)) query = query.eq("city_id", f.city!);
  if (f.status && ["available", "unavailable", "temporarily_suspended"].includes(f.status)) query = query.eq("availability", f.status);
  const [{ data }, cities, cmap] = await Promise.all([query, getCities(true), cityMap()]);
  return (
    <div>
      <PageHeader title={t.admin.donors} />
      <AdminFilters cities={cities} values={f} statuses={[
        { value: "available", label: t.donor.available }, { value: "unavailable", label: t.donor.unavailable }, { value: "temporarily_suspended", label: t.donor.suspended },
      ]} />
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <div className="card overflow-x-auto">
          <table className="w-full min-w-[560px] text-sm">
            <thead><tr className="text-start text-muted"><th className="py-2 text-start">{t.donor.alias}</th><th className="text-start">{t.common.bloodGroup}</th><th className="text-start">{t.common.city}</th><th className="text-start">{t.common.status}</th><th className="text-start">{t.donor.lastDonation}</th></tr></thead>
            <tbody>
              {data!.map((d) => (
                <tr key={d.user_id} className="border-t border-line">
                  <td className="latin py-2 font-semibold">{d.public_alias} {d.is_verified && <Chip tone="navy">{t.common.verified}</Chip>}</td>
                  <td><BloodChip group={d.blood_group} /></td>
                  <td>{cityName(cmap.get(d.city_id), locale)}</td>
                  <td><Chip tone={d.availability === "available" ? "green" : "gray"}>{d.availability === "available" ? t.donor.available : d.availability === "unavailable" ? t.donor.unavailable : t.donor.suspended}</Chip></td>
                  <td>{fmtDate(d.last_donation_date, locale)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
