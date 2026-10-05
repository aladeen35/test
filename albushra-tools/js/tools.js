/* ═══════════════════════════════════════════════
   أدوات البشري — سجل الأدوات
   كل أداة: { id, name, sub, cat, icon, color, render(el) → cleanup? }
   ═══════════════════════════════════════════════ */

const CATS = [
  { id: 'all', name: 'الكل' },
  { id: 'money', name: 'المال والسودان' },
  { id: 'islam', name: 'إسلامية' },
  { id: 'calc', name: 'حاسبات' },
  { id: 'daily', name: 'يومية' },
  { id: 'media', name: 'نصوص وصور' },
  { id: 'device', name: 'الجهاز' },
];

const COLORS = {
  blue: ['#E3EBFF', '#2F64F0'], cyan: ['#DDF6FB', '#0FA3C2'], gold: ['#FFF1D6', '#D98F00'], green: ['#E0F5EA', '#17A673'],
  purple: ['#ECE6FF', '#6E4DE0'], pink: ['#FDE3EA', '#D9416A'], orange: ['#FFE9DC', '#E2662B'], teal: ['#DDF3EF', '#14897A'],
  gray: ['#E9ECF3', '#5D6787'],
};

const opt = (arr, sel) => arr.map(([v, t]) => `<option value="${v}"${v === sel ? ' selected' : ''}>${t}</option>`).join('');
const cityOpts = (sel) => opt(CITIES.map((c) => [c.id, `${c.name} — ${c.state}`]), sel);
const curOpts = (sel) => opt(CURRENCIES.map((c) => [c.code, `${c.flag} ${c.code} — ${c.name}`]), sel);
const num = (v) => { const n = parseFloat(String(v).replace(/,/g, '').replace(/[٠-٩]/g, (d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d))); return isFinite(n) ? n : 0; };

