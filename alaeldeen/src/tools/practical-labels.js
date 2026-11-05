/* Practical tools: product label generator, batch / date code generator, kitchen prep labels
   and an EAN-13 / UPC-A barcode generator. ES module (uses the npm packages qrcode and
   jsbarcode); it plugs into js/tools.js through TOOLS.register and must be imported after it.
   Data stays in localStorage only. The tools never propose shelf lives, limits or legal
   claims: the user enters them. */
import QRCode from "qrcode";
import JsBarcode from "jsbarcode";
import "../../css/tools-practical-labels.css";

const T = window.TOOLS, A = window.APP, I = window.ICONS;
const { disclaimer, crumbsFor, store, esc, L, t, $, $$, toast, download, csv, uid, fmtDate, pageHead } = T.h;
const W = (a, e) => (A.lang === "ar" ? a : e);

/* ---------- icons used by these tools ---------- */
const sv = (p) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${p}</svg>`;
I.tag = I.tag || sv('<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1.5"/>');
I.barcode = I.barcode || sv('<path d="M3 5v14M6 5v14M10 5v14M13 5v14M17 5v14M21 5v14M8 5v14M19 5v14" stroke-width="1.4"/>');
I.hash = I.hash || sv('<path d="M5 9h14M5 15h14M10 4 8 20M16 4l-2 16"/>');
I.clock = I.clock || sv('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>');

/* ---------- small helpers ---------- */
const pad2 = (n, l) => String(n).padStart(l || 2, "0");
const clone = (o) => JSON.parse(JSON.stringify(o));
const reEsc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const fmtN = (n, d) => (n === "" || n == null || !isFinite(n) ? "—" : Number(n).toLocaleString("en-GB", { maximumFractionDigits: d == null ? 1 : d }));
const fld = (id, label, input, o) => { o = o || {}; return `<div class="field ${o.full ? "full" : ""}" ${o.attrs || ""}><label for="${id}" class="${o.req ? "req" : ""}">${esc(label)}</label>${input}${o.hint ? `<span class="hint">${esc(o.hint)}</span>` : ""}<span class="err" id="${id}-e"></span></div>`; };
const selOpts = (opts, cur) => opts.map(([v, l]) => `<option value="${esc(v)}" ${String(cur) === String(v) ? "selected" : ""}>${esc(l)}</option>`).join("");
const setErr = (id, msg) => { const el = document.getElementById(id), e = document.getElementById(id + "-e"); if (el) el.setAttribute("aria-invalid", msg ? "true" : "false"); if (e) e.textContent = msg || ""; return !msg; };
const focusBad = (root) => { const b = $("[aria-invalid=true]", root); if (b) b.focus(); };
const toolOf = (id) => T.list.find((x) => x.id === id);
const head = (id) => `${pageHead(L(toolOf(id).t), L(toolOf(id).d), crumbsFor(toolOf(id)))}<section class="sec"><div class="wrap pt-page">${disclaimer()}`;
const isInt = (v, lo, hi) => String(v).trim() !== "" && Number.isInteger(Number(v)) && Number(v) >= lo && Number(v) <= hi;
const iconBtn = (data, id, icon, label) => `<button type="button" class="icon-btn" data-${data}="${esc(id)}" aria-label="${esc(label)}" title="${esc(label)}" style="width:34px;height:34px">${icon}</button>`;
const modeSeg = (id, cur) => `<div class="seg pt-seg" role="group" id="${id}" aria-label="${esc(W("لغة الملصق", "Label language"))}">${[["ar", "عربي"], ["en", "English"], ["bi", W("ثنائي اللغة", "Bilingual")]].map(([v, l]) => `<button type="button" data-mode="${v}" aria-pressed="${cur === v}">${esc(l)}</button>`).join("")}</div>`;

/* ---------- dates (UTC calendar arithmetic, no time-zone drift) ---------- */
const pD = (s) => { const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s || ""); if (!m) return null; const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3])); return d.getUTCMonth() === +m[2] - 1 ? d : null; };
const isoD = (d) => d.toISOString().slice(0, 10);
const addDays = (s, n) => { const d = pD(s); d.setUTCDate(d.getUTCDate() + n); return isoD(d); };
const doy = (s) => { const d = pD(s); return Math.round((d - Date.UTC(d.getUTCFullYear(), 0, 1)) / 864e5) + 1; };
const isoWeek = (s) => { const d = pD(s); const wd = d.getUTCDay() || 7; d.setUTCDate(d.getUTCDate() + 4 - wd); const y = d.getUTCFullYear(); return { y, w: Math.ceil(((d - Date.UTC(y, 0, 1)) / 864e5 + 1) / 7) }; };
const fromDoy = (y, n) => { if (!(n >= 1)) return null; const d = new Date(Date.UTC(y, 0, n)); return d.getUTCFullYear() === y ? isoD(d) : null; };
const fromWeek = (y, w) => { const d = new Date(Date.UTC(y, 0, 4)); d.setUTCDate(d.getUTCDate() - (d.getUTCDay() || 7) + 1 + (w - 1) * 7); return isoD(d); };
const mkDate = (y, m, d) => pD(`${pad2(y, 4)}-${pad2(m)}-${pad2(d)}`) ? `${pad2(y, 4)}-${pad2(m)}-${pad2(d)}` : null;
const todayL = () => { const d = new Date(); return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`; };
const nowL = () => { const d = new Date(); return `${todayL()}T${pad2(d.getHours())}:${pad2(d.getMinutes())}`; };
const dmy = (s) => { const [y, m, d] = s.split("-"); return `${d}/${m}/${y}`; };
const yymmdd = (s) => s.slice(2, 4) + s.slice(5, 7) + s.slice(8, 10);
const AR_MONTHS = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"];
const DAYS = [["الأحد", "Sunday", "SUN"], ["الاثنين", "Monday", "MON"], ["الثلاثاء", "Tuesday", "TUE"], ["الأربعاء", "Wednesday", "WED"], ["الخميس", "Thursday", "THU"], ["الجمعة", "Friday", "FRI"], ["السبت", "Saturday", "SAT"]];
const wdayOf = (s) => DAYS[pD(s).getUTCDay()];

/* ---------- GTIN / EAN-13 ---------- */
// mod-10 check digit of a GTIN body: weights 3,1,3… from the rightmost body digit
const gtinCheck = (body) => { let s = 0; for (let i = body.length - 1, w = 3; i >= 0; i--, w = 4 - w) s += +body[i] * w; return (10 - (s % 10)) % 10; };
const EAN_L = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"];
const EAN_G = ["0100111", "0110011", "0011011", "0100001", "0011101", "0111001", "0000101", "0010001", "0001001", "0010111"];
const EAN_R = ["1110010", "1100110", "1101100", "1000010", "1011100", "1001110", "1010000", "1000100", "1001000", "1110100"];
const EAN_PAR = ["LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG", "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"];
const eanBits = (d) => { let b = "101"; for (let i = 1; i <= 6; i++) b += (EAN_PAR[+d[0]][i - 1] === "L" ? EAN_L : EAN_G)[+d[i]]; b += "01010"; for (let i = 7; i <= 12; i++) b += EAN_R[+d[i]]; return b + "101"; };
/* SVG in module units: 113 × 78.58 modules = 37.29 × 25.93 mm at 100 % (X = 0.33 mm).
   EAN-13: 11-module left / 7-module right quiet zone; UPC-A (12 digits): 9 + 9. */
function eanSvg(code, o) {
  o = o || {};
  const upc = code.length === 12, d = upc ? "0" + code : code, bits = eanBits(d), q = upc ? 9 : 11, H = 78.58, hb = 69.24, hg = 74.24;
  const guard = (i) => i < 3 || (i >= 45 && i < 50) || i >= 92 || (upc && (i < 10 || i >= 85));
  let rects = "";
  for (let i = 0; i < 95;) { if (bits[i] === "1") { let j = i; while (j < 95 && bits[j] === "1" && guard(j) === guard(i)) j++; rects += `<rect x="${q + i}" y="0" width="${j - i}" height="${guard(i) ? hg : hb}"/>`; i = j; } else i++; }
  const tx = (x, s, f) => `<text x="${x}" y="77.6" font-size="${f || 8.6}" text-anchor="middle">${s}</text>`;
  let txt = "";
  if (upc) { txt += tx(4.5, code[0], 6.4) + tx(q + 95 + 4.5, code[11], 6.4); for (let k = 0; k < 5; k++) txt += tx(q + 10 + 7 * k + 3.5, code[1 + k]) + tx(q + 50 + 7 * k + 3.5, code[6 + k]); }
  else { txt += tx(q - 5.5, d[0]); for (let k = 0; k < 6; k++) txt += tx(q + 3 + 7 * k + 3.5, d[1 + k]) + tx(q + 50 + 7 * k + 3.5, d[7 + k]); }
  const size = o.mag ? `width="${(37.29 * o.mag).toFixed(2)}mm" height="${(25.93 * o.mag).toFixed(2)}mm"` : o.px ? `width="${o.px[0]}" height="${o.px[1]}"` : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 113 ${H}" ${size} ${o.style ? `style="${o.style}"` : ""} role="img" aria-label="${upc ? "UPC-A" : "EAN-13"} ${code}"><rect width="113" height="${H}" fill="#fff"/><g fill="#000">${rects}</g><g fill="#000" font-family="Arial, Helvetica, sans-serif">${txt}</g></svg>`;
}
// Code 128 / GS1-128 via JsBarcode; returns an SVG stretched to its box and its width in modules
function c128(data, gs1) {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  JsBarcode(svg, data, { format: "CODE128", ean128: !!gs1, displayValue: false, margin: 0, width: 1, height: 40, background: "#ffffff", lineColor: "#000000" });
  const mods = parseFloat(svg.getAttribute("width"));
  ["width", "height", "x", "y", "style"].forEach((a) => svg.removeAttribute(a));
  svg.setAttribute("preserveAspectRatio", "none");
  return { svg: new XMLSerializer().serializeToString(svg), mods };
}
const qrCache = new Map();
async function qrSvg(text) { if (!qrCache.has(text)) qrCache.set(text, await QRCode.toString(text, { type: "svg", margin: 0, errorCorrectionLevel: "M", color: { dark: "#000000", light: "#ffffff" } })); return qrCache.get(text); }

/* ---------- label rendering shared by preview and print ---------- */
const LAB_CSS = `.pl-lab{box-sizing:border-box;width:100%;height:100%;background:#fff;color:#000;font-family:"IBM Plex Sans Arabic","Noto Sans Arabic","Inter",Arial,sans-serif;line-height:1.2;display:flex;flex-direction:column;overflow:hidden;text-align:start;font-size:8pt}
.pl-lab *{box-sizing:border-box}
.pl-lab .pl-tx{flex:1 1 auto;min-height:0;overflow:hidden;overflow-wrap:anywhere}
.pl-lab .pl-tx p,.pl-lab .pl-tx div{margin:0 0 .2em;font-size:inherit;color:#000;line-height:1.2;max-width:none}
.pl-lab .pl-tx .pl-nm{font-size:1.4em}
.pl-lab .pl-nm{font-weight:700;font-size:1.4em;line-height:1.12;margin-bottom:.18em}
.pl-lab b{font-weight:700}
.pl-lab .pl-al{font-weight:800}
.pl-lab .pl-cd{flex:0 0 auto;display:flex;align-items:flex-end;justify-content:space-between;gap:1.5mm;direction:ltr;margin-top:.6mm}
.pl-lab .pl-bc{display:flex;flex-direction:column;align-items:center;min-width:0;overflow:hidden}
.pl-lab svg{display:block}
.pl-lab .pl-hr{font-family:Arial,Helvetica,sans-serif;font-size:2.1mm;line-height:1;margin-top:.4mm;white-space:nowrap}
.pl-lab .pl-nt{border-collapse:collapse;width:100%;margin:.15em 0 .25em;font-size:.9em}
.pl-lab .pl-nt th,.pl-lab .pl-nt td{border:.2mm solid #000;color:#000;background:#fff;font-size:inherit;padding:0 .3em;text-align:start;font-weight:400;line-height:1.2}
.pl-lab .pl-nt td{text-align:end;direction:ltr;white-space:nowrap}
.pl-lab .pl-nt thead th{font-weight:700}
.pl-lab .pl-band{flex:0 0 auto;margin:calc(-1 * var(--pad)) calc(-1 * var(--pad)) .25em;padding:.12em var(--pad);text-align:center;font-weight:800;letter-spacing:.03em;font-size:1.1em}
.pl-lab .pl-ub{font-weight:800;font-size:1.15em}`;
(() => { if (!document.getElementById("pl-lab-css")) { const s = document.createElement("style"); s.id = "pl-lab-css"; s.textContent = LAB_CSS; document.head.appendChild(s); } })();
const labPad = (w, h) => Math.round(Math.min(4, Math.max(1.2, Math.min(w, h) * 0.05)) * 10) / 10;
const PX = 96 / 25.4;
// draw a label at its real size in mm, scaled to the preview box; returns the .pl-lab element
function stage(host, w, h, inner) {
  const avail = Math.max(120, Math.min((host.clientWidth || 300) - 28, 460)), pw = w * PX, ph = h * PX;
  const s = Math.min(avail / pw, 520 / ph, 4);
  host.innerHTML = `<div class="pl-stage" style="width:${(pw * s).toFixed(1)}px;height:${(ph * s).toFixed(1)}px"><div class="pl-scale" style="width:${w}mm;height:${h}mm;transform:scale(${s.toFixed(4)})">${inner}</div></div>`;
  return $(".pl-lab", host);
}
// largest font size (pt) at which the text block fits the label
function fit(lab, maxPt) {
  const tx = $(".pl-tx", lab), ok = () => tx.scrollHeight <= tx.clientHeight + 0.5;
  lab.style.fontSize = maxPt + "pt"; if (ok()) return { pt: maxPt, ok: true };
  let lo = 3, hi = maxPt;
  for (let i = 0; i < 12; i++) { const mid = (lo + hi) / 2; lab.style.fontSize = mid + "pt"; if (ok()) lo = mid; else hi = mid; }
  const pt = Math.floor(lo * 10) / 10; lab.style.fontSize = pt + "pt";
  return { pt, ok: ok() };
}
const maxPtFor = (h) => Math.round(Math.min(18, Math.max(5, h * 0.33)) * 10) / 10;

