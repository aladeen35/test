/* ============================================================
   هاف مليون ½M — التعريب/الترجمة (عربي ⇄ English)
   - العربية هي لغة المصدر في الكود، والإنجليزية تُطبَّق عبر:
     1) tx(ar,en) للنصوص المركّبة برمجيًا
     2) قاموس + مراقب DOM يترجم النصوص الثابتة بعد كل رسم
   ============================================================ */

function lang(){ try{ return localStorage.getItem("hm-lang")||"ar"; }catch(e){ return "ar"; } }
function isEn(){ return lang()==="en"; }
function tx(ar,en){ return isEn() ? en : ar; }

const DAYS_EN=["Sunday","Monday","Tuesday","Wednesday","Thursday"];
function dayName(i){ return isEn() ? (DAYS_EN[i]??"") : (["الأحد","الاثنين","الثلاثاء","الأربعاء","الخميس"][i]??""); }
/* اسم الفرع حسب اللغة */
function bName(b){ return b ? (isEn() ? (b.nameEn||b.nameAr) : b.nameAr) : "؟"; }
function stopName(st){ return isEn() ? (st.nameEn||st.nameAr) : st.nameAr; }
function visitName(v){
  const b=state.branches.find(x=>x.id===v.branchId);
  return b ? bName(b) : v.nameAr;
}

function setLang(l){
  try{ localStorage.setItem("hm-lang", l); }catch(e){}
  applyLang();
  if(typeof render==="function") render();
}
function applyLang(){
  const en=isEn();
  document.documentElement.lang = en?"en":"ar";
  document.documentElement.dir  = en?"ltr":"rtl";
  document.title = en ? "Half Million ½M — Smart Visit Planner" : "هاف مليون ½M — مخطط الزيارات الذكي";
  const lb=document.getElementById("lang-btn");
  if(lb) lb.textContent = en ? "ع" : "EN";
  if(en) translateTree(document.body);
}

