/* ═══════════════════════════════════════════════
   أدوات البشري — التشغيل والواجهة
   الحالة، التخزين، التنقل، الشاشة الرئيسية، الصلاة، الإعدادات
   ═══════════════════════════════════════════════ */

const STORE_KEY = 'albushra-tools';
const DEFAULTS = {
  name: '', city: 'khartoum', gps: null, method: 'egypt', asr: 'standard', adjust: {},
  hijriShift: 0, theme: 'auto', favs: ['currency', 'remit', 'tasbih', 'qibla', 'flashlight', 'calc'], recent: [],
  rates: null, sdgParallel: null, rateMode: 'parallel', wx: {}, prayerNotify: false, onboarded: false,
};

let S;
try { S = { ...DEFAULTS, ...JSON.parse(localStorage.getItem(STORE_KEY) || '{}') }; } catch { S = { ...DEFAULTS }; }
function save() { try { localStorage.setItem(STORE_KEY, JSON.stringify(S)); } catch { /* التخزين غير متاح */ } }

/* ── أدوات مساعدة ── */
const $ = (s, r = document) => r.querySelector(s);
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmtNum = (n, d = 2) => (isFinite(n) ? new Intl.NumberFormat('en-US', { maximumFractionDigits: d }).format(n) : '—');
const fmtBytes = (b) => (b < 1024 ? b + ' B' : b < 1048576 ? fmtNum(b / 1024, 0) + ' KB' : fmtNum(b / 1048576, 2) + ' MB');

function toast(msg) {
  const t = $('#toast'); t.textContent = msg; t.classList.add('show');
  clearTimeout(t._h); t._h = setTimeout(() => t.classList.remove('show'), 2200);
}
async function copyText(s) {
  if (!s || s === '—') return;
  try { await navigator.clipboard.writeText(s); toast('تم النسخ ✓'); } catch { toast('تعذّر النسخ'); }
}
async function shareFile(file) {
  if (navigator.canShare?.({ files: [file] })) { try { await navigator.share({ files: [file] }); } catch { /* أُلغي */ } }
  else toast('المشاركة غير مدعومة — استخدم «حفظ»');
}
const loaded = {};
function loadScript(src) {
  return loaded[src] ||= new Promise((ok, no) => {
    const s = document.createElement('script'); s.src = src; s.onload = ok; s.onerror = () => { delete loaded[src]; no(); };
    document.head.appendChild(s);
  });
}
function beep() {
  try {
    const c = new AudioContext(), o = c.createOscillator(), g = c.createGain();
    o.connect(g); g.connect(c.destination); o.frequency.value = 880; g.gain.value = 0.2;
    o.start(); [0.3, 0.6].forEach((t) => { g.gain.setValueAtTime(0, c.currentTime + t - 0.1); g.gain.setValueAtTime(0.2, c.currentTime + t); });
    o.stop(c.currentTime + 0.9);
  } catch { /* */ }
}
async function notify(body, title = 'أدوات البشري') {
  if (window.Notification?.permission !== 'granted') return;
  try { const r = await navigator.serviceWorker?.ready; r ? r.showNotification(title, { body, icon: 'icons/icon-192.png', lang: 'ar', dir: 'rtl' }) : new Notification(title, { body }); } catch { /* */ }
}

/* ── الموقع والصلاة ── */
function city() {
  const c = CITIES.find((x) => x.id === S.city) || CITIES[0];
  return S.gps ? { ...c, name: `${c.name} (موقعي)`, lat: S.gps.lat, lng: S.gps.lng } : c;
}
const prayerOpts = () => ({ method: S.method, asr: S.asr, adjust: S.adjust });

function todayTimes(date = new Date()) {
  const c = city(), p = sdParts(date);
  return PrayerCalc.times(p.y, p.m, p.d, c.lat, c.lng, prayerOpts());
}
function nextPrayer(now = new Date()) {
  const t = todayTimes(now);
  for (const k of PRAYER_ORDER) if (k !== 'sunrise' && t[k] > now) return { key: k, at: t[k], times: t };
  const tm = todayTimes(new Date(now.getTime() + 86400000));
  return { key: 'fajr', at: tm.fajr, times: t };
}
function currentPrayer(times, now = new Date()) {
  let cur = null;
  for (const k of PRAYER_ORDER) if (times[k] <= now) cur = k;
  return cur;
}
const dur = (ms) => { const m = Math.max(0, Math.floor(ms / 60000)); return m >= 60 ? `${Math.floor(m / 60)} س ${m % 60} د` : `${m} دقيقة`; };

