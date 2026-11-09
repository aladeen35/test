"use server";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient, createServiceClient } from "@/lib/supabase/server";
import { callRpc, str, bool } from "@/lib/action-helpers";
import { getDict } from "@/lib/i18n/server";
import { errorText, type ActionState } from "@/lib/errors";

function safeNext(next: string | null) {
  return next && next.startsWith("/") && !next.startsWith("//") ? next : "/";
}

/** Email sign-in has no verified number, so the user provides a private contact number. */
async function saveContactPhone(fd: FormData): Promise<ActionState> {
  const phone = str(fd, "contact_phone");
  if (phone === null) return null;
  return callRpc("set_contact_phone", { p_phone: phone });
}

export async function completeOnboarding(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("complete_onboarding", {
    p_full_name: str(fd, "full_name"), p_country: str(fd, "country"), p_city: str(fd, "city"),
    p_language: str(fd, "language") ?? "ar", p_accept_privacy: bool(fd, "consent"),
  });
  if (res.error) return res;
  const phoneRes = await saveContactPhone(fd);
  if (phoneRes?.error) return phoneRes;
  redirect(safeNext(str(fd, "next")));
}

export async function updateProfile(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("complete_onboarding", {
    p_full_name: str(fd, "full_name"), p_country: str(fd, "country"), p_city: str(fd, "city"),
    p_language: str(fd, "language") ?? "ar", p_accept_privacy: true,
  });
  if (res.error) return res;
  const phoneRes = await saveContactPhone(fd);
  revalidatePath("/", "layout");
  return phoneRes?.error ? phoneRes : res;
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/");
}

export async function deleteAccount(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const word = str(fd, "confirm");
  if (word !== t.profile.deleteWord && word !== "DELETE" && word !== "حذف") return { error: t.errors.consent_required };
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const uid = data?.claims?.sub;
  const { error } = await supabase.rpc("delete_my_account");
  if (error) return { error: errorText(t, error) };
  // Remove the auth identity too (needs the service role); the profile is already anonymised.
  const admin = createServiceClient();
  if (admin && uid) await admin.auth.admin.deleteUser(uid);
  await supabase.auth.signOut();
  redirect("/");
}

export async function markAllRead() {
  const supabase = await createClient();
  await supabase.rpc("mark_all_notifications_read");
  revalidatePath("/", "layout");
}

export async function markRead(id: string) {
  const supabase = await createClient();
  await supabase.from("notifications").update({ read_at: new Date().toISOString() }).eq("id", id).is("read_at", null);
}

export async function savePushSubscription(sub: { endpoint: string; p256dh: string; auth: string; userAgent?: string }) {
  if (!/^https:\/\//.test(sub.endpoint)) return;
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  if (!data?.claims?.sub) return;
  await supabase.from("push_subscriptions").upsert(
    { user_id: data.claims.sub, endpoint: sub.endpoint, p256dh: sub.p256dh, auth: sub.auth, user_agent: sub.userAgent ?? null },
    { onConflict: "endpoint" },
  );
  await supabase.from("user_consents").insert({ user_id: data.claims.sub, consent_type: "push_notifications", granted: true });
}

export async function removePushSubscription(endpoint: string) {
  const supabase = await createClient();
  await supabase.from("push_subscriptions").delete().eq("endpoint", endpoint);
}

export async function blockUser(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("block_match_party", { p_match: str(fd, "match_id") });
  revalidatePath("/", "layout");
  return res;
}

export async function reportMatchParty(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const res = await callRpc("report_match_party", { p_match: str(fd, "match_id"), p_reason: str(fd, "reason"), p_details: str(fd, "details") });
  return res.error ? res : { ok: true, message: t.report.sent };
}

export async function unblockUser(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { error } = await supabase.from("user_blocks").delete().eq("blocked_id", str(fd, "blocked_id"));
  if (error) return { error: errorText(t, error) };
  revalidatePath("/profile");
  return { ok: true, message: t.common.saved };
}

export async function submitReport(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const { error } = await supabase.from("reports").insert({
    reporter_id: data?.claims?.sub, target_type: str(fd, "target_type"), target_id: str(fd, "target_id"),
    reason: str(fd, "reason"), details: str(fd, "details"),
  });
  if (error) return { error: errorText(t, error) };
  return { ok: true, message: t.report.sent };
}
