import 'package:flutter/material.dart';
import '../../core/i18n.dart';
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

List<ToolDef> get moneyTools => [
  ToolDef(id: 'currency', name: t('الدولار والعملات', 'الدولار والعملات', 'Dollar & Currencies'), sub: t('الموازي والرسمي', 'السوق الموازية والسعر الرسمي', 'Parallel & official rates'), cat: ToolCat.money, icon: Icons.currency_exchange_rounded,
      color: SD.green, sudan: true, keywords: 'دولار ريال جنيه صرف عملة سوق موازي بنكك dollar currency exchange rate parallel market sdg', builder: (_) => const CurrencyTool()),
  ToolDef(id: 'remit', name: t('تحويلات المغتربين', 'تحويلات المغتربين', 'Expat Remittances'), sub: t('كم بيصل لأهلك؟', 'كم يصل إلى أهلك؟', 'How much reaches home?'), cat: ToolCat.money, icon: Icons.send_rounded,
      color: SD.nile, sudan: true, keywords: 'تحويل مغترب ريال سعودية رسوم remittance transfer expat fees riyal', builder: (_) => const RemitTool()),
  ToolDef(id: 'gold', name: t('الدهب', 'الذهب', 'Gold'), sub: t('العيارات والقيمة', 'العيارات والقيمة', 'Karats & value'), cat: ToolCat.money, icon: Icons.diamond_rounded,
      color: SD.gold, sudan: true, keywords: 'ذهب عيار 21 جرام دهب gold karat gram price', builder: (_) => const GoldTool()),
  ToolDef(id: 'zakat', name: tr('الزكاة', 'Zakat'), sub: t('قروش، زروع، بهائم', 'مال، زروع، أنعام', 'Money, crops, livestock'), cat: ToolCat.money, icon: Icons.volunteer_activism_rounded,
      color: SD.teal, keywords: 'زكاة نصاب بهائم غنم بقر ابل زرع zakat nisab livestock sheep cattle camels crops', builder: (_) => const ZakatTool()),
  ToolDef(id: 'power', name: t('الكهربا والشمسية', 'الكهرباء والطاقة الشمسية', 'Power & Solar'), sub: t('الاستهلاك والمنظومة', 'الاستهلاك والمنظومة', 'Usage & system sizing'), cat: ToolCat.money, icon: Icons.solar_power_rounded,
      color: SD.orange, sudan: true, keywords: 'كهرباء طاقة شمسية انفرتر بطارية الواح مولد جازولين electricity solar inverter battery panels generator diesel', builder: (_) => const PowerTool()),
  ToolDef(id: 'units', name: tr('محوّل الوحدات', 'Unit Converter'), sub: t('فدان، جوال، جركانة', 'فدان، جوال، جركن', 'Feddan, sack, jerrycan'), cat: ToolCat.money, icon: Icons.straighten_rounded,
      color: SD.henna, sudan: true, keywords: 'فدان قيراط متر وزن طول حجم جوال جركانة unit convert feddan length weight volume area', builder: (_) => const UnitsTool()),
  ToolDef(id: 'loan', name: tr('الأقساط والمرابحة', 'Installments & Murabaha'), sub: tr('القسط الشهري', 'Monthly payment'), cat: ToolCat.money, icon: Icons.account_balance_rounded,
      color: SD.indigo, keywords: 'قسط قرض مرابحة تمويل بنك loan installment murabaha finance bank', builder: (_) => const LoanTool()),
  ToolDef(id: 'percent', name: tr('النسب والضريبة', 'Percent & Tax'), sub: tr('خصم، ربح، ضريبة', 'Discount, profit, VAT'), cat: ToolCat.money, icon: Icons.percent_rounded,
      color: SD.pink, keywords: 'نسبة ضريبة خصم ربح تخفيض percent tax vat discount profit', builder: (_) => const PercentTool()),
  ToolDef(id: 'split', name: t('قسمة الحساب', 'تقسيم الحساب', 'Bill Splitter'), sub: t('الفطور والرحلات', 'الوجبات والرحلات', 'Meals & trips'), cat: ToolCat.money, icon: Icons.groups_rounded,
      color: SD.purple, keywords: 'قسمة حساب كشف شلة رحلة split bill trip group share', builder: (_) => const SplitTool()),
  ToolDef(id: 'tafqeet', name: tr('تفقيط المبالغ', 'Amount in Words'), sub: tr('الرقم بالحروف', 'Number to words'), cat: ToolCat.money, icon: Icons.spellcheck_rounded,
      color: SD.coffee, sudan: true, keywords: 'تفقيط شيك فاتورة كتابة رقم حروف cheque check invoice number words', builder: (_) => const TafqeetTool()),
];
