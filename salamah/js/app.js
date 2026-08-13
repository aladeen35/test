/* ═══════════════════════════════════════════════════════════
   سلامة — منطق التطبيق والواجهة
   ═══════════════════════════════════════════════════════════ */

const st = () => store.state;
const $ = (id) => document.getElementById(id);
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const bdi = (v) => `<bdi style="white-space:nowrap">${esc(v)}</bdi>`;
const num = (v) => (Math.round(Number(v) * 10) / 10).toString();

let tab = 'today';
let tempPoint = null;      // نقطة القياس المختارة حاليًا
let repRange = 'today';    // مدى التقرير
let ncFilter = 'open';     // فلتر المخالفات

/* ═══════════ تنبيهات ═══════════ */
function toast(msg, kind = '') {
  const t = document.createElement('div');
  t.className = 'toast ' + kind;
  t.textContent = msg;
  const stack = $('toasts');
  stack.appendChild(t);
  while (stack.children.length > 2) stack.firstElementChild.remove();
  setTimeout(() => t.remove(), 2600);
}

/* ═══════════ نوافذ سفلية ═══════════ */
function openSheet(title, html) {
  $('sheet-title').textContent = title;
  $('sheet-body').innerHTML = html;
  $('sheet').classList.add('open');
}
function closeSheet() {
  $('sheet').classList.remove('open');
  $('sheet-body').innerHTML = '';
}

/* ═══════════ التنقل ═══════════ */
function go(name) {
  tab = name;
  document.querySelectorAll('.view').forEach((v) => v.classList.toggle('active', v.id === 'view-' + name));
  document.querySelectorAll('#tabs button').forEach((b) => b.setAttribute('aria-selected', b.dataset.tab === name));
  document.querySelector('main').scrollTo(0, 0);
  render();
}

function render() {
  renderBadges();
  if (tab === 'today') renderToday();
  if (tab === 'temp') renderTemp();
  if (tab === 'round') renderRound();
  if (tab === 'shelf') renderShelf();
  if (tab === 'nc') renderNc();
}

function renderBadges() {
  const openNcs = st().ncs.filter((n) => n.status === 'open').length;
  const risky = st().items.filter((i) => { const d = daysLeft(i.expiry); return d !== null && d <= 1; }).length;
  const set = (t, n) => {
    const btn = document.querySelector(`#tabs button[data-tab="${t}"]`);
    const old = btn.querySelector('.dot');
    if (old) old.remove();
    if (n > 0) btn.insertAdjacentHTML('beforeend', `<span class="dot">${n}</span>`);
  };
  set('nc', openNcs);
  set('shelf', risky);
}

/* ═══════════════════════════════════════════════════════════
   ١) اليوم — لوحة المتابعة والتقارير
   ═══════════════════════════════════════════════════════════ */
function renderToday() {
  const s = st();
  const today = dayKey();
  const inspector = s.settings.inspector || 'مسؤول الجودة';
  $('today-title').textContent = `مرحبًا ${inspector}`;
  $('today-date').textContent = `${fmtDayName(new Date())} ${today}${s.settings.branch ? ' · ' + s.settings.branch : ''}`;
  $('hdr-sub').textContent = s.settings.branch || 'مساعد ضبط جودة الغذاء';

  const todays = s.readings.filter((r) => fmtDate(r.at) === today);
  const dev = todays.filter((r) => r.ok === false).length;
  const round = s.rounds.filter((r) => fmtDate(r.at) === today).slice(-1)[0];
  const openNcs = s.ncs.filter((n) => n.status === 'open');
  const expSoon = s.items.filter((i) => { const d = daysLeft(i.expiry); return d !== null && d <= 2; });

  $('today-kpis').innerHTML = `
    <div class="kpi ${dev ? 'bad' : 'ok'}"><div class="v mono">${todays.length}</div><div class="l">قراءة اليوم${dev ? ` · ${dev} خارج الحد` : ''}</div></div>
    <div class="kpi ${round ? (round.score >= 85 ? 'ok' : 'warn') : ''}"><div class="v mono">${round ? round.score + '%' : '—'}</div><div class="l">جولة اليوم</div></div>
    <div class="kpi ${openNcs.length ? 'warn' : 'ok'}"><div class="v mono">${openNcs.length}</div><div class="l">مخالفة مفتوحة</div></div>
    <div class="kpi ${expSoon.length ? 'bad' : 'ok'}"><div class="v mono">${expSoon.length}</div><div class="l">صنف منتهٍ أو قارب</div></div>`;

  /* تنبيهات ومهام مستحقّة */
  const alerts = [];
  if (!s.settings.inspector || !s.settings.branch) {
    alerts.push(['info', '⚙️', 'أكمل الإعداد', 'أضف اسمك واسم الفرع ليظهرا في التقارير الموقّعة.', "openSettings()"]);
  }
  const missing = s.settings.points.filter((p) => !todays.some((r) => r.pointId === p.id));
  if (missing.length) {
    alerts.push(['warn', '🌡️', `${missing.length} نقطة لم تُقس اليوم`, missing.map((p) => p.name).join(' · '), "go('temp')"]);
  }
  if (!round) alerts.push(['warn', '📋', 'لم تُسجَّل جولة تفتيش اليوم', 'ابدأ الجولة وقيّم البنود.', "go('round')"]);
  const crit = openNcs.filter((n) => n.severity === 'critical');
  if (crit.length) alerts.push(['bad', '🚨', `${crit.length} مخالفة حرجة مفتوحة`, crit.map((n) => n.title).join(' · '), "go('nc')"]);
  const late = openNcs.filter((n) => n.due && daysLeft(n.due) < 0);
  if (late.length) alerts.push(['bad', '⏰', `${late.length} مخالفة تجاوزت تاريخ الإغلاق`, late.map((n) => n.title).join(' · '), "go('nc')"]);
  if (expSoon.length) {
    alerts.push(['bad', '🏷️', 'أصناف تحتاج تصرفًا', expSoon.map((i) => `${i.name} (${expLabel(daysLeft(i.expiry)).txt})`).join(' · '), "go('shelf')"]);
  }
  if (!alerts.length) alerts.push(['ok', '🎉', 'كل المهام المستحقّة مكتملة', 'لا توجد تنبيهات لهذا اليوم.', '']);

  $('today-alerts').innerHTML = `<div class="card"><h3>🔔 يحتاج انتباهك</h3><div class="list">` +
    alerts.map(([k, ico, t, sub, act]) => `
      <div class="row edge-${k === 'info' ? 'mute' : k} ${act ? 'tap' : ''}" ${act ? `onclick="${act}"` : ''}>
        <span style="font-size:1.1rem">${ico}</span>
        <div class="grow"><div class="t">${esc(t)}</div><div class="s">${esc(sub)}</div></div>
        ${act ? '<span style="color:var(--text-3)">‹</span>' : ''}
      </div>`).join('') + `</div></div>`;

  renderReportCard();

  /* آخر النشاط */
  const feed = [
    ...s.readings.map((r) => ({ at: r.at, t: `${r.pointName}: ${num(r.value)}${r.unit}`, s: r.ok === false ? 'خارج الحد' : 'مطابق', k: r.ok === false ? 'bad' : 'ok' })),
    ...s.rounds.map((r) => ({ at: r.at, t: `جولة تفتيش — ${r.score}%`, s: r.grade, k: r.score >= 85 ? 'ok' : r.score >= 70 ? 'warn' : 'bad' })),
    ...s.ncs.map((n) => ({ at: n.at, t: `مخالفة: ${n.title}`, s: n.status === 'open' ? 'مفتوحة' : 'مغلقة', k: n.status === 'open' ? 'warn' : 'ok' })),
  ].sort((a, b) => new Date(b.at) - new Date(a.at)).slice(0, 8);

  $('today-feed').innerHTML = feed.length
    ? feed.map((f) => `<div class="row edge-${f.k}"><div class="grow"><div class="t">${esc(f.t)}</div>
        <div class="s mono" dir="ltr">${fmtDateTime(f.at)}</div></div><span class="badge ${f.k}">${esc(f.s)}</span></div>`).join('')
    : `<div class="empty"><span class="ico">📭</span>لا يوجد نشاط بعد — ابدأ بتسجيل قراءة حرارة.
       <div style="margin-top:.7rem"><button class="btn sm" onclick="seedDemo()">تجربة ببيانات نموذجية</button></div></div>`;
}

