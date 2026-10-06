import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

String _flatL() => tr('مرابحة ثابتة', 'Flat murabaha');
String _decL() => tr('قرض متناقص', 'Declining loan');

class _Row {
  final int m;
  final double pay, principal, profit, remain;
  _Row(this.m, this.pay, this.principal, this.profit, this.remain);
}

class _Plan {
  final double monthly, total, profit;
  final List<_Row> rows;
  _Plan(this.monthly, this.total, this.profit, this.rows);
}

_Plan _flat(double p, double annual, int n) {
  final profit = p * annual / 100 * n / 12;
  final total = p + profit;
  final m = total / n;
  final rows = <_Row>[];
  var bal = total;
  for (var i = 1; i <= n; i++) {
    bal -= m;
    rows.add(_Row(i, m, p / n, profit / n, math.max(0, bal)));
  }
  return _Plan(m, total, profit, rows);
}

_Plan _declining(double p, double annual, int n) {
  final r = annual / 100 / 12;
  final m = r == 0 ? p / n : p * r / (1 - math.pow(1 + r, -n));
  final rows = <_Row>[];
  var bal = p;
  var prof = 0.0;
  for (var i = 1; i <= n; i++) {
    final it = bal * r;
    final pr = m - it;
    bal -= pr;
    prof += it;
    rows.add(_Row(i, m, pr, it, math.max(0, bal)));
  }
  return _Plan(m, m * n, prof, rows);
}

