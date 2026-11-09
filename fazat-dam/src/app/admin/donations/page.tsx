import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDate } from "@/lib/format";
import { confirmDonation } from "@/app/actions/requests";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, DemoBadge, Empty, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.donations };
}

export default async function AdminDonations() {
  const { t, locale } = await getDict();
  await requireAdmin();
  const supabase = await createClient();
  const { data } = await supabase.from("donation_records").select("id, status, donated_on, units, request_id, is_demo, blood_requests(reference)").order("status", { ascending: false }).order("created_at", { ascending: false }).limit(100);
  return (
    <div>
      <PageHeader title={t.admin.donations} />
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <ul className="flex flex-col gap-2">
          {data!.map((d) => (
            <li key={d.id} className="card flex flex-wrap items-center gap-3">
              <Link href={`/admin/requests/${d.request_id}`} className="latin font-bold underline-offset-4 hover:underline">{(d.blood_requests as unknown as { reference: string } | null)?.reference ?? "—"}</Link>
              <span className="text-sm">{fmtDate(d.donated_on, locale)} · <span className="latin">{d.units}</span> {t.common.units}</span>
              <Chip tone={d.status === "confirmed" ? "green" : d.status === "pending_confirmation" ? "amber" : "gray"}>
                {d.status === "confirmed" ? t.match.donationConfirmed : d.status === "pending_confirmation" ? t.match.donationPending : t.match.donationNotCompleted}
              </Chip>
              {d.is_demo && <DemoBadge t={t} />}
              {d.status === "pending_confirmation" && (
                <div className="ms-auto flex gap-2">
                  <ActionForm action={confirmDonation} className="flex"><input type="hidden" name="record_id" value={d.id} /><input type="hidden" name="confirm" value="true" /><SubmitButton>{t.admin.confirm}</SubmitButton></ActionForm>
                  <ActionForm action={confirmDonation} className="flex"><input type="hidden" name="record_id" value={d.id} /><input type="hidden" name="confirm" value="false" /><SubmitButton className="btn-outline">{t.admin.notCompleted}</SubmitButton></ActionForm>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