/* ═══════════ التقارير ═══════════ */
const RANGES = { today: 'اليوم', '7': 'آخر ٧ أيام', '30': 'آخر ٣٠ يومًا' };

function rangeStart(r) {
  if (r === 'today') return dayKey();
  return addDays(dayKey(), -(Number(r) - 1));
}
function inRange(iso, r) {
  return fmtDate(iso) >= rangeStart(r);
}
function reportData(r = repRange) {
  const s = st();
  const readings = s.readings.filter((x) => inRange(x.at, r));
  const rounds = s.rounds.filter((x) => inRange(x.at, r));
  const ncs = s.ncs.filter((x) => inRange(x.at, r));
  const avg = rounds.length ? Math.round(rounds.reduce((a, b) => a + b.score, 0) / rounds.length) : null;
  return {
    readings, rounds, ncs, avg,
    dev: readings.filter((x) => x.ok === false).length,
    open: ncs.filter((x) => x.status === 'open').length,
    expired: s.items.filter((i) => daysLeft(i.expiry) !== null && daysLeft(i.expiry) < 0),
  };
}
function renderReportCard() {
  $('rep-range').innerHTML = Object.entries(RANGES)
    .map(([k, v]) => `<button class="chip" aria-pressed="${repRange === k}" onclick="repRange='${k}';renderReportCard()">${v}</button>`).join('');
  const d = reportData();
  $('rep-summary').innerHTML = `<div class="list">
    <div class="row edge-mute"><div class="grow"><div class="t">قراءات الحرارة والتطهير</div>
      <div class="s">${d.dev ? `<span style="color:var(--danger)">${d.dev} خارج الحد</span>` : 'كلها مطابقة'}</div></div>
      <div class="val mono">${d.readings.length}</div></div>
    <div class="row edge-mute"><div class="grow"><div class="t">جولات التفتيش</div>
      <div class="s">${d.avg !== null ? 'المتوسط ' + d.avg + '%' : 'لا جولات'}</div></div>
      <div class="val mono">${d.rounds.length}</div></div>
    <div class="row edge-mute"><div class="grow"><div class="t">المخالفات</div>
      <div class="s">${d.open} مفتوحة من ${d.ncs.length}</div></div>
      <div class="val mono">${d.ncs.length}</div></div></div>`;
}

function printReport() {
  const d = reportData();
  const s = st();
  const tbl = (head, rows) => rows.length
    ? `<div class="tbl-wrap"><table><thead><tr>${head.map((h) => `<th>${h}</th>`).join('')}</tr></thead>
       <tbody>${rows.map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`
    : '<p>لا توجد بيانات في هذه المدة.</p>';

  $('print-area').innerHTML = `
    <h2>تقرير ضبط جودة الغذاء</h2>
    <div class="meta">
      الفرع: ${esc(s.settings.branch || '—')} &nbsp;|&nbsp; المسؤول: ${esc(s.settings.inspector || '—')}
      &nbsp;|&nbsp; المدة: ${RANGES[repRange]} (${rangeStart(repRange)} إلى ${dayKey()})
      &nbsp;|&nbsp; تاريخ الطباعة: ${dayKey()} ${fmtTime(new Date().toISOString())}
    </div>
    <div class="sec-t">١) ملخص</div>
    ${tbl(['البند', 'العدد'], [
      ['قراءات مسجّلة', d.readings.length], ['قراءات خارج الحد', d.dev],
      ['جولات تفتيش', d.rounds.length], ['متوسط نسبة المطابقة', d.avg !== null ? d.avg + '%' : '—'],
      ['مخالفات مرصودة', d.ncs.length], ['مخالفات ما زالت مفتوحة', d.open],
      ['أصناف منتهية الصلاحية', d.expired.length],
    ])}
    <div class="sec-t">٢) سجل الحرارة والتطهير</div>
    ${tbl(['التاريخ', 'الوقت', 'نقطة القياس', 'القراءة', 'المدى', 'الحكم', 'الإجراء التصحيحي'],
      d.readings.map((r) => [fmtDate(r.at), fmtTime(r.at), esc(r.pointName), bdi(num(r.value) + r.unit),
        bdi(`${r.min} — ${r.max}`), r.ok === false ? 'خارج الحد' : 'مطابق', esc(r.action || '—')]))}
    <div class="sec-t">٣) جولات التفتيش</div>
    ${tbl(['التاريخ', 'الوقت', 'النسبة', 'التقدير', 'مخالف', 'ملاحظة', 'حرج مخالف'],
      d.rounds.map((r) => [fmtDate(r.at), fmtTime(r.at), r.score + '%', esc(r.grade), r.bad, r.obs, r.critBad]))}
    <div class="sec-t">٤) المخالفات والإجراءات التصحيحية</div>
    ${tbl(['التاريخ', 'المخالفة', 'الخطورة', 'المسؤول', 'الاستحقاق', 'الحالة', 'الإجراء'],
      d.ncs.map((n) => [fmtDate(n.at), esc(n.title), SEVERITY_LABEL[n.severity], esc(n.owner || '—'),
        bdi(n.due || '—'), n.status === 'open' ? 'مفتوحة' : 'مغلقة ' + (n.closedAt ? bdi(fmtDate(n.closedAt)) : ''), esc(n.action || '—')]))}
    <div class="sign"><span>مسؤول الجودة: ${esc(s.settings.inspector || '____________')}</span>
      <span>مدير الفرع: ____________</span><span>التوقيع: ____________</span></div>`;
  setTimeout(() => window.print(), 60);
}

function download(name, text, type = 'text/csv;charset=utf-8') {
  const body = type.startsWith('text/csv') ? '﻿' + text : text;  // BOM ليقرأ Excel العربية
  const url = URL.createObjectURL(new Blob([body], { type }));
  const a = document.createElement('a');
  a.href = url; a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1500);
}
const csvRow = (arr) => arr.map((c) => `"${String(c ?? '').replace(/"/g, '""')}"`).join(',') + '\n';

function exportCsv() {
  openSheet('تصدير CSV', `<p class="hint" style="margin-bottom:.8rem">تُصدَّر بيانات ${RANGES[repRange]} بترميز يفتح مباشرة في Excel.</p>
    <div class="btn-row">
      <button class="btn sm" onclick="doExport('readings')">🌡️ الحرارة</button>
      <button class="btn sm" onclick="doExport('rounds')">📋 الجولات</button>
      <button class="btn sm" onclick="doExport('ncs')">⚠️ المخالفات</button>
      <button class="btn sm" onclick="doExport('items')">🏷️ الأصناف</button>
      <button class="btn sm" onclick="doExport('backup')">💾 نسخة كاملة JSON</button>
    </div>`);
}

