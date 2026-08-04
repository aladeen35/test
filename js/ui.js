/* ============================================================
   هاف مليون ½M — واجهة المستخدم
   عرض التبويبات الستة + النوافذ + التشغيل
   ============================================================ */

const main=$("#main");
let leafletMap=null, mapDayFilter="all", editMode=false;

/* ============ مكتبة أيقونات SVG (بديل الإيموجي في عناصر التفاعل) ============ */
const ICONS={
  sparkles:'<path d="M12 3l1.7 4.6L18 9.2l-4.3 1.7L12 15.5l-1.7-4.6L6 9.2l4.3-1.6L12 3z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8L19 15z"/>',
  pencil:'<path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 1 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>',
  share:'<path d="M7 17L17 7"/><path d="M8 7h9v9"/>',
  file:'<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M16 13H8M16 17H8"/>',
  image:'<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/>',
  nav:'<path d="M3 11l19-9-9 19-2-8-8-2z"/>',
  check:'<path d="M20 6L9 17l-5-5"/>',
  x:'<path d="M18 6L6 18M6 6l12 12"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  download:'<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="M7 10l5 5 5-5"/><path d="M12 15V3"/>',
  refresh:'<path d="M23 4v6h-6"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>',
  send:'<path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 7-7z"/>',
  sliders:'<path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"/>',
  trash:'<path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
  users:'<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  calendar:'<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M8 3v4M16 3v4M3 10h18"/>',
  alert:'<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  flask:'<path d="M10 2v7.5a2 2 0 0 1-.2.9L4.7 20.5a1 1 0 0 0 .9 1.5h12.8a1 1 0 0 0 .9-1.5L14.2 10.4a2 2 0 0 1-.2-.9V2"/><path d="M8.5 2h7"/><path d="M7 16h10"/>',
  clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/>',
  trend:'<path d="M23 6l-9.5 9.5-5-5L1 18"/><path d="M17 6h6v6"/>',
  droplet:'<path d="M12 2.7l5.66 5.66a8 8 0 1 1-11.31 0z"/>',
  leaf:'<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.5 19 2c1 2 2 4.2 2 8 0 5.5-4.8 10-10 10z"/><path d="M2 21c0-3 1.9-5.4 5.1-6C9.5 14.5 12 13 13 12"/>',
  msg:'<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
  flag:'<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><path d="M4 22v-7"/>',
};
function ic(name, size=16){
  return `<svg class="ic" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name]||""}</svg>`;
}

const TAB_META={
  plan:     ["الخطة الأسبوعية","توليد وتتبع مسار زياراتك"],
  branches: ["إدارة الفروع","78+ فرعًا عبر المملكة"],
  map:      ["الخريطة","مسارات الأيام والفروع"],
  ai:       ["المساعد الذكي ✦","رؤى وتقارير بالذكاء الاصطناعي"],
  dash:     ["لوحة الزيارات","مؤشرات ونتائج الفحص"],
  settings: ["الإعدادات","المواقع والتنبيهات والمزامنة"],
};

function setTab(tab){
  state.tab=tab;
  document.querySelectorAll("nav.tabs button").forEach(b=>b.classList.toggle("active",b.dataset.tab===tab));
  $("#tab-name").textContent=TAB_META[tab][0];
  $("#tab-sub").textContent=TAB_META[tab][1];
  leafletMap?.remove(); leafletMap=null;
  render();
}
document.querySelectorAll("nav.tabs button").forEach(b=>b.onclick=()=>setTab(b.dataset.tab));

function render(){
  autoCloseVisits();
  if(state.tab==="plan") renderPlan();
  else if(state.tab==="branches") renderBranches();
  else if(state.tab==="map") renderMap();
  else if(state.tab==="ai") renderAI();
  else if(state.tab==="dash") renderDash();
  else renderSettings();
}

/* ==================== تبويب الخطة ==================== */
function visitBadge(v){
  if(!v) return "";
  if(v.status==="open") return `<span class="visit-chip timer-chip">⏱ ${visitElapsedMin(v)}د / ${v.plannedMin}د</span>`;
  if(v.status==="auto" && !v.dataComplete) return `<span class="visit-chip auto-chip">⏱ أُغلقت تلقائيًا — أكمل البيانات</span>`;
  if(!v.dataComplete) return `<span class="visit-chip auto-chip">بيانات ناقصة</span>`;
  return `<span class="visit-chip done-chip">✓ تمت · C:${v.critical} M:${v.major} m:${v.minor}${v.ph!=null?" · PH "+v.ph:""}${v.tds!=null?" · TDS "+v.tds:""}</span>`;
}

