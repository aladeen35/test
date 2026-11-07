import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { getCities } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui";
import { InitiativeForm } from "@/components/initiative-form";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.initiative.submitNew };
}

export default async function NewInitiativePage({ searchParams }: PageProps<"/initiatives/new">) {
  const { t } = await getDict();
  await requireViewer("/initiatives/new");
  const sp = await searchParams;
  const cities = await getCities();
  let initial;
  if (typeof sp.edit === "string" && /^[0-9a-f-]{36}$/.test(sp.edit)) {
    const supabase = await createClient();
    const { data } = await supabase.from("humanitarian_initiatives").select("*").eq("id", sp.edit).in("status", ["draft", "rejected"]).maybeSingle();
    initial = data ?? undefined;
  }
  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={t.initiative.submitNew} intro={t.initiative.intro} />
      <InitiativeForm cities={cities} initial={initial} />
    </div>
  );
}
