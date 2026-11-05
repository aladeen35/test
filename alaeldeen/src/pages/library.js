/* 3D reference library: CSS 3D books on wooden shelves, animated with GSAP.
   Hover pulls a book off the shelf, click opens it in the reading panel, the whole
   bookcase leans towards the pointer and the shelves settle in as you scroll. */
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { AR_BOOKS, AR_SHELVES } from "./library-ar.js";

const A = window.APP, I = window.ICONS, S = window.SITE;
const { esc, L, t, $, $$, pageHead } = A;
const W = (a, e) => (A.lang === "ar" ? a : e);
const reduce = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const CAT = {
  fs: { ar: "سلامة الغذاء", en: "Food safety" },
  std: { ar: "المواصفات وأنظمة الإدارة", en: "Standards & systems" },
  reg: { ar: "التشريعات والجهات الرقابية", en: "Regulation" },
  micro: { ar: "الميكروبيولوجيا والمختبر", en: "Microbiology & lab" },
  nut: { ar: "التغذية", en: "Nutrition" },
  ohs: { ar: "السلامة المهنية", en: "Occupational safety" },
  mine: { ar: "مؤلفاتي", en: "My books" },
};
const CODEX_COP = "https://www.fao.org/fao-who-codexalimentarius/codex-texts/codes-of-practice/en/";
const CODEX_STD = "https://www.fao.org/fao-who-codexalimentarius/codex-texts/list-standards/en/";
const ONLINE = { ar: "متجدد", en: "Online" };

