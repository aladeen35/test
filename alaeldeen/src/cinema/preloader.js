/* Preloader: waits for fonts and every image marked [data-preload] (hero portrait),
   shows real progress, then lifts like a curtain. Resolves when the page is revealed.
   Has a hard timeout so a slow network never traps the visitor. */
export function runPreloader(gsap) {
  const el = document.getElementById("preloader");
  if (!el) return Promise.resolve();
  const count = el.querySelector(".pl-count"), line = el.querySelector(".pl-line i"), logo = el.querySelector("img");
  const shown = { v: 0 };
  const render = () => { count.textContent = String(Math.round(shown.v)).padStart(3, "0"); line.style.transform = `scaleX(${shown.v / 100})`; };

  return new Promise((resolve) => {
    const tasks = [document.fonts ? document.fonts.ready : Promise.resolve()];
    let done = 0, finished = false;
    const step = () => { done++; gsap.to(shown, { v: Math.min(100, (done / Math.max(1, tasks.length)) * 100), duration: 0.5, ease: "power2.out", onUpdate: render }); };
    const finish = () => {
      if (finished) return; finished = true;
      gsap.timeline({ onComplete: () => { el.classList.add("gone"); resolve(); } })
        .to(shown, { v: 100, duration: 0.45, ease: "power2.out", onUpdate: render })
        .to(logo, { scale: 1.15, autoAlpha: 0, duration: 0.6, ease: "cineInOut" }, "+=0.05")
        .to([count, line.parentElement], { autoAlpha: 0, duration: 0.4 }, "<")
        .to(el, { clipPath: "inset(0% 0% 100% 0%)", duration: 1.1, ease: "cineInOut" }, "-=0.25");
    };
    gsap.from(logo, { autoAlpha: 0, scale: 0.85, duration: 0.8, ease: "cine" });
    const minTime = new Promise((r) => setTimeout(r, 900));
    // the first route renders on DOMContentLoaded (module scripts run just before it),
    // so its [data-preload] images exist only after that event
    const go = () => {
      document.querySelectorAll("img[data-preload]").forEach((img) => tasks.push(img.decode ? img.decode().catch(() => {}) : Promise.resolve()));
      tasks.forEach((p) => p.then(step));
      Promise.all([...tasks, minTime]).then(finish);
    };
    if (document.readyState === "complete") setTimeout(go, 0);
    else document.addEventListener("DOMContentLoaded", () => setTimeout(go, 0), { once: true });
    setTimeout(finish, 4500); // safety net
  });
}
