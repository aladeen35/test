import type { Dict } from "@/lib/i18n";
import { EcgLine, PulsingDrop } from "./brand-motion";

/** Animated wait screen shown while a page's data loads. */
export function WaitScreen({ t }: { t: Dict }) {
  return (
    <div className="fd-wait flex min-h-[60vh] flex-col items-center justify-center gap-5" role="status" aria-live="polite">
      <PulsingDrop size={88} />
      <EcgLine className="h-8 w-44" />
      <p className="text-sm font-semibold text-navy">{t.splash.wait}</p>
      {/* content-shaped placeholders hint at what is coming */}
      <div className="mt-2 flex w-full max-w-md flex-col gap-3" aria-hidden="true">
        {[0, 1, 2].map((i) => (
          <div key={i} className="card flex animate-pulse items-center gap-3">
            <span className="h-10 w-10 rounded-full bg-brand-50" />
            <span className="flex flex-1 flex-col gap-2">
              <span className="h-3 w-2/3 rounded bg-navy-100" />
              <span className="h-3 w-1/3 rounded bg-navy-100" />
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
