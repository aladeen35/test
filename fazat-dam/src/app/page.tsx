import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { fmt } from "@/lib/i18n";
import { getViewer } from "@/lib/auth";
import { getNetwork } from "@/lib/network";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { fmtDateTime, pick, timeLeft } from "@/lib/format";
import { TIMEZONE } from "@/lib/constants";
import { BloodChip, Chip, DemoBadge, Empty, MedicalNotice, SetupMissing } from "@/components/ui";
import { CountUp } from "@/components/count-up";
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

      {/* Hero: brand-red header with the greeting and the network switch */}
      <section className="fd-hero relative -mx-4 -mt-5 overflow-hidden rounded-b-[2rem] px-5 pb-16 pt-6 text-white">
        <svg viewBox="0 0 400 60" preserveAspectRatio="none" aria-hidden="true" className="pointer-events-none absolute inset-x-0 bottom-8 h-14 w-full opacity-25">
          <path d="M0 30 H120 L135 30 L147 8 L165 52 L180 20 L190 30 H400" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        <div className="relative mx-auto flex max-w-6xl items-center gap-4">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/brand/symbol.png" alt="" width={72} height={72} className="fd-float h-[72px] w-[72px] shrink-0 rounded-2xl bg-white p-1 shadow-lg" />
          <div className="flex min-w-0 flex-col gap-1">
            <h1 className="text-2xl font-bold leading-tight">
              {viewer?.fullName ? fmt(t.home.welcomeUser, { name: viewer.fullName.split(" ")[0] }) : t.home.welcome}
            </h1>
            <p className="text-sm text-white/90">{t.meta.slogan}</p>
          </div>
        </div>
        <div className="relative mx-auto mt-4 flex max-w-6xl flex-wrap items-center gap-2">
          <GlobeIcon className="h-5 w-5 text-white/80" />
          <NetworkSwitch current={network} />
        </div>
      </section>

      {/* Primary actions overlap the hero */}
      <section className="fd-stagger relative z-10 -mt-14 grid grid-cols-2 gap-3 sm:grid-cols-3">
        <Link href="/requests/new" className="flex min-h-32 flex-col justify-between rounded-[var(--radius-card)] bg-white p-4 shadow-[0_10px_30px_rgb(198_40_40/0.18)] ring-1 ring-brand/10 transition-transform active:scale-[0.98]">
          <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-brand text-white"><DropIcon className="h-7 w-7" /></span>
          <span><span className="block text-lg font-bold text-brand-600">{t.home.needBlood}</span><span className="block text-xs text-muted">{t.home.needBloodSub}</span></span>
        </Link>
        <Link href="/donate" className="flex min-h-32 flex-col justify-between rounded-[var(--radius-card)] bg-navy p-4 text-white shadow-[0_10px_30px_rgb(23_43_77/0.25)] transition-transform active:scale-[0.98]">
          <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/15"><HeartIcon className="fd-heart h-7 w-7" /></span>
          <span><span className="block text-lg font-bold">{t.home.wantDonate}</span><span className="block text-xs text-white/80">{t.home.wantDonateSub}</span></span>
        </Link>
        <Link href="/donors" className="col-span-2 flex items-center gap-3 rounded-[var(--radius-card)] bg-white p-4 shadow-[var(--shadow-card)] transition-transform active:scale-[0.98] sm:col-span-1 sm:min-h-32 sm:flex-col sm:items-start sm:justify-between">
          <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-brand-50 text-brand"><SearchIcon className="h-7 w-7" /></span>
          <span><span className="block text-lg font-bold text-navy">{t.home.searchDonors}</span><span className="block text-xs text-muted">{t.search.intro}</span></span>
        </Link>
      </section>

      <section aria-labelledby="em" className="flex flex-col gap-3">
        <h2 id="em" className="section-title flex items-center gap-2">
          {emergencies.length > 0 && <span className="fd-live-dot !bg-brand" aria-hidden />}
          {t.home.emergency}
        </h2>
        {emergencies.length === 0 ? <Empty>{t.home.emergencyEmpty}</Empty> : (
          <ul className="fd-stagger grid grid-cols-1 gap-3 md:grid-cols-2">
            {emergencies.map((r) => {
              const left = timeLeft(r.required_by);
              const tone = r.urgency === "critical" ? "bg-brand" : r.urgency === "urgent" ? "bg-warning" : "bg-navy";
              return (
                <li key={r.id} className="relative flex items-stretch overflow-hidden rounded-[var(--radius-card)] bg-white shadow-[var(--shadow-card)]">
                  <span className={`w-1.5 shrink-0 ${tone}`} aria-hidden />
                  <div className="flex flex-1 items-center gap-3 p-4">
                    <span className={`rounded-full ${r.urgency === "critical" ? "fd-critical" : ""}`}><BloodChip group={r.blood_group} size="lg" /></span>
                    <div className="flex min-w-0 flex-1 flex-col gap-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <Chip tone={r.urgency === "critical" ? "red" : r.urgency === "urgent" ? "amber" : "navy"}>{t.request[`urgency_${r.urgency}`]}</Chip>
                        <span className="text-xs font-bold text-brand-600">{left.key === "overdue" ? t.home.overdue : fmt(t.home[left.key], { n: left.n })}</span>
                        {r.is_demo && <DemoBadge t={t} />}
                      </div>
                      <p className="truncate font-bold text-navy">{r.hospital_name}</p>
                      <p className="text-xs text-muted">
                        {locale === "ar" ? r.city_ar : r.city_en} · <span className="latin">{r.units}</span> {t.common.units} · {fmtDateTime(r.required_by, locale, TIMEZONE[network])}
                      </p>
                    </div>
                    <Link href="/donate" className="btn-primary min-h-10 shrink-0 px-3 text-sm">{t.home.helpNow}</Link>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
        <p className="text-xs text-muted">{t.home.networkNote}</p>
      </section>

      {stats && (
        <section aria-labelledby="st" className="flex flex-col gap-3">
          <h2 id="st" className="section-title">{t.home.stats}</h2>
          <div className="fd-stagger grid grid-cols-2 gap-3 sm:grid-cols-5">
            {([[t.home.statDonors, stats.registered_donors], [t.home.statAvailable, stats.available_donors], [t.home.statVerified, stats.verified_requests],
               [t.home.statDonations, stats.confirmed_donations], [t.home.statInitiatives, stats.approved_initiatives]] as const).map(([label, v], i) => (
              <div key={label} className={`card flex flex-col gap-1 ${i === 4 ? "col-span-2 sm:col-span-1" : ""}`}>
                <span className="text-3xl font-bold text-navy"><CountUp value={v ?? 0} /></span>
                <span className="text-xs text-muted">{label}</span>
              </div>
            ))}
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
