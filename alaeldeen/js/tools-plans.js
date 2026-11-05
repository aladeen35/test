/* Six planning tools: allergen matrix, mock recall exercise, sampling plan, goods receiving,
   supplier evaluation and cleaning & sanitation plan. They plug into js/tools.js through
   TOOLS.register and share its helpers (TOOLS.h). Data stays in localStorage only.
   The tools never propose limits, doses or legal criteria: the user enters them. */
(function () {
  "use strict";
  const T = window.TOOLS, A = window.APP, I = window.ICONS;
  const { printHtml, disclaimer, crumbsFor, kvTable, today, opt, readImage, store, esc, L, t, $, toast, download, csv, uid, fmtDate, pageHead } = T.h;
  const W = (a, e) => (A.lang === "ar" ? a : e);
  const loc = () => (A.lang === "ar" ? "ar-SA-u-ca-gregory-nu-latn" : "en-GB");
  const num = (n, d) => Number(n).toLocaleString(loc(), { maximumFractionDigits: d == null ? 2 : d });
  const clone = (o) => JSON.parse(JSON.stringify(o));
  const pad = (n) => String(n).padStart(2, "0");
  const nowLocal = (sec) => { const d = new Date(); d.setMinutes(d.getMinutes() - d.getTimezoneOffset()); return d.toISOString().slice(0, sec ? 19 : 16); };
  const has = (v) => v !== "" && v != null && !isNaN(Number(v));
  const parseD = (s) => { const [y, m, dd] = String(s).split("-").map(Number); return new Date(y, m - 1, dd); };
  const addDays = (dt, n) => new Date(dt.getFullYear(), dt.getMonth(), dt.getDate() + n);
  const daysSince = (iso) => Math.round((parseD(today()) - parseD(iso)) / 86400000);
  const dayName = (dt, long) => new Intl.DateTimeFormat(loc(), { weekday: long ? "long" : "short" }).format(dt);
  const dm = (dt) => `<span dir="ltr">${dt.getDate()}/${dt.getMonth() + 1}</span>`;
  const WEEKDAYS = () => [0, 1, 2, 3, 4, 5, 6].map((i) => [String(i), dayName(new Date(2024, 0, 7 + i), true)]); // 7 Jan 2024 is a Sunday
  const optsHtml = (list, v, blank) => `${blank ? `<option value="">—</option>` : ""}${list.map(([k, a, e]) => `<option value="${esc(k)}" ${String(v) === String(k) ? "selected" : ""}>${esc(e == null ? a : W(a, e))}</option>`).join("")}`;
  const labOf = (list, v) => { const o = list.find((x) => x[0] === v); return o ? (o[2] == null ? o[1] : W(o[1], o[2])) : ""; };

  /* ---------- small form helpers ---------- */
  const fld = (id, label, input, o) => { o = o || {}; return `<div class="field ${o.full ? "full" : ""}"><label for="${id}" class="${o.req ? "req" : ""}">${esc(label)}</label>${input}${o.hint ? `<span class="hint">${esc(o.hint)}</span>` : ""}<span class="err" id="${id}-e"></span></div>`; };
  const bind = (a, r, k) => (a ? `data-a="${a}" data-r="${r}" ` : "") + `data-k="${k}"`;
  const inp = (id, type, v, b, extra) => `<input type="${type}" id="${id}" ${b} value="${esc(v == null ? "" : v)}" ${type === "number" ? 'inputmode="decimal"' : ""} ${extra || ""}>`;
  // mark a field valid/invalid; returns true when valid
  const setErr = (el, msg, errId) => { if (!el) return !msg; el.setAttribute("aria-invalid", msg ? "true" : "false"); const e = document.getElementById(errId || el.id + "-e"); if (e) e.textContent = msg || ""; return !msg; };
  const delBtn = (act, id, label) => `<button type="button" class="icon-btn" style="width:36px;height:36px;flex-shrink:0" data-act="${act}" data-id="${id}" aria-label="${esc(label || t("del"))}" title="${esc(label || t("del"))}">${I.trash}</button>`;
  const sigTable = (cols) => `<table class="t" style="min-width:0;margin-top:22px"><tr>${cols.map((c) => `<th>${esc(c)}</th>`).join("")}</tr><tr>${cols.map(() => `<td style="height:46px"></td>`).join("")}</tr></table>`;
  const LAND = `<style>@page{size:A4 landscape;margin:10mm}#printArea table.t th,#printArea table.t td{font-size:9pt;padding:4px 6px}</style>`;

  /* ---------- generic builder page (draft autosave + saved records/versions) ---------- */
  function builder(cfg) {
    const DK = "tool:" + cfg.id + ":draft", RK = "tool:" + cfg.id;
    return function page() {
      const tool = T.list.find((x) => x.id === cfg.id);
      let d = store.get(DK, null);
      if (!d || typeof d !== "object" || !d.id) { d = cfg.blank(); store.set(DK, d); }
      cfg.fix && cfg.fix(d);
      const save = () => store.set(DK, d);
      return {
        title: L(tool.t),
        html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}<section class="sec"><div class="wrap">${disclaimer()}
          ${cfg.intro ? `<div class="card" style="margin-top:18px;padding:16px 18px">${cfg.intro()}</div>` : ""}
          <div class="card" style="margin-top:18px"><div class="row"><button type="button" class="btn btn-gold btn-sm" id="bSave">${I.check}<span>${esc(cfg.versioned ? W("حفظ نسخة", "Save version") : t("save"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="bPrint">${I.printer}<span>${esc(t("print"))}</span></button>${cfg.csv ? `<button type="button" class="btn btn-ghost btn-sm" id="bCsv">${I.download}<span>${esc(t("exportCsv"))}</span></button>` : ""}<button type="button" class="btn btn-ghost btn-sm" id="bJson">${I.download}<span>JSON</span></button><span class="spacer"></span><button type="button" class="btn btn-ghost btn-sm" id="bNew">${I.plus}<span>${esc(W("بدء جديد", "Start new"))}</span></button></div>
            <p class="note" style="margin-bottom:0">${esc(W("تُحفظ المسودة تلقائيًا على هذا الجهاز أثناء الكتابة.", "The draft autosaves on this device as you type."))} <span class="err" id="bErr" role="alert"></span></p></div>
          <div id="bBody" style="margin-top:18px"></div>
          <h2 style="font-size:22px;margin:34px 0 12px">${esc(cfg.versioned ? W("النسخ المحفوظة", "Saved versions") : W("السجلات المحفوظة", "Saved records"))}</h2><div id="bList"></div></div></section>`,
        after() {
          const body = $("#bBody");
          const live = (el) => cfg.live && cfg.live(d, el);
          const draw = () => {
            const f = document.activeElement && document.activeElement.id;
            body.innerHTML = cfg.body(d); cfg.mounted && cfg.mounted(d); live(null);
            if (f) { const n = document.getElementById(f); if (n && body.contains(n)) n.focus({ preventScroll: true }); }
          };
          const target = (el) => (el.dataset.a ? (d[el.dataset.a] || []).find((x) => x.id === el.dataset.r) : d);
          const setVal = (el) => { const o = target(el); if (!o) return; const ks = el.dataset.k.split("."); let p = o; for (let i = 0; i < ks.length - 1; i++) p = p[ks[i]] = p[ks[i]] && typeof p[ks[i]] === "object" ? p[ks[i]] : {}; p[ks[ks.length - 1]] = el.type === "checkbox" ? el.checked : el.value; };
          body.addEventListener("input", (e) => { const el = e.target; if (!el.dataset || !el.dataset.k || el.type === "checkbox" || el.tagName === "SELECT") return; setVal(el); save(); live(el); });
          body.addEventListener("change", (e) => { const el = e.target; if (!el.dataset || !el.dataset.k) return; setVal(el); save(); if (el.dataset.redraw != null) draw(); else live(el); });
          body.addEventListener("click", (e) => {
            const b = e.target.closest("button[data-act]"); if (!b || !cfg.act) return;
            const r = cfg.act(b.dataset.act, b.dataset.id, d, b); if (r === false) return;
            save(); if (r === "live") { live(b); return; }
            draw(); if (r && r.focus) { const n = document.getElementById(r.focus); n && n.focus(); }
          });
          body.addEventListener("keydown", (e) => { const el = e.target; if (e.key === "Enter" && el.dataset && el.dataset.enter) { e.preventDefault(); const b = $(`button[data-act="${el.dataset.enter}"]`, body); b && b.click(); } });
          const drawList = () => {
            const all = store.get(RK, []);
            $("#bList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr>${cfg.cols.map(([l]) => `<th>${esc(L(l))}</th>`).join("")}${cfg.versioned ? `<th>${esc(W("النسخة", "Version"))}</th>` : ""}<th>${esc(W("حُفظ", "Saved"))}</th><th></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr>${cfg.cols.map(([, f]) => `<td>${f(r)}</td>`).join("")}${cfg.versioned ? `<td><span class="chip">v${esc(r.ver)}</span></td>` : ""}<td>${esc(fmtDate(new Date(r.saved).toISOString()))}</td><td style="white-space:nowrap"><button class="icon-btn" style="width:34px;height:34px" data-load="${esc(r.id)}" aria-label="${esc(W("فتح للتعديل", "Open to edit"))}">${I.note}</button> <button class="icon-btn" style="width:34px;height:34px" data-pr="${esc(r.id)}" aria-label="${esc(t("print"))}">${I.printer}</button> <button class="icon-btn" style="width:34px;height:34px" data-del="${esc(r.id)}" aria-label="${esc(t("del"))}">${I.trash}</button></td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`;
          };
          const doPrint = (r) => printHtml(`${L(tool.t)} — ${cfg.label(r) || ""}`, cfg.report(r));
          $("#bList").addEventListener("click", (e) => {
            const all = store.get(RK, []); const ld = e.target.closest("[data-load]"), pr = e.target.closest("[data-pr]"), dl = e.target.closest("[data-del]");
            if (ld) { const r = all.find((x) => x.id === ld.dataset.load); if (!r) return; d = clone(r); delete d.saved; cfg.fix && cfg.fix(d); save(); draw(); A.scrollTo(0, true); toast(W("فُتح السجل في المحرر", "Opened in the editor")); }
            if (pr) { const r = all.find((x) => x.id === pr.dataset.pr); r && doPrint(r); }
            if (dl && confirm(t("confirmDel"))) { store.set(RK, all.filter((x) => x.id !== dl.dataset.del)); drawList(); toast(t("deleted")); }
          });
          $("#bSave").addEventListener("click", () => {
            draw();
            if (!cfg.validate(d)) { $("#bErr").textContent = t("fixErrors"); toast(t("fixErrors"), "bad"); const bad = $("[aria-invalid=true]", body); if (bad) { const det = bad.closest("details"); if (det) det.open = true; bad.focus(); } return; }
            $("#bErr").textContent = "";
            const all = store.get(RK, []); const rec = clone(d); rec.saved = Date.now(); cfg.compute && cfg.compute(rec);
            if (cfg.versioned) { rec.id = uid(); rec.ver = 1 + all.filter((x) => x.planId === d.planId).reduce((m, x) => Math.max(m, +x.ver || 0), 0); all.push(rec); }
            else { const i = all.findIndex((x) => x.id === rec.id); i >= 0 ? (all[i] = rec) : all.push(rec); }
            if (store.set(RK, all)) { toast(cfg.versioned ? W(`حُفظت النسخة ${rec.ver}`, `Version ${rec.ver} saved`) : t("saved")); drawList(); }
          });
          $("#bPrint").addEventListener("click", () => doPrint(d));
          $("#bJson").addEventListener("click", () => download(`${cfg.id}-${today()}.json`, JSON.stringify({ tool: cfg.id, exported: new Date().toISOString(), draft: d, records: store.get(RK, []) }, null, 2), "application/json"));
          $("#bCsv") && $("#bCsv").addEventListener("click", () => download(`${cfg.id}-${today()}.csv`, csv(cfg.csv(d)), "text/csv;charset=utf-8"));
          $("#bNew").addEventListener("click", () => { if (!confirm(W("بدء مسودة جديدة؟ احفظ المسودة الحالية أولًا إن كنت تحتاج إليها.", "Start a new draft? Save the current one first if you need it."))) return; d = cfg.blank(); save(); $("#bErr").textContent = ""; draw(); });
          draw(); drawList();
        },
      };
    };
  }

  /* ---------- record tool (uses the toolkit's own when it is exposed) ---------- */
  function localRecordTool(cfg) {
    const key = "tool:" + cfg.id;
    const recs = () => store.get(key, []);
    const field = (f, v) => {
      const id = "f-" + f.k, lab = `<label for="${id}" class="${f.req ? "req" : ""}">${esc(L(f.label))}</label>`;
      const hint = f.hint ? `<span class="hint">${esc(L(f.hint))}</span>` : "";
      let el;
      if (f.type === "textarea") el = `<textarea id="${id}" rows="${f.rows || 3}">${esc(v || "")}</textarea>`;
      else if (f.type === "select") el = `<select id="${id}"><option value="">—</option>${f.opts.map((o) => `<option value="${esc(o.v)}" ${String(v) === String(o.v) ? "selected" : ""}>${esc(L(o.l))}</option>`).join("")}</select>`;
      else if (f.type === "custom") return `<div class="field ${f.full ? "full" : ""}" data-custom="${f.k}"></div>`;
      else el = `<input type="${f.type || "text"}" id="${id}" value="${esc(v == null ? "" : v)}" ${f.step ? `step="${f.step}"` : ""} ${f.list ? `list="${f.list}"` : ""} ${f.type === "number" ? 'inputmode="decimal"' : ""}>`;
      return `<div class="field ${f.full ? "full" : ""}">${lab}${el}${hint}<span class="err" id="${id}-e"></span></div>`;
    };
    let editing = null;
    function page() {
      const tool = T.list.find((x) => x.id === cfg.id);
      return {
        title: L(tool.t),
        html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}
        <section class="sec"><div class="wrap">${disclaimer()}
          ${cfg.intro ? `<div style="margin-top:18px">${cfg.intro()}</div>` : ""}
          <form class="card" id="rform" novalidate style="margin-top:18px"><div class="row" style="margin-bottom:14px"><h2 style="font-size:20px;margin:0" id="formTitle"></h2><span class="spacer"></span><button type="button" class="btn btn-ghost btn-sm" id="rNew">${I.plus}<span>${esc(t("newRec"))}</span></button></div>
            <div class="form" id="rfields"></div>
            <div class="row" style="margin-top:18px"><button class="btn btn-gold" type="submit">${I.check}<span>${esc(t("save"))}</span></button><button type="button" class="btn btn-ghost" id="rPrintCur">${I.printer}<span>${esc(t("print"))}</span></button><span class="err" id="rErr" role="alert"></span></div></form>
          <div class="row" style="margin:32px 0 12px"><h2 style="font-size:22px;margin:0">${esc(t("records"))} <span class="chip" id="rCount"></span></h2><span class="spacer"></span>
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
        const all = recs(); $("#rCount").textContent = all.length;
        $("#rList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr>${cfg.columns.map((c) => `<th>${esc(L(c.l))}</th>`).join("")}<th></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr>${cfg.columns.map((c) => `<td>${c.f(r)}</td>`).join("")}<td style="white-space:nowrap"><button class="icon-btn" data-ed="${esc(r.id)}" aria-label="${esc(t("edit"))}" style="width:34px;height:34px">${I.note}</button> <button class="icon-btn" data-pr="${esc(r.id)}" aria-label="${esc(t("print"))}" style="width:34px;height:34px">${I.printer}</button> <button class="icon-btn" data-del="${esc(r.id)}" aria-label="${esc(t("del"))}" style="width:34px;height:34px">${I.trash}</button></td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`;
        cfg.below && cfg.below($("#rBelow"), recs());
      };
      const doPrint = (r) => printHtml(`${L(T.list.find((x) => x.id === cfg.id).t)} — ${cfg.label(r)}`, cfg.print(r));
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
      $("#rCsv").addEventListener("click", () => { const all = recs(); const keys = cfg.csvKeys; download(`${cfg.id}-${today()}.csv`, csv([keys, ...all.map((r) => keys.map((k) => (cfg.csvVal ? cfg.csvVal(k, r) : r[k])))]), "text/csv;charset=utf-8"); });
      $("#rJson").addEventListener("click", () => download(`${cfg.id}-${today()}.json`, JSON.stringify({ tool: cfg.id, exported: new Date().toISOString(), records: recs() }, null, 2), "application/json"));
      $("#rImp").addEventListener("change", (e) => { const f = e.target.files[0]; if (!f) return; const fr = new FileReader(); fr.onload = () => { try { const d = JSON.parse(fr.result); const incoming = Array.isArray(d) ? d : d.records; if (!Array.isArray(incoming)) throw 0; const all = recs(); const ids = new Set(all.map((r) => r.id)); incoming.forEach((r) => { if (r && typeof r === "object") { if (!r.id || ids.has(r.id)) r.id = uid(); all.push(r); } }); if (store.set(key, all)) { drawList(); toast(t("imported")); } } catch (_) { toast(t("importFail"), "bad"); } }; fr.readAsText(f); e.target.value = ""; });
      fill(null); drawList();
    }
    return { page, recs, cfg };
  }
  const recordTool = T.h.recordTool || localRecordTool;

  /* =====================================================================
     1) Allergen matrix
     ===================================================================== */
  const ALG = [["gluten", "الحبوب المحتوية على الغلوتين", "Cereals containing gluten"], ["crust", "القشريات", "Crustaceans"], ["egg", "البيض", "Eggs"], ["fish", "الأسماك", "Fish"], ["peanut", "الفول السوداني", "Peanuts"], ["soy", "فول الصويا", "Soybeans"], ["milk", "الحليب", "Milk"], ["nuts", "المكسرات الشجرية", "Tree nuts"], ["sesame", "السمسم", "Sesame"], ["sulph", "الكبريتيت ≥ 10 ملغم/كغم", "Sulphites ≥ 10 mg/kg"]];
  const AST = { c: ["يحتوي", "Contains", "●"], m: ["قد يحتوي (خط إنتاج مشترك)", "May contain (shared line)", "◐"], f: ["خالٍ منه", "Free from", "○"], "": ["لم يُقيَّم", "Not assessed", "–"] };
  const ACYCLE = ["", "c", "m", "f"];
  const aLab = (v) => W(AST[v || ""][0], AST[v || ""][1]);
  const algCols = (d) => ALG.map(([id, a, e]) => ({ id, n: W(a, e) })).concat((d.custom || []).map((c) => ({ id: c.id, n: c.name, custom: true })));
  const newProd = () => ({ id: uid(), name: "", note: "", reviewed: "", supChanged: false, cells: {} });
  const reviewDue = (p) => !p.reviewed || daysSince(p.reviewed) > 180;
  const algFlags = (p) => { const out = []; if (reviewDue(p)) out.push(`<span class="chip warn">${esc(p.reviewed ? W("مضى أكثر من 180 يومًا على المراجعة", "Not reviewed in 180 days") : W("لا توجد مراجعة مسجلة", "No review recorded"))}</span>`); if (p.supChanged) out.push(`<span class="chip bad">${esc(W("تغيّر المورد", "Supplier changed"))}</span>`); return out.join(" ") || `<span class="chip ok">${esc(W("محدّث", "Up to date"))}</span>`; };
  const algCell = (p, c) => { const v = (p.cells || {})[c.id] || ""; const lab = `${p.name || W("منتج", "Product")} — ${c.n}: ${aLab(v)}`; return `<td style="text-align:center"><button type="button" class="al-cell al-${v || "n"}" data-act="cell" data-id="${p.id}:${c.id}" aria-label="${esc(lab)}" title="${esc(lab)}">${AST[v][2]}</button></td>`; };
  const algLegend = () => `<div class="row" style="gap:6px">${["c", "m", "f", ""].map((v) => `<span class="chip"><span class="al-cell al-${v || "n"} al-mini" aria-hidden="true">${AST[v][2]}</span>${esc(aLab(v))}</span>`).join("")}</div>`;
  const ALG_NOTE = () => W("الأعمدة العشرة: مسببات الحساسية الشائعة الواجب الإفصاح عنها (Codex CXS 1-1985). تحقق من التشريع المطبّق عليك (مثل اشتراطات الهيئة العامة للغذاء والدواء SFDA) وأضف ما يلزم من أعمدة.", "The ten columns are the common declarable allergens (Codex CXS 1-1985). Check your applicable regulation (e.g. SFDA requirements) and add any columns it needs.");
  const allergensPage = builder({
    id: "allergens", versioned: true,
    blank: () => ({ id: uid(), planId: uid(), title: "", by: "", custom: [], products: [newProd()] }),
    fix: (d) => { d.custom = d.custom || []; d.products = d.products || []; d.products.forEach((p) => (p.cells = p.cells || {})); },
    label: (d) => d.title,
    intro: () => `<p style="margin:0">${esc(ALG_NOTE())}</p><p class="note" style="margin-bottom:0">${esc(W("«قد يحتوي» يعني خطر انتقال عرضي عبر خط أو معدة مشتركة بعد تقييمه. راجع كل منتج عند تغيّر المورد أو التركيبة، وكل 180 يومًا على الأقل في هذه الأداة.", "\"May contain\" means an assessed cross-contact risk from a shared line or equipment. Review each product when the supplier or recipe changes, and at least every 180 days in this tool."))} <a href="#/knowledge/allergen">${esc(W("درس إدارة مسببات الحساسية", "Allergen management lesson"))}</a></p>`,
    body: (d) => { const cols = algCols(d);
      return `<div class="card"><div class="form">
          ${fld("al-title", W("المنشأة / اسم المصفوفة", "Site / matrix name"), inp("al-title", "text", d.title, bind(0, 0, "title")), { req: 1 })}
          ${fld("al-by", W("أعدّها", "Prepared by"), inp("al-by", "text", d.by, bind(0, 0, "by")))}</div></div>
        <div class="card" style="margin-top:16px"><div class="row" style="margin-bottom:8px"><h3 style="margin:0;font-size:17px">${esc(W("المصفوفة: المنتج × مسبب الحساسية", "Matrix: product × allergen"))}</h3><span class="spacer"></span>${algLegend()}</div>
          <p class="note" style="margin-top:0">${esc(W("اضغط الخلية للتبديل: لم يُقيَّم ← يحتوي ← قد يحتوي ← خالٍ منه.", "Tap a cell to cycle: not assessed → contains → may contain → free from."))}</p>
          <div class="table-wrap"><table class="t al-grid"><thead><tr><th>${esc(W("المنتج", "Product"))}</th>${cols.map((c) => `<th class="vh">${esc(c.n)}${c.custom ? ` <span class="chip" style="padding:0 6px">${esc(W("مخصص", "custom"))}</span>` : ""}</th>`).join("")}<th>${esc(W("تنبيهات", "Flags"))}</th></tr></thead>
            <tbody>${d.products.map((p) => `<tr><th scope="row" class="al-pn" id="aln-${p.id}">${esc(p.name || "—")}</th>${cols.map((c) => algCell(p, c)).join("")}<td id="alf-${p.id}">${algFlags(p)}</td></tr>`).join("") || `<tr><td colspan="${cols.length + 2}">${esc(W("أضف منتجًا أدناه.", "Add a product below."))}</td></tr>`}</tbody></table></div>
          <div class="row" style="margin-top:14px"><input type="text" id="al-newcol" data-enter="addcol" placeholder="${esc(W("أضف عمودًا مخصصًا (مثل: الخردل، الترمس)", "Add a custom column (e.g. mustard, lupin)"))}" aria-label="${esc(W("اسم العمود المخصص", "Custom column name"))}" style="flex:1 1 200px;height:40px"><button type="button" class="btn btn-ghost btn-sm" data-act="addcol">${I.plus}<span>${esc(W("إضافة عمود", "Add column"))}</span></button><span class="err" id="al-newcol-e"></span></div>
          ${d.custom.length ? `<div class="row" style="margin-top:10px;gap:6px">${d.custom.map((c) => `<span class="chip">${esc(c.name)}<button type="button" class="chip-x" data-act="rmcol" data-id="${c.id}" aria-label="${esc(t("del") + " — " + c.name)}">×</button></span>`).join("")}</div>` : ""}</div>
        <h3 style="margin:24px 0 12px;font-size:18px">${esc(W("تفاصيل المنتجات", "Product details"))}</h3>
        ${d.products.map((p, i) => `<div class="card plan-item"><div class="row" style="margin-bottom:12px"><span class="chip gold">${i + 1}</span><b id="alh-${p.id}">${esc(p.name || "—")}</b><span id="alf2-${p.id}">${algFlags(p)}</span><span class="spacer"></span>${delBtn("rmp", p.id)}</div>
          <div class="form">
            ${fld(`al-${p.id}-name`, W("اسم المنتج", "Product name"), inp(`al-${p.id}-name`, "text", p.name, bind("products", p.id, "name")), { req: 1 })}
            ${fld(`al-${p.id}-reviewed`, W("تاريخ آخر مراجعة", "Last reviewed"), inp(`al-${p.id}-reviewed`, "date", p.reviewed, bind("products", p.id, "reviewed")))}
            ${fld(`al-${p.id}-note`, W("المكونات / ملاحظة المورد", "Ingredients / supplier note"), `<textarea id="al-${p.id}-note" rows="2" ${bind("products", p.id, "note")}>${esc(p.note)}</textarea>`, { full: 1, hint: W("انقلها من بطاقة المواصفات أو ملصق المورد.", "Copy from the specification sheet or the supplier label.") })}
            <div class="field full"><label class="chk" for="al-${p.id}-sup"><input type="checkbox" id="al-${p.id}-sup" ${bind("products", p.id, "supChanged")} ${p.supChanged ? "checked" : ""}><span>${esc(W("تغيّر المورد أو التركيبة منذ آخر مراجعة", "Supplier or recipe changed since the last review"))}</span></label></div>
          </div></div>`).join("")}
        <div class="row"><button type="button" class="btn btn-ghost btn-sm" data-act="addp">${I.plus}<span>${esc(W("أضف منتجًا", "Add product"))}</span></button><span class="err" id="al-prods-e"></span></div>`; },
    live: (d, el) => {
      if (!el || !el.dataset || el.dataset.a !== "products") return;
      const p = d.products.find((x) => x.id === el.dataset.r); if (!p) return;
      if (el.dataset.k === "name") { $("#aln-" + p.id).textContent = p.name || "—"; $("#alh-" + p.id).textContent = p.name || "—"; }
      $("#alf-" + p.id).innerHTML = algFlags(p); $("#alf2-" + p.id).innerHTML = algFlags(p);
    },
    act: (a, id, d, b) => {
      if (a === "cell") { const [pid, cid] = id.split(":"); const p = d.products.find((x) => x.id === pid); if (!p) return false; const v = ACYCLE[(ACYCLE.indexOf(p.cells[cid] || "") + 1) % ACYCLE.length]; if (v) p.cells[cid] = v; else delete p.cells[cid]; const c = algCols(d).find((x) => x.id === cid); const lab = `${p.name || W("منتج", "Product")} — ${c ? c.n : ""}: ${aLab(v)}`; b.className = `al-cell al-${v || "n"}`; b.textContent = AST[v][2]; b.setAttribute("aria-label", lab); b.title = lab; return "live"; }
      if (a === "addp") { const p = newProd(); d.products.push(p); return { focus: `al-${p.id}-name` }; }
      if (a === "rmp") { const p = d.products.find((x) => x.id === id); if (!confirm(W(`حذف المنتج «${(p && p.name) || "—"}»؟`, `Remove product "${(p && p.name) || "—"}"?`))) return false; d.products = d.products.filter((x) => x.id !== id); return undefined; }
      if (a === "addcol") { const el = $("#al-newcol"); const v = el.value.trim(); const dup = algCols(d).some((c) => c.n.toLowerCase() === v.toLowerCase()); if (!setErr(el, !v ? t("required") : dup ? W("هذا العمود موجود.", "That column already exists.") : "")) { el.focus(); return false; } d.custom.push({ id: "x" + uid(), name: v }); return { focus: "al-newcol" }; }
      if (a === "rmcol") { const c = d.custom.find((x) => x.id === id); if (!c || !confirm(W(`حذف العمود «${c.name}» وقيمه؟`, `Remove column "${c.name}" and its values?`))) return false; d.custom = d.custom.filter((x) => x.id !== id); d.products.forEach((p) => delete p.cells[id]); return undefined; }
      return false;
    },
    validate: (d) => {
      let ok = setErr($("#al-title"), d.title.trim() ? "" : t("required"));
      const pe = $("#al-prods-e"); if (pe) pe.textContent = d.products.length ? "" : W("أضف منتجًا واحدًا على الأقل.", "Add at least one product.");
      if (!d.products.length) ok = false;
      d.products.forEach((p) => { ok = setErr($(`#al-${p.id}-name`), p.name.trim() ? "" : t("required")) && ok; ok = setErr($(`#al-${p.id}-reviewed`), p.reviewed && p.reviewed > today() ? W("لا يمكن أن يكون في المستقبل.", "Can't be in the future.") : "") && ok; });
      return ok;
    },
    cols: [[{ ar: "المصفوفة", en: "Matrix" }, (r) => esc(r.title)], [{ ar: "المنتجات", en: "Products" }, (r) => r.products.length], [{ ar: "تحتاج مراجعة", en: "Need review" }, (r) => { const n = r.products.filter((p) => reviewDue(p) || p.supChanged).length; return `<span class="chip ${n ? "warn" : "ok"}">${n}</span>`; }]],
    report: (d) => { const cols = algCols(d);
      return LAND + kvTable([[W("المنشأة / المصفوفة", "Site / matrix"), esc(d.title)], [W("أعدّها", "Prepared by"), esc(d.by)], [W("النسخة", "Version"), d.ver ? "v" + esc(d.ver) : W("مسودة", "Draft")]]) +
        `<p style="font-size:9pt">${["c", "m", "f", ""].map((v) => `<b>${AST[v][2]}</b> ${esc(aLab(v))}`).join(" · ")}<br>${esc(ALG_NOTE())}</p>
        <table class="t" style="min-width:0"><tr><th>${esc(W("المنتج", "Product"))}</th>${cols.map((c) => `<th style="white-space:normal;text-align:center">${esc(c.n)}</th>`).join("")}</tr>${d.products.map((p) => `<tr><td>${esc(p.name)}</td>${cols.map((c) => `<td style="text-align:center"><b>${AST[p.cells[c.id] || ""][2]}</b></td>`).join("")}</tr>`).join("")}</table>
        <h3>${esc(W("تفاصيل المنتجات", "Product details"))}</h3><table class="t" style="min-width:0"><tr><th>${esc(W("المنتج", "Product"))}</th><th>${esc(W("المكونات / ملاحظة المورد", "Ingredients / supplier note"))}</th><th>${esc(W("آخر مراجعة", "Last reviewed"))}</th><th>${esc(W("تنبيهات", "Flags"))}</th></tr>${d.products.map((p) => `<tr><td>${esc(p.name)}</td><td>${esc(p.note).replace(/\n/g, "<br>")}</td><td>${esc(fmtDate(p.reviewed)) || "—"}</td><td>${algFlags(p)}</td></tr>`).join("")}</table>` +
        sigTable([W("أعدّه", "Prepared by"), W("راجعه", "Reviewed by"), W("التاريخ", "Date")]); },
    csv: (d) => { const cols = algCols(d); return [[W("المنتج", "Product"), ...cols.map((c) => c.n), W("المكونات / ملاحظة المورد", "Ingredients / supplier note"), W("آخر مراجعة", "Last reviewed"), W("تغيّر المورد", "Supplier changed"), W("تحتاج مراجعة", "Review due")], ...d.products.map((p) => [p.name, ...cols.map((c) => aLab(p.cells[c.id] || "")), p.note, p.reviewed, p.supChanged ? W("نعم", "Yes") : W("لا", "No"), reviewDue(p) ? W("نعم", "Yes") : W("لا", "No")])]; },
  });

  /* =====================================================================
     2) Mock recall exercise
     ===================================================================== */
  const rcNum = (v) => (has(v) ? Number(v) : 0);
  const rcCalc = (d) => {
    const produced = rcNum(d.produced), stock = rcNum(d.stock), used = rcNum(d.used);
    const disp = d.customers.reduce((s, c) => s + rcNum(c.dispatched), 0), rec = d.customers.reduce((s, c) => s + rcNum(c.recovered), 0);
    const accounted = stock + rec + used;
    const pct = produced > 0 ? (accounted / produced) * 100 : null;
    const t0 = d.notifiedAt ? Date.parse(d.notifiedAt) : NaN, t1 = d.completedAt ? Date.parse(d.completedAt) : Date.now();
    const mins = isNaN(t0) || isNaN(t1) ? null : Math.max(0, (t1 - t0) / 60000);
    const tgtMin = has(d.targetH) ? Number(d.targetH) * 60 : null, tgtPct = has(d.targetPct) ? Number(d.targetPct) : null;
    const done = !!d.completedAt && mins != null;
    const pctOk = pct != null && tgtPct != null ? pct >= tgtPct : null, timeOk = mins != null && tgtMin != null ? mins <= tgtMin : null;
    const pass = done && pctOk != null && timeOk != null ? pctOk && timeOk : null;
    return { produced, stock, used, disp, rec, accounted, pct, mins, tgtMin, tgtPct, done, pctOk, timeOk, pass, balance: produced - (stock + disp + used) };
  };
  const fmtDur = (mins) => { if (mins == null) return "—"; const s = Math.floor(mins * 60), h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), x = s % 60; return `${h}:${pad(m)}:${pad(x)}`; };
  const rcVerdict = (d, c) => !d.notifiedAt ? `<span class="chip">${esc(W("ابدأ التمرين", "Start the exercise"))}</span>` : c.tgtMin == null || c.tgtPct == null ? `<span class="chip warn">${esc(W("أدخل الهدفين لعرض النتيجة", "Enter both targets to see the result"))}</span>` : !c.done ? `<span class="chip warn">${esc(W("قيد التنفيذ", "In progress"))}</span>` : c.pass ? `<span class="chip ok">${esc(W("ناجح — حقق الهدفين", "Pass — both targets met"))}</span>` : `<span class="chip bad">${esc(W("غير ناجح", "Fail"))}${c.pctOk ? "" : " · " + esc(W("النسبة أقل من الهدف", "% below target"))}${c.timeOk ? "" : " · " + esc(W("الوقت تجاوز الهدف", "time over target"))}</span>`;
  const newCust = () => ({ id: uid(), name: "", dispatched: "", recovered: "" });
  const newLot = () => ({ id: uid(), material: "", supplier: "", lot: "", qty: "" });
  let rcTimer = null;
  const recallPage = builder({
    id: "recall",
    blank: () => ({ id: uid(), ref: "", notifiedAt: "", completedAt: "", product: "", batch: "", prodDate: "", unit: "", produced: "", stock: "", used: "", customers: [newCust()], lots: [newLot()], targetH: "", targetPct: "", notes: "" }),
    fix: (d) => { d.customers = d.customers || []; d.lots = d.lots || []; },
    label: (d) => [d.product, d.batch].filter(Boolean).join(" · "),
    intro: () => `<p style="margin:0">${esc(W("اضغط «بدء» لحظة استلام إشعار الاستدعاء التجريبي، ثم تتبّع الدفعة: المخزون لديك، وما أُرسل لكل عميل أو فرع، وما استُرجع. النسبة = (المخزون + المسترجَع + المستخدَم/المُتلَف الموثّق) ÷ الكمية المنتَجة × 100.", "Press \"Start\" the moment the mock-recall notification arrives, then trace the lot: what you still hold, what went to each customer or branch, and what came back. % accounted for = (in stock + recovered + documented used/destroyed) ÷ quantity produced × 100."))}</p><p class="note" style="margin-bottom:0">${esc(W("حدّد الوقت والنسبة المستهدفين وفق إجراء الاستدعاء لديك أو متطلبات عميلك أو المعيار الذي تطبقه.", "Set the target time and % from your recall procedure, customer requirements or the standard you follow."))}</p>`,
    body: (d) => { const n = (id, k, v, b, o) => fld(id, k, inp(id, "number", v, b, 'step="any" min="0"'), o);
      return `<div class="card"><h3 style="font-size:17px">${esc(W("1. الإشعار والمؤقت", "1. Notification & timer"))}</h3>
          <div class="grid g2 rc-top" style="align-items:start"><div class="form">
            ${fld("rc-ref", W("مرجع التمرين", "Exercise reference"), inp("rc-ref", "text", d.ref, bind(0, 0, "ref")), { full: 1 })}
            ${fld("rc-notifiedAt", W("وقت الإشعار", "Notification time"), inp("rc-notifiedAt", "datetime-local", d.notifiedAt, bind(0, 0, "notifiedAt") + ' data-redraw step="1"'), { req: 1 })}
            ${fld("rc-completedAt", W("وقت الإنجاز", "Completion time"), inp("rc-completedAt", "datetime-local", d.completedAt, bind(0, 0, "completedAt") + ' data-redraw step="1"'))}
          </div><div class="rc-timer"><span class="lbl">${esc(W("الوقت المنقضي (س:د:ث)", "Elapsed time (h:mm:ss)"))}</span><div class="big-n" id="rcElapsed" dir="ltr">—</div>
            <div class="row"><button type="button" class="btn btn-gold btn-sm" data-act="start">${I.check}<span>${esc(d.notifiedAt ? W("إعادة البدء الآن", "Restart now") : W("بدء — وصل الإشعار الآن", "Start — notification received now"))}</span></button><button type="button" class="btn btn-ghost btn-sm" data-act="finish">${I.check}<span>${esc(W("تسجيل الإنجاز الآن", "Mark complete now"))}</span></button></div></div></div></div>
        <div class="card" style="margin-top:16px"><h3 style="font-size:17px">${esc(W("2. المنتج والدفعة", "2. Product & lot"))}</h3><div class="form">
          ${fld("rc-product", W("المنتج", "Product"), inp("rc-product", "text", d.product, bind(0, 0, "product")), { req: 1 })}
          ${fld("rc-batch", W("رقم الدفعة / التشغيلة", "Batch / lot no."), inp("rc-batch", "text", d.batch, bind(0, 0, "batch")), { req: 1 })}
          ${fld("rc-prodDate", W("تاريخ الإنتاج", "Production date"), inp("rc-prodDate", "date", d.prodDate, bind(0, 0, "prodDate")))}
          ${fld("rc-unit", W("وحدة الكمية", "Quantity unit"), inp("rc-unit", "text", d.unit, bind(0, 0, "unit"), `placeholder="${esc(W("مثل: كرتون، كغم", "e.g. cartons, kg"))}"`), { req: 1 })}
          ${n("rc-produced", W("الكمية المنتَجة", "Quantity produced"), d.produced, bind(0, 0, "produced"), { req: 1 })}
        </div></div>
        <div class="card" style="margin-top:16px"><h3 style="font-size:17px">${esc(W("3. حصر الكميات", "3. Quantity reconciliation"))}</h3><div class="form">
          ${n("rc-stock", W("الكمية في المخزون", "Quantity in stock"), d.stock, bind(0, 0, "stock"))}
          ${n("rc-used", W("مستخدَم / مُتلَف (موثّق)", "Used / destroyed (documented)"), d.used, bind(0, 0, "used"), { hint: W("فقط ما يوجد له سجل إتلاف أو استخدام.", "Only what a destruction or usage record supports.") })}</div>
          <h4 style="margin:18px 0 4px;font-size:15px">${esc(W("الكميات المرسلة لكل عميل / فرع والمسترجعة منه", "Dispatched to and recovered from each customer / branch"))}</h4>
          ${d.customers.map((c, i) => `<div class="lgrid">
            ${fld(`rc-${c.id}-name`, `${W("العميل / الفرع", "Customer / branch")} ${i + 1}`, inp(`rc-${c.id}-name`, "text", c.name, bind("customers", c.id, "name")), { req: 1 })}
            ${n(`rc-${c.id}-dispatched`, W("المرسَل", "Dispatched"), c.dispatched, bind("customers", c.id, "dispatched"), { req: 1 })}
            ${n(`rc-${c.id}-recovered`, W("المسترجَع", "Recovered"), c.recovered, bind("customers", c.id, "recovered"))}
            ${delBtn("rmc", c.id)}</div>`).join("")}
          <button type="button" class="btn btn-ghost btn-sm" style="margin-top:12px" data-act="addc">${I.plus}<span>${esc(W("أضف عميلًا / فرعًا", "Add customer / branch"))}</span></button></div>
        <div class="card" style="margin-top:16px"><h3 style="font-size:17px">${esc(W("4. الأهداف والنتيجة", "4. Targets & result"))}</h3><div class="form">
          ${n("rc-targetH", W("الوقت المستهدف (ساعات)", "Target time (hours)"), d.targetH, bind(0, 0, "targetH"), { req: 1, hint: W("من إجرائك أو متطلبات عميلك.", "From your procedure or customer requirement.") })}
          ${n("rc-targetPct", W("النسبة المستهدفة %", "Target %"), d.targetPct, bind(0, 0, "targetPct"), { req: 1, hint: W("من إجرائك أو متطلبات عميلك.", "From your procedure or customer requirement.") })}</div>
          <div id="rcRes" aria-live="polite" style="margin-top:16px"></div></div>
        <div class="card" style="margin-top:16px"><h3 style="font-size:17px">${esc(W("5. خطوة للخلف: دفعات المواد الخام من الموردين", "5. One step back: supplier lots of raw materials"))}</h3>
          ${d.lots.map((l) => `<div class="lgrid l5">
            ${fld(`rl-${l.id}-material`, W("المادة الخام / التعبئة", "Raw / packaging material"), inp(`rl-${l.id}-material`, "text", l.material, bind("lots", l.id, "material")), { req: 1 })}
            ${fld(`rl-${l.id}-supplier`, W("المورد", "Supplier"), inp(`rl-${l.id}-supplier`, "text", l.supplier, bind("lots", l.id, "supplier")))}
            ${fld(`rl-${l.id}-lot`, W("رقم دفعة المورد", "Supplier lot no."), inp(`rl-${l.id}-lot`, "text", l.lot, bind("lots", l.id, "lot")))}
            ${fld(`rl-${l.id}-qty`, W("الكمية المستخدمة", "Quantity used"), inp(`rl-${l.id}-qty`, "text", l.qty, bind("lots", l.id, "qty")))}
            ${delBtn("rml", l.id)}</div>`).join("")}
          <button type="button" class="btn btn-ghost btn-sm" style="margin-top:12px" data-act="addl">${I.plus}<span>${esc(W("أضف مادة", "Add material"))}</span></button>
          <div style="margin-top:18px">${fld("rc-notes", W("الملاحظات والدروس المستفادة", "Notes & lessons learned"), `<textarea id="rc-notes" rows="3" ${bind(0, 0, "notes")}>${esc(d.notes)}</textarea>`, { full: 1 })}<</div></div>`; },
    live: (d) => {
      const c = rcCalc(d), u = esc(d.unit || "");
      const el = $("#rcRes"); if (!el) return;
      const over = d.customers.filter((x) => has(x.recovered) && has(x.dispatched) && +x.recovered > +x.dispatched);
      el.innerHTML = `<div class="grid g3">
        <div class="score"><div><span class="note" style="margin:0">${esc(W("نسبة الكمية المحصورة", "% accounted for"))}</span><br><b id="rcPct">${c.pct == null ? "—" : num(c.pct, 1) + "%"}</b>${c.tgtPct != null ? `<br><span class="note" style="margin:0">${esc(W("الهدف", "Target"))} ≥ ${num(c.tgtPct, 1)}%</span>` : ""}</div></div>
        <div class="score"><div><span class="note" style="margin:0">${esc(W("الوقت حتى الإنجاز", "Time to completion"))}</span><br><b id="rcElapsed2" dir="ltr">${fmtDur(c.mins)}</b>${c.tgtMin != null ? `<br><span class="note" style="margin:0">${esc(W("الهدف", "Target"))} ≤ <span dir="ltr">${fmtDur(c.tgtMin)}</span></span>` : ""}</div></div>
        <div style="align-self:center">${rcVerdict(d, c)}</div></div>
        <p class="note" dir="ltr" style="text-align:start">(${num(c.stock)} + ${num(c.rec)} + ${num(c.used)}) ÷ ${num(c.produced)} × 100 = ${c.pct == null ? "—" : num(c.pct, 1) + "%"}</p>
        <p class="note">${esc(W("المرسَل إجمالًا", "Total dispatched"))}: <b>${num(c.disp)}</b> ${u} · ${esc(W("المسترجَع", "Recovered"))}: <b>${num(c.rec)}</b> ${u} · ${esc(W("المتبقي لدى العملاء", "Still with customers"))}: <b>${num(Math.max(0, c.disp - c.rec))}</b> ${u}</p>
        ${c.produced > 0 && Math.abs(c.balance) > 1e-9 ? `<p class="note"><span class="chip warn">${esc(W("فرق في الموازنة", "Mass-balance gap"))}</span> ${esc(W("المنتَج − (المخزون + المرسَل + المستخدَم/المُتلَف)", "Produced − (stock + dispatched + used/destroyed)"))} = <b dir="ltr">${num(c.balance)}</b> ${u}</p>` : ""}
        ${over.length ? `<p class="err">${esc(W("المسترجَع أكبر من المرسَل لدى:", "Recovered exceeds dispatched for:"))} ${over.map((x) => esc(x.name || "—")).join("، ")}</p>` : ""}`;
      const e1 = $("#rcElapsed"); if (e1) e1.textContent = fmtDur(c.mins);
    },
    mounted: (d) => {
      clearInterval(rcTimer);
      rcTimer = setInterval(() => { const e1 = $("#rcElapsed"); if (!e1) { clearInterval(rcTimer); return; } if (d.completedAt || !d.notifiedAt) return; const m = rcCalc(d).mins; e1.textContent = fmtDur(m); const e2 = $("#rcElapsed2"); if (e2) e2.textContent = fmtDur(m); }, 1000);
    },
    act: (a, id, d) => {
      if (a === "start") { if (d.notifiedAt && !confirm(W("إعادة تعيين وقت الإشعار إلى الآن ومسح وقت الإنجاز؟", "Reset the notification time to now and clear the completion time?"))) return false; d.notifiedAt = nowLocal(true); d.completedAt = ""; return undefined; }
      if (a === "finish") { if (!d.notifiedAt) { toast(W("ابدأ التمرين أولًا.", "Start the exercise first."), "bad"); return false; } d.completedAt = nowLocal(true); return undefined; }
      if (a === "addc") { const c = newCust(); d.customers.push(c); return { focus: `rc-${c.id}-name` }; }
      if (a === "rmc") { d.customers = d.customers.filter((x) => x.id !== id); return undefined; }
      if (a === "addl") { const l = newLot(); d.lots.push(l); return { focus: `rl-${l.id}-material` }; }
      if (a === "rml") { d.lots = d.lots.filter((x) => x.id !== id); return undefined; }
      return false;
    },
    validate: (d) => {
      const req = (id, v) => setErr($("#" + id), String(v == null ? "" : v).trim() ? "" : t("required"));
      const nonNeg = (id, v, need) => setErr($("#" + id), !has(v) ? (need ? t("required") : "") : Number(v) < 0 ? W("أدخل رقمًا موجبًا.", "Enter a non-negative number.") : "");
      let ok = true;
      ok = req("rc-notifiedAt", d.notifiedAt) && ok;
      ok = setErr($("#rc-completedAt"), d.completedAt && d.notifiedAt && Date.parse(d.completedAt) < Date.parse(d.notifiedAt) ? W("يجب أن يكون بعد وقت الإشعار.", "Must be after the notification time.") : "") && ok;
      ["product", "batch", "unit"].forEach((k) => (ok = req("rc-" + k, d[k]) && ok));
      ok = setErr($("#rc-produced"), !has(d.produced) ? t("required") : +d.produced <= 0 ? W("أدخل رقمًا أكبر من صفر.", "Enter a number above zero.") : "") && ok;
      ok = nonNeg("rc-stock", d.stock) && ok; ok = nonNeg("rc-used", d.used) && ok;
      ok = setErr($("#rc-targetH"), !has(d.targetH) ? t("required") : +d.targetH <= 0 ? W("أدخل رقمًا أكبر من صفر.", "Enter a number above zero.") : "") && ok;
      ok = setErr($("#rc-targetPct"), !has(d.targetPct) ? t("required") : +d.targetPct <= 0 || +d.targetPct > 100 ? W("أدخل قيمة بين 0 و100.", "Enter a value between 0 and 100.") : "") && ok;
      d.customers.forEach((c) => { ok = req(`rc-${c.id}-name`, c.name) && ok; ok = nonNeg(`rc-${c.id}-dispatched`, c.dispatched, true) && ok; ok = setErr($(`#rc-${c.id}-recovered`), has(c.recovered) && +c.recovered < 0 ? W("أدخل رقمًا موجبًا.", "Enter a non-negative number.") : has(c.recovered) && has(c.dispatched) && +c.recovered > +c.dispatched ? W("أكبر من الكمية المرسلة.", "More than was dispatched.") : "") && ok; });
      d.lots.forEach((l) => { if (l.supplier || l.lot || l.qty || d.lots.length > 1) ok = req(`rl-${l.id}-material`, l.material) && ok; });
      return ok;
    },
    compute: (r) => { const c = rcCalc(r); r.res = { pct: c.pct, mins: c.mins, pass: c.pass }; },
    cols: [[{ ar: "المنتج", en: "Product" }, (r) => esc(r.product)], [{ ar: "الدفعة", en: "Lot" }, (r) => esc(r.batch)], ["%", (r) => (r.res && r.res.pct != null ? num(r.res.pct, 1) + "%" : "—")], [{ ar: "الوقت", en: "Time" }, (r) => `<span dir="ltr">${fmtDur(r.res && r.res.mins)}</span>`], [{ ar: "النتيجة", en: "Result" }, (r) => (r.res && r.res.pass != null ? `<span class="chip ${r.res.pass ? "ok" : "bad"}">${esc(r.res.pass ? W("ناجح", "Pass") : W("غير ناجح", "Fail"))}</span>` : `<span class="chip warn">${esc(W("غير مكتمل", "Incomplete"))}</span>`)]],
    report: (d) => { const c = rcCalc(d), u = esc(d.unit || ""), dt = (v) => esc((v || "").replace("T", " "));
      return kvTable([[W("مرجع التمرين", "Exercise reference"), esc(d.ref)], [W("المنتج", "Product"), esc(d.product)], [W("الدفعة", "Lot"), esc(d.batch)], [W("تاريخ الإنتاج", "Production date"), esc(fmtDate(d.prodDate))], [W("الكمية المنتَجة", "Quantity produced"), `${num(c.produced)} ${u}`], [W("وقت الإشعار", "Notification time"), `<span dir="ltr">${dt(d.notifiedAt)}</span>`], [W("وقت الإنجاز", "Completion time"), `<span dir="ltr">${dt(d.completedAt) || "—"}</span>`], [W("الوقت المنقضي", "Elapsed time"), `<span dir="ltr">${fmtDur(c.mins)}</span>${c.tgtMin != null ? ` (${esc(W("الهدف", "target"))} ≤ <span dir="ltr">${fmtDur(c.tgtMin)}</span>)` : ""}`], [W("نسبة الكمية المحصورة", "% accounted for"), `<b>${c.pct == null ? "—" : num(c.pct, 1) + "%"}</b>${c.tgtPct != null ? ` (${esc(W("الهدف", "target"))} ≥ ${num(c.tgtPct, 1)}%)` : ""}`], [W("النتيجة", "Result"), rcVerdict(d, c)]]) +
        `<h3>${esc(W("حصر الكميات", "Reconciliation"))}</h3><table class="t" style="min-width:0"><tr><th>${esc(W("العميل / الفرع", "Customer / branch"))}</th><th>${esc(W("المرسَل", "Dispatched"))}</th><th>${esc(W("المسترجَع", "Recovered"))}</th><th>${esc(W("المتبقي", "Outstanding"))}</th></tr>${d.customers.map((x) => `<tr><td>${esc(x.name)}</td><td>${num(rcNum(x.dispatched))}</td><td>${num(rcNum(x.recovered))}</td><td>${num(rcNum(x.dispatched) - rcNum(x.recovered))}</td></tr>`).join("")}<tr><th>${esc(W("الإجمالي", "Total"))}</th><th>${num(c.disp)}</th><th>${num(c.rec)}</th><th>${num(c.disp - c.rec)}</th></tr></table>` +
        kvTable([[W("في المخزون", "In stock"), `${num(c.stock)} ${u}`], [W("مستخدَم / مُتلَف (موثّق)", "Used / destroyed (documented)"), `${num(c.used)} ${u}`], [W("المعادلة", "Formula"), `<span dir="ltr">(${num(c.stock)} + ${num(c.rec)} + ${num(c.used)}) ÷ ${num(c.produced)} × 100</span>`], [W("فرق الموازنة", "Mass-balance gap"), `<span dir="ltr">${num(c.balance)}</span> ${u}`]]) +
        `<h3>${esc(W("خطوة للخلف: دفعات المواد الخام", "One step back: raw material lots"))}</h3><table class="t" style="min-width:0"><tr><th>${esc(W("المادة", "Material"))}</th><th>${esc(W("المورد", "Supplier"))}</th><th>${esc(W("رقم الدفعة", "Lot no."))}</th><th>${esc(W("الكمية", "Quantity"))}</th></tr>${d.lots.map((l) => `<tr><td>${esc(l.material)}</td><td>${esc(l.supplier)}</td><td>${esc(l.lot)}</td><td>${esc(l.qty)}</td></tr>`).join("")}</table>` +
        (d.notes ? `<h3>${esc(W("الملاحظات والدروس المستفادة", "Notes & lessons learned"))}</h3><p>${esc(d.notes).replace(/\n/g, "<br>")}</p>` : "") +
        sigTable([W("منسق الاستدعاء", "Recall coordinator"), W("مدير الجودة", "Quality manager"), W("التاريخ", "Date")]); },
  });

  /* =====================================================================
     3) Sampling plan builder
     ===================================================================== */
  const MICRO = [["tpc", "العدد الكلي للبكتيريا (TPC)", "Total plate count (TPC)"], ["entero", "البكتيريا المعوية (Enterobacteriaceae)", "Enterobacteriaceae"], ["ecoli", "الإشريكية القولونية (E. coli)", "E. coli"], ["salm", "السالمونيلا (Salmonella)", "Salmonella"], ["listeria", "الليستيريا (Listeria)", "Listeria"], ["saureus", "المكورات العنقودية الذهبية (S. aureus)", "S. aureus"], ["ym", "الخمائر والفطريات", "Yeasts & moulds"]];
  const OTHER_T = [["chem", "تحليل كيميائي", "Chemical analysis"], ["water", "تحليل المياه", "Water analysis"], ["swab", "مسحة أسطح", "Surface swab"]];
  const TESTS = MICRO.concat(OTHER_T);
  const SFREQ = [["daily", "يومي", "Daily"], ["weekly", "أسبوعي", "Weekly"], ["monthly", "شهري", "Monthly"], ["batch", "لكل دفعة", "Per batch"], ["quarterly", "ربع سنوي", "Quarterly"]];
  const LABS = [["int", "مختبر داخلي", "Internal lab"], ["ext", "مختبر خارجي", "External lab"]];
  const newItem = () => ({ id: uid(), point: "", test: "", detail: "", freq: "", wd: "", dom: "", size: "", lab: "", labName: "", resp: "", n: "", c: "", m: "", M: "", unit: "" });
  const smEnd = (d) => { const s = parseD(d.start); return d.horizon === "3m" ? new Date(s.getFullYear(), s.getMonth() + 3, s.getDate()) : addDays(s, 28); };
  const smDays = (d) => { if (!d.start) return []; const s = parseD(d.start), end = smEnd(d), out = []; for (let x = s; x < end; x = addDays(x, 1)) out.push(x); return out; };
  const smHit = (it, dt, s) => {
    const dom = +it.dom || s.getDate();
    if (it.freq === "daily") return true;
    if (it.freq === "weekly") return dt.getDay() === (it.wd === "" || it.wd == null ? s.getDay() : +it.wd);
    if (it.freq === "monthly") return dt.getDate() === dom;
    if (it.freq === "quarterly") { const md = (dt.getFullYear() - s.getFullYear()) * 12 + dt.getMonth() - s.getMonth(); return md % 3 === 0 && dt.getDate() === dom; }
    return false;
  };
  const smTest = (it) => [labOf(TESTS, it.test), it.detail].filter(Boolean).join(" — ");
  const smFreq = (it) => { const f = labOf(SFREQ, it.freq); if (it.freq === "weekly" && it.wd !== "") return `${f} (${WEEKDAYS()[+it.wd][1]})`; if ((it.freq === "monthly" || it.freq === "quarterly") && it.dom) return `${f} (${W("يوم", "day")} ${esc(it.dom)})`; return f; };
  const smPlan = (it) => (["n", "c", "m", "M"].some((k) => has(it[k])) ? `<span dir="ltr">n=${esc(it.n || "—")}, c=${esc(it.c || "—")}, m=${esc(it.m || "—")}, M=${esc(it.M || "—")} ${esc(it.unit)}</span>` : "—");
  const smLegend = (d) => `<div class="table-wrap"><table class="t"><thead><tr><th>#</th><th>${esc(W("نقطة / منتج", "Point / product"))}</th><th>${esc(W("الفحص", "Test"))}</th><th>${esc(W("التكرار", "Frequency"))}</th><th>${esc(W("حجم العينة / الوحدات", "Sample size / units"))}</th><th>${esc(W("المختبر", "Lab"))}</th><th>${esc(W("المسؤول", "Responsible"))}</th><th>n, c, m, M</th></tr></thead><tbody>${d.items.map((it, i) => `<tr><td><span class="sm-it">#${i + 1}</span></td><td>${esc(it.point)}</td><td>${esc(smTest(it))}</td><td>${smFreq(it)}</td><td>${esc(it.size)}</td><td>${esc([labOf(LABS, it.lab), it.labName].filter(Boolean).join(" — "))}</td><td>${esc(it.resp)}</td><td>${smPlan(it)}</td></tr>`).join("")}</tbody></table></div>`;
  const smCal = (d) => {
    if (!d.start) return `<div class="empty">${esc(W("اختر تاريخ البدء لعرض التقويم.", "Pick a start date to see the calendar."))}</div>`;
    if (!d.items.length) return `<div class="empty">${esc(W("أضف نقاط أخذ العينات.", "Add sampling points."))}</div>`;
    const s = parseD(d.start), days = smDays(d), chip = (i, it) => `<span class="sm-it" title="${esc(it.point + " — " + smTest(it))}">#${i + 1}</span>`;
    const batch = d.items.map((it, i) => [it, i]).filter(([it]) => it.freq === "batch");
    const batchNote = batch.length ? `<p class="note">${esc(W("لكل دفعة (غير مرتبطة بتاريخ — خذ العينة عند كل دفعة إنتاج):", "Per batch (not date-bound — sample at every production batch):"))} ${batch.map(([it, i]) => chip(i, it)).join(" ")}</p>` : "";
    if (d.horizon !== "3m") {
      const weeks = [0, 1, 2, 3].map((w) => days.slice(w * 7, w * 7 + 7));
      return `<div class="table-wrap"><table class="t sm-cal"><thead><tr><th>${esc(W("الأسبوع", "Week"))}</th>${weeks[0].map((dt) => `<th>${esc(dayName(dt))}</th>`).join("")}</tr></thead><tbody>${weeks.map((wk, w) => `<tr><th scope="row">${esc(W("أ", "W"))}${w + 1}</th>${wk.map((dt) => `<td><span class="dn">${dm(dt)}</span>${d.items.map((it, i) => (smHit(it, dt, s) ? chip(i, it) : "")).join("")}</td>`).join("")}</tr>`).join("")}</tbody></table></div>${batchNote}`;
    }
    const nW = Math.ceil(days.length / 7), weeks = Array.from({ length: nW }, (_, w) => days.slice(w * 7, w * 7 + 7));
    const dated = d.items.map((it, i) => [it, i]).filter(([it]) => it.freq !== "batch");
    return `<div class="table-wrap"><table class="t sm-cal sm-q"><thead><tr><th>${esc(W("العينة", "Sample"))}</th>${weeks.map((wk, w) => `<th>${esc(W("أ", "W"))}${w + 1}<br><small>${dm(wk[0])}</small></th>`).join("")}</tr></thead><tbody>${dated.map(([it, i]) => `<tr><th scope="row">${chip(i, it)} <span style="white-space:normal">${esc(it.point)}</span></th>${weeks.map((wk) => { const hit = wk.filter((dt) => smHit(it, dt, s)); return `<td>${!hit.length ? `<span style="color:var(--dim)">—</span>` : hit.length <= 2 ? hit.map((dt) => `<span class="dn" style="margin:0">${dm(dt)}</span>`).join("") : `<b>×${hit.length}</b>`}</td>`; }).join("")}</tr>`).join("") || `<tr><td colspan="${nW + 1}">—</td></tr>`}</tbody></table></div><p class="note">${esc(W("الخلية تعرض تاريخ العينة (يوم/شهر) أو عدد العينات في ذلك الأسبوع.", "Each cell shows the sampling date (day/month) or the number of samples that week."))}</p>${batchNote}`;
  };
  const ICMSF_NOTE = () => W("خطة ICMSF (اختيارية): n عدد الوحدات المأخوذة من الدفعة؛ c أقصى عدد من الوحدات يُسمح أن تقع نتيجتها بين m وM؛ m الحد الفاصل بين المقبول والمقبول بشروط؛ M الحد الذي تُرفض فوقه أي وحدة. أدخل القيم من مواصفتك أو التشريع المطبّق — لا توجد قيم افتراضية.", "ICMSF plan (optional): n = number of sample units taken from the lot; c = maximum number of units allowed to fall between m and M; m = limit separating acceptable from marginally acceptable; M = limit above which any unit is unacceptable. Enter values from your specification or applicable regulation — there are no defaults.");
  const samplingPage = builder({
    id: "sampling",
    blank: () => ({ id: uid(), title: "", start: today(), horizon: "4w", items: [newItem()] }),
    fix: (d) => { d.items = d.items || []; d.horizon = d.horizon === "3m" ? "3m" : "4w"; },
    label: (d) => d.title,
    intro: () => `<p style="margin:0">${esc(W("أعداد العينات وأحجامها ومعايير القبول تأتي من مواصفتك أو التشريع المطبّق عليك أو متطلبات عميلك — الأداة لا تقترح أيًّا منها. إن كنت تستخدم خطط ICMSF فأدخل n وc وm وM بنفسك.", "Sample numbers, sizes and acceptance criteria come from your specification, applicable regulation or customer requirement — the tool suggests none. If you use ICMSF plans, enter n, c, m and M yourself."))}</p><p class="note" style="margin-bottom:0">${esc(ICMSF_NOTE())}</p>`,
    body: (d) => `<div class="card"><div class="form">
        ${fld("sm-title", W("اسم الخطة / المنشأة", "Plan / site name"), inp("sm-title", "text", d.title, bind(0, 0, "title")), { req: 1 })}
        ${fld("sm-start", W("تاريخ البدء", "Start date"), inp("sm-start", "date", d.start, bind(0, 0, "start")), { req: 1 })}
        <div class="field full"><span class="lbl" id="sm-hz-l">${esc(W("مدى التقويم", "Calendar range"))}</span><div class="seg pick" role="group" aria-labelledby="sm-hz-l">${[["4w", W("4 أسابيع", "4 weeks")], ["3m", W("3 أشهر", "3 months")]].map(([k, l]) => `<button type="button" data-act="hz" data-id="${k}" aria-pressed="${d.horizon === k}">${esc(l)}</button>`).join("")}</div></div></div></div>
      <h3 style="margin:24px 0 12px;font-size:18px">${esc(W("نقاط أخذ العينات", "Sampling points"))}</h3>
      ${d.items.map((it, i) => { const b = (k) => bind("items", it.id, k), id = (k) => `sm-${it.id}-${k}`;
        return `<div class="card plan-item"><div class="row" style="margin-bottom:12px"><span class="sm-it">#${i + 1}</span><b id="smh-${it.id}">${esc(it.point || "—")}</b><span class="spacer"></span>${delBtn("rmi", it.id)}</div><div class="form">
          ${fld(id("point"), W("نقطة أخذ العينة / المنتج", "Sampling point / product"), inp(id("point"), "text", it.point, b("point")), { req: 1 })}
          ${fld(id("test"), W("الفحص", "Test"), `<select id="${id("test")}" ${b("test")}><option value="">—</option><optgroup label="${esc(W("ميكروبيولوجي", "Microbiological"))}">${optsHtml(MICRO, it.test)}</optgroup><optgroup label="${esc(W("أخرى", "Other"))}">${optsHtml(OTHER_T, it.test)}</optgroup></select>`, { req: 1 })}
          ${fld(id("detail"), W("تفاصيل الفحص / الطريقة", "Test details / method"), inp(id("detail"), "text", it.detail, b("detail")), { hint: W("مثل: المعيار أو المادة الكيميائية المطلوب تحليلها.", "e.g. method standard or the analyte to test.") })}
          ${fld(id("freq"), W("التكرار", "Frequency"), `<select id="${id("freq")}" ${b("freq")} data-redraw>${optsHtml(SFREQ, it.freq, 1)}</select>`, { req: 1 })}
          ${it.freq === "weekly" ? fld(id("wd"), W("يوم الأسبوع", "Day of week"), `<select id="${id("wd")}" ${b("wd")}>${optsHtml(WEEKDAYS(), it.wd, 1)}</select>`, { hint: W("إن تُرك فارغًا: يوم تاريخ البدء.", "If empty: the start date's weekday.") }) : ""}
          ${it.freq === "monthly" || it.freq === "quarterly" ? fld(id("dom"), W("يوم الشهر (1–28)", "Day of month (1–28)"), inp(id("dom"), "number", it.dom, b("dom"), 'min="1" max="28" step="1"'), { hint: W("إن تُرك فارغًا: يوم تاريخ البدء.", "If empty: the start date's day.") }) : ""}
          ${fld(id("size"), W("حجم العينة / الوحدات", "Sample size / units"), inp(id("size"), "text", it.size, b("size")), { req: 1, hint: W("كما تنص مواصفتك.", "As your specification states.") })}
          ${fld(id("lab"), W("المختبر", "Lab"), `<select id="${id("lab")}" ${b("lab")}>${optsHtml(LABS, it.lab, 1)}</select>`, { req: 1 })}
          ${fld(id("labName"), W("اسم المختبر", "Lab name"), inp(id("labName"), "text", it.labName, b("labName")))}
          ${fld(id("resp"), W("المسؤول", "Responsible"), inp(id("resp"), "text", it.resp, b("resp")), { req: 1 })}
          <details class="full sm-icmsf" ${["n", "c", "m", "M"].some((k) => has(it[k])) ? "open" : ""}><summary>${esc(W("خطة ICMSF (n, c, m, M) — اختيارية", "ICMSF plan (n, c, m, M) — optional"))}</summary><p class="note">${esc(ICMSF_NOTE())}</p><div class="form">
            ${fld(id("n"), W("n — عدد الوحدات", "n — sample units"), inp(id("n"), "number", it.n, b("n"), 'min="0" step="1"'))}
            ${fld(id("c"), W("c — أقصى عدد بين m وM", "c — max units between m and M"), inp(id("c"), "number", it.c, b("c"), 'min="0" step="1"'))}
            ${fld(id("m"), "m", inp(id("m"), "number", it.m, b("m"), 'step="any"'))}
            ${fld(id("M"), "M", inp(id("M"), "number", it.M, b("M"), 'step="any"'))}
            ${fld(id("unit"), W("وحدة m وM", "Unit for m and M"), inp(id("unit"), "text", it.unit, b("unit"), `placeholder="${esc(W("مثل: CFU/g", "e.g. CFU/g"))}"`))}
          </div></details></div></div>`; }).join("")}
      <div class="row"><button type="button" class="btn btn-ghost btn-sm" data-act="addi">${I.plus}<span>${esc(W("أضف نقطة", "Add sampling point"))}</span></button><span class="err" id="sm-items-e"></span></div>
      <div class="card" style="margin-top:22px"><h3 style="font-size:18px">${esc(W("التقويم", "Calendar"))}</h3><div id="smCal"></div><h4 style="margin:18px 0 8px;font-size:15px">${esc(W("مفتاح العينات", "Sample key"))}</h4><div id="smKey"></div></div>`,
    live: (d, el) => {
      if (el && el.dataset && el.dataset.a === "items" && el.dataset.k === "point") { const h = $("#smh-" + el.dataset.r); if (h) h.textContent = el.value || "—"; }
      const c = $("#smCal"); if (c) c.innerHTML = smCal(d); const k = $("#smKey"); if (k) k.innerHTML = d.items.length ? smLegend(d) : "";
    },
    act: (a, id, d) => {
      if (a === "hz") { d.horizon = id === "3m" ? "3m" : "4w"; return undefined; }
      if (a === "addi") { const it = newItem(); d.items.push(it); return { focus: `sm-${it.id}-point` }; }
      if (a === "rmi") { const it = d.items.find((x) => x.id === id); if (!confirm(W(`حذف «${(it && it.point) || "—"}»؟`, `Remove "${(it && it.point) || "—"}"?`))) return false; d.items = d.items.filter((x) => x.id !== id); return undefined; }
      return false;
    },
    validate: (d) => {
      let ok = setErr($("#sm-title"), d.title.trim() ? "" : t("required"));
      ok = setErr($("#sm-start"), d.start ? "" : t("required")) && ok;
      const ie = $("#sm-items-e"); if (ie) ie.textContent = d.items.length ? "" : W("أضف نقطة واحدة على الأقل.", "Add at least one sampling point.");
      if (!d.items.length) ok = false;
      const int0 = (v) => has(v) && Number.isInteger(+v) && +v >= 0;
      d.items.forEach((it) => {
        const e = (k, msg) => (ok = setErr($(`#sm-${it.id}-${k}`), msg) && ok);
        ["point", "test", "freq", "size", "lab", "resp"].forEach((k) => e(k, String(it[k] || "").trim() ? "" : t("required")));
        if (it.freq === "monthly" || it.freq === "quarterly") e("dom", has(it.dom) && !(Number.isInteger(+it.dom) && +it.dom >= 1 && +it.dom <= 28) ? W("أدخل رقمًا صحيحًا بين 1 و28.", "Enter a whole number from 1 to 28.") : "");
        e("n", has(it.n) && !int0(it.n) ? W("أدخل عددًا صحيحًا موجبًا.", "Enter a whole non-negative number.") : "");
        e("c", has(it.c) && !int0(it.c) ? W("أدخل عددًا صحيحًا موجبًا.", "Enter a whole non-negative number.") : int0(it.c) && int0(it.n) && +it.c > +it.n ? W("لا يمكن أن يتجاوز c قيمة n.", "c can't exceed n.") : "");
        e("M", has(it.m) && has(it.M) && +it.M < +it.m ? W("يجب أن يكون M أكبر من m أو مساويًا له.", "M must be greater than or equal to m.") : "");
      });
      return ok;
    },
    cols: [[{ ar: "الخطة", en: "Plan" }, (r) => esc(r.title)], [{ ar: "النقاط", en: "Points" }, (r) => r.items.length], [{ ar: "البدء", en: "Start" }, (r) => esc(fmtDate(r.start))], [{ ar: "المدى", en: "Range" }, (r) => esc(r.horizon === "3m" ? W("3 أشهر", "3 months") : W("4 أسابيع", "4 weeks"))]],
    report: (d) => LAND + kvTable([[W("الخطة / المنشأة", "Plan / site"), esc(d.title)], [W("تاريخ البدء", "Start date"), esc(fmtDate(d.start))], [W("المدى", "Range"), esc(d.horizon === "3m" ? W("3 أشهر", "3 months") : W("4 أسابيع", "4 weeks"))]]) + `<h3>${esc(W("مفتاح العينات", "Sample key"))}</h3>${smLegend(d)}<h3>${esc(W("التقويم", "Calendar"))}</h3>${smCal(d)}<p style="font-size:9pt">${esc(ICMSF_NOTE())}</p>` + sigTable([W("أعدّه", "Prepared by"), W("اعتمده", "Approved by"), W("التاريخ", "Date")]),
    csv: (d) => [[ "#", W("نقطة / منتج", "Point / product"), W("الفحص", "Test"), W("التكرار", "Frequency"), W("حجم العينة / الوحدات", "Sample size / units"), W("المختبر", "Lab"), W("اسم المختبر", "Lab name"), W("المسؤول", "Responsible"), "n", "c", "m", "M", W("الوحدة", "Unit")], ...d.items.map((it, i) => [i + 1, it.point, smTest(it), smFreq(it).replace(/<[^>]+>/g, ""), it.size, labOf(LABS, it.lab), it.labName, it.resp, it.n, it.c, it.m, it.M, it.unit])],
  });

  /* =====================================================================
     4) Goods receiving inspection (record tool)
     ===================================================================== */
  const DEC = [opt("accept", "قبول", "Accept"), opt("remark", "قبول مع ملاحظة", "Accept with remark"), opt("reject", "رفض", "Reject")];
  const decChip = (v) => { const o = DEC.find((x) => x.v === v); return o ? `<span class="chip ${v === "accept" ? "ok" : v === "remark" ? "warn" : "bad"}">${esc(L(o.l))}</span>` : ""; };
  const RSEL = {
    vehicle: [opt("ok", "مطابقة", "OK"), opt("notok", "غير مطابقة", "Not OK")],
    pack: [opt("intact", "سليمة", "Intact"), opt("damaged", "تالفة / مفتوحة", "Damaged / opened")],
    label: [opt("complete", "مكتمل", "Complete"), opt("incomplete", "ناقص", "Incomplete")],
    coa: [opt("yes", "مُستلَمة", "Received"), opt("no", "غير مُستلَمة", "Not received"), opt("na", "غير مطلوبة", "Not required")],
    pest: [opt("none", "لا توجد", "None"), opt("found", "توجد دلائل", "Signs found")],
  };
  const rcvWarn = (r) => {
    const rej = [], rev = [];
    if (has(r.temp) && ((has(r.tmin) && +r.temp < +r.tmin) || (has(r.tmax) && +r.temp > +r.tmax))) rej.push(W("درجة حرارة المنتج خارج النطاق الذي حددته", "Product temperature is outside your acceptable range"));
    const rd = (r.at || "").slice(0, 10) || today(); if (r.expiry && r.expiry < rd) rej.push(W("تاريخ الانتهاء قد مضى", "The expiry date has passed"));
    if (r.vehicle === "notok") rev.push(W("نظافة المركبة غير مطابقة", "Vehicle hygiene not OK"));
    if (r.pack === "damaged") rev.push(W("التعبئة تالفة", "Packaging damaged"));
    if (r.label === "incomplete") rev.push(W("الملصق ناقص", "Label incomplete"));
    if (r.coa === "no") rev.push(W("الشهادة / COA غير مُستلَمة", "Certificate / COA not received"));
    if (r.pest === "found") rev.push(W("دلائل على وجود آفات", "Pest signs found"));
    return { rej, rev };
  };
  const rcvFlagHtml = (r) => { const w = rcvWarn(r); return (w.rej.length ? `<div class="disclaimer" style="margin-bottom:8px">${I.warn}<div><b>${esc(W("يُقترح الرفض", "Consider rejecting"))}:</b> ${w.rej.map(esc).join("؛ ")}</div></div>` : "") + (w.rev.length ? `<div class="row" style="gap:6px">${w.rev.map((x) => `<span class="chip warn">${esc(x)}</span>`).join("")}</div>` : "") || `<span class="chip ok">${esc(W("لا توجد ملاحظات حتى الآن", "No issues flagged so far"))}</span>`; };
  let rcvPhoto = "";
  const okPhoto = (s) => (typeof s === "string" && /^data:image\/(jpeg|png|webp|gif);base64,[A-Za-z0-9+/=]+$/.test(s) ? s : "");
  const receiving = recordTool({
    id: "receiving",
    defaults: () => ({ at: nowLocal() }),
    label: (r) => `${r.supplier || ""} · ${r.product || ""}`,
    intro: () => `<datalist id="rcvSup">${[...new Set(store.get("tool:receiving", []).map((r) => r.supplier).filter(Boolean))].map((s) => `<option value="${esc(s)}">`).join("")}</datalist><div class="card" style="padding:16px 18px"><p style="margin:0">${esc(W("أدخل نطاق الحرارة المقبول من مواصفة المنتج أو التشريع المطبّق عليك. تنبهك الأداة إلى الرفض إذا كانت الحرارة خارج نطاقك أو انتهت الصلاحية، والقرار النهائي لك.", "Enter the acceptable temperature range from the product specification or your applicable regulation. The tool warns you to consider rejection if the temperature is outside your range or the product is past its expiry; the final decision is yours."))}</p></div>`,
    fields: [
      { k: "at", type: "datetime-local", label: { ar: "تاريخ ووقت الاستلام", en: "Date & time received" }, req: true },
      { k: "supplier", label: { ar: "المورد", en: "Supplier" }, req: true, list: "rcvSup" },
      { k: "po", label: { ar: "رقم أمر الشراء / إشعار التسليم", en: "PO / delivery note no." } },
      { k: "product", label: { ar: "المنتج", en: "Product" }, req: true },
      { k: "batch", label: { ar: "رقم الدفعة", en: "Batch / lot no." } },
      { k: "expiry", type: "date", label: { ar: "تاريخ الانتهاء", en: "Expiry date" } },
      { k: "temp", type: "number", step: "0.1", label: { ar: "حرارة المنتج °م", en: "Product temperature °C" }, hint: { ar: "مقيسة عند الاستلام", en: "Measured at receipt" } },
      { k: "tmin", type: "number", step: "0.1", label: { ar: "الحد الأدنى المقبول °م", en: "Acceptable min °C" }, hint: { ar: "من مواصفتك أو التشريع المطبّق", en: "From your specification or applicable regulation" } },
      { k: "tmax", type: "number", step: "0.1", label: { ar: "الحد الأعلى المقبول °م", en: "Acceptable max °C" }, hint: { ar: "من مواصفتك أو التشريع المطبّق", en: "From your specification or applicable regulation" } },
      { k: "vehicle", type: "select", req: true, label: { ar: "نظافة المركبة", en: "Vehicle hygiene" }, opts: RSEL.vehicle },
      { k: "pack", type: "select", req: true, label: { ar: "حالة التعبئة", en: "Packaging condition" }, opts: RSEL.pack },
      { k: "label", type: "select", req: true, label: { ar: "اكتمال بيانات الملصق", en: "Label complete" }, opts: RSEL.label },
      { k: "coa", type: "select", req: true, label: { ar: "شهادة التحليل / الشهادات", en: "COA / certificate received" }, opts: RSEL.coa },
      { k: "pest", type: "select", req: true, label: { ar: "دلائل الآفات", en: "Pest signs" }, opts: RSEL.pest },
      { k: "flag", type: "custom", full: true, mount(el) { el.innerHTML = `<span class="lbl">${esc(W("تنبيهات تلقائية", "Automatic warnings"))}</span><div id="rcvFlag" aria-live="polite"></div>`; }, read() { return ""; } },
      { k: "decision", type: "select", req: true, label: { ar: "القرار", en: "Decision" }, opts: DEC },
      { k: "reason", type: "textarea", full: true, rows: 2, label: { ar: "السبب / الملاحظة", en: "Reason / remark" }, hint: { ar: "مطلوب عند القبول مع ملاحظة أو الرفض.", en: "Required for accept with remark or reject." } },
      { k: "photo", type: "custom", full: true,
        mount(el, r) {
          rcvPhoto = okPhoto(r.photo);
          const draw = () => {
            el.innerHTML = `<span class="lbl">${esc(W("صورة (اختيارية)", "Photo (optional)"))}</span><div class="thumbs">${rcvPhoto ? `<figure><img src="${esc(rcvPhoto)}" alt="${esc(W("صورة الاستلام", "Receiving photo"))}"><button type="button" data-rm aria-label="${esc(t("del"))}">×</button></figure>` : `<label class="btn btn-ghost btn-sm" style="cursor:pointer;height:96px;width:96px;flex-direction:column;border-radius:8px">${I.camera}<span style="font-size:11.5px">+</span><input type="file" accept="image/*" capture="environment" hidden aria-label="${esc(W("إضافة صورة", "Add photo"))}"></label>`}</div><span class="hint">${esc(W("صورة واحدة، تُصغَّر وتُحفظ على جهازك فقط.", "One photo, resized and kept on your device only."))}</span>`;
            const rm = $("[data-rm]", el); rm && rm.addEventListener("click", () => { rcvPhoto = ""; draw(); });
            const fi = $("input[type=file]", el);
            fi && fi.addEventListener("change", async () => { const f = fi.files[0]; if (!f) return; try { rcvPhoto = await readImage(f, 640); draw(); } catch (e) { toast(e.message === "size" ? W("الملف أكبر من 15 ميغابايت.", "File is larger than 15 MB.") : W("نوع الملف غير مدعوم — اختر صورة.", "Unsupported file — choose an image."), "bad"); } });
          };
          draw();
        },
        read() { return rcvPhoto; } },
      { k: "by", label: { ar: "المستلِم", en: "Received by" }, req: true },
    ],
    onFill: () => {
      const val = (k) => { const el = $("#f-" + k); return el ? el.value : ""; };
      const flag = () => { const box = $("#rcvFlag"); if (box) box.innerHTML = rcvFlagHtml({ at: val("at"), expiry: val("expiry"), temp: val("temp"), tmin: val("tmin"), tmax: val("tmax"), vehicle: val("vehicle"), pack: val("pack"), label: val("label"), coa: val("coa"), pest: val("pest") }); };
      ["at", "expiry", "temp", "tmin", "tmax", "vehicle", "pack", "label", "coa", "pest"].forEach((k) => { const el = $("#f-" + k); if (el) { el.addEventListener("input", flag); el.addEventListener("change", flag); } });
      flag();
    },
    check: (k, r) => (k === "reason" && r.decision && r.decision !== "accept" && !r.reason ? t("required")
      : k === "tmax" && has(r.tmin) && has(r.tmax) && r.tmax < r.tmin ? W("الحد الأعلى أقل من الأدنى.", "Max is below min.")
      : k === "temp" && !has(r.temp) && (has(r.tmin) || has(r.tmax)) ? W("أدخل الحرارة المقيسة أو احذف النطاق.", "Enter the measured temperature or clear the range.") : ""),
    compute: (r) => { const w = rcvWarn(r); r.warn = w.rej.length > 0; },
    columns: [
      { l: { ar: "الوقت", en: "Time" }, f: (r) => `<span dir="ltr">${esc((r.at || "").replace("T", " "))}</span>` },
      { l: { ar: "المورد", en: "Supplier" }, f: (r) => esc(r.supplier) },
      { l: { ar: "المنتج", en: "Product" }, f: (r) => esc(r.product) + (r.batch ? `<br><small style="color:var(--dim)">${esc(r.batch)}</small>` : "") },
      { l: { ar: "الحرارة", en: "Temp" }, f: (r) => (has(r.temp) ? `<span dir="ltr">${esc(r.temp)}°C</span>` : "—") },
      { l: { ar: "القرار", en: "Decision" }, f: (r) => decChip(r.decision) + (rcvWarn(r).rej.length && r.decision !== "reject" ? ` <span class="chip bad" title="${esc(rcvWarn(r).rej.join(" · "))}">!</span>` : "") },
      { l: { ar: "المستلِم", en: "Received by" }, f: (r) => esc(r.by) },
    ],
    csvKeys: ["at", "supplier", "po", "product", "batch", "expiry", "temp", "tmin", "tmax", "vehicle", "pack", "label", "coa", "pest", "decision", "reason", "by"],
    below: (el, all) => {
      if (!all.length) { el.innerHTML = ""; return; }
      const by = {}; all.forEach((r) => { const k = (r.supplier || "—").trim(); const o = (by[k] = by[k] || { n: 0, a: 0, m: 0, x: 0 }); o.n++; if (r.decision === "accept") o.a++; else if (r.decision === "remark") o.m++; else if (r.decision === "reject") o.x++; });
      const rows = Object.entries(by).map(([k, o]) => [k, o, ((o.a + o.m) / o.n) * 100]).sort((a, b) => a[2] - b[2]);
      el.innerHTML = `<div class="card" style="margin-bottom:16px"><h3 style="font-size:16px">${esc(W("نسبة القبول حسب المورد", "Acceptance rate by supplier"))}</h3><div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("المورد", "Supplier"))}</th><th>${esc(W("الشحنات", "Deliveries"))}</th><th>${esc(W("قبول", "Accepted"))}</th><th>${esc(W("مع ملاحظة", "With remark"))}</th><th>${esc(W("رفض", "Rejected"))}</th><th>${esc(W("نسبة القبول", "Acceptance rate"))}</th></tr></thead><tbody>${rows.map(([k, o, p]) => `<tr><td>${esc(k)}</td><td>${o.n}</td><td>${o.a}</td><td>${o.m}</td><td>${o.x}</td><td><b data-rate="${esc(k)}">${num(p, 1)}%</b></td></tr>`).join("")}</tbody></table></div><p class="note" style="margin-bottom:0">${esc(W("نسبة القبول = (قبول + قبول مع ملاحظة) ÷ إجمالي الشحنات × 100.", "Acceptance rate = (accepted + accepted with remark) ÷ total deliveries × 100."))}</p></div>`;
    },
    print: (r) => { const sel = (k) => { const o = (RSEL[k] || []).find((x) => x.v === r[k]); return o ? esc(L(o.l)) : ""; }; const w = rcvWarn(r); const ph = okPhoto(r.photo);
      return kvTable([[W("التاريخ والوقت", "Date & time"), `<span dir="ltr">${esc((r.at || "").replace("T", " "))}</span>`], [W("المورد", "Supplier"), esc(r.supplier)], [W("أمر الشراء / إشعار التسليم", "PO / delivery note"), esc(r.po)], [W("المنتج", "Product"), esc(r.product)], [W("الدفعة", "Batch"), esc(r.batch)], [W("تاريخ الانتهاء", "Expiry"), esc(fmtDate(r.expiry))], [W("الحرارة", "Temperature"), has(r.temp) ? `<span dir="ltr">${esc(r.temp)}°C (${has(r.tmin) ? esc(r.tmin) : "−∞"} … ${has(r.tmax) ? esc(r.tmax) : "+∞"})</span>` : ""], [W("نظافة المركبة", "Vehicle hygiene"), sel("vehicle")], [W("التعبئة", "Packaging"), sel("pack")], [W("الملصق", "Label"), sel("label")], [W("الشهادات", "COA / certificate"), sel("coa")], [W("الآفات", "Pest signs"), sel("pest")], [W("تنبيهات", "Warnings"), [...w.rej, ...w.rev].map(esc).join("<br>")], [W("القرار", "Decision"), decChip(r.decision)], [W("السبب / الملاحظة", "Reason / remark"), esc(r.reason)], [W("المستلِم", "Received by"), esc(r.by)]]) +
        (ph ? `<img src="${esc(ph)}" alt="" style="width:220px;margin-top:12px;border:1px solid #bbb;border-radius:4px">` : "") + sigTable([W("المستلِم", "Received by"), W("مراقبة الجودة", "QC")]); },
  });

  /* =====================================================================
     5) Supplier evaluation matrix
     ===================================================================== */
  const CRIT = [["quality", "الجودة ومطابقة المواصفات", "Quality / conformity"], ["delivery", "الالتزام بمواعيد التسليم", "On-time delivery"], ["certs", "الشهادات (مثل ISO 22000 / FSSC 22000 / HACCP)", "Certificates (e.g. ISO 22000 / FSSC 22000 / HACCP)"], ["complaints", "الشكاوى وحالات عدم المطابقة", "Complaints / NCRs"], ["price", "السعر والخدمة", "Price / service"], ["audit", "نتيجة التدقيق", "Audit result"]];
  const SSTAT = [["approved", "معتمد", "Approved"], ["conditional", "معتمد بشروط", "Conditionally approved"], ["review", "قيد التقييم", "Under evaluation"], ["rejected", "غير معتمد", "Not approved"]];
  const newSup = () => ({ id: uid(), name: "", category: "", scores: {}, status: "", next: "", notes: "" });
  const wSum = (d) => CRIT.reduce((s, [k]) => s + (has(d.weights[k]) ? Number(d.weights[k]) : 0), 0);
  const supScore = (d, s) => { const tot = wSum(d); if (!tot || CRIT.some(([k]) => !has(s.scores[k]) || s.scores[k] === "")) return null; return CRIT.reduce((a, [k]) => a + Number(d.weights[k] || 0) * Number(s.scores[k]), 0) / (5 * tot) * 100; };
  const rating = (d, sc) => (sc == null ? null : sc >= +d.bands.a ? "A" : sc >= +d.bands.b ? "B" : "C");
  const ratingChip = (d, sc) => { const r = rating(d, sc); return r ? `<span class="chip ${r === "A" ? "ok" : r === "B" ? "warn" : "bad"}"><b>${r}</b></span>` : `<span class="chip">—</span>`; };
  const statChip = (v) => (v ? `<span class="chip ${v === "approved" ? "ok" : v === "conditional" ? "warn" : v === "rejected" ? "bad" : ""}">${esc(labOf(SSTAT, v))}</span>` : "");
  const ranked = (d) => d.sups.map((s) => ({ s, sc: supScore(d, s) })).sort((a, b) => (b.sc == null ? -1 : b.sc) - (a.sc == null ? -1 : a.sc));
  const spRankHtml = (d) => d.sups.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>#</th><th>${esc(W("المورد", "Supplier"))}</th><th>${esc(W("الفئة", "Category"))}</th><th>${esc(W("النتيجة الموزونة", "Weighted score"))}</th><th>${esc(W("التصنيف", "Rating"))}</th><th>${esc(W("حالة الاعتماد", "Approval status"))}</th><th>${esc(W("التقييم القادم", "Next evaluation"))}</th></tr></thead><tbody>${ranked(d).map(({ s, sc }, i) => `<tr><td>${i + 1}</td><td>${esc(s.name || "—")}</td><td>${esc(s.category)}</td><td><b dir="ltr">${sc == null ? "—" : num(sc, 1) + "%"}</b></td><td>${ratingChip(d, sc)}</td><td>${statChip(s.status)}</td><td>${esc(fmtDate(s.next))}${s.next && s.next < today() ? ` <span class="chip bad">${esc(W("متأخر", "Overdue"))}</span>` : ""}</td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(W("أضف موردًا.", "Add a supplier."))}</div>`;
  const BANDS_NOTE = (d) => W(`التصنيف المعلن: A ≥ ${d.bands.a}% · B من ${d.bands.b}% إلى أقل من ${d.bands.a}% · C أقل من ${d.bands.b}%. عدّله وفق إجراء منشأتك.`, `Declared bands: A ≥ ${d.bands.a}% · B ${d.bands.b}% to below ${d.bands.a}% · C below ${d.bands.b}%. Adapt them to your site procedure.`);
  const suppliersPage = builder({
    id: "suppliers",
    blank: () => ({ id: uid(), title: "", period: "", weights: { quality: 25, delivery: 15, certs: 20, complaints: 15, price: 10, audit: 15 }, bands: { a: 85, b: 70 }, sups: [newSup()] }),
    fix: (d) => { d.sups = d.sups || []; d.weights = d.weights || {}; d.bands = d.bands || { a: 85, b: 70 }; d.sups.forEach((s) => (s.scores = s.scores || {})); },
    label: (d) => d.title,
    intro: () => `<p style="margin:0">${esc(W("النتيجة الموزونة % = Σ(الوزن × الدرجة) ÷ (5 × Σالأوزان) × 100. الدرجات من 1 (ضعيف) إلى 5 (ممتاز)؛ في معيار الشكاوى تعني 5 أقل عدد من الشكاوى. الأوزان والتصنيف معلنة وقابلة للتعديل.", "Weighted score % = Σ(weight × score) ÷ (5 × Σweights) × 100. Scores run from 1 (poor) to 5 (excellent); for complaints, 5 means the fewest. Weights and rating bands are declared and editable."))}</p>`,
    body: (d) => `<div class="card"><div class="form">
        ${fld("sp-title", W("اسم التقييم / المنشأة", "Evaluation / site name"), inp("sp-title", "text", d.title, bind(0, 0, "title")), { req: 1 })}
        ${fld("sp-period", W("فترة التقييم", "Evaluation period"), inp("sp-period", "text", d.period, bind(0, 0, "period"), `placeholder="${esc(W("مثل: النصف الأول 2026", "e.g. H1 2026"))}"`))}</div></div>
      <div class="grid g2" style="margin-top:16px;align-items:start">
        <div class="card"><h3 style="font-size:17px">${esc(W("أوزان المعايير (المجموع 100)", "Criteria weights (must total 100)"))}</h3><div class="form">${CRIT.map(([k, a, e]) => fld(`sp-w-${k}`, W(a, e), inp(`sp-w-${k}`, "number", d.weights[k], bind(0, 0, "weights." + k), 'min="0" max="100" step="1"'))).join("")}</div>
          <p style="margin:14px 0 0">${esc(W("المجموع", "Total"))}: <span id="spSum"></span> <span class="err" id="spSum-e" role="alert"></span></p></div>
        <div class="card"><h3 style="font-size:17px">${esc(W("حدود التصنيف (%)", "Rating bands (%)"))}</h3><div class="form">
          ${fld("sp-ba", W("الحد الأدنى للفئة A", "Minimum for A"), inp("sp-ba", "number", d.bands.a, bind(0, 0, "bands.a"), 'min="0" max="100" step="any"'), { req: 1 })}
          ${fld("sp-bb", W("الحد الأدنى للفئة B", "Minimum for B"), inp("sp-bb", "number", d.bands.b, bind(0, 0, "bands.b"), 'min="0" max="100" step="any"'), { req: 1 })}</div>
          <p class="note" id="spBands"></p></div></div>
      <div class="card" style="margin-top:16px"><h3 style="font-size:17px">${esc(W("الترتيب", "Ranking"))}</h3><div id="spRank"></div></div>
      <h3 style="margin:24px 0 12px;font-size:18px">${esc(W("الموردون", "Suppliers"))}</h3>
      ${d.sups.map((s, i) => { const id = (k) => `sp-${s.id}-${k}`, b = (k) => bind("sups", s.id, k);
        return `<div class="card plan-item"><div class="row" style="margin-bottom:12px"><span class="chip gold">${i + 1}</span><b id="sph-${s.id}">${esc(s.name || "—")}</b><span id="sps-${s.id}"></span><span class="spacer"></span>${delBtn("rms", s.id)}</div><div class="form">
          ${fld(id("name"), W("اسم المورد", "Supplier name"), inp(id("name"), "text", s.name, b("name")), { req: 1 })}
          ${fld(id("category"), W("الفئة", "Category"), inp(id("category"), "text", s.category, b("category"), `placeholder="${esc(W("مثل: لحوم، تعبئة", "e.g. meat, packaging"))}"`))}
          ${CRIT.map(([k, a, e]) => fld(id("s-" + k), W(a, e), `<select id="${id("s-" + k)}" ${b("scores." + k)}><option value="">—</option>${[1, 2, 3, 4, 5].map((n) => `<option ${String(s.scores[k]) === String(n) ? "selected" : ""}>${n}</option>`).join("")}</select>`, { req: 1 })).join("")}
          ${fld(id("status"), W("حالة الاعتماد", "Approval status"), `<select id="${id("status")}" ${b("status")}>${optsHtml(SSTAT, s.status, 1)}</select>`, { req: 1 })}
          ${fld(id("next"), W("موعد التقييم القادم", "Next evaluation date"), inp(id("next"), "date", s.next, b("next")))}
          ${fld(id("notes"), W("ملاحظات / إجراءات مطلوبة", "Notes / actions required"), `<textarea id="${id("notes")}" rows="2" ${b("notes")}>${esc(s.notes)}</textarea>`, { full: 1 })}
        </div></div>`; }).join("")}
      <div class="row"><button type="button" class="btn btn-ghost btn-sm" data-act="adds">${I.plus}<span>${esc(W("أضف موردًا", "Add supplier"))}</span></button><span class="err" id="sp-sups-e"></span></div>`,
    live: (d, el) => {
      const sum = wSum(d), se = $("#spSum"); if (!se) return;
      se.innerHTML = `<span class="chip ${sum === 100 ? "ok" : "bad"}" dir="ltr">${num(sum)} / 100</span>`;
      $("#spBands").textContent = BANDS_NOTE(d);
      $("#spRank").innerHTML = spRankHtml(d);
      d.sups.forEach((s) => { const sc = supScore(d, s); const c = $("#sps-" + s.id); if (c) c.innerHTML = `<span class="chip" dir="ltr">${sc == null ? "—" : num(sc, 1) + "%"}</span> ${ratingChip(d, sc)}`; });
      if (el && el.dataset && el.dataset.k === "name" && el.dataset.r) { const h = $("#sph-" + el.dataset.r); if (h) h.textContent = el.value || "—"; }
    },
    act: (a, id, d) => {
      if (a === "adds") { const s = newSup(); d.sups.push(s); return { focus: `sp-${s.id}-name` }; }
      if (a === "rms") { const s = d.sups.find((x) => x.id === id); if (!confirm(W(`حذف المورد «${(s && s.name) || "—"}»؟`, `Remove supplier "${(s && s.name) || "—"}"?`))) return false; d.sups = d.sups.filter((x) => x.id !== id); return undefined; }
      return false;
    },
    validate: (d) => {
      let ok = setErr($("#sp-title"), d.title.trim() ? "" : t("required"));
      CRIT.forEach(([k]) => { const v = d.weights[k]; ok = setErr($(`#sp-w-${k}`), !has(v) ? t("required") : !(Number.isInteger(+v) && +v >= 0 && +v <= 100) ? W("عدد صحيح من 0 إلى 100.", "Whole number from 0 to 100.") : "") && ok; });
      const sum = wSum(d), sumOk = sum === 100; $("#spSum-e").textContent = sumOk ? "" : W(`مجموع الأوزان ${sum} — يجب أن يساوي 100.`, `Weights total ${sum} — they must total 100.`); if (!sumOk) { ok = false; CRIT.forEach(([k]) => $(`#sp-w-${k}`).setAttribute("aria-invalid", "true")); }
      const a = d.bands.a, b = d.bands.b;
      ok = setErr($("#sp-ba"), !has(a) ? t("required") : +a <= 0 || +a > 100 ? W("قيمة بين 0 و100.", "A value between 0 and 100.") : "") && ok;
      ok = setErr($("#sp-bb"), !has(b) ? t("required") : +b <= 0 || +b >= +a ? W("يجب أن يكون أكبر من 0 وأقل من حد الفئة A.", "Must be above 0 and below the A minimum.") : "") && ok;
      const pe = $("#sp-sups-e"); if (pe) pe.textContent = d.sups.length ? "" : W("أضف موردًا واحدًا على الأقل.", "Add at least one supplier.");
      if (!d.sups.length) ok = false;
      d.sups.forEach((s) => { const e = (k, msg) => (ok = setErr($(`#sp-${s.id}-${k}`), msg) && ok); e("name", s.name.trim() ? "" : t("required")); CRIT.forEach(([k]) => e("s-" + k, s.scores[k] ? "" : t("required"))); e("status", s.status ? "" : t("required")); });
      return ok;
    },
    compute: (r) => { r.res = ranked(r).map(({ s, sc }) => ({ name: s.name, sc, rt: rating(r, sc) })); },
    cols: [[{ ar: "التقييم", en: "Evaluation" }, (r) => esc(r.title)], [{ ar: "الفترة", en: "Period" }, (r) => esc(r.period)], [{ ar: "الموردون", en: "Suppliers" }, (r) => r.sups.length], [{ ar: "الأعلى", en: "Top" }, (r) => (r.res && r.res[0] ? `${esc(r.res[0].name)} <span dir="ltr">${r.res[0].sc == null ? "" : num(r.res[0].sc, 1) + "%"}</span>` : "—")]],
    report: (d) => kvTable([[W("التقييم / المنشأة", "Evaluation / site"), esc(d.title)], [W("الفترة", "Period"), esc(d.period)], [W("التصنيف", "Rating bands"), esc(BANDS_NOTE(d))]]) +
      `<h3>${esc(W("أوزان المعايير", "Criteria weights"))}</h3><table class="t" style="min-width:0"><tr>${CRIT.map(([, a, e]) => `<th style="white-space:normal">${esc(W(a, e))}</th>`).join("")}<th>${esc(W("المجموع", "Total"))}</th></tr><tr>${CRIT.map(([k]) => `<td>${esc(d.weights[k])}</td>`).join("")}<td><b>${wSum(d)}</b></td></tr></table>` +
      `<h3>${esc(W("الترتيب", "Ranking"))}</h3>${spRankHtml(d)}` +
      `<h3>${esc(W("الدرجات التفصيلية", "Detailed scores"))}</h3><table class="t" style="min-width:0"><tr><th>${esc(W("المورد", "Supplier"))}</th>${CRIT.map(([, a, e]) => `<th style="white-space:normal">${esc(W(a, e))}</th>`).join("")}<th>${esc(W("ملاحظات", "Notes"))}</th></tr>${ranked(d).map(({ s }) => `<tr><td>${esc(s.name)}</td>${CRIT.map(([k]) => `<td>${esc(s.scores[k] || "—")}</td>`).join("")}<td>${esc(s.notes)}</td></tr>`).join("")}</table>` +
      sigTable([W("أعدّه", "Prepared by"), W("اعتمده", "Approved by"), W("التاريخ", "Date")]),
    csv: (d) => [[W("الترتيب", "Rank"), W("المورد", "Supplier"), W("الفئة", "Category"), ...CRIT.map(([k, a, e]) => `${W(a, e)} (${W("الوزن", "weight")} ${d.weights[k]})`), W("النتيجة الموزونة %", "Weighted score %"), W("التصنيف", "Rating"), W("حالة الاعتماد", "Approval status"), W("التقييم القادم", "Next evaluation")], ...ranked(d).map(({ s, sc }, i) => [i + 1, s.name, s.category, ...CRIT.map(([k]) => s.scores[k] || ""), sc == null ? "" : Math.round(sc * 10) / 10, rating(d, sc) || "", labOf(SSTAT, s.status), s.next])],
  });

  /* =====================================================================
     6) Cleaning & sanitation plan builder
     ===================================================================== */
  const CFREQ = [["use", "بعد كل استخدام", "After each use"], ["shift", "كل وردية", "Each shift"], ["daily", "يومي", "Daily"], ["weekly", "أسبوعي", "Weekly"], ["monthly", "شهري", "Monthly"]];
  const VERIF = [["visual", "فحص بصري", "Visual"], ["atp", "اختبار ATP", "ATP"], ["swab", "مسحة ميكروبية", "Microbial swab"]];
  const defSteps = () => W("الشطف المبدئي\nالغسل بالمنظف\nالشطف\nالتطهير\nالتجفيف بالهواء", "Pre-rinse\nDetergent wash\nRinse\nSanitise\nAir dry");
  const newArea = () => ({ id: uid(), area: "", steps: defSteps(), chem: "", dose: "", contact: "", freq: "", wd: "", dom: "", resp: "", ver: {} });
  const sbox = (lab) => `<span class="sbox-i"><span class="sbox"></span>${lab ? `<small>${esc(lab)}</small>` : ""}</span>`;
  const clBoxes = (d, r, dt, s) => {
    if (r.freq === "use") return `<span class="sbox-wrap">${sbox()}${sbox()}${sbox()}</span>`;
    if (r.freq === "shift") { const n = Math.min(6, Math.max(1, +d.shifts || 1)); return `<span class="sbox-wrap">${Array.from({ length: n }, (_, i) => sbox(W("و", "S") + (i + 1))).join("")}</span>`; }
    if (r.freq === "daily") return `<span class="sbox-wrap">${sbox()}</span>`;
    if (r.freq === "weekly") return dt.getDay() === (r.wd === "" || r.wd == null ? s.getDay() : +r.wd) ? `<span class="sbox-wrap">${sbox()}</span>` : `<span style="color:var(--dim)">—</span>`;
    if (r.freq === "monthly") return dt.getDate() === (+r.dom || s.getDate()) ? `<span class="sbox-wrap">${sbox()}</span>` : `<span style="color:var(--dim)">—</span>`;
    return `<span style="color:var(--dim)">—</span>`;
  };
  const verLab = (r) => VERIF.filter(([k]) => r.ver && r.ver[k]).map(([, a, e]) => W(a, e)).join("، ");
  const clSched = (d) => {
    if (!d.weekOf) return `<div class="empty">${esc(W("اختر تاريخ بداية الأسبوع لعرض الجدول.", "Pick the week start date to see the schedule."))}</div>`;
    if (!d.rows.length) return `<div class="empty">${esc(W("أضف منطقة أو معدة.", "Add an area or equipment."))}</div>`;
    const s = parseD(d.weekOf), days = [0, 1, 2, 3, 4, 5, 6].map((i) => addDays(s, i));
    return `<div class="table-wrap"><table class="t cl-grid"><thead><tr><th>${esc(W("المنطقة / المعدة", "Area / equipment"))}</th>${days.map((dt) => `<th>${esc(dayName(dt))}<br><small>${dm(dt)}</small></th>`).join("")}</tr></thead><tbody>${d.rows.map((r) => `<tr><th scope="row" class="cl-area">${esc(r.area || "—")}<small>${esc(labOf(CFREQ, r.freq) || "—")}${r.resp ? " · " + esc(r.resp) : ""}${verLab(r) ? " · " + esc(verLab(r)) : ""}</small></th>${days.map((dt) => `<td>${clBoxes(d, r, dt, s)}</td>`).join("")}</tr>`).join("")}<tr><th scope="row" class="cl-area">${esc(W("تحقق المشرف", "Supervisor verification"))}</th>${days.map(() => `<td><span class="sbox-wrap">${sbox()}</span></td>`).join("")}</tr></tbody></table></div>
      <p class="note">${esc(W("وقّع بالأحرف الأولى في المربع بعد التنفيذ. «بعد كل استخدام»: مربع لكل مرة؛ أضف مربعات يدويًا عند الحاجة.", "Initial the box once done. \"After each use\": one box per clean; add more by hand if needed."))}</p>`;
  };
  const cleaningPage = builder({
    id: "cleaning",
    blank: () => ({ id: uid(), title: "", weekOf: today(), shifts: "", rows: [newArea()] }),
    fix: (d) => { d.rows = d.rows || []; d.rows.forEach((r) => (r.ver = r.ver || {})); },
    label: (d) => d.title,
    intro: () => `<p style="margin:0">${esc(W("اكتب اسم المادة الكيميائية كما يظهر في ملصقها، وخذ الجرعة وزمن التلامس من ملصق المنتج أو صحيفة بيانات السلامة (SDS) فقط. الأداة لا تقترح مواد أو تراكيز.", "Write the chemical name exactly as on its label, and take the dose and contact time only from the product label or safety data sheet (SDS). The tool never suggests chemicals or concentrations."))}</p><p class="note" style="margin-bottom:0"><a href="#/tools/dilution">${esc(W("حاسبة التخفيف (باستخدام بيانات الملصق)", "Dilution calculator (using label data)"))}</a></p>`,
    body: (d) => `<div class="card"><div class="form">
        ${fld("cl-title", W("المنشأة / القسم", "Site / department"), inp("cl-title", "text", d.title, bind(0, 0, "title")), { req: 1 })}
        ${fld("cl-weekOf", W("بداية الأسبوع", "Week starting"), inp("cl-weekOf", "date", d.weekOf, bind(0, 0, "weekOf")), { req: 1 })}
        ${fld("cl-shifts", W("عدد الورديات يوميًا", "Shifts per day"), inp("cl-shifts", "number", d.shifts, bind(0, 0, "shifts"), `min="1" max="6" step="1" placeholder="${esc(W("مطلوب عند اختيار «كل وردية»", "Needed for \"each shift\""))}"`))}
      </div></div>
      <h3 style="margin:24px 0 12px;font-size:18px">${esc(W("المناطق والمعدات", "Areas & equipment"))}</h3>
      ${d.rows.map((r, i) => { const id = (k) => `cl-${r.id}-${k}`, b = (k) => bind("rows", r.id, k);
        return `<div class="card plan-item"><div class="row" style="margin-bottom:12px"><span class="chip gold">${i + 1}</span><b id="clh-${r.id}">${esc(r.area || "—")}</b><span class="spacer"></span>${delBtn("rmr", r.id)}</div><div class="form">
          ${fld(id("area"), W("المنطقة / المعدة", "Area / equipment"), inp(id("area"), "text", r.area, b("area")), { req: 1 })}
          ${fld(id("resp"), W("المسؤول", "Responsible"), inp(id("resp"), "text", r.resp, b("resp")), { req: 1 })}
          ${fld(id("steps"), W("خطوات الطريقة (خطوة في كل سطر)", "Method steps (one per line)"), `<textarea id="${id("steps")}" rows="5" ${b("steps")}>${esc(r.steps)}</textarea>`, { full: 1, hint: W("عدّلها لتطابق إجراء التنظيف المعتمد لديك.", "Edit to match your approved cleaning procedure.") })}
          ${fld(id("chem"), W("المادة الكيميائية (الاسم كما في الملصق)", "Chemical (name as on label)"), inp(id("chem"), "text", r.chem, b("chem"), `placeholder="${esc(W("انسخ الاسم من ملصق المنتج", "Copy the name from the product label"))}"`))}
          ${fld(id("dose"), W("الجرعة / التخفيف — حسب ملصق المنتج", "Dose / dilution — as per product label"), inp(id("dose"), "text", r.dose, b("dose"), `placeholder="${esc(W("كما ورد في ملصق المنتج", "As stated on the product label"))}"`))}
          ${fld(id("contact"), W("زمن التلامس — من ملصق المنتج", "Contact time — from product label"), inp(id("contact"), "text", r.contact, b("contact"), `placeholder="${esc(W("كما ورد في ملصق المنتج", "As stated on the product label"))}"`))}
          ${fld(id("freq"), W("التكرار", "Frequency"), `<select id="${id("freq")}" ${b("freq")} data-redraw>${optsHtml(CFREQ, r.freq, 1)}</select>`, { req: 1 })}
          ${r.freq === "weekly" ? fld(id("wd"), W("يوم الأسبوع", "Day of week"), `<select id="${id("wd")}" ${b("wd")}>${optsHtml(WEEKDAYS(), r.wd, 1)}</select>`, { hint: W("إن تُرك فارغًا: أول يوم في الأسبوع.", "If empty: the first day of the week.") }) : ""}
          ${r.freq === "monthly" ? fld(id("dom"), W("يوم الشهر (1–28)", "Day of month (1–28)"), inp(id("dom"), "number", r.dom, b("dom"), 'min="1" max="28" step="1"'), { hint: W("يظهر في الجدول فقط إن وقع ضمن الأسبوع.", "Shows in the grid only if it falls in that week.") }) : ""}
          <fieldset class="field full cl-ver"><legend class="lbl req">${esc(W("طريقة التحقق", "Verification method"))}</legend><div class="row">${VERIF.map(([k, a, e]) => `<label class="chk" for="${id("v-" + k)}"><input type="checkbox" id="${id("v-" + k)}" ${b("ver." + k)} ${r.ver[k] ? "checked" : ""}><span>${esc(W(a, e))}</span></label>`).join("")}</div><span class="err" id="${id("ver")}-e"></span></fieldset>
        </div></div>`; }).join("")}
      <div class="row"><button type="button" class="btn btn-ghost btn-sm" data-act="addr">${I.plus}<span>${esc(W("أضف منطقة / معدة", "Add area / equipment"))}</span></button><span class="err" id="cl-rows-e"></span></div>
      <div class="card" style="margin-top:22px"><h3 style="font-size:18px">${esc(W("الجدول الأسبوعي مع خانات التوقيع", "Weekly schedule with sign-off boxes"))}</h3><div id="clSched"></div></div>`,
    live: (d, el) => {
      if (el && el.dataset && el.dataset.k === "area" && el.dataset.r) { const h = $("#clh-" + el.dataset.r); if (h) h.textContent = el.value || "—"; }
      const s = $("#clSched"); if (s) s.innerHTML = clSched(d);
    },
    act: (a, id, d) => {
      if (a === "addr") { const r = newArea(); d.rows.push(r); return { focus: `cl-${r.id}-area` }; }
      if (a === "rmr") { const r = d.rows.find((x) => x.id === id); if (!confirm(W(`حذف «${(r && r.area) || "—"}»؟`, `Remove "${(r && r.area) || "—"}"?`))) return false; d.rows = d.rows.filter((x) => x.id !== id); return undefined; }
      return false;
    },
    validate: (d) => {
      let ok = setErr($("#cl-title"), d.title.trim() ? "" : t("required"));
      ok = setErr($("#cl-weekOf"), d.weekOf ? "" : t("required")) && ok;
      const needShift = d.rows.some((r) => r.freq === "shift");
      ok = setErr($("#cl-shifts"), needShift && !has(d.shifts) ? t("required") : has(d.shifts) && !(Number.isInteger(+d.shifts) && +d.shifts >= 1 && +d.shifts <= 6) ? W("عدد صحيح من 1 إلى 6.", "Whole number from 1 to 6.") : "") && ok;
      const re = $("#cl-rows-e"); if (re) re.textContent = d.rows.length ? "" : W("أضف منطقة واحدة على الأقل.", "Add at least one area.");
      if (!d.rows.length) ok = false;
      d.rows.forEach((r) => {
        const e = (k, msg) => (ok = setErr($(`#cl-${r.id}-${k}`), msg) && ok);
        ["area", "resp", "freq"].forEach((k) => e(k, String(r[k] || "").trim() ? "" : t("required")));
        const chem = r.chem.trim();
        e("dose", chem && !r.dose.trim() ? W("مطلوب عند ذكر مادة كيميائية — انقله من الملصق.", "Required when a chemical is named — copy it from the label.") : "");
        e("contact", chem && !r.contact.trim() ? W("مطلوب عند ذكر مادة كيميائية — انقله من الملصق.", "Required when a chemical is named — copy it from the label.") : "");
        e("chem", !chem && (r.dose.trim() || r.contact.trim()) ? W("اذكر اسم المادة كما في الملصق.", "Name the chemical as on its label.") : "");
        if (r.freq === "monthly") e("dom", has(r.dom) && !(Number.isInteger(+r.dom) && +r.dom >= 1 && +r.dom <= 28) ? W("عدد صحيح من 1 إلى 28.", "Whole number from 1 to 28.") : "");
        ok = setErr($(`#cl-${r.id}-v-visual`), VERIF.some(([k]) => r.ver[k]) ? "" : W("اختر طريقة واحدة على الأقل.", "Choose at least one method."), `cl-${r.id}-ver-e`) && ok;
      });
      return ok;
    },
    cols: [[{ ar: "المنشأة / القسم", en: "Site / department" }, (r) => esc(r.title)], [{ ar: "الأسبوع", en: "Week" }, (r) => esc(fmtDate(r.weekOf))], [{ ar: "المناطق", en: "Areas" }, (r) => r.rows.length]],
    report: (d) => LAND + kvTable([[W("المنشأة / القسم", "Site / department"), esc(d.title)], [W("بداية الأسبوع", "Week starting"), esc(fmtDate(d.weekOf))]]) +
      `<h3>${esc(W("خطة التنظيف والتطهير", "Cleaning & sanitation plan"))}</h3><table class="t" style="min-width:0"><tr><th>${esc(W("المنطقة / المعدة", "Area / equipment"))}</th><th>${esc(W("خطوات الطريقة", "Method steps"))}</th><th>${esc(W("المادة (كما في الملصق)", "Chemical (as on label)"))}</th><th>${esc(W("الجرعة — حسب الملصق", "Dose — as per label"))}</th><th>${esc(W("زمن التلامس", "Contact time"))}</th><th>${esc(W("التكرار", "Frequency"))}</th><th>${esc(W("المسؤول", "Responsible"))}</th><th>${esc(W("التحقق", "Verification"))}</th></tr>${d.rows.map((r) => `<tr><td>${esc(r.area)}</td><td>${r.steps.split("\n").filter((x) => x.trim()).map((x, i) => `${i + 1}. ${esc(x.trim())}`).join("<br>")}</td><td>${esc(r.chem)}</td><td>${esc(r.dose)}</td><td>${esc(r.contact)}</td><td>${esc(labOf(CFREQ, r.freq))}</td><td>${esc(r.resp)}</td><td>${esc(verLab(r))}</td></tr>`).join("")}</table>` +
      `<h3 style="break-before:page">${esc(W("الجدول الأسبوعي", "Weekly schedule"))}</h3>${clSched(d)}` + sigTable([W("أعدّه", "Prepared by"), W("مشرف القسم", "Area supervisor"), W("مراقبة الجودة", "QC")]),
    csv: (d) => [[W("المنطقة / المعدة", "Area / equipment"), W("خطوات الطريقة", "Method steps"), W("المادة (كما في الملصق)", "Chemical (as on label)"), W("الجرعة — حسب الملصق", "Dose — as per label"), W("زمن التلامس", "Contact time"), W("التكرار", "Frequency"), W("المسؤول", "Responsible"), W("التحقق", "Verification")], ...d.rows.map((r) => [r.area, r.steps.split("\n").filter((x) => x.trim()).join(" → "), r.chem, r.dose, r.contact, labOf(CFREQ, r.freq), r.resp, verLab(r)])],
  });

  /* ---------- register (appended to the toolkit list) ---------- */
  T.register({ id: "allergens", icon: "leaf", t: { ar: "مصفوفة مسببات الحساسية", en: "Allergen matrix" }, d: { ar: "شبكة المنتج × مسبب الحساسية (يحتوي / قد يحتوي / خالٍ) مع تنبيهات المراجعة وتغيّر المورد، ونسخ محفوظة وطباعة وCSV.", en: "Product × allergen grid (contains / may contain / free) with review and supplier-change flags, saved versions, print and CSV." } }, allergensPage);
  T.register({ id: "recall", icon: "truck", t: { ar: "تمرين الاستدعاء التجريبي", en: "Mock recall exercise" }, d: { ar: "مؤقت من لحظة الإشعار، حصر الكميات لكل عميل، نسبة الكمية المحصورة والنتيجة مقابل أهدافك، وخطوة للخلف لدفعات المواد الخام.", en: "Timer from notification, per-customer reconciliation, % accounted for and pass/fail against your targets, plus one step back to raw material lots." } }, recallPage);
  T.register({ id: "sampling", icon: "flask", t: { ar: "مولّد خطة أخذ العينات", en: "Sampling plan builder" }, d: { ar: "نقاط العينات والفحوص والتكرار والمختبر والمسؤول، مع تقويم 4 أسابيع أو 3 أشهر وحقول ICMSF اختيارية.", en: "Sampling points, tests, frequency, lab and owner, with a 4-week or 3-month calendar and optional ICMSF fields." } }, samplingPage);
  T.register({ id: "receiving", icon: "check", t: { ar: "فحص استلام البضائع", en: "Goods receiving inspection" }, d: { ar: "الحرارة مقابل نطاقك، الصلاحية، المركبة، التعبئة، الملصق، الشهادات والآفات، مع تنبيه رفض تلقائي ونسبة القبول لكل مورد.", en: "Temperature against your range, expiry, vehicle, packaging, label, certificates and pests, with an automatic reject warning and acceptance rate by supplier." } }, receiving.page);
  T.register({ id: "suppliers", icon: "star", t: { ar: "مصفوفة تقييم الموردين", en: "Supplier evaluation matrix" }, d: { ar: "أوزان قابلة للتعديل (مجموعها 100)، درجات 1–5، نتيجة موزونة وتصنيف A/B/C معلن، مع ترتيب وطباعة.", en: "Editable weights (total 100), 1–5 scores, weighted score and declared A/B/C rating, with ranking and print." } }, suppliersPage);
  T.register({ id: "cleaning", icon: "hands", t: { ar: "مولّد خطة التنظيف والتطهير", en: "Cleaning & sanitation plan builder" }, d: { ar: "المناطق والخطوات والمادة والجرعة كما في الملصق والتكرار والتحقق، مع جدول أسبوعي قابل للطباعة وخانات توقيع.", en: "Areas, steps, chemical and label dose, frequency and verification, with a printable weekly schedule and sign-off boxes." } }, cleaningPage);
})();