/* ── العملات ── */
async function refreshRates(force = false) {
  if (!force && S.rates && Date.now() - S.rates.at < 6 * 3600000) return;
  try {
    const r = await fetch('https://open.er-api.com/v6/latest/USD').then((x) => x.json());
    if (r.result === 'success') { S.rates = { at: Date.now(), r: r.rates }; save(); }
  } catch { /* دون اتصال: نستخدم المحفوظ */ }
}
function usdRate(code, mode = S.rateMode) {
  if (code === 'SDG' && mode === 'parallel' && S.sdgParallel) return S.sdgParallel;
  return S.rates?.r?.[code] ?? FALLBACK_RATES[code] ?? 1;
}
// كم وحدة من «to» تساوي وحدة واحدة من «from»
function convertRate(from, to, mode) { return usdRate(to, mode) / usdRate(from, mode); }
const curSym = (code) => CURRENCIES.find((c) => c.code === code)?.sym || code;
function ratesNote() {
  const off = S.rates ? `السعر الرسمي محدَّث ${fmtDate(new Date(S.rates.at), { day: 'numeric', month: 'short' })} ${fmtTime(new Date(S.rates.at))}` : 'أسعار تقريبية — اتصل بالإنترنت للتحديث';
  return `${off}${S.rateMode === 'parallel' && S.sdgParallel ? ` · الجنيه بسعر السوق الموازي (${fmtNum(S.sdgParallel)} للدولار)` : ''}`;
}

/* ── الطقس والغبار ── */
async function getWeather(c, full = false) {
  const key = c.id, cached = S.wx[key];
  if (cached && Date.now() - cached.at < 30 * 60000) return cached;
  try {
    const q = `latitude=${c.lat}&longitude=${c.lng}&timezone=Africa%2FKhartoum`;
    const [f, a] = await Promise.all([
      fetch(`https://api.open-meteo.com/v1/forecast?${q}&current=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max&forecast_days=7`).then((r) => r.json()),
      fetch(`https://air-quality-api.open-meteo.com/v1/air-quality?${q}&current=pm10,dust,us_aqi`).then((r) => r.json()).catch(() => null),
    ]);
    const w = {
      at: Date.now(), temp: f.current.temperature_2m, feels: f.current.apparent_temperature, code: f.current.weather_code,
      hum: f.current.relative_humidity_2m, wind: f.current.wind_speed_10m, uv: f.daily.uv_index_max?.[0],
      pm10: a?.current?.pm10 ?? null, dust: a?.current?.dust ?? null, aqi: a?.current?.us_aqi ?? null,
      daily: f.daily.time.map((d, i) => ({ date: d, code: f.daily.weather_code[i], max: f.daily.temperature_2m_max[i], min: f.daily.temperature_2m_min[i] })),
    };
    S.wx[key] = w; save(); return w;
  } catch { return cached || null; }
}
function dustLevel(w) {
  const v = w?.pm10 ?? w?.dust;
  if (v == null) return null;
  if (v >= 400) return { cls: 'bad', t: 'هبوب / غبار كثيف — تجنّب الخروج وأغلق النوافذ' };
  if (v >= 150) return { cls: 'warn', t: 'غبار مرتفع — الكمامة مفيدة لمرضى الحساسية' };
  return null;
}
function dustBanner(w) {
  const d = dustLevel(w);
  return d ? `<div class="card" style="border-color:${d.cls === 'bad' ? 'var(--bad)' : 'var(--warn)'}"><b>🌪️ ${d.t}</b></div>` : '';
}

