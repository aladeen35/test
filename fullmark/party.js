/* فول مارك — غرفة العائلة أونلاين
   عدة لاعبين في غرفة واحدة، كلٌّ يجيب من جواله على السؤال نفسه في اللحظة نفسها.
   جهاز المضيف هو المرجع: يقرأ السؤال، يبدأ المؤقت، ويرسل لكل لاعب لقطة خاصة به.
   النقاط: نقاط المستوى كالمعتاد + نقاط السرعة (والأسرع في الإجابة الصحيحة يأخذ +2). */
'use strict';

const PARTY_STAGES = ['easy','medium','bonus','hard'];
const P = {
  on:false, phase:'lobby', players:new Map(), stage:-1, qi:0, qs:{},
  left:0, total:0, tStart:0, iid:null, started:false, revealed:false, fastest:null,
  bonus:{idx:0, left:BONUS_TIME, running:false, buzzed:null, locked:new Set(), iid:null},
  syncIid:null, last:new Map(),
};

/* ================= المضيف ================= */
const Party = {};
Party.hostStart = async function(hostName){
  P.on=true; P.phase='lobby'; P.players.clear(); P.last.clear();
  state.host={name:hostName, avatar:profile.host.avatar||0};
  $('joinedList').innerHTML='';
  lobbyStatus('lobbyHostStatus','جاري التجهيز…');
  try{
    const code = await Net.hostRoom({
      join(id){ /* ننتظر رسالة hello بالاسم */ },
      message(m, id){ onPartyMessage(m, id); },
      leave(id){
        const p=P.players.get(id); if(!p) return;
        p.gone=true; toast('غادر '+p.name+' الغرفة');
        renderJoined(); if(P.phase!=='lobby') maybeEndQuestion();
      },
    });
    $('roomCode').textContent=code;
    $('lobbyHostHint').textContent='كل فرد يفتح «غرفة العائلة» على جواله، يختار «أنا اللاعب» ويكتب هذا الرمز (حتى 8 لاعبين).';
    lobbyStatus('lobbyHostStatus','الغرفة جاهزة — بانتظار اللاعبين…');
  }catch(err){ lobbyStatus('lobbyHostStatus', err.message||'تعذر إنشاء الغرفة', 'err'); }
};
Party.attachTest = function(id, t){ Net.roomAttach(id, t); };

function activePlayers(){ return [...P.players.entries()].filter(([,p])=>!p.gone); }
function renderJoined(){
  const box=$('joinedList'); box.innerHTML='';
  activePlayers().forEach(([,p])=>{
    const c=document.createElement('span'); c.className='pl-chip player-chip';
    c.innerHTML='<span class="avatar">'+AVATARS[p.avatar].svg+'</span>'; c.append(p.name);
    box.appendChild(c);
  });
  const n=activePlayers().length;
  if(P.phase==='lobby'){
    $('lobbyStartBtn').disabled = n<1;
    lobbyStatus('lobbyHostStatus', n ? ('في الغرفة: '+n+' '+(n===1?'لاعب':'لاعبين')+' ✓') : 'بانتظار اللاعبين…', n?'ok':'');
  }
  $('phCount').textContent='👥 '+n;
}

function onPartyMessage(m, id){
  if(m.t==='hello'){
    if(P.phase!=='lobby' && !P.players.has(id)){ Net.sendTo(id,{t:'busy'}); return; }
    const name=String(m.name||'لاعب').slice(0,20);
    P.players.set(id, {name, avatar:(m.avatar|0)%AVATARS.length, score:{easy:0,medium:0,bonus:0,hard:0}, speed:0,
      ll:{jet:false, fifty:false}, ans:null, elim:[], gone:false, saved:false});
    renderJoined(); partySync(true); return;
  }
  const p=P.players.get(id); if(!p) return;
  if(m.t==='pans' && P.phase==='q' && P.started && !P.revealed && p.ans===null){
    const i=m.i|0; if(p.elim.includes(i)) return;
    p.ans={i, at:Date.now()};
    renderHostQ(); maybeEndQuestion();
  }else if(m.t==='pll' && P.phase==='q' && P.started && !P.revealed && p.ans===null){
    const lvl=PARTY_STAGES[P.stage];
    if(m.k==='fifty' && lvl==='hard' && !p.ll.fifty){
      p.ll.fifty=true;
      const it=curQ(); p.elim=shuffle([0,1,2,3].filter(i=>i!==it.a)).slice(0,2);
    }else if(m.k==='jet' && lvl==='medium' && !p.ll.jet){
      p.ll.jet=true; p.ans={i:curQ().a, at:null, jet:true};
      renderHostQ(); maybeEndQuestion();
    }
  }else if(m.t==='buzz' && P.phase==='bonus' && P.bonus.running && !P.bonus.buzzed && !P.bonus.locked.has(id)){
    P.bonus.buzzed=id; sfx.buzz(); vibrate(40); renderHostBonus();
  }
  partySync(true);
}

