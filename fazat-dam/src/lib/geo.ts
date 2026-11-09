import "server-only";
import { cache } from "react";
import { createClient } from "./supabase/server";
import { isSupabaseConfigured } from "./supabase/config";

export type City = { id: string; country_code: "SD" | "SA"; name_ar: string; name_en: string; is_active?: boolean };

export const getCities = cache(async (includeInactive = false): Promise<City[]> => {
  if (!isSupabaseConfigured()) return [];
  const supabase = await createClient();
  let q = supabase.from("cities").select("id, country_code, name_ar, name_en, is_active").order("sort_order").order("name_en");
  if (!includeInactive) q = q.eq("is_active", true);
  const { data } = await q;
  return (data ?? []) as City[];
});

export async function cityMap() {
  const cities = await getCities(true);
  return new Map(cities.map((c) => [c.id, c]));
}
