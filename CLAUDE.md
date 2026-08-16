# قواعد المستودع

## الخط الرسمي — إلزامي لكل التطبيقات

الخط المعتمد لجميع التطبيقات الحالية والمستقبلية في هذا المستودع هو **Noto Kufi Arabic**.

- الملف المرجعي: `assets/fonts/NotoKufiArabic-Regular.ttf`
- عند إنشاء أي تطبيق جديد: انسخ الملف إلى مجلد `fonts/` داخل التطبيق وضمّنه محليًا عبر `@font-face` (لا تعتمد على Google Fonts أو أي CDN — التطبيقات تعمل دون اتصال):

```css
@font-face{
  font-family:"Noto Kufi Arabic";
  src:url("fonts/NotoKufiArabic-Regular.ttf") format("truetype");
  font-weight:100 900;
  font-display:swap;
}
body{font-family:"Noto Kufi Arabic",system-ui,sans-serif}
```

- استخدمه للنصوص والعناوين معًا، وأضف الملف إلى قائمة `ASSETS` في `sw.js` ليعمل دون اتصال.

## بنية المستودع

كل تطبيق/لعبة في مجلد مستقل كتطبيق PWA كامل (index.html + manifest.webmanifest + sw.js + أيقونات):

- الجذر: تطبيق «هاف مليون ½M» — مخطط الزيارات
- `game/` — لعبة العائلة للاعبين
- `madrasatuna/` — لعبة «مدرستنا»
- `baynana/` — لعبة «بيننا» للمتزوجين

## قواعد عامة

- الواجهات عربية RTL أولًا
- التطبيقات تعمل دون اتصال بالكامل (Service Worker) وقابلة للتثبيت
- الأصول البصرية المعتمدة من المالك (شعارات، صور شخصيات) تُستخدم كملفات كما هي ولا يُعاد رسمها بالكود
