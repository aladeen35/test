/* نظام البشرى لإدارة الشركة — الصفحات */
(function(){
"use strict";
const D = window.BOS_DATA;
const U = window.BOS_UI;
const {$, $$, esc, fmtDate, fmtDT, money, avatar, empName, statusBadge, toast, modal, formData, userOptions} = U;
const S = () => BOS.S;
const me = () => BOS.me();
const go = h => { location.hash = h; };
const need = (mod, act) => { if(!BOS.can(me(), mod, act||"view")) throw new Error("لا تملك صلاحية الوصول إلى هذه الصفحة — راجع مدير النظام."); };
const CLS_BADGE = {1:"", 2:"info", 3:"warn", 4:"bad"};
const clsBadge = c => `<span class="badge ${CLS_BADGE[c]||""}">${esc(D.CLEARANCE[c]||c)}</span>`;
const typeName = t => (D.TYPES[t]||{}).name || t;
const typeIcon = t => (D.TYPES[t]||{}).icon || "📄";
const whoLabel = w => w==="manager" ? "المدير المباشر" : w==="creator" ? "منشئ الطلب" : ((BOS.posByKey(w)||D.POSITIONS.find(p=>p.key===w)||{}).title || w);
const empty = t => `<div class="empty">${esc(t)}</div>`;
const head = (title, sub, actions) => `<div class="page-head"><div><h1>${esc(title)}</h1>${sub?`<div class="sub">${sub}</div>`:""}</div><div class="actions">${actions||""}</div></div>`;
const kpi = (lbl, val, hint, cls) => `<div class="card kpi ${cls||""}"><div class="lbl">${esc(lbl)}</div><div class="val">${val}</div>${hint?`<div class="hint">${hint}</div>`:""}</div>`;
const overdue = r => { const st = BOS.currentStep(r); return st && st.dueAt && new Date(st.dueAt) < new Date() && ["in_review","executing","info_requested"].includes(r.status); };
const open = r => ["in_review","executing","returned","info_requested"].includes(r.status);

function reqRow(r){
  const st = BOS.currentStep(r);
  return `<tr class="link" data-go="#/request/${r.id}"><td class="mono">${esc(r.no)}</td><td>${typeIcon(r.type)} ${esc(r.title)}</td><td>${empName(r.creatorId)}</td>
    <td>${statusBadge(r.status)} ${overdue(r)?'<span class="badge bad">متأخر</span>':""}</td>
    <td>${st && open(r) ? `${esc(st.label)}<div class="muted small">${empName(st.assigneeId)}</div>` : "—"}</td><td class="small">${fmtDate(r.createdAt)}</td></tr>`;
}
function reqTable(list, emptyText){
  if(!list.length) return empty(emptyText || "لا توجد طلبات");
  return `<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>الطلب</th><th>المنشئ</th><th>الحالة</th><th>المرحلة الحالية</th><th>التاريخ</th></tr></thead><tbody>${list.map(reqRow).join("")}</tbody></table></div>`;
}
const bindRows = root => $$("[data-go]", root).forEach(el=>el.onclick = e => { if(e.target.closest("button,a,input,select")) return; go(el.dataset.go); });

/* =================== الرئيسية (القسم 13) =================== */
function home(){
  const u = me(); const q = U.myQueue();
  const mine = S().requests.filter(r=>r.creatorId===u.id);
  const notes = S().notifications.filter(n=>n.userId===u.id).slice(0,6);
  const types = Object.entries(D.TYPES).filter(([k,t])=>!t.system);
  const docs = S().documents.filter(d=>BOS.canSeeDoc(u,d)).length;
  const e = u; const leaveLeft = Number(S().settings.leaveDays||30) - Number(e.leaveUsed||0);
  return {title:"الرئيسية", html: `
    ${head("أهلاً، " + u.name, esc(BOS.posTitle(u.positionId)) + " · " + esc((BOS.dept(u.deptId)||{}).name||""), BOS.can(u,"requests","create")?'<button class="btn primary" data-new>＋ طلب جديد</button>':"")}
    <div class="grid g4">
      ${kpi("ينتظر موافقتي", q.length, q.filter(overdue).length ? `<span style="color:var(--bad)">${q.filter(overdue).length} متأخر</span>` : "لا شيء متأخر", q.length?"warn":"")}
      ${kpi("طلباتي المفتوحة", mine.filter(open).length, mine.filter(r=>r.status==="returned"||r.status==="info_requested").length + " تحتاج إجراءً مني")}
      ${kpi("الملفات المتاحة لي", docs, "حسب المنصب ومستوى السرية")}
      ${kpi("رصيد الإجازات", leaveLeft + " يوم", "المستخدم: " + (e.leaveUsed||0))}
    </div>${window.BOS_VIEWS_HR ? BOS_VIEWS_HR.homeTop() : ""}
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><div class="card-head"><h2>مهامي اليوم — ينتظر موافقتي</h2><a href="#/approvals" class="small">الكل</a></div>${reqTable(q.slice(0,6),"لا توجد مهام بانتظارك 🎉")}</div>
      <div class="card"><div class="card-head"><h2>طلباتي</h2><a href="#/requests" class="small">الكل</a></div>${reqTable(mine.slice(0,6),"لم تنشئ طلبات بعد")}</div>
    </div>
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><div class="card-head"><h2>إنشاء طلب سريع</h2></div><div class="pick-grid">${types.map(([k,t])=>`<a class="btn" href="#/new/${k}" style="justify-content:flex-start">${t.icon} ${esc(t.name)}</a>`).join("")}</div></div>
      <div class="card"><div class="card-head"><h2>إشعاراتي</h2><a href="#/notifications" class="small">الكل</a></div>${notes.length ? notes.map(noteItem).join("") : empty("لا توجد إشعارات")}</div>
    </div>${window.BOS_VIEWS_OPS ? BOS_VIEWS_OPS.homeExtra() : ""}${window.BOS_VIEWS_HR ? BOS_VIEWS_HR.homeExtra() : ""}`,
    bind: root => { bindRows(root); const b=$("[data-new]",root); if(b) b.onclick = newRequestPicker; bindNotes(root); if(window.BOS_VIEWS_HR) BOS_VIEWS_HR.bindHome(root); }};
}
function noteItem(n){ return `<div class="list-item ${n.read?"":"unread"}" data-note="${n.id}" style="cursor:pointer"><span>${n.kind==="task"?"📌":n.kind==="ok"?"✅":n.kind==="bad"?"⛔":n.kind==="warn"?"↩️":"🔔"}</span><div class="grow"><div style="${n.read?"":"font-weight:700"}">${esc(n.text)}</div><div class="muted small">${fmtDT(n.at)}</div></div></div>`; }
function bindNotes(root){ $$("[data-note]",root).forEach(el=>el.onclick=()=>{ const n = S().notifications.find(x=>x.id===el.dataset.note); if(n){ n.read=true; BOS.save(); if(n.link){ U.refresh(); go(n.link); } else U.refresh(); } }); }
function newRequestPicker(){
  const types = Object.entries(D.TYPES).filter(([k,t])=>!t.system);
  const bg = modal("اختر نوع الطلب", `<div class="pick-grid">${types.map(([k,t])=>`<button class="btn" data-t="${k}" style="justify-content:flex-start">${t.icon} ${esc(t.name)}</button>`).join("")}</div>`, []);
  $$("[data-t]",bg).forEach(b=>b.onclick=()=>{ bg.remove(); go("#/new/"+b.dataset.t); });
}

/* =================== لوحة المدير العام (القسم 6.1) =================== */
function dashboard(){
  need("dashboard");
  const u = me(); const s = S(); const cur = s.settings.currency;
  const reqs = s.requests.filter(r=>BOS.canSeeRequest(u,r));
  const openR = reqs.filter(open);
  const late = openR.filter(overdue);
  const inv = s.invoices;
  const outstanding = inv.filter(i=>!["draft","cancelled"].includes(i.status)).reduce((a,i)=>a + BOS.totals(i.items,i.discount,i.taxRate).total - BOS.invoicePaid(i), 0);
  const overdueInv = inv.filter(i=>/overdue/.test(BOS.invoiceState(i)));
  const overdueVal = overdueInv.reduce((a,i)=>a + BOS.totals(i.items,i.discount,i.taxRate).total - BOS.invoicePaid(i), 0);
  const collected = inv.reduce((a,i)=>a+BOS.invoicePaid(i),0);
  const pendingFin = openR.filter(r=>["purchase","expense","invoice"].includes(r.type));
  const closed = reqs.filter(r=>r.status==="closed" && r.closedAt);
  const cycle = closed.length ? closed.reduce((a,r)=>a + (new Date(r.closedAt)-new Date(r.createdAt)),0)/closed.length/36e5 : 0;
  const incidents = openR.filter(r=>r.type==="incident");
  const complaints = openR.filter(r=>r.type==="complaint");
  const releases = reqs.filter(r=>r.type==="release");
  const soon = new Date(Date.now()+45*864e5).toISOString().slice(0,10);
  const expiring = s.documents.filter(d=>d.expires && d.expires <= soon).concat([]);
  const contracts = reqs.filter(r=>r.type==="contract" && r.data.end && r.data.end <= soon && r.status==="closed");
  const queue = U.myQueue();
  // الاختناقات: المراحل المفتوحة حسب قسم صاحبها
  const bn = {};
  openR.forEach(r=>{ const st = BOS.currentStep(r); const e = st && BOS.byId(st.assigneeId); const k = e ? (BOS.dept(e.deptId)||{}).name : "غير مسند"; bn[k] = bn[k] || {n:0, late:0}; bn[k].n++; if(overdue(r)) bn[k].late++; });
  const bnRows = Object.entries(bn).sort((a,b)=>b[1].n-a[1].n);
  const maxBn = Math.max(1, ...bnRows.map(x=>x[1].n));
  const byType = {}; reqs.forEach(r=>{ byType[r.type] = (byType[r.type]||0)+1; });
  const recent = s.audit.slice(-10).reverse();
  const emps = s.employees.filter(BOS.active);
  const newCust = s.customers.filter(c=>c.createdAt > new Date(Date.now()-30*864e5).toISOString());
  return {title:"لوحة المدير العام", html: `
    ${head("لوحة المدير العام", "نظرة شاملة على الشركة · " + fmtDT(BOS.now()), '<a class="btn" href="#/audit">سجل القرارات</a><button class="btn primary" onclick="location.hash=\'#/approvals\'">ينتظر موافقتي ('+queue.length+')</button>')}
    <div class="grid g4">
      ${kpi("الفواتير المستحقة", money(outstanding,cur), inv.filter(i=>i.status!=="draft").length + " فاتورة صادرة")}
      ${kpi("المتأخر تحصيله", money(overdueVal,cur), overdueInv.length + " فاتورة متأخرة", overdueVal?"bad":"ok")}
      ${kpi("المحصّل", money(collected,cur), "إجمالي الإيصالات", "ok")}
      ${kpi("طلبات مالية معلقة", pendingFin.length, money(pendingFin.reduce((a,r)=>a+(r.amount||0),0),cur), pendingFin.length?"warn":"")}
      ${kpi("طلبات مفتوحة", openR.length, `<span style="color:var(--bad)">${late.length} متأخر</span> · ${openR.length?Math.round(late.length/openR.length*100):0}%`, late.length?"warn":"")}
      ${kpi("متوسط زمن دورة الموافقة", cycle ? cycle.toFixed(1) + " ساعة" : "—", closed.length + " طلب مغلق")}
      ${kpi("حوادث أمنية مفتوحة", incidents.length, "مقيدة الوصول", incidents.length?"bad":"ok")}
      ${kpi("شكاوى العملاء المفتوحة", complaints.length, newCust.length + " عميل جديد خلال 30 يوماً", complaints.length?"warn":"")}
    </div>
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><div class="card-head"><h2>ينتظر موافقتك</h2><a class="small" href="#/approvals">الكل</a></div>${reqTable(queue.slice(0,6),"لا يوجد ما ينتظر موافقتك")}</div>
      <div class="card"><div class="card-head"><h2>نقاط التعطيل حسب القسم</h2></div>
        ${bnRows.length ? bnRows.map(([k,v])=>`<div style="margin-bottom:10px"><div class="row small"><b>${esc(k)}</b><span class="spacer"></span>${v.n} مفتوح ${v.late?`<span class="badge bad">${v.late} متأخر</span>`:""}</div><div class="bar"><i style="width:${v.n/maxBn*100}%;${v.late?"background:var(--bad)":""}"></i></div></div>`).join("") : empty("لا توجد اختناقات")}
      </div>
    </div>
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><div class="card-head"><h2>المعاملات المفتوحة في الشركة</h2><a class="small" href="#/requests">كل الطلبات</a></div>${reqTable(openR.slice(0,8),"لا توجد معاملات مفتوحة")}</div>
      <div class="card"><div class="card-head"><h2>آخر القرارات والتغييرات</h2></div>
        ${recent.map(a=>`<div class="list-item"><span class="mono small muted">#${a.seq}</span><div class="grow"><b>${esc(a.action)}</b> <span class="muted small">— ${esc(a.actorName)}</span><div class="small muted">${esc(a.details)}</div></div><span class="small muted">${fmtDT(a.at)}</span></div>`).join("")}
      </div>
    </div>
    <div class="grid g3" style="margin-top:14px">
      <div class="card"><h2 style="margin-bottom:10px">الجودة والإطلاق</h2><dl class="kv"><dt>طلبات إطلاق</dt><dd>${releases.length}</dd><dt>اجتازت بوابة الجودة</dt><dd>${releases.filter(r=>r.steps.some(s=>s.who==="qm"&&s.status==="approved")).length}</dd><dt>مرفوضة</dt><dd>${releases.filter(r=>r.status==="rejected").length}</dd></dl></div>
      <div class="card"><h2 style="margin-bottom:10px">الموظفون والأقسام</h2><dl class="kv"><dt>موظفون نشطون</dt><dd>${emps.length}</dd><dt>في إجازة</dt><dd>${emps.filter(e=>e.onLeave).length}</dd><dt>موقوفون</dt><dd>${s.employees.length-emps.length}</dd><dt>الأقسام</dt><dd>${s.departments.length}</dd></dl></div>
      <div class="card"><h2 style="margin-bottom:10px">العقود والمستندات المنتهية قريباً</h2>${expiring.length+contracts.length ? expiring.map(d=>`<div class="small">📄 <a href="#/doc/${d.id}">${esc(d.title)}</a> — ${fmtDate(d.expires)}</div>`).join("") + contracts.map(r=>`<div class="small">📜 <a href="#/request/${r.id}">${esc(r.data.subject)}</a> — ${fmtDate(r.data.end)}</div>`).join("") : empty("لا شيء خلال 45 يوماً")}</div>
    </div>
    <div class="card" style="margin-top:14px"><h2 style="margin-bottom:10px">الطلبات حسب النوع</h2>
      <div class="grid g4">${Object.entries(byType).map(([t,n])=>`<div class="row small">${typeIcon(t)} ${esc(typeName(t))}<span class="spacer"></span><b>${n}</b></div>`).join("") || empty("لا توجد بيانات بعد")}</div></div>
    ${window.BOS_VIEWS_OPS ? BOS_VIEWS_OPS.dashExtra() : ""}${window.BOS_VIEWS_HR ? BOS_VIEWS_HR.dashExtra() : ""}${window.BOS_VIEWS_SEC ? BOS_VIEWS_SEC.dashExtra() : ""}`,
    bind: bindRows};
}

/* =================== الهيكل التنظيمي (القسم 4 و5) =================== */
function org(){
  need("org");
  const s = S(); const u = me(); const manage = BOS.can(u,"people","manage") || BOS.isTop(u);
  const holders = p => s.employees.filter(e=>e.positionId===p.id && BOS.active(e));
  const posNode = p => {
    const hs = holders(p);
    const kids = s.positions.filter(x=>x.reportsTo===p.key);
    return `<li><span class="node ${hs.length?"":"vacant"} ${p.level<=2?"lead":""}" ${manage?`data-pos="${p.id}" style="cursor:pointer"`:""}>
      <span><span class="t">${esc(p.title)}</span><br><span class="p">${hs.length ? hs.map(e=>esc(e.name)+(e.onLeave?" (إجازة)":"")).join("، ") : "شاغر"} · ${esc((BOS.dept(p.deptId)||{}).name||"")}</span></span></span>
      ${kids.length?`<ul>${kids.map(posNode).join("")}</ul>`:""}</li>`;
  };
  const roots = s.positions.filter(p=>!p.reportsTo);
  const deptNode = d => { const kids = s.departments.filter(x=>x.parentId===d.id); const ps = s.positions.filter(p=>p.deptId===d.id);
    return `<li><span class="node"><span><span class="t">${esc(d.name)}</span><br><span class="p">${ps.map(p=>esc(p.title)).join("، ")||"لا مناصب"}</span></span></span>${kids.length?`<ul>${kids.map(deptNode).join("")}</ul>`:""}</li>`; };
  const types = Object.keys(s.policies);
  return {title:"الهيكل التنظيمي", html: `
    ${head("الهيكل التنظيمي", "خدمة العملاء تتبع تنظيمياً لمدير الجودة لضمان استقلال قياس رضا العميل عن فريق الإنتاج", manage?'<button class="btn" id="add-dep">＋ قسم</button><button class="btn primary" id="add-pos">＋ منصب</button>':"")}
    <div class="tabs"><button class="on" data-tab="pos">التسلسل الوظيفي</button><button data-tab="dep">الأقسام</button><button data-tab="flow">مخطط المسؤوليات</button></div>
    <div data-pane="pos" class="card tree"><ul>${roots.map(posNode).join("")}</ul>${manage?'<p class="muted small">اضغط على أي منصب لتعديل تسلسله وصلاحياته.</p>':""}</div>
    <div data-pane="dep" class="card tree hidden"><ul>${s.departments.filter(d=>!d.parentId).map(deptNode).join("")}</ul></div>
    <div data-pane="flow" class="card hidden">
      <p class="small muted">يوضح لكل نوع معاملة: من يرفع الطلب، من يراجعه، من يعتمد، من ينفذ، ومن يغلق — مطبقاً على موظف محدد.</p>
      <div class="grid g2"><div class="field"><label class="f">نوع المعاملة</label><select class="input" id="fl-type">${types.map(t=>`<option value="${t}">${typeIcon(t)} ${esc(typeName(t))}</option>`).join("")}</select></div>
      <div class="field"><label class="f">منشئ الطلب</label><select class="input" id="fl-user">${userOptions(u.id)}</select></div></div>
      <label class="check"><input type="checkbox" id="fl-big"> مبلغ يتجاوز حد المدير العام / تفعيل كل الشروط</label>
      <div id="fl-out" style="margin-top:12px"></div>
    </div>`,
    bind: root => {
      $$("[data-tab]",root).forEach(b=>b.onclick=()=>{ $$("[data-tab]",root).forEach(x=>x.classList.toggle("on",x===b)); $$("[data-pane]",root).forEach(p=>p.classList.toggle("hidden",p.dataset.pane!==b.dataset.tab)); });
      $$("[data-pos]",root).forEach(n=>n.onclick=()=>positionEditor(BOS.pos(n.dataset.pos)));
      if($("#add-pos",root)) $("#add-pos",root).onclick = () => positionEditor(null);
      if($("#add-dep",root)) $("#add-dep",root).onclick = deptEditor;
      const draw = () => {
        const t = $("#fl-type",root).value, cu = $("#fl-user",root).value, big = $("#fl-big",root).checked;
        const data = {}; if(big){ const f = (D.TYPES[t]||{}).amount; if(f) data[f] = Number(S().settings.gmThreshold||0)+1; (D.TYPES[t].fields||[]).filter(x=>x.t==="check").forEach(x=>data[x.k]=true); }
        const saved = S().session.userId; // المعاينة لا تغير شيئاً
        const steps = BOS.buildRoute(t, data, cu);
        $("#fl-out",root).innerHTML = routeHorizontal(steps, cu);
        S().session.userId = saved;
      };
      ["#fl-type","#fl-user","#fl-big"].forEach(sel=>$(sel,root).onchange = draw); draw();
    }};
}
function routeHorizontal(steps, creatorId){
  return `<div class="route-h"><span class="chip"><span class="muted small">يرفع الطلب</span><b>${empName(creatorId)}</b></span>` +
    steps.filter(s=>s.status!=="skipped").map(s=>`<span class="arrow">←</span><span class="chip" title="${esc(s.notes.join(" · "))}"><span class="muted small">${esc(D.STAGES[s.stage])}: ${esc(s.label)}</span><b>${empName(s.assigneeId)}</b>${s.notes.length?'<span class="badge warn">ⓘ</span>':""}</span>`).join("") +
    `</div>` + (steps.some(s=>s.notes.length) ? `<ul class="small muted" style="margin:8px 0 0">${steps.flatMap(s=>s.notes.map(n=>`<li>${esc(s.label)}: ${esc(n)}</li>`)).join("")}</ul>` : "") +
    (steps.some(s=>s.status==="skipped") ? `<div class="small muted" style="margin-top:6px">مراحل لا تنطبق: ${steps.filter(s=>s.status==="skipped").map(s=>esc(s.label)).join("، ")}</div>` : "");
}
function permMatrix(perms){
  return `<div class="table-wrap"><table><thead><tr><th>الوحدة</th>${D.ACTIONS.map(a=>`<th style="font-size:.66rem">${a[1]}</th>`).join("")}</tr></thead><tbody>
    ${D.MODULES.map(m=>`<tr><td class="small">${m.icon} ${esc(m.name)}</td>${D.ACTIONS.map(a=>`<td><input type="checkbox" data-pm="${m.key}:${a[0]}" ${(perms[m.key]||[]).includes(a[0])?"checked":""}></td>`).join("")}</tr>`).join("")}</tbody></table></div>`;
}
const readMatrix = root => { const o = {}; $$("[data-pm]",root).forEach(c=>{ if(!c.checked) return; const [m,a] = c.dataset.pm.split(":"); (o[m]=o[m]||[]).push(a); }); return o; };
function positionEditor(p){
  const s = S(); const isNew = !p;
  p = p || {title:"", deptId:me().deptId, reportsTo:"gm", level:4, scope:"dept", clearance:2, mfa:false, perms:BOS.clone(BOS.posByKey("staff")?BOS.posByKey("staff").perms:{})};
  const bg = modal(isNew?"منصب جديد":"تعديل منصب: " + p.title, `
    <div class="grid g2"><div class="field"><label class="f">المسمى الوظيفي</label><input class="input" name="title" value="${esc(p.title)}"></div>
    <div class="field"><label class="f">القسم</label><select class="input" name="deptId">${s.departments.map(d=>`<option value="${d.id}" ${d.id===p.deptId?"selected":""}>${esc(d.name)}</option>`).join("")}</select></div>
    <div class="field"><label class="f">يتبع (المنصب الأعلى)</label><select class="input" name="reportsTo" ${p.key==="owner"?"disabled":""}><option value="">— لا يوجد —</option>${s.positions.filter(x=>x.id!==p.id).map(x=>`<option value="${x.key}" ${x.key===p.reportsTo?"selected":""}>${esc(x.title)}</option>`).join("")}</select></div>
    <div class="field"><label class="f">المستوى الإداري</label><input class="input" type="number" name="level" min="0" max="9" value="${p.level}"></div>
    <div class="field"><label class="f">نطاق الرؤية</label><select class="input" name="scope">${Object.entries(D.SCOPES).map(([k,v])=>`<option value="${k}" ${k===p.scope?"selected":""}>${v}</option>`).join("")}</select></div>
    <div class="field"><label class="f">أعلى مستوى سرية</label><select class="input" name="clearance">${Object.entries(D.CLEARANCE).map(([k,v])=>`<option value="${k}" ${Number(k)===p.clearance?"selected":""}>${v}</option>`).join("")}</select></div></div>
    <label class="check"><input type="checkbox" name="mfa" ${p.mfa?"checked":""}> يتطلب مصادقة متعددة العوامل</label>
    <h3 style="margin:12px 0 8px">الصلاحيات</h3>${permMatrix(p.perms||{})}`,
    [{label:"حفظ", cls:"primary", onClick:bg=>{
      const f = formData(bg); if(!f.title) throw new Error("المسمى إلزامي");
      if(["gm","owner"].includes(p.key) && !BOS.isTop(me())) throw new Error("لا يعدل هذا المنصب إلا المدير العام");
      const perms = readMatrix(bg);
      const before = isNew ? null : JSON.stringify(p.perms);
      Object.assign(p, {title:f.title, deptId:f.deptId, level:Number(f.level), scope:f.scope, clearance:Number(f.clearance), mfa:f.mfa, perms});
      if(p.key!=="owner") p.reportsTo = f.reportsTo || null;
      if(isNew){ p.id = BOS.uid("pos"); p.key = "p" + Date.now().toString(36); s.positions.push(p); BOS.audit("إنشاء منصب","position",p.id,p.title); }
      else BOS.audit("تعديل منصب","position",p.id,p.title + (before!==JSON.stringify(perms)?" — تغيير صلاحيات":""));
      BOS.save(); toast("تم الحفظ","ok"); U.route();
    }}], true);
}
function deptEditor(){
  const s = S();
  modal("قسم جديد", `<div class="field"><label class="f">اسم القسم</label><input class="input" name="name"></div>
    <div class="field"><label class="f">يتبع</label><select class="input" name="parentId">${s.departments.map(d=>`<option value="${d.id}">${esc(d.name)}</option>`).join("")}</select></div>`,
    [{label:"إضافة", cls:"primary", onClick:bg=>{ const f = formData(bg); if(!f.name) throw new Error("الاسم إلزامي");
      const d = {id:BOS.uid("dep"), key:"d"+Date.now().toString(36), name:f.name, parentId:f.parentId}; s.departments.push(d);
      BOS.audit("إنشاء قسم","department",d.id,d.name); BOS.save(); U.route(); }}]);
}

/* =================== الموظفون (القسم 4.2 و6.2) =================== */
function people(){
  need("people");
  const s = S(); const u = me(); const manage = BOS.can(u,"people","create");
  const list = s.employees.slice().sort((a,b)=>(BOS.pos(a.positionId).level)-(BOS.pos(b.positionId).level));
  return {title:"الموظفون", html: `
    ${head("الموظفون والموارد البشرية", list.filter(BOS.active).length + " نشط · " + (list.length-list.filter(BOS.active).length) + " موقوف", manage?'<button class="btn primary" id="add">＋ دعوة / إنشاء موظف</button>':"")}
    <div class="card"><div class="row" style="margin-bottom:12px"><input class="input" id="q" placeholder="بحث بالاسم أو المنصب أو القسم" style="max-width:340px"></div>
    <div class="table-wrap"><table><thead><tr><th>الموظف</th><th>المنصب</th><th>القسم</th><th>المدير المباشر</th><th>النطاق</th><th>الحالة</th></tr></thead><tbody>
    ${list.map(e=>`<tr class="link" data-go="#/person/${e.id}" data-s="${esc(e.name+" "+BOS.posTitle(e.positionId)+" "+((BOS.dept(e.deptId)||{}).name||""))}"><td><div class="row">${avatar(e)}<span><b>${esc(e.name)}</b><div class="muted small mono" dir="ltr" style="text-align:end">${esc(e.mailAddr||e.email||"")}</div></span></div></td>
      <td>${esc(BOS.posTitle(e.positionId))}</td><td>${esc((BOS.dept(e.deptId)||{}).name||"")}</td><td>${e.managerId?empName(e.managerId):"—"}</td><td class="small">${esc(D.SCOPES[BOS.scopeOf(e)])}</td>
      <td>${BOS.active(e) ? (e.onLeave?'<span class="badge warn">في إجازة</span>':'<span class="badge ok">نشط</span>') : '<span class="badge bad">موقوف</span>'}</td></tr>`).join("")}
    </tbody></table></div></div>`,
    bind: root => { bindRows(root); if($("#add",root)) $("#add",root).onclick = () => employeeEditor(null);
      $("#q",root).oninput = e => { const q = e.target.value.trim(); $$("[data-s]",root).forEach(r=>r.classList.toggle("hidden", q && !r.dataset.s.includes(q))); }; }};
}
function employeeEditor(e){
  const s = S(); const isNew = !e;
  e = e || {name:"", email:"", phone:"", positionId:(BOS.posByKey("staff")||s.positions[s.positions.length-1]).id, managerId:"", scope:"", delegateId:"", validFrom:BOS.now().slice(0,10), validTo:"", hireDate:BOS.now().slice(0,10)};
  const bg = modal(isNew?"دعوة موظف جديد":"تعديل: " + e.name, `
    <div class="grid g2">
      <div class="field"><label class="f">الاسم الكامل *</label><input class="input" name="name" value="${esc(e.name)}"></div>
      <div class="field"><label class="f">البريد</label><input class="input" name="email" type="email" value="${esc(e.email)}" dir="ltr"></div>
      <div class="field"><label class="f">الهاتف</label><input class="input" name="phone" value="${esc(e.phone)}" dir="ltr"></div>
      <div class="field"><label class="f">المنصب / المسمى الوظيفي *</label><select class="input" name="positionId">${s.positions.map(p=>`<option value="${p.id}" ${p.id===e.positionId?"selected":""}>${esc(p.title)}</option>`).join("")}</select></div>
      <div class="field"><label class="f">القسم</label><select class="input" name="deptId"><option value="">حسب المنصب</option>${s.departments.map(d=>`<option value="${d.id}" ${d.id===e.deptId?"selected":""}>${esc(d.name)}</option>`).join("")}</select></div>
      <div class="field"><label class="f">المدير المباشر</label><select class="input" name="managerId"><option value="">تلقائي حسب التسلسل</option>${userOptions(e.managerId, x=>x.id!==e.id)}</select></div>
      <div class="field"><label class="f">نطاق الرؤية</label><select class="input" name="scope"><option value="">حسب المنصب</option>${Object.entries(D.SCOPES).map(([k,v])=>`<option value="${k}" ${k===e.scope?"selected":""}>${v}</option>`).join("")}</select></div>
      <div class="field"><label class="f">البديل أثناء الإجازة</label><select class="input" name="delegateId"><option value="">—</option>${userOptions(e.delegateId, x=>x.id!==e.id)}</select></div>
      <div class="field"><label class="f">بداية الصلاحية</label><input class="input" type="date" name="validFrom" value="${esc(e.validFrom)}"></div>
      <div class="field"><label class="f">انتهاء الصلاحية (اختياري)</label><input class="input" type="date" name="validTo" value="${esc(e.validTo)}"></div>
    </div>
    <div id="pv" class="note"></div>`,
    [{label:isNew?"إنشاء وإرسال الدعوة":"حفظ", cls:"primary", onClick:bg=>{
      const f = formData(bg); if(!f.name) throw new Error("الاسم إلزامي");
      const p = BOS.pos(f.positionId);
      if(p.key==="gm" && !BOS.isTop(me())) throw new Error("تعيين مدير عام يتطلب صلاحية المالك/المدير العام");
      const changes = [];
      if(!isNew){ if(e.positionId!==f.positionId) changes.push("المنصب"); if(e.scope!==f.scope) changes.push("النطاق"); if((e.validTo||"")!==f.validTo) changes.push("انتهاء الصلاحية"); }
      Object.assign(e, f, {deptId: f.deptId || p.deptId});
      if(!e.managerId){ e.managerId = null; const m = BOS.managerOf(e); e.managerId = m ? m.id : null; }
      if(isNew){ Object.assign(e, {id:BOS.uid("e"), status:"active", leaveUsed:0}); if(window.BOS_MAIL) e.mailAddr = BOS_MAIL.suggestAddress(e.name, e.id); s.employees.push(e);
        BOS.audit("دعوة موظف","employee",e.id, e.name + " — " + p.title);
        BOS.notify(e.id, "مرحباً بك في " + s.company.tradeName + " — منصبك: " + p.title, "#/home");
        if(window.BOS_HR) BOS_HR.onEmployeeCreated(e);
        toast("تم إنشاء الحساب. (في التشغيل الفعلي تُرسل دعوة آمنة بالبريد — لا تُرسل كلمات المرور بالبريد)","ok");
      } else { BOS.audit("تعديل بيانات موظف","employee",e.id, e.name + (changes.length?" — تغيير صلاحية: "+changes.join("، "):"")); toast("تم الحفظ","ok"); }
      BOS.save(); U.route();
    }}], true);
  const pv = () => { const f = formData(bg); const p = BOS.pos(f.positionId); const tmp = {id:e.id||"_", positionId:f.positionId, managerId:f.managerId||null, status:"active"};
    const m = f.managerId ? BOS.byId(f.managerId) : BOS.managerOf(tmp);
    $("#pv",bg).innerHTML = `<b>معاينة:</b> يرفع طلباته إلى <b>${m?esc(m.name):"—"}</b> (${m?esc(BOS.posTitle(m.positionId)):"لا يوجد مستوى أعلى"}) · نطاق الرؤية: ${esc(D.SCOPES[f.scope||p.scope])} · السرية: ${esc(D.CLEARANCE[p.clearance])} · ${p.mfa?"يتطلب MFA":"بدون MFA"}`; };
  $$("select",bg).forEach(x=>x.addEventListener("change",pv)); pv();
}
function person(id){
  const s = S(); const e = BOS.byId(id); if(!e) throw new Error("الموظف غير موجود");
  const u = me(); const self = u.id===e.id;
  const mgr = window.BOS_HR && BOS_HR.isManagerOf(u,e);
  if(!self && !mgr && !BOS.can(u,"people","view")) throw new Error("لا تملك صلاحية عرض ملفات الموظفين");
  const hrx = window.BOS_VIEWS_HR ? BOS_VIEWS_HR.personExtra(e) : {html:"", bind:null};
  const hr = BOS.can(u,"people","edit");
  const p = BOS.pos(e.positionId);
  const reqs = s.requests.filter(r=>r.creatorId===e.id && BOS.canSeeRequest(u,r));
  const reports = s.employees.filter(x=>x.managerId===e.id);
  const pending = s.requests.filter(r=>{ const st = BOS.currentStep(r); return st && st.assigneeId===e.id && open(r); });
  return {title:e.name, html: `
    ${head(e.name, esc(p.title) + " · " + esc((BOS.dept(e.deptId)||{}).name||""), (hr?`<button class="btn" id="edit">تعديل</button>`:"") + (hr?`<button class="btn" id="leave">${e.onLeave?"إنهاء الإجازة":"تسجيل في إجازة"}</button>`:"") + (hr && !self && BOS.active(e)?`<button class="btn danger" id="disable">إيقاف الحساب وإنهاء الخدمة</button>`:"") + (hr && !BOS.active(e)?`<button class="btn ok" id="enable">إعادة التفعيل</button>`:""))}
    ${BOS.active(e)?"":`<div class="note bad" style="margin-bottom:14px">الحساب موقوف منذ ${fmtDate(e.disabledAt)} — ${esc(e.disableReason||"")}. لا يمكنه تسجيل الدخول أو استلام مراحل الموافقة.</div>`}
    <div class="grid g2">
      <div class="card"><h2 style="margin-bottom:10px">الملف الوظيفي</h2><dl class="kv">
        <dt>البريد الداخلي</dt><dd><span class="mono" dir="ltr">${esc(e.mailAddr||"—")}</span> ${window.BOS_MAIL && !self && BOS.active(e)?`<button class="btn sm" id="msg">✉️ مراسلة</button>`:""} ${window.BOS_MAIL && (BOS.can(u,"people","edit")||BOS.isTop(u))?`<button class="btn sm" id="addr">تعديل العنوان</button>`:""}</dd>
        <dt>البريد الخارجي</dt><dd dir="ltr" style="text-align:end">${esc(e.email||"—")}</dd><dt>الهاتف</dt><dd>${esc(e.phone||"—")}</dd>
        <dt>المدير المباشر</dt><dd>${e.managerId?empName(e.managerId):"—"}</dd><dt>البديل أثناء الإجازة</dt><dd>${e.delegateId?empName(e.delegateId):"—"}</dd>
        <dt>المرؤوسون</dt><dd>${reports.map(r=>esc(r.name)).join("، ")||"—"}</dd>
        <dt>نطاق الرؤية</dt><dd>${esc(D.SCOPES[BOS.scopeOf(e)])}</dd><dt>مستوى السرية</dt><dd>${clsBadge(BOS.clearance(e))}</dd>
        <dt>الصلاحية</dt><dd>${fmtDate(e.validFrom)} ← ${e.validTo?fmtDate(e.validTo):"مفتوحة"}</dd>
        <dt>الإجازات المستخدمة</dt><dd>${e.leaveUsed||0} من ${s.settings.leaveDays||30} يوم</dd></dl></div>
      <div class="card"><h2 style="margin-bottom:10px">صلاحيات المنصب</h2>
        ${D.MODULES.filter(m=>(p.perms[m.key]||[]).length).map(m=>`<div class="small" style="margin-bottom:6px">${m.icon} <b>${esc(m.name)}:</b> ${(p.perms[m.key]).map(a=>esc((D.ACTIONS.find(x=>x[0]===a)||[a,a])[1])).join("، ")}</div>`).join("")}</div>
    </div>
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><h2 style="margin-bottom:10px">طلباته</h2>${reqTable(reqs.slice(0,8))}</div>
      <div class="card"><h2 style="margin-bottom:10px">مراحل مسندة إليه حالياً</h2>${reqTable(pending,"لا يوجد")}</div>
    </div>${hrx.html}`,
    bind: root => {
      bindRows(root); hrx.bind && hrx.bind(root);
      if($("#msg",root)) $("#msg",root).onclick = () => BOS_VIEWS_MAIL.compose({to:[e.mailAddr]});
      if($("#addr",root)) $("#addr",root).onclick = () => U.ask("عنوان البريد الداخلي — " + e.name, "العنوان (المقترح: " + BOS_MAIL.suggestAddress(e.name, e.id) + ")", v=>{ BOS_MAIL.setAddress(e, v); U.route(); }, {value:e.mailAddr||""});
      if($("#edit",root)) $("#edit",root).onclick = () => employeeEditor(e);
      if($("#leave",root)) $("#leave",root).onclick = () => { e.onLeave = !e.onLeave; BOS.audit(e.onLeave?"بدء إجازة":"انتهاء إجازة","employee",e.id,e.name + (e.onLeave && e.delegateId?" — البديل: "+BOS.byId(e.delegateId).name:"")); BOS.save(); U.route(); };
      if($("#enable",root)) $("#enable",root).onclick = () => { e.status="active"; e.validTo=""; BOS.audit("إعادة تفعيل حساب","employee",e.id,e.name); BOS.save(); U.route(); };
      if($("#disable",root)) $("#disable",root).onclick = () => modal("إيقاف حساب " + e.name, `<p class="small">يتوقف وصوله فوراً، وتُحال المراحل المسندة إليه (${pending.length}) إلى مديره المباشر.</p><div class="field"><label class="f">السبب *</label><input class="input" name="reason" placeholder="انتهاء العقد / استقالة / ..."></div>
        <label class="check"><input type="checkbox" name="handover" checked> ${window.BOS_HR ? "بدء قائمة إنهاء الخدمة وتسليم العهد (" + BOS_HR.custodyOf(e.id).length + " عهدة مسجلة)" : "فتح طلب تسليم العهد والأجهزة"}</label>`,
        [{label:"إيقاف", cls:"danger solid", onClick:bg=>{ const f = formData(bg); if(!f.reason) throw new Error("السبب إلزامي");
          e.status = "disabled"; e.disabledAt = BOS.now(); e.disableReason = f.reason;
          const up = BOS.managerOf(e) || BOS.byId((BOS.holderOf("gm")||{}).id);
          pending.forEach(r=>{ const st = BOS.currentStep(r); st.notes.push("أعيد الإسناد بسبب إيقاف " + e.name); st.assigneeId = up ? up.id : null; if(up) BOS.notify(up.id,"أحيلت إليك مرحلة في "+r.no+" بسبب إيقاف "+e.name,"#/request/"+r.id,"task"); });
          BOS.audit("إيقاف حساب وإنهاء وصول","employee",e.id,e.name + " — " + f.reason + " — أعيد إسناد " + pending.length + " مرحلة");
          if(f.handover && window.BOS_HR) BOS_HR.onEmployeeDisabled(e, f.reason);
          else if(f.handover) BOS.createRequest("general",{subject:"تسليم العهد والأجهزة — " + e.name, details:"إنهاء خدمة: " + f.reason + ". يُرجى حصر العهد والأجهزة واستلامها وإغلاق الحسابات."},{title:"تسليم عهد — " + e.name});
          BOS.save(); toast("تم إيقاف الحساب","ok"); U.refresh(); }}]);
    }};
}

/* =================== الطلبات =================== */
function requests(){
  need("requests");
  const u = me();
  const all = S().requests.filter(r=>BOS.canSeeRequest(u,r));
  return {title:"الطلبات", html: `
    ${head("الطلبات والمعاملات", all.length + " طلب ضمن نطاق رؤيتك", BOS.can(u,"requests","create")?'<button class="btn primary" id="new">＋ طلب جديد</button>':"")}
    <div class="card"><div class="row" style="margin-bottom:12px">
      <select class="input" id="f-scope" style="max-width:190px"><option value="all">كل ما أراه</option><option value="mine">طلباتي</option><option value="acted">شاركت في اعتمادها</option></select>
      <select class="input" id="f-status" style="max-width:190px"><option value="">كل الحالات</option>${Object.entries(U.REQ_STATUS).map(([k,v])=>`<option value="${k}">${v[0]}</option>`).join("")}<option value="late">متأخرة</option></select>
      <select class="input" id="f-type" style="max-width:220px"><option value="">كل الأنواع</option>${Object.entries(D.TYPES).map(([k,t])=>`<option value="${k}">${t.icon} ${esc(t.name)}</option>`).join("")}</select>
      <input class="input" id="f-q" placeholder="بحث بالرقم أو العنوان" style="max-width:240px"></div><div id="list"></div></div>`,
    bind: root => {
      if($("#new",root)) $("#new",root).onclick = newRequestPicker;
      const draw = () => {
        const sc = $("#f-scope",root).value, st = $("#f-status",root).value, ty = $("#f-type",root).value, q = $("#f-q",root).value.trim();
        const list = all.filter(r=> (sc!=="mine"||r.creatorId===u.id) && (sc!=="acted"||r.steps.some(s=>s.actedBy===u.id)) && (!st || (st==="late"?overdue(r):r.status===st)) && (!ty||r.type===ty) && (!q || (r.no+r.title).includes(q)));
        $("#list",root).innerHTML = reqTable(list); bindRows(root);
      };
      $$("#f-scope,#f-status,#f-type",root).forEach(x=>x.onchange=draw); $("#f-q",root).oninput = draw; draw();
    }};
}
function fieldInput(f, v){
  const val = v==null ? "" : v;
  if(f.t==="textarea") return `<textarea class="input" name="${f.k}">${esc(val)}</textarea>`;
  if(f.t==="select") return `<select class="input" name="${f.k}">${f.o.map(o=>`<option ${o===val?"selected":""}>${esc(o)}</option>`).join("")}</select>`;
  if(f.t==="check") return `<label class="check"><input type="checkbox" name="${f.k}" ${val?"checked":""}> ${esc(f.l)}</label>`;
  if(f.t==="user") return `<select class="input" name="${f.k}"><option value="">—</option>${userOptions(val, x=>x.id!==me().id)}</select>`;
  return `<input class="input" name="${f.k}" type="${f.t}" value="${esc(val)}">`;
}
function requestForm(type, data){
  const T = D.TYPES[type];
  return T.fields.map(f=> f.t==="check" ? `<div class="field">${fieldInput(f,data[f.k])}</div>` : `<div class="field"><label class="f">${esc(f.l)}${f.req?" *":""}</label>${fieldInput(f,data[f.k])}</div>`).join("");
}
function validate(type, data){
  for(const f of D.TYPES[type].fields){ if(f.req && (data[f.k]===""||data[f.k]==null)) throw new Error("الحقل «" + f.l + "» إلزامي"); }
  if(type==="leave" && data.to < data.from) throw new Error("تاريخ النهاية قبل البداية");
}
function newReq(type){
  need("requests","create");
  const T = D.TYPES[type]; if(!T || T.system) throw new Error("نوع طلب غير متاح للإنشاء المباشر");
  const tpl = D.TYPE_TEMPLATES[type];
  return {title:"طلب جديد — " + T.name, html: `
    ${head(T.icon + " " + T.name, "رقم الطلب يصدر تلقائياً عند الإرسال ولا يُعاد استخدامه", tpl?`<a class="btn" href="library/${tpl}" download>⬇ النموذج الرسمي</a>`:"")}
    <div class="grid g2">
      <div class="card" id="form">${requestForm(type,{})}
        ${T.docs.length?`<div class="field"><label class="f">المستندات المطلوبة</label>${T.docs.map((d,i)=>`<label class="check"><input type="checkbox" data-doc="${i}"> ${esc(d)} — مرفق</label>`).join("")}</div>`:""}
        <div class="row"><span class="spacer"></span><a class="btn" href="#/requests">إلغاء</a><button class="btn primary" id="submit">إرسال للمراجعة</button></div></div>
      <div class="card"><h2 style="margin-bottom:10px">قبل الإرسال: أين سيذهب طلبك؟</h2><div id="pv"></div></div>
    </div>`,
    bind: root => {
      const form = $("#form",root);
      const draw = () => {
        const data = formData(form); const pv = BOS.routePreview(type, data, me().id);
        const amt = BOS.amountOf(type,data); const cur = S().settings.currency;
        const next = pv.steps.filter(s=>s.status!=="skipped")[1];
        $("#pv",root).innerHTML = `
          <dl class="kv" style="margin-bottom:12px">
            <dt>من سيستلم الطلب</dt><dd>${pv.first?empName(pv.first.assigneeId) + ` <span class="muted small">(${esc(pv.first.label)})</span>`:"—"}</dd>
            <dt>المرحلة التالية</dt><dd>${next?esc(next.label) + " — " + empName(next.assigneeId):"الإغلاق"}</dd>
            <dt>المدة المتوقعة</dt><dd>${pv.days} أيام عمل</dd>
            <dt>المستندات المطلوبة</dt><dd>${T.docs.map(esc).join("، ")||"لا يوجد"}</dd>
            <dt>الأثر المالي</dt><dd>${amt?money(amt,cur):"لا يوجد"}</dd>
            <dt>الأثر الأمني</dt><dd>${T.confidential?'<span class="badge bad">سري — وصول مقيد</span>':(data.sensitive?'<span class="badge warn">حساس</span>':"عادي")}</dd>
            <dt>موافقة المدير العام</dt><dd>${pv.needsGm?'<span class="badge warn">مطلوبة</span>':'<span class="badge ok">غير مطلوبة</span>'}</dd>
          </dl>${routeHorizontal(pv.steps, me().id)}`;
      };
      form.addEventListener("input", draw); form.addEventListener("change", draw); draw();
      $("#submit",root).onclick = () => {
        try{
          const data = formData(form); $$("[data-doc]",form).forEach(c=>delete data[c.name]);
          validate(type, data);
          const missing = $$("[data-doc]",form).filter(c=>!c.checked).map(c=>T.docs[c.dataset.doc]);
          const title = data.item || data.subject || data.program || data.purpose || data.system || data.customer || data.project || "";
          const r = BOS.createRequest(type, data, {title: T.name + (title?" — " + title:"")});
          if(missing.length){ r.missingDocs = missing; r.steps[0] && r.steps[0].notes.push("مستندات لم تُرفق: " + missing.join("، ")); BOS.save(); }
          toast("أُرسل الطلب " + r.no, "ok"); U.refresh(); go("#/request/" + r.id);
        }catch(e){ toast(e.message,"bad"); }
      };
    }};
}
function stepHtml(s, i, r){
  const cls = s.status==="approved" ? "done" : s.status==="pending" && open(r) ? "current" : ["rejected","returned"].includes(s.status) ? "rejected" : ["skipped","cancelled"].includes(s.status) ? "skipped" : "";
  const st = {approved:["تمت","ok"], pending:[open(r)?"جارية":"بانتظار","info"], rejected:["مرفوضة","bad"], returned:["أعيدت للتعديل","warn"], skipped:["لا تنطبق",""], cancelled:["ملغاة",""]}[s.status] || [s.status,""];
  return `<div class="step ${cls}"><div class="n">${s.status==="approved"?"✓":i+1}</div><div class="b">
    <b>${esc(s.label)}</b><span class="stage-tag">${esc(D.STAGES[s.stage])}</span> <span class="badge ${st[1]}">${st[0]}</span>${s.conditional?' <span class="badge warn">مشروط</span>':""}${s.override?' <span class="badge bad">تدخل المدير العام</span>':""}
    <div class="meta">${s.status==="skipped" ? esc(s.skipReason||"") : (s.actedBy ? `${empName(s.actedBy)} · ${esc(s.actorPos||"")} · ${fmtDT(s.actedAt)} · بيانات الإصدار ${s.dataVersion} <span class="mono" title="بصمة نسخة البيانات المعتمدة">#${esc(s.snapshot)}</span>` : `المسؤول: ${empName(s.assigneeId)}${s.dueAt && s.status==="pending" && open(r)?` · الاستحقاق ${fmtDT(s.dueAt)}`:""}`)}</div>
    ${s.comment?`<div class="cm">${esc(s.comment)}</div>`:""}
    ${s.notes.map(n=>`<div class="meta">• ${esc(n)}</div>`).join("")}</div></div>`;
}
function request(id){
  const r = S().requests.find(x=>x.id===id); const u = me();
  if(!r) throw new Error("الطلب غير موجود");
  if(!BOS.canSeeRequest(u,r)) { BOS.audit("محاولة وصول مرفوضة","request",r.id,r.no); BOS.save(); throw new Error("لا تملك صلاحية عرض هذا الطلب" + ((D.TYPES[r.type]||{}).confidential?" (سجل مقيد الوصول)":"")); }
  const T = D.TYPES[r.type]; const st = BOS.currentStep(r);
  const isAssignee = st && st.assigneeId===u.id && open(r);
  const gm = BOS.isTop(u);
  const creator = r.creatorId===u.id;
  const val = (f) => { const v = r.data[f.k]; if(f.t==="check") return v?"نعم":"لا"; if(f.t==="user") return v?empName(v):"—"; if(f.t==="number" && f.k===T.amount) return money(v); return esc(v||"—"); };
  let actions = "";
  if(open(r) && (isAssignee || (gm && st))){
    const exec = st.stage==="execute"||st.stage==="close";
    actions = `<div class="card" style="border-color:var(--accent)"><h2>${isAssignee?"إجراؤك المطلوب":"تدخل المدير العام"}: ${esc(st.label)}</h2>
      ${!isAssignee?'<p class="small muted">هذه المرحلة مسندة إلى '+empName(st.assigneeId)+'. أي إجراء منك يُسجل كتدخل مع سبب إلزامي.</p>':""}
      ${r.status==="info_requested"?'<div class="note warn small">بانتظار رد المنشئ على طلب المعلومات.</div>':""}
      <div class="field" style="margin-top:10px"><label class="f">تعليق / سبب (إلزامي للرفض والإعادة والشرط)</label><textarea class="input" id="cm"></textarea></div>
      <div class="row">
        <button class="btn ok solid" data-a="approve">${exec?"✓ تم التنفيذ":"✓ اعتماد"}</button>
        ${exec?"":'<button class="btn" data-a="conditional">اعتماد مشروط</button>'}
        <button class="btn" data-a="return">↩ إعادة للتعديل</button>
        <button class="btn" data-a="info">❓ طلب معلومات</button>
        <button class="btn" data-a="delegate">تفويض</button>
        <button class="btn" data-a="escalate">⬆ تصعيد</button>
        <button class="btn danger" data-a="reject">✕ رفض</button>
      </div><p class="small muted" style="margin-top:8px">يُحفظ مع قرارك: اسمك، منصبك، التاريخ والوقت، التعليق، وبصمة نسخة البيانات التي اعتمدتها.</p></div>`;
  }
  let creatorBox = "";
  if(creator && r.status==="returned") creatorBox = `<div class="card" style="border-color:var(--warn)"><h2 style="margin-bottom:10px">عدّل الطلب وأعد إرساله</h2><div id="rform">${requestForm(r.type, r.data)}</div><button class="btn primary" id="resubmit">إعادة الإرسال (إصدار ${r.version+1})</button></div>`;
  if(creator && r.status==="info_requested") creatorBox = `<div class="card" style="border-color:var(--warn)"><h2 style="margin-bottom:10px">المعلومات المطلوبة</h2><div class="small">${esc((st.notes.filter(n=>n.startsWith("طلب معلومات")).pop())||"")}</div><textarea class="input" id="ans" style="margin-top:8px"></textarea><button class="btn primary" id="answer" style="margin-top:8px">إرسال الرد</button></div>`;
  const link = r.link && r.link.kind==="document" ? `<a href="#/doc/${r.link.id}">فتح المستند</a>` : r.link && r.link.kind==="invoice" ? `<a href="#/invoice/${r.link.id}">فتح الفاتورة</a>` : "";
  const tpl = D.TYPE_TEMPLATES[r.type];
  const secx = window.BOS_VIEWS_SEC ? BOS_VIEWS_SEC.requestExtra(r) : {html:"", bind:null};
  return {title:r.no, html: `
    ${head(T.icon + " " + r.title, `<span class="mono">${esc(r.no)}</span> · ${statusBadge(r.status)} ${overdue(r)?'<span class="badge bad">متأخر</span>':""} ${T.confidential?'<span class="badge bad">🔒 وصول مقيد</span>':""} · الإصدار ${r.version}`,
      `<button class="btn" onclick="print()">🖨 طباعة</button>${tpl?`<a class="btn" href="library/${tpl}" download>⬇ النموذج الرسمي</a>`:""}${(creator||gm)&&open(r)?'<button class="btn danger" id="cancel">إلغاء الطلب</button>':""}`)}
    ${actions}${creatorBox}
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><h2 style="margin-bottom:10px">بيانات الطلب</h2><dl class="kv">
        <dt>المنشئ</dt><dd>${empName(r.creatorId)} <span class="muted small">— ${esc(BOS.posTitle((BOS.byId(r.creatorId)||{}).positionId))}</span></dd>
        <dt>تاريخ الإنشاء</dt><dd>${fmtDT(r.createdAt)}</dd><dt>الاستحقاق</dt><dd>${fmtDate(r.due)}</dd>
        ${T.fields.map(f=>`<dt>${esc(f.l)}</dt><dd>${val(f)}</dd>`).join("")}
        ${r.missingDocs?`<dt>مستندات ناقصة</dt><dd><span class="badge warn">${r.missingDocs.map(esc).join("، ")}</span></dd>`:""}
        ${r.cancelReason?`<dt>سبب الإلغاء</dt><dd>${esc(r.cancelReason)}</dd>`:""}
        ${link?`<dt>مرتبط بـ</dt><dd>${link}</dd>`:""}</dl></div>
      <div class="card"><h2 style="margin-bottom:12px">مسار الموافقة</h2><div class="route">${r.steps.map((s,i)=>stepHtml(s,i,r)).join("")}</div>
        ${(r.previousRounds||[]).length?`<details style="margin-top:8px"><summary class="small">جولات سابقة (${r.previousRounds.length})</summary>${r.previousRounds.map((rd,k)=>`<div class="route" style="margin-top:8px"><b class="small">الجولة ${k+1}</b>${rd.map((s,i)=>stepHtml(s,i,{status:"closed"})).join("")}</div>`).join("")}</details>`:""}
      </div>
    </div>
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><h2 style="margin-bottom:10px">التعليقات</h2>${r.comments.map(c=>`<div class="list-item">${avatar(BOS.byId(c.by))}<div class="grow"><b class="small">${empName(c.by)}</b> <span class="muted small">${fmtDT(c.at)}</span><div>${esc(c.text)}</div></div></div>`).join("")||'<div class="muted small">لا توجد تعليقات</div>'}
        <div class="row" style="margin-top:10px"><input class="input" id="cmt" placeholder="أضف تعليقاً…" style="flex:1"><button class="btn" id="addc">إرسال</button></div></div>
      <div class="card"><h2 style="margin-bottom:10px">إصدارات البيانات</h2>${r.history.map(h=>`<div class="list-item"><span class="badge">إ${h.v}</span><div class="grow small">${empName(h.by)} · ${fmtDT(h.at)} <span class="mono muted">#${esc(h.hash)}</span></div></div>`).join("")}
        <div class="muted small">كل اعتماد مرتبط ببصمة نسخة البيانات؛ أي تعديل بعد الإعادة ينشئ إصداراً جديداً ويُعاد المسار.</div></div>
    </div>${secx.html}`,
    bind: root => {
      secx.bind && secx.bind(root);
      const doAct = (a, o) => { try{ BOS.act(r, a, o); toast("تم تسجيل الإجراء","ok"); U.refresh(); }catch(e){ toast(e.message,"bad"); } };
      $$("[data-a]",root).forEach(b=>b.onclick=()=>{
        const a = b.dataset.a, comment = $("#cm",root).value.trim();
        if(a==="delegate"){
          modal("تفويض المرحلة", `<div class="field"><label class="f">فوّض إلى</label><select class="input" name="to">${userOptions("", x=>x.id!==u.id)}</select></div>`, [{label:"تفويض",cls:"primary",onClick:bg=>doAct("delegate",{toId:$("[name=to]",bg).value, comment})}]);
          return;
        }
        if(a==="reject") return U.ask("رفض الطلب", "سيُرفض الطلب نهائياً ويُبلَّغ المنشئ بالسبب: " + (comment||"(اكتب السبب في خانة التعليق أولاً)"), ()=>doAct("reject",{comment}), {confirmOnly:true, okLabel:"رفض", cls:"danger solid"});
        doAct(a, {comment});
      });
      if($("#cancel",root)) $("#cancel",root).onclick = () => U.ask("إلغاء الطلب " + r.no, "سبب الإلغاء", c=>doAct("cancel",{comment:c}), {okLabel:"إلغاء الطلب", cls:"danger solid"});
      if($("#resubmit",root)) $("#resubmit",root).onclick = () => { try{ const d = formData($("#rform",root)); validate(r.type,d); BOS.act(r,"resubmit",{data:d}); toast("أعيد الإرسال","ok"); U.refresh(); }catch(e){ toast(e.message,"bad"); } };
      if($("#answer",root)) $("#answer",root).onclick = () => doAct("answer",{comment:$("#ans",root).value.trim()});
      $("#addc",root).onclick = () => doAct("comment",{comment:$("#cmt",root).value.trim()});
    }};
}
function approvals(){
  const u = me(); const q = U.myQueue();
  const done = S().requests.filter(r=>r.steps.some(s=>s.actedBy===u.id)).slice(0,20);
  return {title:"ينتظر موافقتي", html: `${head("ينتظر موافقتي", q.length + " مرحلة مسندة إليك")}
    <div class="card">${reqTable(q,"لا يوجد ما ينتظر موافقتك")}</div>
    <div class="card"><h2 style="margin-bottom:10px">قراراتي السابقة</h2>${reqTable(done,"لم تتخذ قرارات بعد")}</div>`, bind: bindRows};
}
function notifications(){
  const u = me(); const list = S().notifications.filter(n=>n.userId===u.id);
  return {title:"الإشعارات", html: `${head("الإشعارات", U.unread().length + " غير مقروء", '<button class="btn" id="all">تعليم الكل كمقروء</button>')}
    <div class="card">${list.length?list.map(noteItem).join(""):empty("لا توجد إشعارات")}</div>
    <p class="muted small">لا ترسل البيانات السرية كاملة عبر البريد؛ يرسل النظام رابطاً آمناً مع ملخص محدود.</p>`,
    bind: root => { bindNotes(root); $("#all",root).onclick = () => { list.forEach(n=>n.read=true); BOS.save(); U.refresh(); }; }};
}

/* =================== المستندات والإصدارات (القسم 6.11) =================== */
function docStatus(d){ const v = d.versions[d.versions.length-1]; return {draft:["مسودة",""], in_review:["قيد الاعتماد","info"], approved:["معتمد","ok"], superseded:["مستبدل",""]}[v.status] || [v.status,""]; }
function documents(){
  need("documents");
  const u = me(); const list = S().documents.filter(d=>BOS.canSeeDoc(u,d));
  const hidden = S().documents.length - list.length;
  const cats = Array.from(new Set(list.map(d=>d.category)));
  return {title:"المستندات", html: `
    ${head("المستودع المركزي للمستندات", "نسخة رئيسية واحدة لكل مستند مع إصدارات مؤرخة" + (hidden?` · ${hidden} مستند خارج مستوى صلاحيتك`:""), BOS.can(u,"documents","create")?'<button class="btn primary" id="new">＋ مستند</button>':"")}
    <div class="card"><div class="row" style="margin-bottom:12px"><select class="input" id="cat" style="max-width:240px"><option value="">كل التصنيفات</option>${cats.map(c=>`<option>${esc(c)}</option>`).join("")}</select><input class="input" id="q" placeholder="بحث" style="max-width:260px"></div>
    <div class="table-wrap"><table><thead><tr><th>الرقم</th><th>العنوان</th><th>التصنيف</th><th>السرية</th><th>الإصدار</th><th>الحالة</th><th>الملف</th></tr></thead><tbody>
    ${list.map(d=>{ const s = docStatus(d); const v = d.versions[d.versions.length-1]; return `<tr class="link" data-go="#/doc/${d.id}" data-cat="${esc(d.category)}" data-s="${esc(d.no+" "+d.title)}"><td class="mono">${esc(d.no)}</td><td>${esc(d.title)} ${d.master?'<span class="badge accent">رئيسي</span>':""}</td><td class="small">${esc(d.category)}</td><td>${clsBadge(d.classification)}</td><td>إ${v.v}</td><td><span class="badge ${s[1]}">${s[0]}</span></td><td>${v.file?`<a href="${esc(v.file)}" download data-dl="${d.id}">⬇ ${esc(v.file.split(".").pop().toUpperCase())}</a>`:"—"}</td></tr>`; }).join("")}
    </tbody></table></div></div>`,
    bind: root => {
      bindRows(root);
      if($("#new",root)) $("#new",root).onclick = docEditor;
      const f = () => { const c = $("#cat",root).value, q = $("#q",root).value.trim(); $$("[data-cat]",root).forEach(r=>r.classList.toggle("hidden", (c && r.dataset.cat!==c) || (q && !r.dataset.s.includes(q)))); };
      $("#cat",root).onchange = f; $("#q",root).oninput = f;
      $$("[data-dl]",root).forEach(a=>a.addEventListener("click",()=>{ const d = S().documents.find(x=>x.id===a.dataset.dl); logDownload(d); }));
    }};
}
function logDownload(d){
  BOS.audit("تنزيل ملف","document",d.id,d.no + " — " + d.title);
  const u = me(); const key = "dl_" + u.id; const t = Date.now();
  const w = (S().settings[key] || []).filter(x=>t-x < 10*60000); w.push(t); S().settings[key] = w;
  if(w.length >= 8 && d.classification >= 2){ BOS.audit("تنبيه أمني: تنزيل ملفات بكميات كبيرة","security",u.id,w.length + " ملف خلال 10 دقائق");
    const sec = BOS.holderOf("secops"); if(sec) BOS.notify(sec.id,"تنبيه: " + u.name + " نزّل " + w.length + " ملفاً خلال 10 دقائق","#/audit","bad"); }
  BOS.save();
}
function docEditor(){
  modal("مستند جديد", `<div class="field"><label class="f">العنوان *</label><input class="input" name="title"></div>
    <div class="grid g2"><div class="field"><label class="f">التصنيف</label><input class="input" name="category" value="عام"></div>
    <div class="field"><label class="f">السرية</label><select class="input" name="classification">${Object.entries(D.CLEARANCE).filter(([k])=>Number(k)<=BOS.clearance(me())).map(([k,v])=>`<option value="${k}" ${k==="2"?"selected":""}>${v}</option>`).join("")}</select></div>
    <div class="field"><label class="f">تاريخ الانتهاء (للعقود والتراخيص)</label><input class="input" type="date" name="expires"></div></div>
    <div class="field"><label class="f">المحتوى / الملخص</label><textarea class="input" name="content" style="min-height:140px"></textarea></div>`,
    [{label:"إنشاء مسودة", cls:"primary", onClick:bg=>{ const f = formData(bg); if(!f.title) throw new Error("العنوان إلزامي"); const d = BOS.createDoc(f); go("#/doc/"+d.id); }}]);
}
function doc(id){
  const d = S().documents.find(x=>x.id===id); const u = me();
  if(!d) throw new Error("المستند غير موجود");
  if(!BOS.canSeeDoc(u,d)){ BOS.audit("محاولة وصول مرفوضة","document",d.id,d.no); BOS.save(); throw new Error("مستوى سرية هذا المستند أعلى من صلاحيتك"); }
  const cur = d.versions[d.versions.length-1];
  const approved = d.versions.filter(v=>v.status==="approved").pop();
  const canEdit = BOS.can(u,"documents","edit") || d.ownerId===u.id;
  return {title:d.no, html: `
    ${head("📄 " + d.title, `<span class="mono">${esc(d.no)}</span> · ${clsBadge(d.classification)} · ${esc(d.category)} · الإصدار الحالي ${cur.v}`,
      `${cur.file?`<a class="btn" href="${esc(cur.file)}" download id="dl">⬇ تنزيل الملف</a>`:""}<a class="btn" href="#/print-doc/${d.id}">🖨 نسخة صادرة</a>${canEdit?'<button class="btn" id="edit">✎ تعديل</button>':""}${canEdit && cur.status==="draft"?'<button class="btn primary" id="submit">إرسال للاعتماد</button>':""}${window.BOS_VIEWS_SEC && approved?'<button class="btn" id="sign">✍ توقيع إ' + approved.v + '</button>':""}`)}
    ${window.BOS_VIEWS_SEC && approved ? `<div class="card" style="margin-bottom:14px">${BOS_VIEWS_SEC.signaturesHtml("document", d.id, approved.v) || '<div class="small muted">لا توقيعات على الإصدار المعتمد بعد</div>'}</div>` : ""}
    ${cur.status!=="approved" && approved?`<div class="note warn" style="margin-bottom:14px">يوجد إصدار أحدث (إ${cur.v}) بحالة «${docStatus(d)[0]}». النسخة المعتمدة السارية هي إ${approved.v}.</div>`:""}
    <div class="grid g2">
      <div class="card"><h2 style="margin-bottom:10px">المحتوى — إ${cur.v}</h2><div style="white-space:pre-wrap">${esc(cur.content)||'<span class="muted">—</span>'}</div>
        ${d.master?'<div class="note warn small" style="margin-top:12px">نسخة من حزمة الشركة الأولية. لا تُوقّع قبل مراجعة محامٍ أو مستشار قانوني مرخّص في السودان.</div>':""}</div>
      <div class="card"><h2 style="margin-bottom:10px">سجل الإصدارات</h2>
        ${d.versions.slice().reverse().map(v=>`<div class="list-item"><span class="badge ${v.status==="approved"?"ok":v.status==="in_review"?"info":""}">إ${v.v}</span><div class="grow small"><b>${esc(v.note||"")}</b><div class="muted">أنشأه ${empName(v.createdBy)} · ${fmtDT(v.createdAt)}${v.approvedBy?` · اعتمده ${empName(v.approvedBy)} ${fmtDT(v.approvedAt)}`:""}${v.requestId?` · <a href="#/request/${v.requestId}">طلب الاعتماد</a>`:""}</div></div><span class="small">${{draft:"مسودة",in_review:"قيد الاعتماد",approved:"معتمد",superseded:"مستبدل"}[v.status]}</span></div>`).join("")}
        <dl class="kv" style="margin-top:12px"><dt>المالك</dt><dd>${empName(d.ownerId)}</dd><dt>القسم</dt><dd>${esc((BOS.dept(d.deptId)||{}).name||"")}</dd><dt>الانتهاء</dt><dd>${d.expires?fmtDate(d.expires):"—"}</dd></dl></div>
    </div>`,
    bind: root => {
      if($("#dl",root)) $("#dl",root).addEventListener("click",()=>logDownload(d));
      if($("#sign",root)) $("#sign",root).onclick = () => BOS_VIEWS_SEC.signatureModal("document", d.id, approved.v, approved.content + "|" + (approved.file||""), d.title);
      if($("#edit",root)) $("#edit",root).onclick = () => modal("تعديل " + d.title, `${cur.status!=="draft"||cur.createdBy!==u.id?`<div class="note small" style="margin-bottom:10px">سيُنشأ الإصدار ${cur.v+1} كمسودة؛ الإصدار ${cur.v} يبقى محفوظاً دون تغيير.</div>`:""}
        <div class="field"><label class="f">ملاحظة التغيير</label><input class="input" name="note"></div><div class="field"><label class="f">المحتوى</label><textarea class="input" name="content" style="min-height:220px">${esc(cur.content)}</textarea></div>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); BOS.editDoc(d, f.content, f.note); U.route(); }}], true);
      if($("#submit",root)) $("#submit",root).onclick = () => { try{ const r = BOS.submitDoc(d); toast("أُرسل للاعتماد: " + r.no,"ok"); U.refresh(); }catch(e){ toast(e.message,"bad"); } };
    }};
}

