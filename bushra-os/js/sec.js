/* نظام البشرى لإدارة الشركة — المرحلة الخامسة: الحماية والتوسع
   الخصوصية وطلبات أصحاب البيانات، خطط الاستجابة للحوادث، النسخ الاحتياطي المشفر واختبار الاستعادة،
   مراجعة الصلاحيات، سجلات الأمان، كلمات المرور المحلية، والتكاملات (البريد، الدفع، التوقيع) — القسمان 6.13 و8.2 */
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
const days = n => n*864e5;

/* ---------- مراجع ---------- */
const DSR_KINDS = {access:"طلب اطلاع / نسخة من البيانات", correction:"طلب تصحيح", deletion:"طلب حذف", objection:"اعتراض / تقييد المعالجة"};
const DSR_FLOW = [["received","استلام"],["verifying","التحقق من الهوية"],["in_progress","قيد المعالجة"],["pending_approval","بانتظار الاعتماد"],["responded","تم الرد"],["closed","مغلق"]];
const DSR_STATUS = Object.assign(Object.fromEntries(DSR_FLOW), {rejected:"مرفوض"});
const LEGAL_BASIS = ["تنفيذ عقد","التزام قانوني","موافقة صاحب البيانات","مصلحة مشروعة","مصلحة عامة"];
const INCIDENT_STEPS = [
  ["contain","الاحتواء: عزل النظام أو الحساب المتأثر"],["assess","تقييم النطاق والبيانات المتأثرة"],
  ["eradicate","الإزالة: معالجة السبب (ثغرة، كلمة مرور، إعداد)"],["recover","الاستعادة والتحقق من سلامة الخدمة"],
  ["notify","قرار الإبلاغ (العملاء / الجهات المختصة) وتوثيقه"],["lessons","الدروس المستفادة والإجراء الوقائي"]
];
const SECURITY_ACTIONS = ["تسجيل دخول","تسجيل خروج","انتهاء الجلسة","فشل التحقق الثنائي","فشل كلمة المرور","قفل الحساب","تعيين كلمة مرور","إعادة تعيين كلمة المرور",
  "محاولة وصول مرفوضة","إيقاف حساب وإنهاء وصول","إعادة تفعيل حساب","إيقاف وصول مستخدم غير نشط","تعديل منصب","إنشاء منصب","تعديل بيانات موظف","دعوة موظف",
  "تنبيه أمني: تنزيل ملفات بكميات كبيرة","تنزيل ملف","تصدير سجل التدقيق","تصدير نسخة احتياطية","نسخة احتياطية مشفرة","اختبار استعادة","استعادة نسخة احتياطية",
  "مراجعة صلاحيات","سحب وصول بمراجعة الصلاحيات","تصدير بيانات صاحب طلب","تعديل إعدادات الشركة","تغيير نطاق: تعديل مسار موافقة"];
const isSecurityEvent = a => SECURITY_ACTIONS.some(k=>a.action.startsWith(k)) || /صلاحي|أمني|تصدير|تنزيل/.test(a.action);
const isExportEvent = a => /تصدير|تنزيل|نسخة احتياطية|إصدار نسخة|طباعة/.test(a.action);
const isPermEvent = a => /منصب|صلاحي|إيقاف حساب|إعادة تفعيل|دعوة موظف|مراجعة صلاحيات|سحب وصول|كلمة المرور/.test(a.action) || /تغيير صلاحي/.test(a.details);

/* ---------- ترقية وبذور ---------- */
function migrate(){
  const s = S(); if(!s.company || !s.company.tradeName) return;
  const st = s.settings;
  if(st.dsrDays === undefined) st.dsrDays = 30;
  if(st.backupEveryDays === undefined) st.backupEveryDays = 7;
  if(st.accessReviewDays === undefined) st.accessReviewDays = 90;
  if(st.inactiveDays === undefined) st.inactiveDays = 30;
  if(st.localAuth === undefined) st.localAuth = false;
  if(!st.lockout) st.lockout = {attempts:5, minutes:15};
  if(!st.email) st.email = {enabled:true, from:"no-reply@albushra.tech"};
  if(!st.payment) st.payment = {bank:"", account:"", instructions:"يرجى ذكر مرجع الدفع في التحويل", provider:"none"};
  if(!s.ropa.length) s.ropa = defaultRopa();
  if(!st.classification) st.classification = {"بيانات الموظفين الأساسية":2,"العقود والأجور":4,"التقييمات والملاحظات السرية":4,"الحضور والإجازات":3,"بيانات العملاء وجهات الاتصال":2,"الفواتير والمدفوعات":3,"تذاكر الدعم":2,"الحوادث الأمنية":4,"سجل التدقيق":3,"المحتوى المنشور":1};
}
function defaultRopa(){
  const own = k => (holder(k)||holder("gm")||{}).id || "";
  return [
    ["الموارد البشرية وملف الموظف","الاسم، التواصل، المنصب، العقد والأجر، التقييم","إدارة علاقة العمل والرواتب","الموظف نفسه","الموارد البشرية، المالية","نظام البشرى (المتصفح)","مدة الخدمة + 5 سنوات","تنفيذ عقد",4,"hr"],
    ["الحضور والإجازات","أوقات الحضور والانصراف، الإجازات","تنظيم الدوام واحتساب الإجازات","الموظف","المدير المباشر، الموارد البشرية","نظام البشرى","سنتان","تنفيذ عقد",3,"hr"],
    ["العملاء والعلاقات","اسم الجهة، جهات الاتصال، المراسلات، موافقة النشر","تقديم الخدمة والتواصل","العميل","المبيعات، المشاريع، خدمة العملاء","نظام البشرى","مدة العلاقة + 3 سنوات","تنفيذ عقد",2,"sales"],
    ["الفواتير والتحصيل","بيانات الفوترة، المبالغ، الإيصالات","الالتزامات المالية والمحاسبية","العميل","المالية، المراجع الخارجي","نظام البشرى","10 سنوات","التزام قانوني",3,"cfo"],
    ["خدمة العملاء والدعم","بيانات مقدم البلاغ، وصف المشكلة، الرضا","حل المشكلات وتحسين الجودة","العميل","خدمة العملاء، الجودة، التطوير","نظام البشرى","3 سنوات","مصلحة مشروعة",2,"qm"],
    ["الحوادث الأمنية","سجلات الأنظمة، الحسابات المتأثرة","حماية الأنظمة والبيانات","الأنظمة","الأمن، مدير التقنية، المدير العام","نظام البشرى","5 سنوات","التزام قانوني",4,"secops"],
    ["التدريب والتطوير","المهارات، نتائج التقييم، الشهادات","تطوير كفاءة الموظفين","الموظف والمدرب","التدريب، الموارد البشرية","نظام البشرى","مدة الخدمة","مصلحة مشروعة",2,"training"]
  ].map(r=>({id:BOS.uid("ro"), system:r[0], dataTypes:r[1], purpose:r[2], source:r[3], recipients:r[4], storage:r[5], retention:r[6], basis:r[7], classification:r[8], ownerId:own(r[9]), reviewedAt:now()}));
}