/* ---------- printing at physical size in a hidden iframe ---------- */
function printDoc(body, css, title) {
  const fonts = $$('link[rel="stylesheet"]').filter((l) => /fonts\.googleapis\.com/.test(l.href)).map((l) => `<link rel="stylesheet" href="${esc(l.href)}">`).join("");
  const html = `<!doctype html><html lang="${A.lang}" dir="${A.lang === "ar" ? "rtl" : "ltr"}"><head><meta charset="utf-8"><title>${esc(title)}</title>${fonts}<style>*{box-sizing:border-box}html,body{margin:0;padding:0;background:#fff;color:#000}body{-webkit-print-color-adjust:exact;print-color-adjust:exact}${css}</style></head><body>${body}</body></html>`;
  const old = document.getElementById("ptPrintFrame"); if (old) old.remove();
  const fr = document.createElement("iframe");
  fr.id = "ptPrintFrame"; fr.title = "print"; fr.tabIndex = -1; fr.setAttribute("aria-hidden", "true");
  fr.style.cssText = "position:fixed;left:0;bottom:0;width:1px;height:1px;border:0;opacity:0;pointer-events:none";
  fr.onload = () => { const w = fr.contentWindow; const go = () => { try { w.focus(); w.print(); } catch (_) { toast(W("تعذّرت الطباعة.", "Printing failed."), "bad"); } }; const f = w.document.fonts; (f && f.ready ? f.ready : Promise.resolve()).then(() => setTimeout(go, 150)); };
  fr.srcdoc = html; document.body.appendChild(fr);
  return html;
}
/* size: { w, h, kind: "roll" | "sheet", cols, rows, left, top, px, py } */
function printLabels(size, inner, copies, skip, title) {
  let body = "", css = LAB_CSS;
  if (size.kind === "sheet") {
    const per = size.cols * size.rows, total = (skip || 0) + copies, pages = Math.ceil(total / per);
    for (let p = 0; p < pages; p++) {
      body += `<div class="sheet">`;
      for (let i = 0; i < per; i++) { const n = p * per + i; if (n < (skip || 0) || n >= total) continue; body += `<div class="cell" style="left:${(size.left + (i % size.cols) * size.px).toFixed(2)}mm;top:${(size.top + Math.floor(i / size.cols) * size.py).toFixed(2)}mm">${inner}</div>`; }
      body += `</div>`;
    }
    css += `@page{size:210mm 297mm;margin:0}.sheet{position:relative;width:210mm;height:296.5mm;overflow:hidden;break-after:page;page-break-after:always}.sheet:last-child{break-after:auto;page-break-after:auto}.cell{position:absolute;width:${size.w}mm;height:${size.h}mm;overflow:hidden}`;
  } else {
    for (let i = 0; i < copies; i++) body += `<div class="pg">${inner}</div>`;
    css += `@page{size:${size.w}mm ${size.h}mm;margin:0}.pg{width:${size.w}mm;height:${size.h - 0.2}mm;overflow:hidden;break-after:page;page-break-after:always}.pg:last-child{break-after:auto;page-break-after:auto}`;
  }
  return printDoc(body, css, title);
}
function downloadBlob(name, blob) { const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = name; document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 500); }

/* ---------- allergen keywords ---------- */
const DEF_ALG = {
  ar: "قمح\nحنطة\nشعير\nشوفان\nجاودار\nغلوتين\nجلوتين\nقشريات\nروبيان\nجمبري\nقريدس\nسلطعون\nكابوريا\nكركند\nبيض\nسمك\nأسماك\nتونة\nسلمون\nأنشوفة\nفول سوداني\nفستق سوداني\nصويا\nحليب\nلبن\nقشطة\nكريمة\nزبدة\nجبن\nمصل اللبن\nكازين\nلاكتوز\nمكسرات\nلوز\nبندق\nجوز\nكاجو\nبقان\nفستق حلبي\nفستق\nمكاديميا\nسمسم\nطحينة\nكبريتيت\nثاني أكسيد الكبريت",
  en: "wheat\nbarley\nrye\noats\nspelt\nkamut\ngluten\ncrustacean\nshrimp\nprawn\ncrab\nlobster\negg\nfish\ntuna\nsalmon\nanchovy\npeanut\ngroundnut\nsoy\nsoya\nsoybean\nmilk\ncream\nbutter\ncheese\nwhey\ncasein\nlactose\nyoghurt\nyogurt\nnut\nalmond\nhazelnut\nwalnut\ncashew\npecan\npistachio\nmacadamia\nbrazil nut\nsesame\ntahini\nsulphite\nsulfite\nsulphur dioxide\nsulfur dioxide",
};
const ALG_KEY = "tool:prodlabel:allergens";
const algWords = () => Object.assign({}, DEF_ALG, store.get(ALG_KEY, {}) || {});
function algRegex(w) {
  const clean = (s) => [...new Set(String(s || "").split(/[\n,،]+/).map((x) => x.trim()).filter(Boolean))].sort((a, b) => b.length - a.length).map(reEsc);
  const a = clean(w.ar), e = clean(w.en), parts = [];
  // Arabic: optional conjunction / preposition / article prefixes and common suffixes, whole word only
  if (a.length) parts.push(`(?:و|ف)?(?:ب|ل|ك)?(?:ال|ل)?(?:${a.join("|")})(?:ة|ات|ه|ها|ي)?`);
  if (e.length) parts.push(`(?:${e.join("|")})(?:s|es)?`);
  return parts.length ? new RegExp(`(?<![\\p{L}\\p{M}\\p{N}])(?:${parts.join("|")})(?![\\p{L}\\p{M}])`, "giu") : null;
}
function boldAlg(text, re, found) {
  if (!re) return esc(text);
  let out = "", last = 0;
  for (const m of text.matchAll(re)) { out += esc(text.slice(last, m.index)) + `<b class="pl-al">${esc(m[0])}</b>`; last = m.index + m[0].length; if (found) found.add(m[0].toLowerCase()); }
  return out + esc(text.slice(last));
}

/* =====================================================================
   1) Product label generator
   ===================================================================== */
const PL_SIZES = [
  { id: "r50x30", w: 50, h: 30, kind: "roll" }, { id: "r60x40", w: 60, h: 40, kind: "roll" }, { id: "r100x50", w: 100, h: 50, kind: "roll" }, { id: "r100x150", w: 100, h: 150, kind: "roll" },
  { id: "a4-3x8", w: 70, h: 37, kind: "sheet", cols: 3, rows: 8, left: 0, top: 0.5, px: 70, py: 37 },
  { id: "a4-2x7", w: 99.1, h: 38.1, kind: "sheet", cols: 2, rows: 7, left: 4.65, top: 15.15, px: 101.6, py: 38.1 },
];
const CAP = { ing: ["المكونات", "Ingredients"], con: ["يحتوي على", "Contains"], may: ["قد يحتوي على", "May contain"], sto: ["التخزين", "Storage"], ori: ["بلد المنشأ", "Country of origin"], mak: ["المصنّع / المعبّئ", "Manufacturer / packer"], net: ["الكمية الصافية", "Net quantity"], prod: ["تاريخ الإنتاج", "Production date"], exp: ["تاريخ الانتهاء", "Expiry date"], bb: ["يُفضّل استهلاكه قبل", "Best before"], batch: ["رقم التشغيلة", "Batch no."] };
const UNITS = [["g", "غ", "g"], ["kg", "كغ", "kg"], ["ml", "مل", "mL"], ["l", "لتر", "L"], ["pcs", "قطعة", "pcs"]];
const NUTK = [["kcal", "الطاقة", "Energy", "kcal", 0], ["protein", "البروتين", "Protein", "g", 1], ["fat", "الدهون الكلية", "Total fat", "g", 1], ["sat", "الدهون المشبعة", "Saturated fat", "g", 1], ["carb", "الكربوهيدرات", "Carbohydrate", "g", 1], ["sugars", "السكريات", "Sugars", "g", 1], ["fibre", "الألياف الغذائية", "Dietary fibre", "g", 1], ["sodium", "الصوديوم", "Sodium", "mg", 0]];
const PL_DEF = () => ({ size: "r50x30", cw: "", ch: "", mode: "bi", copies: 1, skip: 0, name_ar: "", name_en: "", ing_ar: "", ing_en: "", con_ar: "", con_en: "", may_ar: "", may_en: "", qty: "", unit: "g", prod: todayL(), dtype: "exp", exp: "", sto_ar: "", sto_en: "", ori_ar: "", ori_en: "", mak_ar: "", mak_en: "", batch: "", bc: "", bcv: "", qr: "", nut: null, nutMode: "p100" });
const plSize = (d) => (d.size === "custom" ? { id: "custom", w: Number(d.cw), h: Number(d.ch), kind: "roll" } : PL_SIZES.find((s) => s.id === d.size) || PL_SIZES[0]);
const sizeName = (s) => (s.kind === "sheet" ? `A4 ${s.cols} × ${s.rows} — ${s.w} × ${s.h} mm (${s.cols * s.rows} ${W("ملصقًا في الورقة", "per sheet")})` : `${s.w} × ${s.h} mm`);

function bcCheck(type, v) {
  v = String(v || "").trim();
  if (!type) return { ok: true };
  if (!v) return { ok: false, msg: W("أدخل قيمة الباركود.", "Enter the barcode value.") };
  if (type === "ean13") {
    if (!/^\d+$/.test(v)) return { ok: false, msg: W("أرقام فقط.", "Digits only.") };
    if (v.length === 12) return { ok: true, code: v + gtinCheck(v) };
    if (v.length === 13) { const c = gtinCheck(v.slice(0, 12)); return +v[12] === c ? { ok: true, code: v } : { ok: false, msg: W(`رقم التحقق غير صحيح — يجب أن يكون ${c}.`, `Wrong check digit — it should be ${c}.`) }; }
    return { ok: false, msg: W("أدخل 12 رقمًا (يُحسب رقم التحقق) أو 13 رقمًا.", "Enter 12 digits (the check digit is computed) or 13 digits.") };
  }
  if (!/^[\x20-\x7e]+$/.test(v)) return { ok: false, msg: W("Code 128 يقبل الأحرف اللاتينية والأرقام والرموز القياسية (ASCII) فقط.", "Code 128 accepts Latin letters, digits and standard symbols (ASCII) only.") };
  if (v.length > 48) return { ok: false, msg: W("الحد الأقصى 48 حرفًا.", "48 characters at most.") };
  return { ok: true, code: v };
}
const qrOk = (u) => { u = String(u || "").trim(); if (!u || /\s/.test(u) || u.length > 512) return false; try { return !!new URL(u).protocol; } catch (_) { return false; } };

function nutTable(n, nm, m) {
  const c = (a, e) => (m === "bi" ? `${a} | ${e}` : m === "ar" ? a : e);
  const cols = nm === "both" ? ["p100", "ps"] : [nm === "ps" ? "ps" : "p100"];
  const hd = { p100: c("لكل 100 غ", "Per 100 g"), ps: c(`لكل حصة (${fmtN(n.servW, 0)} غ)`, `Per serving (${fmtN(n.servW, 0)} g)`) };
  return `<table class="pl-nt"><thead><tr><th>${c("القيم الغذائية", "Nutrition")}</th>${cols.map((k) => `<th>${hd[k]}</th>`).join("")}</tr></thead><tbody>${NUTK.map(([k, a, e, u, dg]) => `<tr><th>${c(a, e)}</th>${cols.map((col) => `<td>${n[col] && isFinite(n[col][k]) && n[col][k] !== "" && n[col][k] != null ? fmtN(n[col][k], dg) + " " + u : "—"}</td>`).join("")}</tr>`).join("")}</tbody></table>`;
}
function plHtml(d, size, cx, fs) {
  const m = d.mode, langs = m === "bi" ? ["ar", "en"] : [m], rtl = m !== "en";
  const da = (lg) => `dir="${lg === "ar" ? "rtl" : "ltr"}" lang="${lg}"`;
  const cap = (k, lg) => CAP[k][lg === "ar" ? 0 : 1];
  const capC = (k) => (m === "bi" ? `${CAP[k][0]} / ${CAP[k][1]}` : cap(k, m));
  const v = (k) => String(d[k] == null ? "" : d[k]).trim();
  const p = cx.pad;
  let h = "";
  langs.forEach((lg) => { if (v("name_" + lg)) h += `<div class="pl-nm" ${da(lg)}>${esc(v("name_" + lg))}</div>`; });
  ["ing", "con", "may"].forEach((k) => langs.forEach((lg) => { if (v(k + "_" + lg)) h += `<p ${da(lg)}><b>${cap(k, lg)}:</b> ${boldAlg(v(k + "_" + lg), cx.re, cx.found).replace(/\n/g, "<br>")}</p>`; }));
  const line = (k, val) => (val ? `<p><b>${capC(k)}:</b> <bdi dir="ltr">${esc(val)}</bdi></p>` : "");
  const u = UNITS.find((x) => x[0] === d.unit) || UNITS[0];
  if (v("qty")) h += line("net", `${v("qty")} ${m === "ar" ? u[1] : m === "en" ? u[2] : u[2] + " / " + u[1]}`);
  h += line("prod", pD(d.prod) ? dmy(d.prod) : "") + line(d.dtype === "bb" ? "bb" : "exp", pD(d.exp) ? dmy(d.exp) : "") + line("batch", v("batch"));
  ["sto", "ori", "mak"].forEach((k) => langs.forEach((lg) => { if (v(k + "_" + lg)) h += `<p ${da(lg)}><b>${cap(k, lg)}:</b> ${esc(v(k + "_" + lg)).replace(/\n/g, "<br>")}</p>`; }));
  if (d.nut) h += nutTable(d.nut, d.nutMode, m);
  if (!h) h = `<p style="color:#777">${esc(W("ابدأ بإدخال بيانات المنتج…", "Start by entering the product details…"))}</p>`;
  const codes = cx.bc || cx.qr ? `<div class="pl-cd">${cx.bc ? `<div class="pl-bc">${cx.bc}</div>` : "<span></span>"}${cx.qr ? `<div class="pl-qr">${cx.qr}</div>` : ""}</div>` : "";
  return `<div class="pl-lab" dir="${rtl ? "rtl" : "ltr"}" lang="${rtl ? "ar" : "en"}" style="padding:${p}mm;--pad:${p}mm;${fs ? `font-size:${fs}pt` : ""}"><div class="pl-tx">${h}</div>${codes}</div>`;
}
async function plCodes(d, size) {
  const cx = { pad: labPad(size.w, size.h), re: algRegex(algWords()), found: new Set(), bc: "", qr: "" };
  const bk = d.bc ? bcCheck(d.bc, d.bcv) : { ok: false }, hasBc = !!d.bc && bk.ok, hasQr = !!String(d.qr || "").trim() && qrOk(d.qr);
  if (!hasBc && !hasQr) return cx;
  const hc = Math.min(26, Math.max(7, size.h * 0.3)), avail = size.w - 2 * cx.pad - (hasQr ? hc + 1.5 : 0);
  if (hasBc && avail > 4) {
    if (d.bc === "ean13") { let bw = (hc * 113) / 78.58, bh = hc; if (bw > avail) { bw = avail; bh = (bw * 78.58) / 113; } cx.bc = eanSvg(bk.code, { style: `width:${bw.toFixed(2)}mm;height:${bh.toFixed(2)}mm` }); cx.mag = bw / 37.29; }
    else { const r = c128(bk.code); const bw = Math.min(avail, r.mods * 0.38); cx.bc = r.svg.replace("<svg", `<svg style="width:${bw.toFixed(2)}mm;height:${(hc - 2.8).toFixed(2)}mm"`) + `<div class="pl-hr">${esc(bk.code)}</div>`; cx.x = bw / r.mods; }
  }
  if (hasQr) cx.qr = (await qrSvg(String(d.qr).trim())).replace("<svg", `<svg style="width:${hc.toFixed(2)}mm;height:${hc.toFixed(2)}mm"`);
  return cx;
}
function plMissing(d, found) {
  const langs = d.mode === "bi" ? ["ar", "en"] : [d.mode], miss = [];
  const lgN = (lg) => (langs.length > 1 ? ` (${lg === "ar" ? W("عربي", "Arabic") : W("إنجليزي", "English")})` : "");
  const need = (k, a, e) => langs.forEach((lg) => { if (!String(d[k + "_" + lg] || "").trim()) miss.push(W(a, e) + lgN(lg)); });
  need("name", "اسم المنتج", "Product name"); need("ing", "قائمة المكونات", "Ingredients list");
  if (!found.size && !String(d.con_ar || "").trim() && !String(d.con_en || "").trim()) miss.push(W("بيان مسببات الحساسية (لم يُعثر على أي منها في المكونات — تأكد)", "Allergen declaration (none found in the ingredients — confirm)"));
  if (!(Number(d.qty) > 0)) miss.push(W("الكمية الصافية", "Net quantity"));
  if (!pD(d.exp)) miss.push(d.dtype === "bb" ? W("تاريخ «يُفضّل استهلاكه قبل»", "Best-before date") : W("تاريخ الانتهاء", "Expiry date"));
  need("sto", "تعليمات التخزين", "Storage instructions"); need("mak", "اسم وعنوان المصنّع / المعبّئ", "Manufacturer / packer name & address");
  if (!String(d.batch || "").trim()) miss.push(W("رقم التشغيلة", "Batch number"));
  return miss;
}

