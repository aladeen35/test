import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { getCities, cityMap } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { cityName, fmtDate, fmtDateTime } from "@/lib/format";
import { TIMEZONE } from "@/lib/constants";
import { registerInstitution } from "@/app/actions/community";
import { confirmDonation } from "@/app/actions/requests";
import { ActionForm, CountryCitySelect, SubmitButton } from "@/components/forms";
import { BloodChip, Chip, Empty, Field, Notice, PageHeader, StatusBadge } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.nav.institution };
}

export default async function InstitutionPage() {
  const { t, locale } = await getDict();
  const viewer = await requireViewer("/institution");
  const supabase = await createClient();
  const [{ data: mine }, cities, cmap] = await Promise.all([
    supabase.from("institutions").select("id, type, name_ar, name_en, status, review_note, country_code, city_id").order("created_at", { ascending: false }),
    getCities(), cityMap(),
  ]);
  const approved = (mine ?? []).filter((i) => i.status === "approved");
  const ids = approved.map((i) => i.id);
  const [{ data: assigned }, { data: pending }] = ids.length && viewer.roles.includes("institution_staff") ? await Promise.all([
    supabase.from("blood_requests").select("id, reference, blood_group, status, urgency, required_by, hospital_name, country_code").in("institution_id", ids)
      .not("status", "in", "(completed,rejected,cancelled,expired)").order("required_by"),
    supabase.from("donation_records").select("id, donated_on, units, request_id, blood_requests(reference)").in("institution_id", ids).eq("status", "pending_confirmation"),
  ]) : [{ data: [] }, { data: [] }];

  return (
    <div className="flex flex-col gap-5">
      <PageHeader title={t.institution.title} intro={t.institution.registerIntro} />
      {(mine ?? []).map((i) => (
        <div key={i.id} className="card flex flex-wrap items-center gap-2">
          <span className="font-bold text-navy">{locale === "ar" ? i.name_ar : i.name_en || i.name_ar}</span>
          <Chip>{t.institution[`type_${i.type as "hospital"}`]}</Chip>
          <Chip>{cityName(cmap.get(i.city_id), locale)}</Chip>
          <Chip tone={i.status === "approved" ? "green" : i.status === "pending" ? "amber" : "red"}>{t.institution[`st_${i.status as "pending"}`]}</Chip>
          {i.review_note && <p className="w-full text-sm text-muted">{i.review_note}</p>}
        </div>
      ))}

      {approved.length > 0 && viewer.roles.includes("institution_staff") && (
        <>
          <section className="flex flex-col gap-3">
            <h2 className="section-title">{t.institution.assigned}</h2>
            {(assigned ?? []).length === 0 ? <Empty>{t.institution.assignedEmpty}</Empty> : (
              <ul className="flex flex-col gap-2">
                {assigned!.map((r) => (
                  <li key={r.id}>
                    <Link href={`/admin/requests/${r.id}`} className="card flex items-center gap-3 hover:ring-2 hover:ring-brand-400/30">
                      <BloodChip group={r.blood_group} />
                      <div className="flex flex-1 flex-col">
                        <span className="latin font-bold">{r.reference}</span>
                        <span className="text-xs text-muted">{r.hospital_name} · {fmtDateTime(r.required_by, locale, TIMEZONE[r.country_code as "SA"])}</span>
                      </div>
                      <StatusBadge status={r.status} t={t} />
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </section>
          <section className="flex flex-col gap-3">
            <h2 className="section-title">{t.institution.toConfirm}</h2>
            {(pending ?? []).length === 0 ? <Empty>{t.institution.toConfirmEmpty}</Empty> : pending!.map((d) => (
              <div key={d.id} className="card flex flex-wrap items-center gap-3">
                <span className="latin font-bold">{(d.blood_requests as unknown as { reference: string } | null)?.reference}</span>
                <span className="text-sm">{fmtDate(d.donated_on, locale)} · <span className="latin">{d.units}</span> {t.common.units}</span>
                <div className="ms-auto flex gap-2">
                  <ActionForm action={confirmDonation} className="flex"><input type="hidden" name="record_id" value={d.id} /><input type="hidden" name="confirm" value="true" /><SubmitButton className="btn-primary">{t.admin.confirm}</SubmitButton></ActionForm>
                  <ActionForm action={confirmDonation} className="flex"><input type="hidden" name="record_id" value={d.id} /><input type="hidden" name="confirm" value="false" /><SubmitButton className="btn-outline">{t.admin.notCompleted}</SubmitButton></ActionForm>
                </div>
              </div>
            ))}
          </section>
        </>
      )}

      <section className="card flex flex-col gap-3">
        <h2 className="section-title">{t.institution.register}</h2>
        {(mine ?? []).some((i) => i.status === "pending") && <Notice tone="info">{t.institution.pending}</Notice>}
        <ActionForm action={registerInstitution} resetOnSuccess>
          <Field label={t.institution.type} htmlFor="type">
            <select id="type" name="type" className="input" required>
              <option value="hospital">{t.institution.type_hospital}</option>
              <option value="blood_bank">{t.institution.type_blood_bank}</option>
            </select>
          </Field>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label={t.institution.nameAr} htmlFor="name_ar"><input id="name_ar" name="name_ar" className="input" required minLength={2} maxLength={160} /></Field>
            <Field label={t.institution.nameEn} htmlFor="name_en"><input id="name_en" name="name_en" dir="ltr" className="input" maxLength={160} /></Field>
          </div>
          <CountryCitySelect cities={cities} defaultCountry={viewer.countryCode} defaultCity={viewer.cityId} />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label={t.institution.license} htmlFor="license"><input id="license" name="license" className="input latin" required maxLength={80} /></Field>
            <Field label={t.institution.contactPhone} htmlFor="contact_phone"><input id="contact_phone" name="contact_phone" className="input latin" inputMode="tel" maxLength={20} /></Field>
          </div>
          <Field label={t.institution.contactEmail} htmlFor="contact_email"><input id="contact_email" name="contact_email" type="email" className="input latin" /></Field>
          <Field label={t.institution.address} htmlFor="address"><input id="address" name="address" className="input" maxLength={300} /></Field>
          <Field label={t.institution.documents} hint={t.request.documentsHint} htmlFor="documents">
            <input id="documents" name="documents" type="file" multiple required accept="application/pdf,image/jpeg,image/png,image/webp" className="input py-2" />
          </Field>
          <SubmitButton className="btn-navy self-start">{t.common.submit}</SubmitButton>
        </ActionForm>
      </section>
    </div>
  );
}
