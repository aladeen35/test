/* Share cards + likes.
   - Any element with data-share='{"k":kicker,"t":title,"b":body|[items],"h":hash,"img":url?}' opens a share
     sheet with a branded 1080×1350 card (logo, site link, QR to the exact page), drawn on a canvas.
     The card can be shared as an image (Web Share API with files), downloaded, or the link sent to
     WhatsApp / X / LinkedIn / Facebook / Telegram / copied.
   - Any element with data-like="<key>" toggles a like for that item. Likes are kept on this device
     (localStorage); a shared counter can be plugged in later through LIKES.backend. */
import QRCode from "qrcode";
import { gsap } from "gsap";

const A = window.APP, I = window.ICONS;
const { esc, $ } = A;
const W = (a, e) => (A.lang === "ar" ? a : e);
const SITE = "aladeen35.github.io/test/alaeldeen";
const pageUrl = (hash) => {
  const base = location.protocol === "http:" || location.protocol === "https:" ? location.origin + location.pathname : `https://${SITE}/`;
  return base.replace(/index\.html$/, "") + (hash || "");
};

/* ---------------- likes ---------------- */
const LIKES = (window.LIKES = {
  backend: null, // { count(key) -> Promise<number>, toggle(key, on) -> Promise<number> }
  all() { try { return JSON.parse(localStorage.getItem("ab:likes") || "{}"); } catch (e) { return {}; } },
  has(k) { return !!this.all()[k]; },
  set(k, on) { const a = this.all(); if (on) a[k] = Date.now(); else delete a[k]; try { localStorage.setItem("ab:likes", JSON.stringify(a)); } catch (e) { /* private mode */ } },
});
A.likeBtn = (key, label) => `<button type="button" class="like-btn" data-like="${esc(key)}" aria-pressed="false" aria-label="${esc(label || W("أعجبني", "Like"))}"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20.5s-7.5-4.6-9.3-9.2C1.4 8 3.4 4.5 7 4.5c2 0 3.4 1.1 5 3 1.6-1.9 3-3 5-3 3.6 0 5.6 3.5 4.3 6.8-1.8 4.6-9.3 9.2-9.3 9.2Z"/></svg><span class="lk-t">${esc(W("أعجبني", "Like"))}</span><span class="lk-n" hidden></span></button>`;
A.shareBtn = (o, label, cls) => `<button type="button" class="share-btn ${cls || ""}" data-share="${esc(JSON.stringify(o))}" aria-label="${esc(label || W("مشاركة", "Share"))}" title="${esc(label || W("مشاركة", "Share"))}">${I.share}<span>${esc(label || W("مشاركة", "Share"))}</span></button>`;
const paintLikes = (root) => (root || document).querySelectorAll("[data-like]").forEach((b) => {
  const on = LIKES.has(b.dataset.like); b.setAttribute("aria-pressed", on); b.classList.toggle("on", on);
  const lt = b.querySelector(".lk-t"), txt = on ? W("أعجبك", "Liked") : W("أعجبني", "Like");
  if (lt.textContent !== txt) lt.textContent = txt; // only touch the DOM when it changes (the observer below watches it)
  if (LIKES.backend) LIKES.backend.count(b.dataset.like).then((n) => { const el = b.querySelector(".lk-n"); el.hidden = !n; el.textContent = n; }).catch(() => {});
});
A.paintLikes = paintLikes;