// every link was checked when this list was written; ISO standards are paid, so they open ISO's official page
const BOOKS = [
  { id: "codex-gph", shelf: "intl", cat: "fs", code: "CXC 1", sub: "General Principles of Food Hygiene", issuer: "Codex Alimentarius (FAO/WHO)", year: "2022", c: ["#1f6b4f", "#0e3b2c"],
    title: { ar: "المبادئ العامة لصحة الغذاء", en: "General Principles of Food Hygiene" },
    desc: { ar: "النص الأساسي الدولي لصحة الغذاء من الدستور الغذائي: الممارسات الصحية الجيدة GHP، ومعه الملحق الكامل لنظام HACCP بمبادئه السبع وخطواته الاثنتي عشرة. مراجعة 2020 وتعديل 2022.", en: "Codex's core international text on food hygiene: Good Hygiene Practices, plus the full HACCP system with its seven principles and twelve steps. Revised 2020, amended 2022." },
    points: [{ ar: "أساس GHP وHACCP عالميًا", en: "The global basis for GHP and HACCP" }, { ar: "شجرة قرار نقاط التحكم الحرجة", en: "CCP decision tree" }, { ar: "مجاني من الموقع الرسمي", en: "Free from the official site" }], url: CODEX_COP },
  { id: "codex-alg", shelf: "intl", cat: "fs", code: "CXC 80", sub: "Food Allergen Management", issuer: "Codex Alimentarius (FAO/WHO)", year: "2020", c: ["#2a7a5e", "#123f30"],
    title: { ar: "مدونة إدارة مسببات الحساسية", en: "Code of Practice on Food Allergen Management" },
    desc: { ar: "إرشادات عملية لمشغلي منشآت الغذاء لمنع الانتقال العرضي لمسببات الحساسية وضمان الإفصاح الصحيح عنها، من الاستلام حتى الملصق.", en: "Practical guidance for food businesses to prevent allergen cross-contact and declare allergens correctly, from receipt to label." },
    points: [{ ar: "الفصل والتنظيف بين التشغيلات", en: "Segregation and clean-down between runs" }, { ar: "التحقق من الملصق", en: "Label verification" }, { ar: "تدريب العاملين", en: "Staff training" }], url: CODEX_COP },
  { id: "codex-lbl", shelf: "intl", cat: "reg", code: "CXS 1", sub: "Labelling of Prepackaged Foods", issuer: "Codex Alimentarius (FAO/WHO)", year: "2018", c: ["#357f68", "#163f33"],
    title: { ar: "المواصفة العامة لبطاقات الأغذية المعبأة", en: "General Standard for the Labelling of Prepackaged Foods" },
    desc: { ar: "ما يجب أن يظهر على ملصق الغذاء المعبأ: الاسم، والمكونات بترتيبها، ومسببات الحساسية، والكمية، والتواريخ، وظروف الحفظ، وبلد المنشأ.", en: "What must appear on a prepackaged food label: name, ingredients in order, allergens, quantity, dates, storage conditions and origin." },
    points: [{ ar: "مرجع مراجعة الملصقات", en: "Reference for label checks" }, { ar: "التواريخ وظروف الحفظ", en: "Date marking and storage" }], url: CODEX_STD },
  { id: "who-5keys", shelf: "intl", cat: "fs", code: "5 KEYS", sub: "to Safer Food", issuer: "World Health Organization", year: "2006", c: ["#1d6fa8", "#0c3757"],
    title: { ar: "المفاتيح الخمسة لأغذية أكثر أمانًا", en: "Five Keys to Safer Food Manual" },
    desc: { ar: "دليل منظمة الصحة العالمية للتدريب على سلامة الغذاء: حافظ على النظافة، افصل النيء عن المطبوخ، اطهِ جيدًا، احفظ الغذاء في درجات حرارة آمنة، استخدم ماءً ومواد خام آمنة. متاح بعدة لغات منها العربية.", en: "WHO's food safety training manual: keep clean, separate raw and cooked, cook thoroughly, keep food at safe temperatures, use safe water and raw materials. Available in many languages, Arabic included." },
    points: [{ ar: "ممتاز لتدريب العاملين", en: "Excellent for staff training" }, { ar: "نسخة عربية رسمية", en: "Official Arabic version" }], url: "https://www.who.int/publications/i/item/9789241594639" },
  { id: "fda-code", shelf: "intl", cat: "reg", code: "FOOD CODE", sub: "2022", issuer: "U.S. FDA", year: "2022", c: ["#24426e", "#0f1f38"],
    title: { ar: "قانون الغذاء الأمريكي (Food Code)", en: "FDA Food Code 2022" },
    desc: { ar: "نموذج لوائح سلامة الغذاء في المطاعم والمتاجر والمطابخ: النظافة الشخصية، ودرجات الحرارة، والتبريد، والتنظيف. مرجع عملي واسع الاستخدام عالميًا.", en: "Model food safety rules for restaurants, retail and kitchens: personal hygiene, temperatures, cooling and cleaning. A widely used practical reference." },
    points: [{ ar: "تفاصيل عملية لخدمات الطعام", en: "Practical food-service detail" }, { ar: "ملف PDF مجاني", en: "Free PDF" }], pdf: "https://www.fda.gov/media/164194/download", url: "https://www.fda.gov/food/fda-food-code/food-code-2022" },
  { id: "fsma-pc", shelf: "intl", cat: "reg", code: "FSMA", sub: "Preventive Controls", issuer: "U.S. FDA", year: "2015", c: ["#2c4d7d", "#132340"],
    title: { ar: "الضوابط الوقائية للأغذية البشرية (FSMA)", en: "FSMA Preventive Controls for Human Food" },
    desc: { ar: "القاعدة الأمريكية التي تُلزم المنشآت بخطة سلامة غذاء مبنية على المخاطر: تحليل المخاطر، والضوابط الوقائية، وسلسلة الإمداد، والاستدعاء.", en: "The US rule requiring a risk-based food safety plan: hazard analysis, preventive controls, supply-chain programme and recall plan." },
    points: [{ ar: "مقارنة مفيدة مع HACCP", en: "Useful comparison with HACCP" }], url: "https://www.fda.gov/food/food-safety-modernization-act-fsma/fsma-final-rule-preventive-controls-human-food" },

  { id: "iso22000", shelf: "std", cat: "std", code: "ISO 22000", sub: "Food Safety Management", issuer: "ISO", year: "2018", c: ["#1c5fae", "#0b2b57"], paid: true,
    title: { ar: "ISO 22000 — نظام إدارة سلامة الغذاء", en: "ISO 22000 — Food safety management systems" },
    desc: { ar: "مواصفة دولية لنظام إدارة سلامة الغذاء لأي منظمة في السلسلة الغذائية، تجمع مبادئ HACCP مع التفكير المبني على المخاطر والتحسين المستمر.", en: "International standard for a food safety management system for any organization in the food chain, combining HACCP with risk-based thinking and continual improvement." },
    points: [{ ar: "PRPs وOPRPs وخطة HACCP", en: "PRPs, OPRPs and the HACCP plan" }, { ar: "هيكل متوافق مع ISO 9001", en: "Structure aligned with ISO 9001" }], url: "https://www.iso.org/standard/65464.html" },
  { id: "iso22002", shelf: "std", cat: "std", code: "ISO/TS 22002-1", sub: "PRPs — Manufacturing", issuer: "ISO", year: "2009", c: ["#2766a8", "#10305a"], paid: true,
    title: { ar: "البرامج التمهيدية — التصنيع الغذائي", en: "Prerequisite programmes — Food manufacturing" },
    desc: { ar: "تفصيل البرامج التمهيدية المطلوبة في مصانع الغذاء: المبنى، والمرافق، والمعدات، والنظافة، ومكافحة الآفات، والنظافة الشخصية.", en: "Details the prerequisite programmes for food manufacturing: buildings, utilities, equipment, cleaning, pest control and personal hygiene." },
    points: [{ ar: "يكمل ISO 22000 في المصانع", en: "Complements ISO 22000 in factories" }], url: "https://www.iso.org/standard/44001.html" },
  { id: "iso9001", shelf: "std", cat: "std", code: "ISO 9001", sub: "Quality Management", issuer: "ISO", year: "2015", c: ["#3a5f9e", "#18294d"], paid: true,
    title: { ar: "ISO 9001 — نظام إدارة الجودة", en: "ISO 9001 — Quality management systems" },
    desc: { ar: "أكثر مواصفات إدارة الجودة انتشارًا: التركيز على العميل، والنهج بالعمليات، والتفكير المبني على المخاطر، والتحسين المستمر.", en: "The most widely used quality management standard: customer focus, process approach, risk-based thinking and continual improvement." },
    points: [{ ar: "أساس أنظمة الإدارة", en: "Foundation for management systems" }], url: "https://www.iso.org/standard/62085.html" },
  { id: "iso19011", shelf: "std", cat: "std", code: "ISO 19011", sub: "Auditing Guidelines", issuer: "ISO", year: "2018", c: ["#4b5d8f", "#1c2443"], paid: true,
    title: { ar: "ISO 19011 — إرشادات تدقيق أنظمة الإدارة", en: "ISO 19011 — Guidelines for auditing management systems" },
    desc: { ar: "كيف تخطط برنامج التدقيق وتنفذه: مبادئ التدقيق، وجمع الأدلة، وكتابة الملاحظات، وكفاءة المدققين.", en: "How to plan and run an audit programme: audit principles, gathering evidence, writing findings and auditor competence." },
    points: [{ ar: "مرجع المدقق الداخلي", en: "The internal auditor's reference" }], url: "https://www.iso.org/standard/70017.html" },
  { id: "fssc", shelf: "std", cat: "std", code: "FSSC 22000", sub: "Version 6", issuer: "Foundation FSSC", year: "2023", c: ["#3f8f3a", "#1a4419"],
    title: { ar: "مخطط شهادة FSSC 22000", en: "FSSC 22000 certification scheme" },
    desc: { ar: "مخطط شهادة معترف به من GFSI يجمع ISO 22000 والبرامج التمهيدية القطاعية ومتطلبات إضافية مثل ثقافة سلامة الغذاء والدفاع الغذائي.", en: "GFSI-recognised certification scheme combining ISO 22000, sector PRPs and additional requirements such as food safety culture and food defense." },
    points: [{ ar: "معترف به من GFSI", en: "GFSI-recognised" }, { ar: "ثقافة سلامة الغذاء", en: "Food safety culture" }], url: "https://www.fssc.com/schemes/fssc-22000/" },
  { id: "gfsi", shelf: "std", cat: "std", code: "GFSI", sub: "Benchmarking", issuer: "Global Food Safety Initiative", year: ONLINE, c: ["#5a7d2e", "#263714"],
    title: { ar: "المبادرة العالمية لسلامة الغذاء GFSI", en: "Global Food Safety Initiative (GFSI)" },
    desc: { ar: "الجهة التي تعتمد مخططات شهادات سلامة الغذاء (مثل FSSC 22000 وBRCGS وIFS) وفق متطلبات مقارنة موحدة.", en: "The body that benchmarks food safety certification schemes (such as FSSC 22000, BRCGS and IFS) against common requirements." },
    points: [{ ar: "يشرح الفرق بين المخططات", en: "Explains how schemes compare" }], url: "https://mygfsi.com/" },

  { id: "iso7218", shelf: "lab", cat: "micro", code: "ISO 7218", sub: "Microbiology — General Rules", issuer: "ISO", year: "2007", c: ["#6b3f8f", "#2f1a44"], paid: true,
    title: { ar: "ISO 7218 — القواعد العامة للفحوص الميكروبيولوجية", en: "ISO 7218 — General requirements for microbiological examinations" },
    desc: { ar: "قواعد المختبر الميكروبيولوجي: تحضير العينات والتخفيفات، والأوساط، والتحضين، وحساب النتائج وتقريبها. منها معادلة العدّ المستخدمة في حاسبة CFU بالموقع.", en: "Rules for the microbiology lab: sample preparation and dilutions, media, incubation, and calculating and rounding results, including the count formula used by this site's CFU calculator." },
    points: [{ ar: "حساب CFU وتقريبه", en: "CFU calculation and rounding" }], url: "https://www.iso.org/standard/36534.html" },
  { id: "bam", shelf: "lab", cat: "micro", code: "BAM", sub: "Bacteriological Analytical Manual", issuer: "U.S. FDA", year: ONLINE, c: ["#7a3f6b", "#371a30"],
    title: { ar: "دليل التحليل البكتيريولوجي BAM", en: "Bacteriological Analytical Manual (BAM)" },
    desc: { ar: "طرق المختبر المرجعية لدى FDA للكشف عن الممرضات والكائنات الدالة في الغذاء: السالمونيلا، والليستيريا، وE. coli، والعدّ الكلي، والخمائر والفطريات.", en: "FDA's reference lab methods for pathogens and indicator organisms in food: Salmonella, Listeria, E. coli, aerobic plate count, yeasts and moulds." },
    points: [{ ar: "طرق مفصلة ومجانية", en: "Detailed, free methods" }], url: "https://www.fda.gov/food/laboratory-methods-food/bacteriological-analytical-manual-bam" },
  { id: "efsa", shelf: "lab", cat: "reg", code: "EFSA", sub: "European Food Safety Authority", issuer: "EFSA", year: ONLINE, c: ["#2d5d7b", "#122838"],
    title: { ar: "الهيئة الأوروبية لسلامة الأغذية", en: "European Food Safety Authority" },
    desc: { ar: "آراء علمية وتقييمات مخاطر في الممرضات، والمضافات، والملوثات، والتغذية. مصدر مهم للأدلة العلمية.", en: "Scientific opinions and risk assessments on pathogens, additives, contaminants and nutrition. A key evidence source." },
    points: [{ ar: "تقييمات مخاطر علمية", en: "Scientific risk assessments" }], url: "https://www.efsa.europa.eu/en" },
  { id: "sfda", shelf: "lab", cat: "reg", code: "SFDA", sub: "Regulations", issuer: "الهيئة العامة للغذاء والدواء", year: ONLINE, c: ["#0f6e6e", "#06302f"],
    title: { ar: "أنظمة ولوائح الهيئة العامة للغذاء والدواء", en: "Saudi Food & Drug Authority regulations" },
    desc: { ar: "اللوائح الفنية والاشتراطات المعمول بها في المملكة العربية السعودية. المرجع الأول لأي حد أو اشتراط يُطبق في منشأتك داخل المملكة.", en: "The technical regulations and requirements in force in Saudi Arabia: the first reference for any limit or requirement applied in a Saudi facility." },
    points: [{ ar: "المرجع الملزم داخل المملكة", en: "Binding reference in Saudi Arabia" }], url: "https://www.sfda.gov.sa/en/regulations" },
  { id: "who-diet", shelf: "lab", cat: "nut", code: "WHO", sub: "Healthy Diet", issuer: "World Health Organization", year: ONLINE, c: ["#b5651d", "#5a300c"],
    title: { ar: "النظام الغذائي الصحي", en: "Healthy diet — fact sheet" },
    desc: { ar: "توصيات منظمة الصحة العالمية للنظام الغذائي الصحي: السكريات الحرة، والملح، والدهون، والخضار والفاكهة، للكبار والأطفال.", en: "WHO recommendations for a healthy diet: free sugars, salt, fats, fruit and vegetables, for adults and children." },
    points: [{ ar: "أرقام توصيات رسمية", en: "Official recommendation figures" }], url: "https://www.who.int/news-room/fact-sheets/detail/healthy-diet" },
  { id: "fao-fs", shelf: "lab", cat: "nut", code: "FAO", sub: "Food Safety & Quality", issuer: "FAO", year: ONLINE, c: ["#2f7d97", "#123541"],
    title: { ar: "سلامة وجودة الغذاء — الفاو", en: "FAO Food Safety and Quality" },
    desc: { ar: "منشورات وأدوات منظمة الأغذية والزراعة في سلامة الغذاء وجودته، والمشورة العلمية، وتقييم المخاطر.", en: "FAO publications and tools on food safety and quality, scientific advice and risk assessment." },
    points: [{ ar: "منشورات مجانية كثيرة", en: "Many free publications" }], url: "https://www.fao.org/food-safety/en/" },
];

