"use client";
import { useState } from "react";
import { useI18n } from "@/lib/i18n/client";

const svg = { width: 20, height: 20, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 2, strokeLinecap: "round" as const, strokeLinejoin: "round" as const, "aria-hidden": true };

function useCopy() {
  const [copied, setCopied] = useState(false);
  async function copy(url: string) {
    try {
      await navigator.clipboard.writeText(url);
    } catch {
      const input = document.createElement("input");
      input.value = url;
      document.body.appendChild(input);
      input.select();
      try { document.execCommand("copy"); } catch { /* ignore */ }
      input.remove();
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1600);
  }
  return { copied, copy };
}

function Toast({ show, text }: { show: boolean; text: string }) {
  return (
    <span role="status" aria-live="polite"
      className={`pointer-events-none fixed inset-x-0 bottom-28 z-50 mx-auto w-fit rounded-full bg-navy px-5 py-2.5 text-sm font-semibold text-white transition-opacity motion-reduce:transition-none md:bottom-8 ${show ? "opacity-100" : "opacity-0"}`}>
      {show ? text : ""}
    </span>
  );
}

/** Share button: native share sheet when available, else copies the link. */
export function ShareButton({ url, title }: { url: string; title: string }) {
  const { t } = useI18n();
  const { copied, copy } = useCopy();
  return (
    <>
      <button type="button" className="btn-outline w-full min-h-14 px-3"
        onClick={() => {
          if (navigator.share) navigator.share({ title, url }).catch(() => {});
          else copy(url);
        }}>
        <svg {...svg} className="text-brand"><circle cx="18" cy="5" r="2.5" /><circle cx="6" cy="12" r="2.5" /><circle cx="18" cy="19" r="2.5" /><path d="M8.2 10.8l7.6-4.4M8.2 13.2l7.6 4.4" /></svg>
        {t.dev.share}
      </button>
      <Toast show={copied} text={t.dev.copied} />
    </>
  );
}

/** Round copy-to-clipboard button for a URL. */
export function CopyButton({ url }: { url: string }) {
  const { t } = useI18n();
  const { copied, copy } = useCopy();
  return (
    <>
      <button type="button" className="icon-btn bg-brand-50 text-brand-600" aria-label={t.dev.copy} onClick={() => copy(url)}>
        <svg {...svg}><rect x="8" y="8" width="12" height="12" rx="2" /><path d="M16 8V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h3" /></svg>
      </button>
      <Toast show={copied} text={t.dev.copied} />
    </>
  );
}
