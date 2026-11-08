/* Cinematic motion engine — GSAP 3 (ScrollTrigger, ScrollSmoother, SplitText, CustomEase).
   Every scroll animation is scrubbed against the smoothed scroll. Only transform, opacity
   and clip-path are animated. When the visitor prefers reduced motion nothing is hidden,
   pinned or smoothed: the page renders static and complete. */
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { ScrollSmoother } from "gsap/ScrollSmoother";
import { SplitText } from "gsap/SplitText";
import { CustomEase } from "gsap/CustomEase";
import { initGrain } from "./grain.js";
import { runPreloader } from "./preloader.js";
import { prepareSwarm, runSwarm } from "./swarm.js";

gsap.registerPlugin(ScrollTrigger, ScrollSmoother, SplitText, CustomEase);
CustomEase.create("cine", "M0,0 C0.16,0.84 0.24,1 1,1");
CustomEase.create("cineInOut", "M0,0 C0.7,0 0.2,1 1,1");
CustomEase.create("cineBack", "M0,0 C0.34,1.56 0.64,1 1,1");

const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const root = document.documentElement;
const isRTL = () => root.dir === "rtl";


let smoother = null;
let ctx = null;
let hero3d = null;
let ready = null; // resolves when the preloader has finished
let bar = null;

/* ---------- public API used by js/app.js ---------- */
function scrollTo(target, smooth) {
  if (smoother) {
    if (target === 0) smoother.scrollTop(0);
    else if (target) smoother.scrollTo(target, !!smooth, "top 90px");
    return;
  }
  if (target === 0) window.scrollTo(0, 0);
  else if (target) target.scrollIntoView({ block: "start", behavior: smooth ? "smooth" : "auto" });
}

export function boot() {
  window.MOTION = { apply, scrollTo };
  initGrain(reduce);
  bar = document.createElement("div");
  bar.className = "scroll-bar"; bar.setAttribute("aria-hidden", "true");
  document.body.appendChild(bar);

  if (reduce) { ready = Promise.resolve(); return; }
  root.classList.add("cine");
  smoother = ScrollSmoother.create({ wrapper: "#smooth-wrapper", content: "#smooth-content", smooth: 1.1, effects: false, smoothTouch: 0.08, normalizeScroll: false });
  ready = runPreloader(gsap);

  // content changes height when lists re-render (dictionary, tools): keep triggers in sync
  let t;
  new ResizeObserver(() => { clearTimeout(t); t = setTimeout(() => ScrollTrigger.refresh(), 150); }).observe(document.getElementById("smooth-content"));
  // let dialogs (search, drawer) scroll on their own
  const lock = () => smoother && smoother.paused(!!document.querySelector(".sdlg.open, .drawer.open"));
  new MutationObserver(lock).observe(document.body, { subtree: true, attributes: true, attributeFilter: ["class"] });
}

