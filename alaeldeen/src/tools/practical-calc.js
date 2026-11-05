/* Practical tools: activity equivalent, shelf life after opening, net content check, recipe
   scaling & costing, customer product card (QR) and hold/thaw/cooling timers.
   They plug into js/tools.js through TOOLS.register and reuse its helpers (TOOLS.h).
   Every shelf life, tolerance and price is entered by the user; nothing here is proposed as a
   legal or medical value. Data stays in localStorage; the product card lives in its own link. */
import QRCode from "qrcode";
import "../../css/tools-practical-calc.css";

const T = window.TOOLS, A = window.APP, I = window.ICONS;
const { printHtml, disclaimer, crumbsFor, kvTable, store, esc, L, t, $, $$, toast, download, csv, uid, fmtDate, pageHead } = T.h;
const W = (a, e) => (A.lang === "ar" ? a : e);
const LOC = () => (A.lang === "ar" ? "ar-SA-u-ca-gregory-nu-latn" : "en-GB");
const isNum = (v) => v !== "" && v != null && isFinite(v);
const num = (n, d) => (n == null || n === "" || !isFinite(n) ? "—" : Number(n).toLocaleString(LOC(), { maximumFractionDigits: d == null ? 1 : d }));
const fix = (n, d) => (isFinite(n) ? Number(n).toFixed(d) : "—"); // fixed decimals, Latin digits (formulas, labels)
const p2 = (n) => String(n).padStart(2, "0");
const tool = (id) => T.list.find((x) => x.id === id);
const head = (id) => `${pageHead(L(tool(id).t), L(tool(id).d), crumbsFor(tool(id)))}<section class="sec"><div class="wrap tc-page pc-page">${disclaimer()}`;
const NUT_KEYS = ["kcal", "protein", "fat", "sat", "carb", "sugars", "fibre", "sodium"];
const NUT_LAB = { kcal: ["الطاقة", "Energy", "kcal", 0], protein: ["البروتين", "Protein", "g", 1], fat: ["الدهون الكلية", "Total fat", "g", 1], sat: ["الدهون المشبعة", "Saturated fat", "g", 1], carb: ["الكربوهيدرات", "Carbohydrate", "g", 1], sugars: ["السكريات", "Sugars", "g", 1], fibre: ["الألياف الغذائية", "Dietary fibre", "g", 1], sodium: ["الصوديوم", "Sodium", "mg", 0] };
const recipes = () => store.get("tool:nutrition", []).filter((r) => r && typeof r === "object" && Array.isArray(r.ing));

/* ---------- icons (added to the shared set if missing) ---------- */
const svg = (p) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${p}</svg>`;
const ICO = {
  flame: '<path d="M12 3c1 3.5 5 5.5 5 10a5 5 0 0 1-10 0c0-2.2 1.2-3.6 2.4-4.6.2 1.6 1 2.6 2.1 3.1C11 9 11 6 12 3Z"/>',
  clock: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  scale: '<path d="M12 4v16M7 20h10M5 8h14"/><path d="m5 8-3 6a3 3 0 0 0 6 0L5 8ZM19 8l-3 6a3 3 0 0 0 6 0l-3-6Z"/>',
  coins: '<ellipse cx="9" cy="7" rx="6" ry="2.5"/><path d="M3 7v4c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5V7"/><path d="M9 13.5V17c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5v-4c0-1.4-2.7-2.5-6-2.5"/>',
  qr: '<rect x="4" y="4" width="6" height="6" rx="1"/><rect x="14" y="4" width="6" height="6" rx="1"/><rect x="4" y="14" width="6" height="6" rx="1"/><path d="M14 14h2v2h-2zM18 14h2M14 18h2M18 18h2v2"/>',
  timer: '<circle cx="12" cy="13" r="7.5"/><path d="M12 9.5V13l2.5 1.5M9.5 2.5h5M19 6l-1.5 1.5"/>',
  walk: '<circle cx="13" cy="4.5" r="1.8"/><path d="M10 21l2.2-6.5L10 12l1-4.5-3 2-1 3.5M11 7.5l3 3.5 3 1M12.2 14.5l2.8 6.5"/>',
  brisk: '<circle cx="14" cy="4.5" r="1.8"/><path d="M8 21l3-6.5-1.5-3 1.5-4-3.5 2-1.5 3.5M11 7.5l3 3.5 3.5 1M11 14.5l4 6.5M2.5 10h3M2 14h3"/>',
  run: '<circle cx="15.5" cy="4.5" r="1.8"/><path d="M5 20.5l4.5-1 2-4M13.5 8 9 9l-2 3.5M13.5 8l-2.2 6.5 4.2 2-1 4.5M13.5 8l2.2 3.5H20"/>',
  bike: '<circle cx="6" cy="16" r="3.5"/><circle cx="18" cy="16" r="3.5"/><path d="M6 16l4-7h5.5L18 16M10 9l3 7H6M13.5 6H16"/>',
  swim: '<circle cx="17" cy="6.5" r="1.8"/><path d="M2.5 17.5c1.6 1 3.2 1 4.8 0s3.2-1 4.8 0 3.2 1 4.8 0 3.2-1 4.6 0M5.5 13.5 10 9.5l3 3 3-1.5"/>',
  stairs: '<path d="M3 20h5v-4h4v-4h4V8h5"/><path d="M14 4l3 0"/>',
};
Object.keys(ICO).forEach((k) => { if (!I[k]) I[k] = svg(ICO[k]); });

/* ---------- shared UI helpers ---------- */
const fld = (id, label, input, o) => { o = o || {}; return `<div class="field ${o.full ? "full" : ""}"><label for="${id}" class="${o.req ? "req" : ""}">${esc(label)}</label>${input}${o.hint ? `<span class="hint">${esc(o.hint)}</span>` : ""}<span class="err" id="${id}-e"></span></div>`; };
const inp = (id, type, v, extra) => `<input id="${id}" type="${type}" value="${esc(v == null ? "" : v)}" ${type === "number" ? 'inputmode="decimal" step="any"' : ""} ${extra || ""}>`;
const sel = (id, opts, cur) => `<select id="${id}">${opts.map(([v, l]) => `<option value="${esc(v)}" ${String(cur) === String(v) ? "selected" : ""}>${esc(l)}</option>`).join("")}</select>`;
const val = (id) => { const el = $("#" + id); return el ? el.value.trim() : ""; };
const nval = (id) => { const v = val(id).replace(",", "."); return v === "" ? "" : Number(v); };
const setErr = (id, msg) => { const el = $("#" + id), e = $("#" + id + "-e"); if (el) el.setAttribute("aria-invalid", msg ? "true" : "false"); if (e) e.textContent = msg || ""; return !msg; };
const clearErrs = (root) => { $$("[aria-invalid]", root).forEach((el) => el.setAttribute("aria-invalid", "false")); $$(".err", root).forEach((e) => (e.textContent = "")); };
const focusBad = (root) => { const b = $("[aria-invalid=true]", root); if (b) b.focus(); };
const iconBtn = (data, id, icon, label) => `<button type="button" class="icon-btn" data-${data}="${esc(id)}" aria-label="${esc(label)}" style="width:34px;height:34px">${icon}</button>`;
const btn = (id, icon, label, cls, type) => `<button type="${type || "button"}" class="btn ${cls || "btn-ghost"}" id="${id}">${icon}<span>${esc(label)}</span></button>`;
const MSG = {
  pos: () => W("أدخل رقمًا أكبر من صفر.", "Enter a number above zero."),
  nonneg: () => W("أدخل رقمًا لا يقل عن صفر.", "Enter a number of zero or more."),
  int: () => W("أدخل عددًا صحيحًا لا يقل عن صفر.", "Enter a whole number of zero or more."),
};
function dlBlob(name, blob) {
  const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = name; document.body.appendChild(a); a.click();
  setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 500);
}
const safeName = (s) => String(s || "item").replace(/[^\p{L}\p{N}]+/gu, "-").replace(/^-|-$/g, "").slice(0, 40) || "item";

/* print a small label / strip: page size set with @page, nothing else on the sheet */
function printLabel(inner, size) {
  const pa = $("#printArea");
  pa.innerHTML = `<style>@page{size:${size};margin:0}body.print-rec #printArea{padding:0!important}</style>${inner}`;
  document.body.classList.add("print-rec");
  const done = () => { document.body.classList.remove("print-rec"); window.removeEventListener("afterprint", done); };
  window.addEventListener("afterprint", done);
  setTimeout(() => { window.print(); setTimeout(done, 1000); }, 60);
}

/* editable rows */
function grid(host, arr, cols, o) {
  const cell = (c, r, i) => {
    const id = `${o.id}-${i}-${c.k}`, lab = `${c.l} ${i + 1}`, v = r[c.k] == null ? "" : r[c.k];
    if (c.type === "select") return `<select id="${id}" data-c="${i}:${c.k}" aria-label="${esc(lab)}">${c.opts().map(([ov, ol]) => `<option value="${esc(ov)}" ${String(v) === String(ov) ? "selected" : ""}>${esc(ol)}</option>`).join("")}</select>`;
    return `<input id="${id}" data-c="${i}:${c.k}" aria-label="${esc(lab)}" type="${c.type || "text"}" value="${esc(v)}" ${c.type === "number" ? 'inputmode="decimal" step="any"' : ""} ${c.w ? `style="min-width:${c.w}px"` : ""}>`;
  };
  const draw = () => {
    host.innerHTML = `<div class="table-wrap"><table class="t tc-grid" style="min-width:${o.minW || 0}px"><thead><tr><th>#</th>${cols.map((c) => `<th>${esc(c.l)}${c.unit ? ` <small>(${esc(c.unit)})</small>` : ""}</th>`).join("")}<th><span class="sr-only">${esc(t("del"))}</span></th></tr></thead><tbody>${arr.map((r, i) => `<tr><td class="tc-n">${i + 1}</td>${cols.map((c) => `<td>${cell(c, r, i)}</td>`).join("")}<td>${iconBtn("rm", i, I.trash, `${t("del")} ${i + 1}`)}</td></tr>`).join("")}</tbody></table></div><button type="button" class="btn btn-ghost btn-sm" data-add style="margin-top:8px">${I.plus}<span>${esc(o.addLabel)}</span></button>`;
  };
  const upd = (e) => { const el = e.target.closest("[data-c]"); if (!el) return; const [i, k] = el.dataset.c.split(":"); if (!arr[+i]) return; const c = cols.find((x) => x.k === k); arr[+i][k] = c.type === "number" ? (el.value === "" ? "" : Number(el.value)) : el.value; o.onChange && o.onChange(); };
  host.addEventListener("input", upd); host.addEventListener("change", upd);
  host.addEventListener("click", (e) => {
    const rm = e.target.closest("[data-rm]"), add = e.target.closest("[data-add]");
    if (rm && arr.length > (o.min || 0)) { arr.splice(+rm.dataset.rm, 1); draw(); o.onChange && o.onChange(); }
    if (add) { arr.push(o.blank()); draw(); const f = $(`#${o.id}-${arr.length - 1}-${cols[0].k}`); f && f.focus(); o.onChange && o.onChange(); }
  });
  draw();
  return { draw, set(next) { arr.length = 0; next.forEach((x) => arr.push({ ...x })); draw(); }, mark(i, k, bad) { const el = $(`#${o.id}-${i}-${k}`); if (el) el.setAttribute("aria-invalid", bad ? "true" : "false"); } };
}

