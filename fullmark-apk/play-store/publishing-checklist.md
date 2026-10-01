# دليل النشر على Google Play — فول مارك

خطوات مرتّبة من الصفر حتى أول إصدار عام، ثم طريقة إصدار التحديثات. ضع ✅ أمام كل خطوة تنتهي منها.

**بيانات ثابتة ستحتاجها:**

| البند | القيمة |
|---|---|
| اسم التطبيق | فول مارك - مسابقة العائلة |
| اسم الحزمة (Package) | `com.albushra.fullmark` (لا يمكن تغييره بعد أول رفع) |
| المطوّر | البشرى للتكنولوجيا — Al-Bushra Technology |
| الفئة | Game → Trivia |
| السعر | مجاني (لا يمكن تحويله إلى مدفوع لاحقًا) |
| البريد | `Aladeen35@gmail.com` |
| رابط سياسة الخصوصية | https://github.com/aladeen35/test/blob/claude/ui-ux-pro-max-skill-n9hipq/fullmark-apk/play-store/PRIVACY.md |

**ملفات هذا المجلد:**
`listing-ar.md` · `listing-en.md` · `data-safety.md` · `content-rating.md` · `target-audience.md` · `PRIVACY.md` · `screenshots/`

---

## الخطوة 0 — قبل أي شيء: جهّز البناء

- [ ] استبدل `Aladeen35@gmail.com` ببريد حقيقي في: `fullmark/config.js`، و`PRIVACY.md`، و`fullmark/privacy.html` (وفي ملفات هذا المجلد عند النسخ إلى Console). زر «الإبلاغ عن الرد» يعتمد عليه.
- [ ] تأكّد أن `AndroidManifest.xml` يحتوي الصلاحيات المذكورة فقط: `INTERNET`، `BLUETOOTH_CONNECT`، `BLUETOOTH` و`BLUETOOTH_ADMIN` (بـ `maxSdkVersion="30"`)، `RECORD_AUDIO`، `VIBRATE`. أي صلاحية إضافية يجب أن تُذكر في سياسة الخصوصية و`data-safety.md`.
- [ ] تأكّد أن **مستوى API المستهدف (targetSdk)** يطابق متطلب Google الحالي للتطبيقات الجديدة (Capacitor 8 يستهدف API 36). ⚠️ تحقّق من المتطلب الحالي في صفحة «Target API level requirements».
- [ ] إذا استخدمت الخادم الوسيط للذكاء الاصطناعي، فرابطه في `config.js` يبدأ بـ `https://` ولا يسجّل الطلبات.
- [ ] جرّب نسخة الإصدار على جوال حقيقي: كل أوضاع اللعب، البلوتوث، الميكروفون، زر «مسح السجلات»، وزر «الإبلاغ عن الرد».

> ✅ **البناء جاهز:** سير العمل `.github/workflows/fullmark-apk.yml` يبني `FullMark.aab` (للمتجر) و`FullMark.apk`، و`versionCode` = رقم تشغيل CI فيزيد تلقائياً مع كل بناء. معرّف التطبيق: `com.albushra.fullmark`.
>
> **التوقيع التلقائي بمفتاح الرفع** — أضف هذه الأسرار مرة واحدة في GitHub: المستودع ← Settings ← Secrets and variables ← Actions ← New repository secret:
>
> | الاسم | القيمة |
> |---|---|
> | `FM_KEYSTORE_B64` | محتوى الملف `fullmark-upload.jks.b64` كاملاً |
> | `FM_KEYSTORE_PASSWORD` | كلمة المرور (ملف `password.txt`) |
> | `FM_KEY_ALIAS` | `fullmark-upload` |
> | `FM_KEY_PASSWORD` | نفس كلمة المرور |
>
> بعدها كل بناء يخرج AAB وAPK موقّعين جاهزين للرفع. **احتفظ بملف المفتاح وكلمة المرور في مكان آمن خارج المستودع** — ضياعه يتطلب طلب إعادة تعيين مفتاح الرفع من دعم Google Play.

---

## الخطوة 1 — إنشاء حساب مطوّر Google Play

