import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { getViewer } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { fmtNumber } from "@/lib/format";
import { errorText } from "@/lib/errors";
import { BLOOD_GROUPS } from "@/lib/constants";
import { Notice, PageHeader, Stat } from "@/components/ui";
import { AdminFilters } from "./admin-filters";
import { sp, isUuid, isDate, isCountry } from "./params";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.title };
}

type Stats = {
  total_users: number; active_donors: number; available_donors: number; confirmed_donations: number; open_reports: number;
  requests: { total: number; verified: number; completed: number; unfulfilled: number; open: number; pending_review: number };
  requests_by_city: { name_ar: string; name_en: string; country_code: string; total: number }[];
  requests_by_country: Record<string, number>;
  blood_group_distribution: Record<string, { donors: number; requests: number }>;
  initiatives: Record<string, number>; institutions: Record<string, number>;
};

function Bar({ label, value, max }: { label: string; value: number; max: number }) {
  return (
    <div className="flex items-center gap-2 text-sm">
      <span className="w-28 shrink-0 truncate">{label}</span>
      <span className="h-3 flex-1 overflow-hidden rounded-full bg-surface-2"><span className="block h-full rounded-full bg-brand" style={{ width: `${max ? (value / max) * 100 : 0}%` }} /></span>
      <span className="latin w-10 text-end font-semibold">{value}</span>
    </div>
  );
}

export default async function AdminOverview({ searchParams }: PageProps<"/admin">) {
  const { t, locale } = await getDict();
  const viewer = await getViewer();
  if (!viewer?.isAdmin) redirect("/institution");
  const q = await searchParams;
  const f = { country: sp(q.country), city: sp(q.city), from: sp(q.from), to: sp(q.to), demo: sp(q.demo) };
  const supabase = await createClient();
  const [cities, { data, error }] = await Promise.all([
    getCities(true),
    supabase.rpc("admin_stats", {
      p_country: isCountry(f.country) ? f.country : null, p_city: isUuid(f.city) ? f.city : null,
      p_from: isDate(f.from) ? f.from : null, p_to: isDate(f.to) ? f.to : null, p_include_demo: f.demo === "1",
    }),
  ]);
  const s = data as Stats | null;
  const n = (v: number | undefined) => fmtNumber(v ?? 0, locale);
  const maxCity = Math.max(1, ...(s?.requests_by_city ?? []).map((c) => c.total));
  const maxGroup = Math.max(1, ...Object.values(s?.blood_group_distribution ?? {}).flatMap((g) => [g.donors, g.requests]));
  return (
    <div>
      <PageHeader title={t.admin.overview} />
      <AdminFilters cities={cities} values={f} showDates showDemo />
      {error && <Notice tone="error">{errorText(t, error)}</Notice>}
      {s && (
        <div className="flex flex-col gap-4">
          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            <Stat label={t.admin.totalUsers} value={n(s.total_users)} />
            <Stat label={t.admin.activeDonors} value={n(s.active_donors)} />
            <Stat label={t.admin.availableDonors} value={n(s.available_donors)} />
            <Stat label={t.admin.confirmedDonations} value={n(s.confirmed_donations)} />
            <Stat label={t.admin.totalRequests} value={n(s.requests.total)} />
            <Stat label={t.admin.verifiedRequests} value={n(s.requests.verified)} />
            <Stat label={t.admin.completedRequests} value={n(s.requests.completed)} />
            <Stat label={t.admin.unfulfilled} value={n(s.requests.unfulfilled)} />
            <Stat label={t.admin.pendingReview} value={n(s.requests.pending_review)} />
            <Stat label={t.admin.openReports} value={n(s.open_reports)} />
          </div>
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            <section className="card flex flex-col gap-2">
              <h2 className="section-title">{t.admin.byCity}</h2>
              {s.requests_by_city.length === 0 ? <p className="text-sm text-muted">{t.admin.noData}</p> :
                s.requests_by_city.map((c) => <Bar key={c.name_en + c.country_code} label={locale === "ar" ? c.name_ar : c.name_en} value={c.total} max={maxCity} />)}
              <h3 className="mt-3 font-bold text-navy">{t.admin.byCountry}</h3>
              <Bar label={t.common.sudan} value={s.requests_by_country.SD ?? 0} max={Math.max(1, s.requests.total)} />
              <Bar label={t.common.saudi} value={s.requests_by_country.SA ?? 0} max={Math.max(1, s.requests.total)} />
            </section>
            <section className="card flex flex-col gap-2">
              <h2 className="section-title">{t.admin.groups}</h2>
              <table className="w-full text-sm">
                <thead><tr className="text-muted"><th className="text-start">{t.common.bloodGroup}</th><th className="text-start">{t.admin.groupDonors}</th><th className="text-start">{t.admin.groupRequests}</th></tr></thead>
                <tbody>
                  {BLOOD_GROUPS.map((g) => {
                    const v = s.blood_group_distribution[g] ?? { donors: 0, requests: 0 };
                    return (
                      <tr key={g} className="border-t border-line">
                        <td className="latin py-1.5 font-bold">{g}</td>
                        <td className="py-1.5 pe-2"><Bar label="" value={v.donors} max={maxGroup} /></td>
                        <td className="py-1.5"><Bar label="" value={v.requests} max={maxGroup} /></td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </section>
            <section className="card flex flex-col gap-2">
              <h2 className="section-title">{t.admin.campaigns}</h2>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <span>{t.initiative.st_under_review}: <b className="latin">{s.initiatives.pending}</b></span>
                <span>{t.initiative.st_approved}: <b className="latin">{s.initiatives.approved}</b></span>
                <span>{t.initiative.st_completed}: <b className="latin">{s.initiatives.completed}</b></span>
                <span>{t.initiative.st_rejected}: <b className="latin">{s.initiatives.rejected}</b></span>
              </div>
            </section>
            <section className="card flex flex-col gap-2">
              <h2 className="section-title">{t.admin.institutionsStat}</h2>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <span>{t.institution.type_hospital}: <b className="latin">{s.institutions.approved_hospitals}</b></span>
                <span>{t.institution.type_blood_bank}: <b className="latin">{s.institutions.approved_blood_banks}</b></span>
                <span>{t.institution.st_pending}: <b className="latin">{s.institutions.pending}</b></span>
              </div>
            </section>
          </div>
        </div>
      )}
    </div>
  );
}
