/* Five more toolkit tools: cooling tracker, recipe nutrition calculator, food label checker,
   quality meeting minutes and branch visit planner. They plug into js/tools.js through
   TOOLS.register and share its helpers (TOOLS.h). Every limit, nutrient value and policy is
   entered by the user; nothing here proposes a legal criterion. Data stays in localStorage. */
(function () {
  "use strict";
  const T = window.TOOLS, A = window.APP, I = window.ICONS;
  const { printHtml, disclaimer, crumbsFor, kvTable, today, readImage, store, esc, L, t, $, $$, toast, uid, fmtDate, pageHead } = T.h;
  const W = (a, e) => (A.lang === "ar" ? a : e);
  const num = (n, d) => (n == null || n === "" || !isFinite(n) ? "—" : Number(n).toLocaleString(A.lang === "ar" ? "ar-SA-u-nu-latn" : "en-GB", { maximumFractionDigits: d == null ? 1 : d }));
  const isNum = (v) => v !== "" && v != null && isFinite(v);
  const pad = (n) => String(n).padStart(2, "0");
  const tool = (id) => T.list.find((x) => x.id === id);
  const head = (id) => `${pageHead(L(tool(id).t), L(tool(id).d), crumbsFor(tool(id)))}<section class="sec"><div class="wrap tc-page">${disclaimer()}`;
  const nl2br = (s) => esc(s || "").replace(/\n/g, "<br>");

  /* ---------- small shared helpers ---------- */
  const fld = (id, label, input, o) => { o = o || {}; return `<div class="field ${o.full ? "full" : ""}"><label for="${id}" class="${o.req ? "req" : ""}">${esc(label)}</label>${input}${o.hint ? `<span class="hint">${esc(o.hint)}</span>` : ""}<span class="err" id="${id}-e"></span></div>`; };
  const inp = (id, type, v, extra) => `<input id="${id}" type="${type}" value="${esc(v == null ? "" : v)}" ${type === "number" ? 'inputmode="decimal" step="any"' : ""} ${extra || ""}>`;
  const val = (id) => { const el = $("#" + id); return el ? el.value.trim() : ""; };
  const nval = (id) => { const v = val(id); return v === "" ? "" : Number(v); };
  const setErr = (id, msg) => { const el = $("#" + id), e = $("#" + id + "-e"); if (el) el.setAttribute("aria-invalid", msg ? "true" : "false"); if (e) e.textContent = msg || ""; return !msg; };
  const focusBad = (root) => { const b = $("[aria-invalid=true]", root); if (b) b.focus(); };
  const iconBtn = (data, id, icon, label) => `<button type="button" class="icon-btn" data-${data}="${esc(id)}" aria-label="${esc(label)}" style="width:34px;height:34px">${icon}</button>`;
  const selOpts = (opts, cur) => opts.map(([v, l]) => `<option value="${esc(v)}" ${String(cur) === String(v) ? "selected" : ""}>${esc(l)}</option>`).join("");

  /* editable rows (readings, ingredients, attendees, actions…) */
  function grid(host, arr, cols, o) {
    const cell = (c, r, i) => {
      const id = `${o.id}-${i}-${c.k}`, lab = `${c.l} ${i + 1}`, v = r[c.k] == null ? "" : r[c.k];
      if (c.type === "select") return `<select id="${id}" data-c="${i}:${c.k}" aria-label="${esc(lab)}">${selOpts(c.opts(), v)}</select>`;
      if (c.type === "textarea") return `<textarea id="${id}" data-c="${i}:${c.k}" aria-label="${esc(lab)}" rows="2" placeholder="${esc(c.ph || "")}" style="min-height:44px">${esc(v)}</textarea>`;
      return `<input id="${id}" data-c="${i}:${c.k}" aria-label="${esc(lab)}" type="${c.type || "text"}" value="${esc(v)}" placeholder="${esc(c.ph || "")}" ${c.type === "number" ? 'inputmode="decimal" step="any"' : ""} ${c.w ? `style="min-width:${c.w}px"` : ""}>`;
    };
    const draw = () => {
      host.innerHTML = `<div class="table-wrap"><table class="t tc-grid" style="min-width:${o.minW || 0}px"><thead><tr><th>#</th>${cols.map((c) => `<th>${esc(c.l)}${c.unit ? ` <small dir="ltr">(${esc(c.unit)})</small>` : ""}</th>`).join("")}<th><span class="sr-only">${esc(t("del"))}</span></th></tr></thead><tbody>${arr.map((r, i) => `<tr><td class="tc-n">${i + 1}</td>${cols.map((c) => `<td>${cell(c, r, i)}</td>`).join("")}<td>${iconBtn("rm", i, I.trash, `${t("del")} ${i + 1}`)}</td></tr>`).join("")}</tbody></table></div>${!o.max || arr.length < o.max ? `<button type="button" class="btn btn-ghost btn-sm" data-add style="margin-top:8px">${I.plus}<span>${esc(o.addLabel)}</span></button>` : ""}`;
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

  /* saved-records table with edit / print / delete */
  function recList(host, key, cols, h) {
    const draw = () => {
      const all = store.get(key, []);
      host.innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr>${cols.map((c) => `<th>${esc(c[0])}</th>`).join("")}<th><span class="sr-only">${esc(W("إجراءات", "Actions"))}</span></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr>${cols.map((c) => `<td>${c[1](r)}</td>`).join("")}<td style="white-space:nowrap">${iconBtn("ed", r.id, I.note, t("edit"))} ${iconBtn("pr", r.id, I.printer, t("print"))} ${iconBtn("del", r.id, I.trash, t("del"))}</td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`;
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
  const recHead = (key) => `<div class="row" style="margin:34px 0 12px"><h2 style="font-size:22px;margin:0">${esc(t("records"))} <span class="chip" id="${key.replace(":", "-")}-n"></span></h2></div><div id="${key.replace(":", "-")}-list"></div>`;
  const formBtns = (pre) => `<div class="row" style="margin-top:18px"><button class="btn btn-gold" type="submit">${I.check}<span>${esc(W("احسب واحفظ", "Calculate & save"))}</span></button><button type="button" class="btn btn-ghost" id="${pre}Calc">${I.calc}<span>${esc(W("احسب فقط", "Calculate only"))}</span></button><button type="button" class="btn btn-ghost" id="${pre}Print">${I.printer}<span>${esc(t("print"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="${pre}New">${I.plus}<span>${esc(t("newRec"))}</span></button><span class="err" id="${pre}Err" role="alert"></span></div>`;
  const editTitle = (pre, txt) => { const el = $("#" + pre + "Title"); if (el) el.textContent = txt; };

  /* hover / focus tooltips for chart points (uses .ktip from tools-extra.css) */
  function bindTips(host, tipEl) {
    const show = (el, ev) => { tipEl.innerHTML = `<b>${esc(el.dataset.tipv)}</b><span>${esc(el.dataset.tip)}</span>`; tipEl.hidden = false; const b = el.getBoundingClientRect(); const x = ev && ev.clientX != null ? ev.clientX : b.left + b.width / 2, y = ev && ev.clientY != null ? ev.clientY : b.top; tipEl.style.left = Math.min(window.innerWidth - 190, Math.max(8, x + 12)) + "px"; tipEl.style.top = y - 52 + "px"; };
    host.addEventListener("pointermove", (e) => { const el = e.target.closest("[data-tip]"); if (el) show(el, e); else tipEl.hidden = true; });
    host.addEventListener("pointerleave", () => (tipEl.hidden = true));
    host.addEventListener("focusin", (e) => { const el = e.target.closest("[data-tip]"); if (el) show(el); });
    host.addEventListener("focusout", () => (tipEl.hidden = true));
  }

  /* =====================================================================
     1) Cooling after cooking tracker
     ===================================================================== */
  const hm = (s) => { const m = /^(\d{1,2}):(\d{2})/.exec(s || ""); return m ? +m[1] * 60 + +m[2] : null; };
  const dur = (m) => { const r = Math.round(m); return `${Math.floor(r / 60)}:${pad(r % 60)}`; };
  // readings (HH:MM in entry order) → minutes from start; a time earlier than the previous one is the next day
  function coolPoints(startTime, startTemp, readings) {
    const s = hm(startTime); let prev = s; const pts = [{ m: 0, T: +startTemp, time: startTime }];
    for (const r of readings) { let a = hm(r.time); if (a == null) return { error: "time" }; while (a < prev) a += 1440; if (a === prev) return { error: "dup" }; pts.push({ m: a - s, T: +r.temp, time: r.time }); prev = a; }
    return { pts };
  }
  // first time (minutes from start) the core temperature is at or below X, by linear interpolation
  function reach(pts, X) {
    if (pts[0].T <= X) return 0;
    for (let i = 1; i < pts.length; i++) { const a = pts[i - 1], b = pts[i]; if (a.T > X && b.T <= X) return a.m + ((a.T - X) * (b.m - a.m)) / (a.T - b.T); }
    return null;
  }
  function coolCalc(pts, stages) {
    const lastM = pts[pts.length - 1].m;
    const res = stages.map((s) => {
      const t0 = s.clock === "start" ? 0 : reach(pts, +s.from), t1 = reach(pts, +s.to), lim = +s.hrs * 60;
      let status, used = null;
      if (t1 != null && t0 != null) { used = t1 - t0; status = used <= lim + 1e-9 ? "pass" : "fail"; }
      else { const since = t0 == null ? null : lastM - t0; status = since != null && since > lim ? "fail" : "open"; }
      return { ...s, t0, t1, used, lim, status };
    });
    const overall = res.some((r) => r.status === "fail") ? "fail" : res.every((r) => r.status === "pass") ? "pass" : "open";
    return { stages: res, overall };
  }
  const ST = { pass: ["مطابق", "Pass", "ok"], fail: ["غير مطابق", "Fail", "bad"], open: ["غير مكتمل — أضف قراءات", "Incomplete — add readings", "warn"] };
  const stChip = (s) => `<span class="chip ${ST[s][2]}">${esc(W(ST[s][0], ST[s][1]))}</span>`;
  function coolChart(pts, res) {
    const Wd = 640, H = 260, pl = 44, pr = 16, pt = 14, pb = 36;
    const temps = pts.map((p) => p.T).concat(res.stages.flatMap((s) => [+s.from, +s.to]));
    const lo = Math.floor((Math.min(...temps) - 3) / 10) * 10, hi = Math.ceil((Math.max(...temps) + 3) / 10) * 10;
    const maxM = Math.max(pts[pts.length - 1].m, ...res.stages.map((s) => (s.t0 || 0) + s.lim).filter(isFinite), 60);
    const x = (m) => pl + (m / maxM) * (Wd - pl - pr), y = (v) => pt + (1 - (v - lo) / (hi - lo)) * (H - pt - pb);
    const yt = []; const ys = hi - lo > 60 ? 20 : 10; for (let v = lo; v <= hi; v += ys) yt.push(v);
    const xs = maxM > 720 ? 120 : maxM > 360 ? 60 : 30, xt = []; for (let m = 0; m <= maxM; m += xs) xt.push(m);
    const cols = ["#53b9ad", "#e6c24a", "#c58af0"];
    return `<svg class="kchart" viewBox="0 0 ${Wd} ${H}" role="img" aria-label="${esc(W("منحنى درجة الحرارة مقابل الزمن", "Temperature vs time curve"))}">
      ${yt.map((v) => `<line x1="${pl}" x2="${Wd - pr}" y1="${y(v)}" y2="${y(v)}" class="grid-l"/><text x="${pl - 8}" y="${y(v) + 4}" class="ax" text-anchor="end">${v}°</text>`).join("")}
      ${xt.map((m) => `<text x="${x(m)}" y="${H - 14}" class="ax" text-anchor="middle">${dur(m)}</text>`).join("")}
      <text x="${Wd - pr}" y="${H - 1}" class="ax" text-anchor="end">h:mm</text>
      ${res.stages.map((s, i) => `<line x1="${pl}" x2="${Wd - pr}" y1="${y(+s.to)}" y2="${y(+s.to)}" stroke="${cols[i]}" stroke-dasharray="6 5" stroke-width="1.5"/><text x="${Wd - pr - 4}" y="${y(+s.to) - 5}" class="ax" text-anchor="end" style="fill:${cols[i]}">S${i + 1}: ${num(+s.to)}° ≤ ${num(+s.hrs, 2)} h</text>${s.t0 != null && isFinite(s.lim) ? `<line x1="${x(s.t0 + s.lim)}" x2="${x(s.t0 + s.lim)}" y1="${pt}" y2="${H - pb}" stroke="${cols[i]}" stroke-dasharray="2 4" stroke-width="1.2"/>` : ""}${s.t1 != null ? `<circle cx="${x(s.t1)}" cy="${y(+s.to)}" r="5" fill="none" stroke="${cols[i]}" stroke-width="2"/>` : ""}`).join("")}
      <polyline points="${pts.map((p) => `${x(p.m)},${y(p.T)}`).join(" ")}" class="ln"/>
      ${pts.map((p) => `<circle cx="${x(p.m)}" cy="${y(p.T)}" r="4" class="pt"/><circle cx="${x(p.m)}" cy="${y(p.T)}" r="14" class="hit" tabindex="0" data-tip="${esc(`${p.time} · +${dur(p.m)} h`)}" data-tipv="${esc(num(p.T) + " °C")}"/>`).join("")}
    </svg>`;
  }
  function coolingPage() {
    const RK = "tool:cooling";
    const stages = [], readings = [];
    let editing = null;
    const blankS = () => ({ from: "", to: "", hrs: "", clock: "reach" }), blankR = () => ({ time: "", temp: "" });
    const html = `${head("cooling")}
      <form class="card" id="coForm" novalidate style="margin-top:18px"><h2 style="font-size:20px" id="coTitle">${esc(t("newRec"))}</h2>
        <div class="form">
          ${fld("co-prod", W("المنتج", "Product"), inp("co-prod", "text"), { req: true })}
          ${fld("co-batch", W("رقم الدفعة / التشغيلة", "Batch / lot no."), inp("co-batch", "text"))}
          ${fld("co-cont", W("نوع الوعاء وعمق المنتج", "Container type & product depth"), inp("co-cont", "text", "", `placeholder="${esc(W("مثال: صينية ستانلس، عمق 5 سم، مكشوفة", "e.g. stainless tray, 5 cm deep, uncovered"))}"`))}
          ${fld("co-meth", W("طريقة التبريد", "Cooling method"), inp("co-meth", "text", "", `placeholder="${esc(W("مثال: مبرد سريع، حمام ثلج", "e.g. blast chiller, ice bath"))}"`))}
          ${fld("co-date", W("تاريخ بدء التبريد", "Cooling start date"), inp("co-date", "date", today()), { req: true })}
          ${fld("co-time", W("وقت بدء التبريد", "Cooling start time"), inp("co-time", "time"), { req: true })}
          ${fld("co-temp", W("درجة الحرارة الداخلية عند البدء (°م)", "Core temperature at start (°C)"), inp("co-temp", "number"), { req: true })}
          ${fld("co-by", W("القائم بالقياس", "Measured by"), inp("co-by", "text"))}
          <div class="full"><span class="lbl req">${esc(W("مراحل التبريد (من إجراءاتك المعتمدة)", "Cooling stages (from your approved procedure)"))}</span>
            <p class="note" style="margin:4px 0 8px">${esc(W("أدخل حدود كل مرحلة كما وردت في اللائحة أو الإجراء المطبَّق لديك؛ لا توجد قيم افتراضية. حتى 3 مراحل.", "Enter each stage's limits exactly as given in the regulation or procedure that applies to you; there are no defaults. Up to 3 stages."))}</p>
            <div id="coStages"></div><span class="err" id="coStages-e"></span></div>
          <div class="full"><span class="lbl req">${esc(W("قراءات درجة الحرارة الداخلية", "Core temperature readings"))}</span>
            <p class="note" style="margin:4px 0 8px">${esc(W("بالترتيب الزمني. الوقت الأقدم من القراءة السابقة يُحتسب في اليوم التالي (بعد منتصف الليل).", "In time order. A time earlier than the previous reading is counted as the next day (after midnight)."))}</p>
            <div id="coReads"></div><span class="err" id="coReads-e"></span></div>
          ${fld("co-ca", W("الإجراء التصحيحي (عند عدم المطابقة)", "Corrective action (if not met)"), `<textarea id="co-ca" rows="2"></textarea>`, { full: true })}
        </div>${formBtns("co")}</form>
      <div class="card" id="coRes" aria-live="polite" style="margin-top:18px"><h3>${esc(W("النتيجة", "Result"))}</h3><p class="note" style="margin:0">${esc(W("أدخل المراحل والقراءات ثم اضغط احسب.", "Enter the stages and readings, then press calculate."))}</p></div>
      <div class="card" style="margin-top:18px"><h3>${esc(W("طريقة الحساب", "How it's calculated"))}</h3>
        <p dir="ltr" style="font-family:var(--font-en);text-align:start;color:var(--text);font-size:15.5px">t(X) = tₐ + (Tₐ − X) × (t_b − tₐ) ÷ (Tₐ − T_b)</p>
        <ul class="ticks"><li>${esc(W("يُحسب وقت الوصول إلى درجة X بالاستكمال الخطي بين القراءتين اللتين تعبرها الحرارة بينهما (Tₐ > X ≥ T_b).", "The time temperature X is reached is linearly interpolated between the two readings it falls between (Tₐ > X ≥ T_b)."))}</li>
          <li>${esc(W("زمن المرحلة = وقت الوصول إلى «إلى» − بداية الساعة. تبدأ الساعة عند الوصول إلى درجة «من» (أو من أول قراءة إذا كانت أقل منها)، أو من بدء التبريد حسب اختيارك لكل مرحلة.", "Stage time = time \"to\" is reached − clock start. The clock starts when \"from\" is reached (or at the first reading if already below it), or at the start of cooling — your choice per stage."))}</li>
          <li>${esc(W("المرحلة مطابقة إذا كان زمنها ≤ الحد. إذا لم تصل الحرارة بعد وتجاوز الزمن الحد فهي غير مطابقة، وإلا فهي غير مكتملة.", "A stage passes if its time ≤ the limit. If the target isn't reached yet and the limit has passed it fails; otherwise it is incomplete."))}</li></ul></div>
      ${recHead(RK)}<div class="ktip" id="coTip" role="status" aria-live="polite" hidden></div></div></section>`;
    function after() {
      const sg = grid($("#coStages"), stages, [
        { k: "from", l: W("من (°م)", "From (°C)"), type: "number", ph: W("من إجراءك", "per your procedure"), w: 90 },
        { k: "to", l: W("إلى (°م)", "To (°C)"), type: "number", ph: W("من إجراءك", "per your procedure"), w: 90 },
        { k: "hrs", l: W("خلال (ساعة)", "Within (h)"), type: "number", ph: W("من إجراءك", "per your procedure"), w: 90 },
        { k: "clock", l: W("بداية الساعة", "Clock starts"), type: "select", opts: () => [["reach", W("عند الوصول إلى «من»", "When \"from\" is reached")], ["start", W("عند بدء التبريد", "At start of cooling")]] },
      ], { id: "cs", min: 1, max: 3, minW: 520, blank: blankS, addLabel: W("أضف مرحلة", "Add stage") });
      const rg = grid($("#coReads"), readings, [
        { k: "time", l: W("الوقت", "Time"), type: "time", w: 110 },
        { k: "temp", l: W("الحرارة الداخلية (°م)", "Core temp (°C)"), type: "number", w: 90 },
      ], { id: "cr", min: 1, minW: 0, blank: blankR, addLabel: W("أضف قراءة", "Add reading") });
      const reset = (r) => {
        editing = r ? r.id : null; r = r || {};
        [["prod", "prod"], ["batch", "batch"], ["cont", "cont"], ["meth", "meth"], ["time", "time"], ["temp", "startT"], ["by", "by"], ["ca", "ca"]].forEach(([id, k]) => ($("#co-" + id).value = r[k] == null ? "" : r[k]));
        $("#co-date").value = r.date || today();
        sg.set(r.stages && r.stages.length ? r.stages : [blankS()]); rg.set(r.readings && r.readings.length ? r.readings : [blankR(), blankR()]);
        editTitle("co", r.id ? `${t("edit")} — ${r.prod}` : t("newRec"));
        $$("[aria-invalid]", $("#coForm")).forEach((el) => el.setAttribute("aria-invalid", "false")); $$(".err", $("#coForm")).forEach((e) => (e.textContent = ""));
      };
      const read = () => ({ prod: val("co-prod"), batch: val("co-batch"), cont: val("co-cont"), meth: val("co-meth"), date: val("co-date"), time: val("co-time"), startT: nval("co-temp"), by: val("co-by"), ca: val("co-ca"), stages: stages.map((s) => ({ ...s })), readings: readings.map((r) => ({ ...r })) });
      const validate = (r) => {
        let ok = true;
        ok = setErr("co-prod", r.prod ? "" : t("required")) && ok;
        ok = setErr("co-date", r.date ? "" : t("required")) && ok;
        ok = setErr("co-time", r.time ? "" : t("required")) && ok;
        ok = setErr("co-temp", isNum(r.startT) ? "" : t("required")) && ok;
        let sMsg = "";
        r.stages.forEach((s, i) => {
          ["from", "to", "hrs"].forEach((k) => { const bad = !isNum(s[k]) || (k === "hrs" && !(s[k] > 0)); sg.mark(i, k, bad); if (bad) sMsg = W(`أكمل حدود المرحلة ${i + 1} (الحد الزمني أكبر من صفر).`, `Complete the limits of stage ${i + 1} (time limit above zero).`); });
          if (!sMsg && +s.to >= +s.from) { sg.mark(i, "to", true); sMsg = W(`في المرحلة ${i + 1} يجب أن تكون درجة «إلى» أقل من «من».`, `In stage ${i + 1} "to" must be lower than "from".`); }
        });
        $("#coStages-e").textContent = sMsg; if (sMsg) ok = false;
        let rMsg = "";
        r.readings.forEach((x, i) => { const bt = !x.time, bv = !isNum(x.temp); rg.mark(i, "time", bt); rg.mark(i, "temp", bv); if (bt || bv) rMsg = W(`أكمل الوقت والحرارة في القراءة ${i + 1}.`, `Enter the time and temperature for reading ${i + 1}.`); });
        if (!rMsg && r.time) { const p = coolPoints(r.time, r.startT, r.readings); if (p.error === "dup") rMsg = W("يوجد وقتان متطابقان متتاليان في القراءات.", "Two consecutive readings have the same time."); }
        $("#coReads-e").textContent = rMsg; if (rMsg) ok = false;
        $("#coErr").textContent = ok ? "" : t("fixErrors");
        if (!ok) focusBad($("#coForm"));
        return ok;
      };
      const resultHtml = (r) => {
        const { pts } = coolPoints(r.time, r.startT, r.readings), res = coolCalc(pts, r.stages), s0 = hm(r.time);
        const clock = (m) => { const tot = s0 + Math.round(m), d = Math.floor(tot / 1440); return `${pad(Math.floor((tot % 1440) / 60))}:${pad(tot % 60)}${d ? ` (+${d} ${W("يوم", "d")})` : ""}`; };
        r.result = { overall: res.overall, stages: res.stages.map((s) => ({ status: s.status, used: s.used })) };
        const table = `<div class="table-wrap"><table class="t" style="min-width:520px"><thead><tr><th>${esc(W("المرحلة", "Stage"))}</th><th>${esc(W("الهدف", "Target"))}</th><th>${esc(W("بداية الساعة", "Clock start"))}</th><th>${esc(W("الوصول إلى «إلى»", "\"To\" reached"))}</th><th>${esc(W("الزمن المستغرق", "Time taken"))}</th><th>${esc(W("النتيجة", "Result"))}</th></tr></thead><tbody>${res.stages.map((s, i) => `<tr><td>${i + 1}</td><td dir="ltr" style="text-align:start">${num(+s.from)} → ${num(+s.to)} °C ≤ ${num(+s.hrs, 2)} h</td><td>${s.t0 == null ? "—" : `<span dir="ltr">${clock(s.t0)} <small class="note">(+${dur(s.t0)})</small></span>`}</td><td>${s.t1 == null ? esc(W("لم تصل بعد", "Not reached")) : `<span dir="ltr">${clock(s.t1)} <small class="note">(+${dur(s.t1)})</small></span>`}</td><td dir="ltr" style="text-align:start">${s.used == null ? "—" : `${dur(s.used)} h`}</td><td>${stChip(s.status)}</td></tr>`).join("")}</tbody></table></div>`;
        return { res, html: `<div class="row"><h3 style="margin:0">${esc(W("النتيجة", "Result"))}</h3><span class="spacer"></span>${stChip(res.overall)}</div><div style="margin:12px auto;max-width:760px">${coolChart(pts, res)}</div>${table}<p class="note">${esc(W("الخطوط المتقطعة: درجة «إلى» لكل مرحلة؛ الخطوط العمودية المنقطة: نهاية المهلة الزمنية للمرحلة؛ الدائرة: لحظة الوصول.", "Dashed lines: each stage's \"to\" temperature; dotted verticals: end of the stage's time limit; ring: the moment it was reached."))}</p>` };
      };
      const compute = () => { const r = read(); if (!validate(r)) return null; const out = resultHtml(r); $("#coRes").innerHTML = out.html; return r; };
      const printRec = (r) => { const out = resultHtml(r); printHtml(`${L(tool("cooling").t)} — ${r.prod}`, kvTable([[W("المنتج", "Product"), esc(r.prod)], [W("الدفعة", "Batch"), esc(r.batch)], [W("الوعاء والعمق", "Container & depth"), esc(r.cont)], [W("الطريقة", "Method"), esc(r.meth)], [W("البدء", "Start"), `${esc(fmtDate(r.date))} ${esc(r.time)} — ${num(r.startT)} °C`], [W("القراءات", "Readings"), r.readings.map((x) => `${esc(x.time)}: ${num(x.temp)} °C`).join(" · ")], [W("القائم بالقياس", "Measured by"), esc(r.by)], [W("الإجراء التصحيحي", "Corrective action"), nl2br(r.ca)]]) + out.html.replace('class="kchart"', 'class="kchart" style="max-width:640px"') + `<table class="t" style="min-width:0;margin-top:22px"><tr><th>${esc(W("القائم بالقياس", "Measured by"))}</th><th>${esc(W("المراجِع / المشرف", "Reviewed by / supervisor"))}</th></tr><tr><td style="height:48px"></td><td></td></tr></table>`); };
      const draw = recList($("#tool-cooling-list"), RK, [
        [W("التاريخ", "Date"), (r) => `${esc(fmtDate(r.date))} ${esc(r.time)}`], [W("المنتج", "Product"), (r) => esc(r.prod)], [W("الدفعة", "Batch"), (r) => esc(r.batch || "—")],
        [W("المراحل", "Stages"), (r) => (r.result ? r.result.stages.map((s, i) => `S${i + 1} ${stChip(s.status)}`).join(" ") : "")], [W("النتيجة", "Result"), (r) => (r.result ? stChip(r.result.overall) : "")],
      ], { edit: (r) => { reset(r); compute(); A.scrollTo($("#coForm"), true); }, print: printRec, deleted: (id) => { if (editing === id) reset(null); } });
      $("#coCalc").addEventListener("click", compute);
      $("#coPrint").addEventListener("click", () => { const r = compute(); if (r) printRec(r); });
      $("#coNew").addEventListener("click", () => { reset(null); $("#coRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3>`; });
      $("#coForm").addEventListener("submit", (e) => { e.preventDefault(); const r = compute(); if (!r) return; if (saveRec(RK, r, editing)) { toast(t("saved")); editing = r.id; editTitle("co", `${t("edit")} — ${r.prod}`); draw(); } });
      bindTips($("#coRes"), $("#coTip"));
      reset(null);
    }
    return { title: L(tool("cooling").t), html, after };
  }

  /* =====================================================================
     2) Recipe nutrition calculator
     ===================================================================== */
  const NUT = [["kcal", "الطاقة", "Energy", "kcal", 0], ["protein", "البروتين", "Protein", "g", 1], ["fat", "الدهون الكلية", "Total fat", "g", 1], ["sat", "الدهون المشبعة", "Saturated fat", "g", 1], ["carb", "الكربوهيدرات", "Carbohydrate", "g", 1], ["sugars", "السكريات", "Sugars", "g", 1], ["fibre", "الألياف الغذائية", "Dietary fibre", "g", 1], ["sodium", "الصوديوم", "Sodium", "mg", 0]];
  // c: { ing: [{ w, kcal, protein, … } per 100 g], yieldW, mode: "n" | "size", n, size }
  function nutCalc(c) {
    const raw = c.ing.reduce((s, x) => s + (+x.w || 0), 0), final = c.yieldW > 0 ? +c.yieldW : raw;
    const tot = {}, p100 = {}, ps = {};
    NUT.forEach(([k]) => { tot[k] = c.ing.reduce((s, x) => s + ((+x.w || 0) * (isNum(x[k]) ? +x[k] : 0)) / 100, 0); p100[k] = final > 0 ? (tot[k] / final) * 100 : 0; });
    const servW = c.mode === "size" ? +c.size : final / +c.n, servings = c.mode === "size" ? final / +c.size : +c.n;
    NUT.forEach(([k]) => (ps[k] = (p100[k] * servW) / 100));
    return { raw, final, factor: raw > 0 ? final / raw : 1, tot, p100, ps, servW, servings };
  }
  function nutPanel(r, o) {
    const hasRI = NUT.some(([k]) => r.ri && r.ri[k] > 0);
    const row = ([k, a, e, u, d]) => `<tr class="${k === "sat" || k === "sugars" ? "sub" : ""}"><th scope="row"><span lang="ar">${a}</span> <span class="np-sep">|</span> <span lang="en">${e}</span></th><td dir="ltr">${num(o.p100[k], d)} ${u}${k === "kcal" ? `<br><small>${num(o.p100[k] * 4.184, 0)} kJ</small>` : ""}</td><td dir="ltr">${num(o.ps[k], d)} ${u}${k === "kcal" ? `<br><small>${num(o.ps[k] * 4.184, 0)} kJ</small>` : ""}</td>${hasRI ? `<td dir="ltr">${r.ri && r.ri[k] > 0 ? num((o.ps[k] / r.ri[k]) * 100, 0) + "%" : "—"}</td>` : ""}</tr>`;
    return `<div class="np"><div class="np-h"><b lang="ar">حقائق التغذية</b><b lang="en">Nutrition Facts</b></div>
      <div class="np-s"><div><span><span lang="ar">حجم الحصة</span> | <span lang="en">Serving size</span></span><b dir="ltr">${num(o.servW, 0)} g</b></div><div><span><span lang="ar">عدد الحصص</span> | <span lang="en">Servings</span></span><b dir="ltr">${num(o.servings, 1)}</b></div></div>
      <table><thead><tr><th></th><th><span lang="ar">لكل 100 غ</span><br><span lang="en">Per 100 g</span></th><th><span lang="ar">لكل حصة</span><br><span lang="en">Per serving</span></th>${hasRI ? `<th><span lang="ar">% من المرجع*</span><br><span lang="en" dir="ltr">%RI*</span></th>` : ""}</tr></thead><tbody>${NUT.map(row).join("")}</tbody></table>
      ${hasRI ? `<p class="np-f"><span lang="ar">* النسبة من الكميات المرجعية التي أدخلها المستخدم${r.riRef ? ": " + esc(r.riRef) : ""}.</span><br><span lang="en">* % of the reference intakes entered by the user${r.riRef ? ": " + esc(r.riRef) : ""}.</span></p>` : ""}</div>`;
  }
  function nutritionPage() {
    const RK = "tool:nutrition";
    const ing = []; let editing = null;
    const blank = () => ({ name: "", w: "", kcal: "", protein: "", fat: "", sat: "", carb: "", sugars: "", fibre: "", sodium: "" });
    const html = `${head("nutrition")}
      <form class="card" id="nuForm" novalidate style="margin-top:18px"><h2 style="font-size:20px" id="nuTitle">${esc(t("newRec"))}</h2>
        <div class="form">
          ${fld("nu-name", W("اسم الوصفة / المنتج", "Recipe / product name"), inp("nu-name", "text"), { req: true })}
          ${fld("nu-ref", W("مصدر القيم الغذائية", "Source of nutrient values"), inp("nu-ref", "text", "", `placeholder="${esc(W("مثال: ملصقات الموردين، جدول تركيب الأغذية…", "e.g. supplier labels, food composition table…"))}"`))}
          <div class="full"><span class="lbl req">${esc(W("المكونات (القيم لكل 100 غ من الملصق أو جداول تركيب الأغذية)", "Ingredients (values per 100 g from labels or food composition tables)"))}</span>
            <p class="note" style="margin:4px 0 8px">${esc(W("لا تتضمن الأداة أي قاعدة بيانات أو قيم افتراضية؛ أدخل القيم من مصدر موثوق. الخانة الفارغة تُحسب صفرًا.", "The tool ships no database or default values; enter values from a reliable source. A blank cell counts as zero."))}</p>
            <div id="nuIng"></div><span class="err" id="nuIng-e"></span></div>
          ${fld("nu-yield", W("وزن المنتج بعد الطهي (غ) — اختياري", "Cooked yield weight (g) — optional"), inp("nu-yield", "number", "", 'min="0"'), { hint: W("زن المنتج النهائي لاحتساب فقد الماء. اتركه فارغًا لاستخدام مجموع أوزان المكونات.", "Weigh the finished product to account for water loss. Leave blank to use the sum of ingredient weights.") })}
          <div class="field"><label for="nu-mode">${esc(W("تحديد الحصة", "Serving basis"))}</label><select id="nu-mode"><option value="n">${esc(W("عدد الحصص", "Number of servings"))}</option><option value="size">${esc(W("حجم الحصة (غ)", "Serving size (g)"))}</option></select></div>
          ${fld("nu-sv", W("القيمة", "Value"), inp("nu-sv", "number", "", 'min="0"'), { req: true })}
          <details class="faq full" id="nuRiBox"><summary>${esc(W("الكميات المرجعية للحساب % (اختياري)", "Reference intakes for % (optional)"))}</summary>
            <p class="note" style="margin-top:0">${esc(W("أدخلها فقط من اللائحة المطبقة لديك (مثل لوائح SFDA)؛ اترك الحقول فارغة لإخفاء عمود النسبة.", "Enter them only from the regulation that applies to you (e.g. SFDA); leave blank to hide the % column."))}</p>
            <div class="form" style="padding-bottom:16px">${NUT.map(([k, a, e, u]) => fld("nu-ri-" + k, `${W(a, e)} (${u})`, inp("nu-ri-" + k, "number", "", 'min="0"'))).join("")}${fld("nu-riref", W("مرجع الكميات", "Reference source"), inp("nu-riref", "text"), { full: true })}</div></details>
        </div>${formBtns("nu")}</form>
      <div class="grid g2" style="margin-top:18px;align-items:start"><div class="card" id="nuRes" aria-live="polite"><h3>${esc(W("النتيجة", "Result"))}</h3><p class="note" style="margin:0">${esc(W("أدخل المكونات ثم اضغط احسب.", "Enter the ingredients, then press calculate."))}</p></div>
        <div class="card"><h3>${esc(W("المعادلات", "Formulas"))}</h3><div dir="ltr" style="font-family:var(--font-en);text-align:start;color:var(--text);font-size:14.5px;line-height:1.9">
          Nutrient<sub>recipe</sub> = Σ (wᵢ × vᵢ ÷ 100)<br>W<sub>final</sub> = cooked yield (or Σ wᵢ)<br>Per 100 g = Nutrient<sub>recipe</sub> ÷ W<sub>final</sub> × 100<br>Serving (g) = W<sub>final</sub> ÷ n &nbsp;or&nbsp; entered size<br>Per serving = Per 100 g × serving ÷ 100<br>%RI = Per serving ÷ RI × 100<br>kJ = kcal × 4.184</div>
          <ul class="ticks" style="margin-top:10px"><li>${esc(W("wᵢ وزن المكوّن بالغرام، vᵢ قيمته لكل 100 غ. معامل الناتج = W_final ÷ Σ wᵢ.", "wᵢ is the ingredient weight in g and vᵢ its value per 100 g. Yield factor = W_final ÷ Σ wᵢ."))}</li><li>${esc(W("يفترض الحساب أن فقد الوزن ماء فقط وأن العناصر الغذائية لا تتغير بالطهي؛ للدقة المطلوبة للملصق الرسمي قد يلزم تحليل مخبري.", "It assumes weight loss is water only and nutrients are unchanged by cooking; a formal label may require laboratory analysis."))}</li></ul></div></div>
      ${recHead(RK)}</div></section>`;
    function after() {
      const cols = [{ k: "name", l: W("المكوّن", "Ingredient"), w: 130 }, { k: "w", l: W("الوزن", "Weight"), unit: "g", type: "number", w: 72 }].concat(NUT.map(([k, a, e, u]) => ({ k, l: W(a, e), unit: `${u}/100 g`, type: "number", w: 72 })));
      const g = grid($("#nuIng"), ing, cols, { id: "ni", min: 1, minW: 1100, blank, addLabel: W("أضف مكوّنًا", "Add ingredient") });
      const svLabel = () => { $("label[for=nu-sv]").textContent = $("#nu-mode").value === "size" ? W("حجم الحصة (غ)", "Serving size (g)") : W("عدد الحصص", "Number of servings"); };
      $("#nu-mode").addEventListener("change", svLabel);
      const reset = (r) => {
        editing = r ? r.id : null; r = r || { mode: "n", ri: {} };
        $("#nu-name").value = r.name || ""; $("#nu-ref").value = r.ref || ""; $("#nu-yield").value = r.yieldW == null ? "" : r.yieldW; $("#nu-mode").value = r.mode || "n"; $("#nu-sv").value = r.sv == null ? "" : r.sv; $("#nu-riref").value = r.riRef || "";
        NUT.forEach(([k]) => ($("#nu-ri-" + k).value = r.ri && r.ri[k] != null ? r.ri[k] : ""));
        $("#nuRiBox").open = NUT.some(([k]) => r.ri && isNum(r.ri[k]));
        g.set(r.ing && r.ing.length ? r.ing : [blank(), blank()]); svLabel();
        editTitle("nu", r.id ? `${t("edit")} — ${r.name}` : t("newRec"));
        $$("[aria-invalid]", $("#nuForm")).forEach((el) => el.setAttribute("aria-invalid", "false")); $$(".err", $("#nuForm")).forEach((e) => (e.textContent = ""));
      };
      const read = () => { const ri = {}; NUT.forEach(([k]) => { const v = nval("nu-ri-" + k); if (v !== "") ri[k] = v; }); return { name: val("nu-name"), ref: val("nu-ref"), yieldW: nval("nu-yield"), mode: $("#nu-mode").value, sv: nval("nu-sv"), ri, riRef: val("nu-riref"), ing: ing.map((x) => ({ ...x })) }; };
      const validate = (r) => {
        let ok = setErr("nu-name", r.name ? "" : t("required"));
        ok = setErr("nu-sv", r.sv === "" ? t("required") : !(r.sv > 0) ? W("أدخل رقمًا أكبر من صفر.", "Enter a number above zero.") : "") && ok;
        ok = setErr("nu-yield", r.yieldW !== "" && !(r.yieldW > 0) ? W("أدخل رقمًا أكبر من صفر أو اتركه فارغًا.", "Enter a number above zero or leave blank.") : "") && ok;
        NUT.forEach(([k]) => { ok = setErr("nu-ri-" + k, isNum(r.ri[k]) && !(r.ri[k] > 0) ? W("أكبر من صفر أو فارغ.", "Above zero or blank.") : "") && ok; });
        let msg = "";
        r.ing.forEach((x, i) => {
          const bn = !x.name.trim(), bw = !(x.w > 0); g.mark(i, "name", bn); g.mark(i, "w", bw);
          if (bn || bw) msg = W(`أدخل اسم المكوّن ${i + 1} ووزنه (أكبر من صفر).`, `Enter a name and a weight above zero for ingredient ${i + 1}.`);
          NUT.forEach(([k]) => { const b = isNum(x[k]) && x[k] < 0; g.mark(i, k, b); if (b) msg = W("القيم الغذائية لا تكون سالبة.", "Nutrient values can't be negative."); });
          if (isNum(x.sat) && isNum(x.fat) && +x.sat > +x.fat) { g.mark(i, "sat", true); msg = W(`المكوّن ${i + 1}: الدهون المشبعة أكبر من الدهون الكلية.`, `Ingredient ${i + 1}: saturated fat exceeds total fat.`); }
          if (isNum(x.sugars) && isNum(x.carb) && +x.sugars > +x.carb) { g.mark(i, "sugars", true); msg = W(`المكوّن ${i + 1}: السكريات أكبر من الكربوهيدرات.`, `Ingredient ${i + 1}: sugars exceed carbohydrate.`); }
          ["protein", "fat", "carb", "fibre"].forEach((k) => { if (isNum(x[k]) && +x[k] > 100) { g.mark(i, k, true); msg = W("لا تتجاوز قيمة بالغرام 100 غ لكل 100 غ.", "A gram value can't exceed 100 g per 100 g."); } });
        });
        $("#nuIng-e").textContent = msg; if (msg) ok = false;
        if (ok && r.mode === "size") { const o = nutCalc({ ing: r.ing, yieldW: r.yieldW, mode: "size", size: r.sv }); if (r.sv > o.final) ok = setErr("nu-sv", W("حجم الحصة أكبر من وزن المنتج النهائي.", "Serving size is larger than the final product weight.")); }
        $("#nuErr").textContent = ok ? "" : t("fixErrors"); if (!ok) focusBad($("#nuForm"));
        return ok;
      };
      const calc = (r) => nutCalc({ ing: r.ing, yieldW: r.yieldW, mode: r.mode, n: r.sv, size: r.sv });
      const resultHtml = (r, o) => {
        const hasRI = NUT.some(([k]) => r.ri[k] > 0);
        return `<h3>${esc(W("النتيجة", "Result"))}</h3><div class="row" style="gap:6px;margin-bottom:10px"><span class="chip">${esc(W("مجموع الأوزان", "Ingredients total"))}: <b dir="ltr">${num(o.raw, 1)} g</b></span><span class="chip">${esc(W("الوزن النهائي", "Final weight"))}: <b dir="ltr">${num(o.final, 1)} g</b></span><span class="chip">${esc(W("معامل الناتج", "Yield factor"))}: <b dir="ltr">${num(o.factor, 3)}</b></span></div>
          <div class="table-wrap"><table class="t" style="min-width:460px"><thead><tr><th>${esc(W("العنصر", "Nutrient"))}</th><th>${esc(W("الوصفة كاملة", "Whole recipe"))}</th><th>${esc(W("لكل 100 غ", "Per 100 g"))}</th><th>${esc(W("لكل حصة", "Per serving"))}</th>${hasRI ? `<th>%RI</th>` : ""}</tr></thead><tbody>${NUT.map(([k, a, e, u, d]) => `<tr><td>${esc(W(a, e))}</td><td dir="ltr" style="text-align:start">${num(o.tot[k], d)} ${u}</td><td dir="ltr" style="text-align:start">${num(o.p100[k], d)} ${u}</td><td dir="ltr" style="text-align:start">${num(o.ps[k], d)} ${u}</td>${hasRI ? `<td dir="ltr" style="text-align:start">${r.ri[k] > 0 ? num((o.ps[k] / r.ri[k]) * 100, 0) + "%" : "—"}</td>` : ""}</tr>`).join("")}</tbody></table></div>
          <p class="note" dir="ltr" style="text-align:start">Energy per 100 g = ${num(o.tot.kcal, 1)} kcal ÷ ${num(o.final, 1)} g × 100 = ${num(o.p100.kcal, 1)} kcal</p>
          <div style="margin-top:14px">${nutPanel(r, o)}</div>`;
      };
      const compute = () => { const r = read(); if (!validate(r)) return null; const o = calc(r); r.out = { p100: o.p100, ps: o.ps, servW: o.servW, final: o.final }; $("#nuRes").innerHTML = resultHtml(r, o); return r; };
      const printRec = (r) => { const o = calc(r); printHtml(`${L(tool("nutrition").t)} — ${r.name}`, `<div style="display:flex;gap:20px;flex-wrap:wrap;align-items:flex-start"><div style="flex:0 0 330px">${nutPanel(r, o)}</div><div style="flex:1;min-width:260px">${kvTable([[W("الوصفة", "Recipe"), esc(r.name)], [W("مصدر القيم", "Source of values"), esc(r.ref)], [W("مجموع الأوزان", "Ingredients total"), `${num(o.raw, 1)} g`], [W("الوزن النهائي", "Final weight"), `${num(o.final, 1)} g`], [W("معامل الناتج", "Yield factor"), num(o.factor, 3)]])}</div></div><h3>${esc(W("المكونات", "Ingredients"))}</h3><table class="t" style="min-width:0;font-size:9pt"><tr><th>${esc(W("المكوّن", "Ingredient"))}</th><th>g</th>${NUT.map(([, a, e, u]) => `<th>${esc(W(a, e))} (${u}/100 g)</th>`).join("")}</tr>${r.ing.map((x) => `<tr><td>${esc(x.name)}</td><td>${num(x.w, 1)}</td>${NUT.map(([k]) => `<td>${isNum(x[k]) ? num(x[k], 2) : "—"}</td>`).join("")}</tr>`).join("")}</table><p style="font-size:9pt;margin-top:10px" dir="ltr">Per 100 g = Σ(wᵢ × vᵢ ÷ 100) ÷ W<sub>final</sub> × 100 · Per serving = Per 100 g × serving ÷ 100 · kJ = kcal × 4.184</p>`); };
      const draw = recList($("#tool-nutrition-list"), RK, [
        [W("الوصفة", "Recipe"), (r) => esc(r.name)], [W("المكونات", "Ingredients"), (r) => (r.ing || []).length], [W("الحصة", "Serving"), (r) => (r.out ? `<span dir="ltr">${num(r.out.servW, 0)} g</span>` : "")],
        [W("الطاقة / 100 غ", "Energy / 100 g"), (r) => (r.out ? `<span dir="ltr">${num(r.out.p100.kcal, 0)} kcal</span>` : "")], [W("التاريخ", "Date"), (r) => esc(fmtDate(new Date(r.updated || r.created).toISOString()))],
      ], { edit: (r) => { reset(r); compute(); A.scrollTo($("#nuForm"), true); }, print: printRec, deleted: (id) => { if (editing === id) reset(null); } });
      $("#nuCalc").addEventListener("click", compute);
      $("#nuPrint").addEventListener("click", () => { const r = compute(); if (r) printRec(r); });
      $("#nuNew").addEventListener("click", () => { reset(null); $("#nuRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3>`; });
      $("#nuForm").addEventListener("submit", (e) => { e.preventDefault(); const r = compute(); if (!r) return; if (saveRec(RK, r, editing)) { toast(t("saved")); editing = r.id; editTitle("nu", `${t("edit")} — ${r.name}`); draw(); } });
      reset(null);
    }
    return { title: L(tool("nutrition").t), html, after };
  }

  /* =====================================================================
     3) Food label checker — Codex CXS 1-1985 general labelling elements
     ===================================================================== */
  const LBL = [
    ["name", "اسم الغذاء يبيّن طبيعته الحقيقية", "Name of the food indicates its true nature", "CXS 1 §4.1"],
    ["ingr", "قائمة المكونات مرتبة تنازليًا حسب الوزن عند التصنيع (بما فيها المضافات بأسماء فئاتها)", "List of ingredients in descending order of ingoing weight (incl. additives by class name)", "CXS 1 §4.2"],
    ["allergen", "التصريح بمسببات الحساسية بوضوح", "Allergens clearly declared", "CXS 1 §4.2.1.4"],
    ["net", "المحتوى الصافي (والوزن المصفّى عند الاقتضاء) بالنظام المتري", "Net contents (and drained weight where applicable) in metric units", "CXS 1 §4.3"],
    ["address", "اسم وعنوان المصنّع أو المعبّئ أو الموزّع أو المستورد", "Name and address of the manufacturer, packer, distributor or importer", "CXS 1 §4.4"],
    ["origin", "بلد المنشأ", "Country of origin", "CXS 1 §4.5"],
    ["lot", "تعريف التشغيلة (رقم الدفعة)", "Lot identification", "CXS 1 §4.6"],
    ["date", "تاريخ الإنتاج / الانتهاء أو «يُفضَّل استهلاكه قبل» حسب الاقتضاء", "Date marking: production / expiry or best before, as applicable", "CXS 1 §4.7"],
    ["storage", "شروط التخزين الخاصة المرتبطة بالتاريخ", "Storage conditions linked to the date marking", "CXS 1 §4.7"],
    ["use", "تعليمات الاستخدام أو التحضير عند الحاجة", "Instructions for use or preparation, where needed", "CXS 1 §4.8"],
    ["nutr", "المعلومات التغذوية (إذا تطلبتها اللائحة المطبقة)", "Nutrition information (if required by the applicable regulation)", "CXG 2-1985"],
    ["lang", "لغة الملصق: العربية مطلوبة حيث تنطبق — راجع لائحتك (مثل SFDA)", "Label language: Arabic required where applicable — check your regulation (e.g. SFDA)", "CXS 1 §8.2"],
    ["legible", "البيانات واضحة ومقروءة وثابتة وغير مضللة", "Information clear, legible, indelible and not misleading", "CXS 1 §3, §8.1"],
  ];
  const labelScore = (ans) => { let y = 0, n = 0, na = 0; LBL.forEach(([k]) => { const a = (ans[k] || {}).a; if (a === "y") y++; else if (a === "n") n++; else if (a === "na") na++; }); return { y, n, na, open: LBL.length - y - n - na, pct: y + n ? Math.round((y / (y + n)) * 1000) / 10 : null }; };
  function labelPage() {
    const RK = "tool:label";
    let ans = {}, photo = "", editing = null;
    const html = `${head("label")}
      <form class="card" id="lbForm" novalidate style="margin-top:18px"><h2 style="font-size:20px" id="lbTitle">${esc(t("newRec"))}</h2>
        <div class="form">
          ${fld("lb-prod", W("اسم المنتج", "Product name"), inp("lb-prod", "text"), { req: true })}
          ${fld("lb-brand", W("العلامة التجارية / المورد", "Brand / supplier"), inp("lb-brand", "text"))}
          ${fld("lb-date", W("تاريخ الفحص", "Check date"), inp("lb-date", "date", today()), { req: true })}
          ${fld("lb-by", W("فحصه", "Checked by"), inp("lb-by", "text"))}
          ${fld("lb-reg", W("اللائحة المرجعية المطبقة", "Applicable regulation"), inp("lb-reg", "text", "", `placeholder="${esc(W("مثال: لائحة SFDA لبطاقات المواد الغذائية المعبأة", "e.g. SFDA regulation for prepackaged food labelling"))}"`), { full: true, hint: W("هذه القائمة مبنية على عناصر Codex CXS 1-1985 العامة؛ تحقق دائمًا من متطلبات لائحتك المحلية.", "This list follows the general elements of Codex CXS 1-1985; always check your local regulation's requirements.") })}
          <div class="full" id="lbPhoto"></div>
          <div class="full"><span class="lbl">${esc(W("عناصر البطاقة", "Label elements"))}</span><div id="lbItems" style="margin-top:6px"></div><span class="err" id="lbItems-e"></span></div>
          ${fld("lb-notes", W("ملاحظات عامة", "General notes"), `<textarea id="lb-notes" rows="2"></textarea>`, { full: true })}
        </div>
        <div class="row" style="margin-top:18px"><button class="btn btn-gold" type="submit">${I.check}<span>${esc(t("save"))}</span></button><button type="button" class="btn btn-ghost" id="lbPrint">${I.printer}<span>${esc(t("print"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="lbNew">${I.plus}<span>${esc(t("newRec"))}</span></button><span class="err" id="lbErr" role="alert"></span></div></form>
      <div class="card" id="lbRes" aria-live="polite" style="margin-top:18px"></div>
      ${recHead(RK)}</div></section>`;
    function after() {
      const drawItems = () => { $("#lbItems").innerHTML = LBL.map(([k, a, e, ref]) => { const v = ans[k] || {}; return `<div class="ck-item lb-item" id="lbi-${k}"><span class="txt">${esc(W(a, e))} <small class="note" dir="ltr">${esc(ref)}</small></span><div class="seg" role="group" aria-label="${esc(W(a, e))}">${[["y", W("نعم", "Yes")], ["n", W("لا", "No")], ["na", W("لا ينطبق", "N/A")]].map(([vv, l]) => `<button type="button" data-k="${k}" data-v="${vv}" aria-pressed="${v.a === vv}">${l}</button>`).join("")}</div><input type="text" data-nk="${k}" value="${esc(v.note || "")}" aria-label="${esc(W("ملاحظة", "Note"))}: ${esc(W(a, e))}" placeholder="${esc(W("ملاحظة (اختياري)", "Note (optional)"))}"></div>`; }).join(""); };
      const drawPhoto = () => { $("#lbPhoto").innerHTML = `<span class="lbl">${esc(W("صورة البطاقة (اختياري)", "Label photo (optional)"))}</span><div class="thumbs" style="margin-top:6px">${photo ? `<figure><img src="${photo}" alt="${esc(W("صورة البطاقة", "Label photo"))}"><button type="button" id="lbRmPh" aria-label="${esc(t("del"))}">×</button></figure>` : `<label class="btn btn-ghost btn-sm" style="cursor:pointer;height:96px;width:96px;flex-direction:column;border-radius:8px;white-space:normal;text-align:center">${I.camera}<span style="font-size:11.5px">${esc(W("أضف صورة", "Add photo"))}</span><input type="file" id="lbFile" accept="image/*" capture="environment" hidden aria-label="${esc(W("صورة البطاقة", "Label photo"))}"></label>`}</div>`;
        const rm = $("#lbRmPh"); rm && rm.addEventListener("click", () => { photo = ""; drawPhoto(); });
        const f = $("#lbFile"); f && f.addEventListener("change", async () => { const file = f.files[0]; if (!file) return; try { photo = await readImage(file, 1000); drawPhoto(); } catch (e) { toast(e.message === "size" ? W("الملف أكبر من 15 ميغابايت.", "File is larger than 15 MB.") : W("نوع الملف غير مدعوم.", "Unsupported file type."), "bad"); } }); };
      const missing = (a) => LBL.filter(([k]) => (a[k] || {}).a === "n");
      const resHtml = () => { const s = labelScore(ans), col = s.pct == null ? "#555" : s.pct === 100 ? "#53b9ad" : "#e5645a", c = 2 * Math.PI * 40, mis = missing(ans);
        return `<h3>${esc(W("نسبة الامتثال", "Compliance"))}</h3><div class="gauge"><svg class="ring" viewBox="0 0 96 96" aria-hidden="true"><circle cx="48" cy="48" r="40" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="9"/><circle cx="48" cy="48" r="40" fill="none" stroke="${col}" stroke-width="9" stroke-linecap="round" stroke-dasharray="${((s.pct || 0) / 100) * c} ${c}" transform="rotate(-90 48 48)"/></svg><div><b>${s.pct == null ? "—" : num(s.pct, 1) + "%"}</b><div class="note" style="margin:0">${esc(W(`نعم ${s.y} · لا ${s.n} · لا ينطبق ${s.na} · بلا إجابة ${s.open}`, `Yes ${s.y} · No ${s.n} · N/A ${s.na} · Unanswered ${s.open}`))}</div></div></div>
          <p class="note" dir="ltr" style="text-align:start">Compliance % = Yes ÷ (Yes + No) × 100${s.y + s.n ? ` = ${s.y} ÷ ${s.y + s.n} × 100` : ""} · N/A excluded</p>
          ${mis.length ? `<h3 style="font-size:15px;margin-top:12px">${esc(W("العناصر الناقصة أو غير المطابقة", "Missing or non-compliant items"))}</h3><ul class="ticks">${mis.map(([k, a, e]) => `<li>${esc(W(a, e))}${ans[k].note ? ` — <i>${esc(ans[k].note)}</i>` : ""}</li>`).join("")}</ul>` : s.y ? `<span class="chip ok">${esc(W("لا توجد عناصر ناقصة", "No missing items"))}</span>` : ""}`; };
      const refresh = () => ($("#lbRes").innerHTML = resHtml());
      $("#lbItems").addEventListener("click", (e) => { const b = e.target.closest("[data-k]"); if (!b) return; const k = b.dataset.k; ans[k] = { ...(ans[k] || {}), a: ans[k] && ans[k].a === b.dataset.v ? "" : b.dataset.v }; $$(`[data-k="${k}"]`).forEach((x) => x.setAttribute("aria-pressed", x.dataset.v === ans[k].a)); $("#lbi-" + k).classList.remove("lb-miss"); refresh(); });
      $("#lbItems").addEventListener("input", (e) => { const n = e.target.closest("[data-nk]"); if (n) { ans[n.dataset.nk] = { ...(ans[n.dataset.nk] || {}), note: n.value }; refresh(); } });
      const reset = (r) => { editing = r ? r.id : null; r = r || {}; ans = JSON.parse(JSON.stringify(r.ans || {})); photo = r.photo || ""; $("#lb-prod").value = r.prod || ""; $("#lb-brand").value = r.brand || ""; $("#lb-date").value = r.date || today(); $("#lb-by").value = r.by || ""; $("#lb-reg").value = r.reg || ""; $("#lb-notes").value = r.notes || ""; drawItems(); drawPhoto(); refresh(); editTitle("lb", r.id ? `${t("edit")} — ${r.prod}` : t("newRec")); ["lb-prod", "lb-date"].forEach((id) => setErr(id, "")); $("#lbItems-e").textContent = ""; $("#lbErr").textContent = ""; };
      const read = () => ({ prod: val("lb-prod"), brand: val("lb-brand"), date: val("lb-date"), by: val("lb-by"), reg: val("lb-reg"), notes: val("lb-notes"), ans: JSON.parse(JSON.stringify(ans)), photo });
      const validate = (r) => {
        let ok = setErr("lb-prod", r.prod ? "" : t("required")); ok = setErr("lb-date", r.date ? "" : t("required")) && ok;
        const open = LBL.filter(([k]) => !(r.ans[k] || {}).a);
        $$(".lb-item").forEach((el) => el.classList.toggle("lb-miss", open.some(([k]) => "lbi-" + k === el.id)));
        $("#lbItems-e").textContent = open.length ? W(`أجب عن كل العناصر (نعم / لا / لا ينطبق). المتبقي: ${open.length}.`, `Answer every item (Yes / No / N/A). Remaining: ${open.length}.`) : "";
        if (open.length) ok = false;
        $("#lbErr").textContent = ok ? "" : t("fixErrors");
        if (!ok) { const b = $("[aria-invalid=true]", $("#lbForm")) || $(".lb-miss button"); b && b.focus(); }
        return ok;
      };
      const report = (r) => { const s = labelScore(r.ans), aL = { y: W("نعم", "Yes"), n: W("لا", "No"), na: W("لا ينطبق", "N/A") };
        return kvTable([[W("المنتج", "Product"), esc(r.prod)], [W("العلامة / المورد", "Brand / supplier"), esc(r.brand)], [W("تاريخ الفحص", "Check date"), esc(fmtDate(r.date))], [W("فحصه", "Checked by"), esc(r.by)], [W("اللائحة المرجعية", "Regulation"), esc(r.reg)], [W("نسبة الامتثال", "Compliance"), `<b>${s.pct == null ? "—" : num(s.pct, 1) + "%"}</b> (${s.y} / ${s.y + s.n}; N/A ${s.na})`]]) +
          `<table class="t" style="min-width:0;margin-top:12px"><tr><th>#</th><th>${esc(W("العنصر", "Element"))}</th><th>${esc(W("المرجع", "Ref."))}</th><th>${esc(W("النتيجة", "Result"))}</th><th>${esc(W("ملاحظة", "Note"))}</th></tr>${LBL.map(([k, a, e, ref], i) => { const v = r.ans[k] || {}; return `<tr><td>${i + 1}</td><td>${esc(W(a, e))}</td><td dir="ltr">${esc(ref)}</td><td><b>${esc(aL[v.a] || "—")}</b></td><td>${esc(v.note || "")}</td></tr>`; }).join("")}</table>` +
          (missing(r.ans).length ? `<h3>${esc(W("العناصر الناقصة أو غير المطابقة", "Missing or non-compliant items"))}</h3><ul>${missing(r.ans).map(([, a, e]) => `<li>${esc(W(a, e))}</li>`).join("")}</ul>` : "") +
          (r.notes ? `<h3>${esc(W("ملاحظات", "Notes"))}</h3><p>${nl2br(r.notes)}</p>` : "") + (r.photo ? `<h3>${esc(W("صورة البطاقة", "Label photo"))}</h3><img src="${r.photo}" alt="" style="max-width:320px;max-height:320px;border:1px solid #bbb;border-radius:4px">` : "") +
          `<p style="font-size:9pt;margin-top:10px">${esc(W("المرجع: عناصر Codex CXS 1-1985 العامة لبطاقات الأغذية المعبأة مسبقًا؛ المتطلبات الملزمة هي ما تنص عليه اللائحة المحلية المطبقة.", "Reference: general elements of Codex CXS 1-1985 for prepackaged food labels; binding requirements are those of the applicable local regulation."))}</p>`; };
      const printRec = (r) => printHtml(`${L(tool("label").t)} — ${r.prod}`, report(r));
      const draw = recList($("#tool-label-list"), RK, [
        [W("التاريخ", "Date"), (r) => esc(fmtDate(r.date))], [W("المنتج", "Product"), (r) => esc(r.prod)], [W("العلامة", "Brand"), (r) => esc(r.brand || "—")],
        [W("الامتثال", "Compliance"), (r) => { const s = labelScore(r.ans || {}); return s.pct == null ? "—" : `<span class="chip ${s.pct === 100 ? "ok" : "bad"}">${num(s.pct, 1)}%</span>`; }], [W("ناقص", "Missing"), (r) => missing(r.ans || {}).length],
      ], { edit: (r) => { reset(r); A.scrollTo($("#lbForm"), true); }, print: printRec, deleted: (id) => { if (editing === id) reset(null); } });
      $("#lbPrint").addEventListener("click", () => { const r = read(); if (validate(r)) printRec(r); });
      $("#lbNew").addEventListener("click", () => reset(null));
      $("#lbForm").addEventListener("submit", (e) => { e.preventDefault(); const r = read(); if (!validate(r)) return; r.pct = labelScore(r.ans).pct; if (saveRec(RK, r, editing)) { toast(t("saved")); editing = r.id; editTitle("lb", `${t("edit")} — ${r.prod}`); draw(); } });
      reset(null);
    }
    return { title: L(tool("label").t), html, after };
  }

  /* =====================================================================
     4) Quality meeting minutes
     ===================================================================== */
  function minutesPage() {
    const RK = "tool:minutes";
    const att = [], agenda = [], actions = []; let editing = null;
    const bA = () => ({ name: "", role: "" }), bG = () => ({ topic: "", notes: "" }), bX = () => ({ action: "", owner: "", due: "", status: "open" });
    const stOpts = () => [["open", W("مفتوح", "Open")], ["done", W("منجز", "Done")]];
    const html = `${head("minutes")}
      <form class="card" id="mnForm" novalidate style="margin-top:18px"><h2 style="font-size:20px" id="mnTitle">${esc(t("newRec"))}</h2>
        <div class="form">
          ${fld("mn-title", W("عنوان الاجتماع", "Meeting title"), inp("mn-title", "text", "", `placeholder="${esc(W("مثال: اجتماع لجنة سلامة الغذاء الشهري", "e.g. Monthly food safety team meeting"))}"`), { req: true, full: true })}
          ${fld("mn-date", W("التاريخ", "Date"), inp("mn-date", "date", today()), { req: true })}
          ${fld("mn-time", W("الوقت", "Time"), inp("mn-time", "time"))}
          ${fld("mn-place", W("المكان", "Place"), inp("mn-place", "text"))}
          ${fld("mn-chair", W("رئيس الاجتماع", "Chair"), inp("mn-chair", "text"), { req: true })}
          ${fld("mn-sec", W("مقرر الاجتماع (كاتب المحضر)", "Minute taker"), inp("mn-sec", "text"))}
          <div class="full"><span class="lbl req">${esc(W("الحضور", "Attendees"))}</span><div id="mnAtt" style="margin-top:6px"></div><span class="err" id="mnAtt-e"></span></div>
          <div class="full"><span class="lbl">${esc(W("بنود جدول الأعمال والنقاش", "Agenda items & discussion"))}</span><div id="mnAg" style="margin-top:6px"></div><span class="err" id="mnAg-e"></span></div>
          ${fld("mn-dec", W("القرارات", "Decisions"), `<textarea id="mn-dec" rows="3" placeholder="${esc(W("قرار في كل سطر", "One decision per line"))}"></textarea>`, { full: true })}
          <div class="full"><div class="row"><span class="lbl">${esc(W("الإجراءات المطلوبة", "Action items"))}</span><span class="spacer"></span><button type="button" class="btn btn-ghost btn-sm" id="mnCarry">${I.arrow}<span>${esc(W("ترحيل الإجراءات المفتوحة من الاجتماع السابق", "Carry over open actions from previous meeting"))}</span></button></div><div id="mnAct" style="margin-top:6px"></div><span class="err" id="mnAct-e"></span></div>
          ${fld("mn-next", W("موعد الاجتماع القادم", "Next meeting"), inp("mn-next", "date"))}
        </div>
        <div class="row" style="margin-top:18px"><button class="btn btn-gold" type="submit">${I.check}<span>${esc(t("save"))}</span></button><button type="button" class="btn btn-ghost" id="mnPrint">${I.printer}<span>${esc(t("print"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="mnNew">${I.plus}<span>${esc(t("newRec"))}</span></button><span class="err" id="mnErr" role="alert"></span></div></form>
      ${recHead(RK)}</div></section>`;
    function after() {
      const ga = grid($("#mnAtt"), att, [{ k: "name", l: W("الاسم", "Name"), w: 140 }, { k: "role", l: W("الصفة / القسم", "Role / department"), w: 140 }], { id: "ma", min: 1, minW: 0, blank: bA, addLabel: W("أضف حاضرًا", "Add attendee") });
      const gg = grid($("#mnAg"), agenda, [{ k: "topic", l: W("البند", "Item"), w: 150 }, { k: "notes", l: W("ملخص النقاش", "Discussion notes"), type: "textarea" }], { id: "mg", min: 0, minW: 520, blank: bG, addLabel: W("أضف بندًا", "Add agenda item") });
      const gx = grid($("#mnAct"), actions, [{ k: "action", l: W("الإجراء", "Action"), w: 170 }, { k: "owner", l: W("المسؤول", "Owner"), w: 110 }, { k: "due", l: W("الموعد", "Due date"), type: "date", w: 130 }, { k: "status", l: W("الحالة", "Status"), type: "select", opts: stOpts }], { id: "mx", min: 0, minW: 640, blank: bX, addLabel: W("أضف إجراءً", "Add action") });
      const reset = (r) => {
        editing = r ? r.id : null; r = r || {};
        [["title", "title"], ["time", "time"], ["place", "place"], ["chair", "chair"], ["sec", "sec"], ["dec", "dec"], ["next", "next"]].forEach(([id, k]) => ($("#mn-" + id).value = r[k] || ""));
        $("#mn-date").value = r.date || today();
        ga.set(r.att && r.att.length ? r.att : [bA()]); gg.set(r.agenda && r.agenda.length ? r.agenda : [bG()]); gx.set(r.actions || []);
        editTitle("mn", r.id ? `${t("edit")} — ${r.title}` : t("newRec"));
        $$("[aria-invalid]", $("#mnForm")).forEach((el) => el.setAttribute("aria-invalid", "false")); $$(".err", $("#mnForm")).forEach((e) => (e.textContent = ""));
      };
      const read = () => ({ title: val("mn-title"), date: val("mn-date"), time: val("mn-time"), place: val("mn-place"), chair: val("mn-chair"), sec: val("mn-sec"), dec: val("mn-dec"), next: val("mn-next"),
        att: att.filter((a) => a.name.trim() || a.role.trim()).map((a) => ({ ...a })), agenda: agenda.filter((a) => a.topic.trim() || a.notes.trim()).map((a) => ({ ...a })), actions: actions.map((a) => ({ ...a })) });
      const validate = (r) => {
        let ok = setErr("mn-title", r.title ? "" : t("required")); ok = setErr("mn-date", r.date ? "" : t("required")) && ok; ok = setErr("mn-chair", r.chair ? "" : t("required")) && ok;
        ok = setErr("mn-next", r.next && r.date && r.next < r.date ? W("يجب أن يكون بعد تاريخ الاجتماع.", "Must be after the meeting date.") : "") && ok;
        let m = "";
        att.forEach((a, i) => { const b = !a.name.trim() && (a.role.trim() || i === 0) && !r.att.length; ga.mark(i, "name", b || (!a.name.trim() && !!a.role.trim())); if (!a.name.trim() && a.role.trim()) m = W(`أدخل اسم الحاضر ${i + 1}.`, `Enter a name for attendee ${i + 1}.`); });
        if (!r.att.length) m = W("أضف حاضرًا واحدًا على الأقل.", "Add at least one attendee.");
        $("#mnAtt-e").textContent = m; if (m) ok = false;
        let g = ""; agenda.forEach((a, i) => { const b = !a.topic.trim() && !!a.notes.trim(); gg.mark(i, "topic", b); if (b) g = W(`أدخل عنوان البند ${i + 1}.`, `Enter a title for agenda item ${i + 1}.`); });
        $("#mnAg-e").textContent = g; if (g) ok = false;
        let x = ""; actions.forEach((a, i) => { const ba = !a.action.trim(), bo = !a.owner.trim(); gx.mark(i, "action", ba); gx.mark(i, "owner", bo); if (ba || bo) x = W(`الإجراء ${i + 1}: أدخل الوصف والمسؤول (أو احذف السطر).`, `Action ${i + 1}: enter the action and owner (or remove the row).`); });
        $("#mnAct-e").textContent = x; if (x) ok = false;
        $("#mnErr").textContent = ok ? "" : t("fixErrors"); if (!ok) focusBad($("#mnForm"));
        return ok;
      };
      $("#mnCarry").addEventListener("click", () => {
        const prev = store.get(RK, []).filter((m) => m.id !== editing).sort((a, b) => (a.date === b.date ? a.created - b.created : a.date < b.date ? -1 : 1)).pop();
        if (!prev) return toast(W("لا يوجد اجتماع سابق محفوظ.", "No previous meeting saved."), "bad");
        const open = (prev.actions || []).filter((a) => a.status !== "done");
        const have = new Set(actions.map((a) => (a.action + "|" + a.owner).toLowerCase()));
        const add = open.filter((a) => !have.has((a.action + "|" + a.owner).toLowerCase()));
        if (!add.length) return toast(open.length ? W("الإجراءات المفتوحة مُرحّلة مسبقًا.", "Open actions are already carried over.") : W("لا توجد إجراءات مفتوحة في الاجتماع السابق.", "No open actions in the previous meeting."));
        gx.set(actions.filter((a) => a.action.trim() || a.owner.trim()).concat(add.map((a) => ({ ...a, from: prev.date })))); toast(W(`تم ترحيل ${add.length} إجراء من اجتماع ${fmtDate(prev.date)}.`, `Carried over ${add.length} action(s) from the ${fmtDate(prev.date)} meeting.`));
      });
      const report = (r) => `${kvTable([[W("الاجتماع", "Meeting"), `<b>${esc(r.title)}</b>`], [W("التاريخ والوقت", "Date & time"), `${esc(fmtDate(r.date))} ${esc(r.time)}`], [W("المكان", "Place"), esc(r.place)], [W("رئيس الاجتماع", "Chair"), esc(r.chair)], [W("مقرر الاجتماع", "Minute taker"), esc(r.sec)]])}
        <h3>${esc(W("الحضور", "Attendees"))}</h3><table class="t" style="min-width:0"><tr><th>#</th><th>${esc(W("الاسم", "Name"))}</th><th>${esc(W("الصفة / القسم", "Role / department"))}</th><th>${esc(W("التوقيع", "Signature"))}</th></tr>${r.att.map((a, i) => `<tr><td>${i + 1}</td><td>${esc(a.name)}</td><td>${esc(a.role)}</td><td style="width:28%"></td></tr>`).join("")}</table>
        ${r.agenda.length ? `<h3>${esc(W("جدول الأعمال والنقاش", "Agenda & discussion"))}</h3>${r.agenda.map((a, i) => `<p style="margin:6px 0"><b>${i + 1}. ${esc(a.topic)}</b><br>${nl2br(a.notes)}</p>`).join("")}` : ""}
        ${r.dec ? `<h3>${esc(W("القرارات", "Decisions"))}</h3><ol>${r.dec.split(/\n+/).filter((s) => s.trim()).map((s) => `<li>${esc(s)}</li>`).join("")}</ol>` : ""}
        <h3>${esc(W("الإجراءات المطلوبة", "Action items"))}</h3>${r.actions.length ? `<table class="t" style="min-width:0"><tr><th>#</th><th>${esc(W("الإجراء", "Action"))}</th><th>${esc(W("المسؤول", "Owner"))}</th><th>${esc(W("الموعد", "Due"))}</th><th>${esc(W("الحالة", "Status"))}</th></tr>${r.actions.map((a, i) => `<tr><td>${i + 1}</td><td>${esc(a.action)}${a.from ? ` <small>(${esc(W("مُرحّل من", "carried from"))} ${esc(fmtDate(a.from))})</small>` : ""}</td><td>${esc(a.owner)}</td><td>${esc(fmtDate(a.due))}</td><td>${esc(a.status === "done" ? W("منجز", "Done") : W("مفتوح", "Open"))}</td></tr>`).join("")}</table>` : `<p>—</p>`}
        ${r.next ? `<p><b>${esc(W("الاجتماع القادم", "Next meeting"))}:</b> ${esc(fmtDate(r.next))}</p>` : ""}
        <table class="t" style="min-width:0;margin-top:26px"><tr><th>${esc(W("رئيس الاجتماع", "Chair"))}: ${esc(r.chair)}</th><th>${esc(W("مقرر الاجتماع", "Minute taker"))}: ${esc(r.sec)}</th></tr><tr><td style="height:56px;vertical-align:bottom">${esc(W("التوقيع / التاريخ", "Signature / date"))}</td><td style="vertical-align:bottom">${esc(W("التوقيع / التاريخ", "Signature / date"))}</td></tr></table>`;
      const printRec = (r) => printHtml(`${W("محضر اجتماع", "Meeting minutes")} — ${r.title}`, report(r));
      const draw = recList($("#tool-minutes-list"), RK, [
        [W("التاريخ", "Date"), (r) => esc(fmtDate(r.date))], [W("الاجتماع", "Meeting"), (r) => esc(r.title)], [W("رئيس الاجتماع", "Chair"), (r) => esc(r.chair)],
        [W("الحضور", "Attendees"), (r) => (r.att || []).length], [W("إجراءات مفتوحة", "Open actions"), (r) => { const n = (r.actions || []).filter((a) => a.status !== "done").length; return `<span class="chip ${n ? "warn" : "ok"}">${n}</span>`; }],
      ], { edit: (r) => { reset(r); A.scrollTo($("#mnForm"), true); }, print: printRec, deleted: (id) => { if (editing === id) reset(null); } });
      $("#mnPrint").addEventListener("click", () => { const r = read(); if (validate(r)) printRec(r); });
      $("#mnNew").addEventListener("click", () => reset(null));
      $("#mnForm").addEventListener("submit", (e) => { e.preventDefault(); const r = read(); if (!validate(r)) return; if (saveRec(RK, r, editing)) { toast(t("saved")); reset(null); draw(); } });
      reset(null);
    }
    return { title: L(tool("minutes").t), html, after };
  }

  /* =====================================================================
     5) Branch visit planner
     ===================================================================== */
  const DAYS = [["الأحد", "Sun"], ["الاثنين", "Mon"], ["الثلاثاء", "Tue"], ["الأربعاء", "Wed"], ["الخميس", "Thu"], ["الجمعة", "Fri"], ["السبت", "Sat"]];
  const PRI = [["high", "عالية", "High", "bad"], ["medium", "متوسطة", "Medium", "warn"], ["low", "منخفضة", "Low", "teal"]];
  const priChip = (p) => { const o = PRI.find((x) => x[0] === p) || PRI[2]; return `<span class="chip ${o[3]}">${esc(W(o[1], o[2]))}</span>`; };
  const pD = (s) => { const [y, m, d] = s.split("-").map(Number); return new Date(Date.UTC(y, m - 1, d)); };
  const iso = (d) => d.toISOString().slice(0, 10);
  const addD = (s, n) => { const d = pD(s); d.setUTCDate(d.getUTCDate() + n); return iso(d); };
  const diffD = (a, b) => Math.round((pD(a) - pD(b)) / 864e5);
  /* s: { start, weeks, days: [0-6], perDay, freq: { high, medium, low } } (days, same weekday numbering as Date#getDay) */
  function planVisits(branches, s) {
    const H = s.weeks * 7, work = [];
    for (let i = 0; i < H; i++) { const d = addD(s.start, i); if (s.days.includes(pD(d).getUTCDay())) work.push({ i, date: d, items: [] }); }
    const rank = { high: 0, medium: 1, low: 2 }, jobs = [];
    branches.forEach((b) => { const f = Math.max(1, +s.freq[b.priority] || 1); let k = b.last ? diffD(b.last, s.start) + f : 0; if (k < 0) k = 0; for (; k < H; k += f) jobs.push({ b, target: k, f }); });
    jobs.sort((a, b) => a.target - b.target || rank[a.b.priority] - rank[b.b.priority] || a.b.name.localeCompare(b.b.name));
    const lastI = {}, unscheduled = [];
    jobs.forEach((j) => {
      const g = Math.floor(j.f / 3), minI = Math.max(0, j.target - g, lastI[j.b.id] != null ? lastI[j.b.id] + Math.ceil(j.f / 2) : 0);
      const cand = work.filter((w) => w.items.length < s.perDay && w.i >= minI);
      if (!cand.length) { unscheduled.push({ branchId: j.b.id, name: j.b.name, due: addD(s.start, j.target) }); return; }
      const win = cand.filter((w) => w.i <= j.target + g), pool = win.length ? win : [cand[0]];
      const area = (j.b.area || "").trim().toLowerCase(), same = (w) => (area ? w.items.filter((x) => x.areaKey === area).length : 0);
      pool.sort((a, b) => same(b) - same(a) || Math.abs(a.i - j.target) - Math.abs(b.i - j.target) || a.i - b.i);
      const w = pool[0];
      w.items.push({ id: uid(), date: w.date, branchId: j.b.id, name: j.b.name, area: j.b.area || "", areaKey: area, priority: j.b.priority, done: false });
      lastI[j.b.id] = w.i;
    });
    return { plan: work.flatMap((w) => w.items), unscheduled };
  }
  function visitsPage() {
    const KEY = "tool:visits";
    const load = () => { const d = store.get(KEY, {}) || {}; return { branches: d.branches || [], settings: Object.assign({ start: today(), weeks: 2, days: [0, 1, 2, 3, 4], perDay: 3, freq: { high: 7, medium: 14, low: 28 } }, d.settings || {}), plan: d.plan || [], unscheduled: d.unscheduled || [], generated: d.generated || null }; };
    let D = load(), editingB = null;
    const persist = () => store.set(KEY, D);
    const html = `${head("visits")}
      <div class="grid g2" style="margin-top:18px;align-items:start">
        <form class="card" id="vbForm" novalidate><h2 style="font-size:20px" id="vbTitle">${esc(W("إضافة فرع", "Add a branch"))}</h2><div class="form">
          ${fld("vb-name", W("اسم الفرع", "Branch name"), inp("vb-name", "text"), { req: true })}
          ${fld("vb-area", W("المنطقة / الحي", "Area / district"), inp("vb-area", "text", "", 'list="vbAreas"'), { hint: W("الفروع في المنطقة نفسها تُجمع في يوم واحد قدر الإمكان.", "Branches in the same area are grouped on the same day where possible.") })}
          ${fld("vb-pri", W("الأولوية", "Priority"), `<select id="vb-pri"><option value="">—</option>${PRI.map(([v, a, e]) => `<option value="${v}">${esc(W(a, e))}</option>`).join("")}</select>`, { req: true })}
          ${fld("vb-last", W("تاريخ آخر زيارة", "Last visit date"), inp("vb-last", "date"), { hint: W("اتركه فارغًا إذا لم يُزر بعد (يُجدول في بداية الخطة).", "Leave blank if never visited (scheduled at the start of the plan).") })}
          <div class="full row"><button class="btn btn-gold" type="submit">${I.plus}<span id="vbSubmit">${esc(W("أضف الفرع", "Add branch"))}</span></button><button type="button" class="btn btn-ghost btn-sm" id="vbCancel" style="display:none">${esc(t("cancel"))}</button></div></div><datalist id="vbAreas"></datalist></form>
        <form class="card" id="vsForm" novalidate><h2 style="font-size:20px">${esc(W("إعدادات التخطيط", "Planning settings"))}</h2><div class="form">
          <fieldset class="full vs-days"><legend class="lbl req">${esc(W("أيام العمل", "Working days"))}</legend><div class="row" style="gap:6px;margin-top:6px">${DAYS.map(([a, e], i) => `<label class="chip vs-day"><input type="checkbox" value="${i}" data-day> ${esc(W(a, e))}</label>`).join("")}</div><span class="err" id="vs-days-e"></span></fieldset>
          ${fld("vs-per", W("عدد الزيارات في اليوم", "Visits per day"), inp("vs-per", "number", "", 'min="1" step="1"'), { req: true })}
          ${fld("vs-weeks", W("مدة الخطة", "Planning horizon"), `<select id="vs-weeks"><option value="2">${esc(W("أسبوعان", "2 weeks"))}</option><option value="4">${esc(W("4 أسابيع", "4 weeks"))}</option></select>`)}
          ${fld("vs-start", W("تاريخ بداية الخطة", "Plan start date"), inp("vs-start", "date"), { req: true })}
          <fieldset class="full"><legend class="lbl">${esc(W("سياستك لتكرار الزيارات (قيم افتراضية قابلة للتعديل)", "Your visit-frequency policy (editable defaults)"))}</legend><div class="form vs-freq" style="margin-top:6px">${PRI.map(([v, a, e]) => fld("vs-f-" + v, W(`${a}: كل … يوم`, `${e}: every … days`), inp("vs-f-" + v, "number", "", 'min="1" step="1"'))).join("")}</div><p class="note" style="margin:4px 0 0">${esc(W("الافتراض: عالية أسبوعيًا، متوسطة كل أسبوعين، منخفضة كل 4 أسابيع — عدّلها حسب سياسة منشأتك.", "Default: high weekly, medium every 2 weeks, low every 4 weeks — change them to your organisation's policy."))}</p></fieldset>
          <div class="full row"><button class="btn btn-gold" type="submit">${I.calc}<span>${esc(W("أنشئ الجدول", "Generate schedule"))}</span></button><button type="button" class="btn btn-ghost" id="vsPrint">${I.printer}<span>${esc(t("print"))}</span></button><span class="err" id="vsErr" role="alert"></span></div></div></form>
      </div>
      <h2 style="font-size:22px;margin:30px 0 12px">${esc(W("الفروع", "Branches"))} <span class="chip" id="vbCount"></span></h2><div id="vbList"></div>
      <div class="row" style="margin:30px 0 12px"><h2 style="font-size:22px;margin:0">${esc(W("جدول الزيارات", "Visit schedule"))}</h2><span class="spacer"></span><span class="note" id="vpMeta" style="margin:0"></span></div><div id="vpCal"></div>
      <div class="card" style="margin-top:18px"><h3>${esc(W("كيف يُبنى الجدول", "How the schedule is built"))}</h3><ul class="ticks">
        <li>${esc(W("موعد الزيارة = آخر زيارة + فترة التكرار حسب الأولوية (الفرع المتأخر أو غير المزار يُجدول من بداية الخطة)، ثم كل فترة تكرار حتى نهاية المدة.", "Due date = last visit + the priority's interval (overdue or never-visited branches start at the plan start), then every interval until the horizon ends."))}</li>
        <li>${esc(W("تُوزَّع الزيارات بترتيب الموعد ثم الأولوية على أيام العمل ضمن نافذة ± ثلث فترة التكرار، مع تفضيل اليوم الذي فيه فرع من المنطقة نفسها، ثم الأقرب إلى الموعد، دون تجاوز عدد الزيارات اليومي.", "Visits are placed in order of due date, then priority, on working days within ± one third of the interval, preferring a day that already has a branch from the same area, then the day nearest the due date, without exceeding the daily capacity."))}</li>
        <li>${esc(W("عند تعليم الزيارة «تمت» يُحدَّث تاريخ آخر زيارة للفرع؛ أعد إنشاء الجدول لاحقًا ليبني على ذلك.", "Marking a visit done updates the branch's last visit date; regenerate later to build on it."))}</li></ul></div>
      </div></section>`;
    function after() {
      const fillSettings = () => { const s = D.settings; $$("[data-day]").forEach((c) => (c.checked = s.days.includes(+c.value))); $("#vs-per").value = s.perDay; $("#vs-weeks").value = String(s.weeks); $("#vs-start").value = s.start || today(); PRI.forEach(([v]) => ($("#vs-f-" + v).value = s.freq[v])); };
      const resetB = (b) => { editingB = b ? b.id : null; $("#vb-name").value = b ? b.name : ""; $("#vb-area").value = b ? b.area : ""; $("#vb-pri").value = b ? b.priority : ""; $("#vb-last").value = b ? b.last || "" : ""; $("#vbTitle").textContent = b ? `${t("edit")} — ${b.name}` : W("إضافة فرع", "Add a branch"); $("#vbSubmit").textContent = b ? t("save") : W("أضف الفرع", "Add branch"); $("#vbCancel").style.display = b ? "" : "none"; ["vb-name", "vb-pri", "vb-last"].forEach((id) => setErr(id, "")); };
      const drawB = () => {
        $("#vbCount").textContent = D.branches.length;
        $("#vbAreas").innerHTML = [...new Set(D.branches.map((b) => b.area).filter(Boolean))].map((a) => `<option value="${esc(a)}">`).join("");
        const sorted = D.branches.slice().sort((a, b) => (a.area || "").localeCompare(b.area || "") || a.name.localeCompare(b.name));
        $("#vbList").innerHTML = D.branches.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("الفرع", "Branch"))}</th><th>${esc(W("المنطقة", "Area"))}</th><th>${esc(W("الأولوية", "Priority"))}</th><th>${esc(W("آخر زيارة", "Last visit"))}</th><th>${esc(W("الزيارة القادمة المستحقة", "Next due"))}</th><th><span class="sr-only">${esc(W("إجراءات", "Actions"))}</span></th></tr></thead><tbody>${sorted.map((b) => { const due = b.last ? addD(b.last, +D.settings.freq[b.priority] || 7) : null; return `<tr><td>${esc(b.name)}</td><td>${esc(b.area || "—")}</td><td>${priChip(b.priority)}</td><td>${esc(b.last ? fmtDate(b.last) : W("لم يُزر", "Never"))}</td><td>${due ? `${esc(fmtDate(due))}${due < today() ? ` <span class="chip bad">${esc(W("متأخر", "Overdue"))}</span>` : ""}` : `<span class="chip warn">${esc(W("في أقرب وقت", "As soon as possible"))}</span>`}</td><td style="white-space:nowrap">${iconBtn("bed", b.id, I.note, t("edit"))} ${iconBtn("bdel", b.id, I.trash, t("del"))}</td></tr>`; }).join("")}</tbody></table></div>` : `<div class="empty">${esc(W("أضف فروعك أولًا.", "Add your branches first."))}</div>`;
      };
      const drawPlan = () => {
        const s = D.settings, host = $("#vpCal");
        if (!D.plan.length && !D.unscheduled.length) { host.innerHTML = `<div class="empty">${esc(W("لم يُنشأ جدول بعد.", "No schedule generated yet."))}</div>`; $("#vpMeta").textContent = ""; return; }
        const days = s.days.slice().sort((a, b) => a - b), done = D.plan.filter((p) => p.done).length;
        $("#vpMeta").textContent = W(`${D.plan.length} زيارة · تمت ${done} · من ${fmtDate(s.start)}`, `${D.plan.length} visits · ${done} done · from ${fmtDate(s.start)}`);
        const sunday = addD(s.start, -pD(s.start).getUTCDay()), end = addD(s.start, s.weeks * 7 - 1), weeks = Math.ceil((diffD(end, sunday) + 1) / 7);
        let rows = "";
        for (let w = 0; w < weeks; w++) {
          rows += `<tr><th scope="row" class="vp-wk">${esc(W("الأسبوع", "Week"))} ${w + 1}</th>${days.map((dd) => { const d = addD(sunday, w * 7 + dd), out = d < s.start || d > end, items = D.plan.filter((p) => p.date === d);
            return `<td class="${out ? "vp-out" : ""}"><div class="vp-d">${esc(fmtDate(d, { day: "numeric", month: "short" }))}</div>${items.map((p) => `<div class="vp-v ${p.done ? "is-done" : ""}"><b>${esc(p.name)}</b><div class="row" style="gap:4px">${p.area ? `<span class="chip">${esc(p.area)}</span>` : ""}${priChip(p.priority)}</div><div class="row" style="gap:8px;margin-top:4px"><label class="vp-done"><input type="checkbox" data-done="${p.id}" ${p.done ? "checked" : ""}> ${esc(W("تمت", "Done"))}</label><a class="more" href="#/tools/inspection" style="font-size:12.5px">${esc(W("قائمة التفتيش", "Checklist"))}</a></div></div>`).join("")}</td>`; }).join("")}</tr>`;
        }
        host.innerHTML = `<div class="table-wrap"><table class="t vp-cal" style="min-width:${120 + days.length * 150}px"><thead><tr><th></th>${days.map((d) => `<th>${esc(W(DAYS[d][0], DAYS[d][1]))}</th>`).join("")}</tr></thead><tbody>${rows}</tbody></table></div>${D.unscheduled.length ? `<div class="disclaimer" style="margin-top:12px">${I.warn}<div>${esc(W(`تعذّرت جدولة ${D.unscheduled.length} زيارة لعدم كفاية السعة (زد أيام العمل أو عدد الزيارات اليومي):`, `${D.unscheduled.length} visit(s) couldn't be scheduled — not enough capacity (add working days or visits per day):`))} ${D.unscheduled.map((u) => `${esc(u.name)} (${esc(fmtDate(u.due))})`).join("، ")}</div></div>` : ""}`;
      };
      $("#vpCal").addEventListener("change", (e) => {
        const c = e.target.closest("[data-done]"); if (!c) return; const p = D.plan.find((x) => x.id === c.dataset.done); if (!p) return; const b = D.branches.find((x) => x.id === p.branchId);
        p.done = c.checked;
        if (b) { if (p.done) { p.prevLast = b.last || ""; if (!b.last || p.date > b.last) b.last = p.date; } else if (p.prevLast != null && b.last === p.date) b.last = p.prevLast; }
        persist(); drawB(); drawPlan(); toast(t("saved"));
      });
      $("#vbForm").addEventListener("submit", (e) => {
        e.preventDefault(); const b = { name: val("vb-name"), area: val("vb-area"), priority: $("#vb-pri").value, last: val("vb-last") };
        let ok = setErr("vb-name", !b.name ? t("required") : D.branches.some((x) => x.id !== editingB && x.name.toLowerCase() === b.name.toLowerCase()) ? W("يوجد فرع بالاسم نفسه.", "A branch with this name already exists.") : "");
        ok = setErr("vb-pri", b.priority ? "" : t("required")) && ok; ok = setErr("vb-last", b.last && b.last > today() ? W("لا يمكن أن يكون في المستقبل.", "Can't be in the future.") : "") && ok;
        if (!ok) return focusBad($("#vbForm"));
        if (editingB) { const x = D.branches.find((y) => y.id === editingB); Object.assign(x, b); D.plan.filter((p) => p.branchId === x.id).forEach((p) => { p.name = x.name; p.area = x.area; p.areaKey = x.area.toLowerCase(); p.priority = x.priority; }); } else D.branches.push({ id: uid(), ...b });
        if (persist()) { toast(t("saved")); resetB(null); drawB(); drawPlan(); $("#vb-name").focus(); }
      });
      $("#vbCancel").addEventListener("click", () => resetB(null));
      $("#vbList").addEventListener("click", (e) => {
        const ed = e.target.closest("[data-bed]"), dl = e.target.closest("[data-bdel]");
        if (ed) { resetB(D.branches.find((b) => b.id === ed.dataset.bed)); A.scrollTo($("#vbForm"), true); }
        if (dl && confirm(t("confirmDel"))) { D.branches = D.branches.filter((b) => b.id !== dl.dataset.bdel); D.plan = D.plan.filter((p) => p.branchId !== dl.dataset.bdel); if (editingB === dl.dataset.bdel) resetB(null); persist(); drawB(); drawPlan(); toast(t("deleted")); }
      });
      $("#vsForm").addEventListener("submit", (e) => {
        e.preventDefault();
        const s = { days: $$("[data-day]").filter((c) => c.checked).map((c) => +c.value), perDay: nval("vs-per"), weeks: +$("#vs-weeks").value, start: val("vs-start"), freq: {} };
        PRI.forEach(([v]) => (s.freq[v] = nval("vs-f-" + v)));
        const intMsg = (v) => (v === "" ? t("required") : !(Number.isInteger(v) && v >= 1) ? W("أدخل عددًا صحيحًا ≥ 1.", "Enter a whole number ≥ 1.") : "");
        let ok = setErr("vs-per", intMsg(s.perDay)); ok = setErr("vs-start", s.start ? "" : t("required")) && ok;
        PRI.forEach(([v]) => { ok = setErr("vs-f-" + v, intMsg(s.freq[v])) && ok; });
        $("#vs-days-e").textContent = s.days.length ? "" : W("اختر يوم عمل واحدًا على الأقل.", "Choose at least one working day."); if (!s.days.length) ok = false;
        let msg = ok ? "" : t("fixErrors");
        if (ok && !D.branches.length) { msg = W("أضف فرعًا واحدًا على الأقل.", "Add at least one branch."); ok = false; }
        $("#vsErr").textContent = msg; if (!ok) { const b = $("[aria-invalid=true]", $("#vsForm")) || (!s.days.length && $("[data-day]")); b && b.focus(); return; }
        if (D.plan.length && !confirm(W("سيُستبدل الجدول الحالي (تواريخ الزيارات المنجزة محفوظة في الفروع). متابعة؟", "This replaces the current schedule (done visits are kept as branch last-visit dates). Continue?"))) return;
        D.settings = s; const out = planVisits(D.branches, s); D.plan = out.plan; D.unscheduled = out.unscheduled; D.generated = Date.now();
        if (persist()) { toast(W("تم إنشاء الجدول", "Schedule generated")); drawB(); drawPlan(); A.scrollTo($("#vpCal"), true); }
      });
      $("#vsPrint").addEventListener("click", () => {
        if (!D.plan.length) return toast(W("أنشئ الجدول أولًا.", "Generate a schedule first."), "bad");
        const dates = [...new Set(D.plan.map((p) => p.date))].sort();
        printHtml(`${L(tool("visits").t)} — ${fmtDate(D.settings.start)}`, kvTable([[W("بداية الخطة", "Plan start"), esc(fmtDate(D.settings.start))], [W("المدة", "Horizon"), esc(W(`${D.settings.weeks} أسابيع`, `${D.settings.weeks} weeks`))], [W("أيام العمل", "Working days"), esc(D.settings.days.map((d) => W(DAYS[d][0], DAYS[d][1])).join("، "))], [W("الزيارات اليومية", "Visits per day"), esc(D.settings.perDay)], [W("سياسة التكرار (يوم)", "Frequency policy (days)"), esc(PRI.map(([v, a, e]) => `${W(a, e)}: ${D.settings.freq[v]}`).join(" · "))]]) +
          `<table class="t" style="min-width:0;margin-top:12px"><tr><th>${esc(W("التاريخ", "Date"))}</th><th>${esc(W("اليوم", "Day"))}</th><th>${esc(W("الفرع", "Branch"))}</th><th>${esc(W("المنطقة", "Area"))}</th><th>${esc(W("الأولوية", "Priority"))}</th><th>${esc(W("تمت", "Done"))}</th><th>${esc(W("التوقيع", "Signature"))}</th></tr>${dates.map((d) => D.plan.filter((p) => p.date === d).map((p, i) => `<tr>${i === 0 ? `<td rowspan="${D.plan.filter((q) => q.date === d).length}">${esc(fmtDate(d))}</td><td rowspan="${D.plan.filter((q) => q.date === d).length}">${esc(W(DAYS[pD(d).getUTCDay()][0], DAYS[pD(d).getUTCDay()][1]))}</td>` : ""}<td>${esc(p.name)}</td><td>${esc(p.area)}</td><td>${priChip(p.priority)}</td><td>${p.done ? "✓" : "☐"}</td><td style="width:18%"></td></tr>`).join("")).join("")}</table>` +
          (D.unscheduled.length ? `<p><b>${esc(W("غير مجدولة", "Unscheduled"))}:</b> ${D.unscheduled.map((u) => esc(u.name)).join("، ")}</p>` : ""));
      });
      fillSettings(); resetB(null); drawB(); drawPlan();
    }
    return { title: L(tool("visits").t), html, after };
  }

  /* ---------- register ---------- */
  T.register({ id: "cooling", icon: "therm", t: { ar: "متابعة تبريد الأغذية بعد الطهي", en: "Cooling after cooking tracker" }, d: { ar: "قراءات الحرارة الداخلية مقابل مراحل التبريد التي تحددها من إجراءاتك، مع وقت الوصول بالاستكمال الخطي ومنحنى ونتيجة لكل مرحلة.", en: "Core temperature readings against the cooling stages from your own procedure, with interpolated reach times, a curve and a result per stage." } }, coolingPage);
  T.register({ id: "nutrition", icon: "calc", t: { ar: "حاسبة القيم الغذائية للوصفات", en: "Recipe nutrition calculator" }, d: { ar: "من أوزان المكونات وقيمها لكل 100 غ (تدخلها أنت) إلى المجموع ولكل 100 غ ولكل حصة، مع معامل الناتج بعد الطهي وجدول غذائي ثنائي اللغة.", en: "From ingredient weights and the per-100 g values you enter to totals, per 100 g and per serving, with a cooked-yield factor and a bilingual nutrition panel." } }, nutritionPage);
  T.register({ id: "label", icon: "clip", t: { ar: "فاحص بطاقة الغذاء", en: "Food label checker" }, d: { ar: "قائمة تحقق لعناصر بطاقة الغذاء المعبأ وفق Codex CXS 1-1985 مع صورة البطاقة ونسبة الامتثال والعناصر الناقصة وتقرير للطباعة.", en: "Checklist of prepackaged food label elements based on Codex CXS 1-1985, with a label photo, compliance %, missing items and a printable report." } }, labelPage);
  T.register({ id: "minutes", icon: "note", t: { ar: "محضر اجتماع الجودة", en: "Quality meeting minutes" }, d: { ar: "الحضور وجدول الأعمال والقرارات وجدول الإجراءات، مع ترحيل الإجراءات المفتوحة من الاجتماع السابق ومحضر رسمي بخانات التوقيع.", en: "Attendees, agenda, decisions and an action table, with carry-over of open actions from the previous meeting and formal minutes with signature lines." } }, minutesPage);
  T.register({ id: "visits", icon: "pin", t: { ar: "مخطط زيارات الفروع", en: "Branch visit planner" }, d: { ar: "وزّع زيارات الفروع حسب الأولوية وسياسة التكرار لديك، مع تجميع فروع المنطقة الواحدة في اليوم نفسه، وتقويم قابل للطباعة وربط بقائمة التفتيش.", en: "Spread branch visits by priority and your frequency policy, grouping branches of the same area on the same day, with a printable calendar linked to the inspection checklist." } }, visitsPage);
  // expose the maths for tests
  Object.assign(T, { coolPoints, coolCalc, reach, nutCalc, labelScore, planVisits });
})();
