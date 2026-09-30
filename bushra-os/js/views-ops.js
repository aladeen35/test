/* نظام البشرى لإدارة الشركة — صفحات المرحلة الثالثة: المشاريع، الاختبار، الجودة، الدعم */
(function(){
"use strict";
const D = window.BOS_DATA;
const U = window.BOS_UI;
const O = window.BOS_OPS;
const {$, $$, esc, fmtDate, fmtDT, money, avatar, empName, statusBadge, toast, modal, formData, userOptions} = U;
const S = () => BOS.S;
const me = () => BOS.me();
const go = h => { location.hash = h; };
const need = (mod, act) => { if(!BOS.can(me(), mod, act||"view")) throw new Error("لا تملك صلاحية الوصول إلى هذه الصفحة — راجع مدير النظام."); };
const empty = t => `<div class="empty">${esc(t)}</div>`;
const head = (title, sub, actions) => `<div class="page-head"><div><h1>${esc(title)}</h1>${sub?`<div class="sub">${sub}</div>`:""}</div><div class="actions">${actions||""}</div></div>`;
const kpi = (lbl, val, hint, cls) => `<div class="card kpi ${cls||""}"><div class="lbl">${esc(lbl)}</div><div class="val">${val}</div>${hint?`<div class="hint">${hint}</div>`:""}</div>`;
const bindRows = root => $$("[data-go]", root).forEach(el=>el.onclick = e => { if(e.target.closest("button,a,input,select,textarea")) return; go(el.dataset.go); });
const safe = fn => { try{ fn(); }catch(e){ toast(e.message,"bad"); } };
const act = (fn, msg) => { try{ fn(); if(msg) toast(msg,"ok"); U.refresh(); }catch(e){ toast(e.message,"bad"); } };
const pct = v => v==null ? "—" : v + "%";
const hrs = v => v==null ? "—" : (v < 48 ? v.toFixed(1) + " ساعة" : (v/24).toFixed(1) + " يوم");
const custName = id => esc((S().customers.find(c=>c.id===id)||{}).name || "—");
const PS_CLS = {draft:"", contracting:"warn", approved:"info", planning:"info", production:"accent", testing:"accent", acceptance:"warn", launch:"ok", support:"ok", closed:""};
const pBadge = s => `<span class="badge ${PS_CLS[s]||""}">${esc(O.PSTATUS[s]||s)}</span>`;
const SEV_CLS = {critical:"bad", high:"bad", medium:"warn", low:""};
const sevBadge = s => `<span class="badge ${SEV_CLS[s]}">${esc(O.SEVERITY[s])}</span>`;
const BUG_CLS = {open:"bad", fixing:"warn", fixed:"info", closed:"ok", reopened:"bad", deferred:""};
const bugBadge = s => `<span class="badge ${BUG_CLS[s]}">${esc(O.BUG_STATUS[s])}</span>`;
const RES_CLS = {pass:"ok", fail:"bad", blocked:"warn"};
const resBadge = r => r ? `<span class="badge ${RES_CLS[r.result]}">${esc(O.RESULT[r.result])}</span>` : '<span class="badge">لم يُنفذ</span>';
const TS_CLS = {new:"bad", verified:"warn", classified:"warn", handling:"info", referred:"info", proposed:"accent", closed:"ok"};
const tBadge = s => `<span class="badge ${TS_CLS[s]}">${esc(O.TSTATUS[s])}</span>`;
const PR_CLS = {P1:"bad", P2:"warn", P3:"info", P4:""};
const prBadge = p => `<span class="badge ${PR_CLS[p]}">${esc(p)}</span>`;
const bar = (v, cls) => `<div class="bar"><i style="width:${Math.max(0,Math.min(100,v||0))}%;${cls||""}"></i></div>`;
const tabs = (list, on, base) => `<div class="tabs">${list.map(([k,l])=>`<button class="${k===on?"on":""}" data-href="${base}/${k}">${l}</button>`).join("")}</div>`;
const bindTabs = root => $$("[data-href]",root).forEach(b=>b.onclick=()=>go(b.dataset.href));
const projOptions = (sel, filter) => S().projects.filter(p=>O.canSeeProject(me(),p) && (!filter||filter(p))).map(p=>`<option value="${p.id}" ${p.id===sel?"selected":""}>${esc(p.no)} — ${esc(p.name)}</option>`).join("");

/* =================== المشاريع =================== */
function projects(){
  need("projects");
  const u = me(); const list = S().projects.filter(p=>O.canSeeProject(u,p)); const m = O.metrics();
  const demo = S().employees.some(e=>e.demo) && !S().projects.length;
  return {title:"المشاريع", html: `
    ${head("المشاريع والإنتاج", "مسودة ← بانتظار التعاقد ← معتمد ← تخطيط ← إنتاج ← اختبار ← قبول العميل ← إطلاق ← دعم ← مغلق",
      (demo?'<button class="btn" id="seed">إنشاء مشروع تجريبي</button>':"") + (BOS.can(u,"projects","create")?'<button class="btn primary" id="new">＋ مشروع</button>':""))}
    <div class="grid g4">${kpi("مشاريع نشطة", m.activeProjects)}${kpi("متأخرة عن موعدها", m.lateProjects, "", m.lateProjects?"bad":"ok")}${kpi("عالية المخاطر", m.highRisk, "خطر عالي مفتوح", m.highRisk?"warn":"")}${kpi("التسليم في الموعد", pct(m.onTime), "مراحل التسليم المنجزة")}</div>
    <div class="card" style="margin-top:14px">${list.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>المشروع</th><th>العميل</th><th>مدير المشروع</th><th>المرحلة</th><th>التقدم</th><th>عيوب مفتوحة</th><th>الموعد</th></tr></thead><tbody>
    ${list.map(p=>{ const ts = O.projTasks(p); const done = ts.filter(t=>t.status==="done").length; const pr = ts.length?Math.round(done/ts.length*100):0; const late = p.end && p.end < BOS.now().slice(0,10) && !["closed","launch","support"].includes(p.status);
      return `<tr class="link" data-go="#/project/${p.id}"><td class="mono">${esc(p.no)}</td><td><b>${esc(p.name)}</b>${p.strategic?' <span class="badge gold" style="background:var(--warn-soft);color:var(--warn)">استراتيجي</span>':""}</td><td class="small">${custName(p.customerId)}</td><td class="small">${empName(p.pmId)}</td><td>${pBadge(p.status)}</td>
      <td style="min-width:110px"><div class="small">${done}/${ts.length} مهمة</div>${bar(pr)}</td><td>${O.openBugs(p).length||"—"}</td><td class="small">${p.end?fmtDate(p.end):"—"} ${late?'<span class="badge bad">متأخر</span>':""}</td></tr>`; }).join("")}
    </tbody></table></div>`:empty("لا توجد مشاريع ضمن نطاقك")}</div>`,
    bind: root => { bindRows(root);
      if($("#new",root)) $("#new",root).onclick = projectEditor;
      if($("#seed",root)) $("#seed",root).onclick = () => act(()=>{ const p = O.seedOps(); setTimeout(()=>go("#/project/"+p.id),0); }, "أُنشئ مشروع تجريبي"); }};
}
function projectEditor(){
  const s = S();
  const quotes = s.quotes.filter(q=>["accepted","invoiced"].includes(q.status) && !s.projects.some(p=>p.quoteId===q.id));
  const contracts = s.requests.filter(r=>r.type==="contract" && r.status==="closed");
  modal("مشروع جديد", `
    <div class="note small" style="margin-bottom:12px">يُنشأ المشروع من عرض سعر وافق عليه العميل أو عقد معتمد. يمكن البدء بمسودة، لكن الانتقال إلى «معتمد» يتطلب أحدهما.</div>
    <div class="grid g2">
      <div class="field"><label class="f">اسم المشروع *</label><input class="input" name="name"></div>
      <div class="field"><label class="f">العميل</label><select class="input" name="customerId"><option value="">—</option>${s.customers.map(c=>`<option value="${c.id}">${esc(c.name)}</option>`).join("")}</select></div>
      <div class="field"><label class="f">عرض السعر المعتمد</label><select class="input" name="quoteId"><option value="">—</option>${quotes.map(q=>`<option value="${q.id}">${esc(q.no)} — ${custName(q.customerId)}</option>`).join("")}</select></div>
      <div class="field"><label class="f">طلب العقد المعتمد</label><select class="input" name="contractRequestId"><option value="">—</option>${contracts.map(r=>`<option value="${r.id}">${esc(r.no)} — ${esc(r.data.subject||"")}</option>`).join("")}</select></div>
      <div class="field"><label class="f">مدير المشروع</label><select class="input" name="pmId">${userOptions((BOS.holderOf("pm")||{}).id||me().id)}</select></div>
      <div class="field"><label class="f">الميزانية</label><input class="input" type="number" name="budget"></div>
      <div class="field"><label class="f">البداية</label><input class="input" type="date" name="start" value="${BOS.now().slice(0,10)}"></div>
      <div class="field"><label class="f">موعد التسليم</label><input class="input" type="date" name="end"></div>
    </div>
    <div class="field"><label class="f">النطاق</label><textarea class="input" name="scope"></textarea></div>
    <div class="field"><label class="f">المخرجات</label><textarea class="input" name="deliverables"></textarea></div>
    <label class="check"><input type="checkbox" name="strategic"> مشروع استراتيجي (إطلاقه يتطلب المدير العام)</label>`,
    [{label:"إنشاء", cls:"primary", onClick:bg=>{ const f = formData(bg); const p = O.createProject(f); go("#/project/"+p.id); }}], true);
}
function flowBar(p){
  const idx = O.PROJECT_FLOW.findIndex(x=>x[0]===p.status);
  return `<div class="route-h" style="margin-bottom:14px">${O.PROJECT_FLOW.map(([k,l],i)=>`${i?'<span class="arrow">←</span>':""}<span class="chip" style="${i<idx?"border-color:var(--ok);color:var(--ok)":i===idx?"border-color:var(--accent);background:var(--accent-soft);font-weight:700":"opacity:.6"}">${i<idx?"✓ ":""}${esc(l)}</span>`).join("")}</div>`;
}
function project(id, tab){
  need("projects");
  const p = O.project(id); const u = me();
  if(!p) throw new Error("المشروع غير موجود");
  if(!O.canSeeProject(u,p)){ BOS.audit("محاولة وصول مرفوضة","project",p.id,p.no); BOS.save(); throw new Error("المشروع خارج نطاق رؤيتك"); }
  tab = tab || "overview";
  const pm = O.isPM(u,p) && BOS.can(u,"projects","edit");
  const order = O.PROJECT_FLOW.map(x=>x[0]); const next = order[order.indexOf(p.status)+1];
  const bl = next ? O.blockers(p,next) : [];
  const base = "#/project/" + p.id;
  const T = [["overview","نظرة عامة"],["tasks","المهام ("+O.projTasks(p).length+")"],["tests","الاختبار"],["bugs","العيوب ("+O.openBugs(p).length+")"],["quality","الجودة"],["meetings","المحاضر"],["delivery","التسليم والإطلاق"]];
  const body = ({overview:pOverview, tasks:pTasks, tests:pTests, bugs:pBugs, quality:pQuality, meetings:pMeetings, delivery:pDelivery}[tab] || pOverview)(p, pm);
  return {title:p.no, html: `
    ${head("🗂️ " + p.name, `<span class="mono">${esc(p.no)}</span> · ${pBadge(p.status)} · العميل: ${custName(p.customerId)} · مدير المشروع: ${empName(p.pmId)} · الإصدار <span class="mono">${esc(p.version)}</span>`,
      (pm && next ? `<button class="btn ${bl.length?"":"primary"}" id="next">الانتقال إلى «${esc(O.PSTATUS[next])}»</button>` : "") + (pm && p.status!=="draft" ? '<button class="btn" id="back">رجوع لمرحلة سابقة</button>' : "") + (pm?'<button class="btn" id="edit">تعديل</button>':""))}
    ${flowBar(p)}
    ${next && bl.length ? `<div class="note warn" style="margin-bottom:14px"><b>موانع الانتقال إلى «${esc(O.PSTATUS[next])}»:</b><ul style="margin:4px 0 0">${bl.map(b=>`<li>${esc(b)}</li>`).join("")}</ul></div>` : ""}
    ${tabs(T, tab, base)}${body.html}`,
    bind: root => {
      bindTabs(root); bindRows(root);
      if($("#next",root)) $("#next",root).onclick = () => {
        if(!bl.length) return act(()=>O.moveProject(p,next), "انتقل المشروع إلى «" + O.PSTATUS[next] + "»");
        if(BOS.isTop(u) && next!=="acceptance") return modal("استثناء المدير العام", `<p class="small">الموانع: ${bl.map(esc).join(" · ")}</p><div class="field"><label class="f">سبب الاستثناء (يظهر في سجل التدقيق) *</label><textarea class="input" name="why"></textarea></div>`,
          [{label:"اعتماد الاستثناء والانتقال", cls:"danger solid", onClick:bg=>{ O.moveProject(p,next,$("[name=why]",bg).value.trim()); U.refresh(); }}]);
        toast("أزل الموانع أولاً" + (next==="acceptance"?" — بوابة الجودة لا تقبل الاستثناء":""),"bad");
      };
      if($("#back",root)) $("#back",root).onclick = () => modal("إرجاع المشروع لمرحلة سابقة", `<div class="field"><label class="f">المرحلة</label><select class="input" name="to">${order.slice(0,order.indexOf(p.status)).map(k=>`<option value="${k}">${esc(O.PSTATUS[k])}</option>`).join("")}</select></div><div class="field"><label class="f">السبب *</label><input class="input" name="why"></div>`,
        [{label:"إرجاع", cls:"primary", onClick:bg=>{ const f = formData(bg); O.moveProject(p,f.to,f.why); U.refresh(); }}]);
      if($("#edit",root)) $("#edit",root).onclick = () => modal("تعديل " + p.name, `<div class="grid g2"><div class="field"><label class="f">الاسم</label><input class="input" name="name" value="${esc(p.name)}"></div>
        <div class="field"><label class="f">الإصدار الحالي</label><input class="input mono" name="version" value="${esc(p.version)}" dir="ltr"></div>
        <div class="field"><label class="f">موعد التسليم</label><input class="input" type="date" name="end" value="${esc(p.end)}"></div>
        <div class="field"><label class="f">مرجع العقد / أمر الشراء</label><input class="input" name="contractRef" value="${esc(p.contractRef)}"></div>
        <div class="field"><label class="f">طلب العقد المعتمد</label><select class="input" name="contractRequestId"><option value="">—</option>${S().requests.filter(r=>r.type==="contract"&&r.status==="closed").map(r=>`<option value="${r.id}" ${r.id===p.contractRequestId?"selected":""}>${esc(r.no)}</option>`).join("")}</select></div>
        <div class="field"><label class="f">العميل</label><select class="input" name="customerId"><option value="">—</option>${S().customers.map(c=>`<option value="${c.id}" ${c.id===p.customerId?"selected":""}>${esc(c.name)}</option>`).join("")}</select></div></div>
        <div class="field"><label class="f">المخرجات</label><textarea class="input" name="deliverables">${esc(p.deliverables)}</textarea></div>
        <label class="check"><input type="checkbox" name="strategic" ${p.strategic?"checked":""}> مشروع استراتيجي</label>
        <p class="small muted">النطاق لا يُعدل هنا؛ أي تغيير فيه يمر عبر «طلب تغيير نطاق».${p.version!=="" ? " تغيير رقم الإصدار يتطلب إعادة تنفيذ الاختبارات وبوابة الجودة عليه." : ""}</p>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); const ch = Object.keys(f).filter(k=>String(p[k]||"")!==String(f[k]||""));
          Object.assign(p,f); BOS.audit("تعديل بيانات مشروع","project",p.id,p.no + (ch.length?" — " + ch.join("، "):"")); BOS.save(); U.route(); }}], true);
      body.bind && body.bind(root);
    }};
}
function pOverview(p, pm){
  const ts = O.projTasks(p); const st = O.testStats(p);
  const spent = ts.reduce((a,t)=>a+t.hours.reduce((x,h)=>x+h.h,0),0);
  const crs = (p.changeRequests||[]).map(id=>S().requests.find(r=>r.id===id)).filter(Boolean);
  const rel = p.releaseRequestId && S().requests.find(r=>r.id===p.releaseRequestId);
  return {html:`
    <div class="grid g4">${kpi("المهام المكتملة", ts.filter(t=>t.status==="done").length + "/" + ts.length)}${kpi("نجاح الاختبارات", st.run?st.rate+"%":"—", st.run + "/" + st.total + " منفذة على " + esc(p.version), st.run && st.rate<Number(S().settings.passRate||95)?"warn":"")}
      ${kpi("عيوب حرجة/عالية مفتوحة", O.openBugs(p,["critical","high"]).length, O.openBugs(p).length + " إجمالي مفتوح", O.openBugs(p,["critical","high"]).length?"bad":"ok")}${kpi("بوابة الجودة", O.gatePassed(p)?"مجتازة":"—", O.latestGate(p)?"آخر مراجعة " + fmtDate(O.latestGate(p).at):"لم تُسجل", O.gatePassed(p)?"ok":"")}</div>
    <div class="grid g2" style="margin-top:14px">
      <div class="card"><h2 style="margin-bottom:10px">النطاق والمخرجات</h2><dl class="kv">
        <dt>النطاق</dt><dd style="white-space:pre-wrap">${esc(p.scope)||"—"}</dd><dt>المخرجات</dt><dd style="white-space:pre-wrap">${esc(p.deliverables)||"—"}</dd>
        <dt>الميزانية</dt><dd>${money(p.budget,p.currency)}</dd><dt>الساعات المسجلة</dt><dd>${spent} ساعة من ${ts.reduce((a,t)=>a+(t.estimate||0),0)} مقدرة</dd>
        <dt>المدة</dt><dd>${fmtDate(p.start)} ← ${p.end?fmtDate(p.end):"—"}</dd><dt>العقد</dt><dd>${esc(p.contractRef||"—")} ${p.quoteId?`· <a href="#/quote/${p.quoteId}">عرض السعر</a>`:""} ${p.contractRequestId?`· <a href="#/request/${p.contractRequestId}">طلب العقد</a>`:""}</dd>
        <dt>الفريق</dt><dd>${[p.pmId,...(p.members||[])].map(id=>empName(id)).join("، ")}</dd></dl>
        ${pm?'<div class="row" style="margin-top:12px"><button class="btn" id="cr">🔁 طلب تغيير نطاق</button></div>':""}
        ${crs.length?`<h3 style="margin:12px 0 6px">طلبات تغيير النطاق</h3>${crs.map(r=>`<div class="small"><a href="#/request/${r.id}">${esc(r.no)}</a> ${statusBadge(r.status)} — ${esc((r.data.change||"").slice(0,80))}</div>`).join("")}`:""}</div>
      <div class="card"><div class="card-head"><h2>مراحل التسليم</h2>${pm?'<button class="btn sm" id="add-ms">＋</button>':""}</div>
        ${p.milestones.length?p.milestones.map(m=>{ const mt = ts.filter(t=>t.milestoneId===m.id); const d = mt.filter(t=>t.status==="done").length;
          return `<div class="list-item"><span class="badge ${m.status==="done"?(m.onTime?"ok":"warn"):""}">${m.status==="done"?(m.onTime?"✓ في الموعد":"✓ متأخر"):"مفتوحة"}</span><div class="grow"><b>${esc(m.title)}</b><div class="small muted">الموعد ${fmtDate(m.due)} · ${d}/${mt.length} مهمة</div>${bar(mt.length?d/mt.length*100:0)}</div>${pm?`<button class="btn sm" data-ms="${m.id}">${m.status==="done"?"إعادة فتح":"إنجاز"}</button>`:""}</div>`; }).join(""):empty("لا توجد مراحل تسليم")}
        <div class="card-head" style="margin-top:14px"><h2>المخاطر</h2>${pm?'<button class="btn sm" id="add-risk">＋</button>':""}</div>
        ${p.risks.length?p.risks.map(r=>`<div class="list-item"><span class="badge ${r.impact==="عالي"?"bad":r.impact==="متوسط"?"warn":""}">${esc(r.impact)}</span><div class="grow small"><b>${esc(r.text)}</b><div class="muted">الاحتمال ${esc(r.prob)} · المالك ${empName(r.ownerId)} · ${esc(r.mitigation)}</div></div>${pm?`<button class="btn sm" data-risk="${r.id}">${r.status==="open"?"إغلاق":"فتح"}</button>`:`<span class="small">${r.status==="open"?"مفتوح":"مغلق"}</span>`}</div>`).join(""):empty("لا مخاطر مسجلة")}
      </div>
    </div>
    <div class="card" style="margin-top:14px"><h2 style="margin-bottom:10px">سجل المراحل</h2>${p.history.slice().reverse().map(h=>`<div class="small list-item"><span class="muted">${fmtDT(h.at)}</span><div class="grow">${h.from?esc(O.PSTATUS[h.from]) + " ← ":""}<b>${esc(O.PSTATUS[h.to])}</b> — ${empName(h.by)} ${h.override?'<span class="badge bad">استثناء</span>':""} ${esc(h.note||"")}</div></div>`).join("")}
      ${rel?`<div class="small" style="margin-top:8px">طلب الإطلاق: <a href="#/request/${rel.id}">${esc(rel.no)}</a> ${statusBadge(rel.status)}</div>`:""}</div>`,
    bind: root => {
      if($("#cr",root)) $("#cr",root).onclick = () => modal("طلب تغيير نطاق — " + p.name, `<div class="field"><label class="f">التغيير المطلوب *</label><textarea class="input" name="change"></textarea></div>
        <div class="grid g2"><div class="field"><label class="f">الأثر على المدة (يوم)</label><input class="input" type="number" name="days" value="0"></div><div class="field"><label class="f">الأثر المالي</label><input class="input" type="number" name="amount" value="0"></div></div>
        <label class="check"><input type="checkbox" name="clientRequested"> بطلب من العميل</label><p class="small muted">يمر الطلب بمسار «تغيير النطاق»، ولا يتغير نطاق المشروع أو ميزانيته إلا بعد اكتماله.</p>`,
        [{label:"إرسال", cls:"primary", onClick:bg=>{ const f = formData(bg); if(!f.change) throw new Error("وصف التغيير إلزامي"); const r = O.requestChange(p,f); toast("أُرسل " + r.no,"ok"); U.refresh(); }}]);
      if($("#add-ms",root)) $("#add-ms",root).onclick = () => modal("مرحلة تسليم", `<div class="field"><label class="f">العنوان *</label><input class="input" name="title"></div><div class="field"><label class="f">الموعد</label><input class="input" type="date" name="due"></div>`,
        [{label:"إضافة", cls:"primary", onClick:bg=>{ O.addMilestone(p,formData(bg)); U.route(); }}]);
      $$("[data-ms]",root).forEach(b=>b.onclick=()=>act(()=>O.toggleMilestone(p, p.milestones.find(m=>m.id===b.dataset.ms))));
      if($("#add-risk",root)) $("#add-risk",root).onclick = () => modal("تسجيل خطر", `<div class="field"><label class="f">الخطر *</label><input class="input" name="text"></div>
        <div class="grid g2"><div class="field"><label class="f">الأثر</label><select class="input" name="impact"><option>منخفض</option><option selected>متوسط</option><option>عالي</option></select></div><div class="field"><label class="f">الاحتمال</label><select class="input" name="prob"><option>منخفض</option><option selected>متوسط</option><option>عالي</option></select></div>
        <div class="field"><label class="f">المالك</label><select class="input" name="ownerId">${userOptions(p.pmId)}</select></div></div><div class="field"><label class="f">خطة التخفيف</label><input class="input" name="mitigation"></div>`,
        [{label:"إضافة", cls:"primary", onClick:bg=>{ O.addRisk(p,formData(bg)); U.route(); }}]);
      $$("[data-risk]",root).forEach(b=>b.onclick=()=>{ const r = p.risks.find(x=>x.id===b.dataset.risk); r.status = r.status==="open"?"closed":"open"; BOS.audit("تحديث خطر","project",p.id,p.no + " — " + r.text + " — " + r.status); BOS.save(); U.route(); });
    }};
}
function taskCard(t, p){
  const u = me(); const hrsDone = t.hours.reduce((a,h)=>a+h.h,0);
  const late = t.due && t.due < BOS.now().slice(0,10) && t.status!=="done";
  return `<div class="card" style="padding:10px 12px;margin-bottom:8px;box-shadow:none" data-task="${t.id}">
    <div class="row small"><span class="mono muted">${esc(t.no)}</span><span class="spacer"></span>${late?'<span class="badge bad">متأخرة</span>':""}${t.reworkCount?`<span class="badge warn">إعادة ×${t.reworkCount}</span>`:""}</div>
    <b style="font-size:.9rem">${esc(t.title)}</b>
    <div class="small muted">المنفذ: ${empName(t.ownerId)} · المراجع: ${t.reviewerId?empName(t.reviewerId):'<span style="color:var(--bad)">غير معين</span>'}</div>
    <div class="small" style="margin-top:4px">🎯 ${esc(t.criteria||"— لا يوجد معيار قبول")}</div>
    <div class="small muted">${t.due?"الموعد " + fmtDate(t.due) + " · ":""}${hrsDone}/${t.estimate||0} ساعة${t.verifiedBy?` · ✓ تحقق ${empName(t.verifiedBy)}`:""}</div>
    <div class="row" style="margin-top:6px;gap:4px">
      ${t.status==="todo" && (t.ownerId===u.id||O.isPM(u,p)) ? `<button class="btn sm" data-tm="doing">▶ بدء</button>`:""}
      ${["doing","blocked"].includes(t.status) && (t.ownerId===u.id||O.isPM(u,p)) ? `<button class="btn sm primary" data-tm="review">إرسال للمراجعة</button>`:""}
      ${t.status==="doing" && (t.ownerId===u.id||O.isPM(u,p)) ? `<button class="btn sm" data-tm="blocked">محجوبة</button>`:""}
      ${t.status==="review" && (t.reviewerId===u.id||BOS.isTop(u)) && t.ownerId!==u.id ? `<button class="btn sm ok solid" data-tm="done">✓ تحقق المعيار</button><button class="btn sm" data-tm="doing">↩ إعادة</button>`:""}
      ${t.status==="done" && O.isPM(u,p) ? `<button class="btn sm" data-tm="doing">إعادة فتح</button>`:""}
      ${t.status!=="done" && t.ownerId===u.id ? `<button class="btn sm" data-th>⏱ وقت</button>`:""}
      ${O.isPM(u,p) && t.status!=="done" ? `<button class="btn sm" data-te>✎</button>`:""}
    </div></div>`;
}
function pTasks(p, pm){
  const ts = O.projTasks(p); const u = me();
  const canAdd = BOS.can(u,"projects","edit") && (pm || (p.members||[]).includes(u.id)) && p.status!=="closed";
  const cols = ["todo","doing","review","done","blocked"];
  return {html:`<div class="row" style="margin-bottom:12px"><span class="small muted">لا تنتقل المهمة إلى «مكتملة» إلا بعد تحقق معيار قبولها بواسطة مراجع غير المنفذ.</span><span class="spacer"></span>${canAdd?'<button class="btn primary" id="add-task">＋ مهمة</button>':""}</div>
    <div class="grid" style="grid-template-columns:repeat(auto-fit,minmax(220px,1fr));align-items:start">${cols.map(c=>{ const l = ts.filter(t=>t.status===c); if(c==="blocked" && !l.length) return "";
      return `<div class="card" style="background:var(--surface-2);padding:12px"><div class="row" style="margin-bottom:8px"><b>${esc(O.TASK_STATUS[c])}</b><span class="spacer"></span><span class="badge">${l.length}</span></div>${l.map(t=>taskCard(t,p)).join("")||'<div class="muted small">—</div>'}</div>`; }).join("")}</div>`,
    bind: root => {
      if($("#add-task",root)) $("#add-task",root).onclick = () => taskEditor(p, null);
      $$("[data-task]",root).forEach(card=>{
        const t = S().tasks.find(x=>x.id===card.dataset.task);
        $$("[data-tm]",card).forEach(b=>b.onclick=()=>{
          const to = b.dataset.tm;
          if(to==="done") return modal("التحقق من معيار القبول — " + t.title, `<div class="note" style="margin-bottom:10px">🎯 ${esc(t.criteria)}</div><label class="check"><input type="checkbox" name="verified"> تحققت بنفسي من أن المعيار متحقق بالكامل</label><div class="field" style="margin-top:8px"><label class="f">ملاحظة التحقق</label><input class="input" name="comment"></div>`,
            [{label:"إقفال المهمة", cls:"ok solid", onClick:bg=>{ O.moveTask(t,"done",formData(bg)); U.refresh(); }}]);
          if(to==="doing" && t.status==="review") return modal("إعادة المهمة للمنفذ", `<div class="field"><label class="f">ما الذي لم يتحقق؟ *</label><textarea class="input" name="comment"></textarea></div>`,
            [{label:"إعادة", cls:"primary", onClick:bg=>{ O.moveTask(t,"doing",formData(bg)); U.refresh(); }}]);
          if(to==="doing" && t.status==="done") { const c = prompt("سبب إعادة فتح المهمة:"); if(!c) return; return act(()=>O.moveTask(t,"doing",{comment:c})); }
          act(()=>O.moveTask(t,to,{}));
        });
        const th = $("[data-th]",card); if(th) th.onclick = () => { const h = prompt("عدد الساعات:"); if(h) act(()=>O.logHours(t,h)); };
        const te = $("[data-te]",card); if(te) te.onclick = () => taskEditor(p, t);
      });
    }};
}
function taskEditor(p, t){
  const isNew = !t; t = t || {};
  const team = x => x.id===p.pmId || (p.members||[]).includes(x.id) || ["dev","designer","devlead","staff","testlead"].includes((BOS.pos(x.positionId)||{}).key);
  modal(isNew?"مهمة جديدة":"تعديل " + t.no, `<div class="field"><label class="f">العنوان *</label><input class="input" name="title" value="${esc(t.title||"")}"></div>
    <div class="grid g2"><div class="field"><label class="f">المنفذ</label><select class="input" name="ownerId">${userOptions(t.ownerId, team)}</select></div>
    <div class="field"><label class="f">المراجع (غير المنفذ) *</label><select class="input" name="reviewerId"><option value="">—</option>${userOptions(t.reviewerId, team)}</select></div>
    <div class="field"><label class="f">مرحلة التسليم</label><select class="input" name="milestoneId"><option value="">—</option>${p.milestones.map(m=>`<option value="${m.id}" ${m.id===t.milestoneId?"selected":""}>${esc(m.title)}</option>`).join("")}</select></div>
    <div class="field"><label class="f">الأولوية</label><select class="input" name="priority">${["منخفضة","متوسطة","عالية","حرجة"].map(x=>`<option ${x===(t.priority||"متوسطة")?"selected":""}>${x}</option>`).join("")}</select></div>
    <div class="field"><label class="f">الموعد</label><input class="input" type="date" name="due" value="${esc(t.due||"")}"></div>
    <div class="field"><label class="f">التقدير (ساعة)</label><input class="input" type="number" name="estimate" value="${esc(t.estimate||"")}"></div>
    <div class="field"><label class="f">المستند المرتبط</label><select class="input" name="docId"><option value="">—</option>${S().documents.filter(d=>BOS.canSeeDoc(me(),d)).map(d=>`<option value="${d.id}" ${d.id===t.docId?"selected":""}>${esc(d.no)} — ${esc(d.title)}</option>`).join("")}</select></div></div>
    <div class="field"><label class="f">معيار القبول *</label><input class="input" name="criteria" value="${esc(t.criteria||"")}" placeholder="متى نعتبر المهمة منجزة؟"></div>
    <div class="field"><label class="f">الوصف</label><textarea class="input" name="desc">${esc(t.desc||"")}</textarea></div>`,
    [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg);
      if(!f.criteria) throw new Error("معيار القبول إلزامي"); if(!f.reviewerId) throw new Error("عيّن مراجعاً"); if(f.reviewerId===f.ownerId) throw new Error("المراجع يجب أن يكون غير المنفذ");
      if(isNew) O.createTask(p,f); else { Object.assign(t,f); BOS.audit("تعديل مهمة","task",t.id,t.no); BOS.save(); } U.refresh(); }}], true);
}
function caseRow(tc, p){
  const r = O.lastRun(tc); const stale = r && r.version!==p.version;
  return `<tr><td class="mono">${esc(tc.no)}</td><td><b>${esc(tc.title)}</b>${tc.kind==="uat"?' <span class="badge accent">قبول مستخدم</span>':""}<div class="small muted">${esc(tc.requirement||"")}${tc.taskId?" · مهمة " + esc((S().tasks.find(t=>t.id===tc.taskId)||{}).no||""):""}</div></td>
    <td>${resBadge(r)} ${stale?'<span class="badge warn">إصدار قديم</span>':""}</td><td class="small">${r?esc(r.version) + " · " + esc(r.platform||"") + " " + esc(r.device||""):"—"}</td><td class="small">${r?empName(r.by) + "<br>" + fmtDT(r.at):"—"}</td>
    <td>${BOS.can(me(),"testing","edit")||BOS.can(me(),"testing","create")?`<button class="btn sm" data-run="${tc.id}">تنفيذ</button>`:""} <button class="btn sm" data-hist="${tc.id}">السجل (${tc.runs.length})</button></td></tr>`;
}
function runModal(tc, p){
  modal("تنفيذ " + tc.no + " — " + tc.title, `<dl class="kv" style="margin-bottom:12px"><dt>الخطوات</dt><dd style="white-space:pre-wrap">${esc(tc.steps)||"—"}</dd><dt>المتوقع</dt><dd>${esc(tc.expected)||"—"}</dd></dl>
    <div class="grid g2"><div class="field"><label class="f">النتيجة *</label><select class="input" name="result"><option value="pass">ناجح</option><option value="fail">فاشل</option><option value="blocked">محجوب</option></select></div>
    <div class="field"><label class="f">الإصدار</label><input class="input mono" name="version" value="${esc(p.version)}" dir="ltr"></div>
    <div class="field"><label class="f">المنصة</label><input class="input" name="platform" placeholder="Android 14 / iOS 18 / Chrome"></div><div class="field"><label class="f">الجهاز</label><input class="input" name="device"></div>
    <div class="field"><label class="f">خطورة العيب عند الفشل</label><select class="input" name="severity">${Object.entries(O.SEVERITY).map(([k,v])=>`<option value="${k}" ${k==="medium"?"selected":""}>${v}</option>`).join("")}</select></div>
    <div class="field"><label class="f">رابط لقطة الشاشة / السجلات</label><input class="input" name="evidence" dir="ltr"></div></div>
    <div class="field"><label class="f">ما حدث فعلاً (إلزامي عند الفشل/الحجب)</label><textarea class="input" name="notes"></textarea></div>
    <p class="small muted">الفشل ينشئ عيباً تلقائياً، أو يعيد فتح العيب المرتبط إن كان بانتظار إعادة الاختبار. النجاح يغلق العيوب التي تنتظر إعادة الاختبار.</p>`,
    [{label:"تسجيل النتيجة", cls:"primary", onClick:bg=>{ const res = O.runCase(tc, formData(bg)); toast(res.bug ? "سُجل الفشل — العيب " + res.bug.no : "سُجلت النتيجة", res.bug?"bad":"ok"); U.refresh(); }}], true);
}
function caseHistory(tc){
  modal("سجل تنفيذ " + tc.no, tc.runs.length ? `<div class="table-wrap"><table><thead><tr><th>الوقت</th><th>النتيجة</th><th>الإصدار</th><th>المنصة</th><th>المنفذ</th><th>ملاحظات</th></tr></thead><tbody>${tc.runs.slice().reverse().map(r=>`<tr><td class="small">${fmtDT(r.at)}</td><td>${resBadge(r)}</td><td class="mono">${esc(r.version)}</td><td class="small">${esc(r.platform)} ${esc(r.device)}</td><td class="small">${empName(r.by)}</td><td class="small">${esc(r.notes)}${r.evidence?` <a href="${esc(r.evidence)}" target="_blank" rel="noopener">دليل</a>`:""}</td></tr>`).join("")}</tbody></table></div>` : empty("لم تُنفذ بعد"), [], true);
}
function caseEditor(p){
  modal("حالة اختبار جديدة", `<div class="field"><label class="f">العنوان *</label><input class="input" name="title"></div>
    <div class="grid g2"><div class="field"><label class="f">النوع</label><select class="input" name="kind"><option value="functional">وظيفي</option><option value="regression">انحدار</option><option value="security">أمني</option><option value="performance">أداء</option><option value="uat">قبول المستخدم (UAT)</option></select></div>
    <div class="field"><label class="f">المهمة المرتبطة</label><select class="input" name="taskId"><option value="">—</option>${O.projTasks(p).map(t=>`<option value="${t.id}">${esc(t.no)} — ${esc(t.title)}</option>`).join("")}</select></div></div>
    <div class="field"><label class="f">المتطلب</label><input class="input" name="requirement"></div>
    <div class="field"><label class="f">الخطوات</label><textarea class="input" name="steps"></textarea></div><div class="field"><label class="f">النتيجة المتوقعة</label><input class="input" name="expected"></div>`,
    [{label:"إضافة", cls:"primary", onClick:bg=>{ O.createCase(p,formData(bg)); U.refresh(); }}], true);
}
function pTests(p){
  const cases = O.projCases(p); const st = O.testStats(p); const pr = Number(S().settings.passRate||95);
  const ready = O.autoCheck(p,"passRate").ok && O.autoCheck(p,"coverage").ok && O.autoCheck(p,"bugs").ok && O.autoCheck(p,"uat").ok;
  return {html:`<div class="grid g4">${kpi("نسبة النجاح", st.run?st.rate+"%":"—", "الحد المعتمد " + pr + "%", st.run&&st.rate<pr?"warn":st.run?"ok":"")}${kpi("التغطية", st.coverage+"%", st.run + "/" + st.total + " على " + esc(p.version))}${kpi("فاشل / محجوب", st.failed + " / " + st.blocked, "", st.failed?"bad":"")}${kpi("جاهزية الإطلاق", ready?"جاهز":"غير جاهز", "", ready?"ok":"warn")}</div>
    <div class="card" style="margin-top:14px"><div class="card-head"><h2>حالات الاختبار</h2><button class="btn" id="readiness">📋 تقرير جاهزية الإطلاق</button>${BOS.can(me(),"testing","create")?'<button class="btn primary" id="add-case">＋ حالة</button>':""}</div>
    ${cases.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>الحالة</th><th>آخر نتيجة</th><th>الإصدار / المنصة</th><th>المنفذ</th><th></th></tr></thead><tbody>${cases.map(tc=>caseRow(tc,p)).join("")}</tbody></table></div>`:empty("لا توجد حالات اختبار")}</div>`,
    bind: root => {
      if($("#add-case",root)) $("#add-case",root).onclick = () => caseEditor(p);
      $$("[data-run]",root).forEach(b=>b.onclick=()=>runModal(S().testCases.find(x=>x.id===b.dataset.run), p));
      $$("[data-hist]",root).forEach(b=>b.onclick=()=>caseHistory(S().testCases.find(x=>x.id===b.dataset.hist)));
      $("#readiness",root).onclick = () => go("#/readiness/" + p.id);
    }};
}
function bugsTable(list, showProject){
  if(!list.length) return empty("لا توجد عيوب");
  return `<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>العيب</th>${showProject?"<th>المشروع</th>":""}<th>الخطورة</th><th>الحالة</th><th>المسند إليه</th><th>الإصدار</th><th>التاريخ</th></tr></thead><tbody>
    ${list.map(b=>`<tr class="link" data-go="#/bug/${b.id}"><td class="mono">${esc(b.no)}</td><td>${esc(b.title)}${b.postLaunch?' <span class="badge bad">بعد الإطلاق</span>':""}${b.ticketId?' <span class="badge accent">من الدعم</span>':""}</td>${showProject?`<td class="small">${esc((O.project(b.projectId)||{}).name||"")}</td>`:""}<td>${sevBadge(b.severity)}</td><td>${bugBadge(b.status)}</td><td class="small">${empName(b.assigneeId)}</td><td class="mono small">${esc(b.version)}</td><td class="small">${fmtDate(b.createdAt)}</td></tr>`).join("")}</tbody></table></div>`;
}
function pBugs(p){
  const list = O.projBugs(p);
  return {html:`<div class="card"><div class="card-head"><h2>العيوب</h2>${BOS.can(me(),"testing","create")?'<button class="btn primary" id="add-bug">＋ تسجيل عيب</button>':""}</div>${bugsTable(list)}</div>`,
    bind: root => { bindRows(root); if($("#add-bug",root)) $("#add-bug",root).onclick = () => bugEditor(p); }};
}
function bugEditor(p){
  modal("تسجيل عيب", `<div class="field"><label class="f">العنوان *</label><input class="input" name="title"></div>
    <div class="grid g2"><div class="field"><label class="f">الخطورة</label><select class="input" name="severity">${Object.entries(O.SEVERITY).map(([k,v])=>`<option value="${k}" ${k==="medium"?"selected":""}>${v}</option>`).join("")}</select></div>
    <div class="field"><label class="f">الإصدار</label><input class="input mono" name="version" value="${esc(p.version)}" dir="ltr"></div>
    <div class="field"><label class="f">المسند إليه</label><select class="input" name="assigneeId"><option value="">قائد فريق التطوير</option>${userOptions("")}</select></div>
    <div class="field"><label class="f">المنصة / الجهاز</label><input class="input" name="platform"></div></div>
    <div class="field"><label class="f">خطوات إعادة الإنتاج</label><textarea class="input" name="steps"></textarea></div>
    <div class="grid g2"><div class="field"><label class="f">المتوقع</label><input class="input" name="expected"></div><div class="field"><label class="f">الفعلي</label><input class="input" name="actual"></div></div>`,
    [{label:"تسجيل", cls:"primary", onClick:bg=>{ const b = O.createBug(p,formData(bg)); go("#/bug/"+b.id); }}], true);
}
function reviewEditor(p, kind){
  const C = O.CHECKLISTS[kind];
  const bg = modal(C.name + " — " + p.name, `${kind==="gate"?`<div class="note small" style="margin-bottom:10px">البنود المعلمة ⚙ يحسبها النظام من بيانات المشروع على الإصدار <span class="mono">${esc(p.version)}</span> ولا يمكن تعديلها يدوياً.</div>`:""}
    ${kind!=="gate"?`<div class="field"><label class="f">موضوع المراجعة</label><input class="input" name="target" placeholder="مستند / فرع كود / شاشة"></div>`:""}
    ${C.items.map((it,i)=>{ const a = it.auto ? O.autoCheck(p,it.auto) : null;
      return `<div class="list-item"><span class="badge ${a?(a.ok?"ok":"bad"):""}">${a?"⚙ "+(a.ok?"مطابق":"غير مطابق"):"يدوي"}</span><div class="grow"><b class="small">${esc(it.t)}</b>${a?`<div class="small muted">${esc(a.note)}</div>`:`<div class="row"><label class="check"><input type="checkbox" data-ok="${i}"> مطابق</label><input class="input" data-note="${i}" placeholder="ملاحظة" style="flex:1;min-width:140px"></div>`}</div></div>`; }).join("")}
    <div class="field" style="margin-top:10px"><label class="f">ملاحظات عامة</label><textarea class="input" name="notes"></textarea></div>
    <label class="check"><input type="checkbox" name="ncr" checked> فتح تقرير عدم مطابقة تلقائياً عند الرسوب</label>`,
    [{label:"تسجيل المراجعة", cls:"primary", onClick:bg=>{ const f = formData($(".modal-b",bg)); const items = C.items.map((_,i)=>({ok:$(`[data-ok="${i}"]`,bg)?$(`[data-ok="${i}"]`,bg).checked:false, note:$(`[data-note="${i}"]`,bg)?$(`[data-note="${i}"]`,bg).value:""}));
      const r = O.createReview(p, kind, items, f); toast(r.result==="pass"?"مطابق ✓":"غير مطابق — راجع البنود", r.result==="pass"?"ok":"bad"); U.refresh(); }}], true);
}
function reviewsTable(list, showProject){
  if(!list.length) return empty("لا توجد مراجعات");
  return `<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>النوع</th>${showProject?"<th>المشروع</th>":""}<th>الموضوع</th><th>النتيجة</th><th>المراجع</th><th>الإصدار</th><th>التاريخ</th></tr></thead><tbody>
    ${list.map(r=>`<tr class="link" data-rev="${r.id}"><td class="mono">${esc(r.no)}</td><td>${esc(O.CHECKLISTS[r.kind].name)}</td>${showProject?`<td class="small">${esc((O.project(r.projectId)||{}).name||"")}</td>`:""}<td class="small">${esc(r.target||"")}</td><td><span class="badge ${r.result==="pass"?"ok":"bad"}">${r.result==="pass"?"مطابق":"غير مطابق"}</span></td><td class="small">${empName(r.reviewerId)}</td><td class="mono small">${esc(r.version)}</td><td class="small">${fmtDT(r.at)}</td></tr>`).join("")}</tbody></table></div>`;
}
function bindReviews(root){ $$("[data-rev]",root).forEach(tr=>tr.onclick=()=>{ const r = S().reviews.find(x=>x.id===tr.dataset.rev);
  modal(r.no + " — " + O.CHECKLISTS[r.kind].name, r.items.map(i=>`<div class="list-item"><span class="badge ${i.ok?"ok":"bad"}">${i.ok?"✓":"✕"}</span><div class="grow small"><b>${esc(i.t)}</b>${i.auto?' <span class="muted">⚙ آلي</span>':""}<div class="muted">${esc(i.note||"")}</div></div></div>`).join("") + (r.notes?`<div class="note small" style="margin-top:10px">${esc(r.notes)}</div>`:""), []); }); }
function ncrTable(list){
  if(!list.length) return empty("لا توجد تقارير عدم مطابقة");
  return `<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>الوصف</th><th>المصدر</th><th>المالك</th><th>الاستحقاق</th><th>الحالة</th></tr></thead><tbody>
    ${list.map(n=>`<tr class="link" data-go="#/ncr/${n.id}"><td class="mono">${esc(n.no)}</td><td class="small">${esc(n.description.slice(0,90))}</td><td class="small">${esc(n.source)}</td><td class="small">${empName(n.ownerId)}</td><td class="small">${fmtDate(n.due)} ${n.status!=="closed"&&n.due<BOS.now().slice(0,10)?'<span class="badge bad">متأخر</span>':""}</td><td><span class="badge ${n.status==="closed"?"ok":"warn"}">${esc(O.NCR_STATUS[n.status])}</span></td></tr>`).join("")}</tbody></table></div>`;
}
function pQuality(p){
  const u = me(); const revs = S().reviews.filter(r=>r.projectId===p.id); const ncrs = S().ncrs.filter(n=>n.projectId===p.id);
  const canQ = BOS.can(u,"quality","create") || BOS.can(u,"quality","approve");
  return {html:`<div class="card"><div class="card-head"><h2>مراجعات الجودة</h2>${canQ?`${Object.entries(O.CHECKLISTS).filter(([k])=>k!=="gate").map(([k,c])=>`<button class="btn sm" data-rv="${k}">${esc(c.name)}</button>`).join("")}${BOS.can(u,"quality","approve")?'<button class="btn gold" data-rv="gate">🏅 بوابة الجودة</button>':""}`:""}</div>
    <p class="small muted">قسم الجودة مستقل وظيفياً: لا يستطيع مدير المشروع ولا منفذو المهام مراجعة عملهم. لا ينتقل المشروع إلى العميل إلا بعد بوابة جودة موثقة على الإصدار الحالي.</p>${reviewsTable(revs)}</div>
    <div class="card"><div class="card-head"><h2>عدم المطابقة والإجراءات التصحيحية</h2>${canQ?'<button class="btn sm" id="ncr">＋ تقرير</button>':""}</div>${ncrTable(ncrs)}</div>`,
    bind: root => { bindRows(root); bindReviews(root);
      $$("[data-rv]",root).forEach(b=>b.onclick=()=>safe(()=>{ if(p.pmId===u.id || O.projTasks(p).some(t=>t.ownerId===u.id)) throw new Error("استقلال الجودة: لا يراجع عضو فريق الإنتاج عمله"); reviewEditor(p,b.dataset.rv); }));
      if($("#ncr",root)) $("#ncr",root).onclick = () => ncrEditor({projectId:p.id}); }};
}
function ncrEditor(pre){
  modal("تقرير عدم مطابقة", `<div class="field"><label class="f">المشروع</label><select class="input" name="projectId"><option value="">—</option>${projOptions(pre.projectId)}</select></div>
    <div class="field"><label class="f">المصدر</label><input class="input" name="source" value="${esc(pre.source||"")}" placeholder="مراجعة / شكوى عميل / حادث / تدقيق"></div>
    <div class="field"><label class="f">وصف عدم المطابقة *</label><textarea class="input" name="description">${esc(pre.description||"")}</textarea></div>
    <div class="grid g2"><div class="field"><label class="f">مالك الإجراء</label><select class="input" name="ownerId">${userOptions(pre.ownerId||"")}</select></div><div class="field"><label class="f">الاستحقاق</label><input class="input" type="date" name="due" value="${new Date(Date.now()+14*864e5).toISOString().slice(0,10)}"></div></div>`,
    [{label:"فتح التقرير", cls:"primary", onClick:bg=>{ const f = formData(bg); if(pre.ticketId) f.ticketId = pre.ticketId; const n = O.createNcr(f); go("#/ncr/"+n.id); }}], true);
}
function pMeetings(p){
  return {html:`<div class="card"><div class="card-head"><h2>محاضر الاجتماعات</h2><button class="btn primary" id="add-mt">＋ محضر</button></div>
    ${p.meetings.length?p.meetings.map(m=>`<div class="list-item"><span class="mono small muted">${esc(m.no)}</span><div class="grow"><b>${esc(m.title)}</b> <span class="muted small">— ${fmtDate(m.date)} · ${empName(m.by)}</span><div class="small muted">الحضور: ${esc(m.attendees)}</div><div class="small" style="white-space:pre-wrap">${esc(m.notes)}</div>${m.decisions?`<div class="small"><b>القرارات:</b> ${esc(m.decisions)}</div>`:""}</div></div>`).join(""):empty("لا توجد محاضر")}</div>`,
    bind: root => { $("#add-mt",root).onclick = () => modal("محضر اجتماع", `<div class="grid g2"><div class="field"><label class="f">العنوان *</label><input class="input" name="title"></div><div class="field"><label class="f">التاريخ</label><input class="input" type="date" name="date" value="${BOS.now().slice(0,10)}"></div></div>
      <div class="field"><label class="f">الحضور</label><input class="input" name="attendees"></div><div class="field"><label class="f">النقاش</label><textarea class="input" name="notes"></textarea></div><div class="field"><label class="f">القرارات والمسؤوليات</label><textarea class="input" name="decisions"></textarea></div>`,
      [{label:"حفظ", cls:"primary", onClick:bg=>{ O.addMeeting(p,formData(bg)); U.route(); }}], true); }};
}
function pDelivery(p, pm){
  const d = p.delivery; const rel = p.releaseRequestId && S().requests.find(r=>r.id===p.releaseRequestId);
  return {html:`<div class="grid g2">
    <div class="card"><div class="card-head"><h2>محضر التسليم والقبول</h2>${d?`<a class="btn sm" href="#/delivery/${p.id}">🖨 المحضر</a>`:""}</div>
      ${d?`<dl class="kv"><dt>رقم المحضر</dt><dd class="mono">${esc(d.no)}</dd><dt>التاريخ</dt><dd>${fmtDate(d.date)}</dd><dt>ممثل العميل</dt><dd>${esc(d.customerRep)}</dd><dt>الإصدار</dt><dd class="mono">${esc(d.version)}</dd>
        <dt>النتيجة</dt><dd>${d.accepted?'<span class="badge ok">قبول العميل</span>':'<span class="badge warn">قبول بتحفظات / رفض</span>'}</dd>${d.reservations?`<dt>التحفظات</dt><dd>${esc(d.reservations)}</dd>`:""}</dl>`:empty(p.status==="acceptance"?"لم يُسجل بعد":"يُسجل في مرحلة «قبول العميل» بعد اجتياز بوابة الجودة")}
      ${pm && p.status==="acceptance"?`<button class="btn primary" id="dlv" style="margin-top:10px">${d?"تحديث المحضر":"تسجيل محضر التسليم"}</button>`:""}</div>
    <div class="card"><h2 style="margin-bottom:10px">اعتماد الإطلاق</h2>
      ${rel?`<div>طلب الإطلاق <a href="#/request/${rel.id}">${esc(rel.no)}</a> ${statusBadge(rel.status)}</div><div class="small muted">المسار: قائد الفريق ← الاختبار ← بوابة الجودة ← مدير التقنية ← مدير المشروع${p.strategic?" ← المدير العام":""}</div>`:empty("لم يُرفع طلب إطلاق")}
      ${["testing","acceptance"].includes(p.status) && (O.isPM(me(),p)||(p.members||[]).includes(me().id)) && (!rel || ["rejected","cancelled"].includes(rel.status)) ? '<button class="btn primary" id="rel" style="margin-top:10px">🚀 رفع طلب إطلاق</button>' : ""}</div>
  </div>
  <div class="card" style="margin-top:14px"><h2 style="margin-bottom:10px">تقرير ما بعد الإطلاق</h2>
    ${p.postLaunch?`<div style="white-space:pre-wrap">${esc(p.postLaunch)}</div>`:empty("لم يُكتب بعد")}
    ${pm && ["launch","support"].includes(p.status)?'<button class="btn" id="pl" style="margin-top:10px">✎ كتابة التقرير</button>':""}
    <div class="small muted" style="margin-top:8px">عيوب ما بعد الإطلاق: ${O.projBugs(p).filter(b=>b.postLaunch).length} · تذاكر الدعم: ${S().tickets.filter(t=>t.projectId===p.id).length}</div></div>`,
    bind: root => {
      if($("#dlv",root)) $("#dlv",root).onclick = () => modal("محضر تسليم مشروع", `<div class="grid g2"><div class="field"><label class="f">التاريخ</label><input class="input" type="date" name="date" value="${BOS.now().slice(0,10)}"></div><div class="field"><label class="f">ممثل العميل *</label><input class="input" name="customerRep"></div></div>
        <div class="field"><label class="f">المخرجات المسلمة</label><textarea class="input" name="deliverables">${esc(p.deliverables)}</textarea></div><div class="field"><label class="f">التحفظات</label><textarea class="input" name="reservations"></textarea></div>
        <label class="check"><input type="checkbox" name="accepted"> العميل قبل المخرجات ووقّع المحضر</label>`,
        [{label:"حفظ المحضر", cls:"primary", onClick:bg=>{ O.recordDelivery(p,formData(bg)); U.route(); }}], true);
      if($("#rel",root)) $("#rel",root).onclick = () => act(()=>{ const r = O.requestRelease(p); toast("أُرسل طلب الإطلاق " + r.no,"ok"); });
      if($("#pl",root)) $("#pl",root).onclick = () => modal("تقرير ما بعد الإطلاق", `<textarea class="input" name="t" style="min-height:220px" placeholder="ما الذي نجح؟ ما الذي تأخر؟ العيوب بعد الإطلاق، ملاحظات العميل، الدروس المستفادة">${esc(p.postLaunch||"")}</textarea>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ p.postLaunch = $("[name=t]",bg).value.trim(); BOS.audit("تقرير ما بعد الإطلاق","project",p.id,p.no); BOS.save(); U.route(); }}], true);
    }};
}
/* مستندات صادرة: محضر التسليم وتقرير الجاهزية */
function paperHead(title, no, date, status){
  const c = S().company;
  return `<div class="ph"><img src="${esc(c.logo)}" alt=""><div class="co"><b>${esc(c.tradeName)}</b><span>${esc(c.nameEn||"")}</span></div><div class="meta"><b>${esc(title)}</b><span class="mono">${esc(no)}</span><br>التاريخ: ${fmtDate(date)}<br>الحالة: <b>${esc(status)}</b></div></div><div class="gold-line"></div>`;
}
function delivery(id){
  const p = O.project(id); if(!p || !O.canSeeProject(me(),p) || !p.delivery) throw new Error("غير متاح"); const d = p.delivery;
  return {title:"محضر التسليم", html:`<div class="row no-print" style="margin-bottom:12px"><a class="btn" href="#/project/${p.id}/delivery">→ رجوع</a><button class="btn primary" onclick="print()">🖨 طباعة / PDF</button><a class="btn" href="library/11-05.docx" download>⬇ النموذج الرسمي</a></div>
    <div class="paper">${paperHead("محضر تسليم مشروع", d.no, d.date, d.accepted?"مقبول":"بتحفظات")}
      <dl class="kv" style="margin-top:14px"><dt>المشروع</dt><dd>${esc(p.name)} (${esc(p.no)})</dd><dt>العميل</dt><dd>${custName(p.customerId)}</dd><dt>ممثل العميل</dt><dd>${esc(d.customerRep)}</dd><dt>الإصدار المسلم</dt><dd class="mono">${esc(d.version)}</dd><dt>مرجع العقد</dt><dd>${esc(p.contractRef||"—")}</dd></dl>
      <h2>المخرجات المسلمة</h2><p style="white-space:pre-wrap">${esc(d.deliverables)}</p>${d.reservations?`<h2>التحفظات</h2><p style="white-space:pre-wrap">${esc(d.reservations)}</p>`:""}
      <h2>بوابة الجودة</h2><p>${O.latestGate(p)?esc(O.latestGate(p).no) + " — " + (O.gatePassed(p)?"مجتازة":"غير مجتازة") + " — " + fmtDate(O.latestGate(p).at):"—"}</p>
      <div class="foot"><div>عن الشركة: <b>${empName(d.by)}</b> — مدير المشروع<br><br>عن العميل: <b>${esc(d.customerRep)}</b> ............................</div>${d.accepted?'<img class="stamp" src="assets/stamp.png" alt="الختم">':""}</div>
      <p class="small" style="color:#7A89A8">الختم الإلكتروني عنصر هوية داخلي ولا يغني عن توقيع ممثلي الطرفين.</p></div>`};
}
function readiness(id){
  const p = O.project(id); if(!p || !O.canSeeProject(me(),p)) throw new Error("غير متاح");
  const st = O.testStats(p); const g = O.latestGate(p);
  const items = O.CHECKLISTS.gate.items.filter(i=>i.auto).map(i=>({t:i.t, ...O.autoCheck(p,i.auto)}));
  const ready = items.every(i=>i.ok) && O.gatePassed(p);
  BOS.audit("إصدار تقرير جاهزية الإطلاق","project",p.id,p.no + " — " + p.version); BOS.save();
  return {title:"تقرير جاهزية الإطلاق", html:`<div class="row no-print" style="margin-bottom:12px"><a class="btn" href="#/project/${p.id}/tests">→ رجوع</a><button class="btn primary" onclick="print()">🖨 طباعة / PDF</button></div>
    <div class="paper">${paperHead("تقرير جاهزية الإطلاق", p.no + " / " + p.version, BOS.now(), ready?"جاهز للإطلاق":"غير جاهز")}
      <dl class="kv" style="margin-top:14px"><dt>المشروع</dt><dd>${esc(p.name)}</dd><dt>العميل</dt><dd>${custName(p.customerId)}</dd><dt>الإصدار</dt><dd class="mono">${esc(p.version)}</dd><dt>المرحلة</dt><dd>${esc(O.PSTATUS[p.status])}</dd></dl>
      <h2>ملخص الاختبار</h2><table><thead><tr><th>الحالات</th><th>المنفذة</th><th>ناجحة</th><th>فاشلة</th><th>محجوبة</th><th>نسبة النجاح</th></tr></thead><tbody><tr><td>${st.total}</td><td>${st.run}</td><td>${st.passed}</td><td>${st.failed}</td><td>${st.blocked}</td><td><b>${st.rate}%</b></td></tr></tbody></table>
      <h2>العيوب المفتوحة حسب الخطورة</h2><table><thead><tr>${Object.values(O.SEVERITY).map(v=>`<th>${v}</th>`).join("")}</tr></thead><tbody><tr>${Object.keys(O.SEVERITY).map(k=>`<td>${O.openBugs(p,[k]).length}</td>`).join("")}</tr></tbody></table>
      <h2>معايير الجاهزية</h2><table><tbody>${items.map(i=>`<tr><td>${i.ok?"✓":"✕"}</td><td>${esc(i.t)}</td><td>${esc(i.note)}</td></tr>`).join("")}<tr><td>${O.gatePassed(p)?"✓":"✕"}</td><td>بوابة الجودة موثقة على الإصدار الحالي</td><td>${g?esc(g.no) + " — " + empName(g.reviewerId):"—"}</td></tr></tbody></table>
      <div class="foot"><div>أعده النظام آلياً لـ: <b>${esc(me().name)}</b><br>صلاحيات الاختبار منفصلة عن اعتماد الإطلاق النهائي.</div></div></div>`};
}

