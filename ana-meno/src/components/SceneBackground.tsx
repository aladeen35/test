// Full-screen playful scene behind every screen, matching the brand layout:
// bright blue sky, puffy clouds, rolling green hills and a sandy path.
export function SceneBackground() {
  return (
    <div className="fixed inset-0 pointer-events-none select-none" aria-hidden="true">
      <svg
        className="w-full h-full"
        viewBox="0 0 400 860"
        preserveAspectRatio="xMidYMax slice"
      >
        <defs>
          <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#3D9BE9" />
            <stop offset="0.5" stopColor="#7CC4F2" />
            <stop offset="1" stopColor="#C4E8FC" />
          </linearGradient>
        </defs>
        <rect width="400" height="860" fill="url(#sky)" />

        {/* clouds */}
        <g fill="#FFFFFF" opacity="0.92">
          <g transform="translate(60,80)">
            <ellipse cx="0" cy="0" rx="34" ry="16" />
            <ellipse cx="24" cy="-8" rx="22" ry="13" />
            <ellipse cx="-26" cy="-5" rx="18" ry="11" />
          </g>
          <g transform="translate(330,140)">
            <ellipse cx="0" cy="0" rx="28" ry="13" />
            <ellipse cx="20" cy="-7" rx="17" ry="10" />
          </g>
          <g transform="translate(210,50)" opacity="0.8">
            <ellipse cx="0" cy="0" rx="22" ry="10" />
            <ellipse cx="15" cy="-6" rx="13" ry="8" />
          </g>
        </g>

        {/* hills */}
        <path d="M-20 700 Q80 620 200 668 Q320 716 420 650 L420 860 L-20 860 Z" fill="#7CC46B" />
        <path d="M-20 760 Q120 690 260 740 Q350 772 420 740 L420 860 L-20 860 Z" fill="#5BAE54" />

        {/* sandy path */}
        <path d="M150 860 Q190 780 240 745 Q270 724 300 716 Q260 750 236 790 Q216 822 210 860 Z" fill="#E8D5A8" opacity="0.9" />

        {/* flowers */}
        <g fill="#FFFFFF">
          <circle cx="60" cy="780" r="4" /><circle cx="70" cy="774" r="4" />
          <circle cx="80" cy="780" r="4" /><circle cx="70" cy="786" r="4" />
          <circle cx="70" cy="780" r="3" fill="#FFC928" />
        </g>
        <g fill="#F7A6C1">
          <circle cx="345" cy="820" r="4" /><circle cx="355" cy="814" r="4" />
          <circle cx="365" cy="820" r="4" /><circle cx="355" cy="826" r="4" />
          <circle cx="355" cy="820" r="3" fill="#FFC928" />
        </g>
      </svg>
    </div>
  );
}