function doExport(kind) {
  const d = reportData();
  const stamp = dayKey();
  if (kind === 'readings') {
    let c = csvRow(['التاريخ', 'الوقت', 'نقطة القياس', 'النوع', 'القراءة', 'الوحدة', 'الحد الأدنى', 'الحد الأعلى', 'الحكم', 'الإجراء التصحيحي']);
    d.readings.forEach((r) => c += csvRow([fmtDate(r.at), fmtTime(r.at), r.pointName, POINT_TYPES[r.type].name, num(r.value), r.unit, r.min, r.max, r.ok === false ? 'خارج الحد' : 'مطابق', r.action || '']));
    download(`salamah-temps-${stamp}.csv`, c);
  } else if (kind === 'rounds') {
    let c = csvRow(['التاريخ', 'الوقت', 'المسؤول', 'الفرع', 'النسبة', 'التقدير', 'مطابق', 'ملاحظة', 'مخالف', 'حرج مخالف']);
    d.rounds.forEach((r) => c += csvRow([fmtDate(r.at), fmtTime(r.at), r.inspector, r.branch, r.score, r.grade, r.ok, r.obs, r.bad, r.critBad]));
    download(`salamah-rounds-${stamp}.csv`, c);
  } else if (kind === 'ncs') {
    let c = csvRow(['التاريخ', 'المخالفة', 'التفصيل', 'المصدر', 'الخطورة', 'المسؤول', 'الاستحقاق', 'الحالة', 'الإجراء', 'تاريخ الإغلاق']);
    d.ncs.forEach((n) => c += csvRow([fmtDateTime(n.at), n.title, n.detail || '', n.source, SEVERITY_LABEL[n.severity], n.owner || '', n.due || '', n.status === 'open' ? 'مفتوحة' : 'مغلقة', n.action || '', n.closedAt ? fmtDate(n.closedAt) : '']));
    download(`salamah-ncs-${stamp}.csv`, c);
  } else if (kind === 'items') {
    let c = csvRow(['الصنف', 'الموقع', 'المورد/التشغيلة', 'تاريخ الفتح', 'يُستهلك قبل', 'الأيام المتبقية']);
    st().items.forEach((i) => c += csvRow([i.name, i.loc || '', i.batch || '', i.openedAt, i.expiry, daysLeft(i.expiry)]));
    download(`salamah-items-${stamp}.csv`, c);
  } else {
    download(`salamah-backup-${stamp}.json`, JSON.stringify(st(), null, 2), 'application/json');
  }
  closeSheet();
  toast('تم التصدير', 'ok');
}

function shareSummary() {
  const d = reportData();
  const s = st();
  const txt = `📋 ملخص جودة الغذاء — ${s.settings.branch || 'الفرع'}\n`
    + `المدة: ${RANGES[repRange]} (${rangeStart(repRange)} → ${dayKey()})\n`
    + `🌡️ قراءات: ${d.readings.length} · خارج الحد: ${d.dev}\n`
    + `✅ جولات: ${d.rounds.length}${d.avg !== null ? ` · المتوسط ${d.avg}%` : ''}\n`
    + `⚠️ مخالفات: ${d.ncs.length} · مفتوحة: ${d.open}\n`
    + `🏷️ أصناف منتهية: ${d.expired.length}\n`
    + `المسؤول: ${s.settings.inspector || '—'}`;
  if (navigator.share) navigator.share({ title: 'ملخص جودة الغذاء', text: txt }).catch(() => {});
  else window.open('https://wa.me/?text=' + encodeURIComponent(txt), '_blank');
}

/* ═══════════════════════════════════════════════════════════
   ٢) الحرارة — تسجيل القراءات والحكم الفوري
   ═══════════════════════════════════════════════════════════ */
function renderTemp() {
  const s = st();
  const today = dayKey();
  const done = new Set(s.readings.filter((r) => fmtDate(r.at) === today).map((r) => r.pointId));

  $('temp-points').innerHTML = s.settings.points
    .map((p) => `<button class="chip" aria-pressed="${tempPoint === p.id}" onclick="pickPoint('${p.id}')">
      ${done.has(p.id) ? '✓ ' : ''}${esc(p.name)}</button>`).join('')
    + `<button class="chip mini" onclick="openSettings('points')">⚙️ النقاط</button>`;

  const list = s.readings.filter((r) => fmtDate(r.at) === today).sort((a, b) => new Date(b.at) - new Date(a.at));
  $('temp-today-note').textContent = `${list.length} قراءة من أصل ${s.settings.points.length} نقطة · ${list.filter((r) => !r.ok).length} خارج الحد`;
  $('temp-list').innerHTML = list.length ? list.map((r) => `
    <div class="row edge-${r.ok ? 'ok' : 'bad'}">
      <div class="grow"><div class="t">${esc(r.pointName)}</div>
        <div class="s mono" dir="ltr">${fmtTime(r.at)} · ${r.min}…${r.max}${r.unit}</div>
        ${r.action ? `<div class="s">↳ ${esc(r.action)}</div>` : ''}</div>
      <div style="text-align:center"><div class="val mono" dir="ltr" style="color:var(--${r.ok ? 'ok' : 'danger'})">${num(r.value)}${r.unit === 'ppm' ? '' : '°'}</div>
        <span class="badge ${r.ok ? 'ok' : 'bad'}">${r.ok ? 'مطابق' : 'خارج الحد'}</span></div>
      <button class="btn ghost sm" onclick="delReading('${r.id}')" aria-label="حذف">🗑️</button>
    </div>`).join('') : `<div class="empty"><span class="ico">🌡️</span>لا قراءات اليوم — اختر نقطة وابدأ.</div>`;

  if (tempPoint && !s.settings.points.some((p) => p.id === tempPoint)) tempPoint = null;
  $('temp-form').hidden = !tempPoint;
  if (tempPoint) {
    const p = s.settings.points.find((x) => x.id === tempPoint);
    const t = POINT_TYPES[p.type], r = s.settings.ranges[p.type];
    $('temp-value-label').textContent = `القراءة ${ltr(t.unit)} — المدى المسموح من ${ltr(r.min)} إلى ${ltr(r.max)}`;
    if (!$('temp-time').value) $('temp-time').value = fmtTime(new Date().toISOString());
    updateVerdict();
  }
}

function pickPoint(id) {
  tempPoint = tempPoint === id ? null : id;
  $('temp-value').value = '';
  $('temp-action').value = '';
  $('temp-time').value = fmtTime(new Date().toISOString());
  renderTemp();
  if (tempPoint) setTimeout(() => $('temp-value').focus(), 80);
}

