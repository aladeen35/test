/* All site content, bilingual. Each text is either a plain string (same in both
   languages) or { ar, en }. Professional data below is taken from the current
   bilingual CV only — nothing is added that the CV does not state. */
window.SITE = (function () {
  const REVIEWED = "2026-11-04";

  const profile = {
    name: { ar: "علاء الدين البشرى عمر", en: "Alaeldeen Albushra Omer" },
    display: "Eng. Alaeldeen",
    title: {
      ar: "أخصائي مراقبة جودة وسلامة غذاء | ميكروبيولوجيا الأغذية",
      en: "Quality Control & Food Safety Officer | Food Microbiology Specialist",
    },
    location: { ar: "مكة المكرمة، المملكة العربية السعودية", en: "Makkah, Saudi Arabia" },
    email: "aladeen35@gmail.com",
    phone: "+966 59 172 3483",
    whatsapp: "966591723483",
    languages: {
      ar: "العربية (لغة أم)، الإنجليزية (متوسط)",
      en: "Arabic (native), English (intermediate)",
    },
    summary: {
      ar: "خريج علوم وتقنية الأغذية، ولدي أكثر من ثلاث سنوات من الخبرة العملية في مراقبة الجودة وسلامة الغذاء وميكروبيولوجيا الأغذية، في مجالات التموين وإنتاج الوجبات الصحية وخدمات المشروبات. أمتلك خبرة في تطبيق مبادئ الهاسب (HACCP) ومتطلبات المواصفتين ISO 22000:2018 وISO 9001، وفي الفحص الميكروبيولوجي ومتابعة النظافة العامة وتقييم الموردين. لدي سجل واضح في توحيد إجراءات العمل وتقليل الفاقد والحفاظ على توثيق جاهز للتدقيق في أي وقت، وأستخدم أدوات الذكاء الاصطناعي وصياغة الأوامر لتسريع إعداد التقارير والمواد التدريبية.",
      en: "Food Science and Technology graduate with over three years of hands-on experience in quality control, food safety and food microbiology across catering, healthy-meal production and beverage service operations. Experienced in applying HACCP principles, ISO 22000:2018 and ISO 9001 requirements, microbiological testing, hygiene monitoring and supplier inspection. Strong record of standardizing processes, reducing waste and maintaining audit-ready documentation, and a practical user of AI tools and prompt writing to speed up reporting and training work.",
    },
    competencies: [
      { ar: "أنظمة إدارة سلامة الغذاء: HACCP وISO 22000:2018 وISO 9001", en: "Food safety management systems: HACCP, ISO 22000:2018, ISO 9001" },
      { ar: "مراقبة وضبط جودة المواد الخام والمنتجات تحت التشغيل والمنتج النهائي", en: "QC/QA of raw materials, in-process and finished products" },
      { ar: "ميكروبيولوجيا الأغذية: سحب العينات، الزراعة الميكروبية، الأوساط اللونية (CHROMagar)، مسحات الأسطح، اختبارات مدة الصلاحية", en: "Food microbiology: sampling, culture, chromogenic media (CHROMagar), swabs and shelf-life checks" },
      { ar: "النظافة العامة والتعقيم والوعي بمكافحة الآفات والاستخدام الصحيح لمواد التنظيف", en: "Hygiene, sanitation, pest-control awareness and correct use of cleaning chemicals" },
      { ar: "ضبط درجات الحرارة ومتابعة سلسلة التبريد والتحقق من نقاط التحكم الحرجة", en: "Temperature control, cold-chain monitoring and CCP verification" },
      { ar: "تقييم الموردين وفحص المواد الواردة ومعايير التخزين والمناولة", en: "Supplier and incoming-goods inspection; storage and handling standards" },
      { ar: "تطوير الوصفات وتوحيد قوائم الطعام وضبط الحصص للوجبات الصحية والعلاجية", en: "Recipe development, menu standardization and portion control for dietary and medical meals" },
      { ar: "التدقيق الداخلي وتقارير عدم المطابقة والإجراءات التصحيحية والوقائية (CAPA)", en: "Internal auditing, non-conformity reporting and CAPA" },
      { ar: "تدريب وتوجيه العاملين على سلامة الغذاء والنظافة الشخصية (مدرب معتمد TOT)", en: "Staff training on food safety and personal hygiene (certified Train the Trainer)" },
      { ar: "التوثيق وحفظ السجلات وإعداد التقارير الرقمية", en: "Documentation, record keeping and digital reporting" },
    ],
    skills: ["HACCP", "ISO 22000:2018", "ISO 9001", "GMP / GHP", "SFDA", "CAPA", "Internal audit", "CHROMagar", "Swab testing", "Shelf-life checks", "Cold chain", "FIFO / FEFO", "Allergen control", "Supplier inspection", "MS Office (ICDL)", "Prompt engineering"],
    experience: [
      {
        role: { ar: "مسؤول جودة", en: "Quality Officer" },
        org: { ar: "هاف مليون (خدمات المشروبات) — مكة المكرمة", en: "Half Million (Beverage Services) — Makkah" },
        from: "2025-05", to: null,
        points: [
          { ar: "إدارة عمليات مراقبة الجودة اليومية لتحضير المشروبات وتعبئتها وتوصيلها، بما يضمن وصول المنتج للعميل بالمواصفات ودرجة الحرارة المطلوبة.", en: "Manage day-to-day quality control for beverage preparation, packaging and delivery, so products reach the customer within the required quality and temperature standards." },
          { ar: "متابعة الالتزام باشتراطات الهيئة العامة للغذاء والدواء وبالإجراءات الداخلية المبنية على نظام الهاسب في الفروع.", en: "Monitor compliance with SFDA food safety regulations and internal HACCP-based procedures across branches." },
          { ar: "تنفيذ جولات تفتيش على النظافة والتحقق من جداول التنظيف ومتابعة الإجراءات التصحيحية مع فرق الفروع.", en: "Conduct hygiene inspections, verify cleaning schedules and follow up corrective actions with branch teams." },
          { ar: "التنسيق مع التشغيل وسلسلة الإمداد وخدمة العملاء لمعالجة شكاوى الجودة ومنع تكرارها.", en: "Coordinate with operations, supply chain and customer service to resolve quality complaints and prevent recurrence." },
          { ar: "حفظ سجلات الجودة وتقارير التفتيش ووثائق التدريب وتجهيزها للتدقيق الداخلي والخارجي.", en: "Maintain quality records, inspection reports and training documentation ready for internal and external audits." },
        ],
      },
      {
        role: { ar: "مسؤول جودة", en: "Quality Officer" },
        org: { ar: "شركة دايت سنتر — السعودية", en: "Diet Center Company — Saudi Arabia" },
        from: "2024-10", to: "2025-05",
        points: [
          { ar: "تطوير وتنفيذ وصفات للوجبات الصحية اليومية والبرامج الغذائية والقوائم المتخصصة للأندية الرياضية والمستشفيات وأصحاب الاحتياجات الغذائية الخاصة.", en: "Developed and implemented recipes for daily healthy meals, dietary programs and specialized menus for sports clubs, hospitals and clients with special nutritional needs." },
          { ar: "ضمان الالتزام الصارم بمعايير الجودة في مراحل الإنتاج والمناولة والتخزين والتوزيع.", en: "Enforced strict quality standards across production, handling, storage and distribution." },
          { ar: "تنفيذ عمليات التفتيش الدورية وقياس درجات الحرارة وسحب العينات الميكروبيولوجية.", en: "Carried out routine inspections, temperature checks and microbiological sampling." },
          { ar: "التعاون مع الفرق المختلفة لتحسين انسيابية الإنتاج وتنظيم المخزون وتقليل الفاقد.", en: "Worked with cross-functional teams to optimize production flow, streamline inventory and reduce food waste." },
          { ar: "تدريب العاملين في المطبخ والتعبئة على النظافة وضبط مسببات الحساسية والتوثيق الصحيح.", en: "Trained kitchen and packing staff on hygiene, allergen control and correct documentation." },
        ],
      },
      {
        role: { ar: "مسؤول جودة", en: "Quality Officer" },
        org: { ar: "شاتيك للخدمات الفندقية والسياحية", en: "SHATIC Hotel and Tourism Services" },
        from: "2021-03", to: "2021-09",
        points: [
          { ar: "إدارة إنتاج الوجبات والإعاشة اليومية في مواقع العمل النائية مع ضمان التسليم في الوقت المحدد وبالجودة المطلوبة.", en: "Managed production of meals and daily rations for remote work sites, ensuring timely delivery and consistent quality." },
          { ar: "تنسيق خدمات التموين لحفلات الزفاف والمناسبات الكبيرة مع الحفاظ على الجودة ومستوى التقديم.", en: "Coordinated catering for weddings and large events while maintaining food quality and presentation." },
          { ar: "تطبيق إجراءات مراقبة الجودة لمتابعة سلامة الغذاء والنظافة خلال الإنتاج والتقديم.", en: "Implemented quality control measures for food safety and hygiene through production and service." },
          { ar: "الإشراف على ظروف التخزين ودوران المخزون (FIFO) ومتابعة توريدات الموردين.", en: "Supervised storage conditions, stock rotation (FIFO) and supplier deliveries." },
        ],
      },
    ],
    education: {
      degree: { ar: "بكالوريوس الزراعة — علوم وتقنية الأغذية", en: "Bachelor of Agriculture — Food Science and Technology" },
      school: { ar: "جامعة الزعيم الأزهري، الخرطوم بحري — السودان", en: "Al-Zaim Al-Azhari University, Khartoum Bahri, Sudan" },
      years: "2014 – 2021",
      grade: { ar: "المعدل التراكمي 3.0 من 4.0 — الدرجة الثانية، القسم الأول (جيد جدًا)", en: "GPA 3.0 / 4.0 — Second Class, Division One (Very Good)" },
    },
    certs: [
      { n: { ar: "المستوى الثالث في سلامة الغذاء", en: "Level 3 Food Safety" }, by: { ar: "Highfield (داخلي NDC)", en: "Highfield (NDC internal)" }, g: "fs" },
      { n: { ar: "المستوى الثاني في سلامة الغذاء", en: "Level 2 Food Safety" }, by: { ar: "داخلي NDC", en: "NDC internal" }, g: "fs" },
      { n: { ar: "نظام إدارة سلامة الغذاء ISO 22000:2018", en: "ISO 22000:2018 Food Safety Management System" }, by: { ar: "داخلي NDC", en: "NDC internal" }, g: "fs" },
      { n: { ar: "نظام إدارة الجودة ISO 9001", en: "Food Safety Management System (ISO 9001)" }, by: null, g: "fs" },
      { n: { ar: "إدارة الجودة الشاملة في المجالات الغذائية", en: "Total Quality Management in Food Fields" }, by: null, g: "fs" },
      { n: { ar: "إدارة تلوث الأغذية والنظافة العامة", en: "Management of Food Contamination and Hygiene" }, by: null, g: "fs" },
      { n: { ar: "إدارة المخاطر في المجالات الصناعية", en: "Risk Management in Industry Fields" }, by: null, g: "fs" },
      { n: { ar: "تدريب على إدارة الجودة", en: "Quality Management Training" }, by: { ar: "شركة دال / كوكاكولا", en: "Dal Company / Coca-Cola" }, g: "fs" },
      { n: { ar: "الأوساط الميكروبيولوجية وتقنيات الزراعة والتحليل الميكروبي", en: "Microbiology Media — advanced microbial culture and analysis" }, by: "CHROMagar", g: "fs" },
      { n: { ar: "التعريف بمواد التنظيف وتطبيقاتها", en: "Cleaning Products Orientation and Applications" }, by: null, g: "fs" },
      { n: { ar: "التثقيف الصحي والتغذوي وإدارة الصحة والتغذية", en: "Health & Nutrition Education; Health & Nutrition Management" }, by: null, g: "fs" },
      { n: { ar: "منظمة بنك الطعام — الأمن الغذائي وممارسات التوزيع", en: "Food Bank Organization — food security and distribution" }, by: null, g: "fs" },
      { n: { ar: "تدريب المدربين (TOT)", en: "Train the Trainer (TOT)" }, by: { ar: "مركز وايني", en: "Winy Center" }, g: "pd" },
      { n: { ar: "الرخصة الدولية لقيادة الحاسب الآلي (ICDL)", en: "ICDL — International Computer Driving License" }, by: { ar: "مركز الأفراح", en: "Alafra Center" }, g: "pd" },
      { n: { ar: "أكاديمية صناع يوتيوب — التصوير وصناعة المحتوى والبث المباشر", en: "YouTube Creator Academy — filming, content creation, live broadcasting" }, by: null, g: "pd" },
      { n: { ar: "دورة الطائرات بدون طيار", en: "Drone Course" }, by: { ar: "جامعة الملك خالد", en: "King Khalid University" }, g: "pd" },
    ],
    achievements: [
      { ar: "شهادة براءة اختراع — وزارة الملكية الفكرية السودانية: إنتاج بسكويت العدس «هيمو».", en: "Patent Certificate — Sudanese Ministry of Intellectual Property: lentil-based biscuits (\"Hemo\")." },
      { ar: "المشاركة في جائزة هالت برايز الإقليمية — جامعة الزعيم الأزهري (تحدي ريادة الأعمال الاجتماعية).", en: "Hult Prize Regional participant, Al-Zaim Al-Azhari University — Social Entrepreneurship Challenge." },
    ],
  };

  /* ---------------- Quality Lamp modules ---------------- */
  const refs = {
    codexGP: "Codex Alimentarius — General Principles of Food Hygiene, CXC 1-1969 (Rev. 2022)",
    iso22000: "ISO 22000:2018 — Food safety management systems: Requirements for any organization in the food chain",
    iso22002: "ISO/TS 22002-1 — Prerequisite programmes on food safety, Part 1: Food manufacturing",
    who5: "WHO — Five Keys to Safer Food Manual (2006)",
    sfda: { ar: "الهيئة العامة للغذاء والدواء (SFDA) — اللوائح الفنية والاشتراطات الصحية المعمول بها", en: "Saudi Food & Drug Authority (SFDA) — applicable technical regulations and requirements" },
    codexAllergen: "Codex — Code of Practice on Food Allergen Management for Food Business Operators, CXC 80-2020",
    codexLabel: "Codex — General Standard for the Labelling of Prepackaged Foods, CXS 1-1985",
  };

  const modules = [
    {
      id: "gmp", code: "GMP", status: "ready", mins: 15,
      title: { ar: "ممارسات التصنيع الجيد", en: "Good Manufacturing Practices" },
      blurb: { ar: "الأساس الذي يقوم عليه كل نظام سلامة غذاء: المبنى، المعدات، العاملون، والعمليات.", en: "The foundation every food safety system stands on: premises, equipment, people and process." },
      lesson: {
        def: { ar: "ممارسات التصنيع الجيد (GMP) هي مجموعة الشروط والممارسات الأساسية التي تضمن إنتاج الغذاء وتداوله في بيئة مناسبة وبطريقة ثابتة ومضبوطة، بحيث يكون المنتج آمنًا ومطابقًا لمواصفاته في كل مرة.", en: "Good Manufacturing Practices (GMP) are the basic conditions and practices that make sure food is produced and handled in a suitable environment, in a consistent and controlled way, so the product is safe and meets its specification every time." },
        why: { ar: "لأن معظم حالات التلوث لا تأتي من خطوة معقدة، بل من أساسيات مهملة: باب مفتوح، سطح متشقق، عامل لم يغسل يديه، أو مادة خام بلا فحص. GMP تمنع هذه المشكلات قبل أن تحتاج إلى نقاط تحكم حرجة.", en: "Most contamination does not come from a complex step but from neglected basics: an open door, a cracked surface, unwashed hands, or an unchecked raw material. GMP prevents these problems before you ever need a critical control point." },
        reqs: [
          { ar: "تصميم المبنى ومسارات الحركة بحيث تمنع التلوث العرضي (من المنطقة غير النظيفة إلى النظيفة باتجاه واحد).", en: "Premises and flow designed to prevent cross-contamination (one-way flow from dirty to clean areas)." },
          { ar: "معدات وأسطح ملامسة للغذاء سهلة التنظيف، غير ماصة، وبحالة جيدة.", en: "Food-contact equipment and surfaces that are cleanable, non-absorbent and in good repair." },
          { ar: "مياه صالحة للشرب وإمداد كافٍ للتنظيف وغسل الأيدي.", en: "Potable water and adequate supply for cleaning and handwashing." },
          { ar: "استلام وتخزين المواد وفق المواصفات وظروف التخزين المحددة.", en: "Receipt and storage of materials against specifications and defined storage conditions." },
          { ar: "عاملون مدربون يلتزمون بالنظافة الشخصية والسلوك الصحي.", en: "Trained staff who follow personal hygiene and health rules." },
          { ar: "سجلات تثبت أن ما خُطط له نُفِّذ فعلًا.", en: "Records that prove what was planned was actually done." },
        ],
        steps: [
          { ar: "ارسم مخطط المنشأة وحدد المناطق (خام / تحضير / طهي / تعبئة / تخزين) ومسارات العاملين والمواد.", en: "Map the facility and mark the zones (raw / prep / cooking / packing / storage) and the routes of people and materials." },
          { ar: "أعد قائمة متطلبات GMP لكل منطقة بالاستناد إلى المرجع المعتمد لديك.", en: "Build a GMP requirement list per zone from your applicable reference." },
          { ar: "قيّم الوضع الحالي بجولة تفتيش موثقة (استخدم قائمة التفتيش في الأدوات).", en: "Assess the current state with a documented walk-through (use the inspection checklist in the toolkit)." },
          { ar: "سجّل الفجوات كحالات عدم مطابقة مع مسؤول وموعد إغلاق.", en: "Log gaps as nonconformities with an owner and a due date." },
          { ar: "درّب العاملين على الإجراءات المعدّلة وتحقق من الفهم في الموقع.", en: "Train staff on the updated procedures and check understanding on the floor." },
          { ar: "أعد التقييم دوريًا وتابع اتجاه نسبة الامتثال.", en: "Reassess periodically and track the compliance trend." },
        ],
        examples: {
          factory: { ar: "تركيب ستائر هوائية وأبواب ذاتية الإغلاق بين منطقة الاستلام ومنطقة الإنتاج.", en: "Air curtains and self-closing doors between goods-in and production." },
          kitchen: { ar: "فصل ألواح التقطيع بالألوان: أحمر للحوم النيئة، أخضر للخضار، أزرق للأسماك.", en: "Colour-coded chopping boards: red for raw meat, green for vegetables, blue for fish." },
          cafe: { ar: "تخصيص منطقة لاستلام الحليب وتسجيل حرارته قبل إدخاله إلى الثلاجة.", en: "A dedicated spot to receive milk and record its temperature before it goes into the fridge." },
        },
        pitfalls: [
          { ar: "اعتبار GMP «ورقًا» يُجهَّز قبل التدقيق فقط.", en: "Treating GMP as paperwork prepared only before an audit." },
          { ar: "تدريب لمرة واحدة دون متابعة أو تقييم للفهم.", en: "One-off training with no follow-up or check of understanding." },
          { ar: "إصلاحات مؤقتة (شريط لاصق على سطح متشقق) تصبح دائمة.", en: "Temporary fixes (tape on a cracked surface) that become permanent." },
        ],
        checklist: [
          { ar: "الأبواب والنوافذ محكمة أو مزودة بشبك.", en: "Doors and windows close tightly or are screened." },
          { ar: "الأسطح الملامسة للغذاء سليمة ونظيفة.", en: "Food-contact surfaces intact and clean." },
          { ar: "مغاسل الأيدي مزودة بصابون ومناديل ورقية.", en: "Handwash stations stocked with soap and paper towels." },
          { ar: "المواد مخزنة بعيدًا عن الأرض والجدران.", en: "Materials stored off the floor and away from walls." },
          { ar: "المواد الكيميائية في مكان منفصل ومعرّفة.", en: "Chemicals stored separately and labelled." },
          { ar: "السجلات اليومية مكتملة وموقّعة.", en: "Daily records complete and signed." },
        ],
        caseStudy: {
          ar: "مطبخ مركزي تكررت فيه ملاحظة «وجود ذباب في منطقة التحضير» في ثلاث جولات متتالية. التحليل أظهر أن باب التفريغ يُترك مفتوحًا أثناء الاستلام لأن الستارة الهوائية معطلة منذ أسابيع. الإجراء: إصلاح الستارة، إضافة الباب إلى قائمة الفحص اليومي، وتحديد مسؤول الاستلام عن إغلاقه. الدرس: الملاحظة المتكررة تعني أن الإجراء التصحيحي عالج العَرَض لا السبب. (دراسة حالة تعليمية مجهّلة)",
          en: "A central kitchen received the same finding — \"flies in the prep area\" — in three rounds in a row. Analysis showed the delivery door was left open during receiving because the air curtain had been broken for weeks. Action: repair the curtain, add the door to the daily check, and make the receiving lead responsible for closing it. Lesson: a repeating finding means the correction treated the symptom, not the cause. (Anonymised teaching case)",
        },
        refs: [refs.codexGP, refs.iso22002, refs.sfda],
      },
      quiz: [
        { q: { ar: "أي مما يلي يُعد مثالًا على GMP؟", en: "Which of these is an example of GMP?" }, o: [{ ar: "تحديد حد حرج لدرجة حرارة الطهي", en: "Setting a critical limit for cooking temperature" }, { ar: "ألواح تقطيع ملونة حسب نوع الغذاء", en: "Colour-coded chopping boards by food type" }, { ar: "حساب تكلفة الوجبة", en: "Costing a meal" }], a: 1, why: { ar: "الفصل بالألوان ممارسة أساسية تمنع التلوث العرضي، وهي من صميم GMP. الحد الحرج يخص خطة HACCP.", en: "Colour coding is a basic practice that prevents cross-contamination — core GMP. A critical limit belongs to the HACCP plan." } },
        { q: { ar: "ما الاتجاه الصحيح لحركة المواد في المنشأة؟", en: "What is the correct direction of material flow?" }, o: [{ ar: "من النظيف إلى غير النظيف", en: "From clean to dirty" }, { ar: "من غير النظيف إلى النظيف باتجاه واحد", en: "One-way from dirty to clean" }, { ar: "لا يهم الاتجاه إذا نُظّفت الأرضية", en: "Direction doesn't matter if floors are cleaned" }], a: 1, why: { ar: "الحركة باتجاه واحد من الخام إلى المنتج النهائي تقلل فرص عودة التلوث إلى المنتج الجاهز.", en: "One-way flow from raw to finished product reduces the chance of contamination reaching ready food." } },
        { q: { ar: "تكررت الملاحظة نفسها في ثلاث جولات. ماذا يعني ذلك غالبًا؟", en: "The same finding repeated in three rounds. What does that usually mean?" }, o: [{ ar: "أن المفتش متشدد", en: "The inspector is too strict" }, { ar: "أن الإجراء عالج العَرَض لا السبب الجذري", en: "The action treated the symptom, not the root cause" }, { ar: "أن الملاحظة غير مهمة", en: "The finding is unimportant" }], a: 1, why: { ar: "التكرار مؤشر على أن السبب الجذري لم يُعالج؛ هنا يلزم تحليل RCA وإجراء تصحيحي حقيقي.", en: "Recurrence signals the root cause was not addressed; it calls for RCA and a real corrective action." } },
        { q: { ar: "لماذا تُعد السجلات جزءًا من GMP؟", en: "Why are records part of GMP?" }, o: [{ ar: "لأنها تثبت أن ما خُطط له نُفّذ فعلًا", en: "They prove what was planned was actually done" }, { ar: "لأن المدقق يطلبها فقط", en: "Only because auditors ask for them" }, { ar: "لأنها تغني عن التدريب", en: "Because they replace training" }], a: 0, why: { ar: "السجل دليل موضوعي على التنفيذ، ويكشف الانحرافات والاتجاهات مع الوقت.", en: "A record is objective evidence of execution and reveals deviations and trends over time." } },
      ],
    },
    {
      id: "ghp", code: "GHP", status: "ready", mins: 12,
      title: { ar: "ممارسات النظافة الجيدة", en: "Good Hygiene Practices" },
      blurb: { ar: "النظافة الشخصية، غسل الأيدي، الحالة الصحية، وسلوك العاملين حول الغذاء.", en: "Personal hygiene, handwashing, health status and behaviour around food." },
      lesson: {
        def: { ar: "ممارسات النظافة الجيدة (GHP) هي الإجراءات التي تمنع وصول الملوثات إلى الغذاء أو تحد منها، وتشمل نظافة العاملين وسلوكهم، ونظافة البيئة والأسطح، والتعامل الصحي مع الغذاء في كل مرحلة.", en: "Good Hygiene Practices (GHP) are the measures that prevent or limit contaminants reaching food — staff hygiene and behaviour, environment and surface hygiene, and hygienic handling at every stage." },
        why: { ar: "الإنسان من أكبر مصادر نقل الميكروبات إلى الغذاء. يد غير مغسولة أو عامل مريض قد يسبب تسممًا جماعيًا حتى لو كانت المعدات ممتازة.", en: "People are one of the biggest carriers of microbes to food. One unwashed hand or one sick worker can cause an outbreak even in an excellent facility." },
        reqs: [
          { ar: "غسل الأيدي بالطريقة الصحيحة وفي الأوقات الصحيحة.", en: "Correct handwashing at the right moments." },
          { ar: "إبلاغ المشرف عن الأعراض (إسهال، قيء، حمى، جروح ملتهبة) والاستبعاد المؤقت عند الحاجة.", en: "Reporting symptoms (diarrhoea, vomiting, fever, infected wounds) and temporary exclusion when needed." },
          { ar: "ملابس عمل نظيفة وغطاء شعر، ومنع المجوهرات في مناطق الغذاء.", en: "Clean work clothes and hair cover; no jewellery in food areas." },
          { ar: "تغطية الجروح بضمادة ملونة مقاومة للماء.", en: "Cover wounds with a coloured, waterproof dressing." },
          { ar: "منع الأكل والتدخين والشرب في مناطق التحضير.", en: "No eating, smoking or drinking in preparation areas." },
        ],
        steps: [
          { ar: "حدد لحظات غسل الأيدي الإلزامية وعلّقها بجوار كل مغسلة.", en: "Define the mandatory handwashing moments and post them at every sink." },
          { ar: "اعتمد نموذج إقرار صحي يومي قبل بدء الوردية.", en: "Use a short daily health declaration before each shift." },
          { ar: "نفّذ تدريبًا عمليًا (تجربة مسحة أو جل فلوري) بدل الشرح النظري فقط.", en: "Run practical training (swab or UV-gel demo) rather than theory only." },
          { ar: "راقب بالملاحظة المباشرة وسجّل النتائج دون تشهير بالأفراد.", en: "Monitor by direct observation and record results without naming and shaming." },
        ],
        examples: {
          factory: { ar: "غرفة تبديل ملابس مع حوض لغسل الأحذية قبل دخول منطقة الإنتاج.", en: "Changing room with boot wash before entering production." },
          kitchen: { ar: "غسل الأيدي إلزاميًا بعد التعامل مع الدجاج النيء وقبل لمس السلطة.", en: "Mandatory handwash after raw chicken and before touching salad." },
          cafe: { ar: "باريستا يستخدم ملقطًا أو قفازًا للمعجنات بدل اليد المجردة.", en: "Barista uses tongs or gloves for pastries, not bare hands." },
        },
        pitfalls: [
          { ar: "الاعتماد على القفازات بدل غسل الأيدي.", en: "Relying on gloves instead of handwashing." },
          { ar: "إجبار العامل المريض على الحضور بسبب نقص الموظفين.", en: "Pressuring a sick worker to come in because of short staffing." },
          { ar: "مغسلة أيدي تُستخدم لغسل الأواني أو مسدودة بالمعدات.", en: "A handwash sink used for dishes or blocked by equipment." },
        ],
        checklist: [
          { ar: "المغاسل متاحة وغير مسدودة ومزودة بالكامل.", en: "Sinks accessible, unblocked and fully stocked." },
          { ar: "جميع العاملين بغطاء شعر وملابس نظيفة.", en: "All staff in hair cover and clean clothes." },
          { ar: "لا مجوهرات ولا ساعات في مناطق التحضير.", en: "No jewellery or watches in prep areas." },
          { ar: "الإقرار الصحي اليومي مكتمل.", en: "Daily health declaration completed." },
          { ar: "الجروح مغطاة بضمادة ملونة.", en: "Wounds covered with coloured dressing." },
        ],
        caseStudy: { ar: "في منشأة تموين، أظهرت مسحات الأيدي العشوائية نتائج مرتفعة رغم أن العاملين «يغسلون أيديهم». الملاحظة المباشرة كشفت أن الغسل يستغرق أقل من 5 ثوانٍ وأن المناديل الورقية تنفد منتصف الوردية. الإجراء: تزويد إضافي، مؤقت رملي بجانب المغسلة، وتدريب عملي. (دراسة حالة تعليمية مجهّلة)", en: "In a catering unit, random hand swabs came back high although staff \"wash their hands\". Direct observation showed washes under 5 seconds and paper towels running out mid-shift. Action: extra supplies, a sand timer at the sink, and hands-on training. (Anonymised teaching case)" },
        refs: [refs.codexGP, refs.who5, refs.sfda],
      },
      quiz: [
        { q: { ar: "هل تُغني القفازات عن غسل الأيدي؟", en: "Do gloves replace handwashing?" }, o: [{ ar: "نعم دائمًا", en: "Yes, always" }, { ar: "لا، تُغسل الأيدي قبل لبس القفازات وتُغيّر القفازات عند تغيير المهمة", en: "No — wash before gloving and change gloves between tasks" }, { ar: "فقط في المقاهي", en: "Only in cafés" }], a: 1, why: { ar: "القفاز الملوث ينقل التلوث مثل اليد تمامًا، وقد يعطي شعورًا زائفًا بالأمان.", en: "A contaminated glove carries contamination just like a hand, and gives a false sense of safety." } },
        { q: { ar: "عامل يعاني من إسهال. ما الإجراء الصحيح؟", en: "A worker has diarrhoea. What is the right action?" }, o: [{ ar: "يعمل مع لبس كمامة", en: "Work wearing a mask" }, { ar: "يبلغ المشرف ويُستبعد من التعامل مع الغذاء وفق السياسة المعتمدة", en: "Report to the supervisor and be excluded from food handling per policy" }, { ar: "يكتفي بغسل يديه أكثر", en: "Just wash hands more often" }], a: 1, why: { ar: "الأعراض المعوية مؤشر على احتمال حمل مسببات مرضية؛ الاستبعاد يحمي المستهلك.", en: "Gastrointestinal symptoms indicate possible pathogen carriage; exclusion protects consumers." } },
        { q: { ar: "ما لون الضمادة المفضل لتغطية الجروح في مناطق الغذاء؟", en: "What dressing colour is preferred for wounds in food areas?" }, o: [{ ar: "لون الجلد", en: "Skin tone" }, { ar: "لون ظاهر (مثل الأزرق) ويفضل قابل للكشف", en: "A visible colour (e.g. blue), ideally detectable" }, { ar: "أبيض", en: "White" }], a: 1, why: { ar: "اللون الظاهر يسهّل رؤية الضمادة إذا سقطت في الغذاء.", en: "A visible colour makes the dressing easy to spot if it falls into food." } },
      ],
    },
    {
      id: "haccp", code: "HACCP", status: "ready", mins: 20,
      title: { ar: "تحليل المخاطر ونقاط التحكم الحرجة", en: "Hazard Analysis & Critical Control Points" },
      blurb: { ar: "المبادئ السبعة، الخطوات التمهيدية، وكيف تبني خطة تعمل فعلًا في الموقع.", en: "The seven principles, the preliminary steps, and how to build a plan that works on the floor." },
      lesson: {
        def: { ar: "الهاسب (HACCP) منهج علمي منظم لتحديد الأخطار المهمة على سلامة الغذاء وتقييمها والسيطرة عليها، بالتركيز على الخطوات التي يكون التحكم فيها ضروريًا لمنع الخطر أو خفضه إلى مستوى مقبول.", en: "HACCP is a structured, science-based method to identify, evaluate and control hazards that are significant for food safety, by focusing on the steps where control is essential to prevent or reduce a hazard to an acceptable level." },
        why: { ar: "بدل فحص المنتج النهائي فقط (وهو متأخر ومحدود)، يضبط HACCP العملية نفسها في النقاط التي تصنع الفرق.", en: "Instead of only testing the finished product (late and limited), HACCP controls the process itself at the points that make the difference." },
        reqs: [
          { ar: "وجود برامج تمهيدية (PRPs/GHP) فعّالة قبل البدء.", en: "Effective prerequisite programmes (PRPs/GHP) in place first." },
          { ar: "فريق متعدد التخصصات لديه معرفة بالمنتج والعملية.", en: "A multidisciplinary team with product and process knowledge." },
          { ar: "وصف المنتج والاستخدام المقصود ومخطط تدفق مُتحقق منه في الموقع.", en: "Product description, intended use, and a flow diagram verified on site." },
          { ar: "تطبيق المبادئ السبعة: (1) تحليل المخاطر، (2) تحديد نقاط التحكم الحرجة، (3) وضع الحدود الحرجة، (4) المراقبة، (5) الإجراءات التصحيحية، (6) التحقق، (7) التوثيق وحفظ السجلات.", en: "Apply the seven principles: (1) hazard analysis, (2) determine CCPs, (3) establish critical limits, (4) monitoring, (5) corrective actions, (6) verification, (7) documentation and records." },
        ],
        steps: [
          { ar: "شكّل فريق HACCP وحدد نطاق الخطة.", en: "Assemble the HACCP team and define the scope." },
          { ar: "صف المنتج وحدد الاستخدام المقصود والمستهلك المستهدف (بما فيه الفئات الحساسة).", en: "Describe the product, intended use and consumers (including vulnerable groups)." },
          { ar: "ارسم مخطط التدفق وتحقق منه بالمشي في الموقع.", en: "Draw the flow diagram and confirm it by walking the line." },
          { ar: "حلّل الأخطار البيولوجية والكيميائية والفيزيائية ومسببات الحساسية لكل خطوة.", en: "Analyse biological, chemical, physical and allergen hazards at each step." },
          { ar: "حدد نقاط التحكم الحرجة باستخدام شجرة القرار أو منطق موثق.", en: "Determine CCPs using a decision tree or documented logic." },
          { ar: "ضع حدودًا حرجة مبنية على مراجع علمية أو تشريعية أو دراسات تحقق — لا على التخمين.", en: "Set critical limits based on scientific, regulatory or validation evidence — never on guesswork." },
          { ar: "حدد طريقة المراقبة ومن يراقب ومتى، والإجراء التصحيحي عند الانحراف.", en: "Define how, who and when to monitor, and the corrective action on deviation." },
          { ar: "تحقق من فاعلية الخطة وراجعها عند أي تغيير.", en: "Verify the plan works and review it whenever something changes." },
        ],
        examples: {
          factory: { ar: "خطوة البسترة كنقطة تحكم حرجة مع مراقبة مستمرة للحرارة والزمن وصمام تحويل تلقائي.", en: "Pasteurisation as a CCP with continuous time/temperature monitoring and an automatic divert valve." },
          kitchen: { ar: "الطهي النهائي للدجاج كنقطة تحكم حرجة مع قياس الحرارة الداخلية لكل دفعة وفق الحد المعتمد في الخطة.", en: "Final cooking of chicken as a CCP, with core temperature measured per batch against the plan's validated limit." },
          cafe: { ar: "التبريد السريع للحليب المبخر غير المستخدم، أو التخلص منه بعد مدة محددة في الإجراء.", en: "Rapid chilling of unused steamed milk, or discarding it after a time set in the procedure." },
        },
        pitfalls: [
          { ar: "تحويل كل خطوة إلى CCP، فتضيع الأولويات.", en: "Making every step a CCP, so priorities get lost." },
          { ar: "نسخ خطة جاهزة من الإنترنت لا تطابق العملية الفعلية.", en: "Copying an internet template that doesn't match the real process." },
          { ar: "حدود حرجة بلا مرجع أو دراسة تحقق.", en: "Critical limits with no reference or validation." },
          { ar: "سجلات مراقبة تُملأ في نهاية اليوم دفعة واحدة.", en: "Monitoring records filled in all at once at the end of the day." },
        ],
        checklist: [
          { ar: "فريق HACCP موثق بالأسماء والمؤهلات.", en: "HACCP team documented with names and competence." },
          { ar: "مخطط التدفق موقّع بعد التحقق الميداني.", en: "Flow diagram signed after on-site verification." },
          { ar: "لكل CCP حد حرج ومرجعه.", en: "Every CCP has a critical limit and its reference." },
          { ar: "سجلات المراقبة تُملأ لحظيًا.", en: "Monitoring records completed in real time." },
          { ar: "الإجراءات التصحيحية موثقة مع مصير المنتج المتأثر.", en: "Corrective actions documented, including fate of affected product." },
          { ar: "مراجعة الخطة مؤرخة خلال آخر 12 شهرًا أو بعد آخر تغيير.", en: "Plan review dated within 12 months or after the last change." },
        ],
        caseStudy: { ar: "مطعم وضع «التخزين البارد» كنقطة تحكم حرجة دون أي مراقبة مستمرة، بينما ترك خطوة إعادة التسخين بلا قياس. بعد إعادة تحليل المخاطر أصبح التخزين البارد برنامجًا تمهيديًا تشغيليًا (OPRP) مع سجل حرارة مرتين يوميًا، وأُضيفت إعادة التسخين كنقطة تحكم حرجة بحد معتمد وقياس لكل دفعة. (دراسة حالة تعليمية مجهّلة)", en: "A restaurant listed \"cold storage\" as a CCP with no real monitoring, while reheating had no measurement at all. After re-analysis, cold storage became an OPRP with twice-daily temperature logs, and reheating was added as a CCP with a validated limit measured per batch. (Anonymised teaching case)" },
        refs: [refs.codexGP, refs.iso22000, refs.sfda],
      },
      quiz: [
        { q: { ar: "ما هو المبدأ الأول من مبادئ HACCP؟", en: "What is the first HACCP principle?" }, o: [{ ar: "وضع الحدود الحرجة", en: "Establish critical limits" }, { ar: "إجراء تحليل المخاطر", en: "Conduct a hazard analysis" }, { ar: "التوثيق", en: "Documentation" }], a: 1, why: { ar: "كل ما بعده مبني على تحليل المخاطر؛ دونه لا يمكن تحديد CCP بشكل صحيح.", en: "Everything else is built on the hazard analysis; without it CCPs cannot be identified correctly." } },
        { q: { ar: "من أين يجب أن يأتي الحد الحرج؟", en: "Where should a critical limit come from?" }, o: [{ ar: "من خبرة الشيف فقط", en: "Only the chef's experience" }, { ar: "من مرجع علمي أو تشريعي أو دراسة تحقق", en: "A scientific or regulatory reference, or a validation study" }, { ar: "من أي خطة على الإنترنت", en: "Any plan found online" }], a: 1, why: { ar: "الحد الحرج يفصل بين الآمن وغير الآمن، لذا يجب أن يكون مثبتًا علميًا ومناسبًا لعمليتك.", en: "A critical limit separates safe from unsafe, so it must be scientifically supported and fit your process." } },
        { q: { ar: "ماذا تفعل عند تجاوز الحد الحرج؟", en: "What do you do when a critical limit is breached?" }, o: [{ ar: "تكمل الإنتاج وتكتب ملاحظة", en: "Carry on and add a note" }, { ar: "تنفذ الإجراء التصحيحي المحدد، وتتحكم في المنتج المتأثر، وتوثق", en: "Apply the defined corrective action, control affected product, and record it" }, { ar: "تغيّر الحد الحرج", en: "Change the critical limit" }], a: 1, why: { ar: "الإجراء التصحيحي يعيد السيطرة ويحدد مصير المنتج الذي أُنتج أثناء الانحراف.", en: "The corrective action restores control and decides the fate of product made during the deviation." } },
        { q: { ar: "ما الفرق بين CCP وOPRP باختصار؟", en: "In short, how does a CCP differ from an OPRP?" }, o: [{ ar: "لا فرق", en: "No difference" }, { ar: "CCP له حد حرج قابل للقياس ومراقبة تسمح بتصحيح فوري؛ OPRP تدبير تحكم بمعيار عمل", en: "A CCP has a measurable critical limit with monitoring allowing timely correction; an OPRP is a control measure with an action criterion" }, { ar: "OPRP أهم دائمًا", en: "OPRP is always more important" }], a: 1, why: { ar: "وفق ISO 22000:2018 يُدار كلاهما بخطة، لكن CCP يُربط بحد حرج قابل للقياس بينما OPRP بمعيار عمل قابل للقياس أو الملاحظة.", en: "Under ISO 22000:2018 both are managed in a plan, but a CCP has a measurable critical limit while an OPRP has a measurable or observable action criterion." } },
      ],
    },
    {
      id: "temp", code: "TEMP", status: "ready", mins: 12,
      title: { ar: "ضبط درجات الحرارة وسلسلة التبريد", en: "Temperature Control & Cold Chain" },
      blurb: { ar: "منطقة الخطر، التبريد والتجميد والحفظ الساخن، والقياس الصحيح.", en: "The danger zone, chilling, freezing, hot holding and measuring correctly." },
      lesson: {
        def: { ar: "ضبط درجات الحرارة هو إبقاء الغذاء خارج النطاق الذي تتكاثر فيه الميكروبات بسرعة، أو تقليل الزمن الذي يقضيه فيه، من الاستلام حتى التقديم.", en: "Temperature control means keeping food out of the range where microbes multiply quickly — or minimising time spent in it — from receipt to service." },
        why: { ar: "كثير من البكتيريا المسببة للأمراض تتكاثر بسرعة بين 5°م و60°م تقريبًا (منظمة الصحة العالمية). خطأ صغير في التبريد قد يحوّل وجبة آمنة إلى خطرة خلال ساعات.", en: "Many pathogenic bacteria grow rapidly between roughly 5°C and 60°C (WHO). A small chilling error can turn a safe meal into a hazard within hours." },
        reqs: [
          { ar: "حدود حرارة لكل مرحلة (استلام، تبريد، تجميد، طهي، حفظ ساخن، تبريد بعد الطهي) مأخوذة من التشريع المعمول به أو المرجع المعتمد لديك.", en: "Temperature limits for each stage (receipt, chilled, frozen, cooking, hot holding, cooling) taken from the applicable regulation or your approved reference." },
          { ar: "أجهزة قياس معايرة ومنظفة ومعقمة بين الاستخدامات.", en: "Calibrated thermometers, cleaned and sanitised between uses." },
          { ar: "سجلات مراقبة بتكرار محدد وإجراء واضح عند الانحراف.", en: "Monitoring records at a defined frequency with a clear action on deviation." },
          { ar: "تبريد سريع للأغذية المطهوة على مراحل زمنية محددة في الإجراء.", en: "Rapid cooling of cooked food within time stages defined in the procedure." },
        ],
        steps: [
          { ar: "حدد نقاط القياس على مخطط التدفق.", en: "Mark the measuring points on the flow diagram." },
          { ar: "اكتب الحد المقبول لكل نقطة ومرجعه.", en: "Write the acceptable limit for each point and its reference." },
          { ar: "عاير أجهزة القياس (ماء مثلج / ماء مغلي أو مقارنة بجهاز مرجعي) وسجّل النتيجة.", en: "Check thermometers (ice point / boiling point or against a reference unit) and record it." },
          { ar: "سجّل القراءات في وقتها — استخدم سجل الحرارة في الأدوات.", en: "Record readings at the time — use the temperature log in the toolkit." },
          { ar: "حلّل الاتجاهات أسبوعيًا: الانحرافات المتكررة تشير لمشكلة جهاز أو سلوك.", en: "Review trends weekly: repeating deviations point to an equipment or behaviour problem." },
        ],
        examples: {
          factory: { ar: "مسجّل بيانات (Data logger) في شاحنة التبريد يُراجع عند كل استلام.", en: "A data logger in the reefer truck, reviewed at every delivery." },
          kitchen: { ar: "تقسيم القدور الكبيرة إلى أوعية ضحلة لتسريع التبريد.", en: "Splitting big pots into shallow trays to speed up cooling." },
          cafe: { ar: "قراءة ثلاجة الحليب عند الفتح والإغلاق.", en: "Reading the milk fridge at opening and closing." },
        },
        pitfalls: [
          { ar: "الاعتماد على شاشة الثلاجة بدل قياس حرارة المنتج.", en: "Trusting the fridge display instead of product temperature." },
          { ar: "ترك الطعام المطهو يبرد على الطاولة لساعات.", en: "Leaving cooked food to cool on the bench for hours." },
          { ar: "تحميل الثلاجة فوق طاقتها ومنع دوران الهواء.", en: "Overloading the fridge and blocking airflow." },
        ],
        checklist: [
          { ar: "سجل الحرارة مكتمل لكل الثلاجات والمجمدات.", en: "Temperature log complete for all fridges and freezers." },
          { ar: "جهاز القياس معاير ومسجل.", en: "Thermometer calibration checked and recorded." },
          { ar: "لا أغذية مطهوة تبرد على الطاولة.", en: "No cooked food cooling on the bench." },
          { ar: "الانحرافات مسجلة مع الإجراء المتخذ.", en: "Deviations recorded with action taken." },
        ],
        caseStudy: { ar: "مقهى سجّل «4°م» لثلاجة الحليب يوميًا لأسابيع، وعند القياس بجهاز معاير كانت حرارة الحليب الفعلية أعلى بكثير. السبب: القراءة تُنسخ من شاشة معطلة. الإجراء: استبدال المستشعر، القياس بمسبار داخل وعاء ماء في الثلاجة، وتدريب على تسجيل القيمة الفعلية. (دراسة حالة تعليمية مجهّلة)", en: "A café logged \"4°C\" for the milk fridge every day for weeks; a calibrated probe showed the milk was much warmer. Cause: values copied from a faulty display. Action: replace the sensor, measure with a probe in a water vial inside the fridge, and train staff to record the actual value. (Anonymised teaching case)" },
        refs: [refs.who5, refs.codexGP, refs.sfda],
      },
      quiz: [
        { q: { ar: "ما النطاق التقريبي لـ«منطقة الخطر» وفق منظمة الصحة العالمية؟", en: "What is the approximate \"danger zone\" per WHO?" }, o: [{ ar: "من -18 إلى 0°م", en: "-18 to 0°C" }, { ar: "من 5 إلى 60°م", en: "5 to 60°C" }, { ar: "من 60 إلى 100°م", en: "60 to 100°C" }], a: 1, why: { ar: "دليل المفاتيح الخمسة يذكر أن تكاثر الميكروبات يتسارع بين 5°م و60°م. الحدود التشغيلية لديك تُؤخذ من التشريع المعمول به.", en: "The Five Keys manual states microbial growth speeds up between 5°C and 60°C. Your operational limits come from the applicable regulation." } },
        { q: { ar: "ما أفضل طريقة لتسريع تبريد قدر كبير من الطعام المطهو؟", en: "Best way to cool a big pot of cooked food faster?" }, o: [{ ar: "تركه مغطى على الطاولة", en: "Leave it covered on the bench" }, { ar: "تقسيمه إلى أوعية ضحلة واستخدام مبرد سريع أو حمام ثلج", en: "Split into shallow trays and use a blast chiller or ice bath" }, { ar: "وضعه في المجمد كما هو", en: "Put it in the freezer as is" }], a: 1, why: { ar: "زيادة المساحة السطحية تسرّع فقد الحرارة وتقلل زمن البقاء في منطقة الخطر.", en: "More surface area speeds heat loss and shortens time in the danger zone." } },
        { q: { ar: "ماذا تقيس للتحقق من سلامة التخزين البارد؟", en: "What do you measure to verify cold storage?" }, o: [{ ar: "شاشة الثلاجة فقط", en: "Only the fridge display" }, { ar: "حرارة المنتج أو محاكٍ له بجهاز معاير", en: "Product (or simulant) temperature with a calibrated probe" }, { ar: "حرارة الغرفة", en: "Room temperature" }], a: 1, why: { ar: "الشاشة تقيس الهواء وقد تكون غير دقيقة؛ المعيار هو حرارة الغذاء نفسه.", en: "Displays read air and may be inaccurate; what matters is the food's own temperature." } },
      ],
    },
    {
      id: "allergen", code: "ALG", status: "ready", mins: 12,
      title: { ar: "إدارة مسببات الحساسية", en: "Allergen Management" },
      blurb: { ar: "تحديد المسببات، منع الانتقال العرضي، والملصقات الصحيحة.", en: "Identify allergens, prevent cross-contact and label correctly." },
      lesson: {
        def: { ar: "إدارة مسببات الحساسية هي ضبط استلام وتخزين وتحضير وتوسيم المكونات التي قد تسبب تفاعلات تحسسية، بحيث يحصل المستهلك على معلومات صحيحة ولا يتعرض لمسبب لم يُعلن عنه.", en: "Allergen management controls how allergenic ingredients are received, stored, prepared and labelled, so consumers get correct information and are never exposed to an undeclared allergen." },
        why: { ar: "لا يوجد «حد آمن» عام لكثير من المصابين، والطهي لا يزيل البروتين المسبب. خطأ ملصق واحد قد يكون قاتلًا ويؤدي إلى سحب المنتج.", en: "For many allergic consumers there is no general \"safe\" level, and cooking does not remove the allergenic protein. One label error can be fatal and trigger a recall." },
        reqs: [
          { ar: "قائمة بمسببات الحساسية المطلوب الإفصاح عنها وفق التشريع المعمول به (مثل: الحبوب المحتوية على الغلوتين، القشريات، البيض، الأسماك، الفول السوداني، الصويا، الحليب، المكسرات، السمسم، الكبريتيت…).", en: "A list of allergens that must be declared under the applicable regulation (e.g. gluten cereals, crustaceans, eggs, fish, peanuts, soy, milk, tree nuts, sesame, sulphites…)." },
          { ar: "مصفوفة تربط كل منتج بالمسببات الموجودة فيه.", en: "A matrix linking each product to the allergens it contains." },
          { ar: "فصل في التخزين والتحضير، وتنظيف موثق بين التشغيلات.", en: "Segregation in storage and prep, with validated cleaning between runs." },
          { ar: "مراجعة الملصق مقابل الوصفة الفعلية عند أي تغيير.", en: "Label checked against the actual recipe whenever anything changes." },
        ],
        steps: [
          { ar: "اجمع مواصفات المكونات من الموردين وحدد المسببات في كل مكون.", en: "Collect supplier specs and identify allergens in each ingredient." },
          { ar: "ابنِ مصفوفة المنتجات × المسببات (استخدم نموذج تقييم الحساسية لاحقًا).", en: "Build the product × allergen matrix." },
          { ar: "خزّن المكونات المسببة في الأسفل وفي حاويات معرّفة.", en: "Store allergenic ingredients low and in labelled containers." },
          { ar: "رتّب الإنتاج من الأقل إلى الأكثر احتواءً على المسببات عند الإمكان.", en: "Schedule production from fewest to most allergens where possible." },
          { ar: "تحقق من الملصق عند بداية كل تشغيلة وعند تغيير الوصفة أو المورد.", en: "Check the label at every run start and whenever recipe or supplier changes." },
        ],
        examples: {
          factory: { ar: "خط مخصص للمنتجات الخالية من المكسرات أو تنظيف موثق بفحص بروتين سريع.", en: "Dedicated nut-free line, or validated clean-down with rapid protein test." },
          kitchen: { ar: "أدوات بنفسجية مخصصة لطلبات الحساسية.", en: "Purple utensils reserved for allergy orders." },
          cafe: { ar: "إبريق مستقل لحليب الشوفان/اللوز مع تعريف واضح.", en: "Separate, clearly marked jug for oat/almond milk." },
        },
        pitfalls: [
          { ar: "تغيير المورد دون مراجعة مواصفات مسببات الحساسية.", en: "Changing a supplier without reviewing its allergen spec." },
          { ar: "الاعتماد على ذاكرة الموظف بدل المصفوفة المكتوبة.", en: "Relying on staff memory instead of the written matrix." },
          { ar: "إعادة استخدام زيت القلي لمنتجات مختلفة المسببات.", en: "Re-using frying oil across products with different allergens." },
        ],
        checklist: [
          { ar: "مصفوفة الحساسية محدثة ومتاحة للعاملين.", en: "Allergen matrix up to date and available to staff." },
          { ar: "المكونات المسببة معرّفة ومخزنة منفصلة.", en: "Allergenic ingredients labelled and stored separately." },
          { ar: "الملصقات مطابقة للوصفة الحالية.", en: "Labels match current recipes." },
          { ar: "العاملون يعرفون كيف يتعاملون مع طلب حساسية.", en: "Staff know how to handle an allergy request." },
        ],
        caseStudy: { ar: "منشأة غيّرت مورد صلصة البيستو إلى صنف يحتوي على الكاجو بدل الصنوبر دون تحديث الملصق. اكتُشف الخطأ في التحقق الأسبوعي من الملصقات قبل التوزيع. الإجراء: إضافة «تغيير المورد» كمحفز إلزامي لمراجعة الحساسية. (دراسة حالة تعليمية مجهّلة)", en: "A site switched to a pesto supplier using cashew instead of pine nuts without updating the label. The weekly label check caught it before dispatch. Action: make \"supplier change\" a mandatory trigger for allergen review. (Anonymised teaching case)" },
        refs: [refs.codexAllergen, refs.codexLabel, refs.sfda],
      },
      quiz: [
        { q: { ar: "هل يزيل الطهي خطر مسببات الحساسية؟", en: "Does cooking remove allergen risk?" }, o: [{ ar: "نعم", en: "Yes" }, { ar: "لا، البروتين المسبب يبقى غالبًا", en: "No — the allergenic protein usually remains" }, { ar: "فقط عند القلي", en: "Only when frying" }], a: 1, why: { ar: "على عكس كثير من الميكروبات، لا يُعتمد على الحرارة للتخلص من مسببات الحساسية.", en: "Unlike many microbes, heat cannot be relied on to eliminate allergens." } },
        { q: { ar: "ما المحفز الذي يجب أن يُطلق مراجعة الحساسية؟", en: "Which trigger should launch an allergen review?" }, o: [{ ar: "تغيير المورد أو الوصفة", en: "A supplier or recipe change" }, { ar: "تغيير لون العبوة فقط", en: "Only a packaging colour change" }, { ar: "مرة كل خمس سنوات", en: "Once every five years" }], a: 0, why: { ar: "أي تغيير في المكونات قد يُدخل مسببًا جديدًا غير معلن.", en: "Any ingredient change may introduce a new undeclared allergen." } },
        { q: { ar: "أين تُخزن المكونات المسببة للحساسية في الرفوف؟", en: "Where should allergenic ingredients go on shelving?" }, o: [{ ar: "في الأعلى", en: "Top shelf" }, { ar: "في الأسفل وفي حاويات معرّفة", en: "Bottom, in labelled containers" }, { ar: "لا يهم", en: "Doesn't matter" }], a: 1, why: { ar: "التخزين السفلي يمنع تساقطها على مواد أخرى.", en: "Storing low prevents spills onto other materials." } },
      ],
    },
    { id: "iso22000", code: "ISO 22000", status: "soon", title: { ar: "نظام إدارة سلامة الغذاء", en: "Food Safety Management System" }, blurb: { ar: "هيكل المواصفة، السياق، القيادة، التخطيط، والتحسين.", en: "Structure, context, leadership, planning and improvement." } },
    { id: "prp", code: "PRPs", status: "soon", title: { ar: "البرامج التمهيدية", en: "Prerequisite Programmes" }, blurb: { ar: "الشروط الأساسية التي تسبق أي خطة HACCP.", en: "The basic conditions that come before any HACCP plan." } },
    { id: "vv", code: "V&V", status: "soon", title: { ar: "التحقق والتحقق من الصلاحية", en: "Verification & Validation" }, blurb: { ar: "متى تسأل «هل نفذنا؟» ومتى تسأل «هل ينجح؟».", en: "When to ask \"did we do it?\" versus \"does it work?\"." } },
    { id: "cleaning", code: "C&S", status: "soon", title: { ar: "التنظيف والتطهير", en: "Cleaning & Sanitation" }, blurb: { ar: "خطوات التنظيف، التحقق بالمسحات، وسلامة المواد الكيميائية.", en: "Cleaning steps, swab verification and chemical safety." } },
    { id: "recall", code: "T&R", status: "soon", title: { ar: "التتبع والاستدعاء", en: "Traceability & Recall" }, blurb: { ar: "خطوة للأمام وخطوة للخلف، وتمرين الاستدعاء التجريبي.", en: "One step forward, one step back, and the mock recall." } },
    { id: "defense", code: "TACCP / VACCP", status: "soon", title: { ar: "الدفاع الغذائي والاحتيال الغذائي", en: "Food Defense & Food Fraud" }, blurb: { ar: "حماية الغذاء من العبث المتعمد والغش.", en: "Protecting food from deliberate tampering and fraud." } },
    { id: "supplier", code: "SQM", status: "soon", title: { ar: "إدارة الموردين والمواد الخام", en: "Supplier & Raw Material Management" }, blurb: { ar: "اعتماد الموردين، المواصفات، وفحص الاستلام.", en: "Supplier approval, specifications and goods-in inspection." } },
  ];

  const paths = [
    { id: "inspector", t: { ar: "مفتش / مدقق", en: "Inspector / Auditor" }, mods: ["gmp", "ghp", "haccp", "temp"] },
    { id: "kitchen", t: { ar: "مشرف مطبخ أو مطعم", en: "Kitchen / restaurant lead" }, mods: ["ghp", "temp", "allergen", "gmp"] },
    { id: "student", t: { ar: "طالب علوم أغذية", en: "Food science student" }, mods: ["gmp", "ghp", "haccp", "allergen", "temp"] },
    { id: "manager", t: { ar: "مدير جودة أو إنتاج", en: "Quality / production manager" }, mods: ["haccp", "gmp", "allergen"] },
  ];

  /* ---------------- Dictionary ---------------- */
  const cats = {
    sys: { ar: "أنظمة", en: "Systems" },
    audit: { ar: "تدقيق", en: "Auditing" },
    fs: { ar: "سلامة غذاء", en: "Food safety" },
    lab: { ar: "مختبرات", en: "Laboratory" },
    mfg: { ar: "تصنيع", en: "Manufacturing" },
    hyg: { ar: "نظافة", en: "Hygiene" },
    risk: { ar: "مخاطر", en: "Risk" },
  };
  const T = (code, en, ar, cat, exAr, exEn, ar2, en2, rel, ex2Ar, ex2En) => ({ code, term_en: en, term_ar: ar, category: cat, simple_explanation_ar: exAr, simple_explanation_en: exEn, example_ar: ex2Ar || ar2 || "", example_en: ex2En || en2 || "", related: rel || [] });
  const dict = [
    T("QA", "Quality Assurance", "ضمان الجودة", "sys", "أنشطة مخططة توفر الثقة بأن متطلبات الجودة ستتحقق.", "Planned activities that give confidence quality requirements will be met.", "إعداد الإجراءات والتدريب والتدقيق الداخلي قبل أن تظهر المشكلة.", "Writing procedures, training and internal audits before problems appear.", ["QC", "SOP"]),
    T("QC", "Quality Control", "ضبط الجودة", "sys", "الفحص والاختبار ومراقبة النتائج للتحقق من المطابقة.", "Inspection, testing and monitoring results to check conformity.", "قياس وزن العبوة وفحص المظهر لكل دفعة.", "Checking pack weight and appearance on every batch.", ["QA", "COA"]),
    T("FSMS", "Food Safety Management System", "نظام إدارة سلامة الغذاء", "sys", "نظام إداري منظم للتحكم في مخاطر سلامة الغذاء.", "An organised management system to control food safety hazards.", "نظام مبني على ISO 22000 يشمل السياسة والأهداف وخطة HACCP.", "A system built on ISO 22000 with policy, objectives and a HACCP plan.", ["HACCP", "PRP"]),
    T("HACCP", "Hazard Analysis and Critical Control Points", "تحليل المخاطر ونقاط التحكم الحرجة", "fs", "منهج لتحديد الأخطار المهمة والسيطرة عليها.", "A method to identify significant hazards and control them.", "تحديد الطهي كنقطة تحكم حرجة بحد حرارة معتمد.", "Making cooking a CCP with a validated temperature limit.", ["CCP", "OPRP", "CCP Limit"]),
    T("GMP", "Good Manufacturing Practices", "ممارسات التصنيع الجيد", "mfg", "ممارسات أساسية لضمان إنتاج الغذاء في ظروف مناسبة.", "Basic practices ensuring food is produced in suitable conditions.", "مسارات حركة باتجاه واحد ومعدات سهلة التنظيف.", "One-way flow and easy-to-clean equipment.", ["GHP", "PRP"]),
    T("GHP", "Good Hygiene Practices", "ممارسات النظافة الجيدة", "hyg", "ممارسات النظافة التي تمنع التلوث وتحد من مخاطره.", "Hygiene practices that prevent contamination and limit its risk.", "غسل الأيدي قبل التعامل مع الأغذية الجاهزة.", "Handwashing before handling ready-to-eat food.", ["GMP", "SSOP"]),
    T("PRP", "Prerequisite Programme", "برنامج تمهيدي", "sys", "شروط وأنشطة أساسية لازمة لتهيئة بيئة إنتاج آمنة.", "Basic conditions and activities needed for a safe production environment.", "مكافحة الآفات، صيانة المبنى، جودة المياه.", "Pest control, building maintenance, water quality.", ["OPRP", "GMP"]),
    T("OPRP", "Operational Prerequisite Programme", "برنامج تمهيدي تشغيلي", "fs", "تدبير تحكم يحدد تحليل المخاطر أنه ضروري للسيطرة على خطر مهم.", "A control measure the hazard analysis shows is needed to control a significant hazard.", "غسل الخضار بمطهر بتركيز يُراقب بمعيار عمل.", "Produce washing with sanitiser monitored against an action criterion.", ["PRP", "CCP"]),
    T("CCP", "Critical Control Point", "نقطة تحكم حرجة", "fs", "خطوة يطبق عندها التحكم لمنع خطر مهم أو خفضه إلى مستوى مقبول.", "A step where control is applied to prevent or reduce a significant hazard to an acceptable level.", "البسترة، الطهي النهائي، كاشف المعادن.", "Pasteurisation, final cooking, metal detection.", ["CCP Limit", "HACCP"]),
    T("CCP Limit", "Critical Limit", "الحد الحرج", "fs", "قيمة أو معيار يفصل بين المقبول وغير المقبول عند نقطة تحكم حرجة.", "A value or criterion separating acceptable from unacceptable at a CCP.", "زمن وحرارة محددان في خطة HACCP بناءً على دراسة تحقق.", "A time and temperature set in the HACCP plan from a validation study.", ["CCP", "Validation"]),
    T("NC", "Nonconformity", "حالة عدم مطابقة", "audit", "عدم استيفاء متطلب محدد.", "Non-fulfilment of a requirement.", "سجل حرارة غير مكتمل ليومين.", "A temperature log missing two days.", ["NCR", "CAPA"]),
    T("NCR", "Nonconformity Report", "تقرير عدم مطابقة", "audit", "وثيقة تسجل الحالة والأدلة والإجراءات والمسؤوليات.", "A document recording the case, evidence, actions and owners.", "تقرير يحدد السبب الجذري والمسؤول وتاريخ الإغلاق.", "A report naming the root cause, owner and close-out date.", ["NC", "CAPA", "RCA"]),
    T("CAPA", "Corrective and Preventive Action", "إجراء تصحيحي ووقائي", "audit", "معالجة سبب المشكلة ومنع تكرارها؛ وتختلف المصطلحات حسب النظام المرجعي.", "Treating the cause of a problem and preventing recurrence; terminology varies by standard.", "تعديل جدول الصيانة بعد تعطل ثلاجة متكرر.", "Changing the maintenance schedule after repeated fridge failures.", ["RCA", "NCR"]),
    T("RCA", "Root Cause Analysis", "تحليل السبب الجذري", "audit", "منهج للوصول إلى السبب الأساسي للمشكلة.", "A method to reach the underlying cause of a problem.", "استخدام 5 لماذا أو مخطط عظم السمكة.", "Using 5 Whys or a fishbone diagram.", ["CAPA", "NCR"]),
    T("SOP", "Standard Operating Procedure", "إجراء تشغيلي قياسي", "sys", "تعليمات معتمدة لتنفيذ نشاط بطريقة ثابتة.", "Approved instructions to perform an activity consistently.", "إجراء استلام البضائع خطوة بخطوة.", "A step-by-step goods-receiving procedure.", ["SSOP", "QA"]),
    T("SSOP", "Sanitation Standard Operating Procedure", "إجراء تشغيلي قياسي للنظافة", "hyg", "تعليمات موثقة لأعمال التنظيف والتطهير ومراقبتها.", "Documented instructions for cleaning and sanitising and how they're monitored.", "إجراء تنظيف آلة التقطيع يوميًا مع التحقق.", "Daily slicer cleaning procedure with verification.", ["SOP", "ATP"]),
    T("COA", "Certificate of Analysis", "شهادة تحليل", "lab", "وثيقة بنتائج اختبارات عينة أو دفعة محددة.", "A document with test results for a specific sample or batch.", "شهادة ميكروبيولوجية مرفقة بدفعة الحليب المجفف.", "A micro certificate shipped with a milk-powder batch.", ["QC"]),
    T("SDS", "Safety Data Sheet", "صحيفة بيانات السلامة", "hyg", "معلومات مخاطر المادة الكيميائية والتعامل الآمن معها.", "Information on a chemical's hazards and safe handling.", "صحيفة المطهر توضح معدات الحماية والإسعافات الأولية.", "The sanitiser sheet showing PPE and first aid.", ["SSOP"]),
    T("FIFO", "First In, First Out", "الوارد أولاً يصرف أولاً", "mfg", "صرف المخزون حسب ترتيب دخوله.", "Issuing stock in the order it arrived.", "وضع الشحنة الجديدة خلف القديمة على الرف.", "Putting new deliveries behind old stock on the shelf.", ["FEFO"]),
    T("FEFO", "First Expired, First Out", "الأقرب انتهاءً يصرف أولاً", "mfg", "صرف المنتجات ذات تاريخ الانتهاء الأقرب أولاً.", "Issuing products with the nearest expiry first.", "صرف علبة تنتهي غدًا قبل علبة وصلت أمس وتنتهي بعد شهر.", "Using a tub expiring tomorrow before one that arrived yesterday but expires next month.", ["FIFO"]),
    T("KPI", "Key Performance Indicator", "مؤشر أداء رئيسي", "sys", "مقياس لمتابعة مدى تحقيق هدف محدد.", "A measure tracking progress against a goal.", "نسبة إغلاق NCR في موعدها شهريًا.", "Monthly % of NCRs closed on time.", ["QA"]),
    T("TDS", "Total Dissolved Solids", "إجمالي المواد الصلبة الذائبة", "lab", "مقياس لتركيز المواد الذائبة في الماء.", "A measure of dissolved substances in water.", "متابعة TDS لمياه آلة القهوة بعد الفلتر.", "Monitoring TDS of espresso-machine water after the filter.", []),
    T("ATP", "Adenosine Triphosphate", "أدينوسين ثلاثي الفوسفات", "lab", "جزيء طاقة يُستخدم اختباره كمؤشر سريع لبقايا عضوية/نظافة السطح، وليس اختباراً مباشراً لعدّ الميكروبات.", "An energy molecule; ATP swabs are a quick indicator of organic residue / surface cleanliness — not a direct microbial count.", "مسحة ATP لسطح التحضير بعد التنظيف.", "An ATP swab of a prep surface after cleaning.", ["SSOP", "Verification"]),
    T("Validation", "Validation", "التحقق من الصلاحية", "fs", "الحصول على دليل أن تدبير التحكم قادر على تحقيق النتيجة المطلوبة.", "Obtaining evidence that a control measure can achieve the intended result.", "دراسة تثبت أن زمن وحرارة الطهي يقتلان الممرض المستهدف.", "A study proving a cook time/temperature kills the target pathogen.", ["Verification", "CCP Limit"]),
    T("Verification", "Verification", "التحقق", "fs", "التأكد من تنفيذ المتطلبات المحددة كما خُطط لها.", "Confirming specified requirements have been fulfilled as planned.", "مراجعة سجلات المراقبة ومعايرة الأجهزة.", "Reviewing monitoring records and calibrating instruments.", ["Validation"]),
  ];

  /* ---------------- Knowledge Center ---------------- */
  const articles = [
    {
      id: "qa-vs-qc", type: "article", mins: 4, date: "2026-11-04",
      title: { ar: "ضمان الجودة وضبط الجودة: ما الفرق؟", en: "QA vs QC: what's the difference?" },
      sum: { ar: "شرح مبسط لدور كل منهما وكيف يتكاملان في منشأة غذائية.", en: "A plain explanation of each role and how they fit together in a food business." },
      body: {
        ar: [["p", "يخلط كثيرون بين ضمان الجودة (QA) وضبط الجودة (QC)، رغم أن لكل منهما سؤالًا مختلفًا."], ["h", "ضبط الجودة: هل هذا المنتج مطابق؟"], ["p", "QC يركز على المنتج: يفحص ويقيس ويختبر الدفعة أو العينة ويقارنها بالمواصفة. هو نشاط تفاعلي يكتشف المشكلة بعد حدوثها أو أثناءها."], ["h", "ضمان الجودة: هل نظامنا قادر على إنتاج منتج مطابق دائمًا؟"], ["p", "QA يركز على النظام: الإجراءات والتدريب والتدقيق الداخلي وإدارة الموردين. هو نشاط وقائي يمنع المشكلة قبل وقوعها."], ["h", "كيف يتكاملان؟"], ["ul", ["نتائج QC هي بيانات يستخدمها QA لتحسين النظام.", "إذا تكررت نتيجة QC سيئة، فهذا سؤال لـ QA عن السبب الجذري.", "لا يغني أحدهما عن الآخر: نظام بلا فحص أعمى، وفحص بلا نظام مُرهق ومتأخر."]]],
        en: [["p", "QA and QC are often mixed up, yet each answers a different question."], ["h", "Quality Control: does this product conform?"], ["p", "QC focuses on the product: it inspects, measures and tests a batch or sample against the specification. It is reactive — it finds problems during or after they happen."], ["h", "Quality Assurance: can our system always make a conforming product?"], ["p", "QA focuses on the system: procedures, training, internal audit and supplier management. It is preventive — it stops problems before they happen."], ["h", "How they fit together"], ["ul", ["QC results are data that QA uses to improve the system.", "A repeating bad QC result is a QA question about root cause.", "Neither replaces the other: a system without checks is blind; checks without a system are exhausting and late."]]],
      },
      refs: ["ISO 9000:2015 — Quality management systems: Fundamentals and vocabulary"],
    },
    {
      id: "good-ncr", type: "guide", mins: 5, date: "2026-11-04",
      title: { ar: "كيف تكتب تقرير عدم مطابقة يُغلق فعلًا", en: "How to write an NCR that actually closes" },
      sum: { ar: "خمسة عناصر تجعل تقرير عدم المطابقة واضحًا وقابلًا للتنفيذ والتحقق.", en: "Five elements that make an NCR clear, actionable and verifiable." },
      body: {
        ar: [["p", "التقرير الجيد لا يصف المشكلة فقط، بل يقود إلى إغلاقها بدليل."], ["h", "1. الحقيقة لا الرأي"], ["p", "اكتب ما رأيته: «وُجدت حاوية أرز مطبوخ في الثلاجة 3 بدون ملصق تاريخ» بدل «الثلاجة غير منظمة»."], ["h", "2. المتطلب المخالَف"], ["p", "اذكر الإجراء أو البند الذي لم يُستوفَ، ليعرف القسم ما المطلوب بالضبط."], ["h", "3. الدليل"], ["p", "صورة، رقم الدفعة، قراءة الحرارة، الوقت. الدليل يمنع الجدل ويُسهّل التحقق."], ["h", "4. تصحيح فوري + سبب جذري"], ["p", "التخلص من المنتج تصحيح؛ معرفة لماذا لم يُوضع الملصق هو الطريق للإجراء التصحيحي الحقيقي."], ["h", "5. مسؤول وموعد وتحقق"], ["p", "بلا اسم وتاريخ لا يُغلق شيء. والإغلاق الحقيقي يكون بعد التحقق من الفاعلية لا بعد التوقيع."], ["p", "جرّب «مولد تقرير عدم المطابقة» في صفحة الأدوات لتطبيق هذه العناصر."]],
        en: [["p", "A good report doesn't just describe a problem — it leads to closing it with evidence."], ["h", "1. Facts, not opinions"], ["p", "Write what you saw: \"Cooked rice container in fridge 3 with no date label\" instead of \"fridge is messy\"."], ["h", "2. The requirement not met"], ["p", "Name the procedure or clause, so the department knows exactly what is expected."], ["h", "3. Evidence"], ["p", "Photo, batch number, temperature reading, time. Evidence ends arguments and makes verification easy."], ["h", "4. Immediate correction + root cause"], ["p", "Discarding the product is a correction; finding out why it wasn't labelled leads to the real corrective action."], ["h", "5. Owner, due date, verification"], ["p", "Without a name and a date nothing closes. True closure comes after checking effectiveness, not after a signature."], ["p", "Try the NCR builder in the toolkit to apply these elements."]],
      },
      refs: ["ISO 22000:2018 — clauses 8.9 and 10.1", "ISO 19011:2018 — Guidelines for auditing management systems"],
    },
    {
      id: "thermometer-check", type: "guide", mins: 3, date: "2026-11-04",
      title: { ar: "التحقق السريع من دقة ميزان الحرارة", en: "Quick accuracy check for a probe thermometer" },
      sum: { ar: "طريقة نقطة التجمد وطريقة المقارنة، ومتى تستبدل الجهاز.", en: "The ice-point method, the comparison method, and when to replace the unit." },
      body: {
        ar: [["p", "القراءة الخاطئة أخطر من عدم القراءة، لأنها تعطي ثقة زائفة."], ["h", "طريقة نقطة التجمد"], ["ul", ["املأ كوبًا بثلج مجروش ثم أضف ماءً باردًا وحرّك.", "انتظر دقيقة ثم أدخل المسبار في الوسط دون لمس القاع.", "يجب أن تقترب القراءة من 0°م ضمن السماحية المحددة في إجراءك أو من الشركة المصنعة."]], ["h", "طريقة المقارنة"], ["p", "قِس العينة نفسها بجهازك وبجهاز مرجعي معاير، وسجّل الفرق."], ["h", "عند الفشل"], ["p", "أوقف استخدام الجهاز، اضبطه إن أمكن أو استبدله، وقيّم القراءات التي أُخذت منذ آخر تحقق ناجح."], ["p", "سجّل النتيجة في سجل معايرة الأجهزة."]],
        en: [["p", "A wrong reading is worse than no reading, because it gives false confidence."], ["h", "Ice-point method"], ["ul", ["Fill a cup with crushed ice, top up with cold water and stir.", "Wait a minute, then put the probe in the middle without touching the bottom.", "The reading should be close to 0°C within the tolerance in your procedure or from the manufacturer."]], ["h", "Comparison method"], ["p", "Measure the same sample with your unit and a calibrated reference unit, and record the difference."], ["h", "If it fails"], ["p", "Stop using it, adjust or replace it, and assess readings taken since the last successful check."], ["p", "Record the result in the instrument calibration log."]],
      },
      refs: [refs.who5, "Manufacturer instructions for the instrument in use"],
    },
  ];

  const faq = [
    { q: { ar: "هل الأدوات بديل عن النظام المعتمد في منشأتي؟", en: "Do these tools replace my site's approved system?" }, a: { ar: "لا. الأدوات تعليمية ومساندة، ولا تحل محل التشريعات أو متطلبات الجهات الرقابية أو إجراءات منشأتك المعتمدة.", en: "No. The tools are educational and supportive; they don't replace regulations, authority requirements or your site's approved procedures." } },
    { q: { ar: "أين تُحفظ البيانات التي أدخلها في الأدوات؟", en: "Where is the data I enter in the tools stored?" }, a: { ar: "في متصفحك فقط على جهازك (التخزين المحلي). لا تُرسل إلى أي خادم. يمكنك تصديرها أو حذفها في أي وقت.", en: "Only in your browser on your device (local storage). Nothing is sent to a server. You can export or delete it any time." } },
    { q: { ar: "هل شارات الإتمام في مصباح الجودة شهادة مهنية؟", en: "Are Quality Lamp completion badges a professional certificate?" }, a: { ar: "لا، هي شارات تعليمية لمتابعة تقدمك فقط وليست اعتمادًا مهنيًا.", en: "No — they are learning badges to track your progress, not a professional credential." } },
    { q: { ar: "كيف أقترح مصطلحًا أو أبلغ عن خطأ؟", en: "How do I suggest a term or report an error?" }, a: { ar: "من زر «اقترح مصطلحًا» في القاموس أو من صفحة التواصل. كل اقتراح يخضع لمراجعة تحريرية قبل النشر.", en: "Use \"Suggest a term\" in the dictionary or the contact page. Every suggestion gets an editorial review before publishing." } },
  ];

  const sources = [
    { n: "Codex Alimentarius (FAO/WHO)", u: "https://www.fao.org/fao-who-codexalimentarius/" },
    { n: "Saudi Food & Drug Authority — SFDA", u: "https://www.sfda.gov.sa/" },
    { n: "ISO 22000 — Food safety management", u: "https://www.iso.org/iso-22000-food-safety-management.html" },
    { n: "WHO — Food safety", u: "https://www.who.int/health-topics/food-safety" },
  ];

  /* ---------------- Projects ---------------- */
  const projects = [
    {
      id: "hemo", tag: { ar: "ابتكار منتج", en: "Product innovation" },
      title: { ar: "بسكويت العدس «هيمو» — براءة اختراع", en: "\"Hemo\" lentil-based biscuits — patent" },
      problem: { ar: "تطوير منتج مخبوز ذي قيمة غذائية أعلى باستخدام بقوليات محلية.", en: "Develop a baked product with higher nutritional value using local legumes." },
      role: { ar: "صاحب الفكرة والمطوّر.", en: "Originator and developer." },
      method: { ar: "تطوير الوصفة وتجارب التصنيع ضمن دراسة علوم وتقنية الأغذية.", en: "Recipe development and processing trials within food science studies." },
      result: { ar: "شهادة براءة اختراع من وزارة الملكية الفكرية السودانية.", en: "Patent certificate from the Sudanese Ministry of Intellectual Property." },
      learned: { ar: "التحويل من فكرة مختبرية إلى منتج موثق قانونيًا.", en: "Turning a lab idea into a legally documented product." },
    },
    {
      id: "beverage-qc", tag: { ar: "عمليات الجودة", en: "Quality operations" },
      title: { ar: "مراقبة جودة متعددة الفروع لخدمات المشروبات", en: "Multi-branch quality control for beverage services" },
      problem: { ar: "ضمان وصول المشروبات بالجودة ودرجة الحرارة المطلوبة عبر عدة فروع ومسارات توصيل.", en: "Make sure beverages reach customers at the required quality and temperature across branches and delivery routes." },
      role: { ar: "مسؤول جودة — جولات التفتيش، متابعة الإجراءات التصحيحية، معالجة الشكاوى.", en: "Quality Officer — inspection rounds, corrective-action follow-up, complaint handling." },
      method: { ar: "جولات نظافة دورية، التحقق من جداول التنظيف، إجراءات مبنية على HACCP، تنسيق مع التشغيل وسلسلة الإمداد.", en: "Routine hygiene rounds, cleaning-schedule verification, HACCP-based procedures, coordination with operations and supply chain." },
      result: { ar: "سجلات وتقارير تفتيش جاهزة للتدقيق الداخلي والخارجي.", en: "Inspection records and reports kept ready for internal and external audits." },
      learned: { ar: "الملاحظة التي لا يُتابع إغلاقها تعود في الجولة التالية.", en: "A finding that isn't followed to closure comes back next round." },
    },
    {
      id: "diet-menus", tag: { ar: "تطوير وصفات", en: "Recipe development" },
      title: { ar: "قوائم الوجبات الصحية والعلاجية", en: "Healthy and medical meal menus" },
      problem: { ar: "إنتاج وجبات يومية لبرامج غذائية متخصصة (أندية رياضية، مستشفيات، احتياجات خاصة) بجودة ثابتة.", en: "Produce daily meals for specialised programmes (sports clubs, hospitals, special needs) with consistent quality." },
      role: { ar: "مسؤول جودة — تطوير الوصفات وتطبيق معايير الجودة.", en: "Quality Officer — recipe development and quality standards." },
      method: { ar: "توحيد الوصفات وضبط الحصص، فحوص حرارة وعينات ميكروبيولوجية، تدريب على الحساسية والتوثيق.", en: "Standardised recipes and portions, temperature checks and micro sampling, allergen and documentation training." },
      result: { ar: "تحسين انسيابية الإنتاج وتنظيم المخزون وتقليل الفاقد.", en: "Improved production flow, streamlined inventory and reduced waste." },
      learned: { ar: "الجودة في الوجبات العلاجية تبدأ من دقة الوصفة والملصق.", en: "In medical meals, quality starts with recipe and label accuracy." },
    },
    {
      id: "remote-catering", tag: { ar: "تموين", en: "Catering" },
      title: { ar: "إعاشة مواقع العمل النائية والمناسبات الكبيرة", en: "Remote-site rations and large-event catering" },
      problem: { ar: "الحفاظ على سلامة الغذاء وجودته مع النقل لمسافات طويلة وأعداد كبيرة.", en: "Keep food safe and consistent across long transport and high volumes." },
      role: { ar: "مسؤول جودة — الإنتاج والتخزين والموردين.", en: "Quality Officer — production, storage and suppliers." },
      method: { ar: "مراقبة الجودة والنظافة أثناء الإنتاج والتقديم، دوران المخزون FIFO، متابعة التوريدات.", en: "QC and hygiene through production and service, FIFO stock rotation, supplier delivery checks." },
      result: { ar: "تسليم في الوقت المحدد بجودة ثابتة.", en: "On-time delivery with consistent quality." },
      learned: { ar: "التخطيط المسبق للحرارة والزمن أهم من أي فحص لاحق.", en: "Planning time and temperature up front beats any later check." },
    },
    {
      id: "digital", tag: { ar: "أدوات رقمية", en: "Digital tools" },
      title: { ar: "أدوات رقمية للجودة بمساعدة الذكاء الاصطناعي", en: "AI-assisted digital quality tools" },
      problem: { ar: "الأعمال الورقية الروتينية تأخذ وقتًا من التفتيش الميداني.", en: "Routine paperwork takes time away from field inspection." },
      role: { ar: "مصمم ومطوّر الفكرة.", en: "Concept designer and builder." },
      method: { ar: "استخدام مساعدات الذكاء الاصطناعي وهندسة الأوامر لإعداد التقارير والقوائم والمواد التدريبية، مع مراجعة المخرجات قبل الاعتماد. مصباح الجودة وأدواته جزء من هذا المسار.", en: "Using AI assistants and prompt engineering to draft reports, checklists and training material, with every output reviewed before use. Quality Lamp and its toolkit are part of this work." },
      result: { ar: "قوائم فحص ونماذج رقمية قابلة للطباعة في هذا الموقع.", en: "Printable digital checklists and forms on this site." },
      learned: { ar: "الذكاء الاصطناعي يسرّع الكتابة، لكن التحقق الفني مسؤولية المختص.", en: "AI speeds up writing, but technical verification stays the professional's job." },
    },
  ];

  return { REVIEWED, profile, modules, paths, cats, dict, articles, faq, sources, projects };
})();
