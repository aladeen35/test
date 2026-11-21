/* نظام البشرى لإدارة الشركة — المرحلة الثالثة: المشاريع والإنتاج، الاختبار والعيوب، الجودة، الدعم الفني وخدمة العملاء
   (الأقسام 6.5 – 6.8 و6.12) */
(function(){
"use strict";
const D = window.BOS_DATA;
const S = () => BOS.S;
const me = () => BOS.me();
const now = () => BOS.now();
const fail = m => { throw new Error(m); };
const posKey = e => e ? (BOS.pos(e.positionId)||{}).key : null;
const hours = h => h*36e5;

/* ---------- مراجع ---------- */
const PROJECT_FLOW = [
  ["draft","مسودة"],["contracting","بانتظار التعاقد"],["approved","معتمد"],["planning","تخطيط"],["production","إنتاج"],
  ["testing","اختبار"],["acceptance","قبول العميل"],["launch","إطلاق"],["support","دعم"],["closed","مغلق"]
];
const PSTATUS = Object.fromEntries(PROJECT_FLOW);
const TASK_STATUS = {todo:"جديدة", doing:"قيد التنفيذ", review:"بانتظار المراجعة", done:"مكتملة", blocked:"محجوبة"};
const BUG_STATUS = {open:"مفتوح", fixing:"قيد الإصلاح", fixed:"بانتظار إعادة الاختبار", closed:"مغلق", reopened:"أعيد فتحه", deferred:"مؤجل بقرار"};
const SEVERITY = {critical:"حرجة", high:"عالية", medium:"متوسطة", low:"منخفضة"};
const RESULT = {pass:"ناجح", fail:"فاشل", blocked:"محجوب"};
const NCR_STATUS = {open:"مفتوح", investigating:"تحليل السبب", action:"إجراء تصحيحي", verify:"تحقق الفعالية", closed:"مغلق"};
/* مسار شكوى العميل (القسم 6.7) */
const TICKET_FLOW = [
  ["new","استقبال"],["verified","تحقق من البيانات"],["classified","تصنيف"],["handling","معالجة أولية"],
  ["referred","إحالة"],["proposed","حل مقترح"],["closed","مغلق"]
];
const TSTATUS = Object.fromEntries(TICKET_FLOW);
const TICKET_TYPES = ["استفسار","طلب خدمة","عطل فني","شكوى"];
const PRIORITY = {P1:"P1 — حرجة", P2:"P2 — عالية", P3:"P3 — متوسطة", P4:"P4 — منخفضة"};
const CLOSE_BASIS = {confirmed:"تأكيد العميل", documented:"نتيجة موثقة (تعذر التأكيد)", escalation:"قرار تصعيد معتمد"};
const ROOT_CAUSES = ["عيب في المنتج","نقص في التدريب","تأخر في الاستجابة","سوء فهم للمتطلبات","بنية تحتية / استضافة","طرف ثالث","استخدام خاطئ","أخرى"];

/* قوائم الفحص الموحدة (القسم 6.6) — auto = بند يحسبه النظام من البيانات */
const CHECKLISTS = {
  gate:{name:"بوابة الجودة قبل التسليم", items:[
    {t:"كل المهام مكتملة ومتحقق من معيارها", auto:"tasks"},
    {t:"نسبة نجاح الاختبارات ≥ الحد المعتمد", auto:"passRate"},
    {t:"كل حالات الاختبار نُفذت على الإصدار الحالي", auto:"coverage"},
    {t:"لا توجد عيوب حرجة أو عالية مفتوحة", auto:"bugs"},
    {t:"اختبار قبول المستخدم ناجح", auto:"uat"},
    {t:"المستندات ودليل الاستخدام مراجعة ومعتمدة"},
    {t:"مراجعة الأمن والخصوصية منجزة"},
    {t:"خطة الإطلاق والتراجع جاهزة"},
    {t:"النسخ الاحتياطي واختبار الاستعادة"}
  ]},
  document:{name:"مراجعة مستند", items:[{t:"مطابق للقالب والهوية"},{t:"رقم المستند وإصداره صحيحان"},{t:"المحتوى كامل ولا حقول «يُعبأ»"},{t:"اللغة والصياغة سليمة"},{t:"معتمد من صاحب الصلاحية"}]},
  code:{name:"مراجعة كود", items:[{t:"يحقق معيار القبول"},{t:"اختبارات آلية مضافة وناجحة"},{t:"لا أسرار أو كلمات مرور في الكود"},{t:"معالجة الأخطاء والتحقق من المدخلات"},{t:"التوثيق والتعليقات كافية"}]},
  design:{name:"مراجعة تصميم", items:[{t:"مطابق للهوية البصرية"},{t:"يعمل على الهاتف والحاسوب"},{t:"تباين الألوان وإتاحة الوصول"},{t:"اتجاه RTL والنصوص العربية سليمة"},{t:"معتمد من العميل عند الحاجة"}]}
};

/* ---------- الرؤية ---------- */
function canSeeProject(u, p){
  if(!u || !p) return false;
  if(BOS.isTop(u)) return true;
  if(!BOS.can(u,"projects","view")) return false;
  if(p.pmId===u.id || (p.members||[]).includes(u.id)) return true;
  const k = posKey(u);
  if(["coo","cto","qm","testlead","cs","cfo","accountant"].includes(k)) return true;
  const sc = BOS.scopeOf(u);
  if(sc==="company") return true;
  if(sc==="dept"){ const pm = BOS.byId(p.pmId); return pm && pm.deptId===u.deptId; }
  return false;
}
const project = id => S().projects.find(p=>p.id===id);
const isPM = (u,p) => u && p && (p.pmId===u.id || BOS.isTop(u) || posKey(u)==="coo");

/* ---------- المشاريع (القسم 6.5) ---------- */
function createProject(o){
  const u = me();
  if(!BOS.can(u,"projects","create")) fail("لا تملك صلاحية إنشاء مشروع");
  if(!o.name) fail("اسم المشروع إلزامي");
  const q = o.quoteId && S().quotes.find(x=>x.id===o.quoteId);
  const p = {id:BOS.uid("p"), no:BOS.nextNo("PRJ"), name:o.name, customerId:o.customerId || (q&&q.customerId) || "",
    quoteId:o.quoteId||"", contractRequestId:o.contractRequestId||"", contractRef:o.contractRef||"",
    pmId:o.pmId||u.id, members:o.members||[], scope:o.scope||"", deliverables:o.deliverables||"",
    budget:Number(o.budget || (q ? BOS.totals(q.items,q.discount,q.taxRate).total : 0)), currency:(q&&q.currency)||S().settings.currency,
    start:o.start||now().slice(0,10), end:o.end||"", status:"draft", strategic:!!o.strategic,
    milestones:[], risks:[], meetings:[], history:[], createdBy:u.id, createdAt:now(), version:"1.0.0"};
  p.history.push({at:now(), by:u.id, from:null, to:"draft", note:"إنشاء"});
  S().projects.unshift(p);
  BOS.audit("إنشاء مشروع","project",p.id,p.no + " — " + p.name + (q?" من العرض " + q.no:""));
  if(p.pmId!==u.id) BOS.notify(p.pmId,"عُينت مديراً للمشروع " + p.no + " — " + p.name,"#/project/"+p.id,"task");
  BOS.save(); return p;
}
const projTasks = p => S().tasks.filter(t=>t.projectId===p.id);
const projCases = p => S().testCases.filter(t=>t.projectId===p.id);
const projBugs  = p => S().bugs.filter(b=>b.projectId===p.id);
const lastRun = tc => (tc.runs||[])[tc.runs.length-1];
function testStats(p){
  const cases = projCases(p);
  const runOnCurrent = cases.filter(tc=>{ const r = lastRun(tc); return r && r.version===p.version; });
  const passed = runOnCurrent.filter(tc=>lastRun(tc).result==="pass").length;
  const failed = runOnCurrent.filter(tc=>lastRun(tc).result==="fail").length;
  const blocked = runOnCurrent.filter(tc=>lastRun(tc).result==="blocked").length;
  const uat = cases.filter(tc=>tc.kind==="uat");
  const uatOk = uat.length>0 && uat.every(tc=>{ const r = lastRun(tc); return r && r.result==="pass" && r.version===p.version; });
  return {total:cases.length, run:runOnCurrent.length, passed, failed, blocked,
    rate: runOnCurrent.length ? Math.round(passed/runOnCurrent.length*100) : 0,
    coverage: cases.length ? Math.round(runOnCurrent.length/cases.length*100) : 0, uat:uat.length, uatOk};
}
const openBugs = (p, sev) => projBugs(p).filter(b=>!["closed","deferred"].includes(b.status) && (!sev || sev.includes(b.severity)));
/* تقييم البنود الآلية في بوابة الجودة */
function autoCheck(p, key){
  const ts = projTasks(p), st = testStats(p), pr = Number(S().settings.passRate||95);
  switch(key){
    case "tasks":    return {ok: ts.length>0 && ts.every(t=>t.status==="done"), note: ts.filter(t=>t.status==="done").length + "/" + ts.length + " مكتملة"};
    case "passRate": return {ok: st.run>0 && st.rate>=pr, note: st.rate + "% (الحد " + pr + "%)"};
    case "coverage": return {ok: st.total>0 && st.coverage===100, note: st.run + "/" + st.total + " على الإصدار " + p.version};
    case "bugs":     { const b = openBugs(p,["critical","high"]); return {ok: b.length===0, note: b.length + " مفتوح"}; }
    case "uat":      return {ok: st.uatOk, note: st.uat ? (st.uatOk?"ناجح":"غير مكتمل") : "لا توجد حالات قبول مستخدم"};
  }
  return {ok:false, note:""};
}
function latestGate(p){ return S().reviews.filter(r=>r.projectId===p.id && r.kind==="gate").sort((a,b)=>a.at<b.at?1:-1)[0]; }
function gatePassed(p){ const g = latestGate(p); return !!g && g.result==="pass" && g.version===p.version; }

/* شروط الانتقال بين مراحل المشروع — تعيد قائمة الموانع */
function blockers(p, to){
  const b = [];
  const ts = projTasks(p);
  switch(to){
    case "contracting": if(!p.customerId) b.push("اربط المشروع بعميل"); break;
    case "approved": {
      const cr = p.contractRequestId && S().requests.find(r=>r.id===p.contractRequestId);
      const q = p.quoteId && S().quotes.find(x=>x.id===p.quoteId);
      if(!(cr && cr.status==="closed") && !(q && ["accepted","invoiced"].includes(q.status)))
        b.push("لا يوجد عقد معتمد (طلب عقد مغلق) أو عرض سعر وافق عليه العميل");
      break; }
    case "planning": break;
    case "production":
      if(!p.milestones.length) b.push("أضف مرحلة تسليم (Milestone) واحدة على الأقل");
      if(!ts.length) b.push("قسّم العمل إلى مهام");
      if(ts.some(t=>!t.reviewerId || !t.criteria)) b.push("كل مهمة تحتاج مراجعاً ومعيار قبول");
      break;
    case "testing":
      if(ts.some(t=>t.status!=="done")) b.push("مهام غير مكتملة: " + ts.filter(t=>t.status!=="done").length);
      if(!projCases(p).length) b.push("لا توجد حالات اختبار");
      break;
    case "acceptance":
      if(!gatePassed(p)) b.push("بوابة الجودة غير مجتازة على الإصدار " + p.version + " (يسجلها مدير الجودة)");
      if(openBugs(p,["critical","high"]).length) b.push("عيوب حرجة/عالية مفتوحة: " + openBugs(p,["critical","high"]).length);
      break;
    case "launch": {
      if(!(p.delivery && p.delivery.accepted)) b.push("محضر التسليم وقبول العميل غير مسجل");
      const rel = p.releaseRequestId && S().requests.find(r=>r.id===p.releaseRequestId);
      if(!(rel && rel.status==="closed")) b.push("طلب إطلاق التطبيق لم يكتمل اعتماده");
      break; }
    case "support": break;
    case "closed":
      if(!p.postLaunch) b.push("اكتب تقرير ما بعد الإطلاق");
      if(S().tickets.some(t=>t.projectId===p.id && t.status!=="closed" && ["P1","P2"].includes(t.priority))) b.push("تذاكر دعم P1/P2 مفتوحة");
      if(p.milestones.some(m=>m.status!=="done")) b.push("مراحل تسليم غير مكتملة");
      break;
  }
  return b;
}
function moveProject(p, to, note){
  const u = me();
  if(!isPM(u,p) || !BOS.can(u,"projects","edit")) fail("تغيير مرحلة المشروع لمدير المشروع أو مدير العمليات أو المدير العام");
  const order = PROJECT_FLOW.map(x=>x[0]);
  const from = p.status, fi = order.indexOf(from), ti = order.indexOf(to);
  if(ti<0) fail("مرحلة غير معروفة");
  if(ti > fi+1) fail("لا يمكن تجاوز المراحل — الانتقال للمرحلة التالية فقط");
  if(ti <= fi && !note) fail("الرجوع لمرحلة سابقة يتطلب ذكر السبب");
  let override = false;
  if(ti === fi+1){
    const b = blockers(p, to);
    if(b.length){
      if(BOS.isTop(u) && note && to!=="acceptance") override = true; // بوابة الجودة لا يُتجاوز عنها (القسم 6.6)
      else fail("لا يمكن الانتقال إلى «" + PSTATUS[to] + "»: " + b.join(" · ") + (to==="acceptance"?"":" — يمكن للمدير العام اعتماد استثناء مع سبب"));
    }
  }
  p.status = to; p.updatedAt = now();
  if(to==="launch"){ p.launchedAt = now(); }
  if(to==="closed"){ p.closedAt = now(); }
  p.history.push({at:now(), by:u.id, from, to, note:note||"", override});
  BOS.audit(override ? "استثناء: نقل مشروع رغم الموانع" : "تغيير مرحلة مشروع","project",p.id,p.no + ": " + PSTATUS[from] + " ← " + PSTATUS[to] + (note?" — " + note:""));
  const watchers = new Set([p.pmId, ...(p.members||[])]);
  if(to==="testing"){ const tl = BOS.holderOf("testlead"); if(tl) watchers.add(tl.id); }
  if(to==="acceptance"||to==="testing"){ const qm = BOS.holderOf("qm"); if(qm) watchers.add(qm.id); }
  watchers.delete(u.id);
  watchers.forEach(id=>BOS.notify(id,"المشروع " + p.no + " انتقل إلى «" + PSTATUS[to] + "»","#/project/"+p.id));
  BOS.save();
}
function requestRelease(p){
  const u = me();
  if(!isPM(u,p) && !(p.members||[]).includes(u.id)) fail("طلب الإطلاق من فريق المشروع");
  if(p.releaseRequestId){ const r = S().requests.find(x=>x.id===p.releaseRequestId); if(r && !["rejected","cancelled"].includes(r.status)) fail("يوجد طلب إطلاق قائم: " + r.no); }
  const st = testStats(p);
  const r = BOS.createRequest("release", {project:p.name, version:p.version, strategic:p.strategic,
    notes:"نسبة النجاح " + st.rate + "% · عيوب مفتوحة " + openBugs(p).length + " · بوابة الجودة: " + (gatePassed(p)?"مجتازة":"غير مجتازة")},
    {title:"إطلاق " + p.name + " — " + p.version, link:{kind:"project", id:p.id}});
  p.releaseRequestId = r.id; BOS.save(); return r;
}
function requestChange(p, o){
  const r = BOS.createRequest("change", {project:p.name, change:o.change, days:Number(o.days||0), amount:Number(o.amount||0), clientRequested:!!o.clientRequested},
    {title:"تغيير نطاق — " + p.name, link:{kind:"project", id:p.id, change:true}});
  (p.changeRequests = p.changeRequests||[]).push(r.id); BOS.save(); return r;
}
function addMilestone(p, o){ if(!isPM(me(),p)) fail("لمدير المشروع"); if(!o.title) fail("العنوان إلزامي");
  const m = {id:BOS.uid("m"), title:o.title, due:o.due||"", status:"open", deliverable:o.deliverable||""}; p.milestones.push(m);
  BOS.audit("إضافة مرحلة تسليم","project",p.id,p.no + " — " + m.title); BOS.save(); return m; }
function toggleMilestone(p, m){ if(!isPM(me(),p)) fail("لمدير المشروع");
  const open = projTasks(p).filter(t=>t.milestoneId===m.id && t.status!=="done");
  if(m.status!=="done" && open.length) fail("مهام غير مكتملة في هذه المرحلة: " + open.length);
  m.status = m.status==="done" ? "open" : "done"; m.doneAt = m.status==="done" ? now() : null;
  m.onTime = m.status==="done" ? (!m.due || now().slice(0,10) <= m.due) : null;
  BOS.audit(m.status==="done"?"إنجاز مرحلة تسليم":"إعادة فتح مرحلة تسليم","project",p.id,p.no + " — " + m.title); BOS.save(); }
function addRisk(p, o){ if(!o.text) fail("وصف الخطر إلزامي");
  p.risks.push({id:BOS.uid("rk"), text:o.text, impact:o.impact||"متوسط", prob:o.prob||"متوسط", ownerId:o.ownerId||p.pmId, mitigation:o.mitigation||"", status:"open", at:now()});
  BOS.audit("تسجيل خطر","project",p.id,p.no + " — " + o.text); BOS.save(); }
function addMeeting(p, o){ if(!o.title) fail("عنوان الاجتماع إلزامي");
  const m = {id:BOS.uid("mt"), no:BOS.nextNo("MIN"), title:o.title, date:o.date||now().slice(0,10), attendees:o.attendees||"", notes:o.notes||"", decisions:o.decisions||"", by:me().id, at:now()};
  p.meetings.unshift(m); BOS.audit("محضر اجتماع","project",p.id,p.no + " — " + m.no); BOS.save(); return m; }
function recordDelivery(p, o){
  if(!isPM(me(),p)) fail("محضر التسليم يسجله مدير المشروع");
  if(p.status!=="acceptance") fail("محضر التسليم يسجل في مرحلة «قبول العميل» بعد اجتياز بوابة الجودة");
  if(!o.customerRep) fail("اسم ممثل العميل إلزامي");
  p.delivery = {no:BOS.nextNo("DLV"), date:o.date||now().slice(0,10), customerRep:o.customerRep, deliverables:o.deliverables||p.deliverables, notes:o.notes||"",
    accepted:!!o.accepted, reservations:o.reservations||"", by:me().id, at:now(), version:p.version};
  BOS.audit("محضر تسليم وقبول","project",p.id,p.no + " — " + p.delivery.no + " — " + (o.accepted?"قبول العميل":"قبول بتحفظات/رفض")); BOS.save();
}

/* ---------- المهام ---------- */
function createTask(p, o){
  const u = me();
  if(!canSeeProject(u,p) || !BOS.can(u,"projects","edit")) fail("لا تملك صلاحية إضافة مهام لهذا المشروع");
  if(["closed"].includes(p.status)) fail("المشروع مغلق");
  if(!o.title) fail("عنوان المهمة إلزامي");
  if(o.ownerId && o.reviewerId && o.ownerId===o.reviewerId) fail("المراجع يجب أن يكون غير المنفذ");
  const t = {id:BOS.uid("t"), no:BOS.nextNo("TSK"), projectId:p.id, milestoneId:o.milestoneId||"", title:o.title, desc:o.desc||"",
    ownerId:o.ownerId||u.id, reviewerId:o.reviewerId||"", criteria:o.criteria||"", priority:o.priority||"متوسطة", due:o.due||"", estimate:Number(o.estimate||0),
    status:"todo", hours:[], docId:o.docId||"", createdBy:u.id, createdAt:now(), log:[]};
  S().tasks.push(t);
  if(t.ownerId && !p.members.includes(t.ownerId) && t.ownerId!==p.pmId) p.members.push(t.ownerId);
  if(t.reviewerId && !p.members.includes(t.reviewerId) && t.reviewerId!==p.pmId) p.members.push(t.reviewerId);
  BOS.audit("إنشاء مهمة","task",t.id,t.no + " — " + t.title + " (" + p.no + ")");
  if(t.ownerId!==u.id) BOS.notify(t.ownerId,"مهمة جديدة: " + t.title + " — " + p.name,"#/project/"+p.id+"/tasks","task");
  BOS.save(); return t;
}
function moveTask(t, to, o){
  o = o || {};
  const u = me(); const p = project(t.projectId);
  const owner = t.ownerId===u.id, reviewer = t.reviewerId===u.id, pm = isPM(u,p);
  if(!TASK_STATUS[to]) fail("حالة غير معروفة");
  if(to==="done"){
    // لا تنتقل المهمة إلى مكتملة إلا بعد تحقق معيارها — بواسطة المراجع لا المنفذ
    if(t.status!=="review") fail("المهمة يجب أن تكون «بانتظار المراجعة» أولاً");
    if(!reviewer && !BOS.isTop(u)) fail("التحقق من معيار القبول للمراجع المعين فقط");
    if(u.id===t.ownerId) fail("لا يجوز للمنفذ التحقق من مهمته");
    if(!o.verified) fail("أكد تحقق معيار القبول: " + (t.criteria||"—"));
    t.verifiedBy = u.id; t.verifiedAt = now(); t.verifyNote = o.comment||"";
  } else if(to==="review"){
    if(!owner && !pm) fail("المنفذ يرسل مهمته للمراجعة");
    if(!t.reviewerId) fail("عيّن مراجعاً للمهمة أولاً");
    if(!t.criteria) fail("حدد معيار القبول أولاً");
    BOS.notify(t.reviewerId,"مهمة بانتظار مراجعتك: " + t.title,"#/project/"+p.id+"/tasks","task");
  } else if(to==="doing" && t.status==="review" && reviewer){
    if(!o.comment) fail("وضح سبب الإعادة للمنفذ");
    BOS.notify(t.ownerId,"أعيدت مهمتك للتعديل: " + t.title + " — " + o.comment,"#/project/"+p.id+"/tasks","warn");
    t.reworkCount = (t.reworkCount||0) + 1;
  } else if(!owner && !pm && !reviewer){ fail("تحديث حالة المهمة للمنفذ أو مدير المشروع"); }
  if(t.status==="done" && to!=="done" && !pm) fail("إعادة فتح مهمة مكتملة لمدير المشروع");
  const from = t.status; t.status = to; t.updatedAt = now();
  t.log.push({at:now(), by:u.id, from, to, note:o.comment||""});
  BOS.audit(to==="done"?"تحقق وإقفال مهمة":"تحديث حالة مهمة","task",t.id,t.no + ": " + TASK_STATUS[from] + " ← " + TASK_STATUS[to] + (o.comment?" — " + o.comment:""));
  BOS.save();
}
function logHours(t, h, note){ const n = Number(h); if(!(n>0 && n<=24)) fail("عدد ساعات غير صالح");
  t.hours.push({by:me().id, h:n, date:now().slice(0,10), note:note||""}); BOS.audit("تسجيل وقت","task",t.id,t.no + " — " + n + " ساعة"); BOS.save(); }

/* ---------- الاختبار (القسم 6.8) ---------- */
function createCase(p, o){
  const u = me();
  if(!BOS.can(u,"testing","create")) fail("لا تملك صلاحية إنشاء حالات اختبار");
  if(!o.title) fail("عنوان الحالة إلزامي");
  const tc = {id:BOS.uid("tc"), no:BOS.nextNo("TC"), projectId:p.id, taskId:o.taskId||"", requirement:o.requirement||"", title:o.title,
    steps:o.steps||"", expected:o.expected||"", kind:o.kind||"functional", runs:[], createdBy:u.id, createdAt:now()};
  S().testCases.push(tc); BOS.audit("إنشاء حالة اختبار","test",tc.id,tc.no + " — " + tc.title); BOS.save(); return tc;
}
function runCase(tc, o){
  const u = me(); const p = project(tc.projectId);
  if(!BOS.can(u,"testing","edit") && !BOS.can(u,"testing","create")) fail("لا تملك صلاحية تنفيذ الاختبار");
  if(!RESULT[o.result]) fail("اختر النتيجة");
  if(o.result!=="pass" && !o.notes) fail("سجل ما حدث عند الفشل أو الحجب");
  const run = {id:BOS.uid("run"), result:o.result, by:u.id, at:now(), platform:o.platform||"", device:o.device||"", version:o.version||p.version, notes:o.notes||"", evidence:o.evidence||""};
  tc.runs.push(run);
  BOS.audit("تنفيذ اختبار","test",tc.id,tc.no + " — " + RESULT[o.result] + " — إصدار " + run.version);
  let bug = null;
  // إعادة الاختبار بعد الإصلاح
  const waiting = S().bugs.filter(b=>b.testCaseId===tc.id && b.status==="fixed");
  if(o.result==="pass") waiting.forEach(b=>{ b.status="closed"; b.closedAt=now(); b.closedBy=u.id; b.log.push({at:now(),by:u.id,to:"closed",note:"نجحت إعادة الاختبار " + run.version});
    BOS.audit("إغلاق عيب بعد إعادة الاختبار","bug",b.id,b.no); if(b.assigneeId) BOS.notify(b.assigneeId,"أغلق العيب " + b.no + " بعد نجاح إعادة الاختبار","#/bug/"+b.id,"ok"); });
  if(o.result==="fail"){
    if(waiting.length) waiting.forEach(b=>{ b.status="reopened"; b.log.push({at:now(),by:u.id,to:"reopened",note:"فشلت إعادة الاختبار: " + o.notes}); b.reopenCount=(b.reopenCount||0)+1;
      BOS.audit("إعادة فتح عيب","bug",b.id,b.no); if(b.assigneeId) BOS.notify(b.assigneeId,"أعيد فتح العيب " + b.no + ": فشلت إعادة الاختبار","#/bug/"+b.id,"bad"); bug = b; });
    else bug = createBug(p, {title:"فشل: " + tc.title, severity:o.severity||"medium", testCaseId:tc.id, version:run.version, steps:tc.steps, actual:o.notes, expected:tc.expected, platform:o.platform, device:o.device}, true);
    const dl = BOS.holderOf("devlead"); if(dl) BOS.notify(dl.id,"فشل اختبار " + tc.no + " في " + p.name,"#/bug/"+bug.id,"bad");
  }
  BOS.save(); return {run, bug};
}
function createBug(p, o, auto){
  const u = me();
  if(!o.title) fail("عنوان العيب إلزامي");
  const b = {id:BOS.uid("b"), no:BOS.nextNo("BUG"), projectId:p.id, testCaseId:o.testCaseId||"", ticketId:o.ticketId||"", title:o.title, severity:o.severity||"medium",
    status:"open", version:o.version||p.version, steps:o.steps||"", expected:o.expected||"", actual:o.actual||"", platform:o.platform||"", device:o.device||"",
    reporterId:u.id, assigneeId:o.assigneeId||"", createdAt:now(), postLaunch: ["launch","support","closed"].includes(p.status), log:[{at:now(),by:u.id,to:"open",note:auto?"أنشئ تلقائياً عند فشل الاختبار":"تسجيل"}]};
  if(!b.assigneeId){ const dl = BOS.holderOf("devlead"); b.assigneeId = dl ? dl.id : p.pmId; }
  S().bugs.unshift(b);
  BOS.audit(auto?"إنشاء عيب تلقائياً":"تسجيل عيب","bug",b.id,b.no + " — " + SEVERITY[b.severity] + " — " + b.title);
  BOS.notify(b.assigneeId,"عيب جديد (" + SEVERITY[b.severity] + "): " + b.title,"#/bug/"+b.id,"bad");
  BOS.save(); return b;
}
function moveBug(b, to, o){
  o = o || {}; const u = me(); const p = project(b.projectId);
  if(!BUG_STATUS[to]) fail("حالة غير معروفة");
  if(to==="closed"){
    // الإغلاق يمر بإعادة الاختبار؛ الإغلاق اليدوي للاختبار فقط مع سبب
    if(!BOS.can(u,"testing","approve") && !BOS.isTop(u)) fail("إغلاق العيب يتم بإعادة الاختبار، أو يدوياً بواسطة رئيس الاختبار");
    if(!o.comment) fail("سبب الإغلاق اليدوي إلزامي");
  }
  if(to==="deferred"){ if(!isPM(u,p) && !BOS.can(u,"quality","approve")) fail("التأجيل بقرار مدير المشروع أو الجودة"); if(!o.comment) fail("سبب التأجيل إلزامي");
    if(["critical"].includes(b.severity) && !BOS.isTop(u)) fail("تأجيل عيب حرج يتطلب المدير العام"); }
  if(to==="fixed"){ if(u.id!==b.assigneeId && !isPM(u,p)) fail("المسند إليه يعلن الإصلاح"); b.fixedAt = now(); b.fixedBy = u.id;
    const tl = BOS.holderOf("testlead"); if(tl) BOS.notify(tl.id,"عيب جاهز لإعادة الاختبار: " + b.no,"#/bug/"+b.id,"task"); }
  const from = b.status; b.status = to; if(to==="closed"){ b.closedAt = now(); b.closedBy = u.id; }
  if(o.assigneeId) b.assigneeId = o.assigneeId;
  b.log.push({at:now(), by:u.id, from, to, note:o.comment||""});
  BOS.audit("تحديث عيب","bug",b.id,b.no + ": " + BUG_STATUS[from] + " ← " + BUG_STATUS[to] + (o.comment?" — " + o.comment:""));
  BOS.save();
}

/* ---------- الجودة (القسم 6.6) ---------- */
function createReview(p, kind, items, o){
  const u = me();
  if(!BOS.can(u,"quality","create") && !BOS.can(u,"quality","approve")) fail("المراجعة من صلاحيات قسم الجودة");
  if(kind==="gate" && !BOS.can(u,"quality","approve")) fail("بوابة الجودة يسجلها مدير الجودة");
  if(p.pmId===u.id || projTasks(p).some(t=>t.ownerId===u.id)) fail("استقلال الجودة: لا يراجع عضو فريق الإنتاج عمله");
  const list = CHECKLISTS[kind].items.map((it,i)=>{
    if(it.auto){ const a = autoCheck(p,it.auto); return {t:it.t, ok:a.ok, note:a.note, auto:true}; }
    return {t:it.t, ok:!!(items[i]&&items[i].ok), note:(items[i]&&items[i].note)||""};
  });
  const pass = list.every(x=>x.ok);
  const r = {id:BOS.uid("qr"), no:BOS.nextNo("QR"), projectId:p.id, kind, target:o.target||"", items:list, result:pass?"pass":"fail",
    reviewerId:u.id, at:now(), notes:o.notes||"", version:p.version};
  S().reviews.unshift(r);
  BOS.audit(kind==="gate"?"بوابة الجودة":"مراجعة جودة","quality",r.id,r.no + " — " + CHECKLISTS[kind].name + " — " + (pass?"مطابق":"غير مطابق") + " — " + p.no);
  BOS.notify(p.pmId,(pass?"✓ ":"✕ ") + CHECKLISTS[kind].name + " — " + p.name + ": " + (pass?"مطابق":"غير مطابق"),"#/project/"+p.id+"/quality",pass?"ok":"bad");
  if(!pass && o.ncr){ createNcr({projectId:p.id, source:"مراجعة " + r.no, description:list.filter(x=>!x.ok).map(x=>x.t).join("؛ "), reviewId:r.id}); }
  BOS.save(); return r;
}
function createNcr(o){
  const u = me();
  if(!o.description) fail("وصف عدم المطابقة إلزامي");
  const n = {id:BOS.uid("ncr"), no:BOS.nextNo("NCR"), projectId:o.projectId||"", ticketId:o.ticketId||"", reviewId:o.reviewId||"", source:o.source||"",
    description:o.description, rootCause:"", correction:"", preventive:"", ownerId:o.ownerId || (o.projectId ? project(o.projectId).pmId : u.id),
    due:o.due || new Date(Date.now()+14*864e5).toISOString().slice(0,10), status:"open", createdBy:u.id, createdAt:now(), log:[]};
  S().ncrs.unshift(n);
  BOS.audit("تقرير عدم مطابقة","quality",n.id,n.no + " — " + n.description.slice(0,80));
  BOS.notify(n.ownerId,"تقرير عدم مطابقة مسند إليك: " + n.no,"#/ncr/"+n.id,"bad");
  BOS.save(); return n;
}
function moveNcr(n, to, o){
  o = o || {}; const u = me();
  const order = ["open","investigating","action","verify","closed"];
  if(order.indexOf(to) !== order.indexOf(n.status)+1) fail("الانتقال للمرحلة التالية فقط");
  if(to==="action" && !o.rootCause && !n.rootCause) fail("سجل السبب الجذري أولاً");
  if(to==="verify" && !(o.correction||n.correction) ) fail("سجل الإجراء التصحيحي");
  if(to==="verify" && !(o.preventive||n.preventive)) fail("سجل الإجراء الوقائي");
  if(to==="closed"){ if(!BOS.can(u,"quality","approve") && !BOS.isTop(u)) fail("التحقق من الفعالية لمدير الجودة"); if(u.id===n.ownerId) fail("لا يتحقق مالك الإجراء من فعاليته بنفسه"); if(!o.comment) fail("سجل نتيجة التحقق"); n.verifiedBy = u.id; n.closedAt = now(); }
  else if(u.id!==n.ownerId && !BOS.can(u,"quality","approve") && !BOS.isTop(u)) fail("لمالك الإجراء أو الجودة");
  ["rootCause","correction","preventive"].forEach(k=>{ if(o[k]) n[k] = o[k]; });
  const from = n.status; n.status = to; n.log.push({at:now(), by:u.id, from, to, note:o.comment||""});
  BOS.audit("تحديث إجراء تصحيحي","quality",n.id,n.no + ": " + NCR_STATUS[from] + " ← " + NCR_STATUS[to]);
  if(to==="verify"){ const qm = BOS.holderOf("qm"); if(qm) BOS.notify(qm.id,"إجراء تصحيحي بانتظار التحقق: " + n.no,"#/ncr/"+n.id,"task"); }
  BOS.save();
}

/* ---------- الدعم الفني وخدمة العملاء (6.7 و6.12) ---------- */
function slaFor(pr){ const s = (S().settings.sla||{})[pr] || [8,72]; return {resp:s[0], res:s[1]}; }
function createTicket(o){
  const u = me();
  if(!BOS.can(u,"support","create")) fail("لا تملك صلاحية فتح تذكرة");
  if(!o.customerId) fail("اختر العميل"); if(!o.subject) fail("الموضوع إلزامي");
  const pr = o.priority || "P3"; const sla = slaFor(pr);
  const t = {id:BOS.uid("tk"), no:BOS.nextNo("TKT"), customerId:o.customerId, projectId:o.projectId||"", version:o.version||"", type:o.type||"استفسار",
    channel:o.channel||"هاتف", subject:o.subject, details:o.details||"", priority:pr, impact:o.impact||"", status:"new",
    ownerId:o.ownerId || ((BOS.holderOf("cs")||{}).id) || u.id, createdBy:u.id, createdAt:now(),
    respondBy:new Date(Date.now()+hours(sla.resp)).toISOString(), resolveBy:new Date(Date.now()+hours(sla.res)).toISOString(),
    firstResponseAt:null, resolvedAt:null, closedAt:null, closeBasis:"", csat:null, rootCause:"", kbId:"", messages:[], log:[], contacts:0};
  t.log.push({at:now(), by:u.id, to:"new", note:"استقبال عبر " + t.channel});
  S().tickets.unshift(t);
  BOS.audit("فتح تذكرة","ticket",t.id,t.no + " — " + t.type + " — " + t.priority);
  if(t.ownerId!==u.id) BOS.notify(t.ownerId,"تذكرة جديدة " + t.priority + ": " + t.subject,"#/ticket/"+t.id,"task");
  BOS.save(); return t;
}
function ticketReply(t, text, internal){
  const u = me(); if(!text) fail("اكتب الرد");
  t.messages.push({at:now(), by:u.id, text, internal:!!internal});
  if(!internal){ t.contacts = (t.contacts||0)+1; if(!t.firstResponseAt){ t.firstResponseAt = now(); } }
  BOS.audit(internal?"ملاحظة داخلية على تذكرة":"رد على العميل","ticket",t.id,t.no); BOS.save();
}
function moveTicket(t, to, o){
  o = o || {}; const u = me();
  const canWork = BOS.can(u,"support","edit") || t.ownerId===u.id;
  if(!canWork) fail("لا تملك صلاحية معالجة التذكرة");
  if(!TSTATUS[to]) fail("حالة غير معروفة");
  if(t.status==="closed") fail("التذكرة مغلقة — افتح تذكرة جديدة مرتبطة بها عند الحاجة");
  if(to==="referred"){
    if(!o.referTo) fail("حدد جهة الإحالة");
    const target = BOS.byId(o.referTo); if(!target) fail("اختر موظفاً");
    t.referredTo = target.id; BOS.notify(target.id,"أحيلت إليك تذكرة " + t.no + ": " + t.subject,"#/ticket/"+t.id,"task");
  }
  if(to==="proposed"){ if(!o.comment) fail("اكتب الحل المقترح"); t.solution = o.comment; t.resolvedAt = t.resolvedAt || now(); }
  if(to==="closed"){
    // لا تغلق التذكرة بمجرد إرسال رد (القسم 6.7)
    if(!CLOSE_BASIS[o.basis]) fail("حدد أساس الإغلاق: تأكيد العميل أو نتيجة موثقة أو قرار تصعيد معتمد");
    if(!t.solution && o.basis!=="escalation") fail("سجل الحل المقترح أولاً");
    if(o.basis!=="confirmed" && !o.comment) fail("وثّق النتيجة أو قرار التصعيد");
    if(o.basis==="escalation" && !BOS.can(u,"quality","approve") && !BOS.isTop(u)) fail("قرار التصعيد يعتمده مدير الجودة");
    if(!o.rootCause) fail("حدد السبب الجذري لتحليل الجودة");
    t.closeBasis = o.basis; t.closedAt = now(); t.rootCause = o.rootCause; t.closeNote = o.comment||"";
    if(!t.firstResponseAt) t.firstResponseAt = now();
    if(!t.resolvedAt) t.resolvedAt = now();
    t.fcr = (t.contacts||0) <= 1;
  }
  if(to!=="new" && !t.firstResponseAt && ["verified","classified","handling"].includes(to)) t.firstResponseAt = now();
  if(o.priority && o.priority!==t.priority){ const sla = slaFor(o.priority); t.priority = o.priority; t.resolveBy = new Date(new Date(t.createdAt).getTime()+hours(sla.res)).toISOString(); t.respondBy = new Date(new Date(t.createdAt).getTime()+hours(sla.resp)).toISOString(); }
  const from = t.status; t.status = to; t.updatedAt = now();
  t.log.push({at:now(), by:u.id, from, to, note:o.comment||""});
  BOS.audit("تحديث تذكرة","ticket",t.id,t.no + ": " + TSTATUS[from] + " ← " + TSTATUS[to] + (o.basis?" — " + CLOSE_BASIS[o.basis]:""));
  if(to==="closed"){ const qm = BOS.holderOf("qm"); if(qm && t.priority==="P1") BOS.notify(qm.id,"أغلقت تذكرة P1 " + t.no + " — للتحليل","#/ticket/"+t.id); }
  BOS.save();
}
function recordCsat(t, score, comment){
  if(t.status!=="closed") fail("قياس الرضا بعد الإغلاق");
  const n = Number(score); if(!(n>=1 && n<=5)) fail("التقييم من 1 إلى 5");
  t.csat = n; t.csatComment = comment||""; t.csatAt = now();
  BOS.audit("قياس رضا العميل","ticket",t.id,t.no + " — " + n + "/5");
  if(n<=2){ const qm = BOS.holderOf("qm"); if(qm) BOS.notify(qm.id,"رضا منخفض (" + n + "/5) على " + t.no,"#/ticket/"+t.id,"bad"); }
  BOS.save();
}
function ticketToBug(t, sev){
  const p = t.projectId && project(t.projectId); if(!p) fail("اربط التذكرة بمشروع أولاً");
  const b = createBug(p,{title:"من الدعم: " + t.subject, severity:sev||"high", ticketId:t.id, version:t.version||p.version, actual:t.details});
  t.bugId = b.id; t.log.push({at:now(), by:me().id, note:"أنشئ عيب " + b.no}); BOS.save(); return b;
}
function ticketToComplaint(t){
  const c = S().customers.find(x=>x.id===t.customerId)||{};
  const r = BOS.createRequest("complaint",{customer:c.name||"", project:(project(t.projectId)||{}).name||"", details:t.subject + " — " + t.details, sensitive:t.priority==="P1"},
    {title:"شكوى عالية الخطورة — " + (c.name||"") + " (" + t.no + ")", link:{kind:"ticket", id:t.id}});
  t.complaintRequestId = r.id; BOS.save(); return r;
}
function slaState(t){
  const n = Date.now();
  const respLate = t.firstResponseAt ? new Date(t.firstResponseAt) > new Date(t.respondBy) : n > new Date(t.respondBy);
  const end = t.resolvedAt || t.closedAt;
  const resLate = end ? new Date(end) > new Date(t.resolveBy) : n > new Date(t.resolveBy);
  return {respLate, resLate, breached: respLate || resLate};
}
/* تنبيه وتصعيد التذاكر التي تجاوزت زمن الاستجابة */
function slaSweep(){
  let n = 0;
  for(const t of S().tickets){
    if(t.status==="closed" || t.slaNotified) continue;
    const s = slaState(t);
    if(s.breached){
      t.slaNotified = true; n++;
      const qm = BOS.holderOf("qm"); if(qm) BOS.notify(qm.id,"تذكرة تجاوزت اتفاقية مستوى الخدمة: " + t.no + " (" + t.priority + ")","#/ticket/"+t.id,"bad");
      BOS.notify(t.ownerId,"تجاوزت التذكرة " + t.no + " زمن " + (s.respLate?"الاستجابة":"الحل"),"#/ticket/"+t.id,"bad");
      BOS.audit("تجاوز اتفاقية مستوى الخدمة","ticket",t.id,t.no,null);
    }
  }
  if(n) BOS.save();
  return n;
}
function createKb(o){
  const u = me(); if(!o.title||!o.body) fail("العنوان والمحتوى إلزاميان");
  const a = {id:BOS.uid("kb"), no:BOS.nextNo("KB"), title:o.title, body:o.body, tags:o.tags||"", status:"draft", by:u.id, at:now(), views:0};
  S().kb.unshift(a); BOS.audit("مقال معرفة","kb",a.id,a.no + " — " + a.title); BOS.save(); return a;
}
function approveKb(a){
  const u = me(); if(!BOS.can(u,"quality","approve") && !BOS.isTop(u)) fail("اعتماد قاعدة المعرفة لمدير الجودة");
  if(a.by===u.id) fail("لا يعتمد الكاتب مقاله");
  a.status = "approved"; a.approvedBy = u.id; a.approvedAt = now(); BOS.audit("اعتماد مقال معرفة","kb",a.id,a.no); BOS.save();
}

/* ---------- ربط محرك الموافقات ---------- */
function onClosed(r){
  if(!r.link) return;
  if(r.link.kind==="project"){
    const p = project(r.link.id); if(!p) return;
    if(r.type==="release"){ p.releaseApproved = true; BOS.audit("اعتماد إطلاق مشروع","project",p.id,p.no + " — " + r.no); BOS.notify(p.pmId,"اعتُمد إطلاق " + p.name,"#/project/"+p.id,"ok"); }
    if(r.type==="change"){ p.scope = (p.scope?p.scope+"\n\n":"") + "تغيير معتمد (" + r.no + "): " + r.data.change;
      if(r.data.amount) p.budget = Number(p.budget||0) + Number(r.data.amount);
      if(r.data.days && p.end){ p.end = new Date(new Date(p.end).getTime() + Number(r.data.days)*864e5).toISOString().slice(0,10); }
      BOS.audit("تطبيق تغيير نطاق","project",p.id,p.no + " — " + r.no); }
  }
  if(r.link.kind==="ticket"){ const t = S().tickets.find(x=>x.id===r.link.id); if(t) t.log.push({at:now(), note:"اكتمل مسار الشكوى " + r.no}); }
}
function onAborted(r){ /* لا شيء: الرفض يبقى ظاهراً على المشروع عبر حالة الطلب */ }

/* ---------- مؤشرات (القسم 11) ---------- */
function metrics(){
  const s = S();
  const ms = s.projects.flatMap(p=>p.milestones.filter(m=>m.status==="done"));
  const onTime = ms.length ? Math.round(ms.filter(m=>m.onTime).length/ms.length*100) : null;
  const runs = s.testCases.map(lastRun).filter(Boolean);
  const passRate = runs.length ? Math.round(runs.filter(r=>r.result==="pass").length/runs.length*100) : null;
  const closedBugs = s.bugs.filter(b=>b.closedAt);
  const mttr = closedBugs.length ? closedBugs.reduce((a,b)=>a+(new Date(b.closedAt)-new Date(b.createdAt)),0)/closedBugs.length/36e5 : null;
  const postLaunch = s.bugs.filter(b=>b.postLaunch).length;
  const tk = s.tickets.filter(t=>t.status==="closed");
  const csatL = tk.filter(t=>t.csat);
  const csat = csatL.length ? csatL.reduce((a,t)=>a+t.csat,0)/csatL.length : null;
  const sla = tk.length ? Math.round(tk.filter(t=>!slaState(t).breached).length/tk.length*100) : null;
  const fr = s.tickets.filter(t=>t.firstResponseAt);
  const frt = fr.length ? fr.reduce((a,t)=>a+(new Date(t.firstResponseAt)-new Date(t.createdAt)),0)/fr.length/36e5 : null;
  const res = tk.filter(t=>t.resolvedAt);
  const ttr = res.length ? res.reduce((a,t)=>a+(new Date(t.resolvedAt)-new Date(t.createdAt)),0)/res.length/36e5 : null;
  const fcr = tk.length ? Math.round(tk.filter(t=>t.fcr).length/tk.length*100) : null;
  const gates = s.reviews.filter(r=>r.kind==="gate");
  const gateRate = gates.length ? Math.round(gates.filter(g=>g.result==="pass").length/gates.length*100) : null;
  const rework = s.tasks.reduce((a,t)=>a+(t.reworkCount||0),0);
  const bySev = Object.fromEntries(Object.keys(SEVERITY).map(k=>[k, s.bugs.filter(b=>b.severity===k && !["closed","deferred"].includes(b.status)).length]));
  const causes = {}; tk.forEach(t=>{ if(t.rootCause) causes[t.rootCause] = (causes[t.rootCause]||0)+1; });
  const repeated = Object.entries(causes).filter(([k,v])=>v>=2).sort((a,b)=>b[1]-a[1]);
  const reopened = s.bugs.filter(b=>(b.reopenCount||0)>0).length;
  return {onTime, passRate, mttr, postLaunch, csat, sla, frt, ttr, fcr, gateRate, rework, bySev, causes, repeated, reopened,
    openNcr: s.ncrs.filter(n=>n.status!=="closed").length, capaFromVoc: s.ncrs.filter(n=>n.ticketId).length,
    openTickets: s.tickets.filter(t=>t.status!=="closed").length, breached: s.tickets.filter(t=>t.status!=="closed" && slaState(t).breached).length,
    activeProjects: s.projects.filter(p=>!["closed","draft"].includes(p.status)).length,
    lateProjects: s.projects.filter(p=>p.end && p.end < now().slice(0,10) && !["closed","launch","support"].includes(p.status)).length,
    highRisk: s.projects.filter(p=>p.risks.some(r=>r.status==="open" && r.impact==="عالي")).length};
}

/* ---------- بيانات تجريبية للمرحلة الثالثة ---------- */
function seedOps(){
  const s = S();
  const k = key => s.employees.find(e=>BOS.active(e) && posKey(e)===key);
  const pm = k("pm"), dev = k("dev"), des = k("designer"), dl = k("devlead"), tl = k("testlead"), cs = k("cs"), qm = k("qm");
  if(!pm || !dev || !dl || !tl) fail("يتطلب الفريق التجريبي");
  const saved = s.session.userId;
  const as = e => { s.session.userId = e.id; };
  const cust = s.customers[0] || (s.customers.push({id:BOS.uid("c"), name:"عميل تجريبي", kind:"قطاع خاص", contact:"", stage:"عميل", publishConsent:false, createdAt:now()}), s.customers[0]);
  try{
    // عرض سعر وافق عليه العميل — أساس اعتماد المشروع
    const sales = k("sales") || pm; as(sales);
    const q = {id:BOS.uid("q"), no:BOS.nextNo("QT"), customerId:cust.id, currency:s.settings.currency, due:new Date(Date.now()+30*864e5).toISOString().slice(0,10), ref:"",
      items:[{desc:"تطبيق جوال (أندرويد وiOS)", qty:1, price:1600000},{desc:"بوابة الإدارة والتكامل", qty:1, price:800000}], discount:0, taxRate:0, terms:"دفعة مقدمة 30% عند التعاقد",
      status:"accepted", acceptedAt:now(), createdBy:sales.id, createdAt:now(), payments:[]};
    s.quotes.unshift(q); BOS.audit("إنشاء عرض سعر","quote",q.id,q.no); BOS.audit("موافقة العميل على عرض","quote",q.id,q.no);
    as(pm);
    const p = createProject({name:"تطبيق مواعيد المستشفيات", customerId:cust.id, quoteId:q.id, contractRef:"اتفاقية تطوير تطبيق (من حزمة الشركة)",
      scope:"تطبيق جوال وبوابة ويب لحجز المواعيد وتذكير المرضى وربطها بنظام المستشفى.", deliverables:"تطبيق أندرويد وiOS، بوابة إدارة، دليل استخدام، تدريب الموظفين",
      end:new Date(Date.now()+60*864e5).toISOString().slice(0,10), members:[dev.id, des&&des.id, dl.id].filter(Boolean)});
    moveProject(p,"contracting"); moveProject(p,"approved"); moveProject(p,"planning");
    const m1 = addMilestone(p,{title:"النموذج الأولي والتصميم", due:new Date(Date.now()+14*864e5).toISOString().slice(0,10)});
    const m2 = addMilestone(p,{title:"الإصدار التجريبي للمستشفى", due:new Date(Date.now()+45*864e5).toISOString().slice(0,10)});
    const t1 = createTask(p,{title:"تصميم واجهات الحجز", ownerId:(des||dev).id, reviewerId:dl.id, criteria:"معتمدة من العميل وتعمل RTL على الهاتف", milestoneId:m1.id, estimate:24});
    const t2 = createTask(p,{title:"واجهة برمجية لحجز المواعيد", ownerId:dev.id, reviewerId:dl.id, criteria:"اختبارات الوحدة ناجحة وزمن الاستجابة أقل من ثانية", milestoneId:m2.id, estimate:40});
    createTask(p,{title:"إشعارات التذكير بالرسائل", ownerId:dev.id, reviewerId:dl.id, criteria:"تصل الرسالة قبل الموعد بـ 24 ساعة", milestoneId:m2.id, estimate:16});
    addRisk(p,{text:"تأخر الربط مع نظام المستشفى الحالي", impact:"عالي", prob:"متوسط", mitigation:"واجهة وسيطة واختبار مبكر"});
    as(tl);
    const c1 = createCase(p,{title:"حجز موعد جديد", taskId:t2.id, steps:"1. اختر العيادة\n2. اختر الموعد\n3. أكد الحجز", expected:"يظهر رقم الحجز ويصل إشعار"});
    createCase(p,{title:"إلغاء موعد", taskId:t2.id, steps:"افتح الحجز ← إلغاء", expected:"يعود الموعد متاحاً"});
    createCase(p,{title:"قبول المستخدم: تجربة موظف الاستقبال", kind:"uat", steps:"سيناريو يوم عمل كامل", expected:"إنجاز 10 حجوزات دون مساعدة"});
    runCase(c1,{result:"fail", notes:"الموعد يظهر بتوقيت خاطئ (UTC)", platform:"Android 14", device:"Samsung A54", severity:"high"});
    as(cs || pm);
    const tk = createTicket({customerId:cust.id, projectId:p.id, type:"استفسار", channel:"بريد", subject:"موعد تسليم النموذج الأولي", details:"يستفسر العميل عن موعد عرض النموذج الأولي", priority:"P3"});
    ticketReply(tk,"النموذج الأولي مجدول للعرض خلال أسبوعين، وسنرسل دعوة الاجتماع.");
    moveTicket(tk,"classified",{}); moveTicket(tk,"proposed",{comment:"تحديد موعد العرض وإرسال الدعوة"});
    createKb({title:"كيف أتابع حالة طلب الدعم؟", body:"كل تذكرة تحمل رقماً يبدأ بـ TKT. تصلك رسالة عند كل تغيير في حالتها، ولا تُغلق إلا بعد تأكيدك أو توثيق النتيجة.", tags:"دعم، تذاكر"});
    BOS.audit("إضافة بيانات تجريبية للمرحلة الثالثة","project",p.id,p.no);
    return p;
  } finally { s.session.userId = saved; BOS.save(); }
}

window.BOS_OPS = {PROJECT_FLOW, PSTATUS, TASK_STATUS, BUG_STATUS, SEVERITY, RESULT, NCR_STATUS, TICKET_FLOW, TSTATUS, TICKET_TYPES, PRIORITY, CLOSE_BASIS, ROOT_CAUSES, CHECKLISTS,
  canSeeProject, project, isPM, createProject, projTasks, projCases, projBugs, lastRun, testStats, openBugs, autoCheck, latestGate, gatePassed, blockers, moveProject,
  requestRelease, requestChange, addMilestone, toggleMilestone, addRisk, addMeeting, recordDelivery,
  createTask, moveTask, logHours, createCase, runCase, createBug, moveBug, createReview, createNcr, moveNcr,
  slaFor, createTicket, ticketReply, moveTicket, recordCsat, ticketToBug, ticketToComplaint, slaState, slaSweep, createKb, approveKb,
  onClosed, onAborted, metrics, seedOps};
})();