/* =================== صفحة العيب =================== */
function bug(id){
  need("testing");
  const b = S().bugs.find(x=>x.id===id); if(!b) throw new Error("العيب غير موجود");
  const p = O.project(b.projectId); const u = me(); if(!O.canSeeProject(u,p)) throw new Error("خارج نطاقك");
  const tc = b.testCaseId && S().testCases.find(x=>x.id===b.testCaseId);
  const btns = [];
  if(["open","reopened"].includes(b.status)) btns.push(["fixing","بدء الإصلاح",""]);
  if(["open","reopened","fixing"].includes(b.status)) btns.push(["fixed","تم الإصلاح — لإعادة الاختبار","primary"]);
  if(b.status!=="closed") btns.push(["closed","إغلاق يدوي","ok"], ["deferred","تأجيل بقرار",""]);
  if(["closed","deferred"].includes(b.status)) btns.push(["reopened","إعادة فتح","danger"]);
  return {title:b.no, html:`${head("🐞 " + b.title, `<span class="mono">${esc(b.no)}</span> · ${sevBadge(b.severity)} ${bugBadge(b.status)} · <a href="#/project/${p.id}/bugs">${esc(p.name)}</a>`,
      btns.map(([k,l,c])=>`<button class="btn ${c}" data-b="${k}">${l}</button>`).join("") + (tc?`<button class="btn" id="retest">🧪 إعادة الاختبار</button>`:""))}
    ${b.status==="fixed"?'<div class="note" style="margin-bottom:14px">بانتظار إعادة الاختبار: نجاح حالة الاختبار المرتبطة يغلق العيب تلقائياً، وفشلها يعيد فتحه.</div>':""}
    <div class="grid g2"><div class="card"><dl class="kv"><dt>الإصدار</dt><dd class="mono">${esc(b.version)}</dd><dt>المنصة</dt><dd>${esc(b.platform||"—")} ${esc(b.device||"")}</dd><dt>المبلّغ</dt><dd>${empName(b.reporterId)}</dd><dt>المسند إليه</dt><dd>${empName(b.assigneeId)}</dd>
      <dt>حالة الاختبار</dt><dd>${tc?esc(tc.no) + " — " + esc(tc.title):"—"}</dd>${b.ticketId?`<dt>تذكرة الدعم</dt><dd><a href="#/ticket/${b.ticketId}">${esc((S().tickets.find(t=>t.id===b.ticketId)||{}).no||"")}</a></dd>`:""}
      <dt>الخطوات</dt><dd style="white-space:pre-wrap">${esc(b.steps||"—")}</dd><dt>المتوقع</dt><dd>${esc(b.expected||"—")}</dd><dt>الفعلي</dt><dd>${esc(b.actual||"—")}</dd></dl></div>
    <div class="card"><h2 style="margin-bottom:10px">السجل</h2>${b.log.slice().reverse().map(l=>`<div class="list-item small"><span class="muted">${fmtDT(l.at)}</span><div class="grow">${l.to?bugBadge(l.to):""} ${empName(l.by)} ${esc(l.note||"")}</div></div>`).join("")}</div></div>`,
    bind: root => {
      $$("[data-b]",root).forEach(btn=>btn.onclick=()=>{ const to = btn.dataset.b;
        const needNote = ["closed","deferred","reopened"].includes(to);
        const c = needNote ? prompt(to==="closed"?"سبب الإغلاق اليدوي:":to==="deferred"?"سبب التأجيل:":"سبب إعادة الفتح:") : "";
        if(needNote && !c) return;
        act(()=>O.moveBug(b,to,{comment:c||""})); });
      if($("#retest",root)) $("#retest",root).onclick = () => runModal(tc, p);
    }};
}

