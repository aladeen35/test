import '../../core/i18n.dart';

/// بيانات السيرة الذاتية محفوظة كـ Map (JSON) — هنا دوال مساعدة مشتركة بين المعاينة والـ PDF

String cvStr(Map cv, String k) => (cv[k] ?? '').toString().trim();

List<Map<String, dynamic>> cvList(Map cv, String k) =>
    cv[k] is List ? [for (final e in cv[k] as List) if (e is Map) Map<String, dynamic>.from(e)] : <Map<String, dynamic>>[];

String itemStr(Map m, String k) => (m[k] ?? '').toString().trim();

int itemLvl(Map m) => (m['lvl'] is num ? (m['lvl'] as num).toInt() : 3).clamp(1, 5);

bool cvRtl(Map cv) => cvStr(cv, 'lang') != 'en';

/// عناوين أقسام السيرة بلغة السيرة نفسها (لا بلغة الواجهة)
String cvLabel(Map cv, String key) {
  final ar = cvRtl(cv);
  return switch (key) {
    'objective' => ar ? 'الملخص المهني' : 'Professional Summary',
    'exp' => ar ? 'الخبرات العملية' : 'Work Experience',
    'edu' => ar ? 'التعليم' : 'Education',
    'skills' => ar ? 'المهارات' : 'Skills',
    'langs' => ar ? 'اللغات' : 'Languages',
    'certs' => ar ? 'الشهادات والدورات' : 'Certificates & Courses',
    'refs' => ar ? 'المعرّفون' : 'References',
    'refsOnRequest' => ar ? 'تُقدَّم عند الطلب.' : 'Available upon request.',
    'nationality' => ar ? 'الجنسية' : 'Nationality',
    'birth' => ar ? 'تاريخ الميلاد' : 'Date of birth',
    'contact' => ar ? 'التواصل' : 'Contact',
    'present' => ar ? 'حتى الآن' : 'Present',
    _ => key,
  };
}

/// وصف مستوى اللغة (1..5) بلغة السيرة
String langLevel(Map cv, int l) {
  final ar = cvRtl(cv);
  const a = ['مبتدئ', 'متوسط', 'جيد', 'جيد جدًا', 'اللغة الأم'];
  const e = ['Beginner', 'Intermediate', 'Good', 'Very good', 'Native'];
  return (ar ? a : e)[l.clamp(1, 5) - 1];
}

/// وصف مستوى اللغة بلغة الواجهة (للمحرّر)
String langLevelUi(int l) => [
      t('مبتدئ', 'مبتدئ', 'Beginner'),
      t('متوسط', 'متوسط', 'Intermediate'),
      t('كويس', 'جيد', 'Good'),
      t('كويس شديد', 'جيد جدًا', 'Very good'),
      t('لغتي الأم', 'اللغة الأم', 'Native'),
    ][l.clamp(1, 5) - 1];

/// سطر الفترة «من – إلى»
String cvPeriod(Map m) {
  final f = itemStr(m, 'from'), to = itemStr(m, 'to');
  if (f.isEmpty && to.isEmpty) return '';
  if (f.isEmpty) return to;
  if (to.isEmpty) return f;
  return '$f – $to';
}

/// نقاط الوصف (سطر لكل نقطة)
List<String> cvBullets(String s) => [
      for (final l in s.split('\n'))
        if (l.trim().replaceFirst(RegExp(r'^[-•*·]\s*'), '').isNotEmpty) l.trim().replaceFirst(RegExp(r'^[-•*·]\s*'), '')
    ];

/// بيانات التواصل
List<String> cvContacts(Map cv) => [for (final k in ['phone', 'email', 'city', 'link']) if (cvStr(cv, k).isNotEmpty) cvStr(cv, k)];