function updateVerdict() {
  const p = st().settings.points.find((x) => x.id === tempPoint);
  if (!p) return;
  const v = $('temp-value').value;
  const r = readingStatus(p.type, v, st().settings.ranges);
  const box = $('temp-verdict');
  if (r.ok === null) { box.innerHTML = ''; $('temp-action-wrap').hidden = true; return; }
  const t = POINT_TYPES[p.type];
  box.innerHTML = r.ok
    ? `<div class="row edge-ok" style="margin-bottom:.7rem"><span>✅</span><div class="grow"><div class="t">مطابق للمعيار</div>
       <div class="s">القراءة داخل المدى من <bdi>${r.min}${t.unit}</bdi> إلى <bdi>${r.max}${t.unit}</bdi></div></div></div>`
    : `<div class="row edge-bad" style="margin-bottom:.7rem"><span>🚨</span><div class="grow"><div class="t">خارج الحد المسموح</div>
       <div class="s">المطلوب من <bdi>${r.min}${t.unit}</bdi> إلى <bdi>${r.max}${t.unit}</bdi> — ستُنشأ مخالفة ${t.critical ? 'حرجة' : 'كبيرة'} تلقائيًا</div></div></div>`;
  $('temp-action-wrap').hidden = r.ok;
}

function saveReading() {
  const s = st();
  const p = s.settings.points.find((x) => x.id === tempPoint);
  if (!p) return;
  const val = $('temp-value').value;
  if (val === '') return toast('أدخل القراءة أولًا', 'bad');
  const r = readingStatus(p.type, val, s.settings.ranges);
  if (r.ok === null) return toast('القراءة غير صالحة', 'bad');
  const action = $('temp-action').value.trim();
  if (!r.ok && !action) return toast('اكتب الإجراء التصحيحي — إلزامي عند الخروج عن الحد', 'bad');

  const [hh, mm] = ($('temp-time').value || fmtTime(new Date().toISOString())).split(':');
  const at = new Date(); at.setHours(Number(hh), Number(mm), 0, 0);
  const t = POINT_TYPES[p.type];
  const rec = {
    id: uid(), at: at.toISOString(), pointId: p.id, pointName: p.name, type: p.type,
    value: Number(val), unit: t.unit, min: r.min, max: r.max, ok: r.ok, action: action || '',
  };
  s.readings.push(rec);

  if (!r.ok) {
    rec.ncId = createNc({
      source: 'temp',
      title: `خروج عن الحد — ${p.name}`,
      detail: `القراءة ${ltr(num(val) + t.unit)} والمدى المسموح من ${ltr(r.min + t.unit)} إلى ${ltr(r.max + t.unit)}.`,
      severity: t.critical ? 'critical' : 'major',
      action, owner: s.settings.inspector || '',
      due: dayKey(),
    });
  }
  store.save();
  tempPoint = null;
  render();
  toast(r.ok ? 'حُفظت القراءة ✓' : 'حُفظت وأُنشئت مخالفة — أغلقها بعد التحقق', r.ok ? 'ok' : 'bad');
}

function delReading(id) {
  const s = st();
  s.readings = s.readings.filter((r) => r.id !== id);
  store.save(); render();
  toast('حُذفت القراءة');
}

/* ═══════════════════════════════════════════════════════════
   ٣) جولة التفتيش
   ═══════════════════════════════════════════════════════════ */
function draft() {
  if (!st().draft) st().draft = { answers: {}, startedAt: new Date().toISOString() };
  return st().draft;
}

function renderRound() {
  const d = draft();
  $('round-sections').innerHTML = CHECKLIST.map((sec) => {
    const rated = sec.items.filter((i) => d.answers[i.id]).length;
    const bad = sec.items.filter((i) => (d.answers[i.id] || {}).v === 'bad').length;
    return `<details class="sec" ${rated < sec.items.length ? 'open' : ''}>
      <summary><span>${sec.icon}</span><span>${sec.title}</span>
        <span class="badge ${bad ? 'bad' : rated === sec.items.length ? 'ok' : 'mute'}">${rated}/${sec.items.length}</span></summary>
      <div class="sec-body">${sec.items.map((i) => {
        const a = d.answers[i.id] || {};
        return `<div class="item">
          <div class="q">${i.crit ? '<span title="بند حرج">⚠️</span>' : ''}<span>${esc(i.text)}</span></div>
          <div class="rate">${['ok', 'obs', 'bad', 'na'].map((v) =>
            `<button data-v="${v}" aria-pressed="${a.v === v}" onclick="rate('${i.id}','${v}')">${RATE_LABEL[v]}</button>`).join('')}</div>
          ${a.v === 'obs' || a.v === 'bad'
            ? `<textarea placeholder="${a.v === 'bad' ? 'الملاحظة إلزامية عند المخالفة — ماذا رأيت وأين؟' : 'ملاحظة (اختياري)'}"
                 oninput="noteRound('${i.id}',this.value)">${esc(a.note || '')}</textarea>` : ''}
        </div>`;
      }).join('')}</div></details>`;
  }).join('');

  const c = computeRound();
  $('round-score').textContent = c.rated ? c.score : '—';
  $('round-bar').style.width = (c.rated ? c.score : 0) + '%';
  $('round-bar').className = c.score >= 85 ? '' : c.score >= 70 ? 'warn' : 'bad';
  const g = $('round-grade');
  g.textContent = c.rated ? c.grade : 'لم تبدأ';
  g.className = 'badge ' + (!c.rated ? 'mute' : c.critBad ? 'crit' : c.score >= 85 ? 'ok' : c.score >= 70 ? 'warn' : 'bad');
  $('round-progress').textContent = `قُيّم ${c.rated} من ${c.total} بندًا · مطابق ${c.ok} · ملاحظة ${c.obs} · مخالف ${c.bad}${c.critBad ? ` · حرج مخالف ${c.critBad}` : ''}`;

  const hist = st().rounds.slice().sort((a, b) => new Date(b.at) - new Date(a.at)).slice(0, 10);
  $('round-history').innerHTML = hist.length ? hist.map((r) => `
    <div class="row edge-${r.critBad ? 'bad' : r.score >= 85 ? 'ok' : 'warn'} tap" onclick="showRound('${r.id}')">
      <div class="grow"><div class="t">${r.score}% · ${esc(r.grade)}</div>
        <div class="s mono" dir="ltr">${fmtDateTime(r.at)}</div></div>
      <span class="badge mute">مخالف ${r.bad}</span></div>`).join('')
    : `<div class="empty"><span class="ico">📋</span>لا جولات محفوظة بعد.</div>`;
}

function rate(itemId, v) {
  const d = draft();
  const cur = d.answers[itemId];
  if (cur && cur.v === v) delete d.answers[itemId];
  else d.answers[itemId] = { v, note: (cur && cur.note) || '' };
  store.save();
  renderRound();
}
function noteRound(itemId, val) {
  const d = draft();
  if (d.answers[itemId]) { d.answers[itemId].note = val; store.save(); }
}

function computeRound(answers) {
  const a = answers || draft().answers;
  let wSum = 0, got = 0, ok = 0, obs = 0, bad = 0, critBad = 0, rated = 0, total = 0;
  CHECKLIST.forEach((sec) => sec.items.forEach((i) => {
    total++;
    const v = (a[i.id] || {}).v;
    if (!v) return;
    rated++;
    if (v === 'na') return;
    const w = i.crit ? 3 : 1;
    wSum += w;
    if (v === 'ok') { got += w; ok++; }
    else if (v === 'obs') { got += w * 0.5; obs++; }
    else { bad++; if (i.crit) critBad++; }
  }));
  const score = wSum ? Math.round((got / wSum) * 100) : 0;
  const grade = critBad ? 'غير مقبول — مخالفة حرجة'
    : score >= 95 ? (bad ? 'جيد' : 'ممتاز')
    : score >= 85 ? 'جيد' : score >= 70 ? 'مقبول — يحتاج تصحيح' : 'غير مقبول';
  return { score, grade, ok, obs, bad, critBad, rated, total };
}

