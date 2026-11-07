import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { getViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { pick } from "@/lib/format";
import { SPONSOR_TYPES } from "@/lib/constants";
import { applySponsor } from "@/app/actions/community";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, DemoBadge, Empty, Field, PageHeader } from "@/components/ui";
import Link from "next/link";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.sponsor.title };
}

export default async function SponsorsPage() {
  const { t, locale } = await getDict();
  const viewer = await getViewer();
  let sponsors: { id: string; type: string; name_ar: string; name_en: string | null; description: string | null; website: string | null; logo_path: string | null; is_demo: boolean }[] = [];
  if (isSupabaseConfigured()) {
    const supabase = await createClient();
    sponsors = (await supabase.from("public_sponsors").select("*").order("name_ar")).data ?? [];
  }
  const logoBase = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/sponsor-logos/`;
  return (
    <div className="flex flex-col gap-4">
      <PageHeader title={t.sponsor.title} intro={t.sponsor.intro} />
      <section className="card">
        <h2 className="section-title mb-2">{t.sponsor.transparency}</h2>
        <ul className="list-disc space-y-1 ps-5 text-sm">
          {[t.sponsor.rule1, t.sponsor.rule2, t.sponsor.rule3, t.sponsor.rule4].map((r) => <li key={r}>{r}</li>)}
        </ul>
      </section>
      {sponsors.length === 0 ? <Empty>{t.sponsor.empty}</Empty> : (
        <ul className="grid grid-cols-2 gap-3 md:grid-cols-4">
          {sponsors.map((s) => (
            <li key={s.id} className="card flex flex-col items-center gap-2 text-center">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              {s.logo_path ? <img src={logoBase + s.logo_path} alt="" className="h-16 w-16 object-contain" /> : <span className="h-16 w-16 rounded-full bg-navy-100" />}
              <span className="font-bold text-navy">{pick(locale, s.name_ar, s.name_en)}</span>
              <Chip>{t.sponsor[`type_${s.type}` as "type_corporate"]}</Chip>
              {s.website && <a href={s.website} target="_blank" rel="noopener noreferrer" className="text-xs text-brand-600 underline">{new URL(s.website).hostname}</a>}
              {s.is_demo && <DemoBadge t={t} />}
            </li>
          ))}
        </ul>
      )}
      <section className="card flex flex-col gap-3">
        <h2 className="section-title">{t.sponsor.apply}</h2>
        {!viewer ? <Link href="/login?next=/sponsors" className="btn-primary self-start">{t.common.signIn}</Link> : (
          <ActionForm action={applySponsor} resetOnSuccess>
            <Field label={t.sponsor.type} htmlFor="type">
              <select id="type" name="type" className="input" required>{SPONSOR_TYPES.map((s) => <option key={s} value={s}>{t.sponsor[`type_${s}`]}</option>)}</select>
            </Field>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field label={t.sponsor.nameAr} htmlFor="name_ar"><input id="name_ar" name="name_ar" className="input" required minLength={2} maxLength={160} /></Field>
              <Field label={t.sponsor.nameEn} htmlFor="name_en"><input id="name_en" name="name_en" className="input" dir="ltr" maxLength={160} /></Field>
            </div>
            <Field label={t.common.country} htmlFor="country">
              <select id="country" name="country" className="input"><option value="SA">{t.common.saudi}</option><option value="SD">{t.common.sudan}</option></select>
            </Field>
            <Field label={t.sponsor.website} htmlFor="website"><input id="website" name="website" type="url" pattern="https://.*" className="input latin" /></Field>
            <Field label={t.sponsor.about} htmlFor="description"><textarea id="description" name="description" className="input min-h-20" maxLength={1000} /></Field>
            <SubmitButton className="btn-navy self-start">{t.common.submit}</SubmitButton>
          </ActionForm>
        )}
      </section>
    </div>
  );
}