/* ---------- السجل: معالجة البيانات ---------- */
function saveRopa(o){
  const u = me(); if(!BOS.can(u,"privacy","edit") && !BOS.isTop(u)) fail("تعديل سجل المعالجة لمسؤول الأمن أو المدير العام");
  if(!o.system || !o.purpose || !o.basis) fail("النظام والغرض والأساس النظامي إلزامية");
  let r = o.id && S().ropa.find(x=>x.id===o.id);
  const isNew = !r; r = r || {id:BOS.uid("ro")};
  Object.assign(r, {system:o.system, dataTypes:o.dataTypes||"", purpose:o.purpose, source:o.source||"", recipients:o.recipients||"", storage:o.storage||"", retention:o.retention||"", basis:o.basis, classification:Number(o.classification||2), ownerId:o.ownerId||u.id, reviewedAt:now()});
  if(isNew) S().ropa.push(r);
  BOS.audit(isNew?"إضافة نشاط معالجة":"مراجعة نشاط معالجة","privacy",r.id,r.system); BOS.save(); return r;
}

/* ---------- طلبات أصحاب البيانات ---------- */
const canPrivacy = (u,a) => BOS.can(u,"privacy",a) || BOS.isTop(u);
function createDsr(o){
  const u = me(); if(!canPrivacy(u,"create")) fail("لا تملك صلاحية تسجيل طلبات الخصوصية");
  if(!DSR_KINDS[o.kind]) fail("اختر نوع الطلب"); if(!o.subjectName) fail("اسم صاحب البيانات إلزامي");
  const d = {id:BOS.uid("dsr"), no:BOS.nextNo("DSR"), kind:o.kind, subjectType:o.subjectType||"other", subjectRef:o.subjectRef||"", subjectName:o.subjectName,
    contact:o.contact||"", channel:o.channel||"بريد", details:o.details||"", receivedAt:now(), due:new Date(Date.now()+days(Number(S().settings.dsrDays||30))).toISOString().slice(0,10),
    status:"received", handlerId:(holder("secops")||u).id, identityVerified:false, log:[{at:now(), by:u.id, to:"received", note:"استلام عبر " + (o.channel||"بريد")}], response:""};
  S().dsr.unshift(d);
  BOS.audit("استلام طلب صاحب بيانات","privacy",d.id,d.no + " — " + DSR_KINDS[d.kind]);
  if(d.handlerId!==u.id) BOS.notify(d.handlerId,"طلب خصوصية جديد " + d.no + " — الاستحقاق " + d.due,"#/dsr/"+d.id,"task");
  BOS.save(); return d;
}
function dsrLog(d, to, note){ d.log.push({at:now(), by:me().id, from:d.status, to, note:note||""}); d.status = to; }
function verifyIdentity(d, method){
  const u = me(); if(!canPrivacy(u,"edit") && d.handlerId!==u.id) fail("لمسؤول معالجة الطلب");
  if(!method) fail("وثّق طريقة التحقق من الهوية (بطاقة، بريد مسجل، حضور شخصي…)");
  if(!["received","verifying"].includes(d.status)) fail("الطلب تجاوز مرحلة التحقق");
  d.identityVerified = true; d.verifyMethod = method; d.verifiedBy = u.id; d.verifiedAt = now();
  dsrLog(d,"in_progress","تحقق الهوية: " + method);
  BOS.audit("تحقق من هوية صاحب طلب","privacy",d.id,d.no + " — " + method); BOS.save();
}
/* تجميع كل البيانات الشخصية المرتبطة بصاحب الطلب */
function subjectData(d){
  const s = S(); const out = {generatedAt:now(), request:d.no, subject:d.subjectName, sections:{}};
  if(d.subjectType==="employee"){
    const e = BOS.byId(d.subjectRef); if(!e) return out;
    out.sections["الملف الوظيفي"] = {الاسم:e.name, البريد:e.email, الهاتف:e.phone, المنصب:BOS.posTitle(e.positionId), القسم:(BOS.dept(e.deptId)||{}).name, تاريخ_التعيين:e.hireDate, الحالة:e.status};
    out.sections["العقود"] = (e.contracts||[]).map(c=>({الإصدار:c.v, النوع:c.type, البدء:c.start, الانتهاء:c.end, الأجر:c.salary, العملة:c.currency}));
    out.sections["الحضور"] = s.attendance.filter(a=>a.empId===e.id).map(a=>({التاريخ:a.date, الحالة:a.status, الحضور:a.in||"", الانصراف:a.out||""}));
    out.sections["الأهداف"] = s.goals.filter(g=>g.empId===e.id).map(g=>({الفترة:g.period, الهدف:g.title, الوزن:g.weight, التقدم:g.progress}));
    out.sections["التقييمات"] = s.evaluations.filter(v=>v.empId===e.id).map(v=>({الفترة:v.period, الإجمالي:v.overall, المعايير:v.scores, تعليقك:v.employeeComment||""}));
    out.sections["العهد"] = s.assets.filter(a=>a.holderId===e.id || a.lastHolderId===e.id).map(a=>({الرقم:a.no, الوصف:a.desc, الحالة:a.status}));
    out.sections["التدريب"] = s.programs.filter(p=>p.enrollments.some(x=>x.empId===e.id)).map(p=>{ const x = p.enrollments.find(z=>z.empId===e.id); return {البرنامج:p.title, الحضور:x.attended, النتيجة:x.post, الشهادة:x.certNo||""}; });
    out.sections["المهارات"] = s.empSkills[e.id] ? Object.fromEntries(Object.entries(s.empSkills[e.id]).map(([k,v])=>[k,v.level])) : {};
    out.sections["الطلبات التي أنشأها"] = s.requests.filter(r=>r.creatorId===e.id).map(r=>({الرقم:r.no, النوع:(D.TYPES[r.type]||{}).name, الحالة:r.status, التاريخ:r.createdAt.slice(0,10)}));
    out.note = "الملاحظات الداخلية السرية تُستثنى إن كان في كشفها إضرار بحقوق الغير أو بتحقيق جارٍ، ويوثق سبب الاستثناء.";
  }
  if(d.subjectType==="customer"){
    const c = s.customers.find(x=>x.id===d.subjectRef); if(!c) return out;
    out.sections["بيانات العميل"] = {الاسم:c.name, النوع:c.kind, جهة_الاتصال:c.contact, الهاتف:c.phone, البريد:c.email, موافقة_النشر:c.publishConsent};
    out.sections["سجل موافقة النشر"] = (c.consentLog||[]).map(l=>({التاريخ:l.at.slice(0,10), القرار:l.value?"موافقة":"سحب", المصدر:l.evidence}));
    out.sections["التواصل"] = s.interactions.filter(i=>i.customerId===c.id).map(i=>({التاريخ:i.date, النوع:i.kind, الملخص:i.summary}));
    out.sections["الاستبيانات"] = s.surveys.filter(x=>x.customerId===c.id).map(x=>({الرضا:x.score, التوصية:x.nps, التعليق:x.comment}));
    out.sections["التذاكر"] = (s.tickets||[]).filter(t=>t.customerId===c.id).map(t=>({الرقم:t.no, الموضوع:t.subject, الحالة:t.status}));
    out.sections["الفواتير"] = s.invoices.filter(i=>i.customerId===c.id).map(i=>({الرقم:i.no, الحالة:i.status, الإجمالي:BOS.totals(i.items,i.discount,i.taxRate).total}));
  }
  return out;
}
function exportSubject(d){
  const u = me(); if(!d.identityVerified) fail("لا تُسلَّم البيانات قبل التحقق من هوية صاحب الطلب");
  if(!canPrivacy(u,"export") && !canPrivacy(u,"edit")) fail("لا تملك صلاحية التصدير");
  const data = subjectData(d);
  d.exportedAt = now(); d.exportedBy = u.id;
  BOS.audit("تصدير بيانات صاحب طلب","privacy",d.id,d.no + " — " + Object.keys(data.sections).length + " قسم"); BOS.save();
  return data;
}
function correctSubject(d, field, value){
  const u = me(); if(!d.identityVerified) fail("تحقق من الهوية أولاً");
  if(!canPrivacy(u,"edit")) fail("لا تملك صلاحية");
  const allowed = {employee:["name","email","phone"], customer:["name","contact","phone","email"]}[d.subjectType]||[];
  if(!allowed.includes(field)) fail("الحقل غير قابل للتصحيح من هنا");
  const rec = d.subjectType==="employee" ? BOS.byId(d.subjectRef) : S().customers.find(x=>x.id===d.subjectRef);
  if(!rec) fail("السجل غير موجود");
  const before = rec[field]; rec[field] = value;
  (d.corrections = d.corrections||[]).push({field, before, after:value, at:now(), by:u.id});
  BOS.audit("تصحيح بيانات بطلب صاحبها","privacy",d.id,d.no + " — الحقل: " + field); BOS.save();
}
/* الحذف = إخفاء الهوية مع الإبقاء على ما يلزم الاحتفاظ به نظاماً */
function deletionCheck(d){
  const s = S(); const holds = [], keeps = [];
  if(d.subjectType==="employee"){
    const e = BOS.byId(d.subjectRef); if(!e) return {holds:["السجل غير موجود"], keeps};
    if(BOS.active(e)) holds.push("الموظف ما زال على رأس العمل — تُحذف البيانات بعد انتهاء العلاقة");
    if(s.assets.some(a=>a.holderId===e.id && a.status==="issued")) holds.push("لديه عهد غير مسلمة");
    if(s.requests.some(r=>r.creatorId===e.id && ["in_review","executing"].includes(r.status))) holds.push("لديه طلبات مفتوحة");
    keeps.push("العقود والمستحقات المالية (التزام قانوني)","سجل التدقيق (غير قابل للتعديل)","القرارات والموافقات التي اتخذها (بالاسم المستعار)");
  }
  if(d.subjectType==="customer"){
    const c = s.customers.find(x=>x.id===d.subjectRef); if(!c) return {holds:["السجل غير موجود"], keeps};
    const openInv = s.invoices.filter(i=>i.customerId===c.id && !["paid","cancelled","draft"].includes(BOS.invoiceState(i)));
    if(openInv.length) holds.push("فواتير غير مسددة: " + openInv.length);
    if((s.projects||[]).some(p=>p.customerId===c.id && p.status!=="closed")) holds.push("مشاريع مفتوحة");
    keeps.push("الفواتير والإيصالات (10 سنوات — التزام قانوني)","العقود","سجل التدقيق (غير قابل للتعديل)");
  }
  if(d.subjectType==="other") holds.push("اربط الطلب بسجل موظف أو عميل لتنفيذ الحذف");
  return {holds, keeps};
}
function proposeDeletion(d, note){
  const u = me(); if(d.kind!=="deletion") fail("ليس طلب حذف"); if(!d.identityVerified) fail("تحقق من الهوية أولاً");
  if(!canPrivacy(u,"edit") && d.handlerId!==u.id) fail("لمسؤول معالجة الطلب");
  const c = deletionCheck(d); if(c.holds.length) fail("لا يمكن الحذف الآن: " + c.holds.join(" · "));
  d.proposedBy = u.id; d.proposalNote = note||""; dsrLog(d,"pending_approval","اقتراح إخفاء الهوية");
  BOS.audit("اقتراح حذف بيانات","privacy",d.id,d.no);
  const ap = holder("legal") || holder("gm"); if(ap && ap.id!==u.id) BOS.notify(ap.id,"طلب حذف بيانات بانتظار اعتمادك: " + d.no,"#/dsr/"+d.id,"task");
  BOS.save();
}
function approveDeletion(d){
  const u = me(); if(d.status!=="pending_approval") fail("الطلب ليس بانتظار الاعتماد");
  if(!canPrivacy(u,"approve")) fail("اعتماد الحذف للمراجع القانوني أو المدير العام");
  if(u.id===d.proposedBy) fail("لا يعتمد مقترح الحذف اقتراحه — فصل الصلاحيات");
  const c = deletionCheck(d); if(c.holds.length) fail("ظهر مانع جديد: " + c.holds.join(" · "));
  const s = S(); const tag = "#" + d.no.slice(-4);
  if(d.subjectType==="employee"){
    const e = BOS.byId(d.subjectRef);
    Object.assign(e, {name:"موظف سابق " + tag, email:"", phone:"", anonymized:true, anonymizedAt:now()});
    s.hrNotes = s.hrNotes.filter(n=>n.empId!==e.id);
    s.goals.filter(g=>g.empId===e.id).forEach(g=>{ g.updates = []; });
    s.evaluations.filter(v=>v.empId===e.id).forEach(v=>{ v.strengths = v.improvements = v.employeeComment = ""; });
    delete s.empSkills[e.id]; if(e.auth) delete e.auth;
  }
  if(d.subjectType==="customer"){
    const cu = s.customers.find(x=>x.id===d.subjectRef);
    Object.assign(cu, {name:"عميل محذوف " + tag, contact:"", phone:"", email:"", notes:"", anonymized:true, anonymizedAt:now()});
    s.interactions.filter(i=>i.customerId===cu.id).forEach(i=>{ i.summary = "[حُذف بطلب صاحب البيانات]"; i.next = ""; });
    s.surveys.filter(x=>x.customerId===cu.id).forEach(x=>{ x.comment = ""; });
  }
  d.approvedBy = u.id; d.approvedAt = now(); d.response = "أُخفيت هوية صاحب البيانات. احتُفظ بما يلزم نظاماً: " + c.keeps.join("، ");
  dsrLog(d,"responded","تنفيذ إخفاء الهوية");
  // لا نكتب الاسم في سجل التدقيق — رقم الطلب فقط
  BOS.audit("تنفيذ حذف / إخفاء هوية","privacy",d.id,d.no + " — " + (d.subjectType==="employee"?"موظف":"عميل"));
  BOS.save();
}
function respondDsr(d, response){
  const u = me(); if(!canPrivacy(u,"edit") && d.handlerId!==u.id) fail("لمسؤول معالجة الطلب");
  if(!d.identityVerified) fail("تحقق من الهوية أولاً");
  if(!response) fail("اكتب الرد المرسل لصاحب الطلب");
  if(d.kind==="access" && !d.exportedAt) fail("أعد نسخة البيانات أولاً");
  if(d.kind==="correction" && !(d.corrections||[]).length) fail("سجّل التصحيح أولاً");
  if(d.kind==="deletion") fail("طلب الحذف يُنفذ عبر الاقتراح والاعتماد");
  d.response = response; dsrLog(d,"responded",response.slice(0,80));
  BOS.audit("الرد على طلب صاحب بيانات","privacy",d.id,d.no); BOS.save();
}
function rejectDsr(d, reason){
  const u = me(); if(!canPrivacy(u,"approve") && !canPrivacy(u,"edit")) fail("لا تملك صلاحية");
  if(!reason) fail("سبب الرفض إلزامي ويُبلَّغ لصاحب الطلب");
  d.response = reason; dsrLog(d,"rejected",reason); BOS.audit("رفض طلب صاحب بيانات","privacy",d.id,d.no + " — " + reason); BOS.save();
}
function closeDsr(d){ if(d.status!=="responded") fail("يُغلق الطلب بعد الرد"); dsrLog(d,"closed",""); d.closedAt = now(); BOS.audit("إغلاق طلب خصوصية","privacy",d.id,d.no + (d.closedAt.slice(0,10) > d.due ? " — بعد المهلة" : " — ضمن المهلة")); BOS.save(); }
function dsrSweep(){
  let n = 0;
  for(const d of S().dsr){ if(["closed","rejected","responded"].includes(d.status) || d.overdueNotified) continue;
    if(d.due < today()){ d.overdueNotified = true; n++; BOS.notify(d.handlerId,"طلب خصوصية تجاوز المهلة: " + d.no,"#/dsr/"+d.id,"bad"); const g = holder("gm"); if(g) BOS.notify(g.id,"طلب خصوصية متأخر: " + d.no,"#/dsr/"+d.id,"bad"); } }
  if(n) BOS.save(); return n;
}