/* ---------------- card drawing ---------------- */
let logoImg = null;
const loadImg = (src) => new Promise((res) => { const im = new Image(); im.crossOrigin = "anonymous"; im.onload = () => res(im); im.onerror = () => res(null); im.src = src; });
function wrap(ctx, text, maxW) {
  const words = String(text).split(/\s+/), lines = []; let line = "";
  for (const w of words) { const t = line ? line + " " + w : w; if (ctx.measureText(t).width > maxW && line) { lines.push(line); line = w; } else line = t; }
  if (line) lines.push(line); return lines;
}
async function drawCard(o) {
  const ar = A.lang === "ar", Wd = 1080, H = 1350, P = 84;
  const c = document.createElement("canvas"); c.width = Wd; c.height = H; const g = c.getContext("2d");
  const fA = '"IBM Plex Sans Arabic", "Noto Sans Arabic", sans-serif', fE = '"Inter", "IBM Plex Sans Arabic", sans-serif', F = ar ? fA : fE;
  try { await Promise.all([document.fonts.load(`700 60px "IBM Plex Sans Arabic"`), document.fonts.load(`800 60px "Inter"`), document.fonts.load(`400 30px "IBM Plex Sans Arabic"`)]); } catch (e) { /* fallback fonts */ }
  // background: charcoal, gold glow, arcs
  g.fillStyle = "#151515"; g.fillRect(0, 0, Wd, H);
  let gr = g.createRadialGradient(Wd * 0.85, 120, 10, Wd * 0.85, 120, 700); gr.addColorStop(0, "rgba(221,176,63,.28)"); gr.addColorStop(1, "rgba(221,176,63,0)"); g.fillStyle = gr; g.fillRect(0, 0, Wd, H);
  gr = g.createRadialGradient(80, H - 80, 10, 80, H - 80, 600); gr.addColorStop(0, "rgba(83,185,173,.18)"); gr.addColorStop(1, "rgba(83,185,173,0)"); g.fillStyle = gr; g.fillRect(0, 0, Wd, H);
  g.strokeStyle = "rgba(221,176,63,.35)"; g.lineWidth = 2; g.beginPath(); g.arc(Wd + 120, -60, 640, Math.PI * 0.52, Math.PI * 0.98); g.stroke();
  g.strokeStyle = "rgba(221,176,63,.18)"; g.beginPath(); g.arc(Wd + 160, -40, 720, Math.PI * 0.55, Math.PI * 0.95); g.stroke();
  // header: logo + brand (always LTR brand)
  logoImg = logoImg || (await loadImg("assets/logo-mark.png"));
  if (logoImg) g.drawImage(logoImg, P, 70, 120, 120 * (logoImg.height / logoImg.width));
  g.textAlign = "left"; g.direction = "ltr"; g.fillStyle = "#fff"; g.font = `800 44px ${fE}`; g.fillText("Eng.", P + 140, 122);
  const engW = g.measureText("Eng. ").width; g.fillStyle = "#ddb03f"; g.fillText("Alaeldeen", P + 140 + engW, 122);
  g.fillStyle = "#cfcfcf"; g.font = `700 20px ${fE}`; g.fillText("Q U A L I T Y   &   S A F E T Y", P + 142, 158);
  // content block
  g.direction = ar ? "rtl" : "ltr"; g.textAlign = ar ? "right" : "left"; const X = ar ? Wd - P : P, maxW = Wd - P * 2;
  let y = 290;
  if (o.k) { g.font = `700 30px ${F}`; const kw = g.measureText(o.k).width + 44; g.fillStyle = "rgba(221,176,63,.14)"; const kx = ar ? X - kw : X; roundRect(g, kx, y - 40, kw, 56, 28); g.fill(); g.strokeStyle = "rgba(221,176,63,.6)"; g.lineWidth = 2; g.stroke(); g.fillStyle = "#ddb03f"; g.fillText(o.k, ar ? X - 22 : X + 22, y - 2); y += 70; }
  let imgDrawn = 0;
  if (o.img) { const im = await loadImg(o.img); if (im) { const ih = 360, iw = ih * (im.width / im.height); const ix = ar ? X - iw : X; g.save(); g.shadowColor = "rgba(0,0,0,.6)"; g.shadowBlur = 40; g.shadowOffsetY = 20; g.drawImage(im, ix, y, iw, ih); g.restore(); y += ih + 50; imgDrawn = 1; } }
  g.fillStyle = "#fff"; g.font = `${ar ? 700 : 800} ${imgDrawn ? 56 : 70}px ${F}`;
  wrap(g, o.t, maxW).slice(0, 3).forEach((ln) => { y += imgDrawn ? 66 : 82; g.fillText(ln, X, y); });
  y += 26; g.fillStyle = "#ddb03f"; g.fillRect(ar ? X - 120 : X, y, 120, 6); y += 34;
  const bodyMax = H - 330; g.font = `400 ${imgDrawn ? 30 : 34}px ${F}`; g.fillStyle = "#e2e2e2"; const lh = imgDrawn ? 48 : 56;
  const items = Array.isArray(o.b) ? o.b : [o.b || ""];
  outer: for (const it of items) {
    const lines = wrap(g, String(it), maxW - (Array.isArray(o.b) ? 44 : 0));
    for (let i = 0; i < lines.length; i++) {
      if (y + lh > bodyMax) { if (i < lines.length || it !== items[items.length - 1]) { g.fillStyle = "#9a9a9a"; g.fillText("…", X - (ar ? 0 : 0), y + lh); } break outer; }
      y += lh;
      if (Array.isArray(o.b) && i === 0) { g.fillStyle = "#ddb03f"; g.beginPath(); g.arc(ar ? X - 10 : X + 10, y - 12, 7, 0, 6.283); g.fill(); g.fillStyle = "#e2e2e2"; }
      g.fillText(lines[i], Array.isArray(o.b) ? (ar ? X - 44 : X + 44) : X, y);
    }
    if (Array.isArray(o.b)) y += 10;
  }
  // footer band with link + QR
  g.fillStyle = "#0f0f0f"; g.fillRect(0, H - 230, Wd, 230); g.fillStyle = "#ddb03f"; g.fillRect(0, H - 230, Wd, 5);
  const url = pageUrl(o.h);
  const qr = await QRCode.toDataURL(url, { margin: 1, width: 170, errorCorrectionLevel: "M", color: { dark: "#151515", light: "#ffffff" } });
  const qim = await loadImg(qr); const qx = ar ? P : Wd - P - 170;
  if (qim) { g.fillStyle = "#fff"; roundRect(g, qx - 10, H - 205, 190, 190, 18); g.fill(); g.drawImage(qim, qx, H - 195, 170, 170); }
  g.direction = ar ? "rtl" : "ltr"; g.textAlign = ar ? "right" : "left"; const tx = ar ? Wd - P : P;
  g.fillStyle = "#fff"; g.font = `700 34px ${F}`; g.fillText(W("اقرأ المزيد على الموقع", "Read more on the site"), tx, H - 140);
  g.direction = "ltr"; g.textAlign = ar ? "right" : "left"; g.fillStyle = "#ddb03f"; g.font = `600 28px ${fE}`; g.fillText(SITE, tx, H - 92);
  g.fillStyle = "#9a9a9a"; g.font = `400 22px ${F}`; g.direction = ar ? "rtl" : "ltr"; g.fillText(W("مصباح الجودة · م. علاء الدين", "Quality Lamp · Eng. Alaeldeen"), tx, H - 54);
  return c;
}
function roundRect(g, x, y, w, h, r) { g.beginPath(); g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r); g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath(); }

