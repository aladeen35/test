/* ═══════════════════════════════════════════════════════════
   سلامة — طبقة البيانات
   المعايير المرجعية، قائمة التفتيش، والتخزين المحلي
   ═══════════════════════════════════════════════════════════ */

const STORE_KEY = 'salamah:v1';

/* ── أنواع نقاط القياس ومداها المسموح ──
   المدى الافتراضي مبني على المتطلبات العامة لسلامة الغذاء
   (الهيئة العامة للغذاء والدواء / مبادئ الهاسب) وقابل للتعديل من الإعدادات. */
const POINT_TYPES = {
  chill:   { name: 'ثلاجة تبريد',            min: 0,   max: 5,   unit: '°C',  critical: true  },
  display: { name: 'ثلاجة عرض / سلطات',      min: 0,   max: 5,   unit: '°C',  critical: true  },
  freeze:  { name: 'مجمّد (فريزر)',           min: -30, max: -18, unit: '°C',  critical: true  },
  hot:     { name: 'حفظ ساخن',                min: 60,  max: 95,  unit: '°C',  critical: true  },
  cook:    { name: 'قلب المنتج بعد الطهي',    min: 75,  max: 100, unit: '°C',  critical: true  },
  reheat:  { name: 'إعادة تسخين',             min: 74,  max: 100, unit: '°C',  critical: true  },
  dry:     { name: 'مخزن جاف',                min: 10,  max: 25,  unit: '°C',  critical: false },
  water:   { name: 'ماء الغسيل الساخن',       min: 60,  max: 90,  unit: '°C',  critical: false },
  sanit:   { name: 'محلول التطهير (كلور)',    min: 100, max: 200, unit: 'ppm', critical: false },
};

/* نقاط القياس الافتراضية — تُعدّل من الإعدادات */
const DEFAULT_POINTS = [
  { id: 'p1', name: 'ثلاجة الحليب',        type: 'chill'   },
  { id: 'p2', name: 'ثلاجة التحضير',       type: 'chill'   },
  { id: 'p3', name: 'ثلاجة عرض الحلويات',  type: 'display' },
  { id: 'p4', name: 'الفريزر الرئيسي',     type: 'freeze'  },
  { id: 'p5', name: 'سخّان الحفظ',          type: 'hot'     },
  { id: 'p6', name: 'المخزن الجاف',        type: 'dry'      },
  { id: 'p7', name: 'محلول تطهير الأسطح',  type: 'sanit'   },
];

