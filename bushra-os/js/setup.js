/* نظام البشرى لإدارة الشركة — تهيئة الحساب لأول مرة (القسم 4) */
(function(){
"use strict";
const D = window.BOS_DATA;

function initCompany(cfg){
  BOS.reset();
  const S = BOS.S;
  S.company = {
    tradeName: cfg.tradeName, legalName: cfg.legalName || cfg.tradeName, nameEn: cfg.nameEn || "",
    country: "السودان", state: cfg.state||"", locality: cfg.locality||"", address: cfg.address||"",
    email: cfg.email||"", phone: cfg.phone||"", website: cfg.website||"",
    activity: cfg.activity||"", logo: cfg.logo || "assets/logo.png", createdAt: BOS.now()
  };
  S.settings = {
    currency: cfg.currency||"SDG", fiscalStart: cfg.fiscalStart||"01-01", template: cfg.template||"navy",
    gmThreshold: Number(cfg.gmThreshold||0), taxRate: 0, sessionMinutes: Number(cfg.sessionMinutes||30),
    mfa: cfg.mfa !== false, autoEscalate: cfg.autoEscalate !== false,
    modules: Object.fromEntries(D.MODULES.map(m=>[m.key, cfg.modules ? cfg.modules[m.key] !== false : true])),
    recovery: cfg.recovery||"", leaveDays: 30, passRate: 95,
    sla: {P1:[1,8], P2:[4,24], P3:[8,72], P4:[24,120]}, work: {start:"08:00", end:"16:00", grace:15, weekend:[5,6]}
  };

  /* الأقسام المختارة — مع الحفاظ على التسلسل */
  const pickedDepts = new Set(cfg.departments || D.DEPARTMENTS.map(d=>d.key));
  pickedDepts.add("board"); pickedDepts.add("mgmt");
  const deptId = {};
  for(const d of D.DEPARTMENTS){ if(pickedDepts.has(d.key)) deptId[d.key] = BOS.uid("dep"); }
  const liveParent = k => { let d = D.DEPARTMENTS.find(x=>x.key===k); while(d && d.parent && !deptId[d.parent]) d = D.DEPARTMENTS.find(x=>x.key===d.parent); return d && d.parent ? deptId[d.parent] : null; };
  const resolveDept = k => { let d = D.DEPARTMENTS.find(x=>x.key===k); while(d && !deptId[d.key]) d = D.DEPARTMENTS.find(x=>x.key===d.parent); return d ? deptId[d.key] : deptId.mgmt; };
  S.departments = D.DEPARTMENTS.filter(d=>deptId[d.key]).map(d=>({id:deptId[d.key], key:d.key, name:d.name, parentId: d.parent ? liveParent(d.key) : null}));

  /* المناصب المختارة (المدير العام والمالك إلزاميان) */
  const pickedPos = new Set(cfg.positions || D.POSITIONS.map(p=>p.key));
  pickedPos.add("gm"); pickedPos.add("owner");
  S.positions = D.POSITIONS.filter(p=>pickedPos.has(p.key)).map(p=>{
    const o = BOS.clone(p); o.id = BOS.uid("pos"); o.deptId = resolveDept(p.dept);
    // إن حُذف المنصب الأعلى، يتصل بأقرب منصب موجود في السلسلة
    let up = p.reportsTo; while(up && !pickedPos.has(up)) up = (D.POSITIONS.find(x=>x.key===up)||{}).reportsTo;
    o.reportsTo = up || null;
    if(cfg.mfa === false) o.mfa = false;
    return o;
  });
  S.policies = BOS.clone(D.POLICIES);

  /* المدير العام */
  const gmPos = BOS.posByKey("gm");
  const gm = {id:BOS.uid("e"), name:cfg.gmName, email:cfg.gmEmail||"", phone:cfg.gmPhone||"",
    positionId:gmPos.id, deptId:gmPos.deptId, managerId:null, status:"active",
    hireDate:BOS.now().slice(0,10), validFrom:BOS.now().slice(0,10), validTo:"", leaveUsed:0};
  S.employees.push(gm);
  S.session = {userId: gm.id, at: BOS.now(), last: Date.now()};

  BOS.audit("إنشاء حساب الشركة", "company", null, S.company.tradeName, gm.id);
  BOS.audit("إنشاء الهيكل التنظيمي", "org", null, S.departments.length + " قسم، " + S.positions.length + " منصب", gm.id);
  BOS.audit("تعيين المدير العام", "employee", gm.id, gm.name, gm.id);

  if(cfg.demo) seedDemo(gm);
  if(cfg.masterDocs !== false) seedDocs(gm);
  if(cfg.demo && window.BOS_OPS){ try{ BOS_OPS.seedOps(); }catch(e){ console.warn(e); } }
  if(window.BOS_HR) BOS_HR.migrate();
  if(cfg.demo && window.BOS_HR){ try{ BOS_HR.seedHr(); }catch(e){ console.warn(e); } }
  if(window.BOS_SEC) BOS_SEC.migrate();
  if(cfg.demo && window.BOS_SEC){ try{ BOS_SEC.seedSec(); }catch(e){ console.warn(e); } }
  if(window.BOS_MAIL) BOS_MAIL.migrate();
  if(cfg.demo && window.BOS_MAIL){ try{ BOS_MAIL.seedMail(); }catch(e){ console.warn(e); } }

  S.setupDone = true;
  BOS.save();
  return gm;
}

function seedDemo(gm){
  const S = BOS.S;
  const made = {};
  for(const [key, name] of D.DEMO_TEAM){
    const p = BOS.posByKey(key); if(!p) continue;
    const e = {id:BOS.uid("e"), name, email: key + "@albushra.tech", phone:"", positionId:p.id, deptId:p.deptId,
      managerId:null, status:"active", hireDate:BOS.now().slice(0,10), validFrom:BOS.now().slice(0,10), validTo:"", leaveUsed:0, demo:true};
    S.employees.push(e); made[key] = e;
  }
  // المدير المباشر حسب التسلسل
  for(const e of S.employees){ if(e.id===gm.id) continue; const m = BOS.managerOf(e); e.managerId = m ? m.id : null; }
  // المالك فوق المدير العام
  if(made.owner){ gm.managerId = made.owner.id; made.owner.managerId = null; }
  // بديل الإجازة
  if(made.dev && made.designer){ made.dev.delegateId = made.designer.id; }
  if(made.pm && made.qm){ made.pm.delegateId = made.coo ? made.coo.id : null; }
  BOS.audit("إضافة فريق تجريبي", "employee", null, Object.keys(made).length + " موظف", gm.id);

  S.customers.push(
    {id:BOS.uid("c"), name:"وزارة الصحة — ولاية الخرطوم", kind:"جهة حكومية", contact:"إدارة التحول الرقمي", phone:"", email:"", stage:"عميل", publishConsent:false, createdAt:BOS.now(), notes:""},
    {id:BOS.uid("c"), name:"شركة النيل للتجارة", kind:"قطاع خاص", contact:"أ. فيصل", phone:"", email:"", stage:"عرض سعر", publishConsent:true, createdAt:BOS.now(), notes:""},
    {id:BOS.uid("c"), name:"جامعة الجزيرة", kind:"تعليمي", contact:"عمادة التقنية", phone:"", email:"", stage:"فرصة", publishConsent:false, createdAt:BOS.now(), notes:""}
  );
}

function seedDocs(gm){
  const S = BOS.S;
  const rec = S.employees.find(e=>BOS.pos(e.positionId).key==="records") || gm;
  for(const [title, cat, cls, file] of D.MASTER_DOCS){
    const d = {id:BOS.uid("d"), no:BOS.nextNo("DOC"), title, category:cat, classification:cls, ownerId:rec.id,
      deptId:rec.deptId, file:"library/"+file, createdAt:BOS.now(), current:1, master:true, expires:"",
      versions:[{v:1, content:"النسخة الرئيسية المستوردة من حزمة الشركة. تحتوي على حقول «يُعبأ» ويجب مراجعتها قانونياً قبل الاستخدام الرسمي.",
        file:"library/"+file, status:"approved", createdBy:rec.id, createdAt:BOS.now(), note:"استيراد من حزمة الشركة", approvedBy:gm.id, approvedAt:BOS.now()}]};
    S.documents.push(d);
  }
  BOS.audit("استيراد المستندات الرئيسية", "document", null, D.MASTER_DOCS.length + " مستند من حزمة الشركة", gm.id);
}

window.BOS_SETUP = {initCompany};
})();