function ringSVG(pct, size=76, stroke=8, color="var(--ok)"){
  const r=(size-stroke)/2, c=2*Math.PI*r, off=c*(1-pct/100);
  return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
    <circle cx="${size/2}" cy="${size/2}" r="${r}" fill="none" stroke="var(--bg-inset)" stroke-width="${stroke}"/>
    <circle cx="${size/2}" cy="${size/2}" r="${r}" fill="none" stroke="${color}" stroke-width="${stroke}"
      stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${off}" style="transition:stroke-dashoffset .6s ease"/>
  </svg>`;
}

function renderPlan(){
  const plan=activePlan(), s=state.settings;
  let html=`<div class="page">
    <button class="btn-primary" id="gen-btn">${ic("sparkles",17)} توليد الخطة الأسبوعية</button>`;
  if(!s.homeLocation) html+=`<div class="hint">💡 حدّد موقع الانطلاق ومقر اجتماع الأحد من تبويب الإعدادات لنتائج أدق</div>`;

  if(state.plans.length>1){
    html+=`<h2 class="sec">الخطط السابقة (${state.plans.length})</h2>`;
    for(const p of state.plans){
      html+=`<div class="card" style="padding:.7rem 1rem;margin-bottom:.5rem;display:flex;align-items:center;gap:.5rem;${p.id===state.activePlanId?'border-color:var(--accent)':''}">
        <button data-sel="${p.id}" style="flex:1;text-align:start;min-height:auto"><b style="font-size:.85rem">${esc(p.weekLabel)}</b>
        <div class="mono faint" dir="ltr" style="font-size:.65rem">${new Date(p.createdAt).toLocaleString("en-GB")}</div></button>
        <button data-share="${p.id}" style="color:var(--ok);font-weight:700;font-size:.75rem;min-height:auto;padding:.4rem">مشاركة</button>
        <button data-delplan="${p.id}" class="del-btn">حذف</button>
      </div>`;
    }
  }

  if(plan){
    const total=plan.days.reduce((t,d)=>t+d.stops.length,0);
    const done=plan.days.reduce((t,d)=>t+d.stops.filter(st=>{const v=findVisit(plan.id,st.branchId);return v&&v.status!=="open";}).length,0);
    const km=plan.days.reduce((t,d)=>t+d.totalDriveKm,0).toFixed(1);
    const pct=total?Math.round(done/total*100):0;
    html+=`<div class="card progress-hero">
      <div class="ring">${ringSVG(pct)}<div class="val mono" dir="ltr">${pct}%</div></div>
      <div class="meta">
        <b>${esc(plan.weekLabel)}</b>
        <span>${done} من ${total} زيارة مكتملة · <span class="mono" dir="ltr">${km} km</span> إجمالي القيادة</span>
      </div>
    </div>`;

    html+=`<div style="display:flex;align-items:center;justify-content:flex-end;margin:0 0 .8rem;gap:.4rem;flex-wrap:wrap">
      <button class="btn-dark" id="edit-btn" style="${editMode?'background:var(--accent);color:var(--accent-ink)':''}">${editMode?`${ic("check",13)} إنهاء التعديل`:`${ic("pencil",13)} تعديل`}</button>
      <button class="btn-dark" id="share-btn">${ic("share",13)} مشاركة</button>
      <button class="btn-ghost" id="pdf-btn">${ic("file",13)} PDF</button>
      <button class="btn-ghost" id="img-btn">${ic("image",13)} صورة</button>
    </div>`;
    if(editMode) html+=`<div class="edit-banner">✏️ <b>وضع التعديل:</b> اسحب ⠿ لإعادة ترتيب الزيارات داخل اليوم أو أفلِتها فوق يوم آخر، أو استخدم قائمة "نقل إلى". التوقيتات تُعاد حسابها تلقائيًا.</div>`;

    for(const day of plan.days){
      html+=`<div class="card day-card">
        <div class="day-head" style="--day-accent:${dayColor(day.dayIndex)}">
          <b style="font-size:.9rem">${day.dayNameAr}${day.isMeetingDay?'<span class="meeting-badge">📋 اجتماع الفريق ثم الانطلاق من المقر</span>':''}</b>
          <span class="mono faint" dir="ltr" style="font-size:.72rem">${day.totalDriveKm} km</span>
        </div>
        <div class="stops-list" data-day="${day.dayIndex}" style="min-height:${editMode?"2.2rem":"0"}">`;
      if(!day.stops.length && !editMode) html+=`<p class="muted" style="padding:.9rem 1rem;font-size:.85rem">لا توجد زيارات مجدولة</p>`;
      day.stops.forEach((st,i)=>{
        const v=findVisit(plan.id,st.branchId);
        const doneCls=v&&v.dataComplete?" done-stop":"";
        html+=`<div class="stop${doneCls}" data-branch="${st.branchId}">
          ${editMode?`<button class="drag-handle" data-drag aria-label="سحب لإعادة الترتيب">⠿</button>`:`<span class="num mono">${v&&v.dataComplete?"✓":i+1}</span>`}
          <div style="flex:1;min-width:0">
            <b style="font-size:.85rem;display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(st.nameAr)}</b>
            <span class="mono faint" dir="ltr" style="font-size:.66rem">${st.arrivalTime} → ${st.departureTime} · ${st.size==="large"?"120":"90"}min · ${st.distanceKm}km</span>
            <div style="margin-top:.25rem">${visitBadge(v)}</div>
          </div>`;
        if(editMode){
          html+=`<select class="move-sel" data-move="${st.branchId}" aria-label="نقل إلى يوم">
            ${plan.days.map(d=>`<option value="${d.dayIndex}" ${d.dayIndex===day.dayIndex?"selected":""}>${d.dayNameAr}</option>`).join("")}
          </select>`;
        }else{
          html+=`<div style="display:flex;flex-direction:column;gap:.3rem;align-items:flex-end">`;
          if(!v) html+=`<button class="nav-btn" style="background:var(--ok);color:#fff" data-arrive="${st.branchId}">${ic("check",12)} أنا وصلت</button>`;
          else if(v.status==="open") html+=`<button class="nav-btn" style="background:var(--accent);color:var(--accent-ink)" data-endvisit="${v.id}">⏹ إنهاء الزيارة</button>`;
          else if(!v.dataComplete) html+=`<button class="nav-btn" style="background:var(--accent);color:var(--accent-ink)" data-endvisit="${v.id}">📝 أكمل البيانات</button>`;
          else html+=`<button class="nav-btn" style="background:var(--bg-inset);color:var(--text-2)" data-endvisit="${v.id}">✏️ تعديل البيانات</button>`;
          html+=`<button class="nav-btn" data-navlat="${st.lat}" data-navlng="${st.lng}">${ic("nav",12)} ملاحة</button>
            <button class="nav-btn" style="background:var(--bg-inset);color:var(--text-2)" data-sharename="${esc(st.nameAr)}" data-sharelat="${st.lat}" data-sharelng="${st.lng}">${ic("share",12)} الموقع</button>
          </div>`;
        }
        html+=`</div>`;
      });
      html+=`</div></div>`;
    }
  } else {
    html+=`<div class="empty"><div class="art">🗓️</div><b>لا توجد خطة بعد</b><p>اضغط "توليد الخطة الأسبوعية" وسيوزّع التطبيق فروعك على أيام الأسبوع بأقصر مسار قيادة</p></div>`;
  }
  html+=`</div>`;
  main.innerHTML=html;

  $("#gen-btn").onclick=openGenModal;
  const editBtn=$("#edit-btn");
  if(editBtn) editBtn.onclick=()=>{ editMode=!editMode; renderPlan(); };
  const shareBtn=$("#share-btn");
  if(shareBtn) shareBtn.onclick=async()=>{ shareBtn.textContent="…"; shareBtn.textContent=await sharePlan(activePlan()); setTimeout(()=>shareBtn.innerHTML=`${ic("share",13)} مشاركة`,2500); };
  const pdfBtn=$("#pdf-btn");
  if(pdfBtn) pdfBtn.onclick=async()=>{ pdfBtn.textContent="…"; try{await exportPlanPDF(activePlan());}catch(e){toast("تعذّر التصدير","err");} pdfBtn.innerHTML=`${ic("file",13)} PDF`; };
  const imgBtn=$("#img-btn");
  if(imgBtn) imgBtn.onclick=async()=>{ imgBtn.textContent="…"; try{await exportPlanImage(activePlan());}catch(e){toast("تعذّر التصدير","err");} imgBtn.innerHTML=`${ic("image",13)} صورة`; };
  main.querySelectorAll("[data-sel]").forEach(b=>b.onclick=async()=>{state.activePlanId=b.dataset.sel; editMode=false; await persist(); scheduleReminders(); renderPlan();});
  main.querySelectorAll("[data-share]").forEach(b=>b.onclick=async()=>{const p=state.plans.find(x=>x.id===b.dataset.share); b.textContent="…"; b.textContent=await sharePlan(p); setTimeout(()=>b.textContent="مشاركة",2500);});
  main.querySelectorAll("[data-delplan]").forEach(b=>b.onclick=async()=>{
    state.plans=state.plans.filter(x=>x.id!==b.dataset.delplan);
    if(state.activePlanId===b.dataset.delplan) state.activePlanId=state.plans[0]?.id??null;
    await persist(); renderPlan(); toast("حُذفت الخطة","ok");
  });
  main.querySelectorAll("[data-navlat]").forEach(b=>b.onclick=()=>openNav(b.dataset.navlat,b.dataset.navlng));
  main.querySelectorAll("[data-sharename]").forEach(b=>b.onclick=()=>shareLocation(b.dataset.sharename,b.dataset.sharelat,b.dataset.sharelng,b));
  main.querySelectorAll("[data-arrive]").forEach(b=>b.onclick=async()=>{ await checkIn(activePlan().id,b.dataset.arrive); toast("بدأ عدّاد الزيارة ⏱","ok"); renderPlan(); });
  main.querySelectorAll("[data-endvisit]").forEach(b=>b.onclick=()=>openVisitForm(b.dataset.endvisit));

  if(editMode){
    main.querySelectorAll("[data-move]").forEach(sel=>sel.onchange=()=>movestopToDay(sel.dataset.move, Number(sel.value)));
    setupDragAndDrop();
  }
}

async function movestopToDay(branchId,targetDay){
  const plan=activePlan(); if(!plan)return;
  let stop=null;
  for(const d of plan.days){
    const i=d.stops.findIndex(x=>x.branchId===branchId);
    if(i>=0){ stop=d.stops.splice(i,1)[0]; break; }
  }
  if(stop) plan.days.find(d=>d.dayIndex===targetDay).stops.push(stop);
  recalcPlanTimes(plan);
  await persist(); scheduleReminders(); renderPlan();
}

function setupDragAndDrop(){
  main.querySelectorAll("[data-drag]").forEach(handle=>{
    handle.addEventListener("pointerdown",e=>{
      e.preventDefault();
      const stopEl=handle.closest(".stop");
      stopEl.classList.add("dragging");
      handle.setPointerCapture(e.pointerId);
      const lists=[...main.querySelectorAll(".stops-list")];
      const onMove=ev=>{
        const x=ev.clientX,y=ev.clientY;
        const list=lists.find(l=>{const r=l.getBoundingClientRect();return x>=r.left&&x<=r.right&&y>=r.top-20&&y<=r.bottom+20;});
        if(!list) return;
        const sibs=[...list.querySelectorAll(".stop")].filter(el=>el!==stopEl);
        let before=null;
        for(const sb of sibs){ const r=sb.getBoundingClientRect(); if(y < r.top + r.height/2){ before=sb; break; } }
        if(before) list.insertBefore(stopEl,before); else list.appendChild(stopEl);
        const mr=main.getBoundingClientRect();
        if(y<mr.top+60) main.scrollBy(0,-12); else if(y>mr.bottom-60) main.scrollBy(0,12);
      };
      const onUp=async()=>{
        handle.removeEventListener("pointermove",onMove);
        handle.removeEventListener("pointerup",onUp);
        stopEl.classList.remove("dragging");
        const plan=activePlan();
        const lookup=new Map();
        plan.days.forEach(d=>d.stops.forEach(st=>lookup.set(st.branchId,st)));
        for(const list of main.querySelectorAll(".stops-list")){
          const dayIndex=Number(list.dataset.day);
          const day=plan.days.find(d=>d.dayIndex===dayIndex);
          day.stops=[...list.querySelectorAll(".stop")].map(el=>lookup.get(el.dataset.branch)).filter(Boolean);
        }
        recalcPlanTimes(plan);
        await persist(); scheduleReminders(); renderPlan();
      };
      handle.addEventListener("pointermove",onMove);
      handle.addEventListener("pointerup",onUp);
    });
  });
}

/* ---- نافذة خيارات توليد الخطة ---- */
let genQuery="";
function openGenModal(){
  genQuery="";
  if(!state.weekSelection) state.weekSelection = state.branches.filter(b=>b.active).map(b=>b.id);
  const ids=new Set(state.branches.map(b=>b.id));
  state.weekSelection = state.weekSelection.filter(id=>ids.has(id));
  $("#gen-modal").classList.add("open");
  renderGenBody();
}
function closeGenModal(){ $("#gen-modal").classList.remove("open"); }

function renderGenBody(){
  const s=state.settings, selSet=new Set(state.weekSelection);
  const q=genQuery.trim();
  const match=b=>!q||b.nameAr.includes(q)||b.nameEn.toLowerCase().includes(q.toLowerCase());
  const opt=(key,icon,label,sub)=>`
    <button class="start-opt ${s.nonMeetingStart===key?"sel":""}" data-start="${key}">
      <span style="font-size:1.2rem">${icon}</span>
      <span style="flex:1">${label}<small class="muted" style="display:block;font-weight:500;font-size:.72rem">${sub}</small></span>
      ${s.nonMeetingStart===key?'<span style="color:var(--accent);font-weight:700">✓</span>':""}
    </button>`;

  let html=`
    <h2 class="sec" style="margin-top:.4rem">🚗 نقطة الانطلاق في الأيام العادية (غير يوم الاجتماع)</h2>
    ${opt("home","🏠","المنزل", s.homeLocation?`${s.homeLocation.lat.toFixed(4)}, ${s.homeLocation.lng.toFixed(4)}`:"حدّده من الإعدادات أو سيُستخدم مركز الفروع")}
    ${opt("meeting","📋",esc(s.meetingVenueName||"مقر الاجتماع"), s.meetingVenue?`${s.meetingVenue.lat.toFixed(4)}, ${s.meetingVenue.lng.toFixed(4)}`:"حدّده من الإعدادات")}
    ${opt("custom","📍","موقع مخصص","أدخل الإحداثيات يدويًا")}`;

  if(s.nonMeetingStart==="custom"){
    html+=`<div style="display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin:.2rem 0 .6rem">
      <input dir="ltr" type="number" step="0.000001" class="mono" id="cs-lat" placeholder="Latitude" value="${s.customStart?.lat??""}" style="font-size:.85rem">
      <input dir="ltr" type="number" step="0.000001" class="mono" id="cs-lng" placeholder="Longitude" value="${s.customStart?.lng??""}" style="font-size:.85rem">
    </div>`;
  }

  html+=`
    <h2 class="sec">⚡ متوسط سرعة القيادة</h2>
    <div style="display:flex;align-items:center;gap:.8rem;background:var(--bg-elev);border:1px solid var(--line);border-radius:.9rem;padding:.6rem .9rem">
      <input dir="ltr" type="range" min="20" max="120" step="5" id="gen-speed" value="${s.avgSpeedKmh}" style="flex:1;padding:0;border:0;background:transparent;accent-color:var(--accent)">
      <span class="mono" dir="ltr" style="font-weight:700;min-width:5.5rem;text-align:center" id="gen-speed-val">${s.avgSpeedKmh} km/h</span>
    </div>

    <h2 class="sec">☕ الفروع الموكلة إليّ هذا الأسبوع <span class="mono" dir="ltr" style="color:var(--ok)">(${state.weekSelection.length})</span></h2>
    <div style="display:flex;gap:.5rem;margin-bottom:.6rem">
      <input id="gen-search" placeholder="ابحث عن فرع…" value="${esc(genQuery)}" style="flex:1;font-size:.85rem;padding:.55rem .9rem">
      <button class="mini-chip" id="gen-all">تحديد الكل</button>
      <button class="mini-chip" id="gen-none">إلغاء الكل</button>
    </div>
    <div class="card" style="overflow:hidden">`;

  const regions=new Map();
  for(const b of state.branches){ const k=b.region??"أخرى"; if(!regions.has(k))regions.set(k,[]); regions.get(k).push(b); }
  for(const [region,list] of regions){
    const vis=list.filter(match); if(!vis.length) continue;
    html+=`<div style="background:var(--bg-soft);padding:.45rem .9rem;font-size:.72rem;font-weight:700;color:var(--text-2)">${esc(region)}</div>`;
    for(const b of vis){
      const on=selSet.has(b.id);
      html+=`<div class="wk-branch ${on?"sel":""} ${b.active?"":"dim"}">
        <button class="cb" data-wk="${b.id}" aria-label="تحديد">${on?"✓":""}</button>
        <span class="nm">${esc(b.nameAr)}${b.active?"":' <small style="color:var(--danger)">· معطّل</small>'}</span>
        <button class="mini-chip ${b.size==="large"?"on":""}" data-wksize="${b.id}">${b.size==="large"?"كبير 120د":"صغير 90د"}</button>
      </div>`;
    }
  }
  html+=`</div>`;
  $("#gen-body").innerHTML=html;
  $("#gen-confirm").textContent=`توليد الخطة (${state.weekSelection.length} فرعًا)`;
  $("#gen-confirm").disabled = state.weekSelection.length===0;
  bindGenEvents();
}

function bindGenEvents(){
  const body=$("#gen-body"), s=state.settings;
  body.querySelectorAll("[data-start]").forEach(b=>b.onclick=async()=>{
    s.nonMeetingStart=b.dataset.start; await persist(); renderGenBody();
  });
  const csLat=body.querySelector("#cs-lat"), csLng=body.querySelector("#cs-lng");
  if(csLat){
    const saveCs=async()=>{
      const la=Number(csLat.value), lo=Number(csLng.value);
      s.customStart=(isFinite(la)&&isFinite(lo)&&csLat.value!==""&&csLng.value!=="")?{lat:la,lng:lo}:null;
      await persist();
    };
    csLat.onchange=saveCs; csLng.onchange=saveCs;
  }
  const sp=body.querySelector("#gen-speed"), spv=body.querySelector("#gen-speed-val");
  sp.oninput=()=>spv.textContent=sp.value+" km/h";
  sp.onchange=async()=>{ s.avgSpeedKmh=Number(sp.value); await persist(); };
  const search=body.querySelector("#gen-search");
  search.oninput=()=>{genQuery=search.value; renderGenBody(); const x=$("#gen-search"); x.focus(); x.setSelectionRange(x.value.length,x.value.length);};
  body.querySelector("#gen-all").onclick=async()=>{ state.weekSelection=state.branches.map(b=>b.id); await persist(); renderGenBody(); };
  body.querySelector("#gen-none").onclick=async()=>{ state.weekSelection=[]; await persist(); renderGenBody(); };
  body.querySelectorAll("[data-wk]").forEach(b=>b.onclick=async()=>{
    const id=b.dataset.wk, i=state.weekSelection.indexOf(id);
    if(i>=0) state.weekSelection.splice(i,1); else {
      state.weekSelection.push(id);
      const br=state.branches.find(x=>x.id===id);
      if(br && !br.active) br.active=true;
    }
    await persist(); renderGenBody();
  });
  body.querySelectorAll("[data-wksize]").forEach(b=>b.onclick=async()=>{
    const br=state.branches.find(x=>x.id===b.dataset.wksize);
    br.size = br.size==="small" ? "large" : "small";
    await persist(); renderGenBody();
  });

  $("#gen-confirm").onclick=async()=>{
    const btn=$("#gen-confirm");
    btn.disabled=true; btn.textContent="جارٍ حساب المسار الأمثل…";
    await new Promise(r=>setTimeout(r,350));
    const p=generatePlan();
    state.plans.unshift(p); state.activePlanId=p.id;
    await persist(); scheduleReminders();
    closeGenModal(); renderPlan();
    toast("جُهّزت خطة الأسبوع ✨","ok");
  };
}

/* ---- نموذج تأكيد الزيارة ---- */
let visitFormId=null;
const vTimeVal=ts=>{const d=new Date(ts);return String(d.getHours()).padStart(2,"0")+":"+String(d.getMinutes()).padStart(2,"0");};
function openVisitForm(visitId){
  visitFormId=visitId;
  const v=state.visits.find(x=>x.id===visitId); if(!v)return;
  $("#visit-title").textContent=`✅ تأكيد زيارة: ${v.nameAr}`;
  $("#visit-body").innerHTML=`
    <p class="mono faint" dir="ltr" style="font-size:.72rem;margin-bottom:.8rem">
      ${new Date(v.startedAt).toLocaleString("en-GB")} · ${visitElapsedMin(v)} min ${v.status==="auto"?"· auto-closed":""}
    </p>
    <h2 class="sec" style="margin-top:0">⏱ وقت الزيارة (اختياري — للتعديل اليدوي)</h2>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:.6rem">
      <div class="finding"><label>وقت الوصول</label>
        <input type="time" class="mono" id="vf-start" value="${vTimeVal(v.startedAt)}"></div>
      <div class="finding"><label>المدة (دقيقة)</label>
        <input dir="ltr" type="number" min="1" inputmode="numeric" class="mono" id="vf-dur" value="${visitElapsedMin(v)||v.plannedMin}" placeholder="${v.plannedMin}"></div>
    </div>
    <h2 class="sec req">نتائج الفحص (إلزامية)</h2>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:.6rem">
      <div class="finding" style="border-color:var(--danger)"><label style="color:var(--danger)">Critical</label>
        <input dir="ltr" type="number" min="0" inputmode="numeric" class="mono" id="vf-critical" value="${v.critical??""}" placeholder="0"></div>
      <div class="finding" style="border-color:var(--accent)"><label style="color:var(--accent)">Major</label>
        <input dir="ltr" type="number" min="0" inputmode="numeric" class="mono" id="vf-major" value="${v.major??""}" placeholder="0"></div>
      <div class="finding"><label style="color:var(--text-2)">Minor</label>
        <input dir="ltr" type="number" min="0" inputmode="numeric" class="mono" id="vf-minor" value="${v.minor??""}" placeholder="0"></div>
    </div>
    <h2 class="sec">قراءات الجودة (اختيارية)</h2>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:.6rem">
      <div class="finding"><label>PH</label>
        <input dir="ltr" type="number" step="0.1" min="0" max="14" class="mono" id="vf-ph" value="${v.ph??""}" placeholder="7.0"></div>
      <div class="finding"><label>TDS (ppm)</label>
        <input dir="ltr" type="number" min="0" class="mono" id="vf-tds" value="${v.tds??""}" placeholder="120"></div>
    </div>
    <h2 class="sec">ملاحظات (اختيارية)</h2>
    <textarea id="vf-notes" placeholder="أي ملاحظات عن الزيارة…">${esc(v.notes??"")}</textarea>
    <p id="vf-err" style="color:var(--danger);font-size:.78rem;font-weight:700;margin-top:.5rem"></p>
  `;
  $("#visit-modal").classList.add("open");
  $("#visit-save").onclick=saveVisitForm;
}
function closeVisitModal(){ $("#visit-modal").classList.remove("open"); visitFormId=null; }
async function saveVisitForm(){
  const v=state.visits.find(x=>x.id===visitFormId); if(!v)return;
  const num=id=>{const el=document.getElementById(id); return el.value===""?null:Number(el.value);};
  const critical=num("vf-critical"), major=num("vf-major"), minor=num("vf-minor");
  if(critical==null||major==null||minor==null||critical<0||major<0||minor<0){
    $("#vf-err").textContent="⚠️ أدخل أعداد Critical و Major و Minor (ضع 0 إن لم توجد)";
    return;
  }
  v.critical=critical; v.major=major; v.minor=minor;
  v.ph=num("vf-ph"); v.tds=num("vf-tds");
  v.notes=$("#vf-notes").value.trim();
  const startEl=$("#vf-start"), durEl=$("#vf-dur");
  if(startEl && startEl.value){
    const [hh,mm]=startEl.value.split(":").map(Number);
    const d=new Date(v.startedAt); d.setHours(hh,mm,0,0); v.startedAt=d.getTime();
  }
  const dur=durEl && durEl.value!==""?Math.max(1,Number(durEl.value)):null;
  v.endedAt = dur!=null ? v.startedAt+dur*60000 : (v.endedAt??Date.now());
  v.manualTime = !!(startEl?.value || dur!=null);
  v.status="closed"; v.dataComplete=true;
  await persist(); closeVisitModal();
  toast("حُفظت بيانات الزيارة ✓","ok");
  if(state.tab==="plan") renderPlan(); else if(state.tab==="dash") renderDash();
}

/* ==================== تبويب الفروع ==================== */
let branchQuery="";
function renderBranches(){
  const q=branchQuery.trim();
  const match=b=>!q||b.nameAr.includes(q)||b.nameEn.toLowerCase().includes(q.toLowerCase());
  const regions=new Map();
  for(const b of state.branches){ const k=b.region??"أخرى"; if(!regions.has(k))regions.set(k,[]); regions.get(k).push(b); }

  let html=`<div class="page">
    <div style="display:flex;gap:.5rem;margin-bottom:.8rem">
      <button class="btn-primary" id="add-branch-btn" style="flex:1">${ic("plus",16)} إضافة فرع يدويًا</button>
      <button class="btn-dark" id="export-branches" style="flex-shrink:0">${ic("download",13)} تصدير Excel</button>
    </div>
    <div class="dropzone" id="dz">
      <input type="file" id="xl-file" accept=".xlsx,.xls" style="display:none">
      <div style="font-size:1.8rem">📥</div>
      <b>استيراد فروع من ملف Excel</b>
      <p class="muted" style="font-size:.8rem;margin-top:.3rem">اسحب الملف هنا أو اضغط للاختيار — أعمدة: الاسم، lat، lng، الحجم</p>
      <p id="import-msg" style="font-size:.82rem;font-weight:700;color:var(--ok);margin-top:.4rem"></p>
    </div>
    <input style="margin-top:1rem" id="search" placeholder="ابحث عن فرع… (مثال: الرياض، النرجس)" value="${esc(branchQuery)}">
    <p class="mono faint" dir="ltr" style="font-size:.78rem;margin-top:.6rem">${state.branches.filter(b=>b.active).length}/${state.branches.length} active</p>`;

  for(const [region,list] of regions){
    const vis=list.filter(match); if(!vis.length) continue;
    html+=`<h2 class="sec">${esc(region)}</h2>`;
    for(const b of vis){
      html+=`<div class="card branch ${b.active?"":"off"}">
        <button class="dot" data-toggle="${b.id}" aria-label="تفعيل/تعطيل">☕</button>
        <div class="info"><b>${esc(b.nameAr)}</b><small dir="ltr">${esc(b.nameEn)}</small>
        <small class="mono" dir="ltr">${b.lat.toFixed(5)}, ${b.lng.toFixed(5)}</small></div>
        <div style="display:flex;flex-direction:column;align-items:flex-end;gap:.3rem">
          <button class="size-btn ${b.size==="large"?"large":""}" data-size="${b.id}">${b.size==="large"?"كبير · 120د":"صغير · 90د"}</button>
          <div style="display:flex;gap:.2rem">
            <button class="del-btn" style="color:var(--ok)" data-shloc="${b.id}">↗ مشاركة</button>
            <button class="del-btn" data-del="${b.id}">حذف</button>
          </div>
        </div>
      </div>`;
    }
  }
  html+=`</div>`;
  main.innerHTML=html;

  $("#add-branch-btn").onclick=()=>openAddBranch();
  $("#export-branches").onclick=()=>{ try{exportBranchesExcel(); toast("صُدّر ملف الفروع ✓","ok");}catch(e){toast("تعذّر التصدير","err");} };
  const dz=$("#dz"), fi=$("#xl-file");
  dz.onclick=()=>fi.click();
  dz.ondragover=e=>{e.preventDefault();dz.classList.add("drag");};
  dz.ondragleave=()=>dz.classList.remove("drag");
  dz.ondrop=e=>{e.preventDefault();dz.classList.remove("drag");handleXl(e.dataTransfer.files);};
  fi.onchange=()=>handleXl(fi.files);
  async function handleXl(files){
    const f=files?.[0]; if(!f)return;
    $("#import-msg").textContent="جارٍ الاستيراد…";
    try{
      const parsed=await parseExcel(f);
      if(!parsed.length){ $("#import-msg").textContent="لم يُعثر على فروع بإحداثيات صالحة في الملف"; return; }
      state.branches.push(...parsed); await persist(); renderBranches();
      toast(`استُورد ${parsed.length} فرعًا ✓`,"ok");
    }catch(e){ $("#import-msg").textContent="تعذّرت قراءة الملف — تأكد أنه بصيغة .xlsx"; }
  }
  $("#search").oninput=e=>{branchQuery=e.target.value; renderBranches(); const s=$("#search"); s.focus(); s.setSelectionRange(s.value.length,s.value.length);};
  main.querySelectorAll("[data-toggle]").forEach(x=>x.onclick=async()=>{const b=state.branches.find(y=>y.id===x.dataset.toggle); b.active=!b.active; await persist(); renderBranches();});
  main.querySelectorAll("[data-size]").forEach(x=>x.onclick=async()=>{const b=state.branches.find(y=>y.id===x.dataset.size); b.size=b.size==="small"?"large":"small"; await persist(); renderBranches();});
  main.querySelectorAll("[data-del]").forEach(x=>x.onclick=async()=>{state.branches=state.branches.filter(y=>y.id!==x.dataset.del); await persist(); renderBranches(); toast("حُذف الفرع","ok");});
  main.querySelectorAll("[data-shloc]").forEach(x=>x.onclick=()=>{const b=state.branches.find(y=>y.id===x.dataset.shloc); shareLocation(b.nameAr,b.lat,b.lng,x);});
}

/* ---- إضافة فرع يدويًا ---- */
let addCoords=null;
/* يُستدعى بعد حفظ فرع جديد (مثلاً من معالج الجدولة) بدل إعادة رسم تبويب الفروع */
let addBranchCallback=null;
function openAddBranch(){
  addCoords=null;
  $("#add-body").innerHTML=`
    <h2 class="sec" style="margin-top:.4rem">📝 بيانات الفرع</h2>
    <input id="ab-name" placeholder="اسم الفرع (مدينة، حي، شارع)" style="margin-bottom:.5rem">
    <input id="ab-region" placeholder="المنطقة (مثال: الرياض)" style="margin-bottom:.7rem">
    <div style="display:flex;gap:.5rem;margin-bottom:.9rem">
      <button class="mini-chip on" id="ab-small" style="flex:1;padding:.6rem">صغير · 90د</button>
      <button class="mini-chip" id="ab-large" style="flex:1;padding:.6rem">كبير · 120د</button>
    </div>

    <h2 class="sec">📍 تحديد الموقع — اختر طريقة</h2>
    <div class="card" style="padding:.85rem">
      <label style="font-size:.78rem;font-weight:700;color:var(--text-2)">1) رابط خرائط جوجل</label>
      <p class="muted" style="font-size:.7rem;margin:.2rem 0 .5rem">ألصق رابط الموقع من تطبيق خرائط جوجل (يحتوي إحداثيات مثل @24.7,46.6)</p>
      <div style="display:flex;gap:.5rem">
        <input dir="ltr" id="ab-url" placeholder="https://maps.google.com/…" style="flex:1;font-size:.8rem">
        <button class="btn-dark" id="ab-url-btn" style="flex-shrink:0">استخراج</button>
      </div>
    </div>

    <div class="card" style="padding:.85rem;margin-top:.6rem">
      <label style="font-size:.78rem;font-weight:700;color:var(--text-2)">2) العنوان الوطني الموحّد</label>
      <p class="muted" style="font-size:.7rem;margin:.2rem 0 .5rem">4 أحرف + 4 أرقام (مثال: RRRA2929) — يفتح خرائط جوجل للبحث عنه ثم ألصق الرابط في الخانة أعلاه</p>
      <div style="display:flex;gap:.5rem">
        <input dir="ltr" id="ab-nat" placeholder="RRRA2929" maxlength="8" class="mono" style="flex:1;text-transform:uppercase;font-size:.9rem;letter-spacing:2px;text-align:center">
        <button class="btn-dark" id="ab-nat-btn" style="flex-shrink:0">🔍 بحث</button>
      </div>
    </div>

    <div class="card" style="padding:.85rem;margin-top:.6rem">
      <label style="font-size:.78rem;font-weight:700;color:var(--text-2)">3) إحداثيات مباشرة</label>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:.5rem;margin-top:.4rem">
        <input dir="ltr" type="number" step="0.000001" class="mono" id="ab-lat" placeholder="Latitude" style="font-size:.82rem">
        <input dir="ltr" type="number" step="0.000001" class="mono" id="ab-lng" placeholder="Longitude" style="font-size:.82rem">
      </div>
      <button id="ab-geo" style="color:var(--ok);font-weight:700;font-size:.8rem;margin-top:.5rem">📍 استخدام موقعي الحالي</button>
    </div>

    <p id="ab-status" style="font-size:.8rem;font-weight:700;margin-top:.7rem;text-align:center"></p>
  `;
  $("#add-modal").classList.add("open");
  bindAddBranch();
}
function closeAddBranch(){ $("#add-modal").classList.remove("open"); addBranchCallback=null; }

function parseMapsUrl(url){
  let m=url.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/);
  if(m) return {lat:+m[1],lng:+m[2]};
  m=url.match(/[?&](?:q|ll|destination)=(-?\d+\.\d+),(-?\d+\.\d+)/);
  if(m) return {lat:+m[1],lng:+m[2]};
  m=url.match(/!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/);
  if(m) return {lat:+m[1],lng:+m[2]};
  m=url.match(/(-?\d{1,2}\.\d{3,}),\s*(-?\d{1,3}\.\d{3,})/);
  if(m) return {lat:+m[1],lng:+m[2]};
  return null;
}
function setAddCoords(c,srcMsg){
  const st=$("#ab-status");
  if(c && isFinite(c.lat) && isFinite(c.lng)){
    addCoords=c;
    $("#ab-lat").value=c.lat.toFixed(6);
    $("#ab-lng").value=c.lng.toFixed(6);
    st.style.color="var(--ok)"; st.textContent=`✓ ${srcMsg}: ${c.lat.toFixed(5)}, ${c.lng.toFixed(5)}`;
  } else {
    st.style.color="var(--danger)"; st.textContent="⚠️ تعذّر استخراج إحداثيات من هذا الرابط — جرّب نسخ الرابط الكامل أو أدخل الإحداثيات يدويًا";
  }
}
function bindAddBranch(){
  const body=$("#add-body");
  let size="small";
  const sm=body.querySelector("#ab-small"), lg=body.querySelector("#ab-large");
  sm.onclick=()=>{size="small";sm.classList.add("on");lg.classList.remove("on");};
  lg.onclick=()=>{size="large";lg.classList.add("on");sm.classList.remove("on");};

  body.querySelector("#ab-url-btn").onclick=()=>{
    const url=body.querySelector("#ab-url").value.trim();
    if(!url) return;
    setAddCoords(parseMapsUrl(url),"من الرابط");
  };
  body.querySelector("#ab-nat-btn").onclick=()=>{
    const code=body.querySelector("#ab-nat").value.trim().toUpperCase();
    const st=$("#ab-status");
    if(!/^[A-Zء-ي]{4}\d{4}$/.test(code)){
      st.style.color="var(--danger)"; st.textContent="⚠️ صيغة العنوان الوطني: 4 أحرف + 4 أرقام (مثال RRRA2929)";
      return;
    }
    st.style.color="var(--text-2)";
    st.innerHTML=`فُتح بحث خرائط جوجل عن <b dir="ltr">${code}</b> — انسخ رابط الموقع من هناك وألصقه في الخانة (1) ثم اضغط استخراج`;
    window.open(`https://www.google.com/maps/search/${encodeURIComponent(code+" السعودية")}`,"_blank");
  };
  body.querySelector("#ab-geo").onclick=()=>{
    navigator.geolocation?.getCurrentPosition(
      p=>setAddCoords({lat:p.coords.latitude,lng:p.coords.longitude},"موقعك الحالي"),
      ()=>{const st=$("#ab-status");st.style.color="var(--danger)";st.textContent="تعذّر تحديد الموقع";}
    );
  };
  const syncManual=()=>{
    const la=Number(body.querySelector("#ab-lat").value), lo=Number(body.querySelector("#ab-lng").value);
    if(isFinite(la)&&isFinite(lo)&&body.querySelector("#ab-lat").value&&body.querySelector("#ab-lng").value) addCoords={lat:la,lng:lo};
  };
  body.querySelector("#ab-lat").oninput=syncManual;
  body.querySelector("#ab-lng").oninput=syncManual;

  $("#add-save").onclick=async()=>{
    const name=body.querySelector("#ab-name").value.trim();
    const st=$("#ab-status");
    if(!name){ st.style.color="var(--danger)"; st.textContent="⚠️ أدخل اسم الفرع"; return; }
    syncManual();
    if(!addCoords){ st.style.color="var(--danger)"; st.textContent="⚠️ حدّد الموقع بإحدى الطرق الثلاث أعلاه"; return; }
    const newId="br-m-"+Date.now().toString(36);
    state.branches.push({
      id:newId,
      nameAr:name, nameEn:name,
      region:body.querySelector("#ab-region").value.trim()||"فروع مضافة",
      lat:addCoords.lat, lng:addCoords.lng, size, active:true
    });
    const cb=addBranchCallback; addBranchCallback=null;
    await persist(); closeAddBranch();
    toast("أُضيف الفرع ✓","ok");
    if(cb) cb(newId);
    else if(state.tab==="branches") renderBranches();
  };
}

