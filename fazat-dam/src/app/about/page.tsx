import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { MedicalNotice } from "@/components/ui";
import { CheckIcon, ShieldIcon } from "@/components/icons";
import { CopyButton, ShareButton } from "@/components/share-link";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.nav.about };
}

const SITE = "https://albushra.app/";
const PLAY = "https://play.google.com/store/apps/details?id=sa.mushaf.albushra";
const APP_ICON = "https://albushra.app/icons/fazatdam.webp";
const VERSION = "1.0.0"; // android-twa versionName
const CONTACT = process.env.NEXT_PUBLIC_CONTACT_EMAIL || "aladeen35@gmail.com";

const svg = { width: 20, height: 20, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 2, strokeLinecap: "round" as const, strokeLinejoin: "round" as const, "aria-hidden": true };

function Section({ title, hint, children }: { title: string; hint: string; children: React.ReactNode }) {
  return (
    <section className="flex flex-col gap-3">
      <div>
        <h2 className="section-title border-s-4 border-brand ps-3">{title}</h2>
        <p className="ps-4 text-xs text-muted">{hint}</p>
      </div>
      {children}
    </section>
  );
}

export default async function AboutPage() {
  const { t } = await getDict();
  const d = t.dev;
  const stats: [number, string][] = [[23, d.statProducts], [18, d.statAndroid], [7, d.statGames], [15, d.statWeb]];
  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <div>
        <h1 className="page-title">{t.nav.about}</h1>
        <p className="mt-1.5 text-sm text-muted">{d.subtitle}</p>
      </div>

      {/* Developer card */}
      <section className="card-dark flex flex-col items-center gap-3 text-center">
        <span className="flex h-28 w-28 items-center justify-center rounded-full bg-white p-2 shadow-[0_0_0_3px_rgb(255_255_255/0.15)]">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/brand/albushra-full.png" alt="" width={96} height={96} className="h-24 w-24 rounded-full object-contain" />
        </span>
        <div>
          <h2 className="text-2xl font-bold">{d.company}</h2>
          <p className="latin text-sm text-white/70">Albushra Technology</p>
        </div>
        <span className="inline-flex items-center gap-2 rounded-full border border-sand/50 bg-white/5 px-4 py-1.5 text-sm font-semibold text-sand">
          <svg {...svg} width={18} height={18}><path d="M8 7l-5 5 5 5" /><path d="M16 7l5 5-5 5" /></svg>
          {d.supervisor}
        </span>
        <p className="flex w-full items-center gap-3 rounded-2xl bg-white/5 px-4 py-3 text-start text-sm font-bold">
          <svg {...svg} width={22} height={22} className="shrink-0 text-brand"><path d="M12 21s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 5.6-7 10-7 10z" fill="currentColor" /></svg>
          {d.dedication}
        </p>
        <p className="text-sm leading-7 text-white/80">{d.companyDesc}</p>
      </section>

      {/* This app */}
      <Section title={d.appTitle} hint={d.appHint}>
        <div className="card flex items-center gap-4">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={APP_ICON} alt="" width={60} height={60} className="h-15 w-15 shrink-0 rounded-2xl bg-surface-2 object-contain" />
          <div className="min-w-0">
            <h3 className="text-lg font-bold text-navy">{t.meta.name}</h3>
            <p className="text-sm text-muted">{d.appTagline}</p>
            <p className="latin text-xs text-muted" dir="ltr">v{VERSION}</p>
          </div>
        </div>
        <div className="card flex flex-col gap-3 text-sm leading-7">
          <p>{t.meta.description}</p>
          <p>{t.home.networkNote}</p>
          <p>{t.legal.crossBorder}</p>
          <p>{t.legal.free}</p>
        </div>
        <MedicalNotice t={t} />
      </Section>

      {/* Links */}
      <Section title={d.linksTitle} hint={d.linksHint}>
        <a href={SITE} target="_blank" rel="noopener" className="btn-navy min-h-14 w-full px-4 text-center">
          <svg {...svg}><path d="M14 4h6v6" /><path d="M20 4l-9 9" /><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5" /></svg>
          {d.visitSite}
        </a>
        <div className="grid grid-cols-2 gap-3">
          <a href={PLAY} target="_blank" rel="noopener" className="btn-outline min-h-14 w-full px-3">
            <svg {...svg} className="text-brand"><path d="M5 3.5l14 8.5-14 8.5z" fill="currentColor" /></svg>
            <span className="latin">Google Play</span>
          </a>
          <ShareButton url={SITE} title={d.company} />
        </div>
        <div className="card flex items-center gap-3 py-3">
          <svg {...svg} width={22} height={22} className="shrink-0 text-brand"><path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1" /><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1" /></svg>
          <div className="min-w-0 flex-1">
            <small className="block text-xs text-muted">{d.siteLabel}</small>
            <b className="latin block truncate text-navy" dir="ltr">https://albushra.app</b>
          </div>
          <CopyButton url={SITE} />
        </div>
      </Section>

      {/* Ecosystem numbers */}
      <Section title={d.statsTitle} hint={d.statsHint}>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {stats.map(([n, label]) => (
            <div key={label} className="card flex flex-col items-center gap-1 py-4 text-center">
              <span className="latin text-3xl font-bold text-brand">{n}</span>
              <span className="text-xs text-muted">{label}</span>
            </div>
          ))}
        </div>
      </Section>

      {/* Privacy and contact */}
      <Section title={d.contactTitle} hint={d.contactHint}>
        <Link href="/privacy" className="btn-outline min-h-14 w-full">
          <ShieldIcon className="h-5 w-5 text-brand" />
          {t.nav.privacy}
        </Link>
        <a href={`mailto:${CONTACT}`} className="btn-outline min-h-14 w-full">
          <svg {...svg} className="text-brand"><rect x="3" y="5" width="18" height="14" rx="2" /><path d="M3.5 6l8.5 7 8.5-7" /></svg>
          <span className="latin" dir="ltr">{CONTACT}</span>
        </a>
        <ul className="flex flex-col gap-2 text-sm">
          {[t.profile.privacyText].map((line) => (
            <li key={line} className="tile flex items-start gap-2.5 py-3">
              <CheckIcon className="mt-1 h-4 w-4 shrink-0 text-success" />
              <span>{line}</span>
            </li>
          ))}
        </ul>
      </Section>

      <p className="text-center text-xs text-muted">
        {d.rights} · <a href={SITE} className="font-semibold text-brand-600" target="_blank" rel="noopener">albushra.app</a>
      </p>
    </div>
  );
}
