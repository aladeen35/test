import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDate } from "@/lib/format";
import { ROLES, type Role } from "@/lib/constants";
import { setAccountStatus, setRole } from "@/app/actions/admin";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, DemoBadge, Empty, PageHeader } from "@/components/ui";
import { sp } from "../params";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.users };
}

type U = { id: string; full_name: string | null; phone: string | null; country_code: string | null; account_status: string; roles: Role[]; created_at?: string; is_demo?: boolean };

export default async function AdminUsers({ searchParams }: PageProps<"/admin/users">) {
  const { t, locale } = await getDict();
  const me = await requireAdmin();
  const q = sp((await searchParams).q);
  const supabase = await createClient();
  let users: U[] = [];
  if (q && q.trim().length >= 3) {
    users = ((await supabase.rpc("admin_find_user", { p_query: q })).data ?? []) as U[];
  } else {
    const { data } = await supabase.from("profiles").select("id, full_name, phone, country_code, account_status, created_at, is_demo, user_roles(role)").order("created_at", { ascending: false }).limit(50);
    users = (data ?? []).map((p) => ({ ...p, roles: (p.user_roles as { role: Role }[]).map((r) => r.role) }));
  }
  return (
    <div>
      <PageHeader title={t.admin.users} />
      <form className="card mb-4 flex gap-2" method="get">
        <input name="q" defaultValue={q} className="input flex-1" placeholder={t.admin.searchUsers} aria-label={t.admin.searchUsers} minLength={3} />
        <button className="btn-navy">{t.common.search}</button>
      </form>
      {users.length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <ul className="flex flex-col gap-2">
          {users.map((u) => (
            <li key={u.id} className="card flex flex-col gap-2">
              <div className="flex flex-wrap items-center gap-2">
                <span className="font-bold">{u.full_name ?? "—"}</span>
                <span className="latin text-sm text-muted">{u.phone ? `+${u.phone}` : ""}</span>
                <Chip>{u.country_code ?? "—"}</Chip>
                <Chip tone={u.account_status === "active" ? "green" : "red"}>{u.account_status}</Chip>
                {u.is_demo && <DemoBadge t={t} />}
                {u.created_at && <span className="text-xs text-muted">{fmtDate(u.created_at, locale)}</span>}
                <code className="latin text-[0.65rem] text-muted">{u.id}</code>
              </div>
              <div className="flex flex-wrap items-center gap-1">
                {ROLES.map((r) => {
                  const has = u.roles.includes(r);
                  return (
                    <ActionForm key={r} action={setRole} className="inline-flex">
                      <input type="hidden" name="user_id" value={u.id} />
                      <input type="hidden" name="role" value={r} />
                      <input type="hidden" name="grant" value={has ? "false" : "true"} />
                      <SubmitButton className={`chip min-h-8 ${has ? "bg-navy text-white" : "border border-line bg-white text-muted"}`} title={has ? t.admin.revoke : t.admin.grant}>
                        {has ? "✓ " : "+ "}{t.profile[`role_${r}`]}
                      </SubmitButton>
                    </ActionForm>
                  );
                })}
              </div>
              {u.id !== me.id && (
                <ActionForm action={setAccountStatus} className="flex flex-wrap gap-2">
                  <input type="hidden" name="user_id" value={u.id} />
                  <input type="hidden" name="status" value={u.account_status === "active" ? "suspended" : "active"} />
                  <input name="note" className="input flex-1" placeholder={t.common.reason} aria-label={t.common.reason} />
                  <SubmitButton className={u.account_status === "active" ? "btn-danger" : "btn-outline"}>{u.account_status === "active" ? t.admin.suspend : t.admin.restore}</SubmitButton>
                </ActionForm>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