/* ==================== تبويب الخريطة ==================== */
const TILE_LIGHT={url:"https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png", attr:"© OpenStreetMap © CARTO", opts:{subdomains:"abcd"}};
const TILE_DARK ={url:"https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", attr:"© OpenStreetMap © CARTO", opts:{subdomains:"abcd"}};
const TILE_FALLBACKS=[
  {url:"https://tile.openstreetmap.org/{z}/{x}/{y}.png", attr:"© OpenStreetMap", opts:{}},
  {url:"https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}", attr:"© Esri", opts:{}}
];
let tileProviderIdx=-1;
function addTileLayer(map){
  const p = tileProviderIdx<0 ? (isDark()?TILE_DARK:TILE_LIGHT) : TILE_FALLBACKS[tileProviderIdx];
  const layer=L.tileLayer(p.url,{maxZoom:19,attribution:p.attr,...p.opts});
  let errors=0, loaded=false;
  layer.on("tileload",()=>{ loaded=true; const n=$("#tile-notice"); if(n)n.style.display="none"; });
  layer.on("tileerror",()=>{
    errors++;
    if(loaded) return;
    if(errors>=3){
      map.removeLayer(layer);
      if(tileProviderIdx<TILE_FALLBACKS.length-1){ tileProviderIdx++; addTileLayer(map); }
      else{ const n=$("#tile-notice"); if(n)n.style.display="block"; }
    }
  });
  layer.addTo(map);
}

