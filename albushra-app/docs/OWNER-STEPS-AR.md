# خطوات المالك لتشغيل albushra.app (من الجوال)

كل شيء مبني ويُنشر تلقائيًا من GitHub Actions. ما يلي هو ما لا أستطيع فعله بنفسي لأنه يحتاج دخولك إلى Cloudflare وGitHub وFirebase. الخطوات ١–٤ إلزامية لإطلاق الموقع، والباقي لإكمال الربط.

> **لا ترسل أي مفتاح أو كلمة مرور في المحادثة.** كل الأسرار تُلصق مباشرة في إعدادات GitHub.

---

## ١) إنشاء مفتاح Cloudflare API (مرة واحدة)

1. افتح `https://dash.cloudflare.com/profile/api-tokens` وسجّل الدخول.
2. اضغط **Create Token** ← في الأسفل **Create Custom Token** ← **Get started**.
3. الاسم: `albushra-app-ci`.
4. في **Permissions** أضف هذه الأسطر (زر **+ Add more** لكل سطر):
   - `Account` · `Cloudflare Pages` · `Edit`
   - `Account` · `Workers Scripts` · `Edit`
   - `Zone` · `Workers Routes` · `Edit`
   - `Zone` · `DNS` · `Edit`
   - `Zone` · `Zone Settings` · `Edit`
   - `Zone` · `Zone` · `Read`
5. في **Account Resources**: `Include` ← حسابك.
6. في **Zone Resources**: `Include` ← `Specific zone` ← `albushra.app`.
7. اضغط **Continue to summary** ← **Create Token**، ثم **انسخ المفتاح** (يظهر مرة واحدة فقط).

## ٢) نسخ معرّف الحساب (Account ID)

1. افتح `https://dash.cloudflare.com` ← اضغط على النطاق `albushra.app`.
2. انزل في صفحة **Overview** إلى قسم **API** على الجانب (في الجوال أسفل الصفحة) وانسخ **Account ID**.

## ٣) إضافة السرّين في GitHub

1. افتح `https://github.com/aladeen35/test/settings/secrets/actions`.
2. **New repository secret**:
   - الاسم `CLOUDFLARE_API_TOKEN` والقيمة المفتاح من الخطوة ١.
   - الاسم `CLOUDFLARE_ACCOUNT_ID` والقيمة من الخطوة ٢.

## ٤) دمج التغييرات وتشغيل النشر

1. ادمج الفرع `claude/affectionate-bohr-ua53oc` في `main` (طلب الدمج Pull Request).
2. يبدأ سير العمل **albushra.app** تلقائيًا من تبويب **Actions**. وفي أي وقت: **Actions** ← **albushra.app** ← **Run workflow**.
3. سير العمل يقوم بـ:
   - بناء الموقع الرئيسي ولوحة التطبيقات من سجل التطبيقات `albushra-app/registry/apps.json`.
   - نشرهما على Cloudflare Pages (مشروع `albushra-app`).
   - إنشاء سجلات DNS (`albushra.app` و`*.albushra.app` و`www`) وضبط SSL على **Full (strict)** وتفعيل **Always Use HTTPS**. لا يحذف أي سجل موجود.
   - نشر الموجّه `albushra-router` الذي يربط كل نطاق فرعي بتطبيقه في مكان استضافته الحالي.
   - فحص كل النطاقات وإظهار النتيجة في سجل التشغيل.
4. يتكرر البناء كل ٦ ساعات تلقائيًا، فيظهر أي إصدار جديد (مثل `version.json` لبُشرى) دون تعديل.

## ٥) حماية لوحة التطبيقات dash.albushra.app (مجاني)

1. افتح `https://one.dash.cloudflare.com` (Zero Trust). إن طُلب اسم فريق اكتب `albushra` واختر الخطة **Free**.
2. **Access** ← **Applications** ← **Add an application** ← **Self-hosted**.
3. الاسم `Albushra Dashboard`، والنطاق: Subdomain `dash`، Domain `albushra.app`.
4. **Policy**: الاسم `Owner`، Action **Allow**، Include ← **Emails** ← بريدك.
5. احفظ. الآن تطلب اللوحة رمزًا يصل إلى بريدك.

> بيانات اللوحة لا تحوي أي سر (أسماء المتغيرات فقط، ومصادر الاستضافة). الحماية تمنع الفضول، أما الأسرار فمكانها إعدادات كل خدمة.

## ٦) تسجيل الدخول على النطاقات الجديدة

| التطبيق | المطلوب | أين |
|---|---|---|
| هدايا أمير `amir.albushra.app` | أضف `amir.albushra.app` | Firebase ← مشروع `ameer-gift` ← Authentication ← Settings ← **Authorized domains** ← Add domain |
| خلود `khulood.albushra.app` | أضف `khulood.albushra.app` إن كان فيه تسجيل دخول | Firebase ← مشروع `alwasoog-e2d17` ← Authorized domains |
| مصباح الجودة `quality.albushra.app` | أضف `https://quality.albushra.app/**` | Supabase ← مشروع الموقع ← Authentication ← URL Configuration ← Redirect URLs |
| فزعة دم `fazatdam.albushra.app` | اتبع `fazat-dam/docs/google-play/DOMAIN-SETUP-AR.md` (Supabase + Vercel) | يعمل الآن عبر الموجّه حتى قبل إضافته في Vercel |

## ٧) تطبيقات تحتاج قرارًا منك

- **التفاؤل**: سير عمله ينشر إلى Cloudflare Pages ويحتاج السرّين نفسيهما في المستودع `aladeen35/altafaoul`. بعد أول نشر أغيّر ربط `altafaoul.albushra.app` ليعرضه.
- **متجر البشرى**: يحتاج إنشاء قاعدة D1 ومخزن R2 (مجانيان في حدود معينة) ثم النشر.
- **عين الجودة (foodguard)**: يحتاج خادم Docker (استضافة مدفوعة غالبًا)، ومعرّف الحزمة `sa.halfm`؛ تأكد من ملكية المنتج قبل نشره باسم البشري.
- **مآب**: النسخة الحية على Vercel غير منشورة (`maab-academy.vercel.app` يعيد 404)؛ النطاق يعرض نسخة العرض حاليًا.

## ٨) أمان عاجل

- مستودع FSM (فرع القرآن) فيه مفتاح توقيع بُشرى وكلمة مروره داخل الملفات. انقل كلمة المرور إلى أسرار GitHub (`MUSHAF_STORE_PASSWORD` و`MUSHAF_KEY_PASSWORD`) واحذفها من README. **لا تغيّر المفتاح نفسه** وإلا لن تُقبل تحديثات Google Play. احتفظ بنسخة احتياطية منه خارج GitHub.

## ٩) إضافة تطبيق جديد مستقبلًا

1. افتح `albushra-app/registry/apps.json` في GitHub ← زر القلم.
2. انسخ كتلة تطبيق مشابه وعدّل: `id`، `subdomain`، الأسماء، `route.target` (رابط التطبيق الحالي)، و`version.source` إن كان للتطبيق ملف إصدار.
3. احفظ (Commit) على `main`. خلال دقائق يظهر في الموقع واللوحة ويعمل نطاقه الفرعي، بلا أي خطوة في Cloudflare.