/* ---------- خطة الاستجابة للحادث ---------- */
function plan(r){
  const s = S();
  if(!s.incidentPlans[r.id]) s.incidentPlans[r.id] = {steps:INCIDENT_STEPS.map(([k,l])=>({key:k, label:l, done:false, note:""})), personalData:!!r.data.sensitive, notify:"", lessons:""};
  return s.incidentPlans[r.id];
}
function canWorkIncident(u, r){ return BOS.canSeeRequest(u,r) && (BOS.can(u,"security","edit") || BOS.isTop(u) || (BOS.currentStep(r)||{}).assigneeId===u.id); }
function updateStep(r, key, o){
  const u = me(); if(!canWorkIncident(u,r)) fail("لفريق الاستجابة للحادث");
  const p = plan(r); const st = p.steps.find(x=>x.key===key); if(!st) fail("خطوة غير معروفة");
  if(o.done && !o.note && !st.note) fail("وثّق ما تم في هذه الخطوة");
  if(key==="notify" && o.done && !o.decision) fail("حدد قرار الإبلاغ");
  if(key==="notify" && o.decision) p.notify = o.decision;
  if(key==="lessons" && o.note) p.lessons = o.note;
  st.done = !!o.done; if(o.note) st.note = o.note; st.at = now(); st.by = u.id;
  BOS.audit("خطة استجابة: " + (st.done?"إتمام ":"تحديث ") + st.label.split(":")[0],"security",r.id,r.no); BOS.save();
}
/* يُستدعى من محرك الموافقات قبل إتمام مرحلة: لا يُغلق الحادث قبل اكتمال خطة الاستجابة */
function beforeComplete(r, st){
  if(r.type==="incident" && st.stage==="close"){
    const p = plan(r); const open = p.steps.filter(x=>!x.done);
    if(open.length) return "لا يُغلق الحادث قبل اكتمال خطة الاستجابة: " + open.map(x=>x.label.split(":")[0]).join("، ");
    if(p.personalData && !p.notify) return "الحادث يمس بيانات شخصية — وثّق قرار الإبلاغ";
  }
  return "";
}

