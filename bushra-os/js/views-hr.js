/* نظام البشرى لإدارة الشركة — صفحات المرحلة الرابعة: الموارد البشرية، التدريب، العلاقات العامة والمحتوى، العملاء */
(function(){
"use strict";
const D = window.BOS_DATA;
const U = window.BOS_UI;
const H = window.BOS_HR;
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
const pct = v => v==null ? "—" : v + "%";
const bar = (v, cls) => `<div class="bar"><i style="width:${Math.max(0,Math.min(100,v||0))}%;${cls||""}"></i></div>`;
const tabs = (list, on, base) => `<div class="tabs">${list.map(([k,l])=>`<button class="${k===on?"on":""}" data-href="${base}/${k}">${l}</button>`).join("")}</div>`;
const bindTabs = root => $$("[data-href]",root).forEach(b=>b.onclick=()=>go(b.dataset.href));
const today = () => BOS.now().slice(0,10);
const ATT_CLS = {present:"ok", late:"warn", absent:"bad", leave:"info", remote:"accent", mission:"accent"};
const attBadge = s => s ? `<span class="badge ${ATT_CLS[s]}">${esc(H.ATT[s])}</span>` : '<span class="badge">—</span>';
const PG_CLS = {draft:"", proposed:"warn", approved:"info", scheduled:"info", running:"accent", evaluation:"warn", completed:"ok", archived:""};
const pgBadge = s => `<span class="badge ${PG_CLS[s]}">${esc(H.PSTAT[s])}</span>`;
const CT_CLS = {draft:"", review:"warn", approved:"info", scheduled:"accent", published:"ok"};
const ctBadge = s => `<span class="badge ${CT_CLS[s]}">${esc(H.CSTAT[s])}</span>`;
const lvl = n => `<span class="badge ${n>=3?"ok":n>=2?"info":n>=1?"warn":""}">${esc(H.LEVELS[n])}</span>`;
const stars = n => `<span style="color:var(--gold)">${"★".repeat(Math.round(n))}${"☆".repeat(5-Math.round(n))}</span>`;
const avg = a => a.length ? a.reduce((x,y)=>x+y,0)/a.length : null;

/* =================== الرئيسية: الحضور وخطة التأهيل =================== */
function homeTop(){
  const u = me(); const a = H.attOf(u.id, today()); const w = H.work();
  const ob = S().onboarding.find(o=>o.empId===u.id && o.kind==="onboarding" && !o.closedAt);
  const workday = H.isWorkday(today());
  return `<div class="card" style="margin-top:14px"><div class="row">
      <div style="flex:1;min-width:200px"><h2>الحضور اليوم</h2><div class="small muted">الدوام ${esc(w.start)} – ${esc(w.end)} · سماح ${esc(w.grace)} دقيقة${workday?"":" · اليوم عطلة أسبوعية"}</div></div>
      <div>${a ? `${attBadge(a.status)} <span class="mono small">${esc(a.in||"")}${a.out?" ← " + esc(a.out):""}</span>` : '<span class="badge">لم يُسجل</span>'}</div>
      ${!a || !a.in ? '<button class="btn primary" data-ci>⏱ تسجيل الحضور</button><button class="btn" data-ci-remote>عن بعد</button>' : (!a.out && a.status!=="leave" ? '<button class="btn" data-co>تسجيل الانصراف</button>' : "")}
    </div>
    ${ob?`<div style="margin-top:12px"><div class="row small"><b>خطة تأهيلك (30/60/90 يوماً)</b><span class="spacer"></span>${ob.items.filter(i=>i.done).length}/${ob.items.length}</div>${bar(ob.items.filter(i=>i.done).length/ob.items.length*100)}
      <div class="small muted" style="margin-top:4px">التالي: ${esc((ob.items.find(i=>!i.done)||{}).text||"")}</div></div>`:""}</div>`;
}
function bindHome(root){
  const ci = $("[data-ci]",root), cr = $("[data-ci-remote]",root), co = $("[data-co]",root);
  if(ci) ci.onclick = () => act(()=>{ const a = H.checkIn(); toast(a.status==="late" ? "سُجل الحضور — متأخر " + a.lateMin + " دقيقة" : "سُجل الحضور", a.status==="late"?"bad":"ok"); });
  if(cr) cr.onclick = () => act(()=>H.checkIn({remote:true}), "سُجل الحضور عن بعد");
  if(co) co.onclick = () => act(()=>H.checkOut(), "سُجل الانصراف");
  $$("[data-ack]",root).forEach(b=>b.onclick=()=>ackModal(S().evaluations.find(x=>x.id===b.dataset.ack)));
}
function homeExtra(){
  const u = me(); const s = S();
  const goals = s.goals.filter(g=>g.empId===u.id && g.period===H.period());
  const progs = s.programs.filter(p=>p.enrollments.some(x=>x.empId===u.id) && !["archived"].includes(p.status));
  const evs = s.evaluations.filter(e=>e.empId===u.id && e.status==="submitted");
  const reports = s.employees.filter(e=>BOS.active(e) && H.isManagerOf(u,e) && e.id!==u.id);
  if(!goals.length && !progs.length && !evs.length && !reports.length) return "";
  const absentToday = reports.filter(e=>{ const a = H.attOf(e.id,today()); return !a || a.status==="absent"; });
  return `<div class="grid g2" style="margin-top:14px">
    <div class="card"><div class="card-head"><h2>أهدافي وتطويري</h2><a class="small" href="#/person/${u.id}">ملفي</a></div>
      ${evs.map(e=>`<div class="note warn small" style="margin-bottom:8px">تقييم أدائك للفترة ${esc(e.period)} جاهز للاطلاع <button class="btn sm" data-ack="${e.id}">اطلاع</button></div>`).join("")}
      ${goals.length?goals.map(g=>`<div style="margin-bottom:8px"><div class="row small"><b>${esc(g.title)}</b><span class="spacer"></span>${g.progress}% · وزن ${g.weight}%</div>${bar(g.progress)}</div>`).join(""):'<div class="muted small">لا أهداف لهذه الفترة</div>'}
      ${progs.length?`<h3 style="margin:12px 0 6px">تدريبي</h3>${progs.map(p=>{ const x = p.enrollments.find(e=>e.empId===u.id); return `<div class="small list-item">${pgBadge(p.status)}<div class="grow"><a href="#/program/${p.id}">${esc(p.title)}</a> ${p.start?"· " + fmtDate(p.start):""}${x.passed?' <span class="badge ok">اجتزت</span>':""}${x.certNo?' <span class="badge accent">شهادة</span>':""}</div></div>`; }).join("")}`:""}</div>
    ${reports.length?`<div class="card"><div class="card-head"><h2>فريقي اليوم</h2><a class="small" href="#/hr/attendance">الحضور</a></div>
      ${reports.map(e=>{ const a = H.attOf(e.id,today()); return `<div class="list-item">${avatar(e)}<div class="grow"><a href="#/person/${e.id}">${esc(e.name)}</a><div class="small muted">${esc(BOS.posTitle(e.positionId))}</div></div>${attBadge(a&&a.status)} <span class="mono small">${esc(a&&a.in||"")}</span></div>`; }).join("")}
      ${absentToday.length && H.isWorkday(today())?`<div class="small muted" style="margin-top:6px">${absentToday.length} لم يسجل حضوره بعد</div>`:""}</div>`:""}
  </div>`;
}

/* =================== ملف الموظف: الأقسام الحساسة (القسم 6.2) =================== */
function personExtra(e){
  const u = me(); const s = S(); const hr = H.isHR(u); const mgr = H.isManagerOf(u,e); const self = u.id===e.id;
  const see = sec => H.canSee(u,e,sec);
  const parts = [];
  const ym = today().slice(0,7);
  if(see("contract")){
    const c = (e.contracts||[]).slice(-1)[0];
    parts.push(`<div class="card"><div class="card-head"><h2>العقد</h2>${hr?'<button class="btn sm" data-hx="contract">'+(c?"إصدار جديد":"تسجيل العقد")+'</button>':""}<a class="btn sm" href="library/03-01.docx" download>⬇ نموذج عقد العمل</a></div>
      ${c?`<dl class="kv"><dt>النوع</dt><dd>${esc(c.type)}</dd><dt>المدة</dt><dd>${fmtDate(c.start)} ← ${c.end?fmtDate(c.end):"غير محدد"}</dd><dt>نهاية التجربة</dt><dd>${c.probationEnd?fmtDate(c.probationEnd):"—"}</dd>
        <dt>الأجر</dt><dd>${c.salary?money(c.salary,c.currency):"—"} <span class="badge bad">سري</span></dd><dt>الإصدار</dt><dd>${c.v} من ${e.contracts.length} · ${fmtDate(c.at)} · ${empName(c.by)}</dd></dl>`:empty("لم يُسجل عقد")}</div>`);
  }
  if(see("attendance")){
    const st = H.monthStats(e.id, ym); const rows = s.attendance.filter(a=>a.empId===e.id).sort((a,b)=>a.date<b.date?1:-1).slice(0,10);
    parts.push(`<div class="card"><div class="card-head"><h2>الحضور — ${esc(ym)}</h2>${hr?'<button class="btn sm" data-hx="att">تصحيح سجل</button>':""}</div>
      <div class="row small" style="gap:6px;margin-bottom:8px">${["present","late","absent","leave","remote"].map(k=>`${attBadge(k)} ${st[k]}`).join(" ")} · تأخير ${st.lateMin} د · ${st.hours.toFixed(1)} ساعة</div>
      ${rows.length?rows.map(a=>`<div class="small list-item"><span class="mono">${esc(a.date)}</span><div class="grow">${attBadge(a.status)} <span class="mono">${esc(a.in||"")}${a.out?" ← " + esc(a.out):""}</span>${a.corrected?` <span class="muted">صُحح: ${esc(a.reason)}</span>`:""}${a.auto?' <span class="muted">رصد آلي</span>':""}</div></div>`).join(""):empty("لا سجلات")}</div>`);
  }
  if(see("performance")){
    const goals = s.goals.filter(g=>g.empId===e.id && g.period===H.period()); const evs = s.evaluations.filter(x=>x.empId===e.id);
    const tw = goals.reduce((a,g)=>a+g.weight,0);
    parts.push(`<div class="card"><div class="card-head"><h2>الأهداف والتقييم — ${esc(H.period())}</h2>${(mgr||hr)&&!self?'<button class="btn sm" data-hx="goal">＋ هدف</button>':""}${(mgr||BOS.isTop(u))&&!self?'<button class="btn sm primary" data-hx="eval">تقييم الأداء</button>':""}</div>
      ${goals.length?goals.map(g=>`<div style="margin-bottom:8px"><div class="row small"><b>${esc(g.title)}</b> <span class="muted">${esc(g.target)}</span><span class="spacer"></span>${g.progress}% · وزن ${g.weight}% ${self||mgr||hr?`<button class="btn sm" data-goal="${g.id}">تحديث</button>`:""}</div>${bar(g.progress)}</div>`).join("") + `<div class="small muted">مجموع الأوزان ${tw}%</div>`:'<div class="muted small">لا أهداف</div>'}
      ${evs.length?`<h3 style="margin:12px 0 6px">التقييمات</h3>${evs.map(v=>`<div class="list-item"><span class="badge ${v.status==="approved"?"ok":"warn"}">${esc(H.EVAL_STATUS[v.status])}</span><div class="grow small"><b>${esc(v.period)} — ${v.overall}/5</b> ${stars(v.overall)} <span class="muted">${esc(v.no)} · المقيّم ${empName(v.managerId)}</span>
        <div class="muted">${Object.entries(v.scores).map(([k,x])=>esc(k)+": "+x).join(" · ")}</div>${v.strengths?`<div>نقاط القوة: ${esc(v.strengths)}</div>`:""}${v.improvements?`<div>للتحسين: ${esc(v.improvements)}</div>`:""}${v.employeeComment?`<div>تعليق الموظف: ${esc(v.employeeComment)}</div>`:""}</div>
        ${self && v.status==="submitted"?`<button class="btn sm" data-ack="${v.id}">اطلاع</button>`:""}${hr && v.status==="acknowledged" && v.managerId!==u.id?`<button class="btn sm ok" data-evap="${v.id}">اعتماد</button>`:""}</div>`).join("")}`:""}</div>`);
  }
  if(see("assets")){
    const cust = H.custodyOf(e.id); const canA = hr || ["accountant","procurement"].includes((BOS.pos(u.positionId)||{}).key);
    parts.push(`<div class="card"><div class="card-head"><h2>العهد والأجهزة (${cust.length})</h2>${canA?'<button class="btn sm" data-hx="asset">＋ تسليم عهدة</button>':""}</div>
      ${cust.length?cust.map(a=>`<div class="list-item"><span class="mono small">${esc(a.no)}</span><div class="grow small"><b>${esc(a.desc)}</b> <span class="muted">${esc(a.serial)} · منذ ${fmtDate(a.issuedAt)}</span></div>${canA?`<button class="btn sm" data-ret="${a.id}">استلام</button>`:""}</div>`).join(""):empty("لا عهد")}</div>`);
  }
  if(see("training")){
    const req = H.reqFor(e); const progs = s.programs.filter(p=>p.enrollments.some(x=>x.empId===e.id));
    const canRate = mgr || H.isHR(u) || (BOS.pos(u.positionId)||{}).key==="training";
    parts.push(`<div class="card"><div class="card-head"><h2>المهارات والتدريب</h2>${canRate && !self?'<button class="btn sm" data-hx="skill">تقدير مهارة</button>':""}</div>
      ${Object.keys(req).length?`<div class="table-wrap"><table><thead><tr><th>المهارة</th><th>المطلوب للمنصب</th><th>الحالي</th><th></th></tr></thead><tbody>${Object.entries(req).map(([k,n])=>{ const h = H.levelOf(e.id,k); return `<tr><td class="small">${esc(k)}</td><td>${lvl(n)}</td><td>${lvl(h)}</td><td>${h<n?'<span class="badge bad">فجوة ' + (n-h) + '</span>':'<span class="badge ok">✓</span>'}</td></tr>`; }).join("")}</tbody></table></div>`:empty("لا توجد مهارات مطلوبة معرّفة لهذا المنصب")}
      ${progs.length?`<h3 style="margin:12px 0 6px">البرامج</h3>${progs.map(p=>{ const x = p.enrollments.find(z=>z.empId===e.id); return `<div class="small list-item">${pgBadge(p.status)}<div class="grow"><a href="#/program/${p.id}">${esc(p.title)}</a> ${x.post!=null?"· " + x.post + "%":""} ${x.passed?'<span class="badge ok">ناجح</span>':x.passed===false?'<span class="badge bad">لم يجتز</span>':""} ${x.certNo?`<span class="badge accent">${esc(x.certNo)} حتى ${esc(x.certExpiry)}</span>`:""}</div></div>`; }).join("")}`:""}</div>`);
  }
  const lc = s.onboarding.filter(o=>o.empId===e.id);
  if(lc.length && (hr || mgr || self)){
    parts.push(lc.map(o=>`<div class="card"><div class="card-head"><h2>${o.kind==="onboarding"?"خطة التأهيل 30/60/90":"إنهاء الخدمة وتسليم العهد"}</h2>${o.closedAt?'<span class="badge ok">مكتملة</span>':`<span class="badge warn">${o.items.filter(i=>!i.done).length} مفتوح</span>`}</div>
      ${o.items.map(i=>`<div class="list-item small"><input type="checkbox" ${i.done?"checked":""} ${i.assetId?"disabled":""} data-obi="${o.id}:${i.id}"><div class="grow">${i.phase?`<span class="badge">${i.phase} يوماً</span> `:""}${esc(i.text)}<div class="muted">${i.ownerId?"المسؤول: " + empName(i.ownerId):""}${i.due?" · " + fmtDate(i.due):""}${i.done&&i.doneAt?" · تم " + fmtDate(i.doneAt):""}${i.note?" · " + esc(i.note):""}${i.assetId&&!i.done?" · يُقفل عند استلام الأصل":""}</div></div></div>`).join("")}</div>`).join(""));
  }
  if(see("notes")){
    const notes = s.hrNotes.filter(n=>n.empId===e.id);
    parts.push(`<div class="card" style="border-color:color-mix(in srgb,var(--bad) 40%,transparent)"><div class="card-head"><h2>🔒 الملف السري — الملاحظات والجزاءات</h2><button class="btn sm" data-hx="note">＋ قيد</button></div>
      <p class="small muted">يظهر للموارد البشرية والمدير العام فقط. لا تظهر التفاصيل لمدير المشروع ولا في سجل التدقيق العام.</p>
      ${notes.length?notes.map(n=>`<div class="list-item"><span class="badge ${n.kind==="commendation"?"ok":n.kind==="note"?"":"bad"}">${esc(H.NOTE_KINDS[n.kind])}</span><div class="grow small">${esc(n.text)}<div class="muted">${esc(n.no)} · ${empName(n.by)} · ${fmtDT(n.at)}</div></div></div>`).join(""):empty("لا قيود")}</div>`);
  }
  if(!parts.length) return {html:"", bind:null};
  return {html:`<div class="grid g2" style="margin-top:14px;align-items:start">${parts.join("")}</div>`, bind: root => bindPerson(root, e)};
}
function ackModal(ev){
  modal("تقييم أدائك — " + ev.period, `<div style="font-size:1.4rem"><b>${ev.overall}/5</b> ${stars(ev.overall)}</div>
    <div class="small">${Object.entries(ev.scores).map(([k,x])=>`<div class="row"><span>${esc(k)}</span><span class="spacer"></span>${x}/5</div>`).join("")}</div>
    ${ev.goalScore!=null?`<div class="small muted">تحقيق الأهداف: ${ev.goalScore.toFixed(2)}/5</div>`:""}
    ${ev.strengths?`<p class="small"><b>نقاط القوة:</b> ${esc(ev.strengths)}</p>`:""}${ev.improvements?`<p class="small"><b>للتحسين:</b> ${esc(ev.improvements)}</p>`:""}
    <div class="field"><label class="f">تعليقك (اختياري — يُحفظ مع التقييم)</label><textarea class="input" name="c"></textarea></div>`,
    [{label:"أقر بالاطلاع", cls:"primary", onClick:bg=>{ H.acknowledgeEvaluation(ev, $("[name=c]",bg).value.trim()); U.refresh(); }}]);
}
function bindPerson(root, e){
  const s = S();
  $$("[data-hx]",root).forEach(b=>b.onclick=()=>{
    const k = b.dataset.hx;
    if(k==="contract") modal("عقد العمل — " + e.name, `<div class="grid g2"><div class="field"><label class="f">النوع *</label><select class="input" name="type"><option>دوام كامل</option><option>دوام جزئي</option><option>عقد محدد المدة</option><option>متعاون / مستشار</option><option>تدريب</option></select></div>
      <div class="field"><label class="f">البدء *</label><input class="input" type="date" name="start" value="${esc(e.hireDate||today())}"></div><div class="field"><label class="f">الانتهاء</label><input class="input" type="date" name="end"></div>
      <div class="field"><label class="f">نهاية فترة التجربة</label><input class="input" type="date" name="probationEnd"></div><div class="field"><label class="f">الأجر الشهري</label><input class="input" type="number" name="salary"></div>
      <div class="field"><label class="f">العملة</label><input class="input" name="currency" value="${esc(s.settings.currency)}"></div></div><div class="field"><label class="f">ملاحظة</label><input class="input" name="note"></div>
      <p class="small muted">أي تعديل ينشئ إصداراً جديداً للعقد ويبقي السابق.</p>`, [{label:"حفظ", cls:"primary", onClick:bg=>{ H.setContract(e, formData(bg)); U.route(); }}], true);
    if(k==="att") modal("تصحيح سجل حضور — " + e.name, `<div class="grid g2"><div class="field"><label class="f">التاريخ</label><input class="input" type="date" name="date" value="${today()}"></div>
      <div class="field"><label class="f">الحالة</label><select class="input" name="status">${Object.entries(H.ATT).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select></div>
      <div class="field"><label class="f">الحضور</label><input class="input" type="time" name="in"></div><div class="field"><label class="f">الانصراف</label><input class="input" type="time" name="out"></div></div>
      <div class="field"><label class="f">السبب *</label><input class="input" name="reason"></div>`, [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); H.correctAttendance(e.id, f.date, f); U.route(); }}]);
    if(k==="goal") modal("هدف جديد — " + e.name, `<div class="field"><label class="f">الهدف *</label><input class="input" name="title"></div><div class="field"><label class="f">المستهدف / مؤشر القياس</label><input class="input" name="target"></div>
      <div class="field"><label class="f">الوزن % *</label><input class="input" type="number" name="weight" value="25"></div>`, [{label:"إضافة", cls:"primary", onClick:bg=>{ H.addGoal(e.id, formData(bg)); U.route(); }}]);
    if(k==="eval"){ const ev = H.evidence(e.id);
      modal("تقييم أداء — " + e.name + " — " + H.period(), `<div class="note small" style="margin-bottom:10px"><b>مؤشرات موضوعية:</b> مهام منجزة ${ev.tasksDone} · إعادة عمل ${ev.rework} · مهام تأخرت ${ev.lateTasks} · عيوب أعيد فتحها ${ev.reopened} · غياب ${ev.absent} · تأخر ${ev.lateDays} يوم · أهداف ${ev.goals.length} (متوسط التقدم ${ev.goals.length?Math.round(avg(ev.goals.map(g=>g.progress))):0}%)</div>
        ${H.EVAL_CRITERIA.map(c=>`<div class="row" style="margin-bottom:6px"><span class="small" style="flex:1">${esc(c)}</span><select class="input" data-sc="${esc(c)}" style="max-width:130px"><option value="">—</option>${[1,2,3,4,5].map(n=>`<option>${n}</option>`).join("")}</select></div>`).join("")}
        <div class="field"><label class="f">نقاط القوة</label><textarea class="input" name="strengths"></textarea></div><div class="field"><label class="f">مجالات التحسين</label><textarea class="input" name="improvements"></textarea></div>
        <div class="field"><label class="f">احتياج تدريبي</label><input class="input" name="trainingNeed" placeholder="يُحال لمدير التدريب"></div>`,
        [{label:"إرسال للموظف", cls:"primary", onClick:bg=>{ const f = formData($(".modal-b",bg)); f.scores = {}; $$("[data-sc]",bg).forEach(x=>f.scores[x.dataset.sc] = x.value); H.createEvaluation(e.id, f); U.refresh(); }}], true); }
    if(k==="asset"){ const stock = s.assets.filter(a=>a.status==="stock");
      modal("تسليم عهدة إلى " + e.name, `${stock.length?`<div class="field"><label class="f">من المخزن</label><select class="input" name="assetId"><option value="">— أصل جديد —</option>${stock.map(a=>`<option value="${a.id}">${esc(a.no)} — ${esc(a.desc)}</option>`).join("")}</select></div>`:""}
        <div class="grid g2"><div class="field"><label class="f">الوصف (أصل جديد)</label><input class="input" name="desc"></div><div class="field"><label class="f">الرقم التسلسلي</label><input class="input" name="serial"></div>
        <div class="field"><label class="f">الفئة</label><select class="input" name="category"><option>أجهزة</option><option>هواتف</option><option>أثاث</option><option>برمجيات وتراخيص</option><option>أخرى</option></select></div><div class="field"><label class="f">القيمة</label><input class="input" type="number" name="value"></div></div>`,
        [{label:"تسليم", cls:"primary", onClick:bg=>{ const f = formData(bg); if(f.assetId) H.issueAsset(s.assets.find(a=>a.id===f.assetId), e.id); else H.createAsset(Object.assign(f,{holderId:e.id})); U.route(); }}], true); }
    if(k==="skill") modal("تقدير مهارة — " + e.name, `<div class="field"><label class="f">المهارة</label><select class="input" name="skill">${s.skills.map(x=>`<option>${esc(x.name)}</option>`).join("")}</select></div>
      <div class="field"><label class="f">المستوى</label><select class="input" name="level">${Object.entries(H.LEVELS).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select></div>`,
      [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); H.rateSkill(e.id, f.skill, f.level); U.route(); }}]);
    if(k==="note") modal("قيد في الملف السري — " + e.name, `<div class="field"><label class="f">النوع</label><select class="input" name="kind">${Object.entries(H.NOTE_KINDS).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select></div>
      <div class="field"><label class="f">النص *</label><textarea class="input" name="text"></textarea></div><p class="small muted">الإنذارات والجزاءات والشكر يُبلَّغ بها الموظف برقم القيد. الملاحظات السرية لا يُبلَّغ بها.</p>`,
      [{label:"حفظ", cls:"primary", onClick:bg=>{ H.addNote(e.id, formData(bg)); U.route(); }}]);
  });
  $$("[data-goal]",root).forEach(b=>b.onclick=()=>{ const g = s.goals.find(x=>x.id===b.dataset.goal);
    modal("تحديث تقدم: " + g.title, `<div class="field"><label class="f">التقدم %</label><input class="input" type="number" name="p" value="${g.progress}" min="0" max="100"></div><div class="field"><label class="f">ملاحظة</label><input class="input" name="n"></div>`,
      [{label:"حفظ", cls:"primary", onClick:bg=>{ H.updateGoal(g, $("[name=p]",bg).value, $("[name=n]",bg).value); U.route(); }}]); });
  $$("[data-ack]",root).forEach(b=>b.onclick=()=>ackModal(s.evaluations.find(x=>x.id===b.dataset.ack)));
  $$("[data-evap]",root).forEach(b=>b.onclick=()=>act(()=>H.approveEvaluation(s.evaluations.find(x=>x.id===b.dataset.evap)),"اعتُمد التقييم"));
  $$("[data-ret]",root).forEach(b=>b.onclick=()=>{ const a = s.assets.find(x=>x.id===b.dataset.ret);
    modal("استلام العهدة " + a.no, `<div class="field"><label class="f">الحالة</label><select class="input" name="status"><option value="returned">مُرجعة سليمة</option><option value="damaged">تالفة</option><option value="lost">مفقودة</option></select></div><div class="field"><label class="f">ملاحظة (إلزامية عند الفقد/التلف)</label><input class="input" name="note"></div>`,
      [{label:"تأكيد", cls:"primary", onClick:bg=>{ H.returnAsset(a, formData(bg)); U.route(); }}]); });
  $$("[data-obi]",root).forEach(c=>c.onchange=()=>{ const [oid, iid] = c.dataset.obi.split(":"); act(()=>H.toggleItem(s.onboarding.find(o=>o.id===oid), iid)); });
}

