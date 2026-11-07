import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { MedicalNotice, PageHeader } from "@/components/ui";
import { RequestForm } from "./request-form";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.request.newTitle };
}

export default async function NewRequestPage() {
  const { t } = await getDict();
  const viewer = await requireViewer("/requests/new");
  const supabase = await createClient();
  const [cities, { data: institutions }] = await Promise.all([
    getCities(),
    supabase.from("public_institutions").select("id, type, name_ar, name_en, country_code, city_id").order("name_ar"),
  ]);
  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={t.request.newTitle} intro={t.request.newIntro} />
      <RequestForm cities={cities} institutions={institutions ?? []} defaultCountry={viewer.countryCode} defaultCity={viewer.cityId} />
      <MedicalNotice t={t} />
    </div>
  );
}
