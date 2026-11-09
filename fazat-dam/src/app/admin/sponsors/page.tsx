import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { pick } from "@/lib/format";
import { linkSponsorship, reviewSponsor, uploadSponsorLogo } from "@/app/actions/admin";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, Empty, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.sponsors };
}

export default async function AdminSponsors() {
  const { t, locale } = await getDict();
  await requireAdmin();
  const supabase = await createClient();
  const [{ data }, { data: initiatives }] = await Promise.all([
    supabase.from("sponsors").select("*").order("status").order("created_at", { ascending: false }),
    supabase.from("humanitarian_initiatives").select("id, title_ar, title_en").in("status", ["approved", "completed"]).order("created_at", { ascending: false }),
  ]);
  const approved = (data ?? []).filter((s) => s.status === "approved");
  const logoBase = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/sponsor-logos/`;
  return (
    <div className="flex flex-col gap-4">
      <PageHeader title={t.admin.sponsors} />
      {(data ?? []).length === 0 ? <Empty>{t.admin.noData}</Empty> : (
        <ul className="flex flex-col gap-3">
          {data!.map((s) => (
            <li key={s.id} className="card flex flex-col gap-2">
              <div className="flex flex-wrap items-center gap-2">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                {s.logo_path && <img src={logoBase + s.logo_path} alt="" className="h-10 w-10 object-contain" />}
                <span className="font-bold">{pick(locale, s.name_ar, s.name_en)}</span>
                <Chip>{t.sponsor[`type_${s.type}` as "type_corporate"]}</Chip>
                <Chip tone={s.status === "approved" ? "green" : s.status === "pending" ? "amber" : "red"}>{t.institution[`st_${s.status as "pending"}`]}</Chip>
                {s.website && <a href={s.website} className="latin text-xs underline" target="_blank" rel="noopener noreferrer">{s.website}</a>}
              </div>
              {s.description && <p className="text-sm text-muted">{s.description}</p>}
              <ActionForm action={reviewSponsor} className="flex flex-wrap gap-2">
                <input type="hidden" name="id" value={s.id} />
                <input name="note" className="input flex-1" placeholder={t.common.reason} aria-label={t.common.reason} />
                <SubmitButton name="approve" value="true" className="btn-primary">{t.common.approve}</SubmitButton>
                <SubmitButton name="approve" value="false" className="btn-outline">{t.common.reject}</SubmitButton>
              </ActionForm>
              <ActionForm action={uploadSponsorLogo} className="flex flex-wrap gap-2">
                <input type="hidden" name="sponsor_id" value={s.id} />
                <input type="file" name="logo" accept="image/png,image/jpeg,image/webp" required className="input flex-1 py-2" aria-label="logo" />
                <SubmitButton className="btn-outline">{t.common.save}</SubmitButton>
              </ActionForm>
            </li>
          ))}
        </ul>
      )}
      {approved.length > 0 && (initiatives ?? []).length > 0 && (
        <section className="card flex flex-col gap-2">
          <h2 className="section-title">{t.admin.sponsorships}</h2>
          <ActionForm action={linkSponsorship}>
            <select name="sponsor_id" className="input" required aria-label={t.admin.sponsors}>{approved.map((s) => <option key={s.id} value={s.id}>{pick(locale, s.name_ar, s.name_en)}</option>)}</select>
            <select name="initiative_id" className="input" required aria-label={t.admin.initiatives}>{initiatives!.map((i) => <option key={i.id} value={i.id}>{pick(locale, i.title_ar, i.title_en)}</option>)}</select>
            <input name="note" className="input" maxLength={500} placeholder={t.common.notes} aria-label={t.common.notes} />
            <SubmitButton className="btn-navy self-start">{t.common.save}</SubmitButton>
          </ActionForm>
        </section>
      )}
    </div>
  );
}