/* ============ القاموس: عربي ← إنجليزي (مطابقة تامة لكل مقطع نصي) ============ */
const I18N_EN = {
  /* التنقل والرأس */
  "الخطة":"Plan","الفروع":"Branches","الخريطة":"Map","الذكاء":"AI","اللوحة":"Dashboard","الإعدادات":"Settings",
  "الخطة الأسبوعية":"Weekly Plan","توليد وتتبع مسار زياراتك":"Generate & track your visit route",
  "إدارة الفروع":"Branch Management","78+ فرعًا عبر المملكة":"78+ branches across KSA",
  "مسارات الأيام والفروع":"Day routes & branches",
  "المساعد الذكي ✦":"AI Assistant ✦","رؤى وتقارير بالذكاء الاصطناعي":"AI-powered insights & reports",
  "لوحة الزيارات":"Visits Dashboard","مؤشرات ونتائج الفحص":"KPIs & inspection results",
  "المواقع والتنبيهات والمزامنة":"Locations, alerts & sync",
  "هاف مليون — مخطط الزيارات":"Half Million — Visit Planner",

  /* الخطة */
  "توليد الخطة الأسبوعية":"Generate Weekly Plan",
  "💡 حدّد موقع الانطلاق ومقر اجتماع الأحد من تبويب الإعدادات لنتائج أدق":"💡 Set your start location and Sunday meeting venue in Settings for better results",
  "تعديل":"Edit","إنهاء التعديل":"Done Editing","مشاركة":"Share","صورة":"Image","حذف":"Delete",
  "لا توجد زيارات مجدولة":"No visits scheduled",
  "لا توجد خطة بعد":"No plan yet",
  "اضغط \"توليد الخطة الأسبوعية\" وسيوزّع التطبيق فروعك على أيام الأسبوع بأقصر مسار قيادة":"Tap \"Generate Weekly Plan\" and the app will distribute your branches across the week with the shortest driving route",
  "أنا وصلت":"I've arrived","ملاحة":"Navigate","الموقع":"Location",
  "إنهاء الزيارة":"End Visit","أكمل البيانات":"Complete Data","تعديل البيانات":"Edit Data",
  "📋 اجتماع الفريق ثم الانطلاق من المقر":"📋 Team meeting, then depart from venue",
  "وضع التعديل:":"Edit mode:",
  "اسحب ⠿ لإعادة ترتيب الزيارات داخل اليوم أو أفلِتها فوق يوم آخر، أو استخدم قائمة \"نقل إلى\". التوقيتات تُعاد حسابها تلقائيًا.":"Drag ⠿ to reorder visits within a day or drop onto another day, or use the \"Move to\" menu. Times recalculate automatically.",
  "الملاحة النشطة":"Start Navigation","لاحقًا":"Later",
  "حان وقت الانطلاق إلى":"Time to head to",

  /* المهام الأسبوعية */
  "المهام الأسبوعية":"Weekly Tasks","إضافة مهمة":"Add Task",
  "أضف مهامًا تُقيَّم في كل زيارة بمقياس":"Add tasks graded on every visit with",
  "مثل \"التحقق من نكهة قهوة التقطير\" أو \"صلاحية الحليب\". مهام الفريق تصل لجميع الأعضاء تلقائيًا.":"e.g. \"Check drip coffee flavor\" or \"Milk expiry\". Team tasks reach all members automatically.",
  "👥 فريق":"👥 Team","محلية":"Local","هذا الأسبوع فقط":"This week only",
  "أضافها:":"Added by:","تعطيل":"Disable","تفعيل":"Enable","معطّلة":"Disabled","انتهى أسبوعها":"Week ended",
  "📋 مهمة أسبوعية جديدة":"📋 New Weekly Task","حفظ المهمة":"Save Task",
  "📝 وصف المهمة":"📝 Task description",
  "مثال: التحقق من نكهة قهوة التقطير":"e.g. Check drip coffee flavor",
  "تفاصيل إضافية (اختياري)":"Extra details (optional)",
  "النطاق":"Scope","كل الفريق":"Whole team","هذا الجهاز فقط":"This device only",
  "💡 فعّل نظام الفريق من الإعدادات لإرسال المهام لكل الأعضاء":"💡 Enable Team System in Settings to send tasks to all members",
  "التكرار":"Recurrence","كل أسبوع حتى أعطّلها":"Every week until disabled",
  "تظهر المهمة في نموذج كل زيارة وتُقيَّم:":"The task appears in every visit form and is graded:",
  "مطابق تمامًا ·":"Fully conforming ·","متوسط/به ملاحظة ·":"Average / has remark ·","مخالف تمامًا (تتطلب ملاحظة)":"Fully non-conforming (requires a note)",
  "المهام الأسبوعية — قيّم كل مهمة":"Weekly tasks — grade each one",
  "A · مطابق تمامًا":"A · Conforming","B · متوسط":"B · Average","C · مخالف تمامًا":"C · Non-conforming","لا ينطبق":"N/A",
  "ملاحظة (إلزامية عند C)":"Note (required for C)",
  "نتائج المهام الأسبوعية":"Weekly Task Results","A مطابق · B متوسط · C مخالف":"A conforming · B average · C non-conforming",

  /* نموذج الزيارة */
  "✅ تأكيد زيارة الفرع":"✅ Confirm Branch Visit","حفظ بيانات الزيارة":"Save Visit Data",
  "⏱ وقت الزيارة (اختياري — للتعديل اليدوي)":"⏱ Visit time (optional — manual override)",
  "وقت الوصول":"Arrival time","المدة (دقيقة)":"Duration (min)",
  "نتائج الفحص (إلزامية)":"Inspection results (required)",
  "قراءات الجودة (اختيارية)":"Quality readings (optional)",
  "ملاحظات (اختيارية)":"Notes (optional)","أي ملاحظات عن الزيارة…":"Any notes about the visit…",

  /* الفروع */
  "إضافة فرع يدويًا":"Add Branch Manually","تصدير Excel":"Export Excel",
  "استيراد فروع من ملف Excel":"Import branches from Excel",
  "اسحب الملف هنا أو اضغط للاختيار — أعمدة: الاسم، lat، lng، الحجم":"Drop the file here or tap to choose — columns: name, lat, lng, size",
  "ابحث عن فرع… (مثال: الرياض، النرجس)":"Search branches… (e.g. Riyadh, Narjis)",
  "كبير · 120د":"Large · 120m","صغير · 90د":"Small · 90m","كبير 120د":"Large 120m","صغير 90د":"Small 90m",
  "➕ إضافة فرع يدويًا":"➕ Add Branch Manually","حفظ الفرع":"Save Branch",
  "📝 بيانات الفرع":"📝 Branch details",
  "اسم الفرع (مدينة، حي، شارع)":"Branch name (city, district, street)","المنطقة (مثال: الرياض)":"Region (e.g. Riyadh)",
  "📍 تحديد الموقع — اختر طريقة":"📍 Set location — choose a method",
  "1) رابط خرائط جوجل":"1) Google Maps link",
  "ألصق رابط الموقع من تطبيق خرائط جوجل (يحتوي إحداثيات مثل @24.7,46.6)":"Paste the location link from Google Maps (contains coords like @24.7,46.6)",
  "استخراج":"Extract","2) العنوان الوطني الموحّد":"2) Saudi National Address",
  "4 أحرف + 4 أرقام (مثال: RRRA2929) — يفتح خرائط جوجل للبحث عنه ثم ألصق الرابط في الخانة أعلاه":"4 letters + 4 digits (e.g. RRRA2929) — opens Google Maps search, then paste the link above",
  "🔍 بحث":"🔍 Search","3) إحداثيات مباشرة":"3) Direct coordinates",
  "📍 استخدام موقعي الحالي":"📍 Use my current location",

  /* الخريطة */
  "الكل":"All",
  "تعذّر تحميل مكتبة الخرائط":"Couldn't load the map library",
  "يبدو أن الاتصال بالإنترنت محجوب أو ضعيف — أعد المحاولة عند توفر الشبكة، بقية التطبيق يعمل دون اتصال.":"Internet seems blocked or weak — retry when back online. The rest of the app works offline.",
  "🗺️ يبدو أن هذه المعاينة تحجب صور الخرائط. العلامات والمسارات تعمل، وستظهر الشوارع كاملة عند فتح التطبيق كموقع ويب.":"🗺️ This preview blocks map tiles. Markers and routes work; streets appear when the app is hosted.",
  "🧭 الملاحة":"🧭 Navigate","⏱ زيارة جارية":"⏱ Visit in progress","✓ تمت الزيارة":"✓ Visited",

  /* الذكاء */
  "مساعد ½M الذكي":"½M AI Assistant",
  "جديد:":"New:",
  "إعداد الذكاء":"AI Setup","إخفاء الإعداد":"Hide Setup","مسح المحادثة":"Clear Chat",
  "⚙️ إعداد الاتصال بـ Claude":"⚙️ Connect to Claude",
  "مفتاح Anthropic API":"Anthropic API key","النموذج":"Model",
  "💾 حفظ واختبار الاتصال":"💾 Save & Test Connection","نسيان المفتاح":"Forget Key",
  "رؤى فورية":"Instant Insights","(تُحسب على جهازك دون إنترنت)":"(computed on-device, offline)",
  "اسأل المساعد":"Ask the Assistant","جدول من قائمة فروع":"Schedule from a list",
  "تقرير أسبوعي تنفيذي":"Executive weekly report","أولويات الأسبوع القادم":"Next week priorities",
  "تحليل قراءات الجودة":"Analyze quality readings","لخّص خطة الأسبوع":"Summarize this week's plan",
  "ابدأ محادثة":"Start a conversation",
  "اكتب سؤالك عن الفروع أو الخطة أو الزيارات…":"Ask about branches, plans or visits…",
  "اسأل عن الفروع… أو ألصق قائمة أسماء لبناء الجدول":"Ask anything… or paste a list of branch names to build a schedule",
  "قد يخطئ الذكاء الاصطناعي — راجع الأرقام المهمة قبل اعتمادها":"AI can make mistakes — verify important numbers",
  "📋 نسخ":"📋 Copy","↗ مشاركة":"↗ Share",
  "إنشاء جدول من قائمتك":"Build schedule from your list",
  "أي فرع تقصد؟":"Which branch do you mean?","فرع غير معروف":"Unknown branch",
  "إضافته كفرع جديد":"Add as new branch","تجاهل":"Skip","استرجاع":"Restore","تغيير":"Change",

  /* اللوحة */
  "بياناتي":"My Data","الفريق":"Team","تقرير ذكي":"AI Report","تحديث":"Refresh",
  "هذا الأسبوع":"This Week","الأسبوع الماضي":"Last Week",
  "كل الحالات":"All States","مكتملة ✓":"Complete ✓","بيانات ناقصة":"Incomplete","جارية ⏱":"Open ⏱",
  "فلترة باسم الفرع…":"Filter by branch name…",
  "زيارة":"Visits","مكتملة البيانات":"Data complete","أعضاء الفريق":"Team members",
  "متوسط PH":"Avg PH","متوسط TDS":"Avg TDS","ساعات الزيارات":"Visit hours",
  "توزيع الزيارات على أيام الأسبوع":"Visits by weekday",
  "توزيع المخالفات حسب الدرجة":"Findings by severity",
  "سجل الزيارات":"Visit Log",
  "لا توجد زيارات ضمن هذا الفلتر":"No visits match this filter",
  "سجّل وصولك من صفحة الخطة بزر \"✅ أنا وصلت\" وستظهر هنا نتائج الفحص والمؤشرات":"Check in from the Plan tab with \"I've arrived\" and results will appear here",
  "لا توجد زيارات فريق ضمن هذا الفلتر":"No team visits match this filter",
  "تأكد أن زملاءك فعّلوا نظام الفريق بنفس الرمز والمفتاح، وأنهم سجّلوا زيارات":"Make sure teammates enabled Team System with the same bin & key, and logged visits",
  "الفرع":"Branch","اليوم":"Day","التاريخ":"Date","المدة":"Duration","الحالة":"Status","العضو":"Member",
  "لا مخالفات مسجلة ضمن هذا الفلتر 🎉":"No findings in this filter 🎉",
  "كل الأعضاء":"All members",

  /* الإعدادات */
  "🎨 المظهر":"🎨 Appearance","تلقائي":"Auto","☀️ فاتح":"☀️ Light","🌙 داكن":"🌙 Dark",
  "🌐 اللغة":"🌐 Language",
  "🏠 موقع الانطلاق (المنزل)":"🏠 Start location (home)",
  "📋 مقر اجتماع الأحد الأسبوعي":"📋 Sunday weekly meeting venue",
  "اسم المقر (مثال: المكتب الرئيسي — الرياض)":"Venue name (e.g. HQ — Riyadh)",
  "🕘 ساعات العمل":"🕘 Working hours","بداية الدوام":"Start of day","نهاية الدوام":"End of day",
  "متوسط سرعة القيادة (كم/س) — لتقدير أزمنة التنقل":"Average driving speed (km/h) — for travel time estimates",
  "أقصى عدد فروع في اليوم الواحد (0 = بلا حد)":"Max branches per day (0 = unlimited)",
  "🔔 تنبيهات الانطلاق":"🔔 Departure alerts","تفعيل التنبيهات":"Enable alerts",
  "التنبيه قبل موعد الوصول بـ:":"Alert before scheduled arrival by:",
  "💡 التنبيهات تعمل أثناء فتح التطبيق في المتصفح.":"💡 Alerts work while the app is open in the browser.",
  "☁️ المزامنة الأونلاين الدائمة":"☁️ Always-on Cloud Sync",
  "تفعيل المزامنة":"Enable sync","مفتاح JSONBin (X-Master-Key)":"JSONBin key (X-Master-Key)",
  "رمز الصندوق (Bin ID) — اتركه فارغًا لإنشاء صندوق جديد":"Bin ID — leave empty to create a new bin",
  "🔗 ربط / إنشاء صندوق":"🔗 Connect / Create bin","⬇️ جلب من السحابة":"⬇️ Pull from cloud",
  "نظام الفريق":"Team System","تفعيل نظام الفريق":"Enable Team System",
  "اسمك (كما سيظهر للفريق)":"Your name (as shown to the team)","مثال: علاء الدين":"e.g. Alaa",
  "مفتاح JSONBin المشترك (X-Master-Key)":"Shared JSONBin key (X-Master-Key)",
  "رمز صندوق الفريق — اتركه فارغًا لإنشاء فريق جديد":"Team bin ID — leave empty to create a new team",
  "يرسله لك قائد الفريق":"Your team lead shares it",
  "إنشاء / انضمام":"Create / Join","اختبار الجلب":"Test Fetch",
  "أنا مدير الفريق (يُظهر أدوات إدارة مهام الفريق)":"I'm the team manager (shows team-task admin tools)",
  "🔗 تحميل خطة مشتركة":"🔗 Load a shared plan",
  "أدخل رمز الخطة الذي شاركه معك زميلك":"Enter the plan code your teammate shared",
  "تحميل":"Load",

  /* المعالج والنوافذ العامة */
  "✨ خيارات توليد الخطة":"✨ Plan Generation Options","توليد الخطة":"Generate Plan",
  "🚗 نقطة الانطلاق في الأيام العادية (غير يوم الاجتماع)":"🚗 Start point on regular days (non-meeting days)",
  "المنزل":"Home","مقر الاجتماع الأسبوعي":"Weekly meeting venue","موقع مخصص":"Custom location",
  "أدخل الإحداثيات يدويًا":"Enter coordinates manually",
  "حدّده من الإعدادات أو سيُستخدم مركز الفروع":"Set it in Settings, or the branches centroid is used",
  "حدّده من الإعدادات":"Set it in Settings",
  "⚡ متوسط سرعة القيادة":"⚡ Average driving speed",
  "☕ الفروع الموكلة إليّ هذا الأسبوع":"☕ My assigned branches this week",
  "ابحث عن فرع…":"Search branches…","تحديد الكل":"Select all","إلغاء الكل":"Clear all",
  "جارٍ حساب المسار الأمثل…":"Computing optimal route…",
  "إلغاء":"Cancel",

  /* مقاطع متفرقة */
  "يقرأ فروعك وخطتك وسجل زياراتك ليجيب عن أسئلتك ويكتب تقاريرك.":"Reads your branches, plan and visit log to answer questions and write your reports.",
  "أرسل قائمة بأسماء فروعك — حتى بالإنجليزية مثل":"Send a list of your branch names — even in English like",
  "— وسيبني جدول أسبوعك فورًا.":"— and it builds your weekly schedule instantly.",
  "○ الدردشة الذكية غير مفعّلة — الجدولة بالقائمة تعمل دون مفتاح":"○ AI chat not set up — list scheduling works without a key",
  "أنشئ مفتاح API من":"Create an API key at","وألصقه هنا.":"and paste it here.",
  "يُحفظ المفتاح على جهازك فقط ولا يُرفع أبدًا مع المزامنة السحابية.":"The key is stored on this device only and is never uploaded with cloud sync.",
  "اسأل: \"ما أكثر فرع سجّل مخالفات؟\"":"Ask: \"Which branch logged the most findings?\"",
  "أو أرسل قائمة:":"Or send a list:","لبناء جدولك":"to build your schedule",
  "جارٍ اختبار الاتصال…":"Testing connection…","ألصق المفتاح أولاً":"Paste the key first",
  "جارٍ الإرسال للفريق…":"Sending to team…","اكتب عنوان المهمة":"⚠️ Enter a task title",
  "· معطّل":"· disabled","معطّل":"disabled","نشط":"active",
  "إجمالي القيادة":"total driving",
  "أدخل اسمك أولاً":"Enter your name first","أدخل مفتاح JSONBin المشترك":"Enter the shared JSONBin key",
  "جارٍ الاتصال…":"Connecting…","جارٍ الجلب…":"Fetching…","جارٍ الرفع…":"Uploading…","جارٍ البحث…":"Searching…","جارٍ الاستيراد…":"Importing…",
  "انضممت للفريق ورُفعت زياراتك ✓":"Joined the team and uploaded your visits ✓",
  "تعذّر الاتصال — تحقق من المفتاح والرمز":"Connection failed — check the key and bin ID",
  "أكمل الاسم والمفتاح والرمز أولاً":"Complete name, key and bin ID first",
  "تعذّر الجلب — تحقق من المفتاح والرمز":"Fetch failed — check the key and bin ID",
  "تعذّر جلب بيانات الفريق — تحقق من المفتاح والرمز":"Could not fetch team data — check the key and bin ID",
  "إعادة المحاولة":"Retry",
  "تم تحميل الخطة ✓ — انتقل لتبويب الخطة":"Plan loaded ✓ — go to the Plan tab",
  "لم يُعثر على خطة بهذا الرمز":"No plan found with this code",
  "تم الربط والمزامنة ✓ — رمز صندوقك:":"Connected & synced ✓ — your bin ID:",
  "تعذّر الربط — تحقق من صحة المفتاح":"Connection failed — verify the key",
  "أدخل مفتاح JSONBin أولاً":"Enter the JSONBin key first",
  "أدخل المفتاح ورمز الصندوق":"Enter the key and bin ID",
  "تم جلب البيانات ومزامنتها ✓":"Data fetched and synced ✓",
  "تعذّر الرفع — سيُعاد عند التعديل التالي":"Upload failed — will retry on next change",
  "تعذّر جلب البيانات — تحقق من الرمز والمفتاح":"Fetch failed — check the bin ID and key",
  "تعذّر الرفع للفريق — سيُعاد عند التعديل التالي":"Team upload failed — will retry on next change",
  "احفظ بياناتك سحابيًا وزامنها بين كل أجهزتك تلقائيًا. مجاني عبر خدمة JSONBin.io — أنشئ حسابًا مجانيًا وانسخ منه مفتاح":"Save your data to the cloud and sync it across devices automatically. Free via JSONBin.io — create a free account and copy your",
  "اجمع نتائج زيارات كل أعضاء الفريق في لوحة واحدة. ينشئ قائد الفريق صندوقًا ويشارك":"Merge every team member's visit results into one dashboard. The team lead creates a bin and shares the",
  "المفتاح":"key","ورمز الصندوق":"and bin ID","مع الأعضاء — كلٌ يرفع زياراته وتُدمج للجميع في تبويب اللوحة.":"with members — everyone uploads their visits and they merge for all in the Dashboard tab.",
  "بعد الربط على جهاز، أدخل نفس المفتاح ورمز الصندوق على أجهزتك الأخرى واضغط \"جلب من السحابة\".":"After connecting on one device, enter the same key and bin ID on your other devices and tap \"Pull from cloud\".",
  "ملاحظة:":"Note:","مفتاح الذكاء الاصطناعي لا يُزامن أبدًا ويبقى على جهازك.":"The AI key never syncs and stays on your device.",
  "⚠️ أدخل أعداد Critical و Major و Minor (ضع 0 إن لم توجد)":"⚠️ Enter Critical, Major and Minor counts (use 0 if none)",
  "⚠️ قيّم كل المهام الأسبوعية (A/B/C أو لا ينطبق)":"⚠️ Grade all weekly tasks (A/B/C or N/A)",
  "⚠️ اكتب عنوان المهمة":"⚠️ Enter a task title",
  "⚠️ أدخل اسم الفرع":"⚠️ Enter the branch name",
  "⚠️ حدّد الموقع بإحدى الطرق الثلاث أعلاه":"⚠️ Set the location using one of the three methods above",
  "⚠️ تعذّر استخراج إحداثيات من هذا الرابط — جرّب نسخ الرابط الكامل أو أدخل الإحداثيات يدويًا":"⚠️ Could not extract coordinates — copy the full link or enter coordinates manually",
  "⚠️ صيغة العنوان الوطني: 4 أحرف + 4 أرقام (مثال RRRA2929)":"⚠️ National address format: 4 letters + 4 digits (e.g. RRRA2929)",
  "تعذّر تحديد الموقع":"Could not get location",
  "لم يُعثر على فروع بإحداثيات صالحة في الملف":"No branches with valid coordinates found in the file",
  "تعذّرت قراءة الملف — تأكد أنه بصيغة .xlsx":"Could not read the file — make sure it is .xlsx",
  "جارية":"Open","مكتملة":"Complete","ناقصة":"Incomplete",
  "✏️ تعديل البيانات":"✏️ Edit Data","📝 أكمل البيانات":"📝 Complete Data","⏹ إنهاء الزيارة":"⏹ End Visit",
  "⏱ جارية":"⏱ Open","✓ مكتملة":"✓ Complete","⚠ ناقصة":"⚠ Incomplete",
  "✓ تمت ·":"✓ Done ·","بيانات ناقصة":"Incomplete data",
  "⏱ أُغلقت تلقائيًا — أكمل البيانات":"⏱ Auto-closed — complete the data",
};

