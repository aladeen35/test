import type { Locale } from "./i18n";

export function fmtDate(value: string | Date | null | undefined, locale: Locale, opts: Intl.DateTimeFormatOptions = {}) {
  if (!value) return "—";
  const d = typeof value === "string" ? new Date(value) : value;
  return new Intl.DateTimeFormat(locale === "ar" ? "ar-SA-u-ca-gregory-nu-latn" : "en-GB", {
    dateStyle: "medium",
    ...opts,
  }).format(d);
}

export function fmtDateTime(value: string | Date | null | undefined, locale: Locale, timeZone?: string) {
  return fmtDate(value, locale, { dateStyle: "medium", timeStyle: "short", ...(timeZone ? { timeZone } : {}) });
}

export function fmtNumber(n: number, locale: Locale) {
  return new Intl.NumberFormat(locale === "ar" ? "ar-SA-u-nu-latn" : "en-US").format(n);
}

export function cityName(c: { name_ar: string; name_en: string } | null | undefined, locale: Locale) {
  if (!c) return "—";
  return locale === "ar" ? c.name_ar : c.name_en;
}

export function pick<T extends string>(locale: Locale, ar: T | null | undefined, en: T | null | undefined) {
  return (locale === "en" ? en || ar : ar || en) ?? "";
}
