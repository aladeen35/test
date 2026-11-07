"use client";
import { useTransition } from "react";
import { useI18n } from "@/lib/i18n/client";
import { setLocale, setNetwork } from "@/app/actions/prefs";

export function LangSwitch() {
  const { t, locale } = useI18n();
  const [pending, start] = useTransition();
  return (
    <button type="button" className="btn-ghost min-h-10 px-3 text-sm" disabled={pending}
      lang={locale === "ar" ? "en" : "ar"}
      onClick={() => start(() => setLocale(locale === "ar" ? "en" : "ar"))}>
      {t.common.switchLang}
    </button>
  );
}

export function NetworkSwitch({ current }: { current: "SD" | "SA" }) {
  const { t } = useI18n();
  const [pending, start] = useTransition();
  return (
    <div role="group" aria-label={t.home.switchNetwork} className="inline-flex rounded-xl bg-navy-100 p-1">
      {(["SD", "SA"] as const).map((c) => (
        <button key={c} type="button" disabled={pending} aria-pressed={current === c}
          onClick={() => start(() => setNetwork(c))}
          className={`min-h-9 rounded-lg px-3 text-sm font-semibold ${current === c ? "bg-white text-navy shadow" : "text-muted"}`}>
          {c === "SD" ? t.common.sudan : t.common.saudi}
        </button>
      ))}
    </div>
  );
}
