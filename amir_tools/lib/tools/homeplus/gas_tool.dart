import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/home_widgets.dart';
import 'hp_common.dart';
import 'hp_notify.dart';

final gasChannel = HpChannel('gas', () => t('أنبوبة الغاز', 'أسطوانة الغاز', 'Gas cylinder'),
    () => t('تذكير قبل ما الغاز يكمل', 'تذكير قبل نفاد الغاز', 'Reminder before the gas runs out'), 7300, 50);

/// حسابات الغاز (منفصلة عن الواجهة لتسهيل الاختبار)
class GasStats {
  final List<Map<String, dynamic>> refills; // مرتبة تصاعديًا بالتاريخ
  final double defaultDays;
  GasStats(this.refills, this.defaultDays);

  List<int> get intervals {
    final r = <int>[];
    for (var i = 1; i < refills.length; i++) {
      final a = parseDk(refills[i - 1]['d']), b = parseDk(refills[i]['d']);
      if (a != null && b != null && dayDiff(a, b) > 0) r.add(dayDiff(a, b));
    }
    return r;
  }

  /// متوسط أيام الأنبوبة (آخر 6 فترات)، أو القيمة الافتراضية
  double get avgDays {
    final iv = intervals;
    if (iv.isEmpty) return defaultDays;
    final last = iv.length > 6 ? iv.sublist(iv.length - 6) : iv;
    return last.reduce((a, b) => a + b) / last.length;
  }

  bool get estimated => intervals.isEmpty;
  DateTime? get last => refills.isEmpty ? null : parseDk(refills.last['d']);
  DateTime? get runOut => last?.add(Duration(days: avgDays.round()));

  double get avgPrice {
    final ps = refills.map((e) => numOf(e['p'])).where((p) => p > 0).toList();
    if (ps.isEmpty) return 0;
    final l = ps.length > 3 ? ps.sublist(ps.length - 3) : ps;
    return l.reduce((a, b) => a + b) / l.length;
  }

  double get monthlyCost => avgDays <= 0 ? 0 : avgPrice * 30.44 / avgDays;
}

class GasTool extends StatefulWidget {
  const GasTool({super.key});
  @override
  State<GasTool> createState() => _GasToolState();
}

