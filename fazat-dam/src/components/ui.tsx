import Link from "next/link";
import type { Dict } from "@/lib/i18n";
import type { RequestStatus } from "@/lib/constants";

export function Logo({ size = 40, withText = true, label }: { size?: number; withText?: boolean; label: string }) {
  return (
    <span className="inline-flex items-center gap-2">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/brand/symbol.png" alt="" width={size} height={size} className="rounded-full bg-white" style={{ width: size, height: size }} />
      {withText && <span className="text-lg font-bold leading-none text-navy">{label}</span>}
    </span>
  );
}

const STATUS_STYLE: Record<RequestStatus, string> = {
  submitted: "bg-navy-100 text-navy",
  under_review: "bg-sand-50 text-sand-600",
  verified: "bg-navy text-white",
  matching_donors: "bg-brand-50 text-brand-600",
  donors_responding: "bg-brand-50 text-brand-600",
  donation_arranged: "bg-success-50 text-success",
  completed: "bg-success text-white",
  rejected: "bg-zinc-200 text-zinc-700",
  cancelled: "bg-zinc-100 text-zinc-600",
  expired: "bg-zinc-100 text-zinc-600",
};

export function StatusBadge({ status, t }: { status: RequestStatus; t: Dict }) {
  return <span className={`chip ${STATUS_STYLE[status]}`}>{t.status[status]}</span>;
}

export function Chip({ tone = "navy", children }: { tone?: "navy" | "red" | "green" | "amber" | "gray" | "sand"; children: React.ReactNode }) {
  const tones = {
    navy: "bg-navy-100 text-navy",
    red: "bg-brand-50 text-brand-600",
    green: "bg-success-50 text-success",
    amber: "bg-sand-50 text-sand-600",
    sand: "bg-sand-50 text-sand-600",
    gray: "bg-surface-2 text-muted",
  };
  return <span className={`chip ${tones[tone]}`}>{children}</span>;
}

export function BloodChip({ group, size = "md" }: { group: string; size?: "md" | "lg" }) {
  const s = size === "lg" ? "h-14 w-14 text-xl" : "h-10 w-10 text-sm";
  return (
    <span className={`blood-disc latin inline-flex shrink-0 items-center justify-center rounded-full font-bold text-white ${s}`} aria-label={group}>
      {group}
    </span>
  );
}

export function DemoBadge({ t }: { t: Dict }) {
  return <span className="chip border border-dashed border-sand bg-sand-50 text-sand-600">{t.common.demo}</span>;
}

export function Empty({ children, action }: { children: React.ReactNode; action?: React.ReactNode }) {
  return (
    <div className="card flex flex-col items-center gap-3 py-10 text-center text-muted">
      <span className="flex h-14 w-14 items-center justify-center rounded-full bg-surface-2" aria-hidden>
        <svg viewBox="0 0 24 24" className="h-6 w-6 text-muted/70" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z" /></svg>
      </span>
      <p className="max-w-xs text-sm">{children}</p>
      {action}
    </div>
  );
}

export function PageHeader({ title, intro, action }: { title: string; intro?: string; action?: React.ReactNode }) {
  return (
    <div className="mb-5 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="page-title">{title}</h1>
        {intro && <p className="mt-1.5 max-w-2xl text-sm text-muted">{intro}</p>}
      </div>
      {action}
    </div>
  );
}

export function Notice({ tone = "info", children }: { tone?: "info" | "warn" | "error" | "ok"; children: React.ReactNode }) {
  const tones = {
    info: "bg-navy-100/70 text-navy",
    warn: "bg-sand-50 text-navy",
    error: "bg-brand-50 text-brand-600",
    ok: "bg-success-50 text-success",
  };
  return <div role={tone === "error" ? "alert" : "status"} className={`rounded-[var(--radius-tile)] px-4 py-3 text-sm leading-6 ${tones[tone]}`}>{children}</div>;
}

export function MedicalNotice({ t }: { t: Dict }) {
  return (
    <Notice tone="warn">
      <strong className="block">{t.legal.medicalTitle}</strong>
      {t.legal.medical}
    </Notice>
  );
}

export function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="card flex flex-col gap-1">
      <span className="latin text-3xl font-bold text-navy">{value}</span>
      <span className="text-xs text-muted">{label}</span>
    </div>
  );
}

export function LinkCard({ href, title, sub, icon, tone = "white" }: { href: string; title: string; sub?: string; icon?: React.ReactNode; tone?: "red" | "navy" | "white" }) {
  const tones = { red: "bg-brand text-white", navy: "bg-navy-800 text-white", white: "bg-white text-navy" };
  return (
    <Link href={href} className={`flex min-h-24 items-center gap-4 rounded-[var(--radius-card)] p-5 shadow-[var(--shadow-card)] transition-transform active:scale-[0.99] ${tones[tone]}`}>
      {icon}
      <span className="flex flex-col">
        <span className="text-lg font-bold">{title}</span>
        {sub && <span className="text-sm opacity-85">{sub}</span>}
      </span>
    </Link>
  );
}

export function Field({ label, hint, htmlFor, children }: { label: string; hint?: string; htmlFor?: string; children: React.ReactNode }) {
  return (
    <div className="field">
      <label className="label" htmlFor={htmlFor}>{label}</label>
      {children}
      {hint && <span className="hint">{hint}</span>}
    </div>
  );
}

export function SetupMissing({ t }: { t: Dict }) {
  return <Notice tone="warn">{t.common.setupMissing}</Notice>;
}