- [ ] ادخل إلى https://play.google.com/console وسجّل بحساب Google خاص بالشركة (ليس حسابًا شخصيًا يوميًا).
- [ ] اختر نوع الحساب:
  - **مؤسسة (Organization):** إذا كانت «البشرى للتكنولوجيا» شركة مسجّلة. يتطلب **رقم D-U-N-S** (مجاني من Dun & Bradstreet، وقد يستغرق أيامًا). **ميزته الكبرى: لا ينطبق عليه شرط الاختبار المغلق بـ 12 مختبرًا لمدة 14 يومًا.**
  - **شخصي (Personal):** أسرع، لكن ينطبق عليه شرط الاختبار المغلق (الخطوة 10).
- [ ] ادفع رسوم التسجيل لمرة واحدة (25 دولارًا أمريكيًا).
- [ ] أكمل **التحقق من الهوية** (هوية/سجل تجاري، والعنوان، ورقم الهاتف والبريد). قد يستغرق التحقق عدة أيام.
- [ ] اكتب اسم المطوّر الذي سيظهر في المتجر: **البشرى للتكنولوجيا** (أو Al-Bushra Technology).

---

## الخطوة 2 — إنشاء التطبيق في Console

- [ ] **Home → Create app**.
- [ ] App name: `فول مارك - مسابقة العائلة`
- [ ] Default language: **العربية – ar**
- [ ] App or game: **Game**
- [ ] Free or paid: **Free**
- [ ] وافق على الإقرارات (Developer Program Policies، وقوانين التصدير الأمريكية) ثم **Create app**.

---

## الخطوة 3 — توقيع التطبيق (Play App Signing) ومفتاح الرفع

نظام Google الحالي: **Google تحتفظ بمفتاح توقيع التطبيق** (app signing key)، وأنت توقّع ملفات الرفع بـ **مفتاح الرفع** (upload key) فقط.

- [ ] أنشئ مفتاح الرفع مرة واحدة على جهازك (إن لم يكن موجودًا):
  ```
  keytool -genkeypair -v -keystore fullmark-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
  ```
- [ ] **احفظ الملف `fullmark-upload.jks` وكلمتي المرور في مكان آمن مع نسخة احتياطية.** لا ترفعه إلى المستودع أبدًا.
- [ ] أضفه إلى أسرار GitHub (Settings → Secrets and variables → Actions) ليوقّع CI ملف AAB، مثلًا:
  `ANDROID_UPLOAD_KEYSTORE_BASE64` (الملف بصيغة base64)، `ANDROID_UPLOAD_KEYSTORE_PASSWORD`، `ANDROID_UPLOAD_KEY_ALIAS`، `ANDROID_UPLOAD_KEY_PASSWORD`. (استخدم الأسماء التي يقرؤها سير العمل فعليًا.)
- [ ] عند أول رفع لملف AAB ستُفعَّل **Play App Signing** تلقائيًا؛ اختر أن تُنشئ Google مفتاح توقيع التطبيق (الخيار الافتراضي المُوصى به).
- [ ] إذا ضاع مفتاح الرفع لاحقًا: يمكن طلب إعادة تعيينه من **Test and release → Setup → App signing** (هذه ميزة Play App Signing)، لكن احرص ألا تحتاجها.

---

## الخطوة 4 — صفحة المتجر (Store listing)

**Grow users → Store presence → Main store listing**

- [ ] **App name / Short description / Full description:** انسخها من `listing-ar.md` (العربية، اللغة الافتراضية).
- [ ] أضف ترجمة **English (United States) – en-US** وانسخ من `listing-en.md`.
- [ ] **App icon:** PNG بحجم **512 × 512**، 32-bit، بحد أقصى 1 ميجابايت (يمكن البدء من `fullmark/icons/icon-512.png` بعد التأكد أنه بلا شفافية غير مقصودة وأنه بلا حواف دائرية مرسومة — Google تضيف القناع تلقائيًا).
- [ ] **Feature graphic:** صورة **1024 × 500** بصيغة JPEG أو PNG 24-bit (بلا شفافية). اسم التطبيق والشعار بوضوح، وتجنّب النصوص الصغيرة على الأطراف.
- [ ] **Phone screenshots:** من مجلد `play-store/screenshots/` — من **2 إلى 8** صور، PNG أو JPEG، كل ضلع بين 320 و3840 بكسل، والضلع الأطول لا يتجاوز ضعف الأقصر (مثلًا 1080 × 1920). اقتراح ترتيب: شاشة البداية مع المقدّم، سؤال في المستوى السهل، جولة السرعة، وسائل المساعدة في الصعب، المساعد الذكي، غرفة العائلة أونلاين، منصّة التتويج، سجل النتائج والمنحنيات.
- [ ] (اختياري) لقطات للأجهزة اللوحية 7 و10 بوصة، وفيديو يوتيوب.
- [ ] **Store settings:** Category = **Trivia**، Tags حسب `listing-ar.md`، بريد التواصل `Aladeen35@gmail.com`، والموقع الإلكتروني (اختياري).

