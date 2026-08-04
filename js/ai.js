/* ============================================================
   هاف مليون ½M — طبقة الذكاء الاصطناعي
   1) محرك رؤى محلي يعمل دون اتصال
   2) عميل Claude API (مباشر من المتصفح) للمساعد والتقارير
   ============================================================ */

/* ============ إعدادات الذكاء ============
   تُخزَّن محليًا فقط (hm-ai) ولا تُرفع أبدًا للمزامنة السحابية
   حفاظًا على سرية مفتاح API. */
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
function aiReady(){ return !!aiConfig().apiKey; }

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
    const e = byBranch.get(v.branchId) ?? {name:v.nameAr, score:0, visits:0, critical:0};
    e.score+=score; e.visits++; e.critical+=(v.critical??0);
    byBranch.set(v.branchId,e);
  }
  const risky=[...byBranch.values()].filter(b=>b.score>0).sort((a,b)=>b.score-a.score).slice(0,3);
  if(risky.length){
    out.push({em:"🚨", acc:"var(--danger)", title:"فروع تحتاج متابعة عاجلة",
      body: risky.map(b=>`${b.name} (مؤشر الخطورة ${Math.round(b.score)}${b.critical?` · ${b.critical} Critical`:""})`).join(" · ")});
  }

  // 2) قراءات جودة خارج النطاق
  const badQ=visits.filter(v=>(v.ph!=null&&(v.ph<PH_RANGE[0]||v.ph>PH_RANGE[1]))||(v.tds!=null&&(v.tds<TDS_RANGE[0]||v.tds>TDS_RANGE[1])));
  if(badQ.length){
    const last=badQ.slice(-3).map(v=>`${v.nameAr}${v.ph!=null&&(v.ph<PH_RANGE[0]||v.ph>PH_RANGE[1])?` PH ${v.ph}`:""}${v.tds!=null&&(v.tds<TDS_RANGE[0]||v.tds>TDS_RANGE[1])?` TDS ${v.tds}`:""}`);
    out.push({em:"🧪", acc:"var(--warn)", title:`${badQ.length} قراءة جودة خارج النطاق الآمن`,
      body:`آخرها: ${last.join(" · ")} — النطاق المرجعي PH ${PH_RANGE[0]}–${PH_RANGE[1]} و TDS ${TDS_RANGE[0]}–${TDS_RANGE[1]} ppm`});
  }

  // 3) فروع نشطة لم تُزَر منذ مدة طويلة (أو أبدًا)
  const lastVisit=new Map();
  for(const v of state.visits) lastVisit.set(v.branchId, Math.max(lastVisit.get(v.branchId)??0, v.startedAt));
  const activeBr=state.branches.filter(b=>b.active);
  const overdue=activeBr.filter(b=>{const t=lastVisit.get(b.id); return !t || now-t > 21*864e5;});
  if(state.visits.length && overdue.length){
    out.push({em:"⏳", acc:"var(--accent)", title:`${overdue.length} فرعًا لم يُزَر منذ أكثر من 3 أسابيع`,
      body:`منها: ${overdue.slice(0,4).map(b=>b.nameAr).join(" · ")}${overdue.length>4?" وغيرها…":""} — رشّحها لخطة الأسبوع القادم`});
  }

  // 4) تقدم خطة الأسبوع الحالية
  const plan=activePlan();
  if(plan){
    const total=plan.days.reduce((t,d)=>t+d.stops.length,0);
    const done=plan.days.reduce((t,d)=>t+d.stops.filter(s=>{const v=findVisit(plan.id,s.branchId);return v&&v.status!=="open";}).length,0);
    if(total){
      const pct=Math.round(done/total*100);
      out.push({em: pct>=80?"🏁":"📈", acc:"var(--ok)", title:`إنجاز الخطة الحالية ${pct}%`,
        body:`اكتملت ${done} من ${total} زيارة مجدولة${pct<50?" — ركّز على الفروع المتبقية أو أعد توزيعها من وضع التعديل":""}`});
    }
  }

  // 5) متوسطات الجودة العامة
  const phs=visits.filter(v=>v.ph!=null), tdss=visits.filter(v=>v.tds!=null);
  if(phs.length>=3){
    const avgPh=(phs.reduce((t,v)=>t+v.ph,0)/phs.length).toFixed(2);
    const avgTds=tdss.length?Math.round(tdss.reduce((t,v)=>t+v.tds,0)/tdss.length):"—";
    out.push({em:"💧", acc:"var(--day-0)", title:`متوسط الجودة: PH ${avgPh} · TDS ${avgTds} ppm`,
      body:`محسوب من ${phs.length} قراءة موثّقة${(avgPh>=PH_RANGE[0]&&avgPh<=PH_RANGE[1])?" — ضمن النطاق الصحي ✓":" — راجع معايرة أجهزة القياس"}`});
  }

  if(!out.length){
    out.push({em:"🌱", acc:"var(--ok)", title:"لا توجد ملاحظات بعد",
      body:"سجّل زياراتك بنتائج الفحص (Critical/Major/Minor) وقراءات PH وTDS وستظهر هنا رؤى فورية عن أداء الفروع"});
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
المستخدم مشرف جودة يزور الفروع أسبوعيًا (الأحد–الخميس، يبدأ الأحد باجتماع الفريق)، يسجّل مخالفات الفحص بثلاث درجات (Critical الأخطر، ثم Major، ثم Minor) وقراءات جودة مياه القهوة (PH النطاق الصحي 6.5–8.5، وTDS النطاق 50–250 ppm).

مهامك: تحليل بيانات الزيارات والمخالفات، اقتراح أولويات الزيارات، كتابة تقارير أسبوعية تنفيذية، والإجابة عن أي سؤال حول الفروع والخطة.

قواعد:
- أجب بالعربية الفصحى المبسطة وبإيجاز عملي. الأرقام والأكواد بالإنجليزية.
- استند حصريًا إلى بيانات التطبيق المرفقة أدناه؛ إن لم تتوفر معلومة فقل ذلك صراحة ولا تخترع أرقامًا.
- عند كتابة تقرير: ابدأ بملخص تنفيذي من سطرين، ثم أبرز الأرقام، ثم الفروع الحرجة، ثم توصيات مرقّمة قابلة للتنفيذ.
- استخدم عناوين قصيرة تبدأ بـ "## " وقوائم تبدأ بـ "- " عند الحاجة، دون جداول.

بيانات التطبيق الحالية (JSON):
${JSON.stringify(buildAiContext())}`;
}

/* ============ عميل Claude API (متدفق) ============ */
async function claudeStream(messages, {onDelta, onDone, onError}){
  const cfg=aiConfig();
  if(!cfg.apiKey){ onError?.("أضف مفتاح Anthropic API أولاً من إعدادات الذكاء"); return; }
  let resp;
  try{
    resp = await fetch("https://api.anthropic.com/v1/messages",{
      method:"POST",
      headers:{
        "content-type":"application/json",
        "x-api-key":cfg.apiKey,
        "anthropic-version":"2023-06-01",
        "anthropic-dangerous-direct-browser-access":"true"
      },
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
  {em:"📄", label:"تقرير أسبوعي تنفيذي", prompt:"اكتب تقريرًا أسبوعيًا تنفيذيًا شاملًا عن زيارات هذا الأسبوع: الملخص، الأرقام، الفروع الحرجة، وتوصيات للأسبوع القادم."},
  {em:"🧭", label:"أولويات الأسبوع القادم", prompt:"بناءً على سجل الزيارات والمخالفات، ما الفروع التي يجب أن أضعها في أولوية زيارات الأسبوع القادم؟ رتّبها مع سبب لكل فرع."},
  {em:"🧪", label:"تحليل قراءات الجودة", prompt:"حلّل قراءات PH وTDS المسجلة: هل هناك فروع خارج النطاق الصحي أو اتجاه مقلق؟ وما الإجراء المقترح؟"},
  {em:"🗓️", label:"لخّص خطة الأسبوع", prompt:"لخّص لي خطة الأسبوع الحالية يومًا بيوم مع أي ملاحظات على التوزيع أو أوقات القيادة."},
];

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
