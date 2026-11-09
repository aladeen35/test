import type { Dict } from "@/lib/i18n";

/** "Designed and developed by Al-Bushra Technology" with the company logo. */
export function Credit({ t, size = 36, className = "", full = false }: { t: Dict; size?: number; className?: string; full?: boolean }) {
  return (
    <span className={`inline-flex items-center gap-2 ${className}`}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={full ? "/brand/albushra-full.png" : "/brand/albushra.png"} alt={full ? "البشري للتكنولوجيا — Al-Bushra Technology" : ""} width={size} height={size} className="rounded-lg" style={{ width: size, height: size }} />
      <span>{t.common.designedBy}</span>
    </span>
  );
}