$('lobbyStartBtn').addEventListener('click', e=>{
  if(!P.on) return;
  e.stopImmediatePropagation();
  if(!activePlayers().length){ toast('لا يوجد لاعبون في الغرفة'); return; }
  state.mode='party';
  P.qs={easy:draw('easy',5).map(prepMcq), medium:draw('medium',5).map(prepMcq), hard:draw('hard',5).map(prepMcq), bonus:draw('bonus',BONUS_COUNT)};
  P.stage=-1; P.gameId=Date.now();
  nextStage();
  showScreen('screen-partyhost');
  clearInterval(P.syncIid); P.syncIid=setInterval(()=>partySync(false), 300);
}, true);

function curQ(){ return P.qs[PARTY_STAGES[P.stage]][P.qi]; }
function phShow(id){ ['phIntro','phQ','phBonus'].forEach(x=>$(x).style.display = x===id?'block':'none'); }

function nextStage(){
  P.stage++; P.qi=0;
  if(P.stage>=PARTY_STAGES.length){ partyFinal(); return; }
  const lvl=PARTY_STAGES[P.stage];
  P.phase='intro';
  phShow('phIntro');
  const tag=$('phLevelTag');
  if(lvl==='bonus'){
    tag.className='level-tag'; $('phLevelName').textContent='⚡ جولة الضغط السريع';
    $('phIntroTitle').textContent='⚡ جولة الضغط السريع'; $('phIntroTitle').style.color='var(--blue)';
    $('phIntroDesc').textContent='10 أسئلة في 60 ثانية: أول من يضغط الزر الأحمر يجيب بصوته، والمضيف يحكم. خطأ؟ يُفتح الزر للباقين.';
  }else{
    const L=LEVELS[lvl];
    tag.className='level-tag '+L.tone; $('phLevelName').textContent=L.name;
    $('phIntroTitle').textContent=L.name; $('phIntroTitle').style.color=L.color;
    $('phIntroDesc').textContent='5 أسئلة — '+L.per+' نقاط لكل إجابة صحيحة و'+L.time+' ثانية. الكل يجيب معاً، والأسرع يأخذ نقاط سرعة إضافية!'+
      (lvl==='medium'?' لكل لاعب «طيارة» واحدة.':lvl==='hard'?' لكل لاعب «50:50» واحدة.':'');
  }
  $('phQNum').textContent='';
  sfx.drumroll(); renderRanks(); partySync(true);
}
$('phIntroGo').addEventListener('click', ()=>{
  if(PARTY_STAGES[P.stage]==='bonus') startPartyBonus(); else startPartyQ();
});

