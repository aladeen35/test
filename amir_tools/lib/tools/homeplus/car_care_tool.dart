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

final carChannel = HpChannel('car', () => t('صيانة العربية', 'صيانة السيارة', 'Car maintenance'),
    () => t('تذكير بمواعيد الصيانة والترخيص', 'تذكير بمواعيد الصيانة والترخيص', 'Service, licence and insurance reminders'), 8000, 100);

/// بنود الصيانة الافتراضية: (مفتاح، كم، أشهر، أيقونة)
const _defaults = <(String, int?, int?, IconData)>[
  ('oil', 5000, 6, Icons.oil_barrel_rounded),
  ('oil_filter', 5000, 6, Icons.filter_alt_rounded),
  ('air_filter', 15000, 12, Icons.air_rounded),
  ('tyres', 40000, 60, Icons.tire_repair_rounded),
  ('battery', null, 36, Icons.battery_charging_full_rounded),
  ('brakes', 30000, null, Icons.do_disturb_on_rounded),
  ('licence', null, 12, Icons.badge_rounded),
  ('insurance', null, 12, Icons.verified_user_rounded),
];

String itemName(Map it) => switch (it['k']) {
      'oil' => t('زيت المكنة', 'زيت المحرك', 'Engine oil'),
      'oil_filter' => t('فلتر الزيت', 'فلتر الزيت', 'Oil filter'),
      'air_filter' => t('فلتر الهوا', 'فلتر الهواء', 'Air filter'),
      'tyres' => t('اللساتك', 'الإطارات', 'Tyres'),
      'battery' => t('البطارية', 'البطارية', 'Battery'),
      'brakes' => t('فحمات الفرامل', 'فحمات الفرامل', 'Brake pads'),
      'licence' => t('تجديد الترخيص', 'تجديد الترخيص', 'Licence renewal'),
      'insurance' => t('تجديد التأمين', 'تجديد التأمين', 'Insurance renewal'),
      _ => (it['n'] as String?) ?? t('بند', 'بند', 'Item'),
    };

IconData itemIcon(Map it) {
  for (final d in _defaults) {
    if (d.$1 == it['k']) return d.$4;
  }
  return Icons.build_rounded;
}

/// حالة بند: كم/أيام متبقية ونسبة الاستهلاك
class Due {
  final Map<String, dynamic> item;
  final int? kmLeft, daysLeft;
  final DateTime? dueDate;
  final double frac; // 0 = جديد، 1 = حان
  final bool unknown;
  Due(this.item, this.kmLeft, this.daysLeft, this.dueDate, this.frac, this.unknown);
  bool get overdue => !unknown && ((kmLeft != null && kmLeft! <= 0) || (daysLeft != null && daysLeft! < 0));
  bool get soon => !unknown && !overdue && ((kmLeft != null && kmLeft! <= 500) || (daysLeft != null && daysLeft! <= 14));
}

Due dueOf(Map<String, dynamic> it, int curKm, DateTime today) {
  final ikm = it['km'] as num?, imo = it['mo'] as num?;
  final lastKm = it['lastKm'] as num?;
  final lastD = parseDk(it['lastD']);
  if (lastKm == null && lastD == null) return Due(it, null, null, null, 0, true);
  int? kmLeft, daysLeft;
  DateTime? dd;
  var frac = 0.0;
  if (ikm != null && ikm > 0 && lastKm != null) {
    kmLeft = (lastKm + ikm - curKm).round();
    frac = (curKm - lastKm) / ikm;
  }
  if (imo != null && imo > 0 && lastD != null) {
    dd = DateTime(lastD.year, lastD.month + imo.toInt(), lastD.day);
    daysLeft = dayDiff(today, dd);
    final total = dayDiff(lastD, dd);
    final f = total <= 0 ? 1.0 : dayDiff(lastD, today) / total;
    if (f > frac) frac = f;
  }
  return Due(it, kmLeft, daysLeft, dd, frac, false);
}

