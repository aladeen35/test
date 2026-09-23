/* فول مارك — اللعب على جهازين (أونلاين / بلوتوث)
   جهاز المضيف هو المرجع: يشغّل محرك اللعبة ويبثّ «لقطة» للحالة 3 مرات في الثانية.
   جهاز اللاعب يعرض اللقطة فقط ويرسل اختياره ووسائل المساعدة. */
'use strict';

const remote = {kind:null, role:null, syncIid:null, lastSnap:'', lastSent:0, savedGame:null, btAddr:null};

/* ================= الردهة ================= */
function openLobby(kind){
  remote.kind = kind; remote.role = null;
  $('lobbyTitle').textContent = kind==='bt' ? 'اللعب عبر البلوتوث' : 'اللعب أونلاين';
  $('lobbySub').textContent = kind==='bt'
    ? 'جهازان قريبان بدون إنترنت — أقرِن الجهازين من إعدادات البلوتوث أولاً'
    : 'جهاز للمضيف (الأسئلة والإجابات والمؤقت) وجهاز للاعب (يختار الإجابة) — من أي مكان';
  $('lobbyName').value = profile.player.name || profile.host.name || '';
  $('lobbyChoose').style.display='block';
  $('lobbyHostPanel').style.display='none';
  $('lobbyJoinPanel').style.display='none';
  showScreen('screen-lobby');
}
function lobbyStatus(id, text, cls){
  const el=$(id); el.textContent=text; el.className='lobby-status'+(cls?' '+cls:'');
}
function lobbyNameOk(){
  const n=$('lobbyName').value.trim();
  if(!n){ $('lobbyName').focus(); toast('اكتب اسمك أولاً'); return null; }
  return n;
}

$('lobbyBackBtn').addEventListener('click', ()=>{ stopSync(); goHome(); });

/* ---------- المضيف ---------- */
$('lobbyHostBtn').addEventListener('click', async ()=>{
  const name=lobbyNameOk(); if(!name) return;
  if(!profile.host.name){ profile.host.name=name; saveProfile(); }
  remote.role='host';
  state.host={name, avatar:profile.host.avatar||0};
  state.player={name:'…', avatar:3};
  $('lobbyChoose').style.display='none';
  $('lobbyHostPanel').style.display='block';
  $('lobbyStartBtn').disabled=true;
  $('roomCode').textContent='';
  lobbyStatus('lobbyHostStatus','جاري التجهيز…');
  const h = hostHandlers();
  try{
    if(remote.kind==='bt'){
      $('lobbyHostHint').textContent='على جهاز اللاعب: اختر «أنا اللاعب» ثم اختر اسم هذا الجوال من قائمة الأجهزة المقترنة.';
      await Net.hostBt(h);
      lobbyStatus('lobbyHostStatus','بانتظار اتصال اللاعب عبر البلوتوث…');
    }else{
      const code = await Net.hostOnline(h);
      $('roomCode').textContent = code;
      $('lobbyHostHint').textContent='شارك هذا الرمز مع اللاعب — يكتبه في جهازه بعد اختيار «أنا اللاعب».';
      lobbyStatus('lobbyHostStatus','الغرفة جاهزة — بانتظار اللاعب…');
    }
  }catch(err){
    lobbyStatus('lobbyHostStatus', err.message||'تعذر بدء الاتصال', 'err');
  }
});

function hostHandlers(){
  return {
    open(){ lobbyStatus('lobbyHostStatus','تم الاتصال ✓ — بانتظار اسم اللاعب…','ok'); },
    message: onHostMessage,
    close(){
      stopSync();
      toast('انقطع الاتصال باللاعب');
      if(state.mode==='remoteHost' && !$('screen-final').classList.contains('active')) goHome();
      else if($('screen-lobby').classList.contains('active')){
        lobbyStatus('lobbyHostStatus','انقطع الاتصال','err'); $('lobbyStartBtn').disabled=true;
      }
    },
    status(s){ toast(s.text); },
  };
}

