import type { Dict } from "@/lib/i18n";
import { fmt } from "@/lib/i18n";
import { REQUEST_FLOW, type RequestStatus } from "@/lib/constants";
import { CheckIcon } from "./icons";

// One heartbeat per stage, drawn across the full width.
const BEAT = (x: number) => `L${x + 34} 20 L${x + 42} 6 L${x + 52} 34 L${x + 60} 14 L${x + 66} 20 L${x + 100} 20`;
const PATH = "M0 20 " + Array.from({ length: 6 }, (_, i) => BEAT(i * 100)).join(" ");

/** Request stages as a heartbeat line that fills with red as the request advances. */
export function RequestTimeline({ status, t }: { status: RequestStatus; t: Dict }) {
  const idx = REQUEST_FLOW.indexOf(status);
  const off = idx === -1; // rejected / cancelled / expired
  const total = REQUEST_FLOW.length;
  const pct = off ? 0 : (idx / (total - 1)) * 100;
  const next = !off && idx < total - 1 ? REQUEST_FLOW[idx + 1] : null;
  return (
    <div aria-label={t.request.timeline}>
      <div className="fd-track relative h-12" aria-hidden="true">
        <svg viewBox="0 0 600 40" preserveAspectRatio="none" className="absolute inset-x-3.5 top-1 h-10 w-[calc(100%-1.75rem)]">
          <path d={PATH} fill="none" stroke="var(--color-line)" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" vectorEffect="non-scaling-stroke" />
        </svg>
        <svg viewBox="0 0 600 40" preserveAspectRatio="none" className="fd-track-fill absolute inset-x-3.5 top-1 h-10 w-[calc(100%-1.75rem)]" style={{ "--p": `${pct}%` } as React.CSSProperties}>
          <path d={PATH} fill="none" stroke={status === "completed" ? "var(--color-success)" : "var(--color-brand)"} strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round" vectorEffect="non-scaling-stroke" />
        </svg>
        <div className="absolute inset-x-0 top-1/2 flex -translate-y-1/2 justify-between">
          {REQUEST_FLOW.map((s, i) => {
            const done = !off && i < idx, current = !off && i === idx;
            return (
              <span key={s} className={`flex h-7 w-7 items-center justify-center rounded-full border-2 text-[0.7rem] font-bold ${
                done ? "border-success bg-success text-white"
                : current ? `border-brand bg-brand text-white ${status === "completed" ? "" : "fd-critical"}`
                : "border-line bg-white text-muted"}`}>
                {done || (current && status === "completed") ? <CheckIcon className="h-4 w-4" /> : <span className="latin">{i + 1}</span>}
              </span>
            );
          })}
        </div>
      </div>
      <ol className="sr-only">
        {REQUEST_FLOW.map((s, i) => <li key={s} aria-current={!off && i === idx ? "step" : undefined}>{t.status[s]}</li>)}
      </ol>
      <div className="mt-3 flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1">
        <p className={`text-lg font-bold ${off ? "text-zinc-600" : status === "completed" ? "text-success" : "text-navy"}`}>{t.status[status]}</p>
        {!off && <p className="text-xs text-muted">{fmt(t.home.stepOf, { n: idx + 1, total })}</p>}
      </div>
      {next && <p className="text-sm text-muted">{fmt(t.home.nextStep, { s: t.status[next] })}</p>}
    </div>
  );
}