/* ---------- كلمات المرور المحلية (PBKDF2) ---------- */
const hex = buf => Array.from(new Uint8Array(buf)).map(b=>b.toString(16).padStart(2,"0")).join("");
const unhex = h => new Uint8Array(h.match(/.{2}/g).map(x=>parseInt(x,16)));
async function pbkdf2(pw, saltHex, iter){
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(pw), "PBKDF2", false, ["deriveBits"]);
  return hex(await crypto.subtle.deriveBits({name:"PBKDF2", salt:unhex(saltHex), iterations:iter, hash:"SHA-256"}, key, 256));
}
const needsPassword = e => !!S().settings.localAuth;
const hasPassword = e => !!(e.auth && e.auth.hash);
function lockedFor(e){ const l = e.auth && e.auth.lockedUntil; return l && new Date(l) > new Date() ? Math.ceil((new Date(l)-Date.now())/60000) : 0; }
function passwordRules(pw){
  if(!pw || pw.length < 8) return "كلمة المرور 8 أحرف على الأقل";
  if(!/[0-9]/.test(pw) || !/[^0-9]/.test(pw)) return "استخدم أرقاماً وحروفاً معاً";
  return "";
}
async function setPassword(e, pw){
  const r = passwordRules(pw); if(r) fail(r);
  const salt = hex(crypto.getRandomValues(new Uint8Array(16)));
  e.auth = {hash: await pbkdf2(pw, salt, 150000), salt, iter:150000, setAt:now(), failures:0, lockedUntil:null};
  BOS.audit("تعيين كلمة مرور","session",e.id,e.name,e.id); BOS.save();
}
async function checkPassword(e, pw){
  const m = lockedFor(e); if(m) fail("الحساب مقفل مؤقتاً بعد محاولات فاشلة — حاول بعد " + m + " دقيقة");
  const ok = (await pbkdf2(pw||"", e.auth.salt, e.auth.iter)) === e.auth.hash;
  if(ok){ e.auth.failures = 0; e.auth.lockedUntil = null; BOS.save(); return true; }
  e.auth.failures = (e.auth.failures||0) + 1;
  const L = S().settings.lockout;
  BOS.audit("فشل كلمة المرور","session",e.id,e.name + " — المحاولة " + e.auth.failures,e.id);
  if(e.auth.failures >= L.attempts){ e.auth.lockedUntil = new Date(Date.now()+L.minutes*60000).toISOString(); e.auth.failures = 0;
    BOS.audit("قفل الحساب","session",e.id,e.name + " — " + L.minutes + " دقيقة",e.id);
    const sec = holder("secops"); if(sec) BOS.notify(sec.id,"قُفل حساب " + e.name + " بعد " + L.attempts + " محاولات فاشلة","#/security/log","bad"); }
  BOS.save();
  fail(e.auth.lockedUntil ? "قُفل الحساب " + L.minutes + " دقيقة بعد محاولات فاشلة متتالية" : "كلمة المرور غير صحيحة");
}
function resetPassword(e){
  const u = me(); if(!(BOS.can(u,"people","manage") || BOS.isTop(u) || posKey(u)==="secops")) fail("إعادة التعيين للموارد البشرية أو الأمن");
  if(e.id===u.id) fail("لا تعيد تعيين كلمة مرورك بهذه الطريقة");
  delete e.auth; BOS.audit("إعادة تعيين كلمة المرور","session",e.id,e.name + " — يعيّنها المستخدم عند الدخول التالي"); BOS.save();
}

