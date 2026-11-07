"use client";
import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import { fmt } from "@/lib/i18n";
import { getBrowserClient } from "@/lib/supabase/client";

const PREFIX = { SA: "966", SD: "249" } as const;

export function LoginForm({ next }: { next: string }) {
  const { t } = useI18n();
  const router = useRouter();
  const [country, setCountry] = useState<"SA" | "SD">("SA");
  const [local, setLocal] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<"phone" | "code">("phone");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const digits = local.replace(/\D/g, "").replace(/^0+/, "");
  const phone = `+${PREFIX[country]}${digits}`;
  const phoneValid = digits.length >= 8 && digits.length <= 10;

  function mapError(message: string) {
    if (/rate|too many|seconds/i.test(message)) return t.auth.tooMany;
    if (/token|otp|expired|invalid/i.test(message)) return step === "code" ? t.auth.invalidCode : t.auth.invalidPhone;
    return t.errors.generic;
  }

  async function sendCode(e?: React.FormEvent) {
    e?.preventDefault();
    if (!phoneValid) return setError(t.auth.invalidPhone);
    setBusy(true); setError(null);
    const { error } = await getBrowserClient().auth.signInWithOtp({ phone, options: { channel: "sms", data: { lang: document.documentElement.lang } } });
    setBusy(false);
    if (error) return setError(mapError(error.message));
    setStep("code");
  }

  async function verify(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true); setError(null);
    const { error } = await getBrowserClient().auth.verifyOtp({ phone, token: code.trim(), type: "sms" });
    setBusy(false);
    if (error) return setError(mapError(error.message));
    router.replace(`/onboarding?next=${encodeURIComponent(next)}`);
    router.refresh();
  }

  return (
    <div className="card flex flex-col gap-4">
      <div>
        <h1 className="page-title">{t.auth.title}</h1>
        <p className="mt-1 text-sm text-muted">{t.auth.subtitle}</p>
      </div>
      {step === "phone" ? (
        <form onSubmit={sendCode} className="flex flex-col gap-4">
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
          {error && <p role="alert" className="text-sm text-brand-600">{error}</p>}
          <button className="btn-primary" disabled={busy}>{busy ? t.common.loading : t.auth.sendCode}</button>
          <p className="text-xs text-muted">
            {t.auth.agree.split(/(\{privacy\}|\{terms\})/).map((part, i) =>
              part === "{privacy}" ? <Link key={i} href="/privacy" className="underline">{t.nav.privacy}</Link>
              : part === "{terms}" ? <Link key={i} href="/terms" className="underline">{t.nav.terms}</Link>
              : <span key={i}>{part}</span>)}
          </p>
        </form>
      ) : (
        <form onSubmit={verify} className="flex flex-col gap-4">
          <p className="text-sm text-navy">{fmt(t.auth.sent, { phone: "" })}<span className="latin font-semibold">{phone}</span></p>
          <div className="field">
            <label className="label" htmlFor="code">{t.auth.code}</label>
            <input id="code" className="input latin text-center text-2xl tracking-[0.5em]" inputMode="numeric" autoComplete="one-time-code"
              pattern="[0-9]{6}" maxLength={6} required value={code} onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))} />
            <span className="hint">{t.auth.codeHint}</span>
          </div>
          {error && <p role="alert" className="text-sm text-brand-600">{error}</p>}
          <button className="btn-primary" disabled={busy || code.length !== 6}>{busy ? t.common.loading : t.auth.verify}</button>
          <div className="flex justify-between">
            <button type="button" className="btn-ghost text-sm" onClick={() => { setStep("phone"); setCode(""); }}>{t.auth.changePhone}</button>
            <button type="button" className="btn-ghost text-sm" disabled={busy} onClick={() => sendCode()}>{t.auth.resend}</button>
          </div>
        </form>
      )}
    </div>
  );
}
