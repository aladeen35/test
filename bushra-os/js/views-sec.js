/* نظام البشرى لإدارة الشركة — صفحات المرحلة الخامسة: الخصوصية، الأمن والنسخ الاحتياطي، التكاملات */
(function(){
"use strict";
const D = window.BOS_DATA;
const U = window.BOS_UI;
const X = window.BOS_SEC;
const {$, $$, esc, fmtDate, fmtDT, money, avatar, empName, statusBadge, toast, modal, formData, userOptions} = U;
const S = () => BOS.S;
const me = () => BOS.me();
const go = h => { location.hash = h; };
const need = (mod, act) => { if(!BOS.can(me(), mod, act||"view")) throw new Error("لا تملك صلاحية الوصول إلى هذه الصفحة — راجع مدير النظام."); };
const empty = t => `<div class="empty">${esc(t)}</div>`;
const head = (title, sub, actions) => `<div class="page-head"><div><h1>${esc(title)}</h1>${sub?`<div class="sub">${sub}</div>`:""}</div><div class="actions">${actions||""}</div></div>`;
const kpi = (lbl, val, hint, cls) => `<div class="card kpi ${cls||""}"><div class="lbl">${esc(lbl)}</div><div class="val">${val}</div>${hint?`<div class="hint">${hint}</div>`:""}</div>`;
const bindRows = root => $$("[data-go]", root).forEach(el=>el.onclick = e => { if(e.target.closest("button,a,input,select,textarea")) return; go(el.dataset.go); });
const act = (fn, msg) => { try{ fn(); if(msg) toast(msg,"ok"); U.refresh(); }catch(e){ toast(e.message,"bad"); } };
const actA = (p, msg) => p.then(()=>{ if(msg) toast(msg,"ok"); U.refresh(); }).catch(e=>toast(e.message,"bad"));
const tabs = (list, on, base) => `<div class="tabs">${list.map(([k,l])=>`<button class="${k===on?"on":""}" data-href="${base}/${k}">${l}</button>`).join("")}</div>`;
const bindTabs = root => $$("[data-href]",root).forEach(b=>b.onclick=()=>go(b.dataset.href));
const today = () => BOS.now().slice(0,10);
const pct = v => v==null ? "—" : v + "%";
const DSR_CLS = {received:"bad", verifying:"warn", in_progress:"info", pending_approval:"warn", responded:"accent", closed:"ok", rejected:""};
const dsrBadge = s => `<span class="badge ${DSR_CLS[s]}">${esc(X.DSR_STATUS[s])}</span>`;
const clsB = c => `<span class="badge ${({1:"",2:"info",3:"warn",4:"bad"})[c]||""}">${esc(D.CLEARANCE[c]||c)}</span>`;
function copy(text, label){
  const done = () => toast((label||"النص") + " نُسخ","ok");
  try{ navigator.clipboard.writeText(text).then(done).catch(()=>fallback()); }catch(e){ fallback(); }
  function fallback(){ modal("انسخ يدوياً", `<textarea class="input mono" style="min-height:220px" readonly>${esc(text)}</textarea>`, []); setTimeout(()=>{ const t = $(".modal textarea"); if(t){ t.focus(); t.select(); } },50); }
}
function download(content, name, type){ const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob([content],{type})); a.download = name; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(a.href), 2000); }