> تنبيه: لا تضع في الصور أو الأيقونة عبارات مثل «للأطفال» ولا رسومًا طفولية بحتة، لأن الجمهور المستهدف 13+ (انظر `target-audience.md`).

---

## الخطوة 5 — سياسة الخصوصية

**Policy and programs → App content → Privacy policy**

- [ ] ضع الرابط:
  `https://github.com/aladeen35/test/blob/claude/ui-ux-pro-max-skill-n9hipq/fullmark-apk/play-store/PRIVACY.md`
- [ ] تأكّد أن **المستودع عام (Public)** وأن الرابط يفتح بدون تسجيل دخول، وإلا ترفضه Google.
- [ ] ⚠️ الرابط مرتبط باسم الفرع؛ إن دمجت الفرع في `main` أو حذفته، حدّث الرابط في Console.

**بديل أجمل (مُوصى به): GitHub Pages**
- [ ] في المستودع: **Settings → Pages → Build and deployment → Deploy from a branch** واختر الفرع والمجلد الجذر `/`.
- [ ] ستُنشر الصفحة المنسّقة على رابط مثل:
  `https://aladeen35.github.io/test/fullmark/privacy.html`
- [ ] ضع صورة الشعار `al-bushra-logo.png` بجانب `privacy.html` في مجلد `fullmark/` حتى تظهر في التذييل.
- [ ] افتح الرابط من الجوال للتأكد، ثم استخدمه بدل رابط GitHub العادي.

---

## الخطوة 6 — أمان البيانات (Data safety)

- [ ] **App content → Data safety** وأجب حسب `data-safety.md` حرفيًا.
- [ ] راجع البنود المعلَّمة بـ ⚠️ واتخذ قرارك فيها.
- [ ] راجع صفحة المعاينة الأخيرة قبل الحفظ: يجب أن تتطابق مع سياسة الخصوصية.

---

## الخطوة 7 — تصنيف المحتوى

- [ ] **App content → Content rating → Start questionnaire**، الفئة **Game**، وأجب حسب `content-rating.md`.
- [ ] التصنيف المتوقع: **3+ / PEGI 3 / Everyone** مع عنصر «Users Interact».

---

## الخطوة 8 — الجمهور المستهدف والإقرارات الأخرى

- [ ] **Target audience and content:** 13–15، 16–17، 18+ (انظر `target-audience.md` للأسباب).
- [ ] **Ads:** No, my app does not contain ads.
- [ ] **App access:** All functionality is available without special access.
- [ ] **Advertising ID:** التطبيق لا يستخدمه.
- [ ] **News / Government / Financial features / Health / COVID-19:** لا ينطبق.
- [ ] تأكّد من استيفاء سياسة **الذكاء الاصطناعي التوليدي**: زر «الإبلاغ عن الرد» يعمل ويصل للبريد الصحيح.

---

## الخطوة 9 — الاختبار الداخلي (Internal testing)

- [ ] **Test and release → Testing → Internal testing → Create new release**.
- [ ] حمّل ملف **`FullMark.aab`** من صفحة إصدار GitHub (Releases → `fullmark-latest`) في المستودع، ثم ارفعه هنا. (لا ترفع ملف APK للتصحيح؛ Play يقبل AAB موقّعًا للإصدار.)
- [ ] اسم الإصدار: `1.1` — وملاحظات الإصدار من `listing-ar.md` و`listing-en.md` (قسم «ما الجديد»).
- [ ] أضف قائمة مختبرين (حتى 100 بريد) وأرسل لهم رابط الانضمام.
- [ ] ثبّت من المتجر على جوالك وجرّب كل شيء. راجع **Pre-launch report** إن ظهر، وأصلح أي تحذير مهم.

---

## الخطوة 10 — الاختبار المغلق (Closed testing) — لحسابات المطوّرين الشخصية الجديدة

