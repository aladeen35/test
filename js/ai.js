/* ============================================================
   هاف مليون ½M — طبقة الذكاء الاصطناعي
   1) محرك رؤى محلي يعمل دون اتصال
   2) عميل Claude API (مباشر من المتصفح) للمساعد والتقارير
   ============================================================ */

/* ============ إعدادات الذكاء ============
   تُخزَّن محليًا فقط (hm-ai) ولا تُرفع أبدًا للمزامنة السحابية
   حفاظًا على سرية مفتاح API.
   سلسلة مزوّدين تلقائية كي يعمل الذكاء دون أي إعداد:
   1) "proxy" — خادم الشركة الوسيط إن حُدّد في js/config.js (بلا مفتاح للمستخدم)
   2) "key"   — مفتاح Anthropic أدخله المستخدم (خيار متقدم)
   3) "puter" — خدمة Puter المجانية بلا مفتاح (تسجيل دخول مجاني عند أول رسالة) */
const AI_MODELS = [
  {id:"claude-opus-5",   label:"Opus 5 — الأذكى (موصى به)"},
  {id:"claude-sonnet-5", label:"Sonnet 5 — متوازن"},
  {id:"claude-haiku-4-5",label:"Haiku 4.5 — سريع واقتصادي"},
];
function aiConfig(){
  try{ return {apiKey:null, model:"claude-opus-5", ...JSON.parse(localStorage.getItem("hm-ai")||"{}")}; }
  catch(e){ return {apiKey:null, model:"claude-opus-5"}; }
}
function saveAiConfig(patch){
  const cfg={...aiConfig(), ...patch};
  try{ localStorage.setItem("hm-ai", JSON.stringify(cfg)); }catch(e){}
  return cfg;
}
function aiProxyUrl(){
  return (typeof APP_CONFIG!=="undefined" && APP_CONFIG?.ai?.proxyUrl) || null;
}
function aiProvider(){
  if(aiConfig().apiKey) return "key";
  if(aiProxyUrl()) return "proxy";
  return "puter";
}
/* الذكاء متاح دائمًا الآن — Puter يعمل كخيار أخير بلا مفتاح */
function aiReady(){ return true; }

/* تحميل Puter عند الحاجة فقط (لا يُحمَّل إن وُجد مفتاح أو خادم وسيط) */
const PUTER_SRC="https://js.puter.com/v2/";
let puterLoading=null;
function loadPuter(){
  if(window.puter?.ai) return Promise.resolve(true);
  if(puterLoading) return puterLoading;
  puterLoading=new Promise(res=>{
    const sc=document.createElement("script");
    sc.src=PUTER_SRC; sc.async=true;
    sc.onload=()=>res(!!window.puter?.ai);
    sc.onerror=()=>{ puterLoading=null; res(false); };
    document.head.appendChild(sc);
    setTimeout(()=>res(!!window.puter?.ai), 15000);
  });
  return puterLoading;
}
/* أقرب نموذج Claude متاح عبر Puter لكل خيار في القائمة */
const PUTER_MODEL_MAP={
  "claude-opus-5":"claude-opus-4-1",
  "claude-sonnet-5":"claude-sonnet-4-5",
  "claude-haiku-4-5":"claude-haiku-4-5",
};

/* سجل المحادثة — محلي فقط، بحد أقصى 60 رسالة */
let aiChat = [];
try{ aiChat = JSON.parse(localStorage.getItem("hm-ai-chat")||"[]"); }catch(e){}
function saveChat(){
  aiChat = aiChat.slice(-60);
  try{ localStorage.setItem("hm-ai-chat", JSON.stringify(aiChat)); }catch(e){}
}
function clearChat(){ aiChat=[]; saveChat(); }

/* ============ محرك الرؤى المحلي (بدون إنترنت) ============ */
const PH_RANGE=[6.5,8.5], TDS_RANGE=[50,250];

