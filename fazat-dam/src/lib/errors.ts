import type { Dict } from "./i18n";

const KNOWN = [
  "not_authenticated", "not_authorized", "account_inactive", "rate_limited", "not_found", "invalid_input",
  "invalid_transition", "country_mismatch", "consent_required", "too_many_open_requests", "blocked",
  "initiative_locked", "file_too_large", "file_type",
] as const;
type Known = (typeof KNOWN)[number];

/** Turns a Postgres/PostgREST error into a translated, user-safe message. */
export function errorText(t: Dict, error: unknown): string {
  const raw = typeof error === "string" ? error : (error as { message?: string } | null)?.message ?? "";
  const code = KNOWN.find((k) => raw.includes(k)) as Known | undefined;
  if (code) return t.errors[code];
  if (/row-level security|permission denied/i.test(raw)) return t.errors.not_authorized;
  if (/violates check constraint|invalid input/i.test(raw)) return t.errors.invalid_input;
  return t.errors.generic;
}

export type ActionState = { ok?: boolean; error?: string; message?: string; data?: Record<string, unknown> } | null;
