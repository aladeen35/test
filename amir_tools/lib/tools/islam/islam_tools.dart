import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/i18n.dart';
import '../registry.dart';
import 'adhkar_tool.dart';
import 'dates_tool.dart';
import 'monthly_tool.dart';
import 'names99_tool.dart';
import 'occasions_tool.dart';
import 'qibla_tool.dart';
import 'tasbih_tool.dart';

List<ToolDef> get islamTools => [
  ToolDef(id: 'qibla', name: tr('القبلة', 'Qibla'), sub: tr('بوصلة الكعبة', 'Kaaba compass'), cat: ToolCat.islam, icon: Icons.explore_rounded,
      color: SD.green, keywords: 'قبلة بوصلة كعبة اتجاه qibla compass kaaba direction mecca', builder: (_) => const QiblaTool()),
  ToolDef(id: 'adhkar', name: tr('الأذكار', 'Adhkar'), sub: tr('صباح، مساء، نوم', 'Morning, evening, sleep'), cat: ToolCat.islam, icon: Icons.auto_stories_rounded,
      color: SD.teal, keywords: 'اذكار صباح مساء نوم صلاة adhkar azkar dhikr morning evening sleep prayer', builder: (_) => const AdhkarTool()),
  ToolDef(id: 'tasbih', name: tr('المسبحة', 'Tasbih'), sub: tr('سبحة إلكترونية', 'Digital prayer beads'), cat: ToolCat.islam, icon: Icons.blur_circular_rounded,
      color: SD.gold, keywords: 'سبحة تسبيح استغفار tasbih beads counter dhikr', builder: (_) => const TasbihTool()),
  ToolDef(id: 'monthly', name: t('المواقيت الشهرية', 'المواقيت الشهرية', 'Monthly prayer times'), sub: tr('وإمساكية رمضان', 'and Ramadan timetable'), cat: ToolCat.islam, icon: Icons.calendar_month_rounded,
      color: SD.nile, keywords: 'امساكية رمضان مواقيت شهر جدول prayer times monthly ramadan timetable imsakiya', builder: (_) => const MonthlyTool()),
  ToolDef(id: 'dates', name: tr('محوّل التواريخ', 'Date converter'), sub: tr('هجري، قبطي، إثيوبي', 'Hijri, Coptic, Ethiopian'), cat: ToolCat.islam, icon: Icons.event_repeat_rounded,
      color: SD.indigo, keywords: 'تاريخ هجري ميلادي قبطي اثيوبي تحويل date hijri gregorian coptic ethiopian convert calendar', builder: (_) => const DatesTool()),
  ToolDef(id: 'occasions', name: tr('المناسبات', 'Occasions'), sub: t('رمضان، العيد، مواعيدك', 'رمضان، العيد، مواعيدك', 'Ramadan, Eid, your dates'), cat: ToolCat.islam, icon: Icons.celebration_rounded,
      color: SD.henna, keywords: 'رمضان عيد عرفة مناسبة عداد ramadan eid arafah occasion countdown', builder: (_) => const OccasionsTool()),
  ToolDef(id: 'names99', name: tr('أسماء الله الحسنى', 'Names of Allah'), sub: t('التسعة وتسعين', 'التسعة والتسعون', 'The 99 names'), cat: ToolCat.islam, icon: Icons.star_rounded,
      color: SD.purple, keywords: 'اسماء الله الحسنى 99 names of allah asma ul husna', builder: (_) => const Names99Tool()),
];