/* ---------- النسخ الاحتياطي المشفر واختبار الاستعادة ---------- */
const b64 = buf => { let s = ""; const b = new Uint8Array(buf); for(let i=0;i<b.length;i+=0x8000) s += String.fromCharCode.apply(null, b.subarray(i,i+0x8000)); return btoa(s); };
const unb64 = t => Uint8Array.from(atob(t), c=>c.charCodeAt(0));
async function aesKey(pass, salt){
  const base = await crypto.subtle.importKey("raw", new TextEncoder().encode(pass), "PBKDF2", false, ["deriveKey"]);
  return crypto.subtle.deriveKey({name:"PBKDF2", salt, iterations:200000, hash:"SHA-256"}, base, {name:"AES-GCM", length:256}, false, ["encrypt","decrypt"]);
}
async function sha256(t){ return hex(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(t))); }
function snapshot(){ return JSON.stringify(Object.assign({}, S(), {session:null})); }
async function encryptedBackup(pass){
  const u = me(); if(!BOS.can(u,"security","export") && !BOS.isTop(u)) fail("النسخ الاحتياطي لمسؤول الأمن أو المدير العام");
  const r = passwordRules(pass); if(r) fail("عبارة التشفير: " + r);
  const plain = snapshot(); const salt = crypto.getRandomValues(new Uint8Array(16)), iv = crypto.getRandomValues(new Uint8Array(12));
  const ct = await crypto.subtle.encrypt({name:"AES-GCM", iv}, await aesKey(pass, salt), new TextEncoder().encode(plain));
  const hash = await sha256(plain);
  const pkg = JSON.stringify({format:"bushra-os-backup-enc-1", company:S().company.tradeName, createdAt:now(), sha256:hash, salt:b64(salt), iv:b64(iv), data:b64(ct)});
  const rec = {id:BOS.uid("bk"), no:BOS.nextNo("BKP"), at:now(), by:u.id, kind:"مشفرة AES-256-GCM", size:pkg.length, sha256:hash, auditCount:S().audit.length, restoreTested:false};
  S().backups.unshift(rec);
  BOS.audit("نسخة احتياطية مشفرة","security",rec.id,rec.no + " — " + Math.round(pkg.length/1024) + " ك.ب — بصمة " + hash.slice(0,12)); BOS.save();
  return {pkg, rec};
}
async function openBackup(text, pass){
  let o; try{ o = JSON.parse(text); }catch(e){ fail("الملف ليس نسخة احتياطية صالحة"); }
  let plain;
  if(o.format==="bushra-os-backup-enc-1"){
    if(!pass) fail("النسخة مشفرة — أدخل عبارة التشفير");
    try{ plain = new TextDecoder().decode(await crypto.subtle.decrypt({name:"AES-GCM", iv:unb64(o.iv)}, await aesKey(pass, unb64(o.salt)), unb64(o.data))); }
    catch(e){ fail("تعذر فك التشفير: عبارة خاطئة أو ملف معدّل"); }
    if(await sha256(plain) !== o.sha256) fail("بصمة المحتوى لا تطابق — الملف تالف");
  } else plain = text;
  const st = JSON.parse(plain);
  if(!st.company || !Array.isArray(st.audit)) fail("الملف لا يحتوي بيانات شركة");
  return {state:st, sha:o.sha256 || await sha256(plain)};
}
/* اختبار الاستعادة: فك التشفير والتحقق من سلسلة التدقيق دون المساس بالبيانات الحالية */
async function testRestore(text, pass){
  const u = me();
  const {state, sha} = await openBackup(text, pass);
  let prev = "GENESIS", ok = true, at = null;
  for(const ev of state.audit){ const h = BOS.hash(prev + "|" + BOS.stable(Object.assign({}, ev, {hash:undefined}))); if(ev.prev!==prev || ev.hash!==h){ ok = false; at = ev.seq; break; } prev = ev.hash; }
  const result = {ok, brokenAt:at, company:state.company.tradeName, employees:(state.employees||[]).length, requests:(state.requests||[]).length, documents:(state.documents||[]).length, invoices:(state.invoices||[]).length, audit:state.audit.length};
  const rec = S().backups.find(b=>b.sha256===sha);
  if(rec){ rec.restoreTested = ok; rec.testAt = now(); rec.testBy = u.id; }
  BOS.audit("اختبار استعادة","security",rec?rec.id:null,(rec?rec.no:"نسخة خارجية") + " — " + (ok?"ناجح":"فشل: سلسلة التدقيق مكسورة عند " + at) + " — " + result.audit + " حدث"); BOS.save();
  return result;
}
async function applyRestore(text, pass){
  const u = me(); if(!BOS.isTop(u)) fail("الاستعادة الفعلية للمدير العام فقط");
  const {state} = await openBackup(text, pass);
  const who = {id:u.id, name:u.name};
  localStorage.setItem("bushra-os-v1", JSON.stringify(Object.assign(state,{session:null})));
  BOS.load();
  BOS.audit("استعادة نسخة احتياطية","security",null,"نفذها " + who.name + " — " + state.audit.length + " حدث",null); BOS.save();
}
function backupDue(){
  const last = S().backups[0]; const every = Number(S().settings.backupEveryDays||7);
  const age = last ? (Date.now()-new Date(last.at))/864e5 : Infinity;
  return {last, age, overdue: age > every, untested: S().backups.filter(b=>!b.restoreTested).length};
}
function backupSweep(){
  const b = backupDue(); const s = S(); const d = today();
  if(b.overdue && s.settings.backupReminded !== d){ s.settings.backupReminded = d;
    [holder("secops"), holder("gm")].filter(Boolean).forEach(x=>BOS.notify(x.id, b.last ? "آخر نسخة احتياطية قبل " + Math.floor(b.age) + " يوماً — السياسة كل " + s.settings.backupEveryDays + " أيام" : "لم تُنشأ أي نسخة احتياطية بعد","#/security/backups","warn"));
    BOS.save(); return 1; }
  return 0;
}