/* ── الشخصية (التميمة) ── */
let mascotN = 0;
const mascot = () => { const id = 'mg' + ++mascotN; return MASCOT_SVG.replace(/__ID__/g, id); };
const MASCOT_SVG = `<svg class="mascot" viewBox="0 0 100 100" aria-hidden="true">
  <defs><radialGradient id="__ID__" cx="35%" cy="30%"><stop offset="0" stop-color="#7FE3FF"/><stop offset=".6" stop-color="#2F7BFF"/><stop offset="1" stop-color="#1E3FC8"/></radialGradient></defs>
  <path d="M30 22 l-6 -10 12 6z M70 22 l6 -10 -12 6z" fill="#F5B83D"/>
  <circle cx="50" cy="54" r="40" fill="url(#__ID__)"/>
  <ellipse cx="38" cy="50" rx="7" ry="9" fill="#fff"/><ellipse cx="62" cy="50" rx="7" ry="9" fill="#fff"/>
  <circle cx="39" cy="52" r="4" fill="#000D2E"/><circle cx="63" cy="52" r="4" fill="#000D2E"/>
  <path d="M41 67 q9 7 18 0" stroke="#000D2E" stroke-width="3" fill="none" stroke-linecap="round"/>
  <circle cx="28" cy="64" r="5" fill="#FF8FB1" opacity=".6"/><circle cx="72" cy="64" r="5" fill="#FF8FB1" opacity=".6"/>
</svg>`;

/* ── بلاطة أداة ── */
function tileHTML(t) {
  const [bg, fg] = COLORS[t.color] || COLORS.blue;
  return `<button class="tile" data-tool="${t.id}">${t.sd ? '<span class="sd" title="مخصصة للسودان">🇸🇩</span>' : ''}
    <span class="ic" style="background:${bg};color:${fg}">${icon(t.icon)}</span><b>${t.name}</b><span>${t.sub}</span></button>`;
}

/* ═════════════ الشاشات ═════════════ */
let cleanup = null, homeTimer = null;

function greeting() {
  const h = +new Intl.DateTimeFormat('en', { timeZone: TZ, hour: 'numeric', hour12: false }).format(new Date()) % 24;
  return h < 12 ? 'صباح الخير' : h < 17 ? 'نهارك سعيد' : 'مساء الخير';
}

