/* نظام البشرى لإدارة الشركة — البريد الداخلي
   عنوان لكل موظف بصيغة: أول حرف من الاسم الأول + "." + الاسم الأخير @ نطاق الشركة (مثال a.alnour@albushra.tech)
   محادثات جماعية يُضاف إليها المشاركون، وقوائم توزيع للأقسام */
(function(){
"use strict";
const S = () => BOS.S;
const me = () => BOS.me();
const now = () => BOS.now();
const fail = m => { throw new Error(m); };

/* ---------- تحويل الأسماء العربية إلى حروف لاتينية ---------- */
const MAP = {"ا":"a","أ":"a","إ":"i","آ":"a","ٱ":"a","ب":"b","ت":"t","ث":"th","ج":"j","ح":"h","خ":"kh","د":"d","ذ":"th","ر":"r","ز":"z","س":"s","ش":"sh",
  "ص":"s","ض":"d","ط":"t","ظ":"z","ع":"a","غ":"gh","ف":"f","ق":"q","ك":"k","ل":"l","م":"m","ن":"n","ه":"h","ة":"a","و":"w","ي":"y","ى":"a","ء":"","ئ":"e","ؤ":"o","ـ":""};
const VOWEL = /[aeiou]/;
/* أسماء شائعة بكتابتها المعتادة — يسبق الجدول العام */
const COMMON = {"محمد":"mohamed","أحمد":"ahmed","احمد":"ahmed","علي":"ali","عمر":"omar","عثمان":"osman","حسن":"hassan","حسين":"hussein","إبراهيم":"ibrahim","ابراهيم":"ibrahim",
  "يوسف":"yousif","يعقوب":"yagoub","عبدالله":"abdalla","عبد الله":"abdalla","خالد":"khalid","صالح":"salih","موسى":"musa","عباس":"abbas","آدم":"adam","ادم":"adam",
  "الطيب":"altayeb","النور":"alnour","الأمين":"alamin","الامين":"alamin","الفاتح":"alfatih","بابكر":"babiker","محجوب":"mahjoub","عوض":"awad","سيد":"sayed","كمال":"kamal",
  "جعفر":"jaafar","الله":"alla","الرحيم":"alrahim","الرحمن":"alrahman","قريب":"garib","الزهراء":"alzahraa","فاطمة":"fatima","الدين":"aldin","البشرى":"albushra","حسام":"hussam","عبد":"abd","مازن":"mazin","سارة":"sara","هبة":"hiba","مروة":"marwa","لينا":"lina","ريم":"reem",
  "نهى":"noha","إيمان":"iman","ايمان":"iman","آمنة":"amna","سلمى":"salma","ياسر":"yasir","طارق":"tariq","بكري":"bakri","منتصر":"muntasir"};
function translit(word){
  word = String(word||"").trim(); if(!word) return "";
  if(COMMON[word]) return COMMON[word];
  if(/\s/.test(word)) return word.split(/\s+/).map(translit).join("");
  if(/^[a-z0-9.\-]+$/i.test(word)) return word.toLowerCase();
  const ch = Array.from(word.replace(/[ً-ْٰ]/g,""));   // حذف التشكيل
  let out = "";
  ch.forEach((c,i)=>{
    const prev = out.slice(-1), last = i===ch.length-1;
    if(c==="و"){ out += (i===0 || VOWEL.test(prev)) ? "w" : "o"; return; }
    if(c==="ي"){ out += (i===0 || VOWEL.test(prev)) ? "y" : "i"; return; }
    if(c==="ا" && i>0){ out += prev==="a" ? "" : "a"; return; }
    out += MAP[c]!==undefined ? MAP[c] : (/[a-z0-9]/i.test(c) ? c.toLowerCase() : "");
  });
  return out.replace(/(.)\1{2,}/g,"$1$1");
}
const domain = () => { const d = (S().settings.mailDomain || "").trim(); if(d) return d.toLowerCase();
  const m = /@([\w.-]+)$/.exec(S().company.email||""); return m ? m[1].toLowerCase() : "albushra.tech"; };
/* الاسم الأول والأخير: تجاهل الألقاب (أ. د.) وضم «عبد» إلى ما يليه */
function nameParts(full){
  let w = String(full||"").replace(/^(أ\.|د\.|م\.|أ\s|د\s)\s*/g,"").trim().split(/\s+/).filter(Boolean);
  const joined = []; for(let i=0;i<w.length;i++){ if(w[i]==="عبد" && w[i+1]){ joined.push("عبد " + w[i+1]); i++; } else if(w[i+1]==="الله"){ joined.push(w[i] + " الله"); i++; } else joined.push(w[i]); }
  return {first: joined[0]||"", last: joined.length>1 ? joined[joined.length-1] : ""};
}
function suggestAddress(full, exceptId){
  const {first, last} = nameParts(full);
  const f = translit(first).replace(/[^a-z0-9]/g,""), l = translit(last).replace(/[^a-z0-9]/g,"");
  let local = (f ? f[0] : "u") + (l ? "." + l : ""); if(!l) local = f || "user";
  let addr = local + "@" + domain(), n = 2;
  while(S().employees.some(e=>e.id!==exceptId && e.mailAddr===addr)) addr = local + (n++) + "@" + domain();
  return addr;
}
const VALID = /^[a-z0-9]+([._-][a-z0-9]+)*@[a-z0-9-]+(\.[a-z0-9-]+)+$/;
function setAddress(e, addr){
  const u = me(); addr = String(addr||"").trim().toLowerCase();
  if(!(BOS.can(u,"people","edit") || BOS.isTop(u))) fail("تعديل العناوين للموارد البشرية");
  if(!VALID.test(addr)) fail("صيغة العنوان غير صحيحة (حروف لاتينية وأرقام ونقطة فقط)");
  if(S().employees.some(x=>x.id!==e.id && x.mailAddr===addr)) fail("العنوان مستخدم لموظف آخر");
  const before = e.mailAddr; e.mailAddr = addr;
  BOS.audit("تعديل عنوان بريد داخلي","employee",e.id,e.name + ": " + (before||"—") + " ← " + addr); BOS.save();
}
function assignMissing(){ let n = 0; for(const e of S().employees){ if(!e.mailAddr && !e.anonymized){ e.mailAddr = suggestAddress(e.name, e.id); n++; } } return n; }

/* قوائم التوزيع: كل قسم + الجميع */
function lists(){
  const s = S(); const out = [];
  for(const d of s.departments){ const members = s.employees.filter(e=>BOS.active(e) && e.deptId===d.id).map(e=>e.id);
    if(members.length) out.push({addr:(d.key||"dept").replace(/[^a-z0-9]/gi,"").toLowerCase() + "@" + domain(), name:"قسم " + d.name, members, dept:d.id}); }
  out.push({addr:"all@" + domain(), name:"جميع الموظفين", members:s.employees.filter(BOS.active).map(e=>e.id), restricted:true});
  return out;
}
const byAddr = a => S().employees.find(e=>e.mailAddr===String(a).trim().toLowerCase());
/* تحويل ما كُتب في «إلى» إلى موظفين: عناوين، قوائم، أو أسماء */
function resolve(tokens){
  const u = me(); const ids = new Set(), unknown = [];
  for(let t of tokens){ t = String(t).trim(); if(!t) continue;
    const e = byAddr(t) || S().employees.find(x=>x.name===t);
    if(e){ if(!BOS.active(e)) unknown.push(t + " (حساب موقوف)"); else ids.add(e.id); continue; }
    const l = lists().find(x=>x.addr===t.toLowerCase());
    if(l){ if(l.restricted && !(BOS.isTop(u) || BOS.can(u,"people","manage"))) fail("قائمة «" + l.name + "» للمدير العام والموارد البشرية فقط"); l.members.forEach(i=>ids.add(i)); continue; }
    unknown.push(t);
  }
  if(unknown.length) fail("عناوين غير معروفة: " + unknown.join("، "));
  return Array.from(ids);
}

/* ---------- المحادثات ---------- */
const canSee = (u, t) => !!u && t.participants.includes(u.id);
function unreadFor(u, t){ if(!canSee(u,t)) return 0; const r = (t.readBy||{})[u.id] || ""; return t.messages.filter(m=>m.at > r && m.from!==u.id).length; }
function send(o){
  const u = me(); if(!BOS.can(u,"mail","create")) fail("لا تملك صلاحية الإرسال");
  const to = resolve(o.to||[]).filter(id=>id!==u.id);
  if(!to.length) fail("أضف مستلماً واحداً على الأقل");
  if(!o.subject) fail("الموضوع مطلوب"); if(!o.body) fail("اكتب نص الرسالة");
  const t = {id:BOS.uid("th"), no:BOS.nextNo("MSG"), subject:o.subject.slice(0,160), participants:[u.id].concat(to), createdBy:u.id, createdAt:now(),
    messages:[{id:BOS.uid("m"), from:u.id, body:o.body, at:now(), link:o.link||""}], readBy:{[u.id]:now()}, archivedBy:[], important:!!o.important, log:[]};
  S().mail.unshift(t);
  to.forEach(id=>BOS.notify(id,"رسالة جديدة من " + u.name + ": " + t.subject,"#/mail/t/"+t.id,"task"));
  // لا نكتب نص الرسالة في سجل التدقيق — الموضوع وعدد المشاركين فقط
  BOS.audit("بريد داخلي: محادثة جديدة","mail",t.id,t.no + " — " + t.participants.length + " مشارك");
  BOS.save(); return t;
}
function reply(t, body){
  const u = me(); if(!canSee(u,t)) fail("لست مشاركاً في هذه المحادثة"); if(!body) fail("اكتب الرد");
  const m = {id:BOS.uid("m"), from:u.id, body, at:now()}; t.messages.push(m);
  t.readBy = t.readBy||{}; t.readBy[u.id] = now(); t.archivedBy = [];
  t.participants.filter(id=>id!==u.id).forEach(id=>BOS.notify(id,"رد من " + u.name + ": " + t.subject,"#/mail/t/"+t.id,"task"));
  BOS.audit("بريد داخلي: رد","mail",t.id,t.no); BOS.save(); return m;
}
function addParticipants(t, tokens, note){
  const u = me(); if(!canSee(u,t)) fail("لست مشاركاً");
  const ids = resolve(tokens).filter(id=>!t.participants.includes(id));
  if(!ids.length) fail("كل من اخترتهم مشاركون بالفعل");
  t.participants.push(...ids);
  t.messages.push({id:BOS.uid("m"), system:true, from:u.id, at:now(), body:"أضاف " + u.name + " إلى المحادثة: " + ids.map(i=>(BOS.byId(i)||{}).name).join("، ") + (note?" — " + note:"")});
  ids.forEach(id=>BOS.notify(id,"أضافك " + u.name + " إلى محادثة: " + t.subject,"#/mail/t/"+t.id,"task"));
  BOS.audit("بريد داخلي: إضافة مشاركين","mail",t.id,t.no + " — +" + ids.length); BOS.save();
}
function leave(t){
  const u = me(); if(!canSee(u,t)) fail("لست مشاركاً");
  if(t.participants.length <= 2) fail("لا يمكن مغادرة محادثة بين شخصين — أرشفها بدلاً من ذلك");
  t.participants = t.participants.filter(id=>id!==u.id);
  t.messages.push({id:BOS.uid("m"), system:true, from:u.id, at:now(), body:u.name + " غادر المحادثة"});
  BOS.audit("بريد داخلي: مغادرة","mail",t.id,t.no); BOS.save();
}
function markRead(t){ const u = me(); if(!canSee(u,t)) return; t.readBy = t.readBy||{}; const last = t.messages[t.messages.length-1].at; if(t.readBy[u.id] !== last && unreadFor(u,t)){ t.readBy[u.id] = now(); BOS.save(); } }
function toggleArchive(t){ const u = me(); t.archivedBy = t.archivedBy||[]; const i = t.archivedBy.indexOf(u.id); if(i>=0) t.archivedBy.splice(i,1); else t.archivedBy.push(u.id); BOS.save(); }
function toggleStar(t){ const u = me(); t.starredBy = t.starredBy||[]; const i = t.starredBy.indexOf(u.id); if(i>=0) t.starredBy.splice(i,1); else t.starredBy.push(u.id); BOS.save(); }
function folder(u, name, q){
  const all = S().mail.filter(t=>canSee(u,t));
  const arch = t => (t.archivedBy||[]).includes(u.id);
  let l = name==="sent" ? all.filter(t=>t.messages.some(m=>m.from===u.id && !m.system)) : name==="archive" ? all.filter(arch) : name==="starred" ? all.filter(t=>(t.starredBy||[]).includes(u.id)) : all.filter(t=>!arch(t));
  if(q){ q = q.trim(); l = l.filter(t=>t.subject.includes(q) || t.messages.some(m=>(m.body||"").includes(q)) || t.participants.some(id=>((BOS.byId(id)||{}).name||"").includes(q) || ((BOS.byId(id)||{}).mailAddr||"").includes(q.toLowerCase()))); }
  return l.sort((a,b)=>a.messages[a.messages.length-1].at < b.messages[b.messages.length-1].at ? 1 : -1);
}
const unreadCount = u => u ? S().mail.filter(t=>canSee(u,t) && !(t.archivedBy||[]).includes(u.id) && unreadFor(u,t)).length : 0;

function migrate(){
  const s = S(); if(!s.company || !s.company.tradeName) return;
  if(!s.settings.mailDomain){ const m = /@([\w.-]+)$/.exec(s.company.email||""); s.settings.mailDomain = m ? m[1].toLowerCase() : "albushra.tech"; }
  assignMissing();
}
function seedMail(){
  const s = S(); const k = key => s.employees.find(e=>BOS.active(e) && (BOS.pos(e.positionId)||{}).key===key);
  const gm = k("gm"), pm = k("pm"), dl = k("devlead"), qm = k("qm"); if(!gm || !pm || !dl) return;
  const saved = s.session.userId;
  try{
    s.session.userId = gm.id;
    const t = send({to:[pm.mailAddr, dl.mailAddr], subject:"خطة الأسبوع لمشروع تطبيق المواعيد", body:"أرجو تحديث خطة الأسبوع قبل اجتماع الخميس، مع أي مخاطر تحتاج قراراً مني."});
    s.session.userId = pm.id; reply(t,"تم. الخطر الأهم هو الربط مع نظام المستشفى؛ اقترحنا واجهة وسيطة.");
    if(qm) addParticipants(t,[qm.mailAddr],"لمتابعة خطة الاختبار");
  } finally { s.session.userId = saved; BOS.save(); }
}

window.BOS_MAIL = {translit, nameParts, suggestAddress, setAddress, assignMissing, domain, lists, resolve, byAddr, canSee, unreadFor, send, reply, addParticipants, leave,
  markRead, toggleArchive, toggleStar, folder, unreadCount, migrate, seedMail, VALID};
})();
