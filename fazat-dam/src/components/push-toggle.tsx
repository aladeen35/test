"use client";
import { useEffect, useState } from "react";
import { useI18n } from "@/lib/i18n/client";
import { savePushSubscription, removePushSubscription } from "@/app/actions/account";

function urlBase64ToUint8Array(base64: string) {
  const padding = "=".repeat((4 - (base64.length % 4)) % 4);
  const raw = atob((base64 + padding).replace(/-/g, "+").replace(/_/g, "/"));
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)));
}

export function PushToggle() {
  const { t } = useI18n();
  const key = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY;
  const [state, setState] = useState<"loading" | "unsupported" | "denied" | "off" | "on">("loading");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    (async () => {
      if (!("serviceWorker" in navigator) || !("PushManager" in window) || !("Notification" in window)) return setState("unsupported");
      if (Notification.permission === "denied") return setState("denied");
      const reg = await navigator.serviceWorker.getRegistration();
      const sub = await reg?.pushManager.getSubscription();
      setState(sub ? "on" : "off");
    })();
  }, []);

  if (!key) return <p className="hint">{t.notifications.pushNotConfigured}</p>;
  if (state === "loading") return null;
  if (state === "unsupported") return <p className="hint">{t.notifications.pushUnsupported} {t.notifications.iosHint}</p>;
  if (state === "denied") return <p className="hint">{t.notifications.pushDenied}</p>;

  async function enable() {
    setBusy(true);
    try {
      const perm = await Notification.requestPermission();
      if (perm !== "granted") return setState("denied");
      const reg = (await navigator.serviceWorker.getRegistration()) ?? (await navigator.serviceWorker.register("/sw.js"));
      const sub = await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: urlBase64ToUint8Array(key!) });
      const json = sub.toJSON();
      await savePushSubscription({ endpoint: json.endpoint!, p256dh: json.keys!.p256dh, auth: json.keys!.auth, userAgent: navigator.userAgent.slice(0, 200) });
      setState("on");
    } finally {
      setBusy(false);
    }
  }
  async function disable() {
    setBusy(true);
    try {
      const reg = await navigator.serviceWorker.getRegistration();
      const sub = await reg?.pushManager.getSubscription();
      if (sub) {
        await removePushSubscription(sub.endpoint);
        await sub.unsubscribe();
      }
      setState("off");
    } finally {
      setBusy(false);
    }
  }
  return state === "on" ? (
    <div className="flex flex-wrap items-center gap-3">
      <span className="text-sm text-success">{t.notifications.pushOn}</span>
      <button className="btn-outline" disabled={busy} onClick={disable}>{t.notifications.disablePush}</button>
    </div>
  ) : (
    <button className="btn-navy" disabled={busy} onClick={enable}>{t.notifications.enablePush}</button>
  );
}
