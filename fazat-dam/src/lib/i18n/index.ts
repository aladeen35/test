import ar, { type Dict } from "./ar";
import en from "./en";

export type Locale = "ar" | "en";
export const LOCALES: Locale[] = ["ar", "en"];
export const DEFAULT_LOCALE: Locale = "ar";
export const LOCALE_COOKIE = "lang";

export const dictionaries: Record<Locale, Dict> = { ar, en };
export type { Dict };

export function dirOf(locale: Locale) {
  return locale === "ar" ? "rtl" : "ltr";
}

/** "{name}" style interpolation */
export function fmt(template: string, vars: Record<string, string | number>) {
  return template.replace(/\{(\w+)\}/g, (_, k) => String(vars[k] ?? ""));
}
