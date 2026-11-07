import type { Dict } from "@/lib/i18n";
import { REQUEST_FLOW, type RequestStatus } from "@/lib/constants";
import { CheckIcon } from "./icons";

export function RequestTimeline({ status, t }: { status: RequestStatus; t: Dict }) {
  const idx = REQUEST_FLOW.indexOf(status);
  const terminalOff = idx === -1; // rejected / cancelled / expired
  return (
    <ol className="flex flex-col gap-0" aria-label={t.request.timeline}>
      {REQUEST_FLOW.map((s, i) => {
        const done = !terminalOff && i < idx;
        const current = !terminalOff && i === idx;
        return (
          <li key={s} className="flex items-center gap-3 py-1.5">
            <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border-2 text-xs font-bold ${
              done ? "border-success bg-success text-white" : current ? "border-brand bg-brand text-white" : "border-line bg-white text-muted"}`}>
              {done ? <CheckIcon className="h-4 w-4" /> : <span className="latin">{i + 1}</span>}
            </span>
            <span className={`text-sm ${current ? "font-bold text-navy" : done ? "text-navy" : "text-muted"}`} aria-current={current ? "step" : undefined}>{t.status[s]}</span>
          </li>
        );
      })}
      {terminalOff && (
        <li className="flex items-center gap-3 py-1.5">
          <span className="flex h-7 w-7 items-center justify-center rounded-full border-2 border-zinc-400 bg-zinc-200 text-xs font-bold text-zinc-700">✕</span>
          <span className="text-sm font-bold text-navy">{t.status[status]}</span>
        </li>
      )}
    </ol>
  );
}