function myBooks() {
  return S.books.map((b) => ({ id: "mine-" + b.id, shelf: "mine", cat: "mine", mine: b, issuer: "Eng. Alaeldeen Albushra", year: b.id === "stolen-gold" ? "2026" : { ar: "الجزء الأول", en: "Part 1" },
    title: b.title, desc: b.fullSubtitle || b.blurb, points: b.toc ? [{ ar: `${b.pdfPages} صفحة، 9 فصول في 5 أبواب`, en: `${b.pdfPages} pages, 9 chapters in 5 parts` }, { ar: "من الحقل إلى السوق: سلاسل القيمة وHACCP", en: "Field to market: value chains and HACCP" }, b.edition] : [], url: b.url, cover: b.cover, cta: b.cta, pdf: b.pdf }));
}
const SHELVES = [["mine", { ar: "رف مؤلفاتي", en: "My books" }], ["intl", { ar: "مراجع سلامة الغذاء الدولية", en: "International food safety references" }], ["std", { ar: "المواصفات وأنظمة الإدارة", en: "Standards & management systems" }], ["lab", { ar: "المختبر والتشريعات والتغذية", en: "Lab, regulation & nutrition" }], ...AR_SHELVES];

BOOKS.push(...AR_BOOKS);
const all = () => [...myBooks(), ...BOOKS];
const yearTxt = (b) => (typeof b.year === "string" ? b.year : L(b.year));

