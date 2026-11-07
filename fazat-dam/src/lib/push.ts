import "server-only";
import * as webpush from "web-push";
import { createServiceClient } from "./supabase/server";

let configured: boolean | null = null;
function configure() {
  if (configured !== null) return configured;
  const pub = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY, priv = process.env.VAPID_PRIVATE_KEY;
  configured = Boolean(pub && priv && process.env.SUPABASE_SERVICE_ROLE_KEY);
  if (configured) webpush.setVapidDetails(process.env.VAPID_SUBJECT || "mailto:support@example.org", pub!, priv!);
  return configured;
}

/**
 * Sends Web Push for notifications not yet pushed (in-app notifications are the source of truth;
 * push is best-effort). Payload carries only a title and an in-app link — no personal data.
 */
export async function dispatchPendingPush(limit = 100) {
  if (!configure()) return { sent: 0, skipped: true };
  const admin = createServiceClient()!;
  const { data: rows } = await admin.from("notifications")
    .select("id, user_id, title_ar, title_en, link, profiles!inner(preferred_language)")
    .is("pushed_at", null).gt("created_at", new Date(Date.now() - 6 * 3600_000).toISOString())
    .order("created_at").limit(limit);
  if (!rows?.length) return { sent: 0 };
  const ids = rows.map((r) => r.id);
  // claim first so concurrent dispatchers don't double-send
  await admin.from("notifications").update({ pushed_at: new Date().toISOString() }).in("id", ids).is("pushed_at", null);
  const users = [...new Set(rows.map((r) => r.user_id))];
  const { data: subs } = await admin.from("push_subscriptions").select("id, user_id, endpoint, p256dh, auth").in("user_id", users);
  let sent = 0;
  for (const n of rows) {
    const lang = (n.profiles as unknown as { preferred_language: string })?.preferred_language;
    const payload = JSON.stringify({ title: lang === "en" ? n.title_en : n.title_ar, url: n.link || "/notifications", tag: n.id });
    for (const s of (subs ?? []).filter((x) => x.user_id === n.user_id)) {
      try {
        await webpush.sendNotification({ endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } }, payload, { TTL: 3600, urgency: "high" });
        sent++;
      } catch (e) {
        const code = (e as { statusCode?: number }).statusCode;
        if (code === 404 || code === 410) await admin.from("push_subscriptions").delete().eq("id", s.id);
      }
    }
  }
  return { sent };
}
