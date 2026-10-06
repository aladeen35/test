import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import '../money/money_common.dart' show CurrencyPicker, PercentBar, curSym;
import 'bills_notify.dart';
import 'home_common.dart';

class _BCat {
  final String key, emoji, sd, ar, en;
  final Color color;
  const _BCat(this.key, this.emoji, this.sd, this.ar, this.en, this.color);
  String get name => t(sd, ar, en);
}

const _bcats = [
  _BCat('power', '💡', 'كهرباء', 'كهرباء', 'Electricity', SD.gold),
  _BCat('water', '🚰', 'موية', 'مياه', 'Water', SD.nileLight),
  _BCat('net', '🌐', 'نت', 'إنترنت', 'Internet', SD.purple),
  _BCat('rent', '🔑', 'إيجار', 'إيجار', 'Rent', SD.indigo),
  _BCat('school', '📚', 'رسوم مدارس', 'رسوم دراسية', 'School fees', SD.teal),
  _BCat('phone', '📱', 'رصيد/تلفون', 'هاتف', 'Phone', SD.nile),
  _BCat('subs', '📺', 'اشتراكات', 'اشتراكات', 'Subscriptions', SD.pink),
  _BCat('gas', '🔥', 'غاز', 'غاز', 'Gas', SD.orange),
  _BCat('other', '🧾', 'تانية', 'أخرى', 'Other', SD.brownLight),
];

_BCat _bcat(String? k) => _bcats.firstWhere((c) => c.key == k, orElse: () => _bcats.last);

class BillsTool extends StatefulWidget {
  const BillsTool({super.key});
  @override
  State<BillsTool> createState() => _BillsToolState();
}