/* ---------- مراجعة الصلاحيات والحسابات غير النشطة ---------- */
function lastLogin(empId){ const a = S().audit; for(let i=a.length-1;i>=0;i--){ if(a[i].action==="تسجيل دخول" && a[i].actorId===empId) return a[i].at; } return null; }
function accessFlags(e){
  const f = []; const p = BOS.pos(e.positionId)||{}; const ll = lastLogin(e.id);
  const inact = Number(S().settings.inactiveDays||30);
  if(!ll) f.push("لم يسجل دخولاً قط"); else if((Date.now()-new Date(ll))/864e5 > inact) f.push("غير نشط منذ " + Math.floor((Date.now()-new Date(ll))/864e5) + " يوماً");
  if(e.validTo && e.validTo < today()) f.push("انتهت صلاحية الحساب");
  if((p.clearance||0) >= 4 && !["gm","owner","hr","secops"].includes(p.key)) f.push("مستوى سرية أعلى من المعتاد");
  if(Object.values(p.perms||{}).some(a=>a.includes("manage")) && !["gm","owner","hr","records","secops","training","pr","cs","testlead","qm"].includes(p.key)) f.push("صلاحية إدارة");
  if(e.permsOverride && Object.keys(e.permsOverride).length) f.push("صلاحيات مخصصة للشخص");
  if(p.mfa && S().settings.mfa===false) f.push("منصب حساس دون MFA");
  return f;
}
function startReview(){
  const u = me(); if(!BOS.can(u,"security","edit") && !BOS.isTop(u)) fail("مراجعة الصلاحيات لمسؤول الأمن أو المدير العام");
  if(S().accessReviews.some(r=>!r.closedAt)) fail("توجد مراجعة مفتوحة — أكملها أولاً");
  const items = S().employees.filter(BOS.active).map(e=>({empId:e.id, position:BOS.posTitle(e.positionId), flags:accessFlags(e), decision:"", note:""}));
  const r = {id:BOS.uid("ar"), no:BOS.nextNo("ACR"), at:now(), by:u.id, items};
  S().accessReviews.unshift(r);
  BOS.audit("مراجعة صلاحيات: بدء","security",r.id,r.no + " — " + items.length + " حساب، " + items.filter(i=>i.flags.length).length + " بملاحظات"); BOS.save(); return r;
}
function decide(r, empId, decision, note){
  const u = me(); if(r.closedAt) fail("المراجعة مغلقة");
  const it = r.items.find(i=>i.empId===empId); if(!it) fail("غير موجود");
  if(!["keep","revoke"].includes(decision)) fail("قرار غير صالح");
  if(decision==="revoke" && !note) fail("سبب سحب الوصول إلزامي");
  if(empId===u.id && decision==="revoke") fail("لا تسحب وصولك بنفسك");
  it.decision = decision; it.note = note||""; it.by = u.id; it.at = now(); BOS.save();
}
function closeReview(r){
  const u = me(); if(r.items.some(i=>!i.decision)) fail("قرر لكل حساب: إبقاء أو سحب (" + r.items.filter(i=>!i.decision).length + " متبقٍ)");
  for(const it of r.items.filter(i=>i.decision==="revoke")){
    const e = BOS.byId(it.empId); if(!e || !BOS.active(e)) continue;
    e.status = "disabled"; e.disabledAt = now(); e.disableReason = "مراجعة الصلاحيات " + r.no + ": " + it.note;
    BOS.audit("سحب وصول بمراجعة الصلاحيات","employee",e.id,e.name + " — " + it.note);
    if(window.BOS_HR) BOS_HR.onEmployeeDisabled(e, e.disableReason);
  }
  r.closedAt = now(); r.closedBy = u.id;
  BOS.audit("مراجعة صلاحيات: إغلاق","security",r.id,r.no + " — سُحب وصول " + r.items.filter(i=>i.decision==="revoke").length); BOS.save();
}
function reviewDue(){ const last = S().accessReviews.find(r=>r.closedAt); const every = Number(S().settings.accessReviewDays||90);
  return {last, overdue: !last || (Date.now()-new Date(last.closedAt))/864e5 > every}; }

