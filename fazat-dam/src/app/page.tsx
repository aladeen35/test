import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { fmt } from "@/lib/i18n";
import { getViewer } from "@/lib/auth";
import { getNetwork } from "@/lib/network";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { fmtDateTime, fmtNumber, pick } from "@/lib/format";
import { TIMEZONE } from "@/lib/constants";
import { BloodChip, Chip, DemoBadge, Empty, LinkCard, MedicalNotice, SetupMissing, Stat } from "@/components/ui";
import { NetworkSwitch } from "@/components/header-controls";
import { DropIcon, HeartIcon, SearchIcon, GlobeIcon } from "@/components/icons";

type Emergency = { id: string; reference: string; blood_group: string; units: number; city_ar: string; city_en: string; hospital_name: string; urgency: "normal" | "urgent" | "critical"; required_by: string; is_demo: boolean };

export default async function HomePage() {
  const { t, locale } = await getDict();
  const viewer = await getViewer();
  const network = await getNetwork();
  const configured = isSupabaseConfigured();

  let emergencies: Emergency[] = [];
  let stats: Record<string, number> | null = null;
  let initiatives: { id: string; title_ar: string; title_en: string | null; organizer_name: string; category: string; is_demo: boolean }[] = [];
  if (configured) {
    const supabase = await createClient();
    const [e, s, i] = await Promise.all([
      supabase.rpc("public_emergency_requests", { p_country: network, p_limit: 6 }),
      supabase.rpc("public_stats", { p_country: network }),
      supabase.from("public_initiatives").select("id, title_ar, title_en, organizer_name, category, is_demo").eq("status", "approved").order("published_at", { ascending: false }).limit(3),
    ]);
    emergencies = (e.data ?? []) as Emergency[];
    stats = (s.data ?? null) as Record<string, number> | null;
    initiatives = i.data ?? [];
  }

  return (
    <div className="flex flex-col gap-6">
      {!configured && <SetupMissing t={t} />}

      <section className="overflow-hidden rounded-[var(--radius-card)] bg-white shadow-[var(--shadow-card)]">
        <div className="flex flex-col items-center gap-4 p-5 sm:flex-row sm:items-center">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/brand/logo-horizontal.png" alt={`${t.meta.name} — ${t.meta.slogan}`} className="w-full max-w-sm" width={572} height={230} />
          <div className="flex flex-1 flex-col gap-2 text-center sm:text-start">
            <h1 className="text-2xl font-bold text-navy">
              {viewer?.fullName ? fmt(t.home.welcomeUser, { name: viewer.fullName.split(" ")[0] }) : t.home.welcome}
            </h1>
            <p className="text-muted">{t.home.intro}</p>
            <div className="mt-1 flex flex-wrap items-center justify-center gap-2 sm:justify-start">
              <GlobeIcon className="h-5 w-5 text-muted" />
              <NetworkSwitch current={network} />
            </div>
          </div>
        </div>
      </section>

      <section className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <LinkCard href="/requests/new" tone="red" title={t.home.needBlood} sub={t.home.needBloodSub} icon={<DropIcon className="h-9 w-9" />} />
        <LinkCard href="/donate" tone="navy" title={t.home.wantDonate} sub={t.home.wantDonateSub} icon={<HeartIcon className="h-9 w-9" />} />
        <LinkCard href="/donors" title={t.home.searchDonors} sub={t.search.intro} icon={<SearchIcon className="h-9 w-9 text-brand" />} />
      </section>

      <section aria-labelledby="em" className="flex flex-col gap-3">
        <h2 id="em" className="section-title">{t.home.emergency}</h2>
        {emergencies.length === 0 ? <Empty>{t.home.emergencyEmpty}</Empty> : (
          <ul className="grid grid-cols-1 gap-3 md:grid-cols-2">
            {emergencies.map((r) => (
              <li key={r.id} className="card flex items-center gap-3">
                <BloodChip group={r.blood_group} size="lg" />
                <div className="flex min-w-0 flex-1 flex-col gap-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <Chip tone={r.urgency === "critical" ? "red" : r.urgency === "urgent" ? "amber" : "navy"}>{t.request[`urgency_${r.urgency}`]}</Chip>
                    <span className="text-sm font-semibold">{locale === "ar" ? r.city_ar : r.city_en}</span>
                    {r.is_demo && <DemoBadge t={t} />}
                  </div>
                  <p className="truncate text-sm text-navy">{r.hospital_name}</p>
                  <p className="text-xs text-muted">
                    <span className="latin">{r.units}</span> {t.common.units} · {t.request.requiredBy} {fmtDateTime(r.required_by, locale, TIMEZONE[network])}
                  </p>
                </div>
                <Link href="/donate" className="btn-primary min-h-10 px-3 text-sm">{t.match.accept}</Link>
              </li>
            ))}
          </ul>
        )}
        <p className="text-xs text-muted">{t.home.networkNote}</p>
      </section>

      {stats && (
        <section aria-labelledby="st" className="flex flex-col gap-3">
          <h2 id="st" className="section-title">{t.home.stats}</h2>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
            <Stat label={t.home.statDonors} value={fmtNumber(stats.registered_donors ?? 0, locale)} />
            <Stat label={t.home.statAvailable} value={fmtNumber(stats.available_donors ?? 0, locale)} />
            <Stat label={t.home.statVerified} value={fmtNumber(stats.verified_requests ?? 0, locale)} />
            <Stat label={t.home.statDonations} value={fmtNumber(stats.confirmed_donations ?? 0, locale)} />
            <Stat label={t.home.statInitiatives} value={fmtNumber(stats.approved_initiatives ?? 0, locale)} />
          </div>
          <p className="text-xs text-muted">{t.home.statsNote}</p>
        </section>
      )}

      <section aria-labelledby="in" className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h2 id="in" className="section-title">{t.home.initiatives}</h2>
          <Link href="/initiatives" className="text-sm font-semibold text-brand-600">{t.common.viewAll}</Link>
        </div>
        {initiatives.length === 0 ? <Empty>{t.home.initiativesEmpty}</Empty> : (
          <ul className="grid grid-cols-1 gap-3 md:grid-cols-3">
            {initiatives.map((i) => (
              <li key={i.id}>
                <Link href={`/initiatives/${i.id}`} className="card flex h-full flex-col gap-2 hover:ring-2 hover:ring-brand-400/30">
                  <Chip tone="red">{t.initiative[`cat_${i.category}` as keyof typeof t.initiative]}</Chip>
                  <span className="font-bold text-navy">{pick(locale, i.title_ar, i.title_en)}</span>
                  <span className="text-sm text-muted">{i.organizer_name}</span>
                  {i.is_demo && <DemoBadge t={t} />}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section aria-labelledby="aw" className="flex flex-col gap-3">
        <h2 id="aw" className="section-title">{t.home.awareness}</h2>
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
          {([[t.home.aware1Title, t.home.aware1], [t.home.aware2Title, t.home.aware2], [t.home.aware3Title, t.home.aware3]] as const).map(([h, p]) => (
            <div key={h} className="card"><h3 className="font-bold text-navy">{h}</h3><p className="mt-1 text-sm text-muted">{p}</p></div>
          ))}
        </div>
        <MedicalNotice t={t} />
      </section>
    </div>
  );
}