function renderMap(){
  if(typeof L==="undefined"){
    main.innerHTML=`<div class="page"><div class="card empty"><div class="art">🗺️</div>
      <b>تعذّر تحميل مكتبة الخرائط</b>
      <p>يبدو أن الاتصال بالإنترنت محجوب أو ضعيف — أعد المحاولة عند توفر الشبكة، بقية التطبيق يعمل دون اتصال.</p></div></div>`;
    return;
  }
  const plan=activePlan();
  tileProviderIdx=-1;
  let chips="";
  if(plan){
    chips=`<div id="map-chips"><button class="chip ${mapDayFilter==="all"?"on":""}" data-day="all">الكل</button>`;
    plan.days.forEach(d=>{
      const on=mapDayFilter===d.dayIndex;
      chips+=`<button class="chip" data-day="${d.dayIndex}" style="${on?`background:${dayColor(d.dayIndex)};color:#fff;border-color:${dayColor(d.dayIndex)}`:""}">${d.dayNameAr}</button>`;
    });
    chips+=`</div>`;
  }
  main.innerHTML=`<div style="position:absolute;inset:0"><div id="map"></div>${chips}
    <div id="tile-notice" style="display:none;position:absolute;bottom:1rem;right:.75rem;left:.75rem;z-index:600;background:var(--espresso);color:var(--bg);border-radius:.9rem;padding:.7rem 1rem;font-size:.78rem;line-height:1.7;box-shadow:var(--sh-3)">
      🗺️ يبدو أن هذه المعاينة تحجب صور الخرائط. العلامات والمسارات تعمل، وستظهر الشوارع كاملة عند فتح التطبيق كموقع ويب.
    </div></div>`;

  const act=state.branches.filter(b=>b.active);
  const c=centroid(act)??{lat:24.7136,lng:46.6753};
  leafletMap=L.map("map",{zoomControl:true}).setView([c.lat,c.lng],6);
  addTileLayer(leafletMap);

  const dayOf=new Map();
  plan?.days.forEach(d=>d.stops.forEach(s=>dayOf.set(s.branchId,d.dayIndex)));

  for(const b of act){
    const day=dayOf.get(b.id);
    if(mapDayFilter!=="all" && day!==mapDayFilter) continue;
    const color=day!=null?dayColor(day):"#B29267";
    const size=b.size==="large"?38:30;
    const icon=L.divIcon({className:"",html:`<div class="hm-marker" style="background:${color};width:${size}px;height:${size}px;font-size:${b.size==="large"?12:9}px">½M</div>`,iconSize:[size,size],iconAnchor:[size/2,size/2]});
    L.marker([b.lat,b.lng],{icon}).addTo(leafletMap).bindPopup(
      `<b>${esc(b.nameAr)}</b><br><span dir="ltr" style="font-size:11px">${esc(b.nameEn)}</span><br>`+
      `<a href="https://www.google.com/maps/dir/?api=1&destination=${b.lat},${b.lng}" target="_blank">🧭 الملاحة</a> · `+
      `<a href="#" onclick="shareLoc('${b.id}',event)">↗ مشاركة</a>`+
      (dayOf.has(b.id)&&!findVisit(plan?.id,b.id)?` · <a href="#" onclick="event.preventDefault();checkInMap('${b.id}')" style="color:#2E8C76;font-weight:700">✅ أنا وصلت</a>`:"")+
      (findVisit(plan?.id,b.id)?` · <span style="color:#2E8C76;font-size:11px">${findVisit(plan.id,b.id).status==="open"?"⏱ زيارة جارية":"✓ تمت الزيارة"}</span>`:"")
    );
  }
  plan?.days.forEach(d=>{
    if(mapDayFilter!=="all" && d.dayIndex!==mapDayFilter) return;
    if(d.stops.length>1) L.polyline(d.stops.map(s=>[s.lat,s.lng]),{color:dayColor(d.dayIndex),weight:3,opacity:.7,dashArray:"6 6"}).addTo(leafletMap);
  });

  let focusStops=null;
  if(plan){
    if(mapDayFilter!=="all") focusStops=plan.days.find(d=>d.dayIndex===mapDayFilter)?.stops;
    if(!focusStops?.length) focusStops=plan.days.find(d=>d.dayIndex===0 && d.stops.length)?.stops;
    if(!focusStops?.length) focusStops=plan.days.find(d=>d.stops.length)?.stops;
  }
  if(focusStops?.length){
    leafletMap.fitBounds(L.latLngBounds(focusStops.map(s=>[s.lat,s.lng])), {padding:[60,60], maxZoom:13});
  } else if(act.length){
    leafletMap.fitBounds(L.latLngBounds(act.map(b=>[b.lat,b.lng])), {padding:[40,40]});
  }

  document.querySelectorAll("#map-chips .chip").forEach(ch=>ch.onclick=()=>{
    mapDayFilter=ch.dataset.day==="all"?"all":Number(ch.dataset.day);
    leafletMap.remove(); leafletMap=null; renderMap();
  });
}

/* ==================== تبويب المساعد الذكي ==================== */
let aiBusy=false, aiSetupOpen=false;
/* معالج إنشاء الجدول من قائمة فروع في الدردشة */
let schedWizard=null; // {items:[{token,status,chosenId,candidates}]}

