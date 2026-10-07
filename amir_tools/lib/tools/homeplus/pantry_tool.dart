import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'hp_common.dart';
import 'hp_notify.dart';

final pantryChannel = HpChannel('pantry', () => t('صلاحية المخزن', 'صلاحية المخزن', 'Pantry expiry'),
    () => t('تنبيه قبل ما الحاجات تنتهي صلاحيتها', 'تنبيه قبل انتهاء صلاحية المنتجات', 'Alert before items expire'), 7600, 300);

const _cats = ['food', 'medicine', 'cosmetics', 'other'];

String catName(String c) => switch (c) {
      'food' => t('أكل', 'طعام', 'Food'),
      'medicine' => t('دوا', 'دواء', 'Medicine'),
      'cosmetics' => t('تجميل', 'تجميل', 'Cosmetics'),
      _ => t('غيرو', 'أخرى', 'Other'),
    };

IconData catIcon(String c) => switch (c) {
      'food' => Icons.restaurant_rounded,
      'medicine' => Icons.medication_rounded,
      'cosmetics' => Icons.face_retouching_natural_rounded,
      _ => Icons.inventory_2_rounded,
    };

/// 0 = منتهي، 1 = خلال 7 أيام، 2 = سليم
int expiryStatus(DateTime exp, DateTime today) {
  final d = dayDiff(today, exp);
  if (d < 0) return 0;
  if (d <= 7) return 1;
  return 2;
}

class PantryTool extends StatefulWidget {
  const PantryTool({super.key});
  @override
  State<PantryTool> createState() => _PantryToolState();
}

