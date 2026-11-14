import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { fmt } from "@/lib/i18n";
import { getViewer } from "@/lib/auth";
import { getNetwork } from "@/lib/network";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { fmtDateTime, pick, timeLeft } from "@/lib/format";
import { BLOOD_GROUPS, TIMEZONE } from "@/lib/constants";
import { DemoBadge, Empty, MedicalNotice, SetupMissing } from "@/components/ui";
import { CountUp } from "@/components/count-up";
import { NetworkSwitch } from "@/components/header-controls";
import { ArrowIcon, ClockIcon, DropIcon, HeartIcon, PinIcon, SearchIcon, ShieldIcon, SlidersIcon, SparkIcon, UsersIcon } from "@/components/icons";

type Emergency = { id: string; reference: string; blood_group: string; units: number; city_ar: string; city_en: string; hospital_name: string; urgency: "normal" | "urgent" | "critical"; required_by: string; is_demo: boolean };

const CAT_TONE: Record<string, string> = {
  blood_drive: "bg-brand-50 text-brand-600", medical_support: "bg-sand-50 text-sand-600", hospital_assistance: "bg-navy-100 text-navy",
  volunteer: "bg-success-50 text-success", awareness: "bg-sand-50 text-sand-600", partnership: "bg-navy-100 text-navy",
};

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
      supabase.from("public_initiatives").select("id, title_ar, title_en, organizer_name, category, is_demo").eq("status", "approved").order("published_at", { ascending: false }).limit(6),
    ]);
    emergencies = (e.data ?? []) as Emergency[];
    stats = (s.data ?? null) as Record<string, number> | null;
    initiatives = i.data ?? [];
  }
  const firstName = viewer?.fullName?.split(" ")[0];
  const networkName = network === "SD" ? t.common.sudan : t.common.saudi;

  return (
    <div className="flex flex-col gap-7">
      {!configured && <SetupMissing t={t} />}

      {/* Greeting + search, in the spirit of a calm dashboard */}
      <section className="fd-stagger flex flex-col gap-4">
        <div>
          <h1 className="text-[1.9rem] font-bold leading-tight text-navy">
            {firstName ? fmt(t.home.helloName, { name: firstName }) : t.home.welcome}
          </h1>
          <p className="mt-1 text-muted">{t.home.howHelp}</p>
        </div>
        <div className="flex items-center gap-2">
          <Link href="/donors" className="flex min-h-14 flex-1 items-center gap-3 rounded-full bg-white px-5 text-muted shadow-[var(--shadow-card)]">
            <SearchIcon className="h-5 w-5 shrink-0" />
            <span className="truncate text-sm">{t.home.searchPlaceholder}</span>
          </Link>
          <Link href="/donors" className="icon-btn h-14 w-14 bg-navy text-white" aria-label={t.search.title}><SlidersIcon className="h-5 w-5" /></Link>
        </div>
      </section>

      {/* Network tile: the navy "status" card */}
      <section className="card-dark relative overflow-hidden" aria-labelledby="net">
        <svg viewBox="0 0 400 80" preserveAspectRatio="none" aria-hidden="true" className="pointer-events-none absolute inset-x-0 bottom-0 h-20 w-full opacity-[0.12]">
          <path d="M0 50 H140 L156 50 L170 18 L190 70 L206 34 L216 50 H400" fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        <div className="relative flex items-start justify-between gap-3">
          <div>
            <p className="text-xs text-white/60">{t.home.networkLabel}</p>
            <h2 id="net" className="text-2xl font-bold text-white">{networkName}</h2>
          </div>
          <span className="flex h-12 w-12 items-center justify-center rounded-full bg-white/10"><DropIcon className="fd-heart h-6 w-6 text-sand" /></span>
        </div>
        {stats && (
          <dl className="relative mt-5 grid grid-cols-3 gap-2">
            {([[UsersIcon, stats.available_donors, t.home.availableShort], [ShieldIcon, stats.verified_requests, t.home.verifiedShort], [HeartIcon, stats.confirmed_donations, t.home.donationsShort]] as const).map(([Icon, v, label]) => (
              <div key={label} className="rounded-2xl bg-white/[0.07] px-3 py-3">
                <Icon className="h-4 w-4 text-white/60" />
                <dd className="mt-1 text-2xl font-bold leading-none text-white"><CountUp value={v ?? 0} /></dd>
                <dt className="mt-1 text-xs text-white/60">{label}</dt>
              </div>
            ))}
          </dl>
        )}
        <div className="relative mt-4"><NetworkSwitch current={network} tone="dark" /></div>
      </section>

      {/* Primary actions */}
      <section aria-labelledby="qa" className="flex flex-col gap-3">
        <h2 id="qa" className="section-title">{t.home.quickActions}</h2>
        <div className="fd-stagger grid grid-cols-2 gap-3">
          <Link href="/requests/new" className="group card flex min-h-44 flex-col justify-between transition-transform active:scale-[0.98]">
            <span className="flex h-14 w-14 items-center justify-center rounded-full bg-brand text-white shadow-[0_10px_22px_-10px_rgb(198_40_40/0.8)]"><DropIcon className="h-7 w-7" /></span>
            <span>
              <span className="block text-lg font-bold text-navy">{t.home.needBlood}</span>
              <span className="mt-0.5 block text-xs leading-5 text-muted">{t.home.needBloodSub}</span>
            </span>
          </Link>
          <Link href="/donate" className="group flex min-h-44 flex-col justify-between rounded-[var(--radius-card)] bg-sand p-5 text-navy-700 shadow-[var(--shadow-card)] transition-transform active:scale-[0.98]">
            <span className="flex h-14 w-14 items-center justify-center rounded-full bg-white/60"><HeartIcon className="fd-heart h-7 w-7 text-brand" /></span>
            <span>
              <span className="block text-lg font-bold">{t.home.wantDonate}</span>
              <span className="mt-0.5 block text-xs leading-5 text-navy-700/75">{t.home.wantDonateSub}</span>
            </span>
          </Link>
        </div>
      </section>

      {/* Urgent requests */}
      <section aria-labelledby="em" className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h2 id="em" className="section-title flex items-center gap-2">
            {emergencies.length > 0 && <span className="fd-live-dot !bg-brand" aria-hidden />}
            {t.home.emergency}
          </h2>
        </div>
        {emergencies.length === 0 ? <Empty>{t.home.emergencyEmpty}</Empty> : (
          <ul className="fd-stagger grid grid-cols-1 gap-3 md:grid-cols-2">
            {emergencies.map((r) => {
              const left = timeLeft(r.required_by);
              return (
                <li key={r.id} className="card flex items-center gap-4 p-4">
                  <span className={`latin flex h-16 w-16 shrink-0 items-center justify-center rounded-full text-xl font-bold text-white ${r.urgency === "critical" ? "fd-critical bg-brand" : r.urgency === "urgent" ? "bg-brand" : "bg-navy"}`}>{r.blood_group}</span>
                  <div className="flex min-w-0 flex-1 flex-col gap-1">
                    <div className="flex flex-wrap items-center gap-1.5">
                      <span className={`chip ${r.urgency === "critical" ? "bg-brand text-white" : r.urgency === "urgent" ? "bg-brand-50 text-brand-600" : "bg-navy-100 text-navy"}`}>{t.request[`urgency_${r.urgency}`]}</span>
                      <span className="chip bg-sand-50 text-sand-600"><ClockIcon className="h-3.5 w-3.5" />{left.key === "overdue" ? t.home.overdue : fmt(t.home[left.key], { n: left.n })}</span>
                      {r.is_demo && <DemoBadge t={t} />}
                    </div>
                    <p className="truncate font-bold text-navy">{r.hospital_name}</p>
                    <p className="flex items-center gap-1 text-xs text-muted">
                      <PinIcon className="h-3.5 w-3.5 shrink-0" />
                      <span className="truncate">{locale === "ar" ? r.city_ar : r.city_en} · <span className="latin">{r.units}</span> {t.common.units} · {fmtDateTime(r.required_by, locale, TIMEZONE[network])}</span>
                    </p>
                  </div>
                  <Link href="/donate" aria-label={`${t.home.helpNow} — ${r.hospital_name}`} className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-navy text-white transition-transform active:scale-95">
                    <ArrowIcon className="h-5 w-5 rtl:-scale-x-100" />
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
        <p className="px-1 text-xs text-muted">{t.home.networkNote}</p>
      </section>

      {/* Browse by blood group */}
      <section aria-labelledby="bg" className="flex flex-col gap-3">
        <h2 id="bg" className="section-title">{t.home.browseGroups}</h2>
        <div className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1 [scrollbar-width:none]">
          {BLOOD_GROUPS.map((g) => (
            <Link key={g} href={`/donors?country=${network}&group=${encodeURIComponent(g)}`} className="latin flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-white text-lg font-bold text-navy shadow-[var(--shadow-card)] transition-colors hover:bg-brand hover:text-white">
              {g}
            </Link>
          ))}
        </div>
      </section>

      {/* Initiatives */}
      <section aria-labelledby="in" className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h2 id="in" className="section-title">{t.home.initiatives}</h2>
          <Link href="/initiatives" className="pill min-h-9">{t.common.viewAll}</Link>
        </div>
        {initiatives.length === 0 ? <Empty>{t.home.initiativesEmpty}</Empty> : (
          <ul className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-1 [scrollbar-width:none]">
            {initiatives.map((i) => (
              <li key={i.id} className="w-64 shrink-0">
                <Link href={`/initiatives/${i.id}`} className="card flex h-full flex-col gap-3">
                  <span className={`chip self-start ${CAT_TONE[i.category] ?? "bg-navy-100 text-navy"}`}>{t.initiative[`cat_${i.category}` as keyof typeof t.initiative]}</span>
                  <span className="font-bold leading-6 text-navy">{pick(locale, i.title_ar, i.title_en)}</span>
                  <span className="mt-auto text-xs text-muted">{i.organizer_name}</span>
                  {i.is_demo && <DemoBadge t={t} />}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* Awareness */}
      <section aria-labelledby="aw" className="flex flex-col gap-3">
        <h2 id="aw" className="section-title">{t.home.awarenessShort}</h2>
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
          {([[SparkIcon, t.home.aware1Title, t.home.aware1], [ShieldIcon, t.home.aware2Title, t.home.aware2], [DropIcon, t.home.aware3Title, t.home.aware3]] as const).map(([Icon, h, p]) => (
            <div key={h} className="card flex gap-4">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-surface-2 text-navy"><Icon className="h-5 w-5" /></span>
              <div><h3 className="text-base font-bold text-navy">{h}</h3><p className="mt-0.5 text-sm text-muted">{p}</p></div>
            </div>
          ))}
        </div>
        <MedicalNotice t={t} />
      </section>
    </div>
  );
}