class _BillsToolState extends State<BillsTool> {
  @override
  void initState() {
    super.initState();
    // إعادة تسليح التنبيهات عند كل فتح (للشهر الجاي وما بعده)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (_bills(s).any((b) => b['notify'] != false)) BillNotifications.reschedule(s);
    });
  }

  List<Map<String, dynamic>> _bills(AppState s) => mapList(s.getData<List>('bills_list'));
  List<Map<String, dynamic>> _pays(AppState s) => mapList(s.getData<List>('bills_paid'));
  String _main(AppState s) => (s.getData<Map>('bills_cfg')?['main'] as String?) ?? 'SDG';

  double _conv(AppState s, double a, String cur, String main) => cur == main ? a : a * s.rate(cur, main);

  void _saveBills(AppState s, List<Map<String, dynamic>> l) {
    s.setData('bills_list', l);
    BillNotifications.reschedule(s);
  }

  void _savePays(AppState s, List<Map<String, dynamic>> l) {
    s.setData('bills_paid', l);
    BillNotifications.reschedule(s);
  }

  Future<void> _edit([Map<String, dynamic>? b]) async {
    final s = context.read<AppState>();
    final nameC = TextEditingController(text: b?['name'] ?? '');
    final aC = TextEditingController(text: b == null ? '' : fmt(numOf(b['a']), 2).replaceAll(',', ''));
    final dayC = TextEditingController(text: '${intOf(b?['day'], 1)}');
    final remC = TextEditingController(text: '${intOf(b?['remind'], 3)}');
    var cat = (b?['cat'] as String?) ?? 'power';
    var cur = (b?['cur'] as String?) ?? _main(s);
    var freq = (b?['freq'] as String?) ?? 'm';
    var month = intOf(b?['month'], todayPlace().month);
    var notify = b?['notify'] != false;
    final ok = await lifeSheet<bool>(
      context,
      b == null ? t('فاتورة جديدة', 'فاتورة جديدة', 'New bill') : t('عدّل الفاتورة', 'تعديل الفاتورة', 'Edit bill'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in _bcats)
            PickChip('${c.emoji} ${c.name}', cat == c.key, () {
              set(() {
                if (nameC.text.trim().isEmpty || _bcats.any((x) => x.name == nameC.text.trim())) nameC.text = c.name;
                cat = c.key;
              });
            }, color: c.color),
        ]),
        const SizedBox(height: 12),
        TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم الفاتورة', 'اسم الفاتورة', 'Bill name'))),
        const SizedBox(height: 10),
        NumField(t('المبلغ المعتاد', 'المبلغ المعتاد', 'Usual amount'), aC, suffix: curSym(cur)),
        CurrencyPicker(t('العملة', 'العملة', 'Currency'), cur, (v) => set(() => cur = v)),
        const SizedBox(height: 12),
        HSeg<String>(freq, [('m', t('كل شهر', 'شهرية', 'Monthly')), ('y', t('كل سنة', 'سنوية', 'Yearly'))], (v) => set(() => freq = v)),
        if (freq == 'y')
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DropdownButtonFormField<int>(
              initialValue: month,
              isExpanded: true,
              decoration: InputDecoration(labelText: t('شهر الاستحقاق', 'شهر الاستحقاق', 'Due month')),
              items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(monthsAr[i - 1], overflow: TextOverflow.ellipsis))],
              onChanged: (v) => set(() => month = v ?? month),
            ),
          ),
        Pair(
          NumField(t('يوم الاستحقاق', 'يوم الاستحقاق', 'Due day'), dayC, decimal: false, hint: '1–31'),
          NumField(t('ذكّرني قبل', 'التذكير قبل', 'Remind before'), remC, decimal: false, suffix: t('يوم', 'يوم', 'days')),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: notify,
          onChanged: (v) => set(() => notify = v),
          title: Text(t('نبّهني', 'تفعيل التنبيه', 'Remind me')),
          subtitle: Text(t('قبل الموعد وفي يومه الساعة 9 الصباح', 'قبل الموعد ويوم الاستحقاق الساعة 9 صباحًا', 'Before and on the due day at 9 AM'), style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 8),
        Row(children: [
          if (b != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          if (b != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم الفاتورة', 'اكتب اسم الفاتورة', 'Enter the bill name'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
      ]),
    );
    final data = {
      'name': nameC.text.trim(),
      'a': parseNum(aC.text),
      'cur': cur,
      'cat': cat,
      'freq': freq,
      'month': month,
      'day': parseNum(dayC.text, 1).round().clamp(1, 31),
      'remind': parseNum(remC.text, 3).round().clamp(0, 60),
      'notify': notify,
    };
    nameC.dispose();
    aC.dispose();
    dayC.dispose();
    remC.dispose();
    if (!mounted || ok == null) return;
    final l = _bills(s);
    if (ok == false && b != null) {
      if (!await confirmAsk(context, t('تمسح الفاتورة؟', 'حذف الفاتورة؟', 'Delete bill?'), '${b['name']}')) return;
      l.removeWhere((x) => x['id'] == b['id']);
      _saveBills(s, l);
      return;
    }
    if (b == null) {
      l.add({'id': newId(), ...data});
      s.awardDaily('bills_add', 3, tr('إضافة فاتورة', 'Added a bill'));
      if (notify && BillNotifications.supported) BillNotifications.requestPermission();
    } else {
      final i = l.indexWhere((x) => x['id'] == b['id']);
      if (i >= 0) l[i] = {...l[i], ...data};
    }
    _saveBills(s, l);
  }

  Future<void> _markPaid(AppState s, Map<String, dynamic> b, DateTime due) async {
    final period = BillDue.period(b, due);
    final pays = _pays(s);
    if (BillDue.isPaid(b, period, pays)) {
      pays.removeWhere((p) => p['bill'] == b['id'] && p['period'] == period);
      _savePays(s, pays);
      toast(t('رجّعناها ما مدفوعة', 'أُلغي تسجيل الدفع', 'Marked as unpaid'));
      return;
    }
    final v = await askText(context, '${t('دفعت', 'المبلغ المدفوع', 'Amount paid')} — ${b['name']} (${curSym(b['cur'] ?? 'SDG')})',
        initial: numOf(b['a']) > 0 ? fmt(numOf(b['a']), 2).replaceAll(',', '') : '', number: true);
    if (v == null || !mounted) return;
    pays.add({
      'id': newId(),
      'bill': b['id'],
      'name': b['name'],
      'cat': b['cat'],
      'period': period,
      'a': parseNum(v, numOf(b['a'])),
      'cur': b['cur'] ?? 'SDG',
      'd': dk(todayPlace()),
    });
    _savePays(s, pays);
    HapticFeedback.selectionClick();
    s.award(5, tr('سداد فاتورة', 'Paid a bill'));
    s.bump('bills_paid');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final bills = _bills(s);
    final pays = _pays(s);
    final main = _main(s);
    final sym = curSym(main);
    final today = todayPlace();

    double inMain(Map b) => _conv(s, numOf(b['a']), (b['cur'] as String?) ?? 'SDG', main);
    final monthlySum = bills.where((b) => b['freq'] != 'y').fold(0.0, (a, b) => a + inMain(b));
    final yearlySum = bills.where((b) => b['freq'] == 'y').fold(0.0, (a, b) => a + inMain(b));
    final avgMonthly = monthlySum + yearlySum / 12;

    // فواتير هذا الشهر (الشهرية + السنوية المستحقة هذا الشهر)
    final thisMonth = <(Map<String, dynamic>, DateTime)>[
      for (final b in bills)
        if (b['freq'] != 'y' || intOf(b['month'], 1) == today.month) (b, BillDue.dueIn(b, today.year, today.month)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final dueThisMonth = thisMonth.fold(0.0, (a, e) => a + inMain(e.$1));
    var paidThisMonth = 0.0;
    for (final e in thisMonth) {
      final p = pays.where((p) => p['bill'] == e.$1['id'] && p['period'] == BillDue.period(e.$1, e.$2));
      for (final x in p) {
        paidThisMonth += _conv(s, numOf(x['a']), (x['cur'] as String?) ?? 'SDG', main);
      }
    }
    final unpaidThisMonth = thisMonth.where((e) => !BillDue.isPaid(e.$1, BillDue.period(e.$1, e.$2), pays)).fold(0.0, (a, e) => a + inMain(e.$1));

    // القادم: أقرب استحقاق غير مدفوع لكل فاتورة
    final upcoming = <(Map<String, dynamic>, DateTime)>[
      for (final b in bills)
        for (final d in BillDue.upcoming(b, today, pays, count: 1)) (b, d),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final byCat = <String, double>{};
    for (final b in bills) {
      final v = b['freq'] == 'y' ? inMain(b) / 12 : inMain(b);
      byCat[_bcat(b['cat']).key] = (byCat[_bcat(b['cat']).key] ?? 0) + v;
    }
    final catsSorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final history = [...pays]..sort((a, b) => ((b['d'] as String?) ?? '').compareTo((a['d'] as String?) ?? ''));

    String summary() {
      final b = StringBuffer('🧾 ${t('فواتير', 'فواتير', 'Bills')} ${fmtMonth(today.year, today.month)}\n');
      for (final e in thisMonth) {
        final paid = BillDue.isPaid(e.$1, BillDue.period(e.$1, e.$2), pays);
        b.writeln('${paid ? '☑' : '☐'} ${e.$1['name']}: ${fmt(numOf(e.$1['a']), 0)} ${curSym(e.$1['cur'] ?? 'SDG')} — ${fmtShort(e.$2)}');
      }
      b.writeln('${t('المجموع', 'الإجمالي', 'Total')}: ${fmt(dueThisMonth, 0)} $sym · ${t('الباقي', 'المتبقي', 'Left')}: ${fmt(unpaidThisMonth, 0)} $sym');
      return b.toString().trim();
    }

    return ToolList(children: [
      ResultHero(
        label: t('فواتير الشهر دا', 'فواتير هذا الشهر', 'Bills this month'),
        value: '${fmt(dueThisMonth, 0)} $sym',
        sub: [
          '${t('دفعت', 'المدفوع', 'Paid')} ${fmt(paidThisMonth, 0)}',
          '${t('فاضل', 'المتبقي', 'Left')} ${fmt(unpaidThisMonth, 0)}',
        ].join(' · '),
        colors: const [SD.indigo, SD.nile, SD.brownDeep],
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: Text(t('ضيف فاتورة', 'إضافة فاتورة', 'Add bill'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(height: 14),
      if (bills.isEmpty)
        EmptyHint(Icons.receipt_long_outlined,
            t('ضيف فواتيرك الثابتة (كهرباء، موية، نت، إيجار…) ونحن بنذكّرك قبل موعدها', 'أضف فواتيرك الثابتة (كهرباء، مياه، إنترنت، إيجار…) وسنذكّرك قبل موعدها',
                'Add your recurring bills (power, water, internet, rent…) and get reminded before they are due'))
      else ...[
        HStats([
          (fmt(avgMonthly, 0), t('متوسط الشهر ($sym)', 'المتوسط الشهري ($sym)', 'Monthly avg ($sym)'), SD.indigo),
          (fmt(avgMonthly * 12, 0), t('في السنة ($sym)', 'سنويًا ($sym)', 'Per year ($sym)'), SD.teal),
          ('${bills.length}', t('فاتورة', 'فاتورة', 'bills'), SD.gold),
        ]),
        const SizedBox(height: 14),
        SCard(
          title: fmtMonth(today.year, today.month),
          icon: Icons.event_available_rounded,
          color: SD.indigo,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (dueThisMonth > 0)
              PercentBar(t('اتدفع', 'نسبة المدفوع', 'Paid'), (dueThisMonth - unpaidThisMonth) / dueThisMonth,
                  '${fmt((dueThisMonth - unpaidThisMonth) / dueThisMonth * 100, 0)}%'),
            for (final e in thisMonth) _billTile(s, e.$1, e.$2, pays, today),
          ]),
        ),
        if (upcoming.isNotEmpty)
          SCard(
            title: t('الجاي', 'القادم', 'Upcoming'),
            icon: Icons.upcoming_rounded,
            color: SD.orange,
            child: Column(children: [
              for (final e in upcoming.take(8))
                InfoRow(
                  '${_bcat(e.$1['cat']).emoji} ${e.$1['name']}',
                  '${fmt(numOf(e.$1['a']), 0)} ${curSym(e.$1['cur'] ?? 'SDG')}',
                  hint: '${fmtShort(e.$2)} · ${_daysText(dayDiff(today, e.$2))}',
                  valueColor: dayDiff(today, e.$2) < 0 ? SD.red : (dayDiff(today, e.$2) <= intOf(e.$1['remind'], 3) ? SD.orange : null),
                ),
            ]),
          ),
        SCard(
          title: t('حسب النوع (في الشهر)', 'حسب الفئة (شهريًا)', 'By category (monthly)'),
          icon: Icons.donut_small_rounded,
          color: SD.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final c in catsSorted)
              PercentBar('${_bcat(c.key).emoji} ${_bcat(c.key).name}', avgMonthly == 0 ? 0 : c.value / avgMonthly, '${fmt(c.value, 0)} $sym', color: _bcat(c.key).color),
            if (yearlySum > 0)
              Text(t('الفواتير السنوية متقسّمة على 12 شهر', 'الفواتير السنوية مقسّمة على 12 شهرًا', 'Yearly bills are spread over 12 months'), style: const TextStyle(fontSize: 11.5)),
          ]),
        ),
        SCard(
          title: t('كل الفواتير', 'كل الفواتير', 'All bills'),
          icon: Icons.list_alt_rounded,
          color: SD.coffee,
          child: Column(children: [
            for (final b in bills)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _edit(b),
                leading: CircleAvatar(backgroundColor: _bcat(b['cat']).color.withValues(alpha: .2), child: Text(_bcat(b['cat']).emoji)),
                title: Text('${b['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  b['freq'] == 'y'
                      ? '${t('سنوية', 'سنوية', 'Yearly')} · ${intOf(b['day'], 1)} ${monthsAr[(intOf(b['month'], 1) - 1) % 12]}'
                      : '${t('شهرية · يوم', 'شهرية · يوم', 'Monthly · day')} ${intOf(b['day'], 1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text('${fmt(numOf(b['a']), 0)} ${curSym(b['cur'] ?? 'SDG')}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 4),
                  Icon(b['notify'] == false ? Icons.notifications_off_outlined : Icons.notifications_active_rounded, size: 18, color: SD.gold),
                ]),
              ),
          ]),
        ),
        if (history.isNotEmpty)
          SCard(
            title: t('سجل الدفع', 'سجل المدفوعات', 'Payment history'),
            icon: Icons.history_rounded,
            color: SD.green,
            child: Column(children: [
              for (final p in history.take(20))
                InfoRow(
                  '${_bcat(p['cat']).emoji} ${p['name']}',
                  '${fmt(numOf(p['a']), 2)} ${curSym(p['cur'] ?? 'SDG')}',
                  hint: '${t('عن', 'عن فترة', 'for')} ${_periodText('${p['period']}')} · ${parseDk(p['d']) == null ? '' : fmtShort(parseDk(p['d'])!)}',
                ),
            ]),
          ),
        ShareBar(summary),
        const SizedBox(height: 10),
      ],
      SCard(
        title: t('الضبط والتنبيهات', 'الإعدادات والتنبيهات', 'Settings & reminders'),
        icon: Icons.notifications_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyPicker(t('اعرض المجاميع بـ', 'عرض الإجماليات بـ', 'Show totals in'), main, (v) => s.setData('bills_cfg', {...?s.getData<Map>('bills_cfg'), 'main': v})),
          const SizedBox(height: 10),
          if (!BillNotifications.supported)
            NoteBox(t('التنبيهات بتشتغل في الموبايل بس (أندرويد/آيفون).', 'التنبيهات متاحة على الهاتف فقط (أندرويد/آيفون).', 'Reminders work on phones only (Android/iOS).'))
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(
                avatar: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(t('جدّد التنبيهات', 'إعادة جدولة', 'Re-arm reminders')),
                onPressed: () async {
                  await BillNotifications.requestPermission();
                  final c = await BillNotifications.reschedule(s);
                  toast('${t('اتجدولت', 'تمت جدولة', 'Scheduled')} $c ${t('تنبيه', 'تنبيه', 'reminders')}');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.notifications_rounded, size: 18),
                label: Text(t('جرّب التنبيه', 'تنبيه تجريبي', 'Test reminder')),
                onPressed: () async {
                  await BillNotifications.requestPermission();
                  await BillNotifications.test();
                },
              ),
            ]),
        ]),
      ),
      NoteBox(
        t('التنبيهات بتتجدد كل ما تفتح الأداة. لو الفاتورة بتتغيّر (زي الكهرباء)، أكتب المبلغ الحقيقي وقت تسجّل الدفع.',
            'تتجدد التنبيهات كلما فتحت الأداة. إن كان مبلغ الفاتورة متغيرًا (كالكهرباء) فأدخل المبلغ الفعلي عند تسجيل الدفع.',
            'Reminders are re-armed each time you open this tool. For variable bills (like electricity), enter the actual amount when marking paid.'),
        kind: NoteKind.tip,
      ),
    ]);
  }

  String _daysText(int d) {
    if (d == 0) return t('الليلة', 'اليوم', 'today');
    if (d < 0) return t('متأخرة ${-d} يوم', 'متأخرة ${-d} يومًا', '${-d} days overdue');
    if (d == 1) return t('بكرة', 'غدًا', 'tomorrow');
    return t('بعد $d يوم', 'بعد $d يومًا', 'in $d days');
  }

  String _periodText(String p) {
    final parts = p.split('-');
    if (parts.length == 2) return fmtMonth(int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 1);
    return p;
  }

  Widget _billTile(AppState s, Map<String, dynamic> b, DateTime due, List<Map<String, dynamic>> pays, DateTime today) {
    final paid = BillDue.isPaid(b, BillDue.period(b, due), pays);
    final d = dayDiff(today, due);
    final c = _bcat(b['cat']);
    final status = paid
        ? t('اتدفعت ✓', 'مدفوعة ✓', 'Paid ✓')
        : (d < 0 ? t('متأخرة!', 'متأخرة!', 'Overdue!') : _daysText(d));
    final sc = paid ? SD.green : (d < 0 ? SD.red : (d <= intOf(b['remind'], 3) ? SD.orange : SD.nile));
    return Card(
      margin: const EdgeInsets.only(top: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: sc.withValues(alpha: .4))),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.only(start: 4, end: 8),
        leading: Checkbox(value: paid, activeColor: SD.green, onChanged: (_) => _markPaid(s, b, due)),
        title: Text('${c.emoji} ${b['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, decoration: paid ? TextDecoration.lineThrough : null)),
        subtitle: Text('${fmtShort(due)} · $status', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: readable(context, sc))),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text('${fmt(numOf(b['a']), 0)} ${curSym(b['cur'] ?? 'SDG')}', style: const TextStyle(fontWeight: FontWeight.w800))),
        ),
        onTap: () => _markPaid(s, b, due),
        onLongPress: () => _edit(b),
      ),
    );
  }
}