function renderAI(){
  const cfg=aiConfig();
  const insights=computeInsights();
  const modelLbl=(AI_MODELS.find(m=>m.id===cfg.model)||AI_MODELS[0]).label.split("—")[0].trim();

  let html=`<div class="page">
    <div class="ai-hero">
      <b>${ic("sparkles",18)} مساعد ½M الذكي</b>
      <p>يقرأ فروعك وخطتك وسجل زياراتك ليجيب عن أسئلتك ويكتب تقاريرك. <b>جديد:</b> أرسل قائمة بأسماء فروعك — حتى بالإنجليزية مثل <span dir="ltr" class="mono">shobra, taif</span> — وسيبني جدول أسبوعك فورًا.</p>
      <div style="display:flex;gap:.4rem;margin-top:.6rem;align-items:center;flex-wrap:wrap">
        ${aiReady()
          ? `<span class="visit-chip done-chip">● متصل · ${esc(modelLbl)}</span>`
          : `<span class="visit-chip auto-chip">○ الدردشة الذكية غير مفعّلة — الجدولة بالقائمة تعمل دون مفتاح</span>`}
        <button class="mini-chip" id="ai-setup-btn">${ic("sliders",12)} ${aiSetupOpen?"إخفاء الإعداد":"إعداد الذكاء"}</button>
        ${aiChat.length?`<button class="mini-chip" id="ai-clear-btn">${ic("trash",12)} مسح المحادثة</button>`:""}
      </div>
    </div>`;

  if(aiSetupOpen || !aiReady()){
    html+=`<div class="card pad" style="margin-bottom:1rem">
      <b style="font-size:.9rem">⚙️ إعداد الاتصال بـ Claude</b>
      <p class="muted" style="font-size:.74rem;margin:.4rem 0 .7rem;line-height:1.8">
        أنشئ مفتاح API من <span dir="ltr" class="mono">console.anthropic.com</span> وألصقه هنا.
        يُحفظ المفتاح على جهازك فقط ولا يُرفع أبدًا مع المزامنة السحابية.</p>
      <label class="muted" style="font-size:.7rem;font-weight:600;display:block">مفتاح Anthropic API</label>
      <input dir="ltr" type="password" class="mono" id="ai-key" placeholder="sk-ant-…" value="${esc(cfg.apiKey??"")}" style="font-size:.8rem;margin:.25rem 0 .6rem" autocomplete="off">
      <label class="muted" style="font-size:.7rem;font-weight:600;display:block">النموذج</label>
      <select id="ai-model" style="margin:.25rem 0 .7rem">
        ${AI_MODELS.map(m=>`<option value="${m.id}" ${cfg.model===m.id?"selected":""}>${m.label}</option>`).join("")}
      </select>
      <div style="display:flex;gap:.5rem">
        <button class="btn-dark" id="ai-save" style="flex:1">💾 حفظ واختبار الاتصال</button>
        ${cfg.apiKey?'<button class="btn-ghost" id="ai-forget">نسيان المفتاح</button>':""}
      </div>
      <p id="ai-setup-msg" style="font-size:.76rem;font-weight:700;margin-top:.55rem;text-align:center"></p>
    </div>`;
  }

  html+=`<h2 class="sec">${ic("trend",13)} رؤى فورية <span class="faint" style="font-weight:500">(تُحسب على جهازك دون إنترنت)</span></h2>`;
  for(const ins of insights){
    html+=`<div class="card insight" style="--acc:${ins.acc}">
      <span class="em" style="color:${ins.acc}">${ins.icon?ic(ins.icon,20):ins.em}</span>
      <div><b>${esc(ins.title)}</b><p>${esc(ins.body)}</p></div>
    </div>`;
  }

  html+=`<h2 class="sec">${ic("msg",13)} اسأل المساعد</h2>
    <div class="scroll-x" style="margin-bottom:.6rem">
      <button class="qa-chip" id="qa-sched">${ic("calendar",13)} جدول من قائمة فروع</button>
      ${AI_QUICK.map((q,i)=>`<button class="qa-chip" data-qa="${i}">${q.em} ${q.label}</button>`).join("")}
    </div>
    <div class="card chat-box" id="chat-box">`;
  if(!aiChat.length && !schedWizard){
    html+=`<div class="empty" style="padding:1.5rem 1rem"><div class="art">💬</div><b>ابدأ محادثة</b><p>اسأل: "ما أكثر فرع سجّل مخالفات؟"<br>أو أرسل قائمة: <span dir="ltr" class="mono">shobra, azizyah, taif</span> لبناء جدولك</p></div>`;
  }
  for(let i=0;i<aiChat.length;i++){
    const m=aiChat[i];
    if(m.role==="user") html+=`<div class="msg user">${esc(m.content)}</div>`;
    else html+=`<div class="msg ai">${mdLite(m.content)}</div>
      <div class="msg-tools"><button data-copy="${i}">📋 نسخ</button><button data-sharemsg="${i}">↗ مشاركة</button></div>`;
  }
  if(schedWizard) html+=schedWizardHTML();
  html+=`</div>
    <div class="chat-input">
      <textarea id="chat-in" rows="1" placeholder="اسأل عن الفروع… أو ألصق قائمة أسماء لبناء الجدول"></textarea>
      <button class="send-btn" id="chat-send" aria-label="إرسال" ${aiBusy?"disabled":""}>${ic("send",19)}</button>
    </div>
    <p class="faint" style="font-size:.66rem;margin-top:.5rem;text-align:center">قد يخطئ الذكاء الاصطناعي — راجع الأرقام المهمة قبل اعتمادها</p>
  </div>`;

  main.innerHTML=html;

  $("#ai-setup-btn").onclick=()=>{ aiSetupOpen=!aiSetupOpen; renderAI(); };
  const clearBtn=$("#ai-clear-btn");
  if(clearBtn) clearBtn.onclick=()=>{ clearChat(); renderAI(); toast("مُسحت المحادثة","ok"); };

  const saveBtn=$("#ai-save");
  if(saveBtn) saveBtn.onclick=async()=>{
    const key=$("#ai-key").value.trim(), model=$("#ai-model").value;
    const msg=$("#ai-setup-msg");
    if(!key){ msg.style.color="var(--danger)"; msg.textContent="ألصق المفتاح أولاً"; return; }
    msg.style.color="var(--text-2)"; msg.textContent="جارٍ اختبار الاتصال…";
    saveBtn.disabled=true;
    try{
      await testAiKey(key, model);
      saveAiConfig({apiKey:key, model});
      aiSetupOpen=false;
      toast("تم الاتصال بنجاح ✦","ok");
      renderAI();
    }catch(e){
      msg.style.color="var(--danger)"; msg.textContent="⚠️ "+e.message;
      saveBtn.disabled=false;
    }
  };
  const forgetBtn=$("#ai-forget");
  if(forgetBtn) forgetBtn.onclick=()=>{ saveAiConfig({apiKey:null}); renderAI(); toast("نُسي المفتاح","ok"); };

  main.querySelectorAll("[data-qa]").forEach(b=>b.onclick=()=>askAi(AI_QUICK[Number(b.dataset.qa)].prompt));
  main.querySelectorAll("[data-copy]").forEach(b=>b.onclick=async()=>{
    try{ await navigator.clipboard.writeText(aiChat[Number(b.dataset.copy)].content); toast("نُسخ الرد ✓","ok"); }catch(e){}
  });
  main.querySelectorAll("[data-sharemsg]").forEach(b=>b.onclick=async()=>{
    const text=aiChat[Number(b.dataset.sharemsg)].content;
    if(navigator.share){ try{ await navigator.share({title:"تقرير مساعد ½M", text}); }catch(e){} }
    else { try{ await navigator.clipboard.writeText(text); toast("نُسخ ✓","ok"); }catch(e){} }
  });

  const input=$("#chat-in"), send=$("#chat-send");
  const autoGrow=()=>{ input.style.height="auto"; input.style.height=Math.min(input.scrollHeight,140)+"px"; };
  input.oninput=autoGrow;
  input.onkeydown=e=>{ if(e.key==="Enter"&&!e.shiftKey){ e.preventDefault(); send.click(); } };
  send.onclick=()=>{
    const t=input.value.trim(); if(!t) return;
    // اعتراض محلي: هل الرسالة قائمة فروع لبناء جدول؟
    const items=detectScheduleIntent(t);
    if(items){
      schedWizard={items};
      input.value=""; autoGrow();
      renderAI();
      return;
    }
    askAi(t);
  };
  $("#qa-sched").onclick=()=>{
    input.value="جدولي: ";
    input.focus();
    input.setSelectionRange(input.value.length,input.value.length);
    toast("ألصق أسماء فروعك مفصولة بفواصل — بالعربية أو الإنجليزية","info",4000);
  };
  bindSchedWizard();

  // مرّر لأسفل فقط عند وجود محادثة قائمة؛ وإلا اعرض البطاقة التعريفية والرؤى
  if(aiChat.length || aiBusy || schedWizard){
    const box=$("#chat-box"); box.scrollTop=box.scrollHeight;
    main.scrollTop = main.scrollHeight;
  } else {
    main.scrollTop = 0;
  }
}

/* ---- بطاقة معالج الجدولة داخل الدردشة ---- */
function schedWizardHTML(){
  const w=schedWizard;
  const resolved=w.items.filter(i=>i.status==="match").length;
  let rows="";
  w.items.forEach((it,idx)=>{
    if(it.status==="match"){
      const b=state.branches.find(x=>x.id===it.chosenId);
      rows+=`<div class="sched-row ok">
        <span class="sched-ic" style="color:var(--ok)">${ic("check",15)}</span>
        <div class="sched-info">
          <small dir="auto">${esc(it.token)}</small>
          <b>${esc(b?b.nameAr:"؟")}</b>
        </div>
        ${it.candidates.length>1?`<button class="mini-chip" data-sw-change="${idx}">تغيير</button>`:""}
        <button class="mini-chip" data-sw-skip="${idx}">تجاهل</button>
      </div>`;
    } else if(it.status==="ambiguous"){
      rows+=`<div class="sched-row ask">
        <span class="sched-ic" style="color:var(--warn)">${ic("alert",15)}</span>
        <div class="sched-info">
          <small dir="auto">${esc(it.token)}</small>
          <b>أي فرع تقصد؟</b>
          <div class="sched-cands">
            ${it.candidates.map(c=>`<button class="mini-chip" data-sw-pick="${idx}:${c.id}">${esc(c.name)}</button>`).join("")}
          </div>
        </div>
        <button class="mini-chip" data-sw-skip="${idx}">تجاهل</button>
      </div>`;
    } else if(it.status==="unknown"){
      rows+=`<div class="sched-row unk">
        <span class="sched-ic" style="color:var(--danger)">${ic("x",15)}</span>
        <div class="sched-info">
          <small dir="auto">${esc(it.token)}</small>
          <b>فرع غير معروف</b>
          <div class="sched-cands">
            <button class="mini-chip on" data-sw-add="${idx}">${ic("plus",11)} إضافته كفرع جديد</button>
            <button class="mini-chip" data-sw-skip="${idx}">تجاهل</button>
          </div>
        </div>
      </div>`;
    } else { // ignored
      rows+=`<div class="sched-row off">
        <span class="sched-ic faint">—</span>
        <div class="sched-info"><small dir="auto" style="text-decoration:line-through">${esc(it.token)}</small></div>
        <button class="mini-chip" data-sw-undo="${idx}">استرجاع</button>
      </div>`;
    }
  });
  const pending=w.items.filter(i=>i.status==="ambiguous"||i.status==="unknown").length;
  return `<div class="card sched-card">
    <div class="sched-head">
      <b>${ic("calendar",15)} إنشاء جدول من قائمتك</b>
      <button class="sheet-x" data-sw-cancel aria-label="إلغاء" style="font-size:1rem">${ic("x",15)}</button>
    </div>
    ${rows}
    <div class="sched-foot">
      <span class="faint" style="font-size:.7rem">${resolved} جاهز${pending?` · ${pending} بانتظار قرارك`:""}</span>
      <button class="btn-primary" data-sw-go style="width:auto;padding:.6rem 1.1rem;font-size:.85rem" ${resolved?"":"disabled"}>
        ${ic("sparkles",14)} توليد الجدول (${resolved})
      </button>
    </div>
  </div>`;
}

function bindSchedWizard(){
  if(!schedWizard) return;
  const w=schedWizard;
  main.querySelectorAll("[data-sw-pick]").forEach(b=>b.onclick=()=>{
    const [idx,id]=b.dataset.swPick.split(":");
    const it=w.items[Number(idx)];
    it.chosenId=id; it.status="match";
    renderAI();
  });
  main.querySelectorAll("[data-sw-change]").forEach(b=>b.onclick=()=>{
    w.items[Number(b.dataset.swChange)].status="ambiguous";
    renderAI();
  });
  main.querySelectorAll("[data-sw-skip]").forEach(b=>b.onclick=()=>{
    w.items[Number(b.dataset.swSkip)].status="ignored";
    renderAI();
  });
  main.querySelectorAll("[data-sw-undo]").forEach(b=>b.onclick=()=>{
    const it=w.items[Number(b.dataset.swUndo)];
    Object.assign(it, matchBranchToken(it.token));
    renderAI();
  });
  main.querySelectorAll("[data-sw-add]").forEach(b=>b.onclick=()=>{
    const idx=Number(b.dataset.swAdd);
    const it=w.items[idx];
    openAddBranch();
    const nameEl=document.getElementById("ab-name");
    if(nameEl) nameEl.value=it.token;
    // بعد حفظ الفرع الجديد يُربط تلقائيًا بالقائمة
    addBranchCallback=(newId)=>{
      _brIdx=null; // إعادة بناء فهرس المطابقة
      it.chosenId=newId; it.status="match";
      it.candidates=[{id:newId, name:state.branches.find(x=>x.id===newId)?.nameAr, score:1}];
      renderAI();
    };
  });
  const cancel=main.querySelector("[data-sw-cancel]");
  if(cancel) cancel.onclick=()=>{ schedWizard=null; renderAI(); };
  const go=main.querySelector("[data-sw-go]");
  if(go) go.onclick=async()=>{
    const ids=[...new Set(w.items.filter(i=>i.status==="match").map(i=>i.chosenId))];
    if(!ids.length) return;
    // فعّل الفروع المختارة واجعلها اختيار الأسبوع
    for(const id of ids){ const b=state.branches.find(x=>x.id===id); if(b) b.active=true; }
    state.weekSelection=ids;
    const p=generatePlan();
    // المستخدم طلب هذه الفروع صراحةً: أي فرع أسقطه المحرك لضيق الدوام
    // يُوزَّع على أقل الأيام ازدحامًا حتى لا يختفي بصمت
    const scheduled=new Set(p.days.flatMap(d=>d.stops.map(s=>s.branchId)));
    const missing=ids.filter(id=>!scheduled.has(id));
    for(const id of missing){
      const b=state.branches.find(x=>x.id===id); if(!b) continue;
      const day=[...p.days].sort((a,c)=>a.stops.length-c.stops.length)[0];
      day.stops.push({branchId:b.id,nameAr:b.nameAr,nameEn:b.nameEn,lat:b.lat,lng:b.lng,size:b.size,
        arrivalTime:"",departureTime:"",travelMinutes:0,distanceKm:0});
    }
    if(missing.length) recalcPlanTimes(p);
    state.plans.unshift(p); state.activePlanId=p.id;
    schedWizard=null;
    await persist(); scheduleReminders();
    setTab("plan");
    if(missing.length) toast(`جُهّز الجدول — ${missing.length} فرعًا بعيدًا قد يتجاوز ساعات الدوام، راجع التوقيتات`,"info",5000);
    else toast(`جُهّز جدول ${ids.length} فرعًا ✨`,"ok");
  };
}