class _PantryToolState extends State<PantryTool> {
  final searchC = TextEditingController();
  String? cat; // null = الكل
  int? status; // null = الكل

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      if (mounted && _cfg(s)['notify'] != false && _items(s).isNotEmpty) _reschedule(s);
    });
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('pantry_cfg') ?? {});
  void _setCfg(AppState s, Map<String, dynamic> m) => s.setData('pantry_cfg', {..._cfg(s), ...m});

  List<Map<String, dynamic>> _items(AppState s) {
    final l = mapList(s.getData<List>('pantry_list'));
    l.sort((a, b) {
      final c = (a['e'] as String? ?? '').compareTo(b['e'] as String? ?? '');
      return c != 0 ? c : (a['n'] as String? ?? '').compareTo(b['n'] as String? ?? '');
    });
    return l;
  }

  /// كل عنصر قادم ياخد فهرسًا ثابتًا حسب ترتيبه بالأقرب انتهاءً داخل النطاق 7600–7898؛ ما زاد يُتجاهل
  Future<void> _reschedule(AppState s) async {
    final cfg = _cfg(s);
    final items = <(int, String, String?, DateTime, DateTimeComponents?)>[];
    if (cfg['notify'] != false) {
      final before = intOf(cfg['before'], 3);
      final now = pNow();
      var idx = 0;
      for (final it in _items(s)) {
        final e = parseDk(it['e']);
        if (e == null) continue;
        var at = DateTime(e.year, e.month, e.day - before, 9);
        if (!at.isAfter(now)) {
          // فات وقت التنبيه المسبق: نبّه يوم الانتهاء نفسه إن كان قادمًا
          at = DateTime(e.year, e.month, e.day, 9);
          if (!at.isAfter(now)) continue;
        }
        if (idx >= pantryChannel.size - 1) break; // أكثر من 299 عنصر: الباقي بدون تنبيه
        final left = dayDiff(DateTime(at.year, at.month, at.day), e);
        items.add((
          idx++,
          '📦 ${t('قرّبت تنتهي', 'تقترب صلاحيتها من الانتهاء', 'Expiring soon')}: ${it['n']}',
          left <= 0
              ? t('صلاحيتها بتنتهي الليلة', 'تنتهي صلاحيتها اليوم', 'Expires today')
              : t('فاضل ليها ${daysLabel(left)} — ${fmtDateAr(e)}', 'متبقٍ ${daysLabel(left)} — ${fmtDateAr(e)}', '${daysLabel(left)} left — ${fmtDateAr(e)}'),
          at,
          null,
        ));
      }
    }
    await HpNotify.replace(s, pantryChannel, items);
  }

  Future<void> _edit(AppState s, [Map<String, dynamic>? it]) async {
    final nC = TextEditingController(text: it?['n'] as String? ?? '');
    final qC = TextEditingController(text: it == null ? '1' : fmt(numOf(it['q'], 1), 2).replaceAll(',', ''));
    final uC = TextEditingController(text: it?['u'] as String? ?? '');
    var c = it?['c'] as String? ?? cat ?? 'food';
    DateTime? exp = parseDk(it?['e']);
    final ok = await lifeSheet<bool>(
      context,
      it == null ? t('ضيف حاجة', 'إضافة منتج', 'Add item') : t('عدّل', 'تعديل', 'Edit item'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HpTextField(t('الاسم', 'الاسم', 'Name'), nC, hint: t('لبن بودرة، بنادول، صلصة…', 'حليب مجفف، بنادول، معجون طماطم…', 'Powdered milk, paracetamol, tomato paste…')),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final k in _cats) PickChip(catName(k), c == k, () => set(() => c = k), color: SD.teal),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumField(t('الكمية', 'الكمية', 'Quantity'), qC)),
          const SizedBox(width: 8),
          Expanded(child: HpTextField(t('الوحدة', 'الوحدة', 'Unit'), uC, hint: t('علبة، كيس…', 'علبة، كيس…', 'can, bag…'))),
        ]),
        LifeDateButton(
          label: t('تاريخ الانتهاء', 'تاريخ انتهاء الصلاحية', 'Expiry date'),
          value: exp,
          onPick: (d) => set(() => exp = d),
          first: DateTime(pToday().year - 3),
          last: DateTime(pToday().year + 15, 12, 31),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('احفظ', 'حفظ', 'Save'))),
      ]),
    );
    final name = nC.text.trim(), q = parseNum(qC.text, 1), u = uC.text.trim();
    nC.dispose();
    qC.dispose();
    uC.dispose();
    if (ok != true || !mounted) return;
    if (name.isEmpty || exp == null) {
      toast(t('لازم الاسم وتاريخ الانتهاء', 'الاسم وتاريخ الانتهاء مطلوبان', 'Name and expiry date are required'));
      return;
    }
    final list = mapList(s.getData<List>('pantry_list'));
    final m = {'id': it?['id'] ?? newId(), 'n': name, 'c': c, 'q': q, if (u.isNotEmpty) 'u': u, 'e': dk(exp!), 'a': it?['a'] ?? dk(pToday())};
    final i = list.indexWhere((x) => x['id'] == m['id']);
    if (i >= 0) {
      list[i] = m;
    } else {
      list.add(m);
      s.awardDaily('pantry_add', 3, t('ضفت للمخزن', 'إضافة للمخزن', 'Added to pantry'));
    }
    s.setData('pantry_list', list);
    _reschedule(s);
    setState(() {});
  }

  void _remove(AppState s, Map<String, dynamic> it, {bool used = false}) {
    final list = mapList(s.getData<List>('pantry_list'));
    final i = list.indexWhere((x) => x['id'] == it['id']);
    if (i < 0) return;
    final removed = list.removeAt(i);
    s.setData('pantry_list', list);
    if (used) s.bump('pantry_used');
    _reschedule(s);
    setState(() {});
    undoSnack(used ? t('اتشالت (استعملتها) ✓', 'أُزيلت (استُهلكت) ✓', 'Removed (used up) ✓') : t('اتمسحت', 'حُذفت', 'Deleted'), () {
      s.setData('pantry_list', mapList(s.getData<List>('pantry_list'))..add(removed));
      _reschedule(s);
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cfg = _cfg(s);
    final today = pToday();
    final all = _items(s);
    final q = searchC.text.trim().toLowerCase();
    int st(Map it) => expiryStatus(parseDk(it['e']) ?? today, today);
    final shown = all.where((it) {
      if (cat != null && it['c'] != cat) return false;
      if (status != null && st(it) != status) return false;
      if (q.isNotEmpty && !(it['n'] as String? ?? '').toLowerCase().contains(q)) return false;
      return true;
    }).toList();
    final nExp = all.where((it) => st(it) == 0).length;
    final nSoon = all.where((it) => st(it) == 1).length;
    final nOk = all.length - nExp - nSoon;
    final next = all.where((it) => st(it) != 0).firstOrNull;
    final nextD = next == null ? null : parseDk(next['e']);

    String summary() => [
          '📦 ${t('صلاحية مخزن البيت', 'صلاحية مخزن المنزل', 'Pantry expiry')}',
          '${t('منتهية', 'منتهية', 'Expired')}: $nExp · ${t('خلال أسبوع', 'خلال أسبوع', 'Within a week')}: $nSoon · ${t('سليمة', 'سليمة', 'OK')}: $nOk',
          for (final it in all.where((it) => st(it) <= 1).take(20)) '• ${it['n']} — ${fmtDateAr(parseDk(it['e']) ?? today, weekday: false)}',
        ].join('\n');

    return ToolList(children: [
      ResultHero(
        label: t('أقرب حاجة بتنتهي', 'الأقرب انتهاءً', 'Next to expire'),
        value: next == null ? '—' : (next['n'] as String? ?? ''),
        sub: nextD == null
            ? t('ضيف حاجات المخزن والدوا عشان نتابعها ليك', 'أضف منتجات المخزن والأدوية لمتابعتها', 'Add pantry items and medicines to track them')
            : (dayDiff(today, nextD) == 0 ? t('بتنتهي الليلة!', 'تنتهي اليوم!', 'Expires today!') : '${t('بعد', 'بعد', 'in')} ${daysLabel(dayDiff(today, nextD))} — ${fmtDateAr(nextD)}'),
        colors: const [Color(0xFF0E8C84), Color(0xFF6B3E26), Color(0xFF3A1F0C)],
      ),
      StatGrid([
        StatChip('$nExp', t('منتهية', 'منتهية', 'expired'), color: SD.red, icon: Icons.dangerous_rounded),
        StatChip('$nSoon', t('خلال أسبوع', 'خلال 7 أيام', '≤ 7 days'), color: SD.orange, icon: Icons.schedule_rounded),
        StatChip('$nOk', t('سليمة', 'سليمة', 'OK'), color: SD.green, icon: Icons.check_circle_rounded),
      ]),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: () => _edit(s), icon: const Icon(Icons.add_rounded), label: Text(t('ضيف حاجة', 'إضافة منتج', 'Add item'))),
      const SizedBox(height: 12),
      TextField(
        controller: searchC,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: t('فتّش…', 'بحث…', 'Search…'),
          suffixIcon: searchC.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    searchC.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded)),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        PickChip(t('الكل', 'الكل', 'All'), cat == null, () => setState(() => cat = null), color: SD.teal),
        for (final k in _cats) PickChip(catName(k), cat == k, () => setState(() => cat = cat == k ? null : k), color: SD.teal),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        PickChip(t('كل الحالات', 'كل الحالات', 'Any status'), status == null, () => setState(() => status = null), color: SD.gold),
        PickChip(t('منتهية', 'منتهية', 'Expired'), status == 0, () => setState(() => status = status == 0 ? null : 0), color: SD.red),
        PickChip(t('قرّبت', 'قريبة', 'Soon'), status == 1, () => setState(() => status = status == 1 ? null : 1), color: SD.orange),
        PickChip(t('سليمة', 'سليمة', 'OK'), status == 2, () => setState(() => status = status == 2 ? null : 2), color: SD.green),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: '${t('المخزن', 'المخزن', 'Pantry')} (${shown.length})',
        icon: Icons.kitchen_rounded,
        color: SD.teal,
        child: shown.isEmpty
            ? EmptyHint(Icons.inventory_2_outlined, all.isEmpty ? t('المخزن فاضي', 'المخزن فارغ', 'Pantry is empty') : t('ما في نتيجة', 'لا توجد نتائج', 'No matches'))
            : Column(children: [for (final it in shown) _ItemTile(it, today, () => _edit(s, it), () => _remove(s, it, used: true), () => _remove(s, it))]),
      ),
      SCard(
        title: t('التنبيه', 'التنبيه', 'Alerts'),
        icon: Icons.notifications_active_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HpSwitch(
            t('نبّهني قبل الانتهاء', 'نبّهني قبل الانتهاء', 'Alert me before expiry'),
            cfg['notify'] != false,
            (v) async {
              _setCfg(s, {'notify': v});
              if (v && HpNotify.supported) await HpNotify.requestPermission();
              await _reschedule(s);
              if (mounted) setState(() {});
            },
            sub: t('الساعة 9 الصباح', 'الساعة 9 صباحًا', 'At 9 AM'),
          ),
          if (cfg['notify'] != false)
            HpStepper(
              label: t('قبلها بـ', 'قبلها بـ', 'Days before'),
              value: intOf(cfg['before'], 3),
              unit: t('يوم', 'يوم', 'd'),
              min: 1,
              max: 30,
              onChanged: (v) {
                _setCfg(s, {'before': v});
                _reschedule(s);
                setState(() {});
              },
            ),
        ]),
      ),
      NoteBox(
        t('الدوا المنتهي ما تستعملو، ووديهو الصيدلية تتخلص منو صاح. «يُفضّل استهلاكه قبل» غير «تاريخ الانتهاء» — شوف المكتوب في العلبة.',
            'لا تستخدم الدواء المنتهي، وسلّمه للصيدلية للتخلص منه بأمان. «يُفضّل استهلاكه قبل» يختلف عن «تاريخ الانتهاء» — راجع ما على العبوة.',
            'Do not use expired medicine; return it to a pharmacy for safe disposal. "Best before" differs from "Use by/expiry" — check the pack.'),
        kind: NoteKind.warn,
      ),
      ShareBar(summary),
    ]);
  }
}