function computeInsights(){
  const out=[];
  const visits=state.visits.filter(v=>v.dataComplete);
  const now=Date.now();

  // 1) الفروع الأعلى خطورة (وزن المخالفات، مع ترجيح آخر 30 يومًا)
  const byBranch=new Map();
  for(const v of visits){
    const rec = now - v.startedAt < 30*864e5 ? 1.5 : 1;
    const score = ((v.critical??0)*3 + (v.major??0)*2 + (v.minor??0)) * rec;
    const e = byBranch.get(v.branchId) ?? {name:visitName(v), score:0, visits:0, critical:0};
    e.score+=score; e.visits++; e.critical+=(v.critical??0);
    byBranch.set(v.branchId,e);
  }
  const risky=[...byBranch.values()].filter(b=>b.score>0).sort((a,b)=>b.score-a.score).slice(0,3);
  if(risky.length){
    out.push({em:"🚨", icon:"alert", acc:"var(--danger)", title:tx("فروع تحتاج متابعة عاجلة","Branches needing urgent follow-up"),
      body: risky.map(b=>`${b.name} (مؤشر الخطورة ${Math.round(b.score)}${b.critical?` · ${b.critical} Critical`:""})`).join(" · ")});
  }

  // 2) قراءات جودة خارج النطاق
  const badQ=visits.filter(v=>(v.ph!=null&&(v.ph<PH_RANGE[0]||v.ph>PH_RANGE[1]))||(v.tds!=null&&(v.tds<TDS_RANGE[0]||v.tds>TDS_RANGE[1])));
  if(badQ.length){
    const last=badQ.slice(-3).map(v=>`${visitName(v)}${v.ph!=null&&(v.ph<PH_RANGE[0]||v.ph>PH_RANGE[1])?` PH ${v.ph}`:""}${v.tds!=null&&(v.tds<TDS_RANGE[0]||v.tds>TDS_RANGE[1])?` TDS ${v.tds}`:""}`);
    out.push({em:"🧪", icon:"flask", acc:"var(--warn)", title:tx(`${badQ.length} قراءة جودة خارج النطاق الآمن`,`${badQ.length} quality readings outside the safe range`),
      body:tx(`آخرها: ${last.join(" · ")} — النطاق المرجعي PH ${PH_RANGE[0]}–${PH_RANGE[1]} و TDS ${TDS_RANGE[0]}–${TDS_RANGE[1]} ppm`,`Latest: ${last.join(" · ")} — reference range PH ${PH_RANGE[0]}–${PH_RANGE[1]}, TDS ${TDS_RANGE[0]}–${TDS_RANGE[1]} ppm`)});
  }

  // 3) فروع نشطة لم تُزَر منذ مدة طويلة (أو أبدًا)
  const lastVisit=new Map();
  for(const v of state.visits) lastVisit.set(v.branchId, Math.max(lastVisit.get(v.branchId)??0, v.startedAt));
  const activeBr=state.branches.filter(b=>b.active);
  const overdue=activeBr.filter(b=>{const t=lastVisit.get(b.id); return !t || now-t > 21*864e5;});
  if(state.visits.length && overdue.length){
    out.push({em:"⏳", icon:"clock", acc:"var(--accent)", title:tx(`${overdue.length} فرعًا لم يُزَر منذ أكثر من 3 أسابيع`,`${overdue.length} branches not visited in 3+ weeks`),
      body:tx(`منها: ${overdue.slice(0,4).map(b=>b.nameAr).join(" · ")}${overdue.length>4?" وغيرها…":""} — رشّحها لخطة الأسبوع القادم`,`Including: ${overdue.slice(0,4).map(b=>bName(b)).join(" · ")}${overdue.length>4?" and more…":""} — shortlist them for next week`)});
  }

  // 3.5) المهمة الأسبوعية الأكثر مخالفة
  const tAgg=new Map();
  for(const v of visits) for(const t of (v.tasks??[])){
    const e=tAgg.get(t.title)??{C:0,B:0,n:0};
    if(t.grade==="C")e.C++; else if(t.grade==="B")e.B++;
    e.n++; tAgg.set(t.title,e);
  }
  const worst=[...tAgg.entries()].filter(([,e])=>e.C>0).sort((a,b)=>b[1].C-a[1].C)[0];
  if(worst){
    out.push({em:"📋", icon:"x", acc:"var(--danger)", title:tx(`المهمة الأكثر مخالفة: ${worst[0]}`,`Most-violated task: ${worst[0]}`),
      body:tx(`سُجّلت ${worst[1].C} مخالفة (C)${worst[1].B?` و${worst[1].B} تقييم متوسط (B)`:""} من أصل ${worst[1].n} تقييمًا — راجع ملاحظاتها في اللوحة`,`${worst[1].C} non-conforming (C)${worst[1].B?` and ${worst[1].B} average (B)`:""} out of ${worst[1].n} gradings — review its notes in the dashboard`)});
  }

  // 4) تقدم خطة الأسبوع الحالية
  const plan=activePlan();
  if(plan){
    const total=plan.days.reduce((t,d)=>t+d.stops.length,0);
    const done=plan.days.reduce((t,d)=>t+d.stops.filter(s=>{const v=findVisit(plan.id,s.branchId);return v&&v.status!=="open";}).length,0);
    if(total){
      const pct=Math.round(done/total*100);
      out.push({em:"📈", icon: pct>=80?"flag":"trend", acc:"var(--ok)", title:tx(`إنجاز الخطة الحالية ${pct}%`,`Current plan ${pct}% complete`),
        body:tx(`اكتملت ${done} من ${total} زيارة مجدولة${pct<50?" — ركّز على الفروع المتبقية أو أعد توزيعها من وضع التعديل":""}`,`${done} of ${total} scheduled visits done${pct<50?" — focus on the remaining branches or redistribute them in edit mode":""}`)});
    }
  }

  // 5) متوسطات الجودة العامة
  const phs=visits.filter(v=>v.ph!=null), tdss=visits.filter(v=>v.tds!=null);
  if(phs.length>=3){
    const avgPh=(phs.reduce((t,v)=>t+v.ph,0)/phs.length).toFixed(2);
    const avgTds=tdss.length?Math.round(tdss.reduce((t,v)=>t+v.tds,0)/tdss.length):"—";
    out.push({em:"💧", icon:"droplet", acc:"var(--day-0)", title:tx(`متوسط الجودة: PH ${avgPh} · TDS ${avgTds} ppm`,`Quality averages: PH ${avgPh} · TDS ${avgTds} ppm`),
      body:tx(`محسوب من ${phs.length} قراءة موثّقة${(avgPh>=PH_RANGE[0]&&avgPh<=PH_RANGE[1])?" — ضمن النطاق الصحي ✓":" — راجع معايرة أجهزة القياس"}`,`Computed from ${phs.length} documented readings${(avgPh>=PH_RANGE[0]&&avgPh<=PH_RANGE[1])?" — within the healthy range ✓":" — recalibrate your meters"}`)});
  }

  if(!out.length){
    out.push({em:"🌱", icon:"leaf", acc:"var(--ok)", title:tx("لا توجد ملاحظات بعد","No insights yet"),
      body:tx("سجّل زياراتك بنتائج الفحص (Critical/Major/Minor) وقراءات PH وTDS وستظهر هنا رؤى فورية عن أداء الفروع","Log visits with findings (Critical/Major/Minor) and PH/TDS readings and instant insights will appear here")});
  }
  return out;
}