function onHostMessage(m){
  if(m.t==='hello'){
    state.player={name:String(m.name||'اللاعب').slice(0,20), avatar:(m.avatar|0)%AVATARS.length};
    lobbyStatus('lobbyHostStatus','متصل مع '+state.player.name+' ✓','ok');
    $('lobbyStartBtn').disabled=false;
    if(state.mode==='remoteHost') renderHud();
    return;
  }
  if(state.mode!=='remoteHost') return;
  const onPlay = $('screen-play').classList.contains('active');
  if(m.t==='answer' && onPlay){
    const i=m.i|0;
    const btn=document.querySelector('#choices .choice[data-idx="'+i+'"]');
    if(!state.timerStarted || state.answered || !btn || btn.classList.contains('eliminated')) return;
    if($('callModal').classList.contains('show') || $('aiModal').classList.contains('show')) return;
    btn.classList.add('remote-picked');
    answer(i);
  }
  else if(m.t==='ll' && onPlay){
    const allowed = state.level==='medium' ? ['jet'] : state.level==='hard' ? ['fifty','call','swap','ai'] : [];
    if(allowed.includes(m.k)) useLifeline(m.k);
  }
  else if(m.t==='aiDone' && $('aiModal').classList.contains('show')) $('aiDoneBtn').click();
  sendSnap(true);
}

$('lobbyStartBtn').addEventListener('click', ()=>{
  if(!Net.connected()){ toast('لا يوجد لاعب متصل'); return; }
  state.mode='remoteHost';
  startGame();
  startSync();
});

/* ---------- اللاعب ---------- */
$('lobbyJoinBtn').addEventListener('click', async ()=>{
  const name=lobbyNameOk(); if(!name) return;
  if(!profile.player.name){ profile.player.name=name; saveProfile(); }
  remote.role='player'; remote.myName=name;
  $('lobbyChoose').style.display='none';
  $('lobbyJoinPanel').style.display='block';
  lobbyStatus('lobbyJoinStatus','');
  const isBt = remote.kind==='bt';
  $('joinCodeField').style.display = isBt ? 'none' : '';
  $('btDeviceList').style.display = isBt ? 'flex' : 'none';
  if(isBt){
    remote.btAddr=null;
    $('btDeviceList').innerHTML='';
    lobbyStatus('lobbyJoinStatus','جاري قراءة الأجهزة المقترنة…');
    try{
      const devs = await Net.listBt();
      if(!devs.length){ lobbyStatus('lobbyJoinStatus','لا توجد أجهزة مقترنة — أقرِن جوال المضيف من إعدادات البلوتوث','err'); return; }
      lobbyStatus('lobbyJoinStatus','اختر جوال المضيف:');
      devs.forEach(d=>{
        const b=document.createElement('button');
        b.type='button'; b.className='bt-dev'; b.setAttribute('aria-pressed','false');
        const nm=document.createElement('span'); nm.textContent=d.name||'جهاز';
        const ad=document.createElement('small'); ad.textContent=d.address;
        b.append(nm, ad);
        b.addEventListener('click', ()=>{
          remote.btAddr=d.address;
          $('btDeviceList').querySelectorAll('.bt-dev').forEach(x=>x.setAttribute('aria-pressed', String(x===b)));
        });
        $('btDeviceList').appendChild(b);
      });
    }catch(err){ lobbyStatus('lobbyJoinStatus', err.message, 'err'); }
  }else{
    $('joinCode').value=''; $('joinCode').focus();
  }
});

$('joinGoBtn').addEventListener('click', async ()=>{
  const h = playerHandlers();
  $('joinGoBtn').disabled=true;
  try{
    if(remote.kind==='bt'){
      if(!remote.btAddr){ toast('اختر جوال المضيف من القائمة'); return; }
      lobbyStatus('lobbyJoinStatus','جاري الاتصال عبر البلوتوث…');
      await Net.joinBt(remote.btAddr, h);
    }else{
      const code=$('joinCode').value.replace(/\D/g,'');
      $('joinCodeField').classList.toggle('invalid', code.length<5);
      if(code.length<5) return;
      lobbyStatus('lobbyJoinStatus','جاري الاتصال بالغرفة '+code+'…');
      await Net.joinOnline(code, h);
    }
  }catch(err){
    lobbyStatus('lobbyJoinStatus', err.message||'تعذر الاتصال', 'err');
  }finally{ $('joinGoBtn').disabled=false; }
});

