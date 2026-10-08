import 'package:flutter/material.dart';
import '../core/i18n.dart';
import '../tools/registry.dart';

/// حزم الأدوات: مجموعات كبرى تضم عدة تصنيفات لتصفّح أسهل لعشرات الأدوات
enum ToolBundle {
  faith('دينك', 'دينك', 'Faith', Icons.mosque_rounded, [Color(0xFF0F7A4A), Color(0xFF0A4A2E)], [ToolCat.islam, ToolCat.quran]),
  money('فلوسك', 'أموالك', 'Money', Icons.payments_rounded, [Color(0xFFB98A1E), Color(0xFF6E4A10)], [ToolCat.money]),
  family('بيتك وأسرتك', 'بيتك وأسرتك', 'Home & Family', Icons.family_restroom_rounded, [Color(0xFFB4492D), Color(0xFF6B2516)], [ToolCat.home, ToolCat.health, ToolCat.life]),
  work('شغلك وقرايتك', 'عملك ودراستك', 'Work & Study', Icons.work_rounded, [Color(0xFF0B5C8A), Color(0xFF07324D)], [ToolCat.work, ToolCat.learn]),
  daily('يومك وونستك', 'يومك وترفيهك', 'Daily & Fun', Icons.wb_sunny_rounded, [Color(0xFFE2702B), Color(0xFF8A3A12)], [ToolCat.daily, ToolCat.fun]),
  tech('تقنية وأمان', 'تقنية وأمان', 'Tech & Safety', Icons.shield_rounded, [Color(0xFF3B2F8F), Color(0xFF1E1750)], [ToolCat.media, ToolCat.device, ToolCat.safety]);

  final String sd, ar, en;
  final IconData icon;
  final List<Color> colors;

  /// التصنيفات المصرّح بها صراحةً لهذه الحزمة (بالترتيب المعروض)
  final List<ToolCat> declaredCats;
  const ToolBundle(this.sd, this.ar, this.en, this.icon, this.colors, this.declaredCats);

  String get label => t(sd, ar, en);

  /// كل تصنيفات الحزمة، بما فيها أي تصنيف جديد غير مذكور صراحةً ويقع هنا افتراضيًا
  List<ToolCat> get cats => [
        ...declaredCats,
        for (final c in ToolCat.values)
          if (!catBundles.containsKey(c) && this == fallbackBundle) c,
      ];

  /// أدوات الحزمة الظاهرة، مرتّبة حسب التصنيف
  List<ToolDef> get tools {
    final all = allTools.where((x) => !x.hidden).toList();
    return [
      for (final c in cats) ...all.where((x) => x.cat == c),
    ];
  }

  static ToolBundle? byName(String? name) {
    for (final b in ToolBundle.values) {
      if (b.name == name) return b;
    }
    return null;
  }
}

/// الحزمة التي يقع فيها أي تصنيف جديد لم يُربط بعد
const fallbackBundle = ToolBundle.daily;

/// ربط كل تصنيف بحزمته
final Map<ToolCat, ToolBundle> catBundles = {
  for (final b in ToolBundle.values)
    for (final c in b.declaredCats) c: b,
};

ToolBundle bundleOf(ToolCat c) => catBundles[c] ?? fallbackBundle;

ToolCat? catByName(String? name) {
  for (final c in ToolCat.values) {
    if (c.name == name) return c;
  }
  return null;
}

/// أدوات جديدة تحمل شارة «جديد» (المعرّفات غير الموجودة تُتجاهل)
const newToolIds = <String>{
  'hifz', 'last_third', 'fidya', 'udhiya', 'wedding_budget', 'shop_ledger', 'month_budget', 'gas', 'generator',
  'car_care', 'power_cuts', 'pantry', 'notes', 'img_pdf', 'recorder', 'mirror', 'travel_list', 'card_scores', 'domino',
  'sd_certificate', 'flashcards', 'times_table',
  // الدفعة القادمة
  'savings_goals', 'sadaqa', 'basket_compare', 'meal_plan', 'trip_plan', 'study_plan', 'vaccines', 'family_health',
  'elder_care', 'first_aid', 'emergency_numbers', 'sd_dialect', 'official_terms', 'cv_builder', 'holidays', 'official_links',
  'quran_search', 'hadith', 'share_cards', 'hajj_umrah', 'account_security', 'fraud_alerts', 'news_check', 'link_check',
};

bool isNewTool(String id) => newToolIds.contains(id);

/// الأدوات الجديدة الموجودة فعلًا، الأحدث أولًا
List<ToolDef> get newTools {
  final byId = {for (final x in allTools) if (!x.hidden) x.id: x};
  return [
    for (final id in newToolIds.toList().reversed)
      if (byId[id] != null) byId[id]!,
  ];
}

/// تطبيع النص العربي للبحث: يوحّد الهمزات والتاء المربوطة والألف المقصورة ويحذف التشكيل
String normalizeSearch(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[ً-ْـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي');

/// بحث في الاسم والوصف والكلمات المفتاحية واسم التصنيف (كل الكلمات يجب أن تطابق)
bool toolMatches(ToolDef x, String query) {
  final q = normalizeSearch(query.trim());
  if (q.isEmpty) return true;
  final hay = normalizeSearch('${x.name} ${x.sub} ${x.keywords} ${x.cat.label} ${x.id}');
  return q.split(RegExp(r'\s+')).every(hay.contains);
}