/* ============ بناء سياق التطبيق للنموذج ============ */
function buildAiContext(){
  const plan=activePlan();
  const visits=[...state.visits].sort((a,b)=>b.startedAt-a.startedAt).slice(0,120).map(v=>({
    branch:v.nameAr, date:new Date(v.startedAt).toISOString().slice(0,10),
    day:DAYS_AR[v.dayIndex]??null, minutes:visitElapsedMin(v),
    critical:v.critical, major:v.major, minor:v.minor, ph:v.ph, tds:v.tds,
    status:v.status==="open"?"جارية":(v.dataComplete?"مكتملة":"ناقصة"),
    tasks:(v.tasks&&v.tasks.length)?v.tasks.map(t=>`${t.title}: ${t.grade}${t.note?` (${t.note})`:""}`):undefined,
    notes:v.notes||undefined
  }));
  const regions={};
  for(const b of state.branches){ const k=b.region??"أخرى"; (regions[k]??=[]).push(b.nameAr+(b.active?"":" (معطّل)")); }
  return {
    today:new Date().toISOString().slice(0,10),
    work_hours:`${state.settings.workStartHour}:00-${state.settings.workEndHour}:00`,
    branches_total:state.branches.length,
    branches_active:state.branches.filter(b=>b.active).length,
    branches_by_region:regions,
    weekly_tasks:activeTasks().map(t=>t.title+(t.source==="team"?" (فريق)":"")),
    active_plan: plan ? {
      week:plan.weekLabel,
      days:plan.days.map(d=>({
        day:d.dayNameAr, meeting:d.isMeetingDay||undefined, drive_km:d.totalDriveKm,
        stops:d.stops.map(s=>{
          const v=findVisit(plan.id,s.branchId);
          return {name:s.nameAr, arrive:s.arrivalTime, leave:s.departureTime,
            visited: v ? (v.status==="open"?"جارية":"تمت") : "لم تتم بعد"};
        })
      }))
    } : null,
    visits_log:visits
  };
}