function playerHandlers(){
  return {
    open(){
      Net.send({t:'hello', name:remote.myName, avatar:profile.player.avatar||0});
      remote.savedGame=null;
      rmState.qKey=null;
      $('rmWaitTitle').textContent='متصل ✓ بانتظار المضيف…';
      $('rmWaitDesc').textContent='سيبدأ المضيف الجولة من جهازه.';
      showRemoteSection('rmWait');
      showScreen('screen-remote');
    },
    message(m){
      if(m.t==='snap') renderRemote(m.s);
      else if(m.t==='busy'){ toast('الغرفة مشغولة بلاعب آخر'); goHome(); }
    },
    close(){ toast('انقطع الاتصال بالمضيف'); goHome(); },
    status(s){ toast(s.text); },
  };
}
$('rmLeaveBtn').addEventListener('click', ()=>goHome());

/* ================= بثّ اللقطات (المضيف) ================= */
function startSync(){
  stopSync();
  remote.lastSnap='';
  remote.syncIid=setInterval(()=>sendSnap(false), 300);
}
function stopSync(){ clearInterval(remote.syncIid); remote.syncIid=null; }

function sendSnap(force){
  if(!Net.connected() || state.mode!=='remoteHost') return;
  const s=buildSnap();
  const json=JSON.stringify(s);
  const now=Date.now();
  if(!force && json===remote.lastSnap && now-remote.lastSent<3000) return;
  remote.lastSnap=json; remote.lastSent=now;
  Net.send({t:'snap', s});
}

function buildSnap(){
  const active=document.querySelector('.screen.active');
  const scr = active ? active.id : '';
  const s={host:state.host.name, hostAv:state.host.avatar, score:totalScore(), gid:state.gameId};
  if(scr==='screen-level'){
    s.ph='intro';
    s.title=$('levelTitle').textContent; s.desc=$('levelDesc').textContent; s.color=$('levelTitle').style.color;
  }else if(scr==='screen-play'){
    const L=LEVELS[state.level], item=state.questions[state.level][state.qIndex];
    const btns=[...document.querySelectorAll('#choices .choice')];
    const callOpen=$('callModal').classList.contains('show'), aiOpen=$('aiModal').classList.contains('show');
    const list = state.level==='medium' ? ['jet'] : state.level==='hard' ? ['fifty','call','swap','ai'] : [];
    s.ph='q';
    s.level=state.level; s.lvlName=L.name+' — '+L.per+' نقاط';
    s.num=$('qNum').textContent; s.text=item.q; s.choices=item.c;
    s.elim=btns.map((b,i)=>b.classList.contains('eliminated')?i:-1).filter(i=>i>=0);
    s.started=state.timerStarted; s.answered=state.answered;
    s.can=state.timerStarted && !state.answered && !callOpen && !aiOpen;
    s.left=timer.left; s.total=timer.total; s.paused=$('timerPausedNote').classList.contains('show');
    s.correct=state.answered ? item.a : null;
    s.chosen=btns.findIndex(b=>b.classList.contains('wrong'));
    s.verdict=state.answered ? {cls:$('verdict').className, text:$('verdict').textContent.trim()} : null;
    s.dots=state.results; s.count=L.count; s.qi=state.qIndex;
    s.ll=list.map(k=>({k, label:LL_DEFS[k].label, used:!!state.lifelines[k],
      on:!state.lifelines[k] && !state.answered && state.timerStarted}));
    s.hint = aiOpen ? $('aiHintText').textContent : null;
    s.call = callOpen ? $('callTimer').textContent : null;
  }else if(scr==='screen-bonus'){
    s.ph='bonus';
    s.text=$('bonusQText').textContent; s.left=bonus.left; s.running=bonus.running;
    s.progress=$('bonusProgress').textContent; s.correct=bonus.correct;
  }else if(scr==='screen-final'){
    s.ph='final';
    s.scores=state.scores; s.total=totalScore(); s.label=$('medalLabel').textContent; s.player=state.player.name;
  }else{
    s.ph='wait';
  }
  return s;
}