/* أنماط ديناميكية (نصوص تحوي أرقامًا) */
const I18N_PATTERNS = [
  [/^توليد الخطة \((\d+) فرعًا\)$/, m=>`Generate Plan (${m[1]} branches)`],
  [/^توليد الجدول \((\d+)\)$/, m=>`Generate Schedule (${m[1]})`],
  [/^(\d+) جاهز(?: · (\d+) بانتظار قرارك)?$/, m=>`${m[1]} ready${m[2]?` · ${m[2]} awaiting your call`:""}`],
  [/^الخطط السابقة \((\d+)\)$/, m=>`Previous plans (${m[1]})`],
  [/^(\d+) من (\d+) زيارة مكتملة ·\s*$/, m=>`${m[1]} of ${m[2]} visits complete · `],
  [/^إجمالي القيادة$/, ()=>`total driving`],
  [/^أسبوع (.+)$/, m=>`Week of ${m[1]}`],
  [/^كل الأعضاء \((\d+)\)$/, m=>`All members (${m[1]})`],
  [/^سجل الزيارات$/, ()=>"Visit Log"],
  [/^● متصل · (.+)$/, m=>`● Connected · ${m[1]}`],
  [/^حان وقت الانطلاق إلى (.+)!$/, m=>`Time to head to ${m[1]}!`],
  [/^✓ من الخريطة: (.+) — اكتب اسم الفرع واحفظ$/, m=>`✓ From the map: ${m[1]} — enter the branch name and save`],
  [/^📍 اضغط على موقع الفرع الجديد في الخريطة —\s*$/, ()=>"📍 Tap the new branch location on the map — "],
  [/^مهمة "(.+)" مخالفة \(C\) — اكتب ملاحظة توضح المخالفة$/, m=>`Task "${m[1]}" is non-conforming (C) — add a note explaining it`],
  [/^⚠️ مهمة "(.+)" مخالفة \(C\) — اكتب ملاحظة توضح المخالفة$/, m=>`⚠️ Task "${m[1]}" is non-conforming (C) — add a note explaining it`],
  [/^متصل ✓ — (\d+) عضو: (.*)$/, m=>`Connected ✓ — ${m[1]} members: ${m[2]}`],
  [/^أُنشئ فريق جديد ✓ — شارك المفتاح والرمز مع أعضائك: (.+)$/, m=>`New team created ✓ — share the key and bin ID with members: ${m[1]}`],
  [/^مُزامَن ✓ (.+)$/, m=>`Synced ✓ ${m[1]}`],
  [/^مُزامَن مع الفريق ✓ (.+)$/, m=>`Team synced ✓ ${m[1]}`],
  [/^لا أعضاء بعد$/, ()=>"no members yet"],
  [/^أضافها: (.+)$/, m=>`Added by: ${m[1]}`],
  [/^⏱ (\d+)د \/ (\d+)د$/, m=>`⏱ ${m[1]}m / ${m[2]}m`],
];