class _ItemTile extends StatelessWidget {
  final Map<String, dynamic> it;
  final DateTime today;
  final VoidCallback onEdit, onUsed, onDelete;
  const _ItemTile(this.it, this.today, this.onEdit, this.onUsed, this.onDelete);

  @override
  Widget build(BuildContext context) {
    final e = parseDk(it['e']) ?? today;
    final d = dayDiff(today, e);
    final st = expiryStatus(e, today);
    final color = switch (st) { 0 => SD.red, 1 => SD.orange, _ => SD.green };
    final rc = readable(context, color);
    final label = d < 0
        ? '${t('انتهت من', 'انتهت منذ', 'expired')} ${daysLabel(d)}${isEn ? ' ago' : ''}'
        : (d == 0 ? t('بتنتهي الليلة', 'تنتهي اليوم', 'expires today') : '${t('فاضل', 'متبقٍ', '')} ${daysLabel(d)}${isEn ? ' left' : ''}'.trim());
    final qty = '${fmt(numOf(it['q'], 1), 2)}${it['u'] != null ? ' ${it['u']}' : ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: BorderDirectional(start: BorderSide(color: color, width: 5)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 2, 8),
          child: Row(children: [
            Icon(catIcon(it['c'] as String? ?? 'other'), color: rc),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it['n'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('$qty · ${fmtDateAr(e, weekday: false)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: rc, fontWeight: FontWeight.w700)),
              ]),
            ),
            IconButton(visualDensity: VisualDensity.compact, tooltip: t('استعملتها', 'استُهلكت', 'Used up'), onPressed: onUsed, icon: const Icon(Icons.task_alt_rounded)),
            IconButton(visualDensity: VisualDensity.compact, tooltip: t('امسح', 'حذف', 'Delete'), onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
          ]),
        ),
      ),
    );
  }
}