/* ================= العرض على جهاز اللاعب ================= */
const rmState={qKey:null};
const RM_SECTIONS=['rmWait','rmQuestion','rmBonus','rmFinal'];
function showRemoteSection(id){ RM_SECTIONS.forEach(x=>$(x).style.display = x===id ? 'block' : 'none'); }
$('rmTimerArc').style.strokeDasharray = ARC_LEN;

function renderRemote(s){
  if(!$('screen-remote').classList.contains('active')) showScreen('screen-remote');
  $('rmHostName').textContent=s.host;
  $('rmHostAvatar').innerHTML=AVATARS[(s.hostAv|0)%AVATARS.length].svg;
  $('rmScore').textContent=s.score;
  const tag=$('rmLevelTag');

  if(s.ph==='intro' || s.ph==='wait'){
    showRemoteSection('rmWait');
    tag.className='level-tag'; $('rmLevelName').textContent='متصل';
    $('rmWaitTitle').textContent = s.ph==='intro' ? s.title : 'بانتظار المضيف…';
    $('rmWaitTitle').style.color = s.ph==='intro' ? s.color : '';
    $('rmWaitDesc').textContent = s.ph==='intro' ? s.desc : 'سيبدأ المضيف الجولة من جهازه.';
    return;
  }

  if(s.ph==='q'){
    showRemoteSection('rmQuestion');
    tag.className='level-tag '+LEVELS[s.level].tone; $('rmLevelName').textContent=s.lvlName;
    // النقاط
    const dots=$('rmDots'); dots.innerHTML='';
    for(let i=0;i<s.count;i++){
      const d=document.createElement('span');
      d.className='pd'+(i===s.qi?' current':'')+(s.dots[i]==='good'?' done-good':s.dots[i]==='bad'?' done-bad':'');
      dots.appendChild(d);
    }
    // المؤقت
    $('rmTimerNum').textContent = s.started||s.answered ? Math.max(0,s.left) : s.total;
    const frac = s.total ? (s.started||s.answered ? s.left : s.total)/s.total : 1;
    $('rmTimerArc').style.strokeDashoffset = ARC_LEN*(1-Math.max(0,frac));
    $('rmTimerRing').classList.toggle('warn', s.started && !s.answered && s.left<=5 && s.left>0);
    $('rmPaused').classList.toggle('show', !!s.paused);
    // التعليمات
    $('rmInstructionText').textContent =
      s.call ? '📞 مكالمة صديق جارية — '+s.call+' ثانية' :
      s.answered ? 'انتظر المضيف للانتقال للسؤال التالي' :
      s.can ? 'اختر إجابتك الآن!' :
      'المضيف يقرأ السؤال… انتظر بدء المؤقت';
    $('rmQNum').textContent=s.num;
    $('rmQText').textContent=s.text;
    // الخيارات — تُبنى مرة لكل سؤال وتُحدّث حالتها مع كل لقطة
    const key=s.gid+'|'+s.level+'|'+s.qi+'|'+s.text;
    const wrap=$('rmChoices');
    if(rmState.qKey!==key){
      rmState.qKey=key; rmState.picked=-1;
      wrap.innerHTML='';
      const keys=['أ','ب','ج','د'];
      s.choices.forEach((txt,i)=>{
        const b=document.createElement('button');
        b.type='button'; b.className='choice'; b.dataset.idx=i;
        const k=document.createElement('span'); k.className='key'; k.textContent=keys[i];
        const t=document.createElement('span'); t.textContent=txt;
        b.append(k,t);
        b.addEventListener('click', ()=>{
          if(b.disabled) return;
          rmState.picked=i;
          wrap.querySelectorAll('.choice').forEach(x=>x.disabled=true);
          b.classList.add('remote-picked');
          Net.send({t:'answer', i});
        });
        wrap.appendChild(b);
      });
    }
    [...wrap.children].forEach((b,i)=>{
      const elim=s.elim.includes(i);
      b.classList.toggle('eliminated', elim);
      b.classList.toggle('correct', s.correct===i);
      b.classList.toggle('wrong', s.chosen===i);
      b.classList.toggle('remote-picked', rmState.picked===i && !s.answered);
      b.classList.toggle('locked', !s.can && !s.answered);
      b.disabled = !s.can || elim || rmState.picked>=0;
    });
    // الحكم
    const v=$('rmVerdict');
    if(s.verdict){ v.className=s.verdict.cls; v.textContent=s.verdict.text; }
    else { v.className='verdict'; v.textContent=''; }
    // التلميح
    $('rmHint').style.display = s.hint ? 'block' : 'none';
    if(s.hint){
      $('rmHintText').textContent=s.hint;
      if(!$('rmHintDone')){
        const b=document.createElement('button');
        b.id='rmHintDone'; b.type='button'; b.className='btn btn-primary btn-block'; b.style.marginTop='12px';
        b.textContent='فهمت — استئناف المؤقت';
        b.addEventListener('click', ()=>Net.send({t:'aiDone'}));
        $('rmHint').appendChild(b);
      }
    }
    // وسائل المساعدة
    $('rmLifelinesWrap').style.display = s.ll.length ? 'block' : 'none';
    const row=$('rmLifelines'); row.innerHTML='';
    s.ll.forEach(l=>{
      const d=LL_DEFS[l.k];
      const b=document.createElement('button');
      b.type='button'; b.className='ll-btn '+d.cls+(l.used?' used':'');
      b.innerHTML=d.icon+'<span></span>'; b.lastChild.textContent=l.label;
      b.disabled=!l.on || !!s.hint || !!s.call;
      b.addEventListener('click', ()=>{ b.disabled=true; Net.send({t:'ll', k:l.k}); });
      row.appendChild(b);
    });
    return;
  }

  if(s.ph==='bonus'){
    showRemoteSection('rmBonus');
    tag.className='level-tag'; $('rmLevelName').textContent='بونص السرعة ⚡';
    $('rmBonusTimer').textContent=s.left;
    $('rmBonusTimer').classList.toggle('warn', s.running && s.left<=10);
    $('rmBonusProgress').textContent=s.progress;
    $('rmBonusQ').textContent=s.text;
    $('rmBonusLive').textContent = s.running ? 'أجب بصوتك — رصيدك: '+s.correct+' / '+BONUS_COUNT : '';
    return;
  }

  if(s.ph==='final'){
    showRemoteSection('rmFinal');
    tag.className='level-tag'; $('rmLevelName').textContent='انتهت الجولة';
    const rows=[['easy','المستوى السهل',15],['medium','المستوى المتوسط',25],['bonus','فقرة البونص',10],['hard','المستوى الصعب',50]];
    const box=$('rmFinalRows'); box.innerHTML='';
    rows.forEach(([k,label,max])=>{
      const r=document.createElement('div'); r.className='score-row '+k;
      r.innerHTML='<span class="sr-name"><span class="sdot"></span></span><span class="sr-bar"><span class="sr-fill"></span></span><span class="sr-val"></span>';
      r.querySelector('.sr-name').append(label);
      r.querySelector('.sr-fill').style.width=(s.scores[k]/max*100)+'%';
      r.querySelector('.sr-val').textContent=s.scores[k]+' / '+max;
      box.appendChild(r);
    });
    $('rmFinalTotal').textContent=s.total;
    $('rmFinalLabel').textContent=s.label;
    // حفظ النتيجة في سجل جهاز اللاعب أيضاً (مرة واحدة لكل جولة)
    if(remote.savedGame!==s.gid){
      remote.savedGame=s.gid;
      addRecord({t:Date.now(), player:s.player||remote.myName, host:s.host, mode:'remotePlayer',
        easy:s.scores.easy, medium:s.scores.medium, bonus:s.scores.bonus, hard:s.scores.hard, total:s.total});
      sfx.fanfare();
    }
  }
}

/* ================= تهيئة الشاشة الرئيسية ================= */
if(!Net.btAvailable()){
  const b=document.querySelector('#modeGrid .mode-btn[data-mode="bt"]');
  b.disabled=true;
  $('btModeNote').textContent='متاح في تطبيق APK';
}
selectMode(chosenMode);
