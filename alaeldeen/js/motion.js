/* Cinematic scroll motion: hero entrance, parallax, staggered reveals, image curtains,
   counters, scroll progress, shrinking header. Only transform/opacity/clip-path are
   animated. Everything is skipped when the visitor prefers reduced motion. */
(function () {
  "use strict";
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
  const on = () => !reduce.matches;
  const root = document.documentElement;
  if (on()) root.classList.add("motion");

  const REVEAL = [
    ".sec-hd", ".card", ".fact", ".tl", ".lsec", ".strip .it", ".band q", ".band .btn",
    ".ph .crumbs", ".ph .eyebrow", ".ph h1", ".ph p", ".ph .cta", "details.faq", ".kv > div",
    ".disclaimer", ".link-group", ".book-copy > *", ".bh-body > *", ".searchbar", ".filters", ".article > *", ".profile-top > div > *",
  ].join(",");
  const CURTAIN = ".qa-about img, .profile-photo img, .book-cover img, .book-thumb img, .video img";

  let io;
  function observer() {
    if (io) return io;
    io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (!e.isIntersecting) return;
        const el = e.target; io.unobserve(el);
        el.classList.add("in");
        if (el.matches(".fact")) count(el.querySelector("b"));
        // once the entrance has played, hand the element back to its normal hover transitions
        const done = () => { el.classList.remove("rv", "in", "rv-curtain"); el.style.removeProperty("--d"); };
        setTimeout(done, 1400 + (parseFloat(el.style.getPropertyValue("--d")) || 0));
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.12 });
    return io;
  }

  function count(b) {
    if (!b || b.dataset.counted) return;
    const m = b.textContent.trim().match(/^(\d+)(.*)$/); if (!m) return;
    b.dataset.counted = "1";
    const end = +m[1], tail = m[2], t0 = performance.now(), dur = 1300;
    if (!end) return;
    const step = (now) => {
      const k = Math.min(1, (now - t0) / dur), e = 1 - Math.pow(1 - k, 4);
      b.textContent = Math.round(end * e) + tail;
      if (k < 1) requestAnimationFrame(step);
    };
    b.textContent = "0" + tail; requestAnimationFrame(step);
  }

  function apply(main) {
    if (!on()) return;
    main.classList.remove("enter"); void main.offsetWidth; main.classList.add("enter");
    const ob = observer();
    main.querySelectorAll(REVEAL).forEach((el) => {
      if (el.closest(".hero") || el.closest("#rList,#iList,#terms,#quiz,#secs,#rBelow,.toc")) return;
      if (el.parentElement.closest(".rv")) return; // parent already animates this block
      // stagger siblings that share a parent, capped so long grids don't drag
      const sib = [...el.parentElement.children].filter((c) => c.matches(REVEAL));
      const i = Math.min(sib.indexOf(el), 7);
      el.style.setProperty("--d", i * 90 + "ms");
      el.classList.add("rv");
      ob.observe(el);
    });
    // a fully clipped image never reports as intersecting, so watch its container instead
    const cio = new IntersectionObserver((entries) => entries.forEach((e) => {
      if (!e.isIntersecting) return; cio.unobserve(e.target);
      const img = e.target._curtain; img.classList.add("in");
      setTimeout(() => img.classList.remove("rv", "in", "rv-curtain"), 2000);
    }), { rootMargin: "0px 0px -8% 0px", threshold: 0.1 });
    main.querySelectorAll(CURTAIN).forEach((img) => { img.classList.add("rv", "rv-curtain"); img.parentElement._curtain = img; cio.observe(img.parentElement); });
    tick();
  }

  /* ---------- scroll-driven layer ---------- */
  let bar, ticking = false;
  function tick() {
    if (ticking) return; ticking = true;
    requestAnimationFrame(() => {
      ticking = false;
      const y = window.scrollY, vh = window.innerHeight, max = document.documentElement.scrollHeight - vh;
      if (!bar) { bar = document.createElement("div"); bar.className = "scroll-bar"; bar.setAttribute("aria-hidden", "true"); document.body.appendChild(bar); }
      bar.style.transform = `scaleX(${max > 0 ? Math.min(1, y / max) : 0})`;
      bar.classList.toggle("lamp", !!document.querySelector("#app .lamp-theme"));
      const hdr = document.getElementById("hdr"); hdr && hdr.classList.toggle("scrolled", y > 24);
      if (!on()) return;
      const hero = document.querySelector("#app .hero");
      if (hero && y < vh * 1.2) {
        const k = Math.min(1, y / hero.offsetHeight);
        const photo = hero.querySelector(".hero-photo"), copy = hero.querySelector(".hero-copy"), sw = hero.querySelector(".swoosh");
        photo && (photo.style.transform = `translate3d(0, ${y * 0.22}px, 0) scale(${1 + k * 0.06})`);
        copy && (copy.style.transform = `translate3d(0, ${y * 0.12}px, 0)`, copy.style.opacity = String(1 - k * 1.1));
        sw && (sw.style.transform = `rotate(${(root.dir === "rtl" ? -1 : 1) * y * 0.03}deg) translateY(${y * 0.1}px)`);
        hero.style.setProperty("--glow", (k * 120).toFixed(1) + "px");
      }
      const ph = document.querySelector("#app .ph");
      if (ph && y < vh) { const w = ph.querySelector(".wrap"); w && (w.style.transform = `translate3d(0, ${y * 0.18}px, 0)`, w.style.opacity = String(Math.max(0, 1 - y / (ph.offsetHeight * 1.3)))); }
      document.querySelectorAll("#app .timeline").forEach((tl) => {
        const r = tl.getBoundingClientRect(); const p = Math.max(0, Math.min(1, (vh * 0.75 - r.top) / r.height));
        tl.style.setProperty("--tl", p.toFixed(3));
      });
    });
  }
  window.addEventListener("scroll", tick, { passive: true });
  window.addEventListener("resize", tick, { passive: true });
  reduce.addEventListener && reduce.addEventListener("change", () => { root.classList.toggle("motion", on()); });

  window.MOTION = { apply, tick };
})();
