"use server";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { callRpc, str, int, bool } from "@/lib/action-helpers";
import { getDict } from "@/lib/i18n/server";
import { fmt } from "@/lib/i18n";
import { errorText, type ActionState } from "@/lib/errors";

// Every function here is re-checked in Postgres (admin-only RPCs / admin RLS policies).

export async function reviewInstitution(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("review_institution", { p_id: str(fd, "id"), p_approve: str(fd, "approve") === "true", p_note: str(fd, "note") });
  revalidatePath("/admin/institutions");
  return res;
}

export async function setInstitutionMember(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("set_institution_member", { p_institution: str(fd, "institution_id"), p_user: str(fd, "user_id"), p_active: str(fd, "active") !== "false", p_title: str(fd, "title") });
  revalidatePath("/admin/institutions");
  return res;
}

export async function reviewInitiative(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("review_initiative", { p_id: str(fd, "id"), p_status: str(fd, "status"), p_note: str(fd, "note") });
  revalidatePath("/admin/initiatives");
  revalidatePath("/initiatives");
  return res;
}

export async function reviewSponsor(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("review_sponsor", { p_id: str(fd, "id"), p_approve: str(fd, "approve") === "true", p_note: str(fd, "note") });
  revalidatePath("/admin/sponsors");
  return res;
}

export async function linkSponsorship(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { error } = await supabase.from("campaign_sponsorships").upsert(
    { initiative_id: str(fd, "initiative_id"), sponsor_id: str(fd, "sponsor_id"), contribution_note: str(fd, "note"), status: "approved" },
    { onConflict: "initiative_id,sponsor_id" },
  );
  if (error) return { error: errorText(t, error) };
  revalidatePath("/admin/sponsors");
  return { ok: true, message: t.common.saved };
}

export async function setAccountStatus(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("admin_set_account_status", { p_user: str(fd, "user_id"), p_status: str(fd, "status"), p_note: str(fd, "note") });
  revalidatePath("/admin/users");
  return res;
}

export async function setRole(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("admin_set_role", { p_user: str(fd, "user_id"), p_role: str(fd, "role"), p_grant: str(fd, "grant") === "true" });
  revalidatePath("/admin/users");
  return res;
}

export async function resolveReport(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("resolve_report", { p_id: str(fd, "id"), p_status: str(fd, "status"), p_note: str(fd, "note") });
  revalidatePath("/admin/reports");
  return res;
}

export async function broadcast(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const res = await callRpc<number>("admin_broadcast", {
    p_country: str(fd, "country"), p_title_ar: str(fd, "title_ar"), p_title_en: str(fd, "title_en"),
    p_body_ar: str(fd, "body_ar"), p_body_en: str(fd, "body_en"), p_link: str(fd, "link"),
  });
  return res.error ? res : { ok: true, message: fmt(t.admin.broadcastSent, { n: res.result ?? 0 }) };
}

export async function addCity(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { error } = await supabase.from("cities").insert({
    country_code: str(fd, "country"), name_ar: str(fd, "name_ar"), name_en: str(fd, "name_en"), sort_order: int(fd, "sort_order") ?? 100,
  });
  if (error) return { error: errorText(t, error) };
  revalidatePath("/admin/settings");
  return { ok: true, message: t.common.saved };
}

export async function toggleCity(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { error } = await supabase.from("cities").update({ is_active: bool(fd, "active") }).eq("id", str(fd, "id"));
  if (error) return { error: errorText(t, error) };
  revalidatePath("/admin/settings");
  return { ok: true, message: t.common.saved };
}

export async function updateSettings(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const clamp = (v: number | null, lo: number, hi: number, d: number) => Math.min(hi, Math.max(lo, v ?? d));
  const rows = [
    { key: "matching", value: { batch_size: clamp(int(fd, "batch_size"), 1, 100, 25) } },
    { key: "requests", value: {
      max_open_per_user: clamp(int(fd, "max_open"), 1, 10, 3),
      max_per_day: clamp(int(fd, "max_day"), 1, 20, 5),
      grace_hours: clamp(int(fd, "grace"), 1, 168, 24),
    } },
  ];
  const { error } = await supabase.from("app_settings").upsert(rows, { onConflict: "key" });
  if (error) return { error: errorText(t, error) };
  revalidatePath("/admin/settings");
  return { ok: true, message: t.common.saved };
}

export async function uploadSponsorLogo(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const id = str(fd, "sponsor_id");
  const file = fd.get("logo");
  if (!(file instanceof File) || file.size === 0) return { error: t.errors.invalid_input };
  if (file.size > 1024 * 1024) return { error: t.errors.file_too_large };
  const ext = ({ "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp" } as Record<string, string>)[file.type];
  if (!ext) return { error: t.errors.file_type };
  const supabase = await createClient();
  const path = `${id}/${crypto.randomUUID()}.${ext}`;
  const { error: upErr } = await supabase.storage.from("sponsor-logos").upload(path, file, { contentType: file.type });
  if (upErr) return { error: errorText(t, upErr) };
  const { error } = await supabase.from("sponsors").update({ logo_path: path }).eq("id", id);
  if (error) return { error: errorText(t, error) };
  revalidatePath("/admin/sponsors");
  return { ok: true, message: t.common.saved };
}