function bookHtml(b) {
  const face = b.cover
    ? `<span class="bk-front bk-img"><img src="${b.cover}" alt="" loading="lazy"></span>`
    : `<span class="bk-front"><span class="bk-issuer">${esc(b.issuer.split(" (")[0])}</span><b class="bk-code">${esc(b.code)}</b><span class="bk-sub">${esc(b.sub)}</span><span class="bk-year">${esc(yearTxt(b))}</span></span>`;
  return `<button type="button" class="bk" data-id="${b.id}" style="--c1:${(b.c || ["#3a2a10", "#1a1206"])[0]};--c2:${(b.c || ["#3a2a10", "#1a1206"])[1]}" aria-label="${esc(L(b.title))} — ${esc(yearTxt(b))}">
    <span class="bk-3d">${face}<span class="bk-spine"><span>${esc(b.code || L(b.title))}</span></span><span class="bk-pages"></span><span class="bk-back"></span></span><span class="bk-shadow"></span></button>`;
}

function detailHtml(b) {
  const cover = b.cover ? `<img src="${b.cover}" alt="">` : `<span class="bk-issuer">${esc(b.issuer.split(" (")[0])}</span><b class="bk-code">${esc(b.code)}</b><span class="bk-sub">${esc(b.sub)}</span><span class="bk-year">${esc(yearTxt(b))}</span>`;
  const btns = [];
  if (b.pdf) btns.push(`<a class="btn btn-gold" href="${b.pdf}" target="_blank" rel="noopener">${I.download}<span>${esc(W("فتح PDF", "Open PDF"))}</span></a>`);
  if (b.mine) {
    if (b.mine.featured) btns.push(`<a class="btn btn-gold" href="#/books">${I.book}<span>${esc(W("اقرأ الكتاب", "Read the book"))}</span></a>`);
    btns.push(`<a class="btn ${b.mine.featured ? "btn-line" : "btn-gold"}" href="${b.url}" target="_blank" rel="noopener">${I.play}<span>${esc(L(b.cta))}</span></a>`);
  } else btns.push(`<a class="btn ${b.pdf ? "btn-line" : "btn-gold"}" href="${b.url}" target="_blank" rel="noopener">${I.external}<span>${esc(b.buy ? W("صفحة الكتاب في المتجر", "Book page in store") : b.paid ? W("صفحة المواصفة الرسمية", "Official standard page") : W("زيارة المصدر", "Visit source"))}</span></a>`);
  return `<div class="lb-detail-in" data-for="${b.id}">
    <div class="lb-stage"><div class="lb-book" style="--c1:${(b.c || ["#3a2a10", "#1a1206"])[0]};--c2:${(b.c || ["#3a2a10", "#1a1206"])[1]}"><span class="lb-front ${b.cover ? "bk-img" : ""}">${cover}</span><span class="lb-spine"></span><span class="lb-pages"></span></div></div>
    <div class="lb-info">
      <h2>${esc(L(b.title))}</h2>
      <div class="row" style="gap:8px;margin:10px 0 14px"><span class="chip gold">${esc(L(CAT[b.cat]))}</span>${b.buy ? `<span class="chip">${esc(W("كتاب مدفوع", "Paid book"))}${b.price ? " · " + esc(L(b.price)) : ""}</span>` : b.paid ? `<span class="chip">${esc(W("مواصفة مدفوعة", "Paid standard"))}</span>` : `<span class="chip teal">${esc(b.mine ? W("من تأليفي", "My book") : W("مجاني", "Free"))}</span>`}${b.arabic ? `<span class="chip">${esc(W("باللغة العربية", "In Arabic"))}</span>` : ""}</div>
      <p class="lb-meta">${I.book}<span>${esc(b.issuer)}</span></p>${b.store ? `<p class="lb-meta">${I.external}<span>${esc(W("يُباع في", "Sold at"))}: ${esc(L(b.store))}</span></p>` : ""}<p class="lb-meta">${I.clip}<span>${esc(W("سنة النشر", "Published"))}: ${esc(yearTxt(b))}</span></p>
      <p class="lb-desc">${esc(L(b.desc))}</p>
      ${b.points && b.points.length ? `<h3>${esc(W("أبرز ما فيه", "Key highlights"))}</h3><ul class="ticks">${b.points.map((p) => `<li>${esc(L(p))}</li>`).join("")}</ul>` : ""}
      <div class="cta" style="justify-content:flex-start;margin-top:18px">${btns.join("")}</div>
      <div class="row" style="margin-top:12px">${A.likeBtn("book:" + b.id)}${A.shareBtn({ k: (A.lang === "ar" ? "المكتبة العلمية · " : "Digital Library · ") + L(CAT[b.cat]), t: L(b.title), b: [b.issuer + " · " + yearTxt(b), L(b.desc)], h: b.mine && b.mine.featured ? "#/books" : "#/library", img: b.cover || undefined })}</div>
    </div></div>`;
}

