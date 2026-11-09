import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDate, pick } from "@/lib/format";
import { Chip, Empty, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.initiative.mine };
}

export default async function MyInitiativesPage() {
  const { t, locale } = await getDict();
  const viewer = await requireViewer("/initiatives/mine");
  const supabase = await createClient();
  const { data } = await supabase.from("humanitarian_initiatives").select("id, title_ar, title_en, status, review_note, created_at").eq("organizer_id", viewer.id).order("created_at", { ascending: false });
  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={t.initiative.mine} action={<Link href="/initiatives/new" className="btn-primary min-h-10 text-sm">{t.initiative.submitNew}</Link>} />
      {(data ?? []).length === 0 ? <Empty>{t.initiative.empty}</Empty> : data!.map((i) => (
        <article key={i.id} className="card flex flex-col gap-2">
          <div className="flex flex-wrap items-center gap-2">
            <Link href={`/initiatives/${i.id}`} className="font-bold text-navy">{pick(locale, i.title_ar, i.title_en)}</Link>
            <Chip tone={i.status === "approved" || i.status === "completed" ? "green" : i.status === "rejected" ? "red" : "amber"}>{t.initiative[`st_${i.status}` as "st_draft"]}</Chip>
          </div>
          <span className="text-xs text-muted">{fmtDate(i.created_at, locale)}</span>
          {i.review_note && <p className="text-sm"><strong>{t.initiative.reviewNote}:</strong> {i.review_note}</p>}
          {(i.status === "draft" || i.status === "rejected") && <Link href={`/initiatives/new?edit=${i.id}`} className="btn-outline self-start min-h-10 text-sm">{t.initiative.resubmit}</Link>}
        </article>
      ))}
    </div>
  );
}
