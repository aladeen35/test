/* Three more toolkit tools: HACCP plan builder, quality KPI dashboard, microbial count (CFU) calculator.
   They plug into js/tools.js through TOOLS.register and share its helpers (TOOLS.h). */
(function () {
  "use strict";
  const T = window.TOOLS, A = window.APP, I = window.ICONS;
  const { printHtml, disclaimer, crumbsFor, kvTable, today, store, esc, L, t, $, $$, toast, download, uid, fmtDate, pageHead } = T.h;
  const W = (a, e) => (A.lang === "ar" ? a : e);
  const num = (n, d) => Number(n).toLocaleString(A.lang === "ar" ? "ar-SA-u-nu-latn" : "en-GB", { maximumFractionDigits: d == null ? 2 : d });

  /* =====================================================================
     1) HACCP plan builder
     ===================================================================== */
  const HZ = { B: ["بيولوجي", "Biological"], C: ["كيميائي", "Chemical"], P: ["فيزيائي", "Physical"], A: ["مسببات حساسية", "Allergen"] };
  // example templates: hazards are starting points to review, never final; critical limits are always left for the user
  const TPL = {
    chicken: { n: ["وجبة دجاج مطبوخ (مطبخ مركزي)", "Cooked chicken meal (central kitchen)"], use: ["تقدَّم ساخنة أو تُبرَّد وتُعاد للتسخين", "Served hot, or chilled and reheated"], steps: [
      ["استلام الدجاج النيء", "Receiving raw chicken", [["B", "وجود سالمونيلا/كامبيلوباكتر في الخام", "Salmonella / Campylobacter in raw chicken", 3, 3, "مورد معتمد، قياس حرارة الاستلام", "Approved supplier, receiving temperature check"], ["P", "أجسام غريبة (ريش، عظم)", "Foreign bodies (feathers, bone)", 2, 2, "فحص بصري عند الاستلام", "Visual check at receipt"]]],
      ["التخزين المبرد", "Chilled storage", [["B", "تكاثر بكتيري عند ارتفاع الحرارة", "Bacterial growth if temperature rises", 2, 3, "ضبط حرارة الثلاجة ومراقبتها", "Fridge temperature control and monitoring"]]],
      ["التحضير والتتبيل", "Preparation & marinating", [["B", "تلوث عرضي من الأدوات والأيدي", "Cross-contamination from tools and hands", 2, 3, "فصل الأدوات بالألوان، غسل الأيدي", "Colour-coded tools, handwashing"], ["A", "مسببات حساسية في التتبيلة (حليب، سمسم)", "Allergens in the marinade (milk, sesame)", 2, 3, "مصفوفة الحساسية ومراجعة الملصق", "Allergen matrix and label check"]]],
      ["الطهي", "Cooking", [["B", "بقاء الممرضات عند طهي غير كافٍ", "Pathogens survive under-cooking", 2, 3, "طهي بزمن وحرارة معتمدين", "Cooking to a validated time/temperature"]]],
      ["التبريد السريع", "Blast chilling", [["B", "إنبات الأبواغ (C. perfringens) عند تبريد بطيء", "Spore germination (C. perfringens) during slow cooling", 2, 3, "تبريد سريع بمراحل زمنية", "Rapid chilling in timed stages"]]],
      ["التقسيم والتعبئة", "Portioning & packing", [["B", "إعادة تلوث من الأيدي والأسطح", "Recontamination from hands and surfaces", 2, 2, "نظافة شخصية وتطهير الأسطح", "Personal hygiene, surface sanitising"], ["P", "أجسام غريبة من العبوات", "Foreign bodies from packaging", 1, 2, "فحص العبوات", "Packaging check"]]],
      ["التوزيع", "Dispatch", [["B", "ارتفاع الحرارة أثناء النقل", "Temperature rise during transport", 2, 3, "مركبات مبردة ومراقبة الحرارة", "Refrigerated vehicles with temperature checks"]]],
    ] },
    coffee: { n: ["مشروب قهوة مثلجة بالحليب", "Iced milk coffee"], use: ["يُحضَّر عند الطلب ويُستهلك خلال وقت قصير", "Made to order, consumed shortly after"], steps: [
      ["استلام الحليب", "Receiving milk", [["B", "ممرضات/فساد بسبب سوء حفظ الحرارة", "Pathogens / spoilage from temperature abuse", 2, 3, "قياس حرارة الاستلام وتاريخ الصلاحية", "Receiving temperature and date check"], ["C", "بقايا مضادات حيوية", "Antibiotic residues", 1, 2, "شهادة تحليل من المورد", "Supplier certificate of analysis"]]],
      ["تخزين الحليب مبردًا", "Chilled milk storage", [["B", "تكاثر بكتيري", "Bacterial growth", 2, 3, "ضبط حرارة الثلاجة", "Fridge temperature control"]]],
      ["تحضير الإسبريسو", "Brewing espresso", [["C", "بقايا مواد تنظيف الآلة", "Machine cleaning chemical residues", 1, 2, "شطف كامل بعد التنظيف", "Full rinse after cleaning"]]],
      ["إضافة الثلج", "Adding ice", [["B", "ثلج ملوث من الماء أو المغرفة", "Ice contaminated by water or scoop", 2, 3, "ماء مفلتر، مغرفة مخصصة، تنظيف آلة الثلج", "Filtered water, dedicated scoop, ice machine cleaning"]]],
      ["الخلط والنكهات", "Mixing & syrups", [["A", "حليب ومكسرات في النكهات", "Milk and nuts in syrups", 2, 3, "تعريف المسببات للعميل", "Allergen information for customers"]]],
      ["الإغلاق والتوصيل", "Sealing & delivery", [["B", "طول زمن التوصيل وارتفاع الحرارة", "Long delivery time, temperature rise", 2, 2, "حقائب معزولة وحد زمني للتوصيل", "Insulated bags, delivery time limit"]]],
    ] },
    sandwich: { n: ["ساندويتشات باردة جاهزة", "Ready-to-eat cold sandwiches"], use: ["تُعرض مبردة وتؤكل دون تسخين", "Displayed chilled, eaten without reheating"], steps: [
      ["استلام المكونات", "Receiving ingredients", [["B", "ليستيريا في اللحوم الباردة والأجبان", "Listeria in cooked meats and cheese", 2, 3, "مورد معتمد، حرارة الاستلام", "Approved supplier, receiving temperature"]]],
      ["التخزين المبرد", "Chilled storage", [["B", "تكاثر الليستيريا", "Listeria growth", 2, 3, "ضبط الحرارة وتدوير المخزون FEFO", "Temperature control, FEFO rotation"]]],
      ["غسل الخضار", "Washing vegetables", [["B", "ممرضات على الخضار الطازجة", "Pathogens on fresh produce", 2, 3, "غسل وتطهير بتركيز يُراقب", "Washing and sanitising at a monitored strength"]]],
      ["التقطيع والتجميع", "Slicing & assembly", [["B", "تلوث عرضي", "Cross-contamination", 2, 3, "فصل المناطق والأدوات", "Separate areas and tools"], ["A", "غلوتين، سمسم، بيض", "Gluten, sesame, egg", 2, 3, "مصفوفة الحساسية والملصق", "Allergen matrix and label"]]],
      ["العرض المبرد", "Chilled display", [["B", "تكاثر بكتيري بارتفاع حرارة العرض", "Bacterial growth if display warms", 2, 3, "مراقبة حرارة الثلاجة وعمر العرض", "Display temperature and shelf-life control"]]],
    ] },
  };
  const blankPlan = () => ({ id: uid(), product: "", desc: "", use: "", consumers: "", team: "", threshold: 6, steps: [], ccp: {} });
  const fromTpl = (k) => {
    const tp = TPL[k], p = blankPlan(); p.product = W(...tp.n); p.use = W(...tp.use);
    p.steps = tp.steps.map(([a, e, hz]) => ({ id: uid(), name: W(a, e), hazards: hz.map(([ty, ha, he, l, s, ca, ce]) => ({ id: uid(), type: ty, desc: W(ha, he), L: l, S: s, control: W(ca, ce), q: {} })) }));
    return p;
  };
  // classic Codex decision tree (CXC 1-1969); returns the next question key or a verdict
  const QS = {
    q1: [W("هل توجد تدابير تحكم لهذا الخطر (في هذه الخطوة أو لاحقًا)؟", "Do control measures exist for this hazard (at this or a later step)?")],
    q1a: [W("هل التحكم في هذه الخطوة ضروري للسلامة؟", "Is control at this step necessary for safety?")],
    q2: [W("هل صُممت هذه الخطوة خصيصًا لإزالة الخطر أو خفضه إلى مستوى مقبول؟", "Is this step specifically designed to eliminate or reduce the hazard to an acceptable level?")],
    q3: [W("هل يمكن أن يحدث التلوث بالخطر أو يزيد إلى مستوى غير مقبول؟", "Could contamination occur or increase to unacceptable levels?")],
    q4: [W("هل ستزيل خطوة لاحقة الخطر أو تخفضه إلى مستوى مقبول؟", "Will a later step eliminate the hazard or reduce it to an acceptable level?")],
  };
  function decide(q) {
    const path = [];
    const ask = (k) => { path.push(k); return q[k]; };
    let a = ask("q1"); if (!a) return { next: "q1", path };
    if (a === "n") { a = ask("q1a"); if (!a) return { next: "q1a", path }; return { verdict: a === "y" ? "modify" : "not", path }; }
    a = ask("q2"); if (!a) return { next: "q2", path }; if (a === "y") return { verdict: "ccp", path };
    a = ask("q3"); if (!a) return { next: "q3", path }; if (a === "n") return { verdict: "not", path };
    a = ask("q4"); if (!a) return { next: "q4", path }; return { verdict: a === "y" ? "not" : "ccp", path };
  }
  const VERD = { ccp: ["نقطة تحكم حرجة CCP", "Critical Control Point (CCP)", "bad"], not: ["ليست CCP — تُدار ببرنامج تمهيدي (PRP/OPRP)", "Not a CCP — managed by a PRP/OPRP", "ok"], modify: ["عدّل الخطوة أو العملية أو المنتج", "Modify the step, process or product", "warn"] };
  const sig = (p, h) => h.L * h.S >= p.threshold;
  const ccps = (p) => { const out = []; p.steps.forEach((s, si) => s.hazards.forEach((h) => { if (sig(p, h) && decide(h.q).verdict === "ccp") out.push({ s, si, h }); })); return out; };
  const PLAN_F = [["limit", "الحد الحرج", "Critical limit"], ["limitRef", "مرجع الحد (دراسة/تشريع/مواصفة)", "Limit reference (study / regulation / standard)"], ["monWhat", "المراقبة: ماذا؟", "Monitoring: what?"], ["monHow", "كيف؟", "How?"], ["monFreq", "متى/كم مرة؟", "When / how often?"], ["monWho", "من؟", "Who?"], ["corrective", "الإجراء التصحيحي", "Corrective action"], ["verification", "التحقق", "Verification"], ["records", "السجلات", "Records"]];

  function haccpPage() {
    const tool = T.list.find((x) => x.id === "haccp");
    const DK = "tool:haccp:draft", RK = "tool:haccp";
    let p = store.get(DK, null);
    if (!p) { p = fromTpl("chicken"); store.set(DK, p); } // keep ids stable across reloads
    let tab = "product";
    const save = () => store.set(DK, p);
    const tabs = [["product", W("1. المنتج والفريق", "1. Product & team")], ["flow", W("2. مخطط التدفق", "2. Flow diagram")], ["hazards", W("3. تحليل المخاطر", "3. Hazard analysis")], ["ccp", W("4. تحديد CCP", "4. CCP decision")], ["plan", W("5. خطة HACCP", "5. HACCP plan")]];
    const hzSel = (h) => `<select data-h="${h.id}" data-f="type" aria-label="${esc(W("نوع الخطر", "Hazard type"))}">${Object.entries(HZ).map(([k, v]) => `<option value="${k}" ${h.type === k ? "selected" : ""}>${esc(W(...v))}</option>`).join("")}</select>`;
    const lsSel = (h, f) => `<select data-h="${h.id}" data-f="${f}" aria-label="${f}" style="width:70px">${[1, 2, 3].map((n) => `<option ${h[f] == n ? "selected" : ""}>${n}</option>`).join("")}</select>`;
    const flowHtml = () => { const cc = ccps(p); let n = 0; const idx = {}; cc.forEach((c) => { if (!(c.s.id in idx)) idx[c.s.id] = ++n; });
      return `<div class="flow">${p.steps.map((s, i) => `<div class="flow-step ${s.id in idx ? "is-ccp" : ""}"><span class="fs-n">${i + 1}</span><span class="fs-t">${esc(s.name || "—")}</span>${s.id in idx ? `<span class="chip bad">CCP ${idx[s.id]}</span>` : ""}</div>${i < p.steps.length - 1 ? `<div class="flow-arrow" aria-hidden="true">↓</div>` : ""}`).join("") || `<div class="empty">${esc(W("أضف خطوات العملية.", "Add process steps."))}</div>`}</div>`; };
    const panels = {
      product: () => `<div class="form">
        ${[["product", "اسم المنتج", "Product name", 1], ["consumers", "المستهلك المستهدف (اذكر الفئات الحساسة)", "Intended consumers (note vulnerable groups)"], ["use", "الاستخدام المقصود", "Intended use"], ["team", "فريق HACCP (الاسم — الدور)", "HACCP team (name — role)"]].map(([k, a, e, req]) => `<div class="field"><label for="hp-${k}" class="${req ? "req" : ""}">${esc(W(a, e))}</label><input id="hp-${k}" type="text" data-p="${k}" value="${esc(p[k])}"></div>`).join("")}
        <div class="field full"><label for="hp-desc">${esc(W("وصف المنتج (المكونات، التعبئة، ظروف الحفظ، العمر التخزيني)", "Product description (ingredients, packaging, storage, shelf life)"))}</label><textarea id="hp-desc" data-p="desc" rows="3">${esc(p.desc)}</textarea></div></div>`,
      flow: () => `<div class="grid g2" style="align-items:start"><div><div id="stepList">${p.steps.map((s, i) => `<div class="row step-row" style="margin-bottom:8px"><span class="chip">${i + 1}</span><input type="text" data-s="${s.id}" data-f="name" value="${esc(s.name)}" style="flex:1;min-width:160px" aria-label="${esc(W("اسم الخطوة", "Step name"))} ${i + 1}"><button class="icon-btn" data-mv="${s.id}:-1" aria-label="${esc(W("أعلى", "Up"))}" style="width:36px;height:36px">↑</button><button class="icon-btn" data-mv="${s.id}:1" aria-label="${esc(W("أسفل", "Down"))}" style="width:36px;height:36px">↓</button><button class="icon-btn" data-rs="${s.id}" aria-label="${esc(t("del"))}" style="width:36px;height:36px">${I.trash}</button></div>`).join("")}</div>
        <button class="btn btn-ghost btn-sm" id="addStep">${I.plus}<span>${esc(W("أضف خطوة", "Add step"))}</span></button><p class="note">${esc(W("تحقق من المخطط بالمشي في الموقع قبل اعتماده.", "Confirm the diagram by walking the line before you approve it."))}</p></div>
        <div class="card">${flowHtml()}</div></div>`,
      hazards: () => `<p class="note" style="margin-top:0">${esc(W(`الاحتمالية × الشدة (1–3). الخطر «مهم» إذا كان الناتج ≥ ${p.threshold}. عدّل الحد وفق إجراء منشأتك:`, `Likelihood × severity (1–3). A hazard is "significant" when the product is ≥ ${p.threshold}. Adjust to your site procedure:`))} <input type="number" id="thr" min="1" max="9" value="${p.threshold}" style="width:70px;height:34px;display:inline-block" aria-label="threshold"></p>
        ${p.steps.map((s, i) => `<div class="card" style="margin-bottom:12px"><h3 style="font-size:16px">${i + 1}. ${esc(s.name || "—")}</h3>
          ${s.hazards.map((h) => `<div class="hz-row"><div class="row" style="gap:8px">${hzSel(h)}<input type="text" data-h="${h.id}" data-f="desc" value="${esc(h.desc)}" placeholder="${esc(W("وصف الخطر", "Hazard"))}" aria-label="${esc(W("وصف الخطر", "Hazard"))}" style="flex:2;min-width:180px"><span class="note" style="margin:0">L</span>${lsSel(h, "L")}<span class="note" style="margin:0">S</span>${lsSel(h, "S")}<span class="chip ${sig(p, h) ? "bad" : ""}" data-sig="${h.id}">${h.L * h.S} · ${esc(sig(p, h) ? W("مهم", "Significant") : W("غير مهم", "Not significant"))}</span><button class="icon-btn" data-rh="${h.id}" aria-label="${esc(t("del"))}" style="width:34px;height:34px">${I.trash}</button></div>
            <input type="text" data-h="${h.id}" data-f="control" value="${esc(h.control)}" placeholder="${esc(W("تدبير التحكم", "Control measure"))}" aria-label="${esc(W("تدبير التحكم", "Control measure"))}" style="margin-top:6px"></div>`).join("")}
          <button class="btn btn-ghost btn-sm" data-ah="${s.id}" style="margin-top:8px">${I.plus}<span>${esc(W("أضف خطرًا", "Add hazard"))}</span></button></div>`).join("") || `<div class="empty">${esc(W("أضف خطوات في مخطط التدفق أولًا.", "Add flow steps first."))}</div>`}`,
      ccp: () => { const list = []; p.steps.forEach((s, i) => s.hazards.forEach((h) => sig(p, h) && list.push({ s, i, h })));
        return `<p class="note" style="margin-top:0">${esc(W("شجرة القرار الكلاسيكية للدستور الغذائي (Codex CXC 1-1969). تظهر الأسئلة واحدًا تلو الآخر حسب إجاباتك.", "Classic Codex decision tree (CXC 1-1969). Questions appear one by one based on your answers."))}</p>
        ${list.map(({ s, i, h }) => { const d = decide(h.q); const v = d.verdict && VERD[d.verdict];
          return `<div class="card" style="margin-bottom:12px"><div class="row"><b>${i + 1}. ${esc(s.name)}</b><span class="chip">${esc(W(...HZ[h.type]))}</span><span style="color:var(--muted)">${esc(h.desc)}</span></div>
          <div class="dt">${d.path.map((k) => `<div class="dt-q"><span>${esc(QS[k][0])}</span><div class="seg" role="group" aria-label="${esc(QS[k][0])}">${[["y", W("نعم", "Yes")], ["n", W("لا", "No")]].map(([val, lab]) => `<button type="button" data-q="${h.id}:${k}" data-v="${val === "y" ? "y" : "n"}" aria-pressed="${h.q[k] === val}">${lab}</button>`).join("")}</div></div>`).join("")}</div>
          ${v ? `<span class="chip ${v[2]}" style="margin-top:10px">${esc(W(v[0], v[1]))}</span>` : ""}</div>`; }).join("") || `<div class="empty">${esc(W("لا توجد مخاطر مهمة بعد. راجع تحليل المخاطر.", "No significant hazards yet. Review the hazard analysis."))}</div>`}`; },
      plan: () => { const cc = ccps(p);
        return cc.length ? cc.map(({ s, si, h }, n) => { const r = p.ccp[h.id] || {}; const done = PLAN_F.filter(([k]) => (r[k] || "").trim()).length;
          return `<div class="card" style="margin-bottom:14px"><div class="row"><span class="chip bad">CCP ${n + 1}</span><b>${si + 1}. ${esc(s.name)}</b><span style="color:var(--muted)">${esc(h.desc)}</span><span class="spacer"></span><span class="chip ${done === PLAN_F.length ? "ok" : "warn"}">${done}/${PLAN_F.length}</span></div>
          <div class="form" style="margin-top:12px">${PLAN_F.map(([k, a, e]) => `<div class="field ${k === "corrective" || k === "limit" ? "full" : ""}"><label for="cp-${h.id}-${k}">${esc(W(a, e))}</label><input id="cp-${h.id}-${k}" type="text" data-c="${h.id}" data-f="${k}" value="${esc(r[k] || "")}"></div>`).join("")}</div></div>`; }).join("") + `<p class="note">${esc(W("لا تقترح الأداة حدودًا حرجة: خذها من دراسة تحقق أو تشريع أو مواصفة معتمدة واذكر المرجع.", "The tool never suggests critical limits: take them from a validation study, regulation or approved standard and cite it."))}</p>`
          : `<div class="empty">${esc(W("لا توجد نقاط تحكم حرجة بعد. أكمل شجرة القرار في الخطوة 4.", "No CCPs yet. Complete the decision tree in step 4."))}</div>`; },
    };
    const report = () => { const cc = ccps(p);
      return kvTable([[W("المنتج", "Product"), esc(p.product)], [W("الوصف", "Description"), esc(p.desc)], [W("الاستخدام المقصود", "Intended use"), esc(p.use)], [W("المستهلك", "Consumers"), esc(p.consumers)], [W("الفريق", "Team"), esc(p.team)]]) +
        `<h3>${esc(W("مخطط التدفق", "Flow diagram"))}</h3>${flowHtml()}` +
        `<h3>${esc(W("تحليل المخاطر", "Hazard analysis"))}</h3><table class="t" style="min-width:0"><tr><th>#</th><th>${esc(W("الخطوة", "Step"))}</th><th>${esc(W("النوع", "Type"))}</th><th>${esc(W("الخطر", "Hazard"))}</th><th>L×S</th><th>${esc(W("مهم", "Sig."))}</th><th>${esc(W("التحكم", "Control"))}</th><th>${esc(W("القرار", "Decision"))}</th></tr>${p.steps.flatMap((s, i) => s.hazards.map((h) => { const d = sig(p, h) ? decide(h.q).verdict : null; return `<tr><td>${i + 1}</td><td>${esc(s.name)}</td><td>${esc(W(...HZ[h.type]))}</td><td>${esc(h.desc)}</td><td>${h.L * h.S}</td><td>${sig(p, h) ? "✓" : "—"}</td><td>${esc(h.control)}</td><td>${d ? esc(W(VERD[d][0], VERD[d][1])) : "—"}</td></tr>`; })).join("")}</table>` +
        `<h3>${esc(W("خطة HACCP", "HACCP plan"))}</h3>${cc.length ? `<table class="t" style="min-width:0"><tr><th>CCP</th>${PLAN_F.map(([, a, e]) => `<th>${esc(W(a, e))}</th>`).join("")}</tr>${cc.map(({ s, h }, n) => { const r = p.ccp[h.id] || {}; return `<tr><td><b>CCP ${n + 1}</b><br>${esc(s.name)}<br><small>${esc(h.desc)}</small></td>${PLAN_F.map(([k]) => `<td>${esc(r[k] || "")}</td>`).join("")}</tr>`; }).join("")}</table>` : `<p>—</p>`}
        <table class="t" style="min-width:0;margin-top:18px"><tr><th>${esc(W("أعدّه", "Prepared by"))}</th><th>${esc(W("اعتمده", "Approved by"))}</th><th>${esc(W("تاريخ المراجعة", "Review date"))}</th></tr><tr><td style="height:46px"></td><td></td><td></td></tr></table>`; };
    return {
      title: L(tool.t),
      html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}<section class="sec"><div class="wrap">${disclaimer()}
        <div class="card" style="margin-top:18px"><div class="row"><label for="tplSel" class="lbl">${esc(W("ابدأ من مثال", "Start from an example"))}</label><select id="tplSel" style="width:auto;height:40px">${Object.entries(TPL).map(([k, v]) => `<option value="${k}">${esc(W(...v.n))}</option>`).join("")}</select><button class="btn btn-ghost btn-sm" id="tplLoad">${esc(W("تحميل المثال", "Load example"))}</button><button class="btn btn-ghost btn-sm" id="blank">${I.plus}<span>${esc(W("خطة فارغة", "Blank plan"))}</span></button><span class="spacer"></span><button class="btn btn-gold btn-sm" id="hSave">${I.check}<span>${esc(t("save"))}</span></button><button class="btn btn-ghost btn-sm" id="hPrint">${I.printer}<span>${esc(t("print"))}</span></button><button class="btn btn-ghost btn-sm" id="hJson">${I.download}<span>JSON</span></button></div>
        <p class="note" style="margin-bottom:0">${esc(W("الأمثلة نقطة بداية فقط: راجع كل خطر وتدبير تحكم مع فريقك.", "Examples are a starting point only: review every hazard and control with your team."))}</p></div>
        <div class="tabs" role="tablist" style="margin-top:22px">${tabs.map(([k, l]) => `<button role="tab" data-tab="${k}" aria-selected="${k === tab}">${esc(l)}</button>`).join("")}</div>
        <div id="hPanel"></div>
        <h2 style="font-size:22px;margin:34px 0 12px">${esc(W("الخطط المحفوظة", "Saved plans"))}</h2><div id="hList"></div></div></section>`,
      after() {
        const panel = $("#hPanel");
        const draw = () => { panel.innerHTML = panels[tab](); $$("[data-tab]").forEach((b) => b.setAttribute("aria-selected", b.dataset.tab === tab)); };
        const findH = (id) => { for (const s of p.steps) for (const h of s.hazards) if (h.id === id) return h; };
        $$("[data-tab]").forEach((b) => b.addEventListener("click", () => { tab = b.dataset.tab; draw(); }));
        panel.addEventListener("input", (e) => {
          const el = e.target;
          if (el.dataset.p) p[el.dataset.p] = el.value;
          else if (el.dataset.s) { p.steps.find((s) => s.id === el.dataset.s).name = el.value; const fl = $(".flow", panel); if (fl) fl.outerHTML = flowHtml(); }
          else if (el.dataset.c) { (p.ccp[el.dataset.c] = p.ccp[el.dataset.c] || {})[el.dataset.f] = el.value; }
          else if (el.dataset.h && el.tagName === "INPUT") findH(el.dataset.h)[el.dataset.f] = el.value;
          else if (el.id === "thr") { const v = +el.value; if (v >= 1 && v <= 9) { p.threshold = v; save(); draw(); $("#thr").focus(); return; } }
          save();
        });
        panel.addEventListener("change", (e) => { const el = e.target; if (el.dataset.h && el.tagName === "SELECT") { const h = findH(el.dataset.h); h[el.dataset.f] = el.dataset.f === "type" ? el.value : +el.value; save(); draw(); } });
        panel.addEventListener("click", (e) => {
          const b = e.target.closest("button"); if (!b) return;
          if (b.id === "addStep") { p.steps.push({ id: uid(), name: "", hazards: [] }); save(); draw(); const ins = $$("#stepList input", panel); ins[ins.length - 1].focus(); return; }
          if (b.dataset.mv) { const [id, d] = b.dataset.mv.split(":"); const i = p.steps.findIndex((s) => s.id === id), j = i + +d; if (j >= 0 && j < p.steps.length) { [p.steps[i], p.steps[j]] = [p.steps[j], p.steps[i]]; save(); draw(); } return; }
          if (b.dataset.rs) { p.steps = p.steps.filter((s) => s.id !== b.dataset.rs); save(); draw(); return; }
          if (b.dataset.ah) { p.steps.find((s) => s.id === b.dataset.ah).hazards.push({ id: uid(), type: "B", desc: "", L: 2, S: 2, control: "", q: {} }); save(); draw(); return; }
          if (b.dataset.rh) { p.steps.forEach((s) => (s.hazards = s.hazards.filter((h) => h.id !== b.dataset.rh))); save(); draw(); return; }
          if (b.dataset.q) { const [id, k] = b.dataset.q.split(":"); const h = findH(id); const keys = ["q1", "q1a", "q2", "q3", "q4"];
            h.q[k] = b.dataset.v; keys.slice(keys.indexOf(k) + 1).forEach((x) => delete h.q[x]); // later answers depend on this one
            save(); draw(); }
        });
        const drawList = () => { const all = store.get(RK, []); $("#hList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("المنتج", "Product"))}</th><th>${esc(W("الخطوات", "Steps"))}</th><th>CCP</th><th>${esc(W("حُفظ", "Saved"))}</th><th></th></tr></thead><tbody>${all.slice().reverse().map((r) => `<tr><td>${esc(r.product)}</td><td>${r.steps.length}</td><td>${ccps(r).length}</td><td>${esc(fmtDate(new Date(r.saved).toISOString()))}</td><td style="white-space:nowrap"><button class="icon-btn" style="width:34px;height:34px" data-load="${r.id}" aria-label="${esc(t("edit"))}">${I.note}</button> <button class="icon-btn" style="width:34px;height:34px" data-del="${r.id}" aria-label="${esc(t("del"))}">${I.trash}</button></td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`; };
        $("#hList").addEventListener("click", (e) => { const all = store.get(RK, []); const ld = e.target.closest("[data-load]"), dl = e.target.closest("[data-del]");
          if (ld) { p = JSON.parse(JSON.stringify(all.find((r) => r.id === ld.dataset.load))); save(); tab = "product"; draw(); A.scrollTo(0, true); }
          if (dl && confirm(t("confirmDel"))) { store.set(RK, all.filter((r) => r.id !== dl.dataset.del)); drawList(); toast(t("deleted")); } });
        $("#tplLoad").addEventListener("click", () => { if (!confirm(W("سيُستبدل المحتوى الحالي غير المحفوظ. متابعة؟", "This replaces the current unsaved draft. Continue?"))) return; p = fromTpl($("#tplSel").value); save(); tab = "flow"; draw(); toast(W("حُمّل المثال", "Example loaded")); });
        $("#blank").addEventListener("click", () => { if (!confirm(W("بدء خطة فارغة؟", "Start a blank plan?"))) return; p = blankPlan(); save(); tab = "product"; draw(); });
        $("#hSave").addEventListener("click", () => { if (!p.product.trim()) { tab = "product"; draw(); toast(W("أدخل اسم المنتج أولًا.", "Enter the product name first."), "bad"); $("#hp-product").focus(); return; } const all = store.get(RK, []); const rec = JSON.parse(JSON.stringify(p)); rec.saved = Date.now(); const i = all.findIndex((x) => x.id === rec.id); i >= 0 ? (all[i] = rec) : all.push(rec); if (store.set(RK, all)) { toast(t("saved")); drawList(); } });
        $("#hPrint").addEventListener("click", () => printHtml(`${L(tool.t)} — ${p.product}`, report()));
        $("#hJson").addEventListener("click", () => download(`haccp-${(p.product || "plan").replace(/\s+/g, "-")}.json`, JSON.stringify(p, null, 2), "application/json"));
        draw(); drawList();
      },
    };
  }

  /* =====================================================================
     2) Quality KPI dashboard — reads what the other tools stored
     ===================================================================== */
  const NCR_ST = [["open", "مفتوحة", "Open", "#e5645a"], ["progress", "قيد التنفيذ", "In progress", "#e6a03d"], ["closed", "أغلقها القسم", "Closed by dept", "#8f8f8f"], ["verified", "تحقق منها QC", "Verified by QC", "#53b9ad"]];
  const CAT = { hygiene: ["النظافة", "Hygiene"], temp: ["الحرارة", "Temperature"], pest: ["الآفات", "Pest"], storage: ["التخزين", "Storage"], docs: ["التوثيق", "Documentation"], allergen: ["الحساسية", "Allergen"], foreign: ["أجسام غريبة", "Foreign body"], supplier: ["الموردون", "Supplier"], equip: ["المعدات", "Equipment"], other: ["أخرى", "Other"] };
  function sampleData() {
    const d = (n) => { const x = new Date(); x.setDate(x.getDate() - n); return x.toISOString().slice(0, 10); };
    const insp = [62, 55, 48, 41, 34, 27, 20, 13, 6].map((n, i) => ({ date: d(n), site: ["فرع A", "فرع B", "فرع C"][i % 3], pct: [78, 82, 80, 85, 88, 84, 90, 92, 94][i] }));
    const cats = ["hygiene", "temp", "storage", "docs", "hygiene", "pest", "temp", "hygiene", "allergen", "docs", "storage", "hygiene"];
    const sts = ["verified", "verified", "closed", "verified", "progress", "open", "verified", "closed", "progress", "open", "verified", "open"];
    const ncr = cats.map((c, i) => ({ date: d(60 - i * 5), category: c, status: sts[i], dept: ["فرع A", "فرع B", "فرع C"][i % 3], due: d(50 - i * 5 - (i % 4 === 0 ? 6 : -4)) }));
    const temp = []; ["ثلاجة 1", "ثلاجة 2", "مجمد 1", "حفظ ساخن"].forEach((u, k) => { for (let i = 0; i < 20; i++) temp.push({ equip: u, at: d(40 - i * 2) + "T08:00", deviation: (i * (k + 3)) % 11 === 0 }); });
    const risk = [20, 16, 12, 9, 6, 4, 15, 10].map((score) => ({ score }));
    const rca = [{ effective: "yes" }, { effective: "yes" }, { effective: "no" }, { effective: "yes" }, { effective: "pending" }];
    return { insp, ncr, temp, risk, rca };
  }
  function kpiPage() {
    const tool = T.list.find((x) => x.id === "kpi");
    const real = { insp: store.get("tool:inspection", []), ncr: store.get("tool:ncr", []), temp: store.get("tool:temp", []), risk: store.get("tool:risk", []), rca: store.get("tool:rca", []) };
    const hasReal = Object.values(real).some((a) => a.length);
    let sample = !hasReal, days = 0;
    const tip = (label, value) => `data-tip="${esc(label)}" data-tipv="${esc(value)}"`;
    const inRange = (dateStr) => { if (!days) return true; const t0 = Date.now() - days * 864e5; return new Date((dateStr || "").slice(0, 10)).getTime() >= t0; };

    const lineChart = (pts) => {
      if (pts.length < 2) return `<div class="empty">${esc(W("يلزم تفتيشان محفوظان على الأقل.", "Needs at least two saved inspections."))}</div>`;
      const Wd = 640, H = 230, pl = 40, pr = 16, pt = 16, pb = 34, lo = Math.max(0, Math.floor((Math.min(...pts.map((p) => p.v)) - 5) / 10) * 10), hi = 100;
      const x = (i) => pl + (i * (Wd - pl - pr)) / (pts.length - 1), y = (v) => pt + (1 - (v - lo) / (hi - lo)) * (H - pt - pb);
      const ticks = []; for (let v = lo; v <= hi; v += lo <= 40 ? 20 : 10) ticks.push(v);
      const last = pts[pts.length - 1];
      return `<svg class="kchart" viewBox="0 0 ${Wd} ${H}" role="img" aria-label="${esc(W("اتجاه نسبة الامتثال", "Compliance trend"))}">
        ${ticks.map((v) => `<line x1="${pl}" x2="${Wd - pr}" y1="${y(v)}" y2="${y(v)}" class="grid-l"/><text x="${pl - 8}" y="${y(v) + 4}" class="ax" text-anchor="end">${v}%</text>`).join("")}
        <path d="M${x(0)},${y(pts[0].v)} ${pts.map((p, i) => `L${x(i)},${y(p.v)}`).join(" ")} L${x(pts.length - 1)},${H - pb} L${x(0)},${H - pb} Z" class="area"/>
        <polyline points="${pts.map((p, i) => `${x(i)},${y(p.v)}`).join(" ")}" class="ln"/>
        ${pts.map((p, i) => `<circle cx="${x(i)}" cy="${y(p.v)}" r="${i === pts.length - 1 ? 6 : 4}" class="pt ${i === pts.length - 1 ? "end" : ""}"/><circle cx="${x(i)}" cy="${y(p.v)}" r="16" class="hit" ${tip(`${fmtDate(p.date)} · ${p.site || ""}`, p.v + "%")}/>`).join("")}
        <text x="${x(pts.length - 1)}" y="${y(last.v) - 12}" class="lbl-v" text-anchor="end">${last.v}%</text>
        <text x="${x(0)}" y="${H - 10}" class="ax">${esc(fmtDate(pts[0].date))}</text><text x="${x(pts.length - 1)}" y="${H - 10}" class="ax" text-anchor="end">${esc(fmtDate(last.date))}</text></svg>`;
    };
    const hbars = (rows, color) => { // rows: [label, value, colorOverride?]
      if (!rows.length) return `<div class="empty">${esc(t("none"))}</div>`;
      const max = Math.max(...rows.map((r) => r[1]), 1);
      return `<div class="hbars">${rows.map(([lab, v, c]) => `<div class="hb" ${tip(lab, v)}><span class="hb-l">${esc(lab)}</span><span class="hb-track"><i style="width:${Math.max(2, (v / max) * 100)}%;background:${c || color}"></i></span><span class="hb-v">${v}</span></div>`).join("")}</div>`;
    };
    const tile = (lab, val, sub, state) => `<div class="fact ktile"><span class="kt-l">${esc(lab)}</span><b>${val}</b>${sub ? `<span class="chip ${state || ""}">${sub}</span>` : ""}</div>`;

    function render() {
      const D = sample ? sampleData() : real;
      const insp = D.insp.filter((r) => inRange(r.date) && r.pct != null).sort((a, b) => (a.date < b.date ? -1 : 1));
      const ncr = D.ncr.filter((r) => inRange(r.date)), temp = D.temp.filter((r) => inRange(r.at));
      const avg = insp.length ? Math.round(insp.reduce((s, r) => s + r.pct, 0) / insp.length) : null;
      const half = Math.floor(insp.length / 2), prev = half ? insp.slice(0, half) : [], cur = half ? insp.slice(half) : [];
      const trend = prev.length && cur.length ? Math.round(cur.reduce((s, r) => s + r.pct, 0) / cur.length - prev.reduce((s, r) => s + r.pct, 0) / prev.length) : null;
      const open = ncr.filter((r) => r.status !== "verified"), overdue = open.filter((r) => r.due && r.due < today());
      const devRate = temp.length ? Math.round((temp.filter((r) => r.deviation).length / temp.length) * 1000) / 10 : null;
      const highRisk = D.risk.filter((r) => r.score >= 10).length;
      const rcaDone = D.rca.filter((r) => r.effective === "yes" || r.effective === "no"), eff = rcaDone.length ? Math.round((rcaDone.filter((r) => r.effective === "yes").length / rcaDone.length) * 100) : null;
      const catRows = Object.entries(ncr.reduce((m, r) => ((m[r.category || "other"] = (m[r.category || "other"] || 0) + 1), m), {})).sort((a, b) => b[1] - a[1]).slice(0, 6).map(([k, v]) => [W(...(CAT[k] || CAT.other)), v]);
      const deptRows = Object.entries(ncr.reduce((m, r) => ((m[r.dept || "—"] = (m[r.dept || "—"] || 0) + 1), m), {})).sort((a, b) => b[1] - a[1]).slice(0, 5);
      const unitRows = Object.entries(temp.reduce((m, r) => { const o = (m[r.equip] = m[r.equip] || [0, 0]); o[0]++; if (r.deviation) o[1]++; return m; }, {})).map(([u, [n, dv]]) => [u, Math.round((dv / n) * 100)]).sort((a, b) => b[1] - a[1]).slice(0, 6);
      const stRows = NCR_ST.map(([k, a, e, c]) => [W(a, e), ncr.filter((r) => r.status === k).length, c]);
      $("#kBody").innerHTML = `
        ${sample ? `<div class="disclaimer" style="margin-bottom:16px">${I.alert}<div><b>${esc(W("بيانات مثال", "Sample data"))}</b> — ${esc(W("هذه أرقام توضيحية وليست بياناتك. استخدم الأدوات (التفتيش، NCR، سجل الحرارة…) لتظهر أرقامك الحقيقية هنا.", "These are illustrative figures, not yours. Use the tools (inspection, NCR, temperature log…) and your real numbers appear here."))}</div></div>` : ""}
        <div class="ktiles">
          ${tile(W("متوسط الامتثال", "Avg compliance"), avg == null ? "—" : avg + "%", trend == null ? "" : (trend >= 0 ? "▲ " : "▼ ") + Math.abs(trend) + W(" نقطة", " pts"), trend == null ? "" : trend >= 0 ? "ok" : "bad")}
          ${tile(W("NCR مفتوحة", "Open NCRs"), open.length, overdue.length ? overdue.length + W(" متأخرة", " overdue") : W("لا متأخرات", "none overdue"), overdue.length ? "bad" : "ok")}
          ${tile(W("انحرافات الحرارة", "Temp deviations"), devRate == null ? "—" : devRate + "%", temp.length ? temp.length + W(" قراءة", " readings") : "", "")}
          ${tile(W("مخاطر مرتفعة/حرجة", "High/critical risks"), highRisk, D.risk.length ? D.risk.length + W(" في السجل", " in register") : "", highRisk ? "warn" : "")}
          ${tile(W("فاعلية CAPA", "CAPA effectiveness"), eff == null ? "—" : eff + "%", rcaDone.length ? rcaDone.length + W(" تم التحقق", " verified") : "", eff == null ? "" : eff >= 80 ? "ok" : "warn")}
        </div>
        <div class="kgrid">
          <div class="card kc-wide"><h3>${esc(W("اتجاه نسبة الامتثال في التفتيش", "Inspection compliance trend"))}</h3>${lineChart(insp.map((r) => ({ v: r.pct, date: r.date, site: r.site })))}</div>
          <div class="card"><h3>${esc(W("حالة تقارير NCR", "NCR status"))}</h3>${hbars(stRows)}</div>
          <div class="card"><h3>${esc(W("NCR حسب الفئة", "NCRs by category"))}</h3>${hbars(catRows, "#ddb03f")}</div>
          <div class="card"><h3>${esc(W("NCR حسب القسم/الفرع", "NCRs by department"))}</h3>${hbars(deptRows, "#ddb03f")}</div>
          <div class="card"><h3>${esc(W("نسبة الانحراف لكل جهاز", "Deviation rate by unit (%)"))}</h3>${hbars(unitRows, "#ddb03f")}</div>
        </div>
        <details class="faq" style="margin-top:16px"><summary>${esc(W("عرض البيانات كجدول", "View data as a table"))}</summary><div class="table-wrap" style="margin-bottom:16px"><table class="t"><tr><th>${esc(W("المؤشر", "Measure"))}</th><th>${esc(W("القيمة", "Value"))}</th></tr>
          ${insp.map((r) => `<tr><td>${esc(W("تفتيش", "Inspection"))} ${esc(fmtDate(r.date))} · ${esc(r.site || "")}</td><td>${r.pct}%</td></tr>`).join("")}
          ${stRows.map(([l, v]) => `<tr><td>NCR · ${esc(l)}</td><td>${v}</td></tr>`).join("")}${unitRows.map(([l, v]) => `<tr><td>${esc(l)}</td><td>${v}%</td></tr>`).join("")}</table></div></details>
        <p class="note">${esc(W("المعادلات: متوسط الامتثال = متوسط نسب التفتيشات المحفوظة · نسبة الانحراف = القراءات خارج الحدود ÷ كل القراءات · فاعلية CAPA = «فعّال» ÷ الحالات التي تم التحقق منها.", "Formulas: avg compliance = mean of saved inspection scores · deviation rate = out-of-limit readings ÷ all readings · CAPA effectiveness = \"effective\" ÷ cases verified."))}</p>`;
    }
    return {
      title: L(tool.t),
      html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}<section class="sec"><div class="wrap">
        <div class="row" style="margin-bottom:16px"><div class="seg" role="group" aria-label="${esc(W("الفترة", "Period"))}">${[[0, W("الكل", "All")], [30, W("30 يومًا", "30 days")], [90, W("90 يومًا", "90 days")]].map(([v, l]) => `<button type="button" data-days="${v}" data-v="na" aria-pressed="${v === 0}">${l}</button>`).join("")}</div>
          <span class="spacer"></span>${hasReal ? `<label class="row" style="gap:6px;font-size:14px;color:var(--muted)"><input type="checkbox" id="kSample"> ${esc(W("عرض بيانات مثال", "Show sample data"))}</label>` : ""}</div>
        <div id="kBody"></div><div class="ktip" id="kTip" role="status" aria-live="polite" hidden></div></div></section>`,
      after() {
        render();
        $$("[data-days]").forEach((b) => b.addEventListener("click", () => { days = +b.dataset.days; $$("[data-days]").forEach((x) => x.setAttribute("aria-pressed", x === b)); render(); }));
        const cb = $("#kSample"); cb && cb.addEventListener("change", () => { sample = cb.checked; render(); });
        const tipEl = $("#kTip"), body = $("#kBody");
        const show = (el, ev) => { tipEl.innerHTML = `<b>${esc(el.dataset.tipv)}</b><span>${esc(el.dataset.tip)}</span>`; tipEl.hidden = false; const r = (ev && ev.clientX != null) ? { x: ev.clientX, y: ev.clientY } : (() => { const b = el.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top }; })(); tipEl.style.left = Math.min(window.innerWidth - 180, Math.max(8, r.x + 12)) + "px"; tipEl.style.top = r.y - 48 + "px"; };
        body.addEventListener("pointermove", (e) => { const el = e.target.closest("[data-tip]"); if (el) show(el, e); else tipEl.hidden = true; });
        body.addEventListener("pointerleave", () => (tipEl.hidden = true));
      },
    };
  }

  /* =====================================================================
     3) Microbial count (CFU) calculator — ISO 7218 weighted mean
     ===================================================================== */
  const SUP = (k) => String(k).replace(/\d/g, (d) => "⁰¹²³⁴⁵⁶⁷⁸⁹"[d]);
  const MEDIA = ["PCA — Total plate count", "VRBG — Enterobacteriaceae", "VRBA — Coliforms", "TBX — E. coli", "CHROMagar", "DRBC / DG18 — Yeasts & moulds", "Baird-Parker — S. aureus", "MYP — B. cereus", "Other"];
  const sig2 = (n) => { if (!(n > 0)) return { txt: "0", man: 0, exp: 0 }; const e = Math.floor(Math.log10(n)); let m = Math.round((n / 10 ** e) * 10) / 10; let ex = e; if (m >= 10) { m = 1; ex++; } return { man: m, exp: ex, val: m * 10 ** ex }; };
  const sci = (n) => { const s = sig2(n); return s.exp < 3 ? num(s.val, 0) : `${num(s.man, 1)} × 10<sup>${s.exp}</sup>`; };
  function cfuCalc(c) {
    // c: { V, min, max, plates: [{ dil: k (10^-k), count|null }] }
    const plates = c.plates.filter((p) => p.count !== "" && p.count != null && !isNaN(p.count)).map((p) => ({ k: +p.dil, n: +p.count }));
    if (!plates.length) return { error: W("أدخل عدد المستعمرات لطبق واحد على الأقل.", "Enter colony counts for at least one plate.") };
    if (!(c.V > 0)) return { error: W("أدخل حجم الزرع.", "Enter the inoculum volume.") };
    const ks = [...new Set(plates.map((p) => p.k))].sort((a, b) => a - b); // least diluted first
    const inRange = plates.filter((p) => p.n >= c.min && p.n <= c.max);
    const okK = ks.filter((k) => inRange.some((p) => p.k === k));
    if (okK.length) {
      const k1 = okK[0], k2 = ks.includes(k1 + 1) ? k1 + 1 : null;
      const use = plates.filter((p) => (p.k === k1 || p.k === k2) && p.n <= c.max);
      const n1 = use.filter((p) => p.k === k1).length, n2 = use.filter((p) => p.k === k2).length, sum = use.reduce((s, p) => s + p.n, 0), d = 10 ** -k1;
      const N = sum / (c.V * (n1 + 0.1 * n2) * d);
      return { N, kind: "count", formula: `N = ΣC / (V × (n₁ + 0.1·n₂) × d) = ${sum} / (${c.V} × (${n1} + 0.1×${n2}) × 10⁻${SUP(k1)})` };
    }
    const k0 = ks[0], low = plates.filter((p) => p.k === k0);
    if (low.every((p) => p.n > c.max)) { const kh = ks[ks.length - 1]; return { N: c.max / (c.V * 10 ** -kh), kind: "gt", formula: `N > ${c.max} / (${c.V} × 10⁻${SUP(kh)})` }; }
    const sum = low.reduce((s, p) => s + p.n, 0);
    if (sum === 0) return { N: 1 / (c.V * 10 ** -k0), kind: "lt", formula: `N < 1 / (${c.V} × 10⁻${SUP(k0)})` };
    return { N: sum / (c.V * low.length * 10 ** -k0), kind: "est", formula: `Nₑ = ${sum} / (${c.V} × ${low.length} × 10⁻${SUP(k0)})` };
  }
  function cfuPage() {
    const tool = T.list.find((x) => x.id === "cfu");
    const RK = "tool:cfu";
    let plates = [{ dil: 1, count: "" }, { dil: 1, count: "" }, { dil: 2, count: "" }, { dil: 2, count: "" }];
    const unitOpts = [["g", "CFU/g"], ["ml", "CFU/ml"], ["cm2", "CFU/cm²"]];
    return {
      title: L(tool.t),
      html: `${pageHead(L(tool.t), L(tool.d), crumbsFor(tool))}<section class="sec"><div class="wrap">${disclaimer()}
        <div class="grid g2" style="margin-top:18px;align-items:start">
          <form class="card" id="cform" novalidate><div class="form">
            <div class="field"><label for="c-id" class="req">${esc(W("رقم العينة", "Sample ID"))}</label><input id="c-id" type="text"><span class="err" id="c-id-e"></span></div>
            <div class="field"><label for="c-prod">${esc(W("المنتج / السطح", "Product / surface"))}</label><input id="c-prod" type="text"></div>
            <div class="field"><label for="c-med">${esc(W("الوسط", "Medium"))}</label><select id="c-med">${MEDIA.map((m) => `<option>${esc(m)}</option>`).join("")}</select></div>
            <div class="field"><label for="c-inc">${esc(W("التحضين", "Incubation"))}</label><input id="c-inc" type="text" placeholder="30°C / 72h"></div>
            <div class="field"><label for="c-meth">${esc(W("طريقة الزرع", "Plating method"))}</label><select id="c-meth"><option value="1">${esc(W("صب الأطباق — 1 مل", "Pour plate — 1 ml"))}</option><option value="0.1">${esc(W("الفرد السطحي — 0.1 مل", "Spread plate — 0.1 ml"))}</option></select></div>
            <div class="field"><label for="c-unit">${esc(W("الوحدة", "Unit"))}</label><select id="c-unit">${unitOpts.map(([v, l]) => `<option value="${v}">${l}</option>`).join("")}</select></div>
            <div class="field"><label for="c-min">${esc(W("أقل عدد يُحتسب", "Min countable"))}</label><input id="c-min" type="number" value="10" min="1"></div>
            <div class="field"><label for="c-max">${esc(W("أعلى عدد يُحتسب", "Max countable"))}</label><input id="c-max" type="number" value="300" min="1"><span class="hint">${esc(W("حسب طريقتك (غالبًا 150 للخمائر والفطريات)", "Per your method (often 150 for yeasts & moulds)"))}</span></div>
            <div class="full"><span class="lbl">${esc(W("الأطباق", "Plates"))}</span><div id="plates" style="margin-top:8px"></div><button type="button" class="btn btn-ghost btn-sm" id="addPlate" style="margin-top:8px">${I.plus}<span>${esc(W("أضف طبقًا", "Add plate"))}</span></button></div>
            <div class="field"><label for="c-lim">${esc(W("الحد المسموح (اختياري)", "Specification limit (optional)"))}</label><input id="c-lim" type="number" min="0" step="any" placeholder="${esc(W("من المواصفة المعتمدة", "From your approved spec"))}"></div>
            <div class="field"><label for="c-ref">${esc(W("مرجع الحد", "Limit reference"))}</label><input id="c-ref" type="text"></div>
            <div class="full row"><button class="btn btn-gold" type="submit">${I.calc}<span>${esc(W("احسب واحفظ", "Calculate & save"))}</span></button><button class="btn btn-ghost" type="button" id="cCalc">${esc(W("احسب فقط", "Calculate only"))}</button></div>
          </div></form>
          <div class="grid">
            <div class="card" id="cRes" aria-live="polite"><h3>${esc(W("النتيجة", "Result"))}</h3><p class="note" style="margin:0">${esc(W("أدخل عدد المستعمرات ثم اضغط احسب.", "Enter colony counts, then press calculate."))}</p></div>
            <div class="card"><h3>${esc(W("طريقة الحساب", "How it's calculated"))}</h3>
              <p style="font-family:var(--font-en);direction:ltr;text-align:start;color:var(--text);font-size:16.5px">N = ΣC / (V × (n₁ + 0.1·n₂) × d)</p>
              <ul class="ticks"><li>${esc(W("ΣC مجموع المستعمرات في أطباق تخفيفين متتاليين يقع فيهما عدد ضمن المدى.", "ΣC: colonies on all retained plates from two successive dilutions."))}</li><li>${esc(W("V حجم الزرع بالمل، n₁ و n₂ عدد الأطباق في التخفيف الأول والثاني، d معامل التخفيف الأول المحتسب.", "V: inoculum in ml; n₁, n₂: plates at the first and second dilution; d: dilution factor of the first retained dilution."))}</li><li>${esc(W("أقل من الحد الأدنى: عدد تقديري Nₑ. صفر مستعمرات: النتيجة «أقل من» 1/(V·d). كل الأطباق مزدحمة: «أكبر من».", "Below the minimum: estimated count Nₑ. Zero colonies: \"less than\" 1/(V·d). All plates crowded: \"greater than\"."))}</li><li>${esc(W("التقريب إلى رقمين معنويين (ISO 7218).", "Rounded to two significant figures (ISO 7218)."))}</li></ul></div>
          </div></div>
        <h2 style="font-size:22px;margin:34px 0 12px">${esc(t("records"))}</h2><div id="cList"></div></div></section>`,
      after() {
        const drawPlates = () => { $("#plates").innerHTML = plates.map((p, i) => `<div class="row" style="margin-bottom:6px"><span class="chip">${i + 1}</span><label class="sr-only" for="pd${i}">dilution</label><select id="pd${i}" data-pd="${i}" style="width:auto;height:40px" dir="ltr">${[0, 1, 2, 3, 4, 5, 6, 7].map((k) => `<option value="${k}" ${p.dil == k ? "selected" : ""}>10⁻${SUP(k)}${k === 0 ? " (" + W("مباشر", "neat") + ")" : ""}</option>`).join("")}</select><label class="sr-only" for="pc${i}">colonies</label><input id="pc${i}" data-pc="${i}" type="number" min="0" inputmode="numeric" value="${p.count}" placeholder="${esc(W("عدد المستعمرات", "Colonies"))}" style="flex:1;min-width:120px;height:40px"><button type="button" class="icon-btn" data-rp="${i}" aria-label="${esc(t("del"))}" style="width:36px;height:36px">${I.trash}</button></div>`).join(""); };
        $("#plates").addEventListener("input", (e) => { const el = e.target; if (el.dataset.pc != null) plates[+el.dataset.pc].count = el.value === "" ? "" : +el.value; });
        $("#plates").addEventListener("change", (e) => { const el = e.target; if (el.dataset.pd != null) plates[+el.dataset.pd].dil = +el.value; });
        $("#plates").addEventListener("click", (e) => { const b = e.target.closest("[data-rp]"); if (b && plates.length > 1) { plates.splice(+b.dataset.rp, 1); drawPlates(); } });
        $("#addPlate").addEventListener("click", () => { const last = plates[plates.length - 1]; plates.push({ dil: last ? last.dil : 1, count: "" }); drawPlates(); $(`#pc${plates.length - 1}`).focus(); });
        const unitLab = () => unitOpts.find((u) => u[0] === $("#c-unit").value)[1];
        const compute = () => {
          const c = { V: +$("#c-meth").value, min: +$("#c-min").value || 10, max: +$("#c-max").value || 300, plates };
          const r = cfuCalc(c);
          if (r.error) { $("#cRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3><p class="err">${esc(r.error)}</p>`; return null; }
          const s = sig2(r.N), lim = $("#c-lim").value === "" ? null : +$("#c-lim").value;
          const pre = { gt: "> ", lt: "< ", est: "~ ", count: "" }[r.kind];
          const pass = lim == null ? null : r.kind === "gt" ? false : s.val <= lim;
          const kindTxt = { count: "", est: W("عدد تقديري (أقل من الحد الأدنى للعد)", "Estimated count (below the minimum countable)"), lt: W("لم تُرصد مستعمرات", "No colonies detected"), gt: W("كل الأطباق فوق الحد الأعلى — أعد بتخفيف أعلى", "All plates above the maximum — repeat with higher dilutions") }[r.kind];
          $("#cRes").innerHTML = `<h3>${esc(W("النتيجة", "Result"))}</h3><div class="cfu-big" dir="ltr">${pre}${sci(s.val)} <small>${unitLab()}</small></div>
            <p class="note" dir="ltr" style="text-align:start;margin:6px 0">log₁₀ = ${s.val > 0 ? num(Math.log10(s.val), 2) : "—"} · ${esc(r.formula)}</p>
            ${kindTxt ? `<span class="chip warn">${esc(kindTxt)}</span> ` : ""}${pass == null ? "" : `<span class="chip ${pass ? "ok" : "bad"}">${esc(pass ? W("ضمن الحد", "Within limit") : W("يتجاوز الحد", "Exceeds limit"))} (${num(lim, 0)})</span>`}`;
          return { r, s, pre, pass, lim };
        };
        const drawList = () => { const all = store.get(RK, []); $("#cList").innerHTML = all.length ? `<div class="table-wrap"><table class="t"><thead><tr><th>${esc(W("العينة", "Sample"))}</th><th>${esc(W("المنتج", "Product"))}</th><th>${esc(W("الوسط", "Medium"))}</th><th>${esc(W("النتيجة", "Result"))}</th><th>${esc(W("الحد", "Limit"))}</th><th>${esc(W("التاريخ", "Date"))}</th><th></th></tr></thead><tbody>${all.slice().reverse().map((x) => `<tr><td>${esc(x.id2)}</td><td>${esc(x.prod)}</td><td>${esc(x.med)}</td><td dir="ltr"><b>${x.pre}${sci(x.val)}</b> ${esc(x.unit)}</td><td>${x.pass == null ? "—" : `<span class="chip ${x.pass ? "ok" : "bad"}">${esc(x.pass ? W("ضمن", "Pass") : W("يتجاوز", "Fail"))}</span>`}</td><td>${esc(fmtDate(x.date))}</td><td style="white-space:nowrap"><button class="icon-btn" style="width:34px;height:34px" data-pr="${x.id}" aria-label="${esc(t("print"))}">${I.printer}</button> <button class="icon-btn" style="width:34px;height:34px" data-del="${x.id}" aria-label="${esc(t("del"))}">${I.trash}</button></td></tr>`).join("")}</tbody></table></div>` : `<div class="empty">${esc(t("none"))}</div>`; };
        $("#cList").addEventListener("click", (e) => { const all = store.get(RK, []); const pr = e.target.closest("[data-pr]"), dl = e.target.closest("[data-del]");
          if (pr) { const x = all.find((y) => y.id === pr.dataset.pr); printHtml(`${L(tool.t)} — ${x.id2}`, kvTable([[W("العينة", "Sample"), esc(x.id2)], [W("المنتج", "Product"), esc(x.prod)], [W("الوسط", "Medium"), esc(x.med)], [W("التحضين", "Incubation"), esc(x.inc)], [W("الأطباق", "Plates"), x.plates.map((p) => `10⁻${SUP(p.dil)}: ${p.count}`).join(" · ")], [W("النتيجة", "Result"), `<b>${x.pre}${sci(x.val)}</b> ${esc(x.unit)}`], [W("المعادلة", "Formula"), esc(x.formula)], [W("الحد", "Limit"), x.lim == null ? "—" : `${num(x.lim, 0)} (${esc(x.ref || "")}) — ${x.pass ? W("ضمن الحد", "within") : W("يتجاوز الحد", "exceeds")}`], [W("التاريخ", "Date"), esc(fmtDate(x.date))]])); }
          if (dl && confirm(t("confirmDel"))) { store.set(RK, all.filter((y) => y.id !== dl.dataset.del)); drawList(); toast(t("deleted")); } });
        $("#cCalc").addEventListener("click", compute);
        $("#cform").addEventListener("submit", (e) => {
          e.preventDefault(); const idEl = $("#c-id"), bad = !idEl.value.trim();
          idEl.setAttribute("aria-invalid", bad); $("#c-id-e").textContent = bad ? t("required") : ""; if (bad) { idEl.focus(); return; }
          const out = compute(); if (!out) return;
          const all = store.get(RK, []); all.push({ id: uid(), id2: idEl.value.trim(), prod: $("#c-prod").value.trim(), med: $("#c-med").value, inc: $("#c-inc").value.trim(), unit: unitLab(), plates: plates.map((p) => ({ ...p })), val: out.s.val, pre: out.pre, kind: out.r.kind, formula: out.r.formula, lim: out.lim, ref: $("#c-ref").value.trim(), pass: out.pass, date: today() });
          if (store.set(RK, all)) { toast(t("saved")); drawList(); }
        });
        drawPlates(); drawList();
      },
    };
  }

  /* ---------- register ---------- */
  const at = (id) => T.list.findIndex((x) => x.id === id) + 1;
  T.register({ id: "haccp", icon: "shield", t: { ar: "مولّد خطة HACCP", en: "HACCP plan builder" }, d: { ar: "من وصف المنتج ومخطط التدفق إلى تحليل المخاطر وشجرة القرار وجدول خطة HACCP جاهز للطباعة.", en: "From product description and flow diagram to hazard analysis, decision tree and a printable HACCP plan table." } }, haccpPage, at("inspection"));
  T.register({ id: "cfu", icon: "flask", t: { ar: "حاسبة العدّ الميكروبي CFU", en: "Microbial count (CFU) calculator" }, d: { ar: "عدد المستعمرات والتخفيفات ← CFU/g أو CFU/ml بمعادلة ISO 7218، مع المقارنة بالحد وسجل للعينات.", en: "Colonies and dilutions → CFU/g or CFU/ml with the ISO 7218 formula, limit check and a sample log." } }, cfuPage, at("dilution"));
  T.register({ id: "kpi", icon: "chart", t: { ar: "لوحة مؤشرات الجودة KPI", en: "Quality KPI dashboard" }, d: { ar: "تجمع بيانات أدواتك: اتجاه الامتثال، تقارير NCR المفتوحة والمتأخرة، انحرافات الحرارة، المخاطر وفاعلية CAPA.", en: "Pulls your tool data together: compliance trend, open and overdue NCRs, temperature deviations, risks and CAPA effectiveness." } }, kpiPage);
  // expose the CFU maths for tests
  T.cfuCalc = cfuCalc; T.sig2 = sig2;
})();