/* ── قائمة جولة التفتيش ── علامة * تعني بندًا حرجًا (وزنه ٣ أضعاف) */
const CHECKLIST = [
  {
    id: 's1', title: 'صحة ونظافة العاملين', icon: '🧑‍🍳',
    items: [
      { id: 'a1', text: 'الزي كامل ونظيف (مريلة، غطاء رأس، حذاء مغلق)' },
      { id: 'a2', text: 'أظافر مقلّمة، بلا حلي أو ساعات، بلا عطر قوي' },
      { id: 'a3', text: 'غسل الأيدي بالطريقة والتكرار الصحيحين', crit: true },
      { id: 'a4', text: 'لا يوجد عامل بأعراض مرضية أو جروح مكشوفة', crit: true },
      { id: 'a5', text: 'الشهادات الصحية سارية لجميع العاملين' },
    ],
  },
  {
    id: 's2', title: 'المرافق والنظافة العامة', icon: '🧽',
    items: [
      { id: 'b1', text: 'مغسلة الأيدي مزوّدة بصابون ومناديل وماء ساخن', crit: true },
      { id: 'b2', text: 'أسطح التحضير نظيفة ومطهّرة' },
      { id: 'b3', text: 'الأرضيات والمصارف نظيفة وجافة وبلا روائح' },
      { id: 'b4', text: 'حاويات النفايات مغطاة ويتم إفراغها بانتظام' },
      { id: 'b5', text: 'الشفاطات والفلاتر نظيفة وتعمل' },
      { id: 'b6', text: 'أدوات التنظيف مخصّصة ومخزّنة بشكل صحيح' },
    ],
  },
  {
    id: 's3', title: 'التخزين', icon: '📦',
    items: [
      { id: 'c1', text: 'فصل النيء عن الجاهز للأكل في التخزين', crit: true },
      { id: 'c2', text: 'لا توجد مواد منتهية أو عبوات منتفخة أو تالفة', crit: true },
      { id: 'c3', text: 'المواد الكيميائية مخزّنة بعيدًا عن الغذاء', crit: true },
      { id: 'c4', text: 'المواد مرفوعة عن الأرض وبعيدة عن الجدار' },
      { id: 'c5', text: 'نظام FIFO/FEFO مطبّق مع بطاقات تاريخ واضحة' },
      { id: 'c6', text: 'العبوات المفتوحة مغلقة ومعنونة بتاريخ الفتح' },
    ],
  },
  {
    id: 's4', title: 'التحضير والمعالجة', icon: '🔪',
    items: [
      { id: 'd1', text: 'المواد الحساسة لا تُترك بحرارة الغرفة أكثر من ساعتين', crit: true },
      { id: 'd2', text: 'التبريد السريع مطبّق (٦٠→٢١ خلال ساعتين، ٢١→٥ خلال ٤ ساعات)', crit: true },
      { id: 'd3', text: 'التذويب بطريقة آمنة (ثلاجة أو ماء جارٍ بارد)', crit: true },
      { id: 'd4', text: 'ألواح وأدوات التقطيع مستخدمة حسب الترميز اللوني' },
      { id: 'd5', text: 'لا تلوث متبادل أثناء التحضير والتقديم' },
      { id: 'd6', text: 'الزيت سليم ويُستبدل حسب الجدول' },
    ],
  },
  {
    id: 's5', title: 'مكافحة الحشرات والصيانة', icon: '🐜',
    items: [
      { id: 'e1', text: 'لا آثار حشرات أو قوارض', crit: true },
      { id: 'e2', text: 'الأبواب والنوافذ محكمة والستائر الهوائية تعمل' },
      { id: 'e3', text: 'عقد المكافحة وسجل الزيارات محدّثان' },
      { id: 'e4', text: 'لا تسريبات مياه ولا أسطح أو معدات تالفة' },
    ],
  },
  {
    id: 's6', title: 'التوثيق والمعايرة', icon: '📋',
    items: [
      { id: 'f1', text: 'سجلات الحرارة مكتملة وموقّعة' },
      { id: 'f2', text: 'معايرة مقياس الحرارة موثّقة (اختبار الثلج ٠°م)' },
      { id: 'f3', text: 'فواتير وشهادات الموردين محفوظة' },
      { id: 'f4', text: 'خطة الهاسب وتحليل المخاطر متاحة ومحدّثة' },
      { id: 'f5', text: 'المخالفات السابقة أُغلقت بإجراء تصحيحي موثّق' },
    ],
  },
];

const RATE_LABEL = { ok: 'مطابق', obs: 'ملاحظة', bad: 'مخالف', na: 'لا ينطبق' };
const SEVERITY_LABEL = { critical: 'حرجة', major: 'كبيرة', minor: 'بسيطة' };
const WEEKDAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

/* ═══════════ أدوات مساعدة ═══════════ */
/** عزل اتجاهي: يمنع انقلاب الأرقام والوحدات داخل نص عربي (‎9°C‎ لا C°9) */
const ltr = (s) => '\u2066' + s + '\u2069';
const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
const pad2 = (n) => String(n).padStart(2, '0');

