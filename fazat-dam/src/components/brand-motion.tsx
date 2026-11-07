// Animated brand pieces used by the splash and wait screens (CSS-only motion, no JS needed).
export function EcgLine({ className = "h-8 w-40", color = "var(--color-brand)" }: { className?: string; color?: string }) {
  return (
    <svg viewBox="0 0 200 40" className={`fd-ecg ${className}`} aria-hidden="true">
      <path d="M0 22 H62 L72 22 L80 6 L92 36 L102 14 L110 22 H200" fill="none" stroke={color} strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function PulsingDrop({ size = 96 }: { size?: number }) {
  return (
    <span className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <span className="fd-ripple" />
      <span className="fd-ripple r2" />
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/brand/symbol.png" alt="" width={size} height={size} className="fd-heart relative rounded-full bg-white shadow-lg" style={{ width: size, height: size }} />
    </span>
  );
}

export function Dots() {
  return <span className="fd-dots inline-flex gap-1.5" aria-hidden="true"><span /><span /><span /></span>;
}
