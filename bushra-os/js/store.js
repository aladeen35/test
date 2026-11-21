/* نظام البشرى لإدارة الشركة — الحالة، التخزين، سجل التدقيق، الصلاحيات، ومحرك الموافقات */
(function(){
"use strict";
const D = window.BOS_DATA;
const KEY = "bushra-os-v1";

/* ---------- أدوات ---------- */
const uid = p => (p||"id") + "_" + Date.now().toString(36) + Math.random().toString(36).slice(2,7);
const now = () => new Date().toISOString();
const clone = o => JSON.parse(JSON.stringify(o));
/* بصمة متزامنة (cyrb53) لسلسلة التدقيق ونسخ البيانات المعتمدة */
function hash(str){
  let h1 = 0xdeadbeef, h2 = 0x41c6ce57;
  for(let i=0;i<str.length;i++){ const ch=str.charCodeAt(i); h1=Math.imul(h1^ch,2654435761); h2=Math.imul(h2^ch,1597334677); }
  h1 = Math.imul(h1^(h1>>>16),2246822507) ^ Math.imul(h2^(h2>>>13),3266489909);
  h2 = Math.imul(h2^(h2>>>16),2246822507) ^ Math.imul(h1^(h1>>>13),3266489909);
  return (h2>>>0).toString(16).padStart(8,"0") + (h1>>>0).toString(16).padStart(8,"0");
}
const stable = o => JSON.stringify(o, Object.keys(o||{}).sort());

/* ---------- الحالة ---------- */
let S = null;
function blank(){
  return {
    v:1, setupDone:false, company:{}, settings:{},
    departments:[], positions:[], employees:[], policies:{},
    requests:[], documents:[], customers:[], quotes:[], invoices:[],
    projects:[], tasks:[], testCases:[], bugs:[], reviews:[], ncrs:[], tickets:[], kb:[],
    attendance:[], goals:[], evaluations:[], assets:[], hrNotes:[], onboarding:[],
    skills:[], skillReq:{}, empSkills:{}, programs:[], providers:[],
    content:[], interactions:[], surveys:[],
    ropa:[], dsr:[], incidentPlans:{}, backups:[], accessReviews:[], outbox:[], signatures:[],
    mail:[], bindings:{},
    notifications:[], audit:[], counters:{}, session:null
  };
}
function load(){
  try{ const raw = localStorage.getItem(KEY); S = raw ? JSON.parse(raw) : blank(); }
  catch(e){ S = blank(); }
  migrate();
  return S;
}
/* ترقية بيانات الإصدارات السابقة: إضافة وحدات المرحلة الثالثة دون المساس بما أنشأه المستخدم */
function migrate(){
  const b = blank();
  for(const k in b) if(S[k] === undefined) S[k] = b[k];
  if(!S.setupDone) return;
  S.settings.modules = S.settings.modules || {};
  for(const m of D.ADDED_MODULES){
    if(S.settings.modules[m] === undefined) S.settings.modules[m] = true;
    for(const p of S.positions){
      const x = D.ADDED_PERMS(p.key);
      if(x[m] && !(p.perms[m]||[]).length) p.perms[m] = x[m].slice();
      if((p.key==="gm"||p.key==="owner") && !(p.perms[m]||[]).length) p.perms[m] = D.ACTIONS.map(a=>a[0]);
    }
  }
  for(const t in D.POLICIES) if(!S.policies[t]) S.policies[t] = clone(D.POLICIES[t]);
  if(S.settings.passRate === undefined) S.settings.passRate = 95;
  if(!S.settings.sla) S.settings.sla = {P1:[1,8], P2:[4,24], P3:[8,72], P4:[24,120]};
  if(!S.settings.work) S.settings.work = {start:"08:00", end:"16:00", grace:15, weekend:[5,6]};
  if(window.BOS_HR) BOS_HR.migrate();
  if(window.BOS_SEC) BOS_SEC.migrate();
  if(window.BOS_MAIL) BOS_MAIL.migrate();
}
function save(){
  // في الوضع المشترك تذهب البيانات لقاعدة البيانات المشتركة، ولا تُكتب فوق بيانات هذا المتصفح المحلية
  if(window.BOS_SYNC && BOS_SYNC.shared){ BOS_SYNC.changed(); return; }
  try{ localStorage.setItem(KEY, JSON.stringify(S)); }
  catch(e){ window.BOS_UI && BOS_UI.toast("تعذر الحفظ على الجهاز: " + e.message, "bad"); }
}
function reset(){ if(!(window.BOS_SYNC && BOS_SYNC.shared)) localStorage.removeItem(KEY); S = blank(); }
function replace(o){ S = o; migrate(); }

/* ---------- الترقيم (لا يعاد استخدام أي رقم) ---------- */
function nextNo(prefix){
  const y = new Date().getFullYear();
  const k = prefix + "-" + y;
  S.counters[k] = (S.counters[k]||0) + 1;
  return k + "-" + String(S.counters[k]).padStart(4,"0");
}

/* ---------- سجل التدقيق: إلحاق فقط + سلسلة بصمات ---------- */
function audit(action, entity, entityId, details, actorId){
  const actor = byId(actorId || (S.session && S.session.userId));
  const prev = S.audit.length ? S.audit[S.audit.length-1].hash : "GENESIS";
  const ev = {
    seq: S.audit.length + 1, at: now(),
    actorId: actor ? actor.id : null, actorName: actor ? actor.name : "النظام",
    actorPos: actor ? posTitle(actor.positionId) : "",
    action, entity, entityId: entityId||null, details: details||"", prev
  };
  ev.hash = hash(prev + "|" + stable(Object.assign({}, ev, {hash:undefined})));
  S.audit.push(ev);
  return ev;
}
function verifyAudit(){
  let prev = "GENESIS";
  for(const ev of S.audit){
    const h = hash(prev + "|" + stable(Object.assign({}, ev, {hash:undefined})));
    if(ev.prev !== prev || ev.hash !== h) return {ok:false, at:ev.seq};
    prev = ev.hash;
  }
  return {ok:true, count:S.audit.length};
}

/* ---------- الإشعارات ---------- */
function notify(userId, text, link, kind){
  if(!userId) return;
  const n = {id:uid("n"), userId, text, link:link||"", kind:kind||"info", read:false, at:now()};
  S.notifications.unshift(n);
  if(S.notifications.length > 600) S.notifications.length = 600;
  if(window.BOS_SEC) BOS_SEC.onNotify(n);
}

/* ---------- استعلامات ---------- */
const byId = id => S && S.employees.find(e=>e.id===id);
const pos = id => S.positions.find(p=>p.id===id);
const posByKey = k => S.positions.find(p=>p.key===k);
const dept = id => S.departments.find(d=>d.id===id);
const posTitle = id => (pos(id)||{}).title || "—";
const me = () => S.session ? byId(S.session.userId) : null;
const active = e => e && e.status === "active" && (!e.validTo || e.validTo >= now().slice(0,10));

/* شاغل المنصب الفعلي — مع البديل أثناء الإجازة */
function holderOf(posKey){
  const p = posByKey(posKey); if(!p) return null;
  const e = S.employees.find(x=>x.positionId===p.id && active(x));
  if(!e) return null;
  if(e.onLeave && e.delegateId && active(byId(e.delegateId))) return {id:e.delegateId, delegatedFrom:e.id};
  return {id:e.id};
}
/* المدير المباشر: المسجل، أو شاغل المنصب الأعلى في التسلسل */
function managerOf(emp){
  if(!emp) return null;
  let m = emp.managerId && byId(emp.managerId);
  if(m && active(m)) return m;
  let p = pos(emp.positionId);
  while(p && p.reportsTo){
    const up = posByKey(p.reportsTo);
    const h = up && S.employees.find(x=>x.positionId===up.id && active(x) && x.id!==emp.id);
    if(h) return h;
    p = up;
  }
  return null;
}
function isTop(emp){ const p = emp && pos(emp.positionId); return !!p && (p.key==="gm" || p.key==="owner"); }

/* ---------- الصلاحيات (القسم 8.1): الدور + القسم + نطاق السجل + الحالة + السرية ---------- */
function can(emp, module, action){
  if(!emp || !active(emp)) return false;
  if(module !== "settings" && S.settings.modules && S.settings.modules[module] === false) return false;
  const p = pos(emp.positionId); if(!p) return false;
  const custom = emp.permsOverride && emp.permsOverride[module];
  const list = custom || (p.perms && p.perms[module]) || [];
  return list.includes(action);
}
function clearance(emp){ return emp ? (emp.clearance || (pos(emp.positionId)||{}).clearance || 1) : 0; }
function scopeOf(emp){ return emp ? (emp.scope || (pos(emp.positionId)||{}).scope || "record") : "record"; }

function canSeeRequest(emp, r){
  if(!emp) return false;
  if(isTop(emp)) return true;
  const involved = r.creatorId===emp.id || r.steps.some(s=>s.assigneeId===emp.id || s.actedBy===emp.id) || (r.watchers||[]).includes(emp.id);
  if(involved) return true;
  if(D.TYPES[r.type] && D.TYPES[r.type].confidential) return false; // الحوادث الأمنية مقيدة
  if(!can(emp,"requests","view")) return false;
  const sc = scopeOf(emp);
  if(sc === "company") return true;
  if(sc === "dept"){ const c = byId(r.creatorId); return c && c.deptId === emp.deptId; }
  return false;
}
function canSeeDoc(emp, d){
  if(!emp || !can(emp,"documents","view")) return false;
  if(isTop(emp)) return true;
  if(d.ownerId === emp.id) return true;
  if(d.classification > clearance(emp)) return false;
  if(d.deptId && scopeOf(emp) !== "company" && d.classification >= 3 && d.deptId !== emp.deptId) return false;
  return true;
}

/* ---------- محرك الموافقات (القسم 7) ---------- */
function amountOf(type, data){ const f = D.TYPES[type] && D.TYPES[type].amount; return f ? Number(data[f]||0) : 0; }
function condMet(when, type, data){
  if(!when) return true;
  if(when.any) return when.any.some(w=>condMet(w,type,data));
  if(when.flag) return !!data[when.flag];
  if(when.min !== undefined){
    const lim = when.min === "gm" ? Number(S.settings.gmThreshold||0) : Number(when.min);
    const a = amountOf(type,data);
    return when.min === "gm" ? a >= lim && lim > 0 : a >= lim;
  }
  return true;
}
/* يبني المسار: يعين كل مرحلة لشخص فعلي، ويمنع الاعتماد الذاتي بالتصعيد */
function buildRoute(type, data, creatorId){
  const creator = byId(creatorId);
  const tpl = S.policies[type] || [];
  const steps = [];
  for(const t of tpl){
    const st = {id:uid("s"), label:t.label, who:t.who, stage:t.stage, status:"pending", notes:[]};
    if(!condMet(t.when, type, data)){ st.status = "skipped"; st.skipReason = "الشرط غير منطبق"; steps.push(st); continue; }
    let target = null;
    if(t.who === "creator") target = {id:creatorId};
    else if(t.who === "manager"){ const m = managerOf(creator); target = m ? {id:m.id} : null; }
    else target = holderOf(t.who);
    if(!target){
      // المنصب شاغر → يصعد إلى المدير العام
      const g = holderOf("gm");
      st.notes.push("المنصب شاغر — أحيلت المرحلة للمدير العام");
      target = g;
    }
    if(target && target.delegatedFrom) st.notes.push("تفويض: البديل أثناء إجازة " + (byId(target.delegatedFrom)||{}).name);
    // منع الاعتماد الذاتي (المبدأ 3)
    if(target && target.id === creatorId && (t.stage==="review" || t.stage==="approve")){
      const up = managerOf(creator);
      if(up){ st.notes.push("تصعيد تلقائي لمنع اعتماد المنشئ لطلبه"); target = {id:up.id}; }
      else { st.selfException = true; st.notes.push("استثناء: لا يوجد مستوى أعلى — يتطلب اعتماد المدير العام الاستثنائي مع سبب"); }
    }
    st.assigneeId = target ? target.id : null;
    steps.push(st);
  }
  // إزالة التكرار المتتالي لنفس المعتمد في مرحلتين متتاليتين من نوع اعتماد/مراجعة
  return steps;
}
function currentStep(r){ return r.steps.find(s=>s.status==="pending"); }
function routePreview(type, data, creatorId){
  const steps = buildRoute(type, data, creatorId);
  const live = steps.filter(s=>s.status!=="skipped");
  const needsGm = live.some(s=>{ const e=byId(s.assigneeId); return e && pos(e.positionId).key==="gm"; });
  return {steps, first: live[0], needsGm, days: (D.TYPES[type]||{}).days||3};
}

function createRequest(type, data, opts){
  const u = me(); const T = D.TYPES[type];
  const r = {
    id: uid("r"), no: nextNo("REQ"), type, title: (opts&&opts.title) || T.name,
    data: clone(data), amount: amountOf(type,data), creatorId: u.id, deptId: u.deptId,
    status: "in_review", createdAt: now(), updatedAt: now(),
    due: new Date(Date.now() + T.days*864e5).toISOString().slice(0,10),
    version: 1, link: (opts&&opts.link)||null, watchers:[], comments:[], history:[]
  };
  r.steps = buildRoute(type, r.data, u.id);
  r.history.push({v:1, at:now(), by:u.id, data:clone(r.data), hash:hash(stable(r.data))});
  S.requests.unshift(r);
  audit("إنشاء طلب", "request", r.id, r.no + " — " + T.name);
  advance(r);
  save();
  return r;
}
/* ينقل الطلب للمرحلة التالية ويشعر صاحبها، أو يغلقه */
function advance(r){
  const st = currentStep(r);
  if(!st){
    r.status = "closed"; r.closedAt = now();
    notify(r.creatorId, "اكتمل الطلب " + r.no + " وأغلق", "#/request/" + r.id, "ok");
    audit("إغلاق طلب", "request", r.id, r.no + " — اكتملت جميع المراحل");
    onClosed(r);
    return;
  }
  r.status = (st.stage==="execute"||st.stage==="close") ? "executing" : "in_review";
  if(r.status==="executing" && !r.approvedAt) r.approvedAt = now();
  st.startedAt = now();
  st.dueAt = new Date(Date.now() + 2*864e5).toISOString();
  notify(st.assigneeId, "بانتظارك: " + D.STAGES[st.stage] + " — " + r.no + " (" + r.title + ")", "#/request/" + r.id, "task");
}
/* أثر الإغلاق على الكيانات المرتبطة */
function onClosed(r){
  if(r.type==="leave"){
    const e = byId(r.creatorId);
    if(e){ const days = Math.max(1, Math.round((new Date(r.data.to)-new Date(r.data.from))/864e5)+1);
      e.leaveUsed = (e.leaveUsed||0) + days;
      audit("تحديث رصيد الإجازات", "employee", e.id, e.name + " — خصم " + days + " يوم"); }
  }
  if(r.link && r.link.kind==="document"){
    const d = S.documents.find(x=>x.id===r.link.id);
    const v = d && d.versions.find(x=>x.v===r.link.v);
    if(v){ v.status="approved"; v.approvedAt=now(); v.approvedBy = lastApprover(r); v.requestId=r.id;
      d.versions.forEach(o=>{ if(o!==v && o.status==="approved") o.status="superseded"; });
      d.current = v.v;
      audit("اعتماد إصدار مستند", "document", d.id, d.no + " الإصدار " + v.v); }
  }
  if(r.link && r.link.kind==="invoice"){
    const inv = S.invoices.find(x=>x.id===r.link.id);
    if(inv && inv.status==="pending"){ inv.status="sent"; inv.approvedBy=lastApprover(r); inv.approvedAt=now();
      audit("اعتماد وإرسال فاتورة", "invoice", inv.id, inv.no); }
  }
  if(window.BOS_OPS) BOS_OPS.onClosed(r);
  if(window.BOS_HR) BOS_HR.onClosed(r);
}
/* عند الرفض أو الإلغاء: يعود الكيان المرتبط إلى مسودة */
function onAborted(r){
  if(r.link && r.link.kind==="document"){
    const d = S.documents.find(x=>x.id===r.link.id); const v = d && d.versions.find(x=>x.v===r.link.v);
    if(v && v.status==="in_review") v.status = "draft";
  }
  if(r.link && r.link.kind==="invoice"){
    const inv = S.invoices.find(x=>x.id===r.link.id);
    if(inv && inv.status==="pending") inv.status = "draft";
  }
  if(window.BOS_OPS) BOS_OPS.onAborted(r);
  if(window.BOS_HR) BOS_HR.onAborted(r);
}
function lastApprover(r){ const a = r.steps.filter(s=>s.status==="approved" && (s.stage==="approve"||s.stage==="review")).pop(); return a ? a.actedBy : null; }

/* الإجراءات على المرحلة الحالية (القسم 7.3) */
function act(r, action, o){
  o = o || {};
  const u = me(); const st = currentStep(r);
  const T = D.TYPES[r.type];
  const isAssignee = st && st.assigneeId === u.id;
  const gm = isTop(u);
  const fail = m => { throw new Error(m); };

  if(action === "cancel"){
    if(!(r.creatorId===u.id || gm)) fail("الإلغاء متاح للمنشئ أو المدير العام فقط");
    if(!o.comment) fail("سبب الإلغاء إلزامي");
    r.status = "cancelled"; r.cancelReason = o.comment; r.updatedAt = now();
    r.steps.forEach(s=>{ if(s.status==="pending") s.status="cancelled"; });
    onAborted(r);
    audit("إلغاء طلب", "request", r.id, r.no + " — " + o.comment);
    r.steps.filter(s=>s.assigneeId && s.assigneeId!==u.id).forEach(s=>notify(s.assigneeId, "أُلغي الطلب " + r.no, "#/request/"+r.id));
    return save();
  }
  if(action === "resubmit" || action === "answer"){
    if(r.creatorId !== u.id) fail("هذا الإجراء للمنشئ فقط");
    if(action === "resubmit"){
      if(r.status !== "returned") fail("الطلب ليس معاداً للتعديل");
      if(o.data){ r.data = clone(o.data); r.amount = amountOf(r.type, r.data); }
      r.version += 1;
      r.history.push({v:r.version, at:now(), by:u.id, data:clone(r.data), hash:hash(stable(r.data))});
      // إعادة بناء المسار من البداية على الإصدار الجديد (الموافقات السابقة تبقى في السجل)
      r.previousRounds = (r.previousRounds||[]).concat([r.steps]);
      r.steps = buildRoute(r.type, r.data, r.creatorId);
      audit("إعادة إرسال بعد التعديل", "request", r.id, r.no + " — الإصدار " + r.version);
      advance(r);
    } else {
      if(r.status !== "info_requested") fail("لا يوجد طلب معلومات مفتوح");
      st.notes.push("رد المنشئ: " + (o.comment||""));
      r.status = "in_review";
      audit("رد على طلب معلومات", "request", r.id, r.no + " — " + (o.comment||""));
      notify(st.assigneeId, "رد المنشئ على طلب المعلومات — " + r.no, "#/request/"+r.id);
    }
    r.updatedAt = now(); return save();
  }
  if(action === "comment"){
    if(!o.comment) fail("اكتب التعليق");
    r.comments.push({by:u.id, at:now(), text:o.comment});
    audit("تعليق", "request", r.id, r.no);
    return save();
  }

  if(!st) fail("لا توجد مرحلة مفتوحة");
  if(!["in_review","executing"].includes(r.status)) fail("الطلب في حالة لا تسمح بهذا الإجراء");
  const override = !isAssignee && gm;
  if(!isAssignee && !gm) fail("هذه المرحلة ليست مسندة إليك");
  if(override && !o.comment) fail("تدخل المدير العام في مرحلة غير مسندة إليه يتطلب ذكر السبب");
  if(st.selfException && u.id===r.creatorId && action==="approve" && !o.comment) fail("الاعتماد الذاتي الاستثنائي يتطلب سبباً");
  if(u.id === r.creatorId && (st.stage==="review"||st.stage==="approve") && action==="approve" && !st.selfException) fail("لا يجوز للمنشئ اعتماد طلبه");

  const snap = hash(stable(r.data) + "#v" + r.version);
  const mark = (status) => {
    st.status = status; st.actedBy = u.id; st.actedAt = now(); st.comment = o.comment||"";
    st.actorPos = posTitle(u.positionId); st.snapshot = snap; st.dataVersion = r.version;
    if(override) st.override = true;
  };
  const label = D.STAGES[st.stage] + " — " + st.label;

  switch(action){
    case "approve":
    case "conditional":
      if(action==="conditional" && !o.comment) fail("اكتب الشرط");
      if(window.BOS_SEC){ const blk = BOS_SEC.beforeComplete(r, st); if(blk) fail(blk); }
      mark("approved"); if(action==="conditional") st.conditional = true;
      audit(action==="conditional" ? "اعتماد مشروط" : (st.stage==="execute"||st.stage==="close" ? "إتمام مرحلة" : "اعتماد"),
        "request", r.id, r.no + " — " + label + (override?" (تدخل المدير العام)":"") + (o.comment?" — "+o.comment:"") + " — بصمة البيانات " + snap);
      notify(r.creatorId, "تمت الموافقة على مرحلة «" + st.label + "» في " + r.no + " بواسطة " + u.name, "#/request/"+r.id, "ok");
      advance(r);
      break;
    case "reject":
      if(!o.comment) fail("سبب الرفض إلزامي");
      mark("rejected"); r.status = "rejected";
      r.steps.forEach(s=>{ if(s.status==="pending") s.status="cancelled"; });
      onAborted(r);
      audit("رفض", "request", r.id, r.no + " — " + label + " — " + o.comment);
      notify(r.creatorId, "رُفض الطلب " + r.no + ": " + o.comment, "#/request/"+r.id, "bad");
      break;
    case "return":
      if(!o.comment) fail("وضح المطلوب تعديله");
      mark("returned"); r.status = "returned";
      audit("إعادة للتعديل", "request", r.id, r.no + " — " + label + " — " + o.comment);
      notify(r.creatorId, "أعيد الطلب " + r.no + " للتعديل: " + o.comment, "#/request/"+r.id, "warn");
      break;
    case "info":
      if(!o.comment) fail("اكتب المعلومات المطلوبة");
      st.notes.push("طلب معلومات من " + u.name + ": " + o.comment);
      r.status = "info_requested";
      audit("طلب معلومات", "request", r.id, r.no + " — " + o.comment);
      notify(r.creatorId, "مطلوب معلومات إضافية في " + r.no + ": " + o.comment, "#/request/"+r.id, "warn");
      break;
    case "delegate": {
      const to = byId(o.toId);
      if(!to || !active(to)) fail("اختر موظفاً نشطاً");
      if(to.id === r.creatorId && (st.stage==="review"||st.stage==="approve")) fail("لا يجوز التفويض لمنشئ الطلب");
      st.notes.push("فوض " + u.name + " المرحلة إلى " + to.name + (o.comment?" — "+o.comment:""));
      st.delegatedFrom = st.assigneeId; st.assigneeId = to.id;
      audit("تفويض مرحلة", "request", r.id, r.no + " — " + label + " → " + to.name);
      notify(to.id, "فُوض إليك: " + label + " في " + r.no, "#/request/"+r.id, "task");
      break; }
    case "escalate": {
      const cur = byId(st.assigneeId); const up = managerOf(cur) || byId((holderOf("gm")||{}).id);
      if(!up || up.id===st.assigneeId) fail("لا يوجد مستوى أعلى للتصعيد");
      st.notes.push("تصعيد من " + (cur?cur.name:"—") + " إلى " + up.name + (o.comment?" — "+o.comment:""));
      st.assigneeId = up.id; st.escalated = true;
      audit("تصعيد", "request", r.id, r.no + " — " + label + " → " + up.name);
      notify(up.id, "تصعيد: " + label + " في " + r.no, "#/request/"+r.id, "bad");
      break; }
    default: fail("إجراء غير معروف");
  }
  r.updatedAt = now();
  save();
}
/* التصعيد التلقائي عند تجاوز موعد المرحلة (يُستدعى عند فتح التطبيق) */
function autoEscalate(){
  let n = 0;
  if(!S.settings.autoEscalate) return 0;
  for(const r of S.requests){
    if(!["in_review","executing"].includes(r.status)) continue;
    const st = currentStep(r); if(!st || !st.dueAt || st.autoEscalated) continue;
    if(new Date(st.dueAt) < new Date()){
      const cur = byId(st.assigneeId); const up = managerOf(cur);
      if(up && up.id !== r.creatorId){
        st.notes.push("تصعيد تلقائي بعد تجاوز المهلة من " + (cur?cur.name:"—") + " إلى " + up.name);
        st.assigneeId = up.id; st.autoEscalated = true;
        st.dueAt = new Date(Date.now()+2*864e5).toISOString();
        audit("تصعيد تلقائي", "request", r.id, r.no + " → " + up.name, null);
        notify(up.id, "تصعيد تلقائي (تجاوز المهلة): " + r.no, "#/request/"+r.id, "bad");
        n++;
      }
    }
  }
  if(n) save();
  return n;
}

/* ---------- المستندات والإصدارات (المبدأ 4) ---------- */
function createDoc(o){
  const u = me();
  const d = {id:uid("d"), no:nextNo("DOC"), title:o.title, category:o.category||"عام", classification:Number(o.classification||2),
    ownerId:u.id, deptId:u.deptId, file:o.file||null, createdAt:now(), current:1, expires:o.expires||"",
    versions:[{v:1, content:o.content||"", file:o.file||null, status:o.approved?"approved":"draft", createdBy:u.id, createdAt:now(), note:o.note||"الإصدار الأول", approvedBy:o.approved?u.id:null, approvedAt:o.approved?now():null}]};
  S.documents.unshift(d);
  audit("إنشاء مستند", "document", d.id, d.no + " — " + d.title);
  save(); return d;
}
function editDoc(d, content, note){
  const u = me();
  const cur = d.versions[d.versions.length-1];
  if(cur.status === "draft" && cur.createdBy === u.id){
    cur.content = content; cur.note = note || cur.note; cur.updatedAt = now();
    audit("تعديل مسودة", "document", d.id, d.no + " الإصدار " + cur.v);
  } else {
    // أي تعديل بعد الاعتماد أو على إصدار غير مسودة ينشئ إصداراً جديداً
    const v = {v:cur.v+1, content, file:cur.file, status:"draft", createdBy:u.id, createdAt:now(), note:note||"تعديل"};
    d.versions.push(v);
    audit("إنشاء إصدار جديد", "document", d.id, d.no + " — الإصدار " + v.v + " (الإصدار " + cur.v + " محفوظ دون تغيير)");
  }
  save();
}
function submitDoc(d){
  const v = d.versions[d.versions.length-1];
  if(v.status !== "draft") throw new Error("الإصدار الأخير ليس مسودة");
  v.status = "in_review";
  return createRequest("document", {docNo:d.no, title:d.title, version:String(v.v)}, {title:"اعتماد " + d.title + " — إ" + v.v, link:{kind:"document", id:d.id, v:v.v}});
}

/* ---------- المالية: عروض الأسعار والفواتير (القسم 6.9) ---------- */
function totals(items, discount, taxRate){
  const sub = items.reduce((a,i)=>a + Number(i.qty||0)*Number(i.price||0), 0);
  const disc = Number(discount||0);
  const tax = Math.max(0, sub-disc) * Number(taxRate||0) / 100;
  return {sub, disc, tax, total: Math.max(0, sub-disc) + tax};
}
function invoicePaid(inv){ return (inv.payments||[]).reduce((a,p)=>a+Number(p.amount||0),0); }
function invoiceState(inv){
  if(["draft","pending","cancelled","disputed"].includes(inv.status)) return inv.status;
  const t = totals(inv.items, inv.discount, inv.taxRate).total, p = invoicePaid(inv);
  if(p >= t - 0.001) return "paid";
  if(inv.due && inv.due < now().slice(0,10)) return p>0 ? "partial_overdue" : "overdue";
  return p>0 ? "partial" : "sent";
}

/* ---------- الجلسة ---------- */
function login(userId){
  S.session = {userId, at:now(), last:Date.now()};
  audit("تسجيل دخول", "session", userId, "", userId);
  save();
}
function logout(reason){
  if(S.session){ audit(reason||"تسجيل خروج", "session", S.session.userId, "", S.session.userId); }
  S.session = null; save();
}
function touch(){ if(S.session){ S.session.last = Date.now(); } }
function sessionExpired(){
  if(!S.session) return false;
  const mins = Number(S.settings.sessionMinutes||30);
  return Date.now() - (S.session.last||0) > mins*60000;
}

window.BOS = {
  get S(){ return S; }, load, save, reset, replace, blank, migrate, lastApprover, uid, now, clone, hash, stable,
  nextNo, audit, verifyAudit, notify,
  byId, pos, posByKey, dept, posTitle, me, active, holderOf, managerOf, isTop,
  can, clearance, scopeOf, canSeeRequest, canSeeDoc,
  buildRoute, routePreview, currentStep, createRequest, act, autoEscalate, amountOf,
  createDoc, editDoc, submitDoc, totals, invoicePaid, invoiceState,
  login, logout, touch, sessionExpired
};
})();
