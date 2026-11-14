"use client";
import { useTransition } from "react";
import { useI18n } from "@/lib/i18n/client";
import { setLocale, setNetwork } from "@/app/actions/prefs";

export function LangSwitch() {
  const { t, locale } = useI18n();
  const [pending, start] = useTransition();
  return (
    <button type="button" className="icon-btn w-auto px-4 text-sm font-semibold" disabled={pending}
      lang={locale === "ar" ? "en" : "ar"}
      onClick={() => start(() => setLocale(locale === "ar" ? "en" : "ar"))}>
      {locale === "ar" ? "EN" : "ع"}
      <span className="sr-only">{t.common.switchLang}</span>
    </button>
  );
}

/** Pill segmented control for the Sudan / Saudi network. `tone="dark"` for use on navy cards. */
export function NetworkSwitch({ current, tone = "light" }: { current: "SD" | "SA"; tone?: "light" | "dark" }) {
  const { t } = useI18n();
  const [pending, start] = useTransition();
  return (
    <div role="group" aria-label={t.home.switchNetwork} className={`inline-flex rounded-full p-1 ${tone === "dark" ? "bg-white/10" : "bg-white shadow-[var(--shadow-card)]"}`}>
      {(["SD", "SA"] as const).map((c) => (
        <button key={c} type="button" disabled={pending} aria-pressed={current === c}
          onClick={() => start(() => setNetwork(c))}
          className={`min-h-9 rounded-full px-4 text-sm font-semibold transition-colors ${
            current === c ? (tone === "dark" ? "bg-sand text-navy-700" : "bg-navy text-white") : tone === "dark" ? "text-white/70" : "text-muted"}`}>
          {c === "SD" ? t.common.sudan : t.common.saudi}
        </button>
      ))}
    </div>
  );
}
