import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/i18n.dart';
import '../registry.dart';
import 'compass_tool.dart';
import 'flashlight_tool.dart';
import 'level_tool.dart';
import 'noise_tool.dart';
import 'phone_tool.dart';
import 'ruler_tool.dart';

List<ToolDef> get deviceTools => [
  ToolDef(id: 'flashlight', name: tr('الكشاف', 'Flashlight'), sub: t('لقطوعات الكهرباء', 'لانقطاع الكهرباء', 'For power cuts'), cat: ToolCat.device, icon: Icons.flashlight_on_rounded,
      color: SD.gold, sudan: true, keywords: 'كشاف بطارية فلاش ضو نور قطوعة flashlight torch light flash sos power cut', builder: (_) => const FlashlightTool()),
  ToolDef(id: 'phone', name: t('تلفوني', 'هاتفي', 'My Phone'), sub: tr('بطارية وجودة', 'Battery & health'), cat: ToolCat.device, icon: Icons.phone_android_rounded,
      color: SD.teal, keywords: 'تلفون هاتف بطارية رام ذاكرة جهاز phone battery ram memory device info', builder: (_) => const PhoneTool()),
  ToolDef(id: 'compass', name: tr('البوصلة والموقع', 'Compass & Location'), sub: tr('الاتجاه والإحداثيات', 'Heading & coordinates'), cat: ToolCat.device, icon: Icons.explore_rounded,
      color: SD.red, keywords: 'بوصلة موقع gps احداثيات خريطة compass location coordinates map heading north', builder: (_) => const CompassTool()),
  ToolDef(id: 'level', name: t('ميزان الموية', 'ميزان الماء', 'Spirit Level'), sub: tr('للبناء والتركيب', 'For building & fitting'), cat: ToolCat.device, icon: Icons.architecture_rounded,
      color: SD.green, keywords: 'ميزان استواء بناء بلاط level spirit bubble tilt angle', builder: (_) => const LevelTool()),
  ToolDef(id: 'ruler', name: tr('المسطرة', 'Ruler'), sub: tr('سم وبوصة', 'cm & inch'), cat: ToolCat.device, icon: Icons.square_foot_rounded,
      color: SD.henna, keywords: 'مسطرة قياس طول سم ruler measure length cm inch', builder: (_) => const RulerTool()),
  ToolDef(id: 'noise', name: tr('مقياس الضوضاء', 'Noise Meter'), sub: tr('ديسيبل', 'Decibels'), cat: ToolCat.device, icon: Icons.graphic_eq_rounded,
      color: SD.purple, keywords: 'ضوضاء صوت ازعاج ديسيبل noise sound decibel db loud meter', builder: (_) => const NoiseTool()),
];