function aiSystemPrompt(){
  return `أنت "مساعد ½M" — مساعد ذكي داخل تطبيق تخطيط زيارات فروع سلسلة قهوة "هاف مليون" في السعودية.
المستخدم مشرف جودة يزور الفروع أسبوعيًا (الأحد–الخميس، يبدأ الأحد باجتماع الفريق)، يسجّل مخالفات الفحص بثلاث درجات (Critical الأخطر، ثم Major، ثم Minor) وقراءات جودة مياه القهوة (PH النطاق الصحي 6.5–8.5، وTDS النطاق 50–250 ppm)، ويقيّم مهامًا أسبوعية بمقياس A (مطابق تمامًا) / B (متوسط أو به ملاحظة) / C (مخالف تمامًا).

مهامك: تحليل بيانات الزيارات والمخالفات، اقتراح أولويات الزيارات، كتابة تقارير أسبوعية تنفيذية، والإجابة عن أي سؤال حول الفروع والخطة.

قواعد:
- ${isEn()?"أجب بالإنجليزية دائمًا (المستخدم اختار واجهة إنجليزية).":"أجب بالعربية الفصحى المبسطة وبإيجاز عملي. الأرقام والأكواد بالإنجليزية."}
- استند حصريًا إلى بيانات التطبيق المرفقة أدناه؛ إن لم تتوفر معلومة فقل ذلك صراحة ولا تخترع أرقامًا.
- عند كتابة تقرير: ابدأ بملخص تنفيذي من سطرين، ثم أبرز الأرقام، ثم الفروع الحرجة، ثم توصيات مرقّمة قابلة للتنفيذ.
- استخدم عناوين قصيرة تبدأ بـ "## " وقوائم تبدأ بـ "- " عند الحاجة، دون جداول.

بيانات التطبيق الحالية (JSON):
${JSON.stringify(buildAiContext())}`;
}

/* ============ عميل الذكاء (متدفق) — يختار المزوّد تلقائيًا ============ */
async function claudeStream(messages, handlers){
  const provider=aiProvider();
  if(provider==="puter") return puterStream(messages, handlers);
  return anthropicStream(provider, messages, handlers);
}

/* مزوّد Puter المجاني — بلا مفتاح API (تسجيل دخول مجاني تلقائي عند أول رسالة) */
async function puterStream(messages, {onDelta, onDone, onError}){
  const ok=await loadPuter();
  if(!ok){ onError?.(tx("تعذّر تحميل مزوّد الذكاء المجاني — تحقق من الإنترنت أو أضف مفتاحك من إعداد الذكاء","Couldn't load the free AI provider — check your connection or add your own key in AI Setup")); return; }
  const msgs=[{role:"system", content:aiSystemPrompt()}, ...messages];
  const model=PUTER_MODEL_MAP[aiConfig().model]||"claude-sonnet-4-5";
  let resp;
  try{
    resp=await puter.ai.chat(msgs,{model, stream:true});
  }catch(e){
    /* النموذج المطلوب غير متاح؟ جرّب النموذج الافتراضي لدى Puter */
    try{ resp=await puter.ai.chat(msgs,{stream:true}); }
    catch(e2){
      const m=String(e2?.message||e2?.error?.message||"");
      onError?.(m.includes("auth")||m.includes("sign")
        ? tx("أكمل تسجيل الدخول المجاني في النافذة المنبثقة ثم أعد الإرسال","Complete the free sign-in in the popup, then resend")
        : tx("تعذّر الاتصال بالمزوّد المجاني — أعد المحاولة أو أضف مفتاحك من إعداد الذكاء","Free provider failed — retry or add your own key in AI Setup"));
      return;
    }
  }
  let full="";
  try{
    for await(const part of resp){
      const t=part?.text ?? "";
      if(t){ full+=t; onDelta?.(t, full); }
    }
  }catch(e){ onError?.(tx("انقطع الاتصال أثناء التوليد — أعد المحاولة","Connection dropped while generating — try again")); return; }
  if(!full){ onError?.(tx("لم يصل رد من المزوّد المجاني — أعد المحاولة","No reply from the free provider — try again")); return; }
  onDone?.(full);
}

