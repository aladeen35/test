import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'car_care_tool.dart';
import 'gas_tool.dart';
import 'generator_tool.dart';
import 'pantry_tool.dart';
import 'power_cuts_tool.dart';

List<ToolDef> get homeplusTools => [
      ToolDef(
        id: 'gas',
        name: t('أنبوبة الغاز', 'أسطوانة الغاز', 'Gas Cylinder'),
        sub: t('متين بتكمل وبتكلّفك كم', 'متى تنفد وكم تكلّف', 'When it runs out & what it costs'),
        cat: ToolCat.home,
        icon: Icons.propane_tank_rounded,
        color: SD.orange,
        keywords: 'غاز أنبوبة انبوبة اسطوانة أسطوانة بوتجاز تعبئة كيلو مطبخ نفاد تذكير سعر gas cylinder lpg propane butane refill cooking kitchen run out reminder price',
        builder: (_) => const GasTool(),
      ),
      ToolDef(
        id: 'generator',
        name: t('المولّد والوقود', 'المولد والوقود', 'Generator & Fuel'),
        sub: t('جازولين كم وزيت متين', 'استهلاك الوقود وموعد الزيت', 'Fuel use & oil-change hours'),
        cat: ToolCat.home,
        icon: Icons.electrical_services_rounded,
        color: SD.teal,
        keywords: 'مولد مولّد جنريتر جازولين ديزل بنزين وقود لتر ساعة زيت كيلوواط kva استهلاك generator genset fuel diesel petrol gasoline litre hour oil change kw kva consumption',
        builder: (_) => const GeneratorTool(),
      ),
      ToolDef(
        id: 'car_care',
        name: t('صيانة العربية', 'صيانة السيارة', 'Car Maintenance'),
        sub: t('الزيت والفلاتر والترخيص', 'الزيت والفلاتر والترخيص', 'Oil, filters & licence'),
        cat: ToolCat.home,
        icon: Icons.car_repair_rounded,
        color: SD.nile,
        keywords: 'عربية سيارة صيانة زيت فلتر هواء لساتك اطارات إطارات بطارية فرامل فحمات ترخيص تأمين عداد كيلو ورشة car vehicle maintenance service oil filter tyres tires battery brakes licence insurance odometer km workshop',
        builder: (_) => const CarCareTool(),
      ),
      ToolDef(
        id: 'power_cuts',
        name: t('جدول قطوعات الكهرباء', 'جدول انقطاع الكهرباء', 'Power-cut Schedule'),
        sub: t('متين بتقطع ومتين بتجي', 'متى تنقطع ومتى تعود', 'When it goes off & comes back'),
        cat: ToolCat.home,
        icon: Icons.power_off_rounded,
        color: SD.gold,
        keywords: 'قطوعات قطوعة كهرباء انقطاع جدول برمجة تيار نور تنبيه power cut outage load shedding electricity schedule blackout reminder',
        builder: (_) => const PowerCutsTool(),
      ),
      ToolDef(
        id: 'pantry',
        name: t('صلاحية مخزن البيت', 'صلاحية مخزن المنزل', 'Pantry Expiry'),
        sub: t('الأكل والدوا قبل ما ينتهي', 'الطعام والدواء قبل انتهاء الصلاحية', 'Food & medicine before they expire'),
        cat: ToolCat.home,
        icon: Icons.kitchen_rounded,
        color: SD.green,
        keywords: 'مخزن صلاحية انتهاء تاريخ أكل طعام دواء دوا تجميل معلبات بقالة تنبيه pantry expiry expiration date food medicine cosmetics groceries best before reminder',
        builder: (_) => const PantryTool(),
      ),
    ];
