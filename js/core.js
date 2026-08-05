/* ============================================================
   هاف مليون ½M — النواة
   الحالة والتخزين والمزامنة ومحرك التخطيط وسجل الزيارات والتصدير
   ============================================================ */

/* ================= الثوابت ================= */
const VISIT_MIN = { small: 90, large: 120 };
const DAYS_AR = ["الأحد","الاثنين","الثلاثاء","الأربعاء","الخميس"];
const MEETING_MIN = 120;
/* ألوان أيام متحقَّق منها لونيًا (وضع فاتح/داكن) */
const DAY_COLORS_LIGHT = ["#2a78d6","#eb6834","#1baf7a","#eda100","#e87ba4"];
const DAY_COLORS_DARK  = ["#3987e5","#d95926","#199e70","#c98500","#d55181"];
function dayColor(i){ return (isDark() ? DAY_COLORS_DARK : DAY_COLORS_LIGHT)[i] ?? "#B29267"; }

const DEFAULT_SETTINGS = {
  homeLocation:null, meetingVenue:null, meetingVenueName:"مقر الاجتماع الأسبوعي",
  workStartHour:9, workEndHour:18, avgSpeedKmh:45,
  notificationsEnabled:true, leadTimeMinutes:30,
  nonMeetingStart:"home", customStart:null,
  maxBranchesPerDay:0,
  syncEnabled:false, syncBinId:null, syncKey:null,
  /* نظام الفريق: صندوق JSONBin مشترك يجمع زيارات كل الأعضاء */
  teamEnabled:false, teamBinId:null, teamKey:null, memberName:"",
  teamManager:false /* يُظهر أدوات إدارة مهام الفريق (حماية واجهة فقط) */
};

let state = {
  branches:[], plans:[], settings:{...DEFAULT_SETTINGS},
  activePlanId:null, tab:"plan", weekSelection:null, visits:[],
  tasks:[] /* المهام الأسبوعية المحلية */
};
let memStore = {};

/* ================= السمة (فاتح/داكن) ================= */
function themePref(){ try{ return localStorage.getItem("hm-theme") || "auto"; }catch(e){ return "auto"; } }
function isDark(){
  const t = themePref();
  return t==="dark" || (t==="auto" && matchMedia("(prefers-color-scheme: dark)").matches);
}
function applyTheme(){
  document.documentElement.dataset.theme = isDark() ? "dark" : "light";
  const meta = document.querySelector('meta[name="theme-color"]');
  if(meta) meta.content = isDark() ? "#211B16" : "#C9AE85";
  updateThemeIcon();
}
function toggleTheme(){
  const next = isDark() ? "light" : "dark";
  try{ localStorage.setItem("hm-theme", next); }catch(e){}
  applyTheme();
  render();
}
function updateThemeIcon(){
  const ic = document.getElementById("theme-ic");
  if(!ic) return;
  ic.innerHTML = isDark()
    ? '<circle cx="12" cy="12" r="4.2"/><path d="M12 2.5v2.4M12 19.1v2.4M4.3 4.3 6 6M18 18l1.7 1.7M2.5 12h2.4M19.1 12h2.4M4.3 19.7 6 18M18 6l1.7-1.7"/>'
    : '<path d="M20.4 14.2A8.4 8.4 0 0 1 9.8 3.6a8.4 8.4 0 1 0 10.6 10.6z"/>';
}
matchMedia("(prefers-color-scheme: dark)").addEventListener?.("change", ()=>{ if(themePref()==="auto"){ applyTheme(); render(); } });

/* ================= التوست ================= */
function toast(msg, type="info", ms=3200){
  const stack = document.getElementById("toast-stack");
  if(!stack){ console.log(msg); return; }
  const el = document.createElement("div");
  el.className = "toast" + (type==="ok" ? " ok" : type==="err" ? " err" : "");
  const em = type==="ok" ? "✅" : type==="err" ? "⚠️" : "💡";
  el.innerHTML = `<span>${em}</span><span style="flex:1">${esc(msg)}</span>`;
  stack.appendChild(el);
  setTimeout(()=>{ el.classList.add("out"); setTimeout(()=>el.remove(), 320); }, ms);
}

/* ================= التخزين ================= */
const hasStorage = () => typeof window.storage !== "undefined";
function lsGet(k){ try{ return localStorage.getItem(k); }catch(e){ return memStore[k] ?? null; } }
function lsSet(k,v){ try{ localStorage.setItem(k,v); }catch(e){ memStore[k]=v; } }
async function stGet(key, shared=false){
  if(hasStorage()){
    try{ const r = await window.storage.get(key, shared); return r ? r.value : null; }catch(e){ return null; }
  }
  return lsGet((shared?"sh:":"")+key);
}
async function stSet(key, val, shared=false){
  if(hasStorage()){
    try{ await window.storage.set(key, val, shared); return; }catch(e){ console.error("storage",e); }
  }
  lsSet((shared?"sh:":"")+key, val);
}

async function persist(){
  await stSet("hm-data", JSON.stringify({
    branches:state.branches, plans:state.plans, settings:state.settings,
    activePlanId:state.activePlanId, weekSelection:state.weekSelection, visits:state.visits,
    tasks:state.tasks
  }));
  scheduleCloudPush();
  scheduleTeamPush();
}

