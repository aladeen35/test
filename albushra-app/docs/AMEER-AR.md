# لوحة «أمير» الخاصة — ameer.albushra.app

لوحة قيادة شخصية لك وحدك: كل ما أنجزه Claude (الجلسات، الإيداعات، طلبات الدمج)، حالة مستودعاتك، مسارات النشر في GitHub Actions، حالة كل تطبيقات albushra.app، أجهزتك (الكمبيوتر)، وملاحظاتك.

## كيف تُحمى؟ (قفلان)

1. **Cloudflare Access** أمام النطاق: لا تفتح الصفحة إلا بعد تسجيل الدخول ببريدك (رمز يصل إلى البريد، أو حساب Google إن فعّلته).
2. **الموجّه نفسه** يتحقق من توقيع Access ثم يقارن البريد بالسر `AMEER_OWNER_EMAILS`. إن لم يُضبط السر تبقى اللوحة **مقفلة** للجميع.

الصفحة وبياناتها لا تُنشر على Cloudflare Pages أبدًا؛ الموجّه هو من يقدّمها بعد التحقق.

## الخطوات (مرة واحدة، من الهاتف)

### ١) رمز الإدخال
أنشئ كلمة سر عشوائية طويلة (٤٠ حرفًا أو أكثر) من مدير كلمات المرور في هاتفك (Google أو Samsung Pass) واحفظها. هذا هو `AMEER_INGEST_TOKEN`؛ يستعمله جامع GitHub وبرنامج الكمبيوتر لإرسال البيانات.

### ٢) رمز GitHub للقراءة فقط
1. افتح `https://github.com/settings/personal-access-tokens/new`.
2. الاسم `ameer-dashboard`، المدة سنة.
3. **Repository access** ← **All repositories**.
4. **Permissions** ← Repository permissions، اختر **Read-only** لكل من: **Actions** و**Contents** و**Metadata** و**Pull requests**.
5. **Generate token** وانسخه.

### ٣) أسرار المستودع `aladeen35/test`
**Settings** ← **Secrets and variables** ← **Actions** ← **New repository secret**، وأضف:

| الاسم | القيمة |
|---|---|
| `AMEER_OWNER_EMAILS` | بريدك الذي تدخل به (يمكن أكثر من بريد مفصولة بفاصلة) |
| `AMEER_INGEST_TOKEN` | الرمز من الخطوة ١ |
| `AMEER_GH_TOKEN` | الرمز من الخطوة ٢ |

### ٤) إضافة النطاق إلى Cloudflare Access
1. افتح `https://one.dash.cloudflare.com` ← **Access** ← **Applications**.
2. افتح تطبيق **Albushra Dashboard** ← **Configure** (أو Edit).
3. في **Public hostnames** اضغط **Add public hostname**: Subdomain `ameer`، Domain `albushra.app`.
4. تأكد أن السياسة (Policy) تسمح ببريدك فقط ← **Save**.
5. (اختياري) للدخول بحساب Google: **Settings** ← **Authentication** ← **Login methods** ← **Add new** ← **Google**، ثم فعّله في التطبيق.

### ٥) النشر
بعد دمج الفرع في `main`: يعمل **albushra.app** تلقائيًا (ينشر الموجّه ويضع السرّين فيه)، ثم شغّل **Actions** ← **ameer** ← **Run workflow** لأول تعبئة. بعدها يتحدث كل ٣٠ دقيقة.

افتح `https://ameer.albushra.app` ← سجّل الدخول ← تظهر اللوحة.

## ربط الكمبيوتر (اختياري)
من اللوحة ← تبويب **الأجهزة** ← نزّل البرنامج (Windows أو Mac/Linux)، ضع رمز الإدخال مكان `PASTE_TOKEN_HERE`، وشغّله. يرسل كل ٥ دقائق: المعالج، الذاكرة، القرص، البطارية، مدة التشغيل فقط، ولا يقرأ أي ملف.

> حد Cloudflare المجاني ١٠٠٠ كتابة يوميًا: جهاز كل ٥ دقائق = ٢٨٨ كتابة، والجامع = ٤٨. لا تجعل الفاصل أقل من ٥ دقائق إن ربطت أكثر من جهازين.

## تسجيل عمل يدوي (لـ Claude أو لأي أداة)
```bash
curl -X POST https://albushra.app/__ameer/ingest \
  -H "Authorization: Bearer $AMEER_INGEST_TOKEN" -H "content-type: application/json" \
  -d '{"kind":"log","data":{"title":"نشر الإصدار 2.9","repo":"mushaf","status":"done"}}'
```

## ماذا يظهر؟
- **نظرة عامة**: آخر جلسة لـ Claude، الأمان، الكمبيوتر، السحابة، المستودعات، مسارات النشر، المؤشرات.
- **Claude**: كل الجلسات (برابط كل جلسة) وخط زمني لكل إيداع وطلب دمج وسجل.
- **التطبيقات**: كل نطاقات albushra.app وزمن استجابتها.
- **الأجهزة** و**ملاحظات** (قائمة مهام خاصة بك).
