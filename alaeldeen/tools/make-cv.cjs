// Builds the updated bilingual CV (EN + AR) as A4 PDFs from one data source, via Chromium.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const OUT = process.argv[2] || __dirname; // e.g. node tools/make-cv.cjs public/cv
const logo = 'data:image/png;base64,' + fs.readFileSync(path.join(__dirname, '../public/assets/logo-mark.png')).toString('base64');

const D = {
  name: { en: 'ALAELDEEN ALBUSHRA MOHAMED ELHASSAN OMER', ar: 'علاء الدين البشري محمد الحسن عمر' },
  title: { en: 'Quality Control & Food Safety Officer | Food Microbiology Specialist', ar: 'أخصائي مراقبة جودة وسلامة غذاء | ميكروبيولوجيا الأغذية' },
  contact: [
    ['pin', { en: 'Riyadh, Saudi Arabia', ar: 'الرياض، المملكة العربية السعودية' }],
    ['phone', '+966 59 172 3483'], ['mail', 'aladeen35@gmail.com'],
    ['in', 'linkedin.com/in/aladeen35'], ['web', 'aladeen35.github.io/test/alaeldeen'],
  ],
  meta: { en: 'Nationality: Sudanese · Languages: Arabic (native), English (intermediate)', ar: 'الجنسية: سوداني · اللغات: العربية (لغة أم)، الإنجليزية (متوسط)' },
  h: {
    summary: { en: 'Professional summary', ar: 'الملخص المهني' }, comp: { en: 'Core competencies', ar: 'الكفاءات الأساسية' },
    exp: { en: 'Professional experience', ar: 'الخبرات العملية' }, edu: { en: 'Education', ar: 'المؤهل العلمي' },
    pub: { en: 'Publications', ar: 'المؤلفات' }, digital: { en: 'Digital projects', ar: 'مشاريع رقمية' },
    skills: { en: 'Technical and digital skills', ar: 'المهارات التقنية والرقمية' }, certs: { en: 'Certifications and training', ar: 'الشهادات والدورات التدريبية' },
    fs: { en: 'Food safety and quality', ar: 'سلامة الغذاء والجودة' }, pd: { en: 'Professional development', ar: 'التطوير المهني' },
    ach: { en: 'Achievements', ar: 'الإنجازات' }, ref: { en: 'References', ar: 'المعرِّفون' }, present: { en: 'Present', ar: 'حتى الآن' },
  },
  summary: {
    en: 'Food Science and Technology graduate with hands-on experience since 2020 in quality control, food safety and food microbiology across catering, healthy and medical meal production (including hospital kitchens), and multi-branch beverage service operations in Saudi Arabia. Experienced in applying HACCP principles, ISO 22000:2018 and ISO 9001 requirements, microbiological testing, hygiene inspections and supplier control. Strong record of standardizing processes, reducing waste and keeping documentation audit-ready. Author of "Stolen Gold", a book on turning Sudan\'s raw materials into safe, competitive food products. Practical user of AI tools and prompt writing to speed up reporting, training material and digital quality tools.',
    ar: 'خريج علوم وتقنية الأغذية، ولدي خبرة عملية منذ عام 2020 في مراقبة الجودة وسلامة الغذاء وميكروبيولوجيا الأغذية، في مجالات التموين وإنتاج الوجبات الصحية والعلاجية (ومنها مطابخ المستشفيات) وخدمات المشروبات متعددة الفروع في المملكة العربية السعودية. أمتلك خبرة في تطبيق مبادئ الهاسب (HACCP) ومتطلبات المواصفتين ISO 22000:2018 وISO 9001، وفي الفحص الميكروبيولوجي وجولات تفتيش النظافة وضبط الموردين. لدي سجل واضح في توحيد إجراءات العمل وتقليل الفاقد والحفاظ على توثيق جاهز للتدقيق. مؤلف كتاب «الذهب المسلوب» عن تحويل خامات السودان إلى منتجات غذائية آمنة ومنافسة، وأستخدم أدوات الذكاء الاصطناعي وصياغة الأوامر لتسريع التقارير والمواد التدريبية وبناء أدوات جودة رقمية.',
  },
  comp: [
    ['Food safety management systems: HACCP, ISO 22000:2018, ISO 9001', 'أنظمة إدارة سلامة الغذاء: HACCP وISO 22000:2018 وISO 9001'],
    ['QC/QA of raw materials, in-process and finished products', 'مراقبة وضبط جودة المواد الخام والمنتجات تحت التشغيل والمنتج النهائي'],
    ['Food microbiology: sampling, microbial culture, chromogenic media (CHROMagar), swabs, shelf-life checks', 'ميكروبيولوجيا الأغذية: سحب العينات، الزراعة الميكروبية، الأوساط اللونية (CHROMagar)، مسحات الأسطح، اختبارات الصلاحية'],
    ['Hygiene and sanitation, pest-control awareness, correct use of cleaning chemicals', 'النظافة العامة والتعقيم، الوعي بمكافحة الآفات، الاستخدام الصحيح لمواد التنظيف'],
    ['Temperature control, cold-chain monitoring and CCP verification', 'ضبط درجات الحرارة ومتابعة سلسلة التبريد والتحقق من نقاط التحكم الحرجة'],
    ['Supplier and incoming-goods inspection; storage and handling standards', 'تقييم الموردين وفحص المواد الواردة ومعايير التخزين والمناولة'],
    ['Recipe development, menu standardization and portion control for dietary and medical meals', 'تطوير الوصفات وتوحيد القوائم وضبط الحصص للوجبات الصحية والعلاجية'],
    ['Internal auditing, nonconformity reporting and CAPA', 'التدقيق الداخلي وتقارير عدم المطابقة والإجراءات التصحيحية والوقائية (CAPA)'],
    ['Staff training on food safety and personal hygiene (certified Train the Trainer)', 'تدريب العاملين على سلامة الغذاء والنظافة الشخصية (مدرب معتمد TOT)'],
    ['Customer complaint investigation and recurrence prevention', 'التحقيق في شكاوى العملاء ومنع تكرارها'],
  ],
  exp: [
    { role: ['Quality Officer', 'مسؤول جودة'], org: ['Half Million (Beverage Services)', 'هاف مليون (خدمات المشروبات)'], from: ['May 2025', 'مايو 2025'], to: null, pts: [
      ['Manage day-to-day quality control for beverage preparation, packaging and delivery across branches, so products reach customers within the required quality and temperature standards.', 'إدارة مراقبة الجودة اليومية لتحضير المشروبات وتعبئتها وتوصيلها في الفروع، بما يضمن وصول المنتج للعميل بالمواصفات ودرجة الحرارة المطلوبة.'],
      ['Monitor compliance with SFDA food safety regulations and internal HACCP-based procedures.', 'متابعة الالتزام باشتراطات الهيئة العامة للغذاء والدواء والإجراءات الداخلية المبنية على نظام الهاسب.'],
      ['Conduct hygiene inspections, verify cleaning schedules and follow up corrective actions with branch teams.', 'تنفيذ جولات تفتيش النظافة والتحقق من جداول التنظيف ومتابعة الإجراءات التصحيحية مع فرق الفروع.'],
      ['Coordinate with operations, supply chain and customer service to resolve quality complaints and prevent recurrence.', 'التنسيق مع التشغيل وسلسلة الإمداد وخدمة العملاء لمعالجة شكاوى الجودة ومنع تكرارها.'],
      ['Maintain quality records, inspection reports and training documentation ready for internal and external audits.', 'حفظ سجلات الجودة وتقارير التفتيش ووثائق التدريب وتجهيزها للتدقيق الداخلي والخارجي.'],
    ] },
    { role: ['Quality Officer', 'مسؤول جودة'], org: ['Diet Center Company, Saudi Arabia', 'شركة دايت سنتر، السعودية'], from: ['October 2021', 'أكتوبر 2021'], to: ['May 2025', 'مايو 2025'], pts: [
      ['Developed and implemented recipes for daily healthy meals, dietary programs and specialized menus for sports clubs, hospitals and clients with special nutritional needs.', 'تطوير وتنفيذ وصفات للوجبات الصحية اليومية والبرامج الغذائية والقوائم المتخصصة للأندية الرياضية والمستشفيات وأصحاب الاحتياجات الغذائية الخاصة.'],
      ['Enforced quality standards across production, handling, storage and distribution.', 'ضمان الالتزام بمعايير الجودة في مراحل الإنتاج والمناولة والتخزين والتوزيع.'],
      ['Carried out routine inspections, temperature checks and microbiological sampling.', 'تنفيذ التفتيش الدوري وقياس درجات الحرارة وسحب العينات الميكروبيولوجية.'],
      ['Worked with cross-functional teams to optimize production flow, streamline inventory and reduce food waste.', 'التعاون مع الفرق المختلفة لتحسين انسيابية الإنتاج وتنظيم المخزون وتقليل الفاقد.'],
      ['Trained kitchen and packing staff on hygiene, allergen control and correct documentation.', 'تدريب العاملين في المطبخ والتعبئة على النظافة وضبط مسببات الحساسية والتوثيق الصحيح.'],
      ['Contracted by Diet Center to manage the quality of the kitchens inside Dr. Sulaiman Al Habib Medical Group hospitals: food safety, clinical nutrition and patient food services.', 'العمل متعاقدًا من دايت سنتر لإدارة جودة المطابخ داخل مستشفيات مجموعة د. سليمان الحبيب الطبية: سلامة الغذاء والتغذية العلاجية وخدمات الطعام للمرضى.'],
    ] },
    { role: ['Quality Officer', 'مسؤول جودة'], org: ['SHATIC Hotel and Tourism Services', 'شاتيك للخدمات الفندقية والسياحية'], from: ['March 2021', 'مارس 2021'], to: ['September 2021', 'سبتمبر 2021'], pts: [
      ['Managed production of meals and daily rations for remote work sites with timely delivery and consistent quality.', 'إدارة إنتاج الوجبات والإعاشة اليومية لمواقع العمل النائية مع التسليم في الوقت المحدد وبجودة ثابتة.'],
      ['Coordinated catering for weddings and large events while maintaining food quality and presentation.', 'تنسيق التموين لحفلات الزفاف والمناسبات الكبيرة مع الحفاظ على الجودة ومستوى التقديم.'],
      ['Implemented quality control for food safety and hygiene through production and service.', 'تطبيق مراقبة الجودة لسلامة الغذاء والنظافة خلال الإنتاج والتقديم.'],
      ['Supervised storage conditions, stock rotation (FIFO) and supplier deliveries.', 'الإشراف على ظروف التخزين ودوران المخزون (FIFO) وتوريدات الموردين.'],
    ] },
    { role: ['Quality Management Trainee', 'متدرب في إدارة الجودة'], org: ['Coca-Cola Sudan — Dal Group', 'كوكاكولا السودان — مجموعة دال'], year: '2020', pts: [
      ['Hands-on quality management training in a beverage manufacturing environment (training certificate).', 'تدريب عملي على إدارة الجودة في بيئة تصنيع مشروبات (شهادة تدريب).'],
    ] },
  ],
  edu: { deg: ['Bachelor of Agriculture — Food Science and Technology', 'بكالوريوس الزراعة — علوم وتقنية الأغذية'], sch: ['Al-Zaim Al-Azhari University, Khartoum Bahri, Sudan | 2014 – 2021', 'جامعة الزعيم الأزهري، الخرطوم بحري — السودان | 2014 – 2021'], gpa: ['GPA 3.0 / 4.0 — Second Class, Division One (Very Good)', 'المعدل التراكمي 3.0 من 4.0 — الدرجة الثانية، القسم الأول (جيد جدًا)'] },
  pub: [
    ['"Stolen Gold: Towards an Industrial Renaissance of Sudan\'s Resources" — a roadmap for quality systems and modern processing of crops and livestock. First edition, 2026, 62 pages, Dar Al-Namaa for Knowledge & Development, Khartoum.', '«الذهب المسلوب: نحو نهضة صناعية للموارد السودانية» — خارطة طريق لتطبيق نظم الجودة والتصنيع الحديث للمحاصيل والثروات الحيوانية. الطبعة الأولى 2026م، 62 صفحة، دار النماء للمعرفة والتنمية للنشر والتوزيع، الخرطوم.'],
    ['"The Return of the Kingdoms" (Part One) — published online as a flipbook.', '«عودة عهد الممالك» (الجزء الأول) — منشور أونلاين بصيغة كتاب تفاعلي.'],
  ],
  digital: [
    ['Bilingual professional website and "Quality Lamp" learning platform: food safety lessons with quizzes, 27 interactive quality tools (HACCP plan builder, NCR, RCA/CAPA, risk matrix, CFU calculator, KPI dashboard and more), a quality dictionary, a reference library and an AI assistant — built with AI assistance: aladeen35.github.io/test/alaeldeen', 'موقع مهني ثنائي اللغة ومنصة «مصباح الجودة» التعليمية: دروس في سلامة الغذاء مع اختبارات، و27 أداة جودة تفاعلية (مولّد خطة HACCP، تقارير عدم المطابقة، تحليل السبب الجذري، مصفوفة المخاطر، حاسبة CFU، لوحة مؤشرات وغيرها)، وقاموس جودة، ومكتبة مراجع، ومساعد ذكي — بُني بمساعدة الذكاء الاصطناعي: aladeen35.github.io/test/alaeldeen'],
  ],
  skills: [
    ['Microsoft Office: Word, Excel, PowerPoint, Outlook — proficient (ICDL certified); data entry, charts and digital reports', 'برامج مايكروسوفت أوفيس: وورد، إكسل، باوربوينت، أوتلوك — مستوى متقدم (ICDL)؛ إدخال البيانات والرسوم البيانية والتقارير الرقمية'],
    ['Food safety applications and digital checklists: HACCP logs, temperature and cleaning records', 'تطبيقات سلامة الغذاء وقوائم الفحص الرقمية: سجلات الهاسب ودرجات الحرارة والتنظيف'],
    ['AI in the workplace: ChatGPT, Claude, Gemini, Copilot for reports, SOPs, checklists, training material and Arabic–English translation; prompt engineering; reviewing AI output with attention to data confidentiality', 'الذكاء الاصطناعي في العمل: ChatGPT وClaude وGemini وCopilot للتقارير والإجراءات وقوائم الفحص والمواد التدريبية والترجمة؛ هندسة الأوامر؛ مراجعة المخرجات مع مراعاة سرية البيانات'],
    ['Laboratory techniques: media preparation, plating, incubation and result interpretation', 'المهارات المعملية: تحضير الأوساط الزرعية والتلقيح والتحضين وتفسير النتائج'],
    ['Graphic design, photography, content creation; certified drone operation', 'أساسيات التصميم الجرافيكي والتصوير وصناعة المحتوى؛ تشغيل الطائرات بدون طيار (دورة معتمدة)'],
  ],
  certFS: [
    ['Level 3 Food Safety — Highfield (NDC internal)', 'المستوى الثالث في سلامة الغذاء — Highfield (داخلي NDC)'], ['Level 2 Food Safety — NDC internal', 'المستوى الثاني في سلامة الغذاء — داخلي NDC'],
    ['ISO 22000:2018 Food Safety Management System — NDC internal', 'نظام إدارة سلامة الغذاء ISO 22000:2018 — داخلي NDC'], ['Food Safety Management System (ISO 9001)', 'نظام إدارة الجودة ISO 9001'],
    ['Total Quality Management in Food Fields', 'إدارة الجودة الشاملة في المجالات الغذائية'], ['Management of Food Contamination and Hygiene', 'إدارة تلوث الأغذية والنظافة العامة'],
    ['Risk Management in Industry Fields', 'إدارة المخاطر في المجالات الصناعية'], ['Quality Management Training — Dal Company / Coca-Cola', 'تدريب على إدارة الجودة — شركة دال / كوكاكولا'],
    ['Microbiology Media — CHROMagar; advanced microbial culture and analysis', 'الأوساط الميكروبيولوجية — CHROMagar؛ تقنيات متقدمة في الزراعة والتحليل الميكروبي'], ['Cleaning Products Orientation and Applications', 'التعريف بمواد التنظيف وتطبيقاتها'],
    ['Health and Nutrition Education; Health and Nutrition Management', 'التثقيف الصحي والتغذوي؛ إدارة الصحة والتغذية'], ['Food Bank Organization — food security and distribution practices', 'منظمة بنك الطعام — الأمن الغذائي وممارسات التوزيع'],
  ],
  certPD: [
    ['Train the Trainer (TOT) — Winy Center', 'تدريب المدربين (TOT) — مركز وايني'], ['ICDL — Alafra Center', 'الرخصة الدولية لقيادة الحاسب الآلي (ICDL) — مركز الأفراح'],
    ['YouTube Creator Academy — filming, content creation, live broadcasting', 'أكاديمية صناع يوتيوب — التصوير وصناعة المحتوى والبث المباشر'], ['Drone Course — King Khalid University', 'دورة الطائرات بدون طيار — جامعة الملك خالد'],
  ],
  ach: [
    ['Author of the book "Stolen Gold" (2026).', 'مؤلف كتاب «الذهب المسلوب» (2026).'],
    ['Patent Certificate — Sudanese Ministry of Intellectual Property: production of lentil-based biscuits ("Hemo").', 'شهادة براءة اختراع — وزارة الملكية الفكرية السودانية: إنتاج بسكويت العدس «هيمو».'],
    ['Hult Prize Regional, Al-Zaim Al-Azhari University — Social Entrepreneurship Challenge participant.', 'المشاركة في جائزة هالت برايز الإقليمية — جامعة الزعيم الأزهري (تحدي ريادة الأعمال الاجتماعية).'],
  ],
  ref: { en: 'Available upon request.', ar: 'تتوفر خطابات التزكية والمعرِّفون عند الطلب.' },
};