class CarCareTool extends StatefulWidget {
  const CarCareTool({super.key});
  @override
  State<CarCareTool> createState() => _CarCareToolState();
}

class _CarCareToolState extends State<CarCareTool> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      if (mounted && _cfg(s)['notify'] != false && _cars(s).isNotEmpty) _reschedule(s);
    });
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('car_cfg') ?? {});
  void _setCfg(AppState s, Map<String, dynamic> m) => s.setData('car_cfg', {..._cfg(s), ...m});
  List<Map<String, dynamic>> _cars(AppState s) => mapList(s.getData<List>('car_cars'));
  String _cur(AppState s) => (_cfg(s)['cur'] as String?) ?? t('جنيه', 'جنيه', 'SDG');

  Map<String, dynamic>? _sel(AppState s) {
    final cars = _cars(s);
    if (cars.isEmpty) return null;
    final id = _cfg(s)['sel'];
    return cars.firstWhere((c) => c['id'] == id, orElse: () => cars.first);
  }

  void _saveCar(AppState s, Map<String, dynamic> car) {
    final cars = _cars(s);
    final i = cars.indexWhere((c) => c['id'] == car['id']);
    if (i >= 0) {
      cars[i] = car;
    } else {
      cars.add(car);
    }
    s.setData('car_cars', cars);
    _reschedule(s);
    setState(() {});
  }

  Future<void> _reschedule(AppState s) async {
    final items = <(int, String, String?, DateTime, DateTimeComponents?)>[];
    if (_cfg(s)['notify'] != false) {
      final today = pToday();
      final dues = <(Due, String)>[];
      for (final car in _cars(s)) {
        for (final it in mapList(car['items'])) {
          final d = dueOf(it, intOf(car['odo']), today);
          if (d.dueDate != null && !d.dueDate!.isBefore(today)) dues.add((d, car['name'] as String? ?? ''));
        }
      }
      dues.sort((a, b) => a.$1.dueDate!.compareTo(b.$1.dueDate!));
      var idx = 0;
      for (final (d, carName) in dues) {
        // تنبيه قبل أسبوع + تنبيه يوم الموعد
        final week = d.dueDate!.subtract(const Duration(days: 7));
        final name = itemName(d.item);
        if (week.isAfter(today)) {
          items.add((idx++, '🚗 ${t('قرّب موعد', 'اقترب موعد', 'Coming up')}: $name', '$carName — ${fmtDateAr(d.dueDate!)}', DateTime(week.year, week.month, week.day, 9), null));
        }
        items.add((idx++, '🚗 ${t('الليلة موعد', 'اليوم موعد', 'Due today')}: $name', carName, DateTime(d.dueDate!.year, d.dueDate!.month, d.dueDate!.day, 9), null));
        if (idx >= carChannel.size - 2) break;
      }
    }
    await HpNotify.replace(s, carChannel, items);
  }

  Future<void> _addCar(AppState s, [Map<String, dynamic>? car]) async {
    final nC = TextEditingController(text: car?['name'] as String? ?? '');
    final kC = TextEditingController(text: car == null ? '' : '${car['odo'] ?? ''}');
    final ok = await lifeSheet<bool>(
      context,
      car == null ? t('ضيف عربية', 'إضافة سيارة', 'Add a car') : t('عدّل العربية', 'تعديل السيارة', 'Edit car'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HpTextField(t('الاسم', 'الاسم', 'Name'), nC, hint: t('مثلًا: الأتوس، البوكس', 'مثلًا: كورولا 2015', 'e.g. Corolla 2015')),
        NumField(t('العداد الحالي', 'قراءة العداد الحالية', 'Current odometer'), kC, suffix: t('كم', 'كم', 'km'), decimal: false),
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('احفظ', 'حفظ', 'Save'))),
        if (car != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, false),
            icon: const Icon(Icons.delete_outline_rounded, color: SD.red),
            label: Text(t('امسح العربية دي', 'حذف هذه السيارة', 'Delete this car'), style: const TextStyle(color: SD.red)),
          ),
        ],
      ]),
    );
    final name = nC.text.trim();
    final km = parseNum(kC.text).round();
    nC.dispose();
    kC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false && car != null) {
      final sure = await confirmAsk(context, t('تمسح ${car['name']}؟', 'حذف ${car['name']}؟', 'Delete ${car['name']}?'),
          t('حيتمسح كل سجل الصيانة بتاعها', 'سيُحذف سجل صيانتها بالكامل', 'Its whole service history will be deleted'));
      if (!sure) return;
      s.setData('car_cars', _cars(s)..removeWhere((c) => c['id'] == car['id']));
      _reschedule(s);
      setState(() {});
      return;
    }
    final today = dk(pToday());
    if (car == null) {
      final id = newId();
      _saveCar(s, {
        'id': id,
        'name': name.isEmpty ? t('عربيتي', 'سيارتي', 'My car') : name,
        'odo': km,
        'odoLog': [
          {'d': today, 'km': km}
        ],
        'items': [
          for (final d in _defaults) {'id': newId(), 'k': d.$1, 'km': d.$2, 'mo': d.$3},
        ],
        'hist': [],
      });
      _setCfg(s, {'sel': id});
      s.award(5, t('ضفت عربية', 'إضافة سيارة', 'Added a car'));
    } else {
      final c = Map<String, dynamic>.from(car)..['name'] = name.isEmpty ? car['name'] : name;
      if (km > 0 && km != intOf(car['odo'])) {
        c['odo'] = km;
        c['odoLog'] = [...mapList(car['odoLog']), {'d': today, 'km': km}];
      }
      _saveCar(s, c);
    }
  }

  Future<void> _logOdo(AppState s, Map<String, dynamic> car) async {
    final v = await askText(context, t('قراية العداد هسي', 'قراءة العداد الآن', 'Odometer now'), initial: '${car['odo'] ?? ''}', number: true);
    if (v == null || !mounted) return;
    final km = parseNum(v).round();
    if (km <= 0) return;
    if (km < intOf(car['odo'])) {
      toast(t('القراية أقل من الفاتت — اتأكد', 'القراءة أقل من السابقة — تحقّق', 'Reading is lower than the previous one — check it'));
      return;
    }
    final log = mapList(car['odoLog'])..add({'d': dk(pToday()), 'km': km});
    _saveCar(s, {...car, 'odo': km, 'odoLog': log.length > 200 ? log.sublist(log.length - 200) : log});
    s.awardDaily('car_odo', 3, t('سجّلت العداد', 'تسجيل العداد', 'Logged odometer'));
  }

  /// نافذة بند: تعديل الفترة أو تسجيل صيانة
  Future<void> _itemSheet(AppState s, Map<String, dynamic> car, Map<String, dynamic>? it) async {
    final isNew = it == null;
    final item = Map<String, dynamic>.from(it ?? {'id': newId(), 'k': 'custom'});
    final nC = TextEditingController(text: item['k'] == 'custom' ? (item['n'] as String? ?? '') : itemName(item));
    final kmC = TextEditingController(text: item['km'] == null ? '' : '${item['km']}');
    final moC = TextEditingController(text: item['mo'] == null ? '' : '${item['mo']}');
    final doneKm = TextEditingController(text: '${car['odo'] ?? ''}');
    final costC = TextEditingController();
    final noteC = TextEditingController();
    var date = pToday();
    final r = await lifeSheet<String>(
      context,
      isNew ? t('بند صيانة جديد', 'بند صيانة جديد', 'New service item') : itemName(item),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!isNew) ...[
          Text(t('سجّل إنك عملتها', 'تسجيل إجراء الصيانة', 'Record this service'), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          LifeDateButton(label: t('التاريخ', 'التاريخ', 'Date'), value: date, onPick: (d) => set(() => date = d ?? date), last: pToday()),
          const SizedBox(height: 10),
          NumField(t('العداد وقتها', 'العداد حينها', 'Odometer then'), doneKm, suffix: t('كم', 'كم', 'km'), decimal: false),
          NumField(t('التكلفة', 'التكلفة', 'Cost'), costC, suffix: _cur(s)),
          HpTextField(t('ملاحظة', 'ملاحظة', 'Note'), noteC, hint: t('الورشة، نوع الزيت…', 'الورشة، نوع الزيت…', 'Workshop, oil grade…')),
          FilledButton.icon(onPressed: () => Navigator.pop(ctx, 'done'), icon: const Icon(Icons.task_alt_rounded), label: Text(t('سجّل', 'تسجيل', 'Record'))),
          const Divider(height: 28),
        ],
        Text(t('الفترة', 'الفترة', 'Interval'), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (item['k'] == 'custom') HpTextField(t('اسم البند', 'اسم البند', 'Item name'), nC),
        Row(children: [
          Expanded(child: NumField(t('كل كم كيلو', 'كل (كم)', 'Every (km)'), kmC, decimal: false)),
          const SizedBox(width: 8),
          Expanded(child: NumField(t('أو كل كم شهر', 'أو كل (شهر)', 'or every (months)'), moC, decimal: false)),
        ]),
        OutlinedButton.icon(onPressed: () => Navigator.pop(ctx, 'save'), icon: const Icon(Icons.save_rounded), label: Text(t('احفظ الفترة', 'حفظ الفترة', 'Save interval'))),
        if (!isNew)
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, 'del'),
            icon: const Icon(Icons.delete_outline_rounded, color: SD.red),
            label: Text(t('امسح البند', 'حذف البند', 'Delete item'), style: const TextStyle(color: SD.red)),
          ),
      ]),
    );
    final ikm = parseNum(kmC.text).round(), imo = parseNum(moC.text).round();
    final km = parseNum(doneKm.text).round(), cost = parseNum(costC.text);
    final note = noteC.text.trim(), name = nC.text.trim();
    for (final c in [nC, kmC, moC, doneKm, costC, noteC]) {
      c.dispose();
    }
    if (r == null || !mounted) return;
    final items = mapList(car['items']);
    final i = items.indexWhere((x) => x['id'] == item['id']);
    if (r == 'del') {
      if (i >= 0) items.removeAt(i);
      _saveCar(s, {...car, 'items': items});
      return;
    }
    item['km'] = ikm > 0 ? ikm : null;
    item['mo'] = imo > 0 ? imo : null;
    if (item['k'] == 'custom') item['n'] = name.isEmpty ? t('بند', 'بند', 'Item') : name;
    final c = Map<String, dynamic>.from(car);
    if (r == 'done') {
      item['lastKm'] = km > 0 ? km : intOf(car['odo']);
      item['lastD'] = dk(date);
      c['hist'] = [
        ...mapList(car['hist']),
        {'id': newId(), 'd': dk(date), 'k': item['k'], 'n': itemName(item), 'km': item['lastKm'], 'cost': cost, if (note.isNotEmpty) 'note': note},
      ];
      if (km > intOf(car['odo'])) {
        c['odo'] = km;
        c['odoLog'] = [...mapList(car['odoLog']), {'d': dk(date), 'km': km}];
      }
      s.award(5, t('سجّلت صيانة', 'تسجيل صيانة', 'Logged a service'));
      s.bump('car_services');
    }
    if (i >= 0) {
      items[i] = item;
    } else {
      items.add(item);
    }
    c['items'] = items;
    _saveCar(s, c);
  }

  void _delHist(AppState s, Map<String, dynamic> car, Map h) {
    _saveCar(s, {...car, 'hist': mapList(car['hist'])..removeWhere((x) => x['id'] == h['id'])});
  }

  /// متوسط الكيلومترات اليومية من سجل العداد
  double? _kmPerDay(Map car) {
    final log = mapList(car['odoLog']);
    if (log.length < 2) return null;
    final a = parseDk(log.first['d']), b = parseDk(log.last['d']);
    if (a == null || b == null) return null;
    final days = dayDiff(a, b);
    if (days < 3) return null;
    final km = intOf(log.last['km']) - intOf(log.first['km']);
    return km <= 0 ? null : km / days;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cfg = _cfg(s);
    final cars = _cars(s);
    final car = _sel(s);
    final cur = _cur(s);
    final today = pToday();

    final carChips = Wrap(spacing: 8, runSpacing: 8, children: [
      for (final c in cars)
        PickChip(c['name'] as String? ?? '', c['id'] == car?['id'], () {
          _setCfg(s, {'sel': c['id']});
          setState(() {});
        }, color: SD.nile),
      ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('عربية', 'سيارة', 'Car')), onPressed: () => _addCar(s)),
    ]);

    if (car == null) {
      return ToolList(children: [
        ResultHero(
          label: t('صيانة العربية', 'صيانة السيارة', 'Car maintenance'),
          value: '🚗',
          sub: t('ضيف عربيتك عشان نتابع ليك الزيت والفلاتر والترخيص', 'أضف سيارتك لمتابعة الزيت والفلاتر والترخيص', 'Add your car to track oil, filters and licence'),
          colors: const [Color(0xFF0B5C8A), Color(0xFF3B2F8F), Color(0xFF3A1F0C)],
        ),
        FilledButton.icon(onPressed: () => _addCar(s), icon: const Icon(Icons.add_rounded), label: Text(t('ضيف عربية', 'إضافة سيارة', 'Add a car'))),
        const SizedBox(height: 12),
        NoteBox(t('الفترات الافتراضية عامة (زيت كل 5000 كم أو 6 شهور…). راجع كتيّب عربيتك وعدّلها.', 'الفترات الافتراضية عامة (زيت كل 5000 كم أو 6 أشهر…). راجع دليل سيارتك وعدّلها.',
            'Default intervals are generic (oil every 5,000 km or 6 months…). Check your owner\'s manual and adjust.')),
      ]);
    }

    final odo = intOf(car['odo']);
    final dues = [for (final it in mapList(car['items'])) dueOf(it, odo, today)];
    dues.sort((a, b) {
      if (a.unknown != b.unknown) return a.unknown ? 1 : -1;
      return b.frac.compareTo(a.frac);
    });
    final overdue = dues.where((d) => d.overdue).length;
    final soon = dues.where((d) => d.soon).length;
    final hist = mapList(car['hist'])..sort((a, b) => (b['d'] as String? ?? '').compareTo(a['d'] as String? ?? ''));
    final total = hist.fold<double>(0, (a, h) => a + numOf(h['cost']));
    final yearTotal = hist.where((h) => (h['d'] as String? ?? '').startsWith('${today.year}-')).fold<double>(0, (a, h) => a + numOf(h['cost']));
    final kmDay = _kmPerDay(car);
    final byItem = <String, double>{};
    for (final h in hist) {
      final n = h['k'] == 'custom' ? (h['n'] as String? ?? '') : itemName(h);
      byItem[n] = (byItem[n] ?? 0) + numOf(h['cost']);
    }
    final topItems = byItem.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));

    String summary() => [
          '🚗 ${car['name']} — ${fmt(odo, 0)} ${t('كم', 'كم', 'km')}',
          for (final d in dues.where((d) => !d.unknown))
            '• ${itemName(d.item)}: ${[
              if (d.kmLeft != null) '${fmt(d.kmLeft, 0)} ${t('كم', 'كم', 'km')}',
              if (d.daysLeft != null) daysLabel(d.daysLeft!) + (d.daysLeft! < 0 ? ' ${t('متأخر', 'متأخر', 'late')}' : ''),
            ].join(' / ')}',
          '${t('مجموع الصيانة', 'إجمالي الصيانة', 'Total maintenance')}: ${fmt(total, 0)} $cur',
        ].join('\n');

    return ToolList(children: [
      carChips,
      const SizedBox(height: 12),
      ResultHero(
        label: car['name'] as String? ?? '',
        value: '${fmt(odo, 0)} ${t('كم', 'كم', 'km')}',
        sub: overdue > 0
            ? '⚠️ ${t('في $overdue بند فات وقتو', 'يوجد $overdue بند متأخر', '$overdue item(s) overdue')}'
            : (soon > 0 ? t('في $soon بند قرّب', 'يوجد $soon بند قريب', '$soon item(s) due soon') : t('كلو تمام ✓', 'كل شيء على ما يرام ✓', 'All good ✓')),
        colors: overdue > 0 ? const [Color(0xFFD21034), Color(0xFF5A3418), Color(0xFF3A1F0C)] : const [Color(0xFF0B5C8A), Color(0xFF3B2F8F), Color(0xFF3A1F0C)],
      ),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _logOdo(s, car),
            icon: const Icon(Icons.speed_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('سجّل العداد', 'سجّل العداد', 'Log odometer'), maxLines: 1)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addCar(s, car),
            icon: const Icon(Icons.edit_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('عدّل', 'تعديل', 'Edit car'), maxLines: 1)),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      StatGrid([
        StatChip('$overdue', t('متأخرة', 'متأخرة', 'overdue'), color: SD.red, icon: Icons.error_outline_rounded),
        StatChip('$soon', t('قرّبت', 'قريبة', 'due soon'), color: SD.orange, icon: Icons.schedule_rounded),
        StatChip(kmDay == null ? '—' : fmt(kmDay, 0), t('كم في اليوم', 'كم يوميًا', 'km / day'), color: SD.nile, icon: Icons.route_rounded),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('المواعيد', 'المواعيد', 'What\'s due'),
        icon: Icons.build_circle_rounded,
        color: SD.nile,
        trailing: IconButton(tooltip: t('ضيف بند', 'إضافة بند', 'Add item'), onPressed: () => _itemSheet(s, car, null), icon: const Icon(Icons.add_rounded)),
        child: Column(children: [
          for (final d in dues) _DueTile(d, kmDay, today, () => _itemSheet(s, car, d.item)),
        ]),
      ),
      SCard(
        title: t('سجل الصيانة', 'سجل الصيانة', 'Service history'),
        icon: Icons.receipt_long_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InfoRow(t('المجموع', 'الإجمالي', 'Total'), '${fmt(total, 0)} $cur'),
          InfoRow(t('السنة دي', 'هذه السنة', 'This year'), '${fmt(yearTotal, 0)} $cur'),
          if (odo > 0 && total > 0 && mapList(car['odoLog']).isNotEmpty)
            InfoRow(t('تكلفة الكيلو', 'تكلفة الكيلومتر', 'Cost per km'),
                () {
                  final startKm = intOf(mapList(car['odoLog']).first['km']);
                  final driven = odo - startKm;
                  return driven > 0 ? '${fmt(total / driven, 2)} $cur' : '—';
                }()),
          for (final e in topItems.take(4)) InfoRow('  • ${e.key}', '${fmt(e.value, 0)} $cur'),
          const SizedBox(height: 6),
          if (hist.isEmpty)
            EmptyHint(Icons.handyman_outlined, t('دوس على أي بند وسجّل إنك عملتو', 'اضغط على أي بند لتسجيل إجرائه', 'Tap any item to record a service'))
          else
            for (final h in hist.take(50))
              HpLogTile(
                icon: itemIcon(h),
                color: SD.gold,
                title: h['k'] == 'custom' ? (h['n'] as String? ?? '') : itemName(h),
                sub: [fmtDateAr(parseDk(h['d']) ?? today, weekday: false), if (h['km'] != null) '${fmt(numOf(h['km']), 0)} ${t('كم', 'كم', 'km')}', if (h['note'] != null) h['note']].join(' · '),
                value: numOf(h['cost']) > 0 ? '${fmt(numOf(h['cost']), 0)} $cur' : null,
                onDelete: () => _delHist(s, car, h),
              ),
        ]),
      ),
      SCard(
        title: t('الضبط', 'الإعدادات', 'Settings'),
        icon: Icons.tune_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _CurField(cur, (v) => _setCfg(s, {'cur': v})),
          HpSwitch(
            t('نبّهني بالمواعيد', 'نبّهني بالمواعيد', 'Remind me of due dates'),
            cfg['notify'] != false,
            (v) async {
              _setCfg(s, {'notify': v});
              if (v && HpNotify.supported) await HpNotify.requestPermission();
              await _reschedule(s);
              if (mounted) setState(() {});
            },
            sub: t('للبنود اللي ليها تاريخ (ترخيص، تأمين…) — قبل أسبوع ويوم الموعد', 'للبنود المؤقتة بتاريخ (ترخيص، تأمين…) — قبل أسبوع ويوم الموعد',
                'For date-based items (licence, insurance…) — a week before and on the day'),
          ),
        ]),
      ),
      NoteBox(t('الفترات تقريبية. في الحر والتراب (زي السودان) الأحسن تقصّر فترة الزيت وفلتر الهوا. راجع كتيّب العربية.',
          'الفترات تقريبية؛ في الحر الشديد والغبار يُفضَّل تقصير فترة الزيت وفلتر الهواء. راجع دليل السيارة.',
          'Intervals are approximate. In heat and dust, shorten oil and air-filter intervals. Follow your owner\'s manual.')),
      ShareBar(summary),
    ]);
  }
}

