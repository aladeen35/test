"use server";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getDict } from "@/lib/i18n/server";
import { str } from "@/lib/action-helpers";
import { uploadFiles } from "@/lib/uploads";
import { errorText, type ActionState } from "@/lib/errors";

async function uid() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  return { supabase, uid: data?.claims?.sub as string | undefined };
}

export async function saveInitiative(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const { supabase, uid: me } = await uid();
  if (!me) return { error: t.errors.not_authenticated };
  const id = str(fd, "id");
  const row = {
    category: str(fd, "category"), title_ar: str(fd, "title_ar"), title_en: str(fd, "title_en"),
    description: str(fd, "description"), objectives: str(fd, "objectives"), beneficiaries: str(fd, "beneficiaries"),
    organizer_name: str(fd, "organizer_name"), organizer_contact: str(fd, "organizer_contact"),
    country_code: str(fd, "country"), city_id: str(fd, "city"), start_date: str(fd, "start_date"), end_date: str(fd, "end_date"),
    status: str(fd, "intent") === "draft" ? "draft" : "submitted",
  };
  const q = id
    ? supabase.from("humanitarian_initiatives").update(row).eq("id", id).select("id").single()
    : supabase.from("humanitarian_initiatives").insert({ ...row, organizer_id: me }).select("id").single();
  const { data, error } = await q;
  if (error) return { error: errorText(t, error) };
  const uploadErr = await uploadFiles("initiative-documents", "initiative_documents", "initiative_id", data.id, fd);
  revalidatePath("/initiatives");
  return { ok: true, message: (row.status === "draft" ? t.common.saved : t.initiative.submitted) + (uploadErr ? ` — ${uploadErr}` : ""), data: { id: data.id } };
}

export async function addInitiativeUpdate(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const { supabase, uid: me } = await uid();
  const id = str(fd, "initiative_id");
  const { error } = await supabase.from("initiative_updates").insert({ initiative_id: id, author_id: me, body: str(fd, "body") });
  if (error) return { error: errorText(t, error) };
  revalidatePath(`/initiatives/${id}`);
  return { ok: true, message: t.common.saved };
}

export async function applySponsor(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const { supabase, uid: me } = await uid();
  if (!me) return { error: t.errors.not_authenticated };
  const { error } = await supabase.from("sponsors").insert({
    type: str(fd, "type"), name_ar: str(fd, "name_ar"), name_en: str(fd, "name_en"), description: str(fd, "description"),
    website: str(fd, "website"), country_code: str(fd, "country"), submitted_by: me,
  });
  if (error) return { error: errorText(t, error) };
  return { ok: true, message: t.sponsor.sent };
}

export async function registerInstitution(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const { supabase, uid: me } = await uid();
  if (!me) return { error: t.errors.not_authenticated };
  const { data, error } = await supabase.from("institutions").insert({
    type: str(fd, "type"), name_ar: str(fd, "name_ar"), name_en: str(fd, "name_en"), country_code: str(fd, "country"),
    city_id: str(fd, "city"), license_number: str(fd, "license"), address: str(fd, "address"),
    contact_phone: str(fd, "contact_phone")?.replace(/[^\d+]/g, ""), contact_email: str(fd, "contact_email"), created_by: me,
  }).select("id").single();
  if (error) return { error: errorText(t, error) };
  const uploadErr = await uploadFiles("institution-documents", "institution_documents", "institution_id", data.id, fd);
  revalidatePath("/institution");
  return { ok: true, message: t.institution.submitted + (uploadErr ? ` — ${uploadErr}` : "") };
}
