import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import '../money/money_common.dart' show CurrencyPicker, PercentBar, curSym;

/// وحدات القياس
class _Unit {
  final String key, sd, ar, en;
  const _Unit(this.key, this.sd, this.ar, this.en);
  String get name => t(sd, ar, en);
}

const _units = [
  _Unit('kg', 'كيلو', 'كيلوغرام', 'kg'),
  _Unit('rotl', 'رطل', 'رطل', 'rotl'),
  _Unit('l', 'لتر', 'لتر', 'liter'),
  _Unit('gal', 'جالون', 'جالون', 'gallon'),
  _Unit('pc', 'حبّة', 'حبّة', 'piece'),
  _Unit('bag', 'كيس', 'كيس', 'bag'),
  _Unit('can', 'علبة', 'علبة', 'pack'),
  _Unit('box', 'كرتونة', 'كرتونة', 'carton'),
  _Unit('bunch', 'ربطة', 'ربطة', 'bunch'),
  _Unit('sack', 'جوال', 'جوال', 'sack'),
];

_Unit _unit(String? k) => _units.firstWhere((u) => u.key == k, orElse: () => _units[4]);

/// مقترحات المشتريات الشائعة في البيت السوداني
class _Sug {
  final String emoji, sd, ar, en, unit;
  const _Sug(this.emoji, this.sd, this.ar, this.en, this.unit);
  String get name => t(sd, ar, en);
}

const _sugs = [
  _Sug('🍚', 'سكر', 'سكر', 'Sugar', 'kg'),
  _Sug('🫒', 'زيت', 'زيت طعام', 'Cooking oil', 'l'),
  _Sug('🌾', 'دقيق', 'دقيق', 'Flour', 'kg'),
  _Sug('🥣', 'عدس', 'عدس', 'Lentils', 'kg'),
  _Sug('🫘', 'فول', 'فول', 'Fava beans', 'kg'),
  _Sug('🧅', 'بصل', 'بصل', 'Onions', 'kg'),
  _Sug('🍵', 'شاي', 'شاي', 'Tea', 'can'),
  _Sug('☕', 'بن', 'بن', 'Coffee beans', 'kg'),
  _Sug('🥛', 'لبن بودرة', 'حليب مجفف', 'Milk powder', 'can'),
  _Sug('🧼', 'صابون', 'صابون', 'Soap', 'pc'),
  _Sug('🍞', 'رغيف', 'خبز', 'Bread', 'pc'),
  _Sug('🍚', 'رز', 'أرز', 'Rice', 'kg'),
  _Sug('🍝', 'مكرونة', 'معكرونة', 'Pasta', 'bag'),
  _Sug('🧂', 'ملح', 'ملح', 'Salt', 'bag'),
  _Sug('🍅', 'طماطم', 'طماطم', 'Tomatoes', 'kg'),
  _Sug('🥔', 'بطاطس', 'بطاطس', 'Potatoes', 'kg'),
  _Sug('🥚', 'بيض', 'بيض', 'Eggs', 'pc'),
  _Sug('🍖', 'لحمة', 'لحم', 'Meat', 'kg'),
  _Sug('🍗', 'فراخ', 'دجاج', 'Chicken', 'kg'),
  _Sug('🌿', 'ويكة', 'ويكة (بامية مجففة)', 'Dried okra (weika)', 'bag'),
  _Sug('🧄', 'توم', 'ثوم', 'Garlic', 'kg'),
  _Sug('🌶️', 'شطة', 'شطة', 'Chili', 'bag'),
  _Sug('🥜', 'دكوة', 'زبدة فول سوداني', 'Peanut butter', 'can'),
  _Sug('🧺', 'صابون بدرة', 'مسحوق غسيل', 'Washing powder', 'bag'),
  _Sug('🔥', 'فحم', 'فحم', 'Charcoal', 'sack'),
  _Sug('🛢️', 'غاز', 'أسطوانة غاز', 'Gas cylinder', 'pc'),
];

class ShoppingTool extends StatefulWidget {
  const ShoppingTool({super.key});
  @override
  State<ShoppingTool> createState() => _ShoppingToolState();
}

class _ShoppingToolState extends State<ShoppingTool> {
  final _addC = TextEditingController();