/* ---------- per-route scene setup ---------- */
const ctxCleanups = [];
function apply(main) {
  ctxCleanups.splice(0).forEach((f) => f());
  if (ctx) ctx.revert();
  if (hero3d) { hero3d.destroy(); hero3d = null; }
  scrollTo(0);

  const hero = main.querySelector('[data-scene="hero"]');
  if (hero) {
    import("./hero3d.js").then(({ createHero3D }) => {
      if (!hero.isConnected) return;
      hero3d = createHero3D(hero.querySelector(".hero-gl"), { reduce, rtl: isRTL() });
      if (!reduce) gsap.to(hero.querySelector(".hero-gl"), { opacity: 1, duration: 2.4, ease: "cine", delay: 0.2 });
    });
  }

  // swarm rebuild: home page and the About page, first view of each per visit
  const route = location.hash.replace(/^#\/?/, "");
  const page = hero ? "home" : route === "about" ? "about" : "";
  let seen;
  try { seen = !page || sessionStorage.getItem("ab:swarm:" + page) === "1"; } catch { seen = true; }
  const sw = !reduce && !seen;

  ctx = gsap.context(() => {
    chrome();
    if (reduce) return;
    if (hero) heroScene(hero, sw);
    marquee(main.querySelector('[data-scene="marquee"]'));
    chapters(main.querySelector('[data-scene="chapters"]'));
    numbers(main.querySelector('[data-scene="numbers"]'));
    book(main.querySelector('[data-scene="book"]'));
    manifesto(main.querySelector('[data-scene="quote"]'));
    pageHeader(main.querySelector(".ph"), sw);
    if (sw) startSwarm(main, page);
    splits(main);
    reveals(main);
    curtains(main);
    timelines(main);
  }, main);
  requestAnimationFrame(() => ScrollTrigger.refresh());
}

/* scroll progress + header state (works with and without motion) */
function chrome() {
  bar.classList.toggle("lamp", !!document.querySelector("#app .lamp-theme"));
  gsap.fromTo(bar, { scaleX: 0 }, { scaleX: 1, ease: "none", scrollTrigger: { start: 0, end: "max", scrub: reduce ? true : 0.4 } });
  const hdr = document.getElementById("hdr");
  ScrollTrigger.create({ start: 24, end: "max", onToggle: (s) => hdr && hdr.classList.toggle("scrolled", s.isActive) });
}

/* ---------- hero: entrance timeline + pinned scrub ---------- */
function heroScene(hero, sw) {
  const photo = hero.querySelector(".hero-photo img");
  const halo = hero.querySelector(".hero-photo");
  const copy = hero.querySelector(".hero-copy");
  if (sw) {
    // the swarm builds the copy, photo and badge; only the swoosh keeps its own entrance
    SplitText.create(hero.querySelectorAll("h1 [data-split]"), { type: "words", wordsClass: "sw-w" });
    gsap.set(hero.querySelector(".swoosh"), { autoAlpha: 0, rotate: isRTL() ? 14 : -14 });
    ready.then(() => gsap.to(hero.querySelector(".swoosh"), { autoAlpha: 1, rotate: 0, duration: 2.4, ease: "cine" }));
  } else heroIntro(hero, photo);
  heroExit(hero, halo, copy);
}

function heroIntro(hero, photo) {
  const lines = [...hero.querySelectorAll("h1 [data-split]")].map((el) => SplitText.create(el, { type: "words,lines", mask: "lines", linesClass: "split-mask" }));
  const words = lines.flatMap((s) => s.words);

  gsap.set(words, { yPercent: 120 });
  gsap.set(hero.querySelectorAll("[data-intro]"), { autoAlpha: 0, y: 26 });
  gsap.set(hero.querySelector("[data-intro-rule]"), { scaleX: 0, transformOrigin: isRTL() ? "100% 50%" : "0% 50%" });
  gsap.set(hero.querySelectorAll("[data-intro-cta] .btn"), { autoAlpha: 0, y: 22 });
  gsap.set(hero.querySelector(".hero-badge"), { autoAlpha: 0, y: 24, scale: 0.88 });
  gsap.set(photo, { clipPath: "inset(100% 0% 0% 0%)", scale: 1.18, filter: "blur(10px) brightness(.6)" });
  gsap.set(hero.querySelector(".swoosh"), { autoAlpha: 0, rotate: isRTL() ? 14 : -14 });

  const intro = gsap.timeline({ paused: true, defaults: { ease: "cine" } })
    .to(photo, { clipPath: "inset(0% 0% 0% 0%)", duration: 1.6, ease: "cineInOut" }, 0)
    .to(photo, { scale: 1, filter: "blur(0px) brightness(1)", duration: 2.2 }, 0.1)
    .to(hero.querySelector(".swoosh"), { autoAlpha: 1, rotate: 0, duration: 2.4 }, 0.2)
    .to(hero.querySelector("[data-intro]"), { autoAlpha: 1, y: 0, duration: 0.9 }, 0.35)
    .to(words, { yPercent: 0, duration: 1.2, stagger: 0.07 }, 0.45)
    .to(hero.querySelectorAll(".role[data-intro]"), { autoAlpha: 1, y: 0, duration: 0.9 }, 0.95)
    .to(hero.querySelector("[data-intro-rule]"), { scaleX: 1, duration: 1, ease: "cineInOut" }, 1.05)
    .to(hero.querySelectorAll(".lead[data-intro]"), { autoAlpha: 1, y: 0, duration: 0.9 }, 1.15)
    .to(hero.querySelectorAll("[data-intro-cta] .btn"), { autoAlpha: 1, y: 0, duration: 0.8, stagger: 0.1 }, 1.3)
    .to(hero.querySelector(".hero-badge"), { autoAlpha: 1, y: 0, scale: 1, duration: 0.9, ease: "cineBack" }, 1.6);
  ready.then(() => intro.play());
}

function heroExit(hero, halo, copy) {
  // scrubbed exit: pinned on large screens, plain parallax on phones
  const mm = gsap.matchMedia();
  mm.add({ big: "(min-width: 900px) and (min-height: 620px)", small: "(max-width: 899px), (max-height: 619px)" }, (c) => {
    const tl = gsap.timeline({
      defaults: { ease: "none" },
      scrollTrigger: { trigger: hero, start: "top top", end: c.conditions.big ? "+=70%" : "bottom top", scrub: 0.8, pin: c.conditions.big, anticipatePin: 1,
        onUpdate: (s) => hero3d && hero3d.setScroll(s.progress) },
    });
    tl.to(halo, { yPercent: c.conditions.big ? 8 : 18, scale: 1.08 }, 0)
      .to(copy, { yPercent: -18, autoAlpha: 0 }, 0)
      .to(hero.querySelector(".swoosh"), { rotate: isRTL() ? -18 : 18, yPercent: 12 }, 0)
      .to(hero.querySelector(".scroll-cue"), { autoAlpha: 0, duration: 0.2 }, 0);
  });
  // tie the WebGL loop to hero visibility
  ScrollTrigger.create({ trigger: hero, start: "top bottom", end: "bottom top", onToggle: (s) => hero3d && hero3d.setActive(s.isActive) });
}

/* ---------- specialties marquee: endless, accelerates with scroll velocity ---------- */
function marquee(sec) {
  if (!sec) return;
  const track = sec.querySelector(".mq-track");
  const dir = isRTL() ? 1 : -1;
  const loop = gsap.fromTo(track, { xPercent: dir === -1 ? 0 : -50 }, { xPercent: dir === -1 ? -50 : 0, duration: 38, ease: "none", repeat: -1 });
  let speed = gsap.quickTo(loop, "timeScale", { duration: 0.6, ease: "power3" });
  ScrollTrigger.create({ trigger: sec, start: "top bottom", end: "bottom top", onUpdate: (s) => { const v = Math.min(5, 1 + Math.abs(s.getVelocity()) / 400); speed(v); gsap.delayedCall(0.25, () => speed(1)); } });
}

/* ---------- chapters: pinned horizontal narrative (desktop), stacked reveal (phone) ---------- */
function chapters(sec) {
  if (!sec) return;
  const pin = sec.querySelector(".ch-pin"), track = sec.querySelector(".ch-track");
  const panels = gsap.utils.toArray(".ch-panel", sec);
  const mm = gsap.matchMedia();
  mm.add("(min-width: 900px)", () => {
    const dist = () => Math.max(0, track.scrollWidth - window.innerWidth);
    const tween = gsap.to(track, { x: () => (isRTL() ? dist() : -dist()), ease: "none",
      scrollTrigger: { trigger: pin, start: "top top", end: () => "+=" + dist(), scrub: 0.9, pin: true, anticipatePin: 1, invalidateOnRefresh: true } });
    panels.forEach((p) => {
      gsap.fromTo(p.querySelectorAll(".ch-num, .ch-ic, h3, p, .ch-go"), { y: 40, autoAlpha: 0 }, { y: 0, autoAlpha: 1, stagger: 0.06, ease: "cine",
        scrollTrigger: { trigger: p, containerAnimation: tween, start: isRTL() ? "right 5%" : "left 95%", end: isRTL() ? "right 40%" : "left 60%", scrub: 0.6 } });
      const img = p.querySelector(".ch-bg img");
      if (img) gsap.fromTo(img, { xPercent: isRTL() ? -8 : 8, scale: 1.12 }, { xPercent: 0, scale: 1, ease: "none", scrollTrigger: { trigger: p, containerAnimation: tween, start: "left right", end: "right left", scrub: true } });
    });
  });
  mm.add("(max-width: 899px)", () => {
    panels.forEach((p) => gsap.from(p, { y: 60, autoAlpha: 0, scale: 0.96, ease: "cine", scrollTrigger: { trigger: p, start: "top 92%", end: "top 60%", scrub: 0.6 } }));
  });
}

/* ---------- numbers: counts are scrubbed to scroll position ---------- */
function numbers(sec) {
  if (!sec) return;
  sec.querySelectorAll("[data-count]").forEach((b, i) => {
    const n = +b.dataset.count, suf = b.dataset.suffix || "", o = { v: 0 };
    gsap.to(o, { v: n, ease: "none", onUpdate: () => (b.textContent = Math.round(o.v) + suf),
      scrollTrigger: { trigger: sec, start: "top 85%", end: "top 30%", scrub: 0.6 } });
    gsap.from(b.parentElement, { y: 50, autoAlpha: 0, ease: "cine", scrollTrigger: { trigger: sec, start: `top ${88 - i * 3}%`, end: "top 50%", scrub: 0.6 } });
  });
}

/* ---------- book: cover turns towards the reader as you scroll ---------- */
function book(sec) {
  if (!sec) return;
  const cover = sec.querySelector(".book-cover"), img = cover && cover.querySelector("img");
  gsap.fromTo(cover, { rotateY: isRTL() ? -32 : 32, rotateX: 8, scale: 0.84, y: 60 }, { rotateY: 0, rotateX: 0, scale: 1, y: 0, ease: "none",
    scrollTrigger: { trigger: sec, start: "top 90%", end: "center 55%", scrub: 1 } });
  if (img) gsap.fromTo(img, { clipPath: "inset(0% 0% 100% 0%)" }, { clipPath: "inset(0% 0% 0% 0%)", ease: "none", scrollTrigger: { trigger: sec, start: "top 85%", end: "top 35%", scrub: 0.8 } });
  gsap.from(sec.querySelectorAll(".book-copy > :not(h2)"), { y: 40, autoAlpha: 0, stagger: 0.08, ease: "cine", scrollTrigger: { trigger: sec, start: "top 75%", end: "center 60%", scrub: 0.7 } });
}

/* ---------- manifesto: the quote "reads itself" word by word ---------- */
function manifesto(sec) {
  if (!sec) return;
  const p = sec.querySelector("[data-read]");
  const split = SplitText.create(p, { type: "words", wordsClass: "w" });
  gsap.fromTo(split.words, { opacity: 0.12, y: 14 }, { opacity: 1, y: 0, stagger: 0.12, ease: "none", scrollTrigger: { trigger: sec, start: "top 80%", end: "center 45%", scrub: 0.6 } });
  gsap.from(sec.querySelector(".btn"), { y: 30, autoAlpha: 0, ease: "cine", scrollTrigger: { trigger: sec, start: "top 60%", end: "center 50%", scrub: 0.6 } });
}

/* ---------- inner page header: masked title reveal + scrubbed exit ---------- */
function pageHeader(ph, sw) {
  if (!ph) return;
  const h1 = ph.querySelector("h1");
  if (sw) SplitText.create(h1, { type: "words", wordsClass: "sw-w" }); // the swarm builds the header
  else {
  const s = SplitText.create(h1, { type: "words,lines", mask: "lines", linesClass: "split-mask" });
  const rest = ph.querySelectorAll(".crumbs, .eyebrow, p, .cta");
  ready.then(() => {
    gsap.from(s.words, { yPercent: 115, duration: 1.1, stagger: 0.06, ease: "cine" });
    gsap.from(rest, { y: 24, autoAlpha: 0, duration: 0.9, stagger: 0.08, ease: "cine", delay: 0.15 });
  });
  }
  gsap.to(ph.querySelector(".wrap"), { yPercent: 22, autoAlpha: 0.15, ease: "none", scrollTrigger: { trigger: ph, start: "top top", end: "bottom top", scrub: true } });
}

/* ---------- swarm rebuild (home + About) ---------- */
function startSwarm(main, page) {
  const q = (s) => [...main.querySelectorAll(s)];
  const hdr = document.getElementById("hdr");
  const head = hdr && window.innerWidth >= 760 ? [hdr.querySelector(".brand"), ...hdr.querySelectorAll(".nav a")] : [];
  const list = page === "home"
    ? [...head, ...q(".hero .hero-kicker, .hero h1 .sw-w, .hero .role, .hero .rule, .hero .lead, .hero .cta .btn, .hero-photo img, .hero-badge")]
    : [...head, ...q(".ph .crumbs, .ph .eyebrow, .ph h1 .sw-w, .ph p, .ph .cta .btn, #about .profile-photo, #about .profile-top > div > *:not(.kv), #about .kv > div")];
  const pieces = prepareSwarm([...new Set(list)]);
  if (!pieces.length) return;
  ready.then(() => {
    if (!pieces[0].isConnected) return;
    try { sessionStorage.setItem("ab:swarm:" + page, "1"); } catch { /* private mode */ }
    const run = runSwarm(pieces, { onDone: () => ScrollTrigger.refresh() });
    if (run) ctxCleanups.push(run.cancel);
  });
}

/* ---------- section headings: words rise out of line masks ---------- */
function splits(main) {
  main.querySelectorAll(".sec-hd h2, [data-split-scrub], .book-copy h2[data-split], .lsec h2, .article h2").forEach((el) => {
    if (el.closest(".hero")) return;
    SplitText.create(el, { type: "words,lines", mask: "lines", linesClass: "split-mask", autoSplit: true,
      onSplit: (self) => gsap.from(self.words, { yPercent: 110, stagger: 0.05, ease: "cine", scrollTrigger: { trigger: el, start: "top 90%", end: "top 62%", scrub: 0.6 } }) });
  });
}

/* ---------- generic content: batched reveals (cards, rows, form blocks) ---------- */
const REVEAL = [".card", ".fact", ".tl", ".kv > div", "details.faq", ".disclaimer", ".searchbar", ".filters", ".link-group h3",
  ".article > p", ".article > ul", ".article > ol", ".lsec > :not(h2)", ".profile-top > div > :not(h2)", ".sec-hd p", ".eyebrow"].join(",");
function reveals(main) {
  const els = [...main.querySelectorAll(REVEAL)].filter((el) => !el.closest("[data-swarm], .hero, .ph, .ch-track, .profile-photo, .book-thumb, .video, [data-scene='numbers'], [data-scene='book'], #rList, #iList, #terms, #quiz, #secs, #rBelow, .toc") && !el.parentElement.closest(".card"));
  if (!els.length) return;
  gsap.set(els, { autoAlpha: 0, y: 42 });
  ScrollTrigger.batch(els, {
    start: "top 92%", once: true, interval: 0.08, batchMax: 8,
    onEnter: (batch) => gsap.to(batch, { autoAlpha: 1, y: 0, duration: 1, stagger: 0.08, ease: "cine", overwrite: true, clearProps: "transform,opacity,visibility" }),
  });
}

/* ---------- image curtains, scrubbed ---------- */
function curtains(main) {
  main.querySelectorAll(".profile-photo img, .book-thumb img, .video img").forEach((img) => {
    if (img.closest("[data-swarm]")) return; // built by the swarm
    const from = { clipPath: "inset(0% 0% 100% 0%)", scale: 1.12 }, to = { clipPath: "inset(0% 0% 0% 0%)", scale: 1, duration: 1.4, ease: "cineInOut" };
    // already on screen when the page opens (e.g. the profile photo on phones): play as soon as the page is revealed
    gsap.set(img, from);
    if (img.parentElement.getBoundingClientRect().top < window.innerHeight * 0.95) { ready.then(() => gsap.to(img, { ...to, delay: 0.35 })); return; }
    // below the fold: the browser's own visibility check on the (unclipped) frame works the same on touch devices
    const io = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) { io.disconnect(); gsap.to(img, to); } }), { threshold: 0.15 });
    io.observe(img.parentElement);
    ctxCleanups.push(() => io.disconnect());
  });
}

/* ---------- experience timeline grows with scroll ---------- */
function timelines(main) {
  main.querySelectorAll(".timeline").forEach((tl) => gsap.fromTo(tl, { "--tl": 0 }, { "--tl": 1, ease: "none", scrollTrigger: { trigger: tl, start: "top 75%", end: "bottom 60%", scrub: 0.5 } }));
}


