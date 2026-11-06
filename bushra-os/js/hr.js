/* نظام البشرى لإدارة الشركة — المرحلة الرابعة: الموارد البشرية والتدريب والعلاقات
   (الأقسام 6.2 و6.3 و6.4) */
(function(){
"use strict";
const D = window.BOS_DATA;
const S = () => BOS.S;
const me = () => BOS.me();
const now = () => BOS.now();
const today = () => now().slice(0,10);
const fail = m => { throw new Error(m); };
const posKey = e => e ? (BOS.pos(e.positionId)||{}).key : null;
const holder = k => { const h = BOS.holderOf(k); return h ? BOS.byId(h.id) : null; };

/* ---------- مراجع ---------- */
const ATT = {present:"حاضر", late:"متأخر", absent:"غائب", leave:"إجازة", remote:"عن بعد", mission:"مهمة عمل"};
const EVAL_CRITERIA = ["جودة العمل","الالتزام بالمواعيد","التعاون والعمل الجماعي","المبادرة وحل المشكلات","الالتزام بالسياسات والأمن"];
const EVAL_STATUS = {draft:"مسودة", submitted:"بانتظار اطلاع الموظف", acknowledged:"اطلع الموظف", approved:"معتمد من الموارد البشرية"};
const ASSET_STATUS = {stock:"في المخزن", issued:"عهدة لدى موظف", returned:"مُرجع", lost:"مفقود", damaged:"تالف"};
const NOTE_KINDS = {note:"ملاحظة سرية", commendation:"شكر وتقدير", warning:"لفت نظر / إنذار", sanction:"جزاء"};
/* حالات خطة التدريب (القسم 6.4) */
const PROGRAM_FLOW = [["draft","مسودة"],["proposed","مقترحة"],["approved","معتمدة"],["scheduled","مجدولة"],["running","جارية"],["evaluation","تقييم"],["completed","مكتملة"],["archived","مؤرشفة"]];
const PSTAT = Object.fromEntries(PROGRAM_FLOW);
const LEVELS = {0:"لا يوجد", 1:"مبتدئ", 2:"متوسط", 3:"متقدم", 4:"خبير"};
const CONTENT_FLOW = [["draft","مسودة"],["review","قيد الاعتماد"],["approved","معتمد"],["scheduled","مجدول"],["published","منشور"]];
const CSTAT = Object.fromEntries(CONTENT_FLOW);
const INTERACTION_KINDS = ["اجتماع","مكالمة","بريد","زيارة","عرض تقديمي","مراسلة رسمية"];

const DEFAULT_SKILLS = [
  ["تطوير تطبيقات الجوال","تقني"],["تطوير الويب","تقني"],["الذكاء الاصطناعي وتعلم الآلة","تقني"],["الحوسبة السحابية","تقني"],
  ["تصميم واجهات وتجربة المستخدم","تصميم"],["اختبار البرمجيات","جودة"],["نظم إدارة الجودة","جودة"],["أمن المعلومات","أمن"],
  ["إدارة المشاريع","إدارة"],["خدمة العملاء","علاقات"],["التواصل والعرض","علاقات"],["المحاسبة والمالية","مالية"],["سياسات الشركة والخصوصية","عام"]
];
/* المهارات المطلوبة لكل منصب ومستواها (مصفوفة المهارات) */
const DEFAULT_REQ = {
  dev:{"تطوير تطبيقات الجوال":3,"تطوير الويب":3,"اختبار البرمجيات":2,"أمن المعلومات":2,"سياسات الشركة والخصوصية":2},
  devlead:{"تطوير تطبيقات الجوال":4,"تطوير الويب":3,"الحوسبة السحابية":3,"إدارة المشاريع":2,"أمن المعلومات":3,"سياسات الشركة والخصوصية":2},
  designer:{"تصميم واجهات وتجربة المستخدم":4,"التواصل والعرض":2,"سياسات الشركة والخصوصية":2},
  testlead:{"اختبار البرمجيات":4,"نظم إدارة الجودة":3,"أمن المعلومات":2,"سياسات الشركة والخصوصية":2},
  qm:{"نظم إدارة الجودة":4,"اختبار البرمجيات":2,"خدمة العملاء":3,"سياسات الشركة والخصوصية":3},
  cs:{"خدمة العملاء":4,"التواصل والعرض":3,"سياسات الشركة والخصوصية":3},
  pm:{"إدارة المشاريع":4,"التواصل والعرض":3,"نظم إدارة الجودة":2,"سياسات الشركة والخصوصية":2},
  secops:{"أمن المعلومات":4,"الحوسبة السحابية":3,"سياسات الشركة والخصوصية":4},
  cto:{"الحوسبة السحابية":3,"أمن المعلومات":3,"إدارة المشاريع":3,"الذكاء الاصطناعي وتعلم الآلة":3},
  accountant:{"المحاسبة والمالية":4,"سياسات الشركة والخصوصية":2},
  sales:{"التواصل والعرض":4,"خدمة العملاء":3},
  pr:{"التواصل والعرض":4,"سياسات الشركة والخصوصية":2},
  staff:{"سياسات الشركة والخصوصية":2}
};
const ONBOARDING = [
  [30,"استلام الأجهزة والحسابات وتسجيل العهدة"],[30,"التعريف بدليل الموظف والسياسات الأساسية"],[30,"توقيع اتفاقية عدم الإفصاح وسياسة أمن المعلومات"],[30,"التعرف على الفريق والمدير المباشر"],
  [60,"تدريب المنصب الأساسي حسب مصفوفة المهارات"],[60,"إنجاز أول مهمة مستقلة بمعيار قبول"],
  [90,"تقييم نهاية فترة التجربة"],[90,"تحديث مصفوفة مهارات الموظف وخطة التطوير"]
];

/* ---------- الرؤية: البيانات الحساسة للموظفين (القسم 6.2) ---------- */
const isHR = u => !!u && (BOS.isTop(u) || posKey(u)==="hr" || BOS.can(u,"people","manage"));
const isManagerOf = (u, e) => !!u && !!e && (e.managerId===u.id || (BOS.managerOf(e)||{}).id===u.id);
/* القسم المطلوب: contract (العقد والأجر)، performance (الأهداف والتقييم)، notes (الملاحظات السرية والجزاءات)،
   attendance، assets، training */
function canSee(u, e, section){
  if(!u || !e) return false;
  if(isHR(u)) return true;
  const self = u.id===e.id, mgr = isManagerOf(u,e);
  switch(section){
    case "notes":       return false;
    case "contract":    return self;
    case "performance": return self || mgr;
    case "attendance":  return self || mgr;
    case "assets":      return self || mgr || ["accountant","procurement"].includes(posKey(u));
    case "training":    return self || mgr || posKey(u)==="training" || BOS.can(u,"training","approve");
  }
  return false;
}

/* ---------- الحضور ---------- */
const work = () => S().settings.work || {start:"08:00", end:"16:00", grace:15, weekend:[5,6]};
const minutes = hm => { const [h,m] = String(hm||"0:0").split(":").map(Number); return h*60+(m||0); };
const nowHM = () => { const d = new Date(); return String(d.getHours()).padStart(2,"0") + ":" + String(d.getMinutes()).padStart(2,"0"); };
const attOf = (empId, date) => S().attendance.find(a=>a.empId===empId && a.date===date);
function checkIn(o){
  const u = me(); o = o || {};
  const d = o.date || today();
  if(attOf(u.id,d) && attOf(u.id,d).in) fail("سجلت حضورك اليوم عند " + attOf(u.id,d).in);
  const t = o.time || nowHM(); const w = work();
  const late = minutes(t) > minutes(w.start) + Number(w.grace||0);
  const a = attOf(u.id,d) || {id:BOS.uid("at"), empId:u.id, date:d};
  Object.assign(a, {in:t, status: o.remote ? "remote" : late ? "late" : "present", lateMin: late ? minutes(t)-minutes(w.start) : 0, by:u.id, at:now(), note:o.note||""});
  if(!S().attendance.includes(a)) S().attendance.push(a);
  BOS.audit("تسجيل حضور","attendance",a.id,u.name + " — " + d + " " + t + (late?" (متأخر " + a.lateMin + " د)":""));
  BOS.save(); return a;
}
function checkOut(o){
  const u = me(); o = o || {}; const d = o.date || today();
  const a = attOf(u.id,d); if(!a || !a.in) fail("سجّل الحضور أولاً");
  if(a.out) fail("سجلت انصرافك عند " + a.out);
  a.out = o.time || nowHM(); a.hours = Math.max(0,(minutes(a.out)-minutes(a.in))/60);
  BOS.audit("تسجيل انصراف","attendance",a.id,u.name + " — " + d + " " + a.out); BOS.save(); return a;
}
/* تصحيح سجل حضور — للموارد البشرية فقط مع سبب */
function correctAttendance(empId, date, o){
  const u = me(); if(!isHR(u)) fail("تصحيح الحضور للموارد البشرية");
  if(!o.reason) fail("سبب التصحيح إلزامي");
  if(!ATT[o.status]) fail("حالة غير معروفة");
  const a = attOf(empId,date) || {id:BOS.uid("at"), empId, date};
  const before = a.status || "—";
  Object.assign(a, {status:o.status, in:o.in||a.in||"", out:o.out||a.out||"", corrected:true, correctedBy:u.id, reason:o.reason, at:now()});
  if(!S().attendance.includes(a)) S().attendance.push(a);
  BOS.audit("تصحيح حضور","attendance",a.id,(BOS.byId(empId)||{}).name + " — " + date + ": " + (ATT[before]||before) + " ← " + ATT[o.status] + " — " + o.reason);
  BOS.save();
}
const isWorkday = d => !(work().weekend||[5,6]).includes(new Date(d+"T12:00:00").getDay());
/* الغياب: أيام العمل السابقة (حتى 7 أيام) دون حضور أو إجازة معتمدة — تنبيه للمدير المباشر */
function absenceSweep(){
  const s = S(); if(!s.setupDone) return 0;
  const start = (s.company.createdAt||now()).slice(0,10); let n = 0;
  for(let i=1;i<=7;i++){
    const d = new Date(Date.now()-i*864e5).toISOString().slice(0,10);
    if(d < start || !isWorkday(d)) continue;
    for(const e of s.employees){
      if(!BOS.active(e) || e.demo || (e.hireDate && e.hireDate > d) || attOf(e.id,d)) continue;
      const a = {id:BOS.uid("at"), empId:e.id, date:d, status:"absent", auto:true, at:now()};
      s.attendance.push(a); n++;
      const m = BOS.managerOf(e); if(m) BOS.notify(m.id,"غياب دون إجازة: " + e.name + " — " + d,"#/hr/attendance","warn");
    }
  }
  if(n){ BOS.audit("رصد غياب آلي","attendance",null,n + " سجل",null); BOS.save(); }
  return n;
}
function monthStats(empId, ym){
  const rows = S().attendance.filter(a=>a.empId===empId && a.date.startsWith(ym));
  const c = k => rows.filter(a=>a.status===k).length;
  return {present:c("present"), late:c("late"), absent:c("absent"), leave:c("leave"), remote:c("remote")+c("mission"),
    hours: rows.reduce((x,a)=>x+(a.hours||0),0), lateMin: rows.reduce((x,a)=>x+(a.lateMin||0),0)};
}

/* ---------- الأهداف والتقييم ---------- */
function period(){ const d = new Date(); return d.getFullYear() + "-" + (d.getMonth()<6?"H1":"H2"); }
function addGoal(empId, o){
  const u = me(); const e = BOS.byId(empId);
  if(!isHR(u) && !isManagerOf(u,e)) fail("الأهداف يضعها المدير المباشر أو الموارد البشرية");
  if(!o.title) fail("عنوان الهدف إلزامي");
  const w = Number(o.weight||0); if(!(w>0 && w<=100)) fail("الوزن بين 1 و100");
  const p = o.period || period();
  const sum = S().goals.filter(g=>g.empId===empId && g.period===p).reduce((a,g)=>a+g.weight,0);
  if(sum + w > 100) fail("مجموع أوزان الأهداف يتجاوز 100% (الحالي " + sum + "%)");
  const g = {id:BOS.uid("g"), empId, period:p, title:o.title, target:o.target||"", weight:w, progress:0, setBy:u.id, at:now(), updates:[]};
  S().goals.push(g);
  BOS.audit("وضع هدف","goal",g.id,e.name + " — " + g.title + " (" + w + "%)");
  if(empId!==u.id) BOS.notify(empId,"هدف جديد: " + g.title,"#/person/"+empId,"task");
  BOS.save(); return g;
}
function updateGoal(g, progress, note){
  const u = me(); const e = BOS.byId(g.empId);
  if(u.id!==g.empId && !isManagerOf(u,e) && !isHR(u)) fail("تحديث التقدم للموظف أو مديره");
  const v = Number(progress); if(!(v>=0 && v<=100)) fail("التقدم بين 0 و100");
  g.updates.push({at:now(), by:u.id, from:g.progress, to:v, note:note||""}); g.progress = v;
  BOS.audit("تحديث تقدم هدف","goal",g.id,e.name + " — " + g.title + ": " + v + "%"); BOS.save();
}
/* مؤشرات موضوعية تُعرض للمقيّم: إعادة العمل، العيوب المعاد فتحها، الحضور */
function evidence(empId){
  const s = S(); const y = new Date().getFullYear() + "-";
  const tasks = s.tasks ? s.tasks.filter(t=>t.ownerId===empId) : [];
  const late = tasks.filter(t=>t.due && t.status==="done" && t.verifiedAt && t.verifiedAt.slice(0,10) > t.due).length;
  const rows = s.attendance.filter(a=>a.empId===empId && a.date.startsWith(y));
  return {tasksDone: tasks.filter(t=>t.status==="done").length, rework: tasks.reduce((a,t)=>a+(t.reworkCount||0),0), lateTasks: late,
    reopened: (s.bugs||[]).filter(b=>b.fixedBy===empId && (b.reopenCount||0)>0).length,
    absent: rows.filter(a=>a.status==="absent").length, lateDays: rows.filter(a=>a.status==="late").length,
    goals: s.goals.filter(g=>g.empId===empId && g.period===period())};
}
function createEvaluation(empId, o){
  const u = me(); const e = BOS.byId(empId);
  if(!isManagerOf(u,e) && !BOS.isTop(u)) fail("التقييم يعده المدير المباشر");
  if(u.id===empId) fail("لا يقيّم الموظف نفسه");
  const scores = {}; for(const c of EVAL_CRITERIA){ const v = Number((o.scores||{})[c]); if(!(v>=1 && v<=5)) fail("قيّم كل المعايير من 1 إلى 5"); scores[c] = v; }
  const p = o.period || period();
  if(S().evaluations.some(x=>x.empId===empId && x.period===p && x.status!=="draft")) fail("يوجد تقييم مرسل لهذه الفترة");
  const goals = S().goals.filter(g=>g.empId===empId && g.period===p);
  const goalScore = goals.length ? goals.reduce((a,g)=>a + g.weight*g.progress/100,0) / goals.reduce((a,g)=>a+g.weight,0) * 5 : null;
  const crit = Object.values(scores).reduce((a,b)=>a+b,0)/EVAL_CRITERIA.length;
  const overall = goalScore==null ? crit : (crit*0.5 + goalScore*0.5);
  const ev = {id:BOS.uid("ev"), no:BOS.nextNo("EVL"), empId, period:p, managerId:u.id, scores, goalScore, overall:Math.round(overall*100)/100,
    strengths:o.strengths||"", improvements:o.improvements||"", trainingNeed:o.trainingNeed||"", status:"submitted", at:now(), evidence:evidence(empId)};
  S().evaluations.unshift(ev);
  BOS.audit("إعداد تقييم أداء","evaluation",ev.id,ev.no + " — " + e.name + " — " + p);
  BOS.notify(empId,"تقييم أدائك للفترة " + p + " جاهز للاطلاع","#/person/"+empId,"task");
  // الاحتياج التدريبي يُسجل فجوة تلقائياً للمتابعة
  if(o.trainingNeed){ const t = holder("training"); if(t) BOS.notify(t.id,"احتياج تدريبي من تقييم " + e.name + ": " + o.trainingNeed,"#/training/gaps","task"); }
  BOS.save(); return ev;
}
function acknowledgeEvaluation(ev, comment){
  const u = me(); if(u.id!==ev.empId) fail("الاطلاع للموظف نفسه");
  if(ev.status!=="submitted") fail("التقييم ليس بانتظار الاطلاع");
  ev.status = "acknowledged"; ev.employeeComment = comment||""; ev.ackAt = now();
  BOS.audit("اطلاع موظف على تقييمه","evaluation",ev.id,ev.no + (comment?" — ملاحظة الموظف: " + comment:""));
  const hr = holder("hr"); if(hr) BOS.notify(hr.id,"تقييم بانتظار الاعتماد: " + ev.no,"#/hr/performance","task");
  BOS.save();
}
function approveEvaluation(ev){
  const u = me(); if(!isHR(u)) fail("الاعتماد للموارد البشرية");
  if(ev.status!=="acknowledged") fail("يُعتمد التقييم بعد اطلاع الموظف");
  if(u.id===ev.managerId) fail("لا يعتمد المقيّم تقييمه");
  ev.status = "approved"; ev.hrBy = u.id; ev.hrAt = now();
  BOS.audit("اعتماد تقييم أداء","evaluation",ev.id,ev.no); BOS.save();
}

/* ---------- العهد والأصول ---------- */
function createAsset(o){
  const u = me(); if(!isHR(u) && !["accountant","procurement"].includes(posKey(u))) fail("سجل الأصول للموارد البشرية والمحاسبة والمشتريات");
  if(!o.desc) fail("وصف الأصل إلزامي");
  const a = {id:BOS.uid("as"), no:BOS.nextNo("AST"), desc:o.desc, category:o.category||"أجهزة", serial:o.serial||"", value:Number(o.value||0),
    status:"stock", holderId:"", issuedAt:"", requestId:o.requestId||"", history:[{at:now(), by:u.id, action:"تسجيل"}], createdAt:now()};
  S().assets.unshift(a);
  BOS.audit("تسجيل أصل","asset",a.id,a.no + " — " + a.desc + (a.serial?" — " + a.serial:""));
  if(o.holderId) issueAsset(a, o.holderId, true); else BOS.save();
  return a;
}
function issueAsset(a, empId, quiet){
  const u = me(); if(!isHR(u) && !["accountant","procurement"].includes(posKey(u))) fail("تسليم العهدة للموارد البشرية أو المحاسبة");
  const e = BOS.byId(empId); if(!e || !BOS.active(e)) fail("اختر موظفاً نشطاً");
  if(a.status==="issued") fail("الأصل عهدة لدى " + (BOS.byId(a.holderId)||{}).name);
  a.status = "issued"; a.holderId = empId; a.issuedAt = now(); a.history.push({at:now(), by:u.id, action:"تسليم عهدة إلى " + e.name});
  BOS.audit("تسليم عهدة","asset",a.id,a.no + " ← " + e.name);
  BOS.notify(empId,"سُجلت في عهدتك: " + a.desc + " (" + a.no + ")","#/person/"+empId);
  BOS.save();
}
function returnAsset(a, o){
  const u = me(); if(!isHR(u) && !["accountant","procurement"].includes(posKey(u))) fail("استلام العهدة للموارد البشرية أو المحاسبة");
  if(a.status!=="issued") fail("الأصل ليس عهدة");
  const st = o.status || "returned"; if(!["returned","lost","damaged"].includes(st)) fail("حالة غير صالحة");
  if(st!=="returned" && !o.note) fail("وثّق حالة الفقد أو التلف");
  const from = BOS.byId(a.holderId);
  a.history.push({at:now(), by:u.id, action:(st==="returned"?"استلام من ":"تسجيل " + ASSET_STATUS[st] + " — ") + (from?from.name:"") + (o.note?" — " + o.note:"")});
  a.status = st==="returned" ? "stock" : st; a.lastHolderId = a.holderId; a.holderId = ""; a.returnedAt = now();
  BOS.audit(st==="returned"?"استلام عهدة":"تسجيل فقد/تلف عهدة","asset",a.id,a.no + " — " + (from?from.name:"") + (o.note?" — " + o.note:""));
  // تحديث قائمة إنهاء الخدمة إن وُجدت
  const ob = S().onboarding.find(x=>x.empId===(from||{}).id && x.kind==="offboarding" && !x.closedAt);
  if(ob){ const it = ob.items.find(i=>i.assetId===a.id); if(it){ it.done = true; it.doneAt = now(); it.doneBy = u.id; it.note = ASSET_STATUS[st==="returned"?"returned":st]; } }
  BOS.save();
}
const custodyOf = empId => S().assets.filter(a=>a.holderId===empId && a.status==="issued");

/* ---------- الملاحظات السرية والجزاءات ---------- */
function addNote(empId, o){
  const u = me(); if(!isHR(u)) fail("الملاحظات السرية والجزاءات للموارد البشرية والمدير العام");
  if(!NOTE_KINDS[o.kind]) fail("اختر النوع"); if(!o.text) fail("النص إلزامي");
  const n = {id:BOS.uid("hn"), no:BOS.nextNo("HRN"), empId, kind:o.kind, text:o.text, by:u.id, at:now()};
  S().hrNotes.unshift(n);
  // لا تُكتب التفاصيل السرية في سجل التدقيق العام — فقط النوع والرقم
  BOS.audit("قيد في الملف السري","hrnote",n.id,n.no + " — " + NOTE_KINDS[o.kind] + " — " + (BOS.byId(empId)||{}).name);
  if(o.kind!=="note") BOS.notify(empId,"أُضيف إلى ملفك: " + NOTE_KINDS[o.kind] + " (" + n.no + ")","#/person/"+empId, o.kind==="commendation"?"ok":"warn");
  BOS.save(); return n;
}

/* ---------- العقد وإصداراته ---------- */
function setContract(e, o){
  const u = me(); if(!isHR(u)) fail("العقد للموارد البشرية");
  if(!o.type || !o.start) fail("نوع العقد وتاريخ البدء إلزاميان");
  e.contracts = e.contracts || [];
  const v = {v:e.contracts.length+1, type:o.type, start:o.start, end:o.end||"", salary:Number(o.salary||0), currency:o.currency||S().settings.currency, probationEnd:o.probationEnd||"", note:o.note||"", by:u.id, at:now()};
  e.contracts.push(v);
  BOS.audit(v.v===1?"تسجيل عقد عمل":"إصدار جديد لعقد العمل","employee",e.id,e.name + " — الإصدار " + v.v + " (" + v.type + ")");
  BOS.save(); return v;
}

/* ---------- التأهيل وإنهاء الخدمة ---------- */
function startOnboarding(e){
  if(S().onboarding.some(x=>x.empId===e.id && x.kind==="onboarding")) return null;
  const base = new Date(e.hireDate || today());
  const m = BOS.managerOf(e); const tr = holder("training"); const hr = holder("hr");
  const ob = {id:BOS.uid("ob"), empId:e.id, kind:"onboarding", createdAt:now(), items: ONBOARDING.map(([d,t])=>({id:BOS.uid("oi"), phase:d, text:t,
    due:new Date(base.getTime()+d*864e5).toISOString().slice(0,10), ownerId: d===30 ? (hr||m||{}).id : d===60 ? (tr||m||{}).id : (m||hr||{}).id, done:false}))};
  S().onboarding.push(ob);
  BOS.audit("إنشاء خطة تأهيل 30/60/90","employee",e.id,e.name);
  [m,tr].filter(Boolean).forEach(x=>BOS.notify(x.id,"موظف جديد يحتاج إلى خطة تأهيل: " + e.name,"#/person/"+e.id,"task"));
  return ob;
}
function startOffboarding(e, reason){
  if(S().onboarding.some(x=>x.empId===e.id && x.kind==="offboarding" && !x.closedAt)) return null;
  const hr = holder("hr"); const m = BOS.managerOf(e);
  const items = custodyOf(e.id).map(a=>({id:BOS.uid("oi"), text:"استلام العهدة: " + a.desc + " (" + a.no + ")", assetId:a.id, ownerId:(hr||{}).id, done:false}))
    .concat([["إيقاف الحسابات وصلاحيات الوصول", true],["نقل الملفات والمهام المفتوحة", false],["التسوية المالية النهائية", false],["مقابلة نهاية الخدمة", false]]
      .map(([t,done])=>({id:BOS.uid("oi"), text:t, ownerId:(t.includes("نقل")?(m||hr):hr||{}).id, done, doneAt:done?now():null, note:done?"تم آلياً عند الإيقاف":""})));
  const ob = {id:BOS.uid("ob"), empId:e.id, kind:"offboarding", reason:reason||"", createdAt:now(), items};
  S().onboarding.push(ob);
  BOS.audit("بدء إنهاء خدمة وتسليم عهد","employee",e.id,e.name + " — " + items.filter(i=>i.assetId).length + " عهدة");
  if(hr) BOS.notify(hr.id,"إنهاء خدمة " + e.name + ": " + items.filter(i=>!i.done).length + " بند مفتوح","#/hr/lifecycle","task");
  return ob;
}
function toggleItem(ob, itemId, note){
  const u = me(); const it = ob.items.find(i=>i.id===itemId); if(!it) fail("بند غير موجود");
  if(it.assetId) fail("بنود العهد تُقفل باستلام الأصل من سجل العهد");
  if(u.id!==it.ownerId && !isHR(u) && !isManagerOf(u, BOS.byId(ob.empId))) fail("البند مسند إلى " + (BOS.byId(it.ownerId)||{}).name);
  it.done = !it.done; it.doneAt = it.done ? now() : null; it.doneBy = u.id; if(note) it.note = note;
  if(ob.items.every(i=>i.done)){ ob.closedAt = now(); BOS.audit(ob.kind==="onboarding"?"اكتمال خطة التأهيل":"اكتمال إنهاء الخدمة","employee",ob.empId,(BOS.byId(ob.empId)||{}).name); }
  else ob.closedAt = null;
  BOS.save();
}

/* ---------- المهارات ومصفوفة الكفاءة (القسم 6.4) ---------- */
const reqFor = e => S().skillReq[posKey(e)] || {};
const levelOf = (empId, skill) => ((S().empSkills[empId]||{})[skill]||{}).level || 0;
function setLevel(empId, skill, level, source){
  const u = me();
  const l = Number(level); if(!(l>=0 && l<=4)) fail("المستوى من 0 إلى 4");
  const m = S().empSkills[empId] = S().empSkills[empId] || {};
  const prev = (m[skill]||{}).level || 0;
  m[skill] = {level:l, at:now(), by:u?u.id:null, source:source||"تقييم", history:((m[skill]||{}).history||[]).concat([{at:now(), from:prev, to:l, source:source||"تقييم"}])};
  BOS.audit("تحديث مصفوفة المهارات","skill",empId,(BOS.byId(empId)||{}).name + " — " + skill + ": " + LEVELS[prev] + " ← " + LEVELS[l] + " (" + (source||"تقييم") + ")");
}
function rateSkill(empId, skill, level){
  const u = me(); const e = BOS.byId(empId);
  if(!isManagerOf(u,e) && posKey(u)!=="training" && !isHR(u)) fail("تقدير المهارة للمدير المباشر أو مدير التدريب");
  setLevel(empId, skill, level, "تقدير " + BOS.posTitle(u.positionId)); BOS.save();
}
/* فجوات المهارات + المؤشرات التي ترفع أولويتها */
function gaps(){
  const s = S(); const out = [];
  for(const e of s.employees.filter(BOS.active)){
    const req = reqFor(e);
    const signals = [];
    const ev = s.evaluations.filter(x=>x.empId===e.id).sort((a,b)=>a.at<b.at?1:-1)[0];
    if(ev && ev.overall < 3) signals.push("تقييم أداء " + ev.overall + "/5");
    if(ev && ev.trainingNeed) signals.push("احتياج من التقييم: " + ev.trainingNeed);
    const rw = (s.tasks||[]).filter(t=>t.ownerId===e.id).reduce((a,t)=>a+(t.reworkCount||0),0); if(rw>=2) signals.push("إعادة عمل ×" + rw);
    const rb = (s.bugs||[]).filter(b=>b.fixedBy===e.id && (b.reopenCount||0)>0).length; if(rb) signals.push("عيوب أعيد فتحها ×" + rb);
    const tk = (s.tickets||[]).filter(t=>t.ownerId===e.id && t.rootCause==="نقص في التدريب").length; if(tk) signals.push("شكاوى بسبب نقص التدريب ×" + tk);
    const inc = s.requests.filter(r=>r.type==="incident" && r.creatorId!==e.id && (r.data.details||"").includes(e.name)).length; if(inc) signals.push("مذكور في حادث أمني");
    for(const skill in req){
      const have = levelOf(e.id, skill);
      if(have < req[skill]){
        const planned = s.programs.some(p=>!["completed","archived"].includes(p.status) && p.skills.includes(skill) && p.enrollments.some(x=>x.empId===e.id));
        out.push({emp:e, skill, need:req[skill], have, gap:req[skill]-have, signals, planned, priority:(req[skill]-have) + signals.length});
      }
    }
  }
  return out.sort((a,b)=>b.priority-a.priority);
}

/* ---------- البرامج التدريبية ---------- */
const program = id => S().programs.find(p=>p.id===id);
const canManageTraining = u => BOS.can(u,"training","edit") || BOS.can(u,"training","manage") || BOS.isTop(u);
function createProgram(o){
  const u = me(); if(!BOS.can(u,"training","create")) fail("لا تملك صلاحية إنشاء برنامج تدريبي");
  if(!o.title) fail("عنوان البرنامج إلزامي");
  const p = {id:BOS.uid("tp"), no:BOS.nextNo("TRN"), title:o.title, kind:o.kind||"داخلي", providerId:o.providerId||"", trainer:o.trainer||"",
    skills:(o.skills||[]).filter(Boolean), level:Number(o.level||2), cost:Number(o.cost||0), currency:S().settings.currency, hours:Number(o.hours||0),
    start:o.start||"", end:o.end||"", seats:Number(o.seats||0), linkedDefect:!!o.linkedDefect, goal:o.goal||"", materials:o.materials||"",
    status:"draft", enrollments:[], requestId:"", createdBy:u.id, createdAt:now(), history:[{at:now(), by:u.id, to:"draft"}], impact:""};
  (o.nominees||[]).forEach(id=>p.enrollments.push({empId:id, nominatedBy:u.id, at:now(), pre:null, post:null, attended:null, passed:null}));
  S().programs.unshift(p);
  BOS.audit("إنشاء برنامج تدريبي","training",p.id,p.no + " — " + p.title);
  BOS.save(); return p;
}
function nominate(p, empId){
  const u = me(); const e = BOS.byId(empId);
  if(!canManageTraining(u) && !isManagerOf(u,e) && !BOS.can(u,"training","create")) fail("الترشيح للمدير المباشر أو إدارة التدريب");
  if(["completed","archived","evaluation"].includes(p.status)) fail("البرنامج في مرحلة لا تقبل ترشيحات");
  if(p.enrollments.some(x=>x.empId===empId)) fail("مرشح مسبقاً");
  if(p.seats && p.enrollments.length >= p.seats) fail("اكتملت المقاعد (" + p.seats + ")");
  p.enrollments.push({empId, nominatedBy:u.id, at:now(), pre:null, post:null, attended:null, passed:null});
  BOS.audit("ترشيح لبرنامج تدريبي","training",p.id,p.no + " — " + e.name);
  if(["scheduled","running"].includes(p.status)) BOS.notify(empId,"رُشحت لبرنامج: " + p.title + (p.start?" — يبدأ " + p.start:""),"#/program/"+p.id,"task");
  BOS.save();
}
function moveProgram(p, to, o){
  o = o || {}; const u = me();
  if(!canManageTraining(u)) fail("إدارة البرامج لمدير التدريب");
  const order = PROGRAM_FLOW.map(x=>x[0]); const fi = order.indexOf(p.status), ti = order.indexOf(to);
  if(ti !== fi+1) fail("الانتقال للمرحلة التالية فقط");
  switch(to){
    case "proposed":
      if(!p.skills.length) fail("اربط البرنامج بمهارة واحدة على الأقل من المصفوفة");
      if(!p.goal) fail("حدد الهدف والأثر المتوقع");
      { // يمر الاعتماد بمسار «خطة / طلب تدريب» (المدير المباشر ← مدير التدريب ← الموارد البشرية ← المالية عند التكلفة ← الجودة عند ارتباطه بعيب ← المدير العام عند تجاوز الحد)
        const r = BOS.createRequest("training",{program:p.title, provider:(provider(p.providerId)||{}).name||p.trainer||p.kind, amount:p.cost, linkedDefect:p.linkedDefect, goal:p.goal},
          {title:"اعتماد برنامج تدريبي — " + p.title, link:{kind:"program", id:p.id}});
        p.requestId = r.id; }
      break;
    case "approved": fail("يُعتمد البرنامج باكتمال مسار الموافقة المرتبط به");
    case "scheduled":
      if(!p.start || !p.end) fail("حدد تاريخي البداية والنهاية");
      if(!p.enrollments.length) fail("رشّح المتدربين أولاً");
      p.enrollments.forEach(x=>BOS.notify(x.empId,"مجدول لك: " + p.title + " — " + p.start + " إلى " + p.end,"#/program/"+p.id,"task"));
      break;
    case "running": break;
    case "evaluation":
      if(p.enrollments.some(x=>x.attended==null)) fail("سجّل الحضور لكل المتدربين");
      break;
    case "completed": {
      // لا يعتبر التدريب مكتملاً بمجرد الحضور (القسم 6.4)
      const attended = p.enrollments.filter(x=>x.attended);
      if(attended.some(x=>x.post==null || x.passed==null)) fail("سجّل نتيجة التقييم البعدي والنجاح لكل من حضر");
      if(!o.impact && !p.impact) fail("سجّل أثر التدريب على مؤشر أو ملاحظة عملية");
      if(o.impact) p.impact = o.impact;
      for(const x of attended.filter(x=>x.passed)){
        for(const skill of p.skills){ const cur = levelOf(x.empId, skill); if(cur < p.level) setLevel(x.empId, skill, p.level, "اجتياز " + p.no); }
        if(o.certMonths){ x.certNo = BOS.nextNo("CERT"); x.certExpiry = new Date(Date.now()+Number(o.certMonths)*30*864e5).toISOString().slice(0,10); }
        BOS.notify(x.empId,"اجتزت البرنامج: " + p.title + (x.certNo?" — شهادة " + x.certNo:""),"#/program/"+p.id,"ok");
      }
      p.completedAt = now();
      break; }
    case "archived": break;
  }
  const from = p.status; p.status = to; p.history.push({at:now(), by:u.id, from, to, note:o.note||""});
  BOS.audit("تغيير مرحلة برنامج تدريبي","training",p.id,p.no + ": " + PSTAT[from] + " ← " + PSTAT[to]);
  BOS.save();
}
function recordResult(p, empId, o){
  const u = me(); if(!canManageTraining(u)) fail("تسجيل النتائج لمدير التدريب");
  const x = p.enrollments.find(e=>e.empId===empId); if(!x) fail("غير مرشح");
  if(o.pre!==undefined && o.pre!=="") { const v = Number(o.pre); if(!(v>=0&&v<=100)) fail("الدرجة من 0 إلى 100"); x.pre = v; }
  if(o.attended!==undefined) x.attended = !!o.attended;
  if(o.post!==undefined && o.post!=="") { if(!["running","evaluation"].includes(p.status)) fail("التقييم البعدي أثناء التنفيذ أو التقييم"); const v = Number(o.post); if(!(v>=0&&v<=100)) fail("الدرجة من 0 إلى 100"); x.post = v; x.passed = v >= Number(o.passMark||70); }
  if(x.attended===false){ x.passed = false; }
  BOS.audit("تسجيل نتيجة تدريب","training",p.id,p.no + " — " + (BOS.byId(empId)||{}).name + (x.post!=null?" — " + x.post + "%":""));
  BOS.save();
}
function rateProvider(p, score){
  const u = me(); const v = Number(score); if(!(v>=1&&v<=5)) fail("التقييم من 1 إلى 5");
  if(!p.enrollments.some(x=>x.empId===u.id) && !canManageTraining(u)) fail("التقييم للمتدربين أو إدارة التدريب");
  p.ratings = (p.ratings||[]).filter(r=>r.by!==u.id).concat([{by:u.id, score:v, at:now()}]);
  const pr = provider(p.providerId); if(pr){ pr.ratings = (pr.ratings||[]).filter(r=>!(r.by===u.id && r.programId===p.id)).concat([{by:u.id, programId:p.id, score:v}]); }
  BOS.audit("تقييم برنامج تدريبي","training",p.id,p.no + " — " + v + "/5"); BOS.save();
}
const provider = id => S().providers.find(x=>x.id===id);
function createProvider(o){ const u = me(); if(!canManageTraining(u)) fail("سجل المدربين لمدير التدريب"); if(!o.name) fail("الاسم إلزامي");
  const x = {id:BOS.uid("pv"), name:o.name, kind:o.kind||"جهة خارجية", contact:o.contact||"", specialty:o.specialty||"", ratings:[], at:now()};
  S().providers.push(x); BOS.audit("إضافة مدرب/مزود","training",x.id,x.name); BOS.save(); return x; }
function certificates(){
  return S().programs.flatMap(p=>p.enrollments.filter(x=>x.certNo).map(x=>({p, x, emp:BOS.byId(x.empId)})));
}
/* تنبيه قبل موعد التدريب وانتهاء الشهادة */
function trainingSweep(){
  let n = 0; const soon = new Date(Date.now()+30*864e5).toISOString().slice(0,10), d3 = new Date(Date.now()+3*864e5).toISOString().slice(0,10);
  for(const c of certificates()){ if(c.x.certExpiry <= soon && !c.x.expiryNotified){ c.x.expiryNotified = true; n++;
    BOS.notify(c.x.empId,"شهادتك " + c.x.certNo + " (" + c.p.title + ") تنتهي " + c.x.certExpiry,"#/program/"+c.p.id,"warn");
    const t = holder("training"); if(t) BOS.notify(t.id,"شهادة تقترب من الانتهاء: " + (c.emp||{}).name + " — " + c.p.title,"#/training/certs","warn"); } }
  for(const p of S().programs){ if(p.status==="scheduled" && p.start && p.start <= d3 && !p.reminded){ p.reminded = true; n++;
    p.enrollments.forEach(x=>BOS.notify(x.empId,"تذكير: يبدأ برنامج " + p.title + " في " + p.start,"#/program/"+p.id,"task")); } }
  if(n) BOS.save(); return n;
}

/* ---------- المحتوى والعلاقات العامة (القسم 6.3) ---------- */
function createContent(o){
  const u = me(); if(!BOS.can(u,"content","create")) fail("لا تملك صلاحية إنشاء محتوى");
  if(!o.title || !o.body) fail("العنوان والنص إلزاميان");
  const c = {id:BOS.uid("ct"), no:BOS.nextNo("PUB"), title:o.title, channel:o.channel||"لينكدإن", date:o.date||"", campaign:o.campaign||"", body:o.body,
    customerId:o.customerId||"", projectId:o.projectId||"", sensitive:!!o.sensitive, status:"draft", by:u.id, at:now(), history:[{at:now(), by:u.id, to:"draft"}]};
  S().content.unshift(c); BOS.audit("إنشاء محتوى","content",c.id,c.no + " — " + c.title); BOS.save(); return c;
}
function consentOk(c){ if(!c.customerId) return true; const cu = S().customers.find(x=>x.id===c.customerId); return !!(cu && cu.publishConsent); }
function moveContent(c, to, o){
  o = o || {}; const u = me();
  if(!BOS.can(u,"content","edit") && c.by!==u.id) fail("لا تملك صلاحية");
  const order = CONTENT_FLOW.map(x=>x[0]); if(order.indexOf(to) !== order.indexOf(c.status)+1 && !(to==="draft" && c.status==="review")) fail("الانتقال للمرحلة التالية فقط");
  if(to==="review"){
    // لا يجوز نشر شعار أو اسم عميل دون سجل موافقة واضح
    if(!consentOk(c)) fail("العميل المذكور لم يوافق على النشر — وثّق موافقته في سجل العميل أولاً");
    const cu = S().customers.find(x=>x.id===c.customerId);
    const r = BOS.createRequest("publish",{channel:c.channel, content:c.title + "\n" + c.body, mentionsClient:!!c.customerId, sensitive:c.sensitive},
      {title:"نشر: " + c.title + (cu?" (يذكر " + cu.name + ")":""), link:{kind:"content", id:c.id}});
    c.requestId = r.id;
  }
  if(to==="approved") fail("يُعتمد المحتوى باكتمال مسار «نشر إعلامي»");
  if(to==="scheduled" && !(o.date || c.date)) fail("حدد تاريخ النشر");
  if(to==="published"){ if(!consentOk(c)) fail("سُحبت موافقة العميل على النشر — أوقف النشر"); c.publishedAt = now(); c.url = o.url||""; }
  if(o.date) c.date = o.date;
  const from = c.status; c.status = to; c.history.push({at:now(), by:u.id, from, to});
  BOS.audit("تغيير حالة محتوى","content",c.id,c.no + ": " + CSTAT[from] + " ← " + CSTAT[to]); BOS.save();
}
function addInteraction(customerId, o){
  const u = me(); if(!BOS.can(u,"customers","edit") && !BOS.can(u,"customers","create") && !BOS.can(u,"support","edit")) fail("لا تملك صلاحية");
  if(!o.summary) fail("الملخص إلزامي");
  const i = {id:BOS.uid("ci"), customerId, kind:o.kind||"اجتماع", date:o.date||today(), summary:o.summary, next:o.next||"", nextDate:o.nextDate||"", by:u.id, at:now()};
  S().interactions.unshift(i); BOS.audit("تسجيل تواصل مع عميل","customer",customerId,i.kind + " — " + i.summary.slice(0,60)); BOS.save(); return i;
}
function setConsent(cust, value, o){
  const u = me(); if(!BOS.can(u,"customers","edit")) fail("لا تملك صلاحية");
  if(value && !o.evidence) fail("وثّق مصدر الموافقة (خطاب، بريد، بند في العقد)");
  cust.consentLog = (cust.consentLog||[]).concat([{at:now(), by:u.id, value:!!value, evidence:o.evidence||"", scope:o.scope||""}]);
  cust.publishConsent = !!value;
  BOS.audit(value?"توثيق موافقة عميل على النشر":"سحب موافقة عميل على النشر","customer",cust.id,cust.name + (o.evidence?" — " + o.evidence:""));
  if(!value){ const pr = holder("pr"); const pending = S().content.filter(c=>c.customerId===cust.id && c.status!=="published"); if(pr && pending.length) BOS.notify(pr.id,"سحب " + cust.name + " موافقته على النشر — " + pending.length + " محتوى معلق","#/content","bad"); }
  BOS.save();
}
function addSurvey(customerId, o){
  const u = me(); if(!BOS.can(u,"customers","edit") && !BOS.can(u,"support","edit")) fail("لا تملك صلاحية");
  const sc = Number(o.score), nps = o.nps===""||o.nps==null ? null : Number(o.nps);
  if(!(sc>=1&&sc<=5)) fail("الرضا من 1 إلى 5"); if(nps!=null && !(nps>=0&&nps<=10)) fail("التوصية من 0 إلى 10");
  const s = {id:BOS.uid("sv"), customerId, projectId:o.projectId||"", score:sc, nps, comment:o.comment||"", by:u.id, at:now()};
  S().surveys.unshift(s); BOS.audit("استبيان رضا عميل","customer",customerId,sc + "/5" + (nps!=null?" — توصية " + nps:""));
  if(sc<=2){ const qm = holder("qm"); if(qm) BOS.notify(qm.id,"رضا منخفض من " + (S().customers.find(c=>c.id===customerId)||{}).name + ": " + sc + "/5","#/customer/"+customerId,"bad"); }
  BOS.save(); return s;
}

/* ---------- ربط محرك الموافقات ---------- */
function onClosed(r){
  const s = S();
  if(r.type==="leave"){
    // تسجيل أيام الإجازة المعتمدة في الحضور وتنبيه نفاد الرصيد
    const from = new Date(r.data.from+"T12:00:00"), to = new Date(r.data.to+"T12:00:00");
    for(let d = new Date(from); d <= to; d = new Date(d.getTime()+864e5)){
      const k = d.toISOString().slice(0,10); const a = attOf(r.creatorId,k) || {id:BOS.uid("at"), empId:r.creatorId, date:k};
      Object.assign(a,{status:"leave", requestId:r.id, at:now()}); if(!s.attendance.includes(a)) s.attendance.push(a);
    }
    const e = BOS.byId(r.creatorId); const left = Number(s.settings.leaveDays||30) - Number(e.leaveUsed||0);
    if(left <= 3){ BOS.notify(e.id,"رصيد إجازاتك المتبقي: " + left + " يوم","#/person/"+e.id,"warn"); const m = BOS.managerOf(e); if(m) BOS.notify(m.id,"رصيد إجازات " + e.name + " شارف على النفاد (" + left + ")","#/person/"+e.id,"warn"); }
  }
  if(r.type==="purchase"){
    // «تسجيل الأصل والعهدة»: يُسجل الأصل المشترى ويسلم عهدة لطالب الشراء
    const qty = Math.max(1, Math.min(20, Number(r.data.qty||1)));
    for(let i=0;i<qty;i++){
      const a = {id:BOS.uid("as"), no:BOS.nextNo("AST"), desc:r.data.item, category:"مشتريات", serial:"", value:Number(r.data.amount||0)/qty, status:"issued",
        holderId:r.creatorId, issuedAt:now(), requestId:r.id, history:[{at:now(), action:"تسجيل من طلب الشراء " + r.no + " وتسليم عهدة"}], createdAt:now()};
      s.assets.unshift(a);
      BOS.audit("تسجيل أصل وعهدة من طلب شراء","asset",a.id,a.no + " — " + a.desc + " ← " + (BOS.byId(r.creatorId)||{}).name);
    }
  }
  if(r.link && r.link.kind==="program"){
    const p = program(r.link.id);
    if(p && p.status==="proposed"){ p.status = "approved"; p.history.push({at:now(), to:"approved", note:"اكتمال " + r.no}); BOS.audit("اعتماد برنامج تدريبي","training",p.id,p.no + " — " + r.no);
      const t = holder("training"); if(t) BOS.notify(t.id,"اعتُمد البرنامج " + p.title + " — جدوله الآن","#/program/"+p.id,"ok"); }
  }
  if(r.link && r.link.kind==="content"){
    const c = s.content.find(x=>x.id===r.link.id);
    if(c && c.status==="review"){ c.status = "approved"; c.history.push({at:now(), to:"approved", note:r.no}); BOS.audit("اعتماد محتوى للنشر","content",c.id,c.no); BOS.notify(c.by,"اعتُمد المحتوى: " + c.title,"#/content","ok"); }
  }
}
function onAborted(r){
  if(r.link && r.link.kind==="program"){ const p = program(r.link.id); if(p && p.status==="proposed"){ p.status = "draft"; p.history.push({at:now(), to:"draft", note:"رُفض/أُلغي " + r.no}); } }
  if(r.link && r.link.kind==="content"){ const c = S().content.find(x=>x.id===r.link.id); if(c && c.status==="review"){ c.status = "draft"; c.history.push({at:now(), to:"draft", note:"رُفض/أُلغي " + r.no}); } }
}
function onEmployeeCreated(e){ startOnboarding(e); BOS.save(); }
function onEmployeeDisabled(e, reason){ startOffboarding(e, reason); BOS.save(); }

/* ---------- ترقية وبذور ---------- */
function migrate(){
  const s = S(); if(!s.company || !s.company.tradeName) return;
  if(!s.skills.length) s.skills = DEFAULT_SKILLS.map(([name,cat])=>({id:BOS.uid("sk"), name, category:cat}));
  if(!Object.keys(s.skillReq).length) s.skillReq = JSON.parse(JSON.stringify(DEFAULT_REQ));
}

/* ---------- مؤشرات (القسم 11) ---------- */
function metrics(){
  const s = S(); const yearAgo = new Date(Date.now()-365*864e5).toISOString();
  const enr = s.programs.filter(p=>p.status==="completed"||p.status==="archived").flatMap(p=>p.enrollments);
  const completion = enr.length ? Math.round(enr.filter(x=>x.attended).length/enr.length*100) : null;
  const assessed = enr.filter(x=>x.passed!=null && x.attended);
  const passRate = assessed.length ? Math.round(assessed.filter(x=>x.passed).length/assessed.length*100) : null;
  const g = gaps();
  const costByDept = {}; s.programs.filter(p=>p.cost && !["draft"].includes(p.status)).forEach(p=>{ const per = p.cost/Math.max(1,p.enrollments.length);
    p.enrollments.forEach(x=>{ const d = (BOS.dept((BOS.byId(x.empId)||{}).deptId)||{}).name || "—"; costByDept[d] = (costByDept[d]||0) + per; }); });
  const ob = s.onboarding.filter(o=>o.kind==="onboarding"); const obDone = ob.length ? Math.round(ob.filter(o=>o.closedAt).length/ob.length*100) : null;
  const headcount = s.employees.filter(BOS.active).length;
  const left = s.employees.filter(e=>e.status==="disabled" && e.disabledAt && e.disabledAt > yearAgo).length;
  const turnover = headcount+left ? Math.round(left/((headcount+left+headcount)/2)*100) : 0;
  const ym = today().slice(0,7);
  const att = s.attendance.filter(a=>a.date.startsWith(ym));
  const absRate = att.length ? Math.round(att.filter(a=>a.status==="absent").length/att.length*100) : null;
  const trainedWithImpact = s.programs.filter(p=>p.status==="completed" && p.impact).length;
  return {completion, passRate, gapsOpen:g.length, gapsUnplanned:g.filter(x=>!x.planned).length, costByDept, obDone, turnover, headcount, left, absRate, trainedWithImpact,
    custody: s.assets.filter(a=>a.status==="issued").length, lostAssets: s.assets.filter(a=>["lost","damaged"].includes(a.status)).length,
    evalPending: s.evaluations.filter(e=>e.status!=="approved").length};
}

/* ---------- بيانات تجريبية ---------- */
function seedHr(){
  const s = S(); migrate();
  const k = key => s.employees.find(e=>BOS.active(e) && posKey(e)===key);
  const hr = k("hr"), tr = k("training"), dev = k("dev"), des = k("designer"), cs = k("cs"), dl = k("devlead"), pr = k("pr"), acc = k("accountant");
  if(!hr || !tr || !dev) return;
  const saved = s.session.userId; const as = e => { s.session.userId = e.id; };
  try{
    // مستويات مهارات أولية
    as(dl); rateSkill(dev.id,"تطوير تطبيقات الجوال",3); rateSkill(dev.id,"تطوير الويب",2); rateSkill(dev.id,"اختبار البرمجيات",1); rateSkill(dev.id,"أمن المعلومات",1);
    if(des){ rateSkill(des.id,"تصميم واجهات وتجربة المستخدم",3); rateSkill(des.id,"التواصل والعرض",2); }
    // عقود وعهد
    as(hr);
    s.employees.filter(e=>e.demo).forEach(e=>{ if(!e.contracts) setContract(e,{type:"دوام كامل", start:e.hireDate, probationEnd:new Date(Date.now()+90*864e5).toISOString().slice(0,10)}); });
    createAsset({desc:"حاسوب محمول Dell Latitude", serial:"DL-7420-001", value:450000, holderId:dev.id});
    createAsset({desc:"هاتف اختبار Samsung A54", serial:"SM-A546-01", value:180000, holderId:dev.id});
    if(cs) createAsset({desc:"سماعة رأس مركز الاتصال", serial:"HS-22", value:25000, holderId:cs.id});
    // أهداف
    as(dl); addGoal(dev.id,{title:"تسليم واجهة الحجز البرمجية", target:"قبل موعد مرحلة الإصدار التجريبي", weight:50}); addGoal(dev.id,{title:"رفع تغطية الاختبارات الآلية", target:"70% من الشيفرة", weight:30});
    // برنامج تدريبي مقترح لسد فجوة
    as(tr); const pv = createProvider({name:"أكاديمية الخرطوم للتقنية", kind:"جهة خارجية", specialty:"الاختبار والأمن"});
    const p = createProgram({title:"أساسيات اختبار البرمجيات الآلي", kind:"خارجي", providerId:pv.id, skills:["اختبار البرمجيات"], level:2, cost:120000, hours:16, seats:6,
      goal:"خفض العيوب المعاد فتحها ورفع تغطية الاختبارات", linkedDefect:true, nominees:[dev.id, des&&des.id].filter(Boolean)});
    createProgram({title:"التعريف بسياسة الخصوصية وأمن المعلومات", kind:"داخلي", skills:["سياسات الشركة والخصوصية"], level:2, cost:0, hours:3, goal:"التزام كل الموظفين بالسياسة", nominees:s.employees.filter(e=>e.demo).slice(0,8).map(e=>e.id)});
    // محتوى
    if(pr){ as(pr); createContent({title:"البشرى للتكنولوجيا تطلق خدماتها في الخرطوم", channel:"لينكدإن", body:"نعلن عن انطلاق خدماتنا في تطوير التطبيقات والحلول الذكية.", date:new Date(Date.now()+5*864e5).toISOString().slice(0,10), campaign:"الإطلاق"});
      const c0 = s.customers.find(c=>!c.publishConsent); if(c0) createContent({title:"دراسة حالة: " + c0.name, channel:"الموقع", body:"كيف ساعدنا عميلنا في التحول الرقمي.", customerId:c0.id, campaign:"دراسات الحالة"}); }
    // تواصل مع عميل
    const sales = k("sales"); if(sales && s.customers[1]){ as(sales); addInteraction(s.customers[1].id,{kind:"اجتماع", summary:"عرض الخدمات ومناقشة احتياجات نظام المبيعات", next:"إرسال عرض سعر", nextDate:new Date(Date.now()+7*864e5).toISOString().slice(0,10)}); }
    const st = k("staff"); if(st) startOnboarding(st);
    BOS.audit("إضافة بيانات تجريبية للمرحلة الرابعة","training",p.id,"");
  } finally { s.session.userId = saved; BOS.save(); }
}

window.BOS_HR = {ATT, EVAL_CRITERIA, EVAL_STATUS, ASSET_STATUS, NOTE_KINDS, PROGRAM_FLOW, PSTAT, LEVELS, CONTENT_FLOW, CSTAT, INTERACTION_KINDS,
  isHR, isManagerOf, canSee, attOf, checkIn, checkOut, correctAttendance, absenceSweep, monthStats, isWorkday, work,
  period, addGoal, updateGoal, evidence, createEvaluation, acknowledgeEvaluation, approveEvaluation,
  createAsset, issueAsset, returnAsset, custodyOf, addNote, setContract, startOnboarding, startOffboarding, toggleItem,
  reqFor, levelOf, rateSkill, gaps, program, canManageTraining, createProgram, nominate, moveProgram, recordResult, rateProvider, provider, createProvider, certificates, trainingSweep,
  createContent, consentOk, moveContent, addInteraction, setConsent, addSurvey,
  onClosed, onAborted, onEmployeeCreated, onEmployeeDisabled, migrate, metrics, seedHr};
})();