class _GasToolState extends State<GasTool> {
  late final TextEditingController curC;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    curC = TextEditingController(text: (_cfg(s)['cur'] as String?) ?? t('جنيه', 'جنيه', 'SDG'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cfg(s)['notify'] == true) _reschedule(s);
    });
  }

  @override
  void dispose() {
    curC.dispose();
    super.dispose();
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('gas_cfg') ?? {});
  void _setCfg(AppState s, Map<String, dynamic> m) {
    s.setData('gas_cfg', {..._cfg(s), ...m});
    HomeWidgets.refreshGas(s);
  }

  List<Map<String, dynamic>> _list(AppState s) {
    final l = mapList(s.getData<List>('gas_list'));
    l.sort((a, b) => (a['d'] as String? ?? '').compareTo(b['d'] as String? ?? ''));
    return l;
  }

  GasStats _stats(AppState s) => GasStats(_list(s), numOf(_cfg(s)['def'], 30));

  Future<void> _reschedule(AppState s) async {
    final cfg = _cfg(s);
    final st = _stats(s);
    final out = st.runOut;
    final items = <(int, String, String?, DateTime, DateTimeComponents?)>[];
    if (cfg['notify'] == true && out != null) {
      final before = intOf(cfg['before'], 3);
      final at = out.subtract(Duration(days: before));
      items.add((
        0,
        '🔥 ${t('الغاز قرّب يكمل', 'الغاز يوشك على النفاد', 'Gas running low')}',
        t('حسب حسابك الأنبوبة بتكمل حوالي ${fmtDateAr(out)} — جهّز البديلة', 'حسب سجلك ستنفد الأسطوانة نحو ${fmtDateAr(out)} — جهّز البديلة',
            'By your history the cylinder runs out around ${fmtDateAr(out)} — get a refill ready'),
        DateTime(at.year, at.month, at.day, 10),
        null,
      ));
      items.add((
        1,
        '🔥 ${t('يوم نهاية الغاز المتوقع', 'يوم نفاد الغاز المتوقع', 'Expected gas run-out day')}',
        t('الليلة متوقع الأنبوبة تكمل', 'اليوم يُتوقع نفاد الأسطوانة', 'Today the cylinder is expected to run out'),
        DateTime(out.year, out.month, out.day, 9),
        null,
      ));
    }
    await HpNotify.replace(s, gasChannel, items);
  }

  Future<void> _edit(AppState s, [Map<String, dynamic>? e]) async {
    var date = parseDk(e?['d']) ?? pToday();
    final pC = TextEditingController(text: e == null ? (_list(s).isEmpty ? '' : fmt(numOf(_list(s).last['p']), 2).replaceAll(',', '')) : fmt(numOf(e['p']), 2).replaceAll(',', ''));
    final kC = TextEditingController(text: e?['kg'] == null ? ((_cfg(s)['kg'] as num?)?.toString() ?? '') : '${e!['kg']}');
    final ok = await lifeSheet<bool>(
      context,
      e == null ? t('عبّيت أنبوبة جديدة', 'تعبئة أسطوانة جديدة', 'New refill') : t('عدّل التعبئة', 'تعديل التعبئة', 'Edit refill'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LifeDateButton(label: t('تاريخ التعبئة', 'تاريخ التعبئة', 'Refill date'), value: date, onPick: (d) => set(() => date = d ?? date), last: pToday()),
        const SizedBox(height: 12),
        NumField(t('السعر', 'السعر', 'Price'), pC, suffix: curC.text),
        NumField(t('الحجم (اختياري)', 'الحجم (اختياري)', 'Size (optional)'), kC, suffix: t('كيلو', 'كغ', 'kg'), hint: '12.5'),
        const SizedBox(height: 6),
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('احفظ', 'حفظ', 'Save'))),
      ]),
    );
    final price = parseNum(pC.text), kg = parseNum(kC.text);
    pC.dispose();
    kC.dispose();
    if (ok != true || !mounted) return;
    final list = mapList(s.getData<List>('gas_list'));
    final m = {'id': e?['id'] ?? newId(), 'd': dk(date), 'p': price, if (kg > 0) 'kg': kg};
    final i = list.indexWhere((x) => x['id'] == m['id']);
    if (i >= 0) {
      list[i] = m;
    } else {
      list.add(m);
      s.award(5, t('سجّلت تعبئة غاز', 'تسجيل تعبئة غاز', 'Logged a gas refill'));
      s.bump('gas_refills');
    }
    if (kg > 0) _setCfg(s, {'kg': kg});
    s.setData('gas_list', list);
    HomeWidgets.refreshGas(s);
    _reschedule(s);
    setState(() {});
  }

  void _delete(AppState s, Map<String, dynamic> e) {
    final list = mapList(s.getData<List>('gas_list'));
    final i = list.indexWhere((x) => x['id'] == e['id']);
    if (i < 0) return;
    final removed = list.removeAt(i);
    s.setData('gas_list', list);
    HomeWidgets.refreshGas(s);
    _reschedule(s);
    setState(() {});
    undoSnack(t('اتمسحت التعبئة', 'حُذفت التعبئة', 'Refill deleted'), () {
      final l = mapList(s.getData<List>('gas_list'))..insert(i.clamp(0, list.length), removed);
      s.setData('gas_list', l);
      HomeWidgets.refreshGas(s);
      _reschedule(s);
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cfg = _cfg(s);
    final list = _list(s);
    final st = _stats(s);
    final cur = curC.text.trim();
    final today = pToday();
    final out = st.runOut;
    final left = out == null ? null : dayDiff(today, out);
    final used = st.last == null ? 0 : dayDiff(st.last!, today);
    final frac = st.avgDays <= 0 ? 0.0 : 1 - used / st.avgDays;
    final color = left == null ? SD.green : (left < 0 ? SD.red : (left <= 5 ? SD.orange : SD.green));
    final iv = st.intervals;
    final prices = list.map((e) => numOf(e['p'])).where((p) => p > 0).toList();
    final yearCost = list.where((e) => (e['d'] as String? ?? '').startsWith('${today.year}-')).fold<double>(0, (a, e) => a + numOf(e['p']));
    final kgs = list.map((e) => numOf(e['kg'])).where((k) => k > 0).toList();
    final kgPerDay = kgs.isEmpty || st.avgDays <= 0 ? null : (kgs.last / st.avgDays);

    String summary() => [
          '🔥 ${t('أنبوبة الغاز', 'أسطوانة الغاز', 'Gas cylinder')}',
          if (st.last != null) '${t('آخر تعبئة', 'آخر تعبئة', 'Last refill')}: ${fmtDateAr(st.last!)}',
          '${t('متوسط عمر الأنبوبة', 'متوسط عمر الأسطوانة', 'Average cylinder life')}: ${fmt(st.avgDays, 1)} ${t('يوم', 'يوم', 'days')}',
          if (out != null) '${t('النهاية المتوقعة', 'النفاد المتوقع', 'Expected run-out')}: ${fmtDateAr(out)}',
          if (st.avgPrice > 0) '${t('التكلفة الشهرية', 'التكلفة الشهرية', 'Monthly cost')}: ${fmt(st.monthlyCost, 0)} $cur',
          '${t('عدد التعبئات', 'عدد التعبئات', 'Refills')}: ${list.length}',
        ].join('\n');

    return ToolList(children: [
      ResultHero(
        label: t('الغاز فاضل ليهو', 'المتبقي من الغاز', 'Gas left (estimate)'),
        value: left == null ? '—' : (left < 0 ? t('كمّل!', 'نفد!', 'Empty!') : daysLabel(left)),
        sub: out == null
            ? t('سجّل أول تعبئة عشان نحسب ليك', 'سجّل أول تعبئة لنبدأ الحساب', 'Log your first refill to start')
            : '${t('متوقع يكمل', 'يُتوقع النفاد', 'Expected to run out')}: ${fmtDateAr(out)}${st.estimated ? ' (${t('تقدير مبدئي', 'تقدير مبدئي', 'rough estimate')})' : ''}',
        colors: const [Color(0xFFE2702B), Color(0xFFB4492D), Color(0xFF3A1F0C)],
      ),
      if (out != null)
        SCard(
          title: t('الأنبوبة الحالية', 'الأسطوانة الحالية', 'Current cylinder'),
          icon: Icons.propane_tank_rounded,
          color: SD.orange,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            HpBar(frac, color: color, left: t('المتبقي التقريبي', 'المتبقي التقريبي', 'Approx. remaining'), right: '${fmt((frac.clamp(0, 1) * 100), 0)}%'),
            const SizedBox(height: 10),
            InfoRow(t('ليها كم يوم شغالة', 'أيام الاستخدام', 'Days in use'), daysLabel(used)),
            InfoRow(t('فاضل', 'المتبقي', 'Days left'), left! < 0 ? '${t('متأخرة', 'متجاوز', 'Overdue')} ${daysLabel(left)}' : daysLabel(left),
                valueColor: color),
            if (kgPerDay != null) InfoRow(t('الاستهلاك اليومي', 'الاستهلاك اليومي', 'Daily usage'), '${fmt(kgPerDay, 2)} ${t('كيلو', 'كغ', 'kg')}'),
          ]),
        ),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _edit(s),
            icon: const Icon(Icons.add_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('عبّيت أنبوبة', 'سجّل تعبئة', 'Log a refill'), maxLines: 1)),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      StatGrid([
        StatChip(fmt(st.avgDays, 1), t('يوم متوسط الأنبوبة', 'يوم متوسط الأسطوانة', 'avg days / cylinder'), color: SD.orange, icon: Icons.timelapse_rounded),
        StatChip(st.avgPrice > 0 ? fmt(st.monthlyCost, 0) : '—', '${t('تكلفة الشهر', 'التكلفة الشهرية', 'per month')} ($cur)', color: SD.gold, icon: Icons.payments_rounded),
        StatChip('${list.length}', t('تعبئات مسجلة', 'تعبئات مسجلة', 'refills logged'), color: SD.nile, icon: Icons.history_rounded),
        StatChip(fmt(yearCost, 0), '${t('صرفت السنة دي', 'إنفاق هذه السنة', 'spent this year')} ($cur)', color: SD.henna, icon: Icons.calendar_today_rounded),
        StatChip(iv.isEmpty ? '—' : '${iv.reduce((a, b) => a < b ? a : b)}', t('أقصر فترة (يوم)', 'أقصر مدة (يوم)', 'shortest (days)'), color: SD.red),
        StatChip(iv.isEmpty ? '—' : '${iv.reduce((a, b) => a > b ? a : b)}', t('أطول فترة (يوم)', 'أطول مدة (يوم)', 'longest (days)'), color: SD.green),
      ]),
      const SizedBox(height: 14),
      if (prices.length >= 2)
        SCard(
          title: t('اتجاه السعر', 'اتجاه السعر', 'Price trend'),
          icon: Icons.trending_up_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            HpMiniBars([
              for (final e in list.where((e) => numOf(e['p']) > 0).toList().reversed.take(8).toList().reversed)
                (fmtShort(parseDk(e['d']) ?? today), numOf(e['p'])),
            ]),
            const SizedBox(height: 8),
            InfoRow(t('أول سعر مسجّل', 'أول سعر مسجل', 'First price'), '${fmt(prices.first, 2)} $cur'),
            InfoRow(t('آخر سعر', 'آخر سعر', 'Latest price'), '${fmt(prices.last, 2)} $cur'),
            InfoRow(
              t('التغيّر', 'نسبة التغير', 'Change'),
              prices.first <= 0 ? '—' : '${prices.last >= prices.first ? '+' : ''}${fmt((prices.last - prices.first) * 100 / prices.first, 1)}%',
              valueColor: prices.last > prices.first ? SD.red : SD.green,
            ),
          ]),
        ),
      SCard(
        title: t('السجل', 'سجل التعبئات', 'Refill history'),
        icon: Icons.history_rounded,
        color: SD.nile,
        child: list.isEmpty
            ? EmptyHint(Icons.propane_tank_outlined, t('لسه ما سجلت ولا تعبئة', 'لم تُسجَّل أي تعبئة بعد', 'No refills logged yet'))
            : Column(children: [
                for (var i = list.length - 1; i >= 0; i--)
                  HpLogTile(
                    icon: Icons.propane_tank_rounded,
                    color: SD.orange,
                    title: fmtDateAr(parseDk(list[i]['d']) ?? today),
                    sub: [
                      if (i > 0 && parseDk(list[i - 1]['d']) != null && parseDk(list[i]['d']) != null)
                        '${t('قعدت', 'استمرت السابقة', 'previous lasted')} ${daysLabel(dayDiff(parseDk(list[i - 1]['d'])!, parseDk(list[i]['d'])!))}',
                      if (list[i]['kg'] != null) '${fmt(numOf(list[i]['kg']), 1)} ${t('كيلو', 'كغ', 'kg')}',
                    ].join(' · '),
                    value: numOf(list[i]['p']) > 0 ? '${fmt(numOf(list[i]['p']), 0)} $cur' : null,
                    onTap: () => _edit(s, list[i]),
                    onDelete: () => _delete(s, list[i]),
                  ),
              ]),
      ),
      SCard(
        title: t('الضبط والتذكير', 'الإعدادات والتذكير', 'Settings & reminder'),
        icon: Icons.tune_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HpTextField(t('العملة', 'العملة', 'Currency'), curC, onChanged: (v) {
            _setCfg(s, {'cur': v.trim()});
            setState(() {});
          }),
          HpStepper(
            label: t('عمر الأنبوبة المبدئي (قبل ما يتجمع سجل)', 'العمر المبدئي للأسطوانة (قبل تكوّن سجل)', 'Initial cylinder life (until history builds)'),
            value: numOf(cfg['def'], 30).round(),
            unit: t('يوم', 'يوم', 'days'),
            min: 5,
            max: 120,
            onChanged: (v) {
              _setCfg(s, {'def': v});
              _reschedule(s);
              setState(() {});
            },
          ),
          HpSwitch(
            t('ذكّرني قبل ما يكمل', 'ذكّرني قبل النفاد', 'Remind me before it runs out'),
            cfg['notify'] == true,
            (v) async {
              _setCfg(s, {'notify': v});
              if (v && HpNotify.supported) {
                final ok = await HpNotify.requestPermission();
                if (!ok) toast(t('فعّل الإشعارات من ضبط التلفون', 'فعّل الإشعارات من إعدادات الهاتف', 'Enable notifications in phone settings'));
              }
              await _reschedule(s);
              if (mounted) setState(() {});
            },
            sub: t('تنبيه الساعة 10 الصباح', 'تنبيه الساعة 10 صباحًا', 'Alert at 10 AM'),
          ),
          if (cfg['notify'] == true)
            HpStepper(
              label: t('قبل النهاية بـ', 'قبل النفاد بـ', 'Days before run-out'),
              value: intOf(cfg['before'], 3),
              unit: t('يوم', 'يوم', 'days'),
              min: 1,
              max: 14,
              onChanged: (v) {
                _setCfg(s, {'before': v});
                _reschedule(s);
                setState(() {});
              },
            ),
        ]),
      ),
      NoteBox(
        t('الحساب تقديري من متوسط المدة بين تعبئاتك. كل ما تسجّل أكتر يبقى أدق. لو شميت ريحة غاز: اقفل المحبس وافتح الشبابيك وما تولّع أي حاجة.',
            'الحساب تقديري من متوسط المدة بين تعبئاتك، ويزداد دقة كلما سجلت أكثر. عند شم رائحة غاز: أغلق الصمام وافتح النوافذ ولا تشعل أي شيء.',
            'This is an estimate based on the average time between your refills — more records make it more accurate. If you smell gas: close the valve, open windows and do not switch anything on.'),
        kind: NoteKind.warn,
      ),
      ShareBar(summary),
    ]);
  }
}
