/* ═══════════════════════════════════════════════
   أدوات البشري — حساب مواقيت الصلاة والقبلة والتاريخ الهجري
   يعمل بالكامل على الجهاز دون إنترنت
   الطريقة الافتراضية: الهيئة المصرية العامة للمساحة (الفجر 19.5° — العشاء 17.5°)
   وهي المعتمدة في تقاويم السودان
   ═══════════════════════════════════════════════ */

const TZ = 'Africa/Khartoum';

const METHODS = {
  egypt: { name: 'الهيئة المصرية العامة للمساحة (السودان)', fajr: 19.5, isha: 17.5 },
  mwl: { name: 'رابطة العالم الإسلامي', fajr: 18, isha: 17 },
  makkah: { name: 'أم القرى', fajr: 18.5, ishaMin: 90 },
  karachi: { name: 'جامعة العلوم الإسلامية بكراتشي', fajr: 18, isha: 18 },
};

const PRAYER_NAMES = { fajr: 'الفجر', sunrise: 'الشروق', dhuhr: 'الظهر', asr: 'العصر', maghrib: 'المغرب', isha: 'العشاء' };
const PRAYER_ORDER = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

const PrayerCalc = (() => {
  const rad = (d) => (d * Math.PI) / 180;
  const deg = (r) => (r * 180) / Math.PI;
  const sin = (d) => Math.sin(rad(d));
  const cos = (d) => Math.cos(rad(d));
  const tan = (d) => Math.tan(rad(d));
  const arcsin = (x) => deg(Math.asin(x));
  const arccos = (x) => deg(Math.acos(Math.max(-1, Math.min(1, x))));
  const arctan2 = (y, x) => deg(Math.atan2(y, x));
  const arccot = (x) => deg(Math.atan(1 / x));
  const fix = (a, b) => { a -= b * Math.floor(a / b); return a < 0 ? a + b : a; };

  function julian(y, m, d) {
    if (m <= 2) { y -= 1; m += 12; }
    const A = Math.floor(y / 100);
    const B = 2 - A + Math.floor(A / 4);
    return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + d + B - 1524.5;
  }

  function sunPos(jd) {
    const D = jd - 2451545.0;
    const g = fix(357.529 + 0.98560028 * D, 360);
    const q = fix(280.459 + 0.98564736 * D, 360);
    const L = fix(q + 1.915 * sin(g) + 0.020 * sin(2 * g), 360);
    const e = 23.439 - 0.00000036 * D;
    const RA = fix(arctan2(cos(e) * sin(L), cos(L)) / 15, 24);
    return { decl: arcsin(sin(e) * sin(L)), eqt: q / 15 - RA };
  }

  // يحسب المواقيت لتاريخ (سنة/شهر/يوم بتوقيت السودان) ويعيد كائنات Date مطلقة
  function times(y, m, d, lat, lng, opts = {}) {
    const method = METHODS[opts.method] || METHODS.egypt;
    const asrFactor = opts.asr === 'hanafi' ? 2 : 1;
    const jd = julian(y, m, d) - lng / (15 * 24);

    const midDay = (t) => fix(12 - sunPos(jd + t).eqt, 24);
    const angleTime = (angle, t, ccw) => {
      const decl = sunPos(jd + t).decl;
      const noon = midDay(t);
      const T = arccos((-sin(angle) - sin(decl) * sin(lat)) / (cos(decl) * cos(lat))) / 15;
      return noon + (ccw ? -T : T);
    };
    const asrTime = (factor, t) => {
      const decl = sunPos(jd + t).decl;
      return angleTime(-arccot(factor + tan(Math.abs(lat - decl))), t);
    };

    // تمريرتان لتحسين الدقة
    let t = { fajr: 5, sunrise: 6, dhuhr: 12, asr: 13, maghrib: 18, isha: 18 };
    for (let i = 0; i < 2; i++) {
      const p = Object.fromEntries(Object.entries(t).map(([k, v]) => [k, v / 24]));
      t = {
        fajr: angleTime(method.fajr, p.fajr, true),
        sunrise: angleTime(0.833, p.sunrise, true),
        dhuhr: midDay(p.dhuhr),
        asr: asrTime(asrFactor, p.asr),
        maghrib: angleTime(0.833, p.maghrib),
        isha: method.ishaMin ? null : angleTime(method.isha, p.isha),
      };
      if (method.ishaMin) t.isha = t.maghrib + method.ishaMin / 60;
    }

    const base = Date.UTC(y, m - 1, d);
    const adj = opts.adjust || {};
    const out = {};
    for (const k of PRAYER_ORDER) {
      const utcHours = t[k] - lng / 15;
      out[k] = new Date(base + Math.round((utcHours * 60 + (adj[k] || 0)) * 60000));
    }
    return out;
  }

  // اتجاه القبلة بالدرجات من الشمال الجغرافي
  function qibla(lat, lng) {
    const kLat = 21.4225, kLng = 39.8262;
    const dL = kLng - lng;
    return fix(arctan2(sin(dL), cos(lat) * tan(kLat) - sin(lat) * cos(dL)), 360);
  }

  // المسافة إلى مكة بالكيلومتر
  function distanceToMakkah(lat, lng) {
    const R = 6371, kLat = 21.4225, kLng = 39.8262;
    const a = sin((kLat - lat) / 2) ** 2 + cos(lat) * cos(kLat) * sin((kLng - lng) / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(a));
  }

  return { times, qibla, distanceToMakkah };
})();