async function hydrate(){
  const raw = await stGet("hm-data");
  if(raw){
    try{
      const d = JSON.parse(raw);
      state.branches = d.branches?.length ? d.branches : structuredClone(SEED_BRANCHES);
      state.plans = d.plans ?? [];
      state.settings = {...DEFAULT_SETTINGS, ...(d.settings??{})};
      state.activePlanId = d.activePlanId ?? (state.plans[0]?.id ?? null);
      state.weekSelection = d.weekSelection ?? null;
      state.visits = d.visits ?? [];
      state.tasks = d.tasks ?? [];
      return;
    }catch(e){}
  }
  state.branches = structuredClone(SEED_BRANCHES);
}

/* ================= المزامنة السحابية (JSONBin) ================= */
const JB_BASE="https://api.jsonbin.io/v3";
let cloudTimer=null, cloudBusy=false;
function cloudPayload(){
  return {branches:state.branches, plans:state.plans, settings:state.settings,
    activePlanId:state.activePlanId, weekSelection:state.weekSelection, visits:state.visits,
    tasks:state.tasks, _ts:Date.now()};
}
function scheduleCloudPush(){
  const s=state.settings;
  if(!s.syncEnabled || !s.syncBinId || !s.syncKey) return;
  clearTimeout(cloudTimer);
  cloudTimer=setTimeout(cloudPush, 1500);
}
async function cloudPush(){
  const s=state.settings;
  if(!s.syncEnabled || !s.syncBinId || !s.syncKey || cloudBusy) return;
  cloudBusy=true; updateSyncStatus("جارٍ الرفع…","var(--text-2)");
  try{
    const r=await fetch(`${JB_BASE}/b/${s.syncBinId}`,{
      method:"PUT",
      headers:{"Content-Type":"application/json","X-Master-Key":s.syncKey},
      body:JSON.stringify(cloudPayload())
    });
    if(!r.ok) throw new Error(r.status);
    updateSyncStatus("مُزامَن ✓ "+new Date().toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"}),"var(--ok)");
  }catch(e){ updateSyncStatus("تعذّر الرفع — سيُعاد عند التعديل التالي","var(--danger)"); }
  finally{ cloudBusy=false; }
}
async function cloudPull(){
  const s=state.settings;
  if(!s.syncEnabled || !s.syncBinId || !s.syncKey) return false;
  try{
    const r=await fetch(`${JB_BASE}/b/${s.syncBinId}/latest`,{headers:{"X-Master-Key":s.syncKey}});
    if(!r.ok) throw new Error(r.status);
    const j=await r.json(); const d=j.record;
    if(d && d.branches){
      state.branches=d.branches; state.plans=d.plans??[]; state.visits=d.visits??[];
      state.tasks=d.tasks??state.tasks??[];
      state.weekSelection=d.weekSelection??null; state.activePlanId=d.activePlanId??null;
      state.settings={...state.settings, ...(d.settings??{}), syncEnabled:true, syncBinId:s.syncBinId, syncKey:s.syncKey};
      await stSet("hm-data", JSON.stringify({branches:state.branches, plans:state.plans, settings:state.settings, activePlanId:state.activePlanId, weekSelection:state.weekSelection, visits:state.visits}));
      return true;
    }
  }catch(e){ updateSyncStatus("تعذّر جلب البيانات — تحقق من الرمز والمفتاح","var(--danger)"); }
  return false;
}
async function cloudCreateBin(masterKey){
  const r=await fetch(`${JB_BASE}/b`,{
    method:"POST",
    headers:{"Content-Type":"application/json","X-Master-Key":masterKey,"X-Bin-Name":"half-million-sync","X-Bin-Private":"true"},
    body:JSON.stringify(cloudPayload())
  });
  if(!r.ok) throw new Error(r.status);
  const j=await r.json();
  return j.metadata.id;
}
function updateSyncStatus(msg,color){
  const el=document.getElementById("sync-status");
  if(el){ el.textContent=msg; el.style.color=color; }
}

/* ================= نظام الفريق =================
   صندوق JSONBin واحد يتشاركه الفريق:
   { type:"hm-team", members: { "<اسم العضو>": { visits:[...], updatedAt } } }
   كل عضو يكتب مدخلته فقط (قراءة ← تعديل ← كتابة) وتُدمج القراءات في اللوحة. */
let teamTimer=null, teamBusy=false;
let teamCache={ts:0, members:null, tasks:[]};

function teamReady(){
  const s=state.settings;
  return !!(s.teamEnabled && s.teamBinId && s.teamKey && (s.memberName||"").trim());
}
function scheduleTeamPush(){
  if(!teamReady()) return;
  clearTimeout(teamTimer);
  teamTimer=setTimeout(teamPush, 3000);
}
async function teamFetch(){
  const s=state.settings;
  const r=await fetch(`${JB_BASE}/b/${s.teamBinId}/latest`,{headers:{"X-Master-Key":s.teamKey}});
  if(!r.ok) throw new Error(r.status);
  const j=await r.json();
  const rec=j.record;
  return (rec && rec.type==="hm-team") ? rec : {type:"hm-team", members:{}};
}
async function teamPush(){
  if(!teamReady() || teamBusy) return;
  teamBusy=true;
  try{
    const s=state.settings;
    let rec;
    try{ rec=await teamFetch(); }catch(e){ rec={type:"hm-team", members:{}}; }
    rec.members = rec.members ?? {};
    rec.members[s.memberName.trim()] = { visits:state.visits, updatedAt:Date.now() };
    const r=await fetch(`${JB_BASE}/b/${s.teamBinId}`,{
      method:"PUT",
      headers:{"Content-Type":"application/json","X-Master-Key":s.teamKey},
      body:JSON.stringify(rec)
    });
    if(!r.ok) throw new Error(r.status);
    updateTeamStatus("مُزامَن مع الفريق ✓ "+new Date().toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"}),"var(--ok)");
  }catch(e){
    updateTeamStatus("تعذّر الرفع للفريق — سيُعاد عند التعديل التالي","var(--danger)");
  }finally{ teamBusy=false; }
}
async function teamPull(force=false){
  if(!teamReady()) return null;
  // ذاكرة مؤقتة 60 ثانية لتخفيف الطلبات
  if(!force && teamCache.members && Date.now()-teamCache.ts<60000) return teamCache.members;
  const rec=await teamFetch();
  teamCache={ts:Date.now(), members:rec.members??{}, tasks:rec.tasks??[]};
  return teamCache.members;
}
/* دمج زيارات كل الأعضاء مع وسم كل زيارة باسم صاحبها */
function mergeTeamVisits(members){
  const out=[];
  for(const [name,entry] of Object.entries(members??{})){
    for(const v of (entry.visits??[])) out.push({...v, owner:name});
  }
  return out;
}
async function teamCreateBin(masterKey, memberName){
  const r=await fetch(`${JB_BASE}/b`,{
    method:"POST",
    headers:{"Content-Type":"application/json","X-Master-Key":masterKey,"X-Bin-Name":"half-million-team","X-Bin-Private":"true"},
    body:JSON.stringify({type:"hm-team", members:{ [memberName]: {visits:state.visits, updatedAt:Date.now()} }})
  });
  if(!r.ok) throw new Error(r.status);
  const j=await r.json();
  return j.metadata.id;
}
function updateTeamStatus(msg,color){
  const el=document.getElementById("team-status");
  if(el){ el.textContent=msg; el.style.color=color; }
}

/* ================= المهام الأسبوعية =================
   مهمة تُقيَّم في كل زيارة بمقياس A/B/C:
   A مطابق تمامًا · B متوسط/به ملاحظة · C مخالف تمامًا (+ لا ينطبق)
   المصدر: "local" على هذا الجهاز فقط، أو "team" من صندوق الفريق المشترك. */
function weekStart(ts=Date.now()){
  const d=new Date(ts);
  d.setDate(d.getDate()-d.getDay()); d.setHours(0,0,0,0);
  return d.getTime();
}
function taskIsCurrent(t){
  if(!t || t.active===false) return false;
  if(t.once && t.weekOf!==weekStart()) return false;
  return true;
}
/* المهام الفعالة الآن: مهام الفريق أولًا ثم المحلية */
function activeTasks(){
  const local=state.tasks.filter(taskIsCurrent);
  const team=(teamReady()?(teamCache.tasks??[]):[])
    .filter(taskIsCurrent)
    .filter(tt=>!local.some(l=>l.id===tt.id));
  return [...team, ...local];
}
function newTask(title, desc, source, once){
  return {
    id:"tsk-"+Date.now().toString(36)+Math.random().toString(36).slice(2,5),
    title, desc:desc||"", source,
    createdBy:(state.settings.memberName||"").trim()||null,
    once:!!once, weekOf: once?weekStart():null,
    active:true, createdAt:Date.now()
  };
}
/* حفظ/حذف مهمة فريق في الصندوق المشترك (قراءة ← تعديل ← كتابة) */
async function teamTaskSave(task){
  const s=state.settings;
  let rec;
  try{ rec=await teamFetch(); }catch(e){ rec={type:"hm-team", members:{}}; }
  rec.tasks=[...(rec.tasks??[]).filter(t=>t.id!==task.id), task];
  const r=await fetch(`${JB_BASE}/b/${s.teamBinId}`,{
    method:"PUT",
    headers:{"Content-Type":"application/json","X-Master-Key":s.teamKey},
    body:JSON.stringify(rec)
  });
  if(!r.ok) throw new Error(r.status);
  teamCache={ts:Date.now(), members:rec.members??{}, tasks:rec.tasks};
}
async function teamTaskDelete(taskId){
  const s=state.settings;
  const rec=await teamFetch();
  rec.tasks=(rec.tasks??[]).filter(t=>t.id!==taskId);
  const r=await fetch(`${JB_BASE}/b/${s.teamBinId}`,{
    method:"PUT",
    headers:{"Content-Type":"application/json","X-Master-Key":s.teamKey},
    body:JSON.stringify(rec)
  });
  if(!r.ok) throw new Error(r.status);
  teamCache={ts:Date.now(), members:rec.members??{}, tasks:rec.tasks};
}

/* ================= محرك التخطيط ================= */
function haversineKm(a,b){
  const R=6371, dLa=(b.lat-a.lat)*Math.PI/180, dLo=(b.lng-a.lng)*Math.PI/180;
  const s=Math.sin(dLa/2)**2+Math.cos(a.lat*Math.PI/180)*Math.cos(b.lat*Math.PI/180)*Math.sin(dLo/2)**2;
  return 2*R*Math.asin(Math.sqrt(s));
}
const travelMin=(km,v)=>Math.round(km/Math.max(v,10)*60*1.25);
const fmt=m=>String(Math.floor(m/60)%24).padStart(2,"0")+":"+String(Math.round(m%60)).padStart(2,"0");
const centroid=l=>l.length?{lat:l.reduce((s,p)=>s+p.lat,0)/l.length,lng:l.reduce((s,p)=>s+p.lng,0)/l.length}:null;

function generatePlan(){
  const s = state.settings;
  const sel = state.weekSelection ? new Set(state.weekSelection) : null;
  const active = state.branches.filter(b=>b.active && (!sel || sel.has(b.id)));
  let home;
  if(s.nonMeetingStart==="meeting" && s.meetingVenue) home = s.meetingVenue;
  else if(s.nonMeetingStart==="custom" && s.customStart) home = s.customStart;
  else home = s.homeLocation ?? centroid(active) ?? {lat:24.7136,lng:46.6753};
  const meeting = s.meetingVenue ?? home;
  const budget = (s.workEndHour - s.workStartHour)*60;

  // بذور موزعة جغرافيًا لخمسة أيام
  const seeds=[active[0]??home];
  while(seeds.length<5 && active.length){
    let far=active[0],fd=-1;
    for(const b of active){ const d=Math.min(...seeds.map(x=>haversineKm(x,b))); if(d>fd){fd=d;far=b;} }
    seeds.push(far);
  }
  while(seeds.length<5) seeds.push(home);
  const centers = seeds.map(x=>({lat:x.lat,lng:x.lng}));
  const clusters=[[],[],[],[],[]];
  const load = (c,meet)=> c.reduce((t,b)=>t+VISIT_MIN[b.size],0) + c.length*travelMin(8,s.avgSpeedKmh) + (meet?MEETING_MIN:0);

  const maxPer = s.maxBranchesPerDay>0 ? s.maxBranchesPerDay : Infinity;
  const rem=[...active].sort((a,b)=>haversineKm(home,a)-haversineKm(home,b));
  for(const br of rem){
    let best=-1,score=Infinity;
    for(let d=0;d<5;d++){
      if(clusters[d].length>=maxPer) continue;
      if(load(clusters[d],d===0)+VISIT_MIN[br.size] > budget*0.95) continue;
      const sc = haversineKm(centers[d],br) + load(clusters[d],d===0)/20;
      if(sc<score){score=sc;best=d;}
    }
    if(best<0) continue; // كل الأيام ممتلئة — الفرع لا يُجدول هذا الأسبوع
    clusters[best].push(br);
    const c=centroid(clusters[best]); if(c) centers[best]=c;
  }

  const days = clusters.map((cluster,dayIndex)=>{
    const meet = dayIndex===0;
    const start = meet ? meeting : home;
    const pool=[...cluster], route=[]; let cur=start;
    while(pool.length){
      let bi=0,bd=Infinity;
      pool.forEach((b,i)=>{const d=haversineKm(cur,b); if(d<bd){bd=d;bi=i;}});
      const n=pool.splice(bi,1)[0]; route.push(n); cur=n;
    }
    let clock=s.workStartHour*60+(meet?MEETING_MIN:0), cursor=start, totalKm=0;
    const stops=[];
    for(const br of route){
      if(stops.length>=maxPer) break;
      const km=haversineKm(cursor,br), t=travelMin(km,s.avgSpeedKmh), v=VISIT_MIN[br.size];
      if(clock+t+v > s.workEndHour*60) break;
      clock+=t; const arr=clock; clock+=v; totalKm+=km;
      stops.push({branchId:br.id,nameAr:br.nameAr,nameEn:br.nameEn,lat:br.lat,lng:br.lng,size:br.size,
        arrivalTime:fmt(arr),departureTime:fmt(clock),travelMinutes:t,distanceKm:Math.round(km*10)/10});
      cursor=br;
    }
    return {dayIndex,dayNameAr:DAYS_AR[dayIndex],isMeetingDay:meet,stops,totalDriveKm:Math.round(totalKm*10)/10};
  });

  return {
    id:"plan-"+Date.now().toString(36),
    createdAt:Date.now(),
    weekLabel:(isEn()?"Week of ":"أسبوع ")+new Date().toLocaleDateString(isEn()?"en-GB":"ar-SA",{day:"numeric",month:"long",year:"numeric"}),
    days
  };
}

function dayStartPoint(dayIndex){
  const s=state.settings;
  const act=state.branches.filter(b=>b.active);
  let home;
  if(s.nonMeetingStart==="meeting" && s.meetingVenue) home=s.meetingVenue;
  else if(s.nonMeetingStart==="custom" && s.customStart) home=s.customStart;
  else home=s.homeLocation ?? centroid(act) ?? {lat:24.7136,lng:46.6753};
  return dayIndex===0 ? (s.meetingVenue ?? home) : home;
}
function recalcPlanTimes(plan){
  const s=state.settings;
  for(const day of plan.days){
    let cursor=dayStartPoint(day.dayIndex);
    let clock=s.workStartHour*60+(day.isMeetingDay?MEETING_MIN:0), totalKm=0;
    for(const st of day.stops){
      const km=haversineKm(cursor,st), t=travelMin(km,s.avgSpeedKmh);
      clock+=t; st.travelMinutes=t; st.distanceKm=Math.round(km*10)/10;
      st.arrivalTime=fmt(clock);
      clock+=VISIT_MIN[st.size];
      st.departureTime=fmt(clock);
      totalKm+=km; cursor=st;
    }
    day.totalDriveKm=Math.round(totalKm*10)/10;
  }
}

/* ================= سجل الزيارات ================= */
function findVisit(planId,branchId){ return state.visits.find(v=>v.planId===planId&&v.branchId===branchId)??null; }
function visitElapsedMin(v){ return Math.floor(((v.endedAt??Date.now())-v.startedAt)/60000); }

async function checkIn(planId,branchId){
  const plan=state.plans.find(p=>p.id===planId); if(!plan) return;
  let stop=null,dayIndex=0;
  for(const d of plan.days){ const f=d.stops.find(x=>x.branchId===branchId); if(f){stop=f;dayIndex=d.dayIndex;break;} }
  if(!stop || findVisit(planId,branchId)) return;
  state.visits.push({
    id:"v-"+Date.now().toString(36), planId, branchId, nameAr:stop.nameAr, dayIndex,
    size:stop.size, plannedMin:VISIT_MIN[stop.size],
    startedAt:Date.now(), endedAt:null, status:"open",
    notes:"", major:null, minor:null, critical:null, ph:null, tds:null, dataComplete:false
  });
  await persist();
}
window.checkInMap=async(branchId)=>{
  const p=activePlan(); if(!p){ toast(tx("ولّد خطة أولاً من تبويب الخطة","Generate a plan first from the Plan tab"),"err"); return; }
  await checkIn(p.id,branchId);
  leafletMap?.closePopup();
  toast(tx("سُجّل الوصول — بدأ عدّاد الزيارة","Checked in — visit timer started"),"ok");
};

/* الإغلاق التلقائي عند تجاوز مدة الزيارة */
function autoCloseVisits(){
  let changed=false;
  for(const v of state.visits){
    if(v.status==="open" && Date.now()-v.startedAt >= v.plannedMin*60000){
      v.status="auto"; v.endedAt=v.startedAt+v.plannedMin*60000; changed=true;
    }
  }
  if(changed) persist();
  return changed;
}

/* ================= التنبيهات ================= */
let timers=[];
function scheduleReminders(){
  timers.forEach(clearTimeout); timers=[];
  const s=state.settings, plan=activePlan();
  if(!plan || !s.notificationsEnabled) return;
  const now=new Date(), sunday=new Date(now); sunday.setDate(now.getDate()-now.getDay());
  for(const day of plan.days) for(const stop of day.stops){
    const [h,m]=stop.arrivalTime.split(":").map(Number);
    const fire=new Date(sunday); fire.setDate(sunday.getDate()+day.dayIndex);
    fire.setHours(h, m - s.leadTimeMinutes - stop.travelMinutes, 0, 0);
    const delay=fire.getTime()-Date.now();
    if(delay>0 && delay<2147000000) timers.push(setTimeout(()=>fireReminder(stop), delay));
  }
}
function fireReminder(stop){
  showRemind(stop);
  if("Notification" in window && Notification.permission==="granted"){
    new Notification(tx("⏰ حان وقت الانطلاق!","⏰ Time to go!"), {body:tx(`توجّه الآن إلى ${stopName(stop)} — الوصول المجدول ${stop.arrivalTime}`,`Head to ${stopName(stop)} now — scheduled arrival ${stop.arrivalTime}`)});
  }
}
function showRemind(stop){
  const t=document.getElementById("remind");
  document.getElementById("remind-title").textContent=tx(`حان وقت الانطلاق إلى ${stopName(stop)}!`,`Time to head to ${stopName(stop)}!`);
  document.getElementById("remind-time").textContent=`Scheduled arrival: ${stop.arrivalTime}`;
  document.getElementById("remind-nav").onclick=()=>{openNav(stop.lat,stop.lng); hideRemind();};
  t.classList.add("show");
}
function hideRemind(){document.getElementById("remind").classList.remove("show");}
const openNav=(lat,lng)=>window.open(`https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}&travelmode=driving`,"_blank");

/* ================= المشاركة ================= */
async function shareLocation(name,lat,lng,btn){
  const url=`https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}&travelmode=driving`;
  const text=`📍 ${name} — هاف مليون ½M\nرابط الملاحة المباشر:\n${url}`;
  let msg="نُسخ الرابط ✓";
  if(navigator.share){
    try{ await navigator.share({title:`📍 ${name}`, text, url}); msg="تمت المشاركة ✓"; }
    catch(e){ if(e.name==="AbortError") return; try{await navigator.clipboard.writeText(url);}catch(_){}}
  } else {
    try{ await navigator.clipboard.writeText(url); }catch(e){ prompt("انسخ رابط الموقع:",url); return; }
  }
  if(btn){ const old=btn.textContent; btn.textContent=msg; setTimeout(()=>btn.textContent=old,2000); }
  else toast(msg,"ok");
}
window.shareLoc=(id,ev)=>{ ev?.preventDefault(); const b=state.branches.find(x=>x.id===id); if(b) shareLocation(b.nameAr,b.lat,b.lng,null); };

const b64enc=o=>btoa(unescape(encodeURIComponent(JSON.stringify(o))));
const b64dec=t=>JSON.parse(decodeURIComponent(escape(atob(t))));
async function sharePlan(plan){
  await stSet("plan:"+plan.id, JSON.stringify(plan), true);
  const url=`${location.origin}${location.pathname}?planId=${plan.id}#p=${b64enc(plan)}`;
  const text=`جدول زيارات هاف مليون ½M — ${plan.weekLabel}\nرمز الخطة: ${plan.id}\n${url}`;
  if(navigator.share){
    try{ await navigator.share({title:"خطة زيارات هاف مليون ½M",text,url}); return "تمت المشاركة ✓"; }catch(e){}
  }
  try{ await navigator.clipboard.writeText(text); return "نُسخ الرابط والرمز ✓"; }
  catch(e){ prompt("انسخ رمز الخطة:", plan.id); return "رمز الخطة: "+plan.id; }
}
async function loadSharedPlan(id){
  const raw=await stGet("plan:"+id.trim(), true);
  if(!raw) return null;
  try{ return JSON.parse(raw); }catch(e){ return null; }
}

/* ================= التصدير ================= */
function exportBranchesExcel(){
  const rows=state.branches.map(b=>({
    "الاسم (عربي)":b.nameAr, "Name (EN)":b.nameEn, "المنطقة":b.region??"",
    "الحجم":b.size==="large"?"كبير":"صغير", "مدة الزيارة (دقيقة)":VISIT_MIN[b.size],
    "Latitude":b.lat, "Longitude":b.lng,
    "الحالة":b.active?"نشط":"معطّل",
    "رابط الملاحة":`https://www.google.com/maps/dir/?api=1&destination=${b.lat},${b.lng}`
  }));
  const ws=XLSX.utils.json_to_sheet(rows);
  ws["!cols"]=[{wch:28},{wch:22},{wch:14},{wch:8},{wch:16},{wch:12},{wch:12},{wch:8},{wch:50}];
  ws["!rtl"]=true;
  const wb=XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb,ws,"فروع هاف مليون");
  XLSX.writeFile(wb,`فروع_هاف_مليون_${new Date().toISOString().slice(0,10)}.xlsx`);
}

/* جدول HTML ملوّن للخطة (للطباعة PDF والصورة) — بألوان ثابتة مناسبة للورق */
const EXPORT_DAY_COLORS=["#2a78d6","#eb6834","#1baf7a","#c98500","#d55181"];
function buildPlanTableHTML(plan){
  let rows="";
  for(const day of plan.days){
    const color=EXPORT_DAY_COLORS[day.dayIndex];
    const span=Math.max(day.stops.length,1);
    if(!day.stops.length){
      rows+=`<tr><td style="background:${color};color:#fff;font-weight:700;padding:10px">${day.dayNameAr}${day.isMeetingDay?" 📋":""}</td><td colspan="5" style="padding:10px;color:#999">لا توجد زيارات</td></tr>`;
    } else {
      day.stops.forEach((st,i)=>{
        rows+=`<tr>`;
        if(i===0) rows+=`<td rowspan="${span}" style="background:${color};color:#fff;font-weight:700;padding:10px;vertical-align:middle;text-align:center;min-width:90px">${day.dayNameAr}${day.isMeetingDay?'<br><span style="font-size:10px">📋 اجتماع</span>':''}<br><span style="font-size:10px;opacity:.85">${day.totalDriveKm} كم</span></td>`;
        rows+=`<td style="padding:8px 10px;font-weight:600">${i+1}. ${esc(st.nameAr)}</td>
          <td style="padding:8px;text-align:center;font-family:monospace" dir="ltr">${st.arrivalTime}</td>
          <td style="padding:8px;text-align:center;font-family:monospace" dir="ltr">${st.departureTime}</td>
          <td style="padding:8px;text-align:center">${st.size==="large"?"كبير 120د":"صغير 90د"}</td>
          <td style="padding:8px;text-align:center;font-family:monospace" dir="ltr">${st.distanceKm} كم</td></tr>`;
      });
    }
  }
  const totalKm=plan.days.reduce((t,d)=>t+d.totalDriveKm,0).toFixed(1);
  const totalStops=plan.days.reduce((t,d)=>t+d.stops.length,0);
  return `<div id="export-canvas" style="width:800px;background:#F5EFE4;padding:28px;font-family:'IBM Plex Sans Arabic',sans-serif;direction:rtl">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:18px">
      <div><div style="font-family:'Space Grotesk';font-size:34px;font-weight:700;color:#1C1917">½M</div>
      <div style="color:#5B3A1E;font-weight:700;font-size:13px">هاف مليون — جدول الزيارات الأسبوعي</div></div>
      <div style="text-align:left"><div style="font-weight:700;font-size:15px">${esc(plan.weekLabel)}</div>
      <div style="color:#5B3A1E99;font-size:12px">${totalStops} زيارة · ${totalKm} كم إجمالي القيادة</div></div>
    </div>
    <table style="width:100%;border-collapse:collapse;background:#fff;border-radius:10px;overflow:hidden;font-size:13px;box-shadow:0 2px 10px #5b3a1e18">
      <thead><tr style="background:#C9AE85;color:#1C1917">
        <th style="padding:10px">اليوم</th><th style="padding:10px;text-align:right">الفرع</th>
        <th style="padding:10px">الوصول</th><th style="padding:10px">المغادرة</th>
        <th style="padding:10px">الحجم</th><th style="padding:10px">المسافة</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
    <div style="margin-top:12px;color:#5B3A1E99;font-size:11px;text-align:center">أُنشئ بواسطة تطبيق هاف مليون لتخطيط الزيارات · ${new Date().toLocaleString("en-GB")}</div>
  </div>`;
}

function offscreen(html){
  const wrap=document.createElement("div");
  wrap.style.cssText="position:fixed;left:-9999px;top:0;z-index:-1";
  wrap.innerHTML=html;
  document.body.appendChild(wrap);
  return wrap;
}
async function renderToCanvas(html){
  const wrap=offscreen(html);
  const node=wrap.firstElementChild;
  const canvas=await html2canvas(node,{scale:2,backgroundColor:"#F5EFE4",useCORS:true,logging:false});
  wrap.remove();
  return canvas;
}
async function exportPlanImage(plan){
  const canvas=await renderToCanvas(buildPlanTableHTML(plan));
  const url=canvas.toDataURL("image/png");
  const a=document.createElement("a"); a.href=url; a.download=`خطة_${plan.weekLabel}.png`; a.click();
}
async function exportPlanPDF(plan){
  const canvas=await renderToCanvas(buildPlanTableHTML(plan));
  const {jsPDF}=window.jspdf;
  const pdf=new jsPDF({orientation:"portrait",unit:"pt",format:"a4"});
  const pw=pdf.internal.pageSize.getWidth(), margin=24;
  const iw=pw-margin*2, ih=canvas.height*iw/canvas.width;
  pdf.addImage(canvas.toDataURL("image/png"),"PNG",margin,margin,iw,ih);
  pdf.save(`خطة_${plan.weekLabel}.pdf`);
}

async function exportDashPDF(list, stats){
  const html=buildDashReportHTML(list, stats);
  const canvas=await renderToCanvas(html);
  const {jsPDF}=window.jspdf;
  const pdf=new jsPDF({orientation:"portrait",unit:"pt",format:"a4"});
  const pw=pdf.internal.pageSize.getWidth(), ph=pdf.internal.pageSize.getHeight(), margin=24;
  const iw=pw-margin*2, ih=canvas.height*iw/canvas.width;
  if(ih<=ph-margin*2){
    pdf.addImage(canvas.toDataURL("image/png"),"PNG",margin,margin,iw,ih);
  } else {
    let remaining=canvas.height, y=0, page=0;
    const sliceH=Math.floor((ph-margin*2)*canvas.width/iw);
    while(remaining>0){
      const c=document.createElement("canvas");
      c.width=canvas.width; c.height=Math.min(sliceH,remaining);
      c.getContext("2d").drawImage(canvas,0,y,canvas.width,c.height,0,0,canvas.width,c.height);
      if(page>0) pdf.addPage();
      pdf.addImage(c.toDataURL("image/png"),"PNG",margin,margin,iw,c.height*iw/canvas.width);
      remaining-=c.height; y+=c.height; page++;
    }
  }
  pdf.save(`تقرير_الزيارات_${new Date().toISOString().slice(0,10)}.pdf`);
}
function exportDashExcel(list){
  const hasOwner=list.some(v=>v.owner);
  const rows=list.map(v=>({
    ...(hasOwner?{"العضو":v.owner??""}:{}),
    "الفرع":visitName(v), "اليوم":dayName(v.dayIndex),
    "التاريخ":new Date(v.startedAt).toLocaleDateString("en-GB"),
    "وقت البدء":new Date(v.startedAt).toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"}),
    "المدة (دقيقة)":visitElapsedMin(v),
    "Critical":v.critical??"", "Major":v.major??"", "Minor":v.minor??"",
    "PH":v.ph??"", "TDS":v.tds??"",
    "الحالة":v.status==="open"?"جارية":v.dataComplete?"مكتملة":"ناقصة",
    "المهام":(v.tasks??[]).map(t=>`${t.title}: ${t.grade}${t.note?` (${t.note})`:""}`).join(" | "),
    "ملاحظات":v.notes??""
  }));
  const ws=XLSX.utils.json_to_sheet(rows); ws["!rtl"]=true;
  ws["!cols"]=[{wch:24},{wch:10},{wch:12},{wch:10},{wch:12},{wch:9},{wch:9},{wch:9},{wch:7},{wch:8},{wch:10},{wch:30}];
  const wb=XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb,ws,"سجل الزيارات");
  XLSX.writeFile(wb,`تقرير_الزيارات_${new Date().toISOString().slice(0,10)}.xlsx`);
}

