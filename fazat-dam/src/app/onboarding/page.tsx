import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { getViewer } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { completeOnboarding } from "@/app/actions/account";
import { ActionForm, CountryCitySelect, SubmitButton } from "@/components/forms";
import { Field, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.onboarding.title };
}

export default async function OnboardingPage({ searchParams }: PageProps<"/onboarding">) {
  const { t, locale } = await getDict();
  const sp = await searchParams;
  const next = typeof sp.next === "string" && sp.next.startsWith("/") && !sp.next.startsWith("//") ? sp.next : "/";
  const viewer = await getViewer();
  if (!viewer) redirect(`/login?next=${encodeURIComponent(next)}`);
  if (viewer.onboarded) redirect(next);
  const cities = await getCities();
  return (
    <div className="mx-auto max-w-xl">
      <PageHeader title={t.onboarding.title} intro={t.onboarding.subtitle} />
      <div className="card">
        <ActionForm action={completeOnboarding}>
          <input type="hidden" name="next" value={next} />
          <Field label={t.onboarding.fullName} hint={t.onboarding.fullNameHint} htmlFor="full_name">
            <input id="full_name" name="full_name" className="input" required minLength={2} maxLength={120} autoComplete="name" />
          </Field>
          <CountryCitySelect cities={cities} defaultCountry={viewer.phone?.startsWith("249") ? "SD" : viewer.phone?.startsWith("966") ? "SA" : null} />
          {!viewer.phone && (
            <Field label={t.onboarding.contactPhone} hint={t.onboarding.contactPhoneHint} htmlFor="contact_phone">
              <input id="contact_phone" name="contact_phone" className="input latin" inputMode="tel" autoComplete="tel" required pattern="\+?[0-9 ]{8,18}" defaultValue={viewer.contactPhone ?? ""} />
            </Field>
          )}
          <Field label={t.onboarding.language} htmlFor="language">
            <select id="language" name="language" className="input" defaultValue={locale}>
              <option value="ar">العربية</option>
              <option value="en">English</option>
            </select>
          </Field>
          <label className="flex items-start gap-3 text-sm">
            <input type="checkbox" name="consent" required className="mt-1 h-5 w-5 accent-[var(--color-brand)]" />
            <span>{t.onboarding.consent} <Link href="/privacy" className="underline" target="_blank">{t.nav.privacy}</Link></span>
          </label>
          <SubmitButton>{t.onboarding.done}</SubmitButton>
        </ActionForm>
      </div>
    </div>
  );
}
