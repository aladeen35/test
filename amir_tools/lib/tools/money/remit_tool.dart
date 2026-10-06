import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/net.dart';
import 'currency_tool.dart' show fmtRate;
import 'money_common.dart';

class RemitTool extends StatefulWidget {
  const RemitTool({super.key});
  @override
  State<RemitTool> createState() => _RemitToolState();
}

class _RemitToolState extends State<RemitTool> {
  late final TextEditingController _amount, _fee, _pct, _custom, _target;
  String _cur = 'SAR';
  bool _onTop = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final d = Map<String, dynamic>.from(s.getData<Map>('remit_inputs') ?? {});
    _amount = TextEditingController(text: d['amount'] ?? '1000');
    _fee = TextEditingController(text: d['fee'] ?? '15');
    _pct = TextEditingController(text: d['pct'] ?? '0');
    _custom = TextEditingController(text: d['custom'] ?? '');
    _target = TextEditingController(text: d['target'] ?? '500000');
    _cur = d['cur'] ?? 'SAR';
    _onTop = d['onTop'] == true;
    refreshRates(s).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    for (final c in [_amount, _fee, _pct, _custom, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('remit_inputs', {
      'amount': _amount.text, 'fee': _fee.text, 'pct': _pct.text, 'custom': _custom.text, 'target': _target.text,
      'cur': _cur, 'onTop': _onTop,
    });
    setState(() {});
  }

  /// يحسب (المُرسل فعليًا، الواصل بالعملة، الرسوم)
  ({double paid, double delivered, double fees}) _calc(double amount, double fee, double pct) {
    final comm = amount * pct / 100;
    final fees = fee + comm;
    if (_onTop) return (paid: amount + fees, delivered: amount, fees: fees);
    final del = amount - fees;
    return (paid: amount, delivered: del < 0 ? 0 : del, fees: fees);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = currencyByCode(_cur);
    final amount = parseNum(_amount.text), fee = parseNum(_fee.text), pct = parseNum(_pct.text);
    final custom = parseNum(_custom.text);
    final rPar = s.rate(_cur, 'SDG', parallel: true);
    final rOff = s.rate(_cur, 'SDG', parallel: false);
    final hasPar = s.sdgParallel != null;
    final rUsed = custom > 0 ? custom : s.rate(_cur, 'SDG');
    final usedName = custom > 0 ? 'سعرك الخاص' : (s.useParallel && hasPar ? 'السعر الموازي' : 'السعر الرسمي');
    final r = _calc(amount, fee, pct);
    final sdg = r.delivered * rUsed;
    final sdgPar = r.delivered * rPar, sdgOff = r.delivered * rOff;
    final lossSdg = r.fees * rUsed;
    final feePctOfPaid = r.paid == 0 ? 0.0 : r.fees / r.paid * 100;
    final usd = r.delivered / s.usdRate(_cur);

    // الحساب العكسي
    final target = parseNum(_target.text);
    final needDelivered = rUsed == 0 ? 0.0 : target / rUsed;
    final double needSend = _onTop
        ? needDelivered * (1 + pct / 100) + fee
        : (pct >= 100 ? double.nan : (needDelivered + fee) / (1 - pct / 100));
    final needFees = _onTop ? needSend - needDelivered : needSend - needDelivered;

    String summary() => [
          '💸 تحويل للأهل',
          'المبلغ: ${fmt(amount)} ${c.name} (${_onTop ? 'الرسوم فوق المبلغ' : 'الرسوم مخصومة منه'})',
          'الرسوم والعمولة: ${fmt(r.fees)} ${c.sym} (${fmt(feePctOfPaid, 1)}%)',
          'بيصل للأهل: ${fmt(sdg, 0)} جنيه سوداني ($usedName ${fmtRate(rUsed)})',
          if (hasPar) 'بالموازي: ${fmt(sdgPar, 0)} ج.س',
          'بالرسمي: ${fmt(sdgOff, 0)} ج.س',
          'عشان يصل ${fmt(target, 0)} ج.س: رسّل ${fmt(needSend)} ${c.sym}',
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: 'تفاصيل التحويلة',
        icon: Icons.send_to_mobile_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyPicker('عملة التحويل', _cur, (v) {
            _cur = v;
            _save();
          }, codes: currencies.where((x) => x.code != 'SDG').map((x) => x.code).toList()),
          const SizedBox(height: 10),
          NumField('المبلغ الداير ترسلو', _amount, suffix: c.sym, hint: 'أكتب هنا', onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: NumField('رسوم ثابتة', _fee, suffix: c.sym, onChanged: (_) => _save())),
            const SizedBox(width: 10),
            Expanded(child: NumField('عمولة %', _pct, suffix: '%', onChanged: (_) => _save())),
          ]),
          NumField('سعر خاص (اختياري): 1 ${c.code} = كم جنيه؟', _custom,
              suffix: 'ج.س', hint: 'لو الصرافة/الوكيل عندو سعر معيّن', onChanged: (_) => _save()),
          ChoiceRow<bool>(const [(false, 'الرسوم بتنخصم من المبلغ'), (true, 'الرسوم بدفعها فوق المبلغ')], _onTop, (v) {
            _onTop = v;
            _save();
          }),
          if (!hasPar && custom <= 0)
            const NoteBox('ما كتبت سعر الموازي في «محوّل العملات»، فبنحسب بالرسمي. أغلب التحويلات بتمشي بالموازي، فاكتب السعر هناك ولا هنا كسعر خاص.',
                kind: NoteKind.warn),
        ]),
      ),
      ResultHero(
        label: 'الواصل للأهل في السودان',
        value: '${fmt(sdg, 0)} ج.س',
        sub: '$usedName: 1 ${c.code} = ${fmtRate(rUsed)} ج.س • ≈ ${fmt(usd)} \$',
      ),
      SCard(
        title: 'الحساب بالتفصيل',
        icon: Icons.receipt_long_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow('بتدفع كم جملةً', '${fmt(r.paid)} ${c.sym}', icon: Icons.payments_rounded),
          InfoRow('الرسوم الثابتة', '${fmt(fee)} ${c.sym}', icon: Icons.price_change_rounded),
          InfoRow('العمولة ($pct%)', '${fmt(amount * pct / 100)} ${c.sym}', icon: Icons.percent_rounded),
          InfoRow('مجموع الرسوم', '${fmt(r.fees)} ${c.sym}', icon: Icons.money_off_rounded, valueColor: SD.red,
              hint: 'يعني ${fmt(feePctOfPaid, 2)}% من اللي دفعتو'),
          InfoRow('المبلغ الصافي المحوَّل', '${fmt(r.delivered)} ${c.sym}', icon: Icons.check_circle_rounded, valueColor: SD.green),
          InfoRow('الخسارة بسبب الرسوم بالجنيه', '${fmt(lossSdg, 0)} ج.س', icon: Icons.trending_down_rounded, valueColor: SD.red),
          InfoRow('الواصل بالدولار', '${fmt(usd)} \$', icon: Icons.attach_money_rounded),
        ]),
      ),
      SCard(
        title: 'موازي ولا رسمي؟',
        icon: Icons.compare_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PercentBar('بالسعر الموازي ${hasPar ? '' : '(ما محدد)'}', 1, '${fmt(sdgPar, 0)} ج.س', color: SD.green),
          PercentBar('بالسعر الرسمي', sdgPar == 0 ? 0 : sdgOff / sdgPar, '${fmt(sdgOff, 0)} ج.س', color: SD.nile),
          if (custom > 0) PercentBar('بسعرك الخاص', sdgPar == 0 ? 0 : sdg / sdgPar, '${fmt(sdg, 0)} ج.س', color: SD.purple),
          const SizedBox(height: 6),
          if (hasPar)
            NoteBox(
              'الفرق بين الموازي والرسمي في التحويلة دي: ${fmt((sdgPar - sdgOff).abs(), 0)} جنيه '
              '(${fmt(sdgOff == 0 ? 0 : (sdgPar - sdgOff) / sdgOff * 100, 1)}%).',
              kind: NoteKind.tip,
            ),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 14),
      SCard(
        title: 'داير يصل كم بالضبط؟',
        icon: Icons.u_turn_left_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField('المبلغ المطلوب يصل للأهل', _target, suffix: 'ج.س', hint: 'مثلًا 500000', onChanged: (_) => _save()),
          Wrap(spacing: 6, children: [
            for (final q in [100000, 250000, 500000, 1000000, 2000000])
              ActionChip(
                  label: Text(fmt(q)),
                  onPressed: () {
                    _target.text = '$q';
                    _save();
                  }),
          ]),
          const SizedBox(height: 8),
          InfoRow('لازم ترسل', '${fmt(needSend)} ${c.sym}', icon: Icons.send_rounded, valueColor: SD.purple),
          InfoRow('الصافي اللي بيتحوّل', '${fmt(needDelivered)} ${c.sym}', icon: Icons.call_made_rounded),
          InfoRow('رسوم التحويلة دي', '${fmt(needFees)} ${c.sym}', icon: Icons.money_off_rounded, valueColor: SD.red),
          InfoRow('بالدولار تقريبًا', '${fmt(needSend / s.usdRate(_cur))} \$', icon: Icons.attach_money_rounded),
        ]),
      ),
      SCard(
        title: 'مقارنة مبالغ شائعة',
        icon: Icons.table_rows_rounded,
        color: SD.teal,
        child: MiniTable(
          ['المبلغ ${c.code}', 'الرسوم', 'نسبة الرسوم', 'بالموازي ج.س', 'بالرسمي ج.س'],
          [
            for (final a in [500.0, 1000.0, 2000.0, 5000.0])
              () {
                final x = _calc(a, fee, pct);
                return [
                  fmt(a),
                  fmt(x.fees),
                  '${fmt(x.paid == 0 ? 0 : x.fees / x.paid * 100, 1)}%',
                  fmt(x.delivered * rPar, 0),
                  fmt(x.delivered * rOff, 0),
                ];
              }(),
          ],
          color: SD.teal,
        ),
      ),
      const NoteBox('💡 الرسوم الثابتة بتأكل نسبة أكبر من المبالغ الصغيرة — لو بتقدر جمّع وارسل مرة واحدة في الشهر بدل مرات كتيرة.', kind: NoteKind.tip),
      const NoteBox('الحساب تقديري: سعر الصرافة والرسوم الفعلية ممكن تختلف من مكان للتاني ومن يوم ليوم. اتأكد من الوكيل قبل ما ترسل.', kind: NoteKind.warn),
    ]);
  }
}
