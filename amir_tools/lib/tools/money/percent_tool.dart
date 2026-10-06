import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

class PercentTool extends StatefulWidget {
  const PercentTool({super.key});
  @override
  State<PercentTool> createState() => _PercentToolState();
}

class _PercentToolState extends State<PercentTool> {
  final Map<String, TextEditingController> _c = {};
  static const _keys = ['vat', 'amount', 'price', 'disc', 'disc2', 'old', 'new', 'x', 'y', 'cost', 'sell', 'tMargin', 'tMarkup'];
  static const _defaults = {'vat': '17', 'amount': '1000', 'price': '50000', 'disc': '20', 'disc2': '', 'old': '1000', 'new': '1250',
    'x': '25', 'y': '200', 'cost': '8000', 'sell': '10000', 'tMargin': '20', 'tMarkup': '25'};
  bool _addTax = true;

  @override
  void initState() {
    super.initState();
    final d = Map<String, dynamic>.from(context.read<AppState>().getData<Map>('percent_inputs') ?? {});
    for (final k in _keys) {
      _c[k] = TextEditingController(text: (d[k] as String?) ?? _defaults[k] ?? '');
    }
    _addTax = d['addTax'] ?? true;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('percent_inputs', {for (final k in _keys) k: _c[k]!.text, 'addTax': _addTax});
    setState(() {});
  }

  double v(String k) => parseNum(_c[k]!.text);
  Widget f(String label, String k, {String? suffix}) => NumField(label, _c[k]!, suffix: suffix, hint: t('أكتب هنا', 'اكتب هنا', 'Type here'), onChanged: (_) => _save());