/// المعدل الشهري الفعلي (IRR) لدفعة شهرية ثابتة
double _irr(double p, double m, int n) {
  if (p <= 0 || m * n <= p) return 0;
  var lo = 0.0, hi = 1.0;
  for (var k = 0; k < 100; k++) {
    final mid = (lo + hi) / 2;
    final pv = m * (1 - math.pow(1 + mid, -n)) / mid;
    if (pv > p) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

class LoanTool extends StatefulWidget {
  const LoanTool({super.key});
  @override
  State<LoanTool> createState() => _LoanToolState();
}

class _LoanToolState extends State<LoanTool> {
  late final TextEditingController _price, _down, _rate, _months;
  bool _flatMode = true;

  @override
  void initState() {
    super.initState();
    final d = Map<String, dynamic>.from(context.read<AppState>().getData<Map>('loan_inputs') ?? {});
    _price = TextEditingController(text: d['price'] ?? '10000000');
    _down = TextEditingController(text: d['down'] ?? '2000000');
    _rate = TextEditingController(text: d['rate'] ?? '15');
    _months = TextEditingController(text: d['months'] ?? '12');
    _flatMode = d['flat'] ?? true;
  }

  @override
  void dispose() {
    for (final c in [_price, _down, _rate, _months]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('loan_inputs',
        {'price': _price.text, 'down': _down.text, 'rate': _rate.text, 'months': _months.text, 'flat': _flatMode});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final price = parseNum(_price.text), down = parseNum(_down.text), rate = parseNum(_rate.text);
    final n = parseNum(_months.text, 12).round().clamp(1, 600);
    final fin = math.max(0.0, price - down);
    final flat = _flat(fin, rate, n), dec = _declining(fin, rate, n);
    final plan = _flatMode ? flat : dec;
    final irr = _irr(fin, plan.monthly, n);
    final effAnnual = (math.pow(1 + irr, 12) - 1) * 100;
    final grand = down + plan.total;
    final modeName = _flatMode ? _flatL() : _decL();

    String summary() => [
          '🏦 ${tr('حساب الأقساط', 'Installment plan')} ($modeName)',
          tr('السعر: ${fmt(price, 0)} • المقدم: ${fmt(down, 0)} • المموَّل: ${fmt(fin, 0)}', 'Price: ${fmt(price, 0)} • Down: ${fmt(down, 0)} • Financed: ${fmt(fin, 0)}'),
          tr('النسبة: $rate% سنويًا لمدة $n شهر', 'Rate: $rate% per year for $n months'),
          '${tr('القسط الشهري', 'Monthly payment')}: ${fmt(plan.monthly, 0)}',
          '${tr('جملة الأرباح', 'Total profit')}: ${fmt(plan.profit, 0)}',
          '${tr('جملة المدفوع (مع المقدم)', 'Total paid (incl. down payment)')}: ${fmt(grand, 0)}',
          '${tr('التكلفة الفعلية السنوية', 'Effective annual cost')} ≈ ${fmt(effAnnual, 2)}%',
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: tr('بيانات التمويل', 'Financing details'),
        icon: Icons.request_quote_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChoiceRow<bool>([(true, _flatL()), (false, _decL())], _flatMode, (x) {
            _flatMode = x;
            _save();
          }, color: SD.indigo),
          NumField(tr('سعر السلعة / مبلغ التمويل', 'Item price / financed amount'), _price, onChanged: (_) => _save()),
          NumField(tr('المقدّم (الدفعة الأولى)', 'Down payment'), _down, onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: NumField(tr('نسبة الربح السنوية', 'Annual profit rate'), _rate, suffix: '%', onChanged: (_) => _save())),
            const SizedBox(width: 10),
            Expanded(child: NumField(t('عدد الشهور', 'عدد الأشهر', 'Months'), _months, suffix: tr('شهر', 'mo'), decimal: false, onChanged: (_) => _save())),
          ]),
          Wrap(spacing: 6, children: [
            for (final m in [6, 12, 18, 24, 36, 48, 60])
              ActionChip(
                  label: Text(tr('$m شهر', '$m mo')),
                  onPressed: () {
                    _months.text = '$m';
                    _save();
                  }),
          ]),
          const SizedBox(height: 6),
          NoteBox(
            _flatMode
                ? t('المرابحة الثابتة: الربح بيتحسب على كامل المبلغ المموَّل طول المدة، والقسط ثابت.', 'المرابحة الثابتة: يُحسب الربح على كامل المبلغ المموَّل طوال المدة، والقسط ثابت.', 'Flat murabaha: profit is charged on the full financed amount for the whole term; the payment is fixed.')
                : t('القرض المتناقص: الربح بيتحسب على الرصيد المتبقي بس، فبيقل مع كل قسط.', 'القرض المتناقص: يُحسب الربح على الرصيد المتبقي فقط، فيقل مع كل قسط.', 'Declining-balance loan: profit is charged only on the remaining balance, so it shrinks with each payment.'),
            kind: NoteKind.info,
          ),
        ]),
      ),
      ResultHero(label: tr('القسط الشهري', 'Monthly payment'), value: fmt(plan.monthly, 0), sub: tr('$modeName • $n شهر • $rate% سنويًا', '$modeName • $n months • $rate% / year')),
      SCard(
        title: tr('الخلاصة', 'Summary'),
        icon: Icons.summarize_rounded,
        color: SD.green,
        child: Column(children: [
          InfoRow(tr('المبلغ المموَّل', 'Financed amount'), fmt(fin, 0), icon: Icons.account_balance_rounded,
              hint: price > 0 ? tr('المقدم ${fmt(down / price * 100, 1)}% من السعر', 'Down payment is ${fmt(down / price * 100, 1)}% of the price') : null),
          InfoRow(tr('جملة الأقساط', 'Total installments'), fmt(plan.total, 0), icon: Icons.stacked_bar_chart_rounded),
          InfoRow(tr('جملة الأرباح', 'Total profit'), fmt(plan.profit, 0), icon: Icons.trending_up_rounded, valueColor: SD.red,
              hint: fin > 0 ? tr('${fmt(plan.profit / fin * 100, 2)}% من المبلغ المموَّل', '${fmt(plan.profit / fin * 100, 2)}% of the financed amount') : null),
          InfoRow(tr('جملة المدفوع مع المقدّم', 'Total paid incl. down payment'), fmt(grand, 0), icon: Icons.payments_rounded,
              hint: price > 0 ? t('يعني بتدفع ${fmt((grand - price) / price * 100, 1)}% زيادة على السعر', 'أي أنك تدفع ${fmt((grand - price) / price * 100, 1)}% زيادة على السعر', 'You pay ${fmt((grand - price) / price * 100, 1)}% over the price') : null),
          InfoRow(tr('التكلفة الفعلية السنوية', 'Effective annual cost'), '${fmt(effAnnual, 2)}%', icon: Icons.insights_rounded, valueColor: SD.henna,
              hint: tr('معدّل شهري ${fmt(irr * 100, 3)}% (المعدل الحقيقي حسب الأقساط)', 'Monthly rate ${fmt(irr * 100, 3)}% (true rate implied by the payments)')),
          InfoRow(tr('أول قسط: أصل / ربح', 'First payment: principal / profit'), '${fmt(plan.rows.first.principal, 0)} / ${fmt(plan.rows.first.profit, 0)}', icon: Icons.looks_one_rounded),
          InfoRow(tr('دخلك المناسب', 'Suggested income'), '≥ ${fmt(plan.monthly * 3, 0)} / ${tr('شهر', 'mo')}', icon: Icons.work_rounded,
              hint: t('عشان القسط ما يزيد عن تلت الدخل', 'كي لا يتجاوز القسط ثلث الدخل', 'So the payment stays under a third of income')),
        ]),
      ),
      SCard(
        title: tr('مقارنة الطريقتين', 'Comparing both methods'),
        icon: Icons.compare_arrows_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MiniTable(
            ['', _flatL(), _decL()],
            [
              [tr('القسط', 'Payment'), fmt(flat.monthly, 0), fmt(dec.monthly, 0)],
              [tr('الأرباح', 'Profit'), fmt(flat.profit, 0), fmt(dec.profit, 0)],
              [tr('الجملة', 'Total'), fmt(flat.total, 0), fmt(dec.total, 0)],
              [
                tr('الفعلي السنوي', 'Effective annual'),
                '${fmt((math.pow(1 + _irr(fin, flat.monthly, n), 12) - 1) * 100, 2)}%',
                '${fmt((math.pow(1 + _irr(fin, dec.monthly, n), 12) - 1) * 100, 2)}%',
              ],
            ],
            color: SD.gold,
          ),
          const SizedBox(height: 8),
          if (flat.profit > dec.profit)
            NoteBox(t('بنفس النسبة، المرابحة الثابتة أغلى بـ ${fmt(flat.profit - dec.profit, 0)}. قارن دايمًا بالتكلفة الفعلية مش بالنسبة المكتوبة.', 'بالنسبة نفسها، المرابحة الثابتة أغلى بـ ${fmt(flat.profit - dec.profit, 0)}. قارن دائمًا بالتكلفة الفعلية لا بالنسبة المعلنة.', 'At the same rate, flat murabaha costs ${fmt(flat.profit - dec.profit, 0)} more. Always compare the effective cost, not the quoted rate.'),
                kind: NoteKind.tip),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 14),
      SCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: SD.nile,
        child: ExpansionTile(
          leading: const Icon(Icons.table_view_rounded, color: SD.nile),
          title: Text(tr('جدول السداد بالتفصيل', 'Full repayment schedule'), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(t('$n قسط — دوس عشان تفتحو', '$n قسطًا — اضغط للفتح', '$n payments — tap to expand')),
          shape: const Border(),
          children: [
            MiniTable(
              [tr('الشهر', 'Month'), tr('القسط', 'Payment'), tr('الأصل', 'Principal'), tr('الربح', 'Profit'), tr('المتبقي', 'Balance')],
              [
                for (final r in plan.rows) ['${r.m}', fmt(r.pay, 0), fmt(r.principal, 0), fmt(r.profit, 0), fmt(r.remain, 0)],
                [tr('المجموع', 'Total'), fmt(plan.total, 0), fmt(fin, 0), fmt(plan.profit, 0), '—'],
              ],
              color: SD.nile,
              highlight: plan.rows.length,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      NoteBox(t('الحساب تقديري. البنوك ممكن تضيف رسوم إدارية وتأمين ودمغة. اتأكد من العقد. والمرابحة الشرعية بتشترط تملّك البنك للسلعة قبل بيعها — اسأل أهل العلم لو عندك شك.', 'الحساب تقديري. قد تضيف البنوك رسومًا إدارية وتأمينًا ودمغة، فتحقّق من العقد. والمرابحة الشرعية تشترط تملّك البنك للسلعة قبل بيعها — اسأل أهل العلم إن كان لديك شك.', 'Estimate only. Banks may add admin fees, insurance and stamp duty — check the contract. A valid Islamic murabaha requires the bank to own the item before selling it; ask a scholar if unsure.'),
          kind: NoteKind.warn),
    ]);
  }
}
