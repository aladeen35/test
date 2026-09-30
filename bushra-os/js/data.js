/* نظام البشرى لإدارة الشركة — البيانات المرجعية الافتراضية
   (المناصب، الأقسام، الوحدات، أنواع المعاملات، مسارات الموافقة) */
(function(){
"use strict";

/* الوحدات وأفعال الصلاحيات (القسم 8.1) */
const MODULES = [
  {key:"dashboard",  name:"لوحة المدير العام",        icon:"📊", core:false},
  {key:"org",        name:"الهيكل التنظيمي",          icon:"🏢", core:true},
  {key:"people",     name:"الموظفون والموارد البشرية", icon:"👥", core:true},
  {key:"requests",   name:"الطلبات والمعاملات",       icon:"📨", core:true},
  {key:"documents",  name:"المستندات والإصدارات",     icon:"📁", core:true},
  {key:"customers",  name:"العملاء والعلاقات العامة", icon:"🤝", core:false},
  {key:"finance",    name:"المالية والفواتير",        icon:"💳", core:false},
  {key:"projects",   name:"المشاريع والإنتاج",        icon:"🗂️", core:false},
  {key:"testing",    name:"الاختبار والعيوب",         icon:"🧪", core:false},
  {key:"quality",    name:"الجودة وضمان الجودة",      icon:"🏅", core:false},
  {key:"support",    name:"خدمة العملاء والدعم الفني", icon:"🎧", core:false},
  {key:"training",   name:"التدريب والتطوير",         icon:"🎓", core:false},
  {key:"content",    name:"العلاقات العامة والمحتوى", icon:"📣", core:false},
  {key:"privacy",    name:"الخصوصية وحماية البيانات", icon:"🔏", core:false},
  {key:"security",   name:"الأمن والنسخ الاحتياطي",   icon:"🛡", core:false},
  {key:"policies",   name:"مسارات الموافقة",          icon:"🔀", core:true},
  {key:"audit",      name:"سجل التدقيق",              icon:"🛡️", core:true},
  {key:"settings",   name:"إعدادات الشركة",           icon:"⚙️", core:true}
];
const ACTIONS = [
  ["create","إنشاء"],["view","عرض"],["edit","تعديل"],["comment","تعليق"],
  ["approve","اعتماد"],["reject","رفض"],["delete","حذف منطقي"],["export","تصدير"],
  ["share","مشاركة"],["print","طباعة"],["stamp","ختم/إصدار"],["manage","إدارة الصلاحيات"]
];
const SCOPES = {company:"الشركة كاملة", dept:"القسم", project:"المشروع", record:"السجلات المحددة فقط"};
const CLEARANCE = {1:"عام", 2:"داخلي", 3:"سري", 4:"سري للغاية"};

/* الأقسام الافتراضية (القسم 5) */
const DEPARTMENTS = [
  {key:"board",    name:"المالك / مجلس الشركاء", parent:null},
  {key:"mgmt",     name:"الإدارة العامة",        parent:"board"},
  {key:"ops",      name:"العمليات",              parent:"mgmt"},
  {key:"finance",  name:"المالية",               parent:"mgmt"},
  {key:"tech",     name:"التقنية",               parent:"mgmt"},
  {key:"hr",       name:"الموارد البشرية",       parent:"mgmt"},
  {key:"projects", name:"المشاريع والإنتاج",      parent:"ops"},
  {key:"quality",  name:"الجودة وضمان الجودة",    parent:"ops"},
  {key:"cs",       name:"خدمة العملاء والدعم",    parent:"quality"},
  {key:"testing",  name:"الاختبار وضبط الجودة",   parent:"quality"},
  {key:"pr",       name:"العلاقات العامة والتسويق", parent:"ops"},
  {key:"sales",    name:"المبيعات وتطوير الأعمال", parent:"ops"},
  {key:"dev",      name:"التطوير",               parent:"tech"},
  {key:"security", name:"الأمن والبنية التحتية",  parent:"tech"},
  {key:"accounts", name:"المحاسبة والمشتريات",    parent:"finance"},
  {key:"training", name:"التدريب والتطوير",       parent:"hr"},
  {key:"records",  name:"الملفات والسجلات",       parent:"mgmt"}
];

/* صلاحيات مختصرة: all = كل الأفعال */
const ALL = ACTIONS.map(a=>a[0]);
const BASE = {requests:["create","view","comment"], documents:["view","comment"], org:["view"]};
function P(extra){ const o = JSON.parse(JSON.stringify(BASE)); for(const k in extra){ o[k] = extra[k]==="all" ? ALL.slice() : Array.from(new Set([...(o[k]||[]), ...extra[k]])); } return o; }
const EVERY = Object.fromEntries(MODULES.map(m=>[m.key,"all"]));

/* المناصب الافتراضية (القسم 4.3) — reportsTo يحدد التسلسل */
const POSITIONS = [
  {key:"owner",   title:"المالك / مجلس الشركاء",           dept:"board",    reportsTo:null,     level:0, scope:"company", clearance:4, mfa:true,  perms:P(EVERY)},
  {key:"gm",      title:"المدير العام",                     dept:"mgmt",     reportsTo:"owner",  level:1, scope:"company", clearance:4, mfa:true,  perms:P(EVERY)},
  {key:"coo",     title:"مدير العمليات",                    dept:"ops",      reportsTo:"gm",     level:2, scope:"dept",    clearance:3, mfa:false, perms:P({dashboard:["view"],customers:["create","view","edit","export"],documents:["create","edit","print"],people:["view"],policies:["view"]})},
  {key:"cfo",     title:"المدير المالي",                    dept:"finance",  reportsTo:"gm",     level:2, scope:"dept",    clearance:3, mfa:true,  perms:P({dashboard:["view"],finance:"all",customers:["view","edit","export"],documents:["create","edit","print","export"],policies:["view"]})},
  {key:"hr",      title:"مدير الموارد البشرية",             dept:"hr",       reportsTo:"gm",     level:2, scope:"company", clearance:4, mfa:true,  perms:P({people:"all",documents:["create","edit","print","export"],policies:["view"]})},
  {key:"cto",     title:"مدير التقنية",                     dept:"tech",     reportsTo:"gm",     level:2, scope:"dept",    clearance:3, mfa:false, perms:P({dashboard:["view"],documents:["create","edit"],people:["view"],audit:["view"],policies:["view"]})},
  {key:"legal",   title:"المراجع القانوني / الممثل المفوض",  dept:"mgmt",     reportsTo:"gm",     level:2, scope:"record",  clearance:3, mfa:false, perms:P({documents:["create","edit","print"]})},
  {key:"pm",      title:"مدير المشاريع",                    dept:"projects", reportsTo:"coo",    level:3, scope:"project", clearance:2, mfa:false, perms:P({customers:["view"],documents:["create","edit"],finance:["view"]})},
  {key:"qm",      title:"مدير الجودة",                      dept:"quality",  reportsTo:"coo",    level:3, scope:"dept",    clearance:3, mfa:false, perms:P({customers:["view"],documents:["create","edit","print"]})},
  {key:"training",title:"مدير التدريب والتطوير",            dept:"training", reportsTo:"hr",     level:3, scope:"dept",    clearance:2, mfa:false, perms:P({people:["view"],documents:["create","edit"]})},
  {key:"testlead",title:"رئيس الاختبار وضمان الجودة",       dept:"testing",  reportsTo:"qm",     level:4, scope:"project", clearance:2, mfa:false, perms:P({documents:["create","edit"]})},
  {key:"devlead", title:"قائد فريق التطوير",                dept:"dev",      reportsTo:"cto",    level:4, scope:"project", clearance:2, mfa:false, perms:P({documents:["create","edit"]})},
  {key:"dev",     title:"مطور تطبيقات",                     dept:"dev",      reportsTo:"devlead",level:5, scope:"record",  clearance:2, mfa:false, perms:P({documents:["create"]})},
  {key:"designer",title:"مصمم UI/UX",                       dept:"dev",      reportsTo:"devlead",level:5, scope:"record",  clearance:2, mfa:false, perms:P({documents:["create"]})},
  {key:"secops",  title:"مسؤول الأمن والبنية التحتية",      dept:"security", reportsTo:"cto",    level:4, scope:"company", clearance:4, mfa:true,  perms:P({audit:["view","export"],documents:["create","edit"],people:["view"]})},
  {key:"pr",      title:"مسؤول العلاقات العامة والتسويق",   dept:"pr",       reportsTo:"coo",    level:4, scope:"dept",    clearance:2, mfa:false, perms:P({customers:["create","view","edit"],documents:["create","edit","share"]})},
  {key:"sales",   title:"مسؤول المبيعات وتطوير الأعمال",    dept:"sales",    reportsTo:"coo",    level:4, scope:"dept",    clearance:2, mfa:false, perms:P({customers:["create","view","edit","export"],finance:["create","view","print"],documents:["create","edit"]})},
  {key:"cs",      title:"مسؤول خدمة العملاء والدعم",        dept:"cs",       reportsTo:"qm",     level:4, scope:"dept",    clearance:2, mfa:false, perms:P({customers:["view","edit"],documents:["create"]})},
  {key:"procurement",title:"مسؤول المشتريات",               dept:"accounts", reportsTo:"cfo",    level:4, scope:"dept",    clearance:2, mfa:false, perms:P({finance:["view","create"],documents:["create","edit"]})},
  {key:"accountant",title:"المحاسب",                        dept:"accounts", reportsTo:"cfo",    level:4, scope:"dept",    clearance:3, mfa:true,  perms:P({finance:["create","view","edit","print","export","stamp"],customers:["view"],documents:["create","print"]})},
  {key:"records", title:"مسؤول الملفات والسجلات",           dept:"records",  reportsTo:"gm",     level:4, scope:"company", clearance:3, mfa:false, perms:P({documents:"all"})},
  {key:"staff",   title:"موظف / متعاون / مستشار خارجي",     dept:"projects", reportsTo:"pm",     level:5, scope:"record",  clearance:1, mfa:false, perms:P({})}
];

/* صلاحيات المرحلة الثالثة (المشاريع، الاختبار، الجودة، الدعم) — تدمج مع صلاحيات المنصب */
const V = ["view","comment"], VE = ["create","view","edit","comment"], VA = ["create","view","edit","comment","approve","reject","print","export"];
const PERMS3 = {
  coo:       {projects:VA, testing:V, quality:V, support:VE},
  cto:       {projects:["view","comment","approve"], testing:V, quality:V, support:V},
  cfo:       {projects:V},
  pm:        {projects:VA, testing:VE, quality:V, support:VE},
  qm:        {projects:V, testing:["view","comment","approve"], quality:ALL, support:VA},
  testlead:  {projects:V, testing:ALL, quality:V, support:V},
  devlead:   {projects:VE, testing:VE, support:V},
  dev:       {projects:VE, testing:VE, support:V},
  designer:  {projects:VE, testing:VE},
  secops:    {projects:V, support:V},
  pr:        {projects:V, support:V},
  sales:     {projects:V, support:VE},
  cs:        {projects:V, testing:["view","create"], quality:V, support:ALL},
  training:  {quality:V},
  accountant:{projects:V},
  staff:     {projects:VE, testing:VE}
};
const P3_MODULES = ["projects","testing","quality","support"];
/* صلاحيات المرحلة الرابعة (التدريب، العلاقات العامة والمحتوى) — كل موظف يرى تدريبه */
const PERMS4 = {
  hr:        {training:VA, content:V},
  training:  {training:ALL},
  qm:        {training:["view","comment","approve"], content:V},
  coo:       {training:V, content:VA},
  cto:       {training:["view","create","comment"]},
  devlead:   {training:["view","create","comment"]},
  pm:        {training:["view","create","comment"], content:V},
  pr:        {content:ALL},
  sales:     {content:VE},
  cs:        {content:V},
  cfo:       {training:V}
};
const P4_MODULES = ["training","content"];
/* صلاحيات المرحلة الخامسة (الخصوصية، الأمن والنسخ الاحتياطي) */
const PERMS5 = {
  secops:  {security:ALL, privacy:VA},
  cto:     {security:["view","comment","export"], privacy:V},
  legal:   {privacy:["view","comment","approve","reject","print","export"]},
  hr:      {privacy:VE},
  cs:      {privacy:["create","view","comment"]},
  records: {privacy:V},
  qm:      {privacy:V}
};
const P5_MODULES = ["privacy","security"];
for(const p of POSITIONS){ if(!["gm","owner"].includes(p.key)) p.perms.training = ["view"]; }
for(const p of POSITIONS){ for(const x of [PERMS3[p.key], PERMS4[p.key], PERMS5[p.key]]) if(x) for(const k in x) p.perms[k] = Array.from(new Set([...(p.perms[k]||[]), ...x[k]])); }
/* كل الوحدات المضافة بعد الإصدار الأول وصلاحياتها — تستخدمها ترقية البيانات */
const ADDED_MODULES = P3_MODULES.concat(P4_MODULES, P5_MODULES);
const ADDED_PERMS = key => { const o = {training:["view"]}; for(const x of [PERMS3[key], PERMS4[key], PERMS5[key]]) if(x) for(const k in x) o[k] = Array.from(new Set([...(o[k]||[]), ...x[k]])); return o; };

/* أنواع المعاملات ونماذجها (القسم 6 و7)
   fields.k = مفتاح، amount = الحقل الذي يمثل القيمة المالية */
const TYPES = {
  purchase:{name:"طلب شراء", icon:"🛒", days:5, amount:"amount",
    docs:["عرض سعر المورد","مبرر الشراء"],
    fields:[{k:"item",l:"البند / الجهاز",t:"text",req:1},{k:"qty",l:"الكمية",t:"number"},{k:"amount",l:"التكلفة التقديرية",t:"number",req:1},{k:"vendor",l:"المورد المقترح",t:"text"},{k:"reason",l:"المبرر",t:"textarea",req:1}]},
  leave:{name:"طلب إجازة", icon:"🌴", days:2,
    docs:[],
    fields:[{k:"kind",l:"نوع الإجازة",t:"select",o:["سنوية","مرضية","طارئة","بدون راتب"]},{k:"from",l:"من تاريخ",t:"date",req:1},{k:"to",l:"إلى تاريخ",t:"date",req:1},{k:"delegate",l:"البديل أثناء الإجازة",t:"user"},{k:"reason",l:"ملاحظات",t:"textarea"}]},
  expense:{name:"طلب صرف / عهدة", icon:"💵", days:3, amount:"amount",
    docs:["الإيصالات أو الفواتير"],
    fields:[{k:"purpose",l:"الغرض",t:"text",req:1},{k:"amount",l:"المبلغ",t:"number",req:1},{k:"project",l:"المشروع / مركز التكلفة",t:"text"},{k:"reason",l:"التفاصيل",t:"textarea"}]},
  invoice:{name:"اعتماد فاتورة عميل", icon:"🧾", days:3, amount:"amount", system:true,
    docs:["محضر الإنجاز أو التسليم"],
    fields:[{k:"invoiceNo",l:"رقم الفاتورة",t:"text"},{k:"customer",l:"العميل",t:"text"},{k:"amount",l:"الإجمالي",t:"number"},{k:"exception",l:"يتضمن استثناء (خصم خاص / شروط غير معتادة)",t:"check"}]},
  release:{name:"إطلاق تطبيق / إصدار", icon:"🚀", days:4,
    docs:["تقرير الاختبار","تقرير جاهزية الإطلاق"],
    fields:[{k:"project",l:"المشروع",t:"text",req:1},{k:"version",l:"رقم الإصدار",t:"text",req:1},{k:"notes",l:"ملاحظات الإصدار",t:"textarea"},{k:"strategic",l:"مشروع استراتيجي (يتطلب المدير العام)",t:"check"}]},
  contract:{name:"عقد عميل", icon:"📜", days:7, amount:"amount",
    docs:["مسودة العقد","عرض السعر المعتمد"],
    fields:[{k:"customer",l:"العميل",t:"text",req:1},{k:"subject",l:"موضوع العقد",t:"text",req:1},{k:"amount",l:"قيمة العقد",t:"number"},{k:"start",l:"تاريخ البداية",t:"date"},{k:"end",l:"تاريخ الانتهاء",t:"date"}]},
  publish:{name:"نشر إعلامي", icon:"📣", days:3,
    docs:["نص المنشور والصور"],
    fields:[{k:"channel",l:"القناة",t:"select",o:["الموقع","لينكدإن","إكس","فيسبوك","إنستغرام","أخرى"]},{k:"content",l:"المحتوى",t:"textarea",req:1},{k:"mentionsClient",l:"يذكر اسم عميل أو شعاره",t:"check"},{k:"sensitive",l:"محتوى حساس",t:"check"}]},
  training:{name:"خطة / طلب تدريب", icon:"🎓", days:5, amount:"amount",
    docs:["وصف البرنامج التدريبي"],
    fields:[{k:"program",l:"البرنامج",t:"text",req:1},{k:"provider",l:"الجهة المدربة",t:"text"},{k:"amount",l:"التكلفة",t:"number"},{k:"linkedDefect",l:"مرتبط بعيب أو شكوى عميل",t:"check"},{k:"goal",l:"الهدف والأثر المتوقع",t:"textarea"}]},
  complaint:{name:"شكوى عميل عالية الخطورة", icon:"⚠️", days:2,
    docs:[],
    fields:[{k:"customer",l:"العميل",t:"text",req:1},{k:"project",l:"المشروع / الإصدار",t:"text"},{k:"details",l:"وصف الشكوى",t:"textarea",req:1},{k:"sensitive",l:"أثر على السمعة أو العقد",t:"check"}]},
  incident:{name:"حادث أمني", icon:"🚨", days:1, confidential:true,
    docs:["السجلات أو لقطات الشاشة"],
    fields:[{k:"severity",l:"الخطورة",t:"select",o:["منخفضة","متوسطة","عالية","حرجة"]},{k:"system",l:"النظام المتأثر",t:"text",req:1},{k:"details",l:"الوصف",t:"textarea",req:1},{k:"sensitive",l:"يتضمن بيانات شخصية",t:"check"}]},
  document:{name:"اعتماد مستند", icon:"📄", days:3, system:true,
    docs:[],
    fields:[{k:"docNo",l:"رقم المستند",t:"text"},{k:"title",l:"العنوان",t:"text"},{k:"version",l:"الإصدار",t:"text"}]},
  change:{name:"طلب تغيير نطاق", icon:"🔁", days:4, amount:"amount",
    docs:["وصف التغيير وأثره"],
    fields:[{k:"project",l:"المشروع",t:"text",req:1},{k:"change",l:"التغيير المطلوب",t:"textarea",req:1},{k:"days",l:"الأثر على المدة (يوم)",t:"number"},{k:"amount",l:"الأثر المالي",t:"number"},{k:"clientRequested",l:"بطلب من العميل",t:"check"}]},
  general:{name:"طلب إداري عام", icon:"📝", days:3,
    docs:[],
    fields:[{k:"subject",l:"الموضوع",t:"text",req:1},{k:"details",l:"التفاصيل",t:"textarea",req:1}]}
};

const STAGES = {review:"مراجعة", approve:"اعتماد", execute:"تنفيذ", close:"إغلاق"};

/* مسارات الموافقة الافتراضية (القسم 7.2)
   who: "manager" = المدير المباشر لمنشئ الطلب، "creator" = المنشئ (للتنفيذ/الإغلاق فقط)، أو مفتاح منصب
   when: شرط اختياري — {min:"gm"} = القيمة ≥ حد المدير العام، {min:1} = قيمة > 0، {flag:"strategic"} = حقل صح */
const POLICIES = {
  invoice:[
    {label:"تأكيد الإنجاز",            who:"pm",         stage:"review"},
    {label:"مراجعة مالية",             who:"cfo",        stage:"approve"},
    {label:"اعتماد الاستثناء",         who:"gm",         stage:"approve", when:{any:[{flag:"exception"},{min:"gm"}]}},
    {label:"إرسال للعميل وتسجيل التحصيل", who:"accountant", stage:"execute"}
  ],
  purchase:[
    {label:"موافقة مدير القسم",        who:"manager",    stage:"review"},
    {label:"مراجعة المشتريات",         who:"procurement",stage:"review"},
    {label:"اعتماد مالي",              who:"cfo",        stage:"approve"},
    {label:"اعتماد المدير العام (تجاوز الحد)", who:"gm", stage:"approve", when:{min:"gm"}},
    {label:"الاستلام",                 who:"procurement",stage:"execute"},
    {label:"تسجيل الأصل والعهدة",      who:"accountant", stage:"close"}
  ],
  leave:[
    {label:"موافقة المدير المباشر",    who:"manager",    stage:"approve"},
    {label:"الموارد البشرية وتحديث الرصيد", who:"hr",   stage:"close"}
  ],
  expense:[
    {label:"موافقة المدير المباشر",    who:"manager",    stage:"review"},
    {label:"اعتماد مالي",              who:"cfo",        stage:"approve"},
    {label:"اعتماد المدير العام (تجاوز الحد)", who:"gm", stage:"approve", when:{min:"gm"}},
    {label:"الصرف والتسوية",           who:"accountant", stage:"execute"}
  ],
  release:[
    {label:"مراجعة قائد الفريق",       who:"devlead",    stage:"review"},
    {label:"الاختبار",                 who:"testlead",   stage:"review"},
    {label:"بوابة الجودة",             who:"qm",         stage:"approve"},
    {label:"اعتماد مدير التقنية",      who:"cto",        stage:"approve"},
    {label:"موافقة مدير المشروع",      who:"pm",         stage:"approve"},
    {label:"المدير العام (مشروع استراتيجي)", who:"gm",   stage:"approve", when:{flag:"strategic"}}
  ],
  contract:[
    {label:"مراجعة المشروع / التقنية", who:"cto",        stage:"review"},
    {label:"المراجعة المالية",         who:"cfo",        stage:"review"},
    {label:"المراجعة القانونية",       who:"legal",      stage:"review"},
    {label:"اعتماد المدير العام",      who:"gm",         stage:"approve"},
    {label:"توقيع وحفظ النسخة",        who:"records",    stage:"close"}
  ],
  publish:[
    {label:"موافقة مالك المشروع",      who:"pm",         stage:"review"},
    {label:"توثيق موافقة العميل",      who:"coo",        stage:"approve", when:{flag:"mentionsClient"}},
    {label:"المدير العام (محتوى حساس)",who:"gm",         stage:"approve", when:{flag:"sensitive"}},
    {label:"النشر",                    who:"creator",    stage:"execute"}
  ],
  training:[
    {label:"موافقة المدير المباشر",    who:"manager",    stage:"review"},
    {label:"مدير التدريب",             who:"training",   stage:"review"},
    {label:"الموارد البشرية",          who:"hr",         stage:"approve"},
    {label:"المالية (تكلفة)",          who:"cfo",        stage:"approve", when:{min:1}},
    {label:"مدير الجودة (عيب/شكوى)",   who:"qm",         stage:"review",  when:{flag:"linkedDefect"}},
    {label:"المدير العام (تجاوز الحد)",who:"gm",         stage:"approve", when:{min:"gm"}},
    {label:"الجدولة والتقييم",         who:"training",   stage:"execute"}
  ],
  complaint:[
    {label:"مدير الجودة",              who:"qm",         stage:"review"},
    {label:"مدير المشروع / الدعم",     who:"pm",         stage:"approve"},
    {label:"مدير العمليات",            who:"coo",        stage:"approve"},
    {label:"المدير العام (أثر سمعة/عقد)", who:"gm",      stage:"approve", when:{flag:"sensitive"}},
    {label:"إجراء تصحيحي",             who:"pm",         stage:"execute"},
    {label:"تأكيد العميل والإغلاق",    who:"creator",    stage:"close"}
  ],
  incident:[
    {label:"تقييم الأمن",              who:"secops",     stage:"review"},
    {label:"مدير التقنية",             who:"cto",        stage:"approve"},
    {label:"المدير العام (بيانات شخصية)", who:"gm",      stage:"approve", when:{flag:"sensitive"}},
    {label:"الاحتواء والإغلاق",        who:"secops",     stage:"close"}
  ],
  change:[
    {label:"مراجعة مدير المشروع",      who:"pm",         stage:"review"},
    {label:"تقييم الأثر التقني",       who:"cto",        stage:"review"},
    {label:"الأثر المالي",             who:"cfo",        stage:"approve", when:{min:1}},
    {label:"المدير العام (تجاوز الحد)",who:"gm",         stage:"approve", when:{min:"gm"}},
    {label:"تحديث النطاق والخطة",      who:"pm",         stage:"execute"}
  ],
  document:[
    {label:"مراجعة المدير المباشر",    who:"manager",    stage:"approve"},
    {label:"حفظ النسخة الرئيسية",      who:"records",    stage:"close"}
  ],
  general:[
    {label:"موافقة المدير المباشر",    who:"manager",    stage:"approve"}
  ]
};

/* المستندات الرئيسية من حزمة الشركة (القسم 2.3) — لكل نوع نسخة رئيسية واحدة
   [العنوان، التصنيف، مستوى السرية، ملف الحزمة في library/] */
const MASTER_DOCS = [
  ["فهرس الحزمة","فهرس وتعليمات",2,"00-00.docx"],
  ["نموذج بيانات الشركة","فهرس وتعليمات",3,"00-01.docx"],
  ["مسودة عقد التأسيس والنظام الأساسي","تأسيس وحوكمة",4,"01-01.docx"],
  ["اتفاقية المؤسسين والشركاء","تأسيس وحوكمة",4,"01-02.docx"],
  ["اتفاقية تطوير تطبيق","عقود وعملاء وموردين",2,"02-01.docx"],
  ["اتفاقية عدم الإفصاح NDA","عقود وعملاء وموردين",2,"02-02.docx"],
  ["عقد عمل نموذجي","موارد بشرية",3,"03-01.docx"],
  ["دليل الموظف والسياسات الأساسية","موارد بشرية",2,"03-02.docx"],
  ["السياسة المالية والمشتريات","مالية ومحاسبة",3,"04-01.docx"],
  ["سياسة الخصوصية","خصوصية وأمن معلومات",1,"05-01.docx"],
  ["سياسة أمن المعلومات والنسخ الاحتياطي","خصوصية وأمن معلومات",2,"05-02.docx"],
  ["دليل إدارة المشاريع والتسليم","تشغيل وإدارة مشاريع",2,"06-01.docx"],
  ["نموذج طلب تغيير النطاق","تشغيل وإدارة مشاريع",2,"06-02.docx"],
  ["سجلات وقوائم الشركة","سجلات وقوائم",3,"08-01.xlsx"],
  ["دليل الهوية البصرية","هوية بصرية وختم",1,"09-01.docx"],
  ["الشعار الرسمي","هوية بصرية وختم",1,"09-official-logo.png"],
  ["رمز الهوية (شفاف)","هوية بصرية وختم",1,"09-brand-symbol-transparent.png"],
  ["الختم الإداري — PNG","هوية بصرية وختم",3,"09-company-stamp.png"],
  ["الختم الإداري — SVG","هوية بصرية وختم",3,"09-company-stamp.svg"],
  ["نموذج دعم فني","نماذج المعاملات",2,"10-01.docx"],
  ["نموذج إبلاغ حادث أمني","نماذج المعاملات",3,"10-02.docx"],
  ["طلب ممارسة حق خصوصية","نماذج المعاملات",2,"10-03.docx"],
  ["نموذج عرض سعر","مالية وتجارية",2,"11-01.docx"],
  ["فاتورة تجارية","مالية وتجارية",2,"11-02.docx"],
  ["أمر شراء","مالية وتجارية",2,"11-03.docx"],
  ["إيصال استلام مبلغ","مالية وتجارية",2,"11-04.docx"],
  ["محضر تسليم مشروع","مالية وتجارية",2,"11-05.docx"],
  ["قرار تعيين مدير","إدارة وموارد بشرية",3,"12-01.docx"],
  ["محضر اجتماع الشركاء","إدارة وموارد بشرية",4,"12-02.docx"],
  ["طلب إجازة","إدارة وموارد بشرية",1,"12-03.docx"],
  ["طلب مصروفات وعهدة","إدارة وموارد بشرية",1,"12-04.docx"],
  ["قائمة مراجعة قبل التسجيل والتشغيل","مراجعة قانونية واعتماد",3,"99-01.docx"]
];
/* النموذج الرسمي المرتبط بكل نوع معاملة */
const TYPE_TEMPLATES = {leave:"12-03.docx", expense:"12-04.docx", purchase:"11-03.docx", invoice:"11-02.docx",
  incident:"10-02.docx", contract:"02-01.docx", complaint:"10-01.docx", change:"06-02.docx", release:"11-05.docx"};

/* فريق تجريبي لتجربة المسارات فوراً */
const DEMO_TEAM = [
  ["owner","عبدالله البشرى"],["coo","سارة الأمين"],["cfo","محمد عثمان"],["hr","هبة الطيب"],
  ["cto","خالد إبراهيم"],["legal","أ. مازن صالح"],["pm","ريم حسن"],["qm","عمر الفاتح"],["training","نهى بابكر"],
  ["testlead","يوسف آدم"],["devlead","أحمد النور"],["dev","مروة علي"],["designer","لينا محجوب"],
  ["secops","طارق عوض"],["pr","إيمان سيد"],["sales","حسام الدين"],["cs","آمنة يعقوب"],
  ["procurement","بكري موسى"],["accountant","سلمى عباس"],["records","ياسر كمال"],["staff","منتصر جعفر"]
];

window.BOS_DATA = {MODULES, ACTIONS, SCOPES, CLEARANCE, DEPARTMENTS, POSITIONS, TYPES, STAGES, POLICIES, MASTER_DOCS, TYPE_TEMPLATES, DEMO_TEAM, PERMS3, P3_MODULES, PERMS4, P4_MODULES, PERMS5, P5_MODULES, ADDED_MODULES, ADDED_PERMS};
})();