function startPartyQ(){
  const lvl=PARTY_STAGES[P.stage], L=LEVELS[lvl];
  P.phase='q'; P.started=false; P.revealed=false; P.fastest=null;
  P.total=L.time; P.left=L.time;
  activePlayers().forEach(([,p])=>{ p.ans=null; p.elim=[]; });
  phShow('phQ');
  $('phQNum').textContent='السؤال '+(P.qi+1)+' من 5';
  $('phStartBtn').style.display=''; $('phStartBtn').disabled=false;
  $('phNextBtn').style.display='none';
  renderHostQ(); renderPartyTimer(); partySync(true);
}
$('phStartBtn').addEventListener('click', ()=>{
  if(P.started) return;
  P.started=true; P.tStart=Date.now(); $('phStartBtn').disabled=true;
  clearInterval(P.iid);
  P.iid=setInterval(()=>{
    P.left=Math.max(0, P.total-Math.floor((Date.now()-P.tStart)/1000));
    if(P.left<=5 && P.left>0) sfx.tick();
    renderPartyTimer();
    if(P.left<=0){ sfx.timeUp(); revealQ(); }
  }, 1000);
  renderHostQ(); partySync(true);
});
function renderPartyTimer(){
  $('phTimerNum').textContent=P.left;
  $('phTimerArc').style.strokeDasharray=ARC_LEN;
  $('phTimerArc').style.strokeDashoffset=ARC_LEN*(1-P.left/P.total);
  $('phTimerRing').classList.toggle('warn', P.started && !P.revealed && P.left<=5 && P.left>0);
}
function maybeEndQuestion(){
  if(P.phase!=='q' || !P.started || P.revealed) return;
  if(activePlayers().every(([,p])=>p.ans!==null)) revealQ();
}
function revealQ(){
  if(P.revealed) return;
  P.revealed=true; clearInterval(P.iid);
  const lvl=PARTY_STAGES[P.stage], L=LEVELS[lvl], it=curQ();
  // الأسرع بين الإجابات الصحيحة (الطيارة لا تُحسب سرعة)
  let best=null;
  activePlayers().forEach(([id,p])=>{
    if(!p.ans) return;
    p.ans.ok = p.ans.i===it.a;
    if(p.ans.ok){
      p.score[lvl]+=L.per;
      if(p.ans.at){
        const rem=Math.max(0, P.total - (p.ans.at-P.tStart)/1000);
        p.ans.sp=Math.max(1, Math.ceil(5*rem/P.total)); p.speed+=p.ans.sp;
        if(!best || p.ans.at<best.at) best={id, at:p.ans.at};
      }
    }
  });
  if(best){ P.fastest=best.id; const p=P.players.get(best.id); p.speed+=2; p.ans.sp+=2; }
  $('phNextBtn').style.display='inline-flex';
  $('phNextBtn').textContent = P.qi<4 ? 'السؤال التالي' : 'المرحلة التالية';
  sfx.good(); renderHostQ(); renderRanks(); partySync(true);
}
$('phNextBtn').addEventListener('click', ()=>{
  if(P.qi<4){ P.qi++; startPartyQ(); } else nextStage();
});

function renderHostQ(){
  const it=curQ();
  $('phQText').textContent=it.q;
  const box=$('phChoices'); box.innerHTML='';
  const keys=['أ','ب','ج','د'];
  it.c.forEach((txt,i)=>{
    const b=document.createElement('div');
    b.className='choice'+(i===it.a?' host-key':'')+(P.revealed&&i===it.a?' correct':'');
    b.innerHTML='<span class="key">'+keys[i]+'</span><span></span>'; b.lastChild.textContent=txt;
    box.appendChild(b);
  });
  const st=$('phStatus'); st.innerHTML='';
  activePlayers().forEach(([id,p])=>{
    const c=document.createElement('span');
    c.className='ps-chip'+(p.ans?(P.revealed?(p.ans.ok?' good':' bad'):' done'):'')+(P.revealed&&P.fastest===id?' fast':'');
    c.textContent=(P.revealed && p.ans ? (p.ans.ok?'✓ ':'✗ ') : p.ans ? '✓ ' : '… ')+p.name+(p.ans&&p.ans.jet?' ✈️':'');
    st.appendChild(c);
  });
}