function saveRound() {
  const d = draft();
  const c = computeRound();
  if (!c.rated) return toast('قيّم بندًا واحدًا على الأقل', 'bad');
  const missingNote = [];
  CHECKLIST.forEach((sec) => sec.items.forEach((i) => {
    const a = d.answers[i.id];
    if (a && a.v === 'bad' && !(a.note || '').trim()) missingNote.push(i.text);
  }));
  if (missingNote.length) return toast(`اكتب ملاحظة للبنود المخالفة (${missingNote.length})`, 'bad');

  const s = st();
  const at = new Date().toISOString();
  const round = {
    id: uid(), at, inspector: s.settings.inspector || '', branch: s.settings.branch || '',
    score: c.score, grade: c.grade, ok: c.ok, obs: c.obs, bad: c.bad, critBad: c.critBad,
    rated: c.rated, total: c.total, answers: JSON.parse(JSON.stringify(d.answers)), ncIds: [],
  };
  CHECKLIST.forEach((sec) => sec.items.forEach((i) => {
    const a = d.answers[i.id];
    if (a && a.v === 'bad') {
      round.ncIds.push(createNc({
        source: 'round',
        title: i.text,
        detail: `القسم: ${sec.title} — ${a.note}`,
        severity: i.crit ? 'critical' : 'major',
        owner: s.settings.inspector || '',
        due: addDays(dayKey(), i.crit ? 1 : 7),
      }));
    }
  }));
  s.rounds.push(round);
  s.draft = { answers: {}, startedAt: at };
  store.save();
  render();
  toast(`حُفظت الجولة: ${c.score}% (${c.grade})${round.ncIds.length ? ` · ${round.ncIds.length} مخالفة` : ''}`, c.critBad ? 'bad' : 'ok');
}

function resetRound() {
  if (!confirm('تفريغ تقييمات الجولة الحالية؟')) return;
  st().draft = { answers: {}, startedAt: new Date().toISOString() };
  store.save(); renderRound();
}

function showRound(id) {
  const r = st().rounds.find((x) => x.id === id);
  if (!r) return;
  const rows = [];
  CHECKLIST.forEach((sec) => sec.items.forEach((i) => {
    const a = r.answers[i.id];
    if (!a || a.v === 'ok' || a.v === 'na') return;
    rows.push(`<div class="row edge-${a.v === 'bad' ? 'bad' : 'warn'}"><div class="grow">
      <div class="t">${i.crit ? '⚠️ ' : ''}${esc(i.text)}</div>
      <div class="s">${esc(sec.title)}${a.note ? ' — ' + esc(a.note) : ''}</div></div>
      <span class="badge ${a.v === 'bad' ? 'bad' : 'warn'}">${RATE_LABEL[a.v]}</span></div>`);
  }));
  openSheet(`جولة ${fmtDate(r.at)} · ${r.score}%`, `
    <div class="card flat"><div class="score-big"><b>${r.score}</b><span>%</span>
      <span class="badge ${r.critBad ? 'crit' : r.score >= 85 ? 'ok' : 'warn'}" style="margin-inline-start:auto">${esc(r.grade)}</span></div>
      <div class="card-note" style="margin-top:.5rem">${fmtDateTime(r.at)} · ${esc(r.inspector || '—')}${r.branch ? ' · ' + esc(r.branch) : ''}
        <br>مطابق ${r.ok} · ملاحظة ${r.obs} · مخالف ${r.bad} من ${r.rated} بندًا مقيَّمًا</div></div>
    <b style="font-size:.85rem">البنود غير المطابقة</b>
    <div class="list" style="margin-top:.5rem">${rows.join('') || '<div class="empty">كل البنود المقيّمة مطابقة 🎉</div>'}</div>
    <button class="btn danger block sm" style="margin-top:1rem" onclick="delRound('${r.id}')">🗑️ حذف الجولة</button>`);
}
function delRound(id) {
  if (!confirm('حذف هذه الجولة من السجل؟')) return;
  st().rounds = st().rounds.filter((r) => r.id !== id);
  store.save(); closeSheet(); render();
  toast('حُذفت الجولة');
}

/* ═══════════════════════════════════════════════════════════
   ٤) الصلاحية والاستلام
   ═══════════════════════════════════════════════════════════ */
const SHELF_CHIPS = [1, 2, 3, 5, 7, 14, 30];
let shelfDays = 3;

function expLabel(d) {
  if (d === null) return { k: 'mute', txt: 'بلا تاريخ' };
  if (d < 0) return { k: 'bad', txt: `منتهٍ منذ ${Math.abs(d)} يوم` };
  if (d === 0) return { k: 'bad', txt: 'ينتهي اليوم' };
  if (d === 1) return { k: 'warn', txt: 'يبقى يوم واحد' };
  if (d <= 3) return { k: 'warn', txt: `يبقى ${d} أيام` };
  return { k: 'ok', txt: `يبقى ${d} يومًا` };
}

function renderShelf() {
  $('it-shelf-chips').innerHTML = SHELF_CHIPS
    .map((d) => `<button class="chip" aria-pressed="${shelfDays === d}" onclick="setShelf(${d})">${d} يوم</button>`).join('');
  if (!$('it-opened').value) $('it-opened').value = dayKey();
  if (!$('it-expiry').value) $('it-expiry').value = addDays($('it-opened').value, shelfDays);

  const list = st().items.slice().sort((a, b) => (daysLeft(a.expiry) ?? 999) - (daysLeft(b.expiry) ?? 999));
  const risky = list.filter((i) => (daysLeft(i.expiry) ?? 99) <= 1).length;
  $('shelf-note').textContent = `${list.length} صنف متابَع · ${risky} يحتاج تصرفًا الآن`;
  $('shelf-list').innerHTML = list.length ? list.map((i) => {
    const e = expLabel(daysLeft(i.expiry));
    return `<div class="row edge-${e.k}">
      <div class="grow"><div class="t">${esc(i.name)}</div>
        <div class="s">${esc(i.loc || '—')}${i.batch ? ' · ' + esc(i.batch) : ''} · فُتح ${i.openedAt}</div>
        <div class="s mono" dir="ltr">يُستهلك قبل ${i.expiry}</div></div>
      <div style="text-align:center"><span class="badge ${e.k}">${e.txt}</span></div>
      <button class="btn ghost sm" onclick="printLabel('${i.id}')" aria-label="ملصق">🖨️</button>
      <button class="btn ghost sm" onclick="delItem('${i.id}')" aria-label="إزالة">✔️</button>
    </div>`;
  }).join('') : `<div class="empty"><span class="ico">🏷️</span>لا أصناف متابَعة — أضف صنفًا مفتوحًا أو دفعة مستلمة.</div>`;
}

function setShelf(d) {
  shelfDays = d;
  $('it-expiry').value = addDays($('it-opened').value || dayKey(), d);
  renderShelf();
}

