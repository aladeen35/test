import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireAdmin } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { addCity, toggleCity, updateSettings } from "@/app/actions/admin";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, Field, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.settings };
}

export default async function AdminSettings() {
  const { t } = await getDict();
  await requireAdmin();
  const supabase = await createClient();
  const [cities, { data: settings }] = await Promise.all([getCities(true), supabase.from("app_settings").select("key, value")]);
  const get = (k: string, p: string, d: number) => Number((settings ?? []).find((s) => s.key === k)?.value?.[p] ?? d);
  return (
    <div className="flex flex-col gap-4">
      <PageHeader title={t.admin.settings} />
      <section className="card">
        <ActionForm action={updateSettings} className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Field label={t.admin.settingsMatching} htmlFor="batch_size"><input id="batch_size" name="batch_size" type="number" min={1} max={100} className="input latin" defaultValue={get("matching", "batch_size", 25)} /></Field>
          <Field label={t.admin.settingsMaxOpen} htmlFor="max_open"><input id="max_open" name="max_open" type="number" min={1} max={10} className="input latin" defaultValue={get("requests", "max_open_per_user", 3)} /></Field>
          <Field label={t.admin.settingsMaxDay} htmlFor="max_day"><input id="max_day" name="max_day" type="number" min={1} max={20} className="input latin" defaultValue={get("requests", "max_per_day", 5)} /></Field>
          <Field label={t.admin.settingsGrace} htmlFor="grace"><input id="grace" name="grace" type="number" min={1} max={168} className="input latin" defaultValue={get("requests", "grace_hours", 24)} /></Field>
          <SubmitButton className="btn-navy self-end">{t.common.save}</SubmitButton>
        </ActionForm>
      </section>
      <section className="card flex flex-col gap-3">
        <h2 className="section-title">{t.admin.cities}</h2>
        <ActionForm action={addCity} resetOnSuccess className="grid grid-cols-1 gap-2 sm:grid-cols-4">
          <select name="country" className="input" required aria-label={t.common.country}><option value="SD">{t.common.sudan}</option><option value="SA">{t.common.saudi}</option></select>
          <input name="name_ar" className="input" required placeholder={t.admin.nameAr} aria-label={t.admin.nameAr} />
          <input name="name_en" className="input" dir="ltr" required placeholder={t.admin.nameEn} aria-label={t.admin.nameEn} />
          <SubmitButton className="btn-outline">{t.admin.addCity}</SubmitButton>
        </ActionForm>
        {(["SD", "SA"] as const).map((c) => (
          <div key={c}>
            <h3 className="mb-1 font-bold text-navy">{c === "SD" ? t.common.sudan : t.common.saudi}</h3>
            <ul className="flex flex-wrap gap-2">
              {cities.filter((x) => x.country_code === c).map((x) => (
                <li key={x.id}>
                  <ActionForm action={toggleCity} className="inline-flex">
                    <input type="hidden" name="id" value={x.id} />
                    <input type="hidden" name="active" value={x.is_active ? "false" : "true"} />
                    <SubmitButton className={`chip min-h-8 ${x.is_active ? "bg-success-50 text-success" : "bg-zinc-100 text-zinc-500 line-through"}`} title={x.is_active ? t.admin.active : t.admin.inactive}>
                      {x.name_ar} · {x.name_en}
                    </SubmitButton>
                  </ActionForm>
                </li>
              ))}
            </ul>
          </div>
        ))}
        <Chip tone="gray">{t.admin.active} / {t.admin.inactive}</Chip>
      </section>
    </div>
  );
}
