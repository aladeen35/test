import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'plan_common.dart';

/// أسماء وحدات أداة «قائمة المشتريات» (للاستيراد فقط)
String _shopUnit(String? k) => switch (k) {
      'kg' => t('كيلو', 'كيلوغرام', 'kg'),
      'rotl' => t('رطل', 'رطل', 'rotl'),
      'l' => t('لتر', 'لتر', 'liter'),
      'gal' => t('جالون', 'جالون', 'gallon'),
      'bag' => t('كيس', 'كيس', 'bag'),
      'can' => t('علبة', 'علبة', 'pack'),
      'box' => t('كرتونة', 'كرتونة', 'carton'),
      'bunch' => t('ربطة', 'ربطة', 'bunch'),
      'sack' => t('جوال', 'جوال', 'sack'),
      _ => t('حبّة', 'حبّة', 'piece'),
    };

/// نتيجة المقارنة (منطق خالص قابل للاختبار)
class BasketResult {
  final List<double> totals;
  final List<int> missing;
  final int? bestShop;
  final double splitTotal;
  final List<int?> cheapestPerItem;
  final int pricedItems;
  const BasketResult(this.totals, this.missing, this.bestShop, this.splitTotal, this.cheapestPerItem, this.pricedItems);

  double? get savings => bestShop == null ? null : totals[bestShop!] - splitTotal;

  static double? price(Map it, int shop) {
    final p = it['p'];
    if (p is List && shop < p.length && p[shop] is num && (p[shop] as num) > 0) return (p[shop] as num).toDouble();
    return null;
  }

  static BasketResult compute(List<Map> items, int shops) {
    final totals = List<double>.filled(shops, 0), missing = List<int>.filled(shops, 0);
    final cheapest = <int?>[];
    var split = 0.0;
    var priced = 0;
    for (final it in items) {
      final q = numOf(it['q'], 1) <= 0 ? 1.0 : numOf(it['q'], 1);
      int? best;
      double? bestP;
      for (var s = 0; s < shops; s++) {
        final p = price(it, s);
        if (p == null) {
          missing[s]++;
          continue;
        }
        totals[s] += p * q;
        if (bestP == null || p < bestP) {
          bestP = p;
          best = s;
        }
      }
      cheapest.add(best);
      if (bestP != null) {
        split += bestP * q;
        priced++;
      }
    }
    int? bestShop;
    for (var s = 0; s < shops; s++) {
      if (missing[s] > 0 || items.isEmpty) continue;
      if (bestShop == null || totals[s] < totals[bestShop]) bestShop = s;
    }
    return BasketResult(totals, missing, bestShop, split, cheapest, priced);
  }
}

class BasketCompareTool extends StatefulWidget {
  const BasketCompareTool({super.key});
  @override
  State<BasketCompareTool> createState() => _BasketCompareToolState();
}

class _BasketCompareToolState extends State<BasketCompareTool> {
  Map<String, dynamic> _d(AppState s) => Map<String, dynamic>.from(s.getData<Map>('basket_compare') ?? const {});
  List<String> _shops(AppState s) {
    final l = List<String>.from((_d(s)['shops'] as List?)?.map((e) => '$e') ?? const <String>[]);
    return l.length >= 2 ? l : [t('دكان الحلة', 'البقالة القريبة', 'Corner shop'), t('السوق الكبير', 'السوق المركزي', 'Big market')];
  }

  List<Map<String, dynamic>> _items(AppState s) => mapList(_d(s)['items']);
  String _cur(AppState s) => (_d(s)['cur'] as String?) ?? tr('ج.س', 'SDG');
  void _put(AppState s, {List<String>? shops, List<Map<String, dynamic>>? items, String? cur}) =>
      s.setData('basket_compare', {..._d(s), 'shops': shops ?? _shops(s), 'items': items ?? _items(s), 'cur': cur ?? _cur(s)});

  Future<void> _renameShop(int i) async {
    final s = context.read<AppState>();
    final shops = _shops(s);
    final v = await askText(context, t('اسم المحل', 'اسم المتجر', 'Shop name'), initial: shops[i]);
    if (v == null || v.trim().isEmpty) return;
    shops[i] = v.trim();
    _put(s, shops: shops);
  }

  void _addShop() {
    final s = context.read<AppState>();
    final shops = _shops(s);
    if (shops.length >= 5) return toast(t('أكتر حاجة 5 محلات', 'الحد الأقصى 5 متاجر', 'Max 5 shops'));
    _put(s, shops: [...shops, '${t('محل', 'متجر', 'Shop')} ${shops.length + 1}']);
  }