/* ---------- جولة الضغط السريع ---------- */
function startPartyBonus(){
  P.phase='bonus';
  Object.assign(P.bonus,{idx:0, left:BONUS_TIME, running:false, buzzed:null});
  P.bonus.locked=new Set();
  phShow('phBonus');
  $('phBonusStart').style.display='inline-flex';
  renderHostBonus(); partySync(true);
}
$('phBonusStart').addEventListener('click', ()=>{
  P.bonus.running=true; $('phBonusStart').style.display='none';
  loopStart();
  clearInterval(P.bonus.iid);
  P.bonus.iid=setInterval(()=>{
    P.bonus.left--;
    if(P.bonus.left<=10 && P.bonus.left>0) sfx.tick();
    if(P.bonus.left<=0) endPartyBonus();
    renderHostBonus();
  },1000);
  renderHostBonus(); partySync(true);
});
function bonusNext(){
  P.bonus.buzzed=null; P.bonus.locked=new Set();
  if(P.bonus.idx+1<BONUS_COUNT){ P.bonus.idx++; } else { endPartyBonus(); return; }
  renderHostBonus(); partySync(true);
}
$('phBonusRight').addEventListener('click', ()=>{
  const id=P.bonus.buzzed; if(!id || !P.bonus.running) return;
  P.players.get(id).score.bonus++; sfx.good(); renderRanks(); bonusNext();
});
$('phBonusWrong').addEventListener('click', ()=>{
  const id=P.bonus.buzzed; if(!id || !P.bonus.running) return;
  P.bonus.locked.add(id); P.bonus.buzzed=null; sfx.bad();
  if(activePlayers().every(([pid])=>P.bonus.locked.has(pid))) bonusNext();
  else { renderHostBonus(); partySync(true); }
});
$('phBonusSkip').addEventListener('click', ()=>{ if(P.bonus.running) bonusNext(); });
function endPartyBonus(){
  if(!P.bonus.running && P.phase!=='bonus') return;
  P.bonus.running=false; clearInterval(P.bonus.iid); loopStop();
  sfx.fanfare(); renderRanks(); partySync(true);
  setTimeout(nextStage, 1500);
}
function renderHostBonus(){
  const it=P.qs.bonus[P.bonus.idx];
  $('phBonusTimer').textContent=P.bonus.left;
  $('phBonusTimer').classList.toggle('warn', P.bonus.running && P.bonus.left<=10);
  $('phBonusProgress').textContent='السؤال '+(P.bonus.idx+1)+' من '+BONUS_COUNT;
  $('phBonusQ').textContent = P.bonus.running ? it.q : 'جاهزون؟ اضغطوا الزر الأحمر عندما تعرفون الإجابة!';
  $('phBonusA').textContent = P.bonus.running ? it.a : '—';
  const b=P.bonus.buzzed && P.players.get(P.bonus.buzzed);
  $('phBuzzState').textContent = b ? '🔔 '+b.name+' ضغط أولاً — يجيب الآن!' : P.bonus.running ? 'بانتظار أول ضغطة…' : '';
  $('phBonusJudge').style.display = b ? 'grid' : 'none';
}

/* ---------- الترتيب والنهاية ---------- */
const pTotal = p => p.score.easy+p.score.medium+p.score.bonus+p.score.hard;
function ranking(){
  return activePlayers().map(([id,p])=>({id, name:p.name, avatar:p.avatar, total:pTotal(p), speed:p.speed, score:p.score}))
    .sort((a,b)=>b.total-a.total || b.speed-a.speed);
}
function renderRanks(){ renderRankList($('phRanks'), ranking()); }

function partyFinal(){
  P.phase='final';
  clearInterval(P.iid); clearInterval(P.bonus.iid); loopStop();
  const r=ranking();
  r.forEach(x=>{
    const p=P.players.get(x.id);
    if(p.saved) return; p.saved=true;
    addRecord({t:Date.now(), player:x.name, host:state.host.name, mode:'room', ...x.score, total:x.total, speed:x.speed});
  });
  partySync(true);
  showPodium(r, 'نتيجة غرفة العائلة', 'ترتيب اللاعبين حسب المجموع ثم نقاط السرعة', 'room');
}
$('phEndBtn').addEventListener('click', ()=>{
  if(P.phase!=='final' && P.phase!=='lobby' && !confirm('إنهاء الغرفة الآن؟')) return;
  partyStop(); goHome();
});
function partyStop(){
  P.on=false; clearInterval(P.syncIid); clearInterval(P.iid); clearInterval(P.bonus.iid); loopStop();
}
Party.stop = partyStop;

