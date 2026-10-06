import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'adhkar_tool.dart';
import 'dates_tool.dart';
import 'monthly_tool.dart';
import 'names99_tool.dart';
import 'occasions_tool.dart';
import 'qibla_tool.dart';
import 'tasbih_tool.dart';

final List<ToolDef> islamTools = [
  ToolDef(id: 'qibla', name: 'القبلة', sub: 'بوصلة الكعبة', cat: ToolCat.islam, icon: Icons.explore_rounded,
      color: SD.green, keywords: 'قبلة بوصلة كعبة اتجاه', builder: (_) => const QiblaTool()),
  ToolDef(id: 'adhkar', name: 'الأذكار', sub: 'صباح، مساء، نوم', cat: ToolCat.islam, icon: Icons.auto_stories_rounded,
      color: SD.teal, keywords: 'اذكار صباح مساء نوم صلاة', builder: (_) => const AdhkarTool()),
  ToolDef(id: 'tasbih', name: 'المسبحة', sub: 'سبحة إلكترونية', cat: ToolCat.islam, icon: Icons.blur_circular_rounded,
      color: SD.gold, keywords: 'سبحة تسبيح استغفار', builder: (_) => const TasbihTool()),
  ToolDef(id: 'monthly', name: 'المواقيت الشهرية', sub: 'وإمساكية رمضان', cat: ToolCat.islam, icon: Icons.calendar_month_rounded,
      color: SD.nile, keywords: 'امساكية رمضان مواقيت شهر جدول', builder: (_) => const MonthlyTool()),
  ToolDef(id: 'dates', name: 'محوّل التواريخ', sub: 'هجري، قبطي، إثيوبي', cat: ToolCat.islam, icon: Icons.event_repeat_rounded,
      color: SD.indigo, keywords: 'تاريخ هجري ميلادي قبطي اثيوبي تحويل', builder: (_) => const DatesTool()),
  ToolDef(id: 'occasions', name: 'المناسبات', sub: 'رمضان، العيد، مواعيدك', cat: ToolCat.islam, icon: Icons.celebration_rounded,
      color: SD.henna, keywords: 'رمضان عيد عرفة مناسبة عداد', builder: (_) => const OccasionsTool()),
  ToolDef(id: 'names99', name: 'أسماء الله الحسنى', sub: 'التسعة وتسعين', cat: ToolCat.islam, icon: Icons.star_rounded,
      color: SD.purple, keywords: 'اسماء الله الحسنى', builder: (_) => const Names99Tool()),
];
