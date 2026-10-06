import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'child_growth_tool.dart';
import 'proverbs_tool.dart';
import 'sizes_tool.dart';
import 'vitals_tool.dart';

List<ToolDef> get plusTools => [
      ToolDef(
          id: 'vitals',
          name: t('سجل السكر والضغط', 'سجل السكر والضغط', 'Glucose & BP Log'),
          sub: t('قراءاتك ورسم وتقرير للدكتور', 'قراءاتك ورسم وتقرير للطبيب', 'Readings, charts & doctor report'),
          cat: ToolCat.health,
          icon: Icons.monitor_heart_rounded,
          color: SD.red,
          keywords: 'سكر ضغط دم قراءة صائم فاطر جهاز سكري نبض انقباضي انبساطي تقرير دكتور glucose sugar blood pressure bp diabetes pulse systolic diastolic log mmol mg/dl',
          builder: (_) => const VitalsTool()),
      ToolDef(
          id: 'child_growth',
          name: t('متابعة نمو الطفل', 'متابعة نمو الطفل', 'Child Growth'),
          sub: t('الوزن والطول والتطعيم', 'الوزن والطول والتطعيمات', 'Weight, height & vaccines'),
          cat: ToolCat.health,
          icon: Icons.child_care_rounded,
          color: SD.teal,
          keywords: 'طفل نمو وزن طول محيط راس رأس رضيع شهور تطعيم عيادة child baby growth weight height length head circumference vaccine vaccination infant',
          builder: (_) => const ChildGrowthTool()),
      ToolDef(
          id: 'sizes',
          name: t('محوّل المقاسات', 'محوّل المقاسات', 'Size Converter'),
          sub: t('جزم وهدوم وخواتم', 'أحذية وملابس وخواتم', 'Shoes, clothes & rings'),
          cat: ToolCat.daily,
          icon: Icons.checkroom_rounded,
          color: SD.coffee,
          keywords: 'مقاس مقاسات جزمة حذاء هدوم ملابس قميص فستان خاتم أطفال اوروبي امريكي size sizes shoe clothes shirt dress ring kids eu us uk converter',
          builder: (_) => const SizesTool()),
      ToolDef(
          id: 'proverbs',
          name: t('الأمثال السودانية', 'الأمثال السودانية', 'Sudanese Proverbs'),
          sub: t('مثل ومعناه كل يوم', 'مثل ومعناه كل يوم', 'A proverb a day, with meaning'),
          cat: ToolCat.daily,
          icon: Icons.format_quote_rounded,
          color: SD.gold,
          sudan: true,
          keywords: 'مثل أمثال حكمة تراث سوداني شعبي قول proverb proverbs saying wisdom sudanese heritage folk',
          builder: (_) => const ProverbsTool()),
    ];