function renderHome() {
  const c = city();
  $('#v-home').innerHTML = `
    <div class="topbar">
      <div>
        <h1>${greeting()}${S.name ? ` يا ${esc(S.name)}` : ''}</h1>
        <div class="sub">${fmtDate(new Date())} — ${hijri(new Date(), S.hijriShift).text}</div>
        <div class="loc">🇸🇩 ${c.name} · ج.س</div>
      </div>
      <div class="btn-row"><button class="round-btn" data-go="tools?search" aria-label="بحث">${icon('search')}</button>
      <button class="round-btn" data-go="settings" aria-label="الإعدادات">${icon('settings')}</button></div>
    </div>

    <div class="hero" data-go="prayer" style="cursor:pointer">
      <div><div class="clock" id="clk"></div><div class="next" id="nxt"></div><div class="count" id="cnt"></div></div>
      ${mascot()}
    </div>

    <button class="weather-card" data-tool="weather" id="wx"><div class="ico">⛅</div><div><div class="t">--°</div><div class="meta">${c.name} — جارٍ التحميل…</div></div><div style="margin-inline-start:auto">${icon('back')}</div></button>

    <div class="card" data-tool="currency" style="cursor:pointer" id="rate"></div>

    <div class="section-h">${icon('bolt')} أدواتك المفضلة <button class="more" data-go="tools">الكل</button></div>
    <div class="quick">${S.favs.map(toolById).filter(Boolean).map(tileHTML).join('')}</div>

    ${S.recent.length ? `<div class="section-h">${icon('timer')} استخدمتها مؤخرًا</div>
    <div class="grid">${S.recent.slice(0, 6).map(toolById).filter(Boolean).map(tileHTML).join('')}</div>` : ''}

    <div class="section-h">${icon('star')} جديد في أدوات البشري</div>
    <div class="grid">${['power', 'gold', 'image'].map(toolById).map(tileHTML).join('')}</div>`;

  const tick = () => {
    const now = new Date(), np = nextPrayer(now);
    const parts = new Intl.DateTimeFormat('ar', { timeZone: TZ, hour: 'numeric', minute: '2-digit', hour12: true, numberingSystem: 'latn' }).formatToParts(now);
    const hm = parts.filter((p) => p.type !== 'dayPeriod').map((p) => p.value).join('').trim();
    const ap = parts.find((p) => p.type === 'dayPeriod')?.value || '';
    $('#clk').innerHTML = `${hm}<small>${ap}</small>`;
    $('#nxt').innerHTML = `${icon('mosque')} ${PRAYER_NAMES[np.key]} • ${fmtTime(np.at)}`;
    $('#cnt').textContent = `بعد ${dur(np.at - now)}`;
  };
  tick(); clearInterval(homeTimer); homeTimer = setInterval(tick, 15000);

  const paintRate = () => {
    const par = S.sdgParallel, off = convertRate('USD', 'SDG', 'official'), sar = convertRate('SAR', 'SDG');
    $('#rate').innerHTML = `
      <div style="display:flex;align-items:center;gap:12px">
        <span class="ic" style="width:48px;height:48px;border-radius:14px;display:grid;place-items:center;background:${COLORS.green[0]};color:${COLORS.green[1]}">${icon('money')}</span>
        <div style="flex:1"><b>الدولار اليوم</b><div class="note" style="margin:0">${par ? `موازي ${fmtNum(par, 0)} · ` : ''}رسمي ${fmtNum(off, 0)} ج.س</div></div>
        <div style="text-align:end"><b class="ltr">${fmtNum(sar, 0)}</b><div class="note" style="margin:0">ج.س للريال</div></div>
      </div>${par ? '' : '<div class="note">💡 أدخل سعر السوق الموازي من محوّل العملات لحسابات أدق.</div>'}`;
  };
  paintRate(); refreshRates().then(() => $('#rate') && paintRate());

  getWeather(c).then((w) => {
    if (!w || !$('#wx')) return;
    const [desc, emo] = WMO[w.code] || ['—', '🌡️'];
    const d = dustLevel(w);
    $('#wx').innerHTML = `<div class="ico">${emo}</div><div><div class="t">${Math.round(w.temp)}°</div>
      <div class="meta">${desc} · ${c.name} · يحس ${Math.round(w.feels)}°</div>${d ? `<span class="badge ${d.cls}" style="margin-top:4px">🌪️ ${d.cls === 'bad' ? 'هبوب' : 'غبار'}</span>` : ''}</div>
      <div style="margin-inline-start:auto">${icon('back')}</div>`;
  });
}

function renderTools(query = '') {
  let cat = 'all';
  $('#v-tools').innerHTML = `
    <div class="page-title"><h1>الأدوات</h1><span class="dot">${icon('grid')}</span></div>
    <div class="search">${icon('search')}<input id="q" placeholder="ابحث عن أداة…" value="${esc(query)}"></div>
    <div class="cat-chips" id="cats">${CATS.map((c) => `<button class="chip${c.id === 'all' ? ' on' : ''}" data-c="${c.id}">${c.name}</button>`).join('')}</div>
    <div class="grid" id="tg"></div>`;
  const draw = () => {
    const q = $('#q').value.trim();
    const list = TOOLS.filter((t) => (!t.hidden || q) && (cat === 'all' || t.cat === cat) && (!q || (t.name + t.sub).includes(q)));
    $('#tg').innerHTML = list.map(tileHTML).join('') || '<div class="empty" style="grid-column:1/-1">لا نتائج</div>';
  };
  $('#cats').onclick = (e) => { const c = e.target.dataset.c; if (!c) return; cat = c; $('#cats').querySelectorAll('.chip').forEach((x) => x.classList.toggle('on', x.dataset.c === c)); draw(); };
  $('#q').oninput = draw;
  draw();
}