A.pages.library = () => {
  const books = all();
  const cats = Object.entries(CAT).map(([k, v]) => [k, v, books.filter((b) => b.cat === k).length]);
  return {
    title: W("المكتبة العلمية", "Digital Library"),
    html: `${pageHead(W("المكتبة العلمية", "Digital Library"), W("أهم مراجع الجودة وسلامة الغذاء الرسمية على رفوف واحدة، مع رف خاص بمؤلفاتي. اضغط أي كتاب لترى نبذة عنه وتفتحه.", "The key official quality and food safety references on one bookcase, with a shelf for my own books. Tap any book for a summary and a link to open it."), [[W("المكتبة", "Library")]], "lb-head", { eyebrow: W("Digital Library", "المكتبة العلمية"), after: `<p class="lb-quote">${esc(W("«المعرفة… هي المفتاح نحو جودة أفضل وسلامة أعمق في عالمنا الغذائي»", "“Knowledge today… safer food tomorrow.”"))}</p>` })}
    <section class="sec lb"><div class="wrap">
      <div class="lb-tools"><div class="searchbar">${I.search}<input type="search" id="lbq" placeholder="${esc(W("ابحث باسم الكتاب أو الجهة أو الموضوع…", "Search by title, issuer or topic…"))}" aria-label="${esc(W("بحث في المكتبة", "Search the library"))}"></div>
        <div class="filters" role="group" aria-label="${esc(W("التصنيف", "Category"))}"><button class="chip" data-lc="" aria-pressed="true">${esc(W("الكل", "All"))} <b>${books.length}</b></button>${cats.map(([k, v, n]) => `<button class="chip" data-lc="${k}" aria-pressed="false">${esc(L(v))} <b>${n}</b></button>`).join("")}</div></div>
      <div class="lb-layout">
        <div class="lb-case" id="lbCase">${SHELVES.map(([sid, st]) => `<div class="lb-shelf" data-shelf="${sid}"><div class="lb-shelf-label"><span>${esc(L(st))}</span></div><div class="lb-row">${books.filter((b) => b.shelf === sid).map(bookHtml).join("")}</div><div class="lb-plank"></div></div>`).join("")}
          <div class="empty" id="lbEmpty" hidden>${esc(t("noResults"))}</div></div>
        <aside class="lb-detail card" id="lbDetail" aria-live="polite"></aside>
      </div>
      <div class="lb-stats"><div><b>${books.length}</b><span>${esc(W("مرجع وكتاب", "references & books"))}</span></div><div><b>${Object.keys(CAT).length}</b><span>${esc(W("تصنيفات", "categories"))}</span></div><div><b>${BOOKS.filter((b) => !b.paid && !b.buy).length}</b><span>${esc(W("مرجع مجاني", "free references"))}</span></div><p class="note">${esc(W("الروابط تفتح المصادر الرسمية مباشرة. المواصفات الدولية (ISO) مدفوعة، فرابطها يفتح صفحتها الرسمية. الكتب المدفوعة تفتح صفحتها في المتجر، والأسعار تقريبية وقد تتغير.", "Links open the official sources directly. ISO standards are paid, so their link opens the official standard page. Paid books open their store page; prices are approximate and may change."))}</p></div>
    </div></section>`,
    after: () => mount(books),
  };
};