function trStr(txt){
  const trimmed=txt.trim();
  if(!trimmed || !/[؀-ۿ]/.test(trimmed)) return null;
  let out=I18N_EN[trimmed];
  if(out==null){
    for(const [re,fn] of I18N_PATTERNS){
      const m=trimmed.match(re);
      if(m){ out=fn(m); break; }
    }
  }
  if(out==null) return null;
  return txt.replace(trimmed, out);
}

const TR_ATTRS=["placeholder","aria-label","title"];
function translateTree(root){
  if(!isEn() || !root) return;
  const walker=document.createTreeWalker(root, NodeFilter.SHOW_TEXT|NodeFilter.SHOW_ELEMENT);
  let node=walker.currentNode;
  while(node){
    if(node.nodeType===3){
      const tr=trStr(node.nodeValue);
      if(tr!=null) node.nodeValue=tr;
    } else if(node.nodeType===1){
      for(const a of TR_ATTRS){
        const v=node.getAttribute?.(a);
        if(v){ const tr=trStr(v); if(tr!=null) node.setAttribute(a,tr); }
      }
    }
    node=walker.nextNode();
  }
}

/* مراقب يترجم كل ما يُرسم بعد الآن (توست، نوافذ، تبويبات) */
new MutationObserver(muts=>{
  if(!isEn()) return;
  for(const m of muts){
    for(const n of m.addedNodes){
      if(n.nodeType===3){ const tr=trStr(n.nodeValue); if(tr!=null) n.nodeValue=tr; }
      else if(n.nodeType===1) translateTree(n);
    }
    if(m.type==="characterData"){ const tr=trStr(m.target.nodeValue); if(tr!=null) m.target.nodeValue=tr; }
  }
}).observe(document.documentElement,{childList:true,subtree:true,characterData:true});
