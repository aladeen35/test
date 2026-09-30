/* نظام البشرى لإدارة الشركة — المزامنة المشتركة بين الزملاء
   عند فتح النظام من رابطه المنشور: تُحفظ بيانات الشركة في قاعدة بيانات مشتركة يراها كل من شورك معه الرابط،
   وتصل تعديلات كل شخص للآخرين مباشرة. خارج الرابط المنشور يعمل النظام محلياً كما كان.
   - الحالة تُقسم على مستندات بحسب المفتاح (requests, mail, audit…) وتُجزأ تحت حد 256 ك.ب للمستند
   - التعديلات المتزامنة تُدمج سجلاً بسجل (دمج ثلاثي: الأساس / المحلي / البعيد)
   - سلسلة التدقيق تُعاد بناؤها عند الدمج فتبقى سليمة، والأرقام المكررة تُعاد ترقيمها */
(function(){
"use strict";
const CHUNK = 60000;            // حروف لكل جزء — يبقي المستند أقل كثيراً من 256 ك.ب
const LOCAL_ONLY = ["session"];
const SESSION_KEY = "bos-shared-session";
const eq = (a,b) => a===b || JSON.stringify(a)===JSON.stringify(b);
const clone = o => o===undefined ? undefined : JSON.parse(JSON.stringify(o));
const isObj = o => o && typeof o==="object" && !Array.isArray(o);
const hasIds = a => Array.isArray(a) && a.length>0 && a.every(x=>x && typeof x==="object" && "id" in x);

/* ---------- الدمج الثلاثي (دالة نقية قابلة للاختبار) ---------- */
function mergeArr(b, l, r){
  b = b||[]; const bm = new Map(b.map(x=>[x.id,x])), lm = new Map(l.map(x=>[x.id,x])), rm = new Map(r.map(x=>[x.id,x]));
  const out = [];
  for(const ri of r){
    const li = lm.get(ri.id), bi = bm.get(ri.id);
    if(li){ out.push(eq(li,ri) ? li : (bi && eq(li,bi)) ? ri : li); }
    else if(bi){ if(!eq(ri,bi)) out.push(ri); }          // حُذف محلياً: يبقى فقط إن عدّله غيرك بعد ذلك
    else out.push(ri);                                    // جديد من زميل
  }
  const front = [], back = [];
  l.forEach((li, idx) => {
    if(rm.has(li.id)) return;
    const bi = bm.get(li.id);
    if(bi){ if(!eq(li,bi)) back.push(li); return; }       // حذفه زميل: يبقى فقط إن عدّلته أنت
    (idx < l.length/2 ? front : back).push(li);           // جديد محلياً: يحافظ على موضعه (الأحدث أولاً غالباً)
  });
  return front.concat(out, back);
}
function mergeAudit(b, l, r, hash, stable){
  const bl = (b||[]).length;
  if(r.length < bl) return l;
  const mine = l.slice(bl);
  if(!mine.length) return r;
  if(r.length === bl) return l;
  let prev = r.length ? r[r.length-1].hash : "GENESIS", seq = r.length;
  const re = mine.map(ev=>{ const e = Object.assign({}, ev, {seq:++seq, prev}); delete e.hash; e.hash = hash(prev + "|" + stable(Object.assign({}, e, {hash:undefined}))); prev = e.hash; return e; });
  return r.concat(re);
}
function mergeObj(b, l, r){
  b = b||{}; const out = {};
  for(const k of new Set(Object.keys(l).concat(Object.keys(r)))){
    const lv = l[k], rv = r[k], bv = b[k];
    if(!(k in r)){ if(!(k in b) || !eq(lv,bv)) out[k] = lv; continue; }
    if(!(k in l)){ if(!(k in b) || !eq(rv,bv)) out[k] = rv; continue; }
    out[k] = eq(lv,rv) ? lv : eq(lv,bv) ? rv : lv;
  }
  return out;
}
function renumber(state, remote){
  const counters = state.counters = state.counters || {};
  for(const [k, arr] of Object.entries(state)){
    if(!Array.isArray(arr) || !arr.length || !arr[0] || !("no" in arr[0])) continue;
    const seen = new Map(); const remoteIds = new Set(((remote||{})[k]||[]).map(x=>x.id));
    for(const it of arr){ if(!it || !it.no) continue;
      const other = seen.get(it.no);
      if(!other){ seen.set(it.no, it); continue; }
      const loser = remoteIds.has(it.id) && !remoteIds.has(other.id) ? other : it;   // صاحب الرقم الأسبق يحتفظ به
      const m = /^(.*)-(\d+)$/.exec(loser.no); if(!m) continue;
      const pre = m[1];
      const max = Math.max(counters[pre]||0, ...arr.filter(x=>x.no && x.no.startsWith(pre + "-")).map(x=>Number(x.no.slice(pre.length+1))||0));
      counters[pre] = max + 1; const old = loser.no; loser.no = pre + "-" + String(counters[pre]).padStart(4,"0");
      loser.renumberedFrom = old; seen.set(loser.no, loser); if(loser===other) seen.set(it.no, it);
    }
  }
}
function merge3(base, local, remote, hash, stable){
  if(!remote) return local; if(!base) base = {};
  const out = {};
  for(const k of new Set(Object.keys(local).concat(Object.keys(remote)))){
    if(LOCAL_ONLY.includes(k)){ out[k] = local[k]; continue; }
    const l = local[k], r = remote[k], b = base[k];
    if(r===undefined){ out[k] = l; continue; }
    if(l===undefined){ out[k] = r; continue; }
    if(eq(l,r)){ out[k] = l; continue; }
    if(eq(l,b)){ out[k] = r; continue; }
    if(eq(r,b)){ out[k] = l; continue; }
    if(k==="audit") out[k] = mergeAudit(b, l, r, hash, stable);
    else if(k==="counters"){ out[k] = Object.assign({}, r); for(const c in l) out[k][c] = Math.max(l[c]||0, r[c]||0); }
    else if(Array.isArray(l) && Array.isArray(r) && (hasIds(l)||hasIds(r)||!l.length||!r.length)) out[k] = mergeArr(b, l, r);
    else if(isObj(l) && isObj(r)) out[k] = mergeObj(b, l, r);
    else out[k] = l;
  }
  renumber(out, remote);
  return out;
}

/* ---------- التخزين المجزأ ---------- */
const safeKey = k => k.replace(/[^A-Za-z0-9_\-.~:@+]/g,"_");
function encode(value){ const s = JSON.stringify(value); const parts = []; for(let i=0;i<s.length;i+=CHUNK) parts.push(s.slice(i,i+CHUNK)); return parts.length ? parts : ["null"]; }
function assemble(docs){
  const heads = {}, chunks = {};
  for(const d of docs){ const id = d.id, x = d.data(); if(!x) continue;
    const m = /^(.+)~(\d+)$/.exec(id); if(m) (chunks[m[1]] = chunks[m[1]]||{})[m[2]] = x; else heads[id] = x; }
  const out = {}, revs = {};
  for(const [id, h] of Object.entries(heads)){
    if(!h.key) continue;
    let s = h.c || ""; let ok = true;
    for(let i=1;i<h.n;i++){ const c = (chunks[id]||{})[i]; if(!c || c.rev!==h.rev){ ok = false; break; } s += c.c; }
    if(!ok) continue;                                     // كتابة جارية — يبقى آخر إصدار مكتمل
    try{ out[h.key] = JSON.parse(s); revs[h.key] = h.rev; }catch(e){}
  }
  return {state: out, revs};
}

/* ---------- الحالة ---------- */
let db = null, user = null, uid = null, owner = false, shared = false, readOnly = false;
let base = null, remote = null, unsub = null, dirty = false, pushing = false, timer = null, pendingRender = false, lastRemoteAt = null, status = "local";
const tab = Math.random().toString(36).slice(2,9);
const listeners = [];
const setStatus = s => { status = s; listeners.forEach(f=>{ try{ f(s); }catch(e){} }); };

function stripLocal(o){ const x = Object.assign({}, o); LOCAL_ONLY.forEach(k=>delete x[k]); return x; }
function loadSession(){ try{ return JSON.parse(localStorage.getItem(SESSION_KEY)||"null"); }catch(e){ return null; } }
function saveSession(){ try{ localStorage.setItem(SESSION_KEY, JSON.stringify(BOS.S.session||null)); }catch(e){} }

function embedded(){ if(window.__BOS_FORCE_SHARED) return true; try{ return window.self !== window.top; }catch(e){ return true; } }
async function waitForClaude(ms){ const t0 = Date.now(); while(!window.claude && Date.now()-t0 < ms) await new Promise(r=>setTimeout(r,100)); return window.claude || null; }

/* يحاول الاتصال بقاعدة البيانات المشتركة. يعيد "shared" أو "local" */
async function init(){
  if(!embedded()) return "local";
  const c = await waitForClaude(4000); if(!c || !c.use) return "local";
  setStatus("connecting");
  try{ db = await c.use("db"); }catch(e){ db = null; }
  if(!db){ setStatus("local"); return "local"; }
  try{ user = await c.use("user"); }catch(e){ user = null; }
  try{ uid = user ? await user.id() : null; }catch(e){ uid = null; }
  try{ owner = user ? !!(await user.isOwner()) : false; }catch(e){ owner = false; }
  try{ const w = user && user.can ? await user.can("data.write") : null; if(w===false) readOnly = true; }catch(e){}
  shared = true;
  const first = await db.collection("state").get();
  const {state} = assemble(first.docs);
  const localCache = BOS.S;
  if(Object.keys(state).length){
    remote = state; base = clone(state);
    BOS.replace(Object.assign(clone(state), {session: loadSession()}));
  } else {
    remote = null; base = {};
    BOS.replace(Object.assign(BOS.blank(), {session:null}));
    BOS.S._localCandidate = localCache && localCache.setupDone ? localCache : null;   // بيانات تجربة سابقة في هذا المتصفح
  }
  unsub = db.collection("state").onSnapshot(onRemote, err=>{ setStatus("error"); console.warn("sync", err); });
  setStatus(readOnly ? "readonly" : "live");
  return "shared";
}
function busy(){ return !!document.querySelector(".modal-bg") || (document.activeElement && /INPUT|TEXTAREA|SELECT/.test(document.activeElement.tagName) && document.activeElement.value); }
function onRemote(snap){
  const {state} = assemble(snap.docs);
  if(!Object.keys(state).length) return;
  if(remote && eq(stripLocal(state), stripLocal(remote))) return;
  const incoming = state;
  // أول بيانات تصل لمتصفح لم يُعدّ شيئاً بعد: تؤخذ كما هي
  if(!remote && !BOS.S.setupDone){
    remote = incoming; base = clone(incoming); lastRemoteAt = new Date().toISOString();
    BOS.replace(Object.assign(clone(incoming), {session: loadSession()}));
    if(busy()) pendingRender = true; else rerender();
    return;
  }
  const merged = merge3(base, BOS.S, incoming, BOS.hash, BOS.stable);
  merged.session = BOS.S.session;
  remote = incoming; base = clone(incoming); lastRemoteAt = new Date().toISOString();
  const changedLocally = !eq(stripLocal(merged), stripLocal(incoming));
  BOS.replace(merged);
  if(changedLocally) schedule();
  if(busy()) pendingRender = true; else rerender();
}
function rerender(){ pendingRender = false; if(window.BOS_UI){ if(BOS.S.setupDone && BOS.S.session) BOS_UI.refresh(); else BOS_UI.render(); } }
setInterval(()=>{ if(pendingRender && !busy()) rerender(); }, 1200);

/* يُستدعى من BOS.save */
function changed(){ if(!shared) return; saveSession(); if(readOnly) return; dirty = true; schedule(); }
function schedule(){ clearTimeout(timer); timer = setTimeout(push, 500); }
async function push(){
  if(!shared || readOnly || pushing) return;
  if(!BOS.S.setupDone && !(remote && Object.keys(remote).length)) return;
  const localState = stripLocal(BOS.S);
  const keys = Object.keys(localState).filter(k=>k!=="_localCandidate" && !eq(localState[k], base ? base[k] : undefined));
  if(!keys.length){ dirty = false; return; }
  pushing = true; dirty = false; setStatus("saving");
  try{
    // قفل قصير يمنع تداخل الحفظ بين الزملاء
    const lock = db.doc("meta/lock"); let got = false;
    for(let i=0;i<12 && !got;i++){ const a = await lock.acquire({holder: (uid||"anon") + ":" + tab, ttlMs: 8000}); got = a.acquired; if(!got) await new Promise(r=>setTimeout(r, 300 + Math.random()*500)); }
    // أحدث نسخة من الخادم ثم دمج
    const fresh = assemble((await db.collection("state").get()).docs).state;
    const hasRemote = Object.keys(fresh).length > 0;
    const merged = hasRemote ? merge3(base, BOS.S, fresh, BOS.hash, BOS.stable) : clone(BOS.S);
    merged.session = BOS.S.session; delete merged._localCandidate;
    const toWrite = Object.keys(stripLocal(merged)).filter(k=>!eq(merged[k], fresh[k]));
    const by = (BOS.S.session||{}).userId || "";
    for(const k of toWrite){
      const parts = encode(merged[k]); const rev = Math.random().toString(36).slice(2,10); const id = safeKey(k);
      for(let i=1;i<parts.length;i++) await db.doc("state/" + id + "~" + i).set({rev, c:parts[i]});
      await db.doc("state/" + id).set({key:k, n:parts.length, rev, c:parts[0], at:new Date().toISOString(), by});
      const prevHead = remote && remote[k] !== undefined ? encode(remote[k]).length : 0;
      for(let i=parts.length;i<prevHead;i++) await db.doc("state/" + id + "~" + i).delete();
    }
    remote = clone(stripLocal(merged)); base = clone(remote);
    if(!eq(stripLocal(merged), stripLocal(BOS.S))){ BOS.replace(merged); if(busy()) pendingRender = true; else rerender(); }
    setStatus("live");
  }catch(e){
    console.warn("sync push", e);
    if(e && e.code==="invalid_argument"){ readOnly = true; setStatus("readonly"); if(window.BOS_UI) BOS_UI.toast("لديك صلاحية عرض فقط في هذا الرابط — اطلب من المالك صلاحية «مساهم»","bad"); }
    else if(e && e.code==="quota_exceeded"){ setStatus("error"); if(window.BOS_UI) BOS_UI.toast("امتلأت سعة قاعدة البيانات المشتركة — أنشئ نسخة احتياطية واحذف بيانات قديمة","bad"); }
    else { setStatus("error"); dirty = true; setTimeout(schedule, 3000); }
  } finally { pushing = false; if(dirty) schedule(); }
}

/* ---------- ربط حساب Claude بموظف ---------- */
function boundEmployee(){ return uid ? (BOS.S.bindings||{})[uid] : null; }
function boundTo(empId){ return Object.entries(BOS.S.bindings||{}).find(([k,v])=>v===empId); }
function bind(empId){
  if(!shared || !uid) return;
  const other = boundTo(empId); if(other && other[0]!==uid) throw new Error("هذا الموظف مرتبط بحساب زميل آخر");
  BOS.S.bindings = BOS.S.bindings || {}; BOS.S.bindings[uid] = empId;
  BOS.audit("ربط حساب مستخدم بموظف","session",empId,(BOS.byId(empId)||{}).name||"",empId);
}
function unbind(empId){
  const u = BOS.me(); if(!(BOS.isTop(u) || BOS.can(u,"people","manage"))) throw new Error("فك الربط للمدير العام أو الموارد البشرية");
  const b = boundTo(empId); if(!b) throw new Error("غير مرتبط");
  delete BOS.S.bindings[b[0]]; BOS.audit("فك ربط حساب مستخدم","session",empId,(BOS.byId(empId)||{}).name||""); BOS.save();
}
function adoptLocal(){ const c = BOS.S._localCandidate; if(!c) return false; BOS.replace(Object.assign(clone(c), {session:null, bindings:{}})); BOS.save(); return true; }

window.BOS_SYNC = {merge3, mergeArr, mergeAudit, encode, assemble, init, changed, push, bind, unbind, boundEmployee, boundTo, adoptLocal,
  get shared(){ return shared; }, get owner(){ return owner; }, get uid(){ return uid; }, get readOnly(){ return readOnly; }, get status(){ return status; }, get lastRemoteAt(){ return lastRemoteAt; },
  onStatus(f){ listeners.push(f); }, embedded};
})();
