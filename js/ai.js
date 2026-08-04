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
    out.push({em:"🚨", icon:"alert", acc:"var(--danger)", title:"فروع تحتاج متابعة عاجلة",
      body: risky.map(b=>`${b.name} (مؤشر الخطورة ${Math.round(b.score)}${b.critical?` · ${b.critical} Critical`:""})`).join(" · ")});
  }

  // 2) قراءات جودة خارج النطاق
  const badQ=visits.filter(v=>(v.ph!=null&&(v.ph<PH_RANGE[0]||v.ph>PH_RANGE[1]))||(v.tds!=null&&(v.tds<TDS_RANGE[0]||v.tds>TDS_RANGE[1])));
  if(badQ.length){
    const last=badQ.slice(-3).map(v=>`${v.nameAr}${v.ph!=null&&(v.ph<PH_RANGE[0]||v.ph>PH_RANGE[1])?` PH ${v.ph}`:""}${v.tds!=null&&(v.tds<TDS_RANGE[0]||v.tds>TDS_RANGE[1])?` TDS ${v.tds}`:""}`);
    out.push({em:"🧪", icon:"flask", acc:"var(--warn)", title:`${badQ.length} قراءة جودة خارج النطاق الآمن`,
      body:`آخرها: ${last.join(" · ")} — النطاق المرجعي PH ${PH_RANGE[0]}–${PH_RANGE[1]} و TDS ${TDS_RANGE[0]}–${TDS_RANGE[1]} ppm`});
  }

  // 3) فروع نشطة لم تُزَر منذ مدة طويلة (أو أبدًا)
  const lastVisit=new Map();
  for(const v of state.visits) lastVisit.set(v.branchId, Math.max(lastVisit.get(v.branchId)??0, v.startedAt));
  const activeBr=state.branches.filter(b=>b.active);
  const overdue=activeBr.filter(b=>{const t=lastVisit.get(b.id); return !t || now-t > 21*864e5;});
  if(state.visits.length && overdue.length){
    out.push({em:"⏳", icon:"clock", acc:"var(--accent)", title:`${overdue.length} فرعًا لم يُزَر منذ أكثر من 3 أسابيع`,
      body:`منها: ${overdue.slice(0,4).map(b=>b.nameAr).join(" · ")}${overdue.length>4?" وغيرها…":""} — رشّحها لخطة الأسبوع القادم`});
  }

  // 4) تقدم خطة الأسبوع الحالية
  const plan=activePlan();
  if(plan){
    const total=plan.days.reduce((t,d)=>t+d.stops.length,0);
    const done=plan.days.reduce((t,d)=>t+d.stops.filter(s=>{const v=findVisit(plan.id,s.branchId);return v&&v.status!=="open";}).length,0);
    if(total){
      const pct=Math.round(done/total*100);
      out.push({em:"📈", icon: pct>=80?"flag":"trend", acc:"var(--ok)", title:`إنجاز الخطة الحالية ${pct}%`,
        body:`اكتملت ${done} من ${total} زيارة مجدولة${pct<50?" — ركّز على الفروع المتبقية أو أعد توزيعها من وضع التعديل":""}`});
    }
  }

  // 5) متوسطات الجودة العامة
  const phs=visits.filter(v=>v.ph!=null), tdss=visits.filter(v=>v.tds!=null);
  if(phs.length>=3){
    const avgPh=(phs.reduce((t,v)=>t+v.ph,0)/phs.length).toFixed(2);
    const avgTds=tdss.length?Math.round(tdss.reduce((t,v)=>t+v.tds,0)/tdss.length):"—";
    out.push({em:"💧", icon:"droplet", acc:"var(--day-0)", title:`متوسط الجودة: PH ${avgPh} · TDS ${avgTds} ppm`,
      body:`محسوب من ${phs.length} قراءة موثّقة${(avgPh>=PH_RANGE[0]&&avgPh<=PH_RANGE[1])?" — ضمن النطاق الصحي ✓":" — راجع معايرة أجهزة القياس"}`});
  }

  if(!out.length){
    out.push({em:"🌱", icon:"leaf", acc:"var(--ok)", title:"لا توجد ملاحظات بعد",
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
function stripAl(w){ return w.replace(/^ال/,""); }

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
    id:b.id, nameAr:b.nameAr, active:b.active,
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
    .map(e=>({id:e.id, name:e.nameAr, active:e.active, score:branchScore(tokenWords,e)}))
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
  const cleaned=text.replace(INTENT_RE," ");
  return cleaned.split(/[,\n،;؛]|\s+و\s+|\s+and\s+/i)
    .map(s=>s.replace(/^[\s.:!?…،؛\-–]+|[\s.:!?…،؛\-–]+$/g,""))
    .filter(s=>s && normTxt(s).length>=2);
}
function hasScheduleKeyword(text){ INTENT_RE.lastIndex=0; return INTENT_RE.test(text); }

/* هل هذه الرسالة طلب جدولة بقائمة فروع؟ */
function detectScheduleIntent(text){
  const tokens=parseBranchList(text);
  if(!tokens.length || tokens.length>40) return null;
  const items=tokens.map(matchBranchToken);
  const hit=items.filter(i=>i.status!=="unknown").length;
  const kw=hasScheduleKeyword(text);
  if((kw && hit>=1) || (tokens.length>=2 && hit>=Math.ceil(tokens.length*0.5)))
    return items;
  return null;
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
