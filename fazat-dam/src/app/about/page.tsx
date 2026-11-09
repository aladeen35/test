import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { MedicalNotice, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.nav.about };
}

export default async function AboutPage() {
  const { t } = await getDict();
  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-4">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/brand/logo-full.png" alt={`${t.meta.name} — ${t.meta.slogan}`} className="mx-auto w-56" width={495} height={510} />
      <PageHeader title={t.nav.about} intro={t.meta.description} />
      <div className="card flex flex-col gap-3 text-sm leading-7">
        <p>{t.home.intro}</p>
        <p>{t.home.networkNote}</p>
        <p>{t.legal.crossBorder}</p>
        <p>{t.legal.free}</p>
      </div>
      <p className="card text-center text-sm font-semibold text-navy">{t.common.designedBy}</p>
      <MedicalNotice t={t} />
    </div>
  );
}
