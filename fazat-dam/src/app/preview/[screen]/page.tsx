import { notFound } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { WaitScreen } from "@/components/wait-screen";
import { RequestForm } from "@/app/requests/new/request-form";
import { RequestTimeline } from "@/components/request-timeline";
import { BloodChip, Chip, DemoBadge, MedicalNotice, Notice, PageHeader, StatusBadge } from "@/components/ui";
import type { City } from "@/lib/geo";

/**
 * Design preview of screens that normally need a signed-in user and live data.
 * Disabled unless UI_PREVIEW=1 (never enable in production). All sample rows are marked as demo.
 */
const CITIES: City[] = [
  { id: "00000000-0000-0000-0000-000000000001", country_code: "SA", name_ar: "الرياض", name_en: "Riyadh" },
  { id: "00000000-0000-0000-0000-000000000002", country_code: "SA", name_ar: "جدة", name_en: "Jeddah" },
  { id: "00000000-0000-0000-0000-000000000003", country_code: "SD", name_ar: "الخرطوم", name_en: "Khartoum" },
];

export default async function Preview({ params }: PageProps<"/preview/[screen]">) {
  if (process.env.UI_PREVIEW !== "1") notFound();
  const { screen } = await params;
  const { t } = await getDict();

  if (screen === "wait") return <WaitScreen t={t} />;
  if (screen === "request") return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={t.request.newTitle} intro={t.request.newIntro} />
      <RequestForm cities={CITIES} institutions={[]} defaultCountry="SA" defaultCity={CITIES[0].id} />
    </div>
  );
  if (screen === "donors") return (
    <div className="flex flex-col gap-4">
      <PageHeader title={t.search.title} intro={t.search.intro} />
      <ul className="grid grid-cols-1 gap-3 md:grid-cols-3">
        {[["D-7K3QX", "O+", true, true], ["D-M4P9R", "O+", true, false], ["سارة · D-Q2W8N", "A-", false, false]].map(([name, g, av, ver]) => (
          <li key={String(name)} className="card flex flex-col gap-3">
            <div className="flex items-center gap-3"><BloodChip group={String(g)} size="lg" />
              <div className="flex flex-col gap-1"><span className="latin font-bold text-navy" dir="auto">{String(name)}</span><span className="text-sm text-muted">{CITIES[0].name_ar}</span></div></div>
            <div className="flex flex-wrap gap-2">
              <Chip tone={av ? "green" : "gray"}>{av ? t.common.available : t.common.unavailable}</Chip>
              {ver && <Chip>{t.common.verified}</Chip>}<DemoBadge t={t} />
            </div>
            {av && <button className="btn-navy">{t.search.sendRequest}</button>}
          </li>
        ))}
      </ul>
    </div>
  );
  if (screen === "track") return (
    <div className="flex flex-col gap-4">
      <div className="card flex flex-wrap items-center gap-4">
        <BloodChip group="O+" size="lg" />
        <div className="flex flex-1 flex-col gap-1">
          <div className="flex flex-wrap items-center gap-2"><h1 className="latin text-xl font-bold text-navy">FD-SA-2611-7K3QX</h1>
            <StatusBadge status="donors_responding" t={t} /><Chip tone="amber">{t.request.urgency_urgent}</Chip><DemoBadge t={t} /></div>
          <p className="text-sm text-navy">مستشفى تجريبي · الرياض</p>
        </div>
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <section className="card"><h2 className="section-title mb-2">{t.request.timeline}</h2><RequestTimeline status="donors_responding" t={t} /></section>
        <section className="flex flex-col gap-3 lg:col-span-2">
          <h2 className="section-title">{t.request.matches}</h2>
          <article className="card flex flex-col gap-3">
            <div className="flex flex-wrap items-center gap-2"><span className="latin font-bold">D-7K3QX</span><Chip tone="green">{t.match.accepted}</Chip><Chip>{t.match.automated}</Chip></div>
            <Notice>{t.match.contactHidden}</Notice>
            <button className="btn-primary self-start">{t.match.requestContact}</button>
          </article>
          <article className="card flex items-center gap-2"><span className="latin font-bold">D-M4P9R</span><Chip tone="amber">{t.match.pending}</Chip></article>
        </section>
      </div>
      <MedicalNotice t={t} />
    </div>
  );
  notFound();
}
