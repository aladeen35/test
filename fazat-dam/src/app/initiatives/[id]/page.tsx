import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { getViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { cityMap } from "@/lib/geo";
import { cityName, fmtDate, fmtDateTime, pick } from "@/lib/format";
import { addInitiativeUpdate } from "@/app/actions/community";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Chip, DemoBadge, Notice } from "@/components/ui";

export async function generateMetadata({ params }: PageProps<"/initiatives/[id]">): Promise<Metadata> {
  const { t, locale } = await getDict();
  const { id } = await params;
  if (!isSupabaseConfigured() || !/^[0-9a-f-]{36}$/.test(id)) return { title: t.initiative.title };
  const supabase = await createClient();
  const { data } = await supabase.from("public_initiatives").select("title_ar, title_en").eq("id", id).maybeSingle();
  return { title: data ? pick(locale, data.title_ar, data.title_en) : t.initiative.title };
}

export default async function InitiativePage({ params }: PageProps<"/initiatives/[id]">) {
  const { id } = await params;
  const { t, locale } = await getDict();
  if (!isSupabaseConfigured() || !/^[0-9a-f-]{36}$/.test(id)) notFound();
  const viewer = await getViewer();
  const supabase = await createClient();
  // public projection first; organisers/admins may also see their own unpublished one
  let { data: i } = await supabase.from("public_initiatives").select("*").eq("id", id).maybeSingle();
  let own = false;
  if (!i && viewer) {
    const r = await supabase.from("humanitarian_initiatives").select("*").eq("id", id).maybeSingle();
    i = r.data; own = Boolean(r.data);
  }
  if (!i) notFound();
  const [{ data: updates }, { data: sponsors }, cities] = await Promise.all([
    supabase.from("initiative_updates").select("id, body, created_at").eq("initiative_id", id).order("created_at", { ascending: false }),
    supabase.from("public_campaign_sponsors").select("sponsor_id, name_ar, name_en, logo_path, website").eq("initiative_id", id),
    cityMap(),
  ]);
  const { data: mine } = viewer ? await supabase.from("humanitarian_initiatives").select("id").eq("id", id).eq("organizer_id", viewer.id).maybeSingle() : { data: null };
  const canUpdate = Boolean(mine) && i.status === "approved";
  const logoBase = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/sponsor-logos/`;

  return (
    <article className="mx-auto flex max-w-3xl flex-col gap-4">
      {own && <Notice tone="warn">{t.initiative[`st_${i.status}` as "st_draft"]}</Notice>}
      <header className="card flex flex-col gap-3">
        <div className="flex flex-wrap gap-2">
          <Chip tone="red">{t.initiative[`cat_${i.category}` as "cat_blood_drive"]}</Chip>
          <Chip>{i.country_code === "SD" ? t.common.sudan : t.common.saudi}{i.city_id ? ` · ${cityName(cities.get(i.city_id), locale)}` : ""}</Chip>
          {i.is_demo && <DemoBadge t={t} />}
        </div>
        <h1 className="page-title">{pick(locale, i.title_ar, i.title_en)}</h1>
        <p className="text-sm text-muted">{i.organizer_name} · {fmtDate(i.start_date, locale)}{i.end_date ? ` – ${fmtDate(i.end_date, locale)}` : ""}</p>
        <p className="whitespace-pre-wrap text-navy">{i.description}</p>
      </header>
      <section className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <div className="card"><h2 className="section-title">{t.initiative.objectives}</h2><p className="mt-1 whitespace-pre-wrap text-sm">{i.objectives}</p></div>
        <div className="card"><h2 className="section-title">{t.initiative.beneficiaries}</h2><p className="mt-1 whitespace-pre-wrap text-sm">{i.beneficiaries}</p></div>
      </section>
      {(sponsors ?? []).length > 0 && (
        <section className="card flex flex-col gap-2">
          <h2 className="section-title">{t.initiative.sponsors}</h2>
          <ul className="flex flex-wrap gap-4">
            {sponsors!.map((s) => (
              <li key={s.sponsor_id} className="flex items-center gap-2">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                {s.logo_path && <img src={logoBase + s.logo_path} alt="" className="h-10 w-10 rounded object-contain" />}
                {s.website ? <a href={s.website} target="_blank" rel="noopener noreferrer" className="font-semibold text-navy underline">{pick(locale, s.name_ar, s.name_en)}</a> : <span className="font-semibold">{pick(locale, s.name_ar, s.name_en)}</span>}
              </li>
            ))}
          </ul>
        </section>
      )}
      <section className="card flex flex-col gap-3">
        <h2 className="section-title">{t.initiative.updates}</h2>
        {canUpdate && (
          <ActionForm action={addInitiativeUpdate} resetOnSuccess className="flex flex-col gap-2">
            <input type="hidden" name="initiative_id" value={id} />
            <textarea name="body" className="input min-h-20" required minLength={4} maxLength={2000} aria-label={t.initiative.addUpdate} />
            <SubmitButton className="btn-navy self-start">{t.initiative.addUpdate}</SubmitButton>
          </ActionForm>
        )}
        {(updates ?? []).length === 0 ? <p className="text-sm text-muted">{t.initiative.noUpdates}</p> : (
          <ol className="flex flex-col gap-3 border-s-2 border-brand/30 ps-4">
            {updates!.map((u) => <li key={u.id}><p className="text-xs text-muted">{fmtDateTime(u.created_at, locale)}</p><p className="whitespace-pre-wrap text-sm">{u.body}</p></li>)}
          </ol>
        )}
      </section>
    </article>
  );
}
