import "server-only";
import { createClient } from "./supabase/server";
import { getDict } from "./i18n/server";
import { errorText, type ActionState } from "./errors";
import { dispatchPendingPush } from "./push";

export function str(fd: FormData, key: string): string | null {
  const v = fd.get(key);
  if (typeof v !== "string") return null;
  const s = v.trim();
  return s === "" ? null : s;
}
export function bool(fd: FormData, key: string) {
  const v = fd.get(key);
  return v === "on" || v === "true" || v === "1";
}
export function int(fd: FormData, key: string) {
  const s = str(fd, key);
  const n = s === null ? NaN : Number.parseInt(s, 10);
  return Number.isFinite(n) ? n : null;
}

/** Call a Postgres workflow function as the signed-in user and translate errors. */
export async function callRpc<T = unknown>(fn: string, args: Record<string, unknown>, okMessage?: string): Promise<ActionState & { result?: T }> {
  const { t } = await getDict();
  const supabase = await createClient();
  const { data, error } = await supabase.rpc(fn, args);
  if (error) return { error: errorText(t, error) };
  // notifications created by the workflow are pushed in the background (no-op if push is not configured)
  void dispatchPendingPush().catch(() => {});
  return { ok: true, message: okMessage ?? t.common.saved, result: data as T };
}

export async function fail(key: keyof Awaited<ReturnType<typeof getDict>>["t"]["errors"]): Promise<ActionState> {
  const { t } = await getDict();
  return { error: t.errors[key] };
}
