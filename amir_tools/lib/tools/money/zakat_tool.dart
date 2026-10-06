import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

/* ───────────── حساب زكاة الأنعام ───────────── */

/// الغنم (ضأن ومعز)
(int, String) sheepZakat(int n) {
  if (n < 40) return (0, 'ما بلغت النصاب (40)');
  if (n <= 120) return (1, 'شاة واحدة');
  if (n <= 200) return (2, 'شاتان');
  if (n <= 399) return (3, 'ثلاث شياه');
  final k = n ~/ 100;
  return (k, '$k شياه (شاة في كل مئة)');
}

/// أفضل تركيبة a*x + b*y ≤ n تغطي أكبر عدد (والتعادل لصالح الأسنّ)
(int, int) _bestCombo(int n, int x, int y) {
  var best = (0, 0);
  var cover = -1;
  for (var b = 0; b * y <= n; b++) {
    final a = (n - b * y) ~/ x;
    final c = a * x + b * y;
    if (c > cover || (c == cover && b > best.$2)) {
      cover = c;
      best = (a, b);
    }
  }
  return best;
}

/// البقر (والجواميس): تبيع لكل 30، مسنّة لكل 40
String cowZakat(int n) {
  if (n < 30) return 'ما بلغت النصاب (30)';
  final (a, b) = _bestCombo(n, 30, 40);
  return [
    if (a > 0) a == 1 ? 'تبيع واحد' : (a == 2 ? 'تبيعان' : '$a أتبعة'),
    if (b > 0) b == 1 ? 'مسنّة واحدة' : (b == 2 ? 'مسنّتان' : '$b مسنّات'),
  ].join(' + ');
}

/// الإبل
String camelZakat(int n) {
  if (n < 5) return 'ما بلغت النصاب (5)';
  if (n <= 9) return 'شاة واحدة';
  if (n <= 14) return 'شاتان';
  if (n <= 19) return 'ثلاث شياه';
  if (n <= 24) return 'أربع شياه';
  if (n <= 35) return 'بنت مخاض';
  if (n <= 45) return 'بنت لبون';
  if (n <= 60) return 'حِقّة';
  if (n <= 75) return 'جَذَعة';
  if (n <= 90) return 'بنتا لبون';
  if (n <= 120) return 'حِقّتان';
  final (a, b) = _bestCombo(n, 40, 50);
  return [
    if (a > 0) a == 1 ? 'بنت لبون' : (a == 2 ? 'بنتا لبون' : '$a بنات لبون'),
    if (b > 0) b == 1 ? 'حِقّة' : (b == 2 ? 'حِقّتان' : '$b حِقاق'),
  ].join(' + ');
}

class ZakatTool extends StatefulWidget {
  const ZakatTool({super.key});
  @override
  State<ZakatTool> createState() => _ZakatToolState();
}

class _ZakatToolState extends State<ZakatTool> {
  int _tab = 0;
  final Map<String, TextEditingController> _c = {};
  bool _byGold = true;
  int _goldK = 21;
  int _irr = 0; // 0 مطري 1 مسقي 2 مختلط

