import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'currency_tool.dart';
import 'gold_tool.dart';
import 'loan_tool.dart';
import 'percent_tool.dart';
import 'power_tool.dart';
import 'remit_tool.dart';
import 'split_tool.dart';
import 'tafqeet_tool.dart';
import 'units_tool.dart';
import 'zakat_tool.dart';

final List<ToolDef> moneyTools = [
  ToolDef(id: 'currency', name: 'الدولار والعملات', sub: 'الموازي والرسمي', cat: ToolCat.money, icon: Icons.currency_exchange_rounded,
      color: SD.green, sudan: true, keywords: 'دولار ريال جنيه صرف عملة سوق موازي بنكك', builder: (_) => const CurrencyTool()),
  ToolDef(id: 'remit', name: 'تحويلات المغتربين', sub: 'كم بيصل لأهلك؟', cat: ToolCat.money, icon: Icons.send_rounded,
      color: SD.nile, sudan: true, keywords: 'تحويل مغترب ريال سعودية رسوم', builder: (_) => const RemitTool()),
  ToolDef(id: 'gold', name: 'الذهب', sub: 'العيارات والقيمة', cat: ToolCat.money, icon: Icons.diamond_rounded,
      color: SD.gold, sudan: true, keywords: 'ذهب عيار 21 جرام دهب', builder: (_) => const GoldTool()),
  ToolDef(id: 'zakat', name: 'الزكاة', sub: 'مال، زروع، أنعام', cat: ToolCat.money, icon: Icons.volunteer_activism_rounded,
      color: SD.teal, keywords: 'زكاة نصاب بهائم غنم بقر ابل زرع', builder: (_) => const ZakatTool()),
  ToolDef(id: 'power', name: 'الكهرباء والشمسية', sub: 'الاستهلاك والمنظومة', cat: ToolCat.money, icon: Icons.solar_power_rounded,
      color: SD.orange, sudan: true, keywords: 'كهرباء طاقة شمسية انفرتر بطارية الواح مولد جازولين', builder: (_) => const PowerTool()),
  ToolDef(id: 'units', name: 'محوّل الوحدات', sub: 'فدان، جوال، جركانة', cat: ToolCat.money, icon: Icons.straighten_rounded,
      color: SD.henna, sudan: true, keywords: 'فدان قيراط متر وزن طول حجم جوال جركانة', builder: (_) => const UnitsTool()),
  ToolDef(id: 'loan', name: 'الأقساط والمرابحة', sub: 'القسط الشهري', cat: ToolCat.money, icon: Icons.account_balance_rounded,
      color: SD.indigo, keywords: 'قسط قرض مرابحة تمويل بنك', builder: (_) => const LoanTool()),
  ToolDef(id: 'percent', name: 'النسب والضريبة', sub: 'خصم، ربح، ضريبة', cat: ToolCat.money, icon: Icons.percent_rounded,
      color: SD.pink, keywords: 'نسبة ضريبة خصم ربح تخفيض', builder: (_) => const PercentTool()),
  ToolDef(id: 'split', name: 'قسمة الحساب', sub: 'الفطور والرحلات', cat: ToolCat.money, icon: Icons.groups_rounded,
      color: SD.purple, keywords: 'قسمة حساب كشف شلة رحلة', builder: (_) => const SplitTool()),
  ToolDef(id: 'tafqeet', name: 'تفقيط المبالغ', sub: 'الرقم بالحروف', cat: ToolCat.money, icon: Icons.spellcheck_rounded,
      color: SD.coffee, sudan: true, keywords: 'تفقيط شيك فاتورة كتابة رقم حروف', builder: (_) => const TafqeetTool()),
];
