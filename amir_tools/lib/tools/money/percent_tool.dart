import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
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
  Widget f(String label, String k, {String? suffix}) => NumField(label, _c[k]!, suffix: suffix, hint: 'أكتب هنا', onChanged: (_) => _save());

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
            child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
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
          '🧮 حسابات النسب',
          'ضريبة $vat%: ${fmt(amt)} + ${fmt(tax1)} = ${fmt(withTax)} • بدون الضريبة: ${fmt(net)}',
          'خصم: ${fmt(price)} بعد ${_pct(totalDisc)} = ${fmt(after2)} (وفّرت ${fmt(price - after2)})',
          'التغيّر من ${fmt(o)} إلى ${fmt(nw)}: ${_pct(change)}',
          '${fmt(x)} من ${fmt(y)} = ${_pct(xOfY)}',
          'التكلفة ${fmt(cost)} والبيع ${fmt(sell)}: ربح ${fmt(profit)} • هامش ربح ${_pct(margin)} • نسبة الزيادة ${_pct(markup)}',
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: 'ضريبة القيمة المضافة',
        icon: Icons.receipt_long_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f('نسبة الضريبة', 'vat', suffix: '%')),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: f('المبلغ', 'amount', suffix: 'ج.س')),
          ]),
          ChoiceRow<bool>(const [(true, 'أضف الضريبة'), (false, 'أشيل الضريبة من المبلغ')], _addTax, (b) {
            _addTax = b;
            _save();
          }),
          if (_addTax) ...[
            _big('المبلغ مع الضريبة', fmt(withTax), SD.green),
            InfoRow('قيمة الضريبة', fmt(tax1), icon: Icons.add_circle_outline_rounded),
          ] else ...[
            _big('المبلغ قبل الضريبة', fmt(net), SD.green),
            InfoRow('الضريبة اللي جوّا المبلغ', fmt(tax2), icon: Icons.remove_circle_outline_rounded),
            InfoRow('نسبتها من المبلغ الكلي', _pct(amt == 0 ? 0 : tax2 / amt * 100), icon: Icons.pie_chart_outline_rounded),
          ],
        ]),
      ),
      SCard(
        title: 'الخصم والتخفيض',
        icon: Icons.local_offer_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f('السعر الأصلي', 'price', suffix: 'ج.س'),
          Row(children: [
            Expanded(child: f('الخصم', 'disc', suffix: '%')),
            const SizedBox(width: 10),
            Expanded(child: f('خصم إضافي (اختياري)', 'disc2', suffix: '%')),
          ]),
          _big('السعر بعد الخصم', fmt(after2), SD.henna),
          InfoRow('وفّرت', fmt(price - after2), icon: Icons.savings_rounded, valueColor: SD.green),
          if (d2 > 0)
            InfoRow('الخصم الكلي الفعلي', _pct(totalDisc), icon: Icons.percent_rounded,
                hint: 'خصمين ${fmt(d1)}% + ${fmt(d2)}% ما بيساوي ${fmt(d1 + d2)}%'),
          InfoRow('مع ضريبة $vat% بعد الخصم', fmt(after2 * (1 + vat / 100)), icon: Icons.receipt_rounded),
        ]),
      ),
      SCard(
        title: 'نسبة التغيّر (زيادة/نقصان)',
        icon: Icons.trending_up_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f('القيمة القديمة', 'old')),
            const SizedBox(width: 10),
            Expanded(child: f('القيمة الجديدة', 'new')),
          ]),
          _big(change >= 0 ? 'زادت بنسبة' : 'نقصت بنسبة', _pct(change.abs()), change >= 0 ? SD.red : SD.green),
          InfoRow('الفرق', fmt(nw - o), icon: Icons.compare_arrows_rounded),
          InfoRow('الجديدة كم ضعف القديمة', o == 0 ? '—' : '${fmt(nw / o, 3)}×', icon: Icons.close_rounded),
          if (change < 0 && change > -100)
            InfoRow('عشان ترجع زي ما كانت محتاجة تزيد', _pct((o - nw) / nw * 100), icon: Icons.undo_rounded,
                hint: 'النقصان والزيادة بنفس النسبة ما بيلغو بعض'),
        ]),
      ),
      SCard(
        title: 'كم في المية؟',
        icon: Icons.percent_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f('الرقم (س)', 'x')),
            const SizedBox(width: 10),
            Expanded(child: f('من (ص)', 'y')),
          ]),
          _big('س كم % من ص', _pct(xOfY), SD.purple),
          InfoRow('${fmt(x)}% من ${fmt(y)}', fmt(x * y / 100), icon: Icons.calculate_rounded),
          InfoRow('${fmt(y)} زائد ${fmt(x)}%', fmt(y * (1 + x / 100)), icon: Icons.add_rounded),
          InfoRow('${fmt(y)} ناقص ${fmt(x)}%', fmt(y * (1 - x / 100)), icon: Icons.remove_rounded),
          InfoRow('${fmt(x)} هي ${fmt(y)}% من كم؟', y == 0 ? '—' : fmt(x / y * 100), icon: Icons.help_outline_rounded),
        ]),
      ),
      SCard(
        title: 'حسابات التاجر: هامش الربح ونسبة الزيادة',
        icon: Icons.storefront_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: f('التكلفة (الشراء)', 'cost', suffix: 'ج.س')),
            const SizedBox(width: 10),
            Expanded(child: f('سعر البيع', 'sell', suffix: 'ج.س')),
          ]),
          _big(profit >= 0 ? 'الربح' : 'الخسارة', fmt(profit.abs()), profit >= 0 ? SD.green : SD.red),
          StatGrid([
            StatChip(_pct(markup), 'نسبة الزيادة على التكلفة', color: SD.gold, icon: Icons.add_chart_rounded),
            StatChip(_pct(margin), 'هامش الربح من البيع', color: SD.green, icon: Icons.donut_large_rounded),
          ], columns: 2),
          const NoteBox('نسبة الزيادة (Markup) = الربح ÷ التكلفة. هامش الربح (Margin) = الربح ÷ سعر البيع. زيادة 25% على التكلفة = هامش 20% بس!',
              kind: NoteKind.tip),
          Row(children: [
            Expanded(child: f('هامش مطلوب', 'tMargin', suffix: '%')),
            const SizedBox(width: 10),
            Expanded(child: f('زيادة مطلوبة', 'tMarkup', suffix: '%')),
          ]),
          InfoRow('عشان هامش ${fmt(tMargin)}% بيع بـ', fmt(priceForMargin), icon: Icons.sell_rounded, valueColor: SD.green),
          InfoRow('عشان زيادة ${fmt(tMarkup)}% بيع بـ', fmt(priceForMarkup), icon: Icons.sell_outlined, valueColor: SD.gold),
          InfoRow('سعر البيع مع ضريبة $vat%', fmt(sell * (1 + vat / 100)), icon: Icons.receipt_rounded),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      const NoteBox('نسبة الضريبة الافتراضية 17% وممكن تتغيّر حسب القرار الحكومي — عدّلها فوق وبنحفظها ليك.', kind: NoteKind.info),
    ]);
  }
}
