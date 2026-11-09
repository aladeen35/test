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

/** Remaining time until a deadline, as a dictionary key + number (computed at request time). */
export function timeLeft(deadline: string): { key: "minutesLeft" | "hoursLeft" | "daysLeft" | "overdue"; n: number } {
  const ms = new Date(deadline).getTime() - Date.now();
  if (ms <= 0) return { key: "overdue", n: 0 };
  const h = ms / 3600_000;
  if (h < 1) return { key: "minutesLeft", n: Math.max(1, Math.round(ms / 60_000)) };
  if (h < 48) return { key: "hoursLeft", n: Math.round(h) };
  return { key: "daysLeft", n: Math.round(h / 24) };
}
