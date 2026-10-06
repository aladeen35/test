import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

/* ───────────── حساب زكاة الأنعام ───────────── */

String _notNisab(int n) => t('ما بلغت النصاب ($n)', 'لم تبلغ النصاب ($n)', 'Below nisab ($n)');
String _sheepN(int k) => switch (k) {
      1 => tr('شاة واحدة', '1 sheep'),
      2 => tr('شاتان', '2 sheep'),
      3 => tr('ثلاث شياه', '3 sheep'),
      _ => tr('$k شياه', '$k sheep'),
    };
String _tabi(int a) => a == 1 ? tr('تبيع واحد', '1 tabi\' (1-yr calf)') : (a == 2 ? tr('تبيعان', '2 tabi\' (1-yr calves)') : tr('$a أتبعة', '$a tabi\' (1-yr calves)'));
String _musinna(int b) => b == 1 ? tr('مسنّة واحدة', '1 musinna (2-yr cow)') : (b == 2 ? tr('مسنّتان', '2 musinna (2-yr cows)') : tr('$b مسنّات', '$b musinna (2-yr cows)'));
String _makhad() => tr('بنت مخاض', 'bint makhad (1-yr she-camel)');
String _labun(int a) => a == 1 ? tr('بنت لبون', 'bint labun (2-yr she-camel)') : (a == 2 ? tr('بنتا لبون', '2 bint labun (2-yr she-camels)') : tr('$a بنات لبون', '$a bint labun (2-yr she-camels)'));
String _hiqqa(int b) => b == 1 ? tr('حِقّة', 'hiqqa (3-yr she-camel)') : (b == 2 ? tr('حِقّتان', '2 hiqqa (3-yr she-camels)') : tr('$b حِقاق', '$b hiqqa (3-yr she-camels)'));
String _jadhaa() => tr('جَذَعة', 'jadha\'a (4-yr she-camel)');
String get _sdg => tr('ج.س', 'SDG');
String get _kgU => tr('كجم', 'kg');
String get _head => tr('رأس', 'head');
List<String> _hdr() => [tr('العدد', 'Count'), tr('الواجب', 'Due')];
String _andUp(int n) => tr('$n فما فوق', '$n and up');

/// الغنم (ضأن ومعز)
(int, String) sheepZakat(int n) {
  if (n < 40) return (0, _notNisab(40));
  if (n <= 120) return (1, _sheepN(1));
  if (n <= 200) return (2, _sheepN(2));
  if (n <= 399) return (3, _sheepN(3));
  final k = n ~/ 100;
  return (k, '${_sheepN(k)} (${tr('شاة في كل مئة', '1 per 100')})');
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
  if (n < 30) return _notNisab(30);
  final (a, b) = _bestCombo(n, 30, 40);
  return [
    if (a > 0) _tabi(a),
    if (b > 0) _musinna(b),
  ].join(' + ');
}