/* ---------- اللقطات: لقطة خاصة لكل لاعب ---------- */
function partySync(force){
  if(!P.on) return;
  const r=ranking();
  const lvl=PARTY_STAGES[P.stage];
  const base={host:state.host.name, ph:P.phase, gid:P.gameId,
    ranks:r.map(x=>({name:x.name, total:x.total, speed:x.speed, id:x.id}))};
  if(P.phase==='intro'){ base.title=$('phIntroTitle').textContent; base.desc=$('phIntroDesc').textContent; base.color=$('phIntroTitle').style.color; }
  if(P.phase==='q'){
    const it=curQ(), L=LEVELS[lvl];
    Object.assign(base,{lvl, lvlName:L.name+' — '+L.per+' نقاط', qn:'السؤال '+(P.qi+1)+' من 5', text:it.q, choices:it.c,
      left:P.left, total:P.total, started:P.started, revealed:P.revealed, correct:P.revealed?it.a:null});
  }
  if(P.phase==='bonus'){
    const it=P.qs.bonus[P.bonus.idx], b=P.bonus.buzzed && P.players.get(P.bonus.buzzed);
    Object.assign(base,{left:P.bonus.left, running:P.bonus.running, text:P.bonus.running?it.q:'جاهزون؟', buzzedName:b?b.name:null,
      qn:'السؤال '+(P.bonus.idx+1)+' من '+BONUS_COUNT});
  }
  activePlayers().forEach(([id,p])=>{
    const me={id, name:p.name, total:pTotal(p), speed:p.speed, score:p.score, rank:r.findIndex(x=>x.id===id)+1,
      ans:p.ans?p.ans.i:null, ok:p.ans&&P.revealed?!!p.ans.ok:null, sp:p.ans&&p.ans.sp||0, fast:P.fastest===id,
      elim:p.elim, ll:{jet:!p.ll.jet && lvl==='medium', fifty:!p.ll.fifty && lvl==='hard'},
      buzzed:P.bonus.buzzed===id, locked:P.bonus.locked.has(id)};
    const s={...base, me};
    const json=JSON.stringify(s);
    const last=P.last.get(id);
    if(!force && last && last.json===json && Date.now()-last.t<3000) return;
    P.last.set(id,{json, t:Date.now()});
    Net.sendTo(id,{t:'psnap', s});
  });
  renderJoined();
}