const TOOLS = [
  /* ───────────── المال والسودان ───────────── */
  {
    id: 'currency', name: 'محوّل العملات', sub: 'الرسمي والموازي', cat: 'money', icon: 'swap', color: 'blue', sd: true,
    render(el) {
      el.innerHTML = `
        <div class="card">
          <div class="seg" id="mode"><button data-m="parallel">سعر السوق الموازي</button><button data-m="official">السعر الرسمي</button></div>
          <label class="f">المبلغ</label><input class="in" id="amt" inputmode="decimal" value="100">
          <div class="row"><div><label class="f">من</label><select class="in" id="from">${curOpts(S.curFrom || 'USD')}</select></div>
          <div style="flex:0 0 auto;align-self:end"><button class="round-btn" id="sw" aria-label="تبديل">${icon('swap')}</button></div>
          <div><label class="f">إلى</label><select class="in" id="to">${curOpts(S.curTo || 'SDG')}</select></div></div>
          <div class="result"><div class="big" id="out">—</div><div class="lbl ltr" id="rateLine" style="display:block"></div></div>
          <div class="note" id="upd"></div>
        </div>
        <div class="card"><h3>سعر الدولار في السوق الموازي</h3>
          <div class="row"><input class="in" id="par" inputmode="decimal" placeholder="مثال: 2600" value="${S.sdgParallel || ''}"><button class="btn" id="savePar">حفظ</button></div>
          <div class="note">السعر الرسمي يُحدَّث تلقائيًا من الإنترنت. سعر السوق الموازي يتغير يوميًا، فأدخله أنت من مصدر تثق به، وتُحسب منه بقية العملات.</div>
        </div>
        <div class="card"><h3>كل العملات مقابل الجنيه</h3><div id="all"></div></div>`;
      const $m = el.querySelector('#mode');
      const paint = () => $m.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b.dataset.m === (S.rateMode || 'parallel')));
      const calc = () => {
        const f = el.querySelector('#from').value, t = el.querySelector('#to').value;
        S.curFrom = f; S.curTo = t; save();
        const r = convertRate(f, t);
        el.querySelector('#out').textContent = `${fmtNum(num(el.querySelector('#amt').value) * r)} ${curSym(t)}`;
        el.querySelector('#rateLine').textContent = `1 ${f} = ${fmtNum(r, 4)} ${t}`;
        el.querySelector('#upd').textContent = ratesNote();
        el.querySelector('#all').innerHTML = CURRENCIES.filter((c) => c.code !== 'SDG').map((c) =>
          `<div class="kv"><span>${c.flag} ${c.name}</span><b class="ltr">${fmtNum(convertRate(c.code, 'SDG'))} ج.س</b></div>`).join('');
      };
      paint();
      $m.onclick = (e) => { const m = e.target.dataset.m; if (!m) return; S.rateMode = m; save(); paint(); calc(); };
      el.querySelector('#sw').onclick = () => { const a = el.querySelector('#from'), b = el.querySelector('#to'); [a.value, b.value] = [b.value, a.value]; calc(); };
      el.querySelector('#savePar').onclick = () => { S.sdgParallel = num(el.querySelector('#par').value) || null; S.rateMode = S.sdgParallel ? 'parallel' : S.rateMode; save(); paint(); calc(); toast('تم حفظ سعر السوق'); };
      el.addEventListener('input', calc);
      el.addEventListener('change', calc);
      refreshRates().then(calc);
      calc();
    },
  },
  {
    id: 'remit', name: 'تحويلات المغتربين', sub: 'كم يصل لأهلك؟', cat: 'money', icon: 'send', color: 'cyan', sd: true,
    render(el) {
      el.innerHTML = `
        <div class="card">
          <div class="row"><div><label class="f">المبلغ المُرسَل</label><input class="in" id="a" inputmode="decimal" value="1000"></div>
          <div><label class="f">العملة</label><select class="in" id="c">${curOpts(S.remitCur || 'SAR')}</select></div></div>
          <div class="row"><div><label class="f">رسوم التحويل (ثابتة)</label><input class="in" id="fee" inputmode="decimal" value="0"></div>
          <div><label class="f">عمولة %</label><input class="in" id="pct" inputmode="decimal" value="0"></div></div>
          <label class="f">سعر الصرف (جنيه لكل وحدة) — اتركه فارغًا لاستخدام السعر المحفوظ</label>
          <input class="in" id="r" inputmode="decimal" placeholder="">
          <div class="result"><div class="lbl">يصل للمستلم</div><div class="big" id="out">—</div><div class="lbl" id="det"></div></div>
        </div>
        <div class="card"><h3>المقارنة بين السعرين</h3><div id="cmp"></div></div>`;
      const calc = () => {
        const cur = el.querySelector('#c').value; S.remitCur = cur; save();
        const a = num(el.querySelector('#a').value), fee = num(el.querySelector('#fee').value), pct = num(el.querySelector('#pct').value);
        const auto = convertRate(cur, 'SDG');
        el.querySelector('#r').placeholder = fmtNum(auto, 2);
        const rate = num(el.querySelector('#r').value) || auto;
        const net = Math.max(0, a - fee - (a * pct) / 100);
        el.querySelector('#out').textContent = `${fmtNum(net * rate, 0)} ج.س`;
        el.querySelector('#det').textContent = `صافي بعد الرسوم: ${fmtNum(net)} ${cur} × ${fmtNum(rate)}`;
        const off = convertRate(cur, 'SDG', 'official'), par = convertRate(cur, 'SDG', 'parallel');
        el.querySelector('#cmp').innerHTML = `
          <div class="kv"><span>بالسعر الرسمي</span><b class="ltr">${fmtNum(net * off, 0)} ج.س</b></div>
          <div class="kv"><span>بسعر السوق الموازي</span><b class="ltr">${S.sdgParallel ? fmtNum(net * par, 0) + ' ج.س' : 'أدخل السعر في محوّل العملات'}</b></div>`;
      };
      el.addEventListener('input', calc); el.addEventListener('change', calc);
      refreshRates().then(calc); calc();
    },
  },
  {
    id: 'gold', name: 'حاسبة الذهب', sub: 'العيارات والقيمة', cat: 'money', icon: 'gold', color: 'gold', sd: true,
    render(el) {
      el.innerHTML = `
        <div class="card">
          <label class="f">سعر جرام عيار 21 بالجنيه (من سوق الذهب)</label>
          <input class="in" id="p21" inputmode="decimal" value="${S.gold21 || ''}" placeholder="أدخل السعر اليوم">
          <div id="karats" style="margin-top:12px"></div>
        </div>
        <div class="card"><h3>قيمة مصاغ</h3>
          <div class="row"><div><label class="f">الوزن بالجرام</label><input class="in" id="w" inputmode="decimal" value="10"></div>
          <div><label class="f">العيار</label><select class="in" id="k">${opt([['24', '24'], ['22', '22'], ['21', '21'], ['18', '18']], '21')}</select></div></div>
          <label class="f">مصنعية الجرام (اختياري)</label><input class="in" id="mk" inputmode="decimal" value="0">
          <div class="result"><div class="big" id="out">—</div><div class="lbl">القيمة التقريبية</div></div>
        </div>`;
      const calc = () => {
        const p21 = num(el.querySelector('#p21').value); S.gold21 = p21 || null; save();
        const pk = (k) => (p21 / 21) * k;
        el.querySelector('#karats').innerHTML = p21 ? [24, 22, 21, 18].map((k) =>
          `<div class="kv"><span>عيار ${k}</span><b class="ltr">${fmtNum(pk(k), 0)} ج.س / جرام</b></div>`).join('') : '<div class="note">أدخل السعر لعرض بقية العيارات.</div>';
        const w = num(el.querySelector('#w').value), k = +el.querySelector('#k').value, mk = num(el.querySelector('#mk').value);
        el.querySelector('#out').textContent = p21 ? `${fmtNum(w * (pk(k) + mk), 0)} ج.س` : '—';
      };
      el.addEventListener('input', calc); el.addEventListener('change', calc); calc();
    },
  },
  {
    id: 'zakat', name: 'حاسبة الزكاة', sub: 'المال والذهب', cat: 'money', icon: 'heart', color: 'green',
    render(el) {
      el.innerHTML = `
        <div class="card">
          <label class="f">سعر جرام الذهب عيار 24 (لحساب النصاب)</label>
          <input class="in" id="g24" inputmode="decimal" value="${S.gold21 ? Math.round((S.gold21 / 21) * 24) : ''}">
          <label class="f">النقد في اليد والبنك (بنكك وغيره)</label><input class="in" id="cash" inputmode="decimal" value="0">
          <label class="f">قيمة الذهب والفضة المدخر</label><input class="in" id="gold" inputmode="decimal" value="0">
          <label class="f">قيمة عروض التجارة (البضاعة)</label><input class="in" id="trade" inputmode="decimal" value="0">
          <label class="f">ديون لك مرجوّة السداد</label><input class="in" id="rec" inputmode="decimal" value="0">
          <label class="f">ديون عليك حالّة</label><input class="in" id="debt" inputmode="decimal" value="0">
          <div class="result"><div class="lbl">الزكاة الواجبة (2.5%)</div><div class="big" id="out">—</div><div class="lbl" id="det"></div></div>
          <div class="hint">النصاب = قيمة 85 جرامًا من الذهب عيار 24 بشرط مرور حول هجري كامل. هذه الحاسبة تقديرية، وللحالات الخاصة راجع أهل العلم أو ديوان الزكاة.</div>
        </div>`;
      const calc = () => {
        const v = (id) => num(el.querySelector('#' + id).value);
        const total = v('cash') + v('gold') + v('trade') + v('rec') - v('debt');
        const nisab = v('g24') * 85;
        const due = nisab && total >= nisab ? total * 0.025 : 0;
        el.querySelector('#out').textContent = `${fmtNum(due, 0)} ج.س`;
        el.querySelector('#det').textContent = nisab ? `الوعاء الزكوي: ${fmtNum(total, 0)} — النصاب: ${fmtNum(nisab, 0)}${total < nisab ? ' (لم يبلغ النصاب)' : ''}` : 'أدخل سعر الذهب لمعرفة النصاب';
      };
      el.addEventListener('input', calc); calc();
    },
  },
  {
    id: 'power', name: 'الكهرباء والطاقة الشمسية', sub: 'الاستهلاك والمنظومة', cat: 'money', icon: 'sun', color: 'orange', sd: true,
    render(el) {
      if (!S.appliances) S.appliances = [
        { n: 'لمبة LED', w: 12, q: 4, h: 6 }, { n: 'مروحة سقف', w: 75, q: 2, h: 10 },
        { n: 'ثلاجة', w: 150, q: 1, h: 10 }, { n: 'تلفزيون', w: 100, q: 1, h: 5 }, { n: 'شاحن هاتف', w: 10, q: 3, h: 3 },
      ];
      el.innerHTML = `
        <div class="card"><h3>الأجهزة</h3><div id="list"></div>
          <div class="row" style="margin-top:10px"><input class="in" id="nn" placeholder="اسم الجهاز"><input class="in" id="nw" inputmode="decimal" placeholder="واط"></div>
          <div class="row" style="margin-top:8px"><input class="in" id="nq" inputmode="numeric" placeholder="العدد"><input class="in" id="nh" inputmode="decimal" placeholder="ساعات/يوم"><button class="btn" id="add">${icon('plus')}</button></div>
        </div>
        <div class="card"><h3>الاستهلاك والتكلفة</h3>
          <label class="f">سعر الكيلوواط ساعة (ج.س)</label><input class="in" id="price" inputmode="decimal" value="${S.kwhPrice || ''}" placeholder="حسب تعرفة الكهرباء">
          <div id="use" style="margin-top:10px"></div></div>
        <div class="card"><h3>تصميم منظومة شمسية</h3>
          <div class="row"><div><label class="f">ساعات الشمس الفعّالة</label><input class="in" id="sun" inputmode="decimal" value="6"></div>
          <div><label class="f">قدرة اللوح (واط)</label><input class="in" id="pw" inputmode="decimal" value="550"></div></div>
          <div class="row"><div><label class="f">جهد البطاريات (فولت)</label><select class="in" id="v">${opt([['12', '12'], ['24', '24'], ['48', '48']], '24')}</select></div>
          <div><label class="f">ساعات التشغيل على البطارية</label><input class="in" id="bh" inputmode="decimal" value="12"></div></div>
          <div id="solar" style="margin-top:10px"></div>
          <div class="note">تقديرات أولية لمساعدتك عند التفاوض مع الفنّي، تشمل هامش أمان 25% وتفريغ بطارية 50% (رصاص) .</div></div>`;
      const draw = () => {
        el.querySelector('#list').innerHTML = S.appliances.map((a, i) => `
          <div class="list-item"><div class="grow"><b>${esc(a.n)}</b><div class="note" style="margin:0">${a.q} × ${a.w} واط × ${a.h} ساعة</div></div>
          <button class="icon-btn" data-del="${i}" aria-label="حذف">${icon('trash')}</button></div>`).join('') || '<div class="empty">أضف أجهزتك</div>';
        calc();
      };
      const calc = () => {
        S.kwhPrice = num(el.querySelector('#price').value) || null; save();
        const load = S.appliances.reduce((s, a) => s + a.w * a.q, 0);
        const wh = S.appliances.reduce((s, a) => s + a.w * a.q * a.h, 0);
        const kwhM = (wh / 1000) * 30;
        el.querySelector('#use').innerHTML = `
          <div class="kv"><span>الحمل الكلي</span><b class="ltr">${fmtNum(load, 0)} W</b></div>
          <div class="kv"><span>الاستهلاك اليومي</span><b class="ltr">${fmtNum(wh / 1000, 2)} kWh</b></div>
          <div class="kv"><span>الاستهلاك الشهري</span><b class="ltr">${fmtNum(kwhM, 1)} kWh</b></div>
          ${S.kwhPrice ? `<div class="kv"><span>التكلفة الشهرية</span><b class="ltr">${fmtNum(kwhM * S.kwhPrice, 0)} ج.س</b></div>` : ''}`;
        const sun = num(el.querySelector('#sun').value) || 6, pw = num(el.querySelector('#pw').value) || 550;
        const V = +el.querySelector('#v').value, bh = num(el.querySelector('#bh').value);
        const inverter = load * 1.25;
        const panels = Math.ceil((wh * 1.25) / (sun * pw * 0.8));
        const nightWh = bh ? (wh * Math.min(bh, 24)) / 24 : 0;
        const ah = (nightWh / V / 0.5) * 1.1;
        el.querySelector('#solar').innerHTML = `
          <div class="kv"><span>قدرة الإنفرتر المقترحة</span><b class="ltr">${fmtNum(Math.ceil(inverter / 500) * 0.5, 1)} kW</b></div>
          <div class="kv"><span>عدد الألواح (${pw} واط)</span><b>${panels}</b></div>
          <div class="kv"><span>سعة البطاريات</span><b class="ltr">${fmtNum(Math.ceil(ah / 10) * 10, 0)} Ah @ ${V}V</b></div>
          <div class="kv"><span>مثال: بطاريات 200Ah / 12V</span><b>${Math.ceil(ah / 200) * (V / 12)} بطارية</b></div>`;
      };
      el.querySelector('#list').onclick = (e) => { const b = e.target.closest('[data-del]'); if (!b) return; S.appliances.splice(+b.dataset.del, 1); save(); draw(); };
      el.querySelector('#add').onclick = () => {
        const n = el.querySelector('#nn').value.trim(), w = num(el.querySelector('#nw').value);
        if (!n || !w) return toast('أدخل الاسم والقدرة');
        S.appliances.push({ n, w, q: num(el.querySelector('#nq').value) || 1, h: num(el.querySelector('#nh').value) || 1 });
        save(); ['#nn', '#nw', '#nq', '#nh'].forEach((s) => (el.querySelector(s).value = '')); draw();
      };
      el.addEventListener('input', (e) => { if (!e.target.closest('.row') || ['price', 'sun', 'pw', 'bh'].includes(e.target.id)) calc(); });
      el.addEventListener('change', calc);
      draw();
    },
  },
  {
    id: 'units', name: 'محوّل الوحدات', sub: 'فدان، جوال، جركانة…', cat: 'money', icon: 'ruler', color: 'teal', sd: true,
    render(el) {
      el.innerHTML = `
        <div class="card">
          <div class="cat-chips" id="cats">${Object.entries(UNITS).map(([k, u]) => `<button class="chip" data-k="${k}">${u.name}</button>`).join('')}</div>
          <label class="f">القيمة</label><input class="in" id="v" inputmode="decimal" value="1">
          <div class="row"><div><label class="f">من</label><select class="in" id="f"></select></div><div><label class="f">إلى</label><select class="in" id="t"></select></div></div>
          <div class="result"><div class="big" id="out">—</div></div>
          <div id="all" style="margin-top:12px"></div>
        </div>`;
      let cat = S.unitCat || 'area';
      const conv = (v, f, t) => {
        if (cat === 'temp') {
          const c = f === 'c' ? v : f === 'f' ? (v - 32) * 5 / 9 : v - 273.15;
          return t === 'c' ? c : t === 'f' ? c * 9 / 5 + 32 : c + 273.15;
        }
        const L = UNITS[cat].list, a = L.find((x) => x[0] === f)[2], b = L.find((x) => x[0] === t)[2];
        return (v * a) / b;
      };
      const setCat = () => {
        S.unitCat = cat; save();
        el.querySelectorAll('#cats .chip').forEach((c) => c.classList.toggle('on', c.dataset.k === cat));
        const L = UNITS[cat].list.map((x) => [x[0], x[1]]);
        el.querySelector('#f').innerHTML = opt(L, L[cat === 'area' ? 1 : 0][0]);
        el.querySelector('#t').innerHTML = opt(L, L[cat === 'area' ? 0 : 1][0]);
        calc();
      };
      const calc = () => {
        const v = num(el.querySelector('#v').value), f = el.querySelector('#f').value, t = el.querySelector('#t').value;
        const name = (k) => UNITS[cat].list.find((x) => x[0] === k)[1];
        el.querySelector('#out').textContent = `${fmtNum(conv(v, f, t), 6)} ${name(t)}`;
        el.querySelector('#all').innerHTML = UNITS[cat].list.filter((x) => x[0] !== f).map((x) =>
          `<div class="kv"><span>${x[1]}</span><b class="ltr">${fmtNum(conv(v, f, x[0]), 6)}</b></div>`).join('');
      };
      el.querySelector('#cats').onclick = (e) => { const k = e.target.dataset.k; if (k) { cat = k; setCat(); } };
      el.addEventListener('input', calc); el.addEventListener('change', (e) => e.target.tagName === 'SELECT' && calc());
      setCat();
    },
  },
  {
    id: 'loan', name: 'الأقساط والمرابحة', sub: 'القسط الشهري', cat: 'calc', icon: 'bank', color: 'purple',
    render(el) {
      el.innerHTML = `
        <div class="card">
          <div class="seg" id="mode"><button data-m="flat" class="on">مرابحة (ربح ثابت)</button><button data-m="amort">قرض متناقص</button></div>
          <label class="f">سعر السلعة / المبلغ</label><input class="in" id="p" inputmode="decimal" value="1000000">
          <label class="f">الدفعة المقدمة</label><input class="in" id="d" inputmode="decimal" value="0">
          <div class="row"><div><label class="f">نسبة الربح السنوية %</label><input class="in" id="r" inputmode="decimal" value="20"></div>
          <div><label class="f">عدد الأشهر</label><input class="in" id="n" inputmode="numeric" value="12"></div></div>
          <div class="result"><div class="lbl">القسط الشهري</div><div class="big" id="out">—</div></div>
          <div id="det" style="margin-top:10px"></div>
        </div>`;
      let mode = 'flat';
      const calc = () => {
        const P = Math.max(0, num(el.querySelector('#p').value) - num(el.querySelector('#d').value));
        const r = num(el.querySelector('#r').value) / 100, n = Math.max(1, Math.round(num(el.querySelector('#n').value)));
        let m, total;
        if (mode === 'flat') { total = P * (1 + r * (n / 12)); m = total / n; }
        else { const i = r / 12; m = i ? (P * i) / (1 - Math.pow(1 + i, -n)) : P / n; total = m * n; }
        el.querySelector('#out').textContent = fmtNum(m, 0);
        el.querySelector('#det').innerHTML = `
          <div class="kv"><span>المبلغ الممول</span><b class="ltr">${fmtNum(P, 0)}</b></div>
          <div class="kv"><span>إجمالي السداد</span><b class="ltr">${fmtNum(total, 0)}</b></div>
          <div class="kv"><span>إجمالي الربح/الفائدة</span><b class="ltr">${fmtNum(total - P, 0)}</b></div>`;
      };
      el.querySelector('#mode').onclick = (e) => { const m = e.target.dataset.m; if (!m) return; mode = m; el.querySelectorAll('#mode button').forEach((b) => b.classList.toggle('on', b.dataset.m === m)); calc(); };
      el.addEventListener('input', calc); calc();
    },
  },
  {
    id: 'percent', name: 'النسب والضريبة', sub: 'خصم، زيادة، ضريبة', cat: 'calc', icon: 'percent', color: 'pink',
    render(el) {
      el.innerHTML = `
        <div class="card"><h3>ضريبة القيمة المضافة</h3>
          <div class="row"><div><label class="f">المبلغ</label><input class="in" id="va" inputmode="decimal" value="1000"></div>
          <div><label class="f">النسبة %</label><input class="in" id="vr" inputmode="decimal" value="${S.vat ?? 17}"></div></div>
          <div id="vout" style="margin-top:10px"></div></div>
        <div class="card"><h3>الخصم</h3>
          <div class="row"><div><label class="f">السعر</label><input class="in" id="da" inputmode="decimal" value="5000"></div>
          <div><label class="f">الخصم %</label><input class="in" id="dr" inputmode="decimal" value="10"></div></div>
          <div id="dout" style="margin-top:10px"></div></div>
        <div class="card"><h3>نسبة التغيّر</h3>
          <div class="row"><div><label class="f">القيمة القديمة</label><input class="in" id="o" inputmode="decimal" value="100"></div>
          <div><label class="f">القيمة الجديدة</label><input class="in" id="nw" inputmode="decimal" value="150"></div></div>
          <div id="cout" style="margin-top:10px"></div></div>`;
      const v = (id) => num(el.querySelector('#' + id).value);
      const calc = () => {
        S.vat = v('vr'); save();
        const a = v('va'), r = v('vr') / 100;
        el.querySelector('#vout').innerHTML = `
          <div class="kv"><span>المبلغ + الضريبة</span><b class="ltr">${fmtNum(a * (1 + r))}</b></div>
          <div class="kv"><span>قيمة الضريبة</span><b class="ltr">${fmtNum(a * r)}</b></div>
          <div class="kv"><span>إن كان المبلغ شاملًا: قبل الضريبة</span><b class="ltr">${fmtNum(a / (1 + r))}</b></div>`;
        el.querySelector('#dout').innerHTML = `
          <div class="kv"><span>السعر بعد الخصم</span><b class="ltr">${fmtNum(v('da') * (1 - v('dr') / 100))}</b></div>
          <div class="kv"><span>التوفير</span><b class="ltr">${fmtNum(v('da') * v('dr') / 100)}</b></div>`;
        const o = v('o'), ch = o ? ((v('nw') - o) / o) * 100 : 0;
        el.querySelector('#cout').innerHTML = `<div class="kv"><span>${ch >= 0 ? 'زيادة' : 'نقص'}</span><b class="ltr">${fmtNum(Math.abs(ch), 2)}%</b></div>`;
      };
      el.addEventListener('input', calc); calc();
    },
  },
  {
    id: 'split', name: 'تقسيم الحساب', sub: 'الفطور والرحلات', cat: 'calc', icon: 'users', color: 'cyan',
    render(el) {
      el.innerHTML = `
        <div class="card">
          <label class="f">إجمالي الحساب</label><input class="in" id="t" inputmode="decimal" value="30000">
          <div class="row"><div><label class="f">عدد الأشخاص</label><input class="in" id="n" inputmode="numeric" value="4"></div>
          <div><label class="f">خدمة/إضافة %</label><input class="in" id="x" inputmode="decimal" value="0"></div></div>
          <div class="row"><div><label class="f">تقريب لأقرب</label><select class="in" id="rd">${opt([['1', 'بدون'], ['100', '100'], ['500', '500'], ['1000', '1000']], '100')}</select></div></div>
          <div class="result"><div class="lbl">على كل شخص</div><div class="big" id="out">—</div><div class="lbl" id="det"></div></div>
        </div>`;
      const calc = () => {
        const t = num(el.querySelector('#t').value) * (1 + num(el.querySelector('#x').value) / 100);
        const n = Math.max(1, Math.round(num(el.querySelector('#n').value))), rd = +el.querySelector('#rd').value;
        const each = Math.ceil(t / n / rd) * rd;
        el.querySelector('#out').textContent = fmtNum(each, 2);
        el.querySelector('#det').textContent = `الإجمالي ${fmtNum(t)}${rd > 1 ? ` — الفائض بعد التقريب ${fmtNum(each * n - t)}` : ''}`;
      };
      el.addEventListener('input', calc); el.addEventListener('change', calc); calc();
    },
  },

  /* ───────────── إسلامية ───────────── */
  {
    id: 'qibla', name: 'اتجاه القبلة', sub: 'بوصلة', cat: 'islam', icon: 'compass', color: 'green',
    render(el) {
      const c = city();
      const q = PrayerCalc.qibla(c.lat, c.lng);
      el.innerHTML = `
        <div class="card" style="text-align:center">
          <div class="compass"><div class="dial" id="dial"><span class="n">N</span>
            <svg class="needle" id="needle" viewBox="0 0 240 240" style="transform:rotate(${q}deg)"><path d="M120 22 L132 120 L120 112 L108 120 Z" fill="#17A673"/><text x="120" y="18" text-anchor="middle" font-size="16">🕋</text><circle cx="120" cy="120" r="8" fill="#5D6787"/></svg>
          </div></div>
          <div class="result"><div class="big">${fmtNum(q, 1)}°</div><div class="lbl">من الشمال باتجاه عقارب الساعة — ${c.name}</div></div>
          <div class="note">المسافة إلى مكة المكرمة: ${fmtNum(PrayerCalc.distanceToMakkah(c.lat, c.lng), 0)} كم</div>
          <button class="btn block" id="go">${icon('compass')} تشغيل البوصلة</button>
          <div class="note" id="st">ضع الهاتف أفقيًا بعيدًا عن المعادن، وحرّكه على شكل رقم 8 لمعايرة البوصلة.</div>
        </div>`;
      let handler;
      const onOri = (e) => {
        let heading = e.webkitCompassHeading ?? (e.absolute || e.type === 'deviceorientationabsolute' ? 360 - e.alpha : null);
        if (heading == null) { el.querySelector('#st').textContent = 'البوصلة غير متاحة على هذا الجهاز — استخدم الزاوية المعروضة.'; return; }
        el.querySelector('#dial').style.transform = `rotate(${-heading}deg)`;
        const diff = Math.abs(((q - heading + 540) % 360) - 180);
        el.querySelector('#st').textContent = diff < 5 ? '✅ أنت باتجاه القبلة' : `أدِر الهاتف ${fmtNum(diff, 0)}°`;
        if (diff < 5 && navigator.vibrate) navigator.vibrate(30);
      };
      el.querySelector('#go').onclick = async () => {
        try { if (typeof DeviceOrientationEvent !== 'undefined' && DeviceOrientationEvent.requestPermission) await DeviceOrientationEvent.requestPermission(); } catch (e) { /* رفض المستخدم */ }
        handler = onOri;
        window.addEventListener('ondeviceorientationabsolute' in window ? 'deviceorientationabsolute' : 'deviceorientation', handler);
      };
      return () => { window.removeEventListener('deviceorientationabsolute', handler); window.removeEventListener('deviceorientation', handler); };
    },
  },
  {
    id: 'adhkar', name: 'أذكار الصباح والمساء', sub: 'مع العدّاد', cat: 'islam', icon: 'book', color: 'purple',
    render(el) {
      const h = +new Intl.DateTimeFormat('en', { timeZone: TZ, hour: 'numeric', hour12: false }).format(new Date());
      let kind = h >= 3 && h < 15 ? 'morning' : 'evening';
      const draw = () => {
        const counts = ADHKAR[kind].map((d) => d.n);
        el.innerHTML = `
          <div class="seg" id="k" style="margin-bottom:14px"><button data-k="morning">☀️ الصباح</button><button data-k="evening">🌙 المساء</button></div>
          ${ADHKAR[kind].map((d, i) => `
            <div class="card dhikr-card" data-i="${i}">
              <div class="dhikr">${d.t}</div>
              <button class="btn ghost block" data-i="${i}">اضغط للعدّ — <span>${d.n}</span></button>
            </div>`).join('')}`;
        el.querySelectorAll('#k button').forEach((b) => b.classList.toggle('on', b.dataset.k === kind));
        el.querySelector('#k').onclick = (e) => { if (e.target.dataset.k) { kind = e.target.dataset.k; draw(); } };
        el.querySelectorAll('button[data-i]').forEach((b) => b.onclick = () => {
          const i = +b.dataset.i; if (counts[i] <= 0) return;
          counts[i]--; b.querySelector('span').textContent = counts[i];
          if (navigator.vibrate) navigator.vibrate(15);
          if (!counts[i]) { b.closest('.card').classList.add('done'); b.textContent = '✔ تم'; }
        });
      };
      draw();
    },
  },
  {
    id: 'tasbih', name: 'المسبحة', sub: 'سبحة إلكترونية', cat: 'islam', icon: 'beads', color: 'teal',
    render(el) {
      S.tasbih = S.tasbih || { dhikr: TASBIH_PRESETS[0], count: 0, target: 33, total: 0 };
      const T = S.tasbih;
      el.innerHTML = `
        <div class="card" style="text-align:center">
          <select class="in" id="d">${opt(TASBIH_PRESETS.map((x) => [x, x]), T.dhikr)}</select>
          <div class="row" style="margin-top:10px"><select class="in" id="tg">${opt([['33', '33'], ['99', '99'], ['100', '100'], ['1000', '1000'], ['0', 'بلا حد']], String(T.target))}</select>
          <button class="btn ghost" id="rs">تصفير</button></div>
          <button class="counter-btn" id="c">${T.count}</button>
          <div class="lbl" id="info"></div>
        </div>`;
      const paint = () => {
        el.querySelector('#c').textContent = T.count;
        el.querySelector('#info').textContent = `${T.target ? `الهدف ${T.target} — ` : ''}المجموع الكلي: ${fmtNum(T.total, 0)}`;
      };
      el.querySelector('#c').onclick = () => {
        T.count++; T.total++;
        if (T.target && T.count >= T.target) { if (navigator.vibrate) navigator.vibrate([80, 60, 80]); toast(`أتممت ${T.target} 🌿`); T.count = 0; }
        else if (navigator.vibrate) navigator.vibrate(12);
        save(); paint();
      };
      el.querySelector('#d').onchange = (e) => { T.dhikr = e.target.value; T.count = 0; save(); paint(); };
      el.querySelector('#tg').onchange = (e) => { T.target = +e.target.value; save(); paint(); };
      el.querySelector('#rs').onclick = () => { T.count = 0; save(); paint(); };
      paint();
    },
  },
  {
    id: 'monthly', name: 'المواقيت الشهرية', sub: 'وإمساكية رمضان', cat: 'islam', icon: 'table', color: 'blue',
    render(el) {
      const now = sdParts();
      el.innerHTML = `
        <div class="card">
          <div class="row"><select class="in" id="c">${cityOpts(S.city)}</select></div>
          <div class="row" style="margin-top:8px"><select class="in" id="m">${opt(Array.from({ length: 12 }, (_, i) => [String(i + 1), fmtDate(new Date(Date.UTC(2000, i, 15)), { month: 'long' })]), String(now.m))}</select>
          <input class="in" id="y" inputmode="numeric" value="${now.y}"></div>
          <div class="tbl-wrap" style="margin-top:12px"><table class="tbl" id="t"></table></div>
          <button class="btn ghost block" id="pr">طباعة / حفظ PDF</button>
        </div>`;
      const draw = () => {
        const c = CITIES.find((x) => x.id === el.querySelector('#c').value);
        const y = +el.querySelector('#y').value, m = +el.querySelector('#m').value;
        const days = new Date(Date.UTC(y, m, 0)).getUTCDate();
        let rows = '';
        for (let d = 1; d <= days; d++) {
          const t = PrayerCalc.times(y, m, d, c.lat, c.lng, prayerOpts());
          const isToday = y === now.y && m === now.m && d === now.d;
          const hj = hijri(new Date(Date.UTC(y, m - 1, d, 10)), S.hijriShift || 0);
          rows += `<tr class="${isToday ? 'today' : ''}"><td>${d}<div class="note" style="margin:0">${hj.d} ${HIJRI_MONTHS[hj.m - 1]}</div></td>${PRAYER_ORDER.map((k) => `<td class="ltr">${fmtTime(t[k]).replace(/\s?[صم]$/, '')}</td>`).join('')}</tr>`;
        }
        el.querySelector('#t').innerHTML = `<tr><th>اليوم</th>${PRAYER_ORDER.map((k) => `<th>${PRAYER_NAMES[k]}</th>`).join('')}</tr>${rows}`;
      };
      el.addEventListener('change', draw); el.querySelector('#y').addEventListener('input', draw);
      el.querySelector('#pr').onclick = () => window.print();
      draw();
    },
  },
  {
    id: 'hijri', name: 'محوّل التاريخ', sub: 'هجري ⇄ ميلادي', cat: 'islam', icon: 'calendar', color: 'gold',
    render(el) {
      const today = new Date().toISOString().slice(0, 10);
      const h = hijri(new Date(), S.hijriShift || 0);
      el.innerHTML = `
        <div class="card"><h3>ميلادي ← هجري</h3>
          <input class="in" type="date" id="g" value="${today}">
          <div class="result"><div class="big" id="go" style="font-size:24px">—</div></div></div>
        <div class="card"><h3>هجري ← ميلادي</h3>
          <div class="row"><input class="in" id="hd" inputmode="numeric" value="${h.d}">
          <select class="in" id="hm">${opt(HIJRI_MONTHS.map((n, i) => [String(i + 1), n]), String(h.m))}</select>
          <input class="in" id="hy" inputmode="numeric" value="${h.y}"></div>
          <div class="result"><div class="big" id="ho" style="font-size:24px">—</div></div>
          <div class="note">حسب تقويم أم القرى، وقد يختلف يومًا حسب رؤية الهلال في السودان (عدّل الفرق من الإعدادات).</div></div>`;
      const calc = () => {
        const g = el.querySelector('#g').value;
        if (g) { const [y, m, d] = g.split('-').map(Number); el.querySelector('#go').textContent = hijri(new Date(Date.UTC(y, m - 1, d, 10)), S.hijriShift || 0).text; }
        const r = hijriToGregorian(+el.querySelector('#hy').value, +el.querySelector('#hm').value, +el.querySelector('#hd').value);
        el.querySelector('#ho').textContent = r ? fmtDate(new Date(r.getTime() - (S.hijriShift || 0) * 86400000)) : 'تاريخ غير صالح';
      };
      el.addEventListener('input', calc); el.addEventListener('change', calc); calc();
    },
  },

  /* ───────────── حاسبات ويومية ───────────── */
  {
    id: 'calc', name: 'الآلة الحاسبة', sub: 'علمية', cat: 'calc', icon: 'calc', color: 'gray',
    render(el) {
      el.innerHTML = `
        <div class="card">
          <div class="calc-screen"><div class="expr" id="e"></div><div class="val" id="v">0</div></div>
          <div class="calc-keys" id="k">
            ${['C', '(', ')', '÷', 'sin', 'cos', 'tan', '√', '7', '8', '9', '×', '4', '5', '6', '−', '1', '2', '3', '+', '%', '0', '.', '⌫', 'π', '^', 'ANS', '=']
              .map((x) => `<button class="${'÷×−+^'.includes(x) ? 'op' : x === '=' ? 'eq' : /[a-zA-Z√πC⌫%()]/.test(x) ? 'fn' : ''}">${x}</button>`).join('')}
          </div></div>`;
      let expr = '', ans = 0;
      const show = (v) => { el.querySelector('#e').textContent = expr; el.querySelector('#v').textContent = v ?? (preview() ?? '0'); };
      const evaluate = (s) => {
        const js = s.replace(/×/g, '*').replace(/÷/g, '/').replace(/−/g, '-').replace(/\^/g, '**').replace(/π/g, '(Math.PI)')
          .replace(/ANS/g, `(${ans})`).replace(/√/g, 'Math.sqrt').replace(/(sin|cos|tan)\(/g, (m, f) => `Math.${f}(Math.PI/180*`)
          .replace(/(\d+(\.\d+)?)%/g, '($1/100)');
        if (!/^[\d+\-*/().\sMathPIsqrtincos]*$/.test(js)) throw new Error('bad');
        const r = Function(`"use strict";return (${js})`)();
        if (!isFinite(r)) throw new Error('nan');
        return +r.toPrecision(12);
      };
      const preview = () => { try { return expr ? fmtNum(evaluate(expr), 10) : null; } catch { return null; } };
      el.querySelector('#k').onclick = (e) => {
        const x = e.target.closest('button')?.textContent; if (!x) return;
        if (x === 'C') expr = '';
        else if (x === '⌫') expr = expr.replace(/(sin\(|cos\(|tan\(|√\(|ANS|.)$/, '');
        else if (x === '=') { try { ans = evaluate(expr); expr = String(ans); return show(fmtNum(ans, 10)); } catch { return show('خطأ'); } }
        else if (['sin', 'cos', 'tan', '√'].includes(x)) expr += x + '(';
        else expr += x;
        show();
      };
      show();
    },
  },
  {
    id: 'age', name: 'حاسبة العمر', sub: 'بالتفصيل', cat: 'daily', icon: 'cake', color: 'pink',
    render(el) {
      el.innerHTML = `
        <div class="card"><label class="f">تاريخ الميلاد</label><input class="in" type="date" id="b" value="${S.birth || '2000-01-01'}">
          <div class="result"><div class="big" id="out" style="font-size:26px">—</div></div><div id="det" style="margin-top:10px"></div></div>`;
      const calc = () => {
        const v = el.querySelector('#b').value; if (!v) return; S.birth = v; save();
        const b = new Date(v + 'T00:00'), n = new Date();
        let y = n.getFullYear() - b.getFullYear(), m = n.getMonth() - b.getMonth(), d = n.getDate() - b.getDate();
        if (d < 0) { m--; d += new Date(n.getFullYear(), n.getMonth(), 0).getDate(); }
        if (m < 0) { y--; m += 12; }
        const days = Math.floor((n - b) / 86400000);
        let next = new Date(n.getFullYear(), b.getMonth(), b.getDate()); if (next < n) next.setFullYear(n.getFullYear() + 1);
        const hb = hijri(new Date(Date.UTC(b.getFullYear(), b.getMonth(), b.getDate(), 10))), hn = hijri(n);
        el.querySelector('#out').textContent = `${y} سنة و${m} شهر و${d} يوم`;
        el.querySelector('#det').innerHTML = `
          <div class="kv"><span>العمر بالأيام</span><b>${fmtNum(days, 0)}</b></div>
          <div class="kv"><span>العمر بالأسابيع</span><b>${fmtNum(Math.floor(days / 7), 0)}</b></div>
          <div class="kv"><span>العمر الهجري التقريبي</span><b>${hn.y - hb.y - (hn.m < hb.m || (hn.m === hb.m && hn.d < hb.d) ? 1 : 0)} سنة</b></div>
          <div class="kv"><span>تاريخ الميلاد هجريًا</span><b>${hb.text}</b></div>
          <div class="kv"><span>عيد الميلاد القادم بعد</span><b>${Math.ceil((next - n) / 86400000)} يوم</b></div>
          <div class="kv"><span>يوم الميلاد</span><b>${fmtDate(b, { weekday: 'long' })}</b></div>`;
      };
      el.addEventListener('input', calc); calc();
    },
  },
  {
    id: 'countdown', name: 'عدّاد المناسبات', sub: 'رمضان، العيد، مواعيدك', cat: 'daily', icon: 'hourglass', color: 'orange',
    render(el) {
      const h = hijri();
      const nextHijri = (m, d) => { let y = h.y; let g = hijriToGregorian(y, m, d); if (!g || g < new Date()) g = hijriToGregorian(y + 1, m, d); return g; };
      const fixed = [['رمضان', nextHijri(9, 1)], ['عيد الفطر', nextHijri(10, 1)], ['يوم عرفة', nextHijri(12, 9)], ['عيد الأضحى', nextHijri(12, 10)], ['رأس السنة الهجرية', nextHijri(1, 1)]];
      S.events = S.events || [];
      el.innerHTML = `
        <div class="card"><h3>مناسباتي</h3><div id="mine"></div>
          <div class="row" style="margin-top:10px"><input class="in" id="n" placeholder="اسم المناسبة"><input class="in" type="date" id="d"></div>
          <button class="btn block" id="add">${icon('plus')} إضافة</button></div>
        <div class="card"><h3>مناسبات إسلامية (تقديرية)</h3><div id="fx"></div></div>`;
      const left = (d) => { const ms = d - new Date(); if (ms < 0) return 'مضت'; const days = Math.floor(ms / 86400000); return days ? `${days} يوم` : `${Math.floor(ms / 3600000)} ساعة`; };
      const draw = () => {
        el.querySelector('#fx').innerHTML = fixed.map(([n, d]) => `<div class="kv"><span>${n}<div class="note" style="margin:0">${d ? fmtDate(d) : ''}</div></span><b>${d ? left(d) : '—'}</b></div>`).join('');
        el.querySelector('#mine').innerHTML = S.events.map((e, i) => `<div class="list-item"><div class="grow"><b>${esc(e.n)}</b><div class="note" style="margin:0">${fmtDate(new Date(e.d + 'T12:00'))}</div></div><b>${left(new Date(e.d + 'T00:00'))}</b><button class="icon-btn" data-del="${i}">${icon('trash')}</button></div>`).join('') || '<div class="empty">لا مناسبات بعد</div>';
      };
      el.querySelector('#add').onclick = () => {
        const n = el.querySelector('#n').value.trim(), d = el.querySelector('#d').value;
        if (!n || !d) return toast('أدخل الاسم والتاريخ');
        S.events.push({ n, d }); S.events.sort((a, b) => a.d.localeCompare(b.d)); save(); draw();
      };
      el.querySelector('#mine').onclick = (e) => { const b = e.target.closest('[data-del]'); if (b) { S.events.splice(+b.dataset.del, 1); save(); draw(); } };
      draw();
    },
  },
  {
    id: 'stopwatch', name: 'المؤقت والإيقاف', sub: 'ساعة إيقاف وعدّ تنازلي', cat: 'daily', icon: 'timer', color: 'blue',
    render(el) {
      el.innerHTML = `
        <div class="seg" id="mode" style="margin-bottom:14px"><button data-m="sw" class="on">ساعة إيقاف</button><button data-m="tm">مؤقت</button></div>
        <div class="card" id="sw"><div class="big-display" id="d">00:00.0</div>
          <div class="row"><button class="btn" id="go">بدء</button><button class="btn ghost" id="lap">لفة</button><button class="btn ghost" id="rs">تصفير</button></div><div id="laps"></div></div>
        <div class="card" id="tm" style="display:none">
          <div class="row"><div><label class="f">دقائق</label><input class="in" id="mm" inputmode="numeric" value="5"></div><div><label class="f">ثواني</label><input class="in" id="ss" inputmode="numeric" value="0"></div></div>
          <div class="big-display" id="td">05:00</div>
          <div class="row"><button class="btn" id="tgo">بدء</button><button class="btn ghost" id="trs">إعادة</button></div></div>`;
      const pad = (n) => String(n).padStart(2, '0');
      const f = (ms) => `${pad(Math.floor(ms / 60000))}:${pad(Math.floor(ms / 1000) % 60)}.${Math.floor(ms / 100) % 10}`;
      let start = 0, acc = 0, run = false, laps = [], raf;
      const tick = () => { el.querySelector('#d').textContent = f(acc + (run ? Date.now() - start : 0)); if (run) raf = requestAnimationFrame(tick); };
      el.querySelector('#go').onclick = (e) => { if (run) { acc += Date.now() - start; run = false; e.target.textContent = 'متابعة'; } else { start = Date.now(); run = true; e.target.textContent = 'إيقاف'; tick(); } };
      el.querySelector('#lap').onclick = () => { if (!run) return; laps.unshift(acc + Date.now() - start); el.querySelector('#laps').innerHTML = laps.map((l, i) => `<div class="kv"><span>لفة ${laps.length - i}</span><b class="ltr">${f(l)}</b></div>`).join(''); };
      el.querySelector('#rs').onclick = () => { run = false; acc = 0; laps = []; el.querySelector('#laps').innerHTML = ''; el.querySelector('#go').textContent = 'بدء'; tick(); };
      let end = 0, tint, remain = 0;
      const tshow = (ms) => { const s = Math.ceil(ms / 1000); el.querySelector('#td').textContent = `${pad(Math.floor(s / 60))}:${pad(s % 60)}`; };
      const tset = () => { remain = (num(el.querySelector('#mm').value) * 60 + num(el.querySelector('#ss').value)) * 1000; tshow(remain); };
      el.querySelector('#tm').addEventListener('input', () => { if (!tint) tset(); });
      el.querySelector('#tgo').onclick = (e) => {
        if (tint) { clearInterval(tint); tint = null; remain = end - Date.now(); e.target.textContent = 'متابعة'; return; }
        if (!remain) tset();
        end = Date.now() + remain; e.target.textContent = 'إيقاف';
        tint = setInterval(() => {
          const r = end - Date.now(); tshow(Math.max(0, r));
          if (r <= 0) { clearInterval(tint); tint = null; remain = 0; e.target.textContent = 'بدء'; beep(); if (navigator.vibrate) navigator.vibrate([400, 200, 400]); toast('⏰ انتهى الوقت'); notify('انتهى المؤقت', 'أدوات البشري'); }
        }, 200);
      };
      el.querySelector('#trs').onclick = () => { clearInterval(tint); tint = null; el.querySelector('#tgo').textContent = 'بدء'; tset(); };
      el.querySelector('#mode').onclick = (e) => { const m = e.target.dataset.m; if (!m) return; el.querySelectorAll('#mode button').forEach((b) => b.classList.toggle('on', b.dataset.m === m)); el.querySelector('#sw').style.display = m === 'sw' ? '' : 'none'; el.querySelector('#tm').style.display = m === 'tm' ? '' : 'none'; };
      tset();
      return () => { cancelAnimationFrame(raf); clearInterval(tint); };
    },
  },
  {
    id: 'bmi', name: 'حاسبة الصحة', sub: 'الوزن المثالي والسعرات', cat: 'calc', icon: 'heart', color: 'pink',
    render(el) {
      el.innerHTML = `
        <div class="card">
          <div class="seg" id="sx"><button data-s="m" class="on">ذكر</button><button data-s="f">أنثى</button></div>
          <div class="row"><div><label class="f">الوزن (كجم)</label><input class="in" id="w" inputmode="decimal" value="70"></div>
          <div><label class="f">الطول (سم)</label><input class="in" id="h" inputmode="decimal" value="170"></div>
          <div><label class="f">العمر</label><input class="in" id="a" inputmode="numeric" value="30"></div></div>
          <label class="f">النشاط اليومي</label><select class="in" id="act">${opt([['1.2', 'قليل الحركة'], ['1.375', 'نشاط خفيف'], ['1.55', 'نشاط متوسط'], ['1.725', 'نشاط عالٍ']], '1.375')}</select>
          <div class="result"><div class="lbl">مؤشر كتلة الجسم</div><div class="big" id="out">—</div><div class="lbl" id="cls"></div></div>
          <div id="det" style="margin-top:10px"></div>
          <div class="note">قيم إرشادية عامة، ولا تغني عن استشارة الطبيب.</div></div>`;
      let sx = 'm';
      const calc = () => {
        const w = num(el.querySelector('#w').value), h = num(el.querySelector('#h').value), a = num(el.querySelector('#a').value);
        const bmi = w / (h / 100) ** 2;
        const cls = bmi < 18.5 ? 'نحافة' : bmi < 25 ? 'وزن طبيعي ✅' : bmi < 30 ? 'زيادة وزن' : 'سمنة';
        const bmr = 10 * w + 6.25 * h - 5 * a + (sx === 'm' ? 5 : -161);
        const tdee = bmr * +el.querySelector('#act').value;
        el.querySelector('#out').textContent = isFinite(bmi) ? fmtNum(bmi, 1) : '—';
        el.querySelector('#cls').textContent = isFinite(bmi) ? cls : '';
        el.querySelector('#det').innerHTML = `
          <div class="kv"><span>الوزن الصحي لطولك</span><b class="ltr">${fmtNum(18.5 * (h / 100) ** 2, 0)} – ${fmtNum(24.9 * (h / 100) ** 2, 0)} كجم</b></div>
          <div class="kv"><span>السعرات للمحافظة على الوزن</span><b class="ltr">${fmtNum(tdee, 0)} سعرة</b></div>
          <div class="kv"><span>لإنقاص الوزن</span><b class="ltr">${fmtNum(tdee - 500, 0)} سعرة</b></div>
          <div class="kv"><span>الماء المقترح يوميًا (في الحر أكثر)</span><b class="ltr">${fmtNum(w * 0.035, 1)} لتر</b></div>`;
      };
      el.querySelector('#sx').onclick = (e) => { if (!e.target.dataset.s) return; sx = e.target.dataset.s; el.querySelectorAll('#sx button').forEach((b) => b.classList.toggle('on', b.dataset.s === sx)); calc(); };
      el.addEventListener('input', calc); el.addEventListener('change', calc); calc();
    },
  },
  {
    id: 'random', name: 'القرعة', sub: 'أسماء، نرد، عملة', cat: 'daily', icon: 'dice', color: 'purple',
    render(el) {
      el.innerHTML = `
        <div class="card"><h3>اختيار اسم عشوائي (الختة والصندوق)</h3>
          <textarea class="in" id="names" placeholder="اكتب كل اسم في سطر">${esc(S.randNames || '')}</textarea>
          <label style="display:flex;gap:8px;align-items:center;margin-top:8px"><input type="checkbox" id="rm"> احذف الاسم الفائز من القائمة</label>
          <button class="btn block" id="pick">اختر</button>
          <div class="result"><div class="big" id="out" style="font-size:28px">—</div></div></div>
        <div class="card"><h3>نرد وعملة</h3><div class="row"><button class="btn ghost" id="dice">🎲 نرد</button><button class="btn ghost" id="coin">🪙 عملة</button></div>
          <div class="result"><div class="big" id="o2">—</div></div></div>`;
      const rnd = (n) => crypto.getRandomValues(new Uint32Array(1))[0] % n;
      el.querySelector('#names').oninput = (e) => { S.randNames = e.target.value; save(); };
      el.querySelector('#pick').onclick = () => {
        const list = el.querySelector('#names').value.split('\n').map((s) => s.trim()).filter(Boolean);
        if (!list.length) return toast('أضف أسماء أولًا');
        let i = 0; const out = el.querySelector('#out');
        const iv = setInterval(() => { out.textContent = list[rnd(list.length)]; if (++i > 15) { clearInterval(iv); const w = list[rnd(list.length)]; out.textContent = '🎉 ' + w;
          if (el.querySelector('#rm').checked) { list.splice(list.indexOf(w), 1); el.querySelector('#names').value = S.randNames = list.join('\n'); save(); } } }, 70);
      };
      el.querySelector('#dice').onclick = () => (el.querySelector('#o2').textContent = '⚀⚁⚂⚃⚄⚅'[rnd(6)] + ' ' + (rnd(6) + 1));
      el.querySelector('#coin').onclick = () => (el.querySelector('#o2').textContent = rnd(2) ? 'كتابة' : 'صورة');
    },
  },
  {
    id: 'contacts', name: 'أرقام مهمة', sub: 'اتصال سريع', cat: 'daily', icon: 'phone', color: 'green',
    render(el) {
      S.contacts = S.contacts || [];
      el.innerHTML = `
        <div class="card"><div id="list"></div>
          <div class="row" style="margin-top:10px"><input class="in" id="n" placeholder="الاسم (طبيب، كهربائي، إسعاف…)"><input class="in ltr" id="p" inputmode="tel" placeholder="الرقم"></div>
          <button class="btn block" id="add">${icon('plus')} إضافة</button>
          <div class="note">احفظ أرقام الطوارئ والخدمات في منطقتك لتصل إليها بسرعة حتى دون إنترنت.</div></div>`;
      const draw = () => {
        el.querySelector('#list').innerHTML = S.contacts.map((c, i) => `
          <div class="list-item"><div class="grow"><b>${esc(c.n)}</b><div class="note ltr" style="margin:0;text-align:right">${esc(c.p)}</div></div>
          <a class="btn ghost" href="tel:${encodeURIComponent(c.p)}">${icon('phone')}</a>
          <a class="btn ghost" href="https://wa.me/${c.p.replace(/\D/g, '').replace(/^0/, '249')}" target="_blank" rel="noopener">واتساب</a>
          <button class="icon-btn" data-del="${i}">${icon('trash')}</button></div>`).join('') || '<div class="empty">لا أرقام بعد</div>';
      };
      el.querySelector('#add').onclick = () => {
        const n = el.querySelector('#n').value.trim(), p = el.querySelector('#p').value.trim();
        if (!n || !p) return toast('أدخل الاسم والرقم');
        S.contacts.push({ n, p }); save(); el.querySelector('#n').value = el.querySelector('#p').value = ''; draw();
      };
      el.querySelector('#list').onclick = (e) => { const b = e.target.closest('[data-del]'); if (b && confirm('حذف الرقم؟')) { S.contacts.splice(+b.dataset.del, 1); save(); draw(); } };
      draw();
    },
  },

  /* ───────────── نصوص وصور ───────────── */
  {
    id: 'qr', name: 'رمز QR', sub: 'إنشاء وقراءة', cat: 'media', icon: 'qr', color: 'gray',
    render(el) {
      el.innerHTML = `
        <div class="seg" id="mode" style="margin-bottom:14px"><button data-m="make" class="on">إنشاء</button><button data-m="scan">قراءة</button></div>
        <div class="card" id="make">
          <select class="in" id="type">${opt([['text', 'نص أو رابط'], ['wifi', 'شبكة واي فاي'], ['phone', 'رقم هاتف'], ['wa', 'واتساب']], 'text')}</select>
          <div id="fields" style="margin-top:8px"></div>
          <button class="btn block" id="gen">إنشاء الرمز</button>
          <div class="qr-out" id="out" style="display:none"></div>
          <button class="btn ghost block" id="dl" style="display:none">حفظ الصورة</button></div>
        <div class="card" id="scan" style="display:none">
          <button class="btn block" id="cam">${icon('qr')} تشغيل الكاميرا</button>
          <video class="cam" id="v" playsinline muted style="display:none"></video>
          <div class="result"><div class="big" id="res" style="font-size:18px;word-break:break-all">—</div></div>
          <div class="row" style="margin-top:8px"><button class="btn ghost" id="cp">${icon('copy')} نسخ</button><a class="btn ghost" id="open" target="_blank" rel="noopener" style="display:none">فتح</a></div></div>`;
      const fields = {
        text: '<textarea class="in" id="q1" placeholder="اكتب النص أو الرابط"></textarea>',
        wifi: '<input class="in" id="q1" placeholder="اسم الشبكة"><input class="in" id="q2" placeholder="كلمة المرور" style="margin-top:8px">',
        phone: '<input class="in ltr" id="q1" inputmode="tel" placeholder="+249…">',
        wa: '<input class="in ltr" id="q1" inputmode="tel" placeholder="+249…"><input class="in" id="q2" placeholder="رسالة (اختياري)" style="margin-top:8px">',
      };
      const $t = el.querySelector('#type');
      const setF = () => (el.querySelector('#fields').innerHTML = fields[$t.value]);
      $t.onchange = setF; setF();
      el.querySelector('#gen').onclick = async () => {
        const a = el.querySelector('#q1')?.value.trim() || '', b = el.querySelector('#q2')?.value.trim() || '';
        if (!a) return toast('أدخل البيانات');
        const data = { text: a, wifi: `WIFI:T:WPA;S:${a};P:${b};;`, phone: `tel:${a}`, wa: `https://wa.me/${a.replace(/\D/g, '')}${b ? '?text=' + encodeURIComponent(b) : ''}` }[$t.value];
        try {
          await loadScript('https://cdnjs.cloudflare.com/ajax/libs/qrcode-generator/1.4.4/qrcode.min.js');
          qrcode.stringToBytes = qrcode.stringToBytesFuncs['UTF-8'];
          const q = qrcode(0, 'M'); q.addData(data); q.make();
          const n = q.getModuleCount(), s = 8, m = 4 * s, cv = document.createElement('canvas');
          cv.width = cv.height = n * s + m * 2;
          const g = cv.getContext('2d'); g.fillStyle = '#fff'; g.fillRect(0, 0, cv.width, cv.height); g.fillStyle = '#000D2E';
          for (let r = 0; r < n; r++) for (let c = 0; c < n; c++) if (q.isDark(r, c)) g.fillRect(m + c * s, m + r * s, s, s);
          const out = el.querySelector('#out'); out.innerHTML = ''; out.appendChild(cv); out.style.display = '';
          const dl = el.querySelector('#dl'); dl.style.display = '';
          dl.onclick = () => { const a2 = document.createElement('a'); a2.href = cv.toDataURL('image/png'); a2.download = 'qr-albushra.png'; a2.click(); };
        } catch { toast('تحتاج اتصالًا بالإنترنت لأول مرة'); }
      };
      let stream, raf;
      const stop = () => { cancelAnimationFrame(raf); stream?.getTracks().forEach((t) => t.stop()); stream = null; };
      const found = (txt) => {
        stop(); el.querySelector('#v').style.display = 'none';
        el.querySelector('#res').textContent = txt; if (navigator.vibrate) navigator.vibrate(60);
        const o = el.querySelector('#open'); if (/^(https?:|tel:|mailto:)/i.test(txt)) { o.href = txt; o.style.display = ''; } else o.style.display = 'none';
      };
      el.querySelector('#cam').onclick = async () => {
        try {
          stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
          const v = el.querySelector('#v'); v.srcObject = stream; v.style.display = ''; await v.play();
          let detector = null;
          if ('BarcodeDetector' in window) detector = new BarcodeDetector({ formats: ['qr_code'] });
          else await loadScript('https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.js');
          const cv = document.createElement('canvas'), g = cv.getContext('2d', { willReadFrequently: true });
          const loop = async () => {
            if (!stream) return;
            if (v.readyState >= 2) {
              if (detector) { const r = await detector.detect(v).catch(() => []); if (r[0]) return found(r[0].rawValue); }
              else { cv.width = v.videoWidth; cv.height = v.videoHeight; g.drawImage(v, 0, 0); const r = jsQR(g.getImageData(0, 0, cv.width, cv.height).data, cv.width, cv.height); if (r) return found(r.data); }
            }
            raf = requestAnimationFrame(loop);
          };
          loop();
        } catch { toast('تعذّر تشغيل الكاميرا — تحقق من الإذن'); }
      };
      el.querySelector('#cp').onclick = () => copyText(el.querySelector('#res').textContent);
      el.querySelector('#mode').onclick = (e) => { const m = e.target.dataset.m; if (!m) return; el.querySelectorAll('#mode button').forEach((b) => b.classList.toggle('on', b.dataset.m === m)); el.querySelector('#make').style.display = m === 'make' ? '' : 'none'; el.querySelector('#scan').style.display = m === 'scan' ? '' : 'none'; if (m === 'make') stop(); };
      return stop;
    },
  },
  {
    id: 'password', name: 'كلمات المرور', sub: 'مولّد آمن', cat: 'media', icon: 'key', color: 'blue',
    render(el) {
      el.innerHTML = `
        <div class="card">
          <div class="result"><div class="big" id="out" style="font-size:22px;word-break:break-all">—</div><div class="lbl" id="str"></div></div>
          <label class="f">الطول: <b id="ln">16</b></label><input type="range" id="len" min="6" max="40" value="16" style="width:100%">
          ${[['up', 'أحرف كبيرة A-Z', 1], ['lo', 'أحرف صغيرة a-z', 1], ['nu', 'أرقام 0-9', 1], ['sy', 'رموز !@#', 1], ['am', 'استبعاد المتشابهة (0 O l 1)', 0]]
            .map(([id, t, c]) => `<label style="display:flex;gap:8px;align-items:center;margin-top:8px"><input type="checkbox" id="${id}" ${c ? 'checked' : ''}> ${t}</label>`).join('')}
          <div class="row" style="margin-top:12px"><button class="btn" id="gen">توليد</button><button class="btn ghost" id="cp">${icon('copy')} نسخ</button></div>
          <div class="note">تُولَّد كلمات المرور على جهازك فقط ولا تُحفظ أو تُرسل لأي مكان.</div></div>`;
      const gen = () => {
        const L = +el.querySelector('#len').value; el.querySelector('#ln').textContent = L;
        let set = '';
        if (el.querySelector('#up').checked) set += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        if (el.querySelector('#lo').checked) set += 'abcdefghijklmnopqrstuvwxyz';
        if (el.querySelector('#nu').checked) set += '0123456789';
        if (el.querySelector('#sy').checked) set += '!@#$%^&*()-_=+[]{};:,.?';
        if (el.querySelector('#am').checked) set = set.replace(/[0Ol1I]/g, '');
        if (!set) return toast('اختر نوعًا واحدًا على الأقل');
        const r = crypto.getRandomValues(new Uint32Array(L));
        const pw = Array.from(r, (x) => set[x % set.length]).join('');
        el.querySelector('#out').textContent = pw;
        const bits = L * Math.log2(set.length);
        el.querySelector('#str').textContent = bits < 50 ? 'ضعيفة' : bits < 80 ? 'متوسطة' : bits < 110 ? 'قوية 💪' : 'قوية جدًا 🛡️';
      };
      el.addEventListener('input', gen); el.querySelector('#gen').onclick = gen;
      el.querySelector('#cp').onclick = () => copyText(el.querySelector('#out').textContent);
      gen();
    },
  },
  {
    id: 'image', name: 'ضغط الصور', sub: 'وفّر الباقة', cat: 'media', icon: 'image', color: 'cyan', sd: true,
    render(el) {
      el.innerHTML = `
        <div class="card">
          <input type="file" id="f" accept="image/*" class="in">
          <div class="row"><div><label class="f">أقصى عرض (بكسل)</label><select class="in" id="w">${opt([['800', '800'], ['1280', '1280'], ['1920', '1920'], ['0', 'الأصلي']], '1280')}</select></div>
          <div><label class="f">الجودة: <b id="qv">70</b>%</label><input type="range" id="q" min="20" max="95" value="70" style="width:100%;margin-top:14px"></div></div>
          <div id="res"></div>
          <div class="note">مفيدة لإرسال الصور والمستندات عبر واتساب والإنترنت الضعيف. المعالجة تتم على جهازك.</div></div>`;
      let img, name = 'image';
      const run = () => {
        el.querySelector('#qv').textContent = el.querySelector('#q').value;
        if (!img) return;
        const W = +el.querySelector('#w').value || img.naturalWidth, sc = Math.min(1, W / img.naturalWidth);
        const cv = document.createElement('canvas'); cv.width = Math.round(img.naturalWidth * sc); cv.height = Math.round(img.naturalHeight * sc);
        cv.getContext('2d').drawImage(img, 0, 0, cv.width, cv.height);
        cv.toBlob((b) => {
          const url = URL.createObjectURL(b);
          el.querySelector('#res').innerHTML = `
            <div class="kv"><span>الحجم الأصلي</span><b class="ltr">${fmtBytes(img._size)} — ${img.naturalWidth}×${img.naturalHeight}</b></div>
            <div class="kv"><span>بعد الضغط</span><b class="ltr">${fmtBytes(b.size)} — ${cv.width}×${cv.height}</b></div>
            <div class="kv"><span>التوفير</span><b>${fmtNum(Math.max(0, (1 - b.size / img._size) * 100), 0)}%</b></div>
            <img src="${url}" style="width:100%;border-radius:14px;margin-top:10px">
            <div class="row" style="margin-top:10px"><a class="btn" href="${url}" download="${name}-small.jpg">حفظ</a><button class="btn ghost" id="sh">${icon('share')} مشاركة</button></div>`;
          el.querySelector('#sh').onclick = () => shareFile(new File([b], `${name}-small.jpg`, { type: 'image/jpeg' }));
        }, 'image/jpeg', +el.querySelector('#q').value / 100);
      };
      el.querySelector('#f').onchange = (e) => {
        const file = e.target.files[0]; if (!file) return;
        name = file.name.replace(/\.[^.]+$/, '');
        img = new Image(); img._size = file.size; img.onload = run; img.src = URL.createObjectURL(file);
      };
      el.querySelector('#w').onchange = run; el.querySelector('#q').oninput = run;
    },
  },
  {
    id: 'text', name: 'أدوات النص', sub: 'عدّ وتنظيف ونطق', cat: 'media', icon: 'text', color: 'orange',
    render(el) {
      el.innerHTML = `
        <div class="card">
          <textarea class="in" id="t" placeholder="ألصق النص هنا">${esc(S.textDraft || '')}</textarea>
          <div id="st" style="margin-top:10px"></div>
          <div class="grid two" style="margin-top:12px;gap:8px">
            <button class="btn ghost" data-a="tashkeel">إزالة التشكيل</button>
            <button class="btn ghost" data-a="spaces">تنظيف المسافات</button>
            <button class="btn ghost" data-a="digitsEn">أرقام ← 123</button>
            <button class="btn ghost" data-a="digitsAr">أرقام ← ١٢٣</button>
            <button class="btn ghost" data-a="upper">ABC كبيرة</button>
            <button class="btn ghost" data-a="lower">abc صغيرة</button>
            <button class="btn ghost" data-a="speak">${icon('sound')} قراءة بصوت</button>
            <button class="btn ghost" data-a="dictate">${icon('mic')} إملاء صوتي</button>
          </div>
          <div class="row" style="margin-top:10px"><button class="btn" data-a="copy">${icon('copy')} نسخ</button><button class="btn ghost" data-a="clear">مسح</button></div></div>`;
      const ta = el.querySelector('#t');
      const stats = () => {
        const v = ta.value; S.textDraft = v; save();
        const words = (v.match(/\S+/g) || []).length;
        el.querySelector('#st').innerHTML = `<div class="kv"><span>الكلمات</span><b>${words}</b></div><div class="kv"><span>الأحرف</span><b>${v.length}</b></div><div class="kv"><span>الأسطر</span><b>${v ? v.split('\n').length : 0}</b></div><div class="kv"><span>وقت القراءة</span><b>${Math.max(1, Math.ceil(words / 180))} دقيقة</b></div>`;
      };
      const A = {
        tashkeel: (s) => s.replace(/[ً-ٰٟـ]/g, ''),
        spaces: (s) => s.replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim(),
        digitsEn: (s) => s.replace(/[٠-٩]/g, (d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)),
        digitsAr: (s) => s.replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]),
        upper: (s) => s.toUpperCase(), lower: (s) => s.toLowerCase(),
      };
      el.querySelector('.card').onclick = (e) => {
        const a = e.target.closest('[data-a]')?.dataset.a; if (!a) return;
        if (A[a]) { ta.value = A[a](ta.value); stats(); }
        else if (a === 'copy') copyText(ta.value);
        else if (a === 'clear') { ta.value = ''; stats(); }
        else if (a === 'speak') {
          if (!('speechSynthesis' in window)) return toast('القراءة الصوتية غير مدعومة');
          speechSynthesis.cancel(); const u = new SpeechSynthesisUtterance(ta.value);
          u.lang = /[؀-ۿ]/.test(ta.value) ? 'ar-SA' : 'en-US'; speechSynthesis.speak(u);
        } else if (a === 'dictate') {
          const R = window.SpeechRecognition || window.webkitSpeechRecognition;
          if (!R) return toast('الإملاء الصوتي غير مدعوم في هذا المتصفح');
          const r = new R(); r.lang = 'ar-SD'; r.interimResults = false;
          r.onresult = (ev) => { ta.value += (ta.value ? ' ' : '') + ev.results[0][0].transcript; stats(); };
          r.onerror = () => toast('تعذّر الإملاء — يحتاج إنترنت وإذن الميكروفون');
          r.start(); toast('🎙️ تحدّث الآن…');
        }
      };
      ta.oninput = stats; stats();
      return () => window.speechSynthesis?.cancel();
    },
  },

  /* ───────────── الجهاز ───────────── */
  {
    id: 'flashlight', name: 'الكشاف', sub: 'عند قطوعات الكهرباء', cat: 'device', icon: 'flash', color: 'gold', sd: true,
    render(el) {
      el.innerHTML = `
        <div class="card" style="text-align:center">
          <button class="counter-btn" id="t" style="font-size:72px">🔦</button>
          <div class="row"><button class="btn ghost" id="sos">SOS</button><button class="btn ghost" id="scr">شاشة بيضاء</button></div>
          <div class="note" id="st">يعمل فلاش الكاميرا على أغلب هواتف أندرويد عبر Chrome. إن لم يعمل استخدم «شاشة بيضاء».</div></div>`;
      let stream, track, on = false, sosT;
      const set = async (v) => {
        try {
          if (!track) {
            stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
            track = stream.getVideoTracks()[0];
            if (!track.getCapabilities?.().torch) throw new Error('no torch');
          }
          await track.applyConstraints({ advanced: [{ torch: v }] }); on = v;
          el.querySelector('#t').style.filter = v ? 'drop-shadow(0 0 30px #FFE48A)' : '';
        } catch { el.querySelector('#st').textContent = 'الفلاش غير متاح على هذا الجهاز — جرّب «شاشة بيضاء».'; }
      };
      el.querySelector('#t').onclick = () => { clearInterval(sosT); set(!on); };
      el.querySelector('#sos').onclick = () => {
        if (sosT) { clearInterval(sosT); sosT = null; set(false); return; }
        const pat = [1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0]; let i = 0;
        sosT = setInterval(() => set(!!pat[i++ % pat.length]), 250);
      };
      el.querySelector('#scr').onclick = () => {
        const d = document.createElement('div');
        d.style.cssText = 'position:fixed;inset:0;background:#fff;z-index:300;display:grid;place-items:end center;padding-bottom:40px;color:#888;font-weight:700';
        d.textContent = 'اضغط للخروج'; d.onclick = () => d.remove(); document.body.appendChild(d);
        document.documentElement.requestFullscreen?.().catch(() => {});
      };
      return () => { clearInterval(sosT); stream?.getTracks().forEach((t) => t.stop()); };
    },
  },
  {
    id: 'level', name: 'ميزان الماء', sub: 'للبناء والتركيب', cat: 'device', icon: 'level', color: 'green',
    render(el) {
      el.innerHTML = `
        <div class="card" style="text-align:center">
          <div class="level-box"><div class="bubble" id="b"></div></div>
          <div class="result"><div class="big" id="o">0.0° / 0.0°</div><div class="lbl">ميل أمامي / جانبي</div></div>
          <button class="btn block" id="go">تشغيل</button></div>`;
      const h = (e) => {
        const x = Math.max(-45, Math.min(45, e.gamma || 0)), y = Math.max(-45, Math.min(45, e.beta || 0));
        el.querySelector('#b').style.left = `${103 + (x / 45) * 100}px`;
        el.querySelector('#b').style.top = `${103 + (y / 45) * 100}px`;
        el.querySelector('#o').textContent = `${fmtNum(y, 1)}° / ${fmtNum(x, 1)}°`;
        el.querySelector('#b').style.background = Math.abs(x) < 1 && Math.abs(y) < 1 ? 'radial-gradient(circle at 35% 35%,#B8FFDD,#17A673)' : 'radial-gradient(circle at 35% 35%,#FFE6A8,#E08A00)';
      };
      el.querySelector('#go').onclick = async () => {
        try { if (DeviceOrientationEvent.requestPermission) await DeviceOrientationEvent.requestPermission(); } catch { /* */ }
        window.addEventListener('deviceorientation', h);
      };
      return () => window.removeEventListener('deviceorientation', h);
    },
  },
  {
    id: 'noise', name: 'مقياس الضوضاء', sub: 'ديسيبل تقريبي', cat: 'device', icon: 'sound', color: 'pink',
    render(el) {
      el.innerHTML = `
        <div class="card" style="text-align:center">
          <div class="big-display" id="o">— dB</div>
          <div class="meter"><div id="m" style="width:0"></div></div>
          <div class="lbl" id="l" style="margin-top:8px"></div>
          <button class="btn block" id="go">${icon('mic')} بدء القياس</button>
          <div class="note">قراءة تقريبية حسب ميكروفون الهاتف، وليست جهاز قياس معتمد.</div></div>`;
      let ctx, stream, raf;
      el.querySelector('#go').onclick = async () => {
        if (stream) return;
        try {
          stream = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false } });
          ctx = new AudioContext(); const an = ctx.createAnalyser(); an.fftSize = 2048;
          ctx.createMediaStreamSource(stream).connect(an);
          const buf = new Float32Array(an.fftSize); let avg = 0;
          const loop = () => {
            an.getFloatTimeDomainData(buf);
            const rms = Math.sqrt(buf.reduce((s, v) => s + v * v, 0) / buf.length);
            const db = Math.max(0, 20 * Math.log10(rms || 1e-8) + 94);
            avg = avg * 0.85 + db * 0.15;
            el.querySelector('#o').textContent = `${fmtNum(avg, 0)} dB`;
            el.querySelector('#m').style.width = `${Math.min(100, avg / 1.2)}%`;
            el.querySelector('#l').textContent = avg < 40 ? 'هادئ جدًا' : avg < 60 ? 'محادثة عادية' : avg < 80 ? 'شارع مزدحم' : avg < 95 ? 'مرتفع — مولّد/ركشة' : 'خطر على السمع ⚠️';
            raf = requestAnimationFrame(loop);
          };
          loop();
        } catch { toast('تعذّر الوصول للميكروفون'); }
      };
      return () => { cancelAnimationFrame(raf); stream?.getTracks().forEach((t) => t.stop()); ctx?.close(); };
    },
  },

  /* ───────────── الطقس (يُفتح من بطاقة البيت) ───────────── */
  {
    id: 'weather', name: 'الطقس والغبار', sub: 'الهبوب وجودة الهواء', cat: 'daily', icon: 'cloud', color: 'blue', hidden: true,
    render(el) {
      el.innerHTML = `<div class="card"><select class="in" id="c">${cityOpts(S.city)}</select></div><div id="w"><div class="empty">جارٍ التحميل…</div></div>`;
      const load = async () => {
        const c = CITIES.find((x) => x.id === el.querySelector('#c').value);
        const w = await getWeather(c, true);
        if (!w) { el.querySelector('#w').innerHTML = '<div class="card empty">تعذّر جلب الطقس — تحقق من الاتصال</div>'; return; }
        const [desc, emo] = WMO[w.code] || ['—', '🌡️'];
        el.querySelector('#w').innerHTML = `
          <div class="weather-card" style="cursor:default"><div class="ico">${emo}</div><div><div class="t">${Math.round(w.temp)}°</div><div class="meta">${desc} — يحس ${Math.round(w.feels)}°</div></div></div>
          ${dustBanner(w)}
          <div class="card"><h3>التفاصيل</h3>
            <div class="kv"><span>الرطوبة</span><b>${w.hum}%</b></div>
            <div class="kv"><span>الرياح</span><b class="ltr">${Math.round(w.wind)} km/h</b></div>
            ${w.pm10 != null ? `<div class="kv"><span>الغبار العالق PM10</span><b class="ltr">${Math.round(w.pm10)} µg/m³</b></div>` : ''}
            ${w.aqi != null ? `<div class="kv"><span>مؤشر جودة الهواء</span><b>${Math.round(w.aqi)}</b></div>` : ''}
            ${w.uv != null ? `<div class="kv"><span>الأشعة فوق البنفسجية (أقصى اليوم)</span><b>${fmtNum(w.uv, 0)}</b></div>` : ''}</div>
          <div class="card"><h3>الأيام القادمة</h3><div class="forecast">${w.daily.map((d) => `<div><div>${fmtDate(new Date(d.date + 'T12:00'), { weekday: 'short' })}</div><div class="e">${(WMO[d.code] || ['', '🌡️'])[1]}</div><b>${Math.round(d.max)}°</b> <span class="lbl">${Math.round(d.min)}°</span></div>`).join('')}</div></div>
          <div class="note">المصدر: Open-Meteo — آخر تحديث ${fmtTime(new Date(w.at))}</div>`;
      };
      el.querySelector('#c').onchange = load; load();
    },
  },
];

const toolById = (id) => TOOLS.find((t) => t.id === id);
