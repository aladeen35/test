import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/net.dart';
import 'currency_tool.dart' show fmtRate;
import 'money_common.dart';

String get _sdg => tr('ج.س', 'SDG');

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
    final usedName = custom > 0 ? tr('سعرك الخاص', 'Your custom rate') : (s.useParallel && hasPar ? t('السعر الموازي', 'سعر السوق الموازية', 'Parallel rate') : tr('السعر الرسمي', 'Official rate'));
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
          '💸 ${t('تحويل للأهل', 'تحويل إلى الأهل', 'Money home')}',
          '${tr('المبلغ', 'Amount')}: ${fmt(amount)} ${c.name} (${_onTop ? tr('الرسوم فوق المبلغ', 'fees on top') : tr('الرسوم مخصومة منه', 'fees deducted')})',
          '${tr('الرسوم والعمولة', 'Fees & commission')}: ${fmt(r.fees)} ${c.sym} (${fmt(feePctOfPaid, 1)}%)',
          t('بيصل للأهل: ${fmt(sdg, 0)} جنيه سوداني ($usedName ${fmtRate(rUsed)})', 'يصل إلى الأهل: ${fmt(sdg, 0)} جنيه سوداني ($usedName ${fmtRate(rUsed)})', 'Family receives: ${fmt(sdg, 0)} SDG ($usedName ${fmtRate(rUsed)})'),
          if (hasPar) '${tr('بالموازي', 'Parallel')}: ${fmt(sdgPar, 0)} $_sdg',
          '${tr('بالرسمي', 'Official')}: ${fmt(sdgOff, 0)} $_sdg',
          t('عشان يصل ${fmt(target, 0)} ج.س: رسّل ${fmt(needSend)} ${c.sym}', 'ليصل ${fmt(target, 0)} ج.س: أرسل ${fmt(needSend)} ${c.sym}', 'To deliver ${fmt(target, 0)} SDG: send ${fmt(needSend)} ${c.sym}'),
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: t('تفاصيل التحويلة', 'تفاصيل الحوالة', 'Transfer details'),
        icon: Icons.send_to_mobile_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyPicker(t('عملة التحويل', 'عملة الحوالة', 'Sending currency'), _cur, (v) {
            _cur = v;
            _save();
          }, codes: currencies.where((x) => x.code != 'SDG').map((x) => x.code).toList()),
          const SizedBox(height: 10),
          NumField(t('المبلغ الداير ترسلو', 'المبلغ المراد إرساله', 'Amount to send'), _amount, suffix: c.sym, hint: t('أكتب هنا', 'اكتب هنا', 'Type here'), onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: NumField(tr('رسوم ثابتة', 'Fixed fee'), _fee, suffix: c.sym, onChanged: (_) => _save())),
            const SizedBox(width: 10),
            Expanded(child: NumField(tr('عمولة %', 'Commission %'), _pct, suffix: '%', onChanged: (_) => _save())),
          ]),
          NumField(tr('سعر خاص (اختياري): 1 ${c.code} = كم جنيه؟', 'Custom rate (optional): 1 ${c.code} = ? SDG'), _custom,
              suffix: _sdg, hint: t('لو الصرافة/الوكيل عندو سعر معيّن', 'إن كان لدى الصرّاف/الوكيل سعر محدد', 'If your exchange/agent quotes a specific rate'), onChanged: (_) => _save()),
          ChoiceRow<bool>([(false, t('الرسوم بتنخصم من المبلغ', 'تُخصم الرسوم من المبلغ', 'Fees deducted from amount')), (true, t('الرسوم بدفعها فوق المبلغ', 'أدفع الرسوم فوق المبلغ', 'I pay fees on top'))], _onTop, (v) {
            _onTop = v;
            _save();
          }),
          if (!hasPar && custom <= 0)
            NoteBox(t('ما كتبت سعر الموازي في «الدولار والعملات»، فبنحسب بالرسمي. أغلب التحويلات بتمشي بالموازي، فاكتب السعر هناك ولا هنا كسعر خاص.', 'لم تُدخل سعر السوق الموازية في «الدولار والعملات»، لذا نحسب بالسعر الرسمي. معظم الحوالات تتم بالسعر الموازي، فأدخله هناك أو هنا كسعر خاص.', 'You haven\'t entered a parallel rate in "Dollar & Currencies", so we use the official rate. Most transfers go at the parallel rate — enter it there, or here as a custom rate.'),
                kind: NoteKind.warn),
        ]),
      ),
      ResultHero(
        label: t('الواصل للأهل في السودان', 'ما يصل إلى الأهل في السودان', 'Family receives in Sudan'),
        value: '${fmt(sdg, 0)} $_sdg',
        sub: '$usedName: 1 ${c.code} = ${fmtRate(rUsed)} $_sdg • ≈ ${fmt(usd)} \$',
      ),
      SCard(
        title: tr('الحساب بالتفصيل', 'Breakdown'),
        icon: Icons.receipt_long_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow(t('بتدفع كم جملةً', 'إجمالي ما تدفعه', 'Total you pay'), '${fmt(r.paid)} ${c.sym}', icon: Icons.payments_rounded),
          InfoRow(tr('الرسوم الثابتة', 'Fixed fee'), '${fmt(fee)} ${c.sym}', icon: Icons.price_change_rounded),
          InfoRow(tr('العمولة ($pct%)', 'Commission ($pct%)'), '${fmt(amount * pct / 100)} ${c.sym}', icon: Icons.percent_rounded),
          InfoRow(tr('مجموع الرسوم', 'Total fees'), '${fmt(r.fees)} ${c.sym}', icon: Icons.money_off_rounded, valueColor: SD.red,
              hint: t('يعني ${fmt(feePctOfPaid, 2)}% من اللي دفعتو', 'أي ${fmt(feePctOfPaid, 2)}% مما دفعته', 'i.e. ${fmt(feePctOfPaid, 2)}% of what you paid')),
          InfoRow(tr('المبلغ الصافي المحوَّل', 'Net amount sent'), '${fmt(r.delivered)} ${c.sym}', icon: Icons.check_circle_rounded, valueColor: SD.green),
          InfoRow(tr('الخسارة بسبب الرسوم بالجنيه', 'Lost to fees (SDG)'), '${fmt(lossSdg, 0)} $_sdg', icon: Icons.trending_down_rounded, valueColor: SD.red),
          InfoRow(tr('الواصل بالدولار', 'Received in USD'), '${fmt(usd)} \$', icon: Icons.attach_money_rounded),
        ]),
      ),
      SCard(
        title: t('موازي ولا رسمي؟', 'موازٍ أم رسمي؟', 'Parallel or official?'),
        icon: Icons.compare_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PercentBar('${tr('بالسعر الموازي', 'At parallel rate')} ${hasPar ? '' : t('(ما محدد)', '(غير محدد)', '(not set)')}', 1, '${fmt(sdgPar, 0)} $_sdg', color: SD.green),
          PercentBar(tr('بالسعر الرسمي', 'At official rate'), sdgPar == 0 ? 0 : sdgOff / sdgPar, '${fmt(sdgOff, 0)} $_sdg', color: SD.nile),
          if (custom > 0) PercentBar(tr('بسعرك الخاص', 'At your rate'), sdgPar == 0 ? 0 : sdg / sdgPar, '${fmt(sdg, 0)} $_sdg', color: SD.purple),
          const SizedBox(height: 6),
          if (hasPar)
            NoteBox(
              '${t('الفرق بين الموازي والرسمي في التحويلة دي', 'الفرق بين الموازي والرسمي في هذه الحوالة', 'Parallel vs official difference on this transfer')}: ${fmt((sdgPar - sdgOff).abs(), 0)} $_sdg '
              '(${fmt(sdgOff == 0 ? 0 : (sdgPar - sdgOff) / sdgOff * 100, 1)}%).',
              kind: NoteKind.tip,
            ),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 14),
      SCard(
        title: t('داير يصل كم بالضبط؟', 'كم تريد أن يصل بالضبط؟', 'How much should arrive?'),
        icon: Icons.u_turn_left_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(t('المبلغ المطلوب يصل للأهل', 'المبلغ المطلوب وصوله إلى الأهل', 'Amount family should receive'), _target, suffix: _sdg, hint: tr('مثلًا 500000', 'e.g. 500000'), onChanged: (_) => _save()),
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
          InfoRow(t('لازم ترسل', 'يجب أن ترسل', 'You need to send'), '${fmt(needSend)} ${c.sym}', icon: Icons.send_rounded, valueColor: SD.purple),
          InfoRow(t('الصافي اللي بيتحوّل', 'الصافي المحوَّل', 'Net transferred'), '${fmt(needDelivered)} ${c.sym}', icon: Icons.call_made_rounded),
          InfoRow(t('رسوم التحويلة دي', 'رسوم هذه الحوالة', 'Fees for this transfer'), '${fmt(needFees)} ${c.sym}', icon: Icons.money_off_rounded, valueColor: SD.red),
          InfoRow(tr('بالدولار تقريبًا', 'Approx. in USD'), '${fmt(needSend / s.usdRate(_cur))} \$', icon: Icons.attach_money_rounded),
        ]),
      ),
      SCard(
        title: tr('مقارنة مبالغ شائعة', 'Common amounts compared'),
        icon: Icons.table_rows_rounded,
        color: SD.teal,
        child: MiniTable(
          [tr('المبلغ ${c.code}', 'Amount ${c.code}'), tr('الرسوم', 'Fees'), tr('نسبة الرسوم', 'Fee %'), tr('بالموازي ج.س', 'Parallel SDG'), tr('بالرسمي ج.س', 'Official SDG')],
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
      NoteBox(t('💡 الرسوم الثابتة بتأكل نسبة أكبر من المبالغ الصغيرة — لو بتقدر جمّع وارسل مرة واحدة في الشهر بدل مرات كتيرة.', '💡 الرسوم الثابتة تلتهم نسبة أكبر من المبالغ الصغيرة — إن استطعت فاجمع وأرسل مرة واحدة شهريًا بدل مرات كثيرة.', '💡 Fixed fees eat a bigger share of small amounts — if you can, send once a month instead of many times.'), kind: NoteKind.tip),
      NoteBox(t('الحساب تقديري: سعر الصرافة والرسوم الفعلية ممكن تختلف من مكان للتاني ومن يوم ليوم. اتأكد من الوكيل قبل ما ترسل.', 'الحساب تقديري: قد يختلف سعر الصرف والرسوم الفعلية من مكان لآخر ومن يوم لآخر. تحقّق من الوكيل قبل الإرسال.', 'Estimate only: actual exchange rates and fees vary by provider and day. Confirm with your agent before sending.'), kind: NoteKind.warn),
    ]);
  }
}