/* =================== الموارد البشرية =================== */
function hr(tab){
  const u = me(); const s = S(); tab = tab || "attendance";
  const isHR = H.isHR(u);
  const visible = sec => s.employees.filter(e=>H.canSee(u,e,sec));
  if(!BOS.can(u,"people","view") && !visible("attendance").some(e=>e.id!==u.id)) throw new Error("لا تملك صلاحية الوصول إلى الموارد البشرية");
  const m = H.metrics();
  const T = [["attendance","الحضور"],["performance","الأداء"],["assets","العهد والأصول"],["lifecycle","التأهيل وإنهاء الخدمة"]];
  let body = "", bind = null;
  if(tab==="attendance"){
    const list = visible("attendance").filter(BOS.active); const d = today(); const ym = d.slice(0,7);
    body = `<div class="grid g4">${kpi("حاضرون اليوم", list.filter(e=>{ const a = H.attOf(e.id,d); return a && ["present","late","remote","mission"].includes(a.status); }).length + "/" + list.length)}${kpi("متأخرون اليوم", list.filter(e=>(H.attOf(e.id,d)||{}).status==="late").length,"", "warn")}${kpi("في إجازة", list.filter(e=>(H.attOf(e.id,d)||{}).status==="leave" || e.onLeave).length)}${kpi("نسبة الغياب هذا الشهر", pct(m.absRate), "", m.absRate?"warn":"")}</div>
      <div class="card" style="margin-top:14px"><div class="table-wrap"><table><thead><tr><th>الموظف</th><th>اليوم</th><th>الحضور / الانصراف</th><th>حاضر</th><th>متأخر</th><th>غائب</th><th>إجازة</th><th>ساعات ${esc(ym)}</th><th>رصيد الإجازة</th></tr></thead><tbody>
      ${list.map(e=>{ const a = H.attOf(e.id,d); const st = H.monthStats(e.id,ym); const left = Number(s.settings.leaveDays||30)-Number(e.leaveUsed||0);
        return `<tr class="link" data-go="#/person/${e.id}"><td><b class="small">${esc(e.name)}</b><div class="muted small">${esc(BOS.posTitle(e.positionId))}</div></td><td>${attBadge(a&&a.status)}</td><td class="mono small">${esc(a&&a.in||"")}${a&&a.out?" ← " + esc(a.out):""}</td><td>${st.present}</td><td>${st.late}</td><td>${st.absent?`<b style="color:var(--bad)">${st.absent}</b>`:0}</td><td>${st.leave}</td><td>${st.hours.toFixed(1)}</td><td>${left<=3?`<span class="badge bad">${left}</span>`:left}</td></tr>`; }).join("")}</tbody></table></div>
      <p class="small muted">يُرصد الغياب آلياً لأيام العمل دون حضور أو إجازة معتمدة، ويُنبَّه المدير المباشر. الإجازات المعتمدة عبر مسار «طلب إجازة» تُسجل تلقائياً. التصحيح للموارد البشرية بسبب مكتوب.</p></div>
      ${isHR?`<div class="card"><h2 style="margin-bottom:10px">إعدادات الدوام</h2><div class="row"><label class="small">البداية <input class="input" type="time" id="ws" value="${esc(H.work().start)}" style="max-width:130px"></label><label class="small">النهاية <input class="input" type="time" id="we" value="${esc(H.work().end)}" style="max-width:130px"></label><label class="small">السماح (دقيقة) <input class="input" type="number" id="wg" value="${esc(H.work().grace)}" style="max-width:100px"></label><button class="btn" id="wsave">حفظ</button></div><div class="small muted" style="margin-top:6px">العطلة الأسبوعية: الجمعة والسبت</div></div>`:""}`;
    bind = root => { if($("#wsave",root)) $("#wsave",root).onclick = () => act(()=>{ const w = H.work(); const before = JSON.stringify(w); w.start = $("#ws",root).value; w.end = $("#we",root).value; w.grace = Number($("#wg",root).value||0); s.settings.work = w; BOS.audit("تعديل إعدادات الدوام","settings",null,before + " ← " + JSON.stringify(w)); BOS.save(); }, "حُفظ"); };
  }
  if(tab==="performance"){
    const list = visible("performance").filter(BOS.active).filter(e=>e.id!==u.id || isHR);
    body = `<div class="grid g4">${kpi("تقييمات غير معتمدة", m.evalPending)}${kpi("موظفون بلا أهداف", list.filter(e=>!s.goals.some(g=>g.empId===e.id && g.period===H.period())).length, "للفترة " + esc(H.period()))}${kpi("دوران الموظفين (12 شهراً)", m.turnover + "%", m.left + " غادروا")}${kpi("عدد الموظفين النشطين", m.headcount)}</div>
      <div class="card" style="margin-top:14px"><div class="table-wrap"><table><thead><tr><th>الموظف</th><th>المدير</th><th>الأهداف</th><th>متوسط التقدم</th><th>آخر تقييم</th><th>الحالة</th></tr></thead><tbody>
      ${list.map(e=>{ const g = s.goals.filter(x=>x.empId===e.id && x.period===H.period()); const ev = s.evaluations.filter(x=>x.empId===e.id)[0];
        return `<tr class="link" data-go="#/person/${e.id}"><td><b class="small">${esc(e.name)}</b></td><td class="small">${e.managerId?empName(e.managerId):"—"}</td><td>${g.length} (${g.reduce((a,x)=>a+x.weight,0)}%)</td><td style="min-width:90px">${g.length?bar(avg(g.map(x=>x.progress))):"—"}</td><td>${ev?ev.overall + "/5 " + stars(ev.overall):"—"}</td><td>${ev?`<span class="badge ${ev.status==="approved"?"ok":"warn"}">${esc(H.EVAL_STATUS[ev.status])}</span>`:"—"}</td></tr>`; }).join("")}</tbody></table></div></div>`;
  }
  if(tab==="assets"){
    const canA = isHR || ["accountant","procurement"].includes((BOS.pos(u.positionId)||{}).key);
    if(!canA) throw new Error("سجل الأصول للموارد البشرية والمحاسبة والمشتريات");
    body = `<div class="grid g4">${kpi("أصول مسجلة", s.assets.length)}${kpi("عهد لدى الموظفين", m.custody)}${kpi("في المخزن", s.assets.filter(a=>a.status==="stock").length)}${kpi("مفقود / تالف", m.lostAssets,"", m.lostAssets?"bad":"")}</div>
      <div class="card" style="margin-top:14px"><div class="card-head"><h2>سجل الأصول والعهد</h2><button class="btn primary" id="new-asset">＋ أصل</button><a class="btn" href="library/08-01.xlsx" download>⬇ سجلات الشركة (Excel)</a></div>
      ${s.assets.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>الوصف</th><th>التسلسلي</th><th>الحالة</th><th>المستخدم</th><th>التسليم</th><th>المصدر</th></tr></thead><tbody>${s.assets.map(a=>`<tr data-asset="${a.id}" class="link"><td class="mono">${esc(a.no)}</td><td>${esc(a.desc)}</td><td class="mono small">${esc(a.serial)}</td><td><span class="badge ${a.status==="issued"?"accent":a.status==="stock"?"":"bad"}">${esc(H.ASSET_STATUS[a.status])}</span></td><td class="small">${a.holderId?empName(a.holderId):"—"}</td><td class="small">${a.issuedAt?fmtDate(a.issuedAt):"—"}</td><td class="small">${a.requestId?`<a href="#/request/${a.requestId}">طلب شراء</a>`:"يدوي"}</td></tr>`).join("")}</tbody></table></div>`:empty("لا أصول")}
      <p class="small muted">الأصول المشتراة عبر «طلب شراء» تُسجل تلقائياً عند إغلاق مرحلة «تسجيل الأصل والعهدة» وتسلم عهدة لطالب الشراء.</p></div>`;
    bind = root => {
      $("#new-asset",root).onclick = () => modal("أصل جديد", `<div class="grid g2"><div class="field"><label class="f">الوصف *</label><input class="input" name="desc"></div><div class="field"><label class="f">التسلسلي</label><input class="input" name="serial"></div>
        <div class="field"><label class="f">الفئة</label><select class="input" name="category"><option>أجهزة</option><option>هواتف</option><option>أثاث</option><option>برمجيات وتراخيص</option></select></div><div class="field"><label class="f">القيمة</label><input class="input" type="number" name="value"></div>
        <div class="field"><label class="f">تسليم عهدة إلى (اختياري)</label><select class="input" name="holderId"><option value="">يبقى في المخزن</option>${userOptions("")}</select></div></div>`,
        [{label:"تسجيل", cls:"primary", onClick:bg=>{ H.createAsset(formData(bg)); U.route(); }}], true);
      $$("[data-asset]",root).forEach(r=>r.onclick=()=>{ const a = s.assets.find(x=>x.id===r.dataset.asset);
        modal(a.no + " — " + a.desc, `<dl class="kv"><dt>الحالة</dt><dd>${esc(H.ASSET_STATUS[a.status])}</dd><dt>القيمة</dt><dd>${money(a.value)}</dd></dl><h3 style="margin:12px 0 6px">السجل</h3>${a.history.slice().reverse().map(h=>`<div class="small list-item"><span class="muted">${fmtDT(h.at)}</span><div class="grow">${esc(h.action)} ${h.by?"— " + empName(h.by):""}</div></div>`).join("")}`,
          a.status==="issued" ? [{label:"استلام العهدة", cls:"primary", onClick:()=>{ setTimeout(()=>{ modal("استلام " + a.no, `<div class="field"><label class="f">الحالة</label><select class="input" name="status"><option value="returned">مُرجعة سليمة</option><option value="damaged">تالفة</option><option value="lost">مفقودة</option></select></div><div class="field"><label class="f">ملاحظة</label><input class="input" name="note"></div>`,
            [{label:"تأكيد", cls:"primary", onClick:bg=>{ H.returnAsset(a, formData(bg)); U.route(); }}]); },0); }}] :
          a.status==="stock" ? [{label:"تسليم عهدة", cls:"primary", onClick:()=>{ setTimeout(()=>modal("تسليم " + a.no, `<div class="field"><label class="f">إلى</label><select class="input" name="to">${userOptions("")}</select></div>`,
            [{label:"تسليم", cls:"primary", onClick:bg=>{ H.issueAsset(a, $("[name=to]",bg).value); U.route(); }}]),0); }}] : [], true); });
    };
  }
  if(tab==="lifecycle"){
    const list = s.onboarding.filter(o=>isHR || H.isManagerOf(u, BOS.byId(o.empId)) || o.empId===u.id);
    body = `<div class="grid g4">${kpi("خطط تأهيل مفتوحة", list.filter(o=>o.kind==="onboarding" && !o.closedAt).length)}${kpi("اكتمال التأهيل", pct(m.obDone))}${kpi("إنهاء خدمة مفتوح", list.filter(o=>o.kind==="offboarding" && !o.closedAt).length)}${kpi("عهد غير مستلمة من المغادرين", list.filter(o=>o.kind==="offboarding").flatMap(o=>o.items.filter(i=>i.assetId && !i.done)).length, "", "warn")}</div>
      <div class="card" style="margin-top:14px">${list.length?`<div class="table-wrap"><table><thead><tr><th>الموظف</th><th>النوع</th><th>التقدم</th><th>البند التالي</th><th>البدء</th><th>الحالة</th></tr></thead><tbody>${list.map(o=>{ const d = o.items.filter(i=>i.done).length; const nx = o.items.find(i=>!i.done);
        return `<tr class="link" data-go="#/person/${o.empId}"><td><b class="small">${empName(o.empId)}</b></td><td>${o.kind==="onboarding"?"تأهيل 30/60/90":"إنهاء خدمة"}</td><td style="min-width:100px">${bar(d/o.items.length*100)}<span class="small">${d}/${o.items.length}</span></td><td class="small">${nx?esc(nx.text) + (nx.due?" · " + fmtDate(nx.due):""):"—"}</td><td class="small">${fmtDate(o.createdAt)}</td><td>${o.closedAt?'<span class="badge ok">مكتمل</span>':'<span class="badge warn">مفتوح</span>'}</td></tr>`; }).join("")}</tbody></table></div>`:empty("لا توجد خطط")}
      <p class="small muted">تُنشأ خطة التأهيل تلقائياً عند دعوة موظف جديد، ويُنبَّه المدير المباشر ومدير التدريب. تُنشأ قائمة إنهاء الخدمة عند إيقاف الحساب، وتضم كل عهدة مسجلة.</p></div>`;
  }
  return {title:"الموارد البشرية", html:`${head("الموارد البشرية", "البيانات الحساسة تظهر بالحد الأدنى اللازم وفق المنصب", `<a class="btn" href="library/03-02.docx" download>⬇ دليل الموظف</a>`)}${tabs(T,tab,"#/hr")}${body}`,
    bind: root => { bindTabs(root); bindRows(root); bind && bind(root); }};
}

/* =================== التدريب والتطوير (القسم 6.4) =================== */
function training(tab){
  need("training");
  const u = me(); const s = S(); tab = tab || "programs"; const m = H.metrics(); const mg = H.canManageTraining(u);
  const T = [["programs","البرامج"],["matrix","مصفوفة المهارات"],["gaps","فجوات المهارات"],["certs","الشهادات"],["providers","المدربون والمزودون"]];
  let body = "", bind = null;
  const kpis = `<div class="grid g4">${kpi("نسبة إكمال التدريب", pct(m.completion))}${kpi("النجاح في التقييم", pct(m.passRate))}${kpi("فجوات مهارات مفتوحة", m.gapsOpen, m.gapsUnplanned + " بلا خطة", m.gapsUnplanned?"warn":"")}${kpi("اكتمال تأهيل الجدد", pct(m.obDone))}</div>`;
  if(tab==="programs"){
    const list = s.programs.filter(p=>mg || BOS.can(u,"training","create") || p.enrollments.some(x=>x.empId===u.id) || BOS.can(u,"training","approve") || H.isHR(u));
    body = kpis + `<div class="card" style="margin-top:14px"><div class="card-head"><h2>البرامج التدريبية</h2>${BOS.can(u,"training","create")?'<button class="btn primary" id="new-prog">＋ برنامج</button>':""}</div>
      <p class="small muted">مسودة ← مقترحة ← معتمدة ← مجدولة ← جارية ← تقييم ← مكتملة ← مؤرشفة. الاعتماد يمر بمسار «خطة / طلب تدريب». لا يكتمل التدريب بمجرد الحضور: يلزم تقييم بعدي، وتحديث مصفوفة المهارات، وتسجيل الأثر.</p>
      ${list.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>البرنامج</th><th>المهارات</th><th>الموعد</th><th>المتدربون</th><th>التكلفة</th><th>الحالة</th></tr></thead><tbody>${list.map(p=>`<tr class="link" data-go="#/program/${p.id}"><td class="mono">${esc(p.no)}</td><td><b>${esc(p.title)}</b><div class="small muted">${esc(p.kind)}${p.providerId?" · " + esc((H.provider(p.providerId)||{}).name||""):""}${p.linkedDefect?' · <span style="color:var(--warn)">مرتبط بعيب/شكوى</span>':""}</div></td><td class="small">${p.skills.map(esc).join("، ")}</td><td class="small">${p.start?fmtDate(p.start):"—"}</td><td>${p.enrollments.length}${p.seats?"/" + p.seats:""}</td><td class="small">${p.cost?money(p.cost,p.currency):"مجاني"}</td><td>${pgBadge(p.status)}</td></tr>`).join("")}</tbody></table></div>`:empty("لا توجد برامج")}</div>
      ${Object.keys(m.costByDept).length?`<div class="card"><h2 style="margin-bottom:10px">تكلفة التدريب لكل قسم</h2>${Object.entries(m.costByDept).map(([k,v])=>`<div class="row small list-item"><span>${esc(k)}</span><span class="spacer"></span><b>${money(v)}</b></div>`).join("")}</div>`:""}`;
    bind = root => { if($("#new-prog",root)) $("#new-prog",root).onclick = () => programEditor(); };
  }
  if(tab==="matrix"){
    const posKeys = Object.keys(s.skillReq).filter(k=>BOS.posByKey(k));
    const emps = s.employees.filter(BOS.active).filter(e=>Object.keys(H.reqFor(e)).length && (mg || H.isHR(u) || H.canSee(u,e,"training")));
    body = `<div class="card"><div class="card-head"><h2>المهارات المطلوبة لكل منصب</h2>${mg?'<button class="btn sm" id="edit-req">تعديل</button>':""}</div><div class="table-wrap"><table><thead><tr><th>المنصب</th>${s.skills.map(k=>`<th style="font-size:.66rem;white-space:normal;min-width:70px">${esc(k.name)}</th>`).join("")}</tr></thead><tbody>
      ${posKeys.map(k=>`<tr><td class="small"><b>${esc(BOS.posByKey(k).title)}</b></td>${s.skills.map(sk=>{ const n = s.skillReq[k][sk.name]; return `<td>${n?lvl(n):""}</td>`; }).join("")}</tr>`).join("")}</tbody></table></div></div>
      <div class="card"><h2 style="margin-bottom:10px">مستوى الموظفين مقابل المطلوب</h2><div class="table-wrap"><table><thead><tr><th>الموظف</th><th>المهارات المطلوبة</th><th>مستوفاة</th><th>الفجوات</th></tr></thead><tbody>
      ${emps.map(e=>{ const req = H.reqFor(e); const ks = Object.keys(req); const ok = ks.filter(k=>H.levelOf(e.id,k)>=req[k]);
        return `<tr class="link" data-go="#/person/${e.id}"><td style="min-width:150px"><b class="small">${esc(e.name)}</b><div class="small muted">${esc(BOS.posTitle(e.positionId))}</div></td><td>${ks.length}</td><td style="min-width:100px">${ks.length?bar(ok.length/ks.length*100):"—"}<span class="small">${ok.length}/${ks.length}</span></td><td class="small">${ks.filter(k=>H.levelOf(e.id,k)<req[k]).map(k=>esc(k) + " (" + H.levelOf(e.id,k) + "→" + req[k] + ")").join("، ")||"—"}</td></tr>`; }).join("")}</tbody></table></div></div>`;
    bind = root => { if($("#edit-req",root)) $("#edit-req",root).onclick = () => {
      const bg = modal("تعديل المهارات المطلوبة لمنصب", `<div class="field"><label class="f">المنصب</label><select class="input" id="rp">${s.positions.map(p=>`<option value="${p.key}">${esc(p.title)}</option>`).join("")}</select></div><div id="rl"></div>
        <div class="field"><label class="f">إضافة مهارة جديدة للكتالوج</label><div class="row"><input class="input" id="nsk" style="flex:1"><button class="btn sm" id="addsk">إضافة</button></div></div>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ const k = $("#rp",bg).value; const o = {}; $$("[data-rq]",bg).forEach(x=>{ if(Number(x.value)>0) o[x.dataset.rq] = Number(x.value); });
          s.skillReq[k] = o; BOS.audit("تعديل مصفوفة المهارات المطلوبة","skill",k,BOS.posByKey(k).title + " — " + Object.keys(o).length + " مهارة"); BOS.save(); U.route(); }}], true);
      const draw = () => { const k = $("#rp",bg).value; const r = s.skillReq[k]||{};
        $("#rl",bg).innerHTML = s.skills.map(sk=>`<div class="row small" style="margin-bottom:4px"><span style="flex:1">${esc(sk.name)}</span><select class="input" data-rq="${esc(sk.name)}" style="max-width:130px">${Object.entries(H.LEVELS).map(([n,v])=>`<option value="${n}" ${Number(n)===(r[sk.name]||0)?"selected":""}>${v}</option>`).join("")}</select></div>`).join(""); };
      $("#rp",bg).onchange = draw; draw();
      $("#addsk",bg).onclick = () => { const n = $("#nsk",bg).value.trim(); if(!n || s.skills.some(x=>x.name===n)) return; s.skills.push({id:BOS.uid("sk"), name:n, category:"مضافة"}); BOS.audit("إضافة مهارة للكتالوج","skill",null,n); BOS.save(); $("#nsk",bg).value=""; draw(); };
    }; };
  }
  if(tab==="gaps"){
    const g = H.gaps().filter(x=>mg || H.isHR(u) || H.canSee(u,x.emp,"training"));
    body = kpis + `<div class="card" style="margin-top:14px"><h2 style="margin-bottom:6px">تحليل فجوات المهارات</h2><p class="small muted">الأولوية = حجم الفجوة + المؤشرات: تقييم الأداء، وإعادة العمل، والعيوب المعاد فتحها، وشكاوى العملاء بسبب نقص التدريب، والحوادث.</p>
      ${g.length?`<div class="table-wrap"><table><thead><tr><th>الموظف</th><th>المهارة</th><th>الحالي ← المطلوب</th><th>المؤشرات</th><th>خطة</th></tr></thead><tbody>${g.map(x=>`<tr><td><a href="#/person/${x.emp.id}">${esc(x.emp.name)}</a><div class="small muted">${esc(BOS.posTitle(x.emp.positionId))}</div></td><td class="small">${esc(x.skill)}</td><td>${lvl(x.have)} ← ${lvl(x.need)}</td><td class="small">${x.signals.map(esc).join("<br>")||"—"}</td><td>${x.planned?'<span class="badge ok">مدرج</span>':(BOS.can(u,"training","create")?`<button class="btn sm" data-plan="${esc(x.skill)}" data-emp="${x.emp.id}">اقتراح برنامج</button>`:'<span class="badge warn">بلا خطة</span>')}</td></tr>`).join("")}</tbody></table></div>`:empty("لا توجد فجوات")}</div>`;
    bind = root => $$("[data-plan]",root).forEach(b=>b.onclick=()=>programEditor({skills:[b.dataset.plan], nominees:[b.dataset.emp], title:"تطوير: " + b.dataset.plan}));
  }
  if(tab==="certs"){
    const list = H.certificates().filter(c=>mg || H.isHR(u) || c.x.empId===u.id);
    const soon = new Date(Date.now()+30*864e5).toISOString().slice(0,10);
    body = `<div class="card">${list.length?`<div class="table-wrap"><table><thead><tr><th>الشهادة</th><th>الموظف</th><th>البرنامج</th><th>الدرجة</th><th>الصلاحية</th></tr></thead><tbody>${list.map(c=>`<tr><td class="mono">${esc(c.x.certNo)}</td><td>${esc((c.emp||{}).name||"")}</td><td><a href="#/program/${c.p.id}">${esc(c.p.title)}</a></td><td>${c.x.post}%</td><td>${fmtDate(c.x.certExpiry)} ${c.x.certExpiry<today()?'<span class="badge bad">منتهية</span>':c.x.certExpiry<=soon?'<span class="badge warn">تنتهي قريباً</span>':""}</td></tr>`).join("")}</tbody></table></div>`:empty("لا شهادات")}
      <p class="small muted">يُنبَّه الموظف ومدير التدريب قبل انتهاء الشهادة بـ 30 يوماً للتجديد.</p></div>`;
  }
  if(tab==="providers"){
    body = `<div class="card"><div class="card-head"><h2>سجل المدربين والمزودين</h2>${mg?'<button class="btn primary" id="new-pv">＋ مزود</button>':""}</div>
      ${s.providers.length?s.providers.map(p=>{ const r = avg((p.ratings||[]).map(x=>x.score)); const n = s.programs.filter(x=>x.providerId===p.id).length;
        return `<div class="list-item"><div class="grow"><b>${esc(p.name)}</b> <span class="badge">${esc(p.kind)}</span><div class="small muted">${esc(p.specialty)} · ${esc(p.contact)} · ${n} برنامج</div></div>${r?stars(r) + ` <span class="small">${r.toFixed(1)} (${p.ratings.length})</span>`:'<span class="muted small">بلا تقييم</span>'}</div>`; }).join(""):empty("لا مزودين")}</div>`;
    bind = root => { if($("#new-pv",root)) $("#new-pv",root).onclick = () => modal("مدرب / مزود", `<div class="field"><label class="f">الاسم *</label><input class="input" name="name"></div><div class="grid g2"><div class="field"><label class="f">النوع</label><select class="input" name="kind"><option>جهة خارجية</option><option>مدرب مستقل</option><option>مدرب داخلي</option><option>منصة إلكترونية</option></select></div><div class="field"><label class="f">التخصص</label><input class="input" name="specialty"></div></div><div class="field"><label class="f">التواصل</label><input class="input" name="contact"></div>`,
      [{label:"إضافة", cls:"primary", onClick:bg=>{ H.createProvider(formData(bg)); U.route(); }}], true); };
  }
  return {title:"التدريب والتطوير", html:`${head("التدريب والتطوير", "مرتبط بالموارد البشرية وبمدير الجودة: الهدف رفع كفاءة التنفيذ وتقليل الأخطاء وتحسين تجربة العميل")}${tabs(T,tab,"#/training")}${body}`,
    bind: root => { bindTabs(root); bindRows(root); bind && bind(root); }};
}
function programEditor(pre){
  pre = pre || {}; const s = S();
  modal("برنامج تدريبي", `<div class="field"><label class="f">العنوان *</label><input class="input" name="title" value="${esc(pre.title||"")}"></div>
    <div class="grid g2"><div class="field"><label class="f">النوع</label><select class="input" name="kind"><option>داخلي</option><option>خارجي</option><option>إلكتروني</option></select></div>
    <div class="field"><label class="f">المزود</label><select class="input" name="providerId"><option value="">—</option>${s.providers.map(p=>`<option value="${p.id}">${esc(p.name)}</option>`).join("")}</select></div>
    <div class="field"><label class="f">المستوى المستهدف</label><select class="input" name="level">${[1,2,3,4].map(n=>`<option value="${n}" ${n===2?"selected":""}>${H.LEVELS[n]}</option>`).join("")}</select></div>
    <div class="field"><label class="f">التكلفة الإجمالية</label><input class="input" type="number" name="cost" value="0"></div>
    <div class="field"><label class="f">الساعات</label><input class="input" type="number" name="hours"></div><div class="field"><label class="f">المقاعد</label><input class="input" type="number" name="seats"></div>
    <div class="field"><label class="f">البداية</label><input class="input" type="date" name="start"></div><div class="field"><label class="f">النهاية</label><input class="input" type="date" name="end"></div></div>
    <div class="field"><label class="f">المهارات المستهدفة *</label><div class="pick-grid">${s.skills.map(k=>`<label class="check"><input type="checkbox" data-sk="${esc(k.name)}" ${(pre.skills||[]).includes(k.name)?"checked":""}> ${esc(k.name)}</label>`).join("")}</div></div>
    <div class="field"><label class="f">المرشحون</label><select class="input" name="nominees" multiple size="5">${s.employees.filter(BOS.active).map(e=>`<option value="${e.id}" ${(pre.nominees||[]).includes(e.id)?"selected":""}>${esc(e.name)} — ${esc(BOS.posTitle(e.positionId))}</option>`).join("")}</select></div>
    <div class="field"><label class="f">الهدف والأثر المتوقع *</label><textarea class="input" name="goal"></textarea></div>
    <div class="field"><label class="f">المحتوى والمواد</label><textarea class="input" name="materials"></textarea></div>
    <label class="check"><input type="checkbox" name="linkedDefect"> مرتبط بعيب أو شكوى عميل (يمر بمدير الجودة)</label>`,
    [{label:"إنشاء كمسودة", cls:"primary", onClick:bg=>{ const f = formData($(".modal-b",bg)); f.skills = $$("[data-sk]",bg).filter(x=>x.checked).map(x=>x.dataset.sk); f.nominees = Array.from($("[name=nominees]",bg).selectedOptions).map(o=>o.value);
      const p = H.createProgram(f); go("#/program/"+p.id); }}], true);
}
function programView(id){
  need("training");
  const p = H.program(id); if(!p) throw new Error("البرنامج غير موجود");
  const u = me(); const mg = H.canManageTraining(u); const s = S();
  const order = H.PROGRAM_FLOW.map(x=>x[0]); const next = order[order.indexOf(p.status)+1];
  const req = p.requestId && s.requests.find(r=>r.id===p.requestId);
  const mine = p.enrollments.find(x=>x.empId===u.id);
  const pre = avg(p.enrollments.filter(x=>x.pre!=null).map(x=>x.pre)), post = avg(p.enrollments.filter(x=>x.post!=null).map(x=>x.post));
  const nextBtn = mg && next && next!=="approved" ? `<button class="btn primary" id="next">الانتقال إلى «${esc(H.PSTAT[next])}»</button>` : "";
  return {title:p.no, html:`${head("🎓 " + p.title, `<span class="mono">${esc(p.no)}</span> · ${pgBadge(p.status)} · ${esc(p.kind)} · ${p.hours||0} ساعة · ${p.cost?money(p.cost,p.currency):"مجاني"}`, nextBtn + (p.status!=="completed" && p.status!=="archived" && (mg || BOS.can(u,"training","create")) ? '<button class="btn" id="nom">＋ ترشيح</button>' : ""))}
    <div class="route-h" style="margin-bottom:14px">${H.PROGRAM_FLOW.map(([k,l],i)=>`${i?'<span class="arrow">←</span>':""}<span class="chip" style="${i<order.indexOf(p.status)?"border-color:var(--ok);color:var(--ok)":k===p.status?"border-color:var(--accent);background:var(--accent-soft);font-weight:700":"opacity:.6"}">${esc(l)}</span>`).join("")}</div>
    ${p.status==="proposed"&&req?`<div class="note" style="margin-bottom:14px">بانتظار مسار الاعتماد <a href="#/request/${req.id}">${esc(req.no)}</a> ${statusBadge(req.status)}</div>`:""}
    <div class="grid g2"><div class="card"><dl class="kv"><dt>المهارات</dt><dd>${p.skills.map(esc).join("، ")} ← ${lvl(p.level)}</dd><dt>المزود / المدرب</dt><dd>${esc((H.provider(p.providerId)||{}).name||p.trainer||"—")}</dd>
      <dt>الموعد</dt><dd>${p.start?fmtDate(p.start) + " ← " + fmtDate(p.end):"—"}</dd><dt>الهدف</dt><dd>${esc(p.goal||"—")}</dd><dt>المواد</dt><dd style="white-space:pre-wrap">${esc(p.materials||"—")}</dd>
      ${p.impact?`<dt>الأثر المسجل</dt><dd>${esc(p.impact)}</dd>`:""}<dt>قبلي ← بعدي</dt><dd>${pre!=null?pre.toFixed(0)+"%":"—"} ← ${post!=null?post.toFixed(0)+"%":"—"}</dd>
      <dt>تقييم المتدربين</dt><dd>${(p.ratings||[]).length?stars(avg(p.ratings.map(r=>r.score))) + " (" + p.ratings.length + ")":"—"}</dd></dl>
      ${mg && ["draft","approved"].includes(p.status)?'<button class="btn sm" id="dates" style="margin-top:10px">تحديد المواعيد</button>':""}
      ${mine && ["evaluation","completed"].includes(p.status)?`<div class="row" style="margin-top:10px"><span class="small">قيّم البرنامج:</span>${[1,2,3,4,5].map(n=>`<button class="btn sm" data-rate="${n}">${n}★</button>`).join("")}</div>`:""}</div>
    <div class="card"><h2 style="margin-bottom:10px">المتدربون (${p.enrollments.length}${p.seats?"/" + p.seats:""})</h2>
      ${p.enrollments.length?`<div class="table-wrap"><table><thead><tr><th>الموظف</th><th>قبلي</th><th>الحضور</th><th>بعدي</th><th>النتيجة</th>${mg&&["scheduled","running","evaluation"].includes(p.status)?"<th></th>":""}</tr></thead><tbody>${p.enrollments.map(x=>`<tr><td class="small"><a href="#/person/${x.empId}">${empName(x.empId)}</a></td><td>${x.pre!=null?x.pre+"%":"—"}</td><td>${x.attended==null?"—":x.attended?'<span class="badge ok">حضر</span>':'<span class="badge bad">غاب</span>'}</td><td>${x.post!=null?x.post+"%":"—"}</td><td>${x.passed==null?"—":x.passed?'<span class="badge ok">ناجح</span>' + (x.certNo?' <span class="badge accent">' + esc(x.certNo) + '</span>':""):'<span class="badge bad">لم يجتز</span>'}</td>${mg&&["scheduled","running","evaluation"].includes(p.status)?`<td><button class="btn sm" data-res="${x.empId}">تسجيل</button></td>`:""}</tr>`).join("")}</tbody></table></div>`:empty("لا مرشحين")}</div></div>
    <div class="card"><h2 style="margin-bottom:10px">السجل</h2>${p.history.slice().reverse().map(h=>`<div class="small list-item"><span class="muted">${fmtDT(h.at)}</span><div class="grow">${pgBadge(h.to)} ${h.by?empName(h.by):""} ${esc(h.note||"")}</div></div>`).join("")}</div>`,
    bind: root => {
      if($("#next",root)) $("#next",root).onclick = () => {
        if(next==="completed") return modal("إكمال البرنامج", `<div class="note small" style="margin-bottom:10px">يُحدَّث مستوى «${p.skills.map(esc).join("، ")}» إلى ${esc(H.LEVELS[p.level])} في مصفوفة كل من اجتاز.</div>
          <div class="field"><label class="f">أثر التدريب على مؤشر أو ملاحظة عملية *</label><textarea class="input" name="impact" placeholder="مثال: انخفضت العيوب المعاد فتحها من 4 إلى 1 خلال شهر">${esc(p.impact||"")}</textarea></div>
          <div class="field"><label class="f">صلاحية الشهادة (أشهر، اتركه فارغاً بلا شهادة)</label><input class="input" type="number" name="certMonths" value="24"></div>`,
          [{label:"إكمال", cls:"ok solid", onClick:bg=>{ H.moveProgram(p,"completed",formData(bg)); U.refresh(); }}]);
        act(()=>H.moveProgram(p,next), next==="proposed" ? "أُرسل البرنامج لمسار الاعتماد" : "تم");
      };
      if($("#nom",root)) $("#nom",root).onclick = () => modal("ترشيح لـ " + p.title, `<div class="field"><label class="f">الموظف</label><select class="input" name="e">${userOptions("", e=>!p.enrollments.some(x=>x.empId===e.id))}</select></div>`,
        [{label:"ترشيح", cls:"primary", onClick:bg=>{ H.nominate(p, $("[name=e]",bg).value); U.route(); }}]);
      if($("#dates",root)) $("#dates",root).onclick = () => modal("مواعيد البرنامج", `<div class="grid g2"><div class="field"><label class="f">البداية</label><input class="input" type="date" name="start" value="${esc(p.start)}"></div><div class="field"><label class="f">النهاية</label><input class="input" type="date" name="end" value="${esc(p.end)}"></div></div>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); if(f.end && f.start && f.end < f.start) throw new Error("النهاية قبل البداية"); Object.assign(p,f); BOS.audit("تحديد مواعيد برنامج","training",p.id,p.no + " " + f.start + " ← " + f.end); BOS.save(); U.route(); }}]);
      $$("[data-res]",root).forEach(b=>b.onclick=()=>{ const x = p.enrollments.find(z=>z.empId===b.dataset.res);
        modal("نتيجة " + (BOS.byId(x.empId)||{}).name, `<div class="grid g2"><div class="field"><label class="f">التقييم القبلي %</label><input class="input" type="number" name="pre" value="${x.pre==null?"":x.pre}"></div>
          <div class="field"><label class="f">الحضور</label><select class="input" name="att"><option value="">—</option><option value="1" ${x.attended?"selected":""}>حضر</option><option value="0" ${x.attended===false?"selected":""}>غاب</option></select></div>
          <div class="field"><label class="f">التقييم البعدي %</label><input class="input" type="number" name="post" value="${x.post==null?"":x.post}" ${["running","evaluation"].includes(p.status)?"":"disabled"}></div><div class="field"><label class="f">درجة النجاح</label><input class="input" type="number" name="passMark" value="70"></div></div>`,
          [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); H.recordResult(p, x.empId, {pre:f.pre, attended: f.att===""?undefined:f.att==="1", post:f.post, passMark:f.passMark}); U.route(); }}]); });
      $$("[data-rate]",root).forEach(b=>b.onclick=()=>act(()=>H.rateProvider(p, b.dataset.rate),"شكراً لتقييمك"));
    }};
}

