/* "الذهب المسلوب" — the full book. Desktop: a 3D book bound on the right (Arabic binding)
   with all 62 PDF pages between the real cover and a back cover; leaves turn with GSAP and
   page images load only near the open spread. Phones: one large page at a time. Plus a
   contents list that jumps to chapters, the PDF download, and the presentation video. */
import { gsap } from "gsap";

const A = window.APP, I = window.ICONS, S = window.SITE;
const { esc, L, $, $$, pageHead } = A;
const W = (a, e) => (A.lang === "ar" ? a : e);
const reduce = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const tr = (k) => A.t(k);

function designed(b) {
  const chain = b.chain.map((c, i) => `<span class="pg-step"><b>${i + 1}</b>${esc(c.ar)}</span>`).join(`<span class="pg-arr">←</span>`);
  return [
    { img: "assets/book-sg-author.webp", alt: "نبذة عن الكاتب", intro: true },
    { img: "assets/book-sg-title.webp", alt: "صفحة العنوان ونبذة الكتاب", intro: true },
    { intro: true, html: `<div class="pg-paper"><span class="pg-kicker">عن الكتاب</span><h3>${esc(b.title.ar)}</h3><p class="pg-q">${esc(b.question.ar)}</p><p>${esc(b.blurb.ar)}</p><p class="pg-aud">${esc(b.audience.ar)}</p></div>` },
    { intro: true, html: `<div class="pg-paper"><span class="pg-kicker">من الخامة إلى المنتج</span><h3>سلسلة القيمة</h3><div class="pg-chain">${chain}</div>
        <p>أمثلة من غلاف الكتاب لمنتجات سودانية يمكن أن تُصنَّع محليًا بجودة تنافسية:</p>
        <ul class="pg-list">${b.products.map((x) => `<li>${esc(x)}</li>`).join("")}</ul>
        <p class="pg-hint">وكلها تمر عبر ضوابط سلامة الغذاء: ${b.haccp.map(esc).join("، ")}.</p></div>` },
    { intro: true, video: true, html: `<div class="pg-paper pg-video"><span class="pg-kicker">عرض الكتاب</span><h3>شاهد المؤلف يقدّم الكتاب</h3>
        <div class="pg-yt" data-yt="${b.video}"><img src="${b.spread}" alt="" loading="lazy"><button type="button" class="play" aria-label="تشغيل عرض الكتاب">${I.play}</button></div>
        <a class="pg-link" href="${b.url}" target="_blank" rel="noopener">${I.external}<span>فتح على يوتيوب</span></a></div>` },
    { intro: true, html: `<div class="pg-paper"><span class="pg-kicker">النسخة الكاملة</span><h3>الكتاب كاملًا يبدأ في الصفحة التالية</h3>
        <p>${b.pdfPages} صفحة في خمسة أبواب وتسعة فصول، مع الخاتمة والتوصيات والملاحق العملية والمراجع. قلّب الصفحات أو انتقل إلى أي فصل من المحتويات.</p>
        <a class="pg-full" href="${b.pdf}" download="${esc(b.title.ar)}.pdf">${I.download}<span>تحميل الكتاب PDF</span></a>
        <p>للتعاون في النشر والتوزيع أو للتواصل مع المؤلف:</p>
        <div class="pg-contact"><a href="https://wa.me/${S.profile.whatsapp}?text=${encodeURIComponent("السلام عليكم، بخصوص كتاب الذهب المسلوب")}" target="_blank" rel="noopener">${I.wa}<span>واتساب</span></a><a href="mailto:${S.profile.email}?subject=${encodeURIComponent("كتاب الذهب المسلوب")}">${I.mail}<span dir="ltr">${S.profile.email}</span></a></div></div>` },
  ];
}
function pagesOf(b) {
  const P = [{ img: b.cover, alt: "غلاف كتاب الذهب المسلوب", cls: "pg-cover" }, ...designed(b)];
  for (let i = 1; i <= b.pdfPages; i++) P.push({ img: `${b.pageDir}/p${String(i).padStart(2, "0")}.webp`, alt: `صفحة ${i}`, pdf: i });
  P.push({ html: `<div class="pg-backcover"><img src="assets/logo-mark.png" alt="" class="pg-logo"><h3>${esc(b.title.ar)}</h3><p class="pg-q">${esc(b.fullSubtitle.ar)}</p><p>${esc(b.blurb.ar)}</p><span class="pg-author">${esc(b.author.ar)}</span><small class="pg-pub">${esc(b.publisher.ar)} · ${esc(b.edition.ar)}</small></div>`, cls: "pg-bc" });
  if (P.length % 2) P.splice(P.length - 1, 0, { html: `<div class="pg-paper"></div>` }); // keep an even page count
  return P; // leaf i = P[2i] (front) + P[2i+1] (back)
}
const face = (p, side) => `<div class="face ${side} ${p.cls || ""}">${p.img ? `<img class="pg-img" data-src="${p.img}" alt="${esc(p.alt)}" decoding="async">` : p.html}</div>`;

