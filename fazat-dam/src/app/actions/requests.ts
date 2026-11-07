"use server";
import { revalidatePath } from "next/cache";
import { callRpc, str, bool, int } from "@/lib/action-helpers";
import { createClient } from "@/lib/supabase/server";
import { getDict } from "@/lib/i18n/server";
import { fmt } from "@/lib/i18n";
import { errorText, type ActionState } from "@/lib/errors";
import { uploadFiles } from "@/lib/uploads";

export async function submitRequest(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const requiredBy = str(fd, "required_by");
  const res = await callRpc<{ id: string; reference: string }[]>("submit_blood_request", {
    p_relation: str(fd, "relation"), p_blood_group: str(fd, "blood_group"), p_units: int(fd, "units"),
    p_country: str(fd, "country"), p_city: str(fd, "city"), p_hospital_name: str(fd, "hospital_name"),
    // datetime-local has no zone: interpret it in the request country's time zone
    p_required_by: requiredBy ? `${requiredBy}:00${str(fd, "country") === "SD" ? "+02:00" : "+03:00"}` : null,
    p_urgency: str(fd, "urgency") ?? "normal", p_declaration: bool(fd, "declaration"),
    p_patient_initials: str(fd, "patient_initials"), p_institution: str(fd, "institution"), p_notes: str(fd, "notes"),
  });
  if (res.error) return res;
  const row = res.result?.[0];
  if (!row) return { error: t.errors.generic };
  const uploadErr = await uploadFiles("request-documents", "request_documents", "request_id", row.id, fd);
  revalidatePath("/activity");
  return { ok: true, message: fmt(t.request.submitted, { ref: row.reference }) + (uploadErr ? ` — ${uploadErr}` : ""), data: { id: row.id } };
}

export async function uploadRequestDocument(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const id = str(fd, "request_id")!;
  const err = await uploadFiles("request-documents", "request_documents", "request_id", id, fd);
  revalidatePath(`/requests/${id}`);
  return err ? { error: err } : { ok: true, message: t.request.uploaded };
}

export async function transitionRequest(_: ActionState, fd: FormData): Promise<ActionState> {
  const id = str(fd, "request_id");
  const res = await callRpc("transition_request", { p_request: id, p_status: str(fd, "status"), p_note: str(fd, "note") });
  revalidatePath(`/requests/${id}`);
  revalidatePath(`/admin/requests/${id}`);
  revalidatePath("/admin/requests");
  return res;
}

export async function runMatching(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const id = str(fd, "request_id");
  const res = await callRpc<number>("run_auto_matching", { p_request: id });
  revalidatePath(`/admin/requests/${id}`);
  return res.error ? res : { ok: true, message: fmt(t.admin.matched, { n: res.result ?? 0 }) };
}

export async function sendManualMatch(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const res = await callRpc("send_manual_match", { p_request: str(fd, "request_id"), p_donor: str(fd, "donor_id") });
  return res.error ? res : { ok: true, message: t.search.sent };
}

export async function respondToMatch(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("respond_to_match", {
    p_match: str(fd, "match_id"), p_accept: str(fd, "accept") === "true", p_reason: str(fd, "reason"), p_share_contact: bool(fd, "share_contact"),
  });
  revalidatePath("/activity");
  return res;
}

export async function setContactConsent(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("set_contact_consent", { p_match: str(fd, "match_id"), p_consent: str(fd, "consent") === "true" });
  revalidatePath("/activity");
  if (str(fd, "request_id")) revalidatePath(`/requests/${str(fd, "request_id")}`);
  return res;
}

export async function revealContact(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("get_match_contact", { p_match: str(fd, "match_id") });
  if (error) return { error: errorText(t, error) };
  const c = data?.[0];
  if (!c) return { error: t.errors.not_found };
  return { ok: true, data: { name: c.name ?? "", phone: c.phone ?? "", method: c.contact_method } };
}

export async function scheduleAppointment(_: ActionState, fd: FormData): Promise<ActionState> {
  const at = str(fd, "at");
  const tz = str(fd, "country") === "SD" ? "+02:00" : "+03:00";
  const res = await callRpc("schedule_appointment", { p_match: str(fd, "match_id"), p_at: at ? `${at}:00${tz}` : null, p_note: str(fd, "note") });
  revalidatePath(`/requests/${str(fd, "request_id")}`);
  return res;
}

export async function recordDonation(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("record_donation", { p_match: str(fd, "match_id"), p_donated_on: str(fd, "donated_on"), p_units: int(fd, "units") ?? 1, p_notes: str(fd, "notes") });
  revalidatePath("/activity");
  if (str(fd, "request_id")) revalidatePath(`/requests/${str(fd, "request_id")}`);
  return res;
}

export async function confirmDonation(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("confirm_donation", { p_record: str(fd, "record_id"), p_confirm: str(fd, "confirm") === "true", p_note: str(fd, "note") });
  revalidatePath("/institution");
  revalidatePath("/admin/donations");
  return res;
}

export async function sendMessage(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const body = str(fd, "body");
  if (!body) return { error: t.errors.invalid_input };
  const { error } = await supabase.from("messages").insert({ match_id: str(fd, "match_id"), sender_id: claims?.claims?.sub, body: body.slice(0, 1000) });
  if (error) return { error: errorText(t, error) };
  revalidatePath(`/messages/${str(fd, "match_id")}`);
  return { ok: true };
}

export async function getDocumentUrl(bucket: "request-documents" | "initiative-documents" | "institution-documents", path: string) {
  if (!["request-documents", "initiative-documents", "institution-documents"].includes(bucket)) return null;
  const supabase = await createClient();
  const { data } = await supabase.storage.from(bucket).createSignedUrl(path, 120);
  return data?.signedUrl ?? null;
}