function prodlabelPage() {
  const DK = "tool:prodlabel:draft", RK = "tool:prodlabel";
  let d = Object.assign(PL_DEF(), store.get(DK, {}) || {}), fitPt = 6, timer = 0, tok = 0;
  const langsOf = () => (d.mode === "bi" ? ["ar", "en"] : [d.mode]);
  const bi = (k, a, e, o) => { o = o || {}; return ["ar", "en"].map((lg) => { const id = `pl-${k}_${lg}`, val = d[k + "_" + lg] || "", at = `id="${id}" data-k="${k}_${lg}" dir="${lg === "ar" ? "rtl" : "ltr"}" lang="${lg}"`; return fld(id, `${W(a, e)} — ${lg === "ar" ? W("بالعربية", "in Arabic") : W("بالإنجليزية", "in English")}`, o.ta ? `<textarea ${at} rows="${o.rows || 2}">${esc(val)}</textarea>` : `<input type="text" ${at} value="${esc(val)}">`, { full: o.ta || o.full, attrs: `data-lg="${lg}"`, hint: o.hint }); }).join(""); };
  const nutRecs = () => (store.get("tool:nutrition", []) || []).filter((r) => r && r.out && r.out.p100);
  const nutOpts = () => { const rs = nutRecs(), o = [["", W("— بدون جدول —", "— no table —")]].concat(rs.map((r) => [r.id, r.name || "—"])); if (d.nut && !rs.some((r) => r.id === d.nut.id)) o.push([d.nut.id, `${d.nut.name} (${W("نسخة محفوظة", "saved copy")})`]); return selOpts(o, d.nut ? d.nut.id : ""); };
  const fieldsHtml = () => {
    const w = algWords();
    return `<h3 class="pt-h">${esc(W("الملصق", "Label"))}</h3>
      ${fld("pl-size", W("مقاس الملصق", "Label size"), `<select id="pl-size" data-k="size"><optgroup label="${esc(W("لفة حرارية", "Thermal roll"))}">${selOpts(PL_SIZES.filter((s) => s.kind === "roll").map((s) => [s.id, sizeName(s)]), d.size)}</optgroup><optgroup label="${esc(W("ورقة A4", "A4 sheet"))}">${selOpts(PL_SIZES.filter((s) => s.kind === "sheet").map((s) => [s.id, sizeName(s)]), d.size)}</optgroup><option value="custom" ${d.size === "custom" ? "selected" : ""}>${esc(W("مقاس مخصص (مم)", "Custom size (mm)"))}</option></select>`, { req: true })}
      ${fld("pl-copies", W("عدد النسخ", "Copies"), `<input type="number" id="pl-copies" data-k="copies" min="1" max="500" step="1" inputmode="numeric" value="${esc(d.copies)}">`, { req: true })}
      ${fld("pl-cw", W("العرض (مم)", "Width (mm)"), `<input type="number" id="pl-cw" data-k="cw" min="10" max="300" step="0.1" inputmode="decimal" value="${esc(d.cw)}">`, { attrs: 'data-show="custom"', req: true })}
      ${fld("pl-ch", W("الارتفاع (مم)", "Height (mm)"), `<input type="number" id="pl-ch" data-k="ch" min="10" max="300" step="0.1" inputmode="decimal" value="${esc(d.ch)}">`, { attrs: 'data-show="custom"', req: true })}
      ${fld("pl-skip", W("تخطي ملصقات مستخدمة في أول ورقة", "Skip used labels on the first sheet"), `<input type="number" id="pl-skip" data-k="skip" min="0" step="1" inputmode="numeric" value="${esc(d.skip)}">`, { attrs: 'data-show="sheet"', hint: W("تُعدّ من أعلى الورقة صفًا بعد صف.", "Counted from the top of the sheet, row by row.") })}
      <div class="field full"><span class="lbl" id="pl-mode-l">${esc(W("لغة الملصق", "Label language"))}</span>${modeSeg("pl-mode", d.mode)}</div>
      <h3 class="pt-h">${esc(W("المنتج والمكونات", "Product & ingredients"))}</h3>
      ${bi("name", "اسم المنتج", "Product name")}
      ${bi("ing", "المكونات (بترتيب تنازلي حسب الوزن)", "Ingredients (in descending order of weight)", { ta: true, rows: 3, hint: W("تظهر مسببات الحساسية الموجودة في قائمة الكلمات أدناه بخط عريض تلقائيًا.", "Allergens found from the keyword list below are bolded automatically.") })}
      <details class="faq full" id="pl-algbox"><summary>${esc(W("قائمة كلمات مسببات الحساسية (قابلة للتعديل)", "Allergen keyword list (editable)"))}</summary>
        <p class="note" style="margin-top:0">${esc(W("كلمة أو عبارة في كل سطر. القائمة الافتراضية تغطي المجموعات الشائعة الواجب التصريح بها (حبوب الغلوتين، القشريات، البيض، الأسماك، الفول السوداني، الصويا، الحليب، المكسرات، السمسم، الكبريتيت). راجع القائمة المعتمدة في لائحتك.", "One word or phrase per line. The default list covers the common declarable groups (gluten cereals, crustaceans, eggs, fish, peanuts, soy, milk, tree nuts, sesame, sulphites). Check the list required by your regulation."))}</p>
        <div class="form" style="padding-bottom:14px">${fld("pl-alg-ar", W("كلمات عربية", "Arabic keywords"), `<textarea id="pl-alg-ar" rows="5" dir="rtl" lang="ar">${esc(w.ar)}</textarea>`)}${fld("pl-alg-en", W("كلمات إنجليزية", "English keywords"), `<textarea id="pl-alg-en" rows="5" dir="ltr" lang="en">${esc(w.en)}</textarea>`)}
        <div class="full"><button type="button" class="btn btn-ghost btn-sm" id="pl-alg-reset">${esc(W("استعادة القائمة الافتراضية", "Restore default list"))}</button></div></div></details>
      <div class="full" id="pl-found" aria-live="polite"></div>
      ${bi("con", "بيان «يحتوي على»", "\"Contains\" statement", { hint: W("مثال: حليب، قمح", "e.g. milk, wheat") })}
      ${bi("may", "بيان «قد يحتوي على»", "\"May contain\" statement")}
      <h3 class="pt-h">${esc(W("الكمية والتواريخ والتشغيلة", "Quantity, dates & batch"))}</h3>
      ${fld("pl-qty", W("الكمية الصافية", "Net quantity"), `<input type="number" id="pl-qty" data-k="qty" min="0" step="any" inputmode="decimal" value="${esc(d.qty)}">`)}
      ${fld("pl-unit", W("الوحدة", "Unit"), `<select id="pl-unit" data-k="unit">${selOpts(UNITS.map(([v, a, e]) => [v, W(a, e)]), d.unit)}</select>`)}
      ${fld("pl-prod", W("تاريخ الإنتاج", "Production date"), `<input type="date" id="pl-prod" data-k="prod" value="${esc(d.prod)}">`)}
      ${fld("pl-dtype", W("نوع التاريخ", "Date type"), `<select id="pl-dtype" data-k="dtype">${selOpts([["exp", W("تاريخ الانتهاء", "Expiry date")], ["bb", W("يُفضّل استهلاكه قبل", "Best before")]], d.dtype)}</select>`)}
      ${fld("pl-exp", d.dtype === "bb" ? W("تاريخ «يُفضّل استهلاكه قبل»", "Best-before date") : W("تاريخ الانتهاء", "Expiry date"), `<input type="date" id="pl-exp" data-k="exp" value="${esc(d.exp)}">`, { hint: W("أدخله من دراسة صلاحية منتجك؛ الأداة لا تقترح مدة صلاحية.", "Enter it from your product's shelf-life study; the tool doesn't suggest a shelf life.") })}
      ${fld("pl-batch", W("رقم التشغيلة", "Batch number"), `<input type="text" id="pl-batch" data-k="batch" dir="ltr" value="${esc(d.batch)}">`, { hint: W("يمكنك توليده بأداة رمز التشغيلة.", "You can generate it with the batch code tool.") })}
      <h3 class="pt-h">${esc(W("التخزين والمنشأ والمصنّع", "Storage, origin & manufacturer"))}</h3>
      ${bi("sto", "تعليمات التخزين", "Storage instructions")}
      ${bi("ori", "بلد المنشأ", "Country of origin")}
      ${bi("mak", "اسم وعنوان المصنّع / المعبّئ", "Manufacturer / packer name & address", { ta: true })}
      <h3 class="pt-h">${esc(W("الباركود وQR", "Barcode & QR"))}</h3>
      ${fld("pl-bc", W("نوع الباركود", "Barcode type"), `<select id="pl-bc" data-k="bc">${selOpts([["", W("بدون", "None")], ["ean13", "EAN-13"], ["c128", "Code 128"]], d.bc)}</select>`)}
      ${fld("pl-bcv", W("قيمة الباركود", "Barcode value"), `<input type="text" id="pl-bcv" data-k="bcv" dir="ltr" autocomplete="off" value="${esc(d.bcv)}">`, { hint: W("أرقام GTIN الحقيقية تُرخَّص من GS1.", "Real GTINs are licensed from GS1.") })}
      ${fld("pl-qr", W("رابط QR (اختياري)", "QR link (optional)"), `<input type="text" id="pl-qr" data-k="qr" dir="ltr" inputmode="url" autocomplete="off" placeholder="https://" value="${esc(d.qr)}">`, { full: true })}
      <h3 class="pt-h">${esc(W("جدول القيم الغذائية (اختياري)", "Nutrition table (optional)"))}</h3>
      ${fld("pl-nut", W("استيراد من حاسبة القيم الغذائية", "Import from the nutrition calculator"), `<select id="pl-nut">${nutOpts()}</select>`, { hint: nutRecs().length ? W("تُنسخ القيم إلى القالب عند الاختيار.", "Values are copied into the template when selected.") : W("لا توجد وصفات محفوظة بعد.", "No saved recipes yet.") })}
      ${fld("pl-nutm", W("الأعمدة", "Columns"), `<select id="pl-nutm" data-k="nutMode">${selOpts([["p100", W("لكل 100 غ", "Per 100 g")], ["ps", W("لكل حصة", "Per serving")], ["both", W("الاثنان", "Both")]], d.nutMode)}</select>`)}
      <p class="note full" style="margin:0"><a href="#/tools/nutrition">${esc(L(toolOf("nutrition") ? toolOf("nutrition").t : { ar: "حاسبة القيم الغذائية", en: "Recipe nutrition calculator" }))}</a> · <a href="#/tools/label">${esc(L(toolOf("label") ? toolOf("label").t : { ar: "فاحص بطاقة الغذاء", en: "Food label checker" }))}</a> · <a href="#/tools/batchcode">${esc(L(toolOf("batchcode").t))}</a></p>`;
  };
  const html = `${head("prodlabel")}
    <div class="pt-split">
      <form class="card" id="plForm" novalidate><div class="form" id="plFields"></div></form>
      <div class="pt-side"><div class="card"><div class="row" style="margin-bottom:10px"><h2 style="font-size:19px;margin:0">${esc(W("معاينة بالمقاس الحقيقي", "Preview at true proportions"))}</h2></div>
        <div class="pt-stagehost" id="plStage" aria-label="${esc(W("معاينة الملصق", "Label preview"))}" role="img"></div>
        <div class="row" id="plInfo" style="margin-top:10px;gap:6px"></div>
        <div id="plWarn" style="margin-top:12px" aria-live="polite"></div>
        <div class="row" style="margin-top:14px"><button type="button" class="btn btn-gold" id="plPrint">${I.printer}<span>${esc(W("طباعة الملصقات", "Print labels"))}</span></button><span class="err" id="plErr" role="alert"></span></div>
        <p class="note">${esc(W("في نافذة الطباعة اختر الطابعة الصحيحة واضبط المقياس على 100% (الحجم الفعلي) دون هوامش.", "In the print dialog choose the right printer and set scale to 100 % (actual size) with no margins."))}</p></div></div>
    </div>
    <div class="card" style="margin-top:22px"><h2 style="font-size:20px">${esc(W("قوالب المنتجات", "Product templates"))}</h2>
      <div class="row"><div class="field" style="flex:1;min-width:200px"><label for="pl-tname">${esc(W("اسم القالب", "Template name"))}</label><input type="text" id="pl-tname"><span class="err" id="pl-tname-e"></span></div><button type="button" class="btn btn-ghost" id="plSave" style="align-self:flex-end">${I.check}<span>${esc(W("حفظ القالب", "Save template"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="plNew" style="align-self:flex-end">${I.plus}<span>${esc(W("ملصق جديد", "New label"))}</span></button></div>
      <div id="plList" style="margin-top:14px"></div></div>
  </div></section>`;

  function after() {
    const form = $("#plForm");
    const showHide = () => {
      const langs = langsOf(), sz = plSize(d);
      $$("[data-lg]", form).forEach((el) => (el.hidden = !langs.includes(el.dataset.lg)));
      $$('[data-show="custom"]', form).forEach((el) => (el.hidden = d.size !== "custom"));
      $$('[data-show="sheet"]', form).forEach((el) => (el.hidden = sz.kind !== "sheet"));
      $$("[data-mode]", form).forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.mode === d.mode)));
      const lab = $('label[for="pl-exp"]'); if (lab) lab.textContent = d.dtype === "bb" ? W("تاريخ «يُفضّل استهلاكه قبل»", "Best-before date") : W("تاريخ الانتهاء", "Expiry date");
    };
    const drawFields = () => { $("#plFields").innerHTML = fieldsHtml(); showHide(); };
    // hard errors that block printing; returns true when printable
    const validate = () => {
      const sz = plSize(d); let ok = true;
      if (d.size === "custom") { ok = setErr("pl-cw", isFinite(sz.w) && sz.w >= 10 && sz.w <= 300 ? "" : W("بين 10 و300 مم.", "Between 10 and 300 mm.")) && ok; ok = setErr("pl-ch", isFinite(sz.h) && sz.h >= 10 && sz.h <= 300 ? "" : W("بين 10 و300 مم.", "Between 10 and 300 mm.")) && ok; }
      ok = setErr("pl-copies", isInt(d.copies, 1, 500) ? "" : W("عدد صحيح من 1 إلى 500.", "A whole number from 1 to 500.")) && ok;
      if (sz.kind === "sheet") ok = setErr("pl-skip", String(d.skip).trim() === "" || isInt(d.skip, 0, sz.cols * sz.rows - 1) ? "" : W(`عدد صحيح من 0 إلى ${sz.cols * sz.rows - 1}.`, `A whole number from 0 to ${sz.cols * sz.rows - 1}.`)) && ok;
      ok = setErr("pl-qty", String(d.qty).trim() === "" || Number(d.qty) > 0 ? "" : W("أدخل رقمًا أكبر من صفر.", "Enter a number above zero.")) && ok;
      ok = setErr("pl-exp", pD(d.exp) && pD(d.prod) && d.exp < d.prod ? W("يجب ألا يسبق تاريخ الإنتاج.", "Can't be before the production date.") : "") && ok;
      const bk = bcCheck(d.bc, d.bcv); ok = setErr("pl-bcv", d.bc && !bk.ok ? bk.msg : "") && ok;
      ok = setErr("pl-qr", String(d.qr || "").trim() && !qrOk(d.qr) ? W("أدخل رابطًا كاملًا صالحًا مثل https://example.com دون مسافات.", "Enter a full valid link such as https://example.com with no spaces.") : "") && ok;
      return ok;
    };
    const render = async () => {
      const my = ++tok; validate();
      const sz = plSize(d), host = $("#plStage");
      if (!(sz.w >= 10 && sz.w <= 300 && sz.h >= 10 && sz.h <= 300)) { host.innerHTML = `<p class="note">${esc(W("أدخل مقاسًا صالحًا للمعاينة.", "Enter a valid size to preview."))}</p>`; $("#plInfo").innerHTML = ""; return; }
      const cx = await plCodes(d, sz); if (my !== tok) return;
      const lab = stage(host, sz.w, sz.h, plHtml(d, sz, cx));
      const f = fit(lab, maxPtFor(sz.h)); fitPt = f.pt;
      const per = sz.kind === "sheet" ? sz.cols * sz.rows : 0, copies = isInt(d.copies, 1, 500) ? +d.copies : 0, skip = isInt(d.skip, 0, 999) ? +d.skip : 0;
      $("#plInfo").innerHTML = `<span class="chip">${esc(sizeName(sz))}</span><span class="chip ${f.ok ? "" : "bad"}">${esc(W("حجم الخط", "Text size"))}: <b dir="ltr">${f.pt} pt</b></span>${per && copies ? `<span class="chip">${esc(W("أوراق A4", "A4 sheets"))}: <b>${Math.ceil((skip + copies) / per)}</b></span>` : ""}${cx.mag ? `<span class="chip ${cx.mag < 0.8 ? "warn" : ""}">EAN-13: <b dir="ltr">${Math.round(cx.mag * 100)} %</b> ${esc(W("من الحجم الاسمي", "of nominal size"))}</span>` : ""}${cx.x ? `<span class="chip">Code 128 X ≈ <b dir="ltr">${cx.x.toFixed(2)} mm</b></span>` : ""}`;
      const fl = $("#pl-found"); if (fl) fl.innerHTML = cx.found.size ? `<span class="lbl">${esc(W("مسببات حساسية وُجدت وستظهر بخط عريض", "Allergens found (shown in bold)"))}:</span> ${[...cx.found].map((a) => `<span class="chip gold">${esc(a)}</span>`).join(" ")}` : `<span class="note" style="margin:0">${esc(W("لم يُعثر على كلمات مسببات حساسية في المكونات.", "No allergen keywords found in the ingredients."))}</span>`;
      const miss = plMissing(d, cx.found);
      $("#plWarn").innerHTML = `${!f.ok ? `<p class="err" style="margin:0 0 8px">${esc(W("النص لا يتسع حتى بأصغر خط — اختر مقاسًا أكبر أو اختصر النص.", "The text doesn't fit even at the smallest size — choose a bigger label or shorten the text."))}</p>` : ""}${miss.length ? `<span class="lbl">${esc(W("عناصر إلزامية ناقصة", "Missing mandatory items"))}:</span><div class="row" style="gap:6px;margin-top:6px">${miss.map((x) => `<span class="chip warn">${esc(x)}</span>`).join("")}</div>` : `<span class="chip ok">${esc(W("العناصر الأساسية مكتملة", "Core items complete"))}</span>`}${d.mode === "en" ? `<div style="margin-top:6px"><span class="chip bad">${esc(W("لا يوجد نص عربي", "No Arabic text"))}</span></div>` : ""}<p class="note" style="margin-bottom:0">${esc(W("تحقق من اللائحة المطبقة عليك (مثل لوائح الهيئة العامة للغذاء والدواء SFDA)؛ اللغة العربية مطلوبة على بطاقة الغذاء في المملكة العربية السعودية. افحص البطاقة النهائية بأداة فاحص بطاقة الغذاء.", "Check your applicable regulation (e.g. SFDA); Arabic is required on food labels in Saudi Arabia. Review the final label with the food label checker."))}</p>`;
    };
    const schedule = () => { clearTimeout(timer); timer = setTimeout(render, 90); };
    const persist = () => store.set(DK, d);
    form.addEventListener("input", (e) => {
      const el = e.target;
      if (el.id === "pl-alg-ar" || el.id === "pl-alg-en") { const w = algWords(); w[el.id.slice(-2)] = el.value; store.set(ALG_KEY, { ar: w.ar, en: w.en }); schedule(); return; }
      if (el.id === "pl-nut") { const r = nutRecs().find((x) => x.id === el.value); d.nut = r ? { id: r.id, name: r.name, p100: r.out.p100, ps: r.out.ps, servW: r.out.servW } : el.value && d.nut && d.nut.id === el.value ? d.nut : null; persist(); schedule(); return; }
      const k = el.dataset.k; if (!k) return;
      d[k] = el.value; if (k === "size" || k === "dtype") showHide();
      persist(); schedule();
    });
    form.addEventListener("click", (e) => {
      const mb = e.target.closest("[data-mode]"); if (mb) { d.mode = mb.dataset.mode; showHide(); persist(); schedule(); }
      if (e.target.closest("#pl-alg-reset")) { store.del(ALG_KEY); $("#pl-alg-ar").value = DEF_ALG.ar; $("#pl-alg-en").value = DEF_ALG.en; schedule(); }
    });
    form.addEventListener("submit", (e) => e.preventDefault());
    const doPrint = async (data) => {
      const keep = d; d = data;
      try {
        if (!validate()) { $("#plErr").textContent = t("fixErrors"); focusBad(form); return; }
        $("#plErr").textContent = "";
        await render();
        const sz = plSize(d), cx = await plCodes(d, sz);
        printLabels(sz, plHtml(d, sz, cx, Math.floor(fitPt * 0.97 * 10) / 10), +d.copies, sz.kind === "sheet" ? +d.skip || 0 : 0, d.name_en || d.name_ar || L(toolOf("prodlabel").t));
      } finally { if (keep !== data) { d = keep; drawFields(); render(); } }
    };
    $("#plPrint").addEventListener("click", () => doPrint(d));
    const recs = () => store.get(RK, []) || [];
    const drawList = () => {
      const all = recs();
      $("#plList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("القالب", "Template"))}</th><th>${esc(W("المنتج", "Product"))}</th><th>${esc(W("المقاس", "Size"))}</th><th>${esc(W("آخر تحديث", "Updated"))}</th><th></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr><td>${esc(r.tname)}</td><td>${esc(r.data.name_ar || r.data.name_en || "")}</td><td dir="ltr">${esc(sizeName(plSize(r.data)))}</td><td>${esc(fmtDate(new Date(r.updated).toISOString()))}</td><td style="white-space:nowrap">${iconBtn("ld", r.id, I.note, W("تحميل", "Load"))} ${iconBtn("pr", r.id, I.printer, t("print"))} ${iconBtn("del", r.id, I.trash, t("del"))}</td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(W("لا توجد قوالب محفوظة بعد.", "No saved templates yet."))}</div>`;
    };
    $("#plSave").addEventListener("click", () => {
      const name = $("#pl-tname").value.trim() || String(d.name_ar || d.name_en || "").trim();
      if (!setErr("pl-tname", name ? "" : W("أدخل اسم القالب أو اسم المنتج.", "Enter a template name or a product name."))) { $("#pl-tname").focus(); return; }
      const all = recs(), i = all.findIndex((r) => r.tname === name);
      if (i >= 0 && !confirm(W("يوجد قالب بهذا الاسم. هل تريد استبداله؟", "A template with this name exists. Replace it?"))) return;
      const rec = { id: i >= 0 ? all[i].id : uid(), tname: name, data: clone(d), updated: Date.now() };
      if (i >= 0) all[i] = rec; else all.push(rec);
      if (store.set(RK, all)) { $("#pl-tname").value = name; toast(t("saved")); drawList(); }
    });
    $("#plNew").addEventListener("click", () => { if (!confirm(W("مسح الحقول والبدء بملصق جديد؟", "Clear the fields and start a new label?"))) return; d = PL_DEF(); persist(); $("#pl-tname").value = ""; drawFields(); render(); });
    $("#plList").addEventListener("click", (e) => {
      const all = recs(), ld = e.target.closest("[data-ld]"), pr = e.target.closest("[data-pr]"), dl = e.target.closest("[data-del]");
      if (ld) { const r = all.find((x) => x.id === ld.dataset.ld); d = Object.assign(PL_DEF(), clone(r.data)); persist(); $("#pl-tname").value = r.tname; drawFields(); render(); A.scrollTo(form, true); toast(W("حُمّل القالب.", "Template loaded.")); }
      if (pr) { const r = all.find((x) => x.id === pr.dataset.pr); doPrint(Object.assign(PL_DEF(), clone(r.data))); }
      if (dl && confirm(t("confirmDel"))) { store.set(RK, all.filter((x) => x.id !== dl.dataset.del)); drawList(); toast(t("deleted")); }
    });
    window.addEventListener("resize", schedule, { passive: true });
    drawFields(); drawList(); render();
  }
  return { title: L(toolOf("prodlabel").t), html, after };
}