/* =================== المستند الصادر بهوية الشركة =================== */
function paper(o){
  const c = S().company;
  const tpl = S().settings.template;
  const line = tpl==="gold" ? "linear-gradient(90deg,#0B1B3A,#F3B83F)" : tpl==="cyan" ? "linear-gradient(90deg,#18CDEF,#0B1B3A)" : "linear-gradient(90deg,#18CDEF,#F3B83F)";
  return `<div class="paper">
    <div class="ph"><img src="${esc(c.logo)}" alt=""><div class="co"><b>${esc(c.tradeName)}</b><span>${esc(c.nameEn||"")}</span><div class="small" style="color:#44557A">${esc([c.state,c.address,c.phone,c.email].filter(Boolean).join(" · "))}</div></div>
      <div class="meta"><b>${esc(o.title)}</b><span class="mono">${esc(o.no)}</span><br>التاريخ: ${fmtDate(o.date)}<br>الحالة: <b>${esc(o.status)}</b></div></div>
    <div class="gold-line" style="background:${line}"></div>
    ${o.body}
    <div class="foot"><div>أنشأه: <b>${esc(o.createdBy||"—")}</b><br>اعتمده: <b>${esc(o.approvedBy||"— (غير معتمد)")}</b><br>صدر من نظام البشرى لإدارة الشركة · ${fmtDT(BOS.now())}</div>
      ${o.stamped?'<img class="stamp" src="assets/stamp.png" alt="الختم">':'<div class="muted small" style="text-align:center;width:120px">بدون ختم<br>(غير معتمد)</div>'}</div>
    <p class="small" style="color:#7A89A8;margin-top:10px">الختم الإلكتروني عنصر هوية وتصديق داخلي فقط، ولا يلغي التوقيع المفوض أو المتطلبات الرسمية.</p>
  </div>`;
}
function printDoc(id){
  const d = S().documents.find(x=>x.id===id); if(!d || !BOS.canSeeDoc(me(),d)) throw new Error("غير متاح");
  const v = d.versions.filter(x=>x.status==="approved").pop() || d.versions[d.versions.length-1];
  BOS.audit("طباعة / إصدار نسخة","document",d.id,d.no + " إ" + v.v); BOS.save();
  return {title:"نسخة صادرة", html:`<div class="row no-print" style="margin-bottom:12px"><a class="btn" href="#/doc/${d.id}">→ رجوع</a><button class="btn primary" onclick="print()">🖨 طباعة / PDF</button></div>` +
    paper({title:d.title, no:d.no + " / إ" + v.v, date:v.approvedAt||v.createdAt, status:v.status==="approved"?"معتمد":"مسودة — غير معتمد", createdBy:(BOS.byId(v.createdBy)||{}).name, approvedBy:(BOS.byId(v.approvedBy)||{}).name, stamped:v.status==="approved",
      body:`<h2>${esc(d.title)}</h2><p>التصنيف: ${esc(d.category)} · السرية: ${esc(D.CLEARANCE[d.classification])}</p><div style="white-space:pre-wrap">${esc(v.content)}</div>${v.file?`<p class="small">الملف المرجعي: ${esc(v.file)}</p>`:""}${window.BOS_VIEWS_SEC ? BOS_VIEWS_SEC.signaturesHtml("document", d.id, v.v) : ""}`})};
}