/* =================== الخصوصية وحماية البيانات (القسم 6.13) =================== */
function privacy(tab){
  need("privacy");
  const u = me(); const s = S(); tab = tab || "requests"; const m = X.metrics();
  const T = [["requests","طلبات أصحاب البيانات"],["register","سجل معالجة البيانات"],["classification","تصنيف البيانات"]];
  let body = "", bind = null;
  if(tab==="requests"){
    body = `<div class="grid g4">${kpi("طلبات مفتوحة", m.openDsr)}${kpi("تجاوزت المهلة", m.lateDsr,"", m.lateDsr?"bad":"ok")}${kpi("الرد ضمن المهلة", pct(m.dsrOnTime))}${kpi("المهلة النظامية", (s.settings.dsrDays||30) + " يوماً")}</div>
      <div class="card" style="margin-top:14px"><div class="card-head"><h2>طلبات الاطلاع والتصحيح والحذف</h2>${X.canPrivacy(u,"create")?'<button class="btn primary" id="new-dsr">＋ تسجيل طلب</button>':""}<a class="btn" href="library/10-03.docx" download>⬇ النموذج الرسمي</a></div>
      <p class="small muted">لا تُسلَّم البيانات ولا تُصحح ولا تُحذف قبل التحقق من الهوية. الحذف إخفاء هوية بعد اعتماد شخص ثانٍ، مع الاحتفاظ بما يلزم نظاماً.</p>
      ${s.dsr.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>النوع</th><th>صاحب البيانات</th><th>القناة</th><th>الاستحقاق</th><th>الهوية</th><th>الحالة</th></tr></thead><tbody>${s.dsr.map(d=>`<tr class="link" data-go="#/dsr/${d.id}"><td class="mono">${esc(d.no)}</td><td class="small">${esc(X.DSR_KINDS[d.kind])}</td><td>${esc(d.subjectName)} <span class="muted small">${d.subjectType==="employee"?"موظف":d.subjectType==="customer"?"عميل":"آخر"}</span></td><td class="small">${esc(d.channel)}</td><td class="small">${fmtDate(d.due)} ${d.due<today() && !["closed","rejected","responded"].includes(d.status)?'<span class="badge bad">متأخر</span>':""}</td><td>${d.identityVerified?'<span class="badge ok">✓</span>':'<span class="badge warn">لم يُتحقق</span>'}</td><td>${dsrBadge(d.status)}</td></tr>`).join("")}</tbody></table></div>`:empty("لا توجد طلبات")}</div>`;
    bind = root => { if($("#new-dsr",root)) $("#new-dsr",root).onclick = dsrEditor; };
  }
  if(tab==="register"){
    const edit = BOS.can(u,"privacy","edit") || BOS.isTop(u);
    body = `<div class="card"><div class="card-head"><h2>سجل أنشطة معالجة البيانات</h2>${edit?'<button class="btn primary" id="new-ro">＋ نشاط</button>':""}<a class="btn" href="library/08-01.xlsx" download>⬇ ورقة «معالجة البيانات»</a></div>
      <div class="table-wrap"><table><thead><tr><th>النظام / الخدمة</th><th>نوع البيانات</th><th>الغرض</th><th>المصدر</th><th>المتلقي</th><th>مدة الاحتفاظ</th><th>الأساس</th><th>التصنيف</th><th>المالك</th></tr></thead><tbody>
      ${s.ropa.map(r=>`<tr ${edit?`class="link" data-ro="${r.id}"`:""}><td><b class="small">${esc(r.system)}</b><div class="muted small">${esc(r.storage)}</div></td><td class="small">${esc(r.dataTypes)}</td><td class="small">${esc(r.purpose)}</td><td class="small">${esc(r.source)}</td><td class="small">${esc(r.recipients)}</td><td class="small">${esc(r.retention)}</td><td class="small">${esc(r.basis)}</td><td>${clsB(r.classification)}</td><td class="small">${empName(r.ownerId)}<div class="muted">راجعه ${fmtDate(r.reviewedAt)}</div></td></tr>`).join("")}</tbody></table></div></div>`;
    bind = root => { if($("#new-ro",root)) $("#new-ro",root).onclick = () => ropaEditor({}); $$("[data-ro]",root).forEach(r=>r.onclick=()=>ropaEditor(s.ropa.find(x=>x.id===r.dataset.ro))); };
  }
  if(tab==="classification"){
    const edit = BOS.can(u,"privacy","edit") || BOS.isTop(u); const c = s.settings.classification;
    body = `<div class="card"><h2 style="margin-bottom:10px">تصنيف فئات البيانات</h2><p class="small muted">يحدد التصنيف من يطّلع على كل فئة، ويُطبق على المستندات بمستوى سرية المنصب.</p>
      ${Object.entries(c).map(([k,v])=>`<div class="row list-item"><span style="flex:1">${esc(k)}</span>${edit?`<select class="input" data-cl="${esc(k)}" style="max-width:170px">${Object.entries(D.CLEARANCE).map(([n,l])=>`<option value="${n}" ${Number(n)===v?"selected":""}>${l}</option>`).join("")}</select>`:clsB(v)}</div>`).join("")}
      ${edit?'<button class="btn primary" id="save-cl" style="margin-top:10px">حفظ</button>':""}</div>
      <div class="card"><h2 style="margin-bottom:10px">من يرى ماذا (مستوى السرية حسب المنصب)</h2><div class="table-wrap"><table><thead><tr><th>المنصب</th><th>أعلى مستوى سرية</th><th>نطاق الرؤية</th><th>MFA</th></tr></thead><tbody>${s.positions.map(p=>`<tr><td class="small">${esc(p.title)}</td><td>${clsB(p.clearance)}</td><td class="small">${esc(D.SCOPES[p.scope])}</td><td>${p.mfa?"✓":""}</td></tr>`).join("")}</tbody></table></div></div>`;
    bind = root => { if($("#save-cl",root)) $("#save-cl",root).onclick = () => act(()=>{ $$("[data-cl]",root).forEach(x=>c[x.dataset.cl] = Number(x.value)); BOS.audit("تعديل تصنيف البيانات","privacy",null,""); BOS.save(); }, "حُفظ"); };
  }
  return {title:"الخصوصية", html:`${head("الخصوصية وحماية البيانات", "سجل المعالجة، التصنيف، وحقوق أصحاب البيانات")}${tabs(T,tab,"#/privacy")}${body}`, bind: root => { bindTabs(root); bindRows(root); bind && bind(root); }};
}
function ropaEditor(r){
  modal(r.id ? "نشاط معالجة: " + r.system : "نشاط معالجة جديد", `<div class="grid g2">
    ${[["system","النظام / الخدمة *"],["dataTypes","نوع البيانات"],["purpose","الغرض *"],["source","مصدر البيانات"],["recipients","المتلقي / المعالج"],["storage","مكان التخزين"],["retention","مدة الاحتفاظ"]].map(([k,l])=>`<div class="field"><label class="f">${l}</label><input class="input" name="${k}" value="${esc(r[k]||"")}"></div>`).join("")}
    <div class="field"><label class="f">الأساس النظامي *</label><select class="input" name="basis">${X.LEGAL_BASIS.map(b=>`<option ${b===r.basis?"selected":""}>${b}</option>`).join("")}</select></div>
    <div class="field"><label class="f">التصنيف</label><select class="input" name="classification">${Object.entries(D.CLEARANCE).map(([n,l])=>`<option value="${n}" ${Number(n)===(r.classification||2)?"selected":""}>${l}</option>`).join("")}</select></div>
    <div class="field"><label class="f">المالك</label><select class="input" name="ownerId">${userOptions(r.ownerId||me().id)}</select></div></div>`,
    [{label:"حفظ", cls:"primary", onClick:bg=>{ X.saveRopa(Object.assign(formData(bg),{id:r.id})); U.route(); }}], true);
}
function dsrEditor(){
  const s = S();
  const bg = modal("تسجيل طلب صاحب بيانات", `<div class="grid g2"><div class="field"><label class="f">النوع *</label><select class="input" name="kind">${Object.entries(X.DSR_KINDS).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select></div>
    <div class="field"><label class="f">صاحب البيانات</label><select class="input" name="subjectType"><option value="customer">عميل / جهة اتصال</option><option value="employee">موظف (حالي أو سابق)</option><option value="other">آخر</option></select></div>
    <div class="field"><label class="f">السجل المرتبط</label><select class="input" name="subjectRef"></select></div>
    <div class="field"><label class="f">الاسم كما ورد في الطلب *</label><input class="input" name="subjectName"></div>
    <div class="field"><label class="f">وسيلة التواصل</label><input class="input" name="contact"></div>
    <div class="field"><label class="f">القناة</label><select class="input" name="channel"><option>بريد</option><option>خطاب رسمي</option><option>بوابة الدعم</option><option>حضور شخصي</option><option>هاتف</option></select></div></div>
    <div class="field"><label class="f">تفاصيل الطلب</label><textarea class="input" name="details"></textarea></div>`,
    [{label:"تسجيل", cls:"primary", onClick:bg=>{ const d = X.createDsr(formData(bg)); go("#/dsr/"+d.id); }}], true);
  const fill = () => { const t = $("[name=subjectType]",bg).value;
    const opts = t==="employee" ? s.employees.map(e=>`<option value="${e.id}">${esc(e.name)}${BOS.active(e)?"":" (سابق)"}</option>`) : t==="customer" ? s.customers.map(c=>`<option value="${c.id}">${esc(c.name)}</option>`) : [];
    $("[name=subjectRef]",bg).innerHTML = `<option value="">—</option>` + opts.join(""); };
  $("[name=subjectType]",bg).onchange = fill; fill();
  $("[name=subjectRef]",bg).onchange = e => { const o = e.target.selectedOptions[0]; if(o && o.value && !$("[name=subjectName]",bg).value) $("[name=subjectName]",bg).value = o.textContent.replace(" (سابق)",""); };
}
function dsr(id){
  need("privacy");
  const d = S().dsr.find(x=>x.id===id); if(!d) throw new Error("الطلب غير موجود");
  const u = me(); const work = X.canPrivacy(u,"edit") || d.handlerId===u.id; const open = !["closed","rejected"].includes(d.status);
  const chk = d.kind==="deletion" ? X.deletionCheck(d) : null;
  let actions = "";
  if(open && work){
    if(!d.identityVerified) actions += '<button class="btn primary" id="verify">التحقق من الهوية</button>';
    else if(d.status==="in_progress"){
      if(d.kind==="access") actions += '<button class="btn primary" id="export">إعداد نسخة البيانات</button>';
      if(d.kind==="correction") actions += '<button class="btn primary" id="correct">تصحيح حقل</button>';
      if(d.kind==="deletion") actions += '<button class="btn primary" id="propose">اقتراح إخفاء الهوية</button>';
      if(d.kind!=="deletion") actions += '<button class="btn" id="respond">تسجيل الرد</button>';
    }
    if(d.status==="responded") actions += '<button class="btn ok solid" id="close">إغلاق</button>';
    if(["received","verifying","in_progress"].includes(d.status)) actions += '<button class="btn danger" id="reject">رفض الطلب</button>';
  }
  if(d.status==="pending_approval" && X.canPrivacy(u,"approve") && u.id!==d.proposedBy) actions += '<button class="btn danger solid" id="approve-del">اعتماد وتنفيذ إخفاء الهوية</button>';
  return {title:d.no, html:`${head("🔏 " + X.DSR_KINDS[d.kind], `<span class="mono">${esc(d.no)}</span> · ${dsrBadge(d.status)} · الاستحقاق ${fmtDate(d.due)} ${d.due<today()&&open&&d.status!=="responded"?'<span class="badge bad">متأخر</span>':""}`, actions)}
    <div class="route-h" style="margin-bottom:14px">${X.DSR_FLOW.filter(([k])=>k!=="pending_approval" || d.kind==="deletion").map(([k,l],i)=>`${i?'<span class="arrow">←</span>':""}<span class="chip" style="${k===d.status?"border-color:var(--accent);background:var(--accent-soft);font-weight:700":""}">${esc(l)}</span>`).join("")}</div>
    <div class="grid g2" style="align-items:start"><div class="card"><dl class="kv"><dt>صاحب البيانات</dt><dd>${esc(d.subjectName)} ${d.subjectRef?(d.subjectType==="customer"?`<a href="#/customer/${d.subjectRef}">السجل</a>`:`<a href="#/person/${d.subjectRef}">السجل</a>`):""}</dd>
      <dt>التواصل / القناة</dt><dd>${esc(d.contact||"—")} · ${esc(d.channel)}</dd><dt>التفاصيل</dt><dd style="white-space:pre-wrap">${esc(d.details||"—")}</dd>
      <dt>المسؤول</dt><dd>${empName(d.handlerId)}</dd><dt>الهوية</dt><dd>${d.identityVerified?`✓ ${esc(d.verifyMethod)} — ${empName(d.verifiedBy)} ${fmtDT(d.verifiedAt)}`:'<span class="badge warn">لم يُتحقق بعد</span>'}</dd>
      ${d.exportedAt?`<dt>نسخة البيانات</dt><dd>أُعدت ${fmtDT(d.exportedAt)} — ${empName(d.exportedBy)}</dd>`:""}
      ${(d.corrections||[]).length?`<dt>التصحيحات</dt><dd>${d.corrections.map(c=>`${esc(c.field)}: «${esc(c.before)}» ← «${esc(c.after)}»`).join("<br>")}</dd>`:""}
      ${d.proposedBy?`<dt>اقتراح الحذف</dt><dd>${empName(d.proposedBy)} ${d.approvedBy?"· اعتمده " + empName(d.approvedBy):""}</dd>`:""}
      ${d.response?`<dt>الرد</dt><dd style="white-space:pre-wrap">${esc(d.response)}</dd>`:""}</dl></div>
    <div class="card">${chk?`<h2 style="margin-bottom:8px">فحص الحذف</h2>${chk.holds.length?`<div class="note bad small" style="margin-bottom:8px"><b>موانع:</b> ${chk.holds.map(esc).join(" · ")}</div>`:'<div class="note small" style="margin-bottom:8px">لا توجد موانع</div>'}<div class="small"><b>يُحتفظ به نظاماً:</b><ul>${chk.keeps.map(k=>`<li>${esc(k)}</li>`).join("")}</ul></div>`:""}
      <h2 style="margin:10px 0 8px">السجل</h2>${d.log.slice().reverse().map(l=>`<div class="small list-item"><span class="muted">${fmtDT(l.at)}</span><div class="grow">${dsrBadge(l.to)} ${empName(l.by)} ${esc(l.note||"")}</div></div>`).join("")}</div></div>`,
    bind: root => {
      const b = (id, fn) => { const el = $("#"+id,root); if(el) el.onclick = fn; };
      b("verify", () => U.ask("التحقق من هوية " + d.subjectName, "طريقة التحقق (مطابقة البطاقة، البريد المسجل، حضور شخصي…)", v=>act(()=>X.verifyIdentity(d,v),"تم التحقق")));
      b("export", () => { try{ const data = X.exportSubject(d); const txt = JSON.stringify(data,null,2);
        modal("نسخة بيانات " + d.subjectName, `<p class="small muted">${Object.keys(data.sections).length} قسم. سلّمها لصاحب الطلب عبر قناة آمنة.</p><pre class="mono small" style="max-height:340px;overflow:auto;background:var(--surface-2);padding:10px;border-radius:10px;white-space:pre-wrap">${esc(txt)}</pre>`,
          [{label:"نسخ", onClick:()=>{ copy(txt,"نسخة البيانات"); return false; }},{label:"تنزيل JSON", cls:"primary", onClick:()=>{ download(txt, d.no + ".json","application/json"); return false; }}], true); U.refresh(); }catch(e){ toast(e.message,"bad"); } });
      b("correct", () => modal("تصحيح بيانات", `<div class="field"><label class="f">الحقل</label><select class="input" name="field">${(d.subjectType==="employee"?[["name","الاسم"],["email","البريد"],["phone","الهاتف"]]:[["name","الاسم"],["contact","جهة الاتصال"],["phone","الهاتف"],["email","البريد"]]).map(([k,l])=>`<option value="${k}">${l}</option>`).join("")}</select></div><div class="field"><label class="f">القيمة الصحيحة</label><input class="input" name="value"></div>`,
        [{label:"تصحيح", cls:"primary", onClick:bg=>{ const f = formData(bg); X.correctSubject(d,f.field,f.value); U.refresh(); }}]));
      b("propose", () => U.ask("اقتراح إخفاء هوية " + d.subjectName, "ملاحظة للمعتمد", v=>act(()=>X.proposeDeletion(d,v),"أُرسل للاعتماد"), {optional:true}));
      b("approve-del", () => U.ask("اعتماد الحذف", "سيُستبدل الاسم ووسائل التواصل باسم مستعار، وتُحذف الملاحظات والمراسلات الشخصية. لا يمكن التراجع.", ()=>act(()=>X.approveDeletion(d),"نُفذ إخفاء الهوية"), {confirmOnly:true, okLabel:"تنفيذ", cls:"danger solid"}));
      b("respond", () => U.ask("الرد على صاحب الطلب", "نص الرد المرسل", v=>act(()=>X.respondDsr(d,v),"سُجل الرد")));
      b("reject", () => U.ask("رفض الطلب", "سبب الرفض (يُبلَّغ لصاحب الطلب)", v=>act(()=>X.rejectDsr(d,v)), {cls:"danger solid", okLabel:"رفض"}));
      b("close", () => act(()=>X.closeDsr(d),"أُغلق الطلب"));
    }};
}

/* =================== الأمن والنسخ الاحتياطي =================== */
function security(tab){
  need("security");
  const u = me(); const s = S(); tab = tab || "overview"; const m = X.metrics();
  const edit = BOS.can(u,"security","edit") || BOS.isTop(u);
  const T = [["overview","نظرة عامة"],["log","سجلات الأمان"],["access","مراجعة الصلاحيات"],["backups","النسخ الاحتياطي"],["incidents","الحوادث"],["auth","الدخول وكلمات المرور"],["integrations","التكاملات"]];
  let body = "", bind = null;
  if(tab==="overview"){
    const an = X.anomalies();
    body = `<div class="grid g4">${kpi("آخر نسخة احتياطية", m.backupAge==null?"لا توجد":m.backupAge + " يوم", "السياسة كل " + s.settings.backupEveryDays + " أيام · " + m.untested + " لم تُختبر", m.backupOverdue?"bad":"ok")}
      ${kpi("مراجعة الصلاحيات", m.reviewOverdue?"مستحقة":"محدّثة", m.lastReview?"آخرها " + fmtDate(m.lastReview):"لم تُجر بعد", m.reviewOverdue?"warn":"ok")}
      ${kpi("حسابات غير نشطة", m.inactive, "أكثر من " + s.settings.inactiveDays + " يوماً", m.inactive?"warn":"")}${kpi("حوادث مفتوحة", m.openIncidents, m.anomalies + " تنبيه أمني", m.openIncidents?"bad":"ok")}</div>
      <div class="grid g2" style="margin-top:14px;align-items:start"><div class="card"><h2 style="margin-bottom:10px">تنبيهات</h2>${an.length?an.map(a=>`<div class="note ${a.kind} small" style="margin-bottom:6px">${esc(a.text)}</div>`).join(""):empty("لا تنبيهات")}</div>
      <div class="card"><h2 style="margin-bottom:10px">الضوابط الإلزامية (القسم 8.2)</h2>${[
        [s.settings.mfa, "مصادقة متعددة العوامل للمدير العام والمالية والموارد البشرية والأمن"],
        [true, "انتهاء الجلسة بعد " + s.settings.sessionMinutes + " دقيقة من عدم النشاط"],
        [BOS.verifyAudit().ok, "سجل تدقيق سليم لا يُمسح (" + s.audit.length + " حدث)"],
        [s.backups.some(b=>b.kind.includes("مشفرة")), "نسخ احتياطي مشفر"],
        [s.backups.some(b=>b.restoreTested), "اختبار استعادة ناجح"],
        [!m.reviewOverdue, "مراجعة صلاحيات دورية كل " + s.settings.accessReviewDays + " يوماً"],
        [true, "إيقاف المستخدم فوراً مع قائمة تسليم العهد"],
        [s.settings.email && s.settings.email.enabled, "البريد لا يحمل البيانات السرية — رابط آمن وملخص محدود"],
        [true, "تنبيه عند تنزيل ملفات حساسة بكميات كبيرة"],
        [s.settings.localAuth, "كلمات مرور محلية مع قفل بعد المحاولات الفاشلة"]
      ].map(([ok,t])=>`<div class="list-item small"><span class="badge ${ok?"ok":"warn"}">${ok?"✓":"!"}</span><div class="grow">${esc(t)}</div></div>`).join("")}
      <p class="small muted">التشفير أثناء النقل والتخزين على الخادم يتطلب نشر النظام على خادم الشركة.</p></div></div>`;
  }
  if(tab==="log"){
    const kinds = {all:"كل أحداث الأمان", login:"الدخول والخروج", denied:"الوصول المرفوض", perm:"تغيير الصلاحيات", export:"التصدير والتنزيل"};
    body = `<div class="card"><div class="row" style="margin-bottom:10px"><select class="input" id="lk" style="max-width:220px">${Object.entries(kinds).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select><input class="input" id="lq" placeholder="بحث" style="max-width:240px"><span class="spacer"></span>${BOS.can(u,"security","export")||BOS.isTop(u)?'<button class="btn" id="lcsv">⬇ CSV</button>':""}</div><div id="ll"></div></div>`;
    bind = root => {
      const pick = () => { const k = $("#lk",root).value, q = $("#lq",root).value.trim();
        return s.audit.slice().reverse().filter(a=> (k==="all" ? X.isSecurityEvent(a) : k==="login" ? /تسجيل (دخول|خروج)|انتهاء الجلسة|فشل|قفل الحساب|كلمة المرور/.test(a.action) : k==="denied" ? /مرفوضة|فشل|قفل/.test(a.action) : k==="perm" ? X.isPermEvent(a) : X.isExportEvent(a)) && (!q || (a.action+a.details+a.actorName).includes(q))); };
      const draw = () => { const l = pick();
        $("#ll",root).innerHTML = l.length ? `<div class="table-wrap"><table><thead><tr><th>#</th><th>الوقت</th><th>المستخدم</th><th>الحدث</th><th>التفاصيل</th></tr></thead><tbody>${l.slice(0,500).map(a=>`<tr><td class="mono">${a.seq}</td><td class="small">${fmtDT(a.at)}</td><td class="small"><b>${esc(a.actorName)}</b><div class="muted">${esc(a.actorPos)}</div></td><td><span class="badge ${/فشل|مرفوضة|قفل|تنبيه/.test(a.action)?"bad":/تصدير|تنزيل|نسخة/.test(a.action)?"info":""}">${esc(a.action)}</span></td><td class="small">${esc(a.details)}</td></tr>`).join("")}</tbody></table></div>` : empty("لا أحداث"); };
      $("#lk",root).onchange = draw; $("#lq",root).oninput = draw; draw();
      if($("#lcsv",root)) $("#lcsv",root).onclick = () => { const rows = [["seq","at","actor","action","details"]].concat(pick().map(a=>[a.seq,a.at,a.actorName,a.action,a.details]));
        download("﻿" + rows.map(r=>r.map(x=>'"'+String(x==null?"":x).replace(/"/g,'""')+'"').join(",")).join("\n"), "security-log-" + today() + ".csv","text/csv"); BOS.audit("تصدير سجل الأمان","security",null,rows.length-1 + " حدث"); BOS.save(); };
    };
  }
  if(tab==="access"){
    const open = s.accessReviews.find(r=>!r.closedAt);
    const list = s.employees.filter(BOS.active);
    body = `<div class="card"><div class="card-head"><h2>${open?"مراجعة الصلاحيات " + esc(open.no):"الحسابات والصلاحيات الحالية"}</h2>${edit && !open?'<button class="btn primary" id="start">بدء مراجعة دورية</button>':""}${open && edit?'<button class="btn ok solid" id="finish">إغلاق المراجعة وتطبيق القرارات</button>':""}</div>
      <p class="small muted">تُراجع كل ${s.settings.accessReviewDays} يوماً: لكل حساب قرار «إبقاء» أو «سحب الوصول» مع سبب. السحب يوقف الحساب فوراً ويفتح قائمة تسليم العهد.</p>
      <div class="table-wrap"><table><thead><tr><th>الموظف</th><th>المنصب</th><th>آخر دخول</th><th>ملاحظات</th>${open?"<th>القرار</th>":""}</tr></thead><tbody>
      ${(open ? open.items : list.map(e=>({empId:e.id, position:BOS.posTitle(e.positionId), flags:X.accessFlags(e)}))).map(it=>`<tr><td><a href="#/person/${it.empId}">${empName(it.empId)}</a></td><td class="small">${esc(it.position)}</td><td class="small">${X.lastLogin(it.empId)?fmtDT(X.lastLogin(it.empId)):"—"}</td><td class="small">${it.flags.map(f=>`<span class="badge warn" style="margin:1px">${esc(f)}</span>`).join("")||'<span class="muted">—</span>'}</td>
        ${open?`<td>${edit?`<div class="row" style="gap:4px"><button class="btn sm ${it.decision==="keep"?"ok solid":""}" data-dec="keep" data-emp="${it.empId}">إبقاء</button><button class="btn sm ${it.decision==="revoke"?"danger solid":"danger"}" data-dec="revoke" data-emp="${it.empId}">سحب</button></div>${it.note?`<div class="small muted">${esc(it.note)}</div>`:""}`:esc(it.decision||"—")}</td>`:""}</tr>`).join("")}</tbody></table></div></div>
      ${s.accessReviews.filter(r=>r.closedAt).length?`<div class="card"><h2 style="margin-bottom:8px">مراجعات سابقة</h2>${s.accessReviews.filter(r=>r.closedAt).map(r=>`<div class="small list-item"><span class="mono">${esc(r.no)}</span><div class="grow">${fmtDate(r.closedAt)} — ${empName(r.closedBy)} — ${r.items.length} حساب، سُحب ${r.items.filter(i=>i.decision==="revoke").length}</div></div>`).join("")}</div>`:""}`;
    bind = root => {
      if($("#start",root)) $("#start",root).onclick = () => act(()=>X.startReview(),"بدأت المراجعة");
      if($("#finish",root)) $("#finish",root).onclick = () => act(()=>X.closeReview(open),"أُغلقت المراجعة");
      $$("[data-dec]",root).forEach(b=>b.onclick=()=>{ const dec = b.dataset.dec, id = b.dataset.emp;
        if(dec==="revoke") return U.ask("سحب وصول " + (BOS.byId(id)||{}).name, "السبب", v=>act(()=>X.decide(open,id,"revoke",v)), {cls:"danger solid"});
        act(()=>X.decide(open,id,"keep","")); });
    };
  }
  if(tab==="backups"){
    const bd = X.backupDue(); const can = BOS.can(u,"security","export") || BOS.isTop(u);
    body = `<div class="grid g2" style="align-items:start"><div class="card"><h2 style="margin-bottom:8px">إنشاء نسخة مشفرة</h2>
        <p class="small muted">تُشفَّر كل بيانات الشركة بمعيار AES-256-GCM بعبارة تختارها. احفظ العبارة في مكان آمن منفصل؛ دونها لا يمكن فتح النسخة. سياسة الشركة: نسخة كل ${s.settings.backupEveryDays} أيام.</p>
        ${bd.overdue?`<div class="note warn small" style="margin-bottom:8px">${bd.last?"آخر نسخة قبل " + Math.floor(bd.age) + " يوماً":"لا توجد نسخة احتياطية بعد"}</div>`:""}
        ${can?`<div class="field"><label class="f">عبارة التشفير</label><input class="input" type="password" id="bp" autocomplete="new-password" dir="ltr"></div><div class="field"><label class="f">تأكيدها</label><input class="input" type="password" id="bp2" autocomplete="new-password" dir="ltr"></div><button class="btn primary" id="mk">إنشاء النسخة</button>`:'<div class="muted small">لمسؤول الأمن أو المدير العام</div>'}</div>
      <div class="card"><h2 style="margin-bottom:8px">اختبار الاستعادة</h2><p class="small muted">يفك التشفير ويتحقق من البصمة ومن سلسلة سجل التدقيق كاملة دون المساس بالبيانات الحالية.</p>
        <div class="field"><label class="f">ملف النسخة</label><input class="input" type="file" id="bf" accept=".json,application/json"></div>
        <div class="field"><label class="f">أو الصق محتواها</label><textarea class="input mono" id="bt" style="min-height:70px" dir="ltr"></textarea></div>
        <div class="field"><label class="f">عبارة التشفير</label><input class="input" type="password" id="bpt" dir="ltr"></div>
        <div class="row"><button class="btn primary" id="test">اختبار دون استعادة</button>${BOS.isTop(u)?'<button class="btn danger" id="apply">استعادة فعلية</button>':""}</div><div id="tres" style="margin-top:10px"></div></div></div>
      <div class="card"><h2 style="margin-bottom:8px">سجل النسخ</h2>${s.backups.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>الوقت</th><th>النوع</th><th>الحجم</th><th>البصمة</th><th>أحداث التدقيق</th><th>اختبار الاستعادة</th></tr></thead><tbody>${s.backups.map(b=>`<tr><td class="mono">${esc(b.no)}</td><td class="small">${fmtDT(b.at)} — ${empName(b.by)}</td><td class="small">${esc(b.kind)}</td><td>${Math.round(b.size/1024)} ك.ب</td><td class="mono small">${esc(b.sha256.slice(0,16))}</td><td>${b.auditCount}</td><td>${b.restoreTested?`<span class="badge ok">ناجح ${fmtDate(b.testAt)}</span>`:'<span class="badge warn">لم يُختبر</span>'}</td></tr>`).join("")}</tbody></table></div>`:empty("لا توجد نسخ")}</div>`;
    bind = root => {
      if($("#mk",root)) $("#mk",root).onclick = () => { const p = $("#bp",root).value; if(p !== $("#bp2",root).value) return toast("العبارتان غير متطابقتين","bad");
        X.encryptedBackup(p).then(({pkg, rec})=>{ download(pkg, "bushra-os-" + rec.no + ".json","application/json");
          modal("أُنشئت النسخة " + rec.no, `<p class="small">إن لم يبدأ التنزيل (في رابط التجربة يُحجب التنزيل)، انسخ المحتوى المشفر واحفظه في ملف.</p><div class="small mono">SHA-256: ${esc(rec.sha256)}</div>`,
            [{label:"نسخ المحتوى المشفر", cls:"primary", onClick:()=>{ copy(pkg,"النسخة المشفرة"); return false; }}]); U.refresh(); }).catch(e=>toast(e.message,"bad")); };
      const readInput = () => new Promise((res, rej) => { const f = $("#bf",root).files[0]; if(f){ const rd = new FileReader(); rd.onload = () => res(rd.result); rd.onerror = () => rej(new Error("تعذرت قراءة الملف")); rd.readAsText(f); } else if($("#bt",root).value.trim()) res($("#bt",root).value.trim()); else rej(new Error("اختر ملفاً أو الصق المحتوى")); });
      $("#test",root).onclick = () => readInput().then(t=>X.testRestore(t, $("#bpt",root).value)).then(r=>{
        $("#tres",root).innerHTML = `<div class="note ${r.ok?"":"bad"} small">${r.ok?"✓ النسخة سليمة وقابلة للاستعادة":"✕ سلسلة التدقيق مكسورة عند الحدث " + r.brokenAt}<br>${esc(r.company)} · ${r.employees} موظف · ${r.requests} طلب · ${r.documents} مستند · ${r.invoices} فاتورة · ${r.audit} حدث تدقيق</div>`; }).catch(e=>{ $("#tres",root).innerHTML = `<div class="note bad small">${esc(e.message)}</div>`; });
      if($("#apply",root)) $("#apply",root).onclick = () => U.ask("استعادة فعلية", "ستُستبدل كل البيانات الحالية بمحتوى النسخة. أنشئ نسخة من الوضع الحالي أولاً إن احتجت إليه.", () => { readInput().then(t=>X.applyRestore(t, $("#bpt",root).value)).then(()=>{ toast("تمت الاستعادة — سجّل الدخول","ok"); U.render(); }).catch(e=>toast(e.message,"bad")); }, {confirmOnly:true, okLabel:"استعادة", cls:"danger solid"});
    };
  }
  if(tab==="incidents"){
    const inc = s.requests.filter(r=>r.type==="incident" && BOS.canSeeRequest(u,r));
    body = `<div class="card"><div class="card-head"><h2>سجل الحوادث الأمنية</h2><a class="btn primary" href="#/new/incident">＋ إبلاغ عن حادث</a><a class="btn" href="library/10-02.docx" download>⬇ نموذج الإبلاغ</a></div>
      <p class="small muted">كل حادث يمر بمسار الموافقة، وله خطة استجابة من ست خطوات. لا يُغلق الحادث قبل اكتمالها، وقبل توثيق قرار الإبلاغ إن مسّ بيانات شخصية. الوصول مقيد بفريق الاستجابة.</p>
      ${inc.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>الحادث</th><th>الخطورة</th><th>الخطة</th><th>الحالة</th><th>التاريخ</th></tr></thead><tbody>${inc.map(r=>{ const p = X.plan(r); const d = p.steps.filter(x=>x.done).length;
        return `<tr class="link" data-go="#/request/${r.id}"><td class="mono">${esc(r.no)}</td><td>${esc(r.data.system)} <div class="small muted">${esc((r.data.details||"").slice(0,70))}</div></td><td><span class="badge ${/حرجة|عالية/.test(r.data.severity)?"bad":"warn"}">${esc(r.data.severity||"")}</span>${r.data.sensitive?' <span class="badge bad">بيانات شخصية</span>':""}</td><td class="small">${d}/${p.steps.length}</td><td>${statusBadge(r.status)}</td><td class="small">${fmtDate(r.createdAt)}</td></tr>`; }).join("")}</tbody></table></div>`:empty("لا حوادث ضمن صلاحيتك")}</div>`;
  }
  if(tab==="auth"){
    const top = BOS.isTop(u);
    body = `<div class="grid g2" style="align-items:start"><div class="card"><h2 style="margin-bottom:10px">سياسة الدخول</h2>
      <label class="check"><input type="checkbox" id="la" ${s.settings.localAuth?"checked":""} ${top?"":"disabled"}> تفعيل كلمات المرور المحلية لكل المستخدمين</label>
      <p class="small muted">يعيّن كل مستخدم كلمة مروره عند أول دخول. تُحفظ بصمتها فقط (PBKDF2-SHA256، 150 ألف تكرار مع ملح عشوائي). لا تُعرض ولا تُرسل لأحد. بعدها تُطلب المصادقة متعددة العوامل للمناصب الحساسة.</p>
      <div class="grid g2"><div class="field"><label class="f">القفل بعد محاولات فاشلة</label><input class="input" type="number" id="lat" value="${s.settings.lockout.attempts}" ${top?"":"disabled"}></div><div class="field"><label class="f">مدة القفل (دقيقة)</label><input class="input" type="number" id="lam" value="${s.settings.lockout.minutes}" ${top?"":"disabled"}></div>
      <div class="field"><label class="f">غير نشط بعد (يوم)</label><input class="input" type="number" id="ina" value="${s.settings.inactiveDays}" ${top?"":"disabled"}></div><div class="field"><label class="f">مراجعة الصلاحيات كل (يوم)</label><input class="input" type="number" id="arv" value="${s.settings.accessReviewDays}" ${top?"":"disabled"}></div>
      <div class="field"><label class="f">نسخة احتياطية كل (يوم)</label><input class="input" type="number" id="bke" value="${s.settings.backupEveryDays}" ${top?"":"disabled"}></div><div class="field"><label class="f">مهلة طلبات الخصوصية (يوم)</label><input class="input" type="number" id="dsd" value="${s.settings.dsrDays}" ${top?"":"disabled"}></div></div>
      ${top?'<button class="btn primary" id="save-auth">حفظ</button>':""}</div>
      <div class="card"><h2 style="margin-bottom:10px">حالة كلمات المرور</h2>${s.settings.localAuth?`<div class="table-wrap"><table><thead><tr><th>الموظف</th><th>الحالة</th><th></th></tr></thead><tbody>${s.employees.filter(BOS.active).map(e=>`<tr><td class="small">${esc(e.name)}</td><td>${X.lockedFor(e)?`<span class="badge bad">مقفل ${X.lockedFor(e)} د</span>`:X.hasPassword(e)?`<span class="badge ok">معيّنة ${fmtDate(e.auth.setAt)}</span>`:'<span class="badge warn">تُعيَّن عند أول دخول</span>'}</td><td>${X.hasPassword(e) && e.id!==u.id && (BOS.can(u,"people","manage")||top||(BOS.pos(u.positionId)||{}).key==="secops")?`<button class="btn sm" data-reset="${e.id}">إعادة تعيين</button>`:""}</td></tr>`).join("")}</tbody></table></div>`:empty("كلمات المرور المحلية غير مفعلة — الدخول الآن باختيار المستخدم (نسخة تجريبية)")}</div></div>`;
    bind = root => {
      if($("#save-auth",root)) $("#save-auth",root).onclick = () => act(()=>{ const st = s.settings; const before = st.localAuth;
        st.localAuth = $("#la",root).checked; st.lockout = {attempts:Math.max(3,Number($("#lat",root).value||5)), minutes:Math.max(1,Number($("#lam",root).value||15))};
        st.inactiveDays = Number($("#ina",root).value||30); st.accessReviewDays = Number($("#arv",root).value||90); st.backupEveryDays = Number($("#bke",root).value||7); st.dsrDays = Number($("#dsd",root).value||30);
        BOS.audit("تعديل إعدادات الشركة","settings",null,"سياسة الدخول والأمن" + (before!==st.localAuth?" — كلمات المرور المحلية: " + (st.localAuth?"مفعلة":"معطلة"):"")); BOS.save(); }, "حُفظ");
      $$("[data-reset]",root).forEach(b=>b.onclick=()=>act(()=>X.resetPassword(BOS.byId(b.dataset.reset)),"أعيد التعيين"));
    };
  }
  if(tab==="integrations"){
    const top = BOS.isTop(u); const pay = s.settings.payment; const em = s.settings.email;
    body = `<div class="grid g2" style="align-items:start">
      <div class="card"><h2 style="margin-bottom:6px">البريد الإلكتروني</h2><span class="badge warn">صندوق صادر — الإرسال الفعلي يتطلب خادم بريد</span>
        <p class="small muted" style="margin-top:8px">كل إشعار يُجهَّز كرسالة لصاحبه. الإشعارات السرية (الحوادث، الملف السري، التقييمات، الخصوصية) تُرسل بعنوان عام دون تفاصيل، مع رابط آمن داخل النظام.</p>
        <label class="check"><input type="checkbox" id="em-on" ${em.enabled?"checked":""} ${top?"":"disabled"}> تجهيز رسائل البريد للإشعارات</label>
        <div class="field"><label class="f">المرسل</label><input class="input" id="em-from" value="${esc(em.from)}" dir="ltr" ${top?"":"disabled"}></div></div>
      <div class="card"><h2 style="margin-bottom:6px">الدفع</h2><span class="badge warn">بوابة الدفع غير مربوطة</span>
        <p class="small muted" style="margin-top:8px">تحمل كل فاتورة «مرجع دفع» برقم تحقق يمنع أخطاء الإدخال، وتظهر عليها بيانات الحساب. الربط مع بوابة دفع يتم بعد اختيار المزود.</p>
        <div class="field"><label class="f">البنك</label><input class="input" id="pb" value="${esc(pay.bank)}" ${top?"":"disabled"}></div><div class="field"><label class="f">رقم الحساب / IBAN</label><input class="input" id="pa" value="${esc(pay.account)}" dir="ltr" ${top?"":"disabled"}></div>
        <div class="field"><label class="f">تعليمات الدفع</label><input class="input" id="pi" value="${esc(pay.instructions)}" ${top?"":"disabled"}></div>
        <div class="field"><label class="f">تحقق من مرجع دفع</label><div class="row"><input class="input mono" id="pref" dir="ltr" placeholder="INV-2026-0001-xx" style="flex:1"><button class="btn sm" id="pchk">تحقق</button></div></div></div>
      <div class="card"><h2 style="margin-bottom:6px">التوقيع الإلكتروني</h2><span class="badge info">توقيع داخلي مفعّل</span>
        <p class="small muted" style="margin-top:8px">يوقّع المستخدم بخط يده على الشاشة لإصدار محدد من مستند أو محضر تسليم. يُربط التوقيع ببصمة SHA-256 للمحتوى، فأي تعديل لاحق يُظهر أن التوقيع لم يعد مطابقاً. التوقيع الداخلي لا يغني عن التوقيع المفوض أو التوثيق الرسمي.</p>
        <div class="small">توقيعات مسجلة: <b>${s.signatures.length}</b></div></div>
      <div class="card"><h2 style="margin-bottom:6px">تثبيت التطبيق على الجوال</h2><span class="badge ok">مفعّل</span>
        <p class="small muted" style="margin-top:8px">النظام تطبيق ويب تقدّمي: من المتصفح اختر «إضافة إلى الشاشة الرئيسية» (أو زر التثبيت في قائمة الحساب)، فيعمل كتطبيق بشريط تنقل سفلي ويعمل دون اتصال بعد أول زيارة.</p></div>
    </div>${top?'<button class="btn primary" id="save-int" style="margin-top:12px">حفظ إعدادات التكاملات</button>':""}
    <div class="card" style="margin-top:14px"><div class="card-head"><h2>صندوق البريد الصادر (${s.outbox.length})</h2></div>${s.outbox.length?`<div class="table-wrap"><table><thead><tr><th>الوقت</th><th>إلى</th><th>العنوان</th><th>سري</th><th></th></tr></thead><tbody>${s.outbox.slice(0,60).map(m=>`<tr><td class="small">${fmtDT(m.at)}</td><td class="mono small">${esc(m.to)}</td><td class="small">${esc(m.subject)}</td><td>${m.confidential?'<span class="badge bad">ملخص محجوب</span>':""}</td><td><button class="btn sm" data-mail="${m.id}">عرض</button></td></tr>`).join("")}</tbody></table></div>`:empty("لا رسائل")}</div>`;
    bind = root => {
      if($("#save-int",root)) $("#save-int",root).onclick = () => act(()=>{ em.enabled = $("#em-on",root).checked; em.from = $("#em-from",root).value.trim(); pay.bank = $("#pb",root).value.trim(); pay.account = $("#pa",root).value.trim(); pay.instructions = $("#pi",root).value.trim();
        BOS.audit("تعديل إعدادات الشركة","settings",null,"التكاملات: البريد والدفع"); BOS.save(); }, "حُفظ");
      $("#pchk",root).onclick = () => { const v = $("#pref",root).value.trim(); toast(X.verifyPaymentRef(v) ? "✓ مرجع دفع صحيح" : "✕ المرجع غير صحيح — تحقق من الأرقام", X.verifyPaymentRef(v)?"ok":"bad"); };
      $$("[data-mail]",root).forEach(b=>b.onclick=()=>{ const m = s.outbox.find(x=>x.id===b.dataset.mail);
        modal("رسالة إلى " + m.to, `<dl class="kv"><dt>من</dt><dd class="mono">${esc(m.from)}</dd><dt>إلى</dt><dd class="mono">${esc(m.to)}</dd><dt>العنوان</dt><dd>${esc(m.subject)}</dd><dt>الحالة</dt><dd>${esc(m.status)}</dd></dl><pre class="small" style="white-space:pre-wrap;background:var(--surface-2);padding:10px;border-radius:10px;margin-top:10px">${esc(m.body)}</pre>`,
          [{label:"نسخ الرسالة", cls:"primary", onClick:()=>{ copy("إلى: " + m.to + "\nالعنوان: " + m.subject + "\n\n" + m.body, "الرسالة"); return false; }}]); });
    };
  }
  return {title:"الأمن والنسخ الاحتياطي", html:`${head("الأمن والنسخ الاحتياطي", "سجلات الأمان، مراجعة الصلاحيات، النسخ المشفر، الحوادث والتكاملات")}${tabs(T,tab,"#/security")}${body}`, bind: root => { bindTabs(root); bindRows(root); bind && bind(root); }};
}

/* =================== خطة الاستجابة داخل صفحة الحادث =================== */
function requestExtra(r){
  if(r.type!=="incident") return {html:"", bind:null};
  const u = me(); const p = X.plan(r); const work = X.canWorkIncident(u,r) && !["closed","rejected","cancelled"].includes(r.status);
  return {html:`<div class="card" style="margin-top:14px;border-color:color-mix(in srgb,var(--bad) 35%,transparent)"><div class="card-head"><h2>🚨 خطة الاستجابة للحادث</h2><span class="badge ${p.steps.every(s=>s.done)?"ok":"warn"}">${p.steps.filter(s=>s.done).length}/${p.steps.length}</span></div>
    ${p.personalData?'<div class="note bad small" style="margin-bottom:8px">الحادث يمس بيانات شخصية: قرار الإبلاغ إلزامي قبل الإغلاق.</div>':""}
    ${p.steps.map(st=>`<div class="list-item"><span class="badge ${st.done?"ok":""}">${st.done?"✓":"○"}</span><div class="grow small"><b>${esc(st.label)}</b>${st.note?`<div>${esc(st.note)}</div>`:""}${st.by?`<div class="muted">${empName(st.by)} · ${fmtDT(st.at)}</div>`:""}${st.key==="notify"&&p.notify?`<div><b>القرار:</b> ${esc(p.notify)}</div>`:""}</div>${work?`<button class="btn sm" data-ps="${st.key}">${st.done?"تعديل":"إتمام"}</button>`:""}</div>`).join("")}
    <p class="small muted">لا تُغلق المرحلة الأخيرة من مسار الحادث قبل اكتمال الخطة.</p></div>`,
    bind: root => $$("[data-ps]",root).forEach(b=>b.onclick=()=>{ const st = p.steps.find(x=>x.key===b.dataset.ps);
      modal(st.label, `<div class="field"><label class="f">ما الذي تم؟ *</label><textarea class="input" name="note">${esc(st.note||"")}</textarea></div>
        ${st.key==="notify"?`<div class="field"><label class="f">قرار الإبلاغ *</label><select class="input" name="decision"><option value="">—</option><option ${p.notify==="لا يلزم الإبلاغ — لا بيانات شخصية متأثرة"?"selected":""}>لا يلزم الإبلاغ — لا بيانات شخصية متأثرة</option><option ${p.notify==="أُبلغ العملاء المتأثرون"?"selected":""}>أُبلغ العملاء المتأثرون</option><option ${p.notify==="أُبلغت الجهة المختصة والعملاء"?"selected":""}>أُبلغت الجهة المختصة والعملاء</option></select></div>`:""}
        <label class="check"><input type="checkbox" name="done" ${st.done?"":"checked"}> الخطوة مكتملة</label>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ X.updateStep(r, st.key, formData(bg)); U.refresh(); }}]); })};
}

/* =================== التوقيع الإلكتروني الداخلي =================== */
function signatureModal(entity, entityId, version, content, title){
  const bg = modal("توقيع إلكتروني — " + title, `<p class="small muted">ارسم توقيعك في المربع. يُربط بالإصدار ${esc(version)} وببصمة محتواه؛ أي تعديل لاحق يلغي تطابقه.</p>
    <canvas class="sig-pad" width="460" height="170"></canvas><div class="row" style="margin-top:6px"><button class="btn sm" type="button" data-clear>مسح</button><span class="small muted">${esc(me().name)} — ${esc(BOS.posTitle(me().positionId))}</span></div>`,
    [{label:"توقيع", cls:"primary", onClick:bg=>{ const c = $("canvas",bg); if(!drawn) throw new Error("ارسم توقيعك أولاً");
      X.sign(entity, entityId, String(version), content, c.toDataURL("image/png")).then(()=>{ bg.remove(); toast("سُجل التوقيع","ok"); U.refresh(); }).catch(e=>toast(e.message,"bad")); return false; }}]);
  const c = $("canvas",bg), g = c.getContext("2d"); let down = false, drawn = false;
  g.lineWidth = 2.4; g.lineCap = "round"; g.strokeStyle = "#0B1B3A";
  const pos = e => { const r = c.getBoundingClientRect(); return [(e.clientX-r.left)*c.width/r.width, (e.clientY-r.top)*c.height/r.height]; };
  c.addEventListener("pointerdown", e=>{ down = true; c.setPointerCapture(e.pointerId); const [x,y] = pos(e); g.beginPath(); g.moveTo(x,y); });
  c.addEventListener("pointermove", e=>{ if(!down) return; const [x,y] = pos(e); g.lineTo(x,y); g.stroke(); drawn = true; });
  c.addEventListener("pointerup", ()=>{ down = false; });
  $("[data-clear]",bg).onclick = () => { g.clearRect(0,0,c.width,c.height); drawn = false; };
}
function signaturesHtml(entity, entityId, version){
  const l = X.signaturesOf(entity, entityId, version==null?null:String(version)); if(!l.length) return "";
  return `<div style="margin-top:16px"><b style="font-size:.9rem">التوقيعات الإلكترونية الداخلية</b><div style="display:flex;flex-wrap:wrap;gap:14px;margin-top:6px">${l.map(sg=>`<div style="text-align:center;font-size:.75rem"><img class="sig-img" src="${esc(sg.image)}" alt="توقيع"><div><b>${esc(sg.signerName)}</b></div><div>${esc(sg.position)}</div><div>${fmtDT(sg.at)}</div><div class="mono" style="font-size:.65rem;color:#7A89A8">#${esc(sg.hash.slice(0,12))}</div></div>`).join("")}</div></div>`;
}

/* =================== لوحة المدير العام =================== */
function dashExtra(){
  const u = me(); if(!BOS.can(u,"dashboard","view")) return "";
  const m = X.metrics();
  return `<h2 style="margin:18px 0 10px">الأمن والخصوصية</h2><div class="grid g4">
    ${kpi("آخر نسخة احتياطية", m.backupAge==null?"لا توجد":m.backupAge + " يوم", m.untested + " لم تُختبر استعادتها", m.backupOverdue?"bad":"ok")}${kpi("طلبات خصوصية مفتوحة", m.openDsr, m.lateDsr + " متأخرة", m.lateDsr?"bad":"")}
    ${kpi("مراجعة الصلاحيات", m.reviewOverdue?"مستحقة":"محدّثة", m.inactive + " حساب غير نشط", m.reviewOverdue?"warn":"ok")}${kpi("تنبيهات أمنية", m.anomalies, "", m.anomalies?"bad":"ok")}</div>`;
}

Object.assign(window.BOS_VIEWS, {privacy, dsr, security});
window.BOS_VIEWS_SEC = {requestExtra, signatureModal, signaturesHtml, dashExtra};
})();