/* Anthropic مباشرة (مفتاح المستخدم) أو عبر خادم الشركة الوسيط */
async function anthropicStream(provider, messages, {onDelta, onDone, onError}){
  const cfg=aiConfig();
  const url = provider==="proxy" ? aiProxyUrl() : "https://api.anthropic.com/v1/messages";
  const headers={"content-type":"application/json","anthropic-version":"2023-06-01"};
  if(provider==="key"){
    headers["x-api-key"]=cfg.apiKey;
    headers["anthropic-dangerous-direct-browser-access"]="true";
  }
  let resp;
  try{
    resp = await fetch(url,{
      method:"POST",
      headers,
      body:JSON.stringify({
        model:cfg.model||"claude-opus-5",
        max_tokens:4096,
        stream:true,
        system:[{type:"text", text:aiSystemPrompt(), cache_control:{type:"ephemeral"}}],
        messages
      })
    });
  }catch(e){ onError?.("تعذّر الاتصال بالخادم — تحقق من الإنترنت"); return; }

  if(!resp.ok){
    let msg=`خطأ من الخادم (${resp.status})`;
    try{ const j=await resp.json(); if(j?.error?.message) msg=j.error.message; }catch(e){}
    if(resp.status===401) msg="مفتاح API غير صالح — تحقق منه في إعدادات الذكاء";
    else if(resp.status===429) msg="تجاوزت حد الطلبات مؤقتًا — انتظر دقيقة ثم أعد المحاولة";
    else if(resp.status===529) msg="الخدمة مزدحمة حاليًا — أعد المحاولة بعد قليل";
    onError?.(msg); return;
  }

  const reader=resp.body.getReader();
  const decoder=new TextDecoder();
  let buf="", full="", stopReason=null;
  try{
    while(true){
      const {done,value}=await reader.read();
      if(done) break;
      buf+=decoder.decode(value,{stream:true});
      const lines=buf.split("\n");
      buf=lines.pop();
      for(const line of lines){
        if(!line.startsWith("data:")) continue;
        const data=line.slice(5).trim();
        if(!data || data==="[DONE]") continue;
        let ev; try{ ev=JSON.parse(data); }catch(e){ continue; }
        if(ev.type==="content_block_delta" && ev.delta?.type==="text_delta"){
          full+=ev.delta.text; onDelta?.(ev.delta.text, full);
        } else if(ev.type==="message_delta" && ev.delta?.stop_reason){
          stopReason=ev.delta.stop_reason;
        } else if(ev.type==="error"){
          onError?.(ev.error?.message||"حدث خطأ أثناء التوليد"); return;
        }
      }
    }
  }catch(e){ onError?.("انقطع الاتصال أثناء التوليد — أعد المحاولة"); return; }

  if(stopReason==="refusal"){
    onError?.("اعتذر النموذج عن هذا الطلب — أعد صياغته بشكل مختلف"); return;
  }
  if(stopReason==="max_tokens") full+="\n\n… (اكتمل الحد الأقصى للرد)";
  onDone?.(full);
}

/* اختبار سريع للاتصال بالمفتاح */
async function testAiKey(key, model){
  const r=await fetch("https://api.anthropic.com/v1/messages",{
    method:"POST",
    headers:{
      "content-type":"application/json",
      "x-api-key":key,
      "anthropic-version":"2023-06-01",
      "anthropic-dangerous-direct-browser-access":"true"
    },
    body:JSON.stringify({model:model||"claude-opus-5",max_tokens:16,messages:[{role:"user",content:"قل: جاهز"}]})
  });
  if(!r.ok){
    let msg=`فشل الاختبار (${r.status})`;
    try{ const j=await r.json(); if(j?.error?.message) msg=j.error.message; }catch(e){}
    throw new Error(msg);
  }
  return true;
}