/* =================== الاختبار عبر المشاريع =================== */
function testing(){
  need("testing");
  const u = me(); const ps = S().projects.filter(p=>O.canSeeProject(u,p));
  const ids = new Set(ps.map(p=>p.id));
  const bugs = S().bugs.filter(b=>ids.has(b.projectId)); const m = O.metrics();
  return {title:"الاختبار والعيوب", html:`${head("الاختبار والعيوب", "صلاحيات الاختبار منفصلة عن اعتماد الإطلاق النهائي")}
    <div class="grid g4">${kpi("نسبة نجاح الاختبارات", pct(m.passRate), "آخر تنفيذ لكل حالة")}${kpi("عيوب مفتوحة", bugs.filter(b=>!["closed","deferred"].includes(b.status)).length, Object.entries(m.bySev).map(([k,v])=>O.SEVERITY[k]+" "+v).join(" · "), m.bySev.critical?"bad":"")}${kpi("متوسط زمن الإصلاح", hrs(m.mttr), "من التسجيل للإغلاق")}${kpi("عيوب أعيد فتحها", m.reopened, "فشل إعادة الاختبار", m.reopened?"warn":"")}</div>
    <div class="card" style="margin-top:14px"><h2 style="margin-bottom:10px">جاهزية المشاريع</h2>${ps.length?`<div class="table-wrap"><table><thead><tr><th>المشروع</th><th>الإصدار</th><th>الحالات</th><th>التغطية</th><th>النجاح</th><th>حرجة/عالية</th><th>بوابة الجودة</th><th></th></tr></thead><tbody>
      ${ps.map(p=>{ const st = O.testStats(p); return `<tr class="link" data-go="#/project/${p.id}/tests"><td><b>${esc(p.name)}</b> ${pBadge(p.status)}</td><td class="mono">${esc(p.version)}</td><td>${st.total}</td><td style="min-width:90px">${bar(st.coverage)}<span class="small">${st.coverage}%</span></td><td>${st.run?st.rate+"%":"—"}</td><td>${O.openBugs(p,["critical","high"]).length}</td><td>${O.gatePassed(p)?'<span class="badge ok">مجتازة</span>':'<span class="badge">—</span>'}</td><td><a class="btn sm" href="#/readiness/${p.id}">تقرير</a></td></tr>`; }).join("")}</tbody></table></div>`:empty("لا توجد مشاريع")}</div>
    <div class="card"><div class="row" style="margin-bottom:10px"><h2 style="flex:1">العيوب</h2><select class="input" id="fs" style="max-width:180px"><option value="open">المفتوحة</option><option value="">الكل</option><option value="fixed">بانتظار إعادة الاختبار</option></select><select class="input" id="fv" style="max-width:160px"><option value="">كل الخطورات</option>${Object.entries(O.SEVERITY).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select></div><div id="bl"></div></div>`,
    bind: root => { bindRows(root);
      const draw = () => { const s = $("#fs",root).value, v = $("#fv",root).value;
        $("#bl",root).innerHTML = bugsTable(bugs.filter(b=>(!s || (s==="open" ? !["closed","deferred"].includes(b.status) : b.status===s)) && (!v || b.severity===v)), true); bindRows($("#bl",root)); };
      $("#fs",root).onchange = draw; $("#fv",root).onchange = draw; draw(); }};
}