/* saved records table with edit / print / delete */
function recList(host, key, cols, h) {
  const draw = () => {
    const all = store.get(key, []);
    host.innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr>${cols.map((c) => `<th>${esc(c[0])}</th>`).join("")}<th><span class="sr-only">${esc(W("إجراءات", "Actions"))}</span></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr>${cols.map((c) => `<td>${c[1](r)}</td>`).join("")}<td style="white-space:nowrap">${iconBtn("ed", r.id, I.note, t("edit"))} ${h.print ? iconBtn("pr", r.id, I.printer, t("print")) : ""} ${iconBtn("del", r.id, I.trash, t("del"))}</td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`;
    const c = $("#" + key.replace(":", "-") + "-n"); if (c) c.textContent = all.length;
  };
  host.addEventListener("click", (e) => {
    const all = store.get(key, []), ed = e.target.closest("[data-ed]"), pr = e.target.closest("[data-pr]"), dl = e.target.closest("[data-del]");
    if (ed) h.edit(all.find((r) => r.id === ed.dataset.ed));
    if (pr) h.print(all.find((r) => r.id === pr.dataset.pr));
    if (dl && confirm(t("confirmDel"))) { store.set(key, all.filter((r) => r.id !== dl.dataset.del)); h.deleted && h.deleted(dl.dataset.del); draw(); toast(t("deleted")); }
  });
  draw();
  return draw;
}
function saveRec(key, rec, editingId) {
  const all = store.get(key, []);
  if (editingId) { const i = all.findIndex((x) => x.id === editingId); rec.id = editingId; rec.created = i >= 0 ? all[i].created : Date.now(); rec.updated = Date.now(); if (i >= 0) all[i] = rec; else all.push(rec); }
  else { rec.id = uid(); rec.created = Date.now(); all.push(rec); }
  return store.set(key, all);
}
const recHead = (key, extra) => `<div class="row" style="margin:34px 0 12px"><h2 style="font-size:22px;margin:0">${esc(t("records"))} <span class="chip" id="${key.replace(":", "-")}-n"></span></h2><span class="spacer"></span>${extra || ""}</div><div id="${key.replace(":", "-")}-list"></div>`;
const recDate = (r) => esc(fmtDate(new Date(r.updated || r.created || Date.now()).toISOString()));
const formula = (html) => `<div class="pc-formula" dir="ltr">${html}</div>`;

/* =====================================================================
   1) Activity equivalent (kcal → minutes of activity)
   ===================================================================== */
const ACTS = [
  { k: "walk", met: 3.5, ar: "المشي (~5 كم/س)", en: "Walking (~5 km/h)", sar: "مشي", sen: "Walk" },
  { k: "brisk", met: 5.0, ar: "المشي السريع (~6.4 كم/س)", en: "Brisk walking (~6.4 km/h)", sar: "مشي سريع", sen: "Brisk walk" },
  { k: "run", met: 8.3, ar: "الجري (~8 كم/س)", en: "Running (~8 km/h)", sar: "جري", sen: "Run" },
  { k: "bike", met: 6.8, ar: "ركوب الدراجة للترفيه", en: "Cycling, leisure", sar: "دراجة", sen: "Cycle" },
  { k: "swim", met: 5.8, ar: "السباحة الحرة بجهد معتدل", en: "Swimming, moderate freestyle", sar: "سباحة", sen: "Swim" },
  { k: "stairs", met: 8.0, ar: "صعود الدرج", en: "Climbing stairs", sar: "درج", sen: "Stairs" },
];
const COMPENDIUM = "Ainsworth BE, Haskell WL, Herrmann SD, et al. 2011 Compendium of Physical Activities: a second update of codes and MET values. Med Sci Sports Exerc. 2011;43(8):1575–1581.";
const kcalPerMin = (met, kg) => (met * 3.5 * kg) / 200;

function stripSvg(o) {
  const cw = 112, w = cw * o.rows.length + 20, h = o.name ? 200 : 180, y0 = o.name ? 22 : 0;
  const cells = o.rows.map((r, i) => {
    const x = 10 + i * cw, a = ACTS.find((z) => z.k === r.k);
    return `<g transform="translate(${x + cw / 2 - 18} ${y0 + 42}) scale(1.5)" fill="none" stroke="#111" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${ICO[r.k]}</g>
      <text x="${x + cw / 2}" y="${y0 + 108}" text-anchor="middle" font-size="21" font-weight="700" fill="#111" direction="ltr">${Math.round(r.min)} min</text>
      <text x="${x + cw / 2}" y="${y0 + 126}" text-anchor="middle" font-size="12" fill="#333">${esc(a.sar)} | ${esc(a.sen)}</text>${i ? `<line x1="${x}" y1="${y0 + 40}" x2="${x}" y2="${y0 + 130}" stroke="#ccc"/>` : ""}`;
  }).join("");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" direction="ltr" font-family="'IBM Plex Sans Arabic','Noto Sans Arabic',Inter,Arial,sans-serif" role="img" aria-label="${esc(`${fix(o.kcal, 0)} kcal ≈ ` + o.rows.map((r) => `${ACTS.find((z) => z.k === r.k).sen} ${Math.round(r.min)} min`).join(", "))}">
    <rect x="1" y="1" width="${w - 2}" height="${h - 2}" rx="8" fill="#fff" stroke="#111" stroke-width="2"/>
    ${o.name ? `<text x="${w / 2}" y="24" text-anchor="middle" font-size="15" font-weight="700" fill="#111">${esc(o.name)}</text>` : ""}
    <text x="14" y="${y0 + 26}" font-size="14" font-weight="700" fill="#111" direction="ltr">≈ ${fix(o.kcal, 0)} kcal per serving equals about</text>
    <text x="${w - 14}" y="${y0 + 26}" text-anchor="start" font-size="14" font-weight="700" fill="#111" direction="rtl">${fix(o.kcal, 0)} سعرة للحصة تعادل تقريبًا</text>
    ${cells}
    <text x="${w / 2}" y="${y0 + 152}" text-anchor="middle" font-size="11" fill="#333" direction="rtl">دقائق تقريبية لشخص وزنه ${fix(o.kg, 0)} كغ — تقدير تعليمي وليس نصيحة طبية</text>
    <text x="${w / 2}" y="${y0 + 168}" text-anchor="middle" font-size="11" fill="#333" direction="ltr">Approx. minutes for a ${fix(o.kg, 0)} kg person — educational estimate, not medical advice · METs: Compendium of Physical Activities</text>
  </svg>`;
}

function burnPage() {
  const CK = "tool:burn";
  const cfg = () => { const c = store.get(CK, {}) || {}; return { kg: isNum(c.kg) ? c.kg : 70, met: Object.assign({}, ...ACTS.map((a) => ({ [a.k]: a.met })), c.met || {}) }; };
  const c0 = cfg(), recs = recipes();
  const html = `${head("burn")}
    <div class="grid g2" style="margin-top:18px;align-items:start">
      <form class="card" id="buForm" novalidate><h2 style="font-size:20px">${esc(W("البيانات", "Inputs"))}</h2>
        <div class="form">
          ${fld("bu-name", W("اسم المنتج (اختياري، يظهر على الشريط)", "Product name (optional, shown on the strip)"), inp("bu-name", "text", "", 'maxlength="60"'), { full: true })}
          <div class="field full"><label for="bu-src">${esc(W("مصدر الطاقة", "Energy source"))}</label>${sel("bu-src", [["label", W("أكتب الطاقة من الملصق", "Type the energy from the label")], ["recipe", W("وصفة محفوظة في حاسبة القيم الغذائية", "Saved recipe in the nutrition calculator")]], "label")}</div>
          <div class="field" data-src="label"><label for="bu-e" class="req">${esc(W("الطاقة لكل حصة", "Energy per serving"))}</label>${inp("bu-e", "number", "", 'min="0"')}<span class="err" id="bu-e-e"></span></div>
          <div class="field" data-src="label"><label for="bu-u">${esc(W("الوحدة", "Unit"))}</label>${sel("bu-u", [["kcal", "kcal"], ["kJ", "kJ"]], "kcal")}</div>
          <div class="field full" data-src="recipe" hidden><label for="bu-rec" class="req">${esc(W("الوصفة", "Recipe"))}</label>${recs.length ? sel("bu-rec", recs.map((r) => [r.id, `${r.name}${r.out && r.out.ps ? ` — ${fix(r.out.ps.kcal, 0)} kcal / ${fix(r.out.servW, 0)} g` : ""}`]), "") : `<select id="bu-rec" disabled><option value="">${esc(W("لا توجد وصفات محفوظة", "No saved recipes"))}</option></select>`}<span class="hint">${recs.length ? esc(W("تُستخدم قيمة الطاقة لكل حصة كما حُسبت في الوصفة.", "Uses the energy per serving calculated in the recipe.")) : `<a href="#/tools/nutrition">${esc(W("افتح حاسبة القيم الغذائية واحفظ وصفة", "Open the nutrition calculator and save a recipe"))}</a>`}</span><span class="err" id="bu-rec-e"></span></div>
          ${fld("bu-kg", W("وزن الجسم (كغ)", "Body weight (kg)"), inp("bu-kg", "number", c0.kg, 'min="20" max="300"'), { req: true, hint: W("القيمة الافتراضية 70 كغ للمقارنة فقط؛ غيّرها حسب الحاجة.", "70 kg is a reference value for comparison only; change it as needed.") })}
        </div>
        <h3 style="margin:20px 0 8px;font-size:16px">${esc(W("الأنشطة وقيم MET (قابلة للتعديل)", "Activities and MET values (editable)"))}</h3>
        <div class="pc-acts">${ACTS.map((a) => `<div class="pc-act"><span class="pc-ai">${I[a.k]}</span><label for="bu-m-${a.k}">${esc(W(a.ar, a.en))}</label><input id="bu-m-${a.k}" type="number" inputmode="decimal" step="any" min="0" value="${esc(c0.met[a.k])}" aria-describedby="bu-met-h"><span class="err" id="bu-m-${a.k}-e"></span></div>`).join("")}</div>
        <p class="note" id="bu-met-h">${esc(W("MET = مكافئ الأيض. القيم المبدئية من «موسوعة الأنشطة البدنية» (Ainsworth وآخرون)؛ راجع الإصدار المعتمد لديك وعدّلها إن لزم.", "MET = metabolic equivalent. Starting values are from the Compendium of Physical Activities (Ainsworth et al.); check the edition you rely on and edit if needed."))}</p>
        <div class="row" style="margin-top:14px">${btn("buCalc", I.calc, W("احسب", "Calculate"), "btn-gold", "submit")}${btn("buReset", I.note, W("استعادة قيم MET", "Restore MET values"), "btn-ghost btn-sm")}<span class="err" id="buErr" role="alert"></span></div>
      </form>
      <div class="card" id="buRes" aria-live="polite"><h3>${esc(W("النتيجة", "Result"))}</h3><p class="note" style="margin:0">${esc(W("أدخل الطاقة لكل حصة ثم اضغط احسب.", "Enter the energy per serving, then press calculate."))}</p></div>
    </div>
    <div class="card" style="margin-top:18px"><h3>${esc(W("المعادلة والمصدر", "Formula and source"))}</h3>
      ${formula("kcal/min = MET × 3.5 × body weight (kg) ÷ 200<br>minutes = energy (kcal) ÷ kcal/min<br>kcal = kJ ÷ 4.184")}
      <ul class="ticks" style="margin-top:10px"><li>${esc(W("‏3.5 مل أكسجين/كغ/دقيقة تعادل MET واحدًا، و5 kcal تقريبًا لكل لتر أكسجين، ومنها القسمة على 200.", "1 MET ≈ 3.5 mL O₂/kg/min and ≈ 5 kcal per litre of O₂, which gives the ÷ 200."))}</li>
        <li>${esc(W("النتيجة تقدير تعليمي متوسط؛ يختلف الإنفاق الفعلي بالعمر واللياقة والجنس والبيئة. ليست نصيحة طبية أو غذائية.", "The result is an average educational estimate; actual expenditure varies with age, fitness, sex and environment. It is not medical or dietary advice."))}</li>
        <li>${esc(W("المصدر:", "Source:"))} <span dir="ltr">${esc(COMPENDIUM)}</span></li></ul></div>
    </div></section>`;
  function after() {
    const form = $("#buForm");
    const srcSwitch = () => { const s = $("#bu-src").value; $$("[data-src]", form).forEach((el) => (el.hidden = el.dataset.src !== s)); };
    $("#bu-src").addEventListener("change", srcSwitch);
    let last = null;
    const read = (silent) => {
      clearErrs(form); let ok = true;
      const src = $("#bu-src").value, kg = nval("bu-kg"); let kcal = null, kj = null, rec = null;
      if (src === "label") {
        const e = nval("bu-e"), u = $("#bu-u").value;
        if (e === "") ok = setErr("bu-e", t("required")) && false;
        else if (!(e > 0) || (u === "kcal" ? e > 10000 : e > 41840)) ok = setErr("bu-e", W("أدخل قيمة أكبر من صفر ومعقولة لحصة واحدة.", "Enter a value above zero that is plausible for one serving.")) && false;
        else if (u === "kJ") { kj = e; kcal = e / 4.184; } else kcal = e;
      } else {
        rec = recipes().find((r) => r.id === $("#bu-rec").value);
        if (!rec || !rec.out || !rec.out.ps || !(rec.out.ps.kcal > 0)) ok = setErr("bu-rec", W("اختر وصفة محفوظة فيها طاقة محسوبة لكل حصة.", "Choose a saved recipe with a calculated energy per serving.")) && false;
        else kcal = rec.out.ps.kcal;
      }
      if (kg === "") ok = setErr("bu-kg", t("required")) && false;
      else if (!(kg >= 20 && kg <= 300)) ok = setErr("bu-kg", W("أدخل وزنًا بين 20 و300 كغ.", "Enter a weight between 20 and 300 kg.")) && false;
      const met = {};
      ACTS.forEach((a) => { const m = nval("bu-m-" + a.k); if (!(m > 0 && m <= 25)) ok = setErr("bu-m-" + a.k, W("بين 0 و25.", "Between 0 and 25.")) && false; else met[a.k] = m; });
      if (!ok && silent) clearErrs(form);
      return ok ? { kcal, kj, kg, met, rec, name: val("bu-name") || (rec ? rec.name : "") } : null;
    };
    const show = (o) => {
      const rows = ACTS.map((a) => { const rate = kcalPerMin(o.met[a.k], o.kg); return { k: a.k, met: o.met[a.k], rate, min: o.kcal / rate }; });
      last = { ...o, rows };
      const w0 = rows[0];
      $("#buRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3>
        <div class="row" style="gap:6px;margin-bottom:10px"><span class="chip gold">${esc(W("الطاقة لكل حصة", "Energy per serving"))}: <b dir="ltr">${fix(o.kcal, 1)} kcal</b></span><span class="chip">${esc(W("الوزن", "Weight"))}: <b dir="ltr">${fix(o.kg, 1)} kg</b></span>${o.rec ? `<span class="chip">${esc(o.rec.name)}</span>` : ""}</div>
        ${o.kj != null ? `<p class="note" dir="ltr" style="text-align:start;margin-top:0">${fix(o.kj, 1)} kJ ÷ 4.184 = ${fix(o.kcal, 1)} kcal</p>` : ""}
        <div class="table-wrap"><table class="t" style="min-width:0"><thead><tr><th>${esc(W("النشاط", "Activity"))}</th><th>MET</th><th>kcal/min</th><th>${esc(W("الدقائق", "Minutes"))}</th></tr></thead><tbody>${rows.map((r) => { const a = ACTS.find((z) => z.k === r.k); return `<tr data-act="${r.k}"><td><span class="pc-ti">${I[r.k]}</span>${esc(W(a.ar, a.en))}</td><td dir="ltr">${fix(r.met, 1)}</td><td dir="ltr">${fix(r.rate, 3)}</td><td dir="ltr" data-min="${fix(r.min, 1)}"><b>${fix(r.min, 1)}</b> min</td></tr>`; }).join("")}</tbody></table></div>
        <p class="note">${esc(W("مثال (المشي):", "Example (walking):"))} <bdi dir="ltr">${fix(w0.met, 1)} × 3.5 × ${fix(o.kg, 1)} ÷ 200 = ${fix(w0.rate, 4)} kcal/min → ${fix(o.kcal, 1)} ÷ ${fix(w0.rate, 4)} = ${fix(w0.min, 1)} min</bdi></p>
        <h3 style="margin-top:16px;font-size:16px">${esc(W("شريط «مكافئ النشاط» للملصق", "“Activity equivalent” strip for the label"))}</h3>
        <div class="pc-strip" id="buStrip">${stripSvg(last)}</div>
        <div class="row" style="margin-top:10px">${btn("buPrint", I.printer, W("طباعة الشريط", "Print strip"), "btn-ghost btn-sm")}${btn("buSvg", I.download, "SVG", "btn-ghost btn-sm")}${btn("buPng", I.download, "PNG", "btn-ghost btn-sm")}${btn("buShare", I.share, W("مشاركة النص", "Share as text"), "btn-ghost btn-sm")}</div>
        <p class="note">${esc(W("تقدير تعليمي وليس نصيحة طبية. تحقّق من متطلبات الملصق في التشريع المطبّق قبل إضافة الشريط إلى منتج.", "Educational estimate, not medical advice. Check the labelling rules that apply to you before adding the strip to a product."))}</p>`;
      store.set(CK, { kg: o.kg, met: o.met });
    };
    const calc = (silent) => { const o = read(silent); $("#buErr").textContent = o || silent ? "" : t("fixErrors"); if (o) show(o); else if (!silent) focusBad(form); };
    form.addEventListener("submit", (e) => { e.preventDefault(); calc(false); });
    form.addEventListener("input", () => calc(true));
    form.addEventListener("change", () => calc(true));
    $("#buReset").addEventListener("click", () => { ACTS.forEach((a) => ($("#bu-m-" + a.k).value = a.met)); calc(true); });
    $("#buRes").addEventListener("click", async (e) => {
      if (!last) return;
      const svgStr = stripSvg(last), base = `activity-${safeName(last.name)}-${Math.round(last.kcal)}kcal`;
      if (e.target.closest("#buPrint")) printLabel(`<div style="width:104mm;padding:2mm">${svgStr.replace(/width="\d+" height="\d+"/, 'width="100%"')}</div>`, "108mm 34mm");
      if (e.target.closest("#buSvg")) download(base + ".svg", svgStr, "image/svg+xml");
      if (e.target.closest("#buPng")) {
        const img = new Image(), m = svgStr.match(/width="(\d+)" height="(\d+)"/);
        img.onload = () => { const c = document.createElement("canvas"); c.width = +m[1] * 3; c.height = +m[2] * 3; const g = c.getContext("2d"); g.scale(3, 3); g.drawImage(img, 0, 0); c.toBlob((b) => b && dlBlob(base + ".png", b), "image/png"); };
        img.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svgStr);
      }
      if (e.target.closest("#buShare")) {
        const txt = `${last.name ? last.name + " — " : ""}${fix(last.kcal, 0)} kcal ≈ ` + last.rows.map((r) => { const a = ACTS.find((z) => z.k === r.k); return `${W(a.sar, a.sen)} ${Math.round(r.min)} min`; }).join(" · ") + ` (${fix(last.kg, 0)} kg; ${W("تقدير تعليمي", "educational estimate")})`;
        try { if (navigator.share) await navigator.share({ title: L(tool("burn").t), text: txt }); else { await navigator.clipboard.writeText(txt); toast(W("نُسخ النص", "Text copied")); } } catch (_) { /* cancelled */ }
      }
    });
    srcSwitch();
  }
  return { title: L(tool("burn").t), html, after };
}

/* =====================================================================
   2) Shelf life after opening / thawing / preparation
   ===================================================================== */
const BASIS = () => [["open", W("بعد الفتح", "After opening")], ["thaw", W("بعد الإذابة", "After thawing")], ["prep", W("بعد التحضير", "After preparation")], ["other", W("أخرى", "Other")]];
const BASIS_BI = { open: ["فُتح", "Opened"], thaw: ["أُذيب", "Thawed"], prep: ["حُضّر", "Prepared"], other: ["البدء", "Start"] };
const nowLocal = () => { const d = new Date(); d.setSeconds(0, 0); d.setMinutes(d.getMinutes() - d.getTimezoneOffset()); return d.toISOString().slice(0, 16); };
const isoLocal = (d) => `${d.getFullYear()}-${p2(d.getMonth() + 1)}-${p2(d.getDate())}T${p2(d.getHours())}:${p2(d.getMinutes())}`;
const dmyhm = (d) => `${p2(d.getDate())}/${p2(d.getMonth() + 1)}/${d.getFullYear()} ${p2(d.getHours())}:${p2(d.getMinutes())}`;
const fmtDT = (d) => d.toLocaleString(LOC(), { weekday: "short", year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
function durTxt(ms) {
  const neg = ms < 0; ms = Math.abs(ms);
  const d = Math.floor(ms / 864e5), h = Math.floor((ms % 864e5) / 36e5), m = Math.floor((ms % 36e5) / 6e4);
  const s = [d ? W(`${d} يوم`, `${d} d`) : "", h ? W(`${h} ساعة`, `${h} h`) : "", W(`${m} دقيقة`, `${m} min`)].filter(Boolean).join(" ");
  return neg ? W(`انتهت منذ ${s}`, `expired ${s} ago`) : s;
}
// start Date + value in hours or days; whole days keep the wall-clock time (calendar arithmetic)
function addDur(start, v, unit) {
  if (unit === "d" && Number.isInteger(v)) { const d = new Date(start); d.setDate(d.getDate() + v); return d; }
  return new Date(start.getTime() + v * (unit === "d" ? 864e5 : 36e5));
}
function afterOpenCalc(r) {
  const start = new Date(r.start), byDur = addDur(start, r.v, r.unit);
  const cap = r.exp ? new Date(`${r.exp}T${r.expT || "23:59"}`) : null;
  const capped = !!(cap && cap < byDur);
  return { start, byDur, cap, useBy: capped ? cap : byDur, capped };
}
function aoLabel(r, o) {
  const b = BASIS_BI[r.basis] || BASIS_BI.other, wd = (l) => o.useBy.toLocaleDateString(l === "ar" ? "ar-SA-u-ca-gregory" : "en-GB", { weekday: "short" });
  return `<div class="pc-lbl"><b class="pc-lbl-n">${esc(r.name)}</b>
    <div><span>${b[0]} | ${b[1]}</span> <bdi dir="ltr">${dmyhm(o.start)}</bdi></div>
    <div class="pc-lbl-u"><span>استخدم قبل | Use by</span><bdi dir="ltr">${dmyhm(o.useBy)}</bdi><small>${esc(wd("ar"))} | ${esc(wd("en"))}</small></div>
    <div class="pc-lbl-f">${r.by ? `<span>${esc(r.by)}</span>` : ""}${o.capped ? `<span>≤ ${esc("EXP")}</span>` : ""}</div></div>`;
}
function afterOpenPage() {
  const IK = "tool:afteropen-items";
  const html = `${head("afteropen")}
    <div class="grid g2" style="margin-top:18px;align-items:start">
      <form class="card" id="aoForm" novalidate><h2 style="font-size:20px">${esc(W("البيانات", "Inputs"))}</h2>
        <div class="form">
          ${fld("ao-name", W("المنتج", "Product"), inp("ao-name", "text", "", 'maxlength="50" list="aoNames"'), { req: true, full: true })}
          <div class="field"><label for="ao-basis">${esc(W("الحدث", "Event"))}</label>${sel("ao-basis", BASIS(), "open")}</div>
          ${fld("ao-start", W("تاريخ ووقت البدء", "Start date and time"), inp("ao-start", "datetime-local", nowLocal()), { req: true })}
          ${fld("ao-v", W("المدة", "Duration"), inp("ao-v", "number", "", 'min="0"'), { req: true, hint: W("من ملصق المنتج أو إجراء منشأتك — لا توجد قيمة افتراضية.", "From the product label or your site procedure — there is no default.") })}
          <div class="field"><label for="ao-unit">${esc(W("وحدة المدة", "Duration unit"))}</label>${sel("ao-unit", [["h", W("ساعات", "hours")], ["d", W("أيام", "days")]], "d")}</div>
          ${fld("ao-src", W("مصدر المدة", "Source of the duration"), inp("ao-src", "text", "", `maxlength="80" placeholder="${esc(W("مثال: ملصق المورد، إجراء SOP-12", "e.g. supplier label, SOP-12"))}"`), { full: true })}
          ${fld("ao-exp", W("تاريخ الانتهاء الأصلي (اختياري)", "Original expiry date (optional)"), inp("ao-exp", "date", ""), { hint: W("لن يتجاوز تاريخ الاستخدام هذا التاريخ.", "The use-by will not go past this date.") })}
          ${fld("ao-expT", W("وقت الانتهاء (اختياري)", "Expiry time (optional)"), inp("ao-expT", "time", ""), { hint: W("إن تُرك فارغًا يُعتبر نهاية اليوم 23:59.", "If blank, the end of the day (23:59) is used.") })}
          ${fld("ao-by", W("بواسطة / الأحرف الأولى (اختياري)", "By / initials (optional)"), inp("ao-by", "text", "", 'maxlength="20"'))}
        </div>
        <div class="row" style="margin-top:16px">${btn("aoCalc", I.calc, W("احسب", "Calculate"), "btn-gold", "submit")}${btn("aoPrint", I.printer, W("طباعة ملصق 50×30 مم", "Print 50×30 mm label"))}${btn("aoSave", I.plus, W("احفظ كعنصر متكرر", "Save as frequent item"), "btn-ghost btn-sm")}<span class="err" id="aoErr" role="alert"></span></div>
      </form>
      <div class="card" id="aoRes" aria-live="polite"><h3>${esc(W("النتيجة", "Result"))}</h3><p class="note" style="margin:0">${esc(W("أدخل البيانات ثم اضغط احسب.", "Enter the details, then press calculate."))}</p></div>
    </div>
    <div class="card" style="margin-top:18px"><h3>${esc(W("طريقة الحساب", "How it is calculated"))}</h3>
      ${formula("use-by = start + duration<br>if an original expiry is entered: use-by = min(start + duration, expiry)<br>whole days keep the same clock time; hours are added exactly")}
      <p class="note">${esc(W("الأداة لا تقترح أي مدة صلاحية. المدة مسؤولية من يدخلها ويجب أن تستند إلى ملصق المنتج أو دراسة/إجراء معتمد.", "The tool suggests no shelf life. The duration is the responsibility of whoever enters it and must come from the product label or a validated study/procedure."))}</p></div>
    <div class="row" style="margin:34px 0 12px"><h2 style="font-size:22px;margin:0">${esc(W("العناصر المتكررة", "Frequent items"))} <span class="chip" id="aoN"></span></h2></div><div id="aoItems"></div><datalist id="aoNames"></datalist>
    </div></section>`;
  function after() {
    const form = $("#aoForm"); let last = null, tick = null;
    const read = () => ({ name: val("ao-name"), basis: $("#ao-basis").value, start: val("ao-start"), v: nval("ao-v"), unit: $("#ao-unit").value, src: val("ao-src"), exp: val("ao-exp"), expT: val("ao-expT"), by: val("ao-by") });
    const validate = (r) => {
      clearErrs(form);
      let ok = setErr("ao-name", r.name ? "" : t("required"));
      ok = setErr("ao-start", !r.start || isNaN(new Date(r.start)) ? W("أدخل تاريخًا ووقتًا صحيحين.", "Enter a valid date and time.") : "") && ok;
      ok = setErr("ao-v", r.v === "" ? t("required") : !(r.v > 0) ? MSG.pos() : (r.unit === "h" ? r.v > 24 * 3650 : r.v > 3650) ? W("المدة كبيرة جدًا؛ تحقق من الوحدة.", "Duration is too large; check the unit.") : "") && ok;
      if (r.expT && !r.exp) ok = setErr("ao-exp", W("أدخل التاريخ مع الوقت.", "Enter the date with the time.")) && ok;
      if (ok && r.exp && new Date(`${r.exp}T${r.expT || "23:59"}`) <= new Date(r.start)) ok = setErr("ao-exp", W("تاريخ الانتهاء الأصلي قبل وقت البدء — المنتج منتهٍ ولا يُستخدم.", "The original expiry is before the start time — the product has expired and must not be used.")) && false;
      $("#aoErr").textContent = ok ? "" : t("fixErrors"); if (!ok) focusBad(form);
      return ok;
    };
    const remain = () => { if (!last) return; const ms = last.o.useBy - Date.now(), el = $("#aoRemain"); if (!el) { clearInterval(tick); return; } el.textContent = durTxt(ms); el.className = "chip " + (ms <= 0 ? "bad" : ms < 36e5 * 6 ? "warn" : "ok"); };
    const show = (r) => {
      const o = afterOpenCalc(r); last = { r, o };
      $("#aoRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3>
        <div class="pc-big"><span>${esc(W("يُستخدم قبل", "Use by"))}</span><b dir="ltr" id="aoUse" data-iso="${isoLocal(o.useBy)}">${dmyhm(o.useBy)}</b><small>${esc(fmtDT(o.useBy))}</small></div>
        <p style="margin:10px 0">${esc(W("المتبقي:", "Remaining:"))} <span id="aoRemain" class="chip"></span></p>
        ${kvTable([[W("البدء", "Start"), `<bdi dir="ltr">${dmyhm(o.start)}</bdi>`], [W("المدة", "Duration"), `<bdi dir="ltr">${fix(r.v, 2).replace(/\.?0+$/, "")} ${r.unit === "h" ? "h" : "d"}</bdi>${r.src ? ` — ${esc(r.src)}` : ""}`], [W("البدء + المدة", "Start + duration"), `<bdi dir="ltr">${dmyhm(o.byDur)}</bdi>`], [W("الانتهاء الأصلي", "Original expiry"), o.cap ? `<bdi dir="ltr">${dmyhm(o.cap)}</bdi>${r.expT ? "" : ` <small>(${esc(W("نهاية اليوم", "end of day"))})</small>`}` : "—"], [W("الحد المطبّق", "Limit applied"), o.capped ? `<span class="chip warn" id="aoCap">${esc(W("الانتهاء الأصلي أقرب", "Original expiry is earlier"))}</span>` : `<span class="chip">${esc(W("المدة المدخلة", "Entered duration"))}</span>`]])}
        <h3 style="margin-top:14px;font-size:16px">${esc(W("معاينة الملصق (50×30 مم)", "Label preview (50×30 mm)"))}</h3><div class="pc-lbl-wrap">${aoLabel(r, o)}</div>`;
      remain(); clearInterval(tick); tick = setInterval(remain, 30000);
    };
    form.addEventListener("submit", (e) => { e.preventDefault(); const r = read(); if (validate(r)) show(r); });
    $("#aoPrint").addEventListener("click", () => { const r = read(); if (!validate(r)) return; show(r); printLabel(aoLabel(r, last.o), "50mm 30mm"); });
    const items = () => store.get(IK, []);
    const drawItems = () => {
      const all = items(); $("#aoN").textContent = all.length;
      $("#aoNames").innerHTML = all.map((x) => `<option value="${esc(x.name)}">`).join("");
      $("#aoItems").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("المنتج", "Product"))}</th><th>${esc(W("الحدث", "Event"))}</th><th>${esc(W("المدة", "Duration"))}</th><th>${esc(W("المصدر", "Source"))}</th><th><span class="sr-only">${esc(W("إجراءات", "Actions"))}</span></th></tr></thead><tbody>${all.map((x) => `<tr><td>${esc(x.name)}</td><td>${esc((BASIS().find((b) => b[0] === x.basis) || ["", ""])[1])}</td><td><bdi dir="ltr">${esc(x.v)} ${x.unit === "h" ? "h" : "d"}</bdi></td><td>${esc(x.src)}</td><td style="white-space:nowrap"><button type="button" class="btn btn-ghost btn-sm" data-use="${esc(x.id)}">${esc(W("استخدم", "Use"))}</button> ${iconBtn("del", x.id, I.trash, t("del"))}</td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(W("لا توجد عناصر بعد. احفظ منتجًا تستخدمه كثيرًا مع مدته.", "No items yet. Save a product you use often with its duration."))}</div>`;
    };
    $("#aoSave").addEventListener("click", () => {
      const r = read(); clearErrs(form); let ok = setErr("ao-name", r.name ? "" : t("required")); ok = setErr("ao-v", r.v === "" ? t("required") : !(r.v > 0) ? MSG.pos() : "") && ok;
      if (!ok) { focusBad(form); return; }
      const all = items(), i = all.findIndex((x) => x.name === r.name && x.basis === r.basis), it = { id: i >= 0 ? all[i].id : uid(), name: r.name, basis: r.basis, v: r.v, unit: r.unit, src: r.src };
      if (i >= 0) all[i] = it; else all.push(it);
      if (store.set(IK, all)) { toast(t("saved")); drawItems(); }
    });
    $("#aoItems").addEventListener("click", (e) => {
      const u = e.target.closest("[data-use]"), d = e.target.closest("[data-del]"), all = items();
      if (u) { const x = all.find((y) => y.id === u.dataset.use); if (!x) return; $("#ao-name").value = x.name; $("#ao-basis").value = x.basis; $("#ao-v").value = x.v; $("#ao-unit").value = x.unit; $("#ao-src").value = x.src || ""; $("#ao-start").value = nowLocal(); A.scrollTo(form, true); $("#ao-start").focus(); }
      if (d && confirm(t("confirmDel"))) { store.set(IK, all.filter((y) => y.id !== d.dataset.del)); drawItems(); toast(t("deleted")); }
    });
    drawItems();
  }
  return { title: L(tool("afteropen").t), html, after };
}

/* =====================================================================
   3) Net content check for a batch
   ===================================================================== */
function nwStats(r) {
  const net = r.samples.map((g) => g - r.tare), n = net.length;
  const mean = net.reduce((s, x) => s + x, 0) / n;
  const sd = n > 1 ? Math.sqrt(net.reduce((s, x) => s + (x - mean) ** 2, 0) / (n - 1)) : 0;
  const t1 = r.qn - r.T, t2 = r.qn - 2 * r.T;
  const below = net.filter((x) => x < r.qn).length, def1 = net.filter((x) => x < t1).length, def2 = net.filter((x) => x < t2).length;
  const k = isNum(r.k) ? +r.k : 0, meanLim = r.qn - k * sd;
  const rules = [{ id: "mean", ok: mean >= meanLim - 1e-9, txt: k ? `mean ≥ Qn − k·s = ${fix(meanLim, 3)}` : "mean ≥ Qn" }, { id: "def", ok: def1 <= r.allowed, txt: `n(< Qn − T) = ${def1} ≤ ${r.allowed}` }];
  if (r.t2rule) rules.push({ id: "t2", ok: def2 === 0, txt: `n(< Qn − 2T) = ${def2} = 0` });
  return { net, n, mean, sd, min: Math.min(...net), max: Math.max(...net), t1, t2, below, def1, def2, meanLim, rules, pass: rules.every((x) => x.ok) };
}
function histSvg(r, s) {
  const lo0 = Math.min(s.min, s.t1), hi0 = Math.max(s.max, r.qn), span = hi0 - lo0 || Math.max(1, r.qn * 0.01);
  const lo = lo0 - span * 0.05, hi = hi0 + span * 0.05, bins = Math.max(5, Math.min(20, Math.ceil(Math.log2(s.n) + 1)));
  const bw = (s.max - s.min) / bins || span / bins, b0 = s.min - (s.max === s.min ? bw / 2 : 0);
  const cnt = Array(bins).fill(0); s.net.forEach((x) => { cnt[Math.min(bins - 1, Math.floor((x - b0) / bw))]++; });
  const Wd = 620, H = 230, L0 = 36, R0 = 12, T0 = 24, B0 = 40, X = (v) => L0 + ((v - lo) / (hi - lo)) * (Wd - L0 - R0), mx = Math.max(...cnt), Y = (c) => H - B0 - (c / mx) * (H - B0 - T0);
  const ticks = Array.from({ length: 5 }, (_, i) => lo + ((hi - lo) * i) / 4);
  const vline = (v, col, lab, dash, dy) => `<line x1="${X(v)}" x2="${X(v)}" y1="${T0 - 6}" y2="${H - B0}" stroke="${col}" stroke-width="2" ${dash ? 'stroke-dasharray="5 4"' : ""}/><text x="${X(v)}" y="${T0 - 10 + (dy || 0)}" text-anchor="middle" font-size="11" fill="${col}">${lab}</text>`;
  return `<svg class="pc-hist" viewBox="0 0 ${Wd} ${H}" role="img" aria-label="${esc(W(`مدرج تكراري لـ ${s.n} عينة`, `Histogram of ${s.n} samples`))}" dir="ltr" font-family="Inter,Arial,sans-serif">
    <line x1="${L0}" x2="${Wd - R0}" y1="${H - B0}" y2="${H - B0}" stroke="currentColor" opacity=".5"/>
    ${cnt.map((c, i) => c ? `<rect x="${X(b0 + i * bw) + 1}" y="${Y(c)}" width="${Math.max(1, X(b0 + (i + 1) * bw) - X(b0 + i * bw) - 2)}" height="${H - B0 - Y(c)}" fill="#53b9ad" opacity=".85"><title>${fix(b0 + i * bw, 2)} – ${fix(b0 + (i + 1) * bw, 2)}: ${c}</title></rect><text x="${(X(b0 + i * bw) + X(b0 + (i + 1) * bw)) / 2}" y="${Y(c) - 3}" text-anchor="middle" font-size="10" fill="currentColor">${c}</text>` : "").join("")}
    ${ticks.map((v) => `<text x="${X(v)}" y="${H - B0 + 16}" text-anchor="middle" font-size="10.5" fill="currentColor" opacity=".8">${fix(v, Math.abs(hi - lo) < 10 ? 2 : 1)}</text>`).join("")}
    <text x="${(Wd + L0) / 2}" y="${H - 6}" text-anchor="middle" font-size="11" fill="currentColor" opacity=".8">net (${esc(r.unit)})</text>
    ${vline(r.qn, "#ddb03f", "Qn", false, 0)}${vline(s.t1, "#e5645a", "Qn−T", false, 0)}${s.t2 >= lo ? vline(s.t2, "#e5645a", "Qn−2T", true, 12) : ""}${vline(s.mean, "#9aa0a6", "x̄", true, 12)}
  </svg>`;
}
const parseNums = (txt) => String(txt || "").split(/[\n\r\t;]+|\s+/).map((x) => x.trim()).filter(Boolean).map((x) => (/^-?\d+,\d+$/.test(x) ? x.replace(",", ".") : x));
function netWeightPage() {
  const RK = "tool:netweight";
  let samples = [""], editing = null;
  const UNITS = [["g", "g"], ["kg", "kg"], ["mL", "mL"], ["L", "L"]];
  const html = `${head("netweight")}
    <form class="card" id="nwForm" novalidate style="margin-top:18px"><h2 style="font-size:20px" id="nwTitle">${esc(t("newRec"))}</h2>
      <div class="form">
        ${fld("nw-prod", W("المنتج", "Product"), inp("nw-prod", "text", "", 'maxlength="80"'), { req: true })}
        ${fld("nw-lot", W("رقم التشغيلة / الدفعة", "Batch / lot number"), inp("nw-lot", "text", "", 'maxlength="40"'))}
        ${fld("nw-date", W("تاريخ الفحص", "Check date"), inp("nw-date", "date", new Date().toISOString().slice(0, 10)))}
        <div class="field"><label for="nw-unit">${esc(W("الوحدة", "Unit"))}</label>${sel("nw-unit", UNITS, "g")}</div>
        ${fld("nw-qn", W("الكمية الاسمية Qn", "Nominal quantity Qn"), inp("nw-qn", "number", "", 'min="0"'), { req: true })}
        ${fld("nw-tare", W("وزن العبوة الفارغة (التارة)", "Tare (empty packaging)"), inp("nw-tare", "number", "", 'min="0"'), { req: true, hint: W("متوسط تارة مقيس لعبواتك، بنفس الوحدة.", "A measured average tare of your packaging, same unit.") })}
        ${fld("nw-T", W("الخطأ السالب المسموح T", "Tolerable negative error T"), inp("nw-T", "number", "", 'min="0"'), { req: true, hint: W("أدخله من الجدول/التشريع الذي تطبّقه (انظر الملاحظة أدناه).", "Enter it from the table/regulation you apply (see the note below).") })}
        ${fld("nw-allow", W("العدد المسموح من العبوات تحت Qn − T", "Allowed count below Qn − T"), inp("nw-allow", "number", "", 'min="0" step="1" inputmode="numeric"'), { req: true, hint: W("من خطة المعاينة التي تطبّقها لحجم العينة هذا.", "From the sampling plan you apply for this sample size.") })}
        ${fld("nw-k", W("معامل تصحيح العينة k (اختياري)", "Sample correction factor k (optional)"), inp("nw-k", "number", "", 'min="0"'), { hint: W("إن كانت خطتك تشترط: المتوسط ≥ Qn − k·s. اتركه فارغًا لقاعدة المتوسط ≥ Qn.", "If your plan requires mean ≥ Qn − k·s. Leave blank for the rule mean ≥ Qn.") })}
        <label class="field" style="flex-direction:row;align-items:center;gap:8px;align-self:end"><input type="checkbox" id="nw-t2" style="width:18px;height:18px;accent-color:var(--gold)"> <span>${esc(W("القاعدة: لا عبوة تحت Qn − 2T", "Rule: no package below Qn − 2T"))}</span></label>
        <div class="full"><span class="lbl req" id="nw-s-l">${esc(W("الأوزان الإجمالية للعينات (مع العبوة)", "Sample gross weights (with packaging)"))}</span>
          <div id="nwRows" class="pc-samples" role="group" aria-labelledby="nw-s-l"></div>
          <div class="row" style="margin-top:8px">${btn("nwAdd", I.plus, W("أضف صفًا", "Add row"), "btn-ghost btn-sm")}<span class="chip" id="nwCnt"></span></div>
          <details class="faq" style="margin-top:10px"><summary>${esc(W("لصق عمود من جدول بيانات", "Paste a column from a spreadsheet"))}</summary>
            <div class="field" style="padding:0 0 14px"><label for="nw-paste">${esc(W("قيمة في كل سطر", "One value per line"))}</label><textarea id="nw-paste" rows="4" dir="ltr"></textarea><span class="err" id="nw-paste-e"></span>
            <div class="row">${btn("nwPasteAdd", I.plus, W("أضف إلى الصفوف", "Add to rows"), "btn-ghost btn-sm")}${btn("nwPasteRep", I.note, W("استبدل الصفوف", "Replace rows"), "btn-ghost btn-sm")}</div></div></details>
          <span class="err" id="nwRows-e"></span></div>
      </div>
      <div class="row" style="margin-top:18px">${btn("nwSave", I.check, W("احسب واحفظ", "Calculate & save"), "btn-gold", "submit")}${btn("nwCalc", I.calc, W("احسب فقط", "Calculate only"))}${btn("nwPrint", I.printer, t("print"))}${btn("nwNew", I.plus, t("newRec"), "btn-ghost btn-sm")}<span class="err" id="nwErr" role="alert"></span></div>
    </form>
    <div class="card" id="nwRes" aria-live="polite" style="margin-top:18px"><h3>${esc(W("النتيجة", "Result"))}</h3><p class="note" style="margin:0">${esc(W("أدخل البيانات والأوزان ثم اضغط احسب.", "Enter the details and weights, then press calculate."))}</p></div>
    <div class="card" style="margin-top:18px"><h3>${esc(W("المعادلات وملاحظة مرجعية", "Formulas and reference note"))}</h3>
      ${formula("netᵢ = grossᵢ − tare<br>x̄ = Σ netᵢ ÷ n &nbsp;·&nbsp; s = √( Σ (netᵢ − x̄)² ÷ (n − 1) )<br>T1 defective: netᵢ &lt; Qn − T &nbsp;·&nbsp; T2 defective: netᵢ &lt; Qn − 2T<br>pass = x̄ ≥ Qn − k·s (k = 0 if blank) AND n(T1) ≤ allowed [AND n(T2) = 0]")}
      <p class="note">${esc(W("مرجع للاستخدام فقط: توصية OIML R 87 «كمية المنتج في العبوات المعبأة مسبقًا»، وفي أوروبا التوجيه 76/211/EEC (علامة ℮)، تتضمن جداول للخطأ السالب المسموح حسب الكمية الاسمية وخطط معاينة. الأداة لا تتضمن هذه الجداول ولا تحدد قيمة قانونية؛ ابحث عن T وعدد العيوب المسموح لكمّيتك في الإصدار المطبّق لديك وأدخلهما بنفسك.", "Reference only: OIML R 87 “Quantity of product in prepackages” and, in Europe, Directive 76/211/EEC (the ℮-mark) give tables of tolerable negative errors by nominal quantity and sampling plans. The tool contains no such table and sets no legal value; look up T and the allowed defective count for your quantity in the edition that applies to you and enter them yourself."))}</p></div>
    ${recHead(RK, btn("nwCsvAll", I.download, t("exportCsv"), "btn-ghost btn-sm"))}
    </div></section>`;
  function after() {
    const form = $("#nwForm");
    const drawRows = () => {
      $("#nwRows").innerHTML = samples.map((v, i) => `<div class="pc-s"><label for="nw-s-${i}">#${i + 1}</label><input id="nw-s-${i}" data-i="${i}" type="number" inputmode="decimal" step="any" value="${esc(v)}"><button type="button" class="pc-x" data-rm="${i}" aria-label="${esc(`${t("del")} #${i + 1}`)}">×</button></div>`).join("");
      $("#nwCnt").textContent = `n = ${samples.filter((x) => x !== "").length}`;
    };
    $("#nwRows").addEventListener("input", (e) => { const el = e.target.closest("[data-i]"); if (el) { samples[+el.dataset.i] = el.value; $("#nwCnt").textContent = `n = ${samples.filter((x) => x !== "").length}`; } });
    $("#nwRows").addEventListener("click", (e) => { const b = e.target.closest("[data-rm]"); if (b) { samples.splice(+b.dataset.rm, 1); if (!samples.length) samples.push(""); drawRows(); } });
    $("#nwRows").addEventListener("keydown", (e) => { const el = e.target.closest("[data-i]"); if (el && e.key === "Enter") { e.preventDefault(); const i = +el.dataset.i; if (i === samples.length - 1) { samples.push(""); drawRows(); } $("#nw-s-" + (i + 1)).focus(); } });
    $("#nwAdd").addEventListener("click", () => { samples.push(""); drawRows(); $("#nw-s-" + (samples.length - 1)).focus(); });
    const paste = (replace) => {
      const vals = parseNums($("#nw-paste").value), bad = vals.filter((x) => !isFinite(x));
      if (!vals.length || bad.length) { setErr("nw-paste", !vals.length ? t("required") : W(`قيم غير رقمية: ${bad.slice(0, 3).join("، ")}`, `Non-numeric values: ${bad.slice(0, 3).join(", ")}`)); return; }
      setErr("nw-paste", ""); const keep = replace ? [] : samples.filter((x) => x !== ""); samples = keep.concat(vals); drawRows(); $("#nw-paste").value = ""; toast(W(`أضيفت ${vals.length} قيمة`, `${vals.length} values added`));
    };
    $("#nwPasteAdd").addEventListener("click", () => paste(false));
    $("#nwPasteRep").addEventListener("click", () => paste(true));
    const read = () => ({ prod: val("nw-prod"), lot: val("nw-lot"), date: val("nw-date"), unit: $("#nw-unit").value, qn: nval("nw-qn"), tare: nval("nw-tare"), T: nval("nw-T"), allowed: nval("nw-allow"), k: nval("nw-k"), t2rule: $("#nw-t2").checked, samples: samples.filter((x) => String(x).trim() !== "").map(Number) });
    const validate = (r) => {
      clearErrs(form);
      let ok = setErr("nw-prod", r.prod ? "" : t("required"));
      ok = setErr("nw-qn", r.qn === "" ? t("required") : !(r.qn > 0) ? MSG.pos() : "") && ok;
      ok = setErr("nw-tare", r.tare === "" ? t("required") : !(r.tare >= 0) ? MSG.nonneg() : "") && ok;
      ok = setErr("nw-T", r.T === "" ? t("required") : !(r.T > 0) ? MSG.pos() : r.qn > 0 && r.T >= r.qn ? W("T يجب أن يكون أصغر من Qn.", "T must be smaller than Qn.") : "") && ok;
      ok = setErr("nw-allow", r.allowed === "" ? t("required") : !(Number.isInteger(r.allowed) && r.allowed >= 0) ? MSG.int() : "") && ok;
      ok = setErr("nw-k", r.k !== "" && !(r.k >= 0) ? MSG.nonneg() : "") && ok;
      let msg = "";
      if (r.samples.length < 2) msg = W("أدخل وزنين على الأقل.", "Enter at least two weights.");
      samples.forEach((x, i) => { const bad = String(x).trim() !== "" && (!isFinite(x) || !(+x > 0)); const el = $("#nw-s-" + i); if (el) el.setAttribute("aria-invalid", bad ? "true" : "false"); if (bad) msg = W(`الصف #${i + 1}: أدخل وزنًا أكبر من صفر.`, `Row #${i + 1}: enter a weight above zero.`); });
      if (!msg && r.tare !== "" && r.samples.some((g) => g <= r.tare)) msg = W("بعض الأوزان الإجمالية لا تزيد على التارة — تحقق من الوحدة أو التارة.", "Some gross weights are not above the tare — check the unit or tare.");
      if (!msg && r.allowed > r.samples.length) ok = setErr("nw-allow", W("أكبر من عدد العينات.", "Larger than the number of samples.")) && false;
      $("#nwRows-e").textContent = msg; if (msg) ok = false;
      $("#nwErr").textContent = ok ? "" : t("fixErrors"); if (!ok) focusBad(form);
      return ok;
    };
    const u = (r) => esc(r.unit);
    const resHtml = (r, s) => `<div class="row" style="margin-bottom:12px"><h3 style="margin:0">${esc(W("النتيجة", "Result"))}</h3><span class="spacer"></span><span class="chip ${s.pass ? "ok" : "bad"}" id="nwVerdict" style="font-size:14px">${esc(s.pass ? W("مطابق لقواعدك", "Passes your rules") : W("غير مطابق لقواعدك", "Fails your rules"))}</span></div>
      <div class="pc-stats">${[["n", s.n], [W("المتوسط", "Mean"), fix(s.mean, 3)], ["SD (s)", fix(s.sd, 3)], [W("الأدنى", "Min"), fix(s.min, 3)], [W("الأعلى", "Max"), fix(s.max, 3)], [W("تحت Qn", "Below Qn"), s.below], [W("تحت Qn − T", "Below Qn − T"), s.def1], [W("تحت Qn − 2T", "Below Qn − 2T"), s.def2]].map(([k, v], i) => `<div><span>${esc(k)}</span><b dir="ltr" data-st="${i}">${v}</b></div>`).join("")}</div>
      <p class="note" dir="ltr" style="text-align:start">Qn = ${fix(r.qn, 3)} ${u(r)} · tare = ${fix(r.tare, 3)} · T = ${fix(r.T, 3)} → Qn − T = ${fix(s.t1, 3)} · Qn − 2T = ${fix(s.t2, 3)} ${u(r)}</p>
      <ul class="pc-rules">${s.rules.map((x) => `<li class="${x.ok ? "ok" : "bad"}" data-rule="${x.id}">${x.ok ? I.check : I.alert}<span dir="ltr">${esc(x.txt)}</span></li>`).join("")}</ul>
      <div class="pc-histwrap">${histSvg(r, s)}</div>
      <details class="faq"><summary>${esc(W("الأوزان الصافية", "Net weights"))}</summary><div class="table-wrap"><table class="t" style="min-width:0"><thead><tr><th>#</th><th>${esc(W("إجمالي", "Gross"))}</th><th>${esc(W("صافٍ", "Net"))}</th><th>${esc(W("الحالة", "Status"))}</th></tr></thead><tbody>${s.net.map((x, i) => `<tr><td>${i + 1}</td><td dir="ltr">${fix(r.samples[i], 3)}</td><td dir="ltr">${fix(x, 3)}</td><td>${x < s.t2 ? `<span class="chip bad">&lt; Qn−2T</span>` : x < s.t1 ? `<span class="chip bad">&lt; Qn−T</span>` : x < r.qn ? `<span class="chip warn">&lt; Qn</span>` : `<span class="chip ok">≥ Qn</span>`}</td></tr>`).join("")}</tbody></table></div></details>`;
    const compute = () => { const r = read(); if (!validate(r)) return null; const s = nwStats(r); r.out = { n: s.n, mean: s.mean, sd: s.sd, min: s.min, def1: s.def1, def2: s.def2, below: s.below, pass: s.pass }; $("#nwRes").innerHTML = resHtml(r, s); return r; };
    const printRec = (r) => { const s = nwStats(r); printHtml(`${L(tool("netweight").t)} — ${r.prod}${r.lot ? " / " + r.lot : ""}`, kvTable([[W("المنتج", "Product"), esc(r.prod)], [W("الدفعة", "Batch"), esc(r.lot)], [W("التاريخ", "Date"), esc(r.date)], ["Qn / T / tare", `<span dir="ltr">${fix(r.qn, 3)} / ${fix(r.T, 3)} / ${fix(r.tare, 3)} ${esc(r.unit)}</span>`], [W("المسموح تحت Qn − T", "Allowed below Qn − T"), r.allowed]]) + `<div style="color:#111">${resHtml(r, s).replace(/<details class="faq">/, '<details open class="faq">')}</div>`); };
    const reset = (r) => {
      editing = r ? r.id : null; r = r || {};
      $("#nw-prod").value = r.prod || ""; $("#nw-lot").value = r.lot || ""; $("#nw-date").value = r.date || new Date().toISOString().slice(0, 10); $("#nw-unit").value = r.unit || "g";
      ["qn", "tare", "T", "k"].forEach((k) => ($("#nw-" + k).value = r[k] == null ? "" : r[k])); $("#nw-allow").value = r.allowed == null ? "" : r.allowed; $("#nw-t2").checked = !!r.t2rule;
      samples = r.samples && r.samples.length ? r.samples.map(String) : [""]; drawRows(); clearErrs(form);
      $("#nwTitle").textContent = r.id ? `${t("edit")} — ${r.prod}` : t("newRec");
    };
    const csvOf = (r) => { const s = nwStats(r); return [["product", "lot", "date", "unit", "Qn", "tare", "T", "#", "gross", "net", "below_Qn", "below_Qn-T", "below_Qn-2T"], ...s.net.map((x, i) => [r.prod, r.lot, r.date, r.unit, r.qn, r.tare, r.T, i + 1, r.samples[i], +x.toFixed(6), x < r.qn ? 1 : 0, x < s.t1 ? 1 : 0, x < s.t2 ? 1 : 0])]; };
    const draw = recList($("#tool-netweight-list"), RK, [[W("المنتج", "Product"), (r) => esc(r.prod)], [W("الدفعة", "Batch"), (r) => esc(r.lot)], ["n", (r) => (r.out ? r.out.n : "")], [W("المتوسط", "Mean"), (r) => (r.out ? `<span dir="ltr">${fix(r.out.mean, 2)} ${esc(r.unit)}</span>` : "")], [W("الحكم", "Verdict"), (r) => (r.out ? `<span class="chip ${r.out.pass ? "ok" : "bad"}">${esc(r.out.pass ? W("مطابق", "Pass") : W("غير مطابق", "Fail"))}</span>` : "")], [W("التاريخ", "Date"), (r) => esc(r.date)]],
      { edit: (r) => { reset(r); compute(); A.scrollTo(form, true); }, print: printRec, deleted: (id) => { if (editing === id) reset(null); } });
    $("#nwCalc").addEventListener("click", compute);
    $("#nwPrint").addEventListener("click", () => { const r = compute(); if (r) printRec(r); });
    $("#nwNew").addEventListener("click", () => { reset(null); $("#nwRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3>`; });
    $("#nwCsvAll").addEventListener("click", () => { const all = store.get(RK, []); if (!all.length) { toast(t("none"), "bad"); return; } const rows = []; all.forEach((r, i) => { const c = csvOf(r); rows.push(...(i ? c.slice(1) : c)); }); download(`netweight-${new Date().toISOString().slice(0, 10)}.csv`, csv(rows), "text/csv;charset=utf-8"); });
    form.addEventListener("submit", (e) => { e.preventDefault(); const r = compute(); if (!r) return; if (saveRec(RK, r, editing)) { toast(t("saved")); editing = r.id; $("#nwTitle").textContent = `${t("edit")} — ${r.prod}`; draw(); } });
    reset(null);
  }
  return { title: L(tool("netweight").t), html, after };
}

/* =====================================================================
   4) Recipe scaling & costing
   ===================================================================== */
const UNITS_ING = () => [["g", "g"], ["kg", "kg"], ["mL", "mL"], ["L", "L"], ["pc", W("حبة", "pc")]];
function scaleCalc(r) {
  const f = r.mode === "w" ? r.targetW / r.baseW : r.target / r.base, portions = r.mode === "w" ? r.base * f : r.target;
  let batch = 0, missing = 0;
  const rows = r.ing.map((x) => { const q = +x.qty * f, has = x.price !== "" && x.pack !== "" && +x.pack > 0; const cost = has ? (q * +x.price) / +x.pack : null; if (has) batch += cost; else missing++; return { ...x, q, cost, unitCost: has ? +x.price / +x.pack : null }; });
  const perPortion = portions > 0 ? batch / portions : 0, fc = isNum(r.sell) && +r.sell > 0 ? (perPortion / +r.sell) * 100 : null;
  return { f, portions, rows, batch, perPortion, fc, missing };
}
const qtyTxt = (q, unit) => { const big = (unit === "g" || unit === "mL") && q >= 1000; return `${num(q, q < 10 ? 2 : 1)} ${unit}${big ? ` <small>(= ${num(q / 1000, 3)} ${unit === "g" ? "kg" : "L"})</small>` : ""}`; };
function scalePage() {
  const RK = "tool:scale", ing = []; let editing = null;
  const blank = () => ({ name: "", qty: "", unit: "g", price: "", pack: "" });
  const recs = recipes();
  const html = `${head("scale")}
    <form class="card" id="scForm" novalidate style="margin-top:18px"><h2 style="font-size:20px" id="scTitle">${esc(t("newRec"))}</h2>
      ${recs.length ? `<div class="row pc-import"><label for="sc-rec" class="lbl">${esc(W("استيراد المكونات من وصفة محفوظة", "Import ingredients from a saved recipe"))}</label><select id="sc-rec" style="max-width:280px">${recs.map((r) => `<option value="${esc(r.id)}">${esc(r.name)}</option>`).join("")}</select>${btn("scImp", I.download, W("استيراد", "Import"), "btn-ghost btn-sm")}</div>` : `<p class="note" style="margin-top:0">${esc(W("يمكنك استيراد المكونات من وصفة محفوظة في", "You can import ingredients from a recipe saved in the"))} <a href="#/tools/nutrition">${esc(L(tool("nutrition") ? tool("nutrition").t : { ar: "حاسبة القيم الغذائية", en: "nutrition calculator" }))}</a>.</p>`}
      <div class="form">
        ${fld("sc-name", W("اسم الوصفة", "Recipe name"), inp("sc-name", "text", "", 'maxlength="80"'), { req: true })}
        ${fld("sc-cur", W("العملة", "Currency"), inp("sc-cur", "text", "", `maxlength="8" placeholder="${esc(W("مثال: SAR", "e.g. SAR"))}"`))}
        ${fld("sc-base", W("الناتج الأساسي (عدد الحصص)", "Base yield (portions)"), inp("sc-base", "number", "", 'min="0"'), { req: true })}
        <div class="field"><label for="sc-mode">${esc(W("التحجيم حسب", "Scale by"))}</label>${sel("sc-mode", [["p", W("عدد الحصص المستهدف", "Target portions")], ["w", W("وزن الدفعة المستهدف", "Target batch weight")]], "p")}</div>
        ${fld("sc-target", W("عدد الحصص المستهدف", "Target portions"), inp("sc-target", "number", "", 'min="0"'), { req: true })}
        <div class="field" data-w hidden><label for="sc-baseW" class="req">${esc(W("وزن الدفعة الأساسية", "Base batch weight"))}</label>${inp("sc-baseW", "number", "", 'min="0"')}<span class="hint">${esc(W("الوزن النهائي للوصفة الأساسية (أي وحدة، نفسها للهدف).", "Finished weight of the base recipe (any unit, same as target)."))}</span><span class="err" id="sc-baseW-e"></span></div>
        ${fld("sc-sell", W("سعر البيع للحصة (اختياري)", "Selling price per portion (optional)"), inp("sc-sell", "number", "", 'min="0"'), { hint: W("لحساب نسبة تكلفة الطعام. أدخل السعر بنفس أساس التكلفة (مثلًا دون ضريبة).", "Used for food-cost %. Enter it on the same basis as the cost (e.g. excluding VAT).") })}
        <div class="full"><span class="lbl req">${esc(W("المكونات (للناتج الأساسي)", "Ingredients (for the base yield)"))}</span>
          <p class="note" style="margin:4px 0 8px">${esc(W("سعر العبوة وحجمها بنفس وحدة الكمية (مثلًا كيس 25000 غ بسعر 100). اتركهما فارغين إذا لم تكن التكلفة مطلوبة.", "Pack price and pack size in the same unit as the quantity (e.g. a 25000 g bag at 100). Leave blank if cost isn't needed."))}</p>
          <div id="scIng"></div><span class="err" id="scIng-e"></span></div>
      </div>
      <div class="row" style="margin-top:18px">${btn("scSave", I.check, W("احسب واحفظ", "Calculate & save"), "btn-gold", "submit")}${btn("scCalc", I.calc, W("احسب فقط", "Calculate only"))}${btn("scPrint", I.printer, t("print"))}${btn("scCsv", I.download, "CSV", "btn-ghost btn-sm")}${btn("scNew", I.plus, t("newRec"), "btn-ghost btn-sm")}<span class="err" id="scErr" role="alert"></span></div>
    </form>
    <div class="card" id="scRes" aria-live="polite" style="margin-top:18px"><h3>${esc(W("النتيجة", "Result"))}</h3><p class="note" style="margin:0">${esc(W("أدخل الوصفة ثم اضغط احسب.", "Enter the recipe, then press calculate."))}</p></div>
    <div class="card" style="margin-top:18px"><h3>${esc(W("المعادلات", "Formulas"))}</h3>
      ${formula("factor f = target portions ÷ base portions &nbsp;(or target weight ÷ base weight)<br>scaled qty = qty × f<br>ingredient cost = scaled qty × pack price ÷ pack size<br>cost per portion = Σ cost ÷ portions<br>food cost % = cost per portion ÷ selling price × 100")}
      <p class="note">${esc(W("التحجيم الخطي لا يناسب دائمًا التوابل والمواد الرافعة وأزمنة الطهي؛ اختبر الدفعة الكبيرة قبل الإنتاج. الأسعار والنسب المستهدفة قرارك.", "Linear scaling doesn't always suit spices, leaveners and cooking times; trial the large batch before production. Prices and target percentages are your decision."))}</p></div>
    ${recHead(RK)}
    </div></section>`;
  function after() {
    const form = $("#scForm");
    const cols = [{ k: "name", l: W("المكوّن", "Ingredient"), w: 130 }, { k: "qty", l: W("الكمية", "Quantity"), type: "number", w: 80 }, { k: "unit", l: W("الوحدة", "Unit"), type: "select", opts: UNITS_ING }, { k: "price", l: W("سعر العبوة", "Pack price"), type: "number", w: 80 }, { k: "pack", l: W("حجم العبوة", "Pack size"), type: "number", w: 80 }];
    const g = grid($("#scIng"), ing, cols, { id: "si", min: 1, minW: 620, blank, addLabel: W("أضف مكوّنًا", "Add ingredient") });
    const modeSw = () => { const w = $("#sc-mode").value === "w"; $("[data-w]", form).hidden = !w; $("label[for=sc-target]").textContent = w ? W("وزن الدفعة المستهدف", "Target batch weight") : W("عدد الحصص المستهدف", "Target portions"); };
    $("#sc-mode").addEventListener("change", modeSw);
    const read = () => ({ name: val("sc-name"), cur: val("sc-cur"), base: nval("sc-base"), mode: $("#sc-mode").value, target: $("#sc-mode").value === "p" ? nval("sc-target") : "", targetW: $("#sc-mode").value === "w" ? nval("sc-target") : "", baseW: nval("sc-baseW"), sell: nval("sc-sell"), ing: ing.map((x) => ({ ...x })) });
    const validate = (r) => {
      clearErrs(form);
      let ok = setErr("sc-name", r.name ? "" : t("required"));
      ok = setErr("sc-base", r.base === "" ? t("required") : !(r.base > 0) ? MSG.pos() : "") && ok;
      const tv = r.mode === "w" ? r.targetW : r.target;
      ok = setErr("sc-target", tv === "" ? t("required") : !(tv > 0) ? MSG.pos() : "") && ok;
      if (r.mode === "w") ok = setErr("sc-baseW", r.baseW === "" ? t("required") : !(r.baseW > 0) ? MSG.pos() : "") && ok;
      ok = setErr("sc-sell", r.sell !== "" && !(r.sell > 0) ? W("أكبر من صفر أو فارغ.", "Above zero or blank.") : "") && ok;
      let msg = "";
      r.ing.forEach((x, i) => {
        const bn = !String(x.name).trim(), bq = !(+x.qty > 0); g.mark(i, "name", bn); g.mark(i, "qty", bq);
        if (bn || bq) msg = W(`أدخل اسم المكوّن ${i + 1} وكميته (أكبر من صفر).`, `Enter a name and a quantity above zero for ingredient ${i + 1}.`);
        const bp = x.price !== "" && !(+x.price >= 0), bs = x.pack !== "" && !(+x.pack > 0), half = (x.price === "") !== (x.pack === "");
        g.mark(i, "price", bp || (half && x.price === "")); g.mark(i, "pack", bs || (half && x.pack === ""));
        if (bp || bs) msg = W(`المكوّن ${i + 1}: السعر لا يكون سالبًا وحجم العبوة أكبر من صفر.`, `Ingredient ${i + 1}: price can't be negative and pack size must be above zero.`);
        else if (half) msg = W(`المكوّن ${i + 1}: أدخل سعر العبوة وحجمها معًا أو اتركهما فارغين.`, `Ingredient ${i + 1}: enter both pack price and pack size, or leave both blank.`);
      });
      $("#scIng-e").textContent = msg; if (msg) ok = false;
      $("#scErr").textContent = ok ? "" : t("fixErrors"); if (!ok) focusBad(form);
      return ok;
    };
    const money = (v, r) => (v == null ? "—" : `${num(v, 2)}${r.cur ? " " + esc(r.cur) : ""}`);
    const resHtml = (r, o) => `<h3>${esc(W("النتيجة", "Result"))}</h3>
      <div class="pc-stats"><div><span>${esc(W("المعامل f", "Factor f"))}</span><b dir="ltr" id="scF">${fix(o.f, 4).replace(/\.?0+$/, "")}</b></div><div><span>${esc(W("الحصص", "Portions"))}</span><b dir="ltr" id="scP">${num(o.portions, 1)}</b></div><div><span>${esc(W("تكلفة الدفعة", "Batch cost"))}</span><b dir="ltr" id="scB">${money(o.batch, r)}</b></div><div><span>${esc(W("تكلفة الحصة", "Cost per portion"))}</span><b dir="ltr" id="scPP">${money(o.perPortion, r)}</b></div>${o.fc != null ? `<div><span>${esc(W("نسبة تكلفة الطعام", "Food cost %"))}</span><b dir="ltr" id="scFC">${fix(o.fc, 1)}%</b></div>` : ""}</div>
      ${o.missing ? `<p class="note" style="color:#f5c06e">${esc(W(`${o.missing} مكوّن بلا سعر — التكلفة لا تشملها.`, `${o.missing} ingredient(s) without a price — not included in the cost.`))}</p>` : ""}
      <div class="table-wrap" style="margin-top:10px"><table class="t" style="min-width:520px"><thead><tr><th>${esc(W("المكوّن", "Ingredient"))}</th><th>${esc(W("الأساس", "Base"))}</th><th>${esc(W("بعد التحجيم", "Scaled"))}</th><th>${esc(W("سعر الوحدة", "Unit price"))}</th><th>${esc(W("التكلفة", "Cost"))}</th></tr></thead><tbody>${o.rows.map((x) => `<tr><td>${esc(x.name)}</td><td dir="ltr">${num(x.qty, 2)} ${esc(x.unit)}</td><td dir="ltr"><b>${qtyTxt(x.q, esc(x.unit))}</b></td><td dir="ltr">${x.unitCost == null ? "—" : `${num(x.unitCost, 4)} / ${esc(x.unit)}`}</td><td dir="ltr">${money(x.cost, r)}</td></tr>`).join("")}</tbody></table></div>
      <p class="note" dir="ltr" style="text-align:start">f = ${r.mode === "w" ? `${fix(r.targetW, 2)} ÷ ${fix(r.baseW, 2)}` : `${fix(r.target, 2)} ÷ ${fix(r.base, 2)}`} = ${fix(o.f, 4)} · ${fix(o.batch, 2)} ÷ ${fix(o.portions, 2)} = ${fix(o.perPortion, 4)}${o.fc != null ? ` · ${fix(o.perPortion, 4)} ÷ ${fix(r.sell, 2)} × 100 = ${fix(o.fc, 1)}%` : ""}</p>`;
    const compute = () => { const r = read(); if (!validate(r)) return null; const o = scaleCalc(r); r.out = { f: o.f, portions: o.portions, batch: o.batch, perPortion: o.perPortion, fc: o.fc }; $("#scRes").innerHTML = resHtml(r, o); return r; };
    const printRec = (r) => printHtml(`${L(tool("scale").t)} — ${r.name}`, `<div style="color:#111">${resHtml(r, scaleCalc(r))}</div>`);
    const csvRec = (r) => { const o = scaleCalc(r); download(`scale-${safeName(r.name)}.csv`, csv([["recipe", "base_portions", "factor", "portions", "ingredient", "qty", "unit", "scaled_qty", "pack_price", "pack_size", "cost", "currency"], ...o.rows.map((x) => [r.name, r.base, +o.f.toFixed(6), +o.portions.toFixed(3), x.name, x.qty, x.unit, +x.q.toFixed(4), x.price, x.pack, x.cost == null ? "" : +x.cost.toFixed(4), r.cur]), ["", "", "", "", "TOTAL", "", "", "", "", "", +o.batch.toFixed(4), r.cur], ["", "", "", "", "PER PORTION", "", "", "", "", "", +o.perPortion.toFixed(4), r.cur]].concat(o.fc != null ? [["", "", "", "", "FOOD COST %", "", "", "", "", "", +o.fc.toFixed(2), ""]] : [])), "text/csv;charset=utf-8"); };
    const reset = (r) => {
      editing = r ? r.id : null; r = r || { mode: "p" };
      $("#sc-name").value = r.name || ""; $("#sc-cur").value = r.cur || ""; $("#sc-base").value = r.base == null ? "" : r.base; $("#sc-mode").value = r.mode || "p";
      $("#sc-target").value = r.mode === "w" ? (r.targetW == null ? "" : r.targetW) : (r.target == null ? "" : r.target); $("#sc-baseW").value = r.baseW == null ? "" : r.baseW; $("#sc-sell").value = r.sell == null ? "" : r.sell;
      g.set(r.ing && r.ing.length ? r.ing : [blank(), blank()]); modeSw(); clearErrs(form);
      $("#scTitle").textContent = r.id ? `${t("edit")} — ${r.name}` : t("newRec");
    };
    const draw = recList($("#tool-scale-list"), RK, [[W("الوصفة", "Recipe"), (r) => esc(r.name)], [W("الحصص", "Portions"), (r) => (r.out ? `<span dir="ltr">${num(r.base, 1)} → ${num(r.out.portions, 1)}</span>` : "")], [W("تكلفة الحصة", "Cost / portion"), (r) => (r.out ? `<span dir="ltr">${num(r.out.perPortion, 2)} ${esc(r.cur)}</span>` : "")], [W("تكلفة الطعام", "Food cost"), (r) => (r.out && r.out.fc != null ? `<span dir="ltr">${fix(r.out.fc, 1)}%</span>` : "—")], [W("التاريخ", "Date"), recDate]],
      { edit: (r) => { reset(r); compute(); A.scrollTo(form, true); }, print: printRec, deleted: (id) => { if (editing === id) reset(null); } });
    $("#scImp") && $("#scImp").addEventListener("click", () => {
      const rec = recipes().find((x) => x.id === $("#sc-rec").value); if (!rec) return;
      g.set(rec.ing.map((x) => ({ name: x.name || "", qty: x.w === "" ? "" : +x.w, unit: "g", price: "", pack: "" })));
      if (!val("sc-name")) $("#sc-name").value = rec.name || "";
      const n = rec.mode === "n" ? +rec.sv : rec.out && rec.sv > 0 ? Math.round((rec.out.final / rec.sv) * 100) / 100 : "";
      if (n > 0) $("#sc-base").value = n;
      toast(W(`استُورد ${rec.ing.length} مكوّن — أضف الأسعار`, `${rec.ing.length} ingredients imported — add the prices`));
    });
    $("#scCalc").addEventListener("click", compute);
    $("#scPrint").addEventListener("click", () => { const r = compute(); if (r) printRec(r); });
    $("#scCsv").addEventListener("click", () => { const r = compute(); if (r) csvRec(r); });
    $("#scNew").addEventListener("click", () => { reset(null); $("#scRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3>`; });
    form.addEventListener("submit", (e) => { e.preventDefault(); const r = compute(); if (!r) return; if (saveRec(RK, r, editing)) { toast(t("saved")); editing = r.id; $("#scTitle").textContent = `${t("edit")} — ${r.name}`; draw(); } });
    reset(null);
  }
  return { title: L(tool("scale").t), html, after };
}

/* =====================================================================
   5) Customer product card via QR (data lives in the URL hash)
   ===================================================================== */
const ALG = [["gluten", "الحبوب المحتوية على الغلوتين", "Cereals containing gluten"], ["crust", "القشريات", "Crustaceans"], ["egg", "البيض", "Eggs"], ["fish", "الأسماك", "Fish"], ["peanut", "الفول السوداني", "Peanuts"], ["soy", "فول الصويا", "Soybeans"], ["milk", "الحليب", "Milk"], ["nuts", "المكسرات", "Tree nuts"], ["sesame", "السمسم", "Sesame"], ["sulphite", "الكبريتيت", "Sulphites"], ["mustard", "الخردل", "Mustard"], ["celery", "الكرفس", "Celery"], ["lupin", "الترمس", "Lupin"], ["mollusc", "الرخويات", "Molluscs"]];
const PC_MAX = 1800, PC_STR = 1500;
const b64u = (bytes) => { let s = ""; for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000)); return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, ""); };
const unb64u = (s) => { const b = atob(s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4)); const u = new Uint8Array(b.length); for (let i = 0; i < b.length; i++) u[i] = b.charCodeAt(i); return u; };
const streamBytes = async (bytes, ts) => new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(ts)).arrayBuffer());
async function packCard(obj) {
  const raw = new TextEncoder().encode(JSON.stringify(obj));
  let out = "0" + b64u(raw);
  if (window.CompressionStream) { try { const z = "1" + b64u(await streamBytes(raw, new CompressionStream("deflate-raw"))); if (z.length < out.length) out = z; } catch (_) { /* keep plain */ } }
  return out;
}
async function unpackCard(s) {
  if (typeof s !== "string" || s.length < 2 || s.length > 12000 || !/^[01][A-Za-z0-9_-]+$/.test(s)) throw new Error("format");
  let bytes = unb64u(s.slice(1));
  if (s[0] === "1") { if (!window.DecompressionStream) throw new Error("support"); bytes = await streamBytes(bytes, new DecompressionStream("deflate-raw")); }
  if (bytes.length > 200000) throw new Error("size");
  return cleanCard(JSON.parse(new TextDecoder().decode(bytes)));
}
// untrusted input → plain object with strings / numbers of bounded size only
function cleanCard(o) {
  if (!o || typeof o !== "object" || Array.isArray(o)) throw new Error("shape");
  const str = (v) => (typeof v === "string" || typeof v === "number" ? String(v).slice(0, PC_STR) : "");
  const pair = (v) => (Array.isArray(v) ? [str(v[0]), str(v[1])] : ["", ""]);
  const nums = (v) => (Array.isArray(v) ? NUT_KEYS.map((_, i) => (v[i] === null || v[i] === "" || v[i] == null || !isFinite(v[i]) ? null : Math.max(0, Math.min(1e6, Number(v[i]))))) : NUT_KEYS.map(() => null));
  const c = { n: pair(o.n), d: pair(o.d), i: pair(o.i), s: pair(o.s), a: Array.isArray(o.a) ? o.a.filter((x) => ALG.some((g) => g[0] === x)) : [], ao: str(o.ao), mc: str(o.mc), c: str(o.c), lot: str(o.lot) };
  if (o.nu && typeof o.nu === "object") c.nu = { sw: isFinite(o.nu.sw) && +o.nu.sw > 0 ? Math.min(1e5, +o.nu.sw) : null, p: nums(o.nu.p), q: nums(o.nu.q) };
  if (!c.n[0] && !c.n[1]) throw new Error("empty");
  return c;
}
const pcBase = () => { const base = location.protocol === "http:" || location.protocol === "https:" ? location.origin + location.pathname : "https://aladeen35.github.io/test/alaeldeen/"; return base.replace(/index\.html$/, ""); };
const biBlock = (pair, cls) => `${pair[0] ? `<p class="${cls || ""}" lang="ar" dir="rtl">${esc(pair[0]).replace(/\n/g, "<br>")}</p>` : ""}${pair[1] ? `<p class="${cls || ""}" lang="en" dir="ltr">${esc(pair[1]).replace(/\n/g, "<br>")}</p>` : ""}`;
const biH = (ar, en) => `<h2 class="pp-h"><span lang="ar">${ar}</span> <span class="np-sep">|</span> <span lang="en">${en}</span></h2>`;
const contactHtml = (c) => {
  if (!c) return "";
  return c.split(/\n/).map((line) => { const s = line.trim(); if (!s) return ""; let href = "";
    if (/^\+?[0-9][0-9 ()-]{5,20}$/.test(s)) href = "tel:" + s.replace(/[^0-9+]/g, "");
    else if (/^[^\s@<>"']+@[^\s@<>"']+\.[a-z]{2,}$/i.test(s)) href = "mailto:" + s;
    else if (/^https:\/\/[^\s<>"']+$/i.test(s)) href = s;
    return `<li dir="auto">${href ? `<a href="${esc(href)}" rel="noopener nofollow" ${href.startsWith("https:") ? 'target="_blank"' : ""}>${esc(s)}</a>` : esc(s)}</li>`; }).join("");
};
function cardHtml(c) {
  const has = (p) => p && (p[0] || p[1]);
  const nuHas = c.nu && (c.nu.p.some((v) => v != null) || c.nu.q.some((v) => v != null));
  return `<article class="pp">
    <header class="pp-top">${c.n[0] ? `<h1 lang="ar" dir="rtl" tabindex="-1">${esc(c.n[0])}</h1>` : ""}${c.n[1] ? `<${c.n[0] ? "p" : "h1 tabindex=\"-1\""} class="pp-en" lang="en" dir="ltr">${esc(c.n[1])}</${c.n[0] ? "p" : "h1"}>` : ""}${c.lot ? `<span class="chip" dir="ltr">${esc(c.lot)}</span>` : ""}</header>
    ${has(c.d) ? `<section>${biBlock(c.d)}</section>` : ""}
    ${has(c.i) ? `<section>${biH("المكونات", "Ingredients")}${biBlock(c.i)}</section>` : ""}
    ${c.a.length || c.ao || c.mc ? `<section class="pp-alg" aria-label="Allergens">${biH("مسببات الحساسية", "Allergens")}${c.a.length || c.ao ? `<p class="pp-alg-t"><span lang="ar">يحتوي على</span> | <span lang="en">Contains</span>:</p><ul class="pp-chips">${c.a.map((k) => { const g = ALG.find((x) => x[0] === k); return `<li><b lang="ar">${esc(g[1])}</b> <span class="np-sep">|</span> <b lang="en">${esc(g[2])}</b></li>`; }).join("")}${c.ao ? `<li dir="auto"><b>${esc(c.ao)}</b></li>` : ""}</ul>` : ""}${c.mc ? `<p class="pp-may"><span lang="ar">قد يحتوي على</span> | <span lang="en">May contain</span>: <b dir="auto">${esc(c.mc)}</b></p>` : ""}</section>` : ""}
    ${nuHas ? `<section>${biH("القيم الغذائية", "Nutrition")}<div class="table-wrap"><table class="t pp-nut"><thead><tr><th></th>${c.nu.p.some((v) => v != null) ? `<th><span lang="ar">لكل 100 غ</span><br><span lang="en">Per 100 g</span></th>` : ""}${c.nu.q.some((v) => v != null) ? `<th><span lang="ar">لكل حصة</span><br><span lang="en">Per serving</span>${c.nu.sw ? ` <bdi dir="ltr">(${num(c.nu.sw, 0)} g)</bdi>` : ""}</th>` : ""}</tr></thead><tbody>${NUT_KEYS.map((k, i) => { const [a, e, u, d] = NUT_LAB[k]; if (c.nu.p[i] == null && c.nu.q[i] == null) return ""; const cell = (v) => `<td dir="ltr">${v == null ? "—" : `${num(v, d)} ${u}`}</td>`; return `<tr><th scope="row"><span lang="ar">${a}</span> <span class="np-sep">|</span> <span lang="en">${e}</span></th>${c.nu.p.some((v) => v != null) ? cell(c.nu.p[i]) : ""}${c.nu.q.some((v) => v != null) ? cell(c.nu.q[i]) : ""}</tr>`; }).join("")}</tbody></table></div></section>` : ""}
    ${has(c.s) ? `<section>${biH("التخزين", "Storage")}${biBlock(c.s)}</section>` : ""}
    ${c.c ? `<section>${biH("التواصل", "Contact")}<ul class="pp-contact">${contactHtml(c.c)}</ul></section>` : ""}
    <footer class="pp-foot"><p lang="ar" dir="rtl">المعلومات مقدمة من المنتِج ومحفوظة داخل الرابط نفسه؛ لا تُخزَّن على أي خادم. راجع ملصق العبوة دائمًا.</p><p lang="en" dir="ltr">Information provided by the producer and contained in the link itself; nothing is stored on a server. Always check the pack label.</p></footer>
  </article>`;
}
A.pages.product = (sub) => ({
  title: W("بطاقة المنتج", "Product card"),
  html: `<section class="sec"><div class="wrap pp-wrap" id="ppView" aria-live="polite"><p class="note">${esc(W("جارٍ فتح البطاقة…", "Opening the card…"))}</p></div></section>`,
  after: async () => {
    let html;
    try { const c = await unpackCard(sub || ""); html = cardHtml(c); document.title = `${c.n[A.lang === "ar" ? 0 : 1] || c.n[0] || c.n[1]} | ${W("بطاقة المنتج", "Product card")}`; }
    catch (e) { html = `<div class="empty"><h1 style="font-size:22px" tabindex="-1">${esc(W("تعذّر فتح بطاقة المنتج", "The product card couldn't be opened"))}</h1><p>${esc(W("الرابط غير مكتمل أو تالف، أو أن متصفحك لا يدعم فك الضغط. اطلب رابطًا جديدًا أو امسح رمز QR مرة أخرى.", "The link is incomplete or damaged, or your browser doesn't support decompression. Ask for a new link or scan the QR code again."))}</p></div>`; }
    const el = $("#ppView"); if (el) el.innerHTML = html;
  },
});
function prodCardPage() {
  const RK = "tool:prodcard"; let editing = null, lastName = "";
  const recs = recipes();
  const pairF = (k, ar, en, ta) => `${fld(`pc-${k}0`, `${ar} — ${W("عربي", "Arabic")}`, ta ? `<textarea id="pc-${k}0" rows="${ta}" dir="rtl" lang="ar" maxlength="${PC_STR}"></textarea>` : inp(`pc-${k}0`, "text", "", 'dir="rtl" lang="ar" maxlength="120"'))}${fld(`pc-${k}1`, `${en} — ${W("إنجليزي", "English")}`, ta ? `<textarea id="pc-${k}1" rows="${ta}" dir="ltr" lang="en" maxlength="${PC_STR}"></textarea>` : inp(`pc-${k}1`, "text", "", 'dir="ltr" lang="en" maxlength="120"'))}`;
  const html = `${head("prodcard")}
    <form class="card" id="pcForm" novalidate style="margin-top:18px"><h2 style="font-size:20px" id="pcTitle">${esc(t("newRec"))}</h2>
      <div class="form">
        ${pairF("n", W("اسم المنتج", "Product name"), W("اسم المنتج", "Product name"))}
        <span class="err full" id="pc-n-e"></span>
        ${pairF("d", W("الوصف", "Description"), W("الوصف", "Description"), 2)}
        ${pairF("i", W("المكونات", "Ingredients"), W("المكونات", "Ingredients"), 3)}
        <fieldset class="full"><legend class="lbl">${esc(W("مسببات الحساسية الموجودة في المنتج", "Allergens present in the product"))}</legend>
          <p class="note" style="margin:4px 0 8px">${esc(W("مجموعات شائعة للاختيار السريع؛ ما يجب التصريح به يحدده التشريع المطبّق لديك ومكونات منتجك.", "Common groups for quick selection; what must be declared depends on your regulation and your ingredients."))}</p>
          <div class="pc-algs">${ALG.map(([k, a, e]) => `<label><input type="checkbox" id="pc-al-${k}" value="${k}"> <span>${esc(W(a, e))}</span></label>`).join("")}</div></fieldset>
        ${fld("pc-ao", W("مسببات حساسية أخرى (اختياري)", "Other allergens (optional)"), inp("pc-ao", "text", "", 'maxlength="200"'))}
        ${fld("pc-mc", W("قد يحتوي على (اختياري)", "May contain (optional)"), inp("pc-mc", "text", "", 'maxlength="200"'))}
        ${pairF("s", W("التخزين", "Storage"), W("التخزين", "Storage"), 2)}
        ${fld("pc-lot", W("الدفعة / الإصدار (اختياري)", "Batch / version (optional)"), inp("pc-lot", "text", "", 'maxlength="40"'))}
        ${fld("pc-c", W("التواصل (سطر لكل وسيلة)", "Contact (one per line)"), `<textarea id="pc-c" rows="2" dir="auto" maxlength="300"></textarea>`, { hint: W("الهاتف والبريد وروابط https تصبح قابلة للنقر.", "Phone numbers, e-mails and https links become clickable.") })}
        <details class="faq full" id="pcNu"><summary>${esc(W("القيم الغذائية (اختياري)", "Nutrition (optional)"))}</summary>
          ${recs.length ? `<div class="row pc-import"><label for="pc-rec" class="lbl">${esc(W("استيراد من وصفة محفوظة", "Import from a saved recipe"))}</label><select id="pc-rec" style="max-width:280px">${recs.map((r) => `<option value="${esc(r.id)}">${esc(r.name)}</option>`).join("")}</select>${btn("pcImp", I.download, W("استيراد", "Import"), "btn-ghost btn-sm")}</div>` : ""}
          ${fld("pc-sw", W("حجم الحصة (غ)", "Serving size (g)"), inp("pc-sw", "number", "", 'min="0"'))}
          <div class="table-wrap" style="margin:10px 0 16px"><table class="t tc-grid" style="min-width:0"><thead><tr><th>${esc(W("العنصر", "Nutrient"))}</th><th>${esc(W("لكل 100 غ", "Per 100 g"))}</th><th>${esc(W("لكل حصة", "Per serving"))}</th></tr></thead><tbody>${NUT_KEYS.map((k) => { const [a, e, u] = NUT_LAB[k]; return `<tr><th scope="row">${esc(W(a, e))} <small dir="ltr">(${u})</small></th><td><input id="pc-p-${k}" type="number" inputmode="decimal" step="any" min="0" aria-label="${esc(`${W(a, e)} — ${W("لكل 100 غ", "per 100 g")}`)}"></td><td><input id="pc-q-${k}" type="number" inputmode="decimal" step="any" min="0" aria-label="${esc(`${W(a, e)} — ${W("لكل حصة", "per serving")}`)}"></td></tr>`; }).join("")}</tbody></table></div><span class="err" id="pcNu-e"></span></details>
      </div>
      <div class="row" style="margin-top:18px">${btn("pcGen", I.qr, W("أنشئ الرابط وQR", "Create link & QR"), "btn-gold", "submit")}${btn("pcSave", I.check, t("save"))}${btn("pcNew", I.plus, t("newRec"), "btn-ghost btn-sm")}<span class="err" id="pcErr" role="alert"></span></div>
    </form>
    <div class="card" id="pcRes" aria-live="polite" style="margin-top:18px"><h3>${esc(W("الرابط ورمز QR", "Link and QR code"))}</h3><p class="note" style="margin:0">${esc(W("املأ البطاقة ثم اضغط «أنشئ الرابط وQR». كل البيانات تُضغط داخل الرابط نفسه — لا خادم ولا قاعدة بيانات.", "Fill in the card, then press “Create link & QR”. All the data is compressed into the link itself — no server, no database."))}</p></div>
    ${recHead(RK)}
    </div></section>`;
  function after() {
    const form = $("#pcForm");
    const read = () => {
      const pair = (k) => [val(`pc-${k}0`), val(`pc-${k}1`)];
      const nums = (p) => NUT_KEYS.map((k) => { const v = nval(`pc-${p}-${k}`); return v === "" ? null : v; });
      const r = { n: pair("n"), d: pair("d"), i: pair("i"), s: pair("s"), a: ALG.map((g) => g[0]).filter((k) => $("#pc-al-" + k).checked), ao: val("pc-ao"), mc: val("pc-mc"), c: val("pc-c"), lot: val("pc-lot") };
      const p = nums("p"), q = nums("q"), sw = nval("pc-sw");
      if (p.some((v) => v != null) || q.some((v) => v != null) || sw !== "") r.nu = { sw: sw === "" ? null : sw, p, q };
      return r;
    };
    const validate = (r) => {
      clearErrs(form);
      let ok = true;
      if (!r.n[0] && !r.n[1]) { setErr("pc-n0", t("required")); setErr("pc-n1", t("required")); $("#pc-n-e").textContent = W("أدخل اسم المنتج بلغة واحدة على الأقل.", "Enter the product name in at least one language."); ok = false; }
      let nm = "";
      if (r.nu) {
        if (r.nu.sw != null && !(r.nu.sw > 0)) ok = setErr("pc-sw", MSG.pos()) && false;
        ["p", "q"].forEach((p) => NUT_KEYS.forEach((k, i) => { const v = r.nu[p][i], bad = v != null && !(v >= 0); $(`#pc-${p}-${k}`).setAttribute("aria-invalid", bad ? "true" : "false"); if (bad) nm = W("القيم الغذائية لا تكون سالبة.", "Nutrient values can't be negative."); }));
        if (!nm && r.nu.q.some((v) => v != null) && r.nu.sw == null) nm = W("أدخل حجم الحصة مع القيم لكل حصة.", "Enter the serving size with per-serving values.");
        $("#pcNu-e").textContent = nm; if (nm) { ok = false; $("#pcNu").open = true; }
      }
      $("#pcErr").textContent = ok ? "" : t("fixErrors"); if (!ok) focusBad(form);
      return ok;
    };
    const compact = (r) => { const o = {}; Object.entries(r).forEach(([k, v]) => { if (Array.isArray(v) ? v.some((x) => x !== "" && x != null) : v !== "" && v != null) o[k] = v; }); if (o.a && !o.a.length) delete o.a; return o; };
    const fill = (r) => {
      editing = r && r.id ? r.id : null; r = r || {};
      ["n", "d", "i", "s"].forEach((k) => [0, 1].forEach((j) => ($(`#pc-${k}${j}`).value = (r[k] && r[k][j]) || "")));
      ALG.forEach(([k]) => ($("#pc-al-" + k).checked = (r.a || []).includes(k)));
      ["ao", "mc", "c", "lot"].forEach((k) => ($("#pc-" + k).value = r[k] || ""));
      $("#pc-sw").value = r.nu && r.nu.sw != null ? r.nu.sw : "";
      NUT_KEYS.forEach((k, i) => { $("#pc-p-" + k).value = r.nu && r.nu.p && r.nu.p[i] != null ? r.nu.p[i] : ""; $("#pc-q-" + k).value = r.nu && r.nu.q && r.nu.q[i] != null ? r.nu.q[i] : ""; });
      $("#pcNu").open = !!r.nu; clearErrs(form);
      $("#pcTitle").textContent = r.id ? `${t("edit")} — ${r.n[0] || r.n[1]}` : t("newRec");
    };
    const generate = async () => {
      const r = read(); if (!validate(r)) return null;
      const data = await packCard(compact(r)), url = pcBase() + "#/product/" + data, long = url.length > PC_MAX;
      lastName = r.n[1] || r.n[0];
      let qrSvg = "", qrPng = "", qerr = "";
      try { const o = { margin: 2, errorCorrectionLevel: url.length > 1200 ? "L" : "M", color: { dark: "#111111", light: "#ffffff" } }; qrPng = await QRCode.toDataURL(url, { ...o, width: 600 }); qrSvg = await QRCode.toString(url, { ...o, type: "svg" }); }
      catch (_) { qerr = W("الرابط أطول من أن يُرمَّز في QR. اختصر النصوص.", "The link is too long to fit in a QR code. Shorten the texts."); }
      $("#pcRes").innerHTML = `<h3>${esc(W("الرابط ورمز QR", "Link and QR code"))}</h3>
        <div class="row" style="gap:6px;margin-bottom:8px"><span class="chip ${long ? "warn" : "ok"}" id="pcLen">${esc(W(`طول الرابط: ${url.length} حرفًا`, `Link length: ${url.length} characters`))}</span></div>
        ${long ? `<p class="note" style="color:#f5c06e" id="pcWarn">${esc(W(`الرابط أطول من ${PC_MAX} حرف؛ قد يصعب مسح QR أو يرفضه بعض التطبيقات. اختصر الوصف أو المكونات.`, `The link is longer than ${PC_MAX} characters; the QR may be hard to scan and some apps may reject it. Shorten the description or ingredients.`))}</p>` : ""}
        <div class="field"><label for="pcUrl">${esc(W("الرابط العام", "Public link"))}</label><input id="pcUrl" type="text" readonly dir="ltr" value="${esc(url)}"></div>
        <div class="row" style="margin-top:8px">${btn("pcCopy", I.note, W("نسخ الرابط", "Copy link"), "btn-ghost btn-sm")}<a class="btn btn-ghost btn-sm" href="${esc(url)}" target="_blank" rel="noopener" id="pcOpen">${I.external || I.arrow}<span>${esc(W("افتح البطاقة", "Open the card"))}</span></a></div>
        ${qerr ? `<p class="err">${esc(qerr)}</p>` : `<div class="pc-qr"><img src="${qrPng}" alt="${esc(W("رمز QR لبطاقة المنتج", "QR code for the product card"))}" width="220" height="220" id="pcQrImg"><div class="row">${btn("pcPng", I.download, "PNG", "btn-ghost btn-sm")}${btn("pcSvg", I.download, "SVG", "btn-ghost btn-sm")}${btn("pcPrint", I.printer, t("print"), "btn-ghost btn-sm")}</div></div>`}`;
      $("#pcCopy").addEventListener("click", async () => { try { await navigator.clipboard.writeText(url); toast(W("نُسخ الرابط", "Link copied")); } catch (_) { $("#pcUrl").select(); } });
      if (!qerr) {
        $("#pcPng").addEventListener("click", () => { const a = document.createElement("a"); a.href = qrPng; a.download = `qr-${safeName(lastName)}.png`; document.body.appendChild(a); a.click(); a.remove(); });
        $("#pcSvg").addEventListener("click", () => download(`qr-${safeName(lastName)}.svg`, qrSvg, "image/svg+xml"));
        $("#pcPrint").addEventListener("click", () => printHtml(`${L(tool("prodcard").t)} — ${lastName}`, `<div class="pc-print"><div class="pc-print-qr">${qrSvg}<p dir="ltr" style="font-size:7pt;word-break:break-all">${esc(url.length > 140 ? url.slice(0, 140) + "…" : url)}</p></div><div class="pc-print-card">${cardHtml(cleanCard(compact(r)))}</div></div>`));
      }
      return r;
    };
    form.addEventListener("submit", (e) => { e.preventDefault(); generate(); });
    $("#pcSave").addEventListener("click", () => { const r = read(); if (!validate(r)) return; if (saveRec(RK, r, editing)) { toast(t("saved")); editing = r.id; draw(); } });
    $("#pcNew").addEventListener("click", () => { fill(null); $("#pcRes").innerHTML = `<h3>${esc(W("الرابط ورمز QR", "Link and QR code"))}</h3>`; });
    $("#pcImp") && $("#pcImp").addEventListener("click", () => {
      const rec = recipes().find((x) => x.id === $("#pc-rec").value); if (!rec || !rec.out) { toast(W("احسب الوصفة واحفظها أولًا.", "Calculate and save the recipe first."), "bad"); return; }
      NUT_KEYS.forEach((k) => { const a = rec.out.p100 && rec.out.p100[k], b = rec.out.ps && rec.out.ps[k], d = NUT_LAB[k][3]; $("#pc-p-" + k).value = isNum(a) ? +(+a).toFixed(d) : ""; $("#pc-q-" + k).value = isNum(b) ? +(+b).toFixed(d) : ""; });
      $("#pc-sw").value = isNum(rec.out.servW) ? Math.round(rec.out.servW) : "";
      if (!val("pc-i0") && !val("pc-i1")) $("#pc-i" + (A.lang === "ar" ? 0 : 1)).value = rec.ing.map((x) => x.name).filter(Boolean).join(A.lang === "ar" ? "، " : ", ");
      toast(W("استُوردت القيم الغذائية", "Nutrition imported"));
    });
    const draw = recList($("#tool-prodcard-list"), RK, [[W("المنتج", "Product"), (r) => esc(r.n[0] || r.n[1])], [W("مسببات الحساسية", "Allergens"), (r) => (r.a || []).length + (r.ao ? 1 : 0)], [W("التاريخ", "Date"), recDate]], { edit: (r) => { fill(r); A.scrollTo(form, true); }, deleted: (id) => { if (editing === id) fill(null); } });
    fill(null);
  }
  return { title: L(tool("prodcard").t), html, after };
}

/* =====================================================================
   6) Hold / thaw / cooling timers (run across in-site navigation)
   ===================================================================== */
const TK = "tool:timers";
const TCAT = () => [["hold", W("احتفاظ ساخن/بارد", "Hot / cold holding")], ["thaw", W("إذابة", "Thawing")], ["cool", W("تبريد", "Cooling")], ["other", W("أخرى", "Other")]];
const tLoad = () => { const d = store.get(TK, null); return d && Array.isArray(d.list) ? { list: d.list, log: Array.isArray(d.log) ? d.log : [] } : { list: [], log: [] }; };
const tSave = (d) => store.set(TK, d);
const tLeft = (x, now) => (x.state === "run" ? x.dur - x.acc - (now - x.start) : x.state === "done" ? 0 : x.dur - x.acc);
const hms = (ms) => { const s = Math.max(0, Math.ceil(ms / 1000)); return `${s >= 3600 ? Math.floor(s / 3600) + ":" : ""}${p2(Math.floor((s % 3600) / 60))}:${p2(s % 60)}`; };
let audio = null;
const unlockAudio = () => { try { if (!audio) { const C = window.AudioContext || window.webkitAudioContext; if (C) audio = new C(); } if (audio && audio.state === "suspended") audio.resume(); } catch (_) { /* no audio */ } };
function beep() {
  if (!audio || audio.state !== "running") return;
  try { const t0 = audio.currentTime; for (let i = 0; i < 3; i++) { const o = audio.createOscillator(), g = audio.createGain(); o.type = "sine"; o.frequency.value = 880; g.gain.setValueAtTime(0.0001, t0 + i * 0.45); g.gain.exponentialRampToValueAtTime(0.35, t0 + i * 0.45 + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, t0 + i * 0.45 + 0.32); o.connect(g).connect(audio.destination); o.start(t0 + i * 0.45); o.stop(t0 + i * 0.45 + 0.35); } } catch (_) { /* ignore */ }
}
function alertDone(x) {
  beep();
  try { navigator.vibrate && navigator.vibrate([300, 150, 300, 150, 300]); } catch (_) { /* ignore */ }
  try { if (window.Notification && Notification.permission === "granted") new Notification(W("انتهى المؤقت", "Timer finished"), { body: x.name, tag: "timer-" + x.id }); } catch (_) { /* ignore */ }
  toast(W(`انتهى المؤقت: ${x.name}`, `Timer finished: ${x.name}`), "bad");
}
const onTimersPage = () => /^#\/tools\/timers\b/.test(location.hash);
let pill = null;
function timerTick() {
  const d = tLoad(), now = Date.now(); let changed = false;
  d.list.forEach((x) => {
    if (x.state === "run" && tLeft(x, now) <= 0) {
      const fin = x.start + (x.dur - x.acc);
      x.state = "done"; x.acc = x.dur; x.doneAt = fin; x.seen = onTimersPage(); changed = true;
      d.log.push({ id: uid(), name: x.name, cat: x.cat, dur: x.dur, started: x.firstStart || fin - x.dur, finished: fin });
      if (d.log.length > 300) d.log.splice(0, d.log.length - 300);
      alertDone(x);
    }
  });
  if (changed) { tSave(d); if (onTimersPage() && window.__pcTimersRedraw) window.__pcTimersRedraw(); }
  // live countdowns on the timers page
  $$("[data-tleft]").forEach((el) => { const x = d.list.find((y) => y.id === el.dataset.tleft); if (!x) return; const left = tLeft(x, now); el.textContent = hms(left); const bar = $(`[data-tbar="${x.id}"]`); if (bar) bar.style.width = `${Math.min(100, Math.max(0, (1 - left / x.dur) * 100))}%`; });
  // floating pill elsewhere on the site
  if (!pill) { pill = document.createElement("a"); pill.className = "pc-pill"; pill.href = "#/tools/timers"; pill.hidden = true; document.body.appendChild(pill); }
  const run = d.list.filter((x) => x.state === "run"), unseen = d.list.filter((x) => x.state === "done" && !x.seen);
  if (onTimersPage() || (!run.length && !unseen.length)) { pill.hidden = true; return; }
  pill.hidden = false; pill.classList.toggle("is-done", !!unseen.length);
  const next = run.map((x) => tLeft(x, now)).sort((a, b) => a - b)[0];
  pill.innerHTML = `${I.timer}<span>${unseen.length ? esc(W(`انتهى ${unseen.length}`, `${unseen.length} done`)) : ""}${unseen.length && run.length ? " · " : ""}${run.length ? `<bdi dir="ltr">${hms(next)}</bdi>${run.length > 1 ? ` +${run.length - 1}` : ""}` : ""}</span>`;
  pill.setAttribute("aria-label", W("المؤقتات", "Timers"));
}
setInterval(timerTick, 1000);
document.addEventListener("visibilitychange", () => { if (!document.hidden) timerTick(); });
window.addEventListener("hashchange", () => setTimeout(timerTick, 0));

function timersPage() {
  const html = `${head("timers")}
    <div class="grid g2" style="margin-top:18px;align-items:start">
      <form class="card" id="tmForm" novalidate><h2 style="font-size:20px">${esc(W("مؤقت جديد", "New timer"))}</h2>
        <div class="form">
          ${fld("tm-name", W("الاسم", "Name"), inp("tm-name", "text", "", `maxlength="60" placeholder="${esc(W("مثال: دجاج — إذابة في الثلاجة", "e.g. Chicken — fridge thaw"))}"`), { req: true, full: true })}
          <div class="field full"><label for="tm-cat">${esc(W("النوع", "Type"))}</label>${sel("tm-cat", TCAT(), "hold")}</div>
          <fieldset class="full"><legend class="lbl req">${esc(W("المدة", "Duration"))}</legend><div class="pc-hms">
            <div class="field"><label for="tm-h">${esc(W("ساعات", "Hours"))}</label>${inp("tm-h", "number", "", 'min="0" step="1" inputmode="numeric"')}</div>
            <div class="field"><label for="tm-m">${esc(W("دقائق", "Minutes"))}</label>${inp("tm-m", "number", "", 'min="0" max="59" step="1" inputmode="numeric"')}</div>
            <div class="field"><label for="tm-s">${esc(W("ثوانٍ", "Seconds"))}</label>${inp("tm-s", "number", "", 'min="0" max="59" step="1" inputmode="numeric"')}</div></div>
            <span class="hint">${esc(W("من إجراء منشأتك أو خطة HACCP — لا توجد مدد افتراضية.", "From your site procedure or HACCP plan — there are no default times."))}</span><span class="err" id="tm-d-e"></span></fieldset>
          <label class="field full" style="flex-direction:row;align-items:center;gap:8px"><input type="checkbox" id="tm-go" checked style="width:18px;height:18px;accent-color:var(--gold)"> <span>${esc(W("ابدأ فورًا", "Start immediately"))}</span></label>
        </div>
        <div class="row" style="margin-top:16px">${btn("tmAdd", I.plus, W("أضف المؤقت", "Add timer"), "btn-gold", "submit")}<span class="err" id="tmErr" role="alert"></span></div>
      </form>
      <div class="card"><h3>${esc(W("التنبيهات", "Alerts"))}</h3>
        <p class="note" style="margin-top:0">${esc(W("عند الانتهاء: صوت (بعد أول نقرة منك في الصفحة)، واهتزاز إن دعمه الجهاز، وإشعار إن سمحت به. يستمر العدّ أثناء تنقلك داخل الموقع، ويُستأنف من وقت البدء المحفوظ إذا أعدت فتح الصفحة، لكن لا يمكن التنبيه والصفحة مغلقة.", "When done: a sound (after your first tap on the page), vibration where supported, and a notification if you allow it. Countdowns keep running while you move around the site and resume from the saved start time if you reopen the page, but no alert can fire while the page is closed."))}</p>
        <div class="row">${btn("tmNotif", I.alert, W("السماح بالإشعارات", "Allow notifications"), "btn-ghost btn-sm")}${btn("tmTest", I.sound || I.check, W("اختبار الصوت", "Test sound"), "btn-ghost btn-sm")}<span class="chip" id="tmNotifSt"></span></div>
        <p class="note">${esc(W("المؤقت تذكير وليس سجلًا للرقابة: تحقق من الحرارة بميزان حرارة معاير وسجّلها في سجلك.", "A timer is a reminder, not a monitoring record: check temperatures with a calibrated thermometer and record them in your log."))}</p></div>
    </div>
    <div class="row" style="margin:30px 0 12px"><h2 style="font-size:22px;margin:0">${esc(W("المؤقتات", "Timers"))} <span class="chip" id="tmN"></span></h2></div>
    <div id="tmList" class="pc-timers"></div>
    <div class="row" style="margin:30px 0 12px"><h2 style="font-size:22px;margin:0">${esc(W("سجل المؤقتات المنتهية", "Finished timers log"))} <span class="chip" id="tmLN"></span></h2><span class="spacer"></span>${btn("tmCsv", I.download, t("exportCsv"), "btn-ghost btn-sm")}${btn("tmClr", I.trash, W("مسح السجل", "Clear log"), "btn-ghost btn-sm")}</div>
    <div id="tmLog"></div>
    </div></section>`;
  function after() {
    const form = $("#tmForm");
    const catL = (c) => (TCAT().find((x) => x[0] === c) || TCAT()[3])[1];
    const durL = (ms) => { const s = Math.round(ms / 1000), h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60; return [h ? W(`${h} س`, `${h} h`) : "", m ? W(`${m} د`, `${m} min`) : "", r ? W(`${r} ث`, `${r} s`) : ""].filter(Boolean).join(" ") || "0"; };
    const tm = (ts) => new Date(ts).toLocaleString(LOC(), { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit", second: "2-digit" });
    const draw = () => {
      const d = tLoad(), now = Date.now(); let seenChange = false;
      d.list.forEach((x) => { if (x.state === "done" && !x.seen) { x.seen = true; seenChange = true; } });
      if (seenChange) tSave(d);
      $("#tmN").textContent = d.list.length;
      const stL = { idle: W("جاهز", "Ready"), run: W("يعمل", "Running"), pause: W("موقوف مؤقتًا", "Paused"), done: W("انتهى", "Done") };
      $("#tmList").innerHTML = d.list.length ? d.list.map((x) => { const left = tLeft(x, now); return `<div class="card pc-tm is-${x.state}" data-id="${esc(x.id)}">
        <div class="row" style="gap:6px"><b class="pc-tm-n">${esc(x.name)}</b><span class="spacer"></span><span class="chip">${esc(catL(x.cat))}</span><span class="chip ${x.state === "done" ? "bad" : x.state === "run" ? "ok" : x.state === "pause" ? "warn" : ""}" data-tst="${esc(x.id)}">${esc(stL[x.state])}</span></div>
        <div class="pc-cd" role="timer" aria-label="${esc(x.name)}" data-tleft="${esc(x.id)}" dir="ltr">${hms(left)}</div>
        <div class="pc-bar"><span data-tbar="${esc(x.id)}" style="width:${Math.min(100, Math.max(0, (1 - left / x.dur) * 100))}%"></span></div>
        <p class="note" style="margin:6px 0 10px">${esc(W("المدة", "Duration"))}: ${esc(durL(x.dur))}${x.state === "done" && x.doneAt ? ` · ${esc(W("انتهى", "finished"))} <bdi dir="ltr">${esc(tm(x.doneAt))}</bdi>` : x.state === "run" ? ` · ${esc(W("ينتهي", "ends"))} <bdi dir="ltr">${esc(tm(x.start + x.dur - x.acc))}</bdi>` : ""}</p>
        <div class="row">${x.state === "run" ? `<button type="button" class="btn btn-ghost btn-sm" data-act="pause">${esc(W("إيقاف مؤقت", "Pause"))}</button>` : x.state !== "done" ? `<button type="button" class="btn btn-gold btn-sm" data-act="start">${esc(x.state === "pause" ? W("استئناف", "Resume") : W("ابدأ", "Start"))}</button>` : ""}<button type="button" class="btn btn-ghost btn-sm" data-act="reset">${esc(W("إعادة ضبط", "Reset"))}</button><span class="spacer"></span><button type="button" class="icon-btn" data-act="del" aria-label="${esc(`${t("del")} — ${x.name}`)}" style="width:34px;height:34px">${I.trash}</button></div></div>`; }).join("") : `<div class="empty">${esc(W("لا توجد مؤقتات. أضف مؤقتًا بالمدة التي يحددها إجراؤك.", "No timers. Add one with the duration your procedure sets."))}</div>`;
      $("#tmLN").textContent = d.log.length;
      $("#tmLog").innerHTML = d.log.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("الاسم", "Name"))}</th><th>${esc(W("النوع", "Type"))}</th><th>${esc(W("المدة", "Duration"))}</th><th>${esc(W("البدء", "Started"))}</th><th>${esc(W("الانتهاء", "Finished"))}</th></tr></thead><tbody>${d.log.slice().reverse().map((l) => `<tr><td>${esc(l.name)}</td><td>${esc(catL(l.cat))}</td><td>${esc(durL(l.dur))}</td><td dir="ltr">${esc(tm(l.started))}</td><td dir="ltr">${esc(tm(l.finished))}</td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`;
    };
    window.__pcTimersRedraw = draw;
    const notifSt = () => { const el = $("#tmNotifSt"); if (!el) return; const p = window.Notification ? Notification.permission : "unsupported"; el.textContent = { granted: W("الإشعارات مسموحة", "Notifications allowed"), denied: W("الإشعارات مرفوضة من المتصفح", "Notifications blocked by the browser"), default: W("الإشعارات غير مفعّلة", "Notifications not enabled"), unsupported: W("الإشعارات غير مدعومة", "Notifications not supported") }[p]; el.className = "chip " + (p === "granted" ? "ok" : p === "denied" ? "bad" : ""); };
    $("#tmNotif").addEventListener("click", async () => { unlockAudio(); if (!window.Notification) return notifSt(); try { await Notification.requestPermission(); } catch (_) { /* ignore */ } notifSt(); });
    $("#tmTest").addEventListener("click", () => { unlockAudio(); setTimeout(beep, 50); });
    document.getElementById("app").addEventListener("pointerdown", unlockAudio, { once: true });
    form.addEventListener("submit", (e) => {
      e.preventDefault(); unlockAudio(); clearErrs(form);
      const name = val("tm-name"), h = nval("tm-h"), m = nval("tm-m"), s = nval("tm-s");
      let ok = setErr("tm-name", name ? "" : t("required")), msg = "";
      [["tm-h", h, 168], ["tm-m", m, 59], ["tm-s", s, 59]].forEach(([id, v, mx]) => { const bad = v !== "" && !(Number.isInteger(v) && v >= 0 && v <= mx); $("#" + id).setAttribute("aria-invalid", bad ? "true" : "false"); if (bad) msg = W("أدخل أعدادًا صحيحة: الساعات حتى 168، والدقائق والثواني حتى 59.", "Use whole numbers: hours up to 168, minutes and seconds up to 59."); });
      const dur = ((+h || 0) * 3600 + (+m || 0) * 60 + (+s || 0)) * 1000;
      if (!msg && !(dur > 0)) { msg = W("أدخل مدة أكبر من صفر.", "Enter a duration above zero."); $("#tm-h").setAttribute("aria-invalid", "true"); }
      $("#tm-d-e").textContent = msg; if (msg) ok = false;
      $("#tmErr").textContent = ok ? "" : t("fixErrors"); if (!ok) { focusBad(form); return; }
      const d = tLoad(), now = Date.now(), go = $("#tm-go").checked;
      d.list.push({ id: uid(), name, cat: $("#tm-cat").value, dur, acc: 0, state: go ? "run" : "idle", start: go ? now : null, firstStart: go ? now : null });
      if (tSave(d)) { ["tm-name", "tm-h", "tm-m", "tm-s"].forEach((id) => ($("#" + id).value = "")); toast(go ? W("بدأ المؤقت", "Timer started") : t("saved")); draw(); }
    });
    $("#tmList").addEventListener("click", (e) => {
      const b = e.target.closest("[data-act]"); if (!b) return; unlockAudio();
      const id = b.closest("[data-id]").dataset.id, d = tLoad(), x = d.list.find((y) => y.id === id), now = Date.now(); if (!x) return;
      const act = b.dataset.act;
      if (act === "start" && x.state !== "run" && x.state !== "done") { x.state = "run"; x.start = now; if (!x.firstStart) x.firstStart = now; }
      if (act === "pause" && x.state === "run") { x.acc += now - x.start; x.state = "pause"; x.start = null; }
      if (act === "reset") { x.state = "idle"; x.acc = 0; x.start = null; x.firstStart = null; x.doneAt = null; }
      if (act === "del") { if (!confirm(t("confirmDel"))) return; d.list = d.list.filter((y) => y !== x); }
      tSave(d); draw();
    });
    $("#tmCsv").addEventListener("click", () => { const d = tLoad(); download(`timers-log-${new Date().toISOString().slice(0, 10)}.csv`, csv([["name", "type", "duration_s", "started", "finished"], ...d.log.map((l) => [l.name, l.cat, Math.round(l.dur / 1000), new Date(l.started).toISOString(), new Date(l.finished).toISOString()])]), "text/csv;charset=utf-8"); });
    $("#tmClr").addEventListener("click", () => { if (!confirm(t("confirmDel"))) return; const d = tLoad(); d.log = []; tSave(d); draw(); toast(t("deleted")); });
    notifSt(); draw(); timerTick();
  }
  return { title: L(tool("timers").t), html, after };
}

/* ---------- registration ---------- */
const reg = (id, icon, tar, ten, dar, den, fn) => T.register({ id, icon, cat: "practical", t: { ar: tar, en: ten }, d: { ar: dar, en: den } }, fn);
reg("burn", "flame", "مكافئ النشاط البدني", "Activity equivalent calculator", "حوّل طاقة الحصة إلى دقائق مشي أو جري أو سباحة تقريبية بقيم MET قابلة للتعديل، مع شريط قابل للطباعة للملصق.", "Turn the energy in a serving into approximate minutes of walking, running or swimming with editable MET values, plus a printable label strip.", burnPage);
reg("afteropen", "clock", "الصلاحية بعد الفتح أو الإذابة أو التحضير", "Shelf life after opening / thawing / preparation", "من وقت البدء والمدة التي تدخلها إلى تاريخ ووقت «يُستخدم قبل» دون تجاوز الانتهاء الأصلي، مع ملصق 50×30 مم.", "From the start time and the duration you enter to a use-by date and time, capped at the original expiry, with a 50×30 mm label.", afterOpenPage);
reg("netweight", "scale", "فحص المحتوى الصافي للدفعة", "Batch net content check", "الأوزان الصافية والمتوسط والانحراف المعياري والعبوات تحت Qn وQn − T مقابل قواعدك، مع مدرج تكراري.", "Net weights, mean, SD and packages below Qn and Qn − T against your own rules, with a histogram.", netWeightPage);
reg("scale", "coins", "تحجيم الوصفات وتكلفتها", "Recipe scaling & costing", "حجّم الوصفة إلى عدد حصص أو وزن دفعة، واحسب تكلفة الدفعة والحصة ونسبة تكلفة الطعام.", "Scale a recipe to a number of portions or a batch weight, and work out batch cost, cost per portion and food-cost %.", scalePage);
reg("prodcard", "qr", "بطاقة المنتج للعميل عبر QR", "Customer product card via QR", "صفحة منتج ثنائية اللغة بالمكونات ومسببات الحساسية والقيم الغذائية، محفوظة كلها داخل رابط ورمز QR دون خادم.", "A bilingual product page with ingredients, allergens and nutrition, stored entirely inside a link and QR code — no server.", prodCardPage);
reg("timers", "timer", "مؤقتات الاحتفاظ والإذابة والتبريد", "Hold / thaw / cooling timers", "عدة مؤقتات بأسماء ومدد تحددها، تستمر أثناء التنقل في الموقع وتنبهك عند الانتهاء، مع سجل.", "Several named timers with durations you set; they keep running as you move around the site, alert you when done and keep a log.", timersPage);