function mount(books) {
  const caseEl = $("#lbCase"), detail = $("#lbDetail");
  const byId = Object.fromEntries(books.map((b) => [b.id, b]));
  const rtl = document.documentElement.dir === "rtl";
  gsap.set(caseEl, { transformPerspective: 1600 });
  let current = null;
  const open = (id, fromUser) => {
    const b = byId[id]; if (!b) return;
    current = id;
    $$(".bk", caseEl).forEach((x) => x.classList.toggle("on", x.dataset.id === id));
    detail.innerHTML = detailHtml(b);
    if (!reduce()) {
      gsap.fromTo(detail.querySelector(".lb-book"), { rotateY: rtl ? 95 : -95, z: -120, autoAlpha: 0 }, { rotateY: rtl ? 22 : -22, z: 0, autoAlpha: 1, duration: 1.1, ease: "cine" });
      gsap.fromTo(detail.querySelectorAll(".lb-info > *"), { y: 18, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.7, stagger: 0.05, ease: "cine", delay: 0.15 });
    }
    if (fromUser && window.innerWidth < 1000) A.scrollTo(detail, true);
  };
  // hover: pull the book off the shelf
  const tilt = rtl ? 18 : -18;
  $$(".bk", caseEl).forEach((bk) => {
    const inner = bk.querySelector(".bk-3d");
    gsap.set(inner, { rotateY: tilt });
    if (reduce()) return;
    bk.addEventListener("pointerenter", () => gsap.to(inner, { rotateY: tilt / 3, z: 46, y: -14, duration: 0.5, ease: "cine" }));
    bk.addEventListener("pointerleave", () => gsap.to(inner, { rotateY: tilt, z: 0, y: 0, duration: 0.6, ease: "cine" }));
    bk.addEventListener("focus", () => gsap.to(inner, { rotateY: tilt / 3, z: 46, y: -14, duration: 0.4, ease: "cine" }));
    bk.addEventListener("blur", () => gsap.to(inner, { rotateY: tilt, z: 0, y: 0, duration: 0.5, ease: "cine" }));
  });
  caseEl.addEventListener("click", (e) => { const bk = e.target.closest(".bk"); if (bk) open(bk.dataset.id, true); });
  // the bookcase leans towards the pointer (lerped)
  if (!reduce()) {
    const rx = gsap.quickTo(caseEl, "rotationX", { duration: 1.2, ease: "power3" }), ry = gsap.quickTo(caseEl, "rotationY", { duration: 1.2, ease: "power3" });
    caseEl.addEventListener("pointermove", (e) => { const r = caseEl.getBoundingClientRect(); ry(((e.clientX - r.left) / r.width - 0.5) * 7); rx(-((e.clientY - r.top) / r.height - 0.5) * 5); });
    caseEl.addEventListener("pointerleave", () => { rx(0); ry(0); });
    $$(".lb-shelf", caseEl).forEach((sh) => {
      gsap.fromTo(sh.querySelectorAll(".bk"), { y: -60, rotateX: -30, autoAlpha: 0 }, { y: 0, rotateX: 0, autoAlpha: 1, stagger: 0.06, ease: "cineBack", scrollTrigger: { trigger: sh, start: "top 92%", end: "top 55%", scrub: 0.7 } });
      gsap.fromTo(sh.querySelector(".lb-plank"), { scaleX: 0.4, autoAlpha: 0 }, { scaleX: 1, autoAlpha: 1, ease: "none", scrollTrigger: { trigger: sh, start: "top 95%", end: "top 70%", scrub: 0.5 } });
    });
    ScrollTrigger.refresh();
  }
  // filters + search
  let cat = "";
  const apply = () => {
    const q = A.norm($("#lbq").value);
    let shown = 0;
    $$(".bk", caseEl).forEach((bk) => { const b = byId[bk.dataset.id]; const hay = A.norm([L(b.title), b.code, b.sub, b.issuer, L(b.desc), L(CAT[b.cat])].join(" ")); const ok = (!cat || b.cat === cat) && (!q || hay.includes(q)); bk.hidden = !ok; if (ok) shown++; });
    $$(".lb-shelf", caseEl).forEach((sh) => (sh.hidden = !sh.querySelector(".bk:not([hidden])")));
    $("#lbEmpty").hidden = shown > 0;
    const first = $(".bk:not([hidden])", caseEl); if (first && (!current || byId[current] && $(`.bk[data-id="${current}"]`).hidden)) open(first.dataset.id);
    ScrollTrigger.refresh();
  };
  $("#lbq").addEventListener("input", apply);
  $$("[data-lc]").forEach((b) => b.addEventListener("click", () => { cat = b.dataset.lc; $$("[data-lc]").forEach((x) => x.setAttribute("aria-pressed", x === b)); apply(); }));
  open("mine-stolen-gold");
}

// global search entries
(A.searchExtra = A.searchExtra || []).push((add) => {
  add("page", W("المكتبة العلمية", "Digital Library"), W("مراجع الجودة وسلامة الغذاء", "Quality & food safety references"), "#/library");
  all().forEach((b) => add("book", L(b.title), b.issuer, "#/library", [b.code, b.sub, L(b.desc)].join(" ")));
});