async function askAi(prompt){
  if(aiBusy) return;
  if(!aiReady()){ aiSetupOpen=true; renderAI(); toast("أضف مفتاح Anthropic API أولاً","err"); return; }
  aiBusy=true;
  aiChat.push({role:"user", content:prompt});
  saveChat();
  renderAI();

  // فقاعة بث مباشر
  const box=$("#chat-box");
  const bubble=document.createElement("div");
  bubble.className="msg ai";
  bubble.innerHTML=`<span class="typing"><i></i><i></i><i></i></span>`;
  box.appendChild(bubble);
  box.scrollTop=box.scrollHeight;
  $("#chat-send").disabled=true;

  // آخر 12 رسالة كسياق محادثة
  const history=aiChat.slice(-12).map(m=>({role:m.role, content:m.content}));

  await claudeStream(history,{
    onDelta:(t,full)=>{ bubble.innerHTML=mdLite(full); box.scrollTop=box.scrollHeight; },
    onDone:(full)=>{
      aiChat.push({role:"assistant", content:full});
      saveChat();
      aiBusy=false;
      renderAI();
    },
    onError:(msg)=>{
      aiChat.pop(); // أزل رسالة المستخدم غير المُجابة كي يعيد المحاولة
      saveChat();
      aiBusy=false;
      renderAI();
      toast(msg,"err",5000);
    }
  });
}

/* ==================== تبويب لوحة البيانات ==================== */
let dashPeriod="week", dashStatus="all", dashQuery="";
let dashScope="mine", dashMember="all", teamLoading=false, teamError=null;
function weekBounds(offset=0){
  const now=new Date(), sun=new Date(now);
  sun.setDate(now.getDate()-now.getDay()+offset*7); sun.setHours(0,0,0,0);
  const end=new Date(sun); end.setDate(sun.getDate()+7);
  return [sun.getTime(), end.getTime()];
}
function filteredVisits(base){
  let list=[...(base??state.visits)];
  if(dashPeriod==="week"){ const [a,b]=weekBounds(0); list=list.filter(v=>v.startedAt>=a&&v.startedAt<b); }
  else if(dashPeriod==="lastweek"){ const [a,b]=weekBounds(-1); list=list.filter(v=>v.startedAt>=a&&v.startedAt<b); }
  if(dashStatus==="complete") list=list.filter(v=>v.dataComplete);
  else if(dashStatus==="incomplete") list=list.filter(v=>!v.dataComplete&&v.status!=="open");
  else if(dashStatus==="open") list=list.filter(v=>v.status==="open");
  const q=dashQuery.trim();
  if(q) list=list.filter(v=>v.nameAr.includes(q));
  return list.sort((a,b)=>b.startedAt-a.startedAt);
}
/* تحميل بيانات الفريق ثم إعادة رسم اللوحة */
function loadTeamThenRender(force=false){
  teamLoading=true; teamError=null;
  teamPull(force).then(()=>{ teamLoading=false; if(state.tab==="dash") renderDash(); })
    .catch(()=>{ teamLoading=false; teamError="تعذّر جلب بيانات الفريق — تحقق من المفتاح والرمز"; if(state.tab==="dash") renderDash(); });
}

/* مخطط أعمدة أسبوعي SVG — الأحد يمينًا (اتجاه القراءة العربية) */
function weekBarsSVG(list){
  const byDay=[0,0,0,0,0];
  for(const v of list){ if(v.dayIndex>=0&&v.dayIndex<5) byDay[v.dayIndex]++; }
  const max=Math.max(1,...byDay);
  const W=520,H=150,pad=8,bw=64,gap=(W-pad*2-bw*5)/4;
  let bars="";
  for(let d=0;d<5;d++){
    const h=Math.max(3,Math.round(byDay[d]/max*92));
    const x=pad+(4-d)*(bw+gap), y=H-34-h;
    bars+=`<rect x="${x}" y="${y}" width="${bw}" height="${h}" rx="4" fill="${dayColor(d)}"/>
      <text x="${x+bw/2}" y="${y-6}" text-anchor="middle" font-size="13" font-weight="700" fill="var(--text)">${byDay[d]||""}</text>
      <text x="${x+bw/2}" y="${H-14}" text-anchor="middle" font-size="11.5" font-weight="600" fill="var(--text-2)">${DAYS_AR[d]}</text>`;
  }
  return `<svg viewBox="0 0 ${W} ${H}" style="width:100%;height:auto" role="img" aria-label="توزيع الزيارات على أيام الأسبوع">
    <line x1="${pad}" y1="${H-33}" x2="${W-pad}" y2="${H-33}" stroke="var(--line)" stroke-width="1"/>
    ${bars}</svg>`;
}

/* شريط مخالفات مكدّس + وسم HTML (يتجنب مشاكل اتجاه النص داخل SVG) */
function severityBarSVG(c,m,mi){
  const total=c+m+mi;
  if(!total) return `<p class="faint" style="font-size:.74rem">لا مخالفات مسجلة ضمن هذا الفلتر 🎉</p>`;
  const W=520,bh=22;
  const segs=[["Critical",c,"var(--danger)"],["Major",m,"var(--accent)"],["Minor",mi,"var(--latte-deep)"]].filter(s=>s[1]>0);
  let x=0, rects="";
  segs.forEach(s=>{
    const w=Math.max(4, s[1]/total*(W-(segs.length-1)*2));
    rects+=`<rect x="${x}" y="0" width="${w}" height="${bh}" rx="4" fill="${s[2]}"/>`;
    x+=w+2;
  });
  const legend=segs.map(s=>
    `<span style="display:inline-flex;align-items:center;gap:.35rem;font-size:.74rem;font-weight:600;color:var(--text-2)">
      <i style="width:10px;height:10px;border-radius:50%;background:${s[2]};display:inline-block"></i>${s[0]} <span class="mono" dir="ltr">${s[1]}</span></span>`
  ).join("");
  return `<svg viewBox="0 0 ${W} ${bh}" style="width:100%;height:auto;display:block" role="img" aria-label="توزيع المخالفات حسب الدرجة">${rects}</svg>
    <div style="display:flex;gap:1rem;margin-top:.5rem;flex-wrap:wrap">${legend}</div>`;
}

