import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'month_budget_tool.dart';
import 'shop_tool.dart';
import 'udhiya_tool.dart';
import 'wedding_tool.dart';

List<ToolDef> get bizTools => [
      ToolDef(
        id: 'wedding_budget',
        name: t('ميزانية العرس', 'ميزانية الزفاف', 'Wedding Budget'),
        sub: t('الشيلة والصالة والنقطة', 'البنود والمدفوعات والمساهمات', 'Items, payments & contributions'),
        cat: ToolCat.money,
        icon: Icons.favorite_rounded,
        color: SD.henna,
        sudan: true,
        keywords: 'عرس زواج زفاف ميزانية شيلة قولة خطوبة مهر صالة صيوان فنان ساوند ضيافة عشاء حنة جرتق دهب ذهب هدايا تجهيز بيت نقطة مساهمات wedding marriage budget dowry mahr hall henna jirtig gold gifts contributions planner',
        builder: (_) => const WeddingTool(),
      ),
      ToolDef(
        id: 'shop_ledger',
        name: t('دفتر الدكان', 'دفتر المحل', 'Shop Ledger'),
        sub: t('المخزن والبيع والربح', 'المخزون والمبيعات والأرباح', 'Stock, sales & profit'),
        cat: ToolCat.money,
        icon: Icons.storefront_rounded,
        color: SD.coffee,
        keywords: 'دكان محل بقالة دفتر مخزن مخزون بيع مبيعات ربح أرباح هامش تكلفة جملة سعر تسعير بضاعة shop store ledger inventory stock sales profit margin markup cost price pricing calculator',
        builder: (_) => const ShopTool(),
      ),
      ToolDef(
        id: 'month_budget',
        name: t('ميزانية الشهر', 'الميزانية الشهرية', 'Monthly Budget'),
        sub: t('قسّم الماهية على ظروف', 'وزّع الدخل على ظروف', 'Split income into envelopes'),
        cat: ToolCat.money,
        icon: Icons.mail_rounded,
        color: SD.indigo,
        keywords: 'ميزانية شهر شهرية ماهية راتب دخل ظروف مصروف صرف توفير ادخار إيجار أكل مدارس تحويل أهل صدقة 50/30/20 budget monthly envelopes income salary spending savings rent food school family charity',
        builder: (_) => const MonthBudgetTool(),
      ),
      ToolDef(
        id: 'udhiya',
        name: t('الضحية والسماية', 'الأضحية والعقيقة', 'Udhiya & Aqiqa'),
        sub: t('الشراكة والشروط وموعد العيد', 'الاشتراك والشروط وموعد العيد', 'Shares, conditions & Eid date'),
        cat: ToolCat.islam,
        icon: Icons.pets_rounded,
        color: SD.green,
        keywords: 'أضحية اضحية ضحية عقيقة سماية عيد الأضحى خروف ضأن معز بقر جمل إبل شراكة سبعة شروط عيوب ذو الحجة ذبح مولود udhiya qurbani aqiqa eid adha sacrifice sheep goat cow camel share dhul hijjah newborn',
        builder: (_) => const UdhiyaTool(),
      ),
    ];