/* ---------- سجلات الأمان ---------- */
function securityLog(){ return S().audit.filter(isSecurityEvent).slice().reverse(); }
function anomalies(){
  const a = S().audit; const out = [];
  const by = {}; a.filter(x=>/فشل (التحقق الثنائي|كلمة المرور)/.test(x.action)).forEach(x=>{ const k = x.actorId + "|" + x.at.slice(0,10); by[k] = (by[k]||0)+1; });
  Object.entries(by).filter(([k,n])=>n>=3).forEach(([k,n])=>{ const [id,d] = k.split("|"); out.push({kind:"bad", text:"محاولات دخول فاشلة ×" + n + " — " + ((BOS.byId(id)||{}).name||"") + " — " + d}); });
  a.filter(x=>x.action.startsWith("تنبيه أمني")).slice(-5).forEach(x=>out.push({kind:"bad", text:x.actorName + ": " + x.details}));
  const denied = a.filter(x=>x.action==="محاولة وصول مرفوضة" && (Date.now()-new Date(x.at))<days(7));
  if(denied.length) out.push({kind:"warn", text:"محاولات وصول مرفوضة خلال 7 أيام: " + denied.length});
  a.filter(x=>x.action==="قفل الحساب").slice(-5).forEach(x=>out.push({kind:"bad", text:"قفل حساب: " + x.details}));
  return out;
}

