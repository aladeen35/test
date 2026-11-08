/* Swarm rebuild: a crowd of labelled cursors drags the page's pieces into place.
   Used on the home page and the top of the About page, once per visit. Each piece is hidden
   when the route renders (under the preloader), scattered when the build starts, then a
   cursor flies to it, "clicks", drags it home, clicks again and leaves.
   Any wheel / touch / key / click finishes the build at once. */
import { gsap } from "gsap";

const LABELS = ["QA", "QC", "HACCP", "GMP", "ISO 22000", "CCP", "PRP", "SOP", "NCR", "CAPA", "FIFO", "ATP", "KPI", "GHP", "SSOP", "RCA", "Aw", "pH", "CFU", "OPRP", "FSMS", "TVC"];
const COLORS = ["#ddb03f", "#53b9ad", "#f4efe6", "#e5845a", "#8fb7ff", "#c59bff", "#7ed38a"];
const arrow = (c) => `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 2l7.5 19 2.6-7.9L21 10.5z" fill="${c}" stroke="#111" stroke-width="1.4" stroke-linejoin="round"/></svg>`;

/** keep only pieces that are rendered and on the first screen, mark and hide them */
export function prepareSwarm(candidates) {
  const H = window.innerHeight;
  const pieces = candidates.filter((el) => {
    if (!el) return false;
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.top < H * 0.96 && r.bottom > 0;
  });
  pieces.forEach((el) => el.setAttribute("data-swarm", ""));
  gsap.set(pieces, { autoAlpha: 0 });
  return pieces;
}

// the area a piece can be seen in: viewport ∩ its nearest clipping ancestor
function visibleArea(el) {
  let a = { left: 0, top: 0, right: window.innerWidth, bottom: window.innerHeight };
  for (let p = el.parentElement; p && p !== document.body; p = p.parentElement) {
    const s = getComputedStyle(p);
    if (/hidden|clip/.test(s.overflowX + s.overflowY)) {
      const r = p.getBoundingClientRect();
      a = { left: Math.max(a.left, r.left), top: Math.max(a.top, r.top), right: Math.min(a.right, r.right), bottom: Math.min(a.bottom, r.bottom) };
      break;
    }
  }
  return a;
}

/** run the build; returns the timeline (also killed by the caller's gsap.context revert) */
export function runSwarm(pieces, { onDone } = {}) {
  if (!pieces.length) { onDone && onDone(); return null; }
  const W = window.innerWidth, small = W < 760;
  const R = gsap.utils.random;
  const layer = document.createElement("div");
  layer.className = "swarm-layer";
  layer.setAttribute("aria-hidden", "true");
  document.body.appendChild(layer);

  let finished = false;
  const done = () => {
    if (finished) return; finished = true;
    off(); layer.remove();
    gsap.set(pieces, { clearProps: "transform,opacity,visibility" });
    pieces.forEach((el) => el.removeAttribute("data-swarm"));
    onDone && onDone();
  };
  const tl = gsap.timeline({ onComplete: done });

  // measure every final position first (pieces are only hidden, not moved, at this point)
  const boxes = pieces.map((el) => ({ el, r: el.getBoundingClientRect(), a: visibleArea(el) }));
  boxes.forEach(({ el, r, a }, i) => {
    const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    const half = Math.min(r.width / 2, (a.right - a.left) / 3);
    // a loose pile in the lower part of the visible area
    const tx = R(a.left + half, Math.max(a.left + half, a.right - half)), ty = R(a.top + (a.bottom - a.top) * 0.55, a.bottom - Math.min(r.height / 2, 40));
    const sx = tx - cx, sy = ty - cy;
    gsap.set(el, { x: sx, y: sy, rotation: R(-24, 24), scale: 0.74, autoAlpha: 0.32 });

    const color = COLORS[i % COLORS.length];
    const cur = document.createElement("div");
    cur.className = "swarm-cur";
    cur.innerHTML = `${arrow(color)}<i style="background:${color}">${LABELS[i % LABELS.length]}</i>`;
    layer.appendChild(cur);
    gsap.set(cur, { x: i % 2 ? -60 : W + 60, y: R(0, window.innerHeight) });

    const pt = gsap.timeline({ defaults: { ease: "cineInOut" } })
      .to(cur, { x: tx, y: ty, duration: small ? 0.45 : 0.55, ease: "power3.inOut" })            // fly to the loose piece
      .to(cur, { scale: 0.8, duration: 0.08, yoyo: true, repeat: 1, ease: "power1.inOut" })      // click: grab
      .to(el, { autoAlpha: 1, duration: 0.15 }, "<")
      .addLabel("drag")
      .to(el, { x: 0, y: 0, rotation: 0, scale: 1, duration: small ? 0.6 : 0.75 }, "drag")      // drag it home
      .to(cur, { x: cx, y: cy, duration: small ? 0.6 : 0.75 }, "drag")
      .to(cur, { scale: 0.8, duration: 0.08, yoyo: true, repeat: 1, ease: "power1.inOut" })      // click: drop
      .to(el, { scale: 1.04, duration: 0.1, yoyo: true, repeat: 1, ease: "power1.out" }, "<")
      .to(cur, { x: cx + R(-380, 380), y: -80, autoAlpha: 0, duration: 0.55, ease: "power2.in" }, ">0.04"); // leave
    tl.add(pt, i * (small ? 0.06 : 0.085));
  });

  // the visitor is in charge: any interaction completes the build
  const skip = () => tl.progress(1);
  const evs = ["wheel", "touchstart", "keydown", "pointerdown"];
  const off = () => evs.forEach((e) => window.removeEventListener(e, skip, { capture: true }));
  evs.forEach((e) => window.addEventListener(e, skip, { capture: true, passive: true }));
  tl.eventCallback("onInterrupt", done);
  return { tl, cancel: () => { tl.kill(); done(); } };
}