function buildDashReportHTML(list, s){
  const byDay=[0,0,0,0,0];
  for(const v of list){ if(v.dayIndex>=0&&v.dayIndex<5) byDay[v.dayIndex]++; }
  const maxDay=Math.max(1,...byDay);
  let bars="";
  for(let d=0;d<5;d++){
    const h=Math.round(byDay[d]/maxDay*90);
    bars+=`<div style="flex:1;text-align:center">
      <div style="height:100px;display:flex;align-items:flex-end;justify-content:center">
        <div style="width:60%;height:${h}px;background:${EXPORT_DAY_COLORS[d]};border-radius:6px 6px 0 0;min-height:3px"></div>
      </div>
      <div style="font-size:11px;font-weight:700;margin-top:4px">${DAYS_AR[d]}</div>
      <div style="font-size:10px;color:#5B3A1E99">${byDay[d]} زيارة</div></div>`;
  }
  const card=(v,l,c)=>`<div style="flex:1;background:#fff;border-radius:10px;padding:12px;text-align:center;box-shadow:0 1px 4px #5b3a1e14">
    <div style="font-family:monospace;font-size:22px;font-weight:700;color:${c||'#1C1917'}">${v}</div>
    <div style="font-size:10px;font-weight:700;color:#5B3A1E99">${l}</div></div>`;
  let tableRows="";
  for(const v of list){
    const stt=v.status==="open"?"جارية":v.dataComplete?"مكتملة":"ناقصة";
    tableRows+=`<tr>
      <td style="padding:6px 8px;text-align:right">${esc(v.nameAr)}</td>
      <td style="padding:6px;text-align:center;font-family:monospace" dir="ltr">${new Date(v.startedAt).toLocaleDateString("en-GB")}</td>
      <td style="padding:6px;text-align:center;font-family:monospace">${visitElapsedMin(v)}د</td>
      <td style="padding:6px;text-align:center;color:#b91c1c;font-weight:700">${v.critical??"—"}</td>
      <td style="padding:6px;text-align:center;color:#C77B2E;font-weight:700">${v.major??"—"}</td>
      <td style="padding:6px;text-align:center">${v.minor??"—"}</td>
      <td style="padding:6px;text-align:center;font-family:monospace">${v.ph??"—"}</td>
      <td style="padding:6px;text-align:center;font-family:monospace">${v.tds??"—"}</td>
      <td style="padding:6px;text-align:center;font-size:11px">${stt}</td></tr>`;
  }
  return `<div style="width:800px;background:#F5EFE4;padding:28px;font-family:'IBM Plex Sans Arabic',sans-serif;direction:rtl">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px">
      <div><div style="font-family:'Space Grotesk';font-size:32px;font-weight:700">½M</div>
      <div style="color:#5B3A1E;font-weight:700;font-size:13px">تقرير زيارات هاف مليون — ${s.periodLbl}</div></div>
      <div style="color:#5B3A1E99;font-size:12px">${new Date().toLocaleString("en-GB")}</div>
    </div>
    <div style="display:flex;gap:8px;margin-bottom:8px">
      ${card(s.count,"زيارة")}${card(s.complete,"مكتملة","#2E8C76")}${card(s.critical,"Critical","#b91c1c")}${card(s.major,"Major","#C77B2E")}${card(s.minor,"Minor")}
    </div>
    <div style="display:flex;gap:8px;margin-bottom:16px">
      ${card(s.avgPh,"متوسط PH")}${card(s.avgTds,"متوسط TDS")}${card(s.hours,"ساعات الزيارات")}
    </div>
    <div style="background:#fff;border-radius:10px;padding:14px;margin-bottom:16px;box-shadow:0 1px 4px #5b3a1e14">
      <div style="font-weight:700;font-size:13px;margin-bottom:8px">توزيع الزيارات على أيام الأسبوع</div>
      <div style="display:flex;gap:6px;align-items:flex-end">${bars}</div>
    </div>
    <table style="width:100%;border-collapse:collapse;background:#fff;border-radius:10px;overflow:hidden;font-size:12px;box-shadow:0 1px 4px #5b3a1e14">
      <thead><tr style="background:#C9AE85">
        <th style="padding:8px;text-align:right">الفرع</th><th style="padding:8px">التاريخ</th><th style="padding:8px">المدة</th>
        <th style="padding:8px;color:#b91c1c">C</th><th style="padding:8px;color:#C77B2E">M</th><th style="padding:8px">m</th>
        <th style="padding:8px">PH</th><th style="padding:8px">TDS</th><th style="padding:8px">الحالة</th></tr></thead>
      <tbody>${tableRows||'<tr><td colspan="9" style="padding:16px;text-align:center;color:#999">لا توجد زيارات</td></tr>'}</tbody>
    </table>
  </div>`;
}