/* ================= اللاعب ================= */
const PP={key:null, picked:-1, saved:null};
function ppShow(id){ ['ppWait','ppQ','ppBonus','ppFinal'].forEach(x=>$(x).style.display = x===id?'block':'none'); }
$('ppTimerArc').style.strokeDasharray=ARC_LEN;
Party.render = function(s){
  if(!$('screen-party').classList.contains('active')) showScreen('screen-party');
  const me=s.me;
  $('ppScore').textContent=me.total; $('ppSpeed').textContent='⚡ '+me.speed;
  $('ppRank').textContent = 'ترتيبك: '+me.rank+' / '+s.ranks.length;
  const tag=$('ppLevelTag');
  if(s.ph==='lobby' || s.ph==='intro'){
    ppShow('ppWait'); tag.className='level-tag'; $('ppLevelName').textContent='غرفة العائلة';
    $('ppWaitTitle').textContent = s.ph==='intro' ? s.title : 'متصل بالغرفة ✓';
    $('ppWaitTitle').style.color = s.ph==='intro' ? s.color : '';
    $('ppWaitDesc').textContent = s.ph==='intro' ? s.desc : 'في الغرفة: '+s.ranks.map(r=>r.name).join('، ')+' — بانتظار المضيف…';
    return;
  }
  if(s.ph==='q'){
    ppShow('ppQ'); tag.className='level-tag '+LEVELS[s.lvl].tone; $('ppLevelName').textContent=s.lvlName;
    $('ppTimerNum').textContent = s.started ? s.left : s.total;
    $('ppTimerArc').style.strokeDashoffset = ARC_LEN*(1-(s.started?s.left:s.total)/s.total);
    $('ppTimerRing').classList.toggle('warn', s.started && !s.revealed && s.left<=5 && s.left>0);
    const answered = me.ans!==null;
    const can = s.started && !s.revealed && !answered;
    $('ppInstr').textContent = s.revealed ? 'انتظر المضيف للسؤال التالي' : answered ? 'تم إرسال إجابتك ✓ بانتظار الباقين…' : can ? 'أجب بسرعة — الأسرع يأخذ نقاطاً إضافية!' : 'المضيف يقرأ السؤال… انتظر بدء المؤقت';
    $('ppQText').textContent=s.text;
    const key=s.gid+'|'+s.lvl+'|'+s.qn;
    const box=$('ppChoices');
    if(PP.key!==key){
      PP.key=key; PP.picked=-1; box.innerHTML='';
      const keys=['أ','ب','ج','د'];
      s.choices.forEach((txt,i)=>{
        const b=document.createElement('button'); b.type='button'; b.className='choice'; b.dataset.idx=i;
        b.innerHTML='<span class="key">'+keys[i]+'</span><span></span>'; b.lastChild.textContent=txt;
        b.addEventListener('click', ()=>{
          if(b.disabled) return;
          PP.picked=i; box.querySelectorAll('.choice').forEach(x=>x.disabled=true);
          b.classList.add('remote-picked'); vibrate(20);
          Net.send({t:'pans', i});
        });
        box.appendChild(b);
      });
    }
    [...box.children].forEach((b,i)=>{
      const el=me.elim.includes(i), mine=(me.ans===i)||(PP.picked===i);
      b.classList.toggle('eliminated', el);
      b.classList.toggle('correct', s.revealed && s.correct===i);
      b.classList.toggle('wrong', s.revealed && mine && s.correct!==i);
      b.classList.toggle('remote-picked', mine && !s.revealed);
      b.classList.toggle('locked', !can);
      b.disabled = !can || el || PP.picked>=0;
    });
    const v=$('ppVerdict');
    if(s.revealed){
      if(PP.verdictFor!==key){ PP.verdictFor=key; if(me.ok){ sfx.good(); celebrate('correct'); } else { sfx.bad(); celebrate('wrong'); } }
      v.className='verdict show '+(me.ok?'good':'bad');
      v.textContent = me.ok ? 'إجابة صحيحة! '+(me.sp?'⚡+'+me.sp:'')+(me.fast?' — أنت الأسرع!':'') : me.ans===null ? 'لم تُجب في الوقت' : 'إجابة غير صحيحة';
    }else{ v.className='verdict'; v.textContent=''; }
    const ll=$('ppLL'); ll.innerHTML='';
    const list=[]; if(s.lvl==='medium') list.push('jet'); if(s.lvl==='hard') list.push('fifty');
    $('ppLLWrap').style.display=list.length?'block':'none';
    list.forEach(k=>{
      const d=LL_DEFS[k], b=document.createElement('button');
      b.type='button'; b.className='ll-btn '+d.cls+(me.ll[k]?'':' used');
      b.innerHTML=d.icon+'<span></span>'; b.lastChild.textContent=d.label;
      b.disabled=!me.ll[k] || !can;
      b.addEventListener('click', ()=>{ b.disabled=true; sfx.lifeline(); Net.send({t:'pll', k}); });
      ll.appendChild(b);
    });
    return;
  }
  if(s.ph==='bonus'){
    ppShow('ppBonus'); tag.className='level-tag'; $('ppLevelName').textContent='⚡ الضغط السريع';
    $('ppBonusTimer').textContent=s.left;
    $('ppBonusTimer').classList.toggle('warn', s.running && s.left<=10);
    $('ppBonusQ').textContent=s.text;
    const btn=$('ppBuzzBtn');
    btn.disabled = !s.running || !!s.buzzedName || me.locked;
    $('ppBuzzState').textContent = me.buzzed ? '🔔 أنت أولاً — أجب بصوتك الآن!' : s.buzzedName ? '🔔 '+s.buzzedName+' ضغط أولاً' : me.locked ? 'انتظر السؤال التالي' : s.running ? 'اضغط إذا عرفت الإجابة!' : 'استعد…';
    if(me.buzzed && PP.buzzFor!==s.qn){ PP.buzzFor=s.qn; vibrate([50,30,50]); }
    return;
  }
  if(s.ph==='final'){
    ppShow('ppFinal'); tag.className='level-tag'; $('ppLevelName').textContent='انتهت الجولة';
    renderPodium($('ppPodium'), s.ranks);
    renderRankList($('ppRankList'), s.ranks, me.id);
    if(PP.saved!==s.gid){
      PP.saved=s.gid;
      addRecord({t:Date.now(), player:me.name, host:s.host, mode:'room', ...me.score, total:me.total, speed:me.speed});
      celebrate(me.rank===1 ? 'big' : 'final');
    }
  }
};
$('ppBuzzBtn').addEventListener('click', ()=>{ sfx.buzz(); vibrate(30); $('ppBuzzBtn').disabled=true; Net.send({t:'buzz'}); });
$('ppLeaveBtn').addEventListener('click', ()=>goHome());