function renderPrayer() {
  const c = city(), now = new Date(), t = todayTimes(now), np = nextPrayer(now), cur = currentPrayer(t, now);
  $('#v-prayer').innerHTML = `
    <div class="page-title"><h1>الصلاة</h1><span class="dot">${icon('mosque')}</span></div>
    <div class="hero"><div>
      <div class="next" style="margin:0;font-size:15px">${icon('pin')} ${c.name}</div>
      <div class="clock" style="font-size:40px;margin-top:8px">${PRAYER_NAMES[np.key]}</div>
      <div class="next">${fmtTime(np.at)} — بعد ${dur(np.at - now)}</div>
      <div class="hijri">${hijri(now, S.hijriShift).text}</div></div>${mascot()}</div>
    <div class="card">${PRAYER_ORDER.map((k) => `
      <div class="prayer-row${k === cur ? ' now' : ''}"><span>${PRAYER_NAMES[k]}</span><span class="t">${fmtTime(t[k])}</span></div>`).join('')}
      <div class="note">${METHODS[S.method].name} · العصر ${S.asr === 'hanafi' ? 'حنفي' : 'الجمهور'} — غيّرها من الإعدادات</div>
    </div>
    <div class="grid">${['qibla', 'adhkar', 'tasbih', 'monthly', 'hijri', 'countdown'].map(toolById).map(tileHTML).join('')}</div>`;
}

function renderSettings() {
  $('#v-settings').innerHTML = `
    <div class="page-title"><h1>الإعدادات</h1><span class="dot">${icon('settings')}</span></div>
    <div class="card"><h3>عام</h3>
      <label class="f">اسمك</label><input class="in" id="nm" value="${esc(S.name)}" placeholder="للتحية في الصفحة الرئيسية">
      <label class="f">المدينة</label><select class="in" id="ct">${cityOpts(S.city)}</select>
      <button class="btn ghost block" id="gps">${icon('pin')} ${S.gps ? 'إلغاء استخدام موقعي الدقيق' : 'استخدام موقعي الدقيق (GPS)'}</button>
      <label class="f">المظهر</label>
      <div class="seg" id="th">${[['auto', 'تلقائي'], ['light', 'فاتح'], ['dark', 'داكن']].map(([v, n]) => `<button data-t="${v}" class="${S.theme === v ? 'on' : ''}">${n}</button>`).join('')}</div>
    </div>
    <div class="card"><h3>الصلاة</h3>
      <label class="f">طريقة الحساب</label><select class="in" id="mt">${opt(Object.entries(METHODS).map(([k, m]) => [k, m.name]), S.method)}</select>
      <label class="f">وقت العصر</label><select class="in" id="as">${opt([['standard', 'الجمهور (مالكي/شافعي/حنبلي)'], ['hanafi', 'الحنفي']], S.asr)}</select>
      <label class="f">تعديل يدوي بالدقائق (لمطابقة مسجد حيّك)</label>
      <div class="grid" style="gap:8px">${PRAYER_ORDER.map((k) => `<div><label class="f" style="margin-top:0">${PRAYER_NAMES[k]}</label><input class="in" data-adj="${k}" inputmode="numeric" value="${S.adjust[k] || 0}"></div>`).join('')}</div>
      <label class="f">فرق التاريخ الهجري (حسب رؤية الهلال)</label>
      <select class="in" id="hs">${opt([['-2', '−2 يوم'], ['-1', '−1 يوم'], ['0', 'بدون'], ['1', '+1 يوم'], ['2', '+2 يوم']], String(S.hijriShift))}</select>
      <label style="display:flex;gap:8px;align-items:center;margin-top:12px"><input type="checkbox" id="pn" ${S.prayerNotify ? 'checked' : ''}> تنبيه عند دخول وقت الصلاة (أثناء فتح التطبيق)</label>
    </div>
    <div class="card"><h3>بياناتك</h3>
      <div class="note" style="margin-top:0">كل بياناتك محفوظة على هذا الجهاز فقط.</div>
      <div class="row" style="margin-top:10px"><button class="btn ghost" id="exp">تصدير نسخة احتياطية</button>
      <label class="btn ghost">استيراد<input type="file" id="imp" accept="application/json" hidden></label></div>
      <button class="btn bad block" id="rst">مسح كل البيانات</button>
    </div>
    <div class="card about">
      <img src="icons/logo.jpg" alt="شعار البشري للتكنولوجيا">
      <h3 style="margin-top:12px">أدوات البشري — الإصدار 1.0</h3>
      <div class="note">من «البشري للتكنولوجيا» · Building meaningful digital products</div>
      <div class="note">أدوات يومية للمواطن السوداني، تعمل دون إنترنت بعد أول فتح.</div>
    </div>`;
  const el = $('#v-settings');
  $('#nm').oninput = (e) => { S.name = e.target.value.trim(); save(); };
  $('#ct').onchange = (e) => { S.city = e.target.value; S.gps = null; save(); renderSettings(); toast('تم تغيير المدينة'); schedulePrayerAlert(); };
  $('#gps').onclick = () => {
    if (S.gps) { S.gps = null; save(); renderSettings(); return; }
    if (!navigator.geolocation) return toast('تحديد الموقع غير مدعوم');
    toast('جارٍ تحديد موقعك…');
    navigator.geolocation.getCurrentPosition((p) => {
      const { latitude: lat, longitude: lng } = p.coords;
      const near = CITIES.reduce((b, c) => ((c.lat - lat) ** 2 + (c.lng - lng) ** 2 < (b.lat - lat) ** 2 + (b.lng - lng) ** 2 ? c : b));
      S.gps = { lat, lng }; S.city = near.id; save(); renderSettings(); schedulePrayerAlert(); toast(`تم: قرب ${near.name}`);
    }, () => toast('تعذّر تحديد الموقع — تحقق من الإذن'), { enableHighAccuracy: true, timeout: 15000 });
  };
  $('#th').onclick = (e) => { const t = e.target.dataset.t; if (!t) return; S.theme = t; save(); applyTheme(); renderSettings(); };
  $('#mt').onchange = (e) => { S.method = e.target.value; save(); schedulePrayerAlert(); };
  $('#as').onchange = (e) => { S.asr = e.target.value; save(); schedulePrayerAlert(); };
  $('#hs').onchange = (e) => { S.hijriShift = +e.target.value; save(); };
  el.querySelectorAll('[data-adj]').forEach((i) => i.oninput = () => { S.adjust[i.dataset.adj] = parseInt(i.value) || 0; save(); schedulePrayerAlert(); });
  $('#pn').onchange = async (e) => {
    if (e.target.checked && 'Notification' in window && Notification.permission !== 'granted') {
      const p = await Notification.requestPermission();
      if (p !== 'granted') { e.target.checked = false; return toast('لم يُمنح إذن التنبيهات'); }
    }
    S.prayerNotify = e.target.checked; save(); schedulePrayerAlert();
  };
  $('#exp').onclick = () => {
    const { wx, rates, ...data } = S;
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }));
    a.download = `albushra-backup-${new Date().toISOString().slice(0, 10)}.json`; a.click();
  };
  $('#imp').onchange = async (e) => {
    try { const d = JSON.parse(await e.target.files[0].text()); S = { ...DEFAULTS, ...d }; save(); toast('تمت الاستعادة ✓'); applyTheme(); renderSettings(); }
    catch { toast('ملف غير صالح'); }
  };
  $('#rst').onclick = () => { if (confirm('سيتم حذف كل بياناتك وإعداداتك من هذا الجهاز. متابعة؟')) { try { localStorage.removeItem(STORE_KEY); } catch { /* */ } location.reload(); } };
}