/* أسئلة سريعة جاهزة */
const AI_QUICK=[
  {em:"📄", label:"تقرير أسبوعي تنفيذي",
   prompt:"اكتب تقريرًا أسبوعيًا تنفيذيًا شاملًا عن زيارات هذا الأسبوع: الملخص، الأرقام، الفروع الحرجة، نتائج المهام الأسبوعية، وتوصيات للأسبوع القادم.",
   promptEn:"Write a comprehensive executive weekly report on this week's visits: summary, key numbers, critical branches, weekly task results, and recommendations for next week."},
  {em:"🧭", label:"أولويات الأسبوع القادم",
   prompt:"بناءً على سجل الزيارات والمخالفات، ما الفروع التي يجب أن أضعها في أولوية زيارات الأسبوع القادم؟ رتّبها مع سبب لكل فرع.",
   promptEn:"Based on the visit log and findings, which branches should I prioritize next week? Rank them with a reason for each."},
  {em:"🧪", label:"تحليل قراءات الجودة",
   prompt:"حلّل قراءات PH وTDS المسجلة: هل هناك فروع خارج النطاق الصحي أو اتجاه مقلق؟ وما الإجراء المقترح؟",
   promptEn:"Analyze the recorded PH and TDS readings: any branches outside the healthy range or a worrying trend? What action do you suggest?"},
  {em:"🗓️", label:"لخّص خطة الأسبوع",
   prompt:"لخّص لي خطة الأسبوع الحالية يومًا بيوم مع أي ملاحظات على التوزيع أو أوقات القيادة.",
   promptEn:"Summarize the current weekly plan day by day, with any notes on distribution or driving times."},
];

/* ============ مطابقة أسماء الفروع من الدردشة ============
   يفهم العربية والإنجليزية والكتابة العامية (shobra ≈ Shubra)
   ويصنّف كل اسم إلى: مطابَق / غامض (عدة مرشحين) / غير معروف */

function normTxt(s){
  return String(s).toLowerCase()
    .replace(/[ً-ٰٟـ]/g,"")      // تشكيل وتطويل
    .replace(/[أإآٱ]/g,"ا").replace(/ة/g,"ه")
    .replace(/ى/g,"ي").replace(/ؤ/g,"و").replace(/ئ/g,"ي").replace(/ء/g,"")
    .replace(/[^\p{L}\p{N} ]/gu," ")
    .replace(/\s+/g," ").trim();
}
function stripAl(w){ return w.replace(/^و(?=.{4,})/,"").replace(/^ال/,""); }

function levDist(a,b){
  const m=a.length,n=b.length;
  if(!m) return n; if(!n) return m;
  let prev=Array.from({length:n+1},(_,i)=>i), cur=new Array(n+1);
  for(let i=1;i<=m;i++){
    cur[0]=i;
    for(let j=1;j<=n;j++){
      cur[j]=Math.min(prev[j]+1, cur[j-1]+1, prev[j-1]+(a[i-1]===b[j-1]?0:1));
    }
    [prev,cur]=[cur,prev];
  }
  return prev[n];
}
function wordSim(a,b){
  a=stripAl(a); b=stripAl(b);
  if(!a||!b) return 0;
  if(a===b) return 1;
  const L=Math.max(a.length,b.length);
  let sim=1-levDist(a,b)/L;
  // احتواء جزئي (shob داخل shubra)
  if(a.length>=3&&b.length>=3&&(a.includes(b)||b.includes(a)))
    sim=Math.max(sim, .8 + .18*Math.min(a.length,b.length)/L);
  return sim;
}

/* فهرس كلمات كل فرع (عربي + إنجليزي) */
let _brIdx=null, _brIdxLen=0;
function branchIndex(){
  if(_brIdx && _brIdxLen===state.branches.length) return _brIdx;
  _brIdx=state.branches.map(b=>({
    id:b.id, nameAr:b.nameAr, nameEn:b.nameEn, active:b.active,
    words:[...new Set([...normTxt(b.nameAr).split(" "), ...normTxt(b.nameEn).split(" ")].filter(w=>w.length>=2))],
    full:normTxt(b.nameAr)+" "+normTxt(b.nameEn)
  }));
  _brIdxLen=state.branches.length;
  return _brIdx;
}

