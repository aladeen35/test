// Original logo mark inspired by the brand artwork: deep-blue speech bubble,
// sunny question mark, magnifier hint.
export function LogoMark({ size = 96 }: { size?: number }) {
  return (
    <svg viewBox="0 0 120 120" width={size} height={size} aria-hidden="true">
      <circle cx="60" cy="58" r="52" fill="#1E63C8" />
      <circle cx="60" cy="58" r="44" fill="#3B82E0" />
      <text
        x="60" y="86" textAnchor="middle" fontSize="64" fontWeight="900"
        fontFamily="Cairo, sans-serif" fill="#FFC928"
        stroke="#173B6C" strokeWidth="2" paintOrder="stroke"
      >
        ؟
      </text>
      <g transform="translate(84,84) rotate(40)">
        <rect x="-4" y="14" width="8" height="20" rx="4" fill="#8A5A44" />
        <circle cx="0" cy="0" r="15" fill="none" stroke="#FFC928" strokeWidth="7" />
        <circle cx="0" cy="0" r="11" fill="#A8DCF7" opacity="0.55" />
      </g>
    </svg>
  );
}

export function LogoTitle({ className = '', light = false }: { className?: string; light?: boolean }) {
  return (
    <h1
      className={`font-cairo font-black ${light
        ? 'text-sun drop-shadow-[0_2px_0_rgba(23,59,108,0.9)]'
        : 'text-navy drop-shadow-[0_2px_0_rgba(255,255,255,0.9)]'} ${className}`}
      style={{ letterSpacing: '0.01em' }}
    >
      أنا مِنو <span aria-hidden="true">🤔</span>
    </h1>
  );
}