/* =================== الجودة =================== */
function quality(tab){
  need("quality");
  const u = me(); tab = tab || "overview"; const m = O.metrics(); const s = S();
  const T = [["overview","المؤشرات"],["reviews","المراجعات"],["ncr","عدم المطابقة والإجراءات"],["voc","صوت العميل"],["checklists","قوائم الفحص"]];
  let body = "";
  if(tab==="overview") body = `<div class="grid g4">${kpi("اجتياز بوابة الإطلاق", pct(m.gateRate))}${kpi("نسبة نجاح الاختبارات", pct(m.passRate))}${kpi("إعادة العمل", m.rework, "مهام أعيدت من المراجع")}${kpi("عيوب بعد الإطلاق", m.postLaunch, "", m.postLaunch?"warn":"")}
      ${kpi("رضا العملاء", m.csat==null?"—":m.csat.toFixed(1)+"/5", "بعد إغلاق التذاكر", m.csat!=null&&m.csat<3.5?"bad":"")}${kpi("الالتزام باتفاقية الخدمة", pct(m.sla), m.breached + " تذكرة مفتوحة متجاوزة", m.breached?"warn":"")}${kpi("إجراءات تصحيحية مفتوحة", m.openNcr, m.capaFromVoc + " ناتجة عن صوت العميل")}${kpi("التسليم في الموعد", pct(m.onTime))}</div>
    <div class="row" style="margin-top:14px"><a class="btn primary" href="#/quality-report">🖨 التقرير الأسبوعي للجودة وخدمة العملاء</a></div>`;
  if(tab==="reviews") body = `<div class="card">${reviewsTable(s.reviews.filter(r=>O.canSeeProject(u,O.project(r.projectId))), true)}</div>`;
  if(tab==="ncr") body = `<div class="card"><div class="card-head"><h2>تقارير عدم المطابقة</h2>${BOS.can(u,"quality","create")||BOS.can(u,"quality","approve")?'<button class="btn primary" id="ncr">＋ تقرير</button>':""}</div>${ncrTable(s.ncrs)}</div>`;
  if(tab==="voc"){ const tk = s.tickets.filter(t=>t.status==="closed"); const max = Math.max(1,...Object.values(m.causes));
    body = `<div class="grid g2"><div class="card"><h2 style="margin-bottom:10px">أسباب الشكاوى والتذاكر</h2>${Object.keys(m.causes).length?Object.entries(m.causes).sort((a,b)=>b[1]-a[1]).map(([k,v])=>`<div style="margin-bottom:8px"><div class="row small"><b>${esc(k)}</b><span class="spacer"></span>${v} ${v>=2?'<span class="badge warn">متكرر</span>':""}</div>${bar(v/max*100, v>=2?"background:var(--warn)":"")}</div>`).join(""):empty("لا توجد تذاكر مغلقة بعد")}</div>
      <div class="card"><h2 style="margin-bottom:10px">أسباب متكررة تحتاج إجراءً</h2>${m.repeated.length?m.repeated.map(([k,v])=>{ const has = s.ncrs.some(n=>n.source==="صوت العميل: " + k && n.status!=="closed");
        return `<div class="list-item"><div class="grow"><b>${esc(k)}</b> <span class="muted small">— ${v} حالة</span></div>${has?'<span class="badge info">إجراء مفتوح</span>':(BOS.can(u,"quality","create")||BOS.can(u,"quality","approve")?`<button class="btn sm" data-voc="${esc(k)}">فتح إجراء تصحيحي</button>`:"")}</div>`; }).join(""):empty("لا توجد أسباب متكررة")}
        <h3 style="margin:14px 0 6px">تقييمات منخفضة (≤ 2)</h3>${tk.filter(t=>t.csat && t.csat<=2).map(t=>`<div class="small"><a href="#/ticket/${t.id}">${esc(t.no)}</a> ${t.csat}/5 — ${esc(t.csatComment||t.subject)}</div>`).join("")||'<div class="muted small">لا يوجد</div>'}</div></div>`; }
  if(tab==="checklists") body = `<div class="grid g2">${Object.values(O.CHECKLISTS).map(c=>`<div class="card"><h2 style="margin-bottom:8px">${esc(c.name)}</h2>${c.items.map(i=>`<div class="small list-item"><span>${i.auto?"⚙":"☐"}</span><div class="grow">${esc(i.t)}</div></div>`).join("")}</div>`).join("")}</div>
    <div class="field card" style="margin-top:14px"><label class="f">الحد الأدنى لنسبة نجاح الاختبارات في بوابة الجودة (%)</label><div class="row"><input class="input" type="number" id="pr" value="${esc(s.settings.passRate)}" style="max-width:120px" ${BOS.can(u,"quality","manage")||BOS.isTop(u)?"":"disabled"}><button class="btn" id="save-pr">حفظ</button></div></div>`;
  return {title:"الجودة", html:`${head("الجودة وضمان الجودة", "قسم مستقل وظيفياً عن الإنتاج · خدمة العملاء تتبعه تنظيمياً")}${tabs(T,tab,"#/quality")}${body}`,
    bind: root => { bindTabs(root); bindRows(root); bindReviews(root);
      if($("#ncr",root)) $("#ncr",root).onclick = () => ncrEditor({});
      $$("[data-voc]",root).forEach(b=>b.onclick=()=>ncrEditor({source:"صوت العميل: " + b.dataset.voc, description:"تكرر سبب «" + b.dataset.voc + "» في شكاوى وتذاكر العملاء. المطلوب تحليل السبب الجذري واقتراح إجراء تصحيحي أو تدريب أو تغيير في المنتج."}));
      if($("#save-pr",root)) $("#save-pr",root).onclick = () => act(()=>{ if(!BOS.can(u,"quality","manage") && !BOS.isTop(u)) throw new Error("لمدير الجودة"); const v = Number($("#pr",root).value); if(!(v>0&&v<=100)) throw new Error("قيمة غير صالحة");
        BOS.audit("تغيير حد نجاح الاختبارات","settings",null,s.settings.passRate + "% ← " + v + "%"); s.settings.passRate = v; BOS.save(); }, "حُفظ");
    }};
}
function qualityReport(){
  need("quality");
  const s = S(); const m = O.metrics(); const since = new Date(Date.now()-7*864e5).toISOString();
  const wk = s.tickets.filter(t=>t.createdAt>=since); const closed = s.tickets.filter(t=>t.closedAt && t.closedAt>=since);
  BOS.audit("إصدار التقرير الأسبوعي للجودة","quality",null,""); BOS.save();
  return {title:"التقرير الأسبوعي", html:`<div class="row no-print" style="margin-bottom:12px"><a class="btn" href="#/quality">→ رجوع</a><button class="btn primary" onclick="print()">🖨 طباعة / PDF</button></div>
    <div class="paper">${paperHead("التقرير الأسبوعي للجودة وخدمة العملاء", "QW-" + BOS.now().slice(0,10), BOS.now(), "إلى مدير الجودة والمدير العام")}
      <h2>خدمة العملاء (آخر 7 أيام)</h2><table><tbody><tr><td>تذاكر جديدة</td><td>${wk.length}</td><td>مغلقة</td><td>${closed.length}</td></tr><tr><td>زمن الاستجابة الأول</td><td>${hrs(m.frt)}</td><td>زمن الحل</td><td>${hrs(m.ttr)}</td></tr>
        <tr><td>الالتزام باتفاقية الخدمة</td><td>${pct(m.sla)}</td><td>الإغلاق من أول تواصل</td><td>${pct(m.fcr)}</td></tr><tr><td>رضا العملاء</td><td>${m.csat==null?"—":m.csat.toFixed(1)+"/5"}</td><td>تذاكر مفتوحة متجاوزة</td><td>${m.breached}</td></tr></tbody></table>
      <h2>الجودة والاختبار</h2><table><tbody><tr><td>نسبة نجاح الاختبارات</td><td>${pct(m.passRate)}</td><td>اجتياز بوابة الإطلاق</td><td>${pct(m.gateRate)}</td></tr><tr><td>عيوب حرجة/عالية مفتوحة</td><td>${m.bySev.critical + m.bySev.high}</td><td>عيوب بعد الإطلاق</td><td>${m.postLaunch}</td></tr>
        <tr><td>متوسط زمن الإصلاح</td><td>${hrs(m.mttr)}</td><td>إعادة العمل</td><td>${m.rework}</td></tr><tr><td>إجراءات تصحيحية مفتوحة</td><td>${m.openNcr}</td><td>ناتجة عن صوت العميل</td><td>${m.capaFromVoc}</td></tr></tbody></table>
      <h2>أسباب متكررة</h2>${m.repeated.length?`<ul>${m.repeated.map(([k,v])=>`<li>${esc(k)} — ${v}</li>`).join("")}</ul>`:"<p>لا توجد</p>"}
      <div class="foot"><div>أعده: <b>${esc(me().name)}</b> — ${esc(BOS.posTitle(me().positionId))}</div></div></div>`};
}
function ncr(id){
  need("quality");
  const n = S().ncrs.find(x=>x.id===id); if(!n) throw new Error("غير موجود");
  const order = ["open","investigating","action","verify","closed"]; const next = order[order.indexOf(n.status)+1];
  return {title:n.no, html:`${head("تقرير عدم مطابقة", `<span class="mono">${esc(n.no)}</span> · <span class="badge ${n.status==="closed"?"ok":"warn"}">${esc(O.NCR_STATUS[n.status])}</span> · المالك ${empName(n.ownerId)} · الاستحقاق ${fmtDate(n.due)}`, next?`<button class="btn primary" id="next">الانتقال إلى «${esc(O.NCR_STATUS[next])}»</button>`:"")}
    <div class="route-h" style="margin-bottom:14px">${order.map((k,i)=>`${i?'<span class="arrow">←</span>':""}<span class="chip" style="${i<=order.indexOf(n.status)?"border-color:var(--accent)":"opacity:.6"}">${esc(O.NCR_STATUS[k])}</span>`).join("")}</div>
    <div class="grid g2"><div class="card"><dl class="kv"><dt>المصدر</dt><dd>${esc(n.source)}</dd>${n.projectId?`<dt>المشروع</dt><dd><a href="#/project/${n.projectId}/quality">${esc((O.project(n.projectId)||{}).name||"")}</a></dd>`:""}${n.ticketId?`<dt>التذكرة</dt><dd><a href="#/ticket/${n.ticketId}">فتح</a></dd>`:""}
      <dt>الوصف</dt><dd style="white-space:pre-wrap">${esc(n.description)}</dd><dt>السبب الجذري</dt><dd>${esc(n.rootCause||"—")}</dd><dt>الإجراء التصحيحي</dt><dd>${esc(n.correction||"—")}</dd><dt>الإجراء الوقائي</dt><dd>${esc(n.preventive||"—")}</dd>${n.verifiedBy?`<dt>تحقق الفعالية</dt><dd>${empName(n.verifiedBy)} · ${fmtDT(n.closedAt)}</dd>`:""}</dl></div>
    <div class="card"><h2 style="margin-bottom:10px">السجل</h2>${n.log.slice().reverse().map(l=>`<div class="list-item small"><span class="muted">${fmtDT(l.at)}</span><div class="grow">${esc(O.NCR_STATUS[l.to])} — ${empName(l.by)} ${esc(l.note||"")}</div></div>`).join("")||empty("—")}</div></div>`,
    bind: root => { if($("#next",root)) $("#next",root).onclick = () => {
      const fields = next==="action" ? `<div class="field"><label class="f">السبب الجذري *</label><textarea class="input" name="rootCause">${esc(n.rootCause)}</textarea></div>` :
        next==="verify" ? `<div class="field"><label class="f">الإجراء التصحيحي المنفذ *</label><textarea class="input" name="correction">${esc(n.correction)}</textarea></div><div class="field"><label class="f">الإجراء الوقائي *</label><textarea class="input" name="preventive">${esc(n.preventive)}</textarea></div>` :
        next==="closed" ? `<div class="note small" style="margin-bottom:8px">التحقق من الفعالية بواسطة الجودة وليس مالك الإجراء.</div>` : "";
      modal("الانتقال إلى «" + O.NCR_STATUS[next] + "»", fields + `<div class="field"><label class="f">ملاحظة${next==="closed"?" / نتيجة التحقق *":""}</label><input class="input" name="comment"></div>`,
        [{label:"تأكيد", cls:"primary", onClick:bg=>{ O.moveNcr(n,next,formData(bg)); U.refresh(); }}], true); }; }};
}