/* =================== العملاء (القسم 6.3) =================== */
const STAGES_C = ["فرصة","عرض سعر","تفاوض","عميل","متوقف"];
function customers(){
  need("customers");
  const u = me(); const list = S().customers;
  return {title:"العملاء", html: `${head("العملاء والعلاقات العامة", list.length + " جهة", BOS.can(u,"customers","create")?'<button class="btn primary" id="new">＋ عميل</button>':"")}
    <div class="card">${list.length?`<div class="table-wrap"><table><thead><tr><th>العميل</th><th>النوع</th><th>جهة الاتصال</th><th>المرحلة</th><th>موافقة النشر</th><th>الفواتير</th></tr></thead><tbody>
    ${list.map(c=>{ const inv = S().invoices.filter(i=>i.customerId===c.id); return `<tr class="link" data-c="${c.id}"><td><b>${esc(c.name)}</b></td><td class="small">${esc(c.kind)}</td><td class="small">${esc(c.contact)} ${esc(c.phone||"")}</td><td><span class="badge info">${esc(c.stage)}</span></td>
      <td>${c.publishConsent?'<span class="badge ok">موثقة</span>':'<span class="badge bad">غير مسموح</span>'}</td><td>${inv.length}</td></tr>`; }).join("")}</tbody></table></div>`:empty("لا يوجد عملاء")}</div>
    <p class="muted small">لا يجوز نشر شعار أو اسم عميل أو مشروع دون سجل موافقة واضح.</p>`,
    bind: root => { if($("#new",root)) $("#new",root).onclick = () => customerEditor(null); $$("[data-c]",root).forEach(r=>r.onclick=()=>{ if(window.BOS_VIEWS.customer) go("#/customer/" + r.dataset.c); else customerEditor(S().customers.find(x=>x.id===r.dataset.c)); }); }};
}
function customerEditor(c){
  const isNew = !c; c = c || {name:"",kind:"قطاع خاص",contact:"",phone:"",email:"",stage:"فرصة",publishConsent:false,notes:""};
  if(!BOS.can(me(),"customers",isNew?"create":"edit")) return toast("لا تملك صلاحية التعديل","bad");
  modal(isNew?"عميل جديد":c.name, `<div class="grid g2">
    <div class="field"><label class="f">الاسم *</label><input class="input" name="name" value="${esc(c.name)}"></div>
    <div class="field"><label class="f">النوع</label><select class="input" name="kind">${["قطاع خاص","جهة حكومية","تعليمي","منظمة","فرد"].map(k=>`<option ${k===c.kind?"selected":""}>${k}</option>`).join("")}</select></div>
    <div class="field"><label class="f">جهة الاتصال</label><input class="input" name="contact" value="${esc(c.contact)}"></div>
    <div class="field"><label class="f">الهاتف</label><input class="input" name="phone" value="${esc(c.phone)}"></div>
    <div class="field"><label class="f">البريد</label><input class="input" name="email" value="${esc(c.email)}"></div>
    <div class="field"><label class="f">مرحلة البيع</label><select class="input" name="stage">${STAGES_C.map(k=>`<option ${k===c.stage?"selected":""}>${k}</option>`).join("")}</select></div></div>
    <label class="check"><input type="checkbox" name="publishConsent" ${c.publishConsent?"checked":""}> العميل وافق كتابياً على نشر اسمه أو شعاره أو دراسة الحالة</label>
    <div class="field"><label class="f">ملاحظات</label><textarea class="input" name="notes">${esc(c.notes)}</textarea></div>`,
    [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); if(!f.name) throw new Error("الاسم إلزامي");
      const consentChanged = !isNew && c.publishConsent !== f.publishConsent;
      Object.assign(c,f); if(isNew){ c.id = BOS.uid("c"); c.createdAt = BOS.now(); S().customers.unshift(c); }
      BOS.audit(isNew?"إضافة عميل":"تعديل عميل","customer",c.id,c.name + (consentChanged?" — تغيير موافقة النشر إلى: " + (f.publishConsent?"موافق":"غير موافق"):""));
      BOS.save(); U.route(); }}], true);
}

