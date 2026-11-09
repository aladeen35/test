import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { cityMap } from "@/lib/geo";
import { cityName, fmtDate, pick } from "@/lib/format";
import { Chip, DemoBadge, Empty, Notice, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.initiative.title };
}

export default async function InitiativesPage({ searchParams }: PageProps<"/initiatives">) {
  const { t, locale } = await getDict();
  const sp = await searchParams;
  const country = sp.country === "SD" || sp.country === "SA" ? sp.country : null;
  let rows: { id: string; category: string; title_ar: string; title_en: string | null; description: string; organizer_name: string; country_code: string; city_id: string | null; start_date: string; end_date: string | null; status: string; is_demo: boolean }[] = [];
  const cities = await cityMap();
  if (isSupabaseConfigured()) {
    const supabase = await createClient();
    let q = supabase.from("public_initiatives").select("*").order("status").order("start_date", { ascending: false }).limit(60);
    if (country) q = q.eq("country_code", country);
    rows = (await q).data ?? [];
  }
  return (
    <div className="flex flex-col gap-4">
      <PageHeader title={t.initiative.title} intro={t.initiative.intro}
        action={<div className="flex gap-2"><Link href="/initiatives/mine" className="btn-outline min-h-10 text-sm">{t.initiative.mine}</Link><Link href="/initiatives/new" className="btn-primary min-h-10 text-sm">{t.initiative.submitNew}</Link></div>} />
      <Notice>{t.initiative.expatNote}</Notice>
      <nav className="flex gap-2 text-sm">
        {[["", t.common.all], ["SD", t.common.sudan], ["SA", t.common.saudi]].map(([c, label]) => (
          <Link key={c} href={c ? `/initiatives?country=${c}` : "/initiatives"} aria-current={(country ?? "") === c ? "page" : undefined}
            className={`rounded-full px-3 py-1.5 font-semibold ${(country ?? "") === c ? "bg-navy text-white" : "bg-white text-navy"}`}>{label}</Link>
        ))}
      </nav>
      {rows.length === 0 ? <Empty>{t.initiative.empty}</Empty> : (
        <ul className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3">
          {rows.map((i) => (
            <li key={i.id}>
              <Link href={`/initiatives/${i.id}`} className="card flex h-full flex-col gap-2 hover:ring-2 hover:ring-brand-400/30">
                <div className="flex flex-wrap gap-2">
                  <Chip tone="red">{t.initiative[`cat_${i.category}` as "cat_blood_drive"]}</Chip>
                  <Chip>{i.country_code === "SD" ? t.common.sudan : t.common.saudi}{i.city_id ? ` · ${cityName(cities.get(i.city_id), locale)}` : ""}</Chip>
                  {i.status === "completed" && <Chip tone="green">{t.initiative.st_completed}</Chip>}
                  {i.is_demo && <DemoBadge t={t} />}
                </div>
                <h2 className="font-bold text-navy">{pick(locale, i.title_ar, i.title_en)}</h2>
                <p className="line-clamp-3 text-sm text-muted">{i.description}</p>
                <p className="mt-auto text-xs text-muted">{i.organizer_name} · {fmtDate(i.start_date, locale)}{i.end_date ? ` – ${fmtDate(i.end_date, locale)}` : ""}</p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