/* =================== الدعم الفني وخدمة العملاء =================== */
function slaBadge(t){ if(t.status==="closed") return O.slaState(t).breached?'<span class="badge warn">أغلقت بعد المهلة</span>':'<span class="badge ok">ضمن المهلة</span>';
  const s = O.slaState(t); if(s.breached) return '<span class="badge bad">متجاوزة</span>';
  const left = (new Date(t.firstResponseAt?t.resolveBy:t.respondBy) - Date.now())/36e5; return `<span class="badge ${left<2?"warn":""}">متبقٍ ${hrs(Math.max(0,left))}</span>`; }
function support(tab){
  need("support");
  const u = me(); tab = tab || "tickets"; const s = S(); const m = O.metrics();
  const T = [["tickets","التذاكر"],["kb","قاعدة المعرفة"],["sla","اتفاقية مستوى الخدمة"]];
  let body = "";
  if(tab==="tickets") body = `<div class="grid g4">${kpi("تذاكر مفتوحة", m.openTickets, m.breached + " متجاوزة", m.breached?"bad":"")}${kpi("زمن الاستجابة الأول", hrs(m.frt))}${kpi("زمن الحل", hrs(m.ttr))}${kpi("رضا العملاء", m.csat==null?"—":m.csat.toFixed(1)+"/5", "الإغلاق من أول تواصل " + pct(m.fcr))}</div>
    <div class="card" style="margin-top:14px"><div class="row" style="margin-bottom:10px"><select class="input" id="fs" style="max-width:180px"><option value="open">المفتوحة</option><option value="">الكل</option>${O.TICKET_FLOW.map(([k,l])=>`<option value="${k}">${l}</option>`).join("")}</select><select class="input" id="fm" style="max-width:160px"><option value="">الجميع</option><option value="me">المسندة لي</option><option value="late">المتجاوزة</option></select></div><div id="tl"></div></div>`;
  if(tab==="kb") body = `<div class="card"><div class="card-head"><h2>قاعدة المعرفة المعتمدة</h2>${BOS.can(u,"support","create")?'<button class="btn primary" id="kb-new">＋ مقال</button>':""}</div>
    ${s.kb.length?s.kb.map(a=>`<div class="list-item"><span class="badge ${a.status==="approved"?"ok":""}">${a.status==="approved"?"معتمد":"مسودة"}</span><div class="grow"><b>${esc(a.title)}</b> <span class="mono small muted">${esc(a.no)}</span><div class="small" style="white-space:pre-wrap">${esc(a.body)}</div><div class="small muted">${empName(a.by)} · ${fmtDate(a.at)}${a.approvedBy?" · اعتمده " + empName(a.approvedBy):""}</div></div>${a.status!=="approved" && a.by!==u.id && (BOS.can(u,"quality","approve")||BOS.isTop(u))?`<button class="btn sm ok" data-kb="${a.id}">اعتماد</button>`:""}</div>`).join(""):empty("لا توجد مقالات")}
    <p class="small muted">الرد على العملاء يكون من المقالات المعتمدة فقط.</p></div>`;
  if(tab==="sla"){ const sla = s.settings.sla; const edit = BOS.can(u,"support","manage")||BOS.isTop(u);
    body = `<div class="card"><h2 style="margin-bottom:10px">أزمنة الاستجابة والحل (ساعة)</h2><div class="table-wrap"><table><thead><tr><th>الأولوية</th><th>الاستجابة الأولى</th><th>الحل</th></tr></thead><tbody>${Object.keys(O.PRIORITY).map(k=>`<tr><td>${prBadge(k)} ${esc(O.PRIORITY[k])}</td><td><input class="input" type="number" data-sla="${k}:0" value="${sla[k][0]}" style="max-width:110px" ${edit?"":"disabled"}></td><td><input class="input" type="number" data-sla="${k}:1" value="${sla[k][1]}" style="max-width:110px" ${edit?"":"disabled"}></td></tr>`).join("")}</tbody></table></div>
    ${edit?'<button class="btn primary" id="save-sla" style="margin-top:10px">حفظ</button>':""}<p class="small muted">عند تجاوز المهلة يُنبَّه مالك التذكرة ومدير الجودة ويُسجل الحدث في سجل التدقيق.</p></div>`; }
  return {title:"خدمة العملاء والدعم", html:`${head("خدمة العملاء والدعم الفني", "تابعة تنظيمياً لمدير الجودة · استقبال ← تحقق ← تصنيف ← معالجة ← إحالة ← حل مقترح ← تأكيد العميل ← إغلاق ← تحليل جودة", BOS.can(u,"support","create")?'<button class="btn primary" id="new">＋ تذكرة</button>':"")}${tabs(T,tab,"#/support")}${body}`,
    bind: root => { bindTabs(root);
      if($("#new",root)) $("#new",root).onclick = ticketEditor;
      if($("#tl",root)){ const draw = () => { const fs = $("#fs",root).value, fm = $("#fm",root).value;
        const list = s.tickets.filter(t=>(!fs || (fs==="open"?t.status!=="closed":t.status===fs)) && (fm!=="me"||t.ownerId===u.id||t.referredTo===u.id) && (fm!=="late"||O.slaState(t).breached));
        $("#tl",root).innerHTML = list.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>الموضوع</th><th>العميل</th><th>النوع</th><th>الأولوية</th><th>الحالة</th><th>المهلة</th><th>المالك</th></tr></thead><tbody>${list.map(t=>`<tr class="link" data-go="#/ticket/${t.id}"><td class="mono">${esc(t.no)}</td><td>${esc(t.subject)}</td><td class="small">${custName(t.customerId)}</td><td class="small">${esc(t.type)}</td><td>${prBadge(t.priority)}</td><td>${tBadge(t.status)}</td><td>${slaBadge(t)}</td><td class="small">${empName(t.ownerId)}</td></tr>`).join("")}</tbody></table></div>`:empty("لا توجد تذاكر");
        bindRows($("#tl",root)); }; $("#fs",root).onchange = draw; $("#fm",root).onchange = draw; draw(); }
      if($("#kb-new",root)) $("#kb-new",root).onclick = () => modal("مقال معرفة", `<div class="field"><label class="f">العنوان *</label><input class="input" name="title"></div><div class="field"><label class="f">المحتوى *</label><textarea class="input" name="body" style="min-height:160px"></textarea></div><div class="field"><label class="f">وسوم</label><input class="input" name="tags"></div>`,
        [{label:"حفظ كمسودة", cls:"primary", onClick:bg=>{ O.createKb(formData(bg)); U.route(); }}], true);
      $$("[data-kb]",root).forEach(b=>b.onclick=()=>act(()=>O.approveKb(s.kb.find(a=>a.id===b.dataset.kb)),"اعتُمد المقال"));
      if($("#save-sla",root)) $("#save-sla",root).onclick = () => act(()=>{ $$("[data-sla]",root).forEach(i=>{ const [k,j] = i.dataset.sla.split(":"); const v = Number(i.value); if(!(v>0)) throw new Error("قيمة غير صالحة"); s.settings.sla[k][Number(j)] = v; });
        BOS.audit("تعديل اتفاقية مستوى الخدمة","settings",null,JSON.stringify(s.settings.sla)); BOS.save(); }, "حُفظ");
    }};
}
function ticketEditor(){
  const s = S(); if(!s.customers.length) return toast("أضف عميلاً أولاً","bad");
  modal("تذكرة جديدة", `<div class="grid g2"><div class="field"><label class="f">العميل *</label><select class="input" name="customerId">${s.customers.map(c=>`<option value="${c.id}">${esc(c.name)}</option>`).join("")}</select></div>
    <div class="field"><label class="f">المشروع</label><select class="input" name="projectId"><option value="">—</option>${projOptions("")}</select></div>
    <div class="field"><label class="f">النوع</label><select class="input" name="type">${O.TICKET_TYPES.map(t=>`<option>${t}</option>`).join("")}</select></div>
    <div class="field"><label class="f">القناة</label><select class="input" name="channel"><option>هاتف</option><option>بريد</option><option>بوابة الدعم</option><option>واتساب</option><option>زيارة</option></select></div>
    <div class="field"><label class="f">الأولوية</label><select class="input" name="priority">${Object.entries(O.PRIORITY).map(([k,v])=>`<option value="${k}" ${k==="P3"?"selected":""}>${v}</option>`).join("")}</select></div>
    <div class="field"><label class="f">الإصدار</label><input class="input mono" name="version" dir="ltr"></div></div>
    <div class="field"><label class="f">الموضوع *</label><input class="input" name="subject"></div><div class="field"><label class="f">التفاصيل</label><textarea class="input" name="details"></textarea></div>
    <div class="field"><label class="f">التأثير</label><input class="input" name="impact" placeholder="عدد المستخدمين المتأثرين، توقف خدمة…"></div>`,
    [{label:"فتح التذكرة", cls:"primary", onClick:bg=>{ const t = O.createTicket(formData(bg)); go("#/ticket/"+t.id); }}], true);
}
function ticket(id){
  need("support");
  const t = S().tickets.find(x=>x.id===id); if(!t) throw new Error("التذكرة غير موجودة");
  const u = me(); const s = O.slaState(t); const work = BOS.can(u,"support","edit") || t.ownerId===u.id || t.referredTo===u.id;
  const idx = O.TICKET_FLOW.findIndex(x=>x[0]===t.status);
  const kb = S().kb.filter(a=>a.status==="approved");
  const nextBtns = t.status==="closed" ? [] : O.TICKET_FLOW.slice(idx+1).filter(([k])=>k!=="closed").slice(0,3).map(([k,l])=>`<button class="btn" data-t="${k}">${l}</button>`).join("") + `<button class="btn ok solid" data-t="closed">إغلاق</button>`;
  return {title:t.no, html:`${head("🎧 " + t.subject, `<span class="mono">${esc(t.no)}</span> · ${prBadge(t.priority)} ${tBadge(t.status)} ${slaBadge(t)} · ${custName(t.customerId)} · ${esc(t.type)} عبر ${esc(t.channel)}`, work?nextBtns:"")}
    <div class="route-h" style="margin-bottom:14px">${O.TICKET_FLOW.map(([k,l],i)=>`${i?'<span class="arrow">←</span>':""}<span class="chip" style="${i<idx?"border-color:var(--ok);color:var(--ok)":i===idx?"border-color:var(--accent);background:var(--accent-soft);font-weight:700":"opacity:.6"}">${esc(l)}</span>`).join("")}<span class="arrow">←</span><span class="chip" style="${t.closedAt?"border-color:var(--ok)":"opacity:.6"}">تحليل جودة</span></div>
    <div class="grid g2">
      <div class="card"><dl class="kv"><dt>التفاصيل</dt><dd style="white-space:pre-wrap">${esc(t.details||"—")}</dd><dt>التأثير</dt><dd>${esc(t.impact||"—")}</dd>
        <dt>المشروع / الإصدار</dt><dd>${t.projectId?`<a href="#/project/${t.projectId}">${esc((O.project(t.projectId)||{}).name||"")}</a>`:"—"} <span class="mono">${esc(t.version||"")}</span></dd>
        <dt>المالك</dt><dd>${empName(t.ownerId)}${t.referredTo?" · محالة إلى " + empName(t.referredTo):""}</dd>
        <dt>مهلة الاستجابة</dt><dd>${fmtDT(t.respondBy)} ${t.firstResponseAt?"· استُجيب " + fmtDT(t.firstResponseAt):""} ${s.respLate?'<span class="badge bad">متأخر</span>':""}</dd>
        <dt>مهلة الحل</dt><dd>${fmtDT(t.resolveBy)} ${s.resLate?'<span class="badge bad">متأخر</span>':""}</dd>
        ${t.solution?`<dt>الحل المقترح</dt><dd>${esc(t.solution)}</dd>`:""}${t.closedAt?`<dt>الإغلاق</dt><dd>${esc(O.CLOSE_BASIS[t.closeBasis])} · ${fmtDT(t.closedAt)}${t.closeNote?" — " + esc(t.closeNote):""}</dd><dt>السبب الجذري</dt><dd>${esc(t.rootCause)}</dd>`:""}
        ${t.bugId?`<dt>العيب</dt><dd><a href="#/bug/${t.bugId}">${esc((S().bugs.find(b=>b.id===t.bugId)||{}).no||"")}</a></dd>`:""}${t.complaintRequestId?`<dt>مسار الشكوى</dt><dd><a href="#/request/${t.complaintRequestId}">${esc((S().requests.find(r=>r.id===t.complaintRequestId)||{}).no||"")}</a></dd>`:""}</dl>
        ${work && t.status!=="closed"?`<div class="row" style="margin-top:12px">${t.projectId && !t.bugId?'<button class="btn sm" id="to-bug">🐞 تحويل لعيب</button>':""}${!t.complaintRequestId?'<button class="btn sm" id="to-cmp">⚠️ تصعيد كشكوى عالية الخطورة</button>':""}<button class="btn sm" id="ncr">فتح إجراء تصحيحي</button></div>`:""}
        ${t.status==="closed"?`<div class="card" style="margin-top:12px;background:var(--surface-2)"><h3>رضا العميل بعد الإغلاق</h3>${t.csat?`<div style="font-size:1.3rem;color:var(--gold)">${"★".repeat(t.csat)}${"☆".repeat(5-t.csat)}</div><div class="small">${esc(t.csatComment||"")}</div>`:(work?`<div class="row" style="margin-top:6px">${[1,2,3,4,5].map(n=>`<button class="btn sm" data-csat="${n}">${n} ★</button>`).join("")}</div>`:empty("لم يُقَس بعد"))}</div>`:""}</div>
      <div class="card"><h2 style="margin-bottom:10px">المراسلات</h2>
        ${t.messages.map(mg=>`<div class="list-item">${avatar(BOS.byId(mg.by))}<div class="grow"><b class="small">${empName(mg.by)}</b> ${mg.internal?'<span class="badge">داخلية</span>':'<span class="badge accent">للعميل</span>'} <span class="muted small">${fmtDT(mg.at)}</span><div style="white-space:pre-wrap">${esc(mg.text)}</div></div></div>`).join("")||'<div class="muted small">لا توجد مراسلات</div>'}
        ${work && t.status!=="closed"?`<div class="field" style="margin-top:10px">${kb.length?`<select class="input" id="kbp" style="margin-bottom:6px"><option value="">إدراج رد من قاعدة المعرفة المعتمدة…</option>${kb.map(a=>`<option value="${a.id}">${esc(a.title)}</option>`).join("")}</select>`:""}<textarea class="input" id="msg"></textarea></div>
          <div class="row"><label class="check"><input type="checkbox" id="internal"> ملاحظة داخلية</label><span class="spacer"></span><button class="btn primary" id="send">إرسال</button></div>`:""}
        <h3 style="margin:14px 0 6px">السجل</h3>${t.log.slice().reverse().map(l=>`<div class="small list-item"><span class="muted">${fmtDT(l.at)}</span><div class="grow">${l.to?tBadge(l.to):""} ${l.by?empName(l.by):""} ${esc(l.note||"")}</div></div>`).join("")}</div>
    </div>`,
    bind: root => {
      $$("[data-t]",root).forEach(b=>b.onclick=()=>{ const to = b.dataset.t;
        if(to==="closed") return modal("إغلاق " + t.no, `<div class="note small" style="margin-bottom:10px">لا تُغلق التذكرة بمجرد إرسال رد. الإغلاق يحتاج نتيجة موثقة أو تأكيد العميل أو قرار تصعيد معتمد.</div>
          <div class="field"><label class="f">أساس الإغلاق *</label><select class="input" name="basis"><option value="">—</option>${Object.entries(O.CLOSE_BASIS).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select></div>
          <div class="field"><label class="f">السبب الجذري (لتحليل الجودة) *</label><select class="input" name="rootCause"><option value="">—</option>${O.ROOT_CAUSES.map(c=>`<option>${c}</option>`).join("")}</select></div>
          <div class="field"><label class="f">التوثيق</label><textarea class="input" name="comment" placeholder="تأكيد العميل بتاريخ… / النتيجة الموثقة / قرار التصعيد"></textarea></div>`,
          [{label:"إغلاق", cls:"ok solid", onClick:bg=>{ O.moveTicket(t,"closed",formData(bg)); U.refresh(); }}]);
        if(to==="referred") return modal("إحالة التذكرة", `<div class="field"><label class="f">إلى</label><select class="input" name="referTo">${userOptions("", x=>["pm","devlead","dev","secops","qm","cto","coo","testlead"].includes((BOS.pos(x.positionId)||{}).key))}</select></div><div class="field"><label class="f">ملاحظة</label><input class="input" name="comment"></div>`,
          [{label:"إحالة", cls:"primary", onClick:bg=>{ O.moveTicket(t,"referred",formData(bg)); U.refresh(); }}]);
        if(to==="proposed") return modal("الحل المقترح", `<div class="field"><label class="f">الحل *</label><textarea class="input" name="comment"></textarea></div>`, [{label:"حفظ", cls:"primary", onClick:bg=>{ O.moveTicket(t,"proposed",formData(bg)); U.refresh(); }}]);
        if(to==="classified") return modal("تصنيف التذكرة", `<div class="field"><label class="f">الأولوية</label><select class="input" name="priority">${Object.entries(O.PRIORITY).map(([k,v])=>`<option value="${k}" ${k===t.priority?"selected":""}>${v}</option>`).join("")}</select></div><div class="field"><label class="f">ملاحظة</label><input class="input" name="comment"></div>`,
          [{label:"حفظ", cls:"primary", onClick:bg=>{ O.moveTicket(t,"classified",formData(bg)); U.refresh(); }}]);
        act(()=>O.moveTicket(t,to,{}));
      });
      if($("#kbp",root)) $("#kbp",root).onchange = e => { const a = S().kb.find(x=>x.id===e.target.value); if(a){ $("#msg",root).value = a.body; a.views++; } };
      if($("#send",root)) $("#send",root).onclick = () => act(()=>O.ticketReply(t, $("#msg",root).value.trim(), $("#internal",root).checked));
      if($("#to-bug",root)) $("#to-bug",root).onclick = () => act(()=>{ const b = O.ticketToBug(t, t.priority==="P1"?"critical":t.priority==="P2"?"high":"medium"); toast("أنشئ العيب " + b.no,"ok"); });
      if($("#to-cmp",root)) $("#to-cmp",root).onclick = () => act(()=>{ const r = O.ticketToComplaint(t); toast("بدأ مسار الشكوى " + r.no,"ok"); });
      if($("#ncr",root)) $("#ncr",root).onclick = () => ncrEditor({projectId:t.projectId, ticketId:t.id, source:"تذكرة " + t.no, description:t.subject + " — " + t.details});
      $$("[data-csat]",root).forEach(b=>b.onclick=()=>{ const c = Number(b.dataset.csat) <= 2 ? (prompt("سبب عدم الرضا:")||"") : ""; act(()=>O.recordCsat(t, b.dataset.csat, c),"سُجل التقييم"); });
    }};
}

/* =================== إضافات للرئيسية ولوحة المدير العام =================== */
function homeExtra(){
  const u = me(); if(!BOS.can(u,"projects","view") && !BOS.can(u,"support","view")) return "";
  const tasks = S().tasks.filter(t=>t.status!=="done" && (t.ownerId===u.id || (t.reviewerId===u.id && t.status==="review")));
  const ps = S().projects.filter(p=>p.status!=="closed" && (p.pmId===u.id || (p.members||[]).includes(u.id)));
  const tk = S().tickets.filter(t=>t.status!=="closed" && (t.ownerId===u.id || t.referredTo===u.id));
  if(!tasks.length && !ps.length && !tk.length) return "";
  return `<div class="grid g2" style="margin-top:14px">
    <div class="card"><div class="card-head"><h2>مهامي في المشاريع</h2></div>${tasks.length?tasks.slice(0,8).map(t=>`<div class="list-item"><span class="badge ${t.status==="review"?"warn":""}">${t.reviewerId===u.id&&t.status==="review"?"للمراجعة":esc(O.TASK_STATUS[t.status])}</span><div class="grow"><a href="#/project/${t.projectId}/tasks">${esc(t.title)}</a><div class="small muted">${esc((O.project(t.projectId)||{}).name||"")}${t.due?" · " + fmtDate(t.due):""}</div></div></div>`).join(""):empty("لا مهام")}
      ${tk.length?`<h3 style="margin:12px 0 6px">تذاكر مسندة إلي</h3>${tk.map(t=>`<div class="small"><a href="#/ticket/${t.id}">${esc(t.no)}</a> ${prBadge(t.priority)} ${esc(t.subject)} ${slaBadge(t)}</div>`).join("")}`:""}</div>
    <div class="card"><div class="card-head"><h2>حالة مشاريعي</h2></div>${ps.length?ps.map(p=>{ const ts = O.projTasks(p); const d = ts.filter(t=>t.status==="done").length;
      return `<div class="list-item">${pBadge(p.status)}<div class="grow"><a href="#/project/${p.id}">${esc(p.name)}</a><div class="small muted">${d}/${ts.length} مهمة · ${O.openBugs(p).length} عيب مفتوح</div>${bar(ts.length?d/ts.length*100:0)}</div></div>`; }).join(""):empty("لست عضواً في مشاريع مفتوحة")}</div></div>`;
}
function dashExtra(){
  const u = me(); if(!BOS.can(u,"projects","view")) return "";
  const m = O.metrics();
  const risky = S().projects.filter(p=>!["closed"].includes(p.status) && (p.risks.some(r=>r.status==="open"&&r.impact==="عالي") || (p.end && p.end < BOS.now().slice(0,10) && !["launch","support"].includes(p.status)) || O.openBugs(p,["critical"]).length));
  return `<h2 style="margin:18px 0 10px">المشاريع والجودة وخدمة العملاء</h2>
    <div class="grid g4">${kpi("التسليم في الموعد", pct(m.onTime))}${kpi("معدل العيوب بعد الإطلاق", m.postLaunch, "", m.postLaunch?"warn":"")}${kpi("رضا العملاء", m.csat==null?"—":m.csat.toFixed(1)+"/5")}${kpi("الالتزام باتفاقية الخدمة", pct(m.sla), m.breached + " تذكرة متجاوزة", m.breached?"bad":"")}</div>
    <div class="card" style="margin-top:14px"><div class="card-head"><h2>المشاريع المتأخرة أو عالية المخاطر</h2><a class="small" href="#/projects">كل المشاريع</a></div>
      ${risky.length?risky.map(p=>`<div class="list-item">${pBadge(p.status)}<div class="grow"><a href="#/project/${p.id}">${esc(p.name)}</a><div class="small muted">${[p.end && p.end < BOS.now().slice(0,10)?"متأخر عن " + fmtDate(p.end):"", p.risks.filter(r=>r.status==="open"&&r.impact==="عالي").map(r=>"خطر: " + r.text).join("، "), O.openBugs(p,["critical"]).length?O.openBugs(p,["critical"]).length + " عيب حرج":""].filter(Boolean).map(esc).join(" · ")}</div></div></div>`).join(""):empty("لا توجد")}</div>`;
}

Object.assign(window.BOS_VIEWS, {projects, project, bug, testing, quality, "quality-report":qualityReport, ncr, support, ticket, delivery, readiness});
window.BOS_VIEWS_OPS = {homeExtra, dashExtra};
})();