A.pages.books = () => {
  const b = S.books.find((x) => x.featured), others = S.books.filter((x) => !x.featured);
  const P = pagesOf(b), n = P.length / 2;
  const toc = b.toc.map((c) => `<li class="${c.lvl ? "sub" : ""}"><button type="button" data-goto="${c.p}"><span>${esc(c.t)}</span><b>${c.p - b.pageOffset > 0 ? c.p - b.pageOffset : ""}</b></button></li>`).join("");
  return {
    title: L(b.title),
    html: `${pageHead(tr("books.t"), tr("books.sub"), [[tr("nav.library"), "#/library"], [tr("books.t")]])}
    <section class="sec"><div class="wrap">
      <div class="reader card">
        <div class="rd-top"><div><span class="eyebrow">${esc(W("الكتاب كاملًا", "The full book"))} · ${esc(L(b.edition))} · ${b.pdfPages} ${esc(W("صفحة", "pages"))}</span><h2 class="book-title">${esc(L(b.title))}</h2><p class="book-sub">${esc(L(b.fullSubtitle))}</p><p class="rd-by">${esc(W("تأليف", "By"))} ${esc(L(b.author))} · ${esc(L(b.publisher))}</p></div>
          <div class="cta" style="margin:0"><a class="btn btn-gold" href="${b.pdf}" download="${esc(b.title.ar)}.pdf">${I.download}<span>${esc(W("تحميل PDF", "Download PDF"))}</span></a><a class="btn btn-line" href="${b.pdf}" target="_blank" rel="noopener">${I.external}<span>${esc(W("فتح PDF", "Open PDF"))}</span></a></div></div>
        <div class="rd-body">
          <div class="rd-main">
            <div class="rd-book" id="rdBook" dir="ltr"><div class="rd-stage" id="rdStage">${Array.from({ length: n }, (_, i) => `<div class="leaf" data-i="${i}">${face(P[2 * i], "front")}${face(P[2 * i + 1], "back")}</div>`).join("")}</div></div>
            <div class="rd-single" id="rdSingle"><img id="rdOne" alt=""><div class="rd-html" id="rdHtml" hidden></div></div>
            <div class="rd-ctrl"><button type="button" class="btn btn-ghost btn-sm" id="rdPrev">→ <span>${esc(W("السابق", "Previous"))}</span></button>
              <span class="rd-pos" id="rdPos" aria-live="polite"></span>
              <button type="button" class="btn btn-gold btn-sm" id="rdNext"><span>${esc(W("قلّب الصفحة", "Turn the page"))}</span> ←</button></div>
            <div class="rd-jump"><label for="rdGo">${esc(W("انتقل إلى صفحة", "Go to page"))}</label><input id="rdGo" type="number" min="1" max="${b.pdfPages}" inputmode="numeric" placeholder="1–${b.pdfPages}"><button type="button" class="btn btn-ghost btn-sm" id="rdGoBtn">${esc(W("انتقال", "Go"))}</button></div>
          </div>
          <aside class="rd-toc"><h3>${esc(W("المحتويات", "Contents"))}</h3><ol>${toc}</ol></aside>
        </div>
      </div>
      <div class="grid g2" style="margin-top:22px;align-items:start">
        <div class="card"><span class="eyebrow">${esc(W("عرض الكتاب", "Book presentation"))}</span><h3>${esc(W("شاهد المؤلف يقدّم الكتاب", "Watch the author present the book"))}</h3>
          <div class="video" data-yt="${b.video}"><img src="${b.spread}" alt="${esc(L(b.title))}" loading="lazy"><button type="button" class="play" aria-label="${esc(tr("books.play"))}">${I.play}</button></div>
          <a class="more" href="${b.url}" target="_blank" rel="noopener" style="margin-top:12px">${esc(W("فتح على يوتيوب", "Open on YouTube"))} ${I.arrow}</a></div>
        <div class="card"><span class="eyebrow">${esc(W("عن الكتاب", "About the book"))}</span><h3>${esc(L(b.question))}</h3><p>${esc(L(b.blurb))}</p><p style="color:var(--muted)">${esc(L(b.audience))}</p>
          <div class="chain">${b.chain.map((c, i) => `<span>${esc(L(c))}</span>${i < b.chain.length - 1 ? I.arrow : ""}`).join("")}</div></div>
      </div>
      ${others.map((o) => `<article class="card book-row" id="${o.id}" style="margin-top:22px"><a href="${o.url}" target="_blank" rel="noopener" class="book-thumb"><img src="${o.cover}" alt="${esc(L(o.title))}" loading="lazy" width="${o.coverW}" height="${o.coverH}"></a><div><span class="eyebrow">${esc(L(o.kind))}</span><h2 class="book-title" style="font-size:28px">${esc(L(o.title))}</h2><p class="book-sub">${esc(L(o.subtitle))}</p><p>${esc(L(o.blurb))}</p><a class="btn btn-line" href="${o.url}" target="_blank" rel="noopener">${I.book}<span>${esc(L(o.cta))}</span>${I.external}</a></div></article>`).join("")}
    </div></section>`,
    after: () => mount(P, b),
  };
};

