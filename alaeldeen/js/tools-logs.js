/* Six record-keeping tools: instrument calibration, surface swab & ATP, pest control, customer complaints,
   staff training matrix and a documentary shelf-life study record.
   They plug into js/tools.js through TOOLS.register and share its helpers (TOOLS.h).
   Limits, tolerances and thresholds are always entered by the user — the tools never propose them. */
(function () {
  "use strict";
  const T = window.TOOLS, A = window.APP, I = window.ICONS;
  const { kvTable, today, opt, readImage, store, esc, L, t, $, $$, toast, uid, fmtDate } = T.h;
  const W = (a, e) => (A.lang === "ar" ? a : e);
  const recordTool = T.h.recordTool;

  /* ---------- small shared helpers ---------- */
  const DAY = 86400000;
  const has = (v) => v !== "" && v != null;
  const daysTo = (d) => (d ? Math.round((Date.parse(String(d).slice(0, 10)) - Date.parse(today())) / DAY) : null);
  const nowLocal = () => { const d = new Date(); d.setMinutes(d.getMinutes() - d.getTimezoneOffset()); return d.toISOString().slice(0, 16); };
  const num = (n, d) => Number(n).toLocaleString(A.lang === "ar" ? "ar-SA-u-nu-latn" : "en-GB", { maximumFractionDigits: d == null ? 3 : d });
  const chip = (cls, txt) => `<span class="chip ${cls}">${esc(txt)}</span>`;
  const optL = (opts, v) => { const o = opts.find((x) => x.v === v); return o ? L(o.l) : ""; };
  const clip = (s, n) => esc(String(s || "").slice(0, n)) + (String(s || "").length > n ? "…" : "");
  const icon = (name, s) => I[name].replace("<svg", `<svg width="${s || 14}" height="${s || 14}"`);
  const uniq = (vals) => [...new Set(vals.map((v) => String(v || "").trim()).filter(Boolean))];
  const datalist = (id, vals) => `<datalist id="${id}">${uniq(vals).map((v) => `<option value="${esc(v)}">`).join("")}</datalist>`;
  const refreshList = (id, vals) => { const d = document.getElementById(id); if (d) d.innerHTML = uniq(vals).map((v) => `<option value="${esc(v)}">`).join(""); };
  const nval = (id) => { const el = $("#" + id); return !el || el.value === "" ? "" : Number(el.value); };
  const dtTxt = (v) => esc(String(v || "").replace("T", " "));
  // printable value of a form field (select → its label, dates formatted, text escaped)
  const pval = (f, r) => { const v = r[f.k]; if (!has(v)) return ""; if (f.type === "select") return esc(optL(f.opts, v)); if (f.type === "date") return esc(fmtDate(v)); if (f.type === "datetime-local") return dtTxt(v); return esc(v).replace(/\n/g, "<br>"); };
  const autoPrint = (fields, r, extra) => kvTable(fields.filter((f) => f.type !== "custom").map((f) => [L(f.label), pval(f, r)]).concat(extra || []));
  const signs = (a, b) => `<table class="t" style="min-width:0;margin-top:22px"><tr><th>${esc(a)}</th><th>${esc(b)}</th></tr><tr><td style="height:48px"></td><td></td></tr></table>`;
  const flagField = (id) => ({ k: "flag", type: "custom", mount(el) { el.innerHTML = `<span class="lbl">${esc(W("النتيجة", "Result"))}</span><div id="${id}" aria-live="polite" class="lg-flag"></div>`; }, read() { return ""; } });
  const introCard = (html) => `<div class="card" style="padding:16px 18px">${html}</div>`;
  const legend = (items) => `<div class="row lg-legend">${items.map(([c, txt]) => chip(c, txt)).join("")}</div>`;
  // rows: [label, value, colour, tooltip, shown text]
  const bars = (rows, max) => `<div class="hbars">${rows.map(([lab, v, col, title, txt]) => `<div class="hb" title="${esc(title || lab)}"><span class="hb-l">${esc(lab)}</span><span class="hb-track"><i style="width:${max ? Math.min(100, Math.max(v ? 3 : 0, Math.round((v / max) * 100))) : 0}%;background:${col || "var(--gold)"}"></i></span><span class="hb-v">${esc(txt != null ? txt : num(v, 0))}</span></div>`).join("")}</div>`;

  /* =====================================================================
     1) Instrument calibration log
     ===================================================================== */
  const INST = [opt("thermo", "ميزان حرارة (ثيرمومتر)", "Thermometer"), opt("ph", "جهاز قياس الأس الهيدروجيني (pH)", "pH meter"), opt("brix", "مقياس الانكسار / بركس", "Refractometer / Brix"), opt("scale", "ميزان وزن", "Weighing scale"), opt("tds", "جهاز قياس المواد الصلبة الذائبة (TDS)", "TDS meter"), opt("hygro", "مقياس الرطوبة", "Hygrometer"), opt("logger", "مسجّل بيانات الحرارة", "Temperature data logger"), opt("other", "أخرى", "Other")];
  const METH = [opt("ice", "نقطة التجمد (ماء مع ثلج)", "Ice point (ice slurry)"), opt("boil", "نقطة الغليان", "Boiling point"), opt("ref", "مقارنة بجهاز مرجعي معاير", "Comparison with a calibrated reference"), opt("buffer", "محاليل منظِّمة قياسية", "Standard buffer solutions"), opt("weights", "أوزان معتمدة", "Certified weights"), opt("std", "محلول قياسي معتمد", "Certified standard solution"), opt("ext", "معايرة خارجية لدى جهة معتمدة", "External calibration by an accredited body"), opt("other", "أخرى", "Other")];
  const calRes = (r) => (has(r.ref) && has(r.reading) && has(r.tol) ? (Math.abs(r.reading - r.ref) <= r.tol + 1e-9 ? "pass" : "fail") : "");
  const calKey = (r) => String(r.instId || "").trim().toLowerCase();
  const calLatest = (all) => { const m = {}; all.forEach((r) => { const k = calKey(r), p = m[k]; if (!p || (r.date || "") > (p.date || "") || ((r.date || "") === (p.date || "") && (r.created || 0) >= (p.created || 0))) m[k] = r; }); return m; };
  const dueSt = (r) => { const d = daysTo(r.due); return d == null ? "" : d < 0 ? "over" : d <= 7 ? "soon" : "ok"; };
  const dueChip = (r) => { const s = dueSt(r), d = daysTo(r.due); return s === "over" ? chip("bad", W(`متأخرة ${-d} يوم`, `Overdue ${-d} d`)) : s === "soon" ? chip("warn", d === 0 ? W("مستحقة اليوم", "Due today") : W(`خلال ${d} يوم`, `Due in ${d} d`)) : s === "ok" ? chip("ok", W("ضمن الموعد", "OK")) : ""; };
  const calFields = [
    { k: "inst", type: "select", req: true, label: { ar: "نوع الجهاز", en: "Instrument type" }, opts: INST },
    { k: "instId", req: true, list: "calIds", label: { ar: "رقم/رمز الجهاز أو الرقم التسلسلي", en: "Instrument ID / serial no." }, hint: { ar: "مثال: TH-03", en: "e.g. TH-03" } },
    { k: "location", list: "calLocs", label: { ar: "الموقع", en: "Location" } },
    { k: "method", type: "select", req: true, label: { ar: "طريقة المعايرة / التحقق", en: "Calibration / check method" }, opts: METH },
    { k: "unit", label: { ar: "الوحدة", en: "Unit" }, hint: { ar: "مثل °م، pH، °Bx، غ، ppm", en: "e.g. °C, pH, °Bx, g, ppm" } },
    { k: "ref", type: "number", step: "any", req: true, label: { ar: "القيمة المرجعية", en: "Reference value" }, hint: { ar: "قيمة المعيار أو الجهاز المرجعي المستخدم", en: "Value of the standard or reference used" } },
    { k: "reading", type: "number", step: "any", req: true, label: { ar: "قراءة الجهاز", en: "Instrument reading" } },
    { k: "tol", type: "number", step: "any", req: true, label: { ar: "السماحية المقبولة (±)", en: "Accepted tolerance (±)" }, hint: { ar: "من مواصفات الصانع أو إجراء منشأتك — الأداة لا تحددها.", en: "From the manufacturer's specification or your site procedure — the tool doesn't set it." } },
    flagField("calFlag"),
    { k: "by", req: true, label: { ar: "نفّذها", en: "Done by" } },
    { k: "date", type: "date", req: true, label: { ar: "تاريخ المعايرة", en: "Calibration date" } },
    { k: "due", type: "date", req: true, label: { ar: "موعد المعايرة القادمة", en: "Next due date" } },
    { k: "action", type: "textarea", full: true, rows: 2, label: { ar: "الإجراء عند عدم المطابقة", en: "Action if out of tolerance" }, hint: { ar: "مثل: ضبط الجهاز، إيقافه عن الاستخدام، استبداله، مراجعة القراءات السابقة. مطلوب عند عدم المطابقة.", en: "e.g. adjust, withdraw from use, replace, review earlier readings. Required when the result fails." } },
    { k: "notes", type: "textarea", full: true, rows: 2, label: { ar: "ملاحظات / رقم شهادة المعايرة", en: "Notes / calibration certificate no." } },
  ];
  const resChip = (v) => (v === "pass" ? chip("ok", W("مطابق", "Pass")) : v === "fail" ? chip("bad", W("غير مطابق", "Fail")) : "");
  const cal = recordTool({
    id: "calibration",
    defaults: () => ({ date: today() }),
    label: (r) => `${r.instId || ""} · ${optL(INST, r.inst)}`,
    intro: () => datalist("calIds", store.get("tool:calibration", []).map((r) => r.instId)) + datalist("calLocs", store.get("tool:calibration", []).map((r) => r.location)) +
      introCard(`<p style="margin:0;color:var(--muted)">${esc(W("النتيجة = |القراءة − القيمة المرجعية| ≤ السماحية التي تُدخلها. تُحتسب حالة الموعد لآخر سجل لكل جهاز: «قريبة» خلال 7 أيام، و«متأخرة» بعد تجاوز الموعد.", "Result = |reading − reference| ≤ the tolerance you enter. Due status uses each instrument's latest record: \"due soon\" within 7 days, \"overdue\" once the date has passed."))}</p>`),
    fields: calFields,
    onFill: () => {
      const id = $("#f-instId");
      id.addEventListener("change", () => { const last = cal.recs().filter((r) => calKey(r) === id.value.trim().toLowerCase()).pop(); if (last) ["inst", "location", "method", "unit", "tol"].forEach((k) => { const el = $("#f-" + k); if (el && el.value === "") el.value = last[k] ?? ""; }); flag(); });
      const flag = () => { const r = { ref: nval("f-ref"), reading: nval("f-reading"), tol: nval("f-tol") }; const res = calRes(r); $("#calFlag").innerHTML = res ? `${resChip(res)} <span class="note" dir="ltr">Δ = ${num(Math.abs(r.reading - r.ref))}</span>` : `<span class="note" style="margin:0">${esc(W("أدخل المرجع والقراءة والسماحية.", "Enter reference, reading and tolerance."))}</span>`; };
      ["f-ref", "f-reading", "f-tol"].forEach((k) => $("#" + k).addEventListener("input", flag)); flag();
    },
    check: (k, r) => (k === "tol" && has(r.tol) && r.tol < 0 ? W("يجب ألا تكون السماحية سالبة.", "Tolerance can't be negative.") : k === "due" && r.due && r.date && r.due <= r.date ? W("يجب أن يكون بعد تاريخ المعايرة.", "Must be after the calibration date.") : k === "action" && calRes(r) === "fail" && !r.action ? t("required") : ""),
    compute: (r) => { r.result = calRes(r); r.deviation = has(r.ref) && has(r.reading) ? Math.round(Math.abs(r.reading - r.ref) * 1e6) / 1e6 : ""; },
    columns: [
      { l: { ar: "التاريخ", en: "Date" }, f: (r) => esc(fmtDate(r.date)) },
      { l: { ar: "الجهاز", en: "Instrument" }, f: (r) => `<b>${esc(r.instId)}</b><div class="note" style="margin:0">${esc(optL(INST, r.inst))}${r.location ? " · " + esc(r.location) : ""}</div>` },
      { l: { ar: "المرجع / القراءة / ±", en: "Ref / reading / ±" }, f: (r) => `<span dir="ltr">${esc(r.ref)} / ${esc(r.reading)} / ±${esc(r.tol)} ${esc(r.unit || "")}</span>` },
      { l: { ar: "النتيجة", en: "Result" }, f: (r) => resChip(r.result || calRes(r)) },
      { l: { ar: "بواسطة", en: "By" }, f: (r) => esc(r.by) },
      { l: { ar: "الموعد القادم", en: "Next due" }, f: (r) => { const latest = calLatest(cal.recs())[calKey(r)]; return `${esc(fmtDate(r.due))}<div style="margin-top:4px">${latest && latest.id === r.id ? dueChip(r) : chip("", W("سجل سابق", "Superseded"))}</div>`; } },
    ],
    filter: { opts: [opt("over", "المتأخرة", "Overdue"), opt("soon", "المستحقة خلال 7 أيام", "Due within 7 days"), opt("fail", "غير المطابقة", "Failed")], test: (r, v) => { if (v === "fail") return (r.result || calRes(r)) === "fail"; const latest = calLatest(cal.recs())[calKey(r)]; return latest && latest.id === r.id && dueSt(r) === v; } },
    csvKeys: ["date", "inst", "instId", "location", "method", "unit", "ref", "reading", "tol", "deviation", "result", "by", "due", "action", "notes"],
    below: (el, all) => {
      refreshList("calIds", all.map((r) => r.instId)); refreshList("calLocs", all.map((r) => r.location));
      if (!all.length) { el.innerHTML = ""; return; }
      const latest = Object.values(calLatest(all)); const c = { ok: 0, soon: 0, over: 0 }; let fails = 0;
      latest.forEach((r) => { const s = dueSt(r); if (c[s] != null) c[s]++; if ((r.result || calRes(r)) === "fail") fails++; });
      el.innerHTML = `<div class="card lg-sum"><h3>${esc(W("حالة الأجهزة (آخر سجل لكل جهاز)", "Instrument status (latest record each)"))}</h3><div class="lg-tiles">
        <div class="lg-tile ok"><b>${c.ok}</b><span>${esc(W("ضمن الموعد", "OK"))}</span></div>
        <div class="lg-tile warn"><b>${c.soon}</b><span>${esc(W("مستحقة خلال 7 أيام", "Due within 7 days"))}</span></div>
        <div class="lg-tile bad"><b>${c.over}</b><span>${esc(W("متأخرة", "Overdue"))}</span></div>
        <div class="lg-tile"><b>${fails}</b><span>${esc(W("غير مطابقة في آخر معايرة", "Failed at last check"))}</span></div></div>
        <p class="note" style="margin-bottom:0">${esc(W(`${latest.length} جهاز مسجّل.`, `${latest.length} instrument(s) recorded.`))}</p></div>`;
    },
    print: (r) => autoPrint(calFields, r, [[W("الفرق", "Deviation"), `<span dir="ltr">${esc(r.deviation)}</span>`], [W("النتيجة", "Result"), esc(r.result === "pass" ? W("مطابق", "Pass") : r.result === "fail" ? W("غير مطابق", "Fail") : "")]]) + signs(W("نفّذها", "Done by"), W("راجعها", "Reviewed by")),
  });

  /* =====================================================================
     2) Surface swab & ATP log
     ===================================================================== */
  const SWT = [opt("atp", "ATP (وحدات ضوء نسبية RLU)", "ATP (RLU)"), opt("micro", "مسحة ميكروبية", "Microbial swab"), opt("allergen", "مسحة بروتين / مسببات حساسية", "Allergen protein swab")];
  const swSt = (r) => (has(r.result) && has(r.passMax) && has(r.warnMax) ? (r.result <= r.passMax ? "pass" : r.result <= r.warnMax ? "caution" : "fail") : "");
  const SWS = { pass: ["ok", "مطابق", "Pass", "#53b9ad"], caution: ["warn", "تحذير", "Caution", "#e8a33d"], fail: ["bad", "غير مطابق", "Fail", "#e5645a"] };
  const swChip = (s) => (SWS[s] ? chip(SWS[s][0], W(SWS[s][1], SWS[s][2])) : "");
  const swFields = [
    { k: "point", req: true, list: "swPts", label: { ar: "نقطة أخذ العينة", en: "Sampling point" }, hint: { ar: "مثال: لوح تقطيع 2 — الخضار", en: "e.g. Cutting board 2 — veg" } },
    { k: "area", list: "swAreas", label: { ar: "المنطقة / القسم", en: "Area / section" } },
    { k: "test", type: "select", req: true, label: { ar: "نوع الاختبار", en: "Test type" }, opts: SWT },
    { k: "unit", label: { ar: "وحدة النتيجة", en: "Result unit" }, hint: { ar: "مثل RLU أو CFU/مسحة أو حسب دليل الطقم", en: "e.g. RLU, CFU/swab, or as per your kit" } },
    { k: "result", type: "number", step: "any", req: true, label: { ar: "النتيجة", en: "Result value" } },
    { k: "passMax", type: "number", step: "any", req: true, label: { ar: "حد المطابقة (≤)", en: "Pass threshold (≤)" }, hint: { ar: "من دليل الطقم أو إجراء منشأتك. النتيجة ≤ هذا الحد = مطابق.", en: "From your kit or site procedure. Result ≤ this = pass." } },
    { k: "warnMax", type: "number", step: "any", req: true, label: { ar: "حد التحذير (≤)", en: "Warning threshold (≤)" }, hint: { ar: "النتيجة فوق حد المطابقة وحتى هذا الحد = تحذير، وما فوقه = غير مطابق.", en: "Above pass up to this = caution; above it = fail." } },
    flagField("swFlag"),
    { k: "date", type: "date", req: true, label: { ar: "التاريخ", en: "Date" } },
    { k: "by", req: true, label: { ar: "بواسطة", en: "By" } },
    { k: "action", type: "textarea", full: true, rows: 2, label: { ar: "الإجراء التصحيحي", en: "Corrective action" }, hint: { ar: "مطلوب عند عدم المطابقة، مثل إعادة التنظيف وإعادة المسح.", en: "Required on fail, e.g. re-clean and re-swab." } },
  ];
  const sw = recordTool({
    id: "swab",
    defaults: () => ({ date: today() }),
    label: (r) => `${r.point || ""} · ${r.result ?? ""}`,
    intro: () => datalist("swPts", store.get("tool:swab", []).map((r) => r.point)) + datalist("swAreas", store.get("tool:swab", []).map((r) => r.area)),
    fields: swFields,
    onFill: () => {
      const pt = $("#f-point");
      pt.addEventListener("change", () => { const last = sw.recs().filter((r) => r.point === pt.value.trim()).pop(); if (last) ["area", "test", "unit", "passMax", "warnMax"].forEach((k) => { const el = $("#f-" + k); if (el && el.value === "") el.value = last[k] ?? ""; }); flag(); });
      const flag = () => { const s = swSt({ result: nval("f-result"), passMax: nval("f-passMax"), warnMax: nval("f-warnMax") }); $("#swFlag").innerHTML = s ? swChip(s) : `<span class="note" style="margin:0">${esc(W("أدخل النتيجة والحدّين.", "Enter the result and both thresholds."))}</span>`; };
      ["f-result", "f-passMax", "f-warnMax"].forEach((k) => $("#" + k).addEventListener("input", flag)); flag();
    },
    check: (k, r) => (k === "warnMax" && has(r.warnMax) && has(r.passMax) && r.warnMax < r.passMax ? W("يجب أن يساوي حد التحذير حد المطابقة أو يزيد عليه.", "Warning threshold must be equal to or above the pass threshold.") : k === "action" && swSt(r) === "fail" && !r.action ? t("required") : ""),
    compute: (r) => { r.status = swSt(r); },
    columns: [
      { l: { ar: "التاريخ", en: "Date" }, f: (r) => esc(fmtDate(r.date)) },
      { l: { ar: "النقطة", en: "Point" }, f: (r) => `<b>${esc(r.point)}</b>${r.area ? `<div class="note" style="margin:0">${esc(r.area)}</div>` : ""}` },
      { l: { ar: "الاختبار", en: "Test" }, f: (r) => esc(optL(SWT, r.test)) },
      { l: { ar: "النتيجة", en: "Result" }, f: (r) => `<b dir="ltr">${esc(r.result)} ${esc(r.unit || "")}</b>` },
      { l: { ar: "الحدود", en: "Thresholds" }, f: (r) => `<span dir="ltr">≤${esc(r.passMax)} / ≤${esc(r.warnMax)}</span>` },
      { l: { ar: "الحالة", en: "Status" }, f: (r) => swChip(r.status || swSt(r)) },
      { l: { ar: "بواسطة", en: "By" }, f: (r) => esc(r.by) },
    ],
    filter: { opts: [opt("fail", "غير المطابقة", "Fail"), opt("caution", "تحذير", "Caution"), opt("pass", "مطابق", "Pass")], test: (r, v) => (r.status || swSt(r)) === v },
    csvKeys: ["date", "point", "area", "test", "unit", "result", "passMax", "warnMax", "status", "by", "action"],
    below: (el, all) => {
      refreshList("swPts", all.map((r) => r.point)); refreshList("swAreas", all.map((r) => r.area));
      if (!all.length) { el.innerHTML = ""; return; }
      const st = (r) => r.status || swSt(r);
      const groups = {}; all.forEach((r) => { const k = `${r.point}||${r.test}`; (groups[k] = groups[k] || []).push(r); });
      const keys = Object.keys(groups); const cur = el.dataset.k && groups[el.dataset.k] ? el.dataset.k : keys[keys.length - 1];
      const pts = groups[cur].filter((r) => r.date).sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : (a.created || 0) - (b.created || 0))).slice(-30);
      const lim = pts[pts.length - 1] || {};
      const vals = pts.map((p) => p.result).concat([lim.passMax, lim.warnMax].filter(has));
      let lo = Math.min(...vals), hi = Math.max(...vals); const span = hi - lo || Math.abs(hi) || 1; lo -= span * 0.12; hi += span * 0.12;
      const Wd = 640, H = 220, pad = 48;
      const x = (i) => pad + (pts.length < 2 ? (Wd - pad * 2) / 2 : (i * (Wd - pad * 2)) / (pts.length - 1));
      const y = (v) => H - 24 - ((v - lo) / (hi - lo || 1)) * (H - 44);
      const ticks = [lo + span * 0.12, (lo + hi) / 2, hi - span * 0.12].map((v) => +v.toPrecision(3));
      const hline = (v, col, txt) => (has(v) ? `<line x1="${pad}" x2="${Wd - pad}" y1="${y(v)}" y2="${y(v)}" stroke="${col}" stroke-dasharray="5 4"/><text x="${Wd - pad}" y="${y(v) - 5}" fill="${col}" font-size="11" text-anchor="end">${esc(txt)} ${esc(v)}</text>` : "");
      const total = all.length, fails = all.filter((r) => st(r) === "fail").length, cautions = all.filter((r) => st(r) === "caution").length;
      const rows = keys.map((k) => { const g = groups[k], f = g.filter((r) => st(r) === "fail").length; return { k, g, f, last: g.slice().sort((a, b) => (a.date < b.date ? -1 : 1)).pop() }; }).sort((a, b) => b.f / b.g.length - a.f / a.g.length);
      el.innerHTML = `<div class="card lg-sum"><h3>${esc(W("ملخص النتائج", "Results summary"))}</h3><div class="lg-tiles">
          <div class="lg-tile"><b>${total}</b><span>${esc(W("مسحة", "Swabs"))}</span></div>
          <div class="lg-tile bad"><b>${total ? Math.round((fails / total) * 100) : 0}%</b><span>${esc(W(`نسبة الإخفاق (${fails})`, `Fail rate (${fails})`))}</span></div>
          <div class="lg-tile warn"><b>${cautions}</b><span>${esc(W("تحذير", "Caution"))}</span></div></div>
        <div class="table-wrap" style="margin-top:14px"><table class="t"><thead><tr><th>${esc(W("النقطة", "Point"))}</th><th>${esc(W("الاختبار", "Test"))}</th><th>${esc(W("العدد", "Count"))}</th><th>${esc(W("آخر نتيجة", "Last result"))}</th><th>${esc(W("نسبة الإخفاق", "Fail rate"))}</th></tr></thead><tbody>${rows.map((o) => `<tr class="${o.f ? "lg-hot" : ""}"><td>${esc(o.g[0].point)}</td><td>${esc(optL(SWT, o.g[0].test))}</td><td>${o.g.length}</td><td><span dir="ltr">${esc(o.last.result)}</span> ${swChip(st(o.last))}</td><td><b>${Math.round((o.f / o.g.length) * 100)}%</b> <span class="note">(${o.f}/${o.g.length})</span></td></tr>`).join("")}</tbody></table></div></div>
        <div class="card" style="margin:16px 0"><div class="row"><h3 style="margin:0;font-size:16px">${esc(W("اتجاه النتائج لكل نقطة", "Trend per point"))}</h3><span class="spacer"></span><select id="swSel" style="width:auto;height:38px;max-width:100%" aria-label="${esc(W("اختر النقطة", "Choose a point"))}">${keys.map((k) => `<option value="${esc(k)}" ${k === cur ? "selected" : ""}>${esc(groups[k][0].point)} — ${esc(optL(SWT, groups[k][0].test))}</option>`).join("")}</select></div>
        <svg class="chart" viewBox="0 0 ${Wd} ${H}" role="img" aria-label="${esc(W("اتجاه النتائج", "Result trend"))}: ${esc(groups[cur][0].point)}" style="direction:ltr">
          ${ticks.map((v) => `<line x1="${pad}" x2="${Wd - pad}" y1="${y(v)}" y2="${y(v)}" stroke="rgba(255,255,255,.07)"/><text x="${pad - 6}" y="${y(v) + 4}" fill="#8f8f8f" font-size="11" text-anchor="end">${v}</text>`).join("")}
          ${hline(lim.warnMax, "#e8a33d", W("تحذير", "warn"))}${hline(lim.passMax, "#53b9ad", W("مطابقة", "pass"))}
          <polyline fill="none" stroke="#ddb03f" stroke-width="2.5" stroke-linejoin="round" points="${pts.map((p, i) => `${x(i)},${y(p.result)}`).join(" ")}"/>
          ${pts.map((p, i) => `<circle cx="${x(i)}" cy="${y(p.result)}" r="4.5" fill="${(SWS[st(p)] ? SWS[st(p)][3] : "#ddb03f")}" stroke="#171717" stroke-width="2"><title>${esc(p.date)} — ${esc(p.result)} ${esc(p.unit || "")}</title></circle>`).join("")}
        </svg><p class="note" style="margin:0">${esc(W("آخر 30 نتيجة. الخطوط المتقطعة هي حدود آخر سجل كما أدخلتها.", "Last 30 results. Dashed lines are the thresholds you entered on the latest record."))}</p></div>`;
      $("#swSel", el).addEventListener("change", (e) => { el.dataset.k = e.target.value; sw.cfg.below(el, sw.recs()); });
    },
    print: (r) => autoPrint(swFields, r, [[W("الحالة", "Status"), esc(SWS[r.status] ? W(SWS[r.status][1], SWS[r.status][2]) : "")]]) + signs(W("أخذ العينة", "Sampled by"), W("راجعها", "Reviewed by")),
  });

  /* =====================================================================
     3) Pest control log
     ===================================================================== */
  const STYPE = [opt("bait", "محطة طعم للقوارض", "Rodent bait station"), opt("ilt", "مصيدة حشرات ضوئية", "Insect light trap"), opt("glue", "لوح لاصق", "Glue board"), opt("rtrap", "مصيدة قوارض", "Rodent trap"), opt("other", "أخرى", "Other")];
  const ACT = [opt("none", "لا يوجد", "None"), opt("low", "منخفض", "Low"), opt("med", "متوسط", "Medium"), opt("high", "مرتفع", "High")];
  const PEST = [opt("rodent", "قوارض", "Rodents"), opt("cockroach", "صراصير", "Cockroaches"), opt("fly", "حشرات طائرة", "Flying insects"), opt("spi", "حشرات المواد المخزنة", "Stored-product insects"), opt("ant", "نمل", "Ants"), opt("bird", "طيور", "Birds"), opt("other", "أخرى", "Other")];
  const actChip = (v) => (v === "none" ? chip("ok", W("لا يوجد", "None")) : v === "low" ? chip("warn", W("منخفض", "Low")) : v === "med" ? chip("warn", W("متوسط", "Medium")) : v === "high" ? chip("bad", W("مرتفع", "High")) : "");
  const active = (r) => !!r.activity && r.activity !== "none";
  const pestFields = [
    { k: "date", type: "date", req: true, label: { ar: "تاريخ الزيارة", en: "Visit date" } },
    { k: "contractor", req: true, list: "pcCon", label: { ar: "شركة المكافحة", en: "Contractor" } },
    { k: "station", req: true, list: "pcSt", label: { ar: "رقم المحطة / المصيدة", en: "Station / trap no." }, hint: { ar: "كما هو في مخطط مواقع المحطات", en: "As on your station location map" } },
    { k: "stype", type: "select", req: true, label: { ar: "نوع المحطة", en: "Station type" }, opts: STYPE },
    { k: "activity", type: "select", req: true, label: { ar: "النشاط المرصود", en: "Activity found" }, opts: ACT },
    { k: "pest", type: "select", label: { ar: "نوع الآفة", en: "Pest type" }, opts: PEST, hint: { ar: "مطلوب عند وجود نشاط.", en: "Required when activity is found." } },
    { k: "action", type: "textarea", full: true, rows: 2, label: { ar: "الإجراء المتخذ", en: "Action taken" }, hint: { ar: "مطلوب عند وجود نشاط، مثل سد الفتحات، التنظيف، استبدال اللوح، زيادة الزيارات.", en: "Required when activity is found, e.g. proofing, cleaning, board replaced, extra visits." } },
    { k: "chem", type: "textarea", full: true, rows: 2, label: { ar: "المواد الكيميائية المستخدمة (الاسم + رقم التسجيل)", en: "Chemicals used (name + reg. no.)" }, hint: { ar: "انقلها كما سجلها المقاول المرخّص. هذه الأداة لا تقترح منتجات ولا جرعات.", en: "Copy them as recorded by the licensed contractor. This tool doesn't suggest products or doses." } },
    { k: "tech", req: true, label: { ar: "الفني", en: "Technician" } },
    { k: "next", type: "date", label: { ar: "الزيارة القادمة", en: "Next visit" } },
    { k: "notes", type: "textarea", full: true, rows: 2, label: { ar: "ملاحظات", en: "Notes" } },
  ];
  const pest = recordTool({
    id: "pest",
    defaults: () => ({ date: today(), activity: "none" }),
    label: (r) => `${r.station || ""} · ${fmtDate(r.date)}`,
    intro: () => datalist("pcCon", store.get("tool:pest", []).map((r) => r.contractor)) + datalist("pcSt", store.get("tool:pest", []).map((r) => r.station)),
    fields: pestFields,
    onFill: () => { const st = $("#f-station"); st.addEventListener("change", () => { const last = pest.recs().filter((r) => r.station === st.value.trim()).pop(); if (last) { const el = $("#f-stype"); if (el.value === "") el.value = last.stype || ""; } }); },
    check: (k, r) => ((k === "pest" || k === "action") && active(r) && !r[k] ? t("required") : k === "next" && r.next && r.date && r.next < r.date ? W("يجب أن يكون بعد تاريخ الزيارة.", "Must be on or after the visit date.") : ""),
    columns: [
      { l: { ar: "التاريخ", en: "Date" }, f: (r) => esc(fmtDate(r.date)) },
      { l: { ar: "المحطة", en: "Station" }, f: (r) => `<b>${esc(r.station)}</b><div class="note" style="margin:0">${esc(optL(STYPE, r.stype))}</div>` },
      { l: { ar: "النشاط", en: "Activity" }, f: (r) => actChip(r.activity) + (active(r) && r.pest ? ` <span class="note">${esc(optL(PEST, r.pest))}</span>` : "") },
      { l: { ar: "الإجراء", en: "Action" }, f: (r) => clip(r.action, 60) },
      { l: { ar: "الفني / المقاول", en: "Technician / contractor" }, f: (r) => `${esc(r.tech)}<div class="note" style="margin:0">${esc(r.contractor)}</div>` },
      { l: { ar: "الزيارة القادمة", en: "Next visit" }, f: (r) => esc(fmtDate(r.next)) },
    ],
    filter: { opts: [opt("act", "الزيارات مع نشاط", "Visits with activity")], test: (r) => active(r) },
    csvKeys: ["date", "contractor", "station", "stype", "activity", "pest", "action", "chem", "tech", "next", "notes"],
    below: (el, all) => {
      refreshList("pcCon", all.map((r) => r.contractor)); refreshList("pcSt", all.map((r) => r.station));
      if (!all.length) { el.innerHTML = ""; return; }
      const g = {}; all.forEach((r) => { const k = String(r.station || "").trim().toLowerCase(); (g[k] = g[k] || []).push(r); });
      const rows = Object.values(g).map((v) => { const act = v.filter(active).sort((a, b) => (a.date < b.date ? -1 : 1)); return { v, act, rep: act.length >= 2, last: act[act.length - 1] }; }).sort((a, b) => b.act.length - a.act.length);
      const rep = rows.filter((o) => o.rep).length, withAct = all.filter(active).length;
      el.innerHTML = `<div class="card lg-sum"><h3>${esc(W("المحطات ذات النشاط", "Stations with activity"))}</h3><div class="lg-tiles">
          <div class="lg-tile"><b>${rows.length}</b><span>${esc(W("محطة", "Stations"))}</span></div>
          <div class="lg-tile warn"><b>${withAct}</b><span>${esc(W("زيارة مع نشاط", "Visits with activity"))}</span></div>
          <div class="lg-tile bad"><b>${rep}</b><span>${esc(W("نشاط متكرر (زيارتان أو أكثر)", "Repeated activity (≥2 visits)"))}</span></div></div>
        ${rows.some((o) => o.act.length) ? `<div class="table-wrap" style="margin-top:14px"><table class="t"><thead><tr><th>${esc(W("المحطة", "Station"))}</th><th>${esc(W("النوع", "Type"))}</th><th>${esc(W("زيارات مع نشاط", "Visits with activity"))}</th><th>${esc(W("آخر نشاط", "Last activity"))}</th><th>${esc(W("الآفات", "Pests"))}</th></tr></thead><tbody>${rows.filter((o) => o.act.length).map((o) => `<tr class="${o.rep ? "lg-hot" : ""}"><td><b>${esc(o.v[0].station)}</b>${o.rep ? ` ${chip("bad", W("متكرر", "Repeated"))}` : ""}</td><td>${esc(optL(STYPE, o.v[o.v.length - 1].stype))}</td><td><b>${o.act.length}</b> / ${o.v.length}</td><td>${esc(fmtDate(o.last.date))} ${actChip(o.last.activity)}</td><td>${esc(uniq(o.act.map((r) => optL(PEST, r.pest))).join("، "))}</td></tr>`).join("")}</tbody></table></div>
        <p class="note" style="margin-bottom:0">${esc(W("المحطات المظللة سجّلت نشاطًا في زيارتين أو أكثر — راجع الأسباب (مداخل، نظافة، تخزين) مع المقاول.", "Shaded stations had activity on two or more visits — review causes (entry points, cleaning, storage) with the contractor."))}</p>` : `<p class="note" style="margin-bottom:0">${esc(W("لم يُسجَّل أي نشاط حتى الآن.", "No activity recorded so far."))}</p>`}</div>`;
    },
    print: (r) => autoPrint(pestFields, r) + signs(W("الفني", "Technician"), W("ممثل المنشأة", "Site representative")),
  });

  /* =====================================================================
     4) Customer complaints log
     ===================================================================== */
  const CH = [opt("phone", "هاتف", "Phone"), opt("app", "التطبيق", "App"), opt("social", "وسائل التواصل الاجتماعي", "Social media"), opt("store", "في الفرع", "In store"), opt("delivery", "منصة توصيل", "Delivery platform"), opt("email", "البريد الإلكتروني", "Email")];
  const CLS = [opt("foreign", "جسم غريب", "Foreign body"), opt("taste", "الطعم / الرائحة", "Taste / odour"), opt("temp", "درجة الحرارة", "Temperature"), opt("illness", "ادعاء إصابة بمرض", "Illness claim"), opt("pack", "التغليف", "Packaging"), opt("qty", "الكمية", "Quantity"), opt("service", "الخدمة", "Service"), opt("other", "أخرى", "Other")];
  const CSEV = [opt("minor", "بسيطة", "Minor"), opt("major", "رئيسية", "Major"), opt("critical", "حرجة", "Critical")];
  const CST = [opt("new", "جديدة", "New"), opt("investigating", "قيد التحقيق", "Investigating"), opt("closed", "مغلقة", "Closed")];
  const NCR_CAT = { foreign: "foreign", temp: "temp", pack: "storage" };
  const csevChip = (v) => (v ? chip(v === "critical" ? "bad" : v === "major" ? "warn" : "", optL(CSEV, v)) : "");
  const cstChip = (v) => (v ? chip(v === "closed" ? "ok" : v === "new" ? "bad" : "warn", optL(CST, v)) : "");
  let cPhotos = [], cNcr = { id: "", rec: null };
  const cPhotoField = {
    k: "photos", type: "custom", full: true,
    mount(el, r) {
      cPhotos = (r.photos || []).slice();
      const lab = W("صور الشكوى (اختياري)", "Complaint photos (optional)");
      const draw = () => {
        el.innerHTML = `<span class="lbl">${esc(lab)}</span><div class="thumbs">${cPhotos.map((src, i) => `<figure><img src="${src}" alt="${esc(lab)} ${i + 1}"><button type="button" data-rmp="${i}" aria-label="${esc(t("del"))} ${i + 1}">×</button></figure>`).join("")}
          ${cPhotos.length < 3 ? `<label class="btn btn-ghost btn-sm lg-addph">${I.camera}<span style="font-size:11.5px">${esc(W("إضافة صورة", "Add photo"))}</span><input type="file" accept="image/*" hidden aria-label="${esc(W("إضافة صورة", "Add photo"))}"></label>` : ""}</div><span class="hint">${esc(W("حتى 3 صور، تُصغَّر وتُحفظ على جهازك فقط. احصل على موافقة العميل قبل حفظ صوره.", "Up to 3 photos, resized and kept on your device only. Get the customer's consent before keeping their photos."))}</span>`;
        $$("[data-rmp]", el).forEach((b) => b.addEventListener("click", () => { cPhotos.splice(+b.dataset.rmp, 1); draw(); }));
        const inp = $("input[type=file]", el);
        inp && inp.addEventListener("change", async () => { const f = inp.files[0]; if (!f) return; try { cPhotos.push(await readImage(f, 800)); draw(); } catch (e) { toast(e.message === "size" ? W("الملف أكبر من 15 ميغابايت.", "File is larger than 15 MB.") : W("نوع الملف غير مدعوم — اختر صورة.", "Unsupported file — choose an image."), "bad"); } });
      };
      draw();
    },
    read() { return cPhotos.slice(); },
  };
  // keeps the id of an NCR raised from this complaint when the record is edited and saved again
  const cNcrField = {
    k: "ncrId", type: "custom", full: true,
    mount(el, r) { cNcr = { id: r.ncrId || "", rec: r.id || null }; el.style.display = cNcr.id ? "" : "none"; el.innerHTML = cNcr.id ? `<span class="lbl">NCR</span><div>${chip("teal", W("أُنشئ تقرير NCR من هذه الشكوى", "An NCR was raised from this complaint"))} <a href="#/tools/ncr">${esc(W("فتح أداة NCR", "Open the NCR tool"))}</a></div>` : ""; },
    read() { return cNcr.id; },
  };
  const cFields = [
    { k: "at", type: "datetime-local", req: true, label: { ar: "التاريخ والوقت", en: "Date & time" } },
    { k: "channel", type: "select", req: true, label: { ar: "قناة الاستلام", en: "Channel" }, opts: CH },
    { k: "branch", req: true, list: "cBr", label: { ar: "الفرع", en: "Branch" } },
    { k: "product", req: true, list: "cPr", label: { ar: "المنتج", en: "Product" } },
    { k: "cls", type: "select", req: true, label: { ar: "التصنيف", en: "Classification" }, opts: CLS },
    { k: "severity", type: "select", req: true, label: { ar: "الخطورة", en: "Severity" }, opts: CSEV },
    { k: "desc", type: "textarea", full: true, req: true, label: { ar: "وصف الشكوى", en: "Description" }, hint: { ar: "كلمات العميل كما وردت، ورقم الطلب ووقته إن وُجد.", en: "The customer's words as received, plus order no. and time if available." } },
    cPhotoField,
    { k: "status", type: "select", req: true, label: { ar: "الحالة", en: "Status" }, opts: CST },
    { k: "ncrRef", label: { ar: "رقم NCR المرتبط", en: "Linked NCR no." } },
    { k: "response", type: "textarea", full: true, rows: 2, label: { ar: "الرد على العميل", en: "Response to customer" }, hint: { ar: "مطلوب عند إغلاق الشكوى.", en: "Required when the complaint is closed." } },
    cNcrField,
  ];
  const weekOf = (d) => { const x = new Date(String(d).slice(0, 10) + "T00:00:00Z"); if (isNaN(x)) return ""; x.setUTCDate(x.getUTCDate() - ((x.getUTCDay() + 6) % 7)); return x.toISOString().slice(0, 10); };
  const comp = recordTool({
    id: "complaints",
    defaults: () => ({ at: nowLocal(), status: "new" }),
    label: (r) => `${r.product || ""} · ${r.branch || ""}`,
    intro: () => datalist("cBr", store.get("tool:complaints", []).map((r) => r.branch)) + datalist("cPr", store.get("tool:complaints", []).map((r) => r.product)) +
      introCard(`<span class="lbl">${esc(W("مسار الحالة", "Status flow"))}</span><div class="status-flow" style="margin-top:8px">${CST.map((s, i) => `<span class="st">${esc(L(s.l))}</span>${i < CST.length - 1 ? I.arrow.replace("<svg", '<svg width="14" height="14" style="color:var(--dim)"') : ""}`).join("")}</div><p class="note" style="margin-bottom:0">${esc(W("زر «إنشاء NCR» في جدول السجلات يُنشئ تقرير عدم مطابقة مفتوحًا في أداة NCR؛ أكمل فيه المسؤول والموعد.", "The \"Raise NCR\" button in the records table creates an open report in the NCR tool; add the owner and due date there."))}</p>`),
    fields: cFields,
    check: (k, r) => (k === "response" && r.status === "closed" && !r.response ? t("required") : ""),
    columns: [
      { l: { ar: "الوقت", en: "Time" }, f: (r) => `<span dir="ltr">${dtTxt(r.at)}</span><div class="note" style="margin:0">${esc(optL(CH, r.channel))}</div>` },
      { l: { ar: "الفرع / المنتج", en: "Branch / product" }, f: (r) => `<b>${esc(r.branch)}</b><div class="note" style="margin:0">${esc(r.product)}</div>` },
      { l: { ar: "التصنيف", en: "Classification" }, f: (r) => esc(optL(CLS, r.cls)) + (r.photos && r.photos.length ? ` <span class="note" title="${esc(W("صور", "Photos"))}">${icon("camera")}${r.photos.length}</span>` : "") },
      { l: { ar: "الوصف", en: "Description" }, f: (r) => clip(r.desc, 60) },
      { l: { ar: "الخطورة", en: "Severity" }, f: (r) => csevChip(r.severity) },
      { l: { ar: "الحالة", en: "Status" }, f: (r) => cstChip(r.status) },
      { l: "NCR", f: (r) => (r.ncrRef ? `<span dir="ltr">${esc(r.ncrRef)}</span> ` : "") + (r.ncrId ? chip("teal", W("أُنشئ", "Raised")) : `<button type="button" class="btn btn-ghost btn-sm" data-ncr="${esc(r.id)}">${icon("alert")}<span>${esc(W("إنشاء NCR", "Raise NCR"))}</span></button>`) },
    ],
    filter: { opts: CST, test: (r, v) => r.status === v },
    csvKeys: ["at", "channel", "branch", "product", "cls", "severity", "desc", "status", "ncrRef", "response", "ncrId"],
    below: (el, all) => {
      refreshList("cBr", all.map((r) => r.branch)); refreshList("cPr", all.map((r) => r.product));
      const rl = $("#rList");
      if (rl && !rl.dataset.ncrBound) {
        rl.dataset.ncrBound = "1";
        rl.addEventListener("click", (e) => {
          const b = e.target.closest("[data-ncr]"); if (!b) return;
          const recs = comp.recs(), r = recs.find((x) => x.id === b.dataset.ncr); if (!r || r.ncrId) return;
          const ncrs = store.get("tool:ncr", []);
          const n = { id: uid(), created: Date.now(), date: String(r.at || today()).slice(0, 10), dept: r.branch || "", category: NCR_CAT[r.cls] || "other", desc: `${W("شكوى عميل", "Customer complaint")} (${optL(CLS, r.cls)}) — ${r.product}: ${r.desc}`, evidence: `${W("شكوى", "Complaint")} ${String(r.at || "").replace("T", " ")} — ${optL(CH, r.channel)}${r.photos && r.photos.length ? " — " + W(`${r.photos.length} صورة في سجل الشكاوى`, `${r.photos.length} photo(s) in the complaints log`) : ""}`, owner: "", severity: "minor", status: "open", due: "", before: [], after: [] };
          ncrs.push(n);
          if (!store.set("tool:ncr", ncrs)) return;
          r.ncrId = n.id; store.set("tool:complaints", recs);
          if (cNcr.rec === r.id) cNcr.id = n.id;
          b.outerHTML = chip("teal", W("أُنشئ", "Raised"));
          toast(W("أُنشئ تقرير NCR — أكمل المسؤول والموعد في أداة NCR.", "NCR created — add the owner and due date in the NCR tool."));
        });
      }
      if (!all.length) { el.innerHTML = ""; return; }
      const weeks = uniq(all.map((r) => weekOf(r.at))).sort().reverse();
      const cur = el.dataset.w && weeks.includes(el.dataset.w) ? el.dataset.w : weeks[0];
      const wk = all.filter((r) => weekOf(r.at) === cur);
      const counts = CLS.map((c) => [L(c.l), wk.filter((r) => r.cls === c.v).length]);
      const max = Math.max(1, ...counts.map((c) => c[1]));
      const open = all.filter((r) => r.status !== "closed").length;
      el.innerHTML = `<div class="card lg-sum"><div class="row" style="margin-bottom:12px"><h3 style="margin:0">${esc(W("الشكاوى الأسبوعية حسب التصنيف", "Weekly complaints by classification"))}</h3><span class="spacer"></span><select id="cWk" style="width:auto;height:38px;max-width:100%" aria-label="${esc(W("اختر الأسبوع", "Choose a week"))}">${weeks.map((w) => `<option value="${w}" ${w === cur ? "selected" : ""}>${esc(W("أسبوع يبدأ", "Week of"))} ${esc(fmtDate(w))}</option>`).join("")}</select></div>
        ${bars(counts.map(([l, v]) => [l, v, v ? "var(--gold)" : "", `${l}: ${v}`]), max)}
        <div class="row" style="margin-top:14px">${chip("gold", W(`${wk.length} شكوى هذا الأسبوع`, `${wk.length} this week`))}${chip(open ? "warn" : "ok", W(`${open} غير مغلقة (الإجمالي)`, `${open} not closed (all time)`))}${chip("", W(`${all.length} إجمالي السجلات`, `${all.length} total`))}</div></div>`;
      $("#cWk", el).addEventListener("change", (e) => { el.dataset.w = e.target.value; comp.cfg.below(el, comp.recs()); });
    },
    print: (r) => autoPrint(cFields, r) + (r.photos && r.photos.length ? `<h3 style="margin-top:14px">${esc(W("الصور", "Photos"))}</h3><div style="display:flex;gap:8px;flex-wrap:wrap">${r.photos.map((s) => `<img src="${s}" alt="" style="width:200px;height:150px;object-fit:cover;border:1px solid #bbb;border-radius:4px">`).join("")}</div>` : "") + signs(W("استلمها", "Received by"), W("مسؤول الجودة", "Quality lead")),
  });

  /* =====================================================================
     5) Staff training matrix
     ===================================================================== */
  const COURSES = [opt("fs1", "سلامة الغذاء — المستوى 1", "Food safety level 1"), opt("fs2", "سلامة الغذاء — المستوى 2", "Food safety level 2"), opt("fs3", "سلامة الغذاء — المستوى 3", "Food safety level 3"), opt("haccp", "HACCP", "HACCP"), opt("allergen", "التوعية بمسببات الحساسية", "Allergen awareness"), opt("hygiene", "النظافة الشخصية", "Hygiene"), opt("chem", "مواد التنظيف الكيميائية", "Cleaning chemicals"), opt("firstaid", "الإسعافات الأولية", "First aid"), opt("other", "أخرى", "Other")];
  const expSt = (d) => { const n = daysTo(d); return n == null ? "none" : n < 0 ? "exp" : n <= 30 ? "soon" : "ok"; };
  const expChip = (d, noneTxt) => { const s = expSt(d), n = daysTo(d); return s === "exp" ? chip("bad", W("منتهية", "Expired")) : s === "soon" ? chip("warn", W(`تنتهي خلال ${n} يوم`, `Expires in ${n} d`)) : s === "ok" ? chip("ok", W("سارية", "Valid")) : noneTxt ? chip("", noneTxt) : ""; };
  const empKey = (r) => String(r.name || "").trim().toLowerCase();
  const cKey = (r) => (r.course === "other" ? "o:" + String(r.courseOther || "").trim().toLowerCase() : r.course);
  const cLab = (r) => (r.course === "other" ? r.courseOther || optL(COURSES, "other") : optL(COURSES, r.course));
  const trFields = [
    { k: "name", req: true, list: "trNames", label: { ar: "اسم الموظف", en: "Employee name" } },
    { k: "role", list: "trRoles", label: { ar: "الوظيفة", en: "Role" } },
    { k: "branch", list: "trBr", label: { ar: "الفرع", en: "Branch" } },
    { k: "course", type: "select", req: true, label: { ar: "الدورة", en: "Course" }, opts: COURSES },
    { k: "courseOther", label: { ar: "اسم الدورة (عند اختيار «أخرى»)", en: "Course name (if \"Other\")" } },
    { k: "done", type: "date", req: true, label: { ar: "تاريخ الإتمام", en: "Date completed" } },
    { k: "expiry", type: "date", label: { ar: "تاريخ انتهاء الشهادة", en: "Certificate expiry" }, hint: { ar: "اتركه فارغًا إن لم تكن للشهادة صلاحية.", en: "Leave blank if the certificate doesn't expire." } },
    { k: "cert", label: { ar: "رقم الشهادة", en: "Certificate no." } },
    { k: "health", type: "date", label: { ar: "انتهاء الشهادة الصحية", en: "Health certificate expiry" } },
    { k: "notes", type: "textarea", full: true, rows: 2, label: { ar: "ملاحظات", en: "Notes" } },
  ];
  const tr = recordTool({
    id: "training",
    defaults: () => ({ done: today() }),
    label: (r) => `${r.name || ""} · ${cLab(r)}`,
    intro: () => { const a = store.get("tool:training", []); return datalist("trNames", a.map((r) => r.name)) + datalist("trRoles", a.map((r) => r.role)) + datalist("trBr", a.map((r) => r.branch)); },
    fields: trFields,
    onFill: () => { const n = $("#f-name"); n.addEventListener("change", () => { const last = tr.recs().filter((r) => empKey(r) === n.value.trim().toLowerCase()).pop(); if (last) ["role", "branch", "health"].forEach((k) => { const el = $("#f-" + k); if (el && el.value === "") el.value = last[k] || ""; }); }); },
    check: (k, r) => (k === "courseOther" && r.course === "other" && !r.courseOther ? t("required") : k === "expiry" && r.expiry && r.done && r.expiry <= r.done ? W("يجب أن يكون بعد تاريخ الإتمام.", "Must be after the completion date.") : ""),
    columns: [
      { l: { ar: "الموظف", en: "Employee" }, f: (r) => `<b>${esc(r.name)}</b><div class="note" style="margin:0">${esc([r.role, r.branch].filter(Boolean).join(" · "))}</div>` },
      { l: { ar: "الدورة", en: "Course" }, f: (r) => esc(cLab(r)) },
      { l: { ar: "الإتمام", en: "Completed" }, f: (r) => esc(fmtDate(r.done)) },
      { l: { ar: "الانتهاء", en: "Expiry" }, f: (r) => `${esc(fmtDate(r.expiry))} ${expChip(r.expiry, W("بلا انتهاء", "No expiry"))}` },
      { l: { ar: "رقم الشهادة", en: "Cert. no." }, f: (r) => esc(r.cert) },
      { l: { ar: "الشهادة الصحية", en: "Health cert." }, f: (r) => (r.health ? `${esc(fmtDate(r.health))} ${expChip(r.health)}` : "—") },
    ],
    filter: { opts: [opt("exp", "منتهية", "Expired"), opt("soon", "تنتهي خلال 30 يومًا", "Expiring within 30 days")], test: (r, v) => expSt(r.expiry) === v || expSt(r.health) === v },
    csvKeys: ["name", "role", "branch", "course", "courseOther", "done", "expiry", "cert", "health", "notes"],
    below: (el, all) => {
      refreshList("trNames", all.map((r) => r.name)); refreshList("trRoles", all.map((r) => r.role)); refreshList("trBr", all.map((r) => r.branch));
      if (!all.length) { el.innerHTML = ""; return; }
      const emps = {}, courses = {};
      all.forEach((r) => {
        const e = (emps[empKey(r)] = emps[empKey(r)] || { name: r.name, branch: r.branch, health: "", cells: {} });
        if (r.health && r.health > e.health) e.health = r.health;
        if (!courses[cKey(r)]) courses[cKey(r)] = { lab: cLab(r), ord: COURSES.findIndex((c) => c.v === r.course) };
        const p = e.cells[cKey(r)]; if (!p || (r.done || "") >= (p.done || "")) e.cells[cKey(r)] = r;
      });
      const cols = Object.entries(courses).sort((a, b) => a[1].ord - b[1].ord || (a[1].lab < b[1].lab ? -1 : 1));
      const MK = { ok: ["ok", "✓", "سارية", "Valid"], soon: ["warn", "⚠", "تنتهي خلال 30 يومًا", "Expiring within 30 days"], exp: ["bad", "✗", "منتهية", "Expired"], none: ["ok", "✓", "بلا انتهاء", "No expiry"] };
      const cell = (r, lab) => { if (!r) return `<td class="lg-c"><span class="lg-na" aria-label="${esc(W("غير مسجّلة", "Not recorded"))}">—</span></td>`; const m = MK[expSt(r.expiry)], tip = `${lab}: ${W(m[2], m[3])}${r.expiry ? " — " + fmtDate(r.expiry) : ""}`; return `<td class="lg-c"><span class="chip ${m[0]}" title="${esc(tip)}" aria-label="${esc(tip)}">${m[1]}</span></td>`; };
      const cnt = { ok: 0, soon: 0, exp: 0 }; Object.values(emps).forEach((e) => Object.values(e.cells).forEach((r) => { const s = expSt(r.expiry); cnt[s === "none" ? "ok" : s]++; }));
      el.innerHTML = `<div class="card lg-sum"><h3>${esc(W("مصفوفة التدريب: موظف × دورة", "Training matrix: employee × course"))}</h3>
        ${legend([["ok", `✓ ${W("سارية", "Valid")} (${cnt.ok})`], ["warn", `⚠ ${W("تنتهي خلال 30 يومًا", "Expiring within 30 days")} (${cnt.soon})`], ["bad", `✗ ${W("منتهية", "Expired")} (${cnt.exp})`], ["", `— ${W("غير مسجّلة", "Not recorded")}`]])}
        <div class="table-wrap" style="margin-top:12px"><table class="t lg-matrix"><thead><tr><th>${esc(W("الموظف", "Employee"))}</th>${cols.map(([, c]) => `<th>${esc(c.lab)}</th>`).join("")}<th>${esc(W("الشهادة الصحية", "Health cert."))}</th></tr></thead>
        <tbody>${Object.values(emps).sort((a, b) => (a.name < b.name ? -1 : 1)).map((e) => `<tr><th scope="row">${esc(e.name)}${e.branch ? `<div class="note" style="margin:0;font-weight:400">${esc(e.branch)}</div>` : ""}</th>${cols.map(([k, c]) => cell(e.cells[k], c.lab)).join("")}<td class="lg-c">${e.health ? `${expChip(e.health)}<div class="note" style="margin:2px 0 0">${esc(fmtDate(e.health))}</div>` : "—"}</td></tr>`).join("")}</tbody></table></div>
        <p class="note" style="margin-bottom:0">${esc(W("تعرض كل خلية أحدث سجل للموظف في تلك الدورة.", "Each cell shows the employee's latest record for that course."))}</p></div>`;
    },
    print: (r) => autoPrint(trFields, r, [[W("حالة الشهادة", "Certificate status"), esc({ ok: W("سارية", "Valid"), soon: W("تنتهي خلال 30 يومًا", "Expiring within 30 days"), exp: W("منتهية", "Expired"), none: W("بلا انتهاء", "No expiry") }[expSt(r.expiry)])]]) + signs(W("الموظف", "Employee"), W("المدرب / المشرف", "Trainer / supervisor")),
  });

  /* =====================================================================
     6) Shelf-life study record (documentary)
     ===================================================================== */
  const blankCp = () => ({ day: "", sens: "", app: "", odour: "", taste: "", ph: "", micro: "", res: "" });
  let cps = [blankCp()];
  const cpCols = () => [["day", W("اليوم", "Day")], ["sens", W("التقييم الحسي (1–5)", "Sensory (1–5)")], ["app", W("المظهر", "Appearance")], ["odour", W("الرائحة", "Odour")], ["taste", W("الطعم", "Taste")], ["ph", W("pH (اختياري)", "pH (optional)")], ["micro", W("النتيجة الميكروبية (اختياري)", "Micro result (optional)")], ["res", W("النتيجة", "Result")]];
  const cpRead = () => { const tb = $("#cpBody"); if (!tb) return cps; cps = $$("tr", tb).map((tr) => { const o = blankCp(); $$("[data-c]", tr).forEach((el) => { o[el.dataset.c] = el.dataset.c === "day" || el.dataset.c === "ph" || el.dataset.c === "sens" ? (el.value === "" ? "" : Number(el.value)) : el.value.trim(); }); return o; }); return cps; };
  const lastPass = (rows) => { let lp = ""; let failDay = ""; rows.filter((c) => has(c.day)).slice().sort((a, b) => a.day - b.day).some((c) => { if (c.res === "fail") { failDay = c.day; return true; } if (c.res === "pass") lp = c.day; return false; }); return { lp, failDay }; };
  const cpField = {
    k: "checkpoints", type: "custom", full: true,
    mount(el, r) {
      cps = (r.checkpoints && r.checkpoints.length ? r.checkpoints : [blankCp()]).map((c) => ({ ...blankCp(), ...c }));
      const cols = cpCols();
      const inp = (c, i, k, lab) => {
        const a = `data-c="${k}" aria-label="${esc(lab)} — ${esc(W("نقطة الفحص", "Checkpoint"))} ${i + 1}"`;
        if (k === "sens") return `<select ${a}><option value="">—</option>${[1, 2, 3, 4, 5].map((n) => `<option value="${n}" ${String(c.sens) === String(n) ? "selected" : ""}>${n}</option>`).join("")}</select>`;
        if (k === "res") return `<select ${a}><option value="">—</option><option value="pass" ${c.res === "pass" ? "selected" : ""}>${esc(W("مطابق", "Pass"))}</option><option value="fail" ${c.res === "fail" ? "selected" : ""}>${esc(W("غير مطابق", "Fail"))}</option></select>`;
        if (k === "day" || k === "ph") return `<input type="number" ${a} step="${k === "ph" ? "0.01" : "1"}" ${k === "day" ? 'min="0"' : ""} inputmode="decimal" value="${esc(c[k])}" class="lg-n">`;
        return `<input type="text" ${a} value="${esc(c[k])}">`;
      };
      const draw = () => {
        el.innerHTML = `<span class="lbl req">${esc(W("نقاط الفحص", "Checkpoints"))}</span>
          <div class="table-wrap"><table class="t lg-cp"><thead><tr>${cols.map(([, l]) => `<th>${esc(l)}</th>`).join("")}<th></th></tr></thead>
          <tbody id="cpBody">${cps.map((c, i) => `<tr>${cols.map(([k, l]) => `<td>${inp(c, i, k, l)}</td>`).join("")}<td><button type="button" class="icon-btn" data-cprm="${i}" aria-label="${esc(t("del"))} — ${esc(W("نقطة الفحص", "Checkpoint"))} ${i + 1}" style="width:34px;height:34px" ${cps.length < 2 ? "disabled" : ""}>${I.trash}</button></td></tr>`).join("")}</tbody></table></div>
          <div class="row" style="margin-top:10px"><button type="button" class="btn btn-ghost btn-sm" id="cpAdd">${I.plus}<span>${esc(W("إضافة نقطة فحص", "Add checkpoint"))}</span></button><span id="cpSum" class="note" style="margin:0" aria-live="polite"></span></div>
          <span class="hint">${esc(W("معايير المطابقة لكل نقطة تحددها خطة الدراسة لديك. اليوم = عدد الأيام منذ الإنتاج.", "Pass/fail criteria for each checkpoint come from your study protocol. Day = days since production."))}</span><span class="err" id="cp-e" role="alert"></span>`;
        $("#cpAdd", el).addEventListener("click", () => { cpRead(); cps.push(blankCp()); draw(); const last = $$("#cpBody tr", el).pop(); last && $("[data-c=day]", last).focus(); });
        $$("[data-cprm]", el).forEach((b) => b.addEventListener("click", () => { cpRead(); cps.splice(+b.dataset.cprm, 1); draw(); }));
        const sum = () => { const { lp, failDay } = lastPass(cpRead()); $("#cpSum", el).textContent = `${W("آخر يوم مطابق", "Last passing day")}: ${has(lp) ? lp : "—"}${has(failDay) ? ` · ${W("أول إخفاق في اليوم", "First fail on day")} ${failDay}` : ""}`; };
        $("#cpBody", el).addEventListener("input", sum); $("#cpBody", el).addEventListener("change", sum); sum();
      };
      draw();
    },
    read() { return cpRead().map((c) => ({ ...c })); },
  };
  const slFields = [
    { k: "product", req: true, label: { ar: "المنتج", en: "Product" } },
    { k: "batch", req: true, label: { ar: "رقم الدفعة", en: "Batch no." } },
    { k: "prodDate", type: "date", req: true, label: { ar: "تاريخ الإنتاج", en: "Production date" } },
    { k: "storage", req: true, label: { ar: "ظروف التخزين", en: "Storage condition" }, hint: { ar: "كما في خطة الدراسة (الحرارة، الرطوبة، الضوء، العبوة).", en: "As in your study protocol (temperature, humidity, light, pack)." } },
    { k: "planned", type: "number", step: "1", req: true, label: { ar: "المدة المخططة (أيام)", en: "Planned duration (days)" } },
    { k: "by", req: true, label: { ar: "المسؤول عن الدراسة", en: "Study lead" } },
    cpField,
    { k: "conclusion", type: "textarea", full: true, rows: 3, label: { ar: "الخلاصة والملاحظات", en: "Conclusion & notes" } },
  ];
  const sl = recordTool({
    id: "shelflife",
    defaults: () => ({ prodDate: today() }),
    label: (r) => `${r.product || ""} · ${r.batch || ""}`,
    intro: () => `<div class="disclaimer">${I.flask}<div><b>${esc(W("سجل توثيقي فقط", "Documentary record only"))}</b><br>${esc(W("هذه الأداة تنظّم نتائج دراستك وتوثّقها، ولا تُغني عن دراسة عمر تخزيني معتمدة (validated) ولا عن نتائج مختبر معتمد. معايير المطابقة ومدة الصلاحية النهائية تحددها خطة الدراسة والتشريعات المعمول بها.", "This tool organises and documents your study results. It doesn't replace a validated shelf-life study or results from an accredited laboratory. Pass criteria and the final shelf life are set by your study protocol and applicable regulations."))}</div></div>`,
    fields: slFields,
    check: (k, r) => (k === "planned" && has(r.planned) && !(r.planned > 0 && Number.isInteger(r.planned)) ? W("أدخل عددًا صحيحًا أكبر من صفر.", "Enter a whole number above zero.") : ""),
    extraValid: (r) => {
      let ok = true, msg = ""; const tb = $("#cpBody");
      const rows = r.checkpoints || [];
      if (!rows.length) { ok = false; msg = t("required"); }
      $$("tr", tb).forEach((tr, i) => {
        const c = rows[i] || {}; const mark = (k, bad) => { const el = $(`[data-c="${k}"]`, tr); if (el) el.setAttribute("aria-invalid", bad ? "true" : "false"); if (bad) ok = false; };
        mark("day", !has(c.day) || c.day < 0 || !Number.isInteger(c.day)); mark("res", !c.res);
      });
      if (!ok && !msg) msg = W("لكل نقطة فحص: اليوم (عدد صحيح ≥ 0) والنتيجة مطلوبان.", "Each checkpoint needs a day (whole number ≥ 0) and a result.");
      const e = $("#cp-e"); if (e) e.textContent = msg;
      return ok;
    },
    compute: (r) => { r.checkpoints = (r.checkpoints || []).slice().sort((a, b) => a.day - b.day); const o = lastPass(r.checkpoints); r.lastPass = o.lp; r.firstFail = o.failDay; },
    columns: [
      { l: { ar: "المنتج / الدفعة", en: "Product / batch" }, f: (r) => `<b>${esc(r.product)}</b><div class="note" style="margin:0">${esc(r.batch)}</div>` },
      { l: { ar: "الإنتاج", en: "Produced" }, f: (r) => esc(fmtDate(r.prodDate)) },
      { l: { ar: "التخزين", en: "Storage" }, f: (r) => clip(r.storage, 40) },
      { l: { ar: "المخطط", en: "Planned" }, f: (r) => `${esc(r.planned)} ${esc(W("يوم", "d"))}` },
      { l: { ar: "نقاط الفحص", en: "Checkpoints" }, f: (r) => String((r.checkpoints || []).length) },
      { l: { ar: "آخر يوم مطابق", en: "Last passing day" }, f: (r) => (has(r.lastPass) ? chip(has(r.firstFail) ? "warn" : "ok", W(`اليوم ${r.lastPass}`, `Day ${r.lastPass}`)) : "—") + (has(r.firstFail) ? ` ${chip("bad", W(`إخفاق يوم ${r.firstFail}`, `Fail day ${r.firstFail}`))}` : "") },
    ],
    csvKeys: ["product", "batch", "prodDate", "storage", "planned", "by", "lastPass", "firstFail", "checkpoints", "conclusion"],
    csvVal: (k, r) => (k === "checkpoints" ? (r.checkpoints || []).map((c) => `D${c.day}: ${c.res}${has(c.sens) ? ` S${c.sens}` : ""}${has(c.ph) ? ` pH${c.ph}` : ""}${c.micro ? ` ${c.micro}` : ""}`).join(" | ") : r[k]),
    below: (el, all) => {
      if (!all.length) { el.innerHTML = ""; return; }
      el.innerHTML = `<div class="card lg-sum"><h3>${esc(W("آخر يوم مطابق مقابل المدة المخططة", "Last passing day vs planned duration"))}</h3>
        ${bars(all.slice(-12).reverse().map((r) => [`${r.product} · ${r.batch}`, r.planned > 0 ? Math.min(100, ((+r.lastPass || 0) / r.planned) * 100) : 0, has(r.firstFail) ? "var(--warn)" : "var(--teal)", `${r.product} · ${r.batch}`, `${has(r.lastPass) ? r.lastPass : "—"} / ${r.planned}`]), 100)}
        <p class="note" style="margin-bottom:0">${esc(W("الأخضر: لا إخفاق مسجّل · البرتقالي: سُجّل إخفاق بعد آخر يوم مطابق.", "Green: no fail recorded · Orange: a fail was recorded after the last passing day."))}</p></div>`;
    },
    print: (r) => autoPrint(slFields, r, [[W("آخر يوم مطابق", "Last passing day"), has(r.lastPass) ? esc(r.lastPass) : "—"], [W("أول إخفاق", "First fail"), has(r.firstFail) ? esc(W(`اليوم ${r.firstFail}`, `Day ${r.firstFail}`)) : ""]]) +
      `<h3 style="margin-top:14px">${esc(W("نقاط الفحص", "Checkpoints"))}</h3><table class="t" style="min-width:0"><thead><tr>${cpCols().map(([, l]) => `<th>${esc(l)}</th>`).join("")}</tr></thead><tbody>${(r.checkpoints || []).map((c) => `<tr>${cpCols().map(([k]) => `<td>${k === "res" ? esc(c.res === "pass" ? W("مطابق", "Pass") : c.res === "fail" ? W("غير مطابق", "Fail") : "") : esc(c[k])}</td>`).join("")}</tr>`).join("")}</tbody></table>` +
      `<p style="font-size:9.5pt;color:#555;margin-top:12px">${esc(W("سجل توثيقي لا يُغني عن دراسة عمر تخزيني معتمدة.", "Documentary record — does not replace a validated shelf-life study."))}</p>` + signs(W("المسؤول عن الدراسة", "Study lead"), W("اعتماد الجودة", "Quality approval")),
  });

  /* ---------- register ---------- */
  T.register({ id: "calibration", icon: "gear", t: { ar: "سجل معايرة أجهزة القياس", en: "Instrument calibration log" }, d: { ar: "قراءة الجهاز مقابل القيمة المرجعية ضمن سماحية تحددها أنت، مع تنبيه بالمواعيد القريبة والمتأخرة.", en: "Reading vs reference within a tolerance you set, with due-soon and overdue alerts." } }, cal.page);
  T.register({ id: "swab", icon: "flask", t: { ar: "سجل مسحات الأسطح وATP", en: "Surface swab & ATP log" }, d: { ar: "نتائج المسحات مقابل حدود تحددها أنت، مع حالة تلقائية واتجاه لكل نقطة ونسبة الإخفاق.", en: "Swab results against thresholds you set, automatic status, per-point trend and fail rate." } }, sw.page);
  T.register({ id: "pest", icon: "bug", t: { ar: "سجل مكافحة الآفات", en: "Pest control log" }, d: { ar: "زيارات المقاول لكل محطة أو مصيدة، والنشاط والإجراء، مع إبراز المحطات ذات النشاط المتكرر.", en: "Contractor visits per station or trap, activity and action, with repeat-activity stations highlighted." } }, pest.page);
  T.register({ id: "complaints", icon: "mail", t: { ar: "سجل شكاوى العملاء", en: "Customer complaints log" }, d: { ar: "صنّف الشكوى وتابعها حتى الإغلاق، وحوّلها إلى NCR بضغطة، مع رسم أسبوعي حسب التصنيف.", en: "Classify and follow complaints to closure, raise an NCR in one tap, and see weekly counts by type." } }, comp.page);
  T.register({ id: "training", icon: "user", t: { ar: "مصفوفة تدريب الموظفين", en: "Staff training matrix" }, d: { ar: "الدورات والشهادات الصحية وتواريخ انتهائها في مصفوفة موظف × دورة.", en: "Courses, health certificates and expiry dates in an employee × course matrix." } }, tr.page);
  T.register({ id: "shelflife", icon: "leaf", t: { ar: "سجل دراسة العمر التخزيني (توثيقي)", en: "Shelf-life study record (documentary)" }, d: { ar: "نقاط فحص حسية وكيميائية وميكروبية لكل دفعة، وآخر يوم مطابق، وتقرير كامل للطباعة.", en: "Sensory, chemical and micro checkpoints per batch, last passing day and a full printable report." } }, sl.page);
})();