/* =================== العلاقات العامة والمحتوى (القسم 6.3) =================== */
let calOffset = 0;
function content(tab){
  need("content");
  const u = me(); const s = S(); tab = tab || "calendar";
  const T = [["calendar","تقويم النشر"],["list","المحتوى"],["media","مكتبة الهوية"]];
  let body = "", bind = null;
  const cName = id => esc((s.customers.find(c=>c.id===id)||{}).name||"");
  if(tab==="calendar"){
    const base = new Date(); base.setDate(1); base.setMonth(base.getMonth() + calOffset); const y = base.getFullYear(), mo = base.getMonth();
    const first = new Date(y,mo,1).getDay(), days = new Date(y,mo+1,0).getDate();
    const cells = []; for(let i=0;i<first;i++) cells.push(""); for(let d=1; d<=days; d++) cells.push(d);
    const key = d => y + "-" + String(mo+1).padStart(2,"0") + "-" + String(d).padStart(2,"0");
    body = `<div class="card"><div class="row" style="margin-bottom:10px"><button class="btn sm" id="cal-prev">→ السابق</button><h2 style="flex:1;text-align:center">${base.toLocaleDateString("ar-SD-u-nu-latn",{month:"long",year:"numeric"})}</h2><button class="btn sm" id="cal-next">التالي ←</button></div>
      <div style="display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:4px">${["أحد","إثنين","ثلاثاء","أربعاء","خميس","جمعة","سبت"].map(d=>`<div class="small muted" style="text-align:center">${d}</div>`).join("")}
      ${cells.map(d=>{ if(!d) return "<div></div>"; const items = s.content.filter(c=>c.date===key(d)); const tk = key(d)===today();
        return `<div style="min-height:74px;border:1px solid ${tk?"var(--accent)":"var(--line)"};border-radius:8px;padding:4px;background:var(--surface-2);overflow:hidden"><div class="small ${tk?"":"muted"}" style="${tk?"font-weight:700;color:var(--accent)":""}">${d}</div>${items.map(c=>`<div class="small" data-ct="${c.id}" style="cursor:pointer;margin-top:2px;padding:1px 4px;border-radius:5px;background:var(--surface);border-inline-start:3px solid ${c.status==="published"?"var(--ok)":c.status==="draft"?"var(--line)":"var(--accent)"};white-space:nowrap;overflow:hidden;text-overflow:ellipsis" title="${esc(c.title)}">${esc(c.title)}</div>`).join("")}</div>`; }).join("")}</div></div>`;
  }
  if(tab==="list"){
    body = `<div class="card"><div class="card-head"><h2>المحتوى والحملات</h2>${BOS.can(u,"content","create")?'<button class="btn primary" id="new-ct">＋ محتوى</button>':""}</div>
      <p class="small muted">مسودة ← قيد الاعتماد (مسار «نشر إعلامي») ← معتمد ← مجدول ← منشور. لا يُرسل للاعتماد محتوى يذكر عميلاً لم يوثق موافقته على النشر.</p>
      ${s.content.length?`<div class="table-wrap"><table><thead><tr><th>الرقم</th><th>العنوان</th><th>القناة</th><th>الحملة</th><th>العميل المذكور</th><th>التاريخ</th><th>الحالة</th></tr></thead><tbody>${s.content.map(c=>`<tr class="link" data-ct="${c.id}"><td class="mono">${esc(c.no)}</td><td>${esc(c.title)}${c.sensitive?' <span class="badge warn">حساس</span>':""}</td><td class="small">${esc(c.channel)}</td><td class="small">${esc(c.campaign)}</td><td class="small">${c.customerId?cName(c.customerId) + " " + (H.consentOk(c)?'<span class="badge ok">موافقة موثقة</span>':'<span class="badge bad">بلا موافقة</span>'):"—"}</td><td class="small">${c.date?fmtDate(c.date):"—"}</td><td>${ctBadge(c.status)}</td></tr>`).join("")}</tbody></table></div>`:empty("لا محتوى")}</div>`;
    bind = root => { if($("#new-ct",root)) $("#new-ct",root).onclick = contentEditor; };
  }
  if(tab==="media"){
    const assets = [["الشعار الرسمي","assets/logo.png","يُستخدم في كل المواد الخارجية والمستندات",1],["رمز الهوية (شفاف)","library/09-brand-symbol-transparent.png","للأيقونات والخلفيات الداكنة",1],["البانر التعريفي","assets/banner.jpg","للمنصات والعروض",1],["الختم الإداري","assets/stamp.png","للمستندات الرسمية المعتمدة فقط — لا يُستخدم في المواد الإعلامية",3]];
    body = `<div class="grid g2">${assets.map(([n,src,rule,cls])=>{ const ok = BOS.clearance(u) >= cls;
      return `<div class="card"><div class="row" style="align-items:flex-start">${ok?`<img src="${esc(src)}" alt="" style="width:110px;height:110px;object-fit:contain;border-radius:12px;background:#0B1B3A">`:'<div style="width:110px;height:110px;border-radius:12px;background:var(--surface-2);display:grid;place-items:center">🔒</div>'}
        <div style="flex:1;min-width:0"><b>${esc(n)}</b><div class="small muted">${esc(rule)}</div>${ok?`<a class="btn sm" href="${esc(src)}" download style="margin-top:8px">⬇ تنزيل</a>`:'<div class="small" style="color:var(--bad)">يتطلب مستوى سرية أعلى</div>'}</div></div></div>`; }).join("")}</div>
      <div class="card"><h2 style="margin-bottom:6px">الألوان المعتمدة</h2><div class="row">${[["#0B1B3A","الكحلي الأساسي"],["#18CDEF","السماوي الكهربائي"],["#F3B83F","الذهبي المساعد"],["#F5F9FF","الأبيض"]].map(([c,n])=>`<div style="text-align:center"><div style="width:74px;height:48px;border-radius:10px;background:${c};border:1px solid var(--line)"></div><div class="small">${n}</div><div class="mono small muted">${c}</div></div>`).join("")}</div>
        <a class="btn sm" href="library/09-01.docx" download style="margin-top:10px">⬇ دليل الهوية البصرية</a></div>`;
  }
  return {title:"العلاقات العامة والمحتوى", html:`${head("العلاقات العامة والمحتوى", "تقويم الحملات والمنشورات ومكتبة الهوية والاعتمادات")}${tabs(T,tab,"#/content")}${body}`,
    bind: root => { bindTabs(root); bind && bind(root);
      if($("#cal-prev",root)){ $("#cal-prev",root).onclick = () => { calOffset--; U.route(); }; $("#cal-next",root).onclick = () => { calOffset++; U.route(); }; }
      $$("[data-ct]",root).forEach(el=>el.onclick=()=>contentModal(s.content.find(c=>c.id===el.dataset.ct))); }};
}
function contentEditor(){
  const s = S();
  modal("محتوى جديد", `<div class="field"><label class="f">العنوان *</label><input class="input" name="title"></div>
    <div class="grid g2"><div class="field"><label class="f">القناة</label><select class="input" name="channel">${D.TYPES.publish.fields[0].o.map(o=>`<option>${o}</option>`).join("")}</select></div><div class="field"><label class="f">تاريخ النشر المقترح</label><input class="input" type="date" name="date"></div>
    <div class="field"><label class="f">الحملة</label><input class="input" name="campaign"></div>
    <div class="field"><label class="f">يذكر عميلاً</label><select class="input" name="customerId"><option value="">لا</option>${s.customers.map(c=>`<option value="${c.id}">${esc(c.name)} ${c.publishConsent?"✓":"(بلا موافقة)"}</option>`).join("")}</select></div></div>
    <div class="field"><label class="f">النص *</label><textarea class="input" name="body" style="min-height:140px"></textarea></div><label class="check"><input type="checkbox" name="sensitive"> محتوى حساس (يتطلب المدير العام)</label>`,
    [{label:"حفظ كمسودة", cls:"primary", onClick:bg=>{ H.createContent(formData(bg)); U.route(); }}], true);
}
function contentModal(c){
  const u = me(); const order = H.CONTENT_FLOW.map(x=>x[0]); const next = order[order.indexOf(c.status)+1];
  const req = c.requestId && S().requests.find(r=>r.id===c.requestId);
  const canMove = (BOS.can(u,"content","edit") || c.by===u.id) && next && next!=="approved";
  modal(c.no + " — " + c.title, `<div>${ctBadge(c.status)} · ${esc(c.channel)} ${c.date?"· " + fmtDate(c.date):""}</div>
    <div style="white-space:pre-wrap;margin:10px 0;padding:10px;border:1px solid var(--line);border-radius:10px;background:var(--surface-2)">${esc(c.body)}</div>
    ${c.customerId?`<div class="small">يذكر: <a href="#/customer/${c.customerId}">${esc((S().customers.find(x=>x.id===c.customerId)||{}).name||"")}</a> ${H.consentOk(c)?'<span class="badge ok">موافقة موثقة</span>':'<span class="badge bad">لا توجد موافقة على النشر</span>'}</div>`:""}
    ${req?`<div class="small">مسار الاعتماد: <a href="#/request/${req.id}">${esc(req.no)}</a> ${statusBadge(req.status)}</div>`:""}
    ${next==="scheduled"?`<div class="field" style="margin-top:10px"><label class="f">تاريخ النشر</label><input class="input" type="date" id="cd" value="${esc(c.date)}"></div>`:""}
    ${next==="published"?`<div class="field" style="margin-top:10px"><label class="f">رابط المنشور</label><input class="input" id="cu" dir="ltr"></div>`:""}
    ${c.url?`<div class="small">الرابط: <a href="${esc(c.url)}" target="_blank" rel="noopener">${esc(c.url)}</a></div>`:""}`,
    canMove ? [{label: next==="review" ? "إرسال للاعتماد" : "الانتقال إلى «" + H.CSTAT[next] + "»", cls:"primary", onClick:bg=>{ H.moveContent(c, next, {date:($("#cd",bg)||{}).value, url:($("#cu",bg)||{}).value}); U.refresh(); }}] : []);
}

