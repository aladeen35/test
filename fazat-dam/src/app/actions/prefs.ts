"use server";
import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { LOCALE_COOKIE } from "@/lib/i18n";
import { NETWORK_COOKIE } from "@/lib/network";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";

const YEAR = 60 * 60 * 24 * 365;

export async function setLocale(locale: "ar" | "en") {
  const value = locale === "en" ? "en" : "ar";
  (await cookies()).set(LOCALE_COOKIE, value, { path: "/", maxAge: YEAR, sameSite: "lax" });
  if (isSupabaseConfigured()) {
    const supabase = await createClient();
    const { data } = await supabase.auth.getClaims();
    if (data?.claims?.sub) await supabase.from("profiles").update({ preferred_language: value }).eq("id", data.claims.sub);
  }
  revalidatePath("/", "layout");
}

export async function setNetwork(country: "SD" | "SA") {
  (await cookies()).set(NETWORK_COOKIE, country === "SD" ? "SD" : "SA", { path: "/", maxAge: YEAR, sameSite: "lax" });
  revalidatePath("/", "layout");
}
