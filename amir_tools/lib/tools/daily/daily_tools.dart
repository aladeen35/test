import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/i18n.dart';
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

List<ToolDef> get dailyTools => [
  ToolDef(id: 'age', name: tr('حاسبة العمر', 'Age calculator'), sub: t('بالتفصيل الممل', 'بالتفصيل الدقيق', 'In every detail'), cat: ToolCat.daily, icon: Icons.cake_rounded,
      color: SD.pink, keywords: 'عمر ميلاد سنة كواكب برج age birthday birth year planets zodiac', builder: (_) => const AgeTool()),
  ToolDef(id: 'calc', name: tr('الآلة الحاسبة', 'Calculator'), sub: tr('علمية', 'Scientific'), cat: ToolCat.daily, icon: Icons.calculate_rounded,
      color: SD.black, keywords: 'حاسبة حساب calculator math scientific', builder: (_) => const CalcTool()),
  ToolDef(id: 'timer', name: tr('المؤقت', 'Timer'), sub: tr('وساعة الإيقاف', 'and stopwatch'), cat: ToolCat.daily, icon: Icons.timer_rounded,
      color: SD.nile, keywords: 'مؤقت ساعة ايقاف منبه وقت timer stopwatch alarm countdown time', builder: (_) => const TimerTool()),
  ToolDef(id: 'focus', name: tr('التركيز', 'Focus'), sub: tr('جلسات بومودورو', 'Pomodoro sessions'), cat: ToolCat.daily, icon: Icons.center_focus_strong_rounded,
      color: SD.purple, keywords: 'تركيز مذاكرة بومودورو focus study pomodoro', builder: (_) => const FocusTool()),
  ToolDef(id: 'random', name: tr('القرعة', 'Random draw'), sub: tr('أسماء، نرد، عملة', 'Names, dice, coin'), cat: ToolCat.daily, icon: Icons.casino_rounded,
      color: SD.orange, keywords: 'قرعة صندوق ختة نرد عشوائي random draw lottery dice coin flip picker', builder: (_) => const RandomTool()),
  ToolDef(id: 'contacts', name: tr('أرقام مهمة', 'Important numbers'), sub: tr('اتصال سريع', 'Quick dial'), cat: ToolCat.daily, icon: Icons.contact_phone_rounded,
      color: SD.green, keywords: 'ارقام اتصال واتساب طوارئ contacts phone call whatsapp emergency', builder: (_) => const ContactsTool()),
  ToolDef(id: 'weather', name: tr('الطقس والغبار', 'Weather & dust'), sub: t('الهبوب والحرارة', 'العواصف الترابية والحرارة', 'Dust storms and heat'), cat: ToolCat.daily, icon: Icons.cloud_rounded,
      color: SD.nileLight, sudan: true, keywords: 'طقس حرارة غبار هبوب مطر weather temperature dust haboob rain forecast', builder: (_) => const WeatherTool()),
  ToolDef(id: 'water', name: t('الموية', 'الماء', 'Water'), sub: t('كم شربت الليلة؟', 'كم شربت اليوم؟', 'How much today?'), cat: ToolCat.health, icon: Icons.water_drop_rounded,
      color: SD.nileLight, keywords: 'موية ماء شرب water drink hydration', builder: (_) => const WaterTool()),
  ToolDef(id: 'sleep_mood', name: tr('النوم والمزاج', 'Sleep & mood'), sub: tr('سجّل يومك', 'Log your day'), cat: ToolCat.health, icon: Icons.bedtime_rounded,
      color: SD.indigo, keywords: 'نوم مزاج sleep mood journal', builder: (_) => const SleepMoodTool()),
  ToolDef(id: 'health', name: tr('حاسبة الصحة', 'Health calculator'), sub: tr('الوزن والسعرات', 'Weight and calories'), cat: ToolCat.health, icon: Icons.monitor_heart_rounded,
      color: SD.red, keywords: 'وزن طول كتلة سعرات صحة رجيم weight height bmi calories health diet', builder: (_) => const HealthTool()),
  ToolDef(id: 'pregnancy', name: tr('حاسبة الحمل', 'Pregnancy calculator'), sub: tr('موعد الولادة', 'Due date'), cat: ToolCat.health, icon: Icons.pregnant_woman_rounded,
      color: SD.pink, keywords: 'حمل ولادة اسابيع pregnancy due date weeks', builder: (_) => const PregnancyTool()),
];
