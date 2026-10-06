import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'duas_tool.dart';
import 'fasting_tool.dart';
import 'inheritance_tool.dart';

List<ToolDef> get deenTools => [
      ToolDef(
        id: 'inheritance',
        name: tr('المواريث', 'Inheritance'),
        sub: t('قسمة التركة بالشرع', 'قسمة التركة شرعًا', 'Islamic estate shares'),
        cat: ToolCat.islam,
        icon: Icons.balance_rounded,
        color: SD.coffee,
        keywords: 'مواريث ميراث ورث تركة فرائض قسمة ورثة عول رد عصبة وصية inheritance estate faraid mirath heirs will wasiyya shares awl radd',
        builder: (_) => const InheritanceTool(),
      ),
      ToolDef(
        id: 'fasting',
        name: tr('متتبع الصيام', 'Fasting Tracker'),
        sub: t('القضاء وصيام السنّة', 'القضاء وصيام التطوع', 'Qada & sunnah fasts'),
        cat: ToolCat.islam,
        icon: Icons.nights_stay_rounded,
        color: SD.indigo,
        keywords: 'صيام صوم قضاء رمضان تطوع اثنين خميس أيام بيض عرفة عاشوراء شوال fasting fast qada ramadan sunnah monday thursday arafah ashura shawwal white days',
        builder: (_) => const FastingTool(),
      ),
      ToolDef(
        id: 'duas',
        name: tr('مكتبة الأدعية', 'Duas Library'),
        sub: t('أدعية صحيحة لكل مناسبة', 'أدعية مأثورة لكل مناسبة', 'Authentic duas for every occasion'),
        cat: ToolCat.islam,
        icon: Icons.menu_book_rounded,
        color: SD.green,
        keywords: 'دعاء أدعية استخارة سفر كرب مرض مطر نوم أكل وضوء استغفار والدين dua duas supplication istikhara travel distress sickness rain sleep forgiveness parents',
        builder: (_) => const DuasTool(),
      ),
    ];
