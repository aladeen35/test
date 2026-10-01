/* فول مارك — المساعد الذكي (وسيلة المساعدة في المستوى الصعب)
   سلسلة المزوّدين: خادم الشركة الوسيط (إن ضُبط في config.js) ← Puter المجاني ← التلميح المدمج.
   الصوت: التعرّف على الكلام والنطق عبر إضافات Capacitor داخل التطبيق، أو واجهات المتصفح على الويب. */
(function(){
  'use strict';
  const CFG = window.FM_CONFIG || {};
  const PUTER_SRC = 'https://js.puter.com/v2/';

  function systemPrompt(q){
    return 'أنت «المساعد الذكي» في برنامج مسابقات عائلي عربي اسمه فول مارك. ' +
      'اللاعب طلب مساعدتك في سؤال من المستوى الصعب. أجب بالعربية الفصحى المبسّطة في جملتين أو ثلاث فقط. ' +
      'اذكر الخيار الذي تراه صحيحاً ومدى ثقتك (مرتفعة/متوسطة/منخفضة) مع سبب قصير، ولا تخترع معلومات. ' +
      'لا تتحدث في أي موضوع خارج السؤال، وحافظ على لغة مناسبة للعائلة.\n\n' +
      'السؤال: ' + q.q + '\nالخيارات المتاحة: ' + q.choices.join(' | ');
  }

  /* ---------- المزوّدون ---------- */
  async function viaProxy(q, history){
    const r = await fetch(CFG.aiProxyUrl, {
      method:'POST',
      headers:{'content-type':'application/json','anthropic-version':'2023-06-01'},
      body: JSON.stringify({model: CFG.aiModel || 'claude-haiku-4-5', max_tokens: 400,
        system: systemPrompt(q), messages: history}),
    });
    if(!r.ok) throw new Error('proxy ' + r.status);
    const d = await r.json();
    const t = (d.content || []).filter(c=>c.type==='text').map(c=>c.text).join('').trim();
    if(!t) throw new Error('empty');
    return t;
  }

  let puterLoading = null;
  function loadPuter(){
    if(window.puter && window.puter.ai) return Promise.resolve(true);
    if(puterLoading) return puterLoading;
    puterLoading = new Promise(res=>{
      const s = document.createElement('script');
      s.src = PUTER_SRC;
      s.onload = ()=>res(!!(window.puter && window.puter.ai));
      s.onerror = ()=>{ puterLoading = null; res(false); };
      document.head.appendChild(s);
      setTimeout(()=>res(!!(window.puter && window.puter.ai)), 12000);
    });
    return puterLoading;
  }
  async function viaPuter(q, history){
    if(!(await loadPuter())) throw new Error('puter-load');
    const msgs = [{role:'system', content: systemPrompt(q)}, ...history];
    let resp;
    try{ resp = await window.puter.ai.chat(msgs, {model:'claude-haiku-4-5'}); }
    catch(e){ resp = await window.puter.ai.chat(msgs); }
    const m = resp && (resp.message || resp);
    let t = '';
    if(typeof m === 'string') t = m;
    else if(m && typeof m.content === 'string') t = m.content;
    else if(m && Array.isArray(m.content)) t = m.content.map(c=>c.text||'').join('');
    else if(resp && typeof resp.toString === 'function') t = String(resp);
    t = (t||'').trim();
    if(!t) throw new Error('empty');
    return t;
  }

  /* يعيد {text, source} — source: proxy | puter | builtin */
  async function ask(q, history){
    if(CFG.aiProxyUrl){
      try{ return {text: await viaProxy(q, history), source:'proxy'}; }catch(e){ /* نجرب التالي */ }
    }
    if(navigator.onLine !== false){
      try{ return {text: await viaPuter(q, history), source:'puter'}; }catch(e){ /* نجرب التالي */ }
    }
    return {text: q.hint || 'فكّر في الخيار الأكثر ارتباطاً بكلمات السؤال، واستبعد ما تعرف أنه خاطئ.', source:'builtin'};
  }

  /* ---------- الصوت ---------- */
  function cap(){ const C = window.Capacitor; return C && C.isNativePlatform && C.isNativePlatform() ? C : null; }
  function nativePlugin(name){
    const C = cap(); if(!C) return null;
    return (C.Plugins && C.Plugins[name]) || (C.registerPlugin && C.registerPlugin(name)) || null;
  }
  const WebSR = window.SpeechRecognition || window.webkitSpeechRecognition;

  function canListen(){ return !!(cap() || WebSR); }

  async function listen(){
    const SR = nativePlugin('SpeechRecognition');
    if(SR){
      const av = await SR.available().catch(()=>({available:false}));
      if(!av.available) throw new Error('خدمة التعرّف على الكلام غير متاحة في هذا الجهاز');
      const perm = await SR.requestPermissions().catch(()=>null);
      if(perm && perm.speechRecognition && perm.speechRecognition !== 'granted') throw new Error('يلزم السماح باستخدام الميكروفون');
      const r = await SR.start({language:'ar-SA', maxResults:1, prompt:'تحدّث بسؤالك للمساعد', partialResults:false, popup:true});
      return (r && r.matches && r.matches[0]) || '';
    }
    if(!WebSR) throw new Error('الإدخال الصوتي غير مدعوم في هذا المتصفح');
    return new Promise((res, rej)=>{
      const rec = new WebSR();
      rec.lang = 'ar-SA'; rec.interimResults = false; rec.maxAlternatives = 1;
      rec.onresult = e => res(e.results[0][0].transcript);
      rec.onerror = e => rej(new Error(e.error==='not-allowed' ? 'يلزم السماح باستخدام الميكروفون' : 'لم أسمع جيداً — حاول مجدداً'));
      rec.onend = () => res('');
      rec.start();
    });
  }

  async function speak(text){
    const TTS = nativePlugin('TextToSpeech');
    if(TTS){ try{ await TTS.speak({text, lang:'ar-SA', rate:1.0}); return; }catch(e){} }
    if(window.speechSynthesis){
      const u = new SpeechSynthesisUtterance(text);
      u.lang = 'ar-SA';
      const v = speechSynthesis.getVoices().find(v=>v.lang && v.lang.startsWith('ar'));
      if(v) u.voice = v;
      speechSynthesis.cancel(); speechSynthesis.speak(u);
    }
  }
  function stopSpeaking(){
    const TTS = nativePlugin('TextToSpeech');
    if(TTS) TTS.stop().catch(()=>{});
    if(window.speechSynthesis) speechSynthesis.cancel();
  }

  window.FMAI = {ask, listen, speak, stopSpeaking, canListen};
})();