/* =================== المالية (القسم 6.9) =================== */
const INV_STATUS = {draft:["مسودة",""], pending:["قيد الاعتماد","info"], sent:["مرسلة","accent"], partial:["مدفوعة جزئياً","warn"], paid:["مدفوعة","ok"], overdue:["متأخرة","bad"], partial_overdue:["جزئية متأخرة","bad"], cancelled:["ملغاة","bad"], disputed:["متنازع عليها","warn"]};
const Q_STATUS = {draft:["مسودة",""], sent:["مرسل للعميل","info"], accepted:["وافق العميل","ok"], rejected:["رفضه العميل","bad"], invoiced:["تمت الفوترة","accent"]};
function finance(){
  need("finance");
  const u = me(); const s = S(); const cur = s.settings.currency;
  const cn = id => esc((s.customers.find(c=>c.id===id)||{}).name||"—");
  const qt = q => BOS.totals(q.items,q.discount,q.taxRate).total;
  const stmt = s.customers.map(c=>{ const inv = s.invoices.filter(i=>i.customerId===c.id && !["draft","cancelled"].includes(i.status)); const t = inv.reduce((a,i)=>a+qt(i),0), p = inv.reduce((a,i)=>a+BOS.invoicePaid(i),0); return {c, n:inv.length, t, p}; }).filter(x=>x.n);
  return {title:"العروض والفواتير", html: `
    ${head("المالية والفواتير", "عرض سعر ← موافقة العميل ← فاتورة ← اعتماد ← إرسال ← تحصيل ← إيصال", BOS.can(u,"finance","create")?'<button class="btn primary" id="newq">＋ عرض سعر</button><button class="btn" id="newi">＋ فاتورة مباشرة</button>':"")}
    ${!s.customers.length?'<div class="note warn">أضف عميلاً أولاً من صفحة العملاء.</div>':""}
    <div class="tabs"><button class="on" data-tab="q">عروض الأسعار (${s.quotes.length})</button><button data-tab="i">الفواتير (${s.invoices.length})</button><button data-tab="st">كشف حساب العملاء</button></div>
    <div data-pane="q" class="card">${s.quotes.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>العميل</th><th>الإجمالي</th><th>الحالة</th><th>التاريخ</th></tr></thead><tbody>${s.quotes.map(q=>`<tr class="link" data-go="#/quote/${q.id}"><td class="mono">${esc(q.no)}</td><td>${cn(q.customerId)}</td><td>${money(qt(q),q.currency)}</td><td><span class="badge ${Q_STATUS[q.status][1]}">${Q_STATUS[q.status][0]}</span></td><td class="small">${fmtDate(q.createdAt)}</td></tr>`).join("")}</tbody></table></div>`:empty("لا توجد عروض أسعار")}</div>
    <div data-pane="i" class="card hidden">${s.invoices.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>العميل</th><th>الإجمالي</th><th>المدفوع</th><th>الاستحقاق</th><th>الحالة</th></tr></thead><tbody>${s.invoices.map(i=>{ const st = BOS.invoiceState(i); return `<tr class="link" data-go="#/invoice/${i.id}"><td class="mono">${esc(i.no)}</td><td>${cn(i.customerId)}</td><td>${money(qt(i),i.currency)}</td><td>${money(BOS.invoicePaid(i),i.currency)}</td><td class="small">${fmtDate(i.due)}</td><td><span class="badge ${INV_STATUS[st][1]}">${INV_STATUS[st][0]}</span></td></tr>`; }).join("")}</tbody></table></div>`:empty("لا توجد فواتير")}</div>
    <div data-pane="st" class="card hidden">${stmt.length?`<div class="table-wrap"><table><thead><tr><th>العميل</th><th>الفواتير</th><th>الإجمالي</th><th>المحصل</th><th>الرصيد</th></tr></thead><tbody>${stmt.map(x=>`<tr><td>${esc(x.c.name)}</td><td>${x.n}</td><td>${money(x.t,cur)}</td><td>${money(x.p,cur)}</td><td><b>${money(x.t-x.p,cur)}</b></td></tr>`).join("")}</tbody></table></div>`:empty("لا توجد حركات")}</div>
    <p class="muted small">لا يفترض النظام نسبة ضريبة أو جهة تحصيل من تلقاء نفسه؛ تُضبط النسبة من الإعدادات بواسطة المدير المالي وفق الوضع النظامي الفعلي.</p>`,
    bind: root => {
      bindRows(root);
      $$("[data-tab]",root).forEach(b=>b.onclick=()=>{ $$("[data-tab]",root).forEach(x=>x.classList.toggle("on",x===b)); $$("[data-pane]",root).forEach(p=>p.classList.toggle("hidden",p.dataset.pane!==b.dataset.tab)); });
      if($("#newq",root)) $("#newq",root).onclick = () => itemsEditor("quote");
      if($("#newi",root)) $("#newi",root).onclick = () => itemsEditor("invoice");
    }};
}
function itemsEditor(kind, src){
  const s = S(); if(!s.customers.length) return toast("أضف عميلاً أولاً","bad");
  const rowH = (it) => `<div class="row item" style="margin-bottom:6px"><input class="input" data-k="desc" placeholder="الخدمة / الوصف" value="${esc(it.desc||"")}" style="flex:3;min-width:160px"><input class="input" data-k="qty" type="number" placeholder="الكمية" value="${esc(it.qty||1)}" style="flex:1;min-width:70px"><input class="input" data-k="price" type="number" placeholder="سعر الوحدة" value="${esc(it.price||"")}" style="flex:1.4;min-width:100px"><button class="btn sm danger" data-rm>✕</button></div>`;
  const items = src ? src.items : [{desc:"",qty:1,price:""}];
  const bg = modal(kind==="quote"?"عرض سعر جديد":"فاتورة جديدة", `
    <div class="grid g2"><div class="field"><label class="f">العميل *</label><select class="input" name="customerId">${s.customers.map(c=>`<option value="${c.id}" ${src&&src.customerId===c.id?"selected":""}>${esc(c.name)}</option>`).join("")}</select></div>
    <div class="field"><label class="f">العملة</label><select class="input" name="currency">${["SDG","USD","SAR","AED","EUR"].map(x=>`<option ${x===(src?src.currency:s.settings.currency)?"selected":""}>${x}</option>`).join("")}</select></div>
    <div class="field"><label class="f">${kind==="quote"?"صالح حتى":"تاريخ الاستحقاق"}</label><input class="input" type="date" name="due" value="${new Date(Date.now()+30*864e5).toISOString().slice(0,10)}"></div>
    <div class="field"><label class="f">المشروع / العقد المرتبط</label><input class="input" name="ref" value="${esc(src?src.ref||"":"")}"></div></div>
    <label class="f">البنود</label><div id="items">${items.map(rowH).join("")}</div><button class="btn sm" id="add-item">＋ بند</button>
    <div class="grid g3" style="margin-top:12px"><div class="field"><label class="f">الخصم</label><input class="input" type="number" name="discount" value="${esc(src?src.discount||0:0)}"></div>
    <div class="field"><label class="f">رسوم/ضريبة % (يحددها المدير المالي)</label><input class="input" type="number" name="taxRate" value="${esc(src?src.taxRate:s.settings.taxRate||0)}" ${BOS.posByKey("cfo") && !["cfo","gm","owner"].includes(BOS.pos(me().positionId).key)?"readonly":""}></div>
    ${kind==="invoice"?'<div class="field"><label class="f">دفعة مقدمة مستلمة</label><input class="input" type="number" name="advance" value="0"></div>':""}</div>
    <div class="field"><label class="f">شروط وملاحظات</label><textarea class="input" name="terms">${esc(src?src.terms||"":"")}</textarea></div>
    <div id="tot" class="note"></div>`,
    [{label:"حفظ كمسودة", cls:"primary", onClick:bg=>{
      const f = formData($(".modal-b",bg)); const its = readItems(bg);
      if(!its.length) throw new Error("أضف بنداً واحداً على الأقل");
      const o = {id:BOS.uid(kind[0]), no:BOS.nextNo(kind==="quote"?"QT":"INV"), customerId:f.customerId, currency:f.currency, due:f.due, ref:f.ref, items:its, discount:Number(f.discount||0), taxRate:Number(f.taxRate||0), terms:f.terms, status:"draft", createdBy:me().id, createdAt:BOS.now(), payments:[]};
      if(kind==="quote"){ s.quotes.unshift(o); BOS.audit("إنشاء عرض سعر","quote",o.id,o.no); }
      else { if(src){ o.quoteId = src.id; src.status = "invoiced"; src.invoiceId = o.id; } s.invoices.unshift(o); BOS.audit("إنشاء فاتورة","invoice",o.id,o.no + (src?" من العرض " + src.no:""));
        if(Number(f.advance)>0) o.advance = Number(f.advance); }
      BOS.save(); go("#/" + kind + "/" + o.id);
    }}], true);
  const upd = () => { const its = readItems(bg); const f = formData($(".modal-b",bg)); const t = BOS.totals(its, f.discount, f.taxRate);
    $("#tot",bg).innerHTML = `المجموع ${money(t.sub,f.currency)} · الخصم ${money(t.disc,f.currency)} · الرسوم ${money(t.tax,f.currency)} · <b>الإجمالي ${money(t.total,f.currency)}</b>`; };
  const wire = () => $$("[data-rm]",bg).forEach(b=>b.onclick=()=>{ b.closest(".item").remove(); upd(); });
  $("#add-item",bg).onclick = () => { $("#items",bg).insertAdjacentHTML("beforeend", rowH({qty:1})); wire(); };
  bg.addEventListener("input", upd); wire(); upd();
}
const readItems = root => $$(".item",root).map(r=>({desc:$("[data-k=desc]",r).value.trim(), qty:Number($("[data-k=qty]",r).value||0), price:Number($("[data-k=price]",r).value||0)})).filter(i=>i.desc && i.qty>0);
function itemsTable(o){
  const t = BOS.totals(o.items,o.discount,o.taxRate);
  return `<table style="margin-top:14px"><thead><tr><th>#</th><th>الخدمة / الوصف</th><th>الكمية</th><th>سعر الوحدة</th><th>الإجمالي</th></tr></thead><tbody>
    ${o.items.map((i,k)=>`<tr><td>${k+1}</td><td>${esc(i.desc)}</td><td>${i.qty}</td><td>${money(i.price,o.currency)}</td><td>${money(i.qty*i.price,o.currency)}</td></tr>`).join("")}
    <tr><td colspan="4" style="text-align:end">المجموع</td><td>${money(t.sub,o.currency)}</td></tr>
    ${t.disc?`<tr><td colspan="4" style="text-align:end">الخصم</td><td>− ${money(t.disc,o.currency)}</td></tr>`:""}
    ${o.taxRate?`<tr><td colspan="4" style="text-align:end">الرسوم/الضرائب (${o.taxRate}%)</td><td>${money(t.tax,o.currency)}</td></tr>`:""}
    <tr><td colspan="4" style="text-align:end"><b>الإجمالي المستحق</b></td><td><b>${money(t.total,o.currency)}</b></td></tr></tbody></table>`;
}
function quote(id){
  need("finance");
  const q = S().quotes.find(x=>x.id===id); if(!q) throw new Error("العرض غير موجود");
  const c = S().customers.find(x=>x.id===q.customerId)||{};
  const canE = BOS.can(me(),"finance","create");
  const btn = (a,l,cls) => canE ? `<button class="btn ${cls||""}" data-q="${a}">${l}</button>` : "";
  return {title:q.no, html:`<div class="row no-print" style="margin-bottom:12px"><a class="btn" href="#/finance">→ المالية</a><span class="spacer"></span>
      ${q.status==="draft"?btn("sent","تسجيل الإرسال للعميل","primary"):""}${q.status==="sent"?btn("accepted","✓ وافق العميل","ok solid")+btn("rejected","رفض العميل","danger"):""}
      ${q.status==="accepted"?btn("invoice","تحويل إلى فاتورة","gold"):""}${q.invoiceId?`<a class="btn" href="#/invoice/${q.invoiceId}">فتح الفاتورة</a>`:""}<button class="btn" onclick="print()">🖨 طباعة / PDF</button></div>` +
    paper({title:"عرض سعر", no:q.no, date:q.createdAt, status:Q_STATUS[q.status][0], createdBy:(BOS.byId(q.createdBy)||{}).name, approvedBy:q.acceptedAt?"موافقة العميل " + fmtDate(q.acceptedAt):"", stamped:q.status!=="draft",
      body:`<dl class="kv" style="margin-top:14px"><dt>العميل</dt><dd>${esc(c.name)}</dd><dt>جهة الاتصال</dt><dd>${esc(c.contact||"—")}</dd><dt>صالح حتى</dt><dd>${fmtDate(q.due)}</dd>${q.ref?`<dt>المرجع</dt><dd>${esc(q.ref)}</dd>`:""}</dl>${itemsTable(q)}${q.terms?`<h2>الشروط</h2><p style="white-space:pre-wrap">${esc(q.terms)}</p>`:""}`}),
    bind: root => $$("[data-q]",root).forEach(b=>b.onclick=()=>{
      const a = b.dataset.q;
      if(a==="invoice") return itemsEditor("invoice", q);
      q.status = a; if(a==="accepted") q.acceptedAt = BOS.now();
      BOS.audit({sent:"إرسال عرض سعر",accepted:"موافقة العميل على عرض",rejected:"رفض العميل لعرض"}[a],"quote",q.id,q.no); BOS.save(); U.route();
    })};
}
function invoice(id){
  need("finance");
  const s = S(); const i = s.invoices.find(x=>x.id===id); if(!i) throw new Error("الفاتورة غير موجودة");
  const c = s.customers.find(x=>x.id===i.customerId)||{};
  const st = BOS.invoiceState(i); const t = BOS.totals(i.items,i.discount,i.taxRate); const paid = BOS.invoicePaid(i);
  const u = me(); const canE = BOS.can(u,"finance","create") || BOS.can(u,"finance","edit");
  const req = s.requests.find(r=>r.link && r.link.kind==="invoice" && r.link.id===i.id && r.status!=="cancelled");
  const b = (a,l,cls) => canE ? `<button class="btn ${cls||""}" data-i="${a}">${l}</button>` : "";
  return {title:i.no, html:`<div class="row no-print" style="margin-bottom:12px"><a class="btn" href="#/finance">→ المالية</a><span class="spacer"></span>
      ${i.status==="draft"?b("submit","إرسال للاعتماد","primary"):""}${req?`<a class="btn" href="#/request/${req.id}">مسار الاعتماد ${esc(req.no)}</a>`:""}
      ${["sent"].includes(i.status) && paid < t.total ? b("pay","تسجيل تحصيل","ok solid")+b("dispute","تسجيل نزاع") : ""}${i.status==="disputed"?b("resolve","إنهاء النزاع"):""}
      ${["draft","pending","sent"].includes(i.status) && !paid ? b("cancel","إلغاء","danger") : ""}<button class="btn" onclick="print()">🖨 طباعة / PDF</button></div>
    ${i.status==="pending"?'<div class="note no-print" style="margin-bottom:12px">الفاتورة بانتظار اكتمال مسار الاعتماد: تأكيد الإنجاز من مدير المشروع ← مراجعة المدير المالي ← المدير العام للاستثناءات ← الإرسال.</div>':""}` +
    paper({title:"فاتورة تجارية", no:i.no, date:i.createdAt, status:INV_STATUS[st][0], createdBy:(BOS.byId(i.createdBy)||{}).name, approvedBy:(BOS.byId(i.approvedBy)||{}).name, stamped:!!i.approvedBy,
      body:`<dl class="kv" style="margin-top:14px"><dt>العميل</dt><dd>${esc(c.name)}</dd><dt>تاريخ الاستحقاق</dt><dd>${fmtDate(i.due)}</dd>${i.ref?`<dt>رقم العقد/أمر الشراء</dt><dd>${esc(i.ref)}</dd>`:""}${i.quoteId?`<dt>عرض السعر</dt><dd>${esc((s.quotes.find(q=>q.id===i.quoteId)||{}).no)}</dd>`:""}<dt>العملة</dt><dd>${esc(i.currency)}</dd>${window.BOS_SEC && i.status!=="draft" ? `<dt>مرجع الدفع</dt><dd class="mono">${esc(BOS_SEC.paymentRef(i))}</dd>${(s.settings.payment||{}).account?`<dt>الحساب</dt><dd>${esc(s.settings.payment.bank)} — <span class="mono">${esc(s.settings.payment.account)}</span></dd>`:""}${(s.settings.payment||{}).instructions?`<dt>تعليمات</dt><dd>${esc(s.settings.payment.instructions)}</dd>`:""}` : ""}</dl>
        ${itemsTable(i)}
        ${(i.payments||[]).length?`<h2>التحصيلات</h2><table><thead><tr><th>الإيصال</th><th>التاريخ</th><th>الطريقة</th><th>المبلغ</th></tr></thead><tbody>${i.payments.map(p=>`<tr><td class="mono">${esc(p.receipt)}</td><td>${fmtDate(p.date)}</td><td>${esc(p.method)}</td><td>${money(p.amount,i.currency)}</td></tr>`).join("")}<tr><td colspan="3" style="text-align:end"><b>الرصيد المتبقي</b></td><td><b>${money(t.total-paid,i.currency)}</b></td></tr></tbody></table>`:""}
        ${i.terms?`<h2>الشروط</h2><p style="white-space:pre-wrap">${esc(i.terms)}</p>`:""}${i.cancelReason?`<p><b>سبب الإلغاء:</b> ${esc(i.cancelReason)}</p>`:""}`}),
    bind: root => $$("[data-i]",root).forEach(btn=>btn.onclick=()=>{
      const a = btn.dataset.i;
      try{
        if(a==="submit"){
          const r = BOS.createRequest("invoice",{invoiceNo:i.no, customer:c.name, amount:t.total, exception: Number(i.discount)>0},{title:"اعتماد فاتورة " + i.no + " — " + c.name, link:{kind:"invoice", id:i.id}});
          i.status = "pending"; BOS.save(); toast("أُرسلت للاعتماد: " + r.no,"ok"); return U.refresh();
        }
        if(a==="pay") return modal("تسجيل تحصيل — " + i.no, `<div class="grid g2"><div class="field"><label class="f">المبلغ</label><input class="input" type="number" name="amount" value="${t.total-paid}"></div>
          <div class="field"><label class="f">التاريخ</label><input class="input" type="date" name="date" value="${BOS.now().slice(0,10)}"></div>
          <div class="field"><label class="f">الطريقة</label><select class="input" name="method"><option>تحويل بنكي</option><option>نقداً</option><option>شيك</option><option>تطبيق دفع</option></select></div></div>`,
          [{label:"تسجيل وإصدار إيصال", cls:"primary", onClick:bg=>{ const f = formData(bg); if(!(f.amount>0)) throw new Error("مبلغ غير صالح"); if(f.amount > t.total-paid+0.001) throw new Error("المبلغ يتجاوز الرصيد");
            const p = {receipt:BOS.nextNo("RCPT"), amount:f.amount, date:f.date, method:f.method, by:u.id, at:BOS.now()}; i.payments.push(p);
            BOS.audit("تسجيل تحصيل وإصدار إيصال","invoice",i.id,i.no + " — " + p.receipt + " — " + f.amount + " " + i.currency); BOS.save(); U.route(); }}]);
        if(a==="cancel") return U.ask("إلغاء الفاتورة " + i.no, "سبب الإلغاء (الرقم لا يعاد استخدامه)", rsn=>{ i.status="cancelled"; i.cancelReason=rsn; if(req && ["in_review","executing"].includes(req.status)) BOS.act(req,"cancel",{comment:"إلغاء الفاتورة: "+rsn}); BOS.audit("إلغاء فاتورة","invoice",i.id,i.no+" — "+rsn); BOS.save(); U.route(); }, {okLabel:"إلغاء الفاتورة", cls:"danger solid"});
        if(a==="dispute") return U.ask("نزاع على الفاتورة " + i.no, "وصف النزاع", rsn=>{ i.status="disputed"; i.disputeNote=rsn; BOS.audit("تسجيل نزاع على فاتورة","invoice",i.id,i.no+" — "+rsn); BOS.save(); U.route(); });
        if(a==="resolve"){ i.status="sent"; BOS.audit("إنهاء نزاع","invoice",i.id,i.no); }
        BOS.save(); U.route();
      }catch(e){ toast(e.message,"bad"); }
    })};
}

