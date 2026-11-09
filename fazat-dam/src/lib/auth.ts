import "server-only";
import { cache } from "react";
import { redirect } from "next/navigation";
import { createClient } from "./supabase/server";
import { isSupabaseConfigured } from "./supabase/config";
import type { Role } from "./constants";

export type Viewer = {
  id: string;
  phone: string | null;
  email: string | null;
  contactPhone: string | null;
  fullName: string | null;
  countryCode: "SD" | "SA" | null;
  cityId: string | null;
  language: "ar" | "en";
  status: "active" | "suspended" | "deleted";
  onboarded: boolean;
  roles: Role[];
  isAdmin: boolean;
};

/** The signed-in user (verified with Supabase Auth) and their profile, once per request. */
export const getViewer = cache(async (): Promise<Viewer | null> => {
  if (!isSupabaseConfigured()) return null;
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const uid = data?.claims?.sub;
  if (!uid) return null;
  const [{ data: profile }, { data: roles }] = await Promise.all([
    supabase.from("profiles").select("id, phone, email, contact_phone, full_name, country_code, city_id, preferred_language, account_status, onboarded_at").eq("id", uid).maybeSingle(),
    supabase.from("user_roles").select("role").eq("user_id", uid),
  ]);
  if (!profile) return null;
  const roleList = (roles ?? []).map((r: { role: Role }) => r.role);
  return {
    id: profile.id,
    phone: profile.phone,
    email: profile.email,
    contactPhone: profile.contact_phone,
    fullName: profile.full_name,
    countryCode: profile.country_code,
    cityId: profile.city_id,
    language: profile.preferred_language,
    status: profile.account_status,
    onboarded: Boolean(profile.onboarded_at),
    roles: roleList,
    isAdmin: roleList.includes("admin") && profile.account_status === "active",
  };
});

/** For pages that need a fully set-up account. */
export async function requireViewer(next = "/"): Promise<Viewer> {
  const viewer = await getViewer();
  if (!viewer) redirect(`/login?next=${encodeURIComponent(next)}`);
  if (!viewer.onboarded) redirect(`/onboarding?next=${encodeURIComponent(next)}`);
  return viewer;
}

export async function requireRole(role: Role, next = "/") {
  const viewer = await requireViewer(next);
  if (!viewer.roles.includes(role) || viewer.status !== "active") redirect("/");
  return viewer;
}

export async function requireAdmin(next = "/admin") {
  const viewer = await requireViewer(next);
  if (!viewer.isAdmin) redirect("/");
  return viewer;
}
