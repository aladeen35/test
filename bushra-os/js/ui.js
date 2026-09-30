/* نظام البشرى لإدارة الشركة — الهيكل العام، التوجيه، الدخول، ومعالج الإعداد */
(function(){
"use strict";
const D = window.BOS_DATA;
const $ = (s, r) => (r||document).querySelector(s);
const $$ = (s, r) => Array.from((r||document).querySelectorAll(s));
const esc = v => String(v==null?"":v).replace(/[&<>"']/g, c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const fmtDate = iso => { if(!iso) return "—"; const d = new Date(iso); return isNaN(d) ? esc(iso) : d.toLocaleDateString("ar-SD-u-nu-latn",{year:"numeric",month:"short",day:"numeric"}); };
const fmtDT = iso => { if(!iso) return "—"; const d = new Date(iso); return d.toLocaleString("ar-SD-u-nu-latn",{year:"numeric",month:"short",day:"numeric",hour:"2-digit",minute:"2-digit"}); };
const money = (n, cur) => Number(n||0).toLocaleString("en-US",{maximumFractionDigits:2}) + " " + esc(cur || (BOS.S.settings||{}).currency || "");
const initials = n => String(n||"؟").trim().split(/\s+/).slice(0,2).map(w=>w[0]).join("");
const avatar = e => `<span class="avatar" title="${esc(e?e.name:"")}">${esc(initials(e?e.name:"—"))}</span>`;
const empName = id => { const e = BOS.byId(id); return e ? esc(e.name) : "<span class='muted'>—</span>"; };

const REQ_STATUS = {
  in_review:["قيد المراجعة","info"], executing:["قيد التنفيذ","accent"], returned:["معاد للتعديل","warn"],
  info_requested:["بانتظار معلومات","warn"], rejected:["مرفوض","bad"], cancelled:["ملغى","bad"], closed:["مغلق","ok"]
};
const statusBadge = s => { const x = REQ_STATUS[s] || [s,""]; return `<span class="badge ${x[1]}">${x[0]}</span>`; };

/* ---------- التنبيهات والنوافذ ---------- */
function toast(msg, kind){
  const t = document.createElement("div"); t.className = "toast " + (kind||""); t.textContent = msg;
  $("#toasts").appendChild(t); setTimeout(()=>t.remove(), kind==="gold" ? 12000 : 4200);
}
function modal(title, body, buttons, wide){
  const bg = document.createElement("div"); bg.className = "modal-bg";
  bg.innerHTML = `<div class="modal ${wide?"wide":""}" role="dialog" aria-modal="true"><div class="modal-h"><h2>${esc(title)}</h2><button class="icon-btn" data-x aria-label="إغلاق">✕</button></div>
    <div class="modal-b">${body}</div><div class="modal-f"></div></div>`;
  const close = () => bg.remove();
  const f = $(".modal-f", bg);
  (buttons||[]).forEach(b=>{
    const el = document.createElement("button"); el.className = "btn " + (b.cls||""); el.textContent = b.label;
    el.onclick = () => { try{ if(b.onClick && b.onClick(bg) === false) return; close(); } catch(e){ toast(e.message,"bad"); } };
    f.appendChild(el);
  });
  const cancel = document.createElement("button"); cancel.className="btn"; cancel.textContent = buttons && buttons.length ? "إلغاء" : "إغلاق"; cancel.onclick = close; f.appendChild(cancel);
  $("[data-x]", bg).onclick = close;
  bg.addEventListener("mousedown", e=>{ if(e.target===bg) close(); });
  document.body.appendChild(bg);
  const first = $("input,select,textarea", bg); if(first) setTimeout(()=>first.focus(), 30);
  return bg;
}
function formData(root){
  const o = {};
  $$("[name]", root).forEach(el=>{
    if(el.type==="checkbox") o[el.name] = el.checked;
    else if(el.type==="number") o[el.name] = el.value==="" ? "" : Number(el.value);
    else o[el.name] = el.value.trim();
  });
  return o;
}
function userOptions(sel, filter){
  return BOS.S.employees.filter(e=>BOS.active(e) && (!filter || filter(e)))
    .map(e=>`<option value="${e.id}" ${e.id===sel?"selected":""}>${esc(e.name)} — ${esc(BOS.posTitle(e.positionId))}</option>`).join("");
}

/* ---------- السمة ---------- */
function applyTheme(){
  let t = "auto"; try{ t = localStorage.getItem("bos-theme") || "auto"; }catch(e){}
  const dark = t==="dark" || (t==="auto" && matchMedia("(prefers-color-scheme: dark)").matches);
  document.documentElement.dataset.theme = dark ? "dark" : "light";
}
function toggleTheme(){
  const dark = document.documentElement.dataset.theme === "dark";
  try{ localStorage.setItem("bos-theme", dark ? "light" : "dark"); }catch(e){}
  applyTheme();
}

/* ---------- التنقل ---------- */
const NAV = [
  {g:"مساحتي"},
  {h:"home", ic:"🏠", t:"الرئيسية"},
  {h:"approvals", ic:"✅", t:"ينتظر موافقتي", badge:()=>myQueue().length},
  {h:"requests", ic:"📨", t:"الطلبات", mod:"requests"},
  {h:"notifications", ic:"🔔", t:"الإشعارات", badge:()=>unread().length},
  {g:"الإدارة"},
  {h:"dashboard", ic:"📊", t:"لوحة المدير العام", mod:"dashboard", act:"view"},
  {h:"org", ic:"🏢", t:"الهيكل التنظيمي", mod:"org", act:"view"},
  {h:"people", ic:"👥", t:"الموظفون", mod:"people", act:"view"},
  {h:"policies", ic:"🔀", t:"مسارات الموافقة", mod:"policies", act:"view"},
  {g:"الأعمال"},
  {h:"documents", ic:"📁", t:"المستندات", mod:"documents", act:"view"},
  {h:"customers", ic:"🤝", t:"العملاء", mod:"customers", act:"view"},
  {h:"finance", ic:"💳", t:"العروض والفواتير", mod:"finance", act:"view"},
  {g:"الإنتاج والجودة"},
  {h:"projects", ic:"🗂️", t:"المشاريع", mod:"projects", act:"view"},
  {h:"testing", ic:"🧪", t:"الاختبار والعيوب", mod:"testing", act:"view"},
  {h:"quality", ic:"🏅", t:"الجودة", mod:"quality", act:"view"},
  {h:"support", ic:"🎧", t:"خدمة العملاء والدعم", mod:"support", act:"view", badge:()=>{ const u = BOS.me(); return window.BOS_OPS ? BOS.S.tickets.filter(t=>t.status!=="closed" && (t.ownerId===u.id||t.referredTo===u.id)).length : 0; }},
  {g:"الحوكمة"},
  {h:"audit", ic:"🛡️", t:"سجل التدقيق", mod:"audit", act:"view"},
  {h:"settings", ic:"⚙️", t:"الإعدادات", mod:"settings", act:"view"}
];
function myQueue(){
  const u = BOS.me(); if(!u) return [];
  return BOS.S.requests.filter(r=>{ const st = BOS.currentStep(r); return st && st.assigneeId===u.id && ["in_review","executing","info_requested"].includes(r.status); });
}
function unread(){ const u = BOS.me(); return u ? BOS.S.notifications.filter(n=>n.userId===u.id && !n.read) : []; }

function shell(){
  const u = BOS.me(); const S = BOS.S;
  let nav = "", pendingGroup = "";
  for(const n of NAV){
    if(n.g){ pendingGroup = `<div class="nav-group">${n.g}</div>`; continue; }
    if(n.mod && !BOS.can(u, n.mod, n.act||"view")) continue;
    const b = n.badge ? n.badge() : 0;
    nav += pendingGroup + `<a href="#/${n.h}" data-h="${n.h}"><span class="ic">${n.ic}</span>${n.t}${b?`<span class="badge solid">${b}</span>`:""}</a>`;
    pendingGroup = "";
  }
  document.getElementById("app").innerHTML = `
  <div class="shell">
    <aside class="side">
      <div class="brand"><img src="${esc(S.company.logo)}" alt=""><div><b>${esc(S.company.tradeName)}</b><span>Company OS</span></div></div>
      <nav class="nav">${nav}</nav>
      <div class="side-foot">نظام البشرى لإدارة الشركة<br>نسخة أولية — البيانات محفوظة على هذا الجهاز</div>
    </aside>
    <div class="main">
      <header class="top">
        <button class="menu-btn" id="menu" aria-label="القائمة">☰</button>
        <div class="title" id="page-title"></div>
        <button class="icon-btn" id="theme" title="الوضع الليلي">◐</button>
        <a class="icon-btn" href="#/notifications" title="الإشعارات">🔔${unread().length?`<span class="dot">${unread().length}</span>`:""}</a>
        <button class="user-chip" id="user-chip">${avatar(u)}<span class="who"><b>${esc(u.name)}</b><span>${esc(BOS.posTitle(u.positionId))}</span></span></button>
      </header>
      <main class="page" id="page"></main>
    </div>
  </div>`;
  $("#menu").onclick = () => document.body.classList.toggle("nav-open");
  $("#theme").onclick = toggleTheme;
  $("#user-chip").onclick = () => modal("الحساب", `
    <div class="row">${avatar(u)}<div><b>${esc(u.name)}</b><div class="muted small">${esc(BOS.posTitle(u.positionId))} · ${esc((BOS.dept(u.deptId)||{}).name||"")}</div></div></div>
    <dl class="kv" style="margin-top:14px"><dt>نطاق الرؤية</dt><dd>${esc(D.SCOPES[BOS.scopeOf(u)])}</dd><dt>مستوى السرية</dt><dd>${esc(D.CLEARANCE[BOS.clearance(u)])}</dd>
    <dt>انتهاء الجلسة</dt><dd>بعد ${esc(S.settings.sessionMinutes)} دقيقة من عدم النشاط</dd></dl>`,
    [{label:"تسجيل الخروج / تبديل المستخدم", cls:"primary", onClick:()=>{ BOS.logout(); render(); }}]);
}

/* ---------- الموجه ---------- */
function route(){
  if(!BOS.S.setupDone) return render();
  if(!BOS.S.session) return render();
  if(BOS.sessionExpired()){ BOS.logout("انتهاء الجلسة"); toast("انتهت الجلسة لعدم النشاط — سجل الدخول مجدداً","warn"); return render(); }
  const u = BOS.me();
  if(!u || !BOS.active(u)){ BOS.logout("إيقاف وصول مستخدم غير نشط"); toast("هذا الحساب موقوف","bad"); return render(); }
  BOS.touch(); BOS.save();
  if(!$(".shell")) shell();
  const parts = (location.hash.replace(/^#\/?/,"") || "home").split("/");
  const name = parts[0], arg = parts[1], arg2 = parts[2];
  document.body.classList.remove("nav-open");
  $$(".nav a").forEach(a=>a.classList.toggle("active", a.dataset.h===name || (name==="request"&&a.dataset.h==="requests") || (name==="doc"&&a.dataset.h==="documents") || (name==="person"&&a.dataset.h==="people") || (["quote","invoice"].includes(name)&&a.dataset.h==="finance") || (["project","delivery","readiness"].includes(name)&&a.dataset.h==="projects") || (name==="bug"&&a.dataset.h==="testing") || (["ncr","quality-report"].includes(name)&&a.dataset.h==="quality") || (name==="ticket"&&a.dataset.h==="support")));
  const V = window.BOS_VIEWS;
  const view = V[name] || V.home;
  const page = $("#page");
  try{
    const out = view(arg, arg2);
    $("#page-title").textContent = out.title;
    page.innerHTML = out.html;
    out.bind && out.bind(page);
  }catch(e){
    console.error(e);
    page.innerHTML = `<div class="note bad">${esc(e.message)}</div>`;
  }
  window.scrollTo(0,0);
}
/* يعيد رسم الهيكل (لتحديث الشارات) ثم الصفحة */
function refresh(){ const s = $(".shell"); if(s) s.remove(); route(); }

function render(){
  applyTheme();
  const app = document.getElementById("app");
  if(!BOS.S.setupDone) return wizard(app);
  if(!BOS.S.session) return loginView(app);
  app.innerHTML = ""; route();
}

/* ---------- الدخول (نسخة أولية: اختيار المستخدم + مصادقة ثنائية محاكاة) ---------- */
function loginView(app){
  const S = BOS.S;
  const users = S.employees.slice().sort((a,b)=>(BOS.pos(a.positionId).level||9)-(BOS.pos(b.positionId).level||9));
  app.innerHTML = `
  <div class="auth">
    <div class="auth-panel">
      <img class="logo" src="${esc(S.company.logo)}" alt="">
      <div><h1>${esc(S.company.tradeName)}</h1><div class="tag">نظام البشرى لإدارة الشركة — Company OS</div></div>
      <input class="input" id="q" placeholder="ابحث بالاسم أو المنصب…">
      <div class="user-pick" id="pick">${users.map(e=>`
        <button data-id="${e.id}" ${BOS.active(e)?"":"disabled"}>${avatar(e)}<span style="flex:1"><b>${esc(e.name)}</b><br><span class="muted small">${esc(BOS.posTitle(e.positionId))}</span></span>
        ${BOS.active(e)?(needsMfa(e)?'<span class="badge accent">MFA</span>':""):'<span class="badge bad">موقوف</span>'}</button>`).join("")}</div>
      <p class="muted small">نسخة تجريبية تعمل على هذا الجهاز فقط. في التشغيل الفعلي يتم الدخول بالبريد وكلمة المرور والمصادقة متعددة العوامل عبر خادم الشركة.</p>
    </div>
    <div class="auth-hero"></div>
  </div>`;
  $("#q").oninput = e => { const q = e.target.value.trim(); $$("#pick button").forEach(b=>b.classList.toggle("hidden", q && !b.textContent.includes(q))); };
  $$("#pick button").forEach(b=>b.onclick = () => {
    const e = BOS.byId(b.dataset.id);
    if(!needsMfa(e)) { BOS.login(e.id); location.hash = "#/home"; render(); return; }
    const code = String(Math.floor(100000 + Math.random()*900000));
    toast("رمز التحقق (محاكاة إرسال إلى " + (e.email||e.phone||"جهاز المستخدم") + "): " + code, "gold");
    modal("المصادقة متعددة العوامل", `<p class="small">منصب «${esc(BOS.posTitle(e.positionId))}» يتطلب رمز تحقق.</p>
      <div class="field"><label class="f">رمز التحقق</label><input class="input mono" name="code" inputmode="numeric" maxlength="6" dir="ltr"></div>`,
      [{label:"دخول", cls:"primary", onClick:(bg)=>{
        if($("[name=code]",bg).value.trim() !== code){ BOS.audit("فشل التحقق الثنائي","session",e.id,"",e.id); BOS.save(); throw new Error("رمز غير صحيح"); }
        BOS.login(e.id); location.hash = "#/home"; render();
      }}]);
  });
}
function needsMfa(e){ return BOS.S.settings.mfa && (BOS.pos(e.positionId)||{}).mfa; }

/* ---------- معالج الإعداد الأولي (القسم 4.1) ---------- */
const WZ = {step:0, cfg:{departments:D.DEPARTMENTS.map(d=>d.key), positions:D.POSITIONS.map(p=>p.key), modules:{}, demo:true, masterDocs:true, mfa:true, autoEscalate:true, currency:"SDG", gmThreshold:1000000, sessionMinutes:30, template:"navy", tradeName:"البشرى للتكنولوجيا", nameEn:"AI-Bushra Technology", activity:"تطوير التطبيقات والحلول الرقمية والذكاء الاصطناعي"}};
const WZ_STEPS = ["بيانات الشركة","الهوية البصرية","المدير العام","الهيكل والمناصب","الوحدات والموافقات","الأمان والفريق"];
function wizard(app){
  const c = WZ.cfg, s = WZ.step;
  const inp = (k,l,t,ph,extra) => `<div class="field"><label class="f">${l}</label><input class="input" name="${k}" type="${t||"text"}" value="${esc(c[k]==null?"":c[k])}" placeholder="${esc(ph||"")}" ${extra||""}></div>`;
  let body = "";
  if(s===0) body = `<div class="grid g2">
      ${inp("tradeName","اسم الشركة التجاري *")}${inp("legalName","الاسم القانوني (إن كان مختلفاً)","text","يُعبأ بعد التسجيل")}
      ${inp("nameEn","الاسم بالإنجليزية")}<div class="field"><label class="f">الدولة</label><input class="input" value="السودان" disabled></div>
      ${inp("state","الولاية","text","مثال: الخرطوم")}${inp("locality","المحلية")}
      </div>${inp("address","العنوان")}<div class="grid g3">${inp("email","البريد","email")}${inp("phone","الهاتف","tel")}${inp("website","الموقع","url")}</div>
      <div class="grid g3"><div class="field"><label class="f">العملة الافتراضية</label><select class="input" name="currency">${["SDG","USD","SAR","AED","EUR"].map(x=>`<option ${c.currency===x?"selected":""}>${x}</option>`).join("")}</select></div>
      ${inp("fiscalStart","بداية السنة المالية (شهر-يوم)","text","01-01")}${inp("activity","مجال النشاط")}</div>`;
  if(s===1) body = `<div class="row" style="gap:18px;align-items:flex-start">
      <img src="${esc(c.logo||"assets/logo.png")}" style="width:140px;height:140px;border-radius:18px;border:1px solid var(--line)" id="logo-prev">
      <div style="flex:1;min-width:240px"><p class="small">الشعار الرسمي المعتمد من حزمة الشركة محمّل مسبقاً. يمكنك رفع نسخة أخرى إن لزم.</p>
      <input type="file" accept="image/*" id="logo-file" class="input">
      <div class="note" style="margin-top:12px">كل فاتورة وعرض سعر ومستند يصدر من النظام يحمل الشعار ورقم المستند وتاريخه وحالته واسم المنشئ والمعتمد، مع الختم الإداري كعنصر هوية داخلي.</div></div></div>
      <h3 style="margin:18px 0 8px">القالب البصري</h3>
      <div class="grid g3">${[["navy","الكحلي الرسمي","linear-gradient(135deg,#0B1B3A,#123A7A)"],["cyan","السماوي الكهربائي","linear-gradient(135deg,#0B1B3A,#18CDEF)"],["gold","كحلي وذهبي","linear-gradient(135deg,#0B1B3A 60%,#F3B83F)"]].map(([k,n,g])=>`<div class="theme-opt ${c.template===k?"on":""}" data-t="${k}"><div class="sw" style="background:${g}"></div>${n}</div>`).join("")}</div>`;
  if(s===2) body = `<p class="small muted">الممثل الأول للشركة. يملك رؤية شاملة لكل الوحدات، لكنه لا يستطيع تجاوز سجل الموافقات أو محو أثر التدقيق.</p>
      <div class="grid g2">${inp("gmName","اسم المدير العام *")}${inp("gmEmail","البريد","email")}${inp("gmPhone","الهاتف","tel")}</div>`;
  if(s===3) body = `<h3>الأقسام</h3><p class="small muted">يُحافظ على التسلسل: القسم الملغى تنتقل أقسامه الفرعية إلى أقرب قسم أعلى.</p>
      <div class="pick-grid">${D.DEPARTMENTS.map(d=>`<label class="check"><input type="checkbox" data-dep="${d.key}" ${c.departments.includes(d.key)?"checked":""} ${["board","mgmt"].includes(d.key)?"disabled":""}>${esc(d.name)}</label>`).join("")}</div>
      <h3 style="margin-top:18px">المناصب وتسلسلها</h3><p class="small muted">كل مستخدم يرتبط بمنصب؛ الصلاحيات تُمنح للمنصب لا للشخص.</p>
      <div class="pick-grid">${D.POSITIONS.map(p=>`<label class="check"><input type="checkbox" data-pos="${p.key}" ${c.positions.includes(p.key)?"checked":""} ${["gm","owner"].includes(p.key)?"disabled":""}><span>${esc(p.title)}<br><span class="muted small">يتبع: ${esc((D.POSITIONS.find(x=>x.key===p.reportsTo)||{title:"—"}).title)}</span></span></label>`).join("")}</div>`;
  if(s===4) body = `<h3>الوحدات</h3><div class="pick-grid">${D.MODULES.map(m=>`<label class="check"><input type="checkbox" data-mod="${m.key}" ${c.modules[m.key]!==false?"checked":""} ${m.core?"disabled":""}>${m.icon} ${esc(m.name)}${m.core?' <span class="muted small">(أساسية)</span>':""}</label>`).join("")}</div>
      <h3 style="margin-top:18px">مسارات الموافقة الافتراضية</h3>
      <div class="grid g2">${inp("gmThreshold","حد اعتماد المدير العام (المبالغ ≥ هذا الحد تتطلب موافقته)","number")}
      <label class="check" style="margin-top:24px"><input type="checkbox" name="autoEscalate" ${c.autoEscalate?"checked":""}>تصعيد تلقائي عند تجاوز مهلة المرحلة (يومان)</label></div>
      <p class="small muted">يتم تحميل مسارات القسم 7.2 (الفواتير، الشراء، الإجازة، الإطلاق، العقود، النشر، التدريب، الشكاوى، الحوادث) ويمكن تعديلها لاحقاً من «مسارات الموافقة».</p>`;
  if(s===5) body = `<label class="check"><input type="checkbox" name="mfa" ${c.mfa?"checked":""}>تفعيل المصادقة متعددة العوامل للمدير العام والمالية والموارد البشرية والأمن</label>
      <div class="grid g2" style="margin-top:8px">${inp("sessionMinutes","انتهاء الجلسة بعد عدم النشاط (دقيقة)","number")}${inp("recovery","سياسة استعادة الحساب (بريد / هاتف احتياطي)","text","مثال: البريد الاحتياطي للمالك")}</div>
      <h3 style="margin-top:16px">الموظفون</h3>
      <label class="check"><input type="checkbox" name="demo" ${c.demo?"checked":""}>إضافة فريق تجريبي يشغل كل المناصب (لتجربة مسارات الموافقة فوراً — يمكن تعطيله لاحقاً)</label>
      <label class="check"><input type="checkbox" name="masterDocs" ${c.masterDocs?"checked":""}>استيراد المستندات الرئيسية من حزمة الشركة (${D.MASTER_DOCS.length} مستند: العقود، السياسات، النماذج، الختم، السجلات)</label>
      <div class="note warn" style="margin-top:12px">هذه مواصفات منتج ونسخة أولية. نماذج الضرائب والفواتير والعقود تحتاج مراجعة وفق كيان الشركة ومتطلبات السودان قبل استخدامها رسمياً.</div>`;

  app.innerHTML = `<div class="wiz">
    <div class="wiz-head"><img src="assets/logo.png" alt=""><div><h1>إعداد حساب الشركة</h1><div class="muted">الخطوة ${s+1} من ${WZ_STEPS.length}: ${WZ_STEPS[s]}</div></div>
      <span class="spacer"></span><button class="icon-btn" id="theme">◐</button></div>
    <div class="steps-bar">${WZ_STEPS.map((_,i)=>`<i class="${i<s?"done":i===s?"on":""}"></i>`).join("")}</div>
    <div class="card" id="wz">${body}</div>
    <div class="row" style="margin-top:14px">${s?'<button class="btn" id="back">السابق</button>':""}<span class="spacer"></span>
      ${s===0?'<button class="btn" id="import">استعادة نسخة احتياطية</button>':""}
      <button class="btn primary" id="next">${s===WZ_STEPS.length-1?"إنشاء الحساب":"التالي"}</button></div>
  </div>`;
  $("#theme").onclick = toggleTheme;
  const collect = () => {
    Object.assign(c, formData($("#wz")));
    if(s===3){ c.departments = $$("[data-dep]").filter(x=>x.checked).map(x=>x.dataset.dep); c.positions = $$("[data-pos]").filter(x=>x.checked).map(x=>x.dataset.pos); }
    if(s===4){ $$("[data-mod]").forEach(x=>c.modules[x.dataset.mod] = x.checked); }
  };
  $$(".theme-opt").forEach(x=>x.onclick=()=>{ c.template = x.dataset.t; wizard(app); });
  const lf = $("#logo-file"); if(lf) lf.onchange = () => { const f = lf.files[0]; if(!f) return; if(f.size>600000) return toast("حجم الشعار كبير — الحد 600KB","bad"); const rd = new FileReader(); rd.onload = () => { c.logo = rd.result; wizard(app); }; rd.readAsDataURL(f); };
  if($("#back")) $("#back").onclick = () => { collect(); WZ.step--; wizard(app); };
  if($("#import")) $("#import").onclick = importBackup;
  $("#next").onclick = () => {
    collect();
    if(s===0 && !c.tradeName) return toast("اسم الشركة إلزامي","bad");
    if(s===2 && !c.gmName) return toast("اسم المدير العام إلزامي","bad");
    if(s < WZ_STEPS.length-1){ WZ.step++; return wizard(app); }
    BOS_SETUP.initCompany(c);
    toast("تم إنشاء حساب الشركة — أهلاً " + c.gmName, "ok");
    location.hash = "#/dashboard"; render();
  };
}

function importBackup(){
  const i = document.createElement("input"); i.type = "file"; i.accept = ".json,application/json";
  i.onchange = () => { const f = i.files[0]; if(!f) return; const rd = new FileReader();
    rd.onload = () => { try{ const o = JSON.parse(rd.result); if(!o.company || !Array.isArray(o.audit)) throw new Error("ملف غير صالح");
      localStorage.setItem("bushra-os-v1", JSON.stringify(Object.assign(o,{session:null}))); BOS.load(); toast("تمت الاستعادة","ok"); render(); }catch(e){ toast("تعذرت الاستعادة: " + e.message, "bad"); } };
    rd.readAsText(f); };
  i.click();
}

window.BOS_UI = {$, $$, esc, fmtDate, fmtDT, money, avatar, empName, statusBadge, REQ_STATUS, toast, modal, formData, userOptions, myQueue, unread, route, refresh, render, importBackup, initials};

/* ---------- التشغيل ---------- */
window.addEventListener("hashchange", route);
["click","keydown"].forEach(ev=>document.addEventListener(ev, ()=>{ if(BOS.S && BOS.S.session){ BOS.touch(); } }, {passive:true}));
setInterval(()=>{ if(BOS.S.session && BOS.sessionExpired()){ BOS.logout("انتهاء الجلسة"); toast("انتهت الجلسة لعدم النشاط","warn"); render(); } }, 30000);
document.addEventListener("DOMContentLoaded", ()=>{
  BOS.load();
  if(BOS.S.setupDone){ const n = BOS.autoEscalate(); if(n) console.info("auto-escalated", n); if(window.BOS_OPS) BOS_OPS.slaSweep(); }
  render();
  if("serviceWorker" in navigator && location.protocol.startsWith("http")) navigator.serviceWorker.register("sw.js").catch(()=>{});
});
})();
