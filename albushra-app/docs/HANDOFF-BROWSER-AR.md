# مهمة: إطلاق albushra.app وربط النطاقات الفرعية (جلسة الكمبيوتر مع المتصفح)

> انسخ هذا الملف كاملًا والصقه كأول رسالة في جلسة Claude الجديدة على الكمبيوتر.

## السياق

أنا مالك الدومين `albushra.app` وهو مضاف في حسابي على Cloudflare (خوادم الأسماء `hera.ns.cloudflare.com` و`pranab.ns.cloudflare.com`)، لكن **لا توجد فيه أي سجلات DNS بعد**.

كل الكود جاهز ومختبر في GitHub:
- المستودع: `https://github.com/aladeen35/test`
- الفرع: `claude/affectionate-bohr-ua53oc`
- المجلد: `albushra-app/`، وفيه:
  - `registry/apps.json`: سجل التطبيقات، المصدر الوحيد للحقيقة.
  - `scripts/build.mjs`: يبني الموقع الرئيسي ولوحة التطبيقات إلى `dist/site`، ويولّد `worker/routes.json`.
  - `worker/router.js` و`wrangler.toml`: Worker اسمه `albushra-router` على المسارين `albushra.app/*` و`*.albushra.app/*`. يربط كل نطاق فرعي بالتطبيق في مكان استضافته الحالي (GitHub Pages أو Vercel) دون نقله.
  - `scripts/dns-sync.mjs`: ينشئ سجلات DNS ويضبط SSL، ولا يحذف شيئًا.
  - `docs/REPORT.md`: الجرد الكامل.
  - `docs/OWNER-STEPS-AR.md`: الخطوات مفصّلة.
- سير العمل: `.github/workflows/albushra-app.yml` يبني ويختبر، ثم ينشر من `main` إذا وُجد السرّان `CLOUDFLARE_API_TOKEN` و`CLOUDFLARE_ACCOUNT_ID`.

## الهدف

أن يعمل `https://albushra.app` و`https://dash.albushra.app` وكل النطاقات الفرعية في الجدول أدناه عبر HTTPS، وأن تتحقق من ذلك بنفسك.

## قواعد إلزامية

- استخدم المتصفح بحسابي المسجّل. إن طُلب تسجيل دخول أو رمز تحقق (MFA) فتوقّف واطلب مني إدخاله.
- **لا تعرض المفتاح (API token) في المحادثة** ولا تكتبه في أي ملف. انسخه من صفحة Cloudflare والصقه مباشرة في صفحة أسرار GitHub.
- **لا تحذف ولا تعدّل أي سجل DNS موجود**، خصوصًا سجلات البريد (MX وTXT). أضف فقط.
- لا تشترك في أي خطة مدفوعة ولا تُدخل بيانات دفع. كل المطلوب يعمل على الخطط المجانية. إن ظهر طلب ترقية فتوقّف واسألني.
- لا تغيّر إعدادات التطبيقات الأخرى إلا ما هو مذكور هنا.
- لا تقل إن شيئًا يعمل قبل أن تفتحه وترى الصفحة الصحيحة.

---

## المسار أ (المفضّل): عبر GitHub Actions

### أ١. إنشاء مفتاح Cloudflare API

1. افتح `https://dash.cloudflare.com/profile/api-tokens`، ثم **Create Token**، ثم في الأسفل **Create Custom Token** ← **Get started**.
2. **Token name**: `albushra-app-ci`
3. **Permissions** (أضف كل سطر بزر **+ Add more**):

   | النوع | الصلاحية | المستوى |
   |---|---|---|
   | Account | Cloudflare Pages | Edit |
   | Account | Workers Scripts | Edit |
   | Zone | Workers Routes | Edit |
   | Zone | DNS | Edit |
   | Zone | Zone Settings | Edit |
   | Zone | Zone | Read |

4. **Account Resources**: Include ← حسابي.
5. **Zone Resources**: Include ← Specific zone ← `albushra.app`.
6. **Continue to summary** ← **Create Token**. لا تنسخ المفتاح إلى المحادثة، فهو مطلوب في الخطوة أ٣.