function saveItem() {
  const name = $('it-name').value.trim();
  if (!name) return toast('اكتب اسم الصنف', 'bad');
  const opened = $('it-opened').value || dayKey();
  const expiry = $('it-expiry').value || addDays(opened, shelfDays);
  const s = st();
  const item = {
    id: uid(), name, loc: $('it-loc').value.trim(), batch: $('it-batch').value.trim(),
    openedAt: opened, expiry, at: new Date().toISOString(),
  };
  s.items.push(item);

  /* حرارة الاستلام — تُسجَّل كقراءة وتُنشئ مخالفة عند الخروج عن الحد */
  const tv = $('it-temp').value;
  if (tv !== '') {
    const type = $('it-temp-type').value;
    const r = readingStatus(type, tv, s.settings.ranges);
    const rec = {
      id: uid(), at: new Date().toISOString(), pointId: 'recv', pointName: `استلام: ${name}`,
      type, value: Number(tv), unit: POINT_TYPES[type].unit, min: r.min, max: r.max, ok: r.ok, action: '',
    };
    s.readings.push(rec);
    if (!r.ok) {
      rec.action = 'رُفضت الدفعة أو حُفظت للمراجعة بانتظار قرار المورد.';
      rec.ncId = createNc({
        source: 'temp',
        title: `حرارة استلام غير مطابقة — ${name}`,
        detail: `القراءة ${ltr(num(tv) + POINT_TYPES[type].unit)} والمدى المسموح من ${ltr(r.min)} إلى ${ltr(r.max)}. المورد: ${item.batch || '—'}`,
        severity: 'critical', owner: s.settings.inspector || '', due: dayKey(),
        action: rec.action,
      });
    }
  }
  store.save();
  ['it-name', 'it-loc', 'it-batch', 'it-temp'].forEach((k) => ($(k).value = ''));
  $('it-expiry').value = '';
  render();
  toast('أُضيف الصنف ✓ — اطبع الملصق من القائمة', 'ok');
}

function delItem(id) {
  const it = st().items.find((i) => i.id === id);
  if (!it || !confirm(`إزالة «${it.name}» من المتابعة؟`)) return;
  st().items = st().items.filter((i) => i.id !== id);
  store.save(); render();
  toast('أُزيل الصنف');
}

function printLabel(id) {
  const i = st().items.find((x) => x.id === id);
  if (!i) return;
  const s = st();
  $('print-area').innerHTML = `<div class="label-card">
    <div style="font-size:9pt">${esc(s.settings.branch || 'الفرع')} — بطاقة صنف مفتوح</div>
    <div class="big">${esc(i.name)}</div>
    <div>الموقع: ${esc(i.loc || '—')}</div>
    ${i.batch ? `<div>المورد/التشغيلة: ${esc(i.batch)}</div>` : ''}
    <div>تاريخ الفتح: ${bdi(i.openedAt)}</div>
    <div class="big">يُستهلك قبل: ${bdi(i.expiry)}</div>
    <div style="font-size:9pt;margin-top:2mm">أعدّه: ${esc(s.settings.inspector || '—')}</div>
  </div>`;
  setTimeout(() => window.print(), 60);
}

/* ═══════════════════════════════════════════════════════════
   ٥) المخالفات والإجراءات التصحيحية
   ═══════════════════════════════════════════════════════════ */
function createNc({ source, title, detail, severity, owner, due, action }) {
  const nc = {
    id: uid(), at: new Date().toISOString(), source, title, detail: detail || '',
    severity: severity || 'major', owner: owner || '', due: due || addDays(dayKey(), 3),
    status: 'open', action: action || '', closedAt: null, photoId: null,
  };
  st().ncs.push(nc);
  return nc.id;
}

const NC_FILTERS = { open: 'المفتوحة', closed: 'المغلقة', all: 'الكل' };

function renderNc() {
  $('nc-filter').innerHTML = Object.entries(NC_FILTERS)
    .map(([k, v]) => `<button class="chip mini" aria-pressed="${ncFilter === k}" onclick="ncFilter='${k}';renderNc()">${v}</button>`).join('');
  const list = st().ncs
    .filter((n) => ncFilter === 'all' || n.status === ncFilter)
    .sort((a, b) => new Date(b.at) - new Date(a.at));

  $('nc-list').innerHTML = list.length ? list.map((n) => {
    const late = n.status === 'open' && n.due && daysLeft(n.due) < 0;
    const k = n.status === 'closed' ? 'ok' : n.severity === 'critical' ? 'bad' : 'warn';
    return `<div class="row edge-${k} tap" onclick="openNc('${n.id}')">
      <div class="grow"><div class="t">${n.severity === 'critical' ? '🚨 ' : ''}${esc(n.title)}</div>
        <div class="s">${esc(n.detail || '').slice(0, 70)}</div>
        <div class="s mono" dir="ltr">${fmtDateTime(n.at)}${n.due ? ` → ${n.due}` : ''}</div></div>
      <div style="display:flex;flex-direction:column;gap:.2rem;align-items:flex-end">
        <span class="badge ${n.status === 'closed' ? 'ok' : n.severity === 'critical' ? 'crit' : 'warn'}">
          ${n.status === 'closed' ? 'مغلقة' : SEVERITY_LABEL[n.severity]}</span>
        ${late ? '<span class="badge bad">متأخرة</span>' : ''}</div></div>`;
  }).join('') : `<div class="empty"><span class="ico">✅</span>لا مخالفات ${NC_FILTERS[ncFilter]}.</div>`;
}

function openNcNew() {
  openSheet('مخالفة جديدة', `
    <label class="field"><span>عنوان المخالفة</span>
      <input id="nc-title" placeholder="مثال: تخزين لحم نيء فوق سلطة جاهزة"></label>
    <label class="field"><span>التفصيل والموقع</span>
      <textarea id="nc-detail" placeholder="ماذا رأيت؟ أين؟ من المسؤول؟"></textarea></label>
    <div class="two">
      <label class="field"><span>الخطورة</span>
        <select id="nc-sev"><option value="critical">حرجة</option><option value="major" selected>كبيرة</option><option value="minor">بسيطة</option></select></label>
      <label class="field"><span>تاريخ الإغلاق المطلوب</span>
        <input id="nc-due" type="date" value="${addDays(dayKey(), 3)}"></label>
    </div>
    <label class="field"><span>المسؤول عن التصحيح</span>
      <input id="nc-owner" value="${esc(st().settings.inspector || '')}"></label>
    <button class="btn primary block" onclick="saveNcNew()">رفع المخالفة</button>`);
}

function saveNcNew() {
  const title = $('nc-title').value.trim();
  if (!title) return toast('اكتب عنوان المخالفة', 'bad');
  createNc({
    source: 'manual', title, detail: $('nc-detail').value.trim(),
    severity: $('nc-sev').value, owner: $('nc-owner').value.trim(), due: $('nc-due').value,
  });
  store.save(); closeSheet();
  ncFilter = 'open'; go('nc');
  toast('رُفعت المخالفة', 'ok');
}