const dayKey = (d = new Date()) => {
  const x = new Date(d);
  return `${x.getFullYear()}-${pad2(x.getMonth() + 1)}-${pad2(x.getDate())}`;
};
const fmtTime = (iso) => {
  const d = new Date(iso);
  return `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
};
const fmtDate = (iso) => dayKey(new Date(iso));
const fmtDateTime = (iso) => `${fmtDate(iso)} · ${fmtTime(iso)}`;
const fmtDayName = (iso) => WEEKDAYS[new Date(iso).getDay()];

/** فرق الأيام بين تاريخين (تقويميًا) — سالب = مضى */
function daysLeft(dateStr) {
  if (!dateStr) return null;
  const a = new Date(dateStr + 'T00:00:00');
  const b = new Date(dayKey() + 'T00:00:00');
  return Math.round((a - b) / 86400000);
}

/** إضافة أيام على تاريخ بصيغة YYYY-MM-DD */
function addDays(dateStr, n) {
  const d = new Date(dateStr + 'T00:00:00');
  d.setDate(d.getDate() + Number(n));
  return dayKey(d);
}

/** هل القراءة داخل المدى المسموح؟ */
function readingStatus(type, value, ranges) {
  const r = (ranges && ranges[type]) || POINT_TYPES[type];
  if (!r || value === '' || value === null || isNaN(value)) return { ok: null };
  const v = Number(value);
  return { ok: v >= Number(r.min) && v <= Number(r.max), min: r.min, max: r.max, unit: POINT_TYPES[type].unit };
}

/* ═══════════ التخزين ═══════════ */
const blankState = () => ({
  v: 1,
  settings: {
    inspector: '',
    branch: '',
    theme: 'auto',
    ranges: Object.fromEntries(Object.entries(POINT_TYPES).map(([k, t]) => [k, { min: t.min, max: t.max }])),
    points: DEFAULT_POINTS.map((p) => ({ ...p })),
  },
  readings: [],   // قراءات الحرارة والتطهير
  rounds: [],     // جولات التفتيش
  items: [],      // أصناف الصلاحية والاستلام
  ncs: [],        // المخالفات والإجراءات التصحيحية
});

const store = {
  state: blankState(),

  load() {
    try {
      const raw = localStorage.getItem(STORE_KEY);
      if (raw) {
        const saved = JSON.parse(raw);
        const base = blankState();
        this.state = {
          ...base, ...saved,
          settings: {
            ...base.settings, ...(saved.settings || {}),
            ranges: { ...base.settings.ranges, ...((saved.settings || {}).ranges || {}) },
            points: (saved.settings && saved.settings.points) || base.settings.points,
          },
        };
      }
    } catch (e) {
      console.warn('تعذّر تحميل البيانات المحفوظة', e);
    }
    return this.state;
  },

  save() {
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify(this.state));
    } catch (e) {
      alert('تعذّر الحفظ: مساحة التخزين ممتلئة. صدّر البيانات ثم امسح القديم.');
    }
  },

  reset() {
    this.state = blankState();
    this.save();
  },
};

/* ═══════════ صور المخالفات (IndexedDB) ═══════════ */
const photos = {
  db: null,
  open() {
    if (this.db) return Promise.resolve(this.db);
    return new Promise((res, rej) => {
      const req = indexedDB.open('salamah-photos', 1);
      req.onupgradeneeded = () => {
        if (!req.result.objectStoreNames.contains('p')) req.result.createObjectStore('p');
      };
      req.onsuccess = () => { this.db = req.result; res(this.db); };
      req.onerror = () => rej(req.error);
    });
  },
  async put(id, dataUrl) {
    const db = await this.open();
    return new Promise((res, rej) => {
      const tx = db.transaction('p', 'readwrite');
      tx.objectStore('p').put(dataUrl, id);
      tx.oncomplete = res; tx.onerror = () => rej(tx.error);
    });
  },
  async get(id) {
    if (!id) return null;
    const db = await this.open();
    return new Promise((res) => {
      const r = db.transaction('p', 'readonly').objectStore('p').get(id);
      r.onsuccess = () => res(r.result || null);
      r.onerror = () => res(null);
    });
  },
  async del(id) {
    if (!id) return;
    const db = await this.open();
    db.transaction('p', 'readwrite').objectStore('p').delete(id);
  },
};

/** ضغط صورة من ملف إلى JPEG بعرض أقصى 900px */
function compressImage(file, maxW = 900, quality = 0.72) {
  return new Promise((res, rej) => {
    const fr = new FileReader();
    fr.onload = () => {
      const img = new Image();
      img.onload = () => {
        const scale = Math.min(1, maxW / img.width);
        const c = document.createElement('canvas');
        c.width = Math.round(img.width * scale);
        c.height = Math.round(img.height * scale);
        c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
        res(c.toDataURL('image/jpeg', quality));
      };
      img.onerror = rej;
      img.src = fr.result;
    };
    fr.onerror = rej;
    fr.readAsDataURL(file);
  });
}