// أجزاء التاريخ بتوقيت السودان
function sdParts(date = new Date()) {
  const p = new Intl.DateTimeFormat('en-US', { timeZone: TZ, year: 'numeric', month: 'numeric', day: 'numeric' })
    .formatToParts(date).reduce((o, x) => (o[x.type] = x.value, o), {});
  return { y: +p.year, m: +p.month, d: +p.day };
}

function fmtTime(date, withSec = false) {
  return new Intl.DateTimeFormat('ar', {
    timeZone: TZ, hour: 'numeric', minute: '2-digit', ...(withSec ? { second: '2-digit' } : {}), hour12: true, numberingSystem: 'latn',
  }).format(date);
}

function fmtDate(date, opts = { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }) {
  return new Intl.DateTimeFormat('ar', { timeZone: TZ, numberingSystem: 'latn', ...opts }).format(date);
}

// التاريخ الهجري (تقويم أم القرى مع إمكانية التعديل ± يوم حسب رؤية الهلال)
function hijri(date = new Date(), shift = 0) {
  const d = new Date(date.getTime() + shift * 86400000);
  const f = new Intl.DateTimeFormat('ar-u-ca-islamic-umalqura-nu-latn', { timeZone: TZ, day: 'numeric', month: 'long', year: 'numeric' });
  const parts = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura-nu-latn', { timeZone: TZ, day: 'numeric', month: 'numeric', year: 'numeric' })
    .formatToParts(d).reduce((o, x) => (o[x.type] = x.value, o), {});
  return { text: f.format(d).replace(/\s?هـ$/, '') + ' هـ', y: parseInt(parts.year), m: +parts.month, d: +parts.day };
}

const HIJRI_MONTHS = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];

// تحويل هجري ← ميلادي بالبحث حول تقدير أولي
function hijriToGregorian(hy, hm, hd) {
  const est = Date.UTC(622, 6, 16) + ((hy - 1) * 354.36707 + (hm - 1) * 29.530588 + (hd - 1)) * 86400000;
  const day0 = Math.floor(est / 86400000) * 86400000;
  for (let off = -40; off <= 40; off++) {
    // الظهيرة بتوقيت السودان (UTC+2) لتجنّب حدود منتصف الليل
    const g = new Date(day0 + off * 86400000 + 10 * 3600000);
    const h = hijri(g);
    if (h.y === hy && h.m === hm && h.d === hd) return g;
  }
  return null;
}