  Future<void> _removeShop(int i) async {
    final s = context.read<AppState>();
    final shops = _shops(s);
    if (shops.length <= 2) return toast(t('لازم محلين على الأقل', 'يلزم متجران على الأقل', 'At least 2 shops'));
    if (!await confirmAsk(context, t('تمسح المحل؟', 'حذف المتجر؟', 'Remove shop?'), shops[i])) return;
    final items = _items(s).map((it) {
      final p = List<dynamic>.from((it['p'] as List?) ?? const []);
      if (i < p.length) p.removeAt(i);
      return {...it, 'p': p};
    }).toList();
    shops.removeAt(i);
    _put(s, shops: shops, items: items);
  }

  Future<void> _editItem([Map<String, dynamic>? it]) async {
    final s = context.read<AppState>();
    final shops = _shops(s);
    final nC = TextEditingController(text: it?['n'] ?? '');
    final qC = TextEditingController(text: it == null ? '1' : rawNum(numOf(it['q'], 1)));
    final uC = TextEditingController(text: it?['u'] ?? t('كيلو', 'كيلوغرام', 'kg'));
    final pCs = [
      for (var i = 0; i < shops.length; i++) TextEditingController(text: it == null ? '' : rawNum(BasketResult.price(it, i) ?? 0)),
    ];
    final cur = _cur(s);
    final ok = await lifeSheet<bool>(
      context,
      it == null ? t('صنف جديد', 'صنف جديد', 'New item') : t('عدّل الصنف', 'تعديل الصنف', 'Edit item'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nC, decoration: InputDecoration(labelText: t('الصنف', 'الصنف', 'Item'), hintText: t('سكر، زيت، عدس…', 'سكر، زيت، عدس…', 'Sugar, oil, lentils…'))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: NumField(t('الكمية', 'الكمية', 'Qty'), qC)),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(controller: uC, decoration: InputDecoration(labelText: t('الوحدة', 'الوحدة', 'Unit'))),
            ),
          ),
        ]),
        Text(t('سعر الوحدة في كل محل (خليه فاضي لو ما عارفه)', 'سعر الوحدة في كل متجر (اتركه فارغًا إن لم تعرفه)', 'Unit price in each shop (leave empty if unknown)'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < shops.length; i++) NumField(shops[i], pCs[i], suffix: cur),
        const SizedBox(height: 8),
        sheetButtons(ctx, onSave: () {
          if (nC.text.trim().isEmpty) return toast(t('أكتب اسم الصنف', 'اكتب اسم الصنف', 'Enter the item name'));
          Navigator.pop(ctx, true);
        }, onDelete: it == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final name = nC.text.trim(), q = parseNum(qC.text, 1), u = uC.text.trim();
    final prices = [for (final c in pCs) parseNum(c.text) > 0 ? parseNum(c.text) : null];
    nC.dispose();
    qC.dispose();
    uC.dispose();
    for (final c in pCs) {
      c.dispose();
    }
    if (!mounted || ok == null) return;
    final items = _items(s);
    if (ok == false && it != null) {
      items.removeWhere((x) => x['id'] == it['id']);
    } else {
      final data = {'n': name, 'q': q <= 0 ? 1 : q, 'u': u, 'p': prices};
      if (it == null) {
        items.add({'id': newId(), ...data});
      } else {
        final i = items.indexWhere((x) => x['id'] == it['id']);
        if (i >= 0) items[i] = {...items[i], ...data};
      }
    }
    _put(s, items: items);
    s.awardDaily('basket_compare', 3, tr('مقارنة أسعار', 'Price comparison'));
  }

  Future<void> _import() async {
    final s = context.read<AppState>();
    final lists = mapList(s.getData<List>('shopping_lists')).where((l) => mapList(l['items']).isNotEmpty).toList();
    if (lists.isEmpty) {
      return toast(t('ما في قوائم في أداة «قائمة المشتريات»', 'لا توجد قوائم في أداة «قائمة المشتريات»', 'No lists in the «Shopping List» tool'));
    }
    final pick = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(t('جيب الأصناف من…', 'استيراد الأصناف من…', 'Import items from…')),
        children: [
          for (final l in lists)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, l),
              child: Text('🛒 ${l['name']} (${mapList(l['items']).length})', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
    if (pick == null || !mounted) return;
    final items = _items(s);
    final names = items.map((e) => '${e['n']}'.trim()).toSet();
    var added = 0;
    for (final it in mapList(pick['items'])) {
      final n = '${it['n'] ?? ''}'.trim();
      if (n.isEmpty || names.contains(n)) continue;
      names.add(n);
      items.add({'id': newId(), 'n': n, 'q': numOf(it['q'], 1), 'u': _shopUnit(it['u'] as String?), 'p': <double?>[]});
      added++;
    }
    _put(s, items: items);
    toast(t('اتضاف $added صنف', 'أُضيف $added صنف', '$added items added'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final shops = _shops(s);
    final items = _items(s);
    final cur = _cur(s);
    final r = BasketResult.compute(items, shops.length);
    final maxTotal = r.totals.fold(0.0, (a, b) => b > a ? b : a);

    String summary() {
      final b = StringBuffer('🧺 ${t('مقارنة سلة المشتريات', 'مقارنة سلة المشتريات', 'Basket price comparison')}\n');
      for (var i = 0; i < shops.length; i++) {
        b.writeln('• ${shops[i]}: ${money(r.totals[i], cur)}${r.missing[i] > 0 ? ' (${t('ناقص', 'ينقص', 'missing')} ${r.missing[i]})' : ''}');
      }
      if (r.bestShop != null) b.writeln('🏆 ${t('أرخص محل', 'أرخص متجر', 'Cheapest shop')}: ${shops[r.bestShop!]}');
      b.writeln('\n${t('التقسيمة الأوفر', 'التوزيع الأوفر', 'Best split')}: ${money(r.splitTotal, cur)}');
      for (var i = 0; i < items.length; i++) {
        final c = r.cheapestPerItem[i];
        if (c != null) b.writeln('  - ${items[i]['n']} ← ${shops[c]}');
      }
      if ((r.savings ?? 0) > 0) b.writeln('${t('بتوفّر', 'التوفير', 'You save')}: ${money(r.savings!, cur)}');
      return b.toString().trim();
    }

    return ToolList(children: [
      SCard(
        title: t('المحلات', 'المتاجر', 'Shops'),
        icon: Icons.storefront_rounded,
        color: SD.nile,
        trailing: shops.length < 5 ? IconButton(onPressed: _addShop, icon: const Icon(Icons.add_business_rounded), tooltip: t('أضف محل', 'إضافة متجر', 'Add shop')) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < shops.length; i++)
              InputChip(
                avatar: CircleAvatar(backgroundColor: palette(i + 1), child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: Text(shops[i], maxLines: 1, overflow: TextOverflow.ellipsis)),
                onPressed: () => _renameShop(i),
                onDeleted: shops.length > 2 ? () => _removeShop(i) : null,
              ),
          ]),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final v = await askText(context, t('العملة', 'العملة', 'Currency label'), initial: cur, hint: 'SDG, \$, SAR');
              if (v != null) _put(s, cur: v.trim());
            },
            child: InfoRow(t('العملة', 'العملة', 'Currency label'), cur.isEmpty ? '—' : cur, icon: Icons.payments_rounded),
          ),
          const SizedBox(height: 4),
          Text(t('دوس على اسم المحل عشان تغيّره', 'اضغط على اسم المتجر لتعديله', 'Tap a shop name to rename it'), style: const TextStyle(fontSize: 11.5)),
        ]),
      ),
      ActionRow([
        MiniAction(Icons.add_shopping_cart_rounded, t('صنف جديد', 'صنف جديد', 'Add item'), () => _editItem(), color: SD.green),
        MiniAction(Icons.download_rounded, t('من قائمة المشتريات', 'من قائمة المشتريات', 'From shopping list'), _import, color: SD.nile),
        MiniAction(Icons.cleaning_services_rounded, t('امسح الأسعار', 'مسح الأسعار', 'Clear prices'), () async {
          if (items.isEmpty) return;
          if (!await confirmAsk(context, t('تمسح كل الأسعار؟', 'مسح كل الأسعار؟', 'Clear all prices?'), t('الأصناف بتفضل', 'ستبقى الأصناف', 'Items stay'))) return;
          _put(s, items: [for (final it in items) {...it, 'p': <double?>[]}]);
        }, color: SD.red),
      ]),
      if (items.isEmpty)
        EmptyHint(Icons.shopping_basket_outlined,
            t('أضف أصناف السلة (سكر، زيت، دقيق…) وأكتب سعر كل محل — بنقول ليك وين أرخص.', 'أضف أصناف السلة واكتب سعر كل متجر لنحدد لك الأرخص.', 'Add basket items and each shop\'s price — we\'ll find the cheapest.'))
      else ...[
        for (var i = 0; i < items.length; i++) _itemCard(items[i], shops, cur, r.cheapestPerItem[i]),
        const SizedBox(height: 6),
        if (r.bestShop != null)
          ResultHero(
            label: t('أرخص محل للسلة كلها', 'أرخص متجر للسلة كاملة', 'Cheapest shop for the whole basket'),
            value: shops[r.bestShop!],
            sub: money(r.totals[r.bestShop!], cur),
            colors: const [SD.green, SD.teal, SD.nile],
          )
        else
          NoteBox(
              t('عشان نحدّد أرخص محل لازم تكتب سعر كل الأصناف في محل واحد على الأقل.', 'لتحديد أرخص متجر، أدخل أسعار جميع الأصناف في متجر واحد على الأقل.',
                  'To pick a cheapest shop, enter all item prices for at least one shop.'),
              kind: NoteKind.warn),
        SCard(
          title: t('المجموع في كل محل', 'الإجمالي لكل متجر', 'Total per shop'),
          icon: Icons.summarize_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < shops.length; i++)
              PercentBar(
                '${i == r.bestShop ? '🏆 ' : ''}${shops[i]}${r.missing[i] > 0 ? ' · ${t('ناقص', 'ينقص', 'missing')} ${r.missing[i]}' : ''}',
                maxTotal == 0 ? 0 : r.totals[i] / maxTotal,
                money(r.totals[i], cur),
                color: i == r.bestShop ? SD.green : (r.missing[i] > 0 ? Colors.grey : palette(i + 1)),
              ),
          ]),
        ),
        SCard(
          title: t('التقسيمة الأوفر', 'التوزيع الأوفر', 'Best split'),
          icon: Icons.call_split_rounded,
          color: SD.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('لو اشتريت كل صنف من المحل الأرخص فيه:', 'إذا اشتريت كل صنف من أرخص متجر له:', 'If you buy each item where it is cheapest:'), style: const TextStyle(fontSize: 13)),
            InfoRow(t('مجموع التقسيمة', 'إجمالي التوزيع', 'Split total'), money(r.splitTotal, cur), icon: Icons.shopping_bag_rounded, hint: '${r.pricedItems}/${items.length} ${t('صنف مسعّر', 'صنف مسعّر', 'priced items')}'),
            if (r.bestShop != null)
              InfoRow(t('بتوفّر مقارنة بأرخص محل', 'التوفير مقارنة بأرخص متجر', 'Savings vs best single shop'), money(r.savings ?? 0, cur),
                  icon: Icons.savings_rounded, valueColor: SD.green, hint: r.bestShop == null ? null : '${shops[r.bestShop!]}: ${money(r.totals[r.bestShop!], cur)}'),
            for (var i = 0; i < shops.length; i++)
              if (r.cheapestPerItem.contains(i))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${shops[i]}: ${[for (var j = 0; j < items.length; j++) if (r.cheapestPerItem[j] == i) items[j]['n']].join('، ')}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: readable(context, palette(i + 1))),
                  ),
                ),
            if ((r.savings ?? 0) > 0)
              NoteBox(
                  t('التوفير دا ما فيه حساب المواصلات والزمن بين المحلات — شوف لو بيستاهل.', 'لا يشمل التوفير تكلفة التنقل والوقت بين المتاجر؛ قدّر إن كان يستحق.',
                      'Savings exclude transport and time between shops — judge if it\'s worth it.'),
                  kind: NoteKind.tip),
          ]),
        ),
        ShareBar(summary),
      ],
      const SizedBox(height: 8),
      NoteBox(t('الأسعار بتتغير بسرعة — حدّثها كل ما تمشي السوق.', 'الأسعار تتغير بسرعة — حدّثها عند كل تسوّق.', 'Prices change fast — update them each market trip.'), kind: NoteKind.info),
    ]);
  }

  Widget _itemCard(Map<String, dynamic> it, List<String> shops, String cur, int? cheapest) {
    final q = numOf(it['q'], 1);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _editItem(it),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text('${it['n']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
              const SizedBox(width: 8),
              Flexible(child: Text('${fmt(q, 2)} ${it['u'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5))),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < shops.length; i++)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Tag(
                    '${i == cheapest ? '✓ ' : ''}${shops[i]}: ${BasketResult.price(it, i) == null ? '—' : money(BasketResult.price(it, i)!, '')}',
                    color: i == cheapest ? SD.green : (BasketResult.price(it, i) == null ? Colors.grey : SD.goldDeep),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