### أ٢. معرّف الحساب

افتح `https://dash.cloudflare.com` ← النطاق `albushra.app` ← صفحة **Overview**، وفي قسم **API** انسخ **Account ID**. هذا المعرّف ليس سرًّا.

### أ٣. إضافة السرّين إلى GitHub

افتح `https://github.com/aladeen35/test/settings/secrets/actions` ← **New repository secret**، وأضف:
- `CLOUDFLARE_API_TOKEN` = المفتاح من أ١
- `CLOUDFLARE_ACCOUNT_ID` = المعرّف من أ٢

### أ٤. الدمج

1. افتح `https://github.com/aladeen35/test/compare/main...claude/affectionate-bohr-ua53oc`
2. **Create pull request**، بعنوان: `albushra.app: main site, dashboard, registry and edge router`
3. انتظر نجاح فحص **albushra.app / build**، ثم **Merge pull request** ← **Confirm merge**.

### أ٥. متابعة النشر

1. افتح `https://github.com/aladeen35/test/actions/workflows/albushra-app.yml` وافتح آخر تشغيل على `main`.
2. يجب أن تنجح كل خطوات مهمة **deploy**:
   1. Deploy the site to Cloudflare Pages
   2. DNS records and SSL settings
   3. Deploy the edge router
   4. Verify every subdomain
3. إن فشلت خطوة فاقرأ السجل وعالج حسب الجدول، ثم أعد التشغيل: **Re-run jobs** أو **Run workflow** على `main`.

| الخطأ | السبب والحل |
|---|---|
| `Authentication error` / `10000` | صلاحية ناقصة في المفتاح. عدّل المفتاح من صفحة API Tokens وأضف الصلاحية المذكورة في الخطأ. |
| `A route with the same pattern already exists` | يوجد Worker آخر على المسار نفسه. في Workers & Pages ← هذا الـ Worker ← Settings ← Domains & Routes: إن كان قديمًا ولا يُستخدم فاسألني قبل إزالته. |
| `kept existing CNAME ...` في خطوة DNS | سجل قديم يمنع الإضافة، وهو ليس خطأ قاتلًا. اذكره لي ولا تحذفه. |
| `setting ssl: ...` | الصلاحية Zone Settings ناقصة. اضبطها يدويًا من SSL/TLS ← Overview ← **Full (strict)**، ثم Edge Certificates ← **Always Use HTTPS** = On. |
| فشل `pages project create` أو `pages deploy` | تأكد من صلاحية Cloudflare Pages: Edit ومن صحة Account ID. |

---

## المسار ب (بديل إن تعذّر المسار أ): النشر من الكمبيوتر بالطرفية

إن كانت لديك طرفية على الكمبيوتر:

```bash
git clone -b claude/affectionate-bohr-ua53oc https://github.com/aladeen35/test.git
cd test/albushra-app
npm ci
npm test
npm run build
npx wrangler login
npx wrangler pages project create albushra-app --production-branch main
npx wrangler pages deploy dist/site --project-name albushra-app --branch main
npx wrangler deploy
```

ملاحظات:
- `npx wrangler login` يفتح المتصفح لأوافق عليه.
- الأمر `pages project create` يكفي مرة واحدة، وتجاهل الخطأ إن كان المشروع موجودًا.

ثم أضف سجلات DNS يدويًا من `https://dash.cloudflare.com` ← `albushra.app` ← **DNS** ← **Records** ← **Add record**، ثلاث مرات:

| Type | Name | IPv6 address | Proxy status |
|---|---|---|---|
| AAAA | `@` | `100::` | Proxied (برتقالي) |
| AAAA | `*` | `100::` | Proxied (برتقالي) |
| AAAA | `www` | `100::` | Proxied (برتقالي) |

وبعدها في **SSL/TLS** ← **Overview**: **Full (strict)**، وفي **Edge Certificates**: **Always Use HTTPS** = On.

مهم: إن فشل الدمج في المسار ب، فما زال يلزم إضافة السرّين ودمج الفرع لاحقًا، حتى تتحدث الإصدارات تلقائيًا كل ٦ ساعات.

---

## ج. التحقق (إلزامي)