function openNc(id) {
  const n = st().ncs.find((x) => x.id === id);
  if (!n) return;
  const closed = n.status === 'closed';
  openSheet(n.title, `
    <div class="row edge-${closed ? 'ok' : n.severity === 'critical' ? 'bad' : 'warn'}" style="margin-bottom:.8rem">
      <div class="grow"><div class="t">${SEVERITY_LABEL[n.severity]} · ${closed ? 'مغلقة' : 'مفتوحة'}</div>
        <div class="s mono" dir="ltr">رُصدت ${fmtDateTime(n.at)}${n.due ? ` · الاستحقاق ${n.due}` : ''}${n.closedAt ? ` · أُغلقت ${fmtDate(n.closedAt)}` : ''}</div>
        <div class="s">المصدر: ${({ temp: 'قراءة حرارة', round: 'جولة تفتيش', manual: 'رفع يدوي' })[n.source]}${n.owner ? ' · المسؤول: ' + esc(n.owner) : ''}</div></div></div>
    ${n.detail ? `<p style="font-size:.85rem;margin-bottom:.8rem">${esc(n.detail)}</p>` : ''}
    <label class="field"><span>الإجراء التصحيحي المتّخذ</span>
      <textarea id="nc-action" ${closed ? 'disabled' : ''} placeholder="ما الذي تم فعله لمنع التكرار؟">${esc(n.action || '')}</textarea></label>
    <div class="field"><span>صورة إثبات</span>
      <input type="file" accept="image/*" capture="environment" onchange="attachPhoto(this,'${n.id}')"></div>
    <div class="photo-box" id="nc-photo"></div>
    <div class="btn-row" style="margin-top:1rem">
      ${closed
        ? `<button class="btn sm" onclick="reopenNc('${n.id}')">↺ إعادة فتح</button>`
        : `<button class="btn primary sm" onclick="closeNc('${n.id}')">✅ إغلاق بعد التحقق</button>
           <button class="btn sm" onclick="saveNcAction('${n.id}')">💾 حفظ الإجراء</button>`}
      <button class="btn danger sm" onclick="delNc('${n.id}')">🗑️ حذف</button>
    </div>`);
  photos.get(n.photoId).then((src) => {
    if (src && $('nc-photo')) $('nc-photo').innerHTML = `<img src="${src}" alt="صورة المخالفة">
      <button class="btn ghost sm" onclick="delPhoto('${n.id}')">إزالة الصورة</button>`;
  });
}

async function attachPhoto(input, id) {
  const f = input.files && input.files[0];
  if (!f) return;
  const n = st().ncs.find((x) => x.id === id);
  try {
    const data = await compressImage(f);
    const pid = n.photoId || uid();
    await photos.put(pid, data);
    n.photoId = pid;
    store.save();
    if ($('nc-photo')) $('nc-photo').innerHTML = `<img src="${data}" alt="صورة المخالفة">
      <button class="btn ghost sm" onclick="delPhoto('${id}')">إزالة الصورة</button>`;
    toast('أُرفقت الصورة', 'ok');
  } catch (e) {
    toast('تعذّر إرفاق الصورة', 'bad');
  }
}
async function delPhoto(id) {
  const n = st().ncs.find((x) => x.id === id);
  await photos.del(n.photoId);
  n.photoId = null; store.save();
  if ($('nc-photo')) $('nc-photo').innerHTML = '';
}

function saveNcAction(id) {
  const n = st().ncs.find((x) => x.id === id);
  n.action = $('nc-action').value.trim();
  store.save(); render();
  toast('حُفظ الإجراء', 'ok');
}
function closeNc(id) {
  const n = st().ncs.find((x) => x.id === id);
  const action = $('nc-action').value.trim();
  if (!action) return toast('لا يمكن الإغلاق بدون إجراء تصحيحي موثّق', 'bad');
  n.action = action; n.status = 'closed'; n.closedAt = new Date().toISOString();
  store.save(); closeSheet(); render();
  toast('أُغلقت المخالفة ✓', 'ok');
}
function reopenNc(id) {
  const n = st().ncs.find((x) => x.id === id);
  n.status = 'open'; n.closedAt = null;
  store.save(); closeSheet(); render();
  toast('أُعيد فتح المخالفة');
}
async function delNc(id) {
  if (!confirm('حذف المخالفة نهائيًا؟')) return;
  const n = st().ncs.find((x) => x.id === id);
  if (n && n.photoId) await photos.del(n.photoId);
  st().ncs = st().ncs.filter((x) => x.id !== id);
  store.save(); closeSheet(); render();
  toast('حُذفت المخالفة');
}

/* ═══════════════════════════════════════════════════════════
   الإعدادات
   ═══════════════════════════════════════════════════════════ */
function openSettings(focus) {
  const s = st();
  openSheet('الإعدادات', `
    <div class="two">
      <label class="field"><span>اسم مسؤول الجودة</span>
        <input id="set-inspector" value="${esc(s.settings.inspector)}" placeholder="الاسم الذي يظهر في التقرير"></label>
      <label class="field"><span>الفرع / الموقع</span>
        <input id="set-branch" value="${esc(s.settings.branch)}" placeholder="مثال: فرع العزيزية"></label>
    </div>
    <label class="field"><span>المظهر</span>
      <select id="set-theme">
        ${[['auto', 'تلقائي حسب النظام'], ['light', 'فاتح'], ['dark', 'ليلي']]
          .map(([k, v]) => `<option value="${k}" ${s.settings.theme === k ? 'selected' : ''}>${v}</option>`).join('')}
      </select></label>
    <button class="btn primary block sm" onclick="saveSettings()">حفظ</button>

    <details class="sec" style="margin-top:1rem" ${focus === 'points' ? 'open' : ''}>
      <summary>🌡️ نقاط القياس (${s.settings.points.length})</summary>
      <div class="sec-body" id="points-editor">${pointsEditorHtml()}</div>
    </details>

    <details class="sec">
      <summary>📏 الحدود المرجعية</summary>
      <div class="sec-body">
        <p class="hint" style="margin-bottom:.6rem">الحدود الافتراضية مبنية على المتطلبات العامة لسلامة الغذاء — عدّلها لتطابق خطة الهاسب المعتمدة في منشأتك.</p>
        ${Object.entries(POINT_TYPES).map(([k, t]) => `
          <div class="two" style="align-items:end">
            <label class="field"><span>${t.name} — الأدنى (${t.unit})</span>
              <input type="number" step="0.1" dir="ltr" id="rng-${k}-min" value="${s.settings.ranges[k].min}"></label>
            <label class="field"><span>الأعلى</span>
              <input type="number" step="0.1" dir="ltr" id="rng-${k}-max" value="${s.settings.ranges[k].max}"></label>
          </div>`).join('')}
        <button class="btn primary block sm" onclick="saveRanges()">حفظ الحدود</button>
      </div>
    </details>

    <details class="sec">
      <summary>💾 البيانات</summary>
      <div class="sec-body">
        <p class="hint" style="margin-bottom:.6rem">كل البيانات محفوظة على هذا الجهاز فقط ولا تُرسل لأي خادم. صدّر نسخة احتياطية بانتظام.</p>
        <div class="btn-row">
          <button class="btn sm" onclick="doExport('backup')">⬇️ نسخة احتياطية</button>
          <button class="btn sm" onclick="$('import-file').click()">⬆️ استيراد نسخة</button>
          <button class="btn sm" onclick="seedDemo()">🧪 بيانات نموذجية</button>
          <button class="btn danger sm" onclick="wipe()">🗑️ مسح كل البيانات</button>
        </div>
        <input id="import-file" type="file" accept="application/json" hidden onchange="importBackup(this)">
      </div>
    </details>
    <p class="hint" style="margin-top:1rem;text-align:center">سلامة · يعمل دون اتصال · الإصدار ١.٠</p>`);
}