function mount(P, b) {
  const n = P.length / 2, stage = $("#rdStage"), book = $("#rdBook"), leavesEl = $$(".leaf", stage), box = $("#rdSingle"), im = $("#rdOne");
  const single = () => window.matchMedia("(max-width: 700px)").matches;
  let at = 0;   // 3D book: turned leaves (0 = closed on the cover, n = closed on the back)
  let one = 0;  // phone view: index in P
  const load = (lf) => lf && $$("img[data-src]", lf).forEach((x) => { x.src = x.dataset.src; x.removeAttribute("data-src"); });
  const near = () => { for (let i = at - 2; i <= at + 2; i++) load(leavesEl[i]); };
  const pdfOf = (idx) => P[idx] && P[idx].pdf;
  const off = P.findIndex((x) => x.pdf === 1) - 1; // P index of PDF page k is k + off
  const label = () => {
    if (single()) { const pg = pdfOf(one); return pg ? W(`صفحة ${pg} من ${b.pdfPages}`, `Page ${pg} of ${b.pdfPages}`) : one === 0 ? W("الغلاف", "Cover") : P[one].intro ? W("صفحات تعريفية", "Introduction pages") : W("الغلاف الخلفي", "Back cover"); }
    if (at === 0) return W("الغلاف", "Cover");
    if (at === n) return W("الغلاف الخلفي", "Back cover");
    const pr = [pdfOf(2 * at - 1), pdfOf(2 * at)].filter(Boolean);
    if (!pr.length) return W("صفحات تعريفية", "Introduction pages");
    return W(`الصفحتان ${pr.join(" و")} من ${b.pdfPages}`, `Pages ${pr.join("–")} of ${b.pdfPages}`);
  };
  const current = () => (single() ? pdfOf(one) : pdfOf(2 * at - 1) || pdfOf(2 * at));
  const upd = () => {
    $("#rdPos").textContent = label();
    $("#rdPrev").disabled = single() ? one === 0 : at === 0;
    $("#rdNext").disabled = single() ? one === P.length - 1 : at === n;
    const cur = current(), btns = $$(".rd-toc [data-goto]");
    let active = null; btns.forEach((x) => { if (cur != null && +x.dataset.goto <= cur) active = x; });
    btns.forEach((x) => x.classList.toggle("on", x === active));
  };
  const sync = (instant) => {
    near();
    leavesEl.forEach((lf, i) => {
      const turned = i < at, z = turned ? i + 1 : n - i, depth = z * 0.35; // preserve-3d stacks by depth, not z-index
      const was = gsap.getProperty(lf, "rotationY") <= -90;
      if (instant || reduce() || was === turned) gsap.set(lf, { rotationY: turned ? -180 : 0, z: depth, zIndex: z });
      else gsap.to(lf, { rotationY: turned ? -180 : 0, z: depth, duration: 1.1, ease: "cineInOut", onStart: () => gsap.set(lf, { zIndex: n + 2 }), onComplete: () => gsap.set(lf, { zIndex: z }) });
    });
    if (![2 * at - 1, 2 * at].includes(videoIdx)) stopVideo();
    gsap.to(stage, { xPercent: at === 0 ? 25 : at === n ? -25 : 0, duration: instant || reduce() ? 0 : 1, ease: "cineInOut" });
    upd();
  };
  const showOne = (dir) => {
    const p = P[one];
    const set = () => {
      const h = $("#rdHtml");
      if (p.img) { im.src = p.img; im.alt = p.alt; im.hidden = false; h.hidden = true; h.innerHTML = ""; }
      else { im.hidden = true; h.className = "rd-html " + (p.cls || ""); h.innerHTML = p.html; h.hidden = false; bindVideo(h); }
    };
    if (reduce() || !dir) set();
    else gsap.timeline().to([im, $("#rdHtml")], { rotationY: dir * 70, autoAlpha: 0, duration: 0.22, ease: "power2.in", onComplete: set }).fromTo([im, $("#rdHtml")], { rotationY: -dir * 70 }, { rotationY: 0, autoAlpha: 1, duration: 0.35, ease: "cine" });
    [one - 1, one + 1].forEach((k) => { if (P[k] && P[k].img) { const pre = new Image(); pre.src = P[k].img; } });
    upd();
  };
  const go = (d) => {
    if (single()) { const nx = Math.max(0, Math.min(P.length - 1, one + d)); if (nx !== one) { one = nx; showOne(d); } return; }
    const nx = Math.max(0, Math.min(n, at + d)); if (nx !== at) { at = nx; sync(); }
  };
  const goPdf = (pg) => {
    pg = Math.max(1, Math.min(b.pdfPages, pg | 0));
    const k = pg + off;
    if (single()) { const d = k >= one ? 1 : -1; one = k; showOne(d); return; }
    const target = Math.ceil(k / 2); // P[k] is on leaf floor(k/2); its spread opens after ceil(k/2) turns
    const far = Math.abs(target - at) > 2; at = target; sync(far);
  };
  $("#rdNext").addEventListener("click", () => go(1));
  $("#rdPrev").addEventListener("click", () => go(-1));
  stage.addEventListener("click", (e) => { if (e.target.closest("a, button, iframe")) return; const lf = e.target.closest(".leaf"); if (lf) go(+lf.dataset.i < at ? -1 : 1); });
  box.addEventListener("click", (e) => { if (e.target.closest("a, button, iframe")) return; const r = box.getBoundingClientRect(); go(e.clientX < r.left + r.width / 2 ? 1 : -1); }); // Arabic book: left side = next
  let sx = null;
  box.addEventListener("touchstart", (e) => (sx = e.touches[0].clientX), { passive: true });
  box.addEventListener("touchend", (e) => { if (sx == null) return; const dx = e.changedTouches[0].clientX - sx; if (Math.abs(dx) > 40) go(dx > 0 ? 1 : -1); sx = null; }, { passive: true });
  [book, box].forEach((el) => {
    el.tabIndex = 0; el.setAttribute("role", "group"); el.setAttribute("aria-label", W("كتاب الذهب المسلوب — الأسهم لتقليب الصفحات", "Stolen Gold — arrow keys turn pages"));
    el.addEventListener("keydown", (e) => { if (e.key === "ArrowLeft") { e.preventDefault(); go(1); } if (e.key === "ArrowRight") { e.preventDefault(); go(-1); } });
  });
  $$(".rd-toc [data-goto]").forEach((x) => x.addEventListener("click", () => { goPdf(+x.dataset.goto); A.scrollTo(single() ? box : book, true); }));
  const jump = () => { const el = $("#rdGo"), v = +el.value; if (v >= 1 && v <= b.pdfPages) goPdf(v); else { el.setAttribute("aria-invalid", "true"); el.focus(); } };
  $("#rdGoBtn").addEventListener("click", jump);
  $("#rdGo").addEventListener("keydown", (e) => { if (e.key === "Enter") jump(); });
  $("#rdGo").addEventListener("input", (e) => e.target.removeAttribute("aria-invalid"));
  function bindVideo(root) {
    $$(".pg-yt", root).forEach((vb) => {
      if (!vb.dataset.poster) vb.dataset.poster = vb.innerHTML;
      const btn = vb.querySelector(".play"); if (!btn) return;
      btn.addEventListener("click", (e) => { e.stopPropagation(); vb.innerHTML = `<iframe src="https://www.youtube-nocookie.com/embed/${vb.dataset.yt}?autoplay=1&rel=0" title="عرض كتاب الذهب المسلوب" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>`; });
    });
  }
  const videoIdx = P.findIndex((x) => x.video);
  const stopVideo = () => $$(".pg-yt", stage).forEach((vb) => { if (vb.querySelector("iframe")) { vb.innerHTML = vb.dataset.poster; bindVideo(vb.parentElement); } });
  bindVideo(stage);
  $$(".video[data-yt]").forEach((v) => v.querySelector(".play").addEventListener("click", () => { v.innerHTML = `<iframe src="https://www.youtube-nocookie.com/embed/${v.dataset.yt}?autoplay=1&rel=0" title="${esc(tr("books.play"))}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>`; }));
  window.matchMedia("(max-width: 700px)").addEventListener("change", () => {
    if (single()) { one = Math.max(0, Math.min(P.length - 1, at ? 2 * at - 1 : 0)); showOne(0); } else { at = Math.max(0, Math.min(n, Math.ceil(one / 2))); sync(true); }
  });
  sync(true); showOne(0);
  if (!reduce()) gsap.from(single() ? box : book, { rotationX: 16, y: 50, autoAlpha: 0, duration: 1.3, ease: "cine", delay: 0.2 });
}
