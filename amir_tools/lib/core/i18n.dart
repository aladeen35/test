/// الترجمة: ثلاث لغات — سوداني (عامية)، عربي (فصحى)، إنجليزي.
///
/// الاستخدام في أي مكان:
///   t('فاضل ليها', 'متبقٍ عليها', 'Time left')   ← عندما يختلف السوداني عن الفصحى
///   tr('الصلاة', 'Prayer')                       ← عندما يتطابق السوداني والفصحى
/// تتغيّر اللغة من «الضبط» فيُعاد بناء التطبيق كله.
library;

enum Lang {
  sd('سوداني', '🇸🇩'),
  ar('عربي', '🌙'),
  en('English', '🇬🇧');

  final String label, flag;
  const Lang(this.label, this.flag);
}

/// اللغة الحالية (تُضبط من AppState)
Lang appLang = Lang.sd;

bool get isEn => appLang == Lang.en;

/// نص بثلاث صيغ: سوداني، فصحى، إنجليزي
String t(String sd, String ar, String en) => switch (appLang) {
      Lang.sd => sd,
      Lang.ar => ar,
      Lang.en => en,
    };

/// نص عربي واحد (سوداني = فصحى) مع ترجمته الإنجليزية
String tr(String arabic, String en) => appLang == Lang.en ? en : arabic;
