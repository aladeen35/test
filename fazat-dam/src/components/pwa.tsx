"use client";
import { useEffect, useRef, useState } from "react";
import { useI18n } from "@/lib/i18n/client";
import { useClientValue, useOnline } from "@/lib/hooks";
import { OfflineIcon } from "./icons";

export function ServiceWorkerRegister() {
  useEffect(() => {
    if (!("serviceWorker" in navigator) || process.env.NODE_ENV !== "production") return;
    navigator.serviceWorker.register("/sw.js", { scope: "/" }).catch(() => {});
  }, []);
  return null;
}

export function OfflineBanner() {
  const { t } = useI18n();
  const online = useOnline();
  const [flash, setFlash] = useState(false);
  const wasOffline = useRef(false);
  useEffect(() => {
    if (!online) { wasOffline.current = true; return; }
    if (!wasOffline.current) return;
    wasOffline.current = false;
    const show = setTimeout(() => setFlash(true), 0);
    const hide = setTimeout(() => setFlash(false), 3000);
    return () => { clearTimeout(show); clearTimeout(hide); };
  }, [online]);
  if (online && !flash) return null;
  return (
    <div role="status" className={`sticky top-0 z-50 flex items-center justify-center gap-2 px-4 py-2 text-sm font-semibold ${online ? "bg-success text-white" : "bg-navy text-white"}`}>
      {!online && <OfflineIcon className="h-5 w-5" />}
      {online ? t.common.backOnline : t.common.offline}
    </div>
  );
}

type BIPEvent = Event & { prompt: () => Promise<void>; userChoice: Promise<{ outcome: string }> };

export function InstallCard() {
  const { t } = useI18n();
  const [evt, setEvt] = useState<BIPEvent | null>(null);
  const ios = useClientValue(() => /iphone|ipad|ipod/i.test(navigator.userAgent), false);
  const installed = useClientValue(() => window.matchMedia("(display-mode: standalone)").matches, false);
  useEffect(() => {
    const h = (e: Event) => { e.preventDefault(); setEvt(e as BIPEvent); };
    window.addEventListener("beforeinstallprompt", h);
    return () => window.removeEventListener("beforeinstallprompt", h);
  }, []);
  if (installed || (!evt && !ios)) return null;
  return (
    <div className="card flex flex-col gap-2">
      <h2 className="section-title">{t.profile.install}</h2>
      <p className="text-sm text-muted">{ios && !evt ? t.profile.installIos : t.profile.installText}</p>
      {evt && <button className="btn-navy self-start" onClick={async () => { await evt.prompt(); setEvt(null); }}>{t.profile.install}</button>}
    </div>
  );
}
