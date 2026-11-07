import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { broadcast } from "@/app/actions/admin";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Field, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.notifications };
}

export default async function AdminNotifications() {
  const { t } = await getDict();
  await requireAdmin();
  return (
    <div className="max-w-2xl">
      <PageHeader title={t.admin.broadcast} />
      <div className="card">
        <ActionForm action={broadcast} resetOnSuccess confirmText={t.admin.broadcast + "?"}>
          <Field label={t.common.country} htmlFor="country">
            <select id="country" name="country" className="input"><option value="">{t.admin.allCountries}</option><option value="SD">{t.common.sudan}</option><option value="SA">{t.common.saudi}</option></select>
          </Field>
          <Field label={t.admin.titleAr} htmlFor="title_ar"><input id="title_ar" name="title_ar" dir="rtl" className="input" required maxLength={140} /></Field>
          <Field label={t.admin.titleEn} htmlFor="title_en"><input id="title_en" name="title_en" dir="ltr" className="input" required maxLength={140} /></Field>
          <Field label={t.admin.bodyAr} htmlFor="body_ar"><textarea id="body_ar" name="body_ar" dir="rtl" className="input" maxLength={500} /></Field>
          <Field label={t.admin.bodyEn} htmlFor="body_en"><textarea id="body_en" name="body_en" dir="ltr" className="input" maxLength={500} /></Field>
          <Field label="Link (/path)" htmlFor="link"><input id="link" name="link" className="input latin" pattern="/.*" placeholder="/initiatives" /></Field>
          <SubmitButton className="btn-navy self-start">{t.common.submit}</SubmitButton>
        </ActionForm>
      </div>
    </div>
  );
}
