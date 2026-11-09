import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDateTime } from "@/lib/format";
import { resolveReport } from "@/app/actions/admin";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, Empty, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.reports };
}

export default async function AdminReports() {
  const { t, locale } = await getDict();
  await requireAdmin();
  const supabase = await createClient();
  const { data } = await supabase.from("reports").select("*").order("status").order("created_at", { ascending: false }).limit(100);
  return (
    <div>
      <PageHeader title={t.admin.reports} />
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <ul className="flex flex-col gap-2">
          {data!.map((r) => (
            <li key={r.id} className="card flex flex-col gap-2">
              <div className="flex flex-wrap items-center gap-2">
                <Chip tone="red">{t.report[r.reason as "fraud"]}</Chip>
                <Chip>{r.target_type}</Chip>
                <Chip tone={r.status === "open" ? "amber" : "gray"}>{r.status}</Chip>
                <span className="text-xs text-muted">{fmtDateTime(r.created_at, locale)}</span>
              </div>
              <p className="text-xs text-muted">{t.admin.target}: <code className="latin">{r.target_id}</code> · reporter: <code className="latin">{r.reporter_id}</code></p>
              {r.details && <p className="text-sm">{r.details}</p>}
              {r.resolution_note && <p className="text-sm text-muted">{r.resolution_note}</p>}
              {(r.status === "open" || r.status === "reviewing") && (
                <ActionForm action={resolveReport} className="flex flex-wrap gap-2">
                  <input type="hidden" name="id" value={r.id} />
                  <input name="note" className="input flex-1" placeholder={t.common.notes} aria-label={t.common.notes} />
                  <SubmitButton name="status" value="resolved" className="btn-navy">{t.admin.resolve}</SubmitButton>
                  <SubmitButton name="status" value="dismissed" className="btn-outline">{t.admin.dismiss}</SubmitButton>
                </ActionForm>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
