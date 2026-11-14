import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { registerDonor, setAvailability } from "@/app/actions/donor";
import { ActionForm, BloodGroupPicker, CountryCitySelect, SubmitButton } from "@/components/forms";
import { Chip, Field, Notice, PageHeader } from "@/components/ui";
import { CONTACT_METHODS } from "@/lib/constants";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.donor.title };
}

export default async function DonatePage() {
  const { t, locale } = await getDict();
  const viewer = await requireViewer("/donate");
  const supabase = await createClient();
  const [{ data: donor }, { data: profile }, cities] = await Promise.all([
    supabase.from("donor_profiles").select("*").eq("user_id", viewer.id).maybeSingle(),
    supabase.from("profiles").select("full_name, email").eq("id", viewer.id).single(),
    getCities(),
  ]);
  const today = new Date().toISOString().slice(0, 10);
  const suspended = donor?.availability === "temporarily_suspended" && donor.suspended_until >= today;

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={donor ? t.donor.editTitle : t.donor.title} intro={t.donor.intro} />

      {donor && (
        <section className="card flex flex-col gap-3">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm text-muted">{t.donor.alias}:</span>
            <span className="latin font-bold text-navy">{donor.public_alias}</span>
            {donor.is_verified && <Chip tone="green">{t.common.verified}</Chip>}
            <Chip tone={donor.availability === "available" ? "green" : "gray"}>
              {suspended ? `${t.donor.suspended} → ${donor.suspended_until}` : donor.availability === "available" ? t.donor.available : t.donor.unavailable}
            </Chip>
          </div>
          <p className="text-sm text-muted">{t.donor.availabilityHelp}</p>
          <div className="flex flex-wrap items-end gap-3">
            {donor.availability !== "available" && (
              <ActionForm action={setAvailability} className="flex">
                <input type="hidden" name="status" value="available" />
                <SubmitButton className="btn-primary">{t.donor.resume}</SubmitButton>
              </ActionForm>
            )}
            {donor.availability === "available" && (
              <ActionForm action={setAvailability} className="flex">
                <input type="hidden" name="status" value="unavailable" />
                <SubmitButton className="btn-outline">{t.donor.unavailable}</SubmitButton>
              </ActionForm>
            )}
            <ActionForm action={setAvailability} className="flex flex-wrap items-end gap-2">
              <input type="hidden" name="status" value="temporarily_suspended" />
              <Field label={t.donor.suspendUntil} htmlFor="until">
                <input id="until" type="date" name="until" className="input" required min={today} />
              </Field>
              <SubmitButton className="btn-outline">{t.donor.suspendAction}</SubmitButton>
            </ActionForm>
          </div>
        </section>
      )}

      <Notice tone="warn">{t.donor.eligibility}</Notice>

      <section className="card">
        <ActionForm action={registerDonor}>
          <Field label={t.onboarding.fullName} hint={t.onboarding.fullNameHint} htmlFor="full_name">
            <input id="full_name" name="full_name" className="input" required minLength={2} maxLength={120} defaultValue={profile?.full_name ?? ""} />
          </Field>
          <Field label={t.onboarding.contactPhone} hint={t.onboarding.contactPhoneHint}>
            <input className="input latin opacity-80" value={`+${(viewer.phone ?? viewer.contactPhone ?? "").replace(/^\+/, "")}`} readOnly aria-readonly />
          </Field>
          <CountryCitySelect cities={cities} defaultCountry={donor?.country_code ?? viewer.countryCode} defaultCity={donor?.city_id ?? viewer.cityId} />
          <BloodGroupPicker defaultValue={donor?.blood_group} />
          {!donor && (
            <Field label={t.donor.availability} htmlFor="availability">
              <select id="availability" name="availability" className="input" defaultValue="available">
                <option value="available">{t.donor.available}</option>
                <option value="unavailable">{t.donor.unavailable}</option>
              </select>
            </Field>
          )}
          {donor && <input type="hidden" name="availability" value={donor.availability === "temporarily_suspended" ? "unavailable" : donor.availability} />}
          <Field label={t.donor.contactMethod} htmlFor="contact_method">
            <select id="contact_method" name="contact_method" className="input" defaultValue={donor?.contact_method ?? "in_app"}>
              {CONTACT_METHODS.map((m) => <option key={m} value={m}>{t.donor[`contact_${m}`]}</option>)}
            </select>
          </Field>
          <Field label={t.onboarding.language} htmlFor="language">
            <select id="language" name="language" className="input" defaultValue={locale}>
              <option value="ar">العربية</option>
              <option value="en">English</option>
            </select>
          </Field>
          <details className="tile">
            <summary className="cursor-pointer text-sm font-semibold text-navy">{t.common.optional}</summary>
            <div className="mt-3 flex flex-col gap-4">
              <Field label={t.donor.email} htmlFor="email">
                <input id="email" name="email" type="email" className="input latin" defaultValue={profile?.email ?? ""} />
              </Field>
              <Field label={t.donor.facility} htmlFor="facility">
                <input id="facility" name="facility" className="input" maxLength={160} defaultValue={donor?.preferred_facility ?? ""} />
              </Field>
              <Field label={t.donor.lastDonation} htmlFor="last_donation">
                <input id="last_donation" name="last_donation" type="date" className="input" max={today} defaultValue={donor?.last_donation_date ?? ""} />
              </Field>
              <label className="flex items-center gap-3 text-sm">
                <input type="checkbox" name="show_first_name" defaultChecked={donor?.show_first_name ?? false} className="h-5 w-5 accent-[var(--color-brand)]" />
                {t.donor.showFirstName}
              </label>
              <label className="flex items-center gap-3 text-sm">
                <input type="checkbox" name="auto_match" defaultChecked={donor?.accepts_auto_matching ?? true} className="h-5 w-5 accent-[var(--color-brand)]" />
                {t.donor.autoMatch}
              </label>
            </div>
          </details>
          <label className="flex items-start gap-3 text-sm">
            <input type="checkbox" name="consent" required className="mt-1 h-5 w-5 accent-[var(--color-brand)]" />
            <span>{t.donor.consent} <Link href="/privacy" className="underline" target="_blank">{t.nav.privacy}</Link></span>
          </label>
          <SubmitButton>{donor ? t.donor.update : t.donor.register}</SubmitButton>
        </ActionForm>
      </section>
    </div>
  );
}
