# فزعة دم — حزمة النشر على Google Play

| البند | القيمة |
|---|---|
| اسم الحزمة (Package) | `com.albushra.fazatdam` |
| الإصدار | 1.0.0 (versionCode 1) |
| نوع التطبيق | Trusted Web Activity، يفتح الموقع https://fazatdam.albushra.app بملء الشاشة |
| الحد الأدنى / الهدف | Android 7.0 (API 24) / Android 16 (API 36) |
| الدومين | يجب ربط الدومين قبل الرفع، راجع `DOMAIN-SETUP-AR.md` |
| التوقيع | مفتاح رفع (Upload key) خاص. يُرسل في ملف منفصل ولا يُنشر أبداً |

## محتويات الحزمة
```
01-upload/
  fazat-dam-1.0.0.aab        ← الملف الذي يُرفع على Google Play
  fazat-dam-1.0.0-test.apk   ← للتجربة المباشرة على جوال أندرويد (ليس للرفع)
  assetlinks.json            ← نسخة مما هو منشور على الموقع (للمرجع)
02-store-listing/
  listing-ar.md / listing-en.md   ← الاسم والوصف المختصر والكامل وملاحظات الإصدار
  data-safety-ar.md               ← إجابات نموذج «أمان البيانات» وتصنيف المحتوى
  graphics/
    app-icon-512.png              ← أيقونة المتجر 512×512
    feature-graphic-ar.png/en.png ← صورة العرض 1024×500
    phone-screenshots-ar/ (7)     ← لقطات 1080×1920
    phone-screenshots-en/ (7)
03-wear-os/
  WEAR-OS-PLAN-AR.md + wear-os-concept.png ← خطة نسخة الساعة الذكية
```

## خطوات الرفع (مرة واحدة)
1. **حساب المطوّر:** سجّل في https://play.google.com/console. الرسوم 25 دولاراً مرة واحدة.
   - يُفضَّل حساب **مؤسسة (Organization)** باسم البشري للتكنولوجيا، ويتطلب رقم D-U-N-S.
   - الحساب **الشخصي** الجديد يشترط اختباراً مغلقاً بـ12 مختبِراً لمدة 14 يوماً قبل الإنتاج.
2. **إنشاء التطبيق:** Create app ← الاسم «فزعة دم - تبرع بالدم» ← اللغة الافتراضية العربية ← App ← Free.
3. **إعداد التطبيق (App content):**
   - Privacy policy: `https://fazatdam.albushra.app/privacy`
   - App access: كل الميزات تتطلب تسجيل دخول بالبريد. أعطِ المراجعين بريداً تجريبياً، فهو يستقبل رمز الدخول.
   - Ads: لا يحتوي إعلانات.
   - Content rating: املأ الاستبيان حسب `data-safety-ar.md`.
   - Target audience: 18+.
   - Data safety: انسخ الإجابات من `data-safety-ar.md`.
   - Health apps: اختر «Blood donation / Health & wellness coordination»، وأكّد أنه ليس جهازاً طبياً.
4. **بطاقة المتجر (Main store listing):**
   - انسخ النصوص من `listing-ar.md`.
   - أضف ترجمة English من `listing-en.md`.
   - ارفع الأيقونة وصورة العرض واللقطات.
   - الفئة: **Medical**. البريد: بريد الدعم الرسمي للبشري.
5. **رفع الإصدار:**
   - Testing ← Internal testing (أو Closed) ← Create release.
   - وافق على **Play App Signing** (موصى به).
   - ارفع `fazat-dam-1.0.0.aab` وانسخ ملاحظات الإصدار.
   - Review ← Start rollout.
6. **⚠️ خطوة ضرورية بعد أول رفع:**
   - افتح Setup ← App signing وانسخ **SHA-256 certificate fingerprint** من قسم *App signing key certificate*، ثم أرسله لي.
   - سأضيفه إلى `/.well-known/assetlinks.json` على الموقع.
   - بدونه يظهر شريط عنوان المتصفح أعلى التطبيق عند تثبيته من المتجر.
   - بصمة مفتاح الرفع الحالي مضافة مسبقاً، لذلك ملف APK التجريبي يعمل بملء الشاشة.
7. **الإنتاج:** بعد نجاح الاختبار انقل الإصدار إلى Production. المراجعة تستغرق عادةً من يوم إلى 7 أيام.

## مفتاح التوقيع 🔐
- يصلك في ملف مضغوط **منفصل** (`fazat-dam-SIGNING-KEY-PRIVATE.zip`) يحتوي ملف `.jks` وكلمات المرور.
- احفظه في مكانين آمنين (مدير كلمات مرور + نسخة احتياطية غير متصلة).
- لا ترفعه إلى GitHub، ولا ترسله بالبريد أو الواتساب.
- إن فُقد مع تفعيل Play App Signing يمكن طلب إعادة تعيين مفتاح الرفع من Google. لذلك فعّل Play App Signing.

## التحديثات القادمة
- **تحديث تصميم أو ميزات الموقع** يظهر فوراً داخل التطبيق دون رفع إصدار جديد، لأن التطبيق يعرض الموقع المباشر.
- **إصدار جديد** لا يلزم إلا عند تغيير الأيقونة أو الاسم أو الإعدادات الأصلية. عندها نرفع `versionCode` ونبني ونوقّع بالمفتاح نفسه.
- **مصدر المشروع:** `android-twa/` في المستودع (بدون أسرار).