1. افتح `https://albushra.app/__router/health`: يجب أن تظهر JSON فيها `"ok": true`.
2. افتح كل رابط وتأكد أن الصفحة الصحيحة تظهر (وليس 404 أو 502 أو خطأ شهادة):

| الرابط | المتوقع |
|---|---|
| `https://albushra.app` | الموقع الرئيسي «البشري للتكنولوجيا» |
| `https://www.albushra.app` | يحوّل إلى albushra.app |
| `https://dash.albushra.app` | لوحة التطبيقات |
| `https://quran.albushra.app` | صفحة تطبيق بُشرى، و`/app/` يفتح التطبيق |
| `https://khulood.albushra.app` | خلود |
| `https://maab.albushra.app` | أكاديمية مآب (نسخة العرض) |
| `https://education.albushra.app` | البشرى أكاديمية تعليمية |
| `https://fazatdam.albushra.app` | فزعة دم |
| `https://quality.albushra.app` | Eng. Alaeldeen — Quality & Safety |
| `https://news.albushra.app` | البشرى للأخبار |
| `https://video.albushra.app` | البشرى فيديو |
| `https://amir.albushra.app` | هدايا أمير |
| `https://abujanan.albushra.app` | ألعاب أبو جنان |
| `https://fullmark.albushra.app` | فول مارك |
| `https://wolaat.albushra.app` | ولعت |
| `https://tools.albushra.app` | Ameer Tools |
| `https://hamli.albushra.app` | حاسبة حملي |
| `https://kids.albushra.app` و`jenan` و`keyboard` و`nibras` و`altafaoul` و`store` و`foodguard` | تحويل إلى صفحة التطبيق في albushra.app |

3. على `https://dash.albushra.app` يجب أن تظهر النقطة الخضراء «يعمل» لكل التطبيقات المربوطة.

## د. إكمال الربط

1. **حماية اللوحة (مجانًا)**:
   1. افتح `https://one.dash.cloudflare.com` ← Zero Trust. إن طُلب اسم فريق اكتب `albushra` واختر **Free**، وإن طُلبت بطاقة دفع فتوقّف واسألني.
   2. Access ← Applications ← **Add an application** ← **Self-hosted**.
   3. الاسم `Albushra Dashboard`، والنطاق `dash` . `albushra.app`.
   4. Policy: `Owner` ← Allow ← Include ← Emails ← بريدي (اسألني عنه).
   5. تحقق أن `dash.albushra.app` يطلب الآن رمزًا بالبريد.
2. **Firebase — هدايا أمير**:
   1. افتح `https://console.firebase.google.com/project/ameer-gift/authentication/settings`.
   2. **Authorized domains** ← **Add domain** ← `amir.albushra.app`.
3. **Firebase — خلود**: في المشروع `alwasoog-e2d17` أضف `khulood.albushra.app` بالطريقة نفسها، إن كان في Authentication نطاقات مصرّح بها.
4. **Supabase — مصباح الجودة**:
   1. افتح `https://supabase.com/dashboard/project/qiogbmeqxgivvbgfgwaz/auth/url-configuration`.
   2. في **Redirect URLs** أضف `https://quality.albushra.app/**`. لا تغيّر **Site URL**.
5. **فزعة دم**: اتبع الملف `fazat-dam/docs/google-play/DOMAIN-SETUP-AR.md` في المستودع نفسه.
   - في Supabase: أضف Redirect URL هو `https://fazatdam.albushra.app/**`.
   - في Vercel: لا تضبط `CANONICAL_HOST` إلا بعد التأكد أن النطاق يعمل.
   - النطاق يعمل الآن عبر الموجّه حتى دون إضافته في Vercel، فإضافته فيه اختيارية.

## هـ. التقرير المطلوب في النهاية

أرسل لي جدولًا بكل نطاق فرعي فيه: يعمل أو لا يعمل، وحالة الشهادة، وما ظهر في الصفحة. ثم اذكر:
- كل خطوة لم تكتمل وسببها.
- كل سجل DNS قديم وجدته ولم تلمسه.
- كل ما يحتاج قرارًا مني.