/* =================== صفحة العميل (القسم 6.3) =================== */
function customer(id){
  need("customers");
  const s = S(); const c = s.customers.find(x=>x.id===id); if(!c) throw new Error("العميل غير موجود");
  const u = me(); const edit = BOS.can(u,"customers","edit");
  const quotes = s.quotes.filter(q=>q.customerId===id), invs = s.invoices.filter(i=>i.customerId===id);
  const projs = (s.projects||[]).filter(p=>p.customerId===id), tks = (s.tickets||[]).filter(t=>t.customerId===id);
  const inter = s.interactions.filter(i=>i.customerId===id), surv = s.surveys.filter(x=>x.customerId===id);
  const csat = avg(tks.filter(t=>t.csat).map(t=>t.csat).concat(surv.map(x=>x.score)));
  const npsL = surv.filter(x=>x.nps!=null).map(x=>x.nps); const nps = npsL.length ? Math.round((npsL.filter(n=>n>=9).length - npsL.filter(n=>n<=6).length)/npsL.length*100) : null;
  const bal = invs.filter(i=>!["draft","cancelled"].includes(i.status)).reduce((a,i)=>a + BOS.totals(i.items,i.discount,i.taxRate).total - BOS.invoicePaid(i),0);
  const complaints = s.requests.filter(r=>r.type==="complaint" && r.data.customer===c.name);
  return {title:c.name, html:`${head("🤝 " + c.name, `${esc(c.kind)} · <span class="badge info">${esc(c.stage)}</span> · ${c.publishConsent?'<span class="badge ok">موافقة نشر موثقة</span>':'<span class="badge bad">لا يجوز النشر عنه</span>'}`,
      (edit?'<button class="btn" id="edit">تعديل</button><button class="btn" id="consent">سجل موافقة النشر</button>':"") + (edit||BOS.can(u,"customers","create")?'<button class="btn primary" id="int">＋ تواصل</button>':"") + (edit||BOS.can(u,"support","edit")?'<button class="btn" id="sv">＋ استبيان رضا</button>':""))}
    <div class="grid g4">${kpi("الرضا", csat==null?"—":csat.toFixed(1)+"/5", tks.filter(t=>t.csat).length + surv.length + " تقييم", csat!=null&&csat<3.5?"bad":"")}${kpi("صافي التوصية (NPS)", nps==null?"—":nps, npsL.length + " رد")}${kpi("الرصيد المستحق", money(bal), invs.length + " فاتورة", bal?"warn":"")}${kpi("تذاكر مفتوحة", tks.filter(t=>t.status!=="closed").length, complaints.length + " شكوى عالية الخطورة", complaints.length?"warn":"")}</div>
    <div class="grid g2" style="margin-top:14px;align-items:start">
      <div class="card"><h2 style="margin-bottom:10px">سجل التواصل والاجتماعات</h2>${inter.length?inter.map(i=>`<div class="list-item"><span class="badge">${esc(i.kind)}</span><div class="grow small"><b>${esc(i.summary)}</b><div class="muted">${fmtDate(i.date)} · ${empName(i.by)}${i.next?" · التالي: " + esc(i.next) + (i.nextDate?" (" + fmtDate(i.nextDate) + ")":""):""}</div></div></div>`).join(""):empty("لا تواصل مسجل")}
        <dl class="kv" style="margin-top:12px"><dt>جهة الاتصال</dt><dd>${esc(c.contact||"—")}</dd><dt>الهاتف</dt><dd>${esc(c.phone||"—")}</dd><dt>البريد</dt><dd>${esc(c.email||"—")}</dd><dt>ملاحظات</dt><dd>${esc(c.notes||"—")}</dd></dl></div>
      <div class="card"><h2 style="margin-bottom:10px">الأعمال</h2>
        ${projs.map(p=>`<div class="small list-item">🗂️ <a href="#/project/${p.id}">${esc(p.name)}</a> <span class="muted">${esc((window.BOS_OPS?BOS_OPS.PSTATUS[p.status]:p.status)||"")}</span></div>`).join("")}
        ${quotes.map(q=>`<div class="small list-item">📄 <a href="#/quote/${q.id}">${esc(q.no)}</a> <span class="muted">${money(BOS.totals(q.items,q.discount,q.taxRate).total,q.currency)} · ${esc(q.status)}</span></div>`).join("")}
        ${invs.map(i=>`<div class="small list-item">🧾 <a href="#/invoice/${i.id}">${esc(i.no)}</a> <span class="muted">${money(BOS.totals(i.items,i.discount,i.taxRate).total,i.currency)} · مدفوع ${money(BOS.invoicePaid(i),i.currency)}</span></div>`).join("")}
        ${tks.map(t=>`<div class="small list-item">🎧 <a href="#/ticket/${t.id}">${esc(t.no)}</a> ${esc(t.subject)} <span class="muted">${t.csat?t.csat+"/5":""}</span></div>`).join("")}
        ${complaints.map(r=>`<div class="small list-item">⚠️ <a href="#/request/${r.id}">${esc(r.no)}</a> ${statusBadge(r.status)}</div>`).join("")}
        ${!projs.length&&!quotes.length&&!invs.length&&!tks.length?empty("لا أعمال بعد"):""}
        ${surv.length?`<h3 style="margin:12px 0 6px">استبيانات الرضا</h3>${surv.map(x=>`<div class="small list-item">${stars(x.score)} ${x.nps!=null?"· توصية " + x.nps:""}<div class="grow muted">${esc(x.comment)} · ${fmtDate(x.at)}</div></div>`).join("")}`:""}
        ${(c.consentLog||[]).length?`<h3 style="margin:12px 0 6px">سجل موافقة النشر</h3>${c.consentLog.slice().reverse().map(l=>`<div class="small list-item"><span class="badge ${l.value?"ok":"bad"}">${l.value?"موافقة":"سحب"}</span><div class="grow muted">${esc(l.evidence)} ${l.scope?"· " + esc(l.scope):""} · ${empName(l.by)} · ${fmtDate(l.at)}</div></div>`).join("")}`:""}</div>
    </div>`,
    bind: root => {
      if($("#edit",root)) $("#edit",root).onclick = () => window.BOS_VIEWS_CORE.customerEditor(c);
      if($("#consent",root)) $("#consent",root).onclick = () => modal("موافقة النشر — " + c.name, `<div class="field"><label class="f">القرار</label><select class="input" name="v"><option value="1" ${c.publishConsent?"":"selected"}>توثيق موافقة</option><option value="0" ${c.publishConsent?"selected":""}>سحب الموافقة</option></select></div>
        <div class="field"><label class="f">مصدر الموافقة (إلزامي للتوثيق)</label><input class="input" name="evidence" placeholder="خطاب رسمي بتاريخ… / بند في العقد / بريد من…"></div><div class="field"><label class="f">النطاق</label><input class="input" name="scope" placeholder="الاسم فقط / الاسم والشعار / دراسة حالة كاملة"></div>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ const f = formData(bg); H.setConsent(c, f.v==="1", f); U.refresh(); }}]);
      if($("#int",root)) $("#int",root).onclick = () => modal("تسجيل تواصل — " + c.name, `<div class="grid g2"><div class="field"><label class="f">النوع</label><select class="input" name="kind">${H.INTERACTION_KINDS.map(k=>`<option>${k}</option>`).join("")}</select></div><div class="field"><label class="f">التاريخ</label><input class="input" type="date" name="date" value="${today()}"></div></div>
        <div class="field"><label class="f">الملخص *</label><textarea class="input" name="summary"></textarea></div><div class="grid g2"><div class="field"><label class="f">الخطوة التالية</label><input class="input" name="next"></div><div class="field"><label class="f">موعدها</label><input class="input" type="date" name="nextDate"></div></div>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ H.addInteraction(c.id, formData(bg)); U.route(); }}], true);
      if($("#sv",root)) $("#sv",root).onclick = () => modal("استبيان رضا — " + c.name, `<div class="field"><label class="f">المشروع</label><select class="input" name="projectId"><option value="">عام</option>${projs.map(p=>`<option value="${p.id}">${esc(p.name)}</option>`).join("")}</select></div>
        <div class="grid g2"><div class="field"><label class="f">الرضا (1–5) *</label><input class="input" type="number" name="score" min="1" max="5"></div><div class="field"><label class="f">احتمال التوصية (0–10)</label><input class="input" type="number" name="nps" min="0" max="10"></div></div><div class="field"><label class="f">تعليق العميل</label><textarea class="input" name="comment"></textarea></div>`,
        [{label:"حفظ", cls:"primary", onClick:bg=>{ H.addSurvey(c.id, formData(bg)); U.route(); }}], true);
    }};
}

/* =================== لوحة المدير العام =================== */
function dashExtra(){
  const u = me(); if(!BOS.can(u,"dashboard","view")) return "";
  const m = H.metrics();
  return `<h2 style="margin:18px 0 10px">الموارد البشرية والتدريب</h2>
    <div class="grid g4">${kpi("معدل دوران الموظفين", m.turnover + "%", m.left + " غادروا خلال 12 شهراً · " + m.headcount + " نشط")}${kpi("الغياب هذا الشهر", pct(m.absRate), "", m.absRate?"warn":"")}${kpi("إكمال التدريب / النجاح", pct(m.completion) + " / " + pct(m.passRate), m.trainedWithImpact + " برنامج بأثر موثق")}${kpi("فجوات مهارات بلا خطة", m.gapsUnplanned, m.gapsOpen + " فجوة إجمالاً", m.gapsUnplanned?"warn":"")}</div>`;
}

Object.assign(window.BOS_VIEWS, {hr, training, program:programView, content, customer});
window.BOS_VIEWS_HR = {homeTop, homeExtra, bindHome, personExtra, dashExtra};
})();
