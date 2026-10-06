import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

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
    final modeName = _flatMode ? 'مرابحة ثابتة' : 'قرض متناقص';

    String summary() => [
          '🏦 حساب الأقساط ($modeName)',
          'السعر: ${fmt(price, 0)} • المقدم: ${fmt(down, 0)} • المموَّل: ${fmt(fin, 0)}',
          'النسبة: $rate% سنويًا لمدة $n شهر',
          'القسط الشهري: ${fmt(plan.monthly, 0)}',
          'جملة الأرباح: ${fmt(plan.profit, 0)}',
          'جملة المدفوع (مع المقدم): ${fmt(grand, 0)}',
          'التكلفة الفعلية السنوية ≈ ${fmt(effAnnual, 2)}%',
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: 'بيانات التمويل',
        icon: Icons.request_quote_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChoiceRow<bool>(const [(true, 'مرابحة ثابتة'), (false, 'قرض متناقص')], _flatMode, (x) {
            _flatMode = x;
            _save();
          }, color: SD.indigo),
          NumField('سعر السلعة / مبلغ التمويل', _price, suffix: 'ج.س', onChanged: (_) => _save()),
          NumField('المقدّم (الدفعة الأولى)', _down, suffix: 'ج.س', onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: NumField('نسبة الربح السنوية', _rate, suffix: '%', onChanged: (_) => _save())),
            const SizedBox(width: 10),
            Expanded(child: NumField('عدد الشهور', _months, suffix: 'شهر', decimal: false, onChanged: (_) => _save())),
          ]),
          Wrap(spacing: 6, children: [
            for (final m in [6, 12, 18, 24, 36, 48, 60])
              ActionChip(
                  label: Text('$m شهر'),
                  onPressed: () {
                    _months.text = '$m';
                    _save();
                  }),
          ]),
          const SizedBox(height: 6),
          NoteBox(
            _flatMode
                ? 'المرابحة الثابتة: الربح بيتحسب على كامل المبلغ المموَّل طول المدة، والقسط ثابت.'
                : 'القرض المتناقص: الربح بيتحسب على الرصيد المتبقي بس، فبيقل مع كل قسط.',
            kind: NoteKind.info,
          ),
        ]),
      ),
      ResultHero(label: 'القسط الشهري', value: '${fmt(plan.monthly, 0)} ج.س', sub: '$modeName • $n شهر • $rate% سنويًا'),
      SCard(
        title: 'الخلاصة',
        icon: Icons.summarize_rounded,
        color: SD.green,
        child: Column(children: [
          InfoRow('المبلغ المموَّل', '${fmt(fin, 0)} ج.س', icon: Icons.account_balance_rounded,
              hint: price > 0 ? 'المقدم ${fmt(down / price * 100, 1)}% من السعر' : null),
          InfoRow('جملة الأقساط', '${fmt(plan.total, 0)} ج.س', icon: Icons.stacked_bar_chart_rounded),
          InfoRow('جملة الأرباح', '${fmt(plan.profit, 0)} ج.س', icon: Icons.trending_up_rounded, valueColor: SD.red,
              hint: fin > 0 ? '${fmt(plan.profit / fin * 100, 2)}% من المبلغ المموَّل' : null),
          InfoRow('جملة المدفوع مع المقدّم', '${fmt(grand, 0)} ج.س', icon: Icons.payments_rounded,
              hint: price > 0 ? 'يعني بتدفع ${fmt((grand - price) / price * 100, 1)}% زيادة على السعر' : null),
          InfoRow('التكلفة الفعلية السنوية', '${fmt(effAnnual, 2)}%', icon: Icons.insights_rounded, valueColor: SD.henna,
              hint: 'معدّل شهري ${fmt(irr * 100, 3)}% (المعدل الحقيقي حسب الأقساط)'),
          InfoRow('أول قسط: أصل / ربح', '${fmt(plan.rows.first.principal, 0)} / ${fmt(plan.rows.first.profit, 0)}', icon: Icons.looks_one_rounded),
          InfoRow('دخلك المناسب', '≥ ${fmt(plan.monthly * 3, 0)} ج.س/شهر', icon: Icons.work_rounded,
              hint: 'عشان القسط ما يزيد عن تلت الدخل'),
        ]),
      ),
      SCard(
        title: 'مقارنة الطريقتين',
        icon: Icons.compare_arrows_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MiniTable(
            ['', 'مرابحة ثابتة', 'قرض متناقص'],
            [
              ['القسط', fmt(flat.monthly, 0), fmt(dec.monthly, 0)],
              ['الأرباح', fmt(flat.profit, 0), fmt(dec.profit, 0)],
              ['الجملة', fmt(flat.total, 0), fmt(dec.total, 0)],
              [
                'الفعلي السنوي',
                '${fmt((math.pow(1 + _irr(fin, flat.monthly, n), 12) - 1) * 100, 2)}%',
                '${fmt((math.pow(1 + _irr(fin, dec.monthly, n), 12) - 1) * 100, 2)}%',
              ],
            ],
            color: SD.gold,
          ),
          const SizedBox(height: 8),
          if (flat.profit > dec.profit)
            NoteBox('بنفس النسبة، المرابحة الثابتة أغلى بـ ${fmt(flat.profit - dec.profit, 0)} ج.س. قارن دايمًا بالتكلفة الفعلية مش بالنسبة المكتوبة.',
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
          title: const Text('جدول السداد بالتفصيل', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('$n قسط — دوس عشان تفتحو'),
          shape: const Border(),
          children: [
            MiniTable(
              ['الشهر', 'القسط', 'الأصل', 'الربح', 'المتبقي'],
              [
                for (final r in plan.rows) ['${r.m}', fmt(r.pay, 0), fmt(r.principal, 0), fmt(r.profit, 0), fmt(r.remain, 0)],
                ['المجموع', fmt(plan.total, 0), fmt(fin, 0), fmt(plan.profit, 0), '—'],
              ],
              color: SD.nile,
              highlight: plan.rows.length,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      const NoteBox('الحساب تقديري. البنوك ممكن تضيف رسوم إدارية وتأمين ودمغة. اتأكد من العقد. والمرابحة الشرعية بتشترط تملّك البنك للسلعة قبل بيعها — اسأل أهل العلم لو عندك شك.',
          kind: NoteKind.warn),
    ]);
  }
}
