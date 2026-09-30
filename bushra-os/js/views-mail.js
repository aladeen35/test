/* نظام البشرى لإدارة الشركة — صفحات البريد الداخلي */
(function(){
"use strict";
const U = window.BOS_UI;
const M = window.BOS_MAIL;
const {$, $$, esc, fmtDT, avatar, empName, toast, modal, formData} = U;
const S = () => BOS.S;
const me = () => BOS.me();
const go = h => { location.hash = h; };
const empty = t => `<div class="empty">${esc(t)}</div>`;
const act = (fn, msg) => { try{ fn(); if(msg) toast(msg,"ok"); U.refresh(); }catch(e){ toast(e.message,"bad"); } };
const when = iso => { const d = new Date(iso), n = new Date(); return d.toDateString()===n.toDateString() ? d.toLocaleTimeString("ar-SD-u-nu-latn",{hour:"2-digit",minute:"2-digit"}) : d.toLocaleDateString("ar-SD-u-nu-latn",{day:"numeric",month:"short"}); };
const addrOf = id => (BOS.byId(id)||{}).mailAddr || "";
const who = id => { const e = BOS.byId(id); return e ? `<span title="${esc(e.mailAddr||"")}">${esc(e.name)}</span>` : "—"; };

/* حقل «إلى» بعناوين متعددة مع إكمال تلقائي من الموظفين وقوائم التوزيع */
function recipientsField(name, preset){
  const opts = S().employees.filter(BOS.active).filter(e=>e.id!==me().id).map(e=>`<option value="${esc(e.mailAddr)}">${esc(e.name)} — ${esc(BOS.posTitle(e.positionId))}</option>`).join("")
    + M.lists().map(l=>`<option value="${esc(l.addr)}">${esc(l.name)} (${l.members.length})</option>`).join("");
  return `<div class="field"><label class="f">إلى</label><div class="rcpt" data-rcpt="${name}">${(preset||[]).map(a=>chip(a)).join("")}<input class="input" list="dl-${name}" placeholder="اكتب اسماً أو عنواناً ثم Enter" dir="auto" style="flex:1;min-width:180px;border:0;background:transparent;box-shadow:none"></div><datalist id="dl-${name}">${opts}</datalist>
    <div class="small muted">مثال: a.alnour@${esc(M.domain())} — أو قائمة قسم مثل dev@${esc(M.domain())}</div></div>`;
}
const chip = a => `<span class="badge accent rc" data-a="${esc(a)}" style="padding:4px 10px">${esc(labelFor(a))} <button type="button" aria-label="إزالة" style="color:inherit">✕</button></span>`;
function labelFor(a){ const e = M.byAddr(a); if(e) return e.name; const l = M.lists().find(x=>x.addr===a); return l ? l.name : a; }
function bindRecipients(root){
  $$("[data-rcpt]",root).forEach(box=>{
    const inp = $("input",box);
    const add = v => { v = v.trim().replace(/[،,;]+$/,""); if(!v) return; const e = S().employees.find(x=>x.name===v); if(e) v = e.mailAddr;
      if(!M.byAddr(v) && !M.lists().some(l=>l.addr===v.toLowerCase())) return toast("عنوان غير معروف: " + v,"bad");
      if($$(".rc",box).some(c=>c.dataset.a===v.toLowerCase())) { inp.value = ""; return; }
      inp.insertAdjacentHTML("beforebegin", chip(v.toLowerCase())); inp.value = ""; wire(); };
    const wire = () => $$(".rc button",box).forEach(b=>b.onclick=()=>b.closest(".rc").remove());
    inp.addEventListener("keydown", e=>{ if(e.key==="Enter" || e.key===","|| e.key==="،"){ e.preventDefault(); add(inp.value); } else if(e.key==="Backspace" && !inp.value){ const l = $$(".rc",box).pop(); if(l) l.remove(); } });
    inp.addEventListener("change", ()=>{ if(inp.value.includes("@")) add(inp.value); });
    box.onclick = e => { if(e.target===box) inp.focus(); };
    wire();
  });
}
const readRecipients = (root, name) => { const box = $(`[data-rcpt="${name}"]`,root); const l = $$(".rc",box).map(c=>c.dataset.a); const v = $("input",box).value.trim(); if(v) l.push(v); return l; };

function compose(pre){
  pre = pre || {};
  const bg = modal("رسالة جديدة", `${recipientsField("to", pre.to)}
    <div class="field"><label class="f">الموضوع</label><input class="input" name="subject" value="${esc(pre.subject||"")}"></div>
    <div class="field"><label class="f">الرسالة</label><textarea class="input" name="body" style="min-height:170px">${esc(pre.body||"")}</textarea></div>
    <label class="check"><input type="checkbox" name="important"> مهمة</label>
    <p class="small muted">من: <span class="mono">${esc(me().mailAddr)}</span> · البريد داخلي بين موظفي الشركة فقط، ويظهر للمشاركين في المحادثة وحدهم.</p>`,
    [{label:"إرسال", cls:"primary", onClick:bg=>{ const f = formData($(".modal-b",bg)); const t = M.send({to:readRecipients(bg,"to"), subject:f.subject, body:f.body, important:f.important}); toast("أُرسلت الرسالة","ok"); go("#/mail/t/" + t.id); U.refresh(); }}], true);
  bindRecipients(bg);
}

function mail(folder, id){
  const u = me(); if(!BOS.can(u,"mail","view")) throw new Error("البريد الداخلي غير متاح لحسابك");
  if(folder==="t") return thread(id);
  folder = folder || "inbox";
  const F = [["inbox","📥 الوارد"],["starred","⭐ المميزة"],["sent","📤 المرسل"],["archive","🗄 الأرشيف"],["directory","📇 دليل العناوين"]];
  const counts = {inbox: M.unreadCount(u)};
  let body;
  if(folder==="directory"){
    const emps = S().employees.filter(BOS.active);
    body = `<div class="card"><div class="card-head"><h2>دليل عناوين الشركة</h2><input class="input" id="dq" placeholder="بحث بالاسم أو القسم أو العنوان" style="max-width:280px"></div>
      <p class="small muted">الصيغة: أول حرف من الاسم الأول، ثم نقطة، ثم الاسم الأخير @${esc(M.domain())}. يُضاف رقم عند تكرار العنوان، ويمكن للموارد البشرية تصحيحه من ملف الموظف.</p>
      <div class="table-wrap"><table><thead><tr><th>الموظف</th><th>العنوان</th><th>المنصب</th><th>القسم</th><th></th></tr></thead><tbody>
      ${emps.map(e=>`<tr data-s="${esc(e.name+" "+e.mailAddr+" "+((BOS.dept(e.deptId)||{}).name||""))}"><td>${avatar(e)} <b class="small">${esc(e.name)}</b></td><td class="mono small" dir="ltr" style="text-align:end">${esc(e.mailAddr)}</td><td class="small">${esc(BOS.posTitle(e.positionId))}</td><td class="small">${esc((BOS.dept(e.deptId)||{}).name||"")}</td><td>${e.id!==u.id?`<button class="btn sm" data-to="${esc(e.mailAddr)}">مراسلة</button>`:'<span class="badge">أنت</span>'}</td></tr>`).join("")}</tbody></table></div></div>
      <div class="card"><h2 style="margin-bottom:8px">قوائم التوزيع</h2>${M.lists().map(l=>`<div class="list-item small"><span class="mono" dir="ltr">${esc(l.addr)}</span><div class="grow">${esc(l.name)} — ${l.members.length} عضو${l.restricted?' <span class="badge warn">للمدير العام والموارد البشرية</span>':""}</div><button class="btn sm" data-to="${esc(l.addr)}">مراسلة</button></div>`).join("")}</div>`;
  } else {
    const list = M.folder(u, folder, "");
    body = `<div class="card"><div class="row" style="margin-bottom:10px"><input class="input" id="mq" placeholder="بحث في الموضوع أو النص أو المشاركين" style="flex:1;min-width:200px"></div><div id="ml">${threadList(list)}</div></div>`;
  }
  return {title:"البريد الداخلي", html:`<div class="page-head"><div><h1>البريد الداخلي</h1><div class="sub">عنوانك: <span class="mono" dir="ltr">${esc(u.mailAddr||"—")}</span></div></div><div class="actions"><button class="btn primary" id="compose">✏️ رسالة جديدة</button></div></div>
    <div class="tabs">${F.map(([k,l])=>`<button class="${k===folder?"on":""}" data-href="#/mail/${k}">${l}${counts[k]?` <span class="badge solid">${counts[k]}</span>`:""}</button>`).join("")}</div>${body}`,
    bind: root => {
      $$("[data-href]",root).forEach(b=>b.onclick=()=>go(b.dataset.href));
      $("#compose",root).onclick = () => compose();
      $$("[data-to]",root).forEach(b=>b.onclick=()=>compose({to:[b.dataset.to]}));
      if($("#dq",root)) $("#dq",root).oninput = e => { const q = e.target.value.trim(); $$("[data-s]",root).forEach(r=>r.classList.toggle("hidden", q && !r.dataset.s.includes(q))); };
      const bindList = () => $$("[data-th]",root).forEach(r=>r.onclick=()=>go("#/mail/t/" + r.dataset.th));
      if($("#mq",root)) $("#mq",root).oninput = e => { $("#ml",root).innerHTML = threadList(M.folder(u, folder, e.target.value)); bindList(); };
      bindList();
    }};
}
function threadList(list){
  const u = me();
  if(!list.length) return empty("لا توجد رسائل");
  return list.map(t=>{ const last = t.messages[t.messages.length-1]; const un = M.unreadFor(u,t); const others = t.participants.filter(id=>id!==u.id);
    return `<div class="list-item" data-th="${t.id}" style="cursor:pointer;${un?"":"opacity:.9"}">${avatar(BOS.byId(last.from))}<div class="grow" style="min-width:0">
      <div class="row small" style="gap:6px"><b style="${un?"":"font-weight:600"}">${others.slice(0,3).map(id=>esc((BOS.byId(id)||{}).name||"")).join("، ")}${others.length>3?" +" + (others.length-3):""}</b>${t.participants.length>2?`<span class="badge">${t.participants.length} مشاركين</span>`:""}${t.important?'<span class="badge warn">مهمة</span>':""}${(t.starredBy||[]).includes(u.id)?"⭐":""}<span class="spacer"></span><span class="muted">${when(last.at)}</span></div>
      <div style="${un?"font-weight:700":""}">${esc(t.subject)} ${un?`<span class="badge solid">${un}</span>`:""}</div>
      <div class="small muted" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${last.system?"":esc((BOS.byId(last.from)||{}).name||"") + ": "}${esc(last.body)}</div></div></div>`; }).join("");
}
function thread(id){
  const u = me(); const t = S().mail.find(x=>x.id===id);
  if(!t || !M.canSee(u,t)) throw new Error("المحادثة غير موجودة أو لست من المشاركين فيها");
  M.markRead(t);
  const star = (t.starredBy||[]).includes(u.id), arch = (t.archivedBy||[]).includes(u.id);
  return {title:t.subject, html:`<div class="row no-print" style="margin-bottom:12px"><a class="btn" href="#/mail/inbox">→ الوارد</a><span class="spacer"></span>
      <button class="btn" id="star">${star?"★ إزالة التمييز":"☆ تمييز"}</button><button class="btn" id="arch">${arch?"إعادة للوارد":"🗄 أرشفة"}</button><button class="btn" id="add">＋ إضافة مشاركين</button>${t.participants.length>2?'<button class="btn danger" id="leave">مغادرة</button>':""}</div>
    <div class="card"><h1 style="font-size:1.25rem">${esc(t.subject)}</h1><div class="small muted" style="margin:4px 0 10px">${esc(t.no)} · بدأها ${who(t.createdBy)} · ${fmtDT(t.createdAt)}</div>
      <div class="row" style="gap:6px">${t.participants.map(id=>`<span class="badge ${id===u.id?"accent":""}" title="${esc(addrOf(id))}">${esc((BOS.byId(id)||{}).name||"")}</span>`).join("")}</div></div>
    <div style="display:flex;flex-direction:column;gap:10px;margin-top:12px">${t.messages.map(m=> m.system ? `<div class="small muted" style="text-align:center">— ${esc(m.body)} · ${fmtDT(m.at)} —</div>` :
      `<div class="card" style="padding:12px 14px;${m.from===u.id?"border-inline-start:3px solid var(--accent)":""}"><div class="row small">${avatar(BOS.byId(m.from))}<b>${who(m.from)}</b><span class="mono muted" dir="ltr">${esc(addrOf(m.from))}</span><span class="spacer"></span><span class="muted">${fmtDT(m.at)}</span></div><div style="white-space:pre-wrap;margin-top:8px">${esc(m.body)}</div></div>`).join("")}</div>
    <div class="card" style="margin-top:12px"><div class="field"><label class="f">الرد على الجميع (${t.participants.length-1})</label><textarea class="input" id="rb" style="min-height:110px"></textarea></div><div class="row"><span class="spacer"></span><button class="btn primary" id="send">إرسال الرد</button></div></div>`,
    bind: root => {
      $("#send",root).onclick = () => act(()=>M.reply(t, $("#rb",root).value.trim()), "أُرسل الرد");
      $("#star",root).onclick = () => act(()=>M.toggleStar(t));
      $("#arch",root).onclick = () => act(()=>M.toggleArchive(t), arch ? "أعيدت للوارد" : "أُرشفت");
      if($("#leave",root)) $("#leave",root).onclick = () => U.ask("مغادرة المحادثة", "لن تصلك ردود هذه المحادثة بعد الآن.", ()=>{ act(()=>M.leave(t)); go("#/mail/inbox"); }, {confirmOnly:true, okLabel:"مغادرة", cls:"danger solid"});
      $("#add",root).onclick = () => { const bg = modal("إضافة مشاركين إلى المحادثة", `${recipientsField("add")}<div class="field"><label class="f">ملاحظة (تظهر في المحادثة)</label><input class="input" name="note"></div><p class="small muted">يرى المشاركون الجدد المحادثة كاملة من بدايتها.</p>`,
        [{label:"إضافة", cls:"primary", onClick:bg=>{ M.addParticipants(t, readRecipients(bg,"add"), $("[name=note]",bg).value.trim()); U.refresh(); }}]); bindRecipients(bg); };
    }};
}

Object.assign(window.BOS_VIEWS, {mail});
window.BOS_VIEWS_MAIL = {compose};
})();
