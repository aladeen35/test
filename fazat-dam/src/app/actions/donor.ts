"use server";
import { revalidatePath } from "next/cache";
import { callRpc, str, bool } from "@/lib/action-helpers";
import { getDict } from "@/lib/i18n/server";
import { fmt } from "@/lib/i18n";
import type { ActionState } from "@/lib/errors";

export async function registerDonor(_: ActionState, fd: FormData): Promise<ActionState> {
  const { t } = await getDict();
  const res = await callRpc<string>("register_donor", {
    p_full_name: str(fd, "full_name"), p_country: str(fd, "country"), p_city: str(fd, "city"),
    p_blood_group: str(fd, "blood_group"), p_availability: str(fd, "availability") ?? "available",
    p_contact_method: str(fd, "contact_method") ?? "in_app", p_language: str(fd, "language") ?? "ar",
    p_accept_privacy: bool(fd, "consent"), p_email: str(fd, "email"), p_preferred_facility: str(fd, "facility"),
    p_last_donation_date: str(fd, "last_donation"), p_show_first_name: bool(fd, "show_first_name"),
    p_accepts_auto_matching: bool(fd, "auto_match"),
  });
  if (res.error) return res;
  revalidatePath("/", "layout");
  return { ok: true, message: fmt(t.donor.registered, { alias: String(res.result) }) };
}

export async function setAvailability(_: ActionState, fd: FormData): Promise<ActionState> {
  const res = await callRpc("set_donor_availability", { p_status: str(fd, "status"), p_until: str(fd, "until") });
  revalidatePath("/donate");
  return res;
}