const ICON = {
  pin: '<path d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12Z"/><circle cx="12" cy="9" r="2.5"/>',
  phone: '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>',
  in: '<rect x="3" y="3" width="18" height="18" rx="3"/><path d="M8 10v7M8 7v.01M12 17v-4a2 2 0 0 1 4 0v4M12 10v7"/>',
  web: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
};
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function html(l) {
  const ar = l === 'ar', T = (x) => (typeof x === 'string' ? x : Array.isArray(x) ? x[ar ? 1 : 0] : x[l]);
  const sec = (k, body) => `<section><h2>${esc(T(D.h[k]))}</h2>${body}</section>`;
  const ul = (arr, cls) => `<ul class="${cls || ''}">${arr.map((x) => `<li>${esc(T(x))}</li>`).join('')}</ul>`;
  return `<!doctype html><html lang="${l}" dir="${ar ? 'rtl' : 'ltr'}"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  @page { size: A4; margin: 13mm 0 15mm; }
  @page :first { margin-top: 0; }
  :root { --ink: #1b1b1b; --soft: #4a4a4a; --mute: #6f6f6f; --gold: #b98b1d; --gold2: #ddb03f; --line: #e6dcc4; --band: #171717; }
  * { box-sizing: border-box; margin: 0; }
  body { font-family: ${ar ? '"IBM Plex Sans Arabic"' : '"Inter"'}, "IBM Plex Sans Arabic", sans-serif; color: var(--ink); font-size: ${ar ? '9.6pt' : '9.2pt'}; line-height: ${ar ? 1.56 : 1.46}; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  header { background: var(--band); color: #fff; padding: 22px 34px 18px; display: flex; gap: 20px; align-items: center; border-bottom: 4px solid var(--gold2); }
  header img { width: 64px; height: auto; flex-shrink: 0; }
  header .who { flex: 1; min-width: 0; }
  header h1 { font-size: ${ar ? '21pt' : '16.5pt'}; font-weight: 800; letter-spacing: ${ar ? '0' : '.02em'}; line-height: 1.15; }
  header .t { color: var(--gold2); font-weight: 600; font-size: 10.5pt; margin-top: 3px; }
  .contact { display: flex; flex-wrap: wrap; gap: 4px 16px; margin-top: 9px; font-size: 8.6pt; color: #e8e8e8; }
  .contact span { display: inline-flex; align-items: center; gap: 5px; }
  .contact svg { width: 12px; height: 12px; stroke: var(--gold2); fill: none; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; flex-shrink: 0; }
  .contact .ltr { direction: ltr; unicode-bidi: isolate; }
  .meta { font-size: 8.4pt; color: #bdbdbd; margin-top: 4px; }
  main { padding: 14px 34px 20px; }
  section { margin-top: 8px; break-inside: auto; }
  h2 { font-size: 10.6pt; font-weight: 700; color: var(--gold); text-transform: ${ar ? 'none' : 'uppercase'}; letter-spacing: ${ar ? '0' : '.08em'}; padding-bottom: 3px; border-bottom: 1.2px solid var(--line); margin-bottom: 6px; break-after: avoid; }
  p { color: var(--soft); text-align: justify; }
  ul { padding-inline-start: 15px; }
  li { margin-bottom: 1px; color: var(--soft); }
  li::marker { color: var(--gold2); }
  .two { columns: 2; column-gap: 22px; }
  .two li { break-inside: avoid; }
  .job { margin-bottom: 8px; break-inside: avoid; }
  .job .top { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; }
  .job b { font-size: 10pt; color: var(--ink); }
  .job .org { color: var(--gold); font-weight: 600; }
  .job .when { font-size: 8.6pt; color: var(--mute); white-space: nowrap; font-weight: 600; }
  section:has(.edu) { break-inside: avoid; }
  .edu b { display: block; font-size: 10pt; }
  .edu span { display: block; color: var(--soft); }
  .sub { font-weight: 700; color: var(--ink); font-size: 9.4pt; margin: 4px 0 2px; }
  footer { position: fixed; bottom: 10px; inset-inline: 34px; font-size: 7.6pt; color: #9a9a9a; display: flex; justify-content: space-between; }
</style></head><body>
<header><img src="${logo}" alt=""><div class="who"><h1>${esc(T(D.name))}</h1><div class="t">${esc(T(D.title))}</div>
  <div class="contact">${D.contact.map(([ic, v]) => `<span><svg viewBox="0 0 24 24">${ICON[ic]}</svg><span class="${typeof v === 'string' ? 'ltr' : ''}">${esc(T(v))}</span></span>`).join('')}</div>
  <div class="meta">${esc(T(D.meta))}</div></div></header>
<main>
  ${sec('summary', `<p>${esc(T(D.summary))}</p>`)}
  ${sec('comp', ul(D.comp, 'two'))}
  ${sec('exp', D.exp.map((j) => `<div class="job"><div class="top"><div><b>${esc(T(j.role))}</b> — <span class="org">${esc(T(j.org))}</span></div><span class="when">${j.year ? esc(j.year) : `${esc(T(j.from))} – ${esc(j.to ? T(j.to) : T(D.h.present))}`}</span></div>${ul(j.pts)}</div>`).join(''))}
  ${sec('edu', `<div class="edu"><b>${esc(T(D.edu.deg))}</b><span>${esc(T(D.edu.sch))}</span><span>${esc(T(D.edu.gpa))}</span></div>`)}
  ${sec('pub', ul(D.pub))}
  ${sec('digital', ul(D.digital))}
  ${sec('skills', ul(D.skills))}
  ${sec('certs', `<div class="sub">${esc(T(D.h.fs))}</div>${ul(D.certFS, 'two')}<div class="sub">${esc(T(D.h.pd))}</div>${ul(D.certPD, 'two')}`)}
  ${sec('ach', ul(D.ach))}
  ${sec('ref', `<p>${esc(T(D.ref))}</p>`)}
</main></body></html>`;
}

(async () => {
  const b = await chromium.launch();
  for (const l of ['en', 'ar']) {
    const p = await b.newPage();
    fs.writeFileSync(path.join(OUT, `cv-${l}.html`), html(l));
    await p.goto('file://' + path.join(OUT, `cv-${l}.html`), { waitUntil: 'networkidle' });
    await p.evaluate(() => document.fonts.ready);
    const file = path.join(OUT, l === 'en' ? 'Alaeldeen_Omer_CV_EN.pdf' : 'Alaeldeen_Omer_CV_AR.pdf');
    await p.pdf({ path: file, format: 'A4', printBackground: true, displayHeaderFooter: true, headerTemplate: '<span></span>',
      footerTemplate: `<div style="width:100%;font-size:7px;color:#999;padding:0 34px;display:flex;justify-content:space-between;font-family:sans-serif"><span>Alaeldeen Albushra Mohamed Elhassan Omer — CV</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>`,
      preferCSSPageSize: true });
    console.log('wrote', file);
  }
  await b.close();
})();