> ⚠️ **سياسة Google الحالية (تحقّق منها قبل البدء لأنها تتغيّر):** حسابات المطوّرين **الشخصية** التي أُنشئت بعد 13 نوفمبر 2023 يجب أن تُجري **اختبارًا مغلقًا بـ 12 مختبرًا على الأقل، يبقون مشتركين لمدة 14 يومًا متواصلة**، قبل أن يُسمح بطلب الوصول إلى الإنتاج (Production). حسابات **المؤسسات** مستثناة.

- [ ] **Testing → Closed testing → Create track** (أو استخدم المسار الافتراضي Alpha).
- [ ] ارفع نفس ملف AAB (أو أحدث).
- [ ] أضف **12 مختبرًا أو أكثر** (يُفضّل 15–20 احتياطًا) عبر قائمة بريد أو مجموعة Google Groups.
- [ ] تأكّد أن كل مختبر **قبِل الدعوة وثبّت التطبيق من رابط الاختبار** ويبقى مشتركًا 14 يومًا كاملة. لا تحذفهم من القائمة.
- [ ] شجّعهم على اللعب فعليًا وإرسال ملاحظات (Google تسأل عن تفاعلهم في طلب الإنتاج).
- [ ] بعد 14 يومًا: **Dashboard → Apply for production**، وأجب عن أسئلة الطلب (كيف اختبرت، ماذا غيّرت بناءً على الملاحظات، ولماذا التطبيق جاهز). المراجعة قد تستغرق أيامًا.

---

## الخطوة 11 — الإصدار للإنتاج (Production)

- [ ] **Test and release → Production → Countries/regions:** اختر الدول (مثلًا السعودية ودول الخليج والدول العربية، أو كل الدول).
- [ ] **Create new release** → اختر ملف AAB من المكتبة (أو ارفعه) → ملاحظات الإصدار → **Next → Start rollout to Production**.
- [ ] (اختياري) ابدأ بنشر مرحلي (Staged rollout) بنسبة 20% ثم ارفعها.
- [ ] **Publishing overview:** تأكّد أن كل التغييرات أُرسلت للمراجعة. أول مراجعة قد تأخذ من ساعات إلى أكثر من أسبوع.
- [ ] بعد الموافقة، افتح صفحة التطبيق في المتجر وتأكّد من الاسم والصور والتصنيف ورابط الخصوصية.

---

## الخطوة 12 — إصدار التحديثات لاحقًا

1. عدّل الكود وادفعه إلى الفرع الذي يشغّل CI.
2. CI يبني ملف AAB موقّعًا بمفتاح الرفع، و**`versionCode` يزيد تلقائيًا مع كل بناء** (Play يرفض أي ملف versionCode له يساوي أو أقل من إصدار مرفوع سابقًا). ⚠️ تأكّد من هذا في سير العمل كما في ملاحظة الخطوة 0.
3. غيّر `versionName` يدويًا عند الحاجة (مثلًا 1.2) ليظهر للمستخدمين.
4. حمّل `FullMark.aab` من إصدار GitHub، وارفعه في **Internal testing** أولًا وجرّبه، ثم **Promote release** إلى Production (أو ارفعه مباشرة في Production).
5. اكتب «ما الجديد» بالعربية والإنجليزية.
6. **إذا غيّرت ما يُرسل من البيانات أو أضفت صلاحية أو ميزة** (دردشة، إعلانات، مزوّد ذكاء اصطناعي جديد): حدّث `PRIVACY.md` و`privacy.html` ونموذج Data safety، وأعد استبيان تصنيف المحتوى إن لزم، **قبل** نشر التحديث.
7. حافظ على تحديث targetSdk سنويًا حسب متطلبات Google، وإلا يتوقف ظهور التطبيق للأجهزة الجديدة.

---

## مراجعة نهائية سريعة

- [ ] `Aladeen35@gmail.com` مستبدل في كل مكان.
- [ ] رابط سياسة الخصوصية يعمل من متصفح خارجي بدون تسجيل دخول.
- [ ] Data safety وسياسة الخصوصية وصفحة المتجر تقول الشيء نفسه.
- [ ] نسخة احتياطية من `fullmark-upload.jks` وكلمات المرور محفوظة في مكانين آمنين.
- [ ] شعار `al-bushra-logo.png` موجود بجانب `privacy.html`.