/* =================== مسارات الموافقة (القسم 7) =================== */
function policies(){
  need("policies");
  const s = S(); const u = me(); const edit = BOS.isTop(u) || BOS.can(u,"policies","edit");
  const whoOpts = sel => `<option value="manager" ${sel==="manager"?"selected":""}>المدير المباشر</option><option value="creator" ${sel==="creator"?"selected":""}>منشئ الطلب (تنفيذ/إغلاق)</option>` + s.positions.map(p=>`<option value="${p.key}" ${p.key===sel?"selected":""}>${esc(p.title)}</option>`).join("");
  const condLabel = w => !w ? "دائماً" : w.any ? w.any.map(condLabel).join(" أو ") : w.flag ? "عند: " + ((Object.values(D.TYPES).flatMap(t=>t.fields).find(f=>f.k===w.flag)||{}).l||w.flag) : w.min==="gm" ? "المبلغ ≥ حد المدير العام" : "المبلغ ≥ " + w.min;
  return {title:"مسارات الموافقة", html: `${head("مسارات الموافقة", "حد المدير العام الحالي: " + money(s.settings.gmThreshold) + " · أي تغيير بعد بدء التشغيل يُسجل كتغيير نطاق")}
    ${Object.keys(s.policies).map(t=>`<div class="card"><div class="card-head"><h2>${typeIcon(t)} ${esc(typeName(t))}</h2>${edit?`<button class="btn sm" data-edit="${t}">تعديل المسار</button>`:""}</div>
      <div class="route-h">${s.policies[t].map((st,i)=>`${i?'<span class="arrow">←</span>':""}<span class="chip"><span class="muted small">${esc(D.STAGES[st.stage])} · ${esc(condLabel(st.when))}</span><b>${esc(st.label)}</b><span class="small">${esc(whoLabel(st.who))}</span></span>`).join("")}</div></div>`).join("")}`,
    bind: root => $$("[data-edit]",root).forEach(b=>b.onclick=()=>{
      const t = b.dataset.edit; const steps = BOS.clone(s.policies[t]);
      const flags = (D.TYPES[t].fields||[]).filter(f=>f.t==="check");
      const condOpts = w => { const v = !w ? "" : w.any ? "any" : w.flag ? "flag:"+w.flag : "min:"+w.min;
        return `<option value="">دائماً</option>${D.TYPES[t].amount?`<option value="min:gm" ${v==="min:gm"?"selected":""}>المبلغ ≥ حد المدير العام</option><option value="min:1" ${v==="min:1"?"selected":""}>عند وجود تكلفة</option>`:""}${flags.map(f=>`<option value="flag:${f.k}" ${v==="flag:"+f.k?"selected":""}>عند: ${esc(f.l)}</option>`).join("")}${v==="any"?'<option value="any" selected>مركب (كما هو)</option>':""}`; };
      const rowH = st => `<div class="row pstep" style="margin-bottom:8px;border:1px solid var(--line);border-radius:10px;padding:8px">
        <input class="input" data-k="label" value="${esc(st.label)}" style="flex:2;min-width:150px"><select class="input" data-k="who" style="flex:2;min-width:150px">${whoOpts(st.who)}</select>
        <select class="input" data-k="stage" style="flex:1;min-width:90px">${Object.entries(D.STAGES).map(([k,v])=>`<option value="${k}" ${k===st.stage?"selected":""}>${v}</option>`).join("")}</select>
        <select class="input" data-k="when" style="flex:2;min-width:150px">${condOpts(st.when)}</select>
        <button class="btn sm" data-up>▲</button><button class="btn sm danger" data-rm>✕</button></div>`;
      const bg = modal("تعديل مسار: " + typeName(t), `<div id="ps">${steps.map(rowH).join("")}</div><button class="btn sm" id="addst">＋ مرحلة</button>
        <div class="field" style="margin-top:12px"><label class="f">سبب التغيير (يسجل كتغيير نطاق) *</label><input class="input" name="why"></div>`,
        [{label:"حفظ المسار", cls:"primary", onClick:bg=>{
          const why = $("[name=why]",bg).value.trim(); if(!why) throw new Error("سبب التغيير إلزامي");
          const orig = s.policies[t];
          const out = $$(".pstep",bg).map((r,i)=>{ const w = $("[data-k=when]",r).value; const o = {label:$("[data-k=label]",r).value.trim()||"مرحلة", who:$("[data-k=who]",r).value, stage:$("[data-k=stage]",r).value};
            if(w==="any"){ const prev = orig.find(x=>x.label===o.label && x.when && x.when.any); if(prev) o.when = prev.when; }
            else if(w.startsWith("min:")) o.when = {min: w.slice(4)==="gm" ? "gm" : Number(w.slice(4))};
            else if(w.startsWith("flag:")) o.when = {flag:w.slice(5)};
            return o; });
          if(!out.length) throw new Error("المسار يحتاج مرحلة واحدة على الأقل");
          if(!out.some(o=>o.stage==="approve"||o.stage==="review")) throw new Error("يجب أن يتضمن المسار مرحلة مراجعة أو اعتماد واحدة على الأقل");
          s.policies[t] = out; BOS.audit("تغيير نطاق: تعديل مسار موافقة","policy",t,typeName(t) + " — " + why + " — " + out.map(o=>o.label).join(" ← ")); BOS.save(); toast("حُفظ المسار — يطبق على الطلبات الجديدة فقط","ok"); U.route(); }}], true);
      const wire = () => { $$("[data-rm]",bg).forEach(x=>x.onclick=()=>x.closest(".pstep").remove()); $$("[data-up]",bg).forEach(x=>x.onclick=()=>{ const r = x.closest(".pstep"); if(r.previousElementSibling) r.parentNode.insertBefore(r, r.previousElementSibling); }); };
      $("#addst",bg).onclick = () => { $("#ps",bg).insertAdjacentHTML("beforeend", rowH({label:"مرحلة جديدة", who:"manager", stage:"approve"})); wire(); };
      wire();
    })};
}

