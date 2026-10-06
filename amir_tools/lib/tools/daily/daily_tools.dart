import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'age_tool.dart';
import 'calc_tool.dart';
import 'contacts_tool.dart';
import 'focus_tool.dart';
import 'health_tool.dart';
import 'pregnancy_tool.dart';
import 'random_tool.dart';
import 'sleep_mood_tool.dart';
import 'timer_tool.dart';
import 'water_tool.dart';
import 'weather_tool.dart';

final List<ToolDef> dailyTools = [
  ToolDef(id: 'age', name: 'حاسبة العمر', sub: 'بالتفصيل الممل', cat: ToolCat.daily, icon: Icons.cake_rounded,
      color: SD.pink, keywords: 'عمر ميلاد سنة كواكب برج', builder: (_) => const AgeTool()),
  ToolDef(id: 'calc', name: 'الآلة الحاسبة', sub: 'علمية', cat: ToolCat.daily, icon: Icons.calculate_rounded,
      color: SD.black, keywords: 'حاسبة حساب', builder: (_) => const CalcTool()),
  ToolDef(id: 'timer', name: 'المؤقت', sub: 'وساعة الإيقاف', cat: ToolCat.daily, icon: Icons.timer_rounded,
      color: SD.nile, keywords: 'مؤقت ساعة ايقاف منبه وقت', builder: (_) => const TimerTool()),
  ToolDef(id: 'focus', name: 'التركيز', sub: 'جلسات بومودورو', cat: ToolCat.daily, icon: Icons.center_focus_strong_rounded,
      color: SD.purple, keywords: 'تركيز مذاكرة بومودورو', builder: (_) => const FocusTool()),
  ToolDef(id: 'random', name: 'القرعة', sub: 'أسماء، نرد، عملة', cat: ToolCat.daily, icon: Icons.casino_rounded,
      color: SD.orange, keywords: 'قرعة صندوق ختة نرد عشوائي', builder: (_) => const RandomTool()),
  ToolDef(id: 'contacts', name: 'أرقام مهمة', sub: 'اتصال سريع', cat: ToolCat.daily, icon: Icons.contact_phone_rounded,
      color: SD.green, keywords: 'ارقام اتصال واتساب طوارئ', builder: (_) => const ContactsTool()),
  ToolDef(id: 'weather', name: 'الطقس والغبار', sub: 'الهبوب والحرارة', cat: ToolCat.daily, icon: Icons.cloud_rounded,
      color: SD.nileLight, sudan: true, keywords: 'طقس حرارة غبار هبوب مطر', builder: (_) => const WeatherTool()),
  ToolDef(id: 'water', name: 'الموية', sub: 'كم شربت الليلة؟', cat: ToolCat.health, icon: Icons.water_drop_rounded,
      color: SD.nileLight, keywords: 'موية ماء شرب', builder: (_) => const WaterTool()),
  ToolDef(id: 'sleep_mood', name: 'النوم والمزاج', sub: 'سجّل يومك', cat: ToolCat.health, icon: Icons.bedtime_rounded,
      color: SD.indigo, keywords: 'نوم مزاج', builder: (_) => const SleepMoodTool()),
  ToolDef(id: 'health', name: 'حاسبة الصحة', sub: 'الوزن والسعرات', cat: ToolCat.health, icon: Icons.monitor_heart_rounded,
      color: SD.red, keywords: 'وزن طول كتلة سعرات صحة رجيم', builder: (_) => const HealthTool()),
  ToolDef(id: 'pregnancy', name: 'حاسبة الحمل', sub: 'موعد الولادة', cat: ToolCat.health, icon: Icons.pregnant_woman_rounded,
      color: SD.pink, keywords: 'حمل ولادة اسابيع', builder: (_) => const PregnancyTool()),
];
