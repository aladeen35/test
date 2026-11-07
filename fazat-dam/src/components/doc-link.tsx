"use client";
import { useState } from "react";
import { getDocumentUrl } from "@/app/actions/requests";

/** Private documents open through a short-lived signed URL created on click. */
export function DocLink({ bucket, path, name }: { bucket: "request-documents" | "initiative-documents" | "institution-documents"; path: string; name: string }) {
  const [busy, setBusy] = useState(false);
  return (
    <button type="button" disabled={busy} className="text-start text-sm font-semibold text-brand-600 underline underline-offset-4"
      onClick={async () => {
        setBusy(true);
        const url = await getDocumentUrl(bucket, path);
        setBusy(false);
        if (url) window.open(url, "_blank", "noopener,noreferrer");
      }}>
      {name}
    </button>
  );
}
