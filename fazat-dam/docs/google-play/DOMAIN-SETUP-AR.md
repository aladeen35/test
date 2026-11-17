# ربط الدومين الرسمي fazatdam.albushra.app

يبقى الموقع مستضافاً على Vercel. Cloudflare يدير الـDNS فقط.

## 1) Vercel
- افتح مشروع **fazat-dam** ثم Settings ← Domains ← Add.
- اكتب `fazatdam.albushra.app` واختر **Production**.

## 2) Cloudflare (albushra.app ← DNS ← Records ← Add record)

| Type | Name | Target | Proxy status |
|---|---|---|---|
| CNAME | `fazatdam` | `cname.vercel-dns.com` | **DNS only (سحابة رمادية)** |

- إذا طلب Vercel سجل تحقق إضافياً من نوع `TXT` باسم `_vercel`، أضفه كما يظهر لك.
- انتظر حتى تظهر علامة ✓ خضراء في Vercel. يستغرق ذلك عادة أقل من 10 دقائق، ثم تُصدر شهادة SSL تلقائياً.

## 3) Supabase (Authentication ← URL Configuration)
- **Site URL:** `https://fazatdam.albushra.app`
- **Redirect URLs:** أضف `https://fazatdam.albushra.app/**`، واترك الرابط القديم مؤقتاً.

## 4) Vercel ← Settings ← Environment Variables (Production)
- `NEXT_PUBLIC_SITE_URL` = `https://fazatdam.albushra.app`
- `CANONICAL_HOST` = `fazatdam.albushra.app`، ويحوّل الرابط القديم تلقائياً إلى الجديد.

بعد إضافتها نفّذ **Redeploy**.

⚠️ لا تضف `CANONICAL_HOST` قبل أن يعمل الدومين الجديد في الخطوة 2، وإلا سيتوقف الرابط القديم.

## 5) التحقق
- `https://fazatdam.albushra.app` يفتح التطبيق.
- `https://fazatdam.albushra.app/.well-known/assetlinks.json` يعرض ملف الربط.
- تسجيل الدخول برابط البريد يعيدك إلى الدومين الجديد.
