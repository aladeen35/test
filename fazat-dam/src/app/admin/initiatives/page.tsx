import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDate, pick } from "@/lib/format";
import { reviewInitiative } from "@/app/actions/admin";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, Empty, PageHeader } from "@/components/ui";
import { DocLink } from "@/components/doc-link";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.initiatives };
}

const ACTIONS: Record<string, string[]> = {
  submitted: ["under_review", "approved", "rejected"],
  under_review: ["approved", "rejected"],
  approved: ["completed", "archived"],
  completed: ["archived"],
  rejected: ["archived"],
};

export default async function AdminInitiatives({ searchParams }: PageProps<"/admin/initiatives">) {
  const { t, locale } = await getDict();
  await requireAdmin();
  const status = (await searchParams).status;
  const supabase = await createClient();
  let q = supabase.from("humanitarian_initiatives").select("*, initiative_documents(id, storage_path, file_name)").neq("status", "draft").order("created_at", { ascending: false }).limit(100);
  if (typeof status === "string" && status) q = q.eq("status", status);
  const { data } = await q;
  const label = (s: string) => t.initiative[`st_${s}` as "st_draft"];
  return (
    <div>
      <PageHeader title={t.admin.initiatives} />
      <nav className="mb-3 flex flex-wrap gap-2 text-sm">
        {["", "submitted", "under_review", "approved", "rejected", "completed", "archived"].map((s) => (
          <Link key={s} href={s ? `?status=${s}` : "?"} className={`rounded-full px-3 py-1 font-semibold ${status === s || (!status && !s) ? "bg-navy text-white" : "bg-white"}`}>{s ? label(s) : t.common.all}</Link>
        ))}
      </nav>
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <ul className="flex flex-col gap-3">
          {data!.map((i) => (
            <li key={i.id} className="card flex flex-col gap-2">
              <div className="flex flex-wrap items-center gap-2">
                <Link href={`/initiatives/${i.id}`} className="font-bold text-navy underline-offset-4 hover:underline">{pick(locale, i.title_ar, i.title_en)}</Link>
                <Chip tone={i.status === "approved" ? "green" : i.status === "rejected" ? "red" : "amber"}>{label(i.status)}</Chip>
                <Chip>{i.country_code}</Chip>
                <Chip tone="red">{t.initiative[`cat_${i.category}` as "cat_blood_drive"]}</Chip>
                <span className="text-xs text-muted">{fmtDate(i.created_at, locale)}</span>
              </div>
              <p className="text-sm">{i.organizer_name} · {i.organizer_contact ?? "—"}</p>
              <p className="line-clamp-3 text-sm text-muted">{i.description}</p>
              <div className="flex flex-wrap gap-3">{(i.initiative_documents ?? []).map((d: { id: string; storage_path: string; file_name: string }) => <DocLink key={d.id} bucket="initiative-documents" path={d.storage_path} name={d.file_name} />)}</div>
              {i.review_note && <p className="text-sm"><strong>{t.initiative.reviewNote}:</strong> {i.review_note}</p>}
              {(ACTIONS[i.status] ?? []).length > 0 && (
                <ActionForm action={reviewInitiative} className="flex flex-wrap gap-2">
                  <input type="hidden" name="id" value={i.id} />
                  <input name="note" className="input flex-1" placeholder={t.common.reason} aria-label={t.common.reason} />
                  {ACTIONS[i.status].map((s) => <SubmitButton key={s} name="status" value={s} className={s === "approved" ? "btn-primary" : "btn-outline"}>{label(s)}</SubmitButton>)}
                </ActionForm>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