function renderDash(){
  const team = dashScope==="team" && teamReady();
  let base=state.visits, memberNames=[];
  if(team){
    if(!teamCache.members && !teamLoading && !teamError) loadTeamThenRender();
    memberNames=Object.keys(teamCache.members??{});
    base = teamCache.members ? mergeTeamVisits(teamCache.members) : [];
    if(dashMember!=="all") base=base.filter(v=>v.owner===dashMember);
  }
  const list=filteredVisits(base);
  const sum=k=>list.reduce((t,v)=>t+(v[k]??0),0);
  const withVal=k=>list.filter(v=>v[k]!=null);
  const avg=k=>{const l=withVal(k);return l.length?(l.reduce((t,v)=>t+v[k],0)/l.length).toFixed(1):"—";};
  const totalMin=list.reduce((t,v)=>t+visitElapsedMin(v),0);
  const complete=list.filter(v=>v.dataComplete).length;

  const chip=(group,val,label)=>`<button class="chip ${(group==="period"?dashPeriod:dashStatus)===val?"on":""}" data-${group}="${val}">${label}</button>`;

  let html=`<div class="page">`;

  // مبدّل النطاق: بياناتي / الفريق (يظهر فقط عند تفعيل نظام الفريق)
  if(teamReady()){
    html+=`<div class="scope-switch">
      <button class="${dashScope==="mine"?"on":""}" data-scope="mine">بياناتي</button>
      <button class="${dashScope==="team"?"on":""}" data-scope="team">${ic("users",14)} الفريق</button>
    </div>`;
  } else if(dashScope==="team"){ dashScope="mine"; }

  html+=`<div class="scroll-x">
      <button class="btn-dark" id="dash-ai" style="flex-shrink:0;background:var(--accent);color:var(--accent-ink)">${ic("sparkles",13)} تقرير ذكي</button>
      <button class="btn-dark" id="dash-share" style="flex-shrink:0">${ic("share",13)} مشاركة</button>
      <button class="btn-ghost" id="dash-pdf" style="flex-shrink:0">${ic("file",13)} PDF</button>
      <button class="btn-ghost" id="dash-xlsx" style="flex-shrink:0">${ic("download",13)} Excel</button>
      ${team?`<button class="btn-ghost" id="dash-refresh" style="flex-shrink:0">${ic("refresh",13)} تحديث</button>`:""}
    </div>`;

  if(team){
    if(teamLoading){
      html+=`<div class="skeleton" style="height:64px;margin:.5rem 0"></div>
        <div class="skeleton" style="height:140px;margin-bottom:.5rem"></div></div>`;
      main.innerHTML=html;
      main.querySelectorAll("[data-scope]").forEach(b=>b.onclick=()=>{dashScope=b.dataset.scope; renderDash();});
      return;
    }
    if(teamError){
      html+=`<div class="hint" style="border-color:var(--danger);color:var(--danger)">${esc(teamError)} — <button style="min-height:auto;font-weight:700;text-decoration:underline" id="team-retry">إعادة المحاولة</button></div>`;
    } else if(memberNames.length){
      html+=`<div class="scroll-x" style="margin-top:.2rem">
        <button class="chip ${dashMember==="all"?"on":""}" data-member="all">كل الأعضاء (${memberNames.length})</button>
        ${memberNames.map(n=>`<button class="chip ${dashMember===n?"on":""}" data-member="${esc(n)}">${esc(n)}</button>`).join("")}
      </div>`;
    }
  }

  html+=`<div class="scroll-x" style="margin-top:.2rem">
      ${chip("period","week","هذا الأسبوع")}${chip("period","lastweek","الأسبوع الماضي")}${chip("period","all","الكل")}
    </div>
    <div class="scroll-x" style="padding:.2rem 0 .4rem">
      ${chip("status","all","كل الحالات")}${chip("status","complete","مكتملة ✓")}${chip("status","incomplete","بيانات ناقصة")}${chip("status","open","جارية ⏱")}
    </div>
    <input id="dash-q" placeholder="فلترة باسم الفرع…" value="${esc(dashQuery)}" style="margin:.3rem 0 .8rem;font-size:.85rem">

    <div class="stat-grid">
      <div class="card stat"><b>${list.length}</b><span>زيارة</span></div>
      ${team?`<div class="card stat"><b style="color:var(--day-0)">${memberNames.length}</b><span>أعضاء الفريق</span></div>`:""}
      <div class="card stat"><b style="color:var(--ok)">${complete}</b><span>مكتملة البيانات</span></div>
      <div class="card stat"><b style="color:var(--danger)">${sum("critical")}</b><span>Critical</span></div>
      <div class="card stat"><b style="color:var(--accent)">${sum("major")}</b><span>Major</span></div>
      <div class="card stat"><b>${sum("minor")}</b><span>Minor</span></div>
      <div class="card stat"><b>${avg("ph")}</b><span>متوسط PH</span></div>
      <div class="card stat"><b>${avg("tds")}</b><span>متوسط TDS</span></div>
      <div class="card stat"><b>${Math.floor(totalMin/60)}:${String(totalMin%60).padStart(2,"0")}</b><span>ساعات الزيارات</span></div>
    </div>`;

  if(list.length){
    html+=`<div class="card viz"><h3>توزيع الزيارات على أيام الأسبوع</h3>${weekBarsSVG(list)}</div>
      <div class="card viz"><h3>توزيع المخالفات حسب الدرجة</h3>${severityBarSVG(sum("critical"),sum("major"),sum("minor"))}</div>`;
  }

  html+=`<h2 class="sec">سجل الزيارات <span class="mono faint" dir="ltr">(${list.length})</span></h2>`;

  if(!list.length){
    html+=team
      ? `<div class="card empty"><div class="art">👥</div><b>لا توجد زيارات فريق ضمن هذا الفلتر</b><p>تأكد أن زملاءك فعّلوا نظام الفريق بنفس الرمز والمفتاح، وأنهم سجّلوا زيارات</p></div>`
      : `<div class="card empty"><div class="art">📭</div><b>لا توجد زيارات ضمن هذا الفلتر</b><p>سجّل وصولك من صفحة الخطة بزر "✅ أنا وصلت" وستظهر هنا نتائج الفحص والمؤشرات</p></div>`;
  } else {
    html+=`<div class="card table-wrap"><table class="dash-table">
      <thead><tr>${team?"<th>العضو</th>":""}<th>الفرع</th><th>التاريخ</th><th>المدة</th><th style="color:var(--danger)">C</th><th style="color:var(--accent)">M</th><th>m</th><th>PH</th><th>TDS</th><th>الحالة</th>${team?"":"<th></th>"}</tr></thead><tbody>`;
    for(const v of list){
      const st=v.status==="open"?"⏱ جارية":v.dataComplete?"✓ مكتملة":"⚠ ناقصة";
      html+=`<tr>
        ${team?`<td><span class="member-chip">${esc(v.owner??"—")}</span></td>`:""}
        <td title="${esc(v.notes??"")}">${esc(v.nameAr)}${v.notes?" 📝":""}</td>
        <td class="mono" dir="ltr">${new Date(v.startedAt).toLocaleDateString("en-GB",{day:"2-digit",month:"2-digit"})} ${new Date(v.startedAt).toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"})}</td>
        <td class="mono" dir="ltr">${visitElapsedMin(v)}د${v.manualTime?" ✎":""}</td>
        <td class="mono">${v.critical??"—"}</td><td class="mono">${v.major??"—"}</td><td class="mono">${v.minor??"—"}</td>
        <td class="mono">${v.ph??"—"}</td><td class="mono">${v.tds??"—"}</td>
        <td style="font-size:.62rem;font-weight:700">${st}</td>
        ${team?"":`<td><button data-vedit="${v.id}" style="min-height:auto;color:var(--accent);font-weight:700;font-size:.68rem;padding:.2rem .4rem" aria-label="تعديل">✏️</button></td>`}
      </tr>`;
    }
    html+=`</tbody></table></div>`;
  }
  html+=`</div>`;
  main.innerHTML=html;

  main.querySelectorAll("[data-scope]").forEach(b=>b.onclick=()=>{dashScope=b.dataset.scope; dashMember="all"; renderDash();});
  main.querySelectorAll("[data-member]").forEach(b=>b.onclick=()=>{dashMember=b.dataset.member; renderDash();});
  const refreshBtn=$("#dash-refresh");
  if(refreshBtn) refreshBtn.onclick=()=>loadTeamThenRender(true);
  const retryBtn=$("#team-retry");
  if(retryBtn) retryBtn.onclick=()=>loadTeamThenRender(true);
  main.querySelectorAll("[data-period]").forEach(b=>b.onclick=()=>{dashPeriod=b.dataset.period; renderDash();});
  main.querySelectorAll("[data-status]").forEach(b=>b.onclick=()=>{dashStatus=b.dataset.status; renderDash();});
  const q=$("#dash-q"); q.oninput=()=>{dashQuery=q.value; renderDash(); const x=$("#dash-q"); x.focus(); x.setSelectionRange(x.value.length,x.value.length);};
  main.querySelectorAll("[data-vedit]").forEach(b=>b.onclick=()=>openVisitForm(b.dataset.vedit));

  const periodLbl={week:"هذا الأسبوع",lastweek:"الأسبوع الماضي",all:"كل الفترات"}[dashPeriod];
  const statsObj={periodLbl, count:list.length, complete, critical:sum("critical"), major:sum("major"),
    minor:sum("minor"), avgPh:avg("ph"), avgTds:avg("tds"), hours:`${Math.floor(totalMin/60)}:${String(totalMin%60).padStart(2,"0")}`};

  $("#dash-ai").onclick=()=>{
    setTab("ai");
    setTimeout(()=>askAi(`اكتب تقريرًا تنفيذيًا عن زيارات ${periodLbl}: الملخص، الأرقام الرئيسية، الفروع الحرجة، وتوصيات عملية.`), 60);
  };
  $("#dash-pdf").onclick=async()=>{ const b=$("#dash-pdf"); b.textContent="…"; try{await exportDashPDF(list,statsObj);}catch(e){toast("تعذّر التصدير","err");} b.innerHTML=`${ic("file",13)} PDF`; };
  $("#dash-xlsx").onclick=()=>{ try{exportDashExcel(list); toast("صُدّر التقرير ✓","ok");}catch(e){toast("تعذّر التصدير","err");} };

  $("#dash-share").onclick=async()=>{
    const btn=$("#dash-share");
    let text=`📊 تقرير زيارات هاف مليون ½M — ${periodLbl}\n`;
    text+=`الزيارات: ${list.length} · مكتملة: ${complete}\n`;
    text+=`Critical: ${sum("critical")} · Major: ${sum("major")} · Minor: ${sum("minor")}\n`;
    text+=`متوسط PH: ${avg("ph")} · متوسط TDS: ${avg("tds")}\n`;
    text+=`إجمالي وقت الزيارات: ${Math.floor(totalMin/60)}س ${totalMin%60}د\n\n`;
    for(const v of list){
      text+=`• ${v.nameAr} — ${new Date(v.startedAt).toLocaleDateString("en-GB")} · ${visitElapsedMin(v)}د · C:${v.critical??"-"} M:${v.major??"-"} m:${v.minor??"-"}${v.ph!=null?" · PH:"+v.ph:""}${v.tds!=null?" · TDS:"+v.tds:""}${v.notes?" · "+v.notes:""}\n`;
    }
    let msg="نُسخ التقرير ✓";
    if(navigator.share){ try{ await navigator.share({title:"تقرير زيارات هاف مليون",text}); msg="تمت المشاركة ✓"; }catch(e){ if(e.name==="AbortError")return; try{await navigator.clipboard.writeText(text);}catch(_){}}}
    else { try{ await navigator.clipboard.writeText(text); }catch(e){} }
    btn.textContent=msg; setTimeout(()=>btn.innerHTML=`${ic("share",13)} مشاركة`,2500);
  };
}