/* ---------- التكاملات: البريد (صندوق صادر)، الدفع، التوقيع ---------- */
/* لا ترسل البيانات السرية كاملة في البريد — رابط آمن مع ملخص محدود (القسم 10) */
const CONFIDENTIAL_LINK = /#\/(dsr|security|mail)|#\/person\//;
function onNotify(n){
  const s = S(); if(!s.settings.email || !s.settings.email.enabled) return;
  const e = BOS.byId(n.userId); if(!e || !e.email) return;
  let confidential = CONFIDENTIAL_LINK.test(n.link||"");
  const m = /#\/request\/(\w+)/.exec(n.link||""); if(m){ const r = s.requests.find(x=>x.id===m[1]); if(r && (D.TYPES[r.type]||{}).confidential) confidential = true; }
  if(/ملفك|تقييم|سري|جزاء|إنذار/.test(n.text)) confidential = true;
  s.outbox.unshift({id:BOS.uid("em"), at:now(), to:e.email, from:s.settings.email.from, notificationId:n.id, confidential,
    subject: confidential ? "لديك إشعار جديد في " + s.company.tradeName : n.text.slice(0,70),
    body: "مرحباً " + e.name.split(" ")[0] + "،\n\n" + (confidential ? "لديك إشعار جديد يتطلب الاطلاع داخل النظام. لا تُرسل تفاصيله عبر البريد." : n.text.slice(0,140)) + "\n\nافتح النظام عبر الرابط الآمن بعد تسجيل الدخول:\n" + (location.origin + location.pathname) + (n.link||"#/notifications") + "\n\nهذه رسالة آلية — لا ترد عليها.",
    status:"جاهزة للإرسال"});
  if(s.outbox.length > 400) s.outbox.length = 400;
}
function paymentRef(inv){
  const digits = inv.no.replace(/\D/g,"");
  let r = 0; for(const ch of digits) r = (r*10 + Number(ch)) % 97;
  return inv.no + "-" + String(98 - (r*100 % 97)).padStart(2,"0");
}
function verifyPaymentRef(ref){ const m = /^(.*)-(\d{2})$/.exec(ref||""); if(!m) return false; return paymentRef({no:m[1]}) === ref; }
async function sign(entity, entityId, version, content, image){
  const u = me(); if(!image || image.length < 200) fail("ارسم توقيعك أولاً");
  const hash = await sha256(entity + "|" + entityId + "|" + version + "|" + content);
  if(S().signatures.some(x=>x.entity===entity && x.entityId===entityId && x.version===version && x.signerId===u.id)) fail("وقّعت هذا الإصدار مسبقاً");
  const sg = {id:BOS.uid("sg"), entity, entityId, version, signerId:u.id, signerName:u.name, position:BOS.posTitle(u.positionId), image, hash, at:now()};
  S().signatures.push(sg);
  BOS.audit("توقيع إلكتروني داخلي","signature",sg.id,entity + " " + entityId.slice(-6) + " إ" + version + " — بصمة " + hash.slice(0,12)); BOS.save(); return sg;
}
const signaturesOf = (entity, entityId, version) => S().signatures.filter(x=>x.entity===entity && x.entityId===entityId && (version==null || x.version===version));
async function verifySignature(sg, content){ return (await sha256(sg.entity + "|" + sg.entityId + "|" + sg.version + "|" + content)) === sg.hash; }

/* ---------- مؤشرات ---------- */
function metrics(){
  const s = S(); const b = backupDue(); const rv = reviewDue();
  const openDsr = s.dsr.filter(d=>!["closed","rejected"].includes(d.status));
  const closed = s.dsr.filter(d=>d.closedAt);
  return {openDsr:openDsr.length, lateDsr:openDsr.filter(d=>d.due<today()).length, dsrOnTime: closed.length ? Math.round(closed.filter(d=>d.closedAt.slice(0,10)<=d.due).length/closed.length*100) : null,
    backupAge: b.last ? Math.floor(b.age) : null, backupOverdue:b.overdue, untested:b.untested, reviewOverdue:rv.overdue, lastReview: rv.last ? rv.last.closedAt : null,
    inactive: s.employees.filter(BOS.active).filter(e=>accessFlags(e).some(f=>/غير نشط|لم يسجل/.test(f))).length,
    openIncidents: s.requests.filter(r=>r.type==="incident" && !["closed","rejected","cancelled"].includes(r.status)).length,
    anomalies: anomalies().length, noPassword: s.settings.localAuth ? s.employees.filter(e=>BOS.active(e) && !hasPassword(e)).length : null,
    outbox: s.outbox.length};
}

/* ---------- بيانات تجريبية ---------- */
function seedSec(){
  const s = S(); migrate();
  const k = key => s.employees.find(e=>BOS.active(e) && posKey(e)===key);
  const cs = k("cs"), sec = k("secops"), sales = k("sales"); if(!cs || !sec) return;
  const saved = s.session.userId;
  try{
    s.session.userId = cs.id;
    const c = s.customers[2];
    if(c) createDsr({kind:"access", subjectType:"customer", subjectRef:c.id, subjectName:c.name, contact:"عمادة التقنية", channel:"بريد", details:"طلب نسخة من البيانات المحفوظة عن الجامعة وجهات الاتصال"});
    // حادث أمني تجريبي بخطة استجابة
    if(sales){ s.session.userId = sales.id;
      const r = BOS.createRequest("incident",{severity:"متوسطة", system:"البريد الإلكتروني", details:"رسالة تصيد تطلب تحديث كلمة المرور وصلت لفريق المبيعات", sensitive:false},{title:"حادث أمني — رسالة تصيد"});
      plan(r).steps[0].done = true; plan(r).steps[0].note = "حُظر المرسل وحُذفت الرسالة من الصناديق"; plan(r).steps[0].by = sec.id; plan(r).steps[0].at = now(); }
  } finally { s.session.userId = saved; BOS.save(); }
}

window.BOS_SEC = {DSR_KINDS, DSR_FLOW, DSR_STATUS, LEGAL_BASIS, INCIDENT_STEPS, isSecurityEvent, isExportEvent, isPermEvent,
  migrate, saveRopa, canPrivacy, createDsr, verifyIdentity, subjectData, exportSubject, correctSubject, deletionCheck, proposeDeletion, approveDeletion, respondDsr, rejectDsr, closeDsr, dsrSweep,
  plan, canWorkIncident, updateStep, beforeComplete,
  needsPassword, hasPassword, lockedFor, passwordRules, setPassword, checkPassword, resetPassword,
  encryptedBackup, openBackup, testRestore, applyRestore, backupDue, backupSweep, snapshot,
  lastLogin, accessFlags, startReview, decide, closeReview, reviewDue, securityLog, anomalies,
  onNotify, paymentRef, verifyPaymentRef, sign, signaturesOf, verifySignature, metrics, seedSec};
})();