/* ================= استيراد Excel ================= */
async function parseExcel(file){
  const buf=await file.arrayBuffer();
  const wb=XLSX.read(buf,{type:"array"});
  const out=[]; let c=Date.now();
  for(const sn of wb.SheetNames){
    const rows=XLSX.utils.sheet_to_json(wb.Sheets[sn]);
    for(const row of rows){
      const get=(...keys)=>{ for(const k of keys){ const f=Object.keys(row).find(rk=>rk.trim().toLowerCase()===k.toLowerCase()); if(f&&row[f]!==""&&row[f]!=null) return row[f]; } };
      const name=String(get("name","الاسم","branch","الفرع")??"").trim(); if(!name) continue;
      let lat=Number(get("lat","latitude","خط العرض")), lng=Number(get("lng","lon","longitude","خط الطول"));
      const wkt=String(get("wkt","geometry","coordinates")??"");
      const m=wkt.match(/(-?\d+\.?\d*)[ ,]+(-?\d+\.?\d*)/);
      if((!isFinite(lat)||!isFinite(lng))&&m){lng=Number(m[1]);lat=Number(m[2]);}
      if(!isFinite(lat)||!isFinite(lng)) continue;
      const sz=String(get("size","الحجم")??"small").toLowerCase();
      const parts=name.split("|").map(p=>p.trim());
      out.push({id:"br-x-"+(c++).toString(36),nameAr:parts[0],nameEn:parts[1]??parts[0],
        region:String(get("region","المنطقة")??sn),lat,lng,
        size:(sz.includes("large")||sz.includes("كبير"))?"large":"small",active:true});
    }
  }
  return out;
}

/* ================= مساعدات عامة ================= */
const $=s=>document.querySelector(s);
const activePlan=()=>state.plans.find(p=>p.id===state.activePlanId)??null;
const esc=s=>String(s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