/* ==================== تبويب الإعدادات ==================== */
function renderSettings(){
  const s=state.settings;
  const pref=themePref();
  const coord=(id,v)=>`<div style="display:grid;grid-template-columns:1fr 1fr;gap:.6rem">
    <div><label style="font-size:.7rem;font-weight:600" class="muted">Latitude</label>
    <input dir="ltr" type="number" step="0.000001" class="mono" id="${id}-lat" value="${v?.lat??""}" placeholder="24.7136" style="font-size:.85rem"></div>
    <div><label style="font-size:.7rem;font-weight:600" class="muted">Longitude</label>
    <input dir="ltr" type="number" step="0.000001" class="mono" id="${id}-lng" value="${v?.lng??""}" placeholder="46.6753" style="font-size:.85rem"></div></div>`;

  main.innerHTML=`<div class="page" style="display:flex;flex-direction:column;gap:1rem">
    <section class="card pad">
      <b>🎨 المظهر</b>
      <div style="display:flex;gap:.5rem;margin-top:.7rem">
        <button class="chip ${pref==="auto"?"on":""}" data-theme-set="auto" style="flex:1">تلقائي</button>
        <button class="chip ${pref==="light"?"on":""}" data-theme-set="light" style="flex:1">☀️ فاتح</button>
        <button class="chip ${pref==="dark"?"on":""}" data-theme-set="dark" style="flex:1">🌙 داكن</button>
      </div>
    </section>
    <section class="card pad">
      <b>🏠 موقع الانطلاق (المنزل)</b><div style="height:.6rem"></div>
      ${coord("home",s.homeLocation)}
      <button id="geo-home" style="color:var(--ok);font-weight:700;font-size:.82rem;margin-top:.4rem">📍 استخدام موقعي الحالي</button>
    </section>
    <section class="card pad">
      <b>📋 مقر اجتماع الأحد الأسبوعي</b><div style="height:.6rem"></div>
      <input id="venue-name" placeholder="اسم المقر (مثال: المكتب الرئيسي — الرياض)" value="${esc(s.meetingVenueName)}" style="margin-bottom:.6rem">
      ${coord("meet",s.meetingVenue)}
      <button id="geo-meet" style="color:var(--ok);font-weight:700;font-size:.82rem;margin-top:.4rem">📍 استخدام موقعي الحالي</button>
    </section>
    <section class="card pad">
      <b>🕘 ساعات العمل</b>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin-top:.6rem">
        <div><label class="muted" style="font-size:.7rem;font-weight:600">بداية الدوام</label><input dir="ltr" type="number" min="5" max="12" class="mono" id="work-start" value="${s.workStartHour}"></div>
        <div><label class="muted" style="font-size:.7rem;font-weight:600">نهاية الدوام</label><input dir="ltr" type="number" min="13" max="23" class="mono" id="work-end" value="${s.workEndHour}"></div>
      </div>
      <label class="muted" style="font-size:.7rem;font-weight:600;display:block;margin-top:.6rem">متوسط سرعة القيادة (كم/س) — لتقدير أزمنة التنقل</label>
      <input dir="ltr" type="number" min="20" max="120" class="mono" id="speed" value="${s.avgSpeedKmh}">
      <label class="muted" style="font-size:.7rem;font-weight:600;display:block;margin-top:.6rem">أقصى عدد فروع في اليوم الواحد (0 = بلا حد)</label>
      <input dir="ltr" type="number" min="0" max="20" class="mono" id="max-per-day" value="${s.maxBranchesPerDay??0}">
    </section>
    <section class="card pad">
      <b>🔔 تنبيهات الانطلاق</b>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-top:.7rem">
        <span style="font-weight:600;font-size:.9rem">تفعيل التنبيهات</span>
        <button class="toggle ${s.notificationsEnabled?"on":""}" id="notif-toggle" role="switch" aria-checked="${s.notificationsEnabled}"><i></i></button>
      </div>
      <p class="muted" style="font-size:.75rem;margin:.7rem 0 .4rem">التنبيه قبل موعد الوصول بـ:</p>
      <div class="lead-grid">${[15,30,45,60].map(m=>`<button data-lead="${m}" class="mono ${s.leadTimeMinutes===m?"sel":""}">${m}د</button>`).join("")}</div>
      <p class="muted" style="font-size:.72rem;margin-top:.6rem;line-height:1.6">💡 التنبيهات تعمل أثناء فتح التطبيق في المتصفح.</p>
    </section>
    <section class="card pad">
      <b>☁️ المزامنة الأونلاين الدائمة</b>
      <p class="muted" style="font-size:.75rem;margin:.4rem 0 .7rem;line-height:1.7">احفظ بياناتك سحابيًا وزامنها بين كل أجهزتك تلقائيًا. مجاني عبر خدمة JSONBin.io — أنشئ حسابًا مجانيًا وانسخ منه مفتاح <span dir="ltr" class="mono">X-MASTER-KEY</span>.</p>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:.6rem">
        <span style="font-weight:600;font-size:.9rem">تفعيل المزامنة</span>
        <button class="toggle ${s.syncEnabled?"on":""}" id="sync-toggle" role="switch" aria-checked="${s.syncEnabled}"><i></i></button>
      </div>
      <div id="sync-fields" style="${s.syncEnabled?"":"display:none"}">
        <label class="muted" style="font-size:.7rem;font-weight:600;display:block">مفتاح JSONBin (X-Master-Key)</label>
        <input dir="ltr" class="mono" id="sync-key" placeholder="$2a$10$..." value="${esc(s.syncKey??"")}" style="font-size:.78rem;margin-bottom:.5rem">
        <label class="muted" style="font-size:.7rem;font-weight:600;display:block">رمز الصندوق (Bin ID) — اتركه فارغًا لإنشاء صندوق جديد</label>
        <input dir="ltr" class="mono" id="sync-bin" placeholder="تلقائي عند أول ربط" value="${esc(s.syncBinId??"")}" style="font-size:.78rem;margin-bottom:.6rem">
        <div style="display:flex;gap:.5rem">
          <button class="btn-dark" id="sync-connect" style="flex:1">🔗 ربط / إنشاء صندوق</button>
          <button class="btn-dark" id="sync-pull" style="flex:1;background:var(--ok)">⬇️ جلب من السحابة</button>
        </div>
        <p id="sync-status" style="font-size:.78rem;font-weight:700;margin-top:.6rem;text-align:center"></p>
        <p class="muted" style="font-size:.7rem;margin-top:.5rem;line-height:1.6">💡 بعد الربط على جهاز، أدخل نفس المفتاح ورمز الصندوق على أجهزتك الأخرى واضغط "جلب من السحابة". <b>ملاحظة:</b> مفتاح الذكاء الاصطناعي لا يُزامن أبدًا ويبقى على جهازك.</p>
      </div>
    </section>
    <section class="card pad">
      <b style="display:inline-flex;align-items:center;gap:.4rem">${ic("users",16)} نظام الفريق</b>
      <p class="muted" style="font-size:.75rem;margin:.4rem 0 .7rem;line-height:1.7">
        اجمع نتائج زيارات كل أعضاء الفريق في لوحة واحدة. ينشئ قائد الفريق صندوقًا ويشارك
        <b>المفتاح</b> و<b>رمز الصندوق</b> مع الأعضاء — كلٌ يرفع زياراته وتُدمج للجميع في تبويب اللوحة.</p>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:.6rem">
        <span style="font-weight:600;font-size:.9rem">تفعيل نظام الفريق</span>
        <button class="toggle ${s.teamEnabled?"on":""}" id="team-toggle" role="switch" aria-checked="${s.teamEnabled}"><i></i></button>
      </div>
      <div id="team-fields" style="${s.teamEnabled?"":"display:none"}">
        <label class="muted" style="font-size:.7rem;font-weight:600;display:block">اسمك (كما سيظهر للفريق)</label>
        <input id="team-name" placeholder="مثال: علاء الدين" value="${esc(s.memberName??"")}" style="margin-bottom:.5rem">
        <label class="muted" style="font-size:.7rem;font-weight:600;display:block">مفتاح JSONBin المشترك (X-Master-Key)</label>
        <input dir="ltr" class="mono" id="team-key" placeholder="$2a$10$..." value="${esc(s.teamKey??"")}" style="font-size:.78rem;margin-bottom:.5rem">
        <label class="muted" style="font-size:.7rem;font-weight:600;display:block">رمز صندوق الفريق — اتركه فارغًا لإنشاء فريق جديد</label>
        <input dir="ltr" class="mono" id="team-bin" placeholder="يرسله لك قائد الفريق" value="${esc(s.teamBinId??"")}" style="font-size:.78rem;margin-bottom:.6rem">
        <div style="display:flex;gap:.5rem">
          <button class="btn-dark" id="team-connect" style="flex:1">${ic("users",13)} إنشاء / انضمام</button>
          <button class="btn-dark" id="team-test" style="flex:1;background:var(--ok)">${ic("refresh",13)} اختبار الجلب</button>
        </div>
        <p id="team-status" style="font-size:.78rem;font-weight:700;margin-top:.6rem;text-align:center"></p>
      </div>
    </section>
    <section class="card pad">
      <b>🔗 تحميل خطة مشتركة</b>
      <p class="muted" style="font-size:.78rem;margin:.4rem 0 .6rem">أدخل رمز الخطة الذي شاركه معك زميلك</p>
      <div style="display:flex;gap:.5rem">
        <input dir="ltr" class="mono" id="shared-code" placeholder="plan-xxxxxxxx" style="font-size:.85rem">
        <button class="btn-dark" id="load-shared" style="flex-shrink:0">تحميل</button>
      </div>
      <p id="shared-msg" style="font-size:.8rem;font-weight:700;margin-top:.5rem"></p>
    </section>
  </div>`;

  main.querySelectorAll("[data-theme-set]").forEach(b=>b.onclick=()=>{
    try{ localStorage.setItem("hm-theme", b.dataset.themeSet); }catch(e){}
    applyTheme(); renderSettings();
  });

  const save=async()=>{
    const num=(id)=>{const v=Number(document.getElementById(id).value);return isFinite(v)?v:null;};
    const pair=(id)=>{const la=num(id+"-lat"),lo=num(id+"-lng");return(la&&lo)?{lat:la,lng:lo}:null;};
    s.homeLocation=pair("home"); s.meetingVenue=pair("meet");
    s.meetingVenueName=$("#venue-name").value;
    s.workStartHour=num("work-start")??9; s.workEndHour=num("work-end")??18; s.avgSpeedKmh=num("speed")??45;
    s.maxBranchesPerDay=num("max-per-day")??0;
    await persist(); scheduleReminders();
  };
  main.querySelectorAll("input").forEach(i=>i.onchange=save);

  $("#geo-home").onclick=()=>geoFill("home"); $("#geo-meet").onclick=()=>geoFill("meet");
  function geoFill(id){
    navigator.geolocation?.getCurrentPosition(p=>{
      document.getElementById(id+"-lat").value=p.coords.latitude.toFixed(6);
      document.getElementById(id+"-lng").value=p.coords.longitude.toFixed(6);
      save(); toast("حُدّد الموقع ✓","ok");
    },()=>toast("تعذّر تحديد الموقع — فعّل صلاحية الموقع للمتصفح","err"));
  }

  $("#notif-toggle").onclick=async()=>{
    s.notificationsEnabled=!s.notificationsEnabled;
    if(s.notificationsEnabled && "Notification" in window && Notification.permission==="default") Notification.requestPermission();
    await persist(); scheduleReminders(); renderSettings();
  };
  main.querySelectorAll("[data-lead]").forEach(b=>b.onclick=async()=>{s.leadTimeMinutes=Number(b.dataset.lead); await persist(); scheduleReminders(); renderSettings();});

  const syncToggle=$("#sync-toggle");
  if(syncToggle) syncToggle.onclick=async()=>{ s.syncEnabled=!s.syncEnabled; await persist(); renderSettings(); };
  const syncKeyEl=$("#sync-key"), syncBinEl=$("#sync-bin");
  if(syncKeyEl) syncKeyEl.onchange=async()=>{ s.syncKey=syncKeyEl.value.trim()||null; await persist(); };
  if(syncBinEl) syncBinEl.onchange=async()=>{ s.syncBinId=syncBinEl.value.trim()||null; await persist(); };
  const connectBtn=$("#sync-connect");
  if(connectBtn) connectBtn.onclick=async()=>{
    s.syncKey=$("#sync-key").value.trim()||null; s.syncBinId=$("#sync-bin").value.trim()||null;
    if(!s.syncKey){ updateSyncStatus("أدخل مفتاح JSONBin أولاً","var(--danger)"); return; }
    updateSyncStatus("جارٍ الاتصال…","var(--text-2)");
    try{
      if(!s.syncBinId){ s.syncBinId=await cloudCreateBin(s.syncKey); $("#sync-bin").value=s.syncBinId; }
      await persist(); await cloudPush();
      updateSyncStatus("تم الربط والمزامنة ✓ — رمز صندوقك: "+s.syncBinId,"var(--ok)");
    }catch(e){ updateSyncStatus("تعذّر الربط — تحقق من صحة المفتاح","var(--danger)"); }
  };
  const pullBtn=$("#sync-pull");
  if(pullBtn) pullBtn.onclick=async()=>{
    s.syncKey=$("#sync-key").value.trim()||null; s.syncBinId=$("#sync-bin").value.trim()||null;
    if(!s.syncKey||!s.syncBinId){ updateSyncStatus("أدخل المفتاح ورمز الصندوق","var(--danger)"); return; }
    await persist();
    updateSyncStatus("جارٍ الجلب…","var(--text-2)");
    const ok=await cloudPull();
    if(ok){ updateSyncStatus("تم جلب البيانات ومزامنتها ✓","var(--ok)"); render(); }
  };

  /* ---- نظام الفريق ---- */
  const teamToggle=$("#team-toggle");
  if(teamToggle) teamToggle.onclick=async()=>{ s.teamEnabled=!s.teamEnabled; await persist(); renderSettings(); };
  const tName=$("#team-name"), tKey=$("#team-key"), tBin=$("#team-bin");
  const saveTeamFields=async()=>{
    s.memberName=tName.value.trim();
    s.teamKey=tKey.value.trim()||null;
    s.teamBinId=tBin.value.trim()||null;
    teamCache={ts:0, members:null};
    await persist();
  };
  if(tName){ tName.onchange=saveTeamFields; tKey.onchange=saveTeamFields; tBin.onchange=saveTeamFields; }
  const teamConnect=$("#team-connect");
  if(teamConnect) teamConnect.onclick=async()=>{
    await saveTeamFields();
    if(!s.memberName){ updateTeamStatus("أدخل اسمك أولاً","var(--danger)"); return; }
    if(!s.teamKey){ updateTeamStatus("أدخل مفتاح JSONBin المشترك","var(--danger)"); return; }
    updateTeamStatus("جارٍ الاتصال…","var(--text-2)");
    try{
      if(!s.teamBinId){
        s.teamBinId=await teamCreateBin(s.teamKey, s.memberName);
        tBin.value=s.teamBinId;
        await persist();
        updateTeamStatus("أُنشئ فريق جديد ✓ — شارك المفتاح والرمز مع أعضائك: "+s.teamBinId,"var(--ok)");
      } else {
        await teamPush();
        updateTeamStatus("انضممت للفريق ورُفعت زياراتك ✓","var(--ok)");
      }
      teamCache={ts:0, members:null};
    }catch(e){ updateTeamStatus("تعذّر الاتصال — تحقق من المفتاح والرمز","var(--danger)"); }
  };
  const teamTest=$("#team-test");
  if(teamTest) teamTest.onclick=async()=>{
    await saveTeamFields();
    if(!teamReady()){ updateTeamStatus("أكمل الاسم والمفتاح والرمز أولاً","var(--danger)"); return; }
    updateTeamStatus("جارٍ الجلب…","var(--text-2)");
    try{
      const members=await teamPull(true);
      const names=Object.keys(members??{});
      updateTeamStatus(`متصل ✓ — ${names.length} عضو: ${names.join("، ")||"لا أعضاء بعد"}`,"var(--ok)");
    }catch(e){ updateTeamStatus("تعذّر الجلب — تحقق من المفتاح والرمز","var(--danger)"); }
  };

  $("#load-shared").onclick=async()=>{
    const code=$("#shared-code").value.trim(); if(!code)return;
    $("#shared-msg").textContent="جارٍ البحث…"; $("#shared-msg").style.color="var(--text-2)";
    const p=await loadSharedPlan(code);
    if(p){
      if(!state.plans.some(x=>x.id===p.id)) state.plans.unshift(p);
      state.activePlanId=p.id; await persist();
      $("#shared-msg").textContent="تم تحميل الخطة ✓ — انتقل لتبويب الخطة"; $("#shared-msg").style.color="var(--ok)";
    } else { $("#shared-msg").textContent="لم يُعثر على خطة بهذا الرمز"; $("#shared-msg").style.color="var(--danger)"; }
  };
}

/* ==================== التشغيل ==================== */
document.getElementById("remind-close").onclick=hideRemind;
document.getElementById("theme-btn").onclick=toggleTheme;

(async function init(){
  applyTheme();
  await hydrate();
  // خطة مشتركة من الرابط (#p=) أو التخزين المشترك (?planId=)
  try{
    const hp=new URLSearchParams(location.hash.slice(1)).get("p");
    if(hp){ const p=b64dec(hp); if(p?.id && !state.plans.some(x=>x.id===p.id)){ state.plans.unshift(p); state.activePlanId=p.id; } }
  }catch(e){}
  const pid=new URLSearchParams(location.search).get("planId");
  if(pid && !state.plans.some(x=>x.id===pid)){
    const p=await loadSharedPlan(pid);
    if(p && !state.plans.some(x=>x.id===p.id)){ state.plans.unshift(p); state.activePlanId=p.id; }
  }
  if(state.settings.syncEnabled && state.settings.syncBinId && state.settings.syncKey){
    await cloudPull();
  }
  await persist();
  scheduleReminders();
  const splash=document.getElementById("splash");
  splash.classList.add("hide");
  setTimeout(()=>splash.remove(), 450);
  render();
  if("serviceWorker" in navigator && location.protocol.startsWith("http")){
    navigator.serviceWorker.register("sw.js").catch(()=>{});
  }
  // تحديث عدادات الزيارات والإغلاق التلقائي كل 30 ثانية
  setInterval(()=>{
    const changed=autoCloseVisits();
    const modalOpen=document.querySelector(".modal.open");
    if(!modalOpen && !editMode && !aiBusy && (state.tab==="plan"||state.tab==="dash")){
      const hasOpen=state.visits.some(v=>v.status==="open");
      if(changed||hasOpen) render();
    }
  },30000);
})();
