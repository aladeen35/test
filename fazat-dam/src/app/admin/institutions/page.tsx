import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { cityMap } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { cityName, fmtDate } from "@/lib/format";
import { reviewInstitution, setInstitutionMember } from "@/app/actions/admin";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, Empty, PageHeader } from "@/components/ui";
import { DocLink } from "@/components/doc-link";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.institutions };
}

export default async function AdminInstitutions() {
  const { t, locale } = await getDict();
  await requireAdmin();
  const supabase = await createClient();
  const [{ data }, cmap] = await Promise.all([
    supabase.from("institutions").select("*, institution_documents(id, storage_path, file_name), institution_members(user_id, title, is_active)").order("status").order("created_at", { ascending: false }),
    cityMap(),
  ]);
  return (
    <div>
      <PageHeader title={t.admin.institutions} />
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <ul className="flex flex-col gap-3">
          {data!.map((i) => (
            <li key={i.id} className="card flex flex-col gap-2">
              <div className="flex flex-wrap items-center gap-2">
                <span className="font-bold">{i.name_ar}{i.name_en ? ` / ${i.name_en}` : ""}</span>
                <Chip>{t.institution[`type_${i.type as "hospital"}`]}</Chip>
                <Chip>{i.country_code} · {cityName(cmap.get(i.city_id), locale)}</Chip>
                <Chip tone={i.status === "approved" ? "green" : i.status === "pending" ? "amber" : "red"}>{t.institution[`st_${i.status as "pending"}`]}</Chip>
                <span className="text-xs text-muted">{fmtDate(i.created_at, locale)}</span>
              </div>
              <p className="text-sm text-muted">{t.institution.license}: <span className="latin">{i.license_number ?? "—"}</span> · {i.address ?? ""} · <span className="latin">{i.contact_phone ?? ""} {i.contact_email ?? ""}</span></p>
              <div className="flex flex-wrap gap-3">
                {(i.institution_documents ?? []).map((d: { id: string; storage_path: string; file_name: string }) => <DocLink key={d.id} bucket="institution-documents" path={d.storage_path} name={d.file_name} />)}
                {(i.institution_documents ?? []).length === 0 && <span className="text-sm text-muted">{t.admin.noDocuments}</span>}
              </div>
              <ActionForm action={reviewInstitution} className="flex flex-wrap gap-2">
                <input type="hidden" name="id" value={i.id} />
                <input name="note" className="input flex-1" placeholder={t.common.reason} aria-label={t.common.reason} />
                <SubmitButton name="approve" value="true" className="btn-primary">{t.common.approve}</SubmitButton>
                <SubmitButton name="approve" value="false" className="btn-outline">{t.common.reject}</SubmitButton>
              </ActionForm>
              {i.status === "approved" && (
                <details>
                  <summary className="cursor-pointer text-sm font-semibold">{t.admin.members} (<span className="latin">{(i.institution_members ?? []).filter((m: { is_active: boolean }) => m.is_active).length}</span>)</summary>
                  <ul className="mt-2 flex flex-col gap-1 text-xs">
                    {(i.institution_members ?? []).map((m: { user_id: string; title: string | null; is_active: boolean }) => (
                      <li key={m.user_id} className="flex items-center gap-2">
                        <code className="latin">{m.user_id}</code> {m.title} {m.is_active ? "✓" : "✕"}
                        {m.is_active && <ActionForm action={setInstitutionMember} className="inline-flex"><input type="hidden" name="institution_id" value={i.id} /><input type="hidden" name="user_id" value={m.user_id} /><input type="hidden" name="active" value="false" /><SubmitButton className="btn-ghost min-h-8 text-xs">{t.admin.revoke}</SubmitButton></ActionForm>}
                      </li>
                    ))}
                  </ul>
                  <ActionForm action={setInstitutionMember} className="mt-2 flex flex-wrap gap-2">
                    <input type="hidden" name="institution_id" value={i.id} />
                    <input name="user_id" className="input latin flex-1" required pattern="[0-9a-f\-]{36}" placeholder={t.admin.addMember} aria-label={t.admin.addMember} />
                    <input name="title" className="input w-40" placeholder="title" aria-label="title" />
                    <SubmitButton className="btn-outline">{t.admin.grant}</SubmitButton>
                  </ActionForm>
                </details>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
