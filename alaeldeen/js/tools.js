/* Quality Toolkit — every tool runs in the browser and saves to localStorage only. */
(function () {
  "use strict";
  const A = window.APP, I = window.ICONS;
  const { esc, L, t, $, $$, store, toast, download, csv, uid, fmtDate, pageHead } = A;
  const ar = () => A.lang === "ar";
  const W = (a, e) => (ar() ? a : e);

  const list = [
    { id: "inspection", icon: "clip", t: { ar: "قائمة تفتيش GMP/GHP", en: "GMP/GHP inspection checklist" }, d: { ar: "قائمة قابلة للتخصيص مع نسبة امتثال لكل قسم وتقرير قابل للطباعة.", en: "Customisable checklist with compliance % per section and a printable report." } },
    { id: "ncr", icon: "alert", t: { ar: "تقرير عدم مطابقة NCR", en: "Nonconformity report (NCR)" }, d: { ar: "سجّل الحالة والأدلة والصور قبل/بعد وتابع الحالة حتى تحقق QC.", en: "Log the case, evidence and before/after photos, and track status to QC verification." } },
    { id: "rca", icon: "branch", t: { ar: "تحليل السبب الجذري وCAPA", en: "Root cause analysis & CAPA" }, d: { ar: "5 لماذا + مخطط عظم السمكة، ثم الإجراء التصحيحي والوقائي والتحقق.", en: "5 Whys + fishbone, then corrective/preventive action and effectiveness check." } },
    { id: "risk", icon: "grid", t: { ar: "تقييم المخاطر", en: "Risk assessment" }, d: { ar: "سجل مخاطر بمصفوفة احتمالية × شدة 5×5 معلنة.", en: "Risk register with a declared 5×5 likelihood × severity matrix." } },
    { id: "temp", icon: "therm", t: { ar: "سجل درجات الحرارة", en: "Temperature log" }, d: { ar: "قراءات مع حدود تحددها أنت، وكشف تلقائي للانحرافات ورسم بياني.", en: "Readings against limits you set, automatic deviation flags and a chart." } },
    { id: "dilution", icon: "calc", t: { ar: "حاسبة التخفيف والتركيز", en: "Dilution & concentration calculator" }, d: { ar: "C1V1 = C2V2 وتحويل ppm ↔ % باستخدام بيانات ملصق المنتج.", en: "C1V1 = C2V2 and ppm ↔ % using your product label data." } },
    { id: "compliance", icon: "percent", t: { ar: "حاسبة نسبة الامتثال", en: "Compliance % calculator" }, d: { ar: "احسب نسبة الامتثال من عدد البنود المطابقة وغير المطابقة.", en: "Compute compliance % from conforming and non-conforming items." } },
  ];
  const planned = [
    ["مصفوفة تقييم الموردين", "Supplier evaluation matrix"], ["سجل معايرة أجهزة القياس", "Instrument calibration log"], ["خطة أخذ العينات", "Sampling plan"], ["مولد خطة التنظيف والتطهير", "Cleaning & sanitation plan builder"], ["سجل مكافحة الآفات", "Pest control log"], ["نموذج تقييم مسببات الحساسية", "Allergen assessment form"], ["تمرين الاستدعاء التجريبي", "Mock recall exercise"], ["حاسبة العمر التخزيني (توثيقية)", "Shelf-life record (documentary)"], ["مولد محضر اجتماع الجودة", "Quality meeting minutes"], ["لوحة مؤشرات KPI", "KPI dashboard"], ["مخطط تدفق العمليات", "Process flow diagram"],
  ];

  const crumbsFor = (tool) => [[t("toolsT"), "#/tools"], [L(tool.t)]];
  const disclaimer = () => `<div class="disclaimer">${I.warn}<div>${esc(t("disclaimer"))}<br><span style="opacity:.8">${esc(t("localNote"))}</span></div></div>`;

  /* ---------- print helper ---------- */
  function printHtml(title, inner) {
    const pa = $("#printArea");
    pa.innerHTML = `<div class="print-head" style="display:flex"><div><b style="font-size:18pt">${esc(title)}</b><div style="font-size:10pt;color:#555">Eng. Alaeldeen | Quality &amp; Safety · ${esc(t("reportDate"))}: ${esc(fmtDate(new Date().toISOString()))}</div></div><img src="assets/logo-mark.png" alt=""></div>${inner}<p style="font-size:9pt;color:#666;margin-top:18px;border-top:1px solid #ccc;padding-top:8px">${esc(t("disclaimer"))}</p>`;
    document.body.classList.add("print-rec");
    const done = () => { document.body.classList.remove("print-rec"); window.removeEventListener("afterprint", done); };
    window.addEventListener("afterprint", done);
    setTimeout(() => { window.print(); setTimeout(done, 1000); }, 60);
  }
  const kvTable = (rows) => `<table class="t" style="min-width:0">${rows.filter((r) => r[1] !== undefined && r[1] !== "").map(([k, v]) => `<tr><th style="width:32%">${esc(k)}</th><td>${v}</td></tr>`).join("")}</table>`;

  /* ---------- image downscale for evidence photos ---------- */
  function readImage(file, max) {
    return new Promise((res, rej) => {
      if (!/^image\/(jpeg|png|webp|gif|heic|heif)$/i.test(file.type)) return rej(new Error("type"));
      if (file.size > 15 * 1024 * 1024) return rej(new Error("size"));
      const fr = new FileReader();
      fr.onload = () => { const img = new Image(); img.onload = () => { const k = Math.min(1, max / Math.max(img.width, img.height)); const c = document.createElement("canvas"); c.width = Math.round(img.width * k); c.height = Math.round(img.height * k); c.getContext("2d").drawImage(img, 0, 0, c.width, c.height); res(c.toDataURL("image/jpeg", 0.72)); }; img.onerror = rej; img.src = fr.result; };
      fr.onerror = rej; fr.readAsDataURL(file);
    });
  }

  /* ---------- generic record tool ---------- */
  function recordTool(cfg) {
    const key = "tool:" + cfg.id;
    const recs = () => store.get(key, []);
    const field = (f, v) => {
      const id = "f-" + f.k, lab = `<label for="${id}" class="${f.req ? "req" : ""}">${esc(L(f.label))}</label>`;
      const hint = f.hint ? `<span class="hint">${esc(L(f.hint))}</span>` : "";
      let inp;
      if (f.type === "textarea") inp = `<textarea id="${id}" rows="${f.rows || 3}">${esc(v || "")}</textarea>`;
      else if (f.type === "select") inp = `<select id="${id}"><option value="">—</option>${f.opts.map((o) => `<option value="${esc(o.v)}" ${String(v) === String(o.v) ? "selected" : ""}>${esc(L(o.l))}</option>`).join("")}</select>`;
      else if (f.type === "custom") return `<div class="field ${f.full ? "full" : ""}" data-custom="${f.k}"></div>`;
      else inp = `<input type="${f.type || "text"}" id="${id}" value="${esc(v == null ? "" : v)}" ${f.step ? `step="${f.step}"` : ""} ${f.list ? `list="${f.list}"` : ""} ${f.type === "number" ? 'inputmode="decimal"' : ""}>`;
      return `<div class="field ${f.full ? "full" : ""}">${lab}${inp}${hint}<span class="err" id="${id}-e"></span></div>`;
    };
    let editing = null;
    function page() {
      const tool = list.find((x) => x.id === cfg.id);
      return {
        title: L(tool.t),
        html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}
        <section class="sec"><div class="wrap">${disclaimer()}
          ${cfg.intro ? `<div style="margin-top:18px">${cfg.intro()}</div>` : ""}
          <form class="card" id="rform" novalidate style="margin-top:18px"><div class="row" style="margin-bottom:14px"><h2 style="font-size:20px;margin:0" id="formTitle"></h2><span class="spacer"></span><button type="button" class="btn btn-ghost btn-sm" id="rNew">${I.plus}<span>${esc(t("newRec"))}</span></button></div>
            <div class="form" id="rfields"></div>
            <div class="row" style="margin-top:18px"><button class="btn btn-gold" type="submit">${I.check}<span>${esc(t("save"))}</span></button><button type="button" class="btn btn-ghost" id="rPrintCur">${I.printer}<span>${esc(t("print"))}</span></button><span class="err" id="rErr" role="alert"></span></div></form>
          <div class="row" style="margin:32px 0 12px"><h2 style="font-size:22px;margin:0">${esc(t("records"))} <span class="chip" id="rCount"></span></h2><span class="spacer"></span>${cfg.filter ? `<select id="rFilter" style="width:auto;height:38px" aria-label="filter"><option value="">${esc(t("all"))}</option>${cfg.filter.opts.map((o) => `<option value="${o.v}">${esc(L(o.l))}</option>`).join("")}</select>` : ""}
            <button class="btn btn-ghost btn-sm" id="rCsv">${I.download}<span>${esc(t("exportCsv"))}</span></button><button class="btn btn-ghost btn-sm" id="rJson">${I.download}<span>${esc(t("exportJson"))}</span></button><label class="btn btn-ghost btn-sm" style="cursor:pointer">${I.plus}<span>${esc(t("importJson"))}</span><input type="file" id="rImp" accept="application/json,.json" hidden></label></div>
          ${cfg.below ? `<div id="rBelow"></div>` : ""}
          <div id="rList"></div>
        </div></section>`,
        after: mount,
      };
    }
    function mount() {
      const form = $("#rform");
      const fill = (rec) => {
        editing = rec ? rec.id : null; const r = rec || cfg.defaults();
        $("#formTitle").textContent = rec ? `${t("edit")} — ${cfg.label(rec)}` : t("newRec");
        $("#rfields").innerHTML = cfg.fields.map((f) => field(f, r[f.k])).join("");
        cfg.fields.filter((f) => f.type === "custom").forEach((f) => f.mount($(`[data-custom="${f.k}"]`), r));
        cfg.onFill && cfg.onFill(r);
      };
      const read = () => { const r = {}; cfg.fields.forEach((f) => { if (f.type === "custom") r[f.k] = f.read(); else { const el = $("#f-" + f.k); r[f.k] = f.type === "number" ? (el.value === "" ? "" : Number(el.value)) : el.value.trim(); } }); return r; };
      const validate = (r) => {
        let ok = true;
        cfg.fields.forEach((f) => { if (f.type === "custom") return; const el = $("#f-" + f.k), e = $("#f-" + f.k + "-e"); let msg = f.req && (r[f.k] === "" || r[f.k] == null) ? t("required") : ""; if (!msg && cfg.check) msg = cfg.check(f.k, r) || ""; el.setAttribute("aria-invalid", msg ? "true" : "false"); e.textContent = msg; if (msg) ok = false; });
        if (cfg.extraValid && !cfg.extraValid(r)) ok = false;
        return ok;
      };
      const drawList = () => {
        let all = recs(); $("#rCount").textContent = all.length;
        const fv = $("#rFilter") ? $("#rFilter").value : ""; if (fv) all = all.filter((r) => cfg.filter.test(r, fv));
        $("#rList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr>${cfg.columns.map((c) => `<th>${esc(L(c.l))}</th>`).join("")}<th></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr>${cfg.columns.map((c) => `<td>${c.f(r)}</td>`).join("")}<td style="white-space:nowrap"><button class="icon-btn" data-ed="${r.id}" aria-label="${esc(t("edit"))}" style="width:34px;height:34px">${I.note}</button> <button class="icon-btn" data-pr="${r.id}" aria-label="${esc(t("print"))}" style="width:34px;height:34px">${I.printer}</button> <button class="icon-btn" data-del="${r.id}" aria-label="${esc(t("del"))}" style="width:34px;height:34px">${I.trash}</button></td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`;
        cfg.below && cfg.below($("#rBelow"), recs());
      };
      const doPrint = (r) => printHtml(`${L(list.find((x) => x.id === cfg.id).t)} — ${cfg.label(r)}`, cfg.print(r));
      form.addEventListener("submit", (e) => {
        e.preventDefault(); const r = read();
        if (!validate(r)) { $("#rErr").textContent = t("fixErrors"); const b = $("[aria-invalid=true]", form); b && b.focus(); return; }
        $("#rErr").textContent = "";
        const all = recs(); cfg.compute && cfg.compute(r);
        if (editing) { const i = all.findIndex((x) => x.id === editing); r.id = editing; r.created = all[i] ? all[i].created : Date.now(); r.updated = Date.now(); all[i] = r; }
        else { r.id = uid(); r.created = Date.now(); all.push(r); }
        if (store.set(key, all)) { toast(t("saved")); fill(null); drawList(); }
      });
      $("#rNew").addEventListener("click", () => fill(null));
      $("#rPrintCur").addEventListener("click", () => { const r = read(); cfg.compute && cfg.compute(r); doPrint(r); });
      $("#rList").addEventListener("click", (e) => {
        const ed = e.target.closest("[data-ed]"), pr = e.target.closest("[data-pr]"), del = e.target.closest("[data-del]");
        if (ed) { fill(recs().find((r) => r.id === ed.dataset.ed)); A.scrollTo(form, true); }
        if (pr) doPrint(recs().find((r) => r.id === pr.dataset.pr));
        if (del && confirm(t("confirmDel"))) { store.set(key, recs().filter((r) => r.id !== del.dataset.del)); if (editing === del.dataset.del) fill(null); drawList(); toast(t("deleted")); }
      });
      $("#rFilter") && $("#rFilter").addEventListener("change", drawList);
      $("#rCsv").addEventListener("click", () => { const all = recs(); const keys = cfg.csvKeys || cfg.fields.filter((f) => f.type !== "custom" || f.csv).map((f) => f.k); download(`${cfg.id}-${new Date().toISOString().slice(0, 10)}.csv`, csv([keys, ...all.map((r) => keys.map((k) => (cfg.csvVal ? cfg.csvVal(k, r) : r[k])))]), "text/csv;charset=utf-8"); });
      $("#rJson").addEventListener("click", () => download(`${cfg.id}-${new Date().toISOString().slice(0, 10)}.json`, JSON.stringify({ tool: cfg.id, exported: new Date().toISOString(), records: recs() }, null, 2), "application/json"));
      $("#rImp").addEventListener("change", (e) => { const f = e.target.files[0]; if (!f) return; const fr = new FileReader(); fr.onload = () => { try { const d = JSON.parse(fr.result); const incoming = Array.isArray(d) ? d : d.records; if (!Array.isArray(incoming)) throw 0; const all = recs(); const ids = new Set(all.map((r) => r.id)); incoming.forEach((r) => { if (r && typeof r === "object") { if (!r.id || ids.has(r.id)) r.id = uid(); all.push(r); } }); if (store.set(key, all)) { drawList(); toast(t("imported")); } } catch (_) { toast(t("importFail"), "bad"); } }; fr.readAsText(f); e.target.value = ""; });
      fill(null); drawList();
    }
    return { page, recs, cfg };
  }

  const today = () => new Date().toISOString().slice(0, 10);
  const nowLocal = () => { const d = new Date(); d.setMinutes(d.getMinutes() - d.getTimezoneOffset()); return d.toISOString().slice(0, 16); };
  const opt = (v, a, e) => ({ v, l: { ar: a, en: e } });

  /* ===== NCR ===== */
  const NCR_STATUS = [opt("open", "مفتوحة", "Open"), opt("progress", "قيد التنفيذ", "In Progress"), opt("closed", "أغلقها القسم", "Closed by Department"), opt("verified", "تحقق منها QC", "Verified by QC")];
  const SEV = [opt("minor", "بسيطة", "Minor"), opt("major", "رئيسية", "Major"), opt("critical", "حرجة", "Critical")];
  const sevChip = (v) => { const o = SEV.find((x) => x.v === v); return o ? `<span class="chip ${v === "critical" ? "bad" : v === "major" ? "warn" : ""}">${esc(L(o.l))}</span>` : ""; };
  const stChip = (v) => { const o = NCR_STATUS.find((x) => x.v === v); return o ? `<span class="chip ${v === "verified" ? "ok" : v === "open" ? "bad" : v === "progress" ? "warn" : "teal"}">${esc(L(o.l))}</span>` : ""; };
  let photoState = { before: [], after: [] };
  const photoField = (k, lab) => ({
    k, type: "custom", full: true,
    mount(el, r) {
      photoState[k] = (r[k] || []).slice();
      const draw = () => {
        el.innerHTML = `<span class="lbl">${esc(L(lab))}</span><div class="thumbs">${photoState[k].map((src, i) => `<figure><img src="${src}" alt="${esc(L(lab))} ${i + 1}"><button type="button" data-rm="${i}" aria-label="${esc(t("del"))}">×</button></figure>`).join("")}
          ${photoState[k].length < 3 ? `<label class="btn btn-ghost btn-sm" style="cursor:pointer;height:96px;width:96px;flex-direction:column;border-radius:8px;white-space:normal;text-align:center">${I.camera}<span style="font-size:11.5px">+</span><input type="file" accept="image/*" capture="environment" hidden></label>` : ""}</div><span class="hint">${esc(W("حتى 3 صور، تُصغَّر وتُحفظ على جهازك فقط. لا ترفع صور منشأة دون موافقتها.", "Up to 3 photos, resized and kept on your device only. Don't add photos of a facility without its consent."))}</span>`;
        $$("[data-rm]", el).forEach((b) => b.addEventListener("click", () => { photoState[k].splice(+b.dataset.rm, 1); draw(); }));
        const inp = $("input[type=file]", el);
        inp && inp.addEventListener("change", async () => { const f = inp.files[0]; if (!f) return; try { photoState[k].push(await readImage(f, 800)); draw(); } catch (e) { toast(e.message === "size" ? W("الملف أكبر من 15 ميغابايت.", "File is larger than 15 MB.") : W("نوع الملف غير مدعوم — اختر صورة.", "Unsupported file — choose an image."), "bad"); } });
      };
      draw();
    },
    read() { return photoState[k].slice(); },
  });
  const ncr = recordTool({
    id: "ncr",
    defaults: () => ({ date: today(), status: "open", severity: "minor" }),
    label: (r) => `${r.ref || "NCR"} · ${r.dept || ""}`,
    intro: () => `<div class="card" style="padding:16px 18px"><span class="lbl">${esc(W("مسار الحالة", "Status flow"))}</span><div class="status-flow" style="margin-top:8px">${NCR_STATUS.map((s, i) => `<span class="st">${esc(L(s.l))}</span>${i < 3 ? I.arrow.replace("<svg", '<svg width="14" height="14" style="color:var(--dim)"') : ""}`).join("")}</div><p class="note" style="margin-bottom:0">${esc(W("لا تُغلق الحالة نهائيًا إلا بعد تحقق QC من فاعلية الإجراء.", "A case is only final once QC has verified the action was effective."))} — <a href="#/knowledge/good-ncr">${esc(W("كيف تكتب NCR جيدًا", "How to write a good NCR"))}</a></p></div>`,
    fields: [
      { k: "ref", label: { ar: "رقم التقرير", en: "Report no." }, hint: { ar: "مثال: NCR-2026-014", en: "e.g. NCR-2026-014" } },
      { k: "date", type: "date", label: { ar: "التاريخ", en: "Date" }, req: true },
      { k: "dept", label: { ar: "القسم / الموقع", en: "Department / location" }, req: true },
      { k: "category", type: "select", label: { ar: "الفئة", en: "Category" }, req: true, opts: [opt("hygiene", "النظافة", "Hygiene"), opt("temp", "درجات الحرارة", "Temperature"), opt("pest", "الآفات", "Pest"), opt("storage", "التخزين", "Storage"), opt("docs", "التوثيق", "Documentation"), opt("allergen", "مسببات الحساسية", "Allergen"), opt("foreign", "أجسام غريبة", "Foreign body"), opt("supplier", "الموردون", "Supplier"), opt("equip", "المعدات والصيانة", "Equipment / maintenance"), opt("other", "أخرى", "Other")] },
      { k: "desc", type: "textarea", full: true, label: { ar: "وصف عدم المطابقة", en: "Description of nonconformity" }, req: true, hint: { ar: "اكتب الحقيقة كما رأيتها، والمتطلب الذي لم يُستوفَ.", en: "State the fact as observed, and the requirement not met." } },
      { k: "evidence", type: "textarea", full: true, rows: 2, label: { ar: "الأدلة", en: "Evidence" }, hint: { ar: "قراءة، رقم دفعة، وقت، شاهد…", en: "Reading, batch no., time, witness…" } },
      photoField("before", { ar: "صور قبل", en: "Photos — before" }),
      { k: "correction", type: "textarea", full: true, rows: 2, label: { ar: "الإجراء الفوري / التصحيح", en: "Immediate action / correction" } },
      { k: "rootCause", type: "textarea", full: true, rows: 2, label: { ar: "السبب الجذري", en: "Root cause" }, hint: { ar: "استخدم أداة RCA لتحليل أعمق.", en: "Use the RCA tool for deeper analysis." } },
      { k: "owner", label: { ar: "المسؤول", en: "Owner" }, req: true },
      { k: "severity", type: "select", label: { ar: "مستوى الخطورة", en: "Severity" }, req: true, opts: SEV },
      { k: "status", type: "select", label: { ar: "الحالة", en: "Status" }, req: true, opts: NCR_STATUS },
      { k: "due", type: "date", label: { ar: "تاريخ الاستحقاق", en: "Due date" }, req: true },
      photoField("after", { ar: "صور بعد", en: "Photos — after" }),
      { k: "verification", type: "textarea", full: true, rows: 2, label: { ar: "التحقق من الفاعلية", en: "Effectiveness verification" }, hint: { ar: "مطلوب عند اختيار «تحقق منها QC».", en: "Required when status is \"Verified by QC\"." } },
    ],
    check: (k, r) => (k === "verification" && r.status === "verified" && !r.verification ? t("required") : k === "due" && r.due && r.date && r.due < r.date ? W("يجب أن يكون بعد تاريخ التقرير.", "Must be on or after the report date.") : ""),
    columns: [
      { l: { ar: "الرقم", en: "No." }, f: (r) => esc(r.ref || "—") },
      { l: { ar: "التاريخ", en: "Date" }, f: (r) => esc(fmtDate(r.date)) },
      { l: { ar: "القسم", en: "Dept" }, f: (r) => esc(r.dept) },
      { l: { ar: "الوصف", en: "Description" }, f: (r) => esc((r.desc || "").slice(0, 70)) + ((r.desc || "").length > 70 ? "…" : "") },
      { l: { ar: "الخطورة", en: "Severity" }, f: (r) => sevChip(r.severity) },
      { l: { ar: "الحالة", en: "Status" }, f: (r) => stChip(r.status) + (r.status !== "verified" && r.due && r.due < today() ? ` <span class="chip bad">${esc(W("متأخرة", "Overdue"))}</span>` : "") },
      { l: { ar: "الاستحقاق", en: "Due" }, f: (r) => esc(fmtDate(r.due)) },
    ],
    filter: { opts: NCR_STATUS, test: (r, v) => r.status === v },
    csvKeys: ["ref", "date", "dept", "category", "desc", "evidence", "correction", "rootCause", "owner", "severity", "status", "due", "verification"],
    print: (r) => {
      const fl = (k) => ncr.cfg.fields.find((f) => f.k === k);
      const val = (k) => { const f = fl(k); if (f.type === "select") { const o = f.opts.find((x) => x.v === r[k]); return o ? esc(L(o.l)) : ""; } if (f.type === "date") return esc(fmtDate(r[k])); return esc(r[k] || "").replace(/\n/g, "<br>"); };
      const ph = (arr, lab) => (arr && arr.length ? `<h3 style="margin-top:14px">${esc(L(lab))}</h3><div style="display:flex;gap:8px;flex-wrap:wrap">${arr.map((s) => `<img src="${s}" style="width:200px;height:150px;object-fit:cover;border:1px solid #bbb;border-radius:4px">`).join("")}</div>` : "");
      return `<div class="status-flow" style="margin-bottom:12px">${NCR_STATUS.map((s) => `<span class="st ${s.v === r.status ? "on" : ""}" style="${s.v === r.status ? "background:#ddb03f;color:#111" : ""}">${esc(L(s.l))}</span>`).join(" → ")}</div>` +
        kvTable(["ref", "date", "dept", "category", "severity", "owner", "due", "desc", "evidence", "correction", "rootCause", "verification"].map((k) => [L(fl(k).label), val(k)])) + ph(r.before, { ar: "صور قبل", en: "Before" }) + ph(r.after, { ar: "صور بعد", en: "After" }) +
        `<table class="t" style="min-width:0;margin-top:22px"><tr><th>${esc(W("أعدّه", "Raised by"))}</th><th>${esc(W("المسؤول", "Owner"))}</th><th>${esc(W("تحقق QC", "QC verification"))}</th></tr><tr><td style="height:48px"></td><td></td><td></td></tr></table>`;
    },
  });

  /* ===== RCA / CAPA ===== */
  const FISH = [["man", "الأفراد", "People"], ["machine", "المعدات", "Machine"], ["method", "الطريقة", "Method"], ["material", "المواد", "Material"], ["measure", "القياس", "Measurement"], ["env", "البيئة", "Environment"]];
  let rcaState = { whys: ["", "", "", "", ""], fish: {} };
  const rca = recordTool({
    id: "rca",
    defaults: () => ({ date: today() }),
    label: (r) => (r.problem || "").slice(0, 40),
    fields: [
      { k: "date", type: "date", label: { ar: "التاريخ", en: "Date" }, req: true },
      { k: "ncrRef", label: { ar: "مرتبط بتقرير NCR", en: "Linked NCR no." } },
      { k: "problem", type: "textarea", full: true, rows: 2, req: true, label: { ar: "بيان المشكلة", en: "Problem statement" }, hint: { ar: "ماذا، أين، متى، وكم؟", en: "What, where, when, how much?" } },
      { k: "whys", type: "custom", full: true, csv: true,
        mount(el, r) { rcaState.whys = (r.whys || ["", "", "", "", ""]).slice(); el.innerHTML = `<span class="lbl">${esc(W("5 لماذا", "5 Whys"))}</span><div class="why-chain">${rcaState.whys.map((w, i) => `<div class="field"><label for="why${i}" style="font-weight:500">${esc(W("لماذا", "Why"))} ${i + 1}${i === 0 ? W(" — لماذا حدثت المشكلة؟", " — why did the problem happen?") : W(" — لماذا حدث ذلك؟", " — why did that happen?")}</label><input type="text" id="why${i}" value="${esc(w)}"></div>`).join("")}</div><span class="hint">${esc(W("توقف حين تصل إلى سبب يمكن التحكم فيه ومنعه — ليس بالضرورة عند الخامسة.", "Stop when you reach a cause you can control and prevent — not necessarily at five."))}</span>`; },
        read() { return [0, 1, 2, 3, 4].map((i) => $("#why" + i).value.trim()); } },
      { k: "fish", type: "custom", full: true, csv: true,
        mount(el, r) { const f = r.fish || {}; el.innerHTML = `<span class="lbl">${esc(W("مخطط عظم السمكة (إيشيكاوا) — الأسباب المحتملة", "Fishbone (Ishikawa) — possible causes"))}</span><div class="fishbone">${FISH.map(([k, a, e]) => `<div class="field"><label for="fb-${k}" style="font-weight:500">${esc(W(a, e))}</label><textarea id="fb-${k}" rows="2">${esc(f[k] || "")}</textarea></div>`).join("")}</div>`; },
        read() { const o = {}; FISH.forEach(([k]) => (o[k] = $("#fb-" + k).value.trim())); return o; } },
      { k: "rootCause", type: "textarea", full: true, rows: 2, req: true, label: { ar: "السبب الجذري المعتمد", en: "Confirmed root cause" } },
      { k: "corrective", type: "textarea", full: true, rows: 2, req: true, label: { ar: "الإجراء التصحيحي", en: "Corrective action" } },
      { k: "preventive", type: "textarea", full: true, rows: 2, label: { ar: "الإجراء الوقائي (عند الحاجة)", en: "Preventive action (if needed)" } },
      { k: "owner", label: { ar: "المسؤول", en: "Owner" }, req: true },
      { k: "due", type: "date", label: { ar: "الموعد", en: "Due date" }, req: true },
      { k: "effective", type: "select", label: { ar: "التحقق من الفاعلية", en: "Effectiveness check" }, opts: [opt("pending", "بانتظار التحقق", "Pending"), opt("yes", "فعّال — تُغلق الحالة", "Effective — close case"), opt("no", "غير فعّال — إعادة التحليل", "Not effective — re-analyse")] },
      { k: "effNote", type: "textarea", full: true, rows: 2, label: { ar: "دليل التحقق", en: "Verification evidence" } },
    ],
    check: (k, r) => (k === "effNote" && r.effective === "yes" && !r.effNote ? t("required") : ""),
    columns: [
      { l: { ar: "التاريخ", en: "Date" }, f: (r) => esc(fmtDate(r.date)) },
      { l: { ar: "المشكلة", en: "Problem" }, f: (r) => esc((r.problem || "").slice(0, 60)) },
      { l: { ar: "السبب الجذري", en: "Root cause" }, f: (r) => esc((r.rootCause || "").slice(0, 60)) },
      { l: { ar: "المسؤول", en: "Owner" }, f: (r) => esc(r.owner) },
      { l: { ar: "الفاعلية", en: "Effective" }, f: (r) => (r.effective === "yes" ? `<span class="chip ok">✓</span>` : r.effective === "no" ? `<span class="chip bad">✗</span>` : `<span class="chip">…</span>`) },
    ],
    csvKeys: ["date", "ncrRef", "problem", "whys", "fish", "rootCause", "corrective", "preventive", "owner", "due", "effective", "effNote"],
    csvVal: (k, r) => (k === "whys" ? (r.whys || []).filter(Boolean).map((w, i) => `${i + 1}) ${w}`).join(" | ") : k === "fish" ? FISH.map(([f, a, e]) => (r.fish && r.fish[f] ? `${W(a, e)}: ${r.fish[f]}` : "")).filter(Boolean).join(" | ") : r[k]),
    print: (r) => kvTable([[W("التاريخ", "Date"), esc(fmtDate(r.date))], [W("تقرير NCR", "NCR no."), esc(r.ncrRef)], [W("المشكلة", "Problem"), esc(r.problem)]]) +
      `<h3 style="margin-top:14px">${esc(W("5 لماذا", "5 Whys"))}</h3><ol>${(r.whys || []).filter(Boolean).map((w) => `<li>${esc(w)}</li>`).join("")}</ol>` +
      `<h3>${esc(W("عظم السمكة", "Fishbone"))}</h3>${kvTable(FISH.map(([k, a, e]) => [W(a, e), esc((r.fish || {})[k] || "")]))}` +
      `<h3 style="margin-top:14px">CAPA</h3>${kvTable([[W("السبب الجذري", "Root cause"), esc(r.rootCause)], [W("تصحيحي", "Corrective"), esc(r.corrective)], [W("وقائي", "Preventive"), esc(r.preventive)], [W("المسؤول", "Owner"), esc(r.owner)], [W("الموعد", "Due"), esc(fmtDate(r.due))], [W("الفاعلية", "Effectiveness"), esc({ yes: W("فعّال", "Effective"), no: W("غير فعّال", "Not effective"), pending: W("بانتظار", "Pending") }[r.effective] || "")], [W("الدليل", "Evidence"), esc(r.effNote)]])}`,
  });

  /* ===== Risk ===== */
  const LIK = [["نادر", "Rare"], ["غير مرجح", "Unlikely"], ["ممكن", "Possible"], ["مرجح", "Likely"], ["شبه مؤكد", "Almost certain"]];
  const SEVR = [["طفيف", "Negligible"], ["بسيط", "Minor"], ["متوسط", "Moderate"], ["كبير", "Major"], ["جسيم", "Severe"]];
  const band = (s) => (s >= 17 ? ["crit", W("حرج", "Critical")] : s >= 10 ? ["high", W("مرتفع", "High")] : s >= 5 ? ["med", W("متوسط", "Medium")] : ["low", W("منخفض", "Low")]);
  const lvChip = (s) => { if (!s) return ""; const [c, l] = band(s); return `<span class="chip" style="background:var(--x);color:#111;border:0" data-lv="${c}"><b>${s}</b> ${esc(l)}</span>`.replace("var(--x)", { low: "#5fbf8f", med: "#e6c24a", high: "#ec8a3c", crit: "#e5645a" }[c]); };
  let riskSel = { l: 0, s: 0 };
  const matrixHtml = (sel, interactive) => `<div class="matrix" role="${interactive ? "grid" : "img"}" aria-label="${esc(W("مصفوفة المخاطر", "Risk matrix"))}"><div class="ax"></div>${[1, 2, 3, 4, 5].map((s) => `<div class="ax" title="${esc(W(...SEVR[s - 1]))}">S${s}</div>`).join("")}${[5, 4, 3, 2, 1].map((l) => `<div class="ax" title="${esc(W(...LIK[l - 1]))}">L${l}</div>${[1, 2, 3, 4, 5].map((s) => `<${interactive ? "button type=button" : "div"} class="c lv-${band(l * s)[0]} ${sel.l === l && sel.s === s ? "sel" : ""}" data-l="${l}" data-s="${s}" aria-label="L${l} × S${s} = ${l * s}">${l * s}</${interactive ? "button" : "div"}>`).join("")}`).join("")}</div>`;
  const risk = recordTool({
    id: "risk",
    defaults: () => ({ date: today(), l: "", s: "" }),
    label: (r) => (r.hazard || "").slice(0, 40),
    intro: () => `<div class="card" style="padding:16px 18px"><b>${esc(W("المصفوفة المعلنة", "Declared matrix"))}:</b> <span style="color:var(--muted)">${esc(W("مستوى المخاطر = الاحتمالية (1–5) × الشدة (1–5). منخفض 1–4 · متوسط 5–9 · مرتفع 10–16 · حرج 17–25. عدّل المعايير وفق إجراء منشأتك.", "Risk level = likelihood (1–5) × severity (1–5). Low 1–4 · Medium 5–9 · High 10–16 · Critical 17–25. Adapt the criteria to your site procedure."))}</span></div>`,
    fields: [
      { k: "date", type: "date", label: { ar: "التاريخ", en: "Date" }, req: true },
      { k: "step", label: { ar: "الخطوة / النشاط", en: "Process step / activity" }, req: true },
      { k: "hazard", type: "textarea", full: true, rows: 2, req: true, label: { ar: "وصف الخطر", en: "Hazard description" } },
      { k: "type", type: "select", req: true, label: { ar: "نوع الخطر", en: "Hazard type" }, opts: [opt("bio", "بيولوجي", "Biological"), opt("chem", "كيميائي", "Chemical"), opt("phys", "فيزيائي", "Physical"), opt("allergen", "مسببات حساسية", "Allergen"), opt("ops", "تشغيلي", "Operational")] },
      { k: "controls", type: "textarea", rows: 2, label: { ar: "الضوابط الحالية", en: "Current controls" } },
      { k: "ls", type: "custom", full: true,
        mount(el, r) { riskSel = { l: +r.l || 0, s: +r.s || 0 }; const draw = () => { el.innerHTML = `<span class="lbl req">${esc(W("الاحتمالية × الشدة — اضغط خلية", "Likelihood × severity — tap a cell"))}</span><div class="grid g2" style="align-items:center"><div style="max-width:380px">${matrixHtml(riskSel, true)}</div><div>${riskSel.l ? `<p style="margin:0 0 6px">${esc(W("الاحتمالية", "Likelihood"))}: <b>${riskSel.l} — ${esc(W(...LIK[riskSel.l - 1]))}</b></p><p style="margin:0 0 10px">${esc(W("الشدة", "Severity"))}: <b>${riskSel.s} — ${esc(W(...SEVR[riskSel.s - 1]))}</b></p>${lvChip(riskSel.l * riskSel.s)}` : `<p class="note">${esc(W("لم يُحدد بعد.", "Not set yet."))}</p>`}<span class="err" id="ls-e"></span></div></div>`; $$(".matrix .c", el).forEach((c) => c.addEventListener("click", () => { riskSel = { l: +c.dataset.l, s: +c.dataset.s }; draw(); const n = $(`.matrix .c[data-l="${riskSel.l}"][data-s="${riskSel.s}"]`, el); n && n.focus(); })); }; draw(); },
        read() { return riskSel.l ? `${riskSel.l}x${riskSel.s}` : ""; } },
      { k: "extra", type: "textarea", rows: 2, label: { ar: "ضوابط إضافية", en: "Additional controls" } },
      { k: "owner", label: { ar: "المسؤول", en: "Owner" }, req: true },
      { k: "review", type: "date", label: { ar: "تاريخ المراجعة", en: "Review date" }, req: true },
    ],
    compute: (r) => { if (r.ls) { const [l, s] = r.ls.split("x").map(Number); r.l = l; r.s = s; r.score = l * s; } },
    extraValid: (r) => { const e = $("#ls-e"); if (e) e.textContent = r.ls ? "" : t("required"); return !!r.ls; },
    columns: [
      { l: { ar: "الخطوة", en: "Step" }, f: (r) => esc(r.step) },
      { l: { ar: "الخطر", en: "Hazard" }, f: (r) => esc((r.hazard || "").slice(0, 60)) },
      { l: { ar: "النوع", en: "Type" }, f: (r) => esc(L((risk_types.find((o) => o.v === r.type) || { l: "" }).l)) },
      { l: "L×S", f: (r) => (r.l ? `${r.l}×${r.s}` : "") },
      { l: { ar: "المستوى", en: "Level" }, f: (r) => lvChip(r.score) },
      { l: { ar: "المسؤول", en: "Owner" }, f: (r) => esc(r.owner) },
      { l: { ar: "المراجعة", en: "Review" }, f: (r) => esc(fmtDate(r.review)) },
    ],
    csvKeys: ["date", "step", "hazard", "type", "controls", "l", "s", "score", "extra", "owner", "review"],
    below: (el, all) => { if (!all.length) { el.innerHTML = ""; return; } const counts = { low: 0, med: 0, high: 0, crit: 0 }; all.forEach((r) => r.score && counts[band(r.score)[0]]++); el.innerHTML = `<div class="row" style="margin-bottom:12px">${Object.entries(counts).map(([k, n]) => `<span class="chip lv-${k}" style="color:#111;border:0">${n} · ${esc({ low: W("منخفض", "Low"), med: W("متوسط", "Medium"), high: W("مرتفع", "High"), crit: W("حرج", "Critical") }[k])}</span>`).join("")}</div>`; },
    print: (r) => kvTable([[W("الخطوة", "Step"), esc(r.step)], [W("الخطر", "Hazard"), esc(r.hazard)], [W("النوع", "Type"), esc(L((risk_types.find((o) => o.v === r.type) || { l: "" }).l))], [W("الضوابط الحالية", "Current controls"), esc(r.controls)], [W("الاحتمالية", "Likelihood"), r.l ? `${r.l} — ${esc(W(...LIK[r.l - 1]))}` : ""], [W("الشدة", "Severity"), r.s ? `${r.s} — ${esc(W(...SEVR[r.s - 1]))}` : ""], [W("المستوى", "Level"), r.score ? `${r.score} — ${esc(band(r.score)[1])}` : ""], [W("ضوابط إضافية", "Additional controls"), esc(r.extra)], [W("المسؤول", "Owner"), esc(r.owner)], [W("المراجعة", "Review"), esc(fmtDate(r.review))]]) + `<div style="max-width:320px;margin-top:14px">${matrixHtml({ l: r.l, s: r.s }, false)}</div>`,
  });
  const risk_types = [opt("bio", "بيولوجي", "Biological"), opt("chem", "كيميائي", "Chemical"), opt("phys", "فيزيائي", "Physical"), opt("allergen", "مسببات حساسية", "Allergen"), opt("ops", "تشغيلي", "Operational")];

  /* ===== Temperature log ===== */
  const TYPES = [opt("chill", "تبريد", "Chiller"), opt("freeze", "تجميد", "Freezer"), opt("hot", "حفظ ساخن", "Hot holding"), opt("cook", "طهي", "Cooking"), opt("receive", "استلام", "Receiving"), opt("cool", "تبريد بعد الطهي", "Cooling"), opt("other", "أخرى", "Other")];
  const isDev = (r) => r.reading !== "" && r.reading != null && ((r.min !== "" && r.min != null && r.reading < r.min) || (r.max !== "" && r.max != null && r.reading > r.max));
  const temp = recordTool({
    id: "temp",
    defaults: () => ({ at: nowLocal() }),
    label: (r) => `${r.equip || ""} · ${r.reading ?? ""}°C`,
    intro: () => `<datalist id="equipList">${[...new Set(temp.recs().map((r) => r.equip))].map((e) => `<option value="${esc(e)}">`).join("")}</datalist>`,
    onFill: () => { const eq = $("#f-equip"); eq && eq.addEventListener("change", () => { const last = temp.recs().filter((r) => r.equip === eq.value).pop(); if (last) { ["type", "min", "max"].forEach((k) => { const el = $("#f-" + k); if (el && el.value === "") el.value = last[k] ?? ""; }); } }); const rd = $("#f-reading"); const flag = () => { const r = { reading: rd.value === "" ? "" : +rd.value, min: $("#f-min").value === "" ? "" : +$("#f-min").value, max: $("#f-max").value === "" ? "" : +$("#f-max").value }; $("#devFlag").innerHTML = rd.value === "" ? "" : isDev(r) ? `<span class="chip bad">${I.warn.replace("<svg", '<svg width="14" height="14"')} ${esc(W("انحراف — سجّل الإجراء المتخذ", "Deviation — record the action taken"))}</span>` : `<span class="chip ok">${esc(W("ضمن الحدود", "Within limits"))}</span>`; }; ["f-reading", "f-min", "f-max"].forEach((id) => $("#" + id).addEventListener("input", flag)); flag(); },
    fields: [
      { k: "equip", label: { ar: "الجهاز / المنتج", en: "Unit / product" }, req: true, list: "equipList", hint: { ar: "مثال: ثلاجة 2 — الألبان", en: "e.g. Fridge 2 — dairy" } },
      { k: "type", type: "select", label: { ar: "النوع", en: "Type" }, req: true, opts: TYPES },
      { k: "min", type: "number", step: "0.1", label: { ar: "الحد الأدنى °م", en: "Min limit °C" }, hint: { ar: "من إجرائك أو التشريع المعمول به", en: "From your procedure or applicable regulation" } },
      { k: "max", type: "number", step: "0.1", label: { ar: "الحد الأعلى °م", en: "Max limit °C" } },
      { k: "reading", type: "number", step: "0.1", label: { ar: "القراءة °م", en: "Reading °C" }, req: true },
      { k: "at", type: "datetime-local", label: { ar: "الوقت", en: "Time" }, req: true },
      { k: "by", label: { ar: "بواسطة", en: "By" }, req: true },
      { k: "flag", type: "custom", mount(el) { el.innerHTML = `<span class="lbl">&nbsp;</span><div id="devFlag" aria-live="polite"></div>`; }, read() { return ""; } },
      { k: "action", type: "textarea", full: true, rows: 2, label: { ar: "الإجراء المتخذ عند الانحراف", en: "Action taken on deviation" } },
    ],
    check: (k, r) => (k === "min" && r.min === "" && r.max === "" ? W("حدد حدًا واحدًا على الأقل.", "Set at least one limit.") : k === "max" && r.min !== "" && r.max !== "" && r.max < r.min ? W("الحد الأعلى أقل من الأدنى.", "Max is below min.") : k === "action" && isDev(r) && !r.action ? t("required") : ""),
    compute: (r) => { r.deviation = isDev(r); },
    columns: [
      { l: { ar: "الوقت", en: "Time" }, f: (r) => esc(r.at ? r.at.replace("T", " ") : "") },
      { l: { ar: "الجهاز", en: "Unit" }, f: (r) => esc(r.equip) },
      { l: { ar: "القراءة", en: "Reading" }, f: (r) => `<b dir="ltr">${esc(r.reading)}°C</b>` },
      { l: { ar: "الحدود", en: "Limits" }, f: (r) => `<span dir="ltr">${r.min !== "" && r.min != null ? esc(r.min) : "−∞"} … ${r.max !== "" && r.max != null ? esc(r.max) : "+∞"}</span>` },
      { l: { ar: "النتيجة", en: "Result" }, f: (r) => (isDev(r) ? `<span class="chip bad">${esc(W("انحراف", "Deviation"))}</span>` : `<span class="chip ok">OK</span>`) },
      { l: { ar: "بواسطة", en: "By" }, f: (r) => esc(r.by) },
    ],
    filter: { opts: [opt("dev", "الانحرافات فقط", "Deviations only")], test: (r) => isDev(r) },
    csvKeys: ["at", "equip", "type", "min", "max", "reading", "deviation", "by", "action"],
    below: (el, all) => {
      const eqs = [...new Set(all.map((r) => r.equip))]; if (!eqs.length) { el.innerHTML = ""; return; }
      const cur = el.dataset.eq && eqs.includes(el.dataset.eq) ? el.dataset.eq : eqs[0];
      const pts = all.filter((r) => r.equip === cur && r.at).sort((a, b) => (a.at < b.at ? -1 : 1)).slice(-30);
      const vals = pts.map((p) => p.reading); const lim = pts[pts.length - 1] || {};
      const lo = Math.min(...vals, lim.min !== "" && lim.min != null ? lim.min : Infinity) - 2, hi = Math.max(...vals, lim.max !== "" && lim.max != null ? lim.max : -Infinity) + 2;
      const Wd = 640, H = 220, pad = 34; const x = (i) => pad + (pts.length < 2 ? (Wd - pad * 2) / 2 : (i * (Wd - pad * 2)) / (pts.length - 1)); const y = (v) => H - pad + 10 - ((v - lo) / (hi - lo || 1)) * (H - pad * 1.6);
      const ticks = [lo + 2, (lo + hi) / 2, hi - 2].map((v) => Math.round(v * 10) / 10);
      el.innerHTML = `<div class="card" style="margin-bottom:16px"><div class="row"><h3 style="margin:0;font-size:16px">${esc(W("اتجاه القراءات", "Reading trend"))}</h3><span class="spacer"></span><select id="eqSel" style="width:auto;height:38px" aria-label="unit">${eqs.map((e) => `<option ${e === cur ? "selected" : ""}>${esc(e)}</option>`).join("")}</select></div>
        <svg class="chart" viewBox="0 0 ${Wd} ${H}" role="img" aria-label="${esc(cur)}" style="direction:ltr">
          ${ticks.map((v) => `<line x1="${pad}" x2="${Wd - pad}" y1="${y(v)}" y2="${y(v)}" stroke="rgba(255,255,255,.07)"/><text x="${pad - 6}" y="${y(v) + 4}" fill="#8f8f8f" font-size="11" text-anchor="end">${v}</text>`).join("")}
          ${lim.max !== "" && lim.max != null ? `<line x1="${pad}" x2="${Wd - pad}" y1="${y(lim.max)}" y2="${y(lim.max)}" stroke="#e5645a" stroke-dasharray="5 4"/><text x="${Wd - pad}" y="${y(lim.max) - 5}" fill="#e5645a" font-size="11" text-anchor="end">max ${lim.max}</text>` : ""}
          ${lim.min !== "" && lim.min != null ? `<line x1="${pad}" x2="${Wd - pad}" y1="${y(lim.min)}" y2="${y(lim.min)}" stroke="#53b9ad" stroke-dasharray="5 4"/><text x="${Wd - pad}" y="${y(lim.min) + 14}" fill="#53b9ad" font-size="11" text-anchor="end">min ${lim.min}</text>` : ""}
          <polyline fill="none" stroke="#ddb03f" stroke-width="2.5" stroke-linejoin="round" points="${pts.map((p, i) => `${x(i)},${y(p.reading)}`).join(" ")}"/>
          ${pts.map((p, i) => `<circle cx="${x(i)}" cy="${y(p.reading)}" r="4.5" fill="${isDev(p) ? "#e5645a" : "#ddb03f"}" stroke="#171717" stroke-width="2"><title>${esc(p.at.replace("T", " "))} — ${p.reading}°C</title></circle>`).join("")}
        </svg><p class="note" style="margin:0">${esc(W("آخر 30 قراءة. النقاط الحمراء انحرافات.", "Last 30 readings. Red points are deviations."))}</p></div>`;
      $("#eqSel", el).addEventListener("change", (e) => { el.dataset.eq = e.target.value; temp.cfg.below(el, temp.recs()); });
    },
    print: (r) => kvTable([[W("الجهاز", "Unit"), esc(r.equip)], [W("الوقت", "Time"), esc((r.at || "").replace("T", " "))], [W("القراءة", "Reading"), esc(r.reading) + "°C"], [W("الحدود", "Limits"), `${esc(r.min)} … ${esc(r.max)}`], [W("النتيجة", "Result"), isDev(r) ? W("انحراف", "Deviation") : "OK"], [W("بواسطة", "By"), esc(r.by)], [W("الإجراء", "Action"), esc(r.action)]]),
  });

  /* ===== Inspection checklist ===== */
  const SECTIONS = [
    ["premises", "المبنى والمرافق", "Premises & facilities", [["الأرضيات والجدران والأسقف سليمة ونظيفة", "Floors, walls and ceilings intact and clean"], ["الأبواب والنوافذ محكمة أو مزودة بشبك", "Doors and windows close tightly or are screened"], ["الإضاءة كافية ومحمية", "Lighting adequate and protected"], ["التهوية مناسبة ولا تكاثف فوق الغذاء", "Ventilation adequate, no condensation over food"]]],
    ["hygiene", "النظافة الشخصية", "Personal hygiene", [["مغاسل الأيدي متاحة ومزودة بالصابون والمناديل", "Handwash sinks accessible and stocked"], ["العاملون بملابس نظيفة وغطاء شعر", "Staff in clean clothes and hair cover"], ["لا مجوهرات ولا أكل أو شرب في مناطق التحضير", "No jewellery, eating or drinking in prep areas"], ["الإقرار الصحي اليومي مكتمل", "Daily health declaration complete"], ["الجروح مغطاة بضمادة ملونة", "Wounds covered with coloured dressing"]]],
    ["cleaning", "التنظيف والتطهير", "Cleaning & sanitation", [["جدول التنظيف معلن ومنفذ وموقّع", "Cleaning schedule posted, done and signed"], ["الأسطح الملامسة للغذاء نظيفة", "Food-contact surfaces clean"], ["المواد الكيميائية معرّفة ومخزنة منفصلة", "Chemicals labelled and stored separately"], ["أدوات التنظيف نظيفة ومخزنة بشكل صحيح", "Cleaning tools clean and stored correctly"]]],
    ["storage", "التخزين ودرجات الحرارة", "Storage & temperature", [["سجلات حرارة الثلاجات والمجمدات مكتملة", "Fridge/freezer temperature logs complete"], ["المواد مرفوعة عن الأرض وبعيدة عن الجدران", "Materials off the floor and away from walls"], ["تطبيق FIFO/FEFO والملصقات مؤرخة", "FIFO/FEFO applied, labels dated"], ["فصل الخام عن الجاهز للأكل", "Raw separated from ready-to-eat"], ["لا مواد منتهية الصلاحية", "No expired items"]]],
    ["pest", "مكافحة الآفات", "Pest control", [["لا دلائل على نشاط آفات", "No signs of pest activity"], ["المصائد والطعوم في أماكنها ومرقمة", "Traps and bait stations in place and numbered"], ["تقرير زيارة شركة المكافحة حديث", "Pest contractor visit report up to date"]]],
    ["handling", "تداول الغذاء", "Food handling", [["أدوات وألواح مفصولة حسب نوع الغذاء", "Utensils/boards segregated by food type"], ["التذويب بطريقة آمنة", "Thawing done safely"], ["مسببات الحساسية معرّفة ومفصولة", "Allergens identified and segregated"], ["لا أغذية مطهوة تبرد على الطاولة", "No cooked food cooling on the bench"]]],
    ["docs", "التوثيق", "Documentation", [["السجلات اليومية مكتملة وموقّعة", "Daily records complete and signed"], ["شهادات التدريب والشهادات الصحية متاحة", "Training and health certificates available"], ["معايرة أجهزة القياس موثقة", "Thermometer calibration recorded"]]],
  ];
  function inspectionPage() {
    const tool = list.find((x) => x.id === "inspection");
    const draftKey = "tool:inspection:draft", recKey = "tool:inspection";
    const blank = () => ({ id: uid(), site: "", date: today(), by: "", custom: {}, ans: {}, notes: {} });
    let d = store.get(draftKey, null) || blank();
    const items = (sec) => sec[3].map((it, i) => ({ id: sec[0] + i, txt: W(it[0], it[1]) })).concat((d.custom[sec[0]] || []).map((c, i) => ({ id: sec[0] + "c" + i, txt: c, custom: i })));
    const score = (secs) => { let y = 0, n = 0; secs.forEach((s) => items(s).forEach((it) => { if (d.ans[it.id] === "y") y++; if (d.ans[it.id] === "n") n++; })); return { y, n, pct: y + n ? Math.round((y / (y + n)) * 100) : null }; };
    const ring = (pct) => { const c = 2 * Math.PI * 40, col = pct == null ? "#555" : pct >= 90 ? "#53b9ad" : pct >= 75 ? "#e6c24a" : "#e5645a"; return `<svg class="ring" viewBox="0 0 96 96"><circle cx="48" cy="48" r="40" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="9"/><circle cx="48" cy="48" r="40" fill="none" stroke="${col}" stroke-width="9" stroke-linecap="round" stroke-dasharray="${((pct || 0) / 100) * c} ${c}" transform="rotate(-90 48 48)"/></svg>`; };
    const save = () => store.set(draftKey, d);
    return {
      title: L(tool.t),
      html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}<section class="sec"><div class="wrap">${disclaimer()}
        <div class="card" style="margin-top:18px"><div class="form">
          <div class="field"><label for="i-site" class="req">${esc(W("المنشأة / القسم", "Site / department"))}</label><input id="i-site" type="text"><span class="err" id="i-site-e"></span></div>
          <div class="field"><label for="i-date" class="req">${esc(W("التاريخ", "Date"))}</label><input id="i-date" type="date"></div>
          <div class="field"><label for="i-by" class="req">${esc(W("المفتش", "Inspector"))}</label><input id="i-by" type="text"><span class="err" id="i-by-e"></span></div>
          <div class="field"><span class="lbl">${esc(W("النتيجة الإجمالية", "Overall result"))}</span><div class="gauge" id="gTotal"></div></div>
        </div><p class="note">${esc(W("نسبة الامتثال = مطابق ÷ (مطابق + غير مطابق) × 100. البنود «لا ينطبق» لا تُحتسب.", "Compliance % = Yes ÷ (Yes + No) × 100. \"N/A\" items are excluded."))}</p></div>
        <div id="secs" style="margin-top:18px"></div>
        <div class="row" style="margin-top:18px"><button class="btn btn-gold" id="iSave">${I.check}<span>${esc(W("حفظ التفتيش", "Save inspection"))}</span></button><button class="btn btn-ghost" id="iPrint">${I.printer}<span>${esc(t("print"))}</span></button><button class="btn btn-ghost" id="iNcr">${I.alert}<span>${esc(W("تحويل الملاحظات إلى NCR", "Raise NCRs from findings"))}</span></button><span class="spacer"></span><button class="btn btn-danger btn-sm" id="iClear">${I.trash}<span>${esc(W("مسح المسودة", "Clear draft"))}</span></button></div>
        <h2 style="font-size:22px;margin:34px 0 12px">${esc(W("التفتيشات المحفوظة", "Saved inspections"))}</h2><div id="iList"></div>
      </div></section>`,
      after() {
        const head = () => { $("#i-site").value = d.site; $("#i-date").value = d.date; $("#i-by").value = d.by; };
        ["site", "date", "by"].forEach((k) => $("#i-" + k).addEventListener("input", (e) => { d[k] = e.target.value; save(); }));
        const draw = () => {
          const tot = score(SECTIONS);
          $("#gTotal").innerHTML = `${ring(tot.pct)}<div><b>${tot.pct == null ? "—" : tot.pct + "%"}</b><div class="note" style="margin:0">${tot.y} ✓ · ${tot.n} ✗</div></div>`;
          $("#secs").innerHTML = SECTIONS.map((s) => { const sc = score([s]); return `<div class="card ck-sec"><h3><span>${esc(W(s[1], s[2]))}</span><span class="chip ${sc.pct == null ? "" : sc.pct >= 90 ? "ok" : sc.pct >= 75 ? "warn" : "bad"}">${sc.pct == null ? "—" : sc.pct + "%"}</span></h3>
            ${items(s).map((it) => `<div class="ck-item ${d.notes[it.id] != null ? "has-note" : ""}"><span class="txt">${esc(it.txt)}</span><div class="row" style="gap:6px"><div class="seg" role="group" aria-label="${esc(it.txt)}">${[["y", W("نعم", "Yes")], ["n", W("لا", "No")], ["na", W("لا ينطبق", "N/A")]].map(([v, l]) => `<button type="button" data-it="${it.id}" data-v="${v}" aria-pressed="${d.ans[it.id] === v}">${l}</button>`).join("")}<button type="button" class="note-btn" data-note="${it.id}" aria-label="${esc(W("ملاحظة", "Note"))}" title="${esc(W("ملاحظة", "Note"))}">${I.note.replace("<svg", '<svg width="15" height="15"')}</button></div>${it.custom != null ? `<button type="button" class="icon-btn" style="width:34px;height:34px" data-rmc="${s[0]}:${it.custom}" aria-label="${esc(t("del"))}">${I.trash}</button>` : ""}</div><textarea data-nt="${it.id}" placeholder="${esc(W("الملاحظة أو الدليل…", "Finding or evidence…"))}" aria-label="${esc(W("ملاحظة", "Note"))}">${esc(d.notes[it.id] || "")}</textarea></div>`).join("")}
            <div class="row" style="margin-top:10px"><input type="text" placeholder="${esc(W("أضف بندًا مخصصًا…", "Add a custom item…"))}" data-addin="${s[0]}" style="flex:1;min-width:180px;height:38px" aria-label="${esc(W("بند مخصص", "Custom item"))}"><button type="button" class="btn btn-ghost btn-sm" data-add="${s[0]}">${I.plus}<span>${esc(W("إضافة", "Add"))}</span></button></div></div>`; }).join("");
        };
        $("#secs").addEventListener("click", (e) => {
          const b = e.target.closest("[data-it]"), nb = e.target.closest("[data-note]"), ad = e.target.closest("[data-add]"), rm = e.target.closest("[data-rmc]");
          if (b) { d.ans[b.dataset.it] = d.ans[b.dataset.it] === b.dataset.v ? undefined : b.dataset.v; if (b.dataset.v === "n" && d.notes[b.dataset.it] == null) d.notes[b.dataset.it] = ""; save(); draw(); const nb2 = $(`[data-it="${b.dataset.it}"][data-v="${b.dataset.v}"]`); nb2 && nb2.focus(); if (b.dataset.v === "n") { const ta = $(`[data-nt="${b.dataset.it}"]`); ta && ta.focus(); } }
          if (nb) { if (d.notes[nb.dataset.note] == null) d.notes[nb.dataset.note] = ""; else if (!d.notes[nb.dataset.note]) delete d.notes[nb.dataset.note]; save(); draw(); const ta = $(`[data-nt="${nb.dataset.note}"]`); ta && ta.focus(); }
          if (ad) { const inp = $(`[data-addin="${ad.dataset.add}"]`); const v = inp.value.trim(); if (!v) { inp.focus(); return; } (d.custom[ad.dataset.add] = d.custom[ad.dataset.add] || []).push(v); save(); draw(); }
          if (rm) { const [sec, i] = rm.dataset.rmc.split(":"); d.custom[sec].splice(+i, 1); Object.keys(d.ans).filter((k) => k.startsWith(sec + "c")).forEach((k) => delete d.ans[k]); save(); draw(); }
        });
        $("#secs").addEventListener("input", (e) => { const ta = e.target.closest("[data-nt]"); if (ta) { d.notes[ta.dataset.nt] = ta.value; save(); } });
        $("#secs").addEventListener("keydown", (e) => { const inp = e.target.closest("[data-addin]"); if (inp && e.key === "Enter") { e.preventDefault(); $(`[data-add="${inp.dataset.addin}"]`).click(); } });
        const valid = () => { let ok = true; ["site", "by"].forEach((k) => { const bad = !d[k].trim(); $("#i-" + k).setAttribute("aria-invalid", bad); $("#i-" + k + "-e").textContent = bad ? t("required") : ""; if (bad) ok = false; }); if (!ok) { toast(t("fixErrors"), "bad"); $("[aria-invalid=true]").focus(); } return ok; };
        const report = (r) => { const prev = d; d = r; const tot = score(SECTIONS); const html = kvTable([[W("المنشأة / القسم", "Site / department"), esc(r.site)], [W("التاريخ", "Date"), esc(fmtDate(r.date))], [W("المفتش", "Inspector"), esc(r.by)], [W("النتيجة الإجمالية", "Overall result"), `<b>${tot.pct == null ? "—" : tot.pct + "%"}</b> (${tot.y} ✓ / ${tot.n} ✗)`]]) + SECTIONS.map((s) => { const sc = score([s]); return `<h3 style="margin-top:14px">${esc(W(s[1], s[2]))} — ${sc.pct == null ? "—" : sc.pct + "%"}</h3><table class="t" style="min-width:0">${items(s).map((it) => `<tr><td>${esc(it.txt)}${r.notes[it.id] ? `<div style="font-size:9.5pt;color:#555">↳ ${esc(r.notes[it.id])}</div>` : ""}</td><td style="width:70px;text-align:center"><b>${{ y: "✓", n: "✗", na: "N/A" }[r.ans[it.id]] || "—"}</b></td></tr>`).join("")}</table>`; }).join("") + `<table class="t" style="min-width:0;margin-top:22px"><tr><th>${esc(W("توقيع المفتش", "Inspector signature"))}</th><th>${esc(W("توقيع مسؤول القسم", "Department lead signature"))}</th></tr><tr><td style="height:48px"></td><td></td></tr></table>`; d = prev; return html; };
        $("#iPrint").addEventListener("click", () => printHtml(`${L(tool.t)} — ${d.site || ""}`, report(d)));
        $("#iSave").addEventListener("click", () => { if (!valid()) return; const all = store.get(recKey, []); const tot = score(SECTIONS); const rec = JSON.parse(JSON.stringify(d)); rec.pct = tot.pct; rec.saved = Date.now(); const i = all.findIndex((x) => x.id === rec.id); i >= 0 ? (all[i] = rec) : all.push(rec); if (store.set(recKey, all)) { toast(t("saved")); drawList(); } });
        $("#iClear").addEventListener("click", () => { if (confirm(W("مسح المسودة الحالية والبدء من جديد؟", "Clear the current draft and start over?"))) { d = blank(); save(); head(); draw(); } });
        $("#iNcr").addEventListener("click", () => {
          const fails = []; SECTIONS.forEach((s) => items(s).forEach((it) => { if (d.ans[it.id] === "n") fails.push({ s, it }); }));
          if (!fails.length) { toast(W("لا توجد بنود «لا» لتحويلها.", "No \"No\" items to raise."), "bad"); return; }
          if (!valid()) return;
          const all = store.get("tool:ncr", []); fails.forEach(({ s, it }) => all.push({ id: uid(), created: Date.now(), date: d.date, dept: d.site, category: { premises: "equip", hygiene: "hygiene", cleaning: "hygiene", storage: "storage", pest: "pest", handling: "hygiene", docs: "docs" }[s[0]], desc: it.txt + (d.notes[it.id] ? " — " + d.notes[it.id] : ""), evidence: `${W("تفتيش", "Inspection")} ${d.date} — ${d.by}`, owner: "", severity: "minor", status: "open", due: "", before: [], after: [] }));
          if (store.set("tool:ncr", all)) toast(W(`أُنشئ ${fails.length} تقرير — أكمل المسؤول والموعد في أداة NCR.`, `${fails.length} NCR(s) created — add owner and due date in the NCR tool.`));
        });
        const drawList = () => { const all = store.get(recKey, []); $("#iList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("التاريخ", "Date"))}</th><th>${esc(W("المنشأة", "Site"))}</th><th>${esc(W("المفتش", "Inspector"))}</th><th>%</th><th></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr><td>${esc(fmtDate(r.date))}</td><td>${esc(r.site)}</td><td>${esc(r.by)}</td><td><span class="chip ${r.pct == null ? "" : r.pct >= 90 ? "ok" : r.pct >= 75 ? "warn" : "bad"}">${r.pct == null ? "—" : r.pct + "%"}</span></td><td style="white-space:nowrap"><button class="icon-btn" style="width:34px;height:34px" data-load="${r.id}" aria-label="${esc(t("edit"))}">${I.note}</button> <button class="icon-btn" style="width:34px;height:34px" data-ip="${r.id}" aria-label="${esc(t("print"))}">${I.printer}</button> <button class="icon-btn" style="width:34px;height:34px" data-idel="${r.id}" aria-label="${esc(t("del"))}">${I.trash}</button></td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`; };
        $("#iList").addEventListener("click", (e) => { const all = store.get(recKey, []); const ld = e.target.closest("[data-load]"), ip = e.target.closest("[data-ip]"), dl = e.target.closest("[data-idel]");
          if (ld) { d = JSON.parse(JSON.stringify(all.find((r) => r.id === ld.dataset.load))); save(); head(); draw(); A.scrollTo(0, true); }
          if (ip) { const r = all.find((x) => x.id === ip.dataset.ip); printHtml(`${L(tool.t)} — ${r.site}`, report(r)); }
          if (dl && confirm(t("confirmDel"))) { store.set(recKey, all.filter((r) => r.id !== dl.dataset.idel)); drawList(); toast(t("deleted")); } });
        head(); draw(); drawList();
      },
    };
  }

  /* ===== Dilution calculator ===== */
  function dilutionPage() {
    const tool = list.find((x) => x.id === "dilution");
    return {
      title: L(tool.t),
      html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}<section class="sec"><div class="wrap">${disclaimer()}
        <div class="grid g2" style="margin-top:18px;align-items:start">
          <form class="card" id="dform" novalidate><h2 style="font-size:20px">${esc(W("كمية المنتج المطلوبة", "Product amount needed"))}</h2><div class="form">
            <div class="field"><label class="req" for="d-c1">${esc(W("تركيز المنتج المركّز (من الملصق)", "Concentrate strength (from label)"))}</label><input id="d-c1" type="number" step="any" inputmode="decimal"><span class="err" id="d-c1-e"></span></div>
            <div class="field"><label for="d-u1">${esc(W("الوحدة", "Unit"))}</label><select id="d-u1"><option value="pct">%</option><option value="ppm">ppm (mg/L)</option></select></div>
            <div class="field"><label class="req" for="d-c2">${esc(W("التركيز المطلوب (من الملصق / الإجراء)", "Target strength (from label / procedure)"))}</label><input id="d-c2" type="number" step="any" inputmode="decimal"><span class="err" id="d-c2-e"></span></div>
            <div class="field"><label for="d-u2">${esc(W("الوحدة", "Unit"))}</label><select id="d-u2"><option value="ppm">ppm (mg/L)</option><option value="pct">%</option></select></div>
            <div class="field full"><label class="req" for="d-v2">${esc(W("حجم المحلول النهائي (لتر)", "Final solution volume (L)"))}</label><input id="d-v2" type="number" step="any" inputmode="decimal"><span class="err" id="d-v2-e"></span></div>
            <div class="full row"><button class="btn btn-gold" type="submit">${I.calc}<span>${esc(W("احسب", "Calculate"))}</span></button></div></div>
            <div id="dres" aria-live="polite" style="margin-top:16px"></div></form>
          <div class="grid">
            <div class="card"><h3>${esc(W("المعادلة", "Formula"))}</h3><p style="font-family:var(--font-en);direction:ltr;text-align:start;color:var(--text);font-size:18px;margin-bottom:8px">C₁ × V₁ = C₂ × V₂ &nbsp;→&nbsp; V₁ = (C₂ × V₂) ÷ C₁</p><ul class="ticks"><li>${esc(W("C₁ تركيز المنتج المركّز، C₂ التركيز المطلوب، V₂ الحجم النهائي، V₁ حجم المنتج.", "C₁ concentrate strength, C₂ target strength, V₂ final volume, V₁ product volume."))}</li><li>${esc(W("1% = 10,000 ppm (للمحاليل المائية المخففة، حجم/حجم أو وزن/حجم حسب الملصق).", "1% = 10,000 ppm (dilute aqueous solutions; v/v or w/v as stated on the label)."))}</li><li>${esc(W("الماء المضاف = V₂ − V₁.", "Water to add = V₂ − V₁."))}</li></ul></div>
            <div class="card"><h3>${esc(W("تحويل ppm ↔ %", "ppm ↔ % converter"))}</h3><div class="form"><div class="field"><label for="cv-ppm">ppm</label><input id="cv-ppm" type="number" step="any" inputmode="decimal"></div><div class="field"><label for="cv-pct">%</label><input id="cv-pct" type="number" step="any" inputmode="decimal"></div></div></div>
          </div></div></div></section>`,
      after() {
        const toPpm = (v, u) => (u === "pct" ? v * 10000 : v);
        $("#dform").addEventListener("submit", (e) => {
          e.preventDefault(); const vals = {}; let ok = true;
          ["c1", "c2", "v2"].forEach((k) => { const el = $("#d-" + k), v = parseFloat(el.value); const bad = !(v > 0); el.setAttribute("aria-invalid", bad); $("#d-" + k + "-e").textContent = bad ? W("أدخل رقمًا أكبر من صفر.", "Enter a number above zero.") : ""; if (bad) ok = false; vals[k] = v; });
          if (!ok) { $("#dres").innerHTML = ""; return; }
          const c1 = toPpm(vals.c1, $("#d-u1").value), c2 = toPpm(vals.c2, $("#d-u2").value);
          if (c2 >= c1) { $("#dres").innerHTML = `<div class="disclaimer">${I.warn}<div>${esc(W("التركيز المطلوب يساوي أو يتجاوز تركيز المنتج — لا يمكن التخفيف.", "Target is equal to or above the concentrate — it can't be diluted to that."))}</div></div>`; return; }
          const v1L = (c2 * vals.v2) / c1, v1 = v1L * 1000, water = vals.v2 - v1L;
          const f = (n, d) => n.toLocaleString(A.lang === "ar" ? "ar-SA-u-nu-latn" : "en-GB", { maximumFractionDigits: d });
          $("#dres").innerHTML = `<div class="score" style="background:rgba(221,176,63,.08);border-color:rgba(221,176,63,.3)"><div><span class="note" style="margin:0">${esc(W("المنتج المركّز", "Concentrate"))}</span><br><b style="color:var(--gold)">${f(v1, v1 < 10 ? 2 : 1)} mL</b></div><div><span class="note" style="margin:0">${esc(W("الماء", "Water"))}</span><br><b style="color:var(--gold)">${f(water, 3)} L</b></div></div><p class="note" dir="ltr" style="text-align:start">V₁ = (${f(c2, 2)} ppm × ${f(vals.v2, 3)} L) ÷ ${f(c1, 2)} ppm = ${f(v1L, 5)} L</p><p class="note">${esc(W("تحقق من التركيز الفعلي بشرائط الاختبار أو الطريقة المعتمدة من المورد.", "Verify the actual strength with test strips or the supplier's approved method."))}</p>`;
        });
        const ppm = $("#cv-ppm"), pct = $("#cv-pct");
        ppm.addEventListener("input", () => (pct.value = ppm.value === "" ? "" : +(ppm.value / 10000).toPrecision(6)));
        pct.addEventListener("input", () => (ppm.value = pct.value === "" ? "" : +(pct.value * 10000).toPrecision(8)));
      },
    };
  }

  /* ===== Compliance calculator ===== */
  function compliancePage() {
    const tool = list.find((x) => x.id === "compliance");
    return {
      title: L(tool.t),
      html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}<section class="sec"><div class="wrap"><div class="grid g2" style="align-items:start">
        <div class="card"><div class="form">
          <div class="field"><label for="c-y">${esc(W("بنود مطابقة", "Conforming items"))}</label><input id="c-y" type="number" min="0" step="1" inputmode="numeric" value="0"></div>
          <div class="field"><label for="c-n">${esc(W("بنود غير مطابقة", "Non-conforming items"))}</label><input id="c-n" type="number" min="0" step="1" inputmode="numeric" value="0"></div>
          <div class="field"><label for="c-na">${esc(W("لا ينطبق", "Not applicable"))}</label><input id="c-na" type="number" min="0" step="1" inputmode="numeric" value="0"></div>
          <div class="field"><label for="c-t">${esc(W("الهدف %", "Target %"))}</label><input id="c-t" type="number" min="0" max="100" step="1" inputmode="numeric" value="90"></div>
        </div><span class="err" id="c-e" role="alert"></span></div>
        <div class="card"><div class="gauge" id="cg"></div><p class="note" id="cmsg"></p><p class="note" style="margin:0">${esc(W("المعادلة: مطابق ÷ (مطابق + غير مطابق) × 100. «لا ينطبق» مستبعد من المقام.", "Formula: conforming ÷ (conforming + non-conforming) × 100. N/A is excluded from the denominator."))}</p><a class="more" href="#/tools/inspection" style="margin-top:12px">${esc(L(list[0].t))} ${I.arrow}</a></div>
      </div></div></section>`,
      after() {
        const calc = () => {
          const v = (id) => { const n = $("#" + id).value; return n === "" ? 0 : Number(n); };
          const y = v("c-y"), n = v("c-n"), na = v("c-na"), tg = v("c-t");
          const bad = [y, n, na].some((x) => x < 0 || !Number.isInteger(x)) || tg < 0 || tg > 100;
          $("#c-e").textContent = bad ? W("أدخل أعدادًا صحيحة موجبة، والهدف بين 0 و100.", "Use whole non-negative numbers and a target between 0 and 100.") : "";
          if (bad) return;
          const pct = y + n ? Math.round((y / (y + n)) * 1000) / 10 : null, col = pct == null ? "#555" : pct >= tg ? "#53b9ad" : "#e5645a", c = 2 * Math.PI * 40;
          $("#cg").innerHTML = `<svg class="ring" viewBox="0 0 96 96"><circle cx="48" cy="48" r="40" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="9"/><circle cx="48" cy="48" r="40" fill="none" stroke="${col}" stroke-width="9" stroke-linecap="round" stroke-dasharray="${((pct || 0) / 100) * c} ${c}" transform="rotate(-90 48 48)"/></svg><div><b>${pct == null ? "—" : pct + "%"}</b><div class="note" style="margin:0">${y + n + na} ${esc(W("بند", "items"))}</div></div>`;
          $("#cmsg").innerHTML = pct == null ? "" : pct >= tg ? `<span class="chip ok">${esc(W("يحقق الهدف", "Meets target"))}</span>` : `<span class="chip bad">${esc(W(`أقل من الهدف — يلزم ${Math.max(0, Math.ceil((tg / 100) * (y + n) - y))} بند إضافي مطابق على الأقل`, `Below target — needs at least ${Math.max(0, Math.ceil((tg / 100) * (y + n) - y))} more conforming item(s)`))}</span>`;
        };
        $$("input", $("#app")).forEach((i) => i.addEventListener("input", calc)); calc();
      },
    };
  }

  /* ---------- toolkit index + router ---------- */
  function index() {
    return `${pageHead(t("toolsT"), t("toolsSub"), [[t("nav.tools")]], "", { eyebrow: t("toolsTag") })}<section class="sec"><div class="wrap">${disclaimer()}
      <div class="grid g3" style="margin-top:22px">${list.map((x) => { const n = x.id === "inspection" ? store.get("tool:inspection", []).length : store.get("tool:" + x.id, []).length; return `<a class="card hover" href="#/tools/${x.id}" style="display:flex;flex-direction:column"><span class="ic">${I[x.icon]}</span><h3>${esc(L(x.t))}</h3><p>${esc(L(x.d))}</p><div class="row" style="margin-top:auto">${Array.isArray(store.get("tool:" + x.id, null)) && n ? `<span class="chip">${n} ${esc(t("records"))}</span>` : ""}<span class="spacer"></span><span class="more">${esc(t("open"))} ${I.arrow}</span></div></a>`; }).join("")}</div>
      <div class="sec-hd" style="margin-top:44px"><div><h2 style="font-size:24px">${esc(t("planned"))}</h2><p>${esc(t("plannedSub"))}</p></div></div>
      <div class="skills">${planned.map((p) => `<span class="chip">${esc(W(p[0], p[1]))}</span>`).join("")}</div></div></section>`;
  }
  function page(sub) {
    if (!sub) return index();
    const map = { inspection: inspectionPage, ncr: ncr.page, rca: rca.page, risk: risk.page, temp: temp.page, dilution: dilutionPage, compliance: compliancePage };
    const fn = map[sub] || (extra[sub] && extra[sub].page);
    return fn ? fn() : A.pages.notfound();
  }
  // other files add tools through TOOLS.register(meta, pageFn); they get the shared helpers in TOOLS.h
  const extra = {};
  function register(meta, pageFn, at) { extra[meta.id] = { page: pageFn }; if (at == null) list.push(meta); else list.splice(at, 0, meta); }
  window.TOOLS = { list, page, register, h: { printHtml, disclaimer, crumbsFor, kvTable, today, opt, readImage, store, esc, L, t, $, $$, toast, download, csv, uid, fmtDate, pageHead } };
})();
