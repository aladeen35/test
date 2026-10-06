import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'compass_tool.dart';
import 'flashlight_tool.dart';
import 'level_tool.dart';
import 'noise_tool.dart';
import 'phone_tool.dart';
import 'ruler_tool.dart';

final List<ToolDef> deviceTools = [
  ToolDef(id: 'flashlight', name: 'الكشاف', sub: 'لقطوعات الكهرباء', cat: ToolCat.device, icon: Icons.flashlight_on_rounded,
      color: SD.gold, sudan: true, keywords: 'كشاف بطارية فلاش ضو نور قطوعة', builder: (_) => const FlashlightTool()),
  ToolDef(id: 'phone', name: 'هاتفي', sub: 'بطارية وجودة', cat: ToolCat.device, icon: Icons.phone_android_rounded,
      color: SD.teal, keywords: 'تلفون بطارية رام ذاكرة جهاز', builder: (_) => const PhoneTool()),
  ToolDef(id: 'compass', name: 'البوصلة والموقع', sub: 'الاتجاه والإحداثيات', cat: ToolCat.device, icon: Icons.explore_rounded,
      color: SD.red, keywords: 'بوصلة موقع gps احداثيات خريطة', builder: (_) => const CompassTool()),
  ToolDef(id: 'level', name: 'ميزان الموية', sub: 'للبناء والتركيب', cat: ToolCat.device, icon: Icons.architecture_rounded,
      color: SD.green, keywords: 'ميزان استواء بناء بلاط', builder: (_) => const LevelTool()),
  ToolDef(id: 'ruler', name: 'المسطرة', sub: 'سم وبوصة', cat: ToolCat.device, icon: Icons.square_foot_rounded,
      color: SD.henna, keywords: 'مسطرة قياس طول سم', builder: (_) => const RulerTool()),
  ToolDef(id: 'noise', name: 'مقياس الضوضاء', sub: 'ديسيبل', cat: ToolCat.device, icon: Icons.graphic_eq_rounded,
      color: SD.purple, keywords: 'ضوضاء صوت ازعاج ديسيبل', builder: (_) => const NoiseTool()),
];
