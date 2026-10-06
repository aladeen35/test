import 'package:flutter/material.dart';
import 'money/money_tools.dart';
import 'islam/islam_tools.dart';
import 'daily/daily_tools.dart';
import 'media/media_tools.dart';
import 'device/device_tools.dart';
import 'life/life_tools.dart';
import 'more/more_tools.dart';
import 'work/work_tools.dart';
import 'home/home_tools.dart';
import 'deen/deen_tools.dart';
import 'plus/plus_tools.dart';
import 'writer/writer_tools.dart';
import '../core/i18n.dart';

/// تصنيفات الأدوات
enum ToolCat {
  money('المال والسوق', 'المال والسوق', 'Money & Market', Icons.payments_rounded),
  islam('دين ودنيا', 'الدين', 'Faith', Icons.mosque_rounded),
  life('تنظيم حياتك', 'تنظيم الحياة', 'Organize', Icons.checklist_rounded),
  work('الشغل والغربة', 'العمل والاغتراب', 'Work & Abroad', Icons.work_rounded),
  home('البيت والزراعة', 'المنزل والزراعة', 'Home & Farm', Icons.cottage_rounded),
  daily('يومياتك', 'اليوميات', 'Daily', Icons.wb_sunny_rounded),
  health('صحتك', 'الصحة', 'Health', Icons.favorite_rounded),
  media('نصوص وصور', 'نصوص وصور', 'Text & Images', Icons.text_snippet_rounded),
  device('جهازك', 'الجهاز', 'Device', Icons.smartphone_rounded);

  final String sd, ar, en;
  final IconData icon;
  const ToolCat(this.sd, this.ar, this.en, this.icon);
  String get label => t(sd, ar, en);
}

/// تعريف أداة
class ToolDef {
  final String id, name, sub;
  final ToolCat cat;
  final IconData icon;
  final Color color;

  /// أداة مخصصة للسودان (تظهر عليها علامة العلم)
  final bool sudan;

  /// لا تظهر في قائمة الأدوات (تُفتح من مكان آخر، مثل الطقس من البيت)
  final bool hidden;

  /// كلمات بحث إضافية
  final String keywords;
  final WidgetBuilder builder;

  const ToolDef({
    required this.id,
    required this.name,
    required this.sub,
    required this.cat,
    required this.icon,
    required this.color,
    required this.builder,
    this.sudan = false,
    this.hidden = false,
    this.keywords = '',
  });
}

/// تُبنى من جديد عند كل استدعاء حتى تتبع لغة التطبيق
List<ToolDef> get allTools => [
      ...moneyTools, ...workTools, ...islamTools, ...deenTools, ...lifeTools, ...homeTools,
      ...dailyTools, ...moreTools, ...plusTools, ...writerTools, ...mediaTools, ...deviceTools,
    ];

ToolDef? toolById(String id) {
  for (final t in allTools) {
    if (t.id == id) return t;
  }
  return null;
}
