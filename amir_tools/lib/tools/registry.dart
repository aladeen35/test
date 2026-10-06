import 'package:flutter/material.dart';
import 'money/money_tools.dart';
import 'islam/islam_tools.dart';
import 'daily/daily_tools.dart';
import 'media/media_tools.dart';
import 'device/device_tools.dart';

/// تصنيفات الأدوات
enum ToolCat {
  money('المال والسوق', Icons.payments_rounded),
  islam('دين ودنيا', Icons.mosque_rounded),
  daily('يومياتك', Icons.wb_sunny_rounded),
  health('صحتك', Icons.favorite_rounded),
  media('نصوص وصور', Icons.text_snippet_rounded),
  device('جهازك', Icons.smartphone_rounded);

  final String label;
  final IconData icon;
  const ToolCat(this.label, this.icon);
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

final List<ToolDef> allTools = [...moneyTools, ...islamTools, ...dailyTools, ...mediaTools, ...deviceTools];

ToolDef? toolById(String id) {
  for (final t in allTools) {
    if (t.id == id) return t;
  }
  return null;
}
