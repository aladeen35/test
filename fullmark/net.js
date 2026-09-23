/* فول مارك — طبقة الاتصال بين جهازين
   واجهة موحدة لنقلين:
   - أونلاين: PeerJS (WebRTC) مع خادم الإشارة المجاني
   - بلوتوث: الإضافة الأصلية FMBluetooth داخل تطبيق APK (Capacitor)
   الرسائل كائنات JSON؛ على البلوتوث تُرسل سطراً سطراً. */
(function(){
  'use strict';
  const PEER_PREFIX = 'fullmark-v1-';
  let active = null;       // {send(obj), close()}
  let handlers = {};

  function emit(name, arg){ try{ handlers[name] && handlers[name](arg); }catch(e){ console.error(e); } }

  function loadScript(src){
    return new Promise((res, rej)=>{
      if(window.Peer) return res();
      const s=document.createElement('script');
      s.src=src; s.onload=()=>res(); s.onerror=()=>rej(new Error('تعذر تحميل مكتبة الاتصال'));
      document.head.appendChild(s);
    });
  }

  /* ---------- أونلاين (PeerJS) ---------- */
  function wireConn(conn){
    conn.on('data', d=>{ if(d && typeof d==='object') emit('message', d); });
    conn.on('close', ()=>{ if(active && active.conn===conn){ active=null; emit('close'); } });
    conn.on('error', ()=>emit('status', {kind:'err', text:'حدث خطأ في الاتصال'}));
    active = {
      conn,
      send(obj){ if(conn.open) conn.send(obj); },
      close(){ try{ conn.close(); }catch(e){} },
    };
  }

  let peer = null;
  function destroyPeer(){ if(peer){ try{ peer.destroy(); }catch(e){} peer=null; } }

  async function hostOnline(h){
    handlers = h;
    await loadScript('peerjs.min.js');
    const tryCode = ()=>new Promise((res, rej)=>{
      const code = String(10000 + Math.floor(Math.random()*90000));
      destroyPeer();
      peer = new window.Peer(PEER_PREFIX + code, {debug:0});
      peer.on('open', ()=>res(code));
      peer.on('error', err=>{
        if(err && err.type==='unavailable-id') res(null);   // رمز محجوز — نجرب غيره
        else rej(err);
      });
    });
    let code = null;
    for(let i=0;i<4 && !code;i++) code = await tryCode();
    if(!code) throw new Error('تعذر إنشاء غرفة');
    peer.on('connection', conn=>{
      if(active){ conn.on('open', ()=>{ conn.send({t:'busy'}); setTimeout(()=>conn.close(), 300); }); return; }
      conn.on('open', ()=>{ wireConn(conn); emit('open'); });
    });
    peer.on('disconnected', ()=>{ try{ peer.reconnect(); }catch(e){} });
    return code;
  }

  async function joinOnline(code, h){
    handlers = h;
    await loadScript('peerjs.min.js');
    destroyPeer();
    return new Promise((res, rej)=>{
      peer = new window.Peer({debug:0});
      let done=false;
      const fail = msg=>{ if(!done){ done=true; rej(new Error(msg)); } };
      const to = setTimeout(()=>fail('انتهت مهلة الاتصال — تأكد من الرمز والإنترنت'), 20000);
      peer.on('error', err=>{
        clearTimeout(to);
        fail(err && err.type==='peer-unavailable' ? 'لا توجد غرفة بهذا الرمز' : 'تعذر الاتصال بالخادم');
      });
      peer.on('open', ()=>{
        const conn = peer.connect(PEER_PREFIX + code, {reliable:true});
        conn.on('open', ()=>{
          clearTimeout(to);
          if(done) return;
          done=true; wireConn(conn); emit('open'); res();
        });
      });
    });
  }

  /* ---------- بلوتوث (إضافة أصلية داخل APK) ---------- */
  function bt(){ return window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.FMBluetooth; }
  let btSubs = [];
  let btBuf = '';
  async function btWire(){
    const B = bt();
    btSubs.forEach(s=>{ try{ s.remove(); }catch(e){} });
    btSubs = [];
    btSubs.push(await B.addListener('data', e=>{
      btBuf += e.data;
      let i;
      while((i = btBuf.indexOf('\n')) >= 0){
        const line = btBuf.slice(0, i); btBuf = btBuf.slice(i+1);
        if(!line.trim()) continue;
        try{ emit('message', JSON.parse(line)); }catch(err){ /* سطر تالف */ }
      }
    }));
    btSubs.push(await B.addListener('disconnected', ()=>{ active=null; emit('close'); }));
    active = {
      send(obj){ B.send({data: JSON.stringify(obj) + '\n'}).catch(()=>{}); },
      close(){ B.disconnect().catch(()=>{}); },
    };
  }
  async function btEnsure(){
    const B = bt();
    if(!B) throw new Error('البلوتوث متاح فقط في تطبيق الجوال (APK)');
    const r = await B.ensure();
    if(!r || !r.enabled) throw new Error('فعّل البلوتوث في الجوال ثم حاول مجدداً');
  }
  async function hostBt(h){
    handlers = h;
    await btEnsure();
    const B = bt();
    const sub = await B.addListener('connected', async e=>{
      sub.remove();
      await btWire();
      emit('open', e && e.name);
    });
    await B.listen();
  }
  async function listBt(){
    await btEnsure();
    const r = await bt().listPaired();
    return (r && r.devices) || [];
  }
  async function joinBt(address, h){
    handlers = h;
    await btEnsure();
    await bt().connect({address});
    await btWire();
    emit('open');
  }

  /* ---------- نقل مخصص (للاختبارات) ---------- */
  function useTransport(t, h){
    handlers = h;
    active = t;
    t.onMessage = m => emit('message', m);
    t.onClose = () => { active=null; emit('close'); };
    emit('open');
  }

  window.Net = {
    btAvailable: ()=>!!bt(),
    hostOnline, joinOnline, hostBt, listBt, joinBt, useTransport,
    send(obj){ if(active) active.send(obj); },
    connected: ()=>!!active,
    close(){
      const a=active; active=null; handlers={};
      if(a) a.close();
      destroyPeer();
      const B=bt(); if(B){ B.disconnect().catch(()=>{}); btSubs.forEach(s=>{ try{s.remove();}catch(e){} }); btSubs=[]; }
    },
  };
})();