/* =====================================================================
   2) Batch / date code generator
   ===================================================================== */
const TOKS = ["PLANT", "LINE", "YY", "YYYY", "MM", "DD", "DDD", "WW", "SHIFT", "SEQ"];
const tokName = (k) => ({ PLANT: W("رمز المصنع", "Plant code"), LINE: W("خط الإنتاج", "Line"), YY: W("السنة (رقمان)", "Year (2 digits)"), YYYY: W("السنة (4 أرقام)", "Year (4 digits)"), MM: W("الشهر", "Month"), DD: W("اليوم", "Day"), DDD: W("اليوم اليولياني (001–366)", "Julian day (001–366)"), WW: W("رقم الأسبوع ISO", "ISO week"), SHIFT: W("الوردية", "Shift"), SEQ: W("التسلسل اليومي", "Daily sequence") })[k];
const GS1_RE = /^[!"%&'()*+,\-./0-9:;<=>?A-Z_a-z]{1,20}$/;
const BC_DEF = () => ({ pattern: "{PLANT}{LINE}-{YY}{DDD}{SHIFT}{SEQ}", plant: "", line: "", shift: "A", seqLen: 3, prod: todayL(), shelf: "", fmt: "dmy", gtin: "", product: "" });
const BC_FMTS = [["dmy", "DD/MM/YYYY"], ["my", "MM/YYYY"], ["bben", "Best before DD/MM/YYYY"], ["bbar", "يُفضّل استهلاكه قبل DD/MM/YYYY"], ["arm", "05 نوفمبر 2026"]];
function fmtD(s, f) { const [y, m, d] = s.split("-"); if (f === "my") return `${m}/${y}`; if (f === "bben") return `Best before ${d}/${m}/${y}`; if (f === "bbar") return `يُفضّل استهلاكه قبل ${d}/${m}/${y}`; if (f === "arm") return `${d} ${AR_MONTHS[+m - 1]} ${y}`; return `${d}/${m}/${y}`; }
const tokVals = (s, seq) => { const [y, m, d] = s.prod.split("-"); return { PLANT: s.plant.trim(), LINE: s.line.trim(), YY: y.slice(2), YYYY: y, MM: m, DD: d, DDD: pad2(doy(s.prod), 3), WW: pad2(isoWeek(s.prod).w), SHIFT: s.shift, SEQ: pad2(seq, +s.seqLen) }; };
const buildCode = (s, seq) => { const v = tokVals(s, seq); return s.pattern.replace(/\{([A-Z]+)\}/g, (_, k) => v[k]); };
const gtin14 = (g) => g.padStart(14, "0");
function gs1(gtin, batch, prod, exp) {
  const hr = (gtin ? `(01)${gtin14(gtin)}` : "") + `(10)${batch}(11)${yymmdd(prod)}` + (exp ? `(17)${yymmdd(exp)}` : "");
  // FNC1 (\xCF) ends the variable-length batch field because more AIs follow it
  const data = (gtin ? `01${gtin14(gtin)}` : "") + `10${batch}\xCF11${yymmdd(prod)}` + (exp ? `17${yymmdd(exp)}` : "");
  return { hr, data };
}
function bcCompute(s, log) {
  const e = {}, toks = [...s.pattern.matchAll(/\{([^}]*)\}/g)].map((m) => m[1]), unk = toks.filter((k) => !TOKS.includes(k));
  if (!s.pattern.trim()) e.pattern = t("required");
  else if (unk.length) e.pattern = W(`رمز غير معروف: {${unk[0]}}`, `Unknown token: {${unk[0]}}`);
  else if (/[{}]/.test(s.pattern.replace(/\{[A-Z]+\}/g, ""))) e.pattern = W("أقواس غير مكتملة في النمط.", "Unbalanced braces in the pattern.");
  ["plant", "line"].forEach((k) => { if (/[{}]/.test(s[k])) e[k] = W("لا تستخدم الأقواس { }.", "Don't use braces { }."); else if (toks.includes(k.toUpperCase()) && !s[k].trim()) e[k] = W(`النمط يستخدم {${k.toUpperCase()}} — أدخل القيمة.`, `The pattern uses {${k.toUpperCase()}} — enter a value.`); });
  if (!pD(s.prod)) e.prod = t("required");
  if (String(s.shelf).trim() !== "" && !isInt(s.shelf, 0, 3650)) e.shelf = W("عدد صحيح من الأيام بين 0 و3650.", "Whole days between 0 and 3650.");
  if (!isInt(s.seqLen, 1, 6)) e.seqLen = W("من 1 إلى 6.", "From 1 to 6.");
  const g = String(s.gtin || "").replace(/\s/g, "");
  if (g) { if (!/^\d+$/.test(g) || ![8, 12, 13, 14].includes(g.length)) e.gtin = W("يتكون GTIN من 8 أو 12 أو 13 أو 14 رقمًا.", "A GTIN has 8, 12, 13 or 14 digits."); else { const c = gtinCheck(g.slice(0, -1)); if (c !== +g.slice(-1)) e.gtin = W(`رقم التحقق غير صحيح — المتوقع ${c}.`, `Wrong check digit — expected ${c}.`); } }
  if (e.pattern || e.prod || e.seqLen || e.plant || e.line) return { e };
  const seq = log.filter((r) => r.prod === s.prod && r.plant === s.plant.trim() && r.line === s.line.trim()).reduce((m, r) => Math.max(m, +r.seq || 0), 0) + 1;
  if (toks.includes("SEQ") && seq >= 10 ** +s.seqLen) e.seq = W("نفدت أرقام التسلسل لهذا اليوم — زد عدد الخانات.", "This day's sequence numbers are used up — add digits.");
  const code = buildCode(s, seq), exp = !e.shelf && String(s.shelf).trim() !== "" ? addDays(s.prod, +s.shelf) : "";
  let g1 = null, gErr = "";
  if (!GS1_RE.test(code)) gErr = W("رمز التشغيلة لا يصلح للمعرّف GS1 (10): حتى 20 حرفًا من A–Z وa–z و0–9 و- . / _ ورموز محددة، دون مسافات أو حروف عربية.", "This batch code can't go into GS1 AI (10): up to 20 characters from A–Z, a–z, 0–9, - . / _ and a few symbols — no spaces or Arabic letters.");
  else if (!e.gtin) g1 = gs1(g, code, s.prod, exp);
  return { e, seq, code, exp, g1, gErr, gtin: g, toks };
}
function decodeCode(code, pattern, s) {
  code = String(code || "").trim();
  if (!code) return { err: t("required") };
  if (code.startsWith("(")) {
    const ai = {}; for (const m of code.matchAll(/\((\d{2,4})\)([^(]*)/g)) ai[m[1]] = m[2];
    const dt = (v) => (v && /^\d{6}$/.test(v) ? mkDate(2000 + +v.slice(0, 2), +v.slice(2, 4), +v.slice(4, 6)) : null);
    if (!ai["10"] && !ai["11"]) return { err: W("لم يُعثر على المعرّفات (10) أو (11).", "No (10) or (11) application identifiers found.") };
    const v = { GTIN: ai["01"] || "", BATCH: ai["10"] || "", "(11)": ai["11"] || "", "(17)": ai["17"] || "" }, date = dt(ai["11"]);
    if (!date) return { gs1: true, v, err: ai["11"] ? W("قيمة (11) ليست تاريخًا صحيحًا بصيغة YYMMDD.", "The (11) value isn't a valid YYMMDD date.") : W("لا يوجد تاريخ إنتاج (11) في السلسلة.", "There's no (11) production date in the string.") };
    return { gs1: true, v, date, exp: dt(ai["17"]), how: "GS1 (11)" };
  }
  const len = (x) => [...String(x || "").trim()].length;
  const re = { PLANT: len(s.plant) ? `(.{${len(s.plant)}})` : "(.+?)", LINE: len(s.line) ? `(.{${len(s.line)}})` : "(.+?)", YY: "(\\d{2})", YYYY: "(\\d{4})", MM: "(\\d{2})", DD: "(\\d{2})", DDD: "(\\d{3})", WW: "(\\d{2})", SHIFT: "([A-Za-z])", SEQ: `(\\d{${isInt(s.seqLen, 1, 6) ? +s.seqLen : 3}})` };
  let src = "^", last = 0; const names = [];
  for (const m of pattern.matchAll(/\{([A-Z]+)\}/g)) { if (!re[m[1]]) return { err: W(`رمز غير معروف في النمط: {${m[1]}}`, `Unknown token in the pattern: {${m[1]}}`) }; src += reEsc(pattern.slice(last, m.index)) + re[m[1]]; names.push(m[1]); last = m.index + m[0].length; }
  src += reEsc(pattern.slice(last)) + "$";
  const mm = new RegExp(src, "u").exec(code);
  if (!mm) return { err: W("الرمز لا يطابق النمط المختار.", "The code doesn't match the chosen pattern.") };
  const v = {}; names.forEach((n, i) => (v[n] = mm[i + 1]));
  const y = v.YYYY ? +v.YYYY : v.YY ? 2000 + +v.YY : null;
  let date = null, how = "";
  if (y && v.MM && v.DD) { date = mkDate(y, +v.MM, +v.DD); how = W("السنة/الشهر/اليوم", "Year/month/day"); }
  else if (y && v.DDD) { date = fromDoy(y, +v.DDD); how = W("اليوم اليولياني", "Julian day"); }
  else if (y && v.WW) { date = +v.WW >= 1 && +v.WW <= 53 ? fromWeek(y, +v.WW) : null; how = W("أسبوع ISO (يوم الاثنين)", "ISO week (its Monday)"); }
  if (!y) return { v, err: W("النمط لا يحتوي على سنة، فلا يمكن استخراج التاريخ.", "The pattern has no year, so the date can't be recovered.") };
  if (!date) return { v, err: W("الأرقام لا تمثل تاريخًا صحيحًا.", "The digits don't form a valid date.") };
  return { v, date, how };
}

function batchcodePage() {
  const DK = "tool:batchcode:draft", RK = "tool:batchcode";
  let s = Object.assign(BC_DEF(), store.get(DK, {}) || {}); s.prod = s.prod || todayL();
  const log = () => store.get(RK, []) || [];
  const html = `${head("batchcode")}
    <div class="pt-split">
      <form class="card" id="bcForm" novalidate><div class="form">
        <h3 class="pt-h">${esc(W("نمط الرمز", "Code pattern"))}</h3>
        ${fld("bc-pattern", W("النمط", "Pattern"), `<input type="text" id="bc-pattern" data-k="pattern" dir="ltr" autocomplete="off" spellcheck="false" value="${esc(s.pattern)}">`, { full: true, req: true, hint: W("أدرج الرموز بالأزرار، واكتب أي فواصل حرة بينها (- / . أو مسافة).", "Insert tokens with the buttons and type any free separators between them (- / . or space).") })}
        <div class="full row pt-tokens" role="group" aria-label="${esc(W("إدراج رمز", "Insert token"))}">${TOKS.map((k) => `<button type="button" class="chip pt-tg" data-tok="${k}" title="${esc(tokName(k))}"><span dir="ltr">{${k}}</span> <span class="pt-tk">${esc(tokName(k))}</span></button>`).join("")}</div>
        ${fld("bc-plant", tokName("PLANT"), `<input type="text" id="bc-plant" data-k="plant" dir="ltr" value="${esc(s.plant)}">`)}
        ${fld("bc-line", tokName("LINE"), `<input type="text" id="bc-line" data-k="line" dir="ltr" value="${esc(s.line)}">`)}
        ${fld("bc-shift", tokName("SHIFT"), `<select id="bc-shift" data-k="shift">${selOpts(["A", "B", "C"].map((x) => [x, x]), s.shift)}</select>`)}
        ${fld("bc-seqLen", W("خانات التسلسل", "Sequence digits"), `<input type="number" id="bc-seqLen" data-k="seqLen" min="1" max="6" step="1" inputmode="numeric" value="${esc(s.seqLen)}">`, { hint: W("يبدأ من 1 لكل يوم إنتاج وخط، ويزيد مع كل رمز تُصدره.", "Starts at 1 for each production day and line and goes up with each code you issue.") })}
        <h3 class="pt-h">${esc(W("التواريخ", "Dates"))}</h3>
        ${fld("bc-prod", W("تاريخ الإنتاج", "Production date"), `<input type="date" id="bc-prod" data-k="prod" value="${esc(s.prod)}">`, { req: true })}
        ${fld("bc-shelf", W("مدة الصلاحية (أيام)", "Shelf life (days)"), `<input type="number" id="bc-shelf" data-k="shelf" min="0" max="3650" step="1" inputmode="numeric" value="${esc(s.shelf)}">`, { hint: W("من دراسة صلاحية منتجك. اتركه فارغًا إن لم يلزم تاريخ انتهاء.", "From your product's shelf-life study. Leave blank if no expiry is needed.") })}
        ${fld("bc-fmt", W("صيغة عرض التاريخ", "Date display format"), `<select id="bc-fmt" data-k="fmt">${selOpts(BC_FMTS, s.fmt)}</select>`)}
        <h3 class="pt-h">GS1-128</h3>
        ${fld("bc-gtin", W("GTIN (اختياري)", "GTIN (optional)"), `<input type="text" id="bc-gtin" data-k="gtin" dir="ltr" inputmode="numeric" autocomplete="off" value="${esc(s.gtin)}">`, { hint: W("8 أو 12 أو 13 أو 14 رقمًا مع رقم التحقق.", "8, 12, 13 or 14 digits including the check digit.") })}
        ${fld("bc-product", W("المنتج (للسجل)", "Product (for the log)"), `<input type="text" id="bc-product" data-k="product" value="${esc(s.product)}">`)}
      </div></form>
      <div class="pt-side"><div class="card" id="bcOut" aria-live="polite"></div></div>
    </div>
    <div class="card" style="margin-top:22px"><h2 style="font-size:20px">${esc(W("فك رمز", "Decode a code"))}</h2>
      <div class="form">${fld("dc-code", W("الرمز أو سلسلة GS1", "Code or GS1 string"), `<input type="text" id="dc-code" dir="ltr" autocomplete="off" spellcheck="false">`, { hint: W("مثال: (01)…(10)…(11)…", "e.g. (01)…(10)…(11)…") })}
        ${fld("dc-pattern", W("النمط", "Pattern"), `<input type="text" id="dc-pattern" dir="ltr" autocomplete="off" spellcheck="false" value="${esc(s.pattern)}">`)}
        <div class="full row"><button type="button" class="btn btn-ghost" id="dcGo">${I.search}<span>${esc(W("فك الرمز", "Decode"))}</span></button></div></div>
      <div id="dcOut" aria-live="polite" style="margin-top:12px"></div></div>
    <div class="row" style="margin:30px 0 12px"><h2 style="font-size:22px;margin:0">${esc(W("سجل الرموز المُصدرة", "Issued codes log"))} <span class="chip" id="bcN"></span></h2><span class="spacer"></span>
      <input type="search" id="bcQ" placeholder="${esc(W("بحث…", "Search…"))}" aria-label="${esc(W("بحث في السجل", "Search the log"))}" style="width:auto;min-width:160px;height:38px">
      <button type="button" class="btn btn-ghost btn-sm" id="bcCsv">${I.download}<span>${esc(t("exportCsv"))}</span></button></div>
    <p class="note" style="margin-top:0">${esc(W("مفيد لتمارين الاسترجاع الوهمي: ابحث عن تشغيلة أو تاريخ وصدّر القائمة.", "Useful for mock recalls: search a batch or date and export the list."))}</p>
    <div id="bcList"></div>
  </div></section>`;

  function after() {
    const form = $("#bcForm");
    let cur = null;
    const draw = () => {
      cur = bcCompute(s, log());
      ["pattern", "plant", "line", "prod", "shelf", "seqLen", "gtin"].forEach((k) => setErr("bc-" + k, cur.e[k] || ""));
      const o = $("#bcOut");
      if (!cur.code) { o.innerHTML = `<h2 style="font-size:19px">${esc(W("الرمز", "Code"))}</h2><p class="err">${esc(W("صحّح الحقول المؤشّرة.", "Fix the highlighted fields."))}</p>`; return; }
      const wk = isoWeek(s.prod);
      let bar = "";
      if (cur.g1) { try { const r = c128(cur.g1.data, true); bar = `<div class="pt-bc" style="margin-top:12px">${r.svg.replace("<svg", '<svg style="width:100%;max-width:420px;height:70px"')}<div class="pt-mono" style="color:#000;font-size:13px;margin-top:4px">${esc(cur.g1.hr)}</div></div>`; } catch (_) { bar = `<p class="err">${esc(W("تعذّر إنشاء الباركود.", "Couldn't build the barcode."))}</p>`; } }
      o.innerHTML = `<h2 style="font-size:19px;margin-bottom:6px">${esc(W("الرمز التالي", "Next code"))}</h2>
        <div class="pt-mono pt-code" id="bcCode">${esc(cur.code)}</div>
        ${cur.e.seq ? `<p class="err">${esc(cur.e.seq)}</p>` : ""}
        <table class="t" style="min-width:0;margin-top:12px"><tbody>
          <tr><th>${esc(W("الإنتاج", "Production"))}</th><td><bdi dir="ltr" id="bcProd">${esc(fmtD(s.prod, /^bb/.test(s.fmt) ? "dmy" : s.fmt))}</bdi> <span class="note">(${esc(W(...wdayOf(s.prod).slice(0, 2)))})</span></td></tr>
          <tr><th>${esc(W("الانتهاء", "Expiry"))}</th><td>${cur.exp ? `<bdi dir="ltr" id="bcExp">${esc(fmtD(cur.exp, s.fmt))}</bdi>` : `<span class="note">${esc(W("أدخل مدة الصلاحية لحسابه.", "Enter the shelf life to compute it."))}</span>`}</td></tr>
          <tr><th>${esc(W("اليوم اليولياني", "Julian day"))}</th><td dir="ltr" style="text-align:start" id="bcDoy">${pad2(doy(s.prod), 3)}</td></tr>
          <tr><th>${esc(W("أسبوع ISO", "ISO week"))}</th><td dir="ltr" style="text-align:start">${wk.y}-W${pad2(wk.w)}</td></tr>
          <tr><th>${esc(W("التسلسل", "Sequence"))}</th><td dir="ltr" style="text-align:start">${cur.toks.includes("SEQ") ? pad2(cur.seq, +s.seqLen) : "—"}</td></tr>
          <tr><th>GS1-128</th><td>${cur.g1 ? `<span class="pt-mono" id="bcGs1">${esc(cur.g1.hr)}</span>` : `<span class="note">${esc(cur.gErr || cur.e.gtin || "")}</span>`}</td></tr>
        </tbody></table>${bar}
        <div class="row" style="margin-top:14px"><button type="button" class="btn btn-gold" id="bcIssue" ${cur.e.seq ? "disabled" : ""}>${I.check}<span>${esc(W("إصدار وتسجيل", "Issue & log"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="bcCopy">${esc(W("نسخ الرمز", "Copy code"))}</button>${cur.g1 ? `<button type="button" class="btn btn-ghost btn-sm" id="bcSvg">${I.download}<span>SVG</span></button>` : ""}<span class="err" id="bcErr" role="alert"></span></div>
        ${cur.toks.some((k) => ["YY", "YYYY"].includes(k)) && cur.toks.some((k) => ["DDD", "MM", "WW"].includes(k)) ? "" : `<p class="note">${esc(W("تنبيه: النمط لا يحتوي على سنة وتاريخ كاملين، فلن يمكن استخراج تاريخ الإنتاج من الرمز.", "Note: the pattern lacks a year plus a date part, so the production date can't be recovered from the code."))}</p>`}
        <p class="note" style="margin-bottom:0">${esc(W("صيغة GS1: ‏(11) تاريخ الإنتاج و(17) تاريخ الانتهاء بصيغة YYMMDD. تأكد من متطلبات عميلك أو لائحتك.", "GS1 format: (11) production and (17) expiry dates as YYMMDD. Confirm your customer's or regulator's requirements."))}</p>`;
    };
    form.addEventListener("input", (e) => { const k = e.target.dataset.k; if (!k) return; s[k] = e.target.value; store.set(DK, s); draw(); });
    form.addEventListener("submit", (e) => e.preventDefault());
    form.addEventListener("click", (e) => {
      const b = e.target.closest("[data-tok]"); if (!b) return;
      const el = $("#bc-pattern"), tk = `{${b.dataset.tok}}`, a = el.selectionStart == null ? el.value.length : el.selectionStart, z = el.selectionEnd == null ? a : el.selectionEnd;
      el.value = el.value.slice(0, a) + tk + el.value.slice(z); el.focus(); el.setSelectionRange(a + tk.length, a + tk.length);
      el.dispatchEvent(new Event("input", { bubbles: true }));
    });
    $("#bcOut").addEventListener("click", async (e) => {
      if (e.target.closest("#bcIssue")) {
        const c = bcCompute(s, log());
        if (!c.code || Object.values(c.e).some(Boolean)) { $("#bcErr").textContent = t("fixErrors"); focusBad(form); return; }
        const all = log();
        if (all.some((r) => r.code === c.code)) { $("#bcErr").textContent = W("هذا الرمز صدر من قبل — أضف {SEQ} أو {SHIFT} إلى النمط.", "This code was already issued — add {SEQ} or {SHIFT} to the pattern."); return; }
        all.push({ id: uid(), code: c.code, product: s.product.trim(), gtin: c.gtin, plant: s.plant.trim(), line: s.line.trim(), shift: c.toks.includes("SHIFT") ? s.shift : "", seq: c.toks.includes("SEQ") ? c.seq : "", prod: s.prod, exp: c.exp, shelf: String(s.shelf).trim(), gs1: c.g1 ? c.g1.hr : "", pattern: s.pattern, created: Date.now() });
        if (store.set(RK, all)) { toast(W(`صدر الرمز ${c.code}`, `Issued ${c.code}`)); draw(); drawList(); }
      }
      if (e.target.closest("#bcCopy")) { try { await navigator.clipboard.writeText(cur.code); toast(W("نُسخ.", "Copied.")); } catch (_) { toast(W("تعذّر النسخ — انسخه يدويًا.", "Couldn't copy — copy it manually."), "bad"); } }
      if (e.target.closest("#bcSvg") && cur.g1) { const r = c128(cur.g1.data, true); const w = r.mods * 2; download(`gs1-128-${cur.code}.svg`, r.svg.replace("<svg", `<svg width="${w}" height="120"`), "image/svg+xml"); }
    });
    $("#dcGo").addEventListener("click", () => {
      const r = decodeCode($("#dc-code").value, $("#dc-pattern").value, s), o = $("#dcOut");
      setErr("dc-code", r.err && !r.v ? r.err : "");
      if (r.err && !r.v) { o.innerHTML = ""; return; }
      const hit = log().find((x) => x.code === $("#dc-code").value.trim() || (r.gs1 && x.code === r.v.BATCH));
      o.innerHTML = `${r.err ? `<p class="err">${esc(r.err)}</p>` : `<p style="margin:0 0 8px">${esc(W("تاريخ الإنتاج", "Production date"))}: <b dir="ltr" id="dcDate">${esc(dmy(r.date))}</b> <span class="note">(${esc(W(...wdayOf(r.date).slice(0, 2)))} · ${esc(r.how)})</span>${r.exp ? ` · ${esc(W("الانتهاء", "Expiry"))}: <b dir="ltr">${esc(dmy(r.exp))}</b>` : ""}</p>`}
        <div class="table-wrap"><table class="t" style="min-width:0"><tbody>${Object.entries(r.v).map(([k, v]) => `<tr><th dir="ltr" style="text-align:start">${esc(k)}</th><td dir="ltr" style="text-align:start">${esc(v)}</td></tr>`).join("")}</tbody></table></div>
        <p class="note">${hit ? esc(W(`موجود في السجل: ${hit.product || "—"} · صدر ${fmtDate(new Date(hit.created).toISOString())}`, `Found in the log: ${hit.product || "—"} · issued ${fmtDate(new Date(hit.created).toISOString())}`)) : esc(W("غير موجود في سجل هذا الجهاز.", "Not in this device's log."))}</p>`;
    });
    const filtered = () => { const q = $("#bcQ").value.trim().toLowerCase(); return log().filter((r) => !q || [r.code, r.product, r.prod, r.exp, r.gs1].join(" ").toLowerCase().includes(q)); };
    const drawList = () => {
      const all = filtered(); $("#bcN").textContent = log().length;
      $("#bcList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("الرمز", "Code"))}</th><th>${esc(W("المنتج", "Product"))}</th><th>${esc(W("الإنتاج", "Production"))}</th><th>${esc(W("الانتهاء", "Expiry"))}</th><th>${esc(W("الوردية", "Shift"))}</th><th>${esc(W("وقت الإصدار", "Issued"))}</th><th></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr><td class="pt-mono">${esc(r.code)}</td><td>${esc(r.product)}</td><td dir="ltr">${esc(dmy(r.prod))}</td><td dir="ltr">${r.exp ? esc(dmy(r.exp)) : "—"}</td><td>${esc(r.shift || "—")}</td><td>${esc(fmtDate(new Date(r.created).toISOString(), { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" }))}</td><td>${iconBtn("del", r.id, I.trash, t("del"))}</td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`;
    };
    $("#bcQ").addEventListener("input", drawList);
    $("#bcList").addEventListener("click", (e) => { const b = e.target.closest("[data-del]"); if (b && confirm(t("confirmDel"))) { store.set(RK, log().filter((r) => r.id !== b.dataset.del)); drawList(); draw(); toast(t("deleted")); } });
    $("#bcCsv").addEventListener("click", () => { const keys = ["code", "product", "gtin", "plant", "line", "shift", "seq", "prod", "exp", "shelf", "gs1", "created"]; download(`batch-codes-${todayL()}.csv`, csv([["code", "product", "gtin", "plant", "line", "shift", "sequence", "production_date", "expiry_date", "shelf_life_days", "gs1_128", "issued_at"], ...filtered().map((r) => keys.map((k) => (k === "created" ? new Date(r.created).toISOString() : r[k])))]), "text/csv;charset=utf-8"); });
    draw(); drawList();
  }
  return { title: L(toolOf("batchcode").t), html, after };
}

/* =====================================================================
   3) Kitchen / café prep labels (day-dot style)
   ===================================================================== */
const PREP_SIZES = [{ id: "40x30", w: 40, h: 30 }, { id: "50x30", w: 50, h: 30 }, { id: "60x40", w: 60, h: 40 }];
const ALG10 = [["gluten", "حبوب الغلوتين", "Gluten"], ["crust", "القشريات", "Crustaceans"], ["egg", "البيض", "Eggs"], ["fish", "الأسماك", "Fish"], ["peanut", "الفول السوداني", "Peanuts"], ["soy", "الصويا", "Soy"], ["milk", "الحليب", "Milk"], ["nuts", "المكسرات", "Tree nuts"], ["sesame", "السمسم", "Sesame"], ["sulph", "الكبريتيت", "Sulphites"]];
const STO = [["chill", "مبرّد", "Chilled"], ["frozen", "مجمّد", "Frozen"], ["ambient", "حرارة الغرفة", "Ambient"]];
// commonly used day-dot scheme, index = Date.getDay() (0 = Sunday)
const DAY_COL = ["#111111", "#1f5fbf", "#f2c200", "#d62828", "#2e9e44", "#7a4a26", "#f07c00"];
const PREP_DEF = () => ({ item: "", at: nowL(), amt: "", unit: "h", by: "", sto: "chill", alg: [], other: "", band: true, bandDay: "use", size: "40x30", copies: 1, mode: A.lang === "ar" ? "ar" : "en" });
const parseLocal = (s) => { const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(s || ""); return m ? new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]) : null; };
const useBy = (at, amt, unit) => { const d = parseLocal(at), n = Number(amt); if (!d || !(n > 0)) return null; const r = new Date(d); if (unit === "d") r.setDate(r.getDate() + n); else r.setTime(r.getTime() + n * 3600e3); return r; };
const dtShort = (d) => `${pad2(d.getDate())}/${pad2(d.getMonth() + 1)}/${String(d.getFullYear()).slice(2)} ${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
const ink = (hex) => { const n = parseInt(hex.slice(1), 16), r = n >> 16, g = (n >> 8) & 255, b = n & 255; return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.6 ? "#000" : "#fff"; };
function prepHtml(p, colors, pad) {
  const m = p.mode, c = (a, e) => (m === "bi" ? `${a} / ${e}` : m === "ar" ? a : e);
  const at = parseLocal(p.at), ub = useBy(p.at, p.amt, p.unit), bd = p.bandDay === "prep" ? at : ub;
  let h = "", band = "";
  if (p.band && bd) { const di = bd.getDay(), col = /^#[0-9a-f]{6}$/i.test(colors[di] || "") ? colors[di] : DAY_COL[di]; band = `<div class="pl-band" style="background:${col};color:${ink(col)}">${esc(m === "bi" ? `${DAYS[di][0]} · ${DAYS[di][2]}` : m === "ar" ? DAYS[di][0] : DAYS[di][1].toUpperCase())}</div>`; }
  h += `<div class="pl-nm">${esc(p.item.trim() || W("اسم الصنف", "Item name"))}</div>`;
  const wd = (d) => (m === "en" ? DAYS[d.getDay()][2] : DAYS[d.getDay()][0]);
  if (at) h += `<p><b>${c("حُضّر", "Prepared")}:</b> <bdi dir="ltr">${esc(dtShort(at))}</bdi> ${esc(wd(at))}</p>`;
  h += `<p class="pl-ub">${c("يُستخدم قبل", "Use by")}: ${ub ? `<bdi dir="ltr">${esc(dtShort(ub))}</bdi> ${esc(wd(ub))}` : "—"}</p>`;
  const st = STO.find((x) => x[0] === p.sto);
  h += `<p>${p.by.trim() ? `<b>${c("بواسطة", "By")}:</b> ${esc(p.by.trim())} · ` : ""}${st ? esc(c(st[1], st[2])) : ""}</p>`;
  const al = ALG10.filter((a) => p.alg.includes(a[0])).map((a) => (m === "bi" ? `${a[1]}/${a[2]}` : m === "ar" ? a[1] : a[2])).concat(p.other.trim() ? [p.other.trim()] : []);
  if (al.length) h += `<p><b>${c("مسببات الحساسية", "Allergens")}:</b> <b class="pl-al">${esc(al.join(m === "en" ? ", " : "، "))}</b></p>`;
  return `<div class="pl-lab" dir="${m === "en" ? "ltr" : "rtl"}" lang="${m === "en" ? "en" : "ar"}" style="padding:${pad}mm;--pad:${pad}mm">${band}<div class="pl-tx">${h}</div></div>`;
}
function preplabelPage() {
  const DK = "tool:preplabel:draft", RK = "tool:preplabel", CK = "tool:preplabel:colors";
  let p = Object.assign(PREP_DEF(), store.get(DK, {}) || {}); p.at = nowL(); if (!Array.isArray(p.alg)) p.alg = [];
  let colors = (store.get(CK, null) || DAY_COL).slice(0, 7), timer = 0, fitPt = 6;
  const items = () => store.get(RK, []) || [];
  const html = `${head("preplabel")}
    <div class="pt-split">
      <form class="card" id="ppForm" novalidate><div class="form">
        ${fld("pp-item", W("الصنف", "Item"), `<input type="text" id="pp-item" data-k="item" list="ppItems" autocomplete="off" value="${esc(p.item)}">`, { req: true })}
        ${fld("pp-at", W("وقت التحضير", "Prepared at"), `<input type="datetime-local" id="pp-at" data-k="at" value="${esc(p.at)}">`, { req: true })}
        ${fld("pp-amt", W("مدة الاستخدام", "Use within"), `<input type="number" id="pp-amt" data-k="amt" min="0" step="1" inputmode="numeric" value="${esc(p.amt)}">`, { req: true, hint: W("من إجراءات منشأتك أو دراسة الصلاحية؛ لا توجد قيم افتراضية.", "From your site's procedure or shelf-life study; there are no defaults.") })}
        ${fld("pp-unit", W("الوحدة", "Unit"), `<select id="pp-unit" data-k="unit">${selOpts([["h", W("ساعات", "Hours")], ["d", W("أيام", "Days")]], p.unit)}</select>`)}
        <div class="field full"><span class="lbl">${esc(W("يُستخدم قبل", "Use by"))}</span><div id="ppUse" class="pt-mono" style="font-size:18px;font-weight:700;color:var(--gold)" aria-live="polite"></div></div>
        ${fld("pp-by", W("حضّره", "Prepared by"), `<input type="text" id="pp-by" data-k="by" value="${esc(p.by)}">`, { req: true })}
        <div class="field"><span class="lbl">${esc(W("التخزين", "Storage"))}</span><div class="seg pt-seg" role="group" aria-label="${esc(W("التخزين", "Storage"))}">${STO.map(([v, a, e]) => `<button type="button" data-sto="${v}" aria-pressed="${p.sto === v}">${esc(W(a, e))}</button>`).join("")}</div></div>
        <div class="field full"><span class="lbl">${esc(W("مسببات الحساسية", "Allergens"))}</span><div class="row" style="gap:6px" role="group" aria-label="${esc(W("مسببات الحساسية", "Allergens"))}">${ALG10.map(([v, a, e]) => `<button type="button" class="chip pt-tg" data-alg="${v}" aria-pressed="${p.alg.includes(v)}">${esc(W(a, e))}</button>`).join("")}</div></div>
        ${fld("pp-other", W("مسببات حساسية أخرى", "Other allergens"), `<input type="text" id="pp-other" data-k="other" value="${esc(p.other)}">`, { full: true })}
        <h3 class="pt-h">${esc(W("الملصق", "Label"))}</h3>
        ${fld("pp-size", W("المقاس", "Size"), `<select id="pp-size" data-k="size">${selOpts(PREP_SIZES.map((s) => [s.id, `${s.w} × ${s.h} mm`]), p.size)}</select>`)}
        ${fld("pp-copies", W("عدد النسخ", "Copies"), `<input type="number" id="pp-copies" data-k="copies" min="1" max="200" step="1" inputmode="numeric" value="${esc(p.copies)}">`, { req: true })}
        <div class="field"><span class="lbl">${esc(W("لغة الملصق", "Label language"))}</span>${modeSeg("pp-mode", p.mode)}</div>
        <div class="field"><label for="pp-bandDay">${esc(W("شريط لون اليوم", "Day colour band"))}</label><select id="pp-bandDay" data-k="bandDay">${selOpts([["use", W("يوم انتهاء الاستخدام", "Use-by day")], ["prep", W("يوم التحضير", "Prepared day")], ["off", W("بدون شريط", "No band")]], p.band ? p.bandDay : "off")}</select></div>
        <details class="faq full"><summary>${esc(W("ألوان الأيام", "Day colours"))}</summary><p class="note" style="margin-top:0">${esc(W("الافتراضي هو النظام الشائع (الاثنين أزرق، الثلاثاء أصفر، الأربعاء أحمر، الخميس أخضر، الجمعة بني، السبت برتقالي، الأحد أسود). استخدم النظام الذي درّبت عليه فريقك.", "The default is the common scheme (Monday blue, Tuesday yellow, Wednesday red, Thursday green, Friday brown, Saturday orange, Sunday black). Use the scheme your team is trained on."))}</p>
          <div class="pt-days">${[1, 2, 3, 4, 5, 6, 0].map((i) => `<div class="field"><label for="pp-col${i}">${esc(W(DAYS[i][0], DAYS[i][1]))}</label><input type="color" id="pp-col${i}" data-col="${i}" value="${esc(colors[i])}"></div>`).join("")}</div>
          <button type="button" class="btn btn-ghost btn-sm" id="ppColReset" style="margin:12px 0">${esc(W("استعادة النظام الشائع", "Restore the common scheme"))}</button></details>
      </div><datalist id="ppItems"></datalist></form>
      <div class="pt-side"><div class="card"><h2 style="font-size:19px;margin-bottom:10px">${esc(W("معاينة", "Preview"))}</h2>
        <div class="pt-stagehost" id="ppStage" role="img" aria-label="${esc(W("معاينة الملصق", "Label preview"))}"></div>
        <div class="row" id="ppInfo" style="margin-top:10px;gap:6px"></div>
        <div class="row" style="margin-top:14px"><button type="button" class="btn btn-gold" id="ppPrint">${I.printer}<span>${esc(t("print"))}</span></button><button type="button" class="btn btn-ghost" id="ppSave">${I.plus}<span>${esc(W("حفظ في أصنافي", "Save to my items"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="ppNow">${I.clock}<span>${esc(W("الآن", "Now"))}</span></button></div>
        <span class="err" id="ppErr" role="alert"></span></div></div>
    </div>
    <h2 style="font-size:22px;margin:30px 0 12px">${esc(W("أصنافي المحفوظة — طباعة بلمسة", "My saved items — one-tap printing"))}</h2>
    <p class="note" style="margin-top:0">${esc(W("الطباعة السريعة تستخدم وقت الآن واسم المحضّر وعدد النسخ والمقاس من النموذج.", "Quick print uses the current time and the preparer, copies and size from the form."))}</p>
    <div id="ppList"></div>
  </div></section>`;

  function after() {
    const form = $("#ppForm");
    const sizeOf = () => PREP_SIZES.find((s) => s.id === p.size) || PREP_SIZES[0];
    const validate = () => {
      let ok = setErr("pp-item", p.item.trim() ? "" : t("required"));
      ok = setErr("pp-at", parseLocal(p.at) ? "" : t("required")) && ok;
      ok = setErr("pp-amt", String(p.amt).trim() === "" ? t("required") : p.unit === "d" ? (isInt(p.amt, 1, 3650) ? "" : W("عدد صحيح من الأيام (1–3650).", "Whole days (1–3650).")) : Number(p.amt) > 0 && Number(p.amt) <= 87600 ? "" : W("أدخل عدد ساعات أكبر من صفر.", "Enter hours above zero.")) && ok;
      ok = setErr("pp-by", p.by.trim() ? "" : t("required")) && ok;
      ok = setErr("pp-copies", isInt(p.copies, 1, 200) ? "" : W("عدد صحيح من 1 إلى 200.", "A whole number from 1 to 200.")) && ok;
      return ok;
    };
    const render = () => {
      const sz = sizeOf(), ub = useBy(p.at, p.amt, p.unit);
      $("#ppUse").innerHTML = ub ? `${esc(dtShort(ub))} <span style="font-family:var(--font-ar);font-size:14px;color:var(--muted)">${esc(W(DAYS[ub.getDay()][0], DAYS[ub.getDay()][1]))}</span>` : `<span class="note" style="font-family:var(--font-ar)">${esc(W("أدخل مدة الاستخدام.", "Enter the use-within time."))}</span>`;
      const lab = stage($("#ppStage"), sz.w, sz.h, prepHtml(p, colors, labPad(sz.w, sz.h)));
      const f = fit(lab, maxPtFor(sz.h)); fitPt = f.pt;
      $("#ppInfo").innerHTML = `<span class="chip">${sz.w} × ${sz.h} mm</span><span class="chip ${f.ok ? "" : "bad"}">${esc(W("حجم الخط", "Text size"))}: <b dir="ltr">${f.pt} pt</b></span>${f.ok ? "" : `<span class="chip bad">${esc(W("النص لا يتسع — اختر مقاسًا أكبر أو اختصر.", "Text doesn't fit — choose a bigger size or shorten it."))}</span>`}`;
    };
    const schedule = () => { clearTimeout(timer); timer = setTimeout(render, 60); };
    const persist = () => store.set(DK, p);
    const syncForm = () => {
      ["item", "at", "amt", "unit", "by", "other", "size", "copies"].forEach((k) => { const el = $("#pp-" + k); if (el) el.value = p[k]; });
      $("#pp-bandDay").value = p.band ? p.bandDay : "off";
      $$("[data-sto]", form).forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.sto === p.sto)));
      $$("[data-alg]", form).forEach((b) => b.setAttribute("aria-pressed", String(p.alg.includes(b.dataset.alg))));
      $$("[data-mode]", form).forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.mode === p.mode)));
      $$("[aria-invalid]", form).forEach((el) => el.setAttribute("aria-invalid", "false")); $$(".err", form).forEach((e) => (e.textContent = ""));
    };
    form.addEventListener("input", (e) => {
      const el = e.target;
      if (el.dataset.col) { colors[+el.dataset.col] = el.value; store.set(CK, colors); schedule(); return; }
      const k = el.dataset.k; if (!k) return;
      if (k === "bandDay") { p.band = el.value !== "off"; if (p.band) p.bandDay = el.value; } else p[k] = el.value;
      if (k === "item") { const it = items().find((x) => x.name === el.value); if (it) { Object.assign(p, { amt: it.amt, unit: it.unit, sto: it.sto, alg: it.alg.slice(), other: it.other || "" }); const keep = p.item; syncForm(); p.item = keep; } }
      persist(); schedule();
    });
    form.addEventListener("click", (e) => {
      const s = e.target.closest("[data-sto]"), a = e.target.closest("[data-alg]"), m = e.target.closest("[data-mode]");
      if (s) { p.sto = s.dataset.sto; }
      if (a) { const v = a.dataset.alg; p.alg = p.alg.includes(v) ? p.alg.filter((x) => x !== v) : p.alg.concat(v); }
      if (m) { p.mode = m.dataset.mode; }
      if (e.target.closest("#ppColReset")) { colors = DAY_COL.slice(); store.del(CK); $$("[data-col]", form).forEach((el) => (el.value = colors[+el.dataset.col])); }
      if (s || a || m) { syncForm(); persist(); }
      schedule();
    });
    form.addEventListener("submit", (e) => e.preventDefault());
    const doPrint = () => {
      if (!validate()) { $("#ppErr").textContent = t("fixErrors"); focusBad(form); return false; }
      $("#ppErr").textContent = ""; render();
      const sz = sizeOf(), lab = prepHtml(p, colors, labPad(sz.w, sz.h)).replace('--pad:', `font-size:${Math.floor(fitPt * 0.97 * 10) / 10}pt;--pad:`);
      printLabels({ w: sz.w, h: sz.h, kind: "roll" }, lab, +p.copies, 0, p.item);
      return true;
    };
    $("#ppPrint").addEventListener("click", doPrint);
    $("#ppNow").addEventListener("click", () => { p.at = nowL(); $("#pp-at").value = p.at; persist(); render(); });
    const drawList = () => {
      const all = items();
      $("#ppItems").innerHTML = all.map((x) => `<option value="${esc(x.name)}">`).join("");
      $("#ppList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("الصنف", "Item"))}</th><th>${esc(W("مدة الاستخدام", "Use within"))}</th><th>${esc(W("التخزين", "Storage"))}</th><th>${esc(W("مسببات الحساسية", "Allergens"))}</th><th></th></tr></thead><tbody>${all.map((x) => { const st = STO.find((s) => s[0] === x.sto); return `<tr><td><b>${esc(x.name)}</b></td><td>${esc(x.amt)} ${esc(x.unit === "d" ? W("يوم", "d") : W("ساعة", "h"))}</td><td>${st ? esc(W(st[1], st[2])) : ""}</td><td>${esc(ALG10.filter((a) => x.alg.includes(a[0])).map((a) => W(a[1], a[2])).concat(x.other ? [x.other] : []).join(W("، ", ", ")) || "—")}</td><td style="white-space:nowrap"><button type="button" class="btn btn-gold btn-sm" data-qp="${esc(x.id)}">${I.printer}<span>${esc(t("print"))}</span></button> ${iconBtn("use", x.id, I.note, W("تحميل في النموذج", "Load into the form"))} ${iconBtn("del", x.id, I.trash, t("del"))}</td></tr>`; }).join("")}</tbody></table></div>` : `<div class="empty">${esc(W("لا توجد أصناف محفوظة بعد. املأ النموذج واضغط «حفظ في أصنافي».", "No saved items yet. Fill the form and press \"Save to my items\"."))}</div>`;
    };
    $("#ppSave").addEventListener("click", () => {
      let ok = setErr("pp-item", p.item.trim() ? "" : t("required"));
      ok = setErr("pp-amt", p.unit === "d" ? (isInt(p.amt, 1, 3650) ? "" : W("عدد صحيح من الأيام (1–3650).", "Whole days (1–3650).")) : Number(p.amt) > 0 ? "" : W("أدخل عدد ساعات أكبر من صفر.", "Enter hours above zero.")) && ok;
      if (!ok) { focusBad(form); return; }
      const all = items(), i = all.findIndex((x) => x.name === p.item.trim()), rec = { id: i >= 0 ? all[i].id : uid(), name: p.item.trim(), amt: p.amt, unit: p.unit, sto: p.sto, alg: p.alg.slice(), other: p.other.trim() };
      if (i >= 0) all[i] = rec; else all.push(rec);
      if (store.set(RK, all)) { toast(t("saved")); drawList(); }
    });
    const load = (x) => { Object.assign(p, { item: x.name, amt: x.amt, unit: x.unit, sto: x.sto, alg: x.alg.slice(), other: x.other || "", at: nowL() }); syncForm(); persist(); render(); };
    $("#ppList").addEventListener("click", (e) => {
      const all = items(), qp = e.target.closest("[data-qp]"), us = e.target.closest("[data-use]"), dl = e.target.closest("[data-del]");
      if (qp) { load(all.find((x) => x.id === qp.dataset.qp)); if (!doPrint()) A.scrollTo(form, true); }
      if (us) { load(all.find((x) => x.id === us.dataset.use)); A.scrollTo(form, true); }
      if (dl && confirm(t("confirmDel"))) { store.set(RK, all.filter((x) => x.id !== dl.dataset.del)); drawList(); toast(t("deleted")); }
    });
    window.addEventListener("resize", schedule, { passive: true });
    drawList(); render();
  }
  return { title: L(toolOf("preplabel").t), html, after };
}

/* =====================================================================
   4) EAN-13 / UPC-A generator & validator
   ===================================================================== */
function eanCheck(mode, raw) {
  const v = String(raw || "").replace(/[\s-]/g, ""), n = mode === "upc" ? 12 : 13;
  if (!v) return { err: t("required") };
  if (!/^\d+$/.test(v)) return { err: W("أرقام فقط.", "Digits only.") };
  if (v.length !== n - 1 && v.length !== n) return { err: mode === "upc" ? W("أدخل 11 رقمًا (لحساب رقم التحقق) أو 12 رقمًا (للتحقق).", "Enter 11 digits (to compute the check digit) or 12 digits (to verify).") : W("أدخل 12 رقمًا (لحساب رقم التحقق) أو 13 رقمًا (للتحقق).", "Enter 12 digits (to compute the check digit) or 13 digits (to verify).") };
  const body = v.slice(0, n - 1), c = gtinCheck(body), given = v.length === n ? +v[n - 1] : null;
  return { body, c, given, code: body + c, valid: given == null || given === c };
}
function eanCalc(body) {
  const rows = [...body].map((dg, i) => { const w = (body.length - 1 - i) % 2 === 0 ? 3 : 1; return { i: i + 1, dg: +dg, w, p: +dg * w }; });
  const sum = rows.reduce((s, r) => s + r.p, 0);
  return { rows, sum, c: (10 - (sum % 10)) % 10 };
}
function ean13Page() {
  const DK = "tool:ean13:draft";
  let s = Object.assign({ mode: "ean", code: "", mag: 100 }, store.get(DK, {}) || {});
  const html = `${head("ean13")}
    <div class="pt-split">
      <form class="card" id="enForm" novalidate><div class="form">
        <div class="field full"><span class="lbl">${esc(W("الرمز", "Symbology"))}</span><div class="seg pt-seg" role="group" aria-label="${esc(W("الرمز", "Symbology"))}"><button type="button" data-em="ean" aria-pressed="${s.mode === "ean"}">EAN-13</button><button type="button" data-em="upc" aria-pressed="${s.mode === "upc"}">UPC-A</button></div></div>
        ${fld("en-code", W("الأرقام", "Digits"), `<input type="text" id="en-code" dir="ltr" inputmode="numeric" autocomplete="off" maxlength="17" value="${esc(s.code)}" class="pt-mono" style="font-size:18px;letter-spacing:.06em">`, { full: true, req: true, hint: W("أدخل الرقم دون رقم التحقق لحسابه، أو الرقم كاملًا للتحقق منه.", "Enter the number without its check digit to compute it, or the full number to verify it.") })}
        ${fld("en-mag", W("التكبير % (80–200)", "Magnification % (80–200)"), `<input type="number" id="en-mag" min="80" max="200" step="1" inputmode="numeric" value="${esc(s.mag)}">`, { hint: W("100% = ‏37.29 × 25.93 مم (X = 0.33 مم).", "100 % = 37.29 × 25.93 mm (X = 0.33 mm).") })}
        <div class="field"><span class="lbl">${esc(W("المقاس الفعلي", "Actual size"))}</span><div id="enSize" class="pt-mono" style="padding-top:8px"></div></div>
      </div>
      <div id="enStatus" aria-live="polite" style="margin-top:16px"></div>
      <div id="enCalc" style="margin-top:12px"></div></form>
      <div class="pt-side"><div class="card"><h2 style="font-size:19px;margin-bottom:10px">${esc(W("الباركود", "Barcode"))}</h2>
        <div id="enSvg" class="pt-bc" style="min-height:120px;justify-content:center"></div>
        <div class="row" style="margin-top:14px"><button type="button" class="btn btn-ghost btn-sm" id="enDlSvg">${I.download}<span>SVG</span></button><button type="button" class="btn btn-ghost btn-sm" id="enDlPng">${I.download}<span>PNG</span></button><button type="button" class="btn btn-gold btn-sm" id="enPrint">${I.printer}<span>${esc(W("طباعة بالمقاس الفعلي", "Print at actual size"))}</span></button></div>
        <span class="err" id="enErr" role="alert"></span>
        <div class="disclaimer" style="margin-top:16px">${I.warn}<div>${esc(W("أرقام GTIN الحقيقية للمنتجات المطروحة في السوق يجب ترخيصها من GS1 (مثل GS1 السعودية). لا تخترع أرقامًا لمنتج سيُباع. افحص الباركود المطبوع بماسح قبل الإنتاج.", "Real GTINs for products on the market must be licensed from GS1 (e.g. GS1 Saudi Arabia). Don't invent numbers for a product that will be sold. Test the printed barcode with a scanner before production."))}</div></div></div></div>
    </div>
  </div></section>`;
  function after() {
    let cur = null;
    const magOk = () => isInt(s.mag, 80, 200);
    const draw = () => {
      store.set(DK, s);
      $$("[data-em]").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.em === s.mode)));
      const r = eanCheck(s.mode, s.code);
      setErr("en-code", s.code.trim() ? r.err || "" : ""); setErr("en-mag", magOk() ? "" : W("عدد صحيح من 80 إلى 200.", "A whole number from 80 to 200."));
      const k = magOk() ? s.mag / 100 : 1;
      $("#enSize").textContent = `${(37.29 * k).toFixed(2)} × ${(25.93 * k).toFixed(2)} mm · X = ${(0.33 * k).toFixed(3)} mm`;
      if (r.err) { cur = null; $("#enStatus").innerHTML = ""; $("#enCalc").innerHTML = ""; $("#enSvg").innerHTML = `<p class="note" style="color:#555;margin:0">${esc(W("أدخل الأرقام لعرض الباركود.", "Enter the digits to show the barcode."))}</p>`; return; }
      const c = eanCalc(r.body);
      $("#enStatus").innerHTML = r.given == null ? `<span class="chip ok">${esc(W("رقم التحقق المحسوب", "Computed check digit"))}: <b dir="ltr" id="enCheck">${r.c}</b></span> <span class="chip"><span dir="ltr" class="pt-mono" id="enFull">${esc(r.code)}</span></span>` : r.valid ? `<span class="chip ok" id="enValid">${esc(W("رقم صحيح — رقم التحقق مطابق", "Valid — check digit matches"))} (<b dir="ltr" id="enCheck">${r.c}</b>)</span>` : `<span class="chip bad" id="enInvalid">${esc(W(`غير صحيح — رقم التحقق يجب أن يكون ${r.c} وليس ${r.given}`, `Invalid — the check digit should be ${r.c}, not ${r.given}`))}</span> <span class="chip">${esc(W("الصحيح", "Correct"))}: <span dir="ltr" class="pt-mono">${esc(r.code)}</span></span>`;
      $("#enCalc").innerHTML = `<span class="lbl">${esc(W("طريقة الحساب", "Calculation"))}</span><div class="table-wrap" style="margin-top:6px"><table class="t" style="min-width:0" dir="ltr"><thead><tr><th>${esc(W("الموضع", "Position"))}</th>${c.rows.map((x) => `<th>${x.i}</th>`).join("")}</tr></thead><tbody><tr><th>${esc(W("الرقم", "Digit"))}</th>${c.rows.map((x) => `<td>${x.dg}</td>`).join("")}</tr><tr><th>${esc(W("الوزن", "Weight"))}</th>${c.rows.map((x) => `<td>×${x.w}</td>`).join("")}</tr><tr><th>${esc(W("الناتج", "Product"))}</th>${c.rows.map((x) => `<td>${x.p}</td>`).join("")}</tr></tbody></table></div>
        <p class="note pt-mono" style="font-size:14px;color:var(--text)">Σ = ${c.sum} → check = (10 − (${c.sum} mod 10)) mod 10 = (10 − ${c.sum % 10}) mod 10 = <b>${c.c}</b></p>
        <p class="note" style="margin:0">${esc(W("الأوزان 3 و1 بالتناوب بدءًا بالوزن 3 من الرقم الأقرب إلى رقم التحقق (يمينًا).", "Weights alternate 3 and 1, starting with 3 at the digit next to the check digit (rightmost)."))}</p>`;
      if (!r.valid) { cur = null; $("#enSvg").innerHTML = `<p class="note" style="color:#a33;margin:0">${esc(W("صحّح رقم التحقق لعرض الباركود.", "Fix the check digit to show the barcode."))}</p>`; return; }
      cur = r.code;
      $("#enSvg").innerHTML = eanSvg(cur, { style: "width:100%;max-width:340px;height:auto" });
    };
    $("#enForm").addEventListener("input", (e) => { if (e.target.id === "en-code") s.code = e.target.value; if (e.target.id === "en-mag") s.mag = e.target.value; draw(); });
    $("#enForm").addEventListener("click", (e) => { const b = e.target.closest("[data-em]"); if (b) { s.mode = b.dataset.em; draw(); } });
    $("#enForm").addEventListener("submit", (e) => e.preventDefault());
    const need = () => { if (!cur) { $("#enErr").textContent = W("أدخل رقمًا صحيحًا أولًا.", "Enter a valid number first."); $("#en-code").focus(); return false; } if (!magOk()) { $("#enErr").textContent = t("fixErrors"); $("#en-mag").focus(); return false; } $("#enErr").textContent = ""; return true; };
    const k = () => s.mag / 100;
    $("#enDlSvg").addEventListener("click", () => { if (need()) download(`${s.mode === "upc" ? "upca" : "ean13"}-${cur}.svg`, `<?xml version="1.0" encoding="UTF-8"?>\n` + eanSvg(cur, { mag: k() }), "image/svg+xml"); });
    $("#enDlPng").addEventListener("click", () => {
      if (!need()) return;
      const pxmm = 600 / 25.4, wpx = Math.round(37.29 * k() * pxmm), hpx = Math.round(25.93 * k() * pxmm), url = URL.createObjectURL(new Blob([eanSvg(cur, { px: [wpx, hpx] })], { type: "image/svg+xml" })), img = new Image();
      img.onload = () => { const c = document.createElement("canvas"); c.width = wpx; c.height = hpx; const g = c.getContext("2d"); g.fillStyle = "#fff"; g.fillRect(0, 0, wpx, hpx); g.drawImage(img, 0, 0, wpx, hpx); URL.revokeObjectURL(url); c.toBlob((b) => (b ? downloadBlob(`${s.mode === "upc" ? "upca" : "ean13"}-${cur}-600dpi.png`, b) : toast(W("تعذّر إنشاء الصورة.", "Couldn't create the image."), "bad")), "image/png"); };
      img.onerror = () => { URL.revokeObjectURL(url); toast(W("تعذّر إنشاء الصورة.", "Couldn't create the image."), "bad"); };
      img.src = url;
    });
    $("#enPrint").addEventListener("click", () => {
      if (!need()) return;
      printDoc(`<div class="wrap"><p>${esc(s.mode === "upc" ? "UPC-A" : "EAN-13")} · <bdi dir="ltr">${esc(cur)}</bdi> · ${s.mag}% · <bdi dir="ltr">${(37.29 * k()).toFixed(2)} × ${(25.93 * k()).toFixed(2)} mm</bdi></p>${eanSvg(cur, { mag: k() })}<p class="sm">${esc(W("اطبع بمقياس 100% (الحجم الفعلي) وتحقق بالمسطرة.", "Print at 100 % scale (actual size) and check with a ruler."))}</p></div>`, `@page{size:A4;margin:15mm}body{font-family:"IBM Plex Sans Arabic","Inter",Arial,sans-serif;font-size:11pt}svg{display:block;margin:6mm 0}.sm{font-size:9pt;color:#555}`, `${s.mode === "upc" ? "UPC-A" : "EAN-13"} ${cur}`);
    });
    draw();
  }
  return { title: L(toolOf("ean13").t), html, after };
}