function renderTool(id) {
  const t = toolById(id);
  if (!t) return go('tools');
  S.recent = [id, ...S.recent.filter((x) => x !== id)].slice(0, 9); save();
  const fav = S.favs.includes(id);
  $('#v-tool').innerHTML = `
    <div class="page-title">
      <h1 style="font-size:24px">${t.name}</h1>
      <button class="round-btn" id="fav" aria-label="المفضلة" style="color:${fav ? 'var(--gold)' : 'var(--muted)'}">${icon('star')}</button>
      <button class="round-btn back" data-back aria-label="رجوع">${icon('back')}</button>
    </div><div id="tool-body"></div>`;
  if (fav) $('#fav svg').style.fill = 'var(--gold)';
  $('#fav').onclick = () => {
    S.favs = S.favs.includes(id) ? S.favs.filter((x) => x !== id) : [...S.favs, id]; save();
    const on = S.favs.includes(id); $('#fav').style.color = on ? 'var(--gold)' : 'var(--muted)'; $('#fav svg').style.fill = on ? 'var(--gold)' : 'none';
    toast(on ? 'أُضيفت للمفضلة ⭐' : 'أُزيلت من المفضلة');
  };
  cleanup = t.render($('#tool-body')) || null;
}

/* ═════════════ التنقل ═════════════ */
function go(route) { location.hash = route; }

