import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDateTime } from "@/lib/format";
import { Empty, PageHeader } from "@/components/ui";
import { sp } from "../params";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.audit };
}

const ENTITIES = ["blood_requests", "donor_matches", "donation_records", "profiles", "user_roles", "institutions", "humanitarian_initiatives", "sponsors", "reports", "notifications", "cities", "app_settings"];

export default async function AdminAudit({ searchParams }: PageProps<"/admin/audit">) {
  const { t, locale } = await getDict();
  await requireAdmin();
  const entity = sp((await searchParams).entity);
  const supabase = await createClient();
  let q = supabase.from("audit_logs").select("id, actor_id, action, entity_type, entity_id, new_data, old_data, created_at").order("created_at", { ascending: false }).limit(200);
  if (entity && ENTITIES.includes(entity)) q = q.eq("entity_type", entity);
  const { data } = await q;
  return (
    <div>
      <PageHeader title={t.admin.audit} />
      <form method="get" className="card mb-3 flex gap-2">
        <select name="entity" className="input flex-1" defaultValue={entity ?? ""} aria-label={t.admin.entity}>
          <option value="">{t.common.all}</option>{ENTITIES.map((e) => <option key={e} value={e}>{e}</option>)}
        </select>
        <button className="btn-navy">{t.common.apply}</button>
      </form>
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <div className="card overflow-x-auto">
          <table className="w-full min-w-[720px] text-xs">
            <thead><tr className="text-muted"><th className="py-2 text-start">{t.common.date}</th><th className="text-start">{t.admin.action}</th><th className="text-start">{t.admin.entity}</th><th className="text-start">{t.admin.actor}</th><th className="text-start">{t.common.details}</th></tr></thead>
            <tbody>
              {data!.map((a) => {
                const changed = a.old_data && a.new_data
                  ? Object.keys(a.new_data).filter((k) => k !== "updated_at" && JSON.stringify(a.new_data[k]) !== JSON.stringify(a.old_data[k])).map((k) => `${k}: ${JSON.stringify(a.old_data[k])} → ${JSON.stringify(a.new_data[k])}`).join("; ")
                  : a.action === "insert" ? "" : JSON.stringify(a.new_data ?? {}).slice(0, 160);
                return (
                  <tr key={a.id} className="border-t border-line align-top">
                    <td className="py-1.5 whitespace-nowrap">{fmtDateTime(a.created_at, locale)}</td>
                    <td className="latin font-semibold">{a.action}</td>
                    <td className="latin">{a.entity_type}<br /><span className="text-muted">{a.entity_id?.slice(0, 8)}</span></td>
                    <td className="latin text-muted">{a.actor_id?.slice(0, 8) ?? "system"}</td>
                    <td className="latin max-w-md break-words">{changed}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