/* ---------- register ---------- */
T.register({ id: "prodlabel", icon: "tag", cat: "practical", t: { ar: "مولّد بطاقة المنتج", en: "Product label generator" }, d: { ar: "بطاقة منتج ثنائية اللغة بمقاسات لفات حرارية وأوراق A4، مع إبراز مسببات الحساسية وباركود وQR وجدول غذائي، وطباعة بالمقاس الفعلي وقوالب محفوظة.", en: "Bilingual product labels for thermal rolls and A4 sheets, with allergens in bold, barcode, QR and nutrition table, printed at exact size, with saved templates." } }, prodlabelPage);
T.register({ id: "batchcode", icon: "hash", cat: "practical", t: { ar: "مولّد رمز التشغيلة والتاريخ", en: "Batch / date code generator" }, d: { ar: "ابنِ نمط رمز التشغيلة (مصنع، خط، تاريخ يولياني، وردية، تسلسل)، واحسب الانتهاء من مدة صلاحيتك، وأنشئ GS1-128، وفك الرموز، واحتفظ بسجل للاسترجاع الوهمي.", en: "Build a batch code pattern (plant, line, Julian date, shift, sequence), compute expiry from your shelf life, create GS1-128, decode codes and keep a log for mock recalls." } }, batchcodePage);
T.register({ id: "preplabel", icon: "clock", cat: "practical", t: { ar: "ملصقات التحضير للمطبخ والمقهى", en: "Kitchen & café prep labels" }, d: { ar: "ملصقات صغيرة بنظام ألوان الأيام: الصنف ووقت التحضير و«يُستخدم قبل» من المدة التي تحددها، ومن حضّره، ومسببات الحساسية، وطباعة سريعة لأصنافك المحفوظة.", en: "Small day-dot style labels: item, prepared time, use-by from the time you set, who prepared it and allergens, with one-tap printing of your saved items." } }, preplabelPage);
T.register({ id: "ean13", icon: "barcode", cat: "practical", t: { ar: "مولّد ومدقّق باركود EAN-13", en: "EAN-13 barcode generator & validator" }, d: { ar: "احسب رقم التحقق لـ EAN-13 / UPC-A أو تحقق منه مع خطوات الحساب، واعرض الباركود ونزّله SVG/PNG، واطبعه بتكبير 80–200%.", en: "Compute or verify the EAN-13 / UPC-A check digit with the working shown, render the barcode, download SVG/PNG and print it at 80–200 % magnification." } }, ean13Page);

export { gtinCheck, doy, addDays, fromDoy, isoWeek, gs1, eanBits, algRegex };