  Widget _big(String label, String value, Color c) => Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: .35)),
        ),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          GestureDetector(
            onLongPress: () => copyText(value),
            child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: readable(context, c))),
          ),
        ]),
      );

  String _pct(double x) => '${x >= 0 ? '' : '−'}${fmt(x.abs(), 2)}%';

  @override
  Widget build(BuildContext context) {
    // الضريبة
    final vat = v('vat'), amt = v('amount');
    final withTax = amt * (1 + vat / 100), tax1 = amt * vat / 100;
    final net = amt / (1 + vat / 100), tax2 = amt - net;
    // الخصم
    final price = v('price'), d1 = v('disc'), d2 = v('disc2');
    final after1 = price * (1 - d1 / 100), after2 = after1 * (1 - d2 / 100);
    final totalDisc = price == 0 ? 0.0 : (price - after2) / price * 100;
    // التغيّر
    final o = v('old'), nw = v('new');
    final change = o == 0 ? double.nan : (nw - o) / o * 100;
    // النسبة
    final x = v('x'), y = v('y');
    final xOfY = y == 0 ? double.nan : x / y * 100;
    // التاجر
    final cost = v('cost'), sell = v('sell');
    final profit = sell - cost;
    final markup = cost == 0 ? double.nan : profit / cost * 100;
    final margin = sell == 0 ? double.nan : profit / sell * 100;
    final tMargin = v('tMargin'), tMarkup = v('tMarkup');
    final priceForMargin = tMargin >= 100 ? double.nan : cost / (1 - tMargin / 100);
    final priceForMarkup = cost * (1 + tMarkup / 100);

    String summary() => [
          '🧮 ${tr('حسابات النسب', 'Percentage calculations')}',
          tr('ضريبة $vat%: ${fmt(amt)} + ${fmt(tax1)} = ${fmt(withTax)} • بدون الضريبة: ${fmt(net)}', 'VAT $vat%: ${fmt(amt)} + ${fmt(tax1)} = ${fmt(withTax)} • excl. VAT: ${fmt(net)}'),
          tr('خصم: ${fmt(price)} بعد ${_pct(totalDisc)} = ${fmt(after2)} (وفّرت ${fmt(price - after2)})', 'Discount: ${fmt(price)} less ${_pct(totalDisc)} = ${fmt(after2)} (saved ${fmt(price - after2)})'),
          tr('التغيّر من ${fmt(o)} إلى ${fmt(nw)}: ${_pct(change)}', 'Change from ${fmt(o)} to ${fmt(nw)}: ${_pct(change)}'),
          tr('${fmt(x)} من ${fmt(y)} = ${_pct(xOfY)}', '${fmt(x)} of ${fmt(y)} = ${_pct(xOfY)}'),
          tr('التكلفة ${fmt(cost)} والبيع ${fmt(sell)}: ربح ${fmt(profit)} • هامش ربح ${_pct(margin)} • نسبة الزيادة ${_pct(markup)}', 'Cost ${fmt(cost)}, sale ${fmt(sell)}: profit ${fmt(profit)} • margin ${_pct(margin)} • markup ${_pct(markup)}'),
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: tr('ضريبة القيمة المضافة', 'VAT / sales tax'),
        icon: Icons.receipt_long_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f(tr('نسبة الضريبة', 'Tax rate'), 'vat', suffix: '%')),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: f(tr('المبلغ', 'Amount'), 'amount')),
          ]),
          ChoiceRow<bool>([(true, t('أضف الضريبة', 'إضافة الضريبة', 'Add tax')), (false, t('أشيل الضريبة من المبلغ', 'استخراج الضريبة من المبلغ', 'Remove tax from amount'))], _addTax, (b) {
            _addTax = b;
            _save();
          }),
          if (_addTax) ...[
            _big(tr('المبلغ مع الضريبة', 'Amount incl. tax'), fmt(withTax), SD.green),
            InfoRow(tr('قيمة الضريبة', 'Tax amount'), fmt(tax1), icon: Icons.add_circle_outline_rounded),
          ] else ...[
            _big(tr('المبلغ قبل الضريبة', 'Amount before tax'), fmt(net), SD.green),
            InfoRow(t('الضريبة اللي جوّا المبلغ', 'الضريبة المتضمَّنة في المبلغ', 'Tax included in amount'), fmt(tax2), icon: Icons.remove_circle_outline_rounded),
            InfoRow(tr('نسبتها من المبلغ الكلي', 'Share of the total'), _pct(amt == 0 ? 0 : tax2 / amt * 100), icon: Icons.pie_chart_outline_rounded),
          ],
        ]),
      ),
      SCard(
        title: tr('الخصم والتخفيض', 'Discounts'),
        icon: Icons.local_offer_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f(tr('السعر الأصلي', 'Original price'), 'price'),
          Row(children: [
            Expanded(child: f(tr('الخصم', 'Discount'), 'disc', suffix: '%')),
            const SizedBox(width: 10),
            Expanded(child: f(tr('خصم إضافي (اختياري)', 'Extra discount (optional)'), 'disc2', suffix: '%')),
          ]),
          _big(tr('السعر بعد الخصم', 'Price after discount'), fmt(after2), SD.henna),
          InfoRow(t('وفّرت', 'وفّرت', 'You save'), fmt(price - after2), icon: Icons.savings_rounded, valueColor: SD.green),
          if (d2 > 0)
            InfoRow(tr('الخصم الكلي الفعلي', 'Actual total discount'), _pct(totalDisc), icon: Icons.percent_rounded,
                hint: t('خصمين ${fmt(d1)}% + ${fmt(d2)}% ما بيساوي ${fmt(d1 + d2)}%', 'خصمان ${fmt(d1)}% + ${fmt(d2)}% لا يساويان ${fmt(d1 + d2)}%', 'Two discounts of ${fmt(d1)}% + ${fmt(d2)}% don\'t equal ${fmt(d1 + d2)}%')),
          InfoRow(tr('مع ضريبة $vat% بعد الخصم', 'With $vat% tax after discount'), fmt(after2 * (1 + vat / 100)), icon: Icons.receipt_rounded),
        ]),
      ),
      SCard(
        title: tr('نسبة التغيّر (زيادة/نقصان)', 'Percent change (up/down)'),
        icon: Icons.trending_up_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f(tr('القيمة القديمة', 'Old value'), 'old')),
            const SizedBox(width: 10),
            Expanded(child: f(tr('القيمة الجديدة', 'New value'), 'new')),
          ]),
          _big(change >= 0 ? tr('زادت بنسبة', 'Increased by') : tr('نقصت بنسبة', 'Decreased by'), _pct(change.abs()), change >= 0 ? SD.red : SD.green),
          InfoRow(tr('الفرق', 'Difference'), fmt(nw - o), icon: Icons.compare_arrows_rounded),
          InfoRow(t('الجديدة كم ضعف القديمة', 'الجديدة كم ضعفًا من القديمة', 'New ÷ old'), o == 0 ? '—' : '${fmt(nw / o, 3)}×', icon: Icons.close_rounded),
          if (change < 0 && change > -100)
            InfoRow(t('عشان ترجع زي ما كانت محتاجة تزيد', 'لتعود كما كانت تحتاج إلى زيادة', 'Increase needed to get back'), _pct((o - nw) / nw * 100), icon: Icons.undo_rounded,
                hint: t('النقصان والزيادة بنفس النسبة ما بيلغو بعض', 'النقصان والزيادة بالنسبة نفسها لا يُلغي أحدهما الآخر', 'A drop and a rise of the same % don\'t cancel out')),
        ]),
      ),
      SCard(
        title: t('كم في المية؟', 'كم في المئة؟', 'What percent?'),
        icon: Icons.percent_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f(tr('الرقم (س)', 'Number (X)'), 'x')),
            const SizedBox(width: 10),
            Expanded(child: f(tr('من (ص)', 'Of (Y)'), 'y')),
          ]),
          _big(t('س كم % من ص', 'س تساوي كم % من ص', 'X is what % of Y'), _pct(xOfY), SD.purple),
          InfoRow(tr('${fmt(x)}% من ${fmt(y)}', '${fmt(x)}% of ${fmt(y)}'), fmt(x * y / 100), icon: Icons.calculate_rounded),
          InfoRow(tr('${fmt(y)} زائد ${fmt(x)}%', '${fmt(y)} plus ${fmt(x)}%'), fmt(y * (1 + x / 100)), icon: Icons.add_rounded),
          InfoRow(tr('${fmt(y)} ناقص ${fmt(x)}%', '${fmt(y)} minus ${fmt(x)}%'), fmt(y * (1 - x / 100)), icon: Icons.remove_rounded),
          InfoRow(t('${fmt(x)} هي ${fmt(y)}% من كم؟', '${fmt(x)} هي ${fmt(y)}% من أي عدد؟', '${fmt(x)} is ${fmt(y)}% of what?'), y == 0 ? '—' : fmt(x / y * 100), icon: Icons.help_outline_rounded),
        ]),
      ),
      SCard(
        title: tr('حسابات التاجر: هامش الربح ونسبة الزيادة', 'Trader math: margin & markup'),
        icon: Icons.storefront_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f(tr('التكلفة (الشراء)', 'Cost (purchase)'), 'cost')),
            const SizedBox(width: 10),
            Expanded(child: f(tr('سعر البيع', 'Sale price'), 'sell')),
          ]),
          _big(profit >= 0 ? tr('الربح', 'Profit') : tr('الخسارة', 'Loss'), fmt(profit.abs()), profit >= 0 ? SD.green : SD.red),
          StatGrid([
            StatChip(_pct(markup), tr('نسبة الزيادة على التكلفة', 'Markup on cost'), color: SD.gold, icon: Icons.add_chart_rounded),
            StatChip(_pct(margin), tr('هامش الربح من البيع', 'Margin on sale'), color: SD.green, icon: Icons.donut_large_rounded),
          ], columns: 2),
          NoteBox(t('نسبة الزيادة (Markup) = الربح ÷ التكلفة. هامش الربح (Margin) = الربح ÷ سعر البيع. زيادة 25% على التكلفة = هامش 20% بس!', 'نسبة الزيادة (Markup) = الربح ÷ التكلفة. هامش الربح (Margin) = الربح ÷ سعر البيع. زيادة 25% على التكلفة = هامش 20% فقط!', 'Markup = profit ÷ cost. Margin = profit ÷ sale price. A 25% markup is only a 20% margin!'),
              kind: NoteKind.tip),
          Row(children: [
            Expanded(child: f(tr('هامش مطلوب', 'Target margin'), 'tMargin', suffix: '%')),
            const SizedBox(width: 10),
            Expanded(child: f(tr('زيادة مطلوبة', 'Target markup'), 'tMarkup', suffix: '%')),
          ]),
          InfoRow(t('عشان هامش ${fmt(tMargin)}% بيع بـ', 'لهامش ${fmt(tMargin)}% بِع بـ', 'For a ${fmt(tMargin)}% margin, sell at'), fmt(priceForMargin), icon: Icons.sell_rounded, valueColor: SD.green),
          InfoRow(t('عشان زيادة ${fmt(tMarkup)}% بيع بـ', 'لزيادة ${fmt(tMarkup)}% بِع بـ', 'For a ${fmt(tMarkup)}% markup, sell at'), fmt(priceForMarkup), icon: Icons.sell_outlined, valueColor: SD.gold),
          InfoRow(tr('سعر البيع مع ضريبة $vat%', 'Sale price with $vat% tax'), fmt(sell * (1 + vat / 100)), icon: Icons.receipt_rounded),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      NoteBox(t('نسبة الضريبة الافتراضية 17% (السودان) وبتختلف من بلد لبلد — عدّلها فوق وبنحفظها ليك.', 'نسبة الضريبة الافتراضية 17% (السودان) وتختلف من بلد لآخر — عدّلها أعلاه وسنحفظها لك.', 'Default tax rate is 17% (Sudan) and varies by country — change it above and we\'ll remember it.'), kind: NoteKind.info),
    ]);
  }
}
