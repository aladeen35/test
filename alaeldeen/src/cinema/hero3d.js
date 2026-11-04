/* Hero WebGL scene: a slow double helix of gold particles inside drifting dust.
   The camera lerps towards the pointer and the hero scroll progress. The loop only
   runs while the hero is on screen and the tab is visible. Reduced motion renders a
   single still frame. */
import {
  WebGLRenderer, Scene, PerspectiveCamera, BufferGeometry, Float32BufferAttribute, Points,
  PointsMaterial, AdditiveBlending, CanvasTexture, Color, Group, Vector2, SRGBColorSpace,
} from "three";

function dotTexture() {
  const c = document.createElement("canvas"); c.width = c.height = 64;
  const g = c.getContext("2d"); const r = g.createRadialGradient(32, 32, 0, 32, 32, 32);
  r.addColorStop(0, "rgba(255,255,255,1)"); r.addColorStop(0.35, "rgba(255,255,255,.55)"); r.addColorStop(1, "rgba(255,255,255,0)");
  g.fillStyle = r; g.fillRect(0, 0, 64, 64);
  const t = new CanvasTexture(c); t.colorSpace = SRGBColorSpace; return t;
}

export function createHero3D(canvas, { reduce = false, rtl = false } = {}) {
  let renderer;
  try { renderer = new WebGLRenderer({ canvas, alpha: true, antialias: false, powerPreference: "high-performance" }); }
  catch (e) { return { destroy() {}, setActive() {}, setScroll() {} }; } // no WebGL: the CSS gradient stays
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.75));
  renderer.setClearColor(0x000000, 0);

  const scene = new Scene();
  const camera = new PerspectiveCamera(42, 1, 0.1, 100);
  camera.position.set(0, 0, 14);
  const tex = dotTexture();
  const world = new Group(); scene.add(world);

  // --- double helix (two strands + rungs) ---
  const helix = new Group();
  const pos = [], col = [];
  const gold = new Color("#ddb03f"), pale = new Color("#f6dc8e"), teal = new Color("#53b9ad");
  const TURNS = 4.2, N = 900, H = 16, R = 1.9;
  for (let i = 0; i < N; i++) {
    const k = i / N, a = k * Math.PI * 2 * TURNS, y = (k - 0.5) * H;
    for (const ph of [0, Math.PI]) {
      const j = (Math.random() - 0.5) * 0.18;
      pos.push(Math.cos(a + ph) * (R + j), y + j, Math.sin(a + ph) * (R + j));
      const c = (ph ? gold : pale).clone().lerp(teal, Math.random() * 0.12); col.push(c.r, c.g, c.b);
    }
    if (i % 18 === 0) for (let s = 1; s < 9; s++) { // rungs
      const u = s / 9 * 2 - 1; pos.push(Math.cos(a) * R * u, y, Math.sin(a) * R * u); const c = gold.clone().multiplyScalar(0.7); col.push(c.r, c.g, c.b);
    }
  }
  const hg = new BufferGeometry();
  hg.setAttribute("position", new Float32BufferAttribute(pos, 3)); hg.setAttribute("color", new Float32BufferAttribute(col, 3));
  const hm = new PointsMaterial({ size: 0.13, map: tex, vertexColors: true, transparent: true, depthWrite: false, blending: AdditiveBlending, opacity: 0.95 });
  helix.add(new Points(hg, hm));
  helix.rotation.z = rtl ? 0.42 : -0.42;
  helix.position.x = rtl ? -3.2 : 3.2;
  world.add(helix);

  // --- dust field ---
  const dp = [], DN = 1400;
  for (let i = 0; i < DN; i++) dp.push((Math.random() - 0.5) * 34, (Math.random() - 0.5) * 20, (Math.random() - 0.5) * 18 - 2);
  const dg = new BufferGeometry(); dg.setAttribute("position", new Float32BufferAttribute(dp, 3));
  const dm = new PointsMaterial({ size: 0.06, map: tex, color: 0xddb03f, transparent: true, depthWrite: false, blending: AdditiveBlending, opacity: 0.55 });
  const dust = new Points(dg, dm); world.add(dust);

  // --- camera rig ---
  const pointer = new Vector2(0, 0), look = new Vector2(0, 0);
  let scroll = 0, scrollL = 0, active = true, raf = 0, last = performance.now();
  const onMove = (e) => { pointer.set((e.clientX / window.innerWidth) * 2 - 1, (e.clientY / window.innerHeight) * 2 - 1); };
  window.addEventListener("pointermove", onMove, { passive: true });

  const resize = () => {
    const w = canvas.clientWidth || canvas.parentElement.clientWidth, h = canvas.clientHeight || canvas.parentElement.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h, false); camera.aspect = w / h;
    // keep the helix framed on narrow screens
    camera.position.z = w < 700 ? 19 : 14; helix.position.x = w < 900 ? 0 : (rtl ? -3.2 : 3.2);
    camera.updateProjectionMatrix();
    if (reduce) renderer.render(scene, camera);
  };
  const ro = new ResizeObserver(resize); ro.observe(canvas.parentElement); resize();

  const frame = (now) => {
    raf = requestAnimationFrame(frame);
    if (!active || document.hidden) { last = now; return; }
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    // lerp everything: pointer → look, scroll → scrollL
    look.lerp(pointer, 1 - Math.pow(0.0015, dt));
    scrollL += (scroll - scrollL) * (1 - Math.pow(0.002, dt));
    helix.rotation.y += dt * 0.22;
    dust.rotation.y += dt * 0.012; dust.position.y = scrollL * 2.5;
    camera.position.x = look.x * 1.2;
    camera.position.y = -look.y * 0.8 - scrollL * 2.2;
    world.rotation.x = scrollL * 0.35;
    helix.scale.setScalar(1 + scrollL * 0.18);
    camera.lookAt(0, -scrollL * 1.5, 0);
    renderer.render(scene, camera);
  };
  if (reduce) renderer.render(scene, camera); else raf = requestAnimationFrame(frame);

  return {
    setActive(v) { active = v; },
    setScroll(p) { scroll = p; },
    destroy() {
      cancelAnimationFrame(raf); ro.disconnect(); window.removeEventListener("pointermove", onMove);
      hg.dispose(); hm.dispose(); dg.dispose(); dm.dispose(); tex.dispose(); renderer.dispose();
    },
  };
}