function route() {
  if (typeof cleanup === 'function') { try { cleanup(); } catch { /* */ } }
  cleanup = null; clearInterval(homeTimer);
  const [path, arg] = location.hash.slice(1).split('?');
  const [view, id] = (path || 'home').split('/');
  const v = ['home', 'tools', 'prayer', 'settings', 'tool'].includes(view) ? view : 'home';
  document.querySelectorAll('.view').forEach((x) => x.classList.toggle('active', x.id === 'v-' + v));
  document.querySelectorAll('.nav button').forEach((b) => b.classList.toggle('on', b.dataset.go === v || (v === 'tool' && b.dataset.go === 'tools')));
  if (v === 'home') renderHome();
  else if (v === 'tools') { renderTools(); if (arg === 'search') $('#q').focus(); }
  else if (v === 'prayer') renderPrayer();
  else if (v === 'settings') renderSettings();
  else renderTool(id);
  window.scrollTo(0, 0);
}

document.addEventListener('click', (e) => {
  const t = e.target.closest('[data-tool]');
  if (t) return go('tool/' + t.dataset.tool);
  const g = e.target.closest('[data-go]');
  if (g) return go(g.dataset.go);
  if (e.target.closest('[data-back]')) return history.length > 1 ? history.back() : go('tools');
});
window.addEventListener('hashchange', route);

/* ── المظهر ── */
function applyTheme() {
  if (S.theme === 'auto') document.documentElement.removeAttribute('data-theme');
  else document.documentElement.setAttribute('data-theme', S.theme);
}

/* ── تنبيه الصلاة (يعمل أثناء فتح التطبيق أو بقائه في الخلفية القريبة) ── */
let prayerAlertT;
function schedulePrayerAlert() {
  clearTimeout(prayerAlertT);
  if (!S.prayerNotify) return;
  const np = nextPrayer();
  const ms = np.at - Date.now();
  if (ms > 0 && ms < 2 ** 31 - 1) prayerAlertT = setTimeout(() => { notify(`حان الآن موعد صلاة ${PRAYER_NAMES[np.key]} — ${city().name}`, '🕌 أدوات البشري'); beep(); setTimeout(schedulePrayerAlert, 60000); }, ms);
}

/* ── الترحيب لأول مرة ── */
function onboarding() {
  const d = document.createElement('div');
  d.style.cssText = 'position:fixed;inset:0;z-index:150;background:var(--bg);overflow:auto';
  d.innerHTML = `<div class="app" style="padding-bottom:40px">
    <div class="about" style="margin-top:24px"><img src="icons/logo.jpg" alt="" style="width:200px"></div>
    <div class="card" style="margin-top:20px"><h3>أهلًا بك في أدوات البشري 👋</h3>
      <div class="note" style="margin-top:0">أدوات يومية للسودانيين: العملات والتحويلات، الذهب والزكاة، الطاقة الشمسية، مواقيت الصلاة، والمزيد.</div>
      <label class="f">اسمك (اختياري)</label><input class="in" id="o-n">
      <label class="f">مدينتك</label><select class="in" id="o-c">${cityOpts(S.city)}</select>
      <button class="btn block" id="o-go">ابدأ</button></div></div>`;
  document.body.appendChild(d);
  d.querySelector('#o-go').onclick = () => {
    S.name = d.querySelector('#o-n').value.trim(); S.city = d.querySelector('#o-c').value; S.onboarded = true; save();
    d.remove(); route();
  };
}

/* ── التشغيل ── */
applyTheme();
route();
schedulePrayerAlert();
setTimeout(() => $('#splash')?.classList.add('hide'), 700);
setTimeout(() => $('#splash')?.remove(), 1300);
if (!S.onboarded) setTimeout(onboarding, 750);
if ('serviceWorker' in navigator && location.protocol !== 'file:') navigator.serviceWorker.register('sw.js').catch(() => {});
