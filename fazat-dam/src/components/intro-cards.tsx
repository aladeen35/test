"use client";
import { useRef, useState, useSyncExternalStore } from "react";
import { useI18n } from "@/lib/i18n/client";
import { DropIcon, HeartIcon, ShieldIcon } from "./icons";
import { EcgLine } from "./brand-motion";

const KEY = "fd:intro-done";
const listeners = new Set<() => void>();
const subscribe = (cb: () => void) => { listeners.add(cb); return () => listeners.delete(cb); };
const readDone = () => { try { return localStorage.getItem(KEY) === "1"; } catch { return true; } };

/** First-launch introduction: four swipeable cards, shown once per device. */
export function IntroCards() {
  const { t, locale } = useI18n();
  const done = useSyncExternalStore(subscribe, readDone, () => true);
  const [index, setIndex] = useState(0);
  const track = useRef<HTMLDivElement>(null);
  if (done) return null;

  const cards = [
    // eslint-disable-next-line @next/next/no-img-element
    { title: t.intro.c1Title, body: t.intro.c1Body, art: <img src="/brand/logo-full.png" alt="" className="h-44 w-auto rounded-2xl bg-white" />, tone: "from-white to-brand-50" },
    { title: t.intro.c2Title, body: t.intro.c2Body, art: <DropIcon className="h-24 w-24 text-white" />, tone: "from-brand-400 to-brand-600", dark: true },
    { title: t.intro.c3Title, body: t.intro.c3Body, art: <HeartIcon className="fd-heart h-24 w-24 text-white" />, tone: "from-navy to-navy-700", dark: true },
    { title: t.intro.c4Title, body: t.intro.c4Body, art: <ShieldIcon className="h-24 w-24 text-success" />, tone: "from-white to-success-50" },
  ];
  const last = index === cards.length - 1;

  function finish() {
    try { localStorage.setItem(KEY, "1"); } catch {}
    listeners.forEach((l) => l());
  }
  function go(i: number) {
    const el = track.current;
    if (!el) return;
    const w = el.clientWidth;
    // scrollLeft is negative in RTL in modern browsers
    el.scrollTo({ left: (locale === "ar" ? -1 : 1) * i * w, behavior: "smooth" });
    setIndex(i);
  }

  return (
    <div className="fd-intro fixed inset-0 z-[90] flex items-end justify-center bg-navy/60 backdrop-blur-sm sm:items-center" role="dialog" aria-modal="true" aria-label={t.intro.label}
      style={{ animationDelay: "2.2s" }}>
      <div className="flex h-[min(640px,92dvh)] w-full max-w-md flex-col overflow-hidden rounded-t-3xl bg-white shadow-2xl sm:rounded-3xl">
        <div className="flex justify-end p-3">
          <button className="btn-ghost min-h-10 text-sm" onClick={finish}>{t.intro.skip}</button>
        </div>
        <div ref={track} className="flex flex-1 snap-x snap-mandatory overflow-x-auto [scrollbar-width:none]"
          onScroll={(e) => { const el = e.currentTarget; setIndex(Math.round(Math.abs(el.scrollLeft) / el.clientWidth)); }}>
          {cards.map((c, i) => (
            <section key={i} aria-roledescription="slide" aria-label={`${i + 1} / ${cards.length}`} className="flex w-full shrink-0 snap-center flex-col items-center gap-5 px-6">
              <div className={`flex h-56 w-full items-center justify-center rounded-3xl bg-gradient-to-br ${c.tone}`}>
                <div className={index === i ? "fd-card-in" : ""}>{c.art}</div>
              </div>
              <EcgLine className="h-6 w-32" color={c.dark ? "var(--color-navy)" : "var(--color-brand)"} />
              <h2 className="text-center text-2xl font-bold text-navy">{c.title}</h2>
              <p className="text-center leading-7 text-muted">{c.body}</p>
            </section>
          ))}
        </div>
        <div className="flex items-center justify-between gap-3 p-5">
          <div className="flex gap-1.5" role="tablist">
            {cards.map((_, i) => (
              <button key={i} role="tab" aria-selected={index === i} aria-label={`${i + 1}`} onClick={() => go(i)}
                className={`h-2.5 rounded-full transition-all ${index === i ? "w-7 bg-brand" : "w-2.5 bg-navy-100"}`} />
            ))}
          </div>
          <button className="btn-primary min-w-32" onClick={() => (last ? finish() : go(index + 1))}>{last ? t.intro.start : t.intro.next}</button>
        </div>
      </div>
    </div>
  );
}
