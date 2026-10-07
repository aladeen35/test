import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import 'biz_common.dart';

/// هامش الربح من سعر البيع (%)
double marginPct(double cost, double price) => price <= 0 ? 0 : (price - cost) / price * 100;

/// نسبة الزيادة على التكلفة (%)
double markupPct(double cost, double price) => cost <= 0 ? 0 : (price - cost) / cost * 100;

/// سعر البيع اللازم لهامش ربح معيّن من سعر البيع
double priceForMargin(double cost, double margin) => margin >= 100 ? double.nan : cost / (1 - margin / 100);

class ShopTool extends StatefulWidget {
  const ShopTool({super.key});
  @override
  State<ShopTool> createState() => _ShopToolState();
}

class _ShopToolState extends State<ShopTool> {
  static const _key = 'shop_ledger_data';
  final _costC = TextEditingController();
  final _marginC = TextEditingController(text: '20');
  final _priceC = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _costC.dispose();
    _marginC.dispose();
    _priceC.dispose();
    super.dispose();
  }

  Map<String, dynamic> _data(AppState s) => Map<String, dynamic>.from(s.getData<Map>(_key) ?? const {});
  void _put(AppState s, Map<String, dynamic> d) => s.setData(_key, d);
  String _cur(Map d) => ((d['cur'] as String?) ?? '').isEmpty ? 'ج.س' : d['cur'] as String;
  List<Map<String, dynamic>> _products(Map d) => mapList(d['products']);
  List<Map<String, dynamic>> _sales(Map d) => mapList(d['sales']);

  void _setList(AppState s, String k, List<Map<String, dynamic>> l) => _put(s, {..._data(s), k: l});

  Future<void> _editProduct([Map<String, dynamic>? p]) async {
    final s = context.read<AppState>();
    final cur = _cur(_data(s));
    String n(dynamic v) => v == null || numOf(v) == 0 ? '' : fmt(numOf(v), 2).replaceAll(',', '');
    final nameC = TextEditingController(text: (p?['name'] as String?) ?? '');
    final costC = TextEditingController(text: n(p?['cost']));
    final priceC = TextEditingController(text: n(p?['price']));
    final qtyC = TextEditingController(text: p == null ? '' : fmt(numOf(p['qty']), 2).replaceAll(',', ''));
    final minC = TextEditingController(text: p == null ? '3' : fmt(numOf(p['min'], 3), 2).replaceAll(',', ''));
    final tgtC = TextEditingController(text: '20');
    final ok = await lifeSheet<bool>(
      context,
      p == null ? t('صنف جديد', 'منتج جديد', 'New product') : t('عدّل الصنف', 'تعديل المنتج', 'Edit product'),
      (ctx, set) {
        final c = parseNum(costC.text), pr = parseNum(priceC.text);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم الصنف', 'اسم المنتج', 'Product name'), hintText: t('سكر كيلو، زيت جركانة…', 'سكر كيلو، زيت…', 'Sugar 1kg, oil…'))),
          const SizedBox(height: 10),
          NumField(t('سعر الجملة (التكلفة)', 'سعر التكلفة', 'Cost price'), costC, suffix: cur, onChanged: (_) => set(() {})),
          NumField(t('سعر البيع', 'سعر البيع', 'Selling price'), priceC, suffix: cur, onChanged: (_) => set(() {})),
          Row(children: [
            Expanded(child: NumField(t('هامش مستهدف', 'هامش مستهدف', 'Target margin'), tgtC, suffix: '%')),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () {
                  final v = priceForMargin(parseNum(costC.text), parseNum(tgtC.text));
                  if (v.isNaN || parseNum(costC.text) <= 0) return toast(t('أكتب التكلفة وهامش أقل من 100%', 'اكتب التكلفة وهامشًا أقل من 100%', 'Enter cost and a margin below 100%'));
                  set(() => priceC.text = fmt(v, 2).replaceAll(',', ''));
                },
                child: Text(t('اقترح سعر', 'اقترح سعرًا', 'Suggest')),
              ),
            ),
          ]),
          if (c > 0 && pr > 0)
            NoteBox(
              '${t('الهامش', 'هامش الربح', 'Margin')} ${pct(marginPct(c, pr), 1)} · ${t('الزيادة على التكلفة', 'نسبة الزيادة', 'Markup')} ${pct(markupPct(c, pr), 1)} · ${t('ربح الحبة', 'ربح الوحدة', 'Profit/unit')} ${money(pr - c, cur, 2)}',
              kind: pr < c ? NoteKind.danger : NoteKind.tip,
            ),
          Row(children: [
            Expanded(child: NumField(t('الكمية في المخزن', 'الكمية بالمخزون', 'Stock qty'), qtyC)),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('نبّهني لمن تنقص عن', 'تنبيه عند أقل من', 'Alert below'), minC)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            if (p != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            if (p != null) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم الصنف', 'اكتب اسم المنتج', 'Enter a name'));
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(t('احفظ', 'حفظ', 'Save')),
              ),
            ),
          ]),
        ]);
      },
    );
    final data = {
      'name': nameC.text.trim(),
      'cost': parseNum(costC.text),
      'price': parseNum(priceC.text),
      'qty': parseNum(qtyC.text),
      'min': parseNum(minC.text, 3),
    };
    for (final c in [nameC, costC, priceC, qtyC, minC, tgtC]) {
      c.dispose();
    }
    if (!mounted || ok == null) return;
    final l = _products(_data(s));
    if (ok == false && p != null) {
      final i = l.indexWhere((x) => x['id'] == p['id']);
      if (i < 0) return;
      final removed = l.removeAt(i);
      _setList(s, 'products', l);
      undoSnack(t('اتمسح الصنف', 'حُذف المنتج', 'Product deleted'), () => _setList(s, 'products', _products(_data(s))..insert(i.clamp(0, _products(_data(s)).length), removed)));
      return;
    }
    if (p == null) {
      l.add({'id': newId(), ...data});
      s.awardDaily('shop_product', 3, tr('إضافة صنف للدكان', 'Added a shop product'));
    } else {
      final i = l.indexWhere((x) => x['id'] == p['id']);
      if (i >= 0) l[i] = {...l[i], ...data};
    }
    _setList(s, 'products', l);
  }

  Future<void> _sell(Map<String, dynamic> p) async {
    final s = context.read<AppState>();
    final cur = _cur(_data(s));
    final qC = TextEditingController(text: '1');
    final prC = TextEditingController(text: fmt(numOf(p['price']), 2).replaceAll(',', ''));
    final ok = await lifeSheet<bool>(
      context,
      '🛒 ${t('بيع', 'تسجيل بيع', 'Sell')}: ${p['name']}',
      (ctx, set) {
        final q = parseNum(qC.text), pr = parseNum(prC.text), cost = numOf(p['cost']);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${t('في المخزن', 'المتوفر', 'In stock')}: ${fmt(numOf(p['qty']), 2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          NumField(t('الكمية', 'الكمية', 'Quantity'), qC, onChanged: (_) => set(() {})),
          NumField(t('سعر الحبة', 'سعر الوحدة', 'Unit price'), prC, suffix: cur, onChanged: (_) => set(() {})),
          InfoRow(t('الجملة', 'الإجمالي', 'Total'), money(q * pr, cur, 2), icon: Icons.payments_rounded),
          InfoRow(t('الربح', 'الربح', 'Profit'), money(q * (pr - cost), cur, 2), icon: Icons.trending_up_rounded, valueColor: pr < cost ? SD.red : SD.green),
          if (q > numOf(p['qty']))
            NoteBox(t('الكمية أكتر من الفي المخزن — المخزن حيبقى بالسالب.', 'الكمية أكبر من المتوفر؛ سيصبح المخزون سالبًا.', 'Quantity exceeds stock; stock will go negative.'), kind: NoteKind.warn),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (parseNum(qC.text) <= 0) return toast(t('أكتب الكمية', 'اكتب الكمية', 'Enter quantity'));
              Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.point_of_sale_rounded),
            label: Text(t('سجّل البيعة', 'تسجيل البيع', 'Record sale')),
          ),
        ]);
      },
    );
    final q = parseNum(qC.text), pr = parseNum(prC.text);
    qC.dispose();
    prC.dispose();
    if (!mounted || ok != true) return;
    final d = _data(s);
    final products = _products(d), sales = _sales(d);
    final i = products.indexWhere((x) => x['id'] == p['id']);
    if (i < 0) return;
    products[i]['qty'] = numOf(products[i]['qty']) - q;
    sales.add({'id': newId(), 'pid': p['id'], 'name': p['name'], 'q': q, 'price': pr, 'cost': numOf(p['cost']), 'd': dk(todayPlace()), 't': DateTime.now().millisecondsSinceEpoch});
    _put(s, {...d, 'products': products, 'sales': sales.length > 2000 ? sales.sublist(sales.length - 2000) : sales});
    HapticFeedback.selectionClick();
    s.awardDaily('shop_sale', 3, tr('تسجيل مبيعات الدكان', 'Logged shop sales'));
    s.bump('shop_sales');
    final left = numOf(products[i]['qty']);
    if (left <= numOf(products[i]['min'], 3)) toast('⚠️ ${p['name']}: ${t('فاضل', 'متبقٍ', 'only')} ${fmt(left, 2)} ${t('بس', 'فقط', 'left')}');
  }

  Future<void> _restock(Map<String, dynamic> p) async {
    final s = context.read<AppState>();
    final v = await askText(context, '📦 ${t('زوّد المخزن', 'إضافة للمخزون', 'Restock')}: ${p['name']}', number: true, hint: t('الكمية الجديدة', 'الكمية المضافة', 'Quantity added'));
    if (v == null || parseNum(v) == 0 || !mounted) return;
    final l = _products(_data(s));
    final i = l.indexWhere((x) => x['id'] == p['id']);
    if (i < 0) return;
    l[i]['qty'] = numOf(l[i]['qty']) + parseNum(v);
    _setList(s, 'products', l);
  }

  void _deleteSale(Map<String, dynamic> sale) {
    final s = context.read<AppState>();
    final d = _data(s);
    final sales = _sales(d)..removeWhere((x) => x['id'] == sale['id']);
    final products = _products(d);
    final i = products.indexWhere((x) => x['id'] == sale['pid']);
    if (i >= 0) products[i]['qty'] = numOf(products[i]['qty']) + numOf(sale['q']);
    _put(s, {...d, 'products': products, 'sales': sales});
    toast(t('اتلغت البيعة ورجعت الكمية للمخزن', 'أُلغي البيع وأُعيدت الكمية للمخزون', 'Sale removed; stock restored'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = _data(s);
    final cur = _cur(d);
    final products = _products(d)..sort((a, b) => ((a['name'] as String?) ?? '').compareTo((b['name'] as String?) ?? ''));
    final sales = _sales(d);
    final today = todayPlace();
    final todayK = dk(today), monthK = mk(today.year, today.month);

    double rev(Iterable<Map> l) => l.fold(0.0, (a, x) => a + numOf(x['q']) * numOf(x['price']));
    double prof(Iterable<Map> l) => l.fold(0.0, (a, x) => a + numOf(x['q']) * (numOf(x['price']) - numOf(x['cost'])));
    final todaySales = sales.where((x) => x['d'] == todayK).toList();
    final monthSales = sales.where((x) => ((x['d'] as String?) ?? '').startsWith(monthK)).toList();
    final stockCost = products.fold(0.0, (a, p) => a + (numOf(p['qty']) > 0 ? numOf(p['qty']) * numOf(p['cost']) : 0));
    final stockSell = products.fold(0.0, (a, p) => a + (numOf(p['qty']) > 0 ? numOf(p['qty']) * numOf(p['price']) : 0));
    final low = products.where((p) => numOf(p['qty']) <= numOf(p['min'], 3)).toList();

    // آخر 7 أيام
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final dayRev = {for (final x in days) dk(x): rev(sales.where((y) => y['d'] == dk(x)))};
    final maxDay = dayRev.values.fold(0.0, (a, b) => a > b ? a : b);
    // آخر 6 شهور
    final months = <(int, int)>[];
    for (var i = 5; i >= 0; i--) {
      var m = today.month - i, y = today.year;
      while (m < 1) {
        m += 12;
        y--;
      }
      months.add((y, m));
    }
    final monthRev = {for (final m in months) mk(m.$1, m.$2): sales.where((x) => ((x['d'] as String?) ?? '').startsWith(mk(m.$1, m.$2)))};
    final maxMonth = monthRev.values.fold(0.0, (a, l) => rev(l) > a ? rev(l) : a);

    // الأكثر مبيعًا هذا الشهر
    final best = <String, double>{};
    for (final x in monthSales) {
      best[(x['name'] as String?) ?? '?'] = (best[(x['name'] as String?) ?? '?'] ?? 0) + numOf(x['q']) * (numOf(x['price']) - numOf(x['cost']));
    }
    final bestL = best.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final shown = _q.isEmpty ? products : products.where((p) => ((p['name'] as String?) ?? '').contains(_q)).toList();
    final recent = [...sales]..sort((a, b) => numOf(b['t']).compareTo(numOf(a['t'])));

    String summary() {
      final b = StringBuffer('🏪 ${t('دفتر الدكان', 'دفتر المحل', 'Shop ledger')} — ${fmtDateAr(today)}\n');
      b.writeln('${t('مبيعات الليلة', 'مبيعات اليوم', 'Today sales')}: ${money(rev(todaySales), cur)} (${t('ربح', 'ربح', 'profit')} ${money(prof(todaySales), cur)})');
      b.writeln('${t('مبيعات الشهر', 'مبيعات الشهر', 'Month sales')}: ${money(rev(monthSales), cur)} (${t('ربح', 'ربح', 'profit')} ${money(prof(monthSales), cur)})');
      b.writeln('${t('قيمة المخزن بالتكلفة', 'قيمة المخزون بالتكلفة', 'Stock value at cost')}: ${money(stockCost, cur)}');
      if (low.isNotEmpty) {
        b.writeln('\n⚠️ ${t('أصناف قرّبت تخلص', 'أصناف منخفضة', 'Low stock')}:');
        for (final p in low) {
          b.writeln('• ${p['name']}: ${fmt(numOf(p['qty']), 2)}');
        }
      }
      return b.toString().trim();
    }

    // الحاسبة السريعة
    final qc = parseNum(_costC.text), qm = parseNum(_marginC.text), qp = parseNum(_priceC.text);
    final sugg = priceForMargin(qc, qm);

    return ToolList(children: [
      SCard(
        title: t('حاسبة السعر السريعة', 'حاسبة التسعير السريعة', 'Quick price calculator'),
        icon: Icons.calculate_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: NumField(t('التكلفة', 'التكلفة', 'Cost'), _costC, suffix: cur, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('الهامش', 'الهامش', 'Margin'), _marginC, suffix: '%', onChanged: (_) => setState(() {}))),
          ]),
          if (qc > 0)
            InfoRow(t('بيعها بـ', 'سعر البيع المقترح', 'Sell at'), sugg.isNaN ? '—' : money(sugg, cur, 2),
                icon: Icons.sell_rounded, valueColor: SD.green, hint: sugg.isNaN ? null : '${t('يعني زيادة', 'أي زيادة', 'i.e. markup')} ${pct(markupPct(qc, sugg), 1)} ${t('على التكلفة', 'على التكلفة', 'on cost')}'),
          const SizedBox(height: 6),
          NumField(t('ولا أكتب سعر البيع وأحسب ليك الهامش', 'أو أدخل سعر البيع لحساب الهامش', 'Or enter a selling price to get the margin'), _priceC, suffix: cur, onChanged: (_) => setState(() {})),
          if (qc > 0 && qp > 0) ...[
            InfoRow(t('هامش الربح', 'هامش الربح', 'Margin'), pct(marginPct(qc, qp), 1), icon: Icons.percent_rounded, valueColor: qp < qc ? SD.red : SD.green),
            InfoRow(t('الزيادة على التكلفة', 'نسبة الزيادة (Markup)', 'Markup'), pct(markupPct(qc, qp), 1), icon: Icons.trending_up_rounded),
            InfoRow(t('ربح الحبة', 'ربح الوحدة', 'Profit per unit'), money(qp - qc, cur, 2), icon: Icons.savings_rounded, valueColor: qp < qc ? SD.red : SD.green),
          ],
          Text(
            t('الهامش = الربح ÷ سعر البيع. الزيادة = الربح ÷ التكلفة. يعني هامش 20% = زيادة 25%.', 'الهامش = الربح ÷ سعر البيع، والزيادة = الربح ÷ التكلفة؛ فهامش 20% يساوي زيادة 25%.',
                'Margin = profit ÷ price; markup = profit ÷ cost. A 20% margin equals a 25% markup.'),
            style: const TextStyle(fontSize: 12),
          ),
        ]),
      ),
      ResultHero(
        label: t('ربح الشهر دا', 'ربح هذا الشهر', 'Profit this month'),
        value: money(prof(monthSales), cur),
        sub: '${t('مبيعات', 'مبيعات', 'Sales')} ${money(rev(monthSales), cur)} · ${monthSales.length} ${t('بيعة', 'عملية', 'sales')}',
        colors: const [SD.green, SD.teal, SD.brownDeep],
      ),
      StatGrid([
        StatChip(compact(rev(todaySales)), t('مبيعات الليلة', 'مبيعات اليوم', 'Today sales'), color: SD.gold, icon: Icons.today_rounded),
        StatChip(compact(prof(todaySales)), t('ربح الليلة', 'ربح اليوم', 'Today profit'), color: SD.green, icon: Icons.trending_up_rounded),
        StatChip(rev(monthSales) == 0 ? '—' : pct(prof(monthSales) / rev(monthSales) * 100), t('هامش الشهر', 'هامش الشهر', 'Month margin'), color: SD.teal, icon: Icons.percent_rounded),
        StatChip(compact(stockCost), t('المخزن بالتكلفة', 'المخزون بالتكلفة', 'Stock at cost'), color: SD.nile, icon: Icons.inventory_2_rounded),
        StatChip(compact(stockSell - stockCost), t('ربح متوقع من المخزن', 'ربح المخزون المتوقع', 'Stock profit'), color: SD.purple, icon: Icons.auto_graph_rounded),
        StatChip('${products.length}', t('صنف', 'منتج', 'products'), color: SD.orange, icon: Icons.category_rounded),
      ]),
      const SizedBox(height: 12),
      if (low.isNotEmpty)
        SCard(
          title: t('قرّب يخلص — جيب تاني', 'مخزون منخفض', 'Low stock'),
          icon: Icons.warning_amber_rounded,
          color: SD.red,
          child: Column(children: [
            for (final p in low)
              MiniRow(
                p['name'] as String? ?? '',
                fmt(numOf(p['qty']), 2),
                sub: '${t('الحد', 'الحد الأدنى', 'Min')}: ${fmt(numOf(p['min'], 3), 2)}',
                color: numOf(p['qty']) <= 0 ? SD.red : SD.orange,
                trailing: iconBtn(Icons.add_box_rounded, t('زوّد', 'إضافة', 'Restock'), () => _restock(p), color: SD.green),
              ),
          ]),
        ),
      SCard(
        title: t('الأصناف', 'المنتجات', 'Products'),
        icon: Icons.storefront_rounded,
        color: SD.coffee,
        trailing: iconBtn(Icons.add_circle_rounded, t('صنف جديد', 'منتج جديد', 'New product'), () => _editProduct(), color: SD.gold),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (products.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: t('فتّش', 'بحث', 'Search'), isDense: true),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
          if (products.isEmpty)
            EmptyHint(Icons.storefront_outlined, t('ضيف أصناف الدكان بسعر الجملة وسعر البيع والكمية', 'أضف منتجاتك بسعر التكلفة والبيع والكمية', 'Add your products with cost, price and quantity'),
                action: FilledButton.icon(onPressed: () => _editProduct(), icon: const Icon(Icons.add_rounded), label: Text(t('ضيف صنف', 'إضافة منتج', 'Add product')))),
          for (final p in shown) _productTile(p, cur),
        ]),
      ),
      if (sales.isNotEmpty) ...[
        SCard(
          title: t('مبيعات آخر 7 أيام', 'مبيعات آخر 7 أيام', 'Last 7 days'),
          icon: Icons.bar_chart_rounded,
          color: SD.gold,
          child: Column(children: [
            for (final x in days)
              BizBar('${shortDaysL[x.weekday - 1]} ${fmtShort(x)}', maxDay == 0 ? 0 : dayRev[dk(x)]! / maxDay, money(dayRev[dk(x)]!, cur), color: x == today ? SD.green : SD.gold),
          ]),
        ),
        SCard(
          title: t('المبيعات بالشهر', 'المبيعات الشهرية', 'Monthly sales'),
          icon: Icons.calendar_month_rounded,
          color: SD.teal,
          child: Column(children: [
            for (final m in months)
              BizBar(fmtMonth(m.$1, m.$2), maxMonth == 0 ? 0 : rev(monthRev[mk(m.$1, m.$2)]!) / maxMonth, money(rev(monthRev[mk(m.$1, m.$2)]!), cur),
                  hint: '${t('ربح', 'ربح', 'Profit')}: ${money(prof(monthRev[mk(m.$1, m.$2)]!), cur)}', color: SD.teal),
          ]),
        ),
        if (bestL.isNotEmpty)
          SCard(
            title: t('الأكتر ربح الشهر دا', 'الأعلى ربحًا هذا الشهر', 'Top earners this month'),
            icon: Icons.emoji_events_rounded,
            color: SD.goldDeep,
            child: Column(children: [
              for (final e in bestL.take(5)) BizBar(e.key, bestL.first.value <= 0 ? 0 : e.value / bestL.first.value, money(e.value, cur), color: SD.goldDeep),
            ]),
          ),
        SCard(
          title: t('آخر البيعات', 'آخر المبيعات', 'Recent sales'),
          icon: Icons.receipt_long_rounded,
          color: SD.green,
          child: Column(children: [
            for (final x in recent.take(20))
              MiniRow(
                '${x['name']} × ${fmt(numOf(x['q']), 2)}',
                money(numOf(x['q']) * numOf(x['price']), cur),
                sub: '${parseDk(x['d']) == null ? '' : fmtShort(parseDk(x['d'])!)} · ${t('ربح', 'ربح', 'profit')} ${money(numOf(x['q']) * (numOf(x['price']) - numOf(x['cost'])), cur)}',
                trailing: iconBtn(Icons.undo_rounded, t('ألغِ البيعة', 'إلغاء البيع', 'Undo sale'), () => _deleteSale(x)),
              ),
          ]),
        ),
      ],
      SCard(
        title: t('الضبط', 'الإعدادات', 'Settings'),
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: CurField(cur, (v) => _put(s, {..._data(s), 'cur': v})),
      ),
      ShareBar(summary),
      const SizedBox(height: 8),
      NoteBox(
        t('الربح هنا = (سعر البيع − سعر الجملة) × الكمية، من غير الإيجار والكهرباء والعمّال. خصمهم عشان تعرف صافي ربحك.',
            'الربح المحسوب إجمالي: (البيع − التكلفة) × الكمية، ولا يشمل الإيجار والكهرباء والأجور؛ اخصمها لمعرفة صافي الربح.',
            'Profit here is gross: (price − cost) × qty, before rent, power and wages. Subtract those for net profit.'),
        kind: NoteKind.info,
      ),
    ]);
  }

  Widget _productTile(Map<String, dynamic> p, String cur) {
    final cost = numOf(p['cost']), price = numOf(p['price']), qty = numOf(p['qty']);
    final isLow = qty <= numOf(p['min'], 3);
    final m = marginPct(cost, price);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: (isLow ? SD.red : SD.gold).withValues(alpha: .4))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MiniRow(
            p['name'] as String? ?? '',
            '${t('المخزن', 'المخزون', 'Stock')}: ${fmt(qty, 2)}',
            sub: '${t('جملة', 'تكلفة', 'Cost')} ${money(cost, cur, 2)} · ${t('بيع', 'بيع', 'Price')} ${money(price, cur, 2)}',
            color: isLow ? SD.red : SD.green,
            onTap: () => _editProduct(p),
          ),
          Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${t('هامش', 'هامش', 'Margin')} ${pct(m, 1)}', style: TextStyle(fontSize: 12, color: readable(context, price < cost ? SD.red : SD.teal))),
            ),
            Chip(visualDensity: VisualDensity.compact, label: Text('${t('زيادة', 'زيادة', 'Markup')} ${pct(markupPct(cost, price), 1)}', style: const TextStyle(fontSize: 12))),
          ]),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _sell(p),
                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('بيع', 'بيع', 'Sell'))),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _restock(p),
                icon: const Icon(Icons.add_box_rounded, size: 18),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('زوّد', 'إضافة', 'Restock'))),
              ),
            ),
            iconBtn(Icons.edit_rounded, t('عدّل', 'تعديل', 'Edit'), () => _editProduct(p)),
          ]),
        ]),
      ),
    );
  }
}