class _CurField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CurField(this.value, this.onChanged);
  @override
  State<_CurField> createState() => _CurFieldState();
}

class _CurFieldState extends State<_CurField> {
  late final TextEditingController c = TextEditingController(text: widget.value);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HpTextField(t('العملة', 'العملة', 'Currency'), c, onChanged: (v) => widget.onChanged(v.trim()));
}

class _DueTile extends StatelessWidget {
  final Due d;
  final double? kmDay;
  final DateTime today;
  final VoidCallback onTap;
  const _DueTile(this.d, this.kmDay, this.today, this.onTap);

  @override
  Widget build(BuildContext context) {
    final color = d.unknown ? SD.nile : (d.overdue ? SD.red : (d.soon ? SD.orange : SD.green));
    final parts = <String>[];
    if (d.unknown) {
      parts.add(t('دوس وسجّل آخر مرة عملتها', 'اضغط لتسجيل آخر مرة', 'Tap to record the last time'));
    } else {
      if (d.kmLeft != null) {
        final k = d.kmLeft!;
        var p = k <= 0 ? '${t('فات بـ', 'متأخر', 'over by')} ${fmt(-k, 0)} ${t('كم', 'كم', 'km')}' : '${t('فاضل', 'متبقٍ', 'left')} ${fmt(k, 0)} ${t('كم', 'كم', 'km')}';
        if (k > 0 && kmDay != null && kmDay! > 0) p += ' (≈ ${fmtShort(today.add(Duration(days: (k / kmDay!).round())))})';
        parts.add(p);
      }
      if (d.daysLeft != null) {
        final n = d.daysLeft!;
        parts.add(n < 0 ? '${t('متأخر', 'متأخر', 'late by')} ${daysLabel(n)}' : '${daysLabel(n)} — ${fmtShort(d.dueDate!)}');
      }
    }
    final iv = [
      if (d.item['km'] != null) '${fmt(numOf(d.item['km']), 0)} ${t('كم', 'كم', 'km')}',
      if (d.item['mo'] != null) '${d.item['mo']} ${t('شهر', 'شهر', 'mo')}',
    ].join(' / ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: .18), child: Icon(itemIcon(d.item), size: 19, color: readable(context, color))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(itemName(d.item), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                if (iv.isNotEmpty)
                  Flexible(child: Text(iv, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(fontSize: 11))),
              ]),
              const SizedBox(height: 4),
              if (!d.unknown) HpBar(d.frac, color: color, height: 7),
              const SizedBox(height: 3),
              Text(parts.join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: readable(context, color), fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}