/* ---------------- share sheet ---------------- */
let sheet = null, lastFocus = null;
function ensureSheet() {
  if (sheet) return sheet;
  sheet = document.createElement("div"); sheet.className = "share-sheet"; sheet.id = "shareSheet"; sheet.hidden = true;
  document.body.appendChild(sheet);
  sheet.addEventListener("click", (e) => { if (e.target === sheet || e.target.closest("[data-sclose]")) closeSheet(); });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !sheet.hidden) closeSheet(); });
  return sheet;
}
function closeSheet() { sheet.hidden = true; document.documentElement.classList.remove("sheet-open"); if (lastFocus) lastFocus.focus(); }
async function openShare(o) {
  lastFocus = document.activeElement; ensureSheet();
  const url = pageUrl(o.h), text = `${o.t} — ${W("مصباح الجودة | م. علاء الدين", "Quality Lamp | Eng. Alaeldeen")}`;
  const enc = encodeURIComponent;
  sheet.innerHTML = `<div class="ss-box" role="dialog" aria-modal="true" aria-label="${esc(W("مشاركة", "Share"))}">
    <div class="ss-head"><b>${esc(W("مشاركة", "Share"))}</b><button type="button" class="icon-btn" data-sclose aria-label="${esc(W("إغلاق", "Close"))}">${I.x}</button></div>
    <div class="ss-preview"><div class="ss-wait">${esc(W("يُجهَّز التصميم…", "Preparing the card…"))}</div></div>
    <div class="ss-actions">
      <button type="button" class="btn btn-gold" id="ssShare" disabled>${I.share}<span>${esc(W("مشاركة الصورة", "Share image"))}</span></button>
      <button type="button" class="btn btn-line" id="ssSave" disabled>${I.download}<span>${esc(W("تنزيل الصورة", "Download image"))}</span></button>
      <button type="button" class="btn btn-ghost" id="ssCopy">${I.clip}<span>${esc(W("نسخ الرابط", "Copy link"))}</span></button></div>
    <div class="ss-net">
      <a href="https://wa.me/?text=${enc(text + "\n" + url)}" target="_blank" rel="noopener" aria-label="WhatsApp">${I.wa}</a>
      <a href="https://www.linkedin.com/sharing/share-offsite/?url=${enc(url)}" target="_blank" rel="noopener" aria-label="LinkedIn">${I.linkedin}</a>
      <a href="https://x.com/intent/post?text=${enc(text)}&url=${enc(url)}" target="_blank" rel="noopener" aria-label="X">${I.xlogo}</a>
      <a href="https://www.facebook.com/sharer/sharer.php?u=${enc(url)}" target="_blank" rel="noopener" aria-label="Facebook">${I.facebook}</a>
      <a href="https://t.me/share/url?url=${enc(url)}&text=${enc(text)}" target="_blank" rel="noopener" aria-label="Telegram">${I.telegram}</a></div>
    <p class="ss-url" dir="ltr">${esc(url)}</p></div>`;
  sheet.hidden = false; document.documentElement.classList.add("sheet-open");
  sheet.querySelector("[data-sclose]").focus();
  if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) gsap.fromTo(sheet.querySelector(".ss-box"), { y: 40, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.45, ease: "cine" });
  $("#ssCopy").addEventListener("click", async () => {
    try { await navigator.clipboard.writeText(url); A.toast(W("نُسخ الرابط", "Link copied")); }
    catch (e) { const r = document.createRange(); r.selectNodeContents(sheet.querySelector(".ss-url")); const s = getSelection(); s.removeAllRanges(); s.addRange(r); A.toast(W("حدّد الرابط وانسخه", "Select the link and copy it"), "bad"); }
  });
  const canvas = await drawCard(o);
  const blob = await new Promise((r) => canvas.toBlob(r, "image/png"));
  // ASCII file name from the page address: Arabic names aren't reliable across browsers and phones
  const name = "quality-lamp-" + ((o.h || "").replace(/^#\/?/, "").replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "") || "card") + ".png";
  const prev = sheet.querySelector(".ss-preview"); prev.innerHTML = ""; const im = new Image(); im.alt = o.t; im.src = URL.createObjectURL(blob); prev.appendChild(im);
  const file = new File([blob], name, { type: "image/png" });
  const sBtn = $("#ssShare"), dBtn = $("#ssSave");
  const canFiles = navigator.canShare && navigator.canShare({ files: [file] });
  sBtn.disabled = false; dBtn.disabled = false;
  if (!canFiles && !navigator.share) sBtn.hidden = true;
  sBtn.addEventListener("click", async () => {
    try { if (canFiles) await navigator.share({ files: [file], title: o.t, text: text + "\n" + url }); else await navigator.share({ title: o.t, text, url }); }
    catch (e) { if (e && e.name !== "AbortError") A.toast(W("تعذّرت المشاركة، نزّل الصورة بدلًا من ذلك.", "Couldn't share; download the image instead."), "bad"); }
  });
  dBtn.addEventListener("click", () => { const a = document.createElement("a"); a.href = im.src; a.download = name; document.body.appendChild(a); a.click(); a.remove(); });
}

/* ---------------- wiring ---------------- */
document.addEventListener("click", (e) => {
  const s = e.target.closest("[data-share]");
  if (s) { e.preventDefault(); e.stopPropagation(); try { openShare(JSON.parse(s.dataset.share)); } catch (err) { A.toast(W("تعذّر تجهيز المشاركة", "Couldn't prepare sharing"), "bad"); } return; }
  const l = e.target.closest("[data-like]");
  if (l) {
    e.preventDefault(); e.stopPropagation();
    const k = l.dataset.like, on = !LIKES.has(k); LIKES.set(k, on); paintLikes(); if (LIKES.backend) LIKES.backend.toggle(k, on).then(() => paintLikes()).catch(() => {});
    if (on && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) gsap.fromTo(l.querySelector("svg"), { scale: 0.6 }, { scale: 1, duration: 0.5, ease: "cineBack" });
  }
}, true);
// repaint like states after every route render
let paintQueued = false;
new MutationObserver(() => { if (paintQueued) return; paintQueued = true; requestAnimationFrame(() => { paintQueued = false; paintLikes(document.getElementById("app")); }); })
  .observe(document.getElementById("app"), { childList: true, subtree: true });
window.SHARE = { open: openShare, drawCard };