function pointsEditorHtml() {
  return st().settings.points.map((p, idx) => `
    <div class="two" style="align-items:end">
      <label class="field"><span>الاسم</span>
        <input value="${esc(p.name)}" oninput="editPoint(${idx},'name',this.value)"></label>
      <label class="field"><span>النوع</span>
        <select onchange="editPoint(${idx},'type',this.value)">
          ${Object.entries(POINT_TYPES).map(([k, t]) =>
            `<option value="${k}" ${p.type === k ? 'selected' : ''}>${t.name} (${t.min}…${t.max}${t.unit})</option>`).join('')}
        </select></label>
    </div>
    <button class="btn danger sm" style="margin-bottom:.8rem" onclick="delPoint(${idx})">حذف «${esc(p.name)}»</button>`).join('')
    + `<button class="btn block sm" onclick="addPoint()">➕ إضافة نقطة قياس</button>`;
}
function editPoint(idx, key, val) {
  st().settings.points[idx][key] = val;
  store.save(); render();
}
function addPoint() {
  st().settings.points.push({ id: uid(), name: 'نقطة جديدة', type: 'chill' });
  store.save();
  $('points-editor').innerHTML = pointsEditorHtml();
  render();
}
function delPoint(idx) {
  const p = st().settings.points[idx];
  if (!confirm(`حذف «${p.name}»؟ القراءات المسجَّلة تبقى في السجل.`)) return;
  st().settings.points.splice(idx, 1);
  store.save();
  $('points-editor').innerHTML = pointsEditorHtml();
  render();
}

function saveSettings() {
  const s = st();
  s.settings.inspector = $('set-inspector').value.trim();
  s.settings.branch = $('set-branch').value.trim();
  s.settings.theme = $('set-theme').value;
  store.save();
  applyTheme();
  closeSheet(); render();
  toast('حُفظت الإعدادات', 'ok');
}
function saveRanges() {
  const s = st();
  Object.keys(POINT_TYPES).forEach((k) => {
    const mn = Number($(`rng-${k}-min`).value), mx = Number($(`rng-${k}-max`).value);
    if (!isNaN(mn) && !isNaN(mx) && mn <= mx) s.settings.ranges[k] = { min: mn, max: mx };
  });
  store.save(); render();
  toast('حُدِّثت الحدود المرجعية', 'ok');
}
function applyTheme() {
  const t = st().settings.theme;
  const dark = t === 'dark' || (t === 'auto' && matchMedia('(prefers-color-scheme: dark)').matches);
  if (dark) document.documentElement.dataset.theme = 'dark';
  else delete document.documentElement.dataset.theme;
}

function importBackup(input) {
  const f = input.files && input.files[0];
  if (!f) return;
  const fr = new FileReader();
  fr.onload = () => {
    try {
      const data = JSON.parse(fr.result);
      if (!data || !Array.isArray(data.readings)) throw new Error('bad');
      if (!confirm('سيحل الملف المستورد مكان البيانات الحالية. المتابعة؟')) return;
      store.state = data;
      store.save(); store.load();
      closeSheet(); applyTheme(); render();
      toast('تم الاستيراد', 'ok');
    } catch (e) {
      toast('ملف غير صالح', 'bad');
    }
  };
  fr.readAsText(f);
}

function wipe() {
  if (!confirm('مسح كل القراءات والجولات والمخالفات والأصناف نهائيًا؟')) return;
  store.reset(); closeSheet(); applyTheme(); go('today');
  toast('مُسحت البيانات');
}

/* ═══════════ بيانات نموذجية للتجربة ═══════════ */
function seedDemo() {
  const s = st();
  if (s.readings.length || s.rounds.length || s.ncs.length) {
    if (!confirm('ستُضاف بيانات تجريبية فوق بياناتك الحالية. المتابعة؟')) return;
  }
  if (!s.settings.inspector) s.settings.inspector = 'مسؤول الجودة';
  if (!s.settings.branch) s.settings.branch = 'فرع العزيزية';

  const mk = (dayOffset, hour, pointId, value) => {
    const p = s.settings.points.find((x) => x.id === pointId);
    const at = new Date(); at.setDate(at.getDate() - dayOffset); at.setHours(hour, 5, 0, 0);
    const r = readingStatus(p.type, value, s.settings.ranges);
    s.readings.push({
      id: uid(), at: at.toISOString(), pointId: p.id, pointName: p.name, type: p.type,
      value, unit: POINT_TYPES[p.type].unit, min: r.min, max: r.max, ok: r.ok,
      action: r.ok ? '' : 'نُقل المنتج لثلاجة سليمة وأُبلغت الصيانة.',
    });
    if (!r.ok) createNc({
      source: 'temp', title: `خروج عن الحد — ${p.name}`,
      detail: `القراءة ${ltr(value + POINT_TYPES[p.type].unit)} والمدى المسموح من ${ltr(r.min)} إلى ${ltr(r.max)}.`,
      severity: 'critical', owner: s.settings.inspector, due: dayKey(),
      action: 'نُقل المنتج لثلاجة سليمة وأُبلغت الصيانة.',
    });
  };
  [3, 2, 1, 0].forEach((d) => {
    mk(d, 8, 'p1', d === 1 ? 8.4 : 3.2);
    mk(d, 8, 'p4', -20.5);
    mk(d, 15, 'p5', d === 0 ? 58 : 64);
    mk(d, 9, 'p7', 150);
  });

  const answers = {};
  CHECKLIST.forEach((sec) => sec.items.forEach((i) => (answers[i.id] = { v: 'ok', note: '' })));
  answers['c5'] = { v: 'obs', note: 'بطاقتا تاريخ ناقصتان في رف المعلبات.' };
  answers['b3'] = { v: 'bad', note: 'مصرف المطبخ الخلفي راكد ويحتاج تنظيفًا فوريًا.' };
  const c = computeRound(answers);
  const at = new Date(); at.setDate(at.getDate() - 1); at.setHours(11, 0, 0, 0);
  s.rounds.push({
    id: uid(), at: at.toISOString(), inspector: s.settings.inspector, branch: s.settings.branch,
    score: c.score, grade: c.grade, ok: c.ok, obs: c.obs, bad: c.bad, critBad: c.critBad,
    rated: c.rated, total: c.total, answers, ncIds: [],
  });
  createNc({
    source: 'round', title: 'الأرضيات والمصارف نظيفة وجافة وبلا روائح',
    detail: 'القسم: المرافق والنظافة العامة — مصرف المطبخ الخلفي راكد ويحتاج تنظيفًا فوريًا.',
    severity: 'major', owner: s.settings.inspector, due: addDays(dayKey(), 2),
  });

  s.items.push(
    { id: uid(), name: 'حليب طازج ٢ لتر', loc: 'ثلاجة الحليب', batch: 'المراعي · L4471', openedAt: dayKey(), expiry: addDays(dayKey(), 2), at: new Date().toISOString() },
    { id: uid(), name: 'كريمة خفق مفتوحة', loc: 'ثلاجة التحضير', batch: '', openedAt: addDays(dayKey(), -3), expiry: addDays(dayKey(), -1), at: new Date().toISOString() },
    { id: uid(), name: 'صوص كراميل', loc: 'المخزن الجاف', batch: 'تشغيلة 88', openedAt: addDays(dayKey(), -2), expiry: addDays(dayKey(), 12), at: new Date().toISOString() },
  );

  store.save(); closeSheet(); go('today');
  toast('أُضيفت بيانات نموذجية للتجربة', 'ok');
}

/* ═══════════════════════════════════════════════════════════
   الإقلاع
   ═══════════════════════════════════════════════════════════ */
store.load();
applyTheme();
matchMedia('(prefers-color-scheme: dark)').addEventListener('change', applyTheme);
$('temp-value').addEventListener('input', updateVerdict);
$('it-opened').addEventListener('change', () => { $('it-expiry').value = addDays($('it-opened').value || dayKey(), shelfDays); });
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeSheet(); });
render();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
}