/* =================== سجل التدقيق (القسم 8.2) =================== */
function auditView(){
  need("audit");
  const s = S(); const u = me();
  const list = s.audit.slice().reverse();
  const actors = Array.from(new Set(s.audit.map(a=>a.actorName)));
  return {title:"سجل التدقيق", html: `${head("سجل التدقيق", s.audit.length + " حدث · إلحاق فقط، كل حدث مرتبط ببصمة الحدث السابق", '<button class="btn" id="verify">🔍 التحقق من سلامة السجل</button>' + (BOS.can(u,"audit","export")?'<button class="btn primary" id="csv">⬇ تقرير تدقيق كامل (CSV)</button>':""))}
    <div id="vres"></div>
    <div class="card"><div class="row" style="margin-bottom:12px"><select class="input" id="actor" style="max-width:220px"><option value="">كل المستخدمين</option>${actors.map(a=>`<option>${esc(a)}</option>`).join("")}</select><input class="input" id="q" placeholder="بحث في الإجراء أو التفاصيل" style="max-width:300px"></div>
    <div class="table-wrap"><table><thead><tr><th>#</th><th>الوقت</th><th>المستخدم</th><th>الإجراء</th><th>التفاصيل</th><th>البصمة</th></tr></thead><tbody>
    ${list.slice(0,800).map(a=>`<tr data-a="${esc(a.actorName)}" data-s="${esc(a.action+" "+a.details)}"><td class="mono">${a.seq}</td><td class="small">${fmtDT(a.at)}</td><td><b class="small">${esc(a.actorName)}</b><div class="muted small">${esc(a.actorPos)}</div></td><td>${esc(a.action)}</td><td class="small">${esc(a.details)}</td><td class="mono small muted">${esc(a.hash.slice(0,10))}</td></tr>`).join("")}
    </tbody></table></div></div>`,
    bind: root => {
      $("#verify",root).onclick = () => { const v = BOS.verifyAudit(); $("#vres",root).innerHTML = v.ok ? `<div class="note" style="margin-bottom:12px">✓ السجل سليم — ${v.count} حدث بتسلسل بصمات متصل.</div>` : `<div class="note bad" style="margin-bottom:12px">✕ تم اكتشاف عبث بالسجل عند الحدث رقم ${v.at}.</div>`; };
      if($("#csv",root)) $("#csv",root).onclick = () => {
        const rows = [["seq","at","actor","position","action","entity","entity_id","details","prev","hash"]].concat(s.audit.map(a=>[a.seq,a.at,a.actorName,a.actorPos,a.action,a.entity,a.entityId,a.details,a.prev,a.hash]));
        const csv = "﻿" + rows.map(r=>r.map(x=>'"'+String(x==null?"":x).replace(/"/g,'""')+'"').join(",")).join("\n");
        download(csv, "audit-" + BOS.now().slice(0,10) + ".csv", "text/csv");
        BOS.audit("تصدير سجل التدقيق","audit",null,s.audit.length + " حدث"); BOS.save();
      };
      const f = () => { const a = $("#actor",root).value, q = $("#q",root).value.trim(); $$("[data-a]",root).forEach(r=>r.classList.toggle("hidden",(a && r.dataset.a!==a) || (q && !r.dataset.s.includes(q)))); };
      $("#actor",root).onchange = f; $("#q",root).oninput = f;
    }};
}
function download(content, name, type){ const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob([content],{type})); a.download = name; a.click(); setTimeout(()=>URL.revokeObjectURL(a.href), 2000); }

/* =================== الإعدادات =================== */
function settings(){
  need("settings");
  const s = S(); const u = me(); const top = BOS.isTop(u); const c = s.company; const st = s.settings;
  const inp = (k,l,v,t) => `<div class="field"><label class="f">${l}</label><input class="input" name="${k}" type="${t||"text"}" value="${esc(v==null?"":v)}" ${top?"":"disabled"}></div>`;
  return {title:"الإعدادات", html: `${head("إعدادات الشركة", top?"":"عرض فقط — التعديل للمدير العام")}
    <div class="grid g2">
      <div class="card" id="co"><h2 style="margin-bottom:12px">بيانات الشركة</h2>
        ${inp("tradeName","الاسم التجاري",c.tradeName)}${inp("legalName","الاسم القانوني",c.legalName)}${inp("nameEn","الاسم بالإنجليزية",c.nameEn)}
        <div class="grid g2">${inp("state","الولاية",c.state)}${inp("locality","المحلية",c.locality)}</div>${inp("address","العنوان",c.address)}
        <div class="grid g2">${inp("email","البريد",c.email)}${inp("phone","الهاتف",c.phone)}</div>${inp("website","الموقع",c.website)}${inp("activity","مجال النشاط",c.activity)}</div>
      <div class="card" id="st"><h2 style="margin-bottom:12px">المالية والأمان</h2>
        <div class="grid g2">${inp("currency","العملة الأساسية",st.currency)}${inp("fiscalStart","بداية السنة المالية",st.fiscalStart)}
        ${inp("gmThreshold","حد اعتماد المدير العام",st.gmThreshold,"number")}${inp("taxRate","نسبة الرسوم/الضريبة الافتراضية %",st.taxRate,"number")}
        ${inp("sessionMinutes","انتهاء الجلسة (دقيقة)",st.sessionMinutes,"number")}${inp("leaveDays","رصيد الإجازة السنوي (يوم)",st.leaveDays,"number")}</div>
        <label class="check"><input type="checkbox" name="mfa" ${st.mfa?"checked":""} ${top?"":"disabled"}> المصادقة متعددة العوامل للمناصب الحساسة</label>
        <label class="check"><input type="checkbox" name="autoEscalate" ${st.autoEscalate?"checked":""} ${top?"":"disabled"}> التصعيد التلقائي عند تجاوز المهلة</label>
        ${inp("recovery","سياسة استعادة الحساب",st.recovery)}
        <h3 style="margin:12px 0 6px">الوحدات المفعلة</h3>${D.MODULES.filter(m=>!m.core).map(m=>`<label class="check"><input type="checkbox" data-mod="${m.key}" ${st.modules[m.key]!==false?"checked":""} ${top?"":"disabled"}> ${m.icon} ${esc(m.name)}</label>`).join("")}</div>
    </div>
    ${top?'<div class="row" style="margin-top:14px"><span class="spacer"></span><button class="btn primary" id="save">حفظ الإعدادات</button></div>':""}
    <div class="card" style="margin-top:14px"><h2 style="margin-bottom:10px">النسخ الاحتياطي والبيانات</h2>
      <p class="small muted">البيانات في هذه النسخة الأولية محفوظة في متصفح هذا الجهاز. صدّر نسخة احتياطية دورياً واختبر استعادتها.</p>
      <div class="row">${BOS.can(u,"settings","export")||top?'<button class="btn" id="backup">⬇ تصدير نسخة احتياطية (JSON)</button>':""}${top?'<button class="btn" id="restore">⬆ استعادة</button><button class="btn danger" id="wipe">حذف كل البيانات</button>':""}</div></div>`,
    bind: root => {
      if($("#save",root)) $("#save",root).onclick = () => {
        const cf = formData($("#co",root)), sf = formData($("#st",root));
        const diff = Object.keys(sf).filter(k=>String(st[k])!==String(sf[k]));
        Object.assign(c, cf); Object.assign(st, sf); $$("[data-mod]",root).forEach(x=>st.modules[x.dataset.mod]=x.checked);
        BOS.audit("تعديل إعدادات الشركة","settings",null, diff.length ? "تغيير: " + diff.join("، ") : "بيانات الشركة"); BOS.save(); toast("تم الحفظ","ok"); U.refresh();
      };
      if($("#backup",root)) $("#backup",root).onclick = () => { BOS.audit("تصدير نسخة احتياطية","settings",null,""); BOS.save(); download(JSON.stringify(Object.assign({}, s, {session:null}), null, 1), "bushra-os-backup-" + BOS.now().slice(0,10) + ".json", "application/json"); };
      if($("#restore",root)) $("#restore",root).onclick = U.importBackup;
      if($("#wipe",root)) $("#wipe",root).onclick = () => U.ask("حذف كل البيانات", "للتأكيد اكتب اسم الشركة: " + c.tradeName, n=>{ if(n!==c.tradeName) throw new Error("الاسم غير مطابق"); BOS.reset(); location.hash=""; U.render(); }, {okLabel:"حذف نهائي", cls:"danger solid"});
    }};
}

window.BOS_VIEWS_CORE = {customerEditor, paper, reqTable, bindRows, clsBadge};
window.BOS_VIEWS = {home, dashboard, org, people, person, requests, new:newReq, request, approvals, notifications, documents, doc, "print-doc":printDoc, customers, finance, quote, invoice, policies, audit:auditView, settings};
})();
