import type { Dict } from "@/lib/i18n";
import { Dots, EcgLine } from "./brand-motion";

/** Inline, runs before first paint: the splash shows only on the first page load of a session. */
export const SPLASH_SCRIPT = `try{if(sessionStorage.getItem('fd:splash')){document.documentElement.dataset.splash='done'}else{sessionStorage.setItem('fd:splash','1')}}catch(e){}`;

/**
 * Launch screen. Pure CSS: it animates in, then fades out by itself after ~2.5s,
 * so it never blocks the app even if JavaScript is slow or disabled.
 */
export function Splash({ t }: { t: Dict }) {
  return (
    <div className="fd-splash" role="status" aria-label={t.splash.loading}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/brand/symbol.png" alt="" width={132} height={132} className="fd-logo h-32 w-32 rounded-[2rem] bg-white p-2 shadow-[0_10px_40px_rgb(198_40_40/0.25)]" />
      <EcgLine className="h-8 w-48" />
      <div className="fd-name flex flex-col items-center leading-tight">
        <span className="text-4xl font-bold text-navy" lang="ar">فزعة دم</span>
        <span className="latin text-lg font-extrabold tracking-[0.2em] text-navy">FAZAT DAM</span>
      </div>
      <div className="fd-slogan flex flex-col items-center gap-0.5 text-sm text-navy/80">
        <span lang="ar">فزعتك حياة.. وقطرتك أمل</span>
        <span className="latin">Your Support Saves Lives.</span>
      </div>
      <div className="mt-6"><Dots /></div>
    </div>
  );
}
