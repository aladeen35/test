import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { deleteAccount, signOut, updateProfile } from "@/app/actions/account";
import { ActionForm, CountryCitySelect, SubmitButton } from "@/components/forms";
import { Chip, Field, PageHeader } from "@/components/ui";
import { InstallCard } from "@/components/pwa";
import { PushToggle } from "@/components/push-toggle";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.profile.title };
}

export default async function ProfilePage() {
  const { t, locale } = await getDict();
  const viewer = await requireViewer("/profile");
  const supabase = await createClient();
  const [cities, { data: donor }, { count: blocked }] = await Promise.all([
    getCities(),
    supabase.from("donor_profiles").select("public_alias, blood_group, availability, is_verified").eq("user_id", viewer.id).maybeSingle(),
    supabase.from("user_blocks").select("blocked_id", { count: "exact", head: true }),
  ]);
  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={t.profile.title} action={<form action={signOut}><button className="btn-outline min-h-10 text-sm">{t.common.signOut}</button></form>} />

      <section className="card flex flex-col gap-3">
        <h2 className="section-title">{t.profile.personal}</h2>
        <ActionForm action={updateProfile}>
          <Field label={t.onboarding.fullName} htmlFor="full_name">
            <input id="full_name" name="full_name" className="input" required minLength={2} maxLength={120} defaultValue={viewer.fullName ?? ""} />
          </Field>
          <Field label={t.profile.phone}>
            <input className="input latin bg-surface" readOnly value={viewer.phone ? `+${viewer.phone.replace(/^\+/, "")}` : ""} />
          </Field>
          <CountryCitySelect cities={cities} defaultCountry={viewer.countryCode} defaultCity={viewer.cityId} />
          <Field label={t.common.language} htmlFor="language">
            <select id="language" name="language" className="input" defaultValue={locale}>
              <option value="ar">العربية</option>
              <option value="en">English</option>
            </select>
          </Field>
          <SubmitButton className="btn-navy">{t.common.save}</SubmitButton>
        </ActionForm>
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-sm text-muted">{t.profile.roles}:</span>
          {viewer.roles.map((r) => <Chip key={r}>{t.profile[`role_${r}`]}</Chip>)}
        </div>
      </section>

      <section className="card flex flex-col gap-2">
        <h2 className="section-title">{t.profile.donorStatus}</h2>
        {donor ? (
          <div className="flex flex-wrap items-center gap-2">
            <span className="latin font-bold">{donor.public_alias}</span>
            <span className="latin chip bg-brand text-white">{donor.blood_group}</span>
            <Chip tone={donor.availability === "available" ? "green" : "gray"}>{donor.availability === "available" ? t.common.available : t.common.unavailable}</Chip>
            {donor.is_verified && <Chip tone="navy">{t.common.verified}</Chip>}
            <Link href="/donate" className="btn-ghost min-h-10 text-sm">{t.common.edit}</Link>
          </div>
        ) : <p className="text-sm text-muted">{t.profile.notDonor} <Link className="font-semibold text-brand-600" href="/donate">{t.donor.register}</Link></p>}
      </section>

      <section className="card flex flex-col gap-2">
        <h2 className="section-title">{t.notifications.title}</h2>
        <PushToggle />
      </section>

      <section className="card flex flex-col gap-2">
        <h2 className="section-title">{t.profile.privacy}</h2>
        <p className="text-sm text-muted">{t.profile.privacyText}</p>
        <p className="text-sm"><strong>{t.profile.blocked}:</strong> <span className="latin">{blocked ?? 0}</span></p>
        <Link href="/privacy" className="text-sm font-semibold text-brand-600">{t.nav.privacy}</Link>
      </section>

      <InstallCard />

      <section className="card flex flex-col gap-2">
        <Link href="/institution" className="font-semibold text-navy">{t.profile.institutionLink}</Link>
        <Link href="/initiatives/mine" className="font-semibold text-navy">{t.initiative.mine}</Link>
        {viewer.isAdmin && <Link href="/admin" className="font-semibold text-brand-600">{t.nav.admin}</Link>}
      </section>

      <section className="card flex flex-col gap-3 border border-brand/20">
        <h2 className="section-title text-brand-600">{t.profile.deleteTitle}</h2>
        <p className="text-sm text-muted">{t.profile.deleteText}</p>
        <ActionForm action={deleteAccount} confirmText={t.profile.deleteText}>
          <Field label={t.profile.deleteConfirm} htmlFor="confirm">
            <input id="confirm" name="confirm" className="input" required autoComplete="off" />
          </Field>
          <SubmitButton className="btn-danger">{t.profile.deleteAction}</SubmitButton>
        </ActionForm>
      </section>
    </div>
  );
}
