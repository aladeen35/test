"use client";
import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import { fmt } from "@/lib/i18n";
import { getBrowserClient } from "@/lib/supabase/client";

const PREFIX = { SA: "966", SD: "249" } as const;
// Phone OTP needs an SMS provider in Supabase. Turn it on with NEXT_PUBLIC_AUTH_PHONE=1 once that is configured.
const PHONE_ENABLED = process.env.NEXT_PUBLIC_AUTH_PHONE === "1";

export function LoginForm({ next, linkError = false }: { next: string; linkError?: boolean }) {
  const { t } = useI18n();
  const router = useRouter();
  const [mode, setMode] = useState<"email" | "phone">("email");
  const [email, setEmail] = useState("");
  const [country, setCountry] = useState<"SA" | "SD">("SA");
  const [local, setLocal] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<"start" | "code">("start");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(linkError ? t.auth.linkFailed : null);

  const digits = local.replace(/\D/g, "").replace(/^0+/, "");
  const phone = `+${PREFIX[country]}${digits}`;
  const phoneValid = digits.length >= 8 && digits.length <= 10;
  const emailClean = email.trim().toLowerCase();
  const emailValid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(emailClean);

  function mapError(message: string) {
    if (/rate|too many|seconds/i.test(message)) return t.auth.tooMany;
    if (/token|otp|expired|invalid/i.test(message)) return step === "code" ? t.auth.invalidCode : mode === "email" ? t.auth.invalidEmail : t.auth.invalidPhone;
    return t.errors.generic;
  }

  async function send(e?: React.FormEvent) {
    e?.preventDefault();
    if (mode === "email" ? !emailValid : !phoneValid) return setError(mode === "email" ? t.auth.invalidEmail : t.auth.invalidPhone);
    setBusy(true); setError(null);
    const lang = document.documentElement.lang;
    const auth = getBrowserClient().auth;
    const { error } = mode === "email"
      ? await auth.signInWithOtp({ email: emailClean, options: { emailRedirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`, data: { lang } } })
      : await auth.signInWithOtp({ phone, options: { channel: "sms", data: { lang } } });
    setBusy(false);
    if (error) return setError(mapError(error.message));
    setStep("code");
  }

  async function verify(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true); setError(null);
    const auth = getBrowserClient().auth;
    const { error } = mode === "email"
      ? await auth.verifyOtp({ email: emailClean, token: code.trim(), type: "email" })
      : await auth.verifyOtp({ phone, token: code.trim(), type: "sms" });
    setBusy(false);
    if (error) return setError(mapError(error.message));
    router.replace(`/onboarding?next=${encodeURIComponent(next)}`);
    router.refresh();
  }

  function switchMode(m: "email" | "phone") { setMode(m); setStep("start"); setCode(""); setError(null); }

  return (
    <div className="card flex flex-col gap-4">
      <div>
        <h1 className="page-title">{mode === "email" ? t.auth.titleEmail : t.auth.title}</h1>
        <p className="mt-1 text-sm text-muted">{mode === "email" ? t.auth.subtitleEmail : t.auth.subtitle}</p>
      </div>
      {PHONE_ENABLED && (
        <div role="tablist" className="inline-flex self-start rounded-full bg-surface-2 p-1">
          {(["email", "phone"] as const).map((m) => (
            <button key={m} role="tab" type="button" aria-selected={mode === m} onClick={() => switchMode(m)}
              className={`min-h-9 rounded-full px-4 text-sm font-semibold ${mode === m ? "bg-navy text-white" : "text-muted"}`}>
              {m === "email" ? t.auth.useEmail : t.auth.usePhone}
            </button>
          ))}
        </div>
      )}
      {step === "start" ? (
        <form onSubmit={send} className="flex flex-col gap-4" noValidate>
          {mode === "email" ? (
            <div className="field">
              <label className="label" htmlFor="email">{t.auth.email}</label>
              <input id="email" type="email" className="input latin" inputMode="email" autoComplete="email" required dir="ltr"
                value={email} onChange={(e) => setEmail(e.target.value)} placeholder="name@example.com" />
            </div>
          ) : (
            <div className="field">
              <label className="label" htmlFor="phone">{t.auth.phone}</label>
              <div className="flex gap-2" dir="ltr">
                <select aria-label={t.common.country} className="input w-32" value={country} onChange={(e) => setCountry(e.target.value as "SA" | "SD")}>
                  <option value="SA">🇸🇦 +966</option>
                  <option value="SD">🇸🇩 +249</option>
                </select>
                <input id="phone" className="input latin flex-1" inputMode="tel" autoComplete="tel-national" required
                  value={local} onChange={(e) => setLocal(e.target.value)} placeholder={country === "SA" ? "5XXXXXXXX" : "9XXXXXXXX"} />
              </div>
              <span className="hint">{t.auth.phoneHint}</span>
            </div>
          )}
          {error && <p role="alert" className="text-sm text-brand-600">{error}</p>}
          <button className="btn-primary" disabled={busy}>{busy ? t.common.loading : mode === "email" ? t.auth.sendLink : t.auth.sendCode}</button>
          <p className="text-xs text-muted">
            {t.auth.agree.split(/(\{privacy\}|\{terms\})/).map((part, i) =>
              part === "{privacy}" ? <Link key={i} href="/privacy" className="underline">{t.nav.privacy}</Link>
              : part === "{terms}" ? <Link key={i} href="/terms" className="underline">{t.nav.terms}</Link>
              : <span key={i}>{part}</span>)}
          </p>
        </form>
      ) : (
        <form onSubmit={verify} className="flex flex-col gap-4">
          <div role="status" className="rounded-[var(--radius-tile)] bg-success-50 px-4 py-3 text-sm text-navy">
            <p className="font-semibold">{fmt(mode === "email" ? t.auth.linkSent : t.auth.sent, { email: "", phone: "" })}<span className="latin">{mode === "email" ? emailClean : phone}</span></p>
            {mode === "email" && <p className="mt-1 text-muted">{t.auth.linkHelp}</p>}
          </div>
          <div className="field">
            <label className="label" htmlFor="code">{t.auth.code}{mode === "email" ? ` (${t.common.optional})` : ""}</label>
            <input id="code" className="input latin text-center text-2xl tracking-[0.5em]" inputMode="numeric" autoComplete="one-time-code"
              pattern="[0-9]{6}" maxLength={6} required value={code} onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))} />
            <span className="hint">{t.auth.codeHint}</span>
          </div>
          {error && <p role="alert" className="text-sm text-brand-600">{error}</p>}
          <button className="btn-primary" disabled={busy || code.length !== 6}>{busy ? t.common.loading : t.auth.verify}</button>
          {mode === "email" && <p className="hint">{t.auth.checkSpam}</p>}
          <div className="flex justify-between">
            <button type="button" className="btn-ghost text-sm" onClick={() => { setStep("start"); setCode(""); }}>{mode === "email" ? t.auth.changeEmail : t.auth.changePhone}</button>
            <button type="button" className="btn-ghost text-sm" disabled={busy} onClick={() => send()}>{t.auth.resend}</button>
          </div>
        </form>
      )}
    </div>
  );
}