  static const _keys = ['cash', 'goldG', 'p21', 'silverG', 'pSilver', 'trade', 'recv', 'debts', 'crop', 'cropPrice', 'sheep', 'cows', 'camels'];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final d = Map<String, dynamic>.from(s.getData<Map>('zakat_inputs') ?? {});
    for (final k in _keys) {
      _c[k] = TextEditingController(text: (d[k] as String?) ?? (k == 'p21' ? (s.getData<String>('gold_p21') ?? '') : ''));
    }
    _byGold = d['byGold'] ?? true;
    _goldK = d['goldK'] ?? 21;
    _irr = d['irr'] ?? 0;
    _tab = d['tab'] ?? 0;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('zakat_inputs', {
      for (final k in _keys) k: _c[k]!.text,
      'byGold': _byGold, 'goldK': _goldK, 'irr': _irr, 'tab': _tab,
    });
    setState(() {});
  }

  double v(String k) => parseNum(_c[k]!.text);

  Widget f(String label, String k, {String? suffix, String? hint}) =>
      NumField(label, _c[k]!, suffix: suffix, hint: hint ?? 'أكتب هنا', onChanged: (_) => _save());

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('المال'), icon: Icon(Icons.account_balance_wallet_rounded)),
          ButtonSegment(value: 1, label: Text('الزروع'), icon: Icon(Icons.grass_rounded)),
          ButtonSegment(value: 2, label: Text('الأنعام'), icon: Icon(Icons.pets_rounded)),
        ],
        selected: {_tab},
        onSelectionChanged: (x) {
          _tab = x.first;
          _save();
        },
      ),
      const SizedBox(height: 14),
      ...switch (_tab) { 0 => _money(), 1 => _crops(), _ => _livestock() },
      const NoteBox('الحساب ده للمساعدة بس. أحكام الزكاة فيها تفاصيل (الحَول، الديون، ذهب الزينة، السائمة والمعلوفة…) — راجع أهل العلم أو ديوان الزكاة في منطقتك.',
          kind: NoteKind.warn),
    ]);
  }

  /* ── زكاة المال ── */
  List<Widget> _money() {
    final p21 = v('p21');
    final p24 = p21 * 24 / 21;
    final goldVal = v('goldG') * p21 * _goldK / 21;
    final silverVal = v('silverG') * v('pSilver');
    final assets = v('cash') + goldVal + silverVal + v('trade') + v('recv');
    final net = assets - v('debts');
    final nisabGold = 85 * p24, nisabSilver = 595 * v('pSilver');
    final nisab = _byGold ? nisabGold : nisabSilver;
    final nisabKnown = nisab > 0;
    final due = nisabKnown && net >= nisab;
    final zakat = due ? net * .025 : 0.0;
    final s = context.read<AppState>();
    final usd = s.rate('SDG', 'USD');

    String summary() => [
          '🕌 حساب زكاة المال',
          'صافي المال الزكوي: ${fmt(net, 0)} ج.س',
          'النصاب (${_byGold ? '85 جرام ذهب عيار 24' : '595 جرام فضة'}): ${fmt(nisab, 0)} ج.س',
          due ? 'الزكاة الواجبة (2.5%): ${fmt(zakat, 0)} ج.س' : 'ما بلغ النصاب — ما عليك زكاة مال',
        ].join('\n');

    return [
      SCard(
        title: 'أموالك',
        icon: Icons.account_balance_wallet_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f('القروش الكاش والرصيد في البنك/بنكك', 'cash', suffix: 'ج.س'),
          f('بضاعة التجارة (بسعر البيع الحالي)', 'trade', suffix: 'ج.س'),
          f('ديون ليك عند ناس (مرجوّة السداد)', 'recv', suffix: 'ج.س'),
          f('ديون عليك حالّة (بتنخصم)', 'debts', suffix: 'ج.س'),
        ]),
      ),
      SCard(
        title: 'الدهب والفضة',
        icon: Icons.diamond_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f('سعر جرام الدهب عيار 21', 'p21', suffix: 'ج.س'),
          Row(children: [
            Expanded(child: f('وزن الدهب', 'goldG', suffix: 'جرام')),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _goldK,
              items: const [24, 22, 21, 18].map((k) => DropdownMenuItem(value: k, child: Text('عيار $k'))).toList(),
              onChanged: (k) {
                _goldK = k ?? 21;
                _save();
              },
            ),
          ]),
          Row(children: [
            Expanded(child: f('وزن الفضة', 'silverG', suffix: 'جرام')),
            const SizedBox(width: 10),
            Expanded(child: f('سعر جرام الفضة', 'pSilver', suffix: 'ج.س')),
          ]),
          const Text('النصاب على أساس:', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<bool>(const [(true, 'الدهب: 85 جرام عيار 24'), (false, 'الفضة: 595 جرام')], _byGold, (x) {
            _byGold = x;
            _save();
          }, color: SD.gold),
        ]),
      ),
      if (!nisabKnown)
        NoteBox(_byGold ? 'أكتب سعر جرام الدهب عشان نعرف النصاب.' : 'أكتب سعر جرام الفضة عشان نعرف النصاب.', kind: NoteKind.tip),
      ResultHero(
        label: due ? 'الزكاة الواجبة عليك' : 'زكاة المال',
        value: due ? '${fmt(zakat, 0)} ج.س' : (nisabKnown ? 'ما بلغ النصاب' : '—'),
        sub: due ? 'ربع العشر (2.5%) من ${fmt(net, 0)} ج.س • ≈ ${fmt(zakat * usd)} \$' : 'صافي مالك: ${fmt(net, 0)} ج.س',
      ),
      SCard(
        title: 'التفاصيل',
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow('الكاش', '${fmt(v('cash'), 0)} ج.س', icon: Icons.money_rounded),
          InfoRow('قيمة الدهب', '${fmt(goldVal, 0)} ج.س', icon: Icons.diamond_outlined, hint: '${fmt(v('goldG'))} جرام عيار $_goldK'),
          InfoRow('قيمة الفضة', '${fmt(silverVal, 0)} ج.س', icon: Icons.circle_outlined),
          InfoRow('بضاعة التجارة', '${fmt(v('trade'), 0)} ج.س', icon: Icons.storefront_rounded),
          InfoRow('ديون ليك', '${fmt(v('recv'), 0)} ج.س', icon: Icons.call_received_rounded),
          InfoRow('ديون عليك', '− ${fmt(v('debts'), 0)} ج.س', icon: Icons.call_made_rounded, valueColor: SD.red),
          InfoRow('الصافي', '${fmt(net, 0)} ج.س', icon: Icons.functions_rounded, valueColor: SD.green),
          InfoRow('نصاب الدهب (85 جرام عيار 24)', nisabGold > 0 ? '${fmt(nisabGold, 0)} ج.س' : '—', icon: Icons.verified_rounded),
          InfoRow('نصاب الفضة (595 جرام)', nisabSilver > 0 ? '${fmt(nisabSilver, 0)} ج.س' : '—', icon: Icons.verified_outlined),
          if (nisabKnown)
            InfoRow(due ? 'زايد عن النصاب بـ' : 'ناقص عن النصاب', '${fmt((net - nisab).abs(), 0)} ج.س',
                icon: Icons.straighten_rounded, valueColor: due ? SD.green : SD.henna),
          if (due) ...[
            InfoRow('لو قسّمتها على 12 شهر', '${fmt(zakat / 12, 0)} ج.س/شهر', icon: Icons.calendar_month_rounded,
                hint: 'تعجيل الزكاة جائز عند جمهور العلماء'),
            InfoRow('بالدولار تقريبًا', '${fmt(zakat * usd)} \$', icon: Icons.attach_money_rounded),
          ],
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      const NoteBox('الزكاة بتجب لما المال يبلغ النصاب ويحول عليه الحول (سنة هجرية كاملة). مصارفها الثمانية في سورة التوبة الآية 60.', kind: NoteKind.info),
    ];
  }

  /* ── زكاة الزروع ── */
  List<Widget> _crops() {
    const nisab = 653.0;
    final kg = v('crop'), price = v('cropPrice');
    final rate = switch (_irr) { 0 => .10, 1 => .05, _ => .075 };
    final rateName = switch (_irr) { 0 => 'العُشر (10%)', 1 => 'نصف العُشر (5%)', _ => 'ثلاثة أرباع العُشر (7.5%)' };
    final due = kg >= nisab;
    final z = due ? kg * rate : 0.0;

    String summary() => [
          '🌾 زكاة الزروع',
          'المحصول: ${fmt(kg)} كجم (النصاب ≈ 653 كجم)',
          due ? 'الواجب: ${fmt(z, 1)} كجم — $rateName' : 'ما بلغ النصاب',
          if (due && price > 0) 'القيمة ≈ ${fmt(z * price, 0)} ج.س',
        ].join('\n');

    return [
      SCard(
        title: 'محصولك',
        icon: Icons.grass_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f('وزن المحصول بعد الحصاد والتصفية', 'crop', suffix: 'كجم'),
          Wrap(spacing: 6, children: [
            for (final s in [10, 20, 50, 100])
              ActionChip(
                  label: Text('$s جوال (90 كجم)'),
                  onPressed: () {
                    _c['crop']!.text = '${s * 90}';
                    _save();
                  }),
          ]),
          const SizedBox(height: 8),
          f('سعر الكيلو (اختياري)', 'cropPrice', suffix: 'ج.س'),
          const Text('طريقة الري:', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<int>(const [(0, 'مطري / بدون كلفة (10%)'), (1, 'مسقي بكلفة (5%)'), (2, 'مختلط بالنص (7.5%)')], _irr, (x) {
            _irr = x;
            _save();
          }),
        ]),
      ),
      ResultHero(
        label: 'زكاة الزرع',
        value: due ? '${fmt(z, 1)} كجم' : (kg > 0 ? 'ما بلغ النصاب' : '—'),
        sub: due ? '$rateName • ≈ ${fmt(z / 90, 1)} جوال (90 كجم)${price > 0 ? ' • ${fmt(z * price, 0)} ج.س' : ''}' : 'النصاب 5 أوسق ≈ 653 كجم',
      ),
      SCard(
        title: 'التفاصيل',
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow('المحصول', '${fmt(kg)} كجم', icon: Icons.inventory_rounded, hint: '≈ ${fmt(kg / 90, 1)} جوال 90 • ${fmt(kg / 1000, 2)} طن'),
          InfoRow('النصاب: 5 أوسق', '≈ 653 كجم', icon: Icons.verified_rounded, hint: 'الوسق 60 صاع — والتقدير بالكيلو تقريبي'),
          InfoRow(due ? 'زايد عن النصاب' : 'ناقص عن النصاب', '${fmt((kg - nisab).abs())} كجم',
              icon: Icons.straighten_rounded, valueColor: due ? SD.green : SD.henna),
          InfoRow('لو مطري (10%)', '${fmt(due ? kg * .10 : 0, 1)} كجم', icon: Icons.water_drop_rounded),
          InfoRow('لو مسقي (5%)', '${fmt(due ? kg * .05 : 0, 1)} كجم', icon: Icons.water_rounded),
          InfoRow('لو مختلط (7.5%)', '${fmt(due ? kg * .075 : 0, 1)} كجم', icon: Icons.opacity_rounded),
          if (price > 0) InfoRow('قيمة المحصول', '${fmt(kg * price, 0)} ج.س', icon: Icons.payments_rounded),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      const NoteBox('زكاة الزروع واجبة يوم الحصاد ﴿وَآتُوا حَقَّهُ يَوْمَ حَصَادِهِ﴾ وما بيشترط ليها حَول. الجمهور على إنها في الحبوب والثمار المدّخرة (زي الذرة والقمح والتمر).',
          kind: NoteKind.info),
    ];
  }

  /* ── زكاة الأنعام ── */
  List<Widget> _livestock() {
    final sh = v('sheep').toInt(), co = v('cows').toInt(), ca = v('camels').toInt();
    final (shN, shT) = sheepZakat(sh);
    final coT = cowZakat(co), caT = camelZakat(ca);
    final any = shN > 0 || co >= 30 || ca >= 5;

    String summary() => [
          '🐪 زكاة الأنعام',
          'الغنم ($sh): $shT',
          'البقر ($co): $coT',
          'الإبل ($ca): $caT',
        ].join('\n');

    return [
      SCard(
        title: 'بهائمك',
        icon: Icons.pets_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f('الغنم (ضأن ومعز)', 'sheep', suffix: 'رأس'),
          f('البقر', 'cows', suffix: 'رأس'),
          f('الإبل', 'camels', suffix: 'رأس'),
        ]),
      ),
      ResultHero(
        label: 'الواجب في بهائمك',
        value: any ? 'عليك زكاة' : 'ما بلغت النصاب',
        sub: [if (shN > 0) 'غنم: $shT', if (co >= 30) 'بقر: $coT', if (ca >= 5) 'إبل: $caT'].join(' • '),
        colors: SD.sunset,
      ),
      SCard(
        title: 'التفاصيل',
        icon: Icons.list_alt_rounded,
        color: SD.green,
        child: Column(children: [
          InfoRow('الغنم: $sh رأس', shT, icon: Icons.cruelty_free_rounded, valueColor: shN > 0 ? SD.green : null, hint: 'النصاب 40'),
          InfoRow('البقر: $co رأس', coT, icon: Icons.agriculture_rounded, valueColor: co >= 30 ? SD.green : null, hint: 'النصاب 30'),
          InfoRow('الإبل: $ca رأس', caT, icon: Icons.landscape_rounded, valueColor: ca >= 5 ? SD.green : null, hint: 'النصاب 5'),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      SCard(
        title: 'معاني الأسنان',
        icon: Icons.menu_book_rounded,
        color: SD.nile,
        child: const Column(children: [
          InfoRow('بنت مخاض', 'أنثى إبل أكملت سنة'),
          InfoRow('بنت لبون', 'أنثى إبل أكملت سنتين'),
          InfoRow('حِقّة', 'أنثى إبل أكملت 3 سنين'),
          InfoRow('جَذَعة', 'أنثى إبل أكملت 4 سنين'),
          InfoRow('تبيع', 'عجل بقر أكمل سنة'),
          InfoRow('مسنّة', 'بقرة أكملت سنتين'),
          InfoRow('شاة', 'جذعة ضأن أو ثنية معز'),
        ]),
      ),
      SCard(
        title: 'جداول الأنصبة',
        icon: Icons.table_chart_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('🐑 الغنم', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const MiniTable(['العدد', 'الواجب'], [
            ['40 – 120', 'شاة'],
            ['121 – 200', 'شاتان'],
            ['201 – 399', '3 شياه'],
            ['400 فما فوق', 'شاة لكل 100'],
          ], color: SD.green),
          const SizedBox(height: 12),
          const Text('🐄 البقر', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const MiniTable(['العدد', 'الواجب'], [
            ['30 – 39', 'تبيع'],
            ['40 – 59', 'مسنّة'],
            ['60 – 69', 'تبيعان'],
            ['70 فما فوق', 'في كل 30 تبيع وفي كل 40 مسنّة'],
          ], color: SD.henna),
          const SizedBox(height: 12),
          const Text('🐪 الإبل', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const MiniTable(['العدد', 'الواجب'], [
            ['5 – 9', 'شاة'],
            ['10 – 14', 'شاتان'],
            ['15 – 19', '3 شياه'],
            ['20 – 24', '4 شياه'],
            ['25 – 35', 'بنت مخاض'],
            ['36 – 45', 'بنت لبون'],
            ['46 – 60', 'حِقّة'],
            ['61 – 75', 'جَذَعة'],
            ['76 – 90', 'بنتا لبون'],
            ['91 – 120', 'حِقّتان'],
            ['121 فما فوق', 'في كل 40 بنت لبون وفي كل 50 حِقّة'],
          ], color: SD.coffee),
        ]),
      ),
      const NoteBox('زكاة الأنعام على السائمة (الراعية أكتر السنة) اللي حال عليها الحول عند الجمهور. لو البهائم للتجارة بتتزكّى زكاة عروض تجارة بقيمتها.',
          kind: NoteKind.info),
    ];
  }
}
