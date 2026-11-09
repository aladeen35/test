import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { fmt } from "@/lib/i18n";
import { requireViewer } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { getNetwork } from "@/lib/network";
import { createClient } from "@/lib/supabase/server";
import { errorText } from "@/lib/errors";
import { BLOOD_GROUPS } from "@/lib/constants";
import { BloodChip, Chip, DemoBadge, Empty, Notice, PageHeader } from "@/components/ui";
import { SearchFilters } from "./search-filters";
import { SendRequestButton } from "./send-request";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.search.title };
}

type Donor = { donor_id: string; display_name: string; blood_group: string; city_ar: string; city_en: string; is_available: boolean; is_verified: boolean; is_demo: boolean };

export default async function DonorsPage({ searchParams }: PageProps<"/donors">) {
  const { t, locale } = await getDict();
  const viewer = await requireViewer("/donors");
  const sp = await searchParams;
  const country = sp.country === "SD" || sp.country === "SA" ? sp.country : await getNetwork();
  const city = typeof sp.city === "string" && /^[0-9a-f-]{36}$/.test(sp.city) ? sp.city : null;
  const group = typeof sp.group === "string" && (BLOOD_GROUPS as readonly string[]).includes(sp.group) ? sp.group : null;
  const availableOnly = sp.all !== "1";
  const page = Math.max(0, Number(sp.page ?? 0) || 0);

  const supabase = await createClient();
  const [cities, search, myRequests] = await Promise.all([
    getCities(),
    supabase.rpc("search_donors", { p_country: country, p_city: city, p_blood_group: group, p_available_only: availableOnly, p_limit: 30, p_offset: page * 30 }),
    // the viewer's own verified, open requests in this network can be used for direct donation requests
    supabase.from("blood_requests").select("id, reference, blood_group").eq("requester_id", viewer.id).eq("country_code", country)
      .in("status", ["verified", "matching_donors", "donors_responding"]),
  ]);
  const donors = (search.data ?? []) as Donor[];
  const reqs = myRequests.data ?? [];

  return (
    <div className="flex flex-col gap-4">
      <PageHeader title={t.search.title} intro={t.search.intro} />
      <SearchFilters cities={cities} country={country} city={city} group={group} availableOnly={availableOnly} />
      <p className="text-xs text-muted">{t.search.mapSoon}</p>
      {search.error && <Notice tone="error">{errorText(t, search.error)}</Notice>}
      {!search.error && <p className="text-sm text-muted">{fmt(t.search.results, { n: donors.length })}</p>}
      {donors.length === 0 ? <Empty>{t.search.empty}</Empty> : (
        <ul className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3">
          {donors.map((d) => {
            const usable = reqs.filter((r) => r.blood_group === d.blood_group);
            return (
              <li key={d.donor_id} className="card flex flex-col gap-3">
                <div className="flex items-center gap-3">
                  <BloodChip group={d.blood_group} size="lg" />
                  <div className="flex flex-col gap-1">
                    <span className="latin font-bold text-navy" dir="auto">{d.display_name}</span>
                    <span className="text-sm text-muted">{locale === "ar" ? d.city_ar : d.city_en}</span>
                  </div>
                </div>
                <div className="flex flex-wrap gap-2">
                  <Chip tone={d.is_available ? "green" : "gray"}>{d.is_available && <span className="fd-live-dot" aria-hidden />}{d.is_available ? t.common.available : t.common.unavailable}</Chip>
                  {d.is_verified && <Chip tone="navy">{t.common.verified}</Chip>}
                  {d.is_demo && <DemoBadge t={t} />}
                </div>
                {d.is_available && (usable.length > 0
                  ? <SendRequestButton donorId={d.donor_id} requests={usable.map((r) => ({ id: r.id, reference: r.reference }))} />
                  : <p className="hint">{t.search.noVerified}</p>)}
              </li>
            );
          })}
        </ul>
      )}
      {donors.length === 30 && (
        <a className="btn-outline self-center" href={`?${new URLSearchParams({ country, ...(city ? { city } : {}), ...(group ? { group } : {}), ...(availableOnly ? {} : { all: "1" }), page: String(page + 1) })}`}>{t.search.more}</a>
      )}
    </div>
  );
}
