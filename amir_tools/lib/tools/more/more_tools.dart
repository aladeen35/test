import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'best_price_tool.dart';
import 'gpa_tool.dart';
import 'khatma_tool.dart';
import 'medicine_tool.dart';
import 'trip_cost_tool.dart';
import 'world_clock_tool.dart';

List<ToolDef> get moreTools => [
  ToolDef(id: 'world_clock', name: tr('ساعات العالم', 'World Clock'), sub: t('الساعة كم عند أهلك؟', 'كم الساعة عند أهلك؟', "What time is it for family?"), cat: ToolCat.daily,
      icon: Icons.public_rounded, color: SD.nile,
      keywords: 'ساعة عالم توقيت فرق وقت مغترب اتصال اهل منطقة زمنية world clock time zone difference call family expat',
      builder: (_) => const WorldClockTool()),
  ToolDef(id: 'khatma', name: tr('ختمة القرآن', 'Qur\'an Khatma'), sub: t('خطة وورد يومي', 'خطة وورد يومي', 'Plan & daily portion'), cat: ToolCat.quran,
      icon: Icons.auto_stories_rounded, color: SD.green,
      keywords: 'ختمة قرآن مصحف ورد جزء حزب صفحة رمضان تلاوة khatma quran juz hizb page ramadan reading plan',
      builder: (_) => const KhatmaTool()),
  ToolDef(id: 'medicine', name: tr('مواعيد الدواء', 'Medicine Reminders'), sub: t('ما تنسى جرعتك', 'لا تنسَ جرعتك', "Never miss a dose"), cat: ToolCat.health,
      icon: Icons.medication_rounded, color: SD.teal,
      keywords: 'دواء علاج جرعة حبوب منبه تذكير صيدلية medicine pill dose reminder pharmacy medication',
      builder: (_) => const MedicineTool()),
  ToolDef(id: 'best_price', name: tr('أيهما أوفر؟', 'Best Price'), sub: t('الجوال ولا بالقطاعي؟', 'الجملة أم التجزئة؟', 'Bulk or retail?'), cat: ToolCat.money,
      icon: Icons.price_check_rounded, color: SD.orange,
      keywords: 'أوفر ارخص سعر كيلو لتر جملة قطاعي جوال مقارنة سوق best price compare cheaper unit price bulk per kg',
      builder: (_) => const BestPriceTool()),
  ToolDef(id: 'trip_cost', name: t('تكلفة المشوار', 'تكلفة الرحلة', 'Trip Cost'), sub: t('البنزين والقسمة', 'الوقود والتقسيم', 'Fuel & split'), cat: ToolCat.money,
      icon: Icons.local_gas_station_rounded, color: SD.henna,
      keywords: 'مشوار سفر رحلة بنزين جازولين ديزل وقود جالون مسافة كيلو trip travel fuel petrol diesel gas distance cost',
      builder: (_) => const TripCostTool()),
  ToolDef(id: 'gpa', name: tr('المعدل الدراسي', 'GPA Calculator'), sub: t('الجامعة والمدرسة', 'الجامعة والمدرسة', 'University & school'), cat: ToolCat.daily,
      icon: Icons.school_rounded, color: SD.indigo,
      keywords: 'معدل تراكمي جامعة مدرسة نسبة درجات شهادة تقدير gpa grade percentage university school cumulative',
      builder: (_) => const GpaTool()),
];