/// نسبة اكتمال السيرة (0..1) مع قائمة الناقص
(double, List<String>) cvCompleteness(Map cv) {
  final missing = <String>[];
  var done = 0;
  void chk(bool ok, String what) => ok ? done++ : missing.add(what);
  chk(cvStr(cv, 'name').isNotEmpty, t('الاسم', 'الاسم', 'Name'));
  chk(cvStr(cv, 'jobTitle').isNotEmpty, t('المسمى الوظيفي', 'المسمى الوظيفي', 'Job title'));
  chk(cvStr(cv, 'phone').isNotEmpty || cvStr(cv, 'email').isNotEmpty, t('رقم أو إيميل', 'هاتف أو بريد', 'Phone or email'));
  chk(cvStr(cv, 'objective').length >= 40, t('ملخص مهني (40 حرف على الأقل)', 'ملخص مهني (40 حرفًا على الأقل)', 'Summary (40+ characters)'));
  chk(cvList(cv, 'exp').isNotEmpty, t('خبرة واحدة على الأقل', 'خبرة واحدة على الأقل', 'At least one job'));
  chk(cvList(cv, 'edu').isNotEmpty, t('التعليم', 'التعليم', 'Education'));
  chk(cvList(cv, 'skills').length >= 3, t('3 مهارات أو أكتر', '3 مهارات أو أكثر', '3+ skills'));
  chk(cvList(cv, 'langs').isNotEmpty, t('لغة واحدة على الأقل', 'لغة واحدة على الأقل', 'At least one language'));
  return (done / 8, missing);
}

/// السيرة كنص عادي (للمشاركة السريعة)
String cvPlainText(Map cv) {
  final b = StringBuffer();
  b.writeln(cvStr(cv, 'name'));
  if (cvStr(cv, 'jobTitle').isNotEmpty) b.writeln(cvStr(cv, 'jobTitle'));
  final c = cvContacts(cv);
  if (c.isNotEmpty) b.writeln(c.join(' | '));
  void sec(String k) => b.writeln('\n— ${cvLabel(cv, k)} —');
  if (cvStr(cv, 'objective').isNotEmpty) {
    sec('objective');
    b.writeln(cvStr(cv, 'objective'));
  }
  final exp = cvList(cv, 'exp');
  if (exp.isNotEmpty) {
    sec('exp');
    for (final e in exp) {
      b.writeln([itemStr(e, 'title'), itemStr(e, 'org'), itemStr(e, 'place'), cvPeriod(e)].where((x) => x.isNotEmpty).join(' · '));
      for (final p in cvBullets(itemStr(e, 'desc'))) {
        b.writeln('  • $p');
      }
    }
  }
  final edu = cvList(cv, 'edu');
  if (edu.isNotEmpty) {
    sec('edu');
    for (final e in edu) {
      b.writeln([itemStr(e, 'degree'), itemStr(e, 'school'), itemStr(e, 'year'), itemStr(e, 'note')].where((x) => x.isNotEmpty).join(' · '));
    }
  }
  final sk = cvList(cv, 'skills');
  if (sk.isNotEmpty) {
    sec('skills');
    b.writeln(sk.map((e) => itemStr(e, 'n')).join('، '));
  }
  final lg = cvList(cv, 'langs');
  if (lg.isNotEmpty) {
    sec('langs');
    b.writeln(lg.map((e) => '${itemStr(e, 'n')} (${langLevel(cv, itemLvl(e))})').join('، '));
  }
  final ce = cvList(cv, 'certs');
  if (ce.isNotEmpty) {
    sec('certs');
    for (final e in ce) {
      b.writeln([itemStr(e, 'n'), itemStr(e, 'org'), itemStr(e, 'year')].where((x) => x.isNotEmpty).join(' · '));
    }
  }
  final rf = cvList(cv, 'refs');
  if (rf.isNotEmpty || cv['refsOnRequest'] == true) {
    sec('refs');
    if (cv['refsOnRequest'] == true) {
      b.writeln(cvLabel(cv, 'refsOnRequest'));
    } else {
      for (final e in rf) {
        b.writeln([itemStr(e, 'n'), itemStr(e, 'role'), itemStr(e, 'contact')].where((x) => x.isNotEmpty).join(' · '));
      }
    }
  }
  return b.toString().trim();
}