/// الإبل
String camelZakat(int n) {
  if (n < 5) return _notNisab(5);
  if (n <= 9) return _sheepN(1);
  if (n <= 14) return _sheepN(2);
  if (n <= 19) return _sheepN(3);
  if (n <= 24) return _sheepN(4);
  if (n <= 35) return _makhad();
  if (n <= 45) return _labun(1);
  if (n <= 60) return _hiqqa(1);
  if (n <= 75) return _jadhaa();
  if (n <= 90) return _labun(2);
  if (n <= 120) return _hiqqa(2);
  final (a, b) = _bestCombo(n, 40, 50);
  return [
    if (a > 0) _labun(a),
    if (b > 0) _hiqqa(b),
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
      NumField(label, _c[k]!, suffix: suffix, hint: hint ?? t('أكتب هنا', 'اكتب هنا', 'Type here'), onChanged: (_) => _save());

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      SegmentedButton<int>(
        segments: [
          ButtonSegment(value: 0, label: Text(t('القروش', 'المال', 'Money')), icon: const Icon(Icons.account_balance_wallet_rounded)),
          ButtonSegment(value: 1, label: Text(tr('الزروع', 'Crops')), icon: const Icon(Icons.grass_rounded)),
          ButtonSegment(value: 2, label: Text(t('البهائم', 'الأنعام', 'Livestock')), icon: const Icon(Icons.pets_rounded)),
        ],
        selected: {_tab},
        onSelectionChanged: (x) {
          _tab = x.first;
          _save();
        },
      ),
      const SizedBox(height: 14),
      ...switch (_tab) { 0 => _money(), 1 => _crops(), _ => _livestock() },
      NoteBox(t('الحساب ده للمساعدة بس. أحكام الزكاة فيها تفاصيل (الحَول، الديون، دهب الزينة، السائمة والمعلوفة…) — راجع أهل العلم أو ديوان الزكاة في منطقتك.', 'هذا الحساب للمساعدة فقط. لأحكام الزكاة تفاصيل (الحَول، الديون، ذهب الزينة، السائمة والمعلوفة…) — راجع أهل العلم أو جهة الزكاة في منطقتك.', 'This is only a helper. Zakat rulings have details (the lunar year, debts, worn jewellery, grazing vs. fed livestock…) — consult a scholar or your local zakat authority.'),
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
          '🕌 ${tr('حساب زكاة المال', 'Zakat on wealth')}',
          '${tr('صافي المال الزكوي', 'Net zakatable wealth')}: ${fmt(net, 0)} $_sdg',
          '${tr('النصاب', 'Nisab')} (${_byGold ? tr('85 جرام ذهب عيار 24', '85 g of 24K gold') : tr('595 جرام فضة', '595 g silver')}): ${fmt(nisab, 0)} $_sdg',
          due ? '${tr('الزكاة الواجبة (2.5%)', 'Zakat due (2.5%)')}: ${fmt(zakat, 0)} $_sdg' : t('ما بلغ النصاب — ما عليك زكاة مال', 'لم يبلغ النصاب — لا زكاة عليك', 'Below nisab — no zakat due'),
        ].join('\n');

    return [
      SCard(
        title: t('قروشك', 'أموالك', 'Your wealth'),
        icon: Icons.account_balance_wallet_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f(t('القروش الكاش والرصيد في البنك/بنكك', 'النقد والرصيد في البنك', 'Cash & bank balance'), 'cash', suffix: _sdg),
          f(tr('بضاعة التجارة (بسعر البيع الحالي)', 'Trade goods (at current sale price)'), 'trade', suffix: _sdg),
          f(t('ديون ليك عند ناس (مرجوّة السداد)', 'ديون لك على الآخرين (مرجوّة السداد)', 'Money owed to you (expected to be repaid)'), 'recv', suffix: _sdg),
          f(t('ديون عليك حالّة (بتنخصم)', 'ديون حالّة عليك (تُخصم)', 'Debts you owe now (deducted)'), 'debts', suffix: _sdg),
        ]),
      ),
      SCard(
        title: t('الدهب والفضة', 'الذهب والفضة', 'Gold & silver'),
        icon: Icons.diamond_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f(t('سعر جرام الدهب عيار 21', 'سعر جرام الذهب عيار 21', '21K gold price per gram'), 'p21', suffix: _sdg),
          Row(children: [
            Expanded(child: f(t('وزن الدهب', 'وزن الذهب', 'Gold weight'), 'goldG', suffix: tr('جرام', 'g'))),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _goldK,
              items: const [24, 22, 21, 18].map((k) => DropdownMenuItem(value: k, child: Text(tr('عيار $k', '${k}K')))).toList(),
              onChanged: (k) {
                _goldK = k ?? 21;
                _save();
              },
            ),
          ]),
          Row(children: [
            Expanded(child: f(tr('وزن الفضة', 'Silver weight'), 'silverG', suffix: tr('جرام', 'g'))),
            const SizedBox(width: 10),
            Expanded(child: f(tr('سعر جرام الفضة', 'Silver price per gram'), 'pSilver', suffix: _sdg)),
          ]),
          Text(tr('النصاب على أساس:', 'Nisab based on:'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<bool>([(true, t('الدهب: 85 جرام عيار 24', 'الذهب: 85 جرامًا عيار 24', 'Gold: 85 g of 24K')), (false, tr('الفضة: 595 جرام', 'Silver: 595 g'))], _byGold, (x) {
            _byGold = x;
            _save();
          }, color: SD.gold),
        ]),
      ),
      if (!nisabKnown)
        NoteBox(_byGold ? t('أكتب سعر جرام الدهب عشان نعرف النصاب.', 'اكتب سعر جرام الذهب لمعرفة النصاب.', 'Enter the gold price per gram to find the nisab.') : t('أكتب سعر جرام الفضة عشان نعرف النصاب.', 'اكتب سعر جرام الفضة لمعرفة النصاب.', 'Enter the silver price per gram to find the nisab.'), kind: NoteKind.tip),
      ResultHero(
        label: due ? tr('الزكاة الواجبة عليك', 'Zakat you owe') : tr('زكاة المال', 'Zakat on wealth'),
        value: due ? '${fmt(zakat, 0)} $_sdg' : (nisabKnown ? t('ما بلغ النصاب', 'لم يبلغ النصاب', 'Below nisab') : '—'),
        sub: due ? '${tr('ربع العشر (2.5%) من', '2.5% of')} ${fmt(net, 0)} $_sdg • ≈ ${fmt(zakat * usd)} \$' : '${tr('صافي مالك', 'Your net wealth')}: ${fmt(net, 0)} $_sdg',
      ),
      SCard(
        title: tr('التفاصيل', 'Details'),
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow(t('الكاش', 'النقد', 'Cash'), '${fmt(v('cash'), 0)} $_sdg', icon: Icons.money_rounded),
          InfoRow(t('قيمة الدهب', 'قيمة الذهب', 'Gold value'), '${fmt(goldVal, 0)} $_sdg', icon: Icons.diamond_outlined, hint: tr('${fmt(v('goldG'))} جرام عيار $_goldK', '${fmt(v('goldG'))} g of ${_goldK}K')),
          InfoRow(tr('قيمة الفضة', 'Silver value'), '${fmt(silverVal, 0)} $_sdg', icon: Icons.circle_outlined),
          InfoRow(tr('بضاعة التجارة', 'Trade goods'), '${fmt(v('trade'), 0)} $_sdg', icon: Icons.storefront_rounded),
          InfoRow(t('ديون ليك', 'ديون لك', 'Owed to you'), '${fmt(v('recv'), 0)} $_sdg', icon: Icons.call_received_rounded),
          InfoRow(tr('ديون عليك', 'Your debts'), '− ${fmt(v('debts'), 0)} $_sdg', icon: Icons.call_made_rounded, valueColor: SD.red),
          InfoRow(tr('الصافي', 'Net'), '${fmt(net, 0)} $_sdg', icon: Icons.functions_rounded, valueColor: SD.green),
          InfoRow(t('نصاب الدهب (85 جرام عيار 24)', 'نصاب الذهب (85 جرامًا عيار 24)', 'Gold nisab (85 g of 24K)'), nisabGold > 0 ? '${fmt(nisabGold, 0)} $_sdg' : '—', icon: Icons.verified_rounded),
          InfoRow(tr('نصاب الفضة (595 جرام)', 'Silver nisab (595 g)'), nisabSilver > 0 ? '${fmt(nisabSilver, 0)} $_sdg' : '—', icon: Icons.verified_outlined),
          if (nisabKnown)
            InfoRow(due ? t('زايد عن النصاب بـ', 'يزيد على النصاب بـ', 'Above nisab by') : t('ناقص عن النصاب', 'ينقص عن النصاب بـ', 'Short of nisab by'), '${fmt((net - nisab).abs(), 0)} $_sdg',
                icon: Icons.straighten_rounded, valueColor: due ? SD.green : SD.henna),
          if (due) ...[
            InfoRow(t('لو قسّمتها على 12 شهر', 'إن قسّمتها على 12 شهرًا', 'Split over 12 months'), '${fmt(zakat / 12, 0)} $_sdg/${tr('شهر', 'mo')}', icon: Icons.calendar_month_rounded,
                hint: tr('تعجيل الزكاة جائز عند جمهور العلماء', 'Paying zakat early is permitted by most scholars')),
            InfoRow(tr('بالدولار تقريبًا', 'Approx. in USD'), '${fmt(zakat * usd)} \$', icon: Icons.attach_money_rounded),
          ],
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      NoteBox(t('الزكاة بتجب لما المال يبلغ النصاب ويحول عليه الحول (سنة هجرية كاملة). مصارفها الثمانية في سورة التوبة الآية 60.', 'تجب الزكاة إذا بلغ المال النصاب وحال عليه الحول (سنة هجرية كاملة). ومصارفها الثمانية في سورة التوبة، الآية 60.', 'Zakat is due once wealth reaches nisab and a full lunar (Hijri) year passes. Its eight categories of recipients are in Surat at-Tawbah, verse 60.'), kind: NoteKind.info),
    ];
  }

  /* ── زكاة الزروع ── */
  List<Widget> _crops() {
    const nisab = 653.0;
    final kg = v('crop'), price = v('cropPrice');
    final rate = switch (_irr) { 0 => .10, 1 => .05, _ => .075 };
    final rateName = switch (_irr) { 0 => tr('العُشر (10%)', 'One tenth (10%)'), 1 => tr('نصف العُشر (5%)', 'Half tenth (5%)'), _ => tr('ثلاثة أرباع العُشر (7.5%)', 'Three-quarter tenth (7.5%)') };
    final due = kg >= nisab;
    final z = due ? kg * rate : 0.0;

    String summary() => [
          '🌾 ${tr('زكاة الزروع', 'Zakat on crops')}',
          tr('المحصول: ${fmt(kg)} كجم (النصاب ≈ 653 كجم)', 'Harvest: ${fmt(kg)} kg (nisab ≈ 653 kg)'),
          due ? tr('الواجب: ${fmt(z, 1)} كجم — $rateName', 'Due: ${fmt(z, 1)} kg — $rateName') : t('ما بلغ النصاب', 'لم يبلغ النصاب', 'Below nisab'),
          if (due && price > 0) '${tr('القيمة', 'Value')} ≈ ${fmt(z * price, 0)} $_sdg',
        ].join('\n');

    return [
      SCard(
        title: tr('محصولك', 'Your harvest'),
        icon: Icons.grass_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f(tr('وزن المحصول بعد الحصاد والتصفية', 'Harvest weight after cleaning'), 'crop', suffix: _kgU),
          Wrap(spacing: 6, children: [
            for (final s in [10, 20, 50, 100])
              ActionChip(
                  label: Text(tr('$s جوال (90 كجم)', '$s sacks (90 kg)')),
                  onPressed: () {
                    _c['crop']!.text = '${s * 90}';
                    _save();
                  }),
          ]),
          const SizedBox(height: 8),
          f(tr('سعر الكيلو (اختياري)', 'Price per kg (optional)'), 'cropPrice', suffix: _sdg),
          Text(tr('طريقة الري:', 'Irrigation:'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<int>([(0, tr('مطري / بدون كلفة (10%)', 'Rain-fed / no cost (10%)')), (1, tr('مسقي بكلفة (5%)', 'Irrigated at cost (5%)')), (2, t('مختلط بالنص (7.5%)', 'مختلط مناصفةً (7.5%)', 'Mixed half-half (7.5%)'))], _irr, (x) {
            _irr = x;
            _save();
          }),
        ]),
      ),
      ResultHero(
        label: tr('زكاة الزرع', 'Crop zakat'),
        value: due ? '${fmt(z, 1)} $_kgU' : (kg > 0 ? t('ما بلغ النصاب', 'لم يبلغ النصاب', 'Below nisab') : '—'),
        sub: due ? '$rateName • ≈ ${fmt(z / 90, 1)} ${tr('جوال (90 كجم)', 'sacks (90 kg)')}${price > 0 ? ' • ${fmt(z * price, 0)} $_sdg' : ''}' : tr('النصاب 5 أوسق ≈ 653 كجم', 'Nisab is 5 awsuq ≈ 653 kg'),
      ),
      SCard(
        title: tr('التفاصيل', 'Details'),
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow(tr('المحصول', 'Harvest'), '${fmt(kg)} $_kgU', icon: Icons.inventory_rounded, hint: tr('≈ ${fmt(kg / 90, 1)} جوال 90 • ${fmt(kg / 1000, 2)} طن', '≈ ${fmt(kg / 90, 1)} × 90 kg sacks • ${fmt(kg / 1000, 2)} t')),
          InfoRow(tr('النصاب: 5 أوسق', 'Nisab: 5 awsuq'), '≈ 653 $_kgU', icon: Icons.verified_rounded, hint: tr('الوسق 60 صاع — والتقدير بالكيلو تقريبي', '1 wasq = 60 sa\' — the kg figure is approximate')),
          InfoRow(due ? t('زايد عن النصاب', 'يزيد على النصاب', 'Above nisab by') : t('ناقص عن النصاب', 'ينقص عن النصاب', 'Short of nisab by'), '${fmt((kg - nisab).abs())} $_kgU',
              icon: Icons.straighten_rounded, valueColor: due ? SD.green : SD.henna),
          InfoRow(t('لو مطري (10%)', 'إن كان مطريًا (10%)', 'If rain-fed (10%)'), '${fmt(due ? kg * .10 : 0, 1)} $_kgU', icon: Icons.water_drop_rounded),
          InfoRow(t('لو مسقي (5%)', 'إن كان مسقيًا (5%)', 'If irrigated (5%)'), '${fmt(due ? kg * .05 : 0, 1)} $_kgU', icon: Icons.water_rounded),
          InfoRow(t('لو مختلط (7.5%)', 'إن كان مختلطًا (7.5%)', 'If mixed (7.5%)'), '${fmt(due ? kg * .075 : 0, 1)} $_kgU', icon: Icons.opacity_rounded),
          if (price > 0) InfoRow(tr('قيمة المحصول', 'Harvest value'), '${fmt(kg * price, 0)} $_sdg', icon: Icons.payments_rounded),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      NoteBox(t('زكاة الزروع واجبة يوم الحصاد ﴿وَآتُوا حَقَّهُ يَوْمَ حَصَادِهِ﴾ وما بيشترط ليها حَول. الجمهور على إنها في الحبوب والثمار المدّخرة (زي الدرة والقمح والتمر).', 'تجب زكاة الزروع يوم الحصاد ﴿وَآتُوا حَقَّهُ يَوْمَ حَصَادِهِ﴾ ولا يُشترط لها حَول. والجمهور على أنها في الحبوب والثمار المدّخرة (كالذرة والقمح والتمر).', 'Crop zakat is due on harvest day ﴿وَآتُوا حَقَّهُ يَوْمَ حَصَادِهِ﴾ — no waiting year. Most scholars apply it to storable grains and fruits (sorghum, wheat, dates).'),
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
          '🐪 ${tr('زكاة الأنعام', 'Zakat on livestock')}',
          '${tr('الغنم', 'Sheep & goats')} ($sh): $shT',
          '${tr('البقر', 'Cattle')} ($co): $coT',
          '${tr('الإبل', 'Camels')} ($ca): $caT',
        ].join('\n');

    return [
      SCard(
        title: t('بهائمك', 'أنعامك', 'Your livestock'),
        icon: Icons.pets_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f(tr('الغنم (ضأن ومعز)', 'Sheep & goats'), 'sheep', suffix: _head),
          f(tr('البقر', 'Cattle'), 'cows', suffix: _head),
          f(tr('الإبل', 'Camels'), 'camels', suffix: _head),
        ]),
      ),
      ResultHero(
        label: t('الواجب في بهائمك', 'الواجب في أنعامك', 'Due on your livestock'),
        value: any ? tr('عليك زكاة', 'Zakat is due') : t('ما بلغت النصاب', 'لم تبلغ النصاب', 'Below nisab'),
        sub: [if (shN > 0) '${tr('غنم', 'Sheep')}: $shT', if (co >= 30) '${tr('بقر', 'Cattle')}: $coT', if (ca >= 5) '${tr('إبل', 'Camels')}: $caT'].join(' • '),
        colors: SD.sunset,
      ),
      SCard(
        title: tr('التفاصيل', 'Details'),
        icon: Icons.list_alt_rounded,
        color: SD.green,
        child: Column(children: [
          InfoRow('${tr('الغنم', 'Sheep & goats')}: $sh $_head', shT, icon: Icons.cruelty_free_rounded, valueColor: shN > 0 ? SD.green : null, hint: '${tr('النصاب', 'Nisab')} 40'),
          InfoRow('${tr('البقر', 'Cattle')}: $co $_head', coT, icon: Icons.agriculture_rounded, valueColor: co >= 30 ? SD.green : null, hint: '${tr('النصاب', 'Nisab')} 30'),
          InfoRow('${tr('الإبل', 'Camels')}: $ca $_head', caT, icon: Icons.landscape_rounded, valueColor: ca >= 5 ? SD.green : null, hint: '${tr('النصاب', 'Nisab')} 5'),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      SCard(
        title: tr('معاني الأسنان', 'Age terms explained'),
        icon: Icons.menu_book_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow(tr('بنت مخاض', 'Bint makhad'), t('أنثى إبل أكملت سنة', 'أنثى إبل أكملت سنة', 'She-camel that completed 1 year')),
          InfoRow(tr('بنت لبون', 'Bint labun'), t('أنثى إبل أكملت سنتين', 'أنثى إبل أكملت سنتين', 'She-camel that completed 2 years')),
          InfoRow(tr('حِقّة', 'Hiqqa'), t('أنثى إبل أكملت 3 سنين', 'أنثى إبل أكملت 3 سنوات', 'She-camel that completed 3 years')),
          InfoRow(tr('جَذَعة', 'Jadha\'a'), t('أنثى إبل أكملت 4 سنين', 'أنثى إبل أكملت 4 سنوات', 'She-camel that completed 4 years')),
          InfoRow(tr('تبيع', 'Tabi\''), tr('عجل بقر أكمل سنة', 'Calf that completed 1 year')),
          InfoRow(tr('مسنّة', 'Musinna'), tr('بقرة أكملت سنتين', 'Cow that completed 2 years')),
          InfoRow(tr('شاة', 'Shah (sheep)'), tr('جذعة ضأن أو ثنية معز', '6-month+ sheep or 1-year+ goat')),
        ]),
      ),
      SCard(
        title: tr('جداول الأنصبة', 'Nisab tables'),
        icon: Icons.table_chart_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('🐑 ${tr('الغنم', 'Sheep & goats')}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          MiniTable(_hdr(), [
            ['40 – 120', _sheepN(1)],
            ['121 – 200', _sheepN(2)],
            ['201 – 399', _sheepN(3)],
            [_andUp(400), tr('شاة لكل 100', '1 sheep per 100')],
          ], color: SD.green),
          const SizedBox(height: 12),
          Text('🐄 ${tr('البقر', 'Cattle')}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          MiniTable(_hdr(), [
            ['30 – 39', _tabi(1)],
            ['40 – 59', _musinna(1)],
            ['60 – 69', _tabi(2)],
            [_andUp(70), tr('في كل 30 تبيع وفي كل 40 مسنّة', '1 tabi\' per 30 + 1 musinna per 40')],
          ], color: SD.henna),
          const SizedBox(height: 12),
          Text('🐪 ${tr('الإبل', 'Camels')}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          MiniTable(_hdr(), [
            ['5 – 9', _sheepN(1)],
            ['10 – 14', _sheepN(2)],
            ['15 – 19', _sheepN(3)],
            ['20 – 24', _sheepN(4)],
            ['25 – 35', _makhad()],
            ['36 – 45', _labun(1)],
            ['46 – 60', _hiqqa(1)],
            ['61 – 75', _jadhaa()],
            ['76 – 90', _labun(2)],
            ['91 – 120', _hiqqa(2)],
            [_andUp(121), tr('في كل 40 بنت لبون وفي كل 50 حِقّة', '1 bint labun per 40 + 1 hiqqa per 50')],
          ], color: SD.coffee),
        ]),
      ),
      NoteBox(t('زكاة الأنعام على السائمة (الراعية أكتر السنة) اللي حال عليها الحول عند الجمهور. لو البهائم للتجارة بتتزكّى زكاة عروض تجارة بقيمتها.', 'تجب زكاة الأنعام عند الجمهور في السائمة (التي ترعى أكثر العام) إذا حال عليها الحول. وإن كانت للتجارة فتُزكّى زكاة عروض التجارة بقيمتها.', 'Most scholars apply livestock zakat to grazing animals (pasture-fed most of the year) after a full lunar year. Animals kept for trade are zakated as trade goods by value.'),
          kind: NoteKind.info),
    ];
  }
}