  @override
  void dispose() {
    _addC.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _lists(AppState s) => mapList(s.getData<List>('shopping_lists'));
  void _saveLists(AppState s, List<Map<String, dynamic>> l) => s.setData('shopping_lists', l);
  String? _selId(AppState s) => s.getData<String>('shopping_sel');

  Map<String, dynamic>? _current(AppState s) {
    final l = _lists(s);
    if (l.isEmpty) return null;
    final id = _selId(s);
    return l.firstWhere((x) => x['id'] == id, orElse: () => l.first);
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic>? l) => mapList(l?['items']);

  void _updateCurrent(AppState s, Map<String, dynamic> Function(Map<String, dynamic>) f) {
    final cur = _current(s);
    if (cur == null) return;
    final l = _lists(s);
    final i = l.indexWhere((x) => x['id'] == cur['id']);
    if (i < 0) return;
    l[i] = f(l[i]);
    _saveLists(s, l);
  }

  void _setItems(AppState s, List<Map<String, dynamic>> items) => _updateCurrent(s, (m) => {...m, 'items': items});

  Future<void> _newList({String? suggested}) async {
    final s = context.read<AppState>();
    final name = await askText(context, t('قائمة جديدة', 'قائمة جديدة', 'New list'),
        initial: suggested ?? '', hint: t('مثلًا: السوق، البقالة، الخضار', 'مثلًا: السوق، البقالة، الخضار', 'e.g. Market, Grocery, Vegetables'));
    if (name == null || name.trim().isEmpty) return;
    final l = _lists(s);
    final cur = _current(s);
    final id = newId();
    l.add({'id': id, 'name': name.trim(), 'items': <Map>[], 'cur': cur?['cur'] ?? 'SDG', 'created': DateTime.now().millisecondsSinceEpoch});
    _saveLists(s, l);
    s.setData('shopping_sel', id);
  }

  /// نسخ آخر قائمة (أو الحالية) كقائمة جديدة غير مشطوبة
  void _copyList(AppState s) {
    final cur = _current(s);
    if (cur == null) return;
    final l = _lists(s);
    final id = newId();
    final items = [for (final it in _items(cur)) {...it, 'id': newId(), 'done': false}];
    l.add({
      'id': id,
      'name': '${cur['name']} (${fmtShort(todayPlace())})',
      'items': items,
      'cur': cur['cur'] ?? 'SDG',
      'created': DateTime.now().millisecondsSinceEpoch,
    });
    _saveLists(s, l);
    s.setData('shopping_sel', id);
    toast(t('اتنسخت القائمة ✓', 'نُسخت القائمة ✓', 'List copied ✓'));
  }

  void _addItem(AppState s, String name, {String unit = 'pc', double qty = 1, double price = 0}) {
    if (name.trim().isEmpty) return;
    if (_current(s) == null) {
      final id = newId();
      _saveLists(s, [
        {'id': id, 'name': t('السوق', 'السوق', 'Market'), 'items': <Map>[], 'cur': 'SDG', 'created': DateTime.now().millisecondsSinceEpoch}
      ]);
      s.setData('shopping_sel', id);
    }
    final items = _items(_current(s));
    final existing = items.indexWhere((x) => (x['n'] as String?)?.trim() == name.trim());
    if (existing >= 0) {
      items[existing] = {...items[existing], 'q': numOf(items[existing]['q'], 1) + qty, 'done': false};
    } else {
      items.add({'id': newId(), 'n': name.trim(), 'q': qty, 'u': unit, 'p': price, 'done': false});
    }
    _setItems(s, items);
    s.awardDaily('shopping_add', 3, tr('قائمة المشتريات', 'Shopping list'));
    HapticFeedback.selectionClick();
  }

  void _toggle(AppState s, String id) {
    final items = _items(_current(s));
    final i = items.indexWhere((x) => x['id'] == id);
    if (i < 0) return;
    items[i] = {...items[i], 'done': items[i]['done'] != true};
    _setItems(s, items);
    if (items.isNotEmpty && items.every((x) => x['done'] == true)) {
      s.award(5, tr('اكتملت قائمة المشتريات', 'Shopping list complete'));
      s.bump('shopping_done');
      toast(t('🎉 جبت كل الحاجات!', '🎉 اكتملت القائمة!', '🎉 Everything bought!'));
    }
  }

  void _deleteItem(AppState s, String id) {
    final items = _items(_current(s));
    final i = items.indexWhere((x) => x['id'] == id);
    if (i < 0) return;
    final removed = items.removeAt(i);
    _setItems(s, items);
    undoSnack(t('اتمسح', 'حُذف العنصر', 'Item removed'), () {
      _setItems(s, _items(_current(s))..insert(i.clamp(0, _items(_current(s)).length), removed));
    });
  }

  Future<void> _editItem(AppState s, Map<String, dynamic> it, String sym) async {
    final nC = TextEditingController(text: it['n'] ?? '');
    final qC = TextEditingController(text: fmt(numOf(it['q'], 1), 3).replaceAll(',', ''));
    final pC = TextEditingController(text: numOf(it['p']) > 0 ? fmt(numOf(it['p']), 2).replaceAll(',', '') : '');
    var unit = (it['u'] as String?) ?? 'pc';
    final ok = await lifeSheet<bool>(
      context,
      t('عدّل الحاجة', 'تعديل العنصر', 'Edit item'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nC, decoration: InputDecoration(labelText: t('الاسم', 'الاسم', 'Name'))),
        const SizedBox(height: 10),
        NumField(t('الكمية', 'الكمية', 'Quantity'), qC, suffix: _unit(unit).name),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final u in _units) PickChip(u.name, unit == u.key, () => set(() => unit = u.key), color: SD.teal),
        ]),
        const SizedBox(height: 12),
        NumField(t('سعر الوحدة (اختياري)', 'سعر الوحدة (اختياري)', 'Unit price (optional)'), pC, suffix: sym),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: SD.red),
              onPressed: () => Navigator.pop(ctx, false),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
      ]),
    );
    final name = nC.text.trim(), q = parseNum(qC.text, 1), p = parseNum(pC.text);
    nC.dispose();
    qC.dispose();
    pC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false) return _deleteItem(s, it['id']);
    final items = _items(_current(s));
    final i = items.indexWhere((x) => x['id'] == it['id']);
    if (i < 0) return;
    items[i] = {...items[i], 'n': name.isEmpty ? items[i]['n'] : name, 'q': q <= 0 ? 1 : q, 'u': unit, 'p': p < 0 ? 0 : p};
    _setItems(s, items);
  }

  String _shareText(Map<String, dynamic> list, String sym) {
    final items = _items(list);
    final b = StringBuffer('🛒 *${list['name']}*\n');
    for (final it in items) {
      final q = numOf(it['q'], 1), p = numOf(it['p']);
      b.write('${it['done'] == true ? '☑' : '☐'} ${it['n']} — ${fmt(q, 2)} ${_unit(it['u']).name}');
      if (p > 0) b.write(' (${fmt(q * p, 0)} $sym)');
      b.writeln();
    }
    final total = items.fold(0.0, (a, it) => a + numOf(it['q'], 1) * numOf(it['p']));
    if (total > 0) b.writeln('\n${t('المجموع', 'الإجمالي', 'Total')}: ${fmt(total, 0)} $sym');
    return b.toString().trim();
  }

  Future<void> _listMenu(AppState s, Map<String, dynamic> list, String action) async {
    switch (action) {
      case 'rename':
        final v = await askText(context, t('اسم القائمة', 'اسم القائمة', 'List name'), initial: list['name'] ?? '');
        if (v != null && v.trim().isNotEmpty) _updateCurrent(s, (m) => {...m, 'name': v.trim()});
      case 'copy':
        _copyList(s);
      case 'uncheck':
        _setItems(s, [for (final it in _items(list)) {...it, 'done': false}]);
      case 'clearDone':
        _setItems(s, _items(list).where((it) => it['done'] != true).toList());
      case 'delete':
        if (!await confirmAsk(context, t('تمسح القائمة؟', 'حذف القائمة؟', 'Delete list?'), '${list['name']}')) return;
        final l = _lists(s)..removeWhere((x) => x['id'] == list['id']);
        _saveLists(s, l);
        s.setData('shopping_sel', l.isEmpty ? null : l.last['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lists = _lists(s);
    final cur = _current(s);
    final items = _items(cur);
    final code = (cur?['cur'] as String?) ?? 'SDG';
    final sym = curSym(code);
    double line(Map it) => numOf(it['q'], 1) * numOf(it['p']);
    final total = items.fold(0.0, (a, it) => a + line(it));
    final bought = items.where((it) => it['done'] == true).fold(0.0, (a, it) => a + line(it));
    final doneN = items.where((it) => it['done'] == true).length;
    final unpriced = items.where((it) => numOf(it['p']) <= 0).length;
    final pending = [...items.where((it) => it['done'] != true), ...items.where((it) => it['done'] == true)];
    final names = items.map((it) => (it['n'] as String?)?.trim()).toSet();

    return ToolList(children: [
      SizedBox(
        height: 48,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final l in lists)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: PickChip('🛒 ${l['name']} (${_items(l).where((x) => x['done'] != true).length})', l['id'] == cur?['id'],
                  () => s.setData('shopping_sel', l['id']),
                  color: SD.green),
            ),
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 18),
            label: Text(t('قائمة جديدة', 'قائمة جديدة', 'New list')),
            onPressed: () => _newList(),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      if (cur == null) ...[
        EmptyHint(Icons.shopping_basket_outlined,
            t('ما عندك قوائم لسه — أعمل قائمة للسوق أو البقالة', 'لا توجد قوائم بعد — أنشئ قائمة للسوق أو البقالة', 'No lists yet — create one for the market or grocery')),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          for (final n in [t('السوق', 'السوق', 'Market'), t('البقالة', 'البقالة', 'Grocery'), t('الخضار', 'الخضار', 'Vegetables'), t('الجزارة', 'الملحمة', 'Butcher')])
            ActionChip(label: Text(n), onPressed: () => _newList(suggested: n)),
        ]),
        const SizedBox(height: 16),
      ] else ...[
        ResultHero(
          label: '${cur['name']}',
          value: total > 0 ? '${fmt(total, 0)} $sym' : '$doneN / ${items.length}',
          sub: [
            '$doneN / ${items.length} ${t('اتشرت', 'تم شراؤها', 'bought')}',
            if (total > 0) '${t('الباقي', 'المتبقي', 'Remaining')} ${fmt(total - bought, 0)} $sym',
          ].join(' · '),
          colors: const [SD.green, SD.teal, SD.nile],
        ),
        if (items.isNotEmpty)
          PercentBar(t('التقدّم', 'التقدّم', 'Progress'), items.isEmpty ? 0 : doneN / items.length, '${fmt(items.isEmpty ? 0 : doneN / items.length * 100, 0)}%'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _addC,
              decoration: InputDecoration(
                labelText: t('ضيف حاجة', 'أضف عنصرًا', 'Add an item'),
                hintText: t('مثلًا: سكر 2', 'مثلًا: سكر 2', 'e.g. Sugar 2'),
              ),
              onSubmitted: (_) => _submitAdd(s),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: () => _submitAdd(s), icon: const Icon(Icons.add_rounded), tooltip: t('ضيف', 'إضافة', 'Add')),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final g in _sugs)
            if (!names.contains(g.name))
              ActionChip(
                visualDensity: VisualDensity.compact,
                label: Text('${g.emoji} ${g.name}'),
                onPressed: () => _addItem(s, g.name, unit: g.unit),
              ),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty)
          EmptyHint(Icons.checklist_rounded, t('القائمة فاضية — دوس على المقترحات فوق', 'القائمة فارغة — اختر من المقترحات أعلاه', 'The list is empty — tap a suggestion above'))
        else
          for (final it in pending) _tile(s, it, sym),
        const SizedBox(height: 8),
        if (unpriced > 0 && items.isNotEmpty)
          Text(
            t('$unpriced حاجة بدون سعر — دوس عليها وأكتب السعر عشان المجموع يكون صاح', '$unpriced عنصر بلا سعر — اضغط عليه لإدخال السعر', '$unpriced item(s) have no price — tap to add one for an accurate total'),
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(height: 8),
        SCard(
          title: t('خيارات القائمة', 'خيارات القائمة', 'List options'),
          icon: Icons.tune_rounded,
          color: SD.coffee,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(avatar: const Icon(Icons.copy_all_rounded, size: 18), label: Text(t('انسخ القائمة دي', 'نسخ القائمة', 'Copy this list')), onPressed: () => _listMenu(s, cur, 'copy')),
              ActionChip(avatar: const Icon(Icons.edit_rounded, size: 18), label: Text(t('غيّر الاسم', 'إعادة تسمية', 'Rename')), onPressed: () => _listMenu(s, cur, 'rename')),
              ActionChip(
                  avatar: const Icon(Icons.restart_alt_rounded, size: 18), label: Text(t('شيل كل الصح', 'إلغاء كل الإشارات', 'Uncheck all')), onPressed: () => _listMenu(s, cur, 'uncheck')),
              ActionChip(
                  avatar: const Icon(Icons.cleaning_services_rounded, size: 18),
                  label: Text(t('امسح الاتشرت', 'حذف المشتراة', 'Remove bought')),
                  onPressed: () => _listMenu(s, cur, 'clearDone')),
              ActionChip(
                  avatar: const Icon(Icons.delete_outline_rounded, size: 18, color: SD.red),
                  label: Text(t('امسح القائمة', 'حذف القائمة', 'Delete list')),
                  onPressed: () => _listMenu(s, cur, 'delete')),
            ]),
            const SizedBox(height: 12),
            CurrencyPicker(t('العملة', 'العملة', 'Currency'), code, (v) => _updateCurrent(s, (m) => {...m, 'cur': v})),
          ]),
        ),
        if (items.isNotEmpty) ...[
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => copyText(_shareText(cur, sym)),
                icon: const Icon(Icons.copy_rounded),
                label: Text(tr('انسخ', 'Copy'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: SD.green),
                onPressed: () => SharePlus.instance.share(ShareParams(text: _shareText(cur, sym))),
                icon: const Icon(Icons.share_rounded),
                label: Text(t('رسّلها واتساب', 'مشاركة', 'Share'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ],
      ],
      NoteBox(
        t('أكتب الحاجة والكمية مع بعض زي «رز 3» وبتتضاف طوالي. المجموع = الكمية × سعر الوحدة.',
            'اكتب العنصر والكمية معًا مثل «أرز 3» ليُضاف مباشرة. الإجمالي = الكمية × سعر الوحدة.',
            'Type the item with a quantity like "Rice 3" to add it at once. Total = quantity × unit price.'),
        kind: NoteKind.tip,
      ),
    ]);
  }

  void _submitAdd(AppState s) {
    var text = _addC.text.trim();
    if (text.isEmpty) return;
    var qty = 1.0;
    final m = RegExp(r'^(.*?)[\s×x*]+([0-9٠-٩]+(?:[.,٫][0-9٠-٩]+)?)$').firstMatch(text);
    if (m != null && m.group(1)!.trim().isNotEmpty) {
      text = m.group(1)!.trim();
      qty = parseNum(m.group(2), 1);
    }
    final sug = _sugs.where((g) => g.name == text);
    _addItem(s, text, qty: qty <= 0 ? 1 : qty, unit: sug.isEmpty ? 'pc' : sug.first.unit);
    _addC.clear();
  }

  Widget _tile(AppState s, Map<String, dynamic> it, String sym) {
    final done = it['done'] == true;
    final q = numOf(it['q'], 1), p = numOf(it['p']);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .55);
    return Dismissible(
      key: ValueKey(it['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(color: SD.red.withValues(alpha: .85), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(s, it['id']),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: (done ? SD.green : SD.gold).withValues(alpha: .35))),
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.only(start: 4, end: 12),
          onTap: () => _editItem(s, it, sym),
          leading: Checkbox(value: done, activeColor: SD.green, onChanged: (_) => _toggle(s, it['id'])),
          title: Text(
            '${it['n']}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, decoration: done ? TextDecoration.lineThrough : null, color: done ? muted : null),
          ),
          subtitle: Text(
            '${fmt(q, 2)} ${_unit(it['u']).name}${p > 0 ? ' × ${fmt(p, 2)} $sym' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: p > 0
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${fmt(q * p, 0)} $sym', style: TextStyle(fontWeight: FontWeight.w800, color: done ? muted : null)),
                  ),
                )
              : Icon(Icons.edit_note_rounded, color: muted),
        ),
      ),
    );
  }
}