/* درجة تطابق اسم مُدخل مع فرع */
function branchScore(tokenWords, entry){
  let sum=0;
  for(const tw of tokenWords){
    let best=0;
    for(const w of entry.words) best=Math.max(best, wordSim(tw,w));
    sum+=best;
  }
  return sum/tokenWords.length;
}

/* تصنيف اسم واحد: match | ambiguous | unknown */
function matchBranchToken(token){
  const t=normTxt(token);
  const tokenWords=t.split(" ").filter(w=>w.length>=2);
  if(!tokenWords.length) return {token, status:"unknown", candidates:[]};
  const scored=branchIndex()
    .map(e=>({id:e.id, name:isEn()?(e.nameEn||e.nameAr):e.nameAr, active:e.active, score:branchScore(tokenWords,e)}))
    .filter(c=>c.score>=0.62)
    .sort((a,b)=>b.score-a.score)
    .slice(0,5);
  if(!scored.length) return {token, status:"unknown", candidates:[]};
  const top=scored[0].score;
  const near=scored.filter(c=>c.score>=top-0.06);
  if(top>=0.8 && near.length===1)
    return {token, status:"match", chosenId:scored[0].id, candidates:scored};
  return {token, status:"ambiguous", candidates:(top>=0.8?near:scored).slice(0,4)};
}

/* تقسيم رسالة إلى أسماء فروع مع إزالة كلمات النية */
const INTENT_RE=/جدول(?:تي|ي|ه|ة)?|خط[هة](?:\s+الاسبوع)?|زيارات(?:ي)?|رت[بّ]|اعمل|انشئ|أنشئ|سو[يّ]|schedule|plan|visits?|make|create|my|table/gi;
function parseBranchList(text){
  let cleaned=text.replace(INTENT_RE," ");
  /* واو العطف الملتصقة: "شبرا والعزيزية وطويق" ← "شبرا ، العزيزية ، طويق"
     (تُشترط 3 أحرف عربية بعد الواو كي لا تنكسر أسماء تبدأ بواو مثل "ووك") */
  cleaned=cleaned.replace(/(^|[\s,،])و(?=[ء-ي]{3,})/g,"$1، ");
  return cleaned.split(/[,\n،;؛]|\s+و\s+|\s+and\s+/i)
    .map(s=>s.replace(/^[\s.:!?…،؛\-–]+|[\s.:!?…،؛\-–]+$/g,""))
    .filter(s=>s && normTxt(s).length>=2);
}
/* تحليل قائمة أدخلها المستخدم صراحةً في «جدولة سريعة» بتبويب الخطة.
   لا تخمين نوايا هنا — كل ما يُكتب يُعامل كأسماء فروع.
   إن كانت القائمة بلا فواصل إطلاقًا (shobra azizyah taif) نجرّب
   الفصل بالمسافات ونعتمد التفسير الذي يطابق فروعًا أكثر. */
function parseScheduleInput(text){
  const tokens=parseBranchList(text);
  let items=tokens.map(matchBranchToken);
  if(tokens.length===1 && /\s/.test(tokens[0]) && items[0].status!=="match"){
    const words=tokens[0].split(/\s+/).filter(w=>normTxt(w).length>=2);
    if(words.length>=2){
      const wi=words.map(matchBranchToken);
      const whit=wi.filter(i=>i.status!=="unknown").length;
      if(whit>=2) items=wi;
    }
  }
  return items;
}

/* تنسيق مبسط لمخرجات النموذج: عناوين وقوائم وعريض */
function mdLite(text){
  let h=esc(text);
  h=h.replace(/^## (.+)$/gm,'<span class="m-h">$1</span>');
  h=h.replace(/^# (.+)$/gm,'<span class="m-h">$1</span>');
  h=h.replace(/\*\*([^*\n]+)\*\*/g,'<b>$1</b>');
  h=h.replace(/^[-•] /gm,'• ');
  h=h.replace(/^\d+\. /gm, m=>m);
  return h;
}
