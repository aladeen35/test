import 'dart:async';
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

final cutsChannel = HpChannel('cuts', () => t('قطوعات الكهرباء', 'انقطاع الكهرباء', 'Power cuts'),
    () => t('تنبيه قبل القطوعة', 'تنبيه قبل موعد انقطاع الكهرباء', 'Alert before a scheduled power cut'), 7400, 200);

/// فترات القطع الفعلية (ساعة حائط المكان) حول تاريخ معيّن — تشمل الفترات العابرة لمنتصف الليل
List<(DateTime, DateTime)> cutIntervals(List<Map<String, dynamic>> slots, DateTime from, int days) {
  final r = <(DateTime, DateTime)>[];
  for (var d = 0; d < days; d++) {
    final day = DateTime(from.year, from.month, from.day + d);
    for (final sl in slots) {
      if (intOf(sl['wd']) != day.weekday) continue;
      final a = intOf(sl['from']), b = intOf(sl['to']);
      final st = DateTime(day.year, day.month, day.day, a ~/ 60, a % 60);
      var en = DateTime(day.year, day.month, day.day, b ~/ 60, b % 60);
      if (!en.isAfter(st)) en = en.add(const Duration(days: 1));
      r.add((st, en));
    }
  }
  r.sort((x, y) => x.$1.compareTo(y.$1));
  // دمج المتداخل
  final m = <(DateTime, DateTime)>[];
  for (final iv in r) {
    if (m.isNotEmpty && !iv.$1.isAfter(m.last.$2)) {
      if (iv.$2.isAfter(m.last.$2)) m[m.length - 1] = (m.last.$1, iv.$2);
    } else {
      m.add(iv);
    }
  }
  return m;
}

int slotMinutes(Map sl) {
  final a = intOf(sl['from']), b = intOf(sl['to']);
  return b > a ? b - a : 1440 - a + b;
}

class PowerCutsTool extends StatefulWidget {
  const PowerCutsTool({super.key});
  @override
  State<PowerCutsTool> createState() => _PowerCutsToolState();
}

class _PowerCutsToolState extends State<PowerCutsTool> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      if (mounted && _cfg(s)['notify'] == true && _slots(s).isNotEmpty) _reschedule(s);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('cuts_cfg') ?? {});
  void _setCfg(AppState s, Map<String, dynamic> m) => s.setData('cuts_cfg', {..._cfg(s), ...m});
  List<Map<String, dynamic>> _slots(AppState s) {
    final l = mapList(s.getData<List>('cuts_slots'));
    l.sort((a, b) {
      final c = intOf(a['wd']).compareTo(intOf(b['wd']));
      return c != 0 ? c : intOf(a['from']).compareTo(intOf(b['from']));
    });
    return l;
  }

  List<Map<String, dynamic>> _log(AppState s) => mapList(s.getData<List>('cuts_log'));

  Future<void> _reschedule(AppState s) async {
    final cfg = _cfg(s);
    final items = <(int, String, String?, DateTime, DateTimeComponents?)>[];
    if (cfg['notify'] == true) {
      final before = intOf(cfg['before'], 15);
      final now = pNow();
      final slots = _slots(s);
      for (var i = 0; i < slots.length && i < 99; i++) {
        final sl = slots[i];
        final wd = intOf(sl['wd']), a = intOf(sl['from']), b = intOf(sl['to']);
        // أقرب موعد قادم لهذه الفترة
        var day = DateTime(now.year, now.month, now.day);
        while (day.weekday != wd) {
          day = day.add(const Duration(days: 1));
        }
        var start = DateTime(day.year, day.month, day.day, a ~/ 60, a % 60);
        var alert = start.subtract(Duration(minutes: before));
        if (!alert.isAfter(now)) {
          start = DateTime(start.year, start.month, start.day + 7, a ~/ 60, a % 60);
          alert = start.subtract(Duration(minutes: before));
        }
        items.add((
          i,
          '🔌 ${t('القطوعة بعد $before دقيقة', 'انقطاع الكهرباء بعد $before دقيقة', 'Power cut in $before min')}',
          t('من ${minsLabel(a)} لحدّي ${minsLabel(b)} — اشحن تلفونك وشغّل الموية', 'من ${minsLabel(a)} حتى ${minsLabel(b)} — اشحن هاتفك واملأ الماء',
              'From ${minsLabel(a)} to ${minsLabel(b)} — charge your phone and fill water'),
          alert,
          DateTimeComponents.dayOfWeekAndTime,
        ));
        if (cfg['back'] == true) {
          var end = DateTime(start.year, start.month, start.day, b ~/ 60, b % 60);
          if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
          items.add((
            100 + i,
            '💡 ${t('الكهرباء المفروض جات', 'يُفترض عودة الكهرباء', 'Power should be back')}',
            t('نهاية القطوعة حسب الجدول', 'نهاية الانقطاع حسب الجدول', 'Scheduled cut has ended'),
            end,
            DateTimeComponents.dayOfWeekAndTime,
          ));
        }
      }
    }
    await HpNotify.replace(s, cutsChannel, items);
  }

  Future<void> _addSlot(AppState s, [Map<String, dynamic>? sl]) async {
    final days = <int>{if (sl != null) intOf(sl['wd']) else pToday().weekday};
    var from = sl == null ? 18 * 60 : intOf(sl['from']);
    var to = sl == null ? 22 * 60 : intOf(sl['to']);
    final ok = await lifeSheet<bool>(
      context,
      sl == null ? t('ضيف قطوعة', 'إضافة موعد قطع', 'Add a cut slot') : t('عدّل القطوعة', 'تعديل الموعد', 'Edit cut slot'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('الأيام', 'الأيام', 'Days'), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var d = 1; d <= 7; d++)
            FilterChip(
              label: Text(weekdaysAr[d - 1]),
              selected: days.contains(d),
              onSelected: (v) => set(() => v ? days.add(d) : days.remove(d)),
            ),
        ]),
        if (sl == null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: () => set(() => days.addAll([1, 2, 3, 4, 5, 6, 7])), child: Text(t('كل الأيام', 'كل الأيام', 'Every day'))),
          ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final v = await pickMins(ctx, from, help: t('بتقطع الساعة', 'تبدأ الساعة', 'Starts at'));
                if (v != null) set(() => from = v);
              },
              child: FittedBox(fit: BoxFit.scaleDown, child: Text('${t('من', 'من', 'From')} ${minsLabel(from)}', maxLines: 1)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final v = await pickMins(ctx, to, help: t('بتجي الساعة', 'تعود الساعة', 'Back at'));
                if (v != null) set(() => to = v);
              },
              child: FittedBox(fit: BoxFit.scaleDown, child: Text('${t('لحدّي', 'إلى', 'To')} ${minsLabel(to)}', maxLines: 1)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('احفظ', 'حفظ', 'Save'))),
      ]),
    );
    if (ok != true || !mounted || days.isEmpty || from == to) return;
    final slots = _slots(s);
    if (sl != null) slots.removeWhere((x) => x['id'] == sl['id']);
    for (final d in days) {
      slots.add({'id': newId(), 'wd': d, 'from': from, 'to': to});
    }
    s.setData('cuts_slots', slots);
    HomeWidgets.refreshPower(s);
    _reschedule(s);
    setState(() {});
  }

  void _delSlot(AppState s, Map sl) {
    s.setData('cuts_slots', _slots(s)..removeWhere((x) => x['id'] == sl['id']));
    HomeWidgets.refreshPower(s);
    _reschedule(s);
    setState(() {});
  }

  void _startCut(AppState s) {
    _setCfg(s, {'open': pNow().toIso8601String()});
    s.awardDaily('cuts_log', 2, t('سجّلت قطوعة', 'تسجيل انقطاع', 'Logged a power cut'));
    setState(() {});
  }

  void _endCut(AppState s) {
    final open = DateTime.tryParse(_cfg(s)['open'] as String? ?? '');
    _setCfg(s, {'open': null});
    if (open != null) {
      final end = pNow();
      if (end.difference(open).inMinutes >= 1) {
        final l = _log(s)..add({'id': newId(), 's': open.toIso8601String(), 'e': end.toIso8601String()});
        s.setData('cuts_log', l.length > 500 ? l.sublist(l.length - 500) : l);
      }
    }
    setState(() {});
  }

  Future<void> _manualCut(AppState s) async {
    var date = pToday();
    var from = 18 * 60, to = 20 * 60;
    final ok = await lifeSheet<bool>(
      context,
      t('سجّل قطوعة فاتت', 'تسجيل انقطاع سابق', 'Log a past cut'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LifeDateButton(label: t('اليوم', 'التاريخ', 'Date'), value: date, onPick: (d) => set(() => date = d ?? date), last: pToday()),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final v = await pickMins(ctx, from);
                if (v != null) set(() => from = v);
              },
              child: FittedBox(fit: BoxFit.scaleDown, child: Text('${t('قطعت', 'انقطعت', 'Off')} ${minsLabel(from)}', maxLines: 1)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final v = await pickMins(ctx, to);
                if (v != null) set(() => to = v);
              },
              child: FittedBox(fit: BoxFit.scaleDown, child: Text('${t('جات', 'عادت', 'Back')} ${minsLabel(to)}', maxLines: 1)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('احفظ', 'حفظ', 'Save'))),
      ]),
    );
    if (ok != true || !mounted || from == to) return;
    final st = DateTime(date.year, date.month, date.day, from ~/ 60, from % 60);
    var en = DateTime(date.year, date.month, date.day, to ~/ 60, to % 60);
    if (!en.isAfter(st)) en = en.add(const Duration(days: 1));
    s.setData('cuts_log', _log(s)..add({'id': newId(), 's': st.toIso8601String(), 'e': en.toIso8601String()}));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cfg = _cfg(s);
    final slots = _slots(s);
    final now = pNow();
    final today = DateTime(now.year, now.month, now.day);
    final ivs = cutIntervals(slots, today.subtract(const Duration(days: 1)), 9);
    (DateTime, DateTime)? inCut;
    DateTime? nextStart;
    for (final iv in ivs) {
      if (!now.isBefore(iv.$1) && now.isBefore(iv.$2)) inCut = iv;
      if (iv.$1.isAfter(now) && nextStart == null) nextStart = iv.$1;
    }
    final schedOff = inCut != null;
    final nextChange = inCut?.$2 ?? nextStart;
    final weekMins = slots.fold<int>(0, (a, sl) => a + slotMinutes(sl));
    final todayMins = cutIntervals(slots, today, 1).fold<int>(0, (a, iv) => a + iv.$2.difference(iv.$1).inMinutes);

    // السجل الفعلي
    final log = _log(s)
      ..sort((a, b) => (b['s'] as String? ?? '').compareTo(a['s'] as String? ?? ''));
    final open = DateTime.tryParse(cfg['open'] as String? ?? '');
    final weekAgo = now.subtract(const Duration(days: 7));
    var actual7 = 0, count7 = 0, longest = 0;
    for (final e in log) {
      final a = DateTime.tryParse(e['s'] as String? ?? ''), b = DateTime.tryParse(e['e'] as String? ?? '');
      if (a == null || b == null) continue;
      final m = b.difference(a).inMinutes;
      if (m > longest) longest = m;
      if (b.isAfter(weekAgo)) {
        final from = a.isBefore(weekAgo) ? weekAgo : a;
        actual7 += b.difference(from).inMinutes;
        count7++;
      }
    }
    if (open != null) actual7 += now.difference(open.isBefore(weekAgo) ? weekAgo : open).inMinutes;

    String h(int mins) => fmt(mins / 60, 1);

    String summary() => [
          '🔌 ${t('جدول قطوعات الكهرباء', 'جدول انقطاع الكهرباء', 'Power-cut schedule')}',
          for (var d = 1; d <= 7; d++)
            if (slots.any((x) => intOf(x['wd']) == d))
              '${weekdaysAr[d - 1]}: ${slots.where((x) => intOf(x['wd']) == d).map((x) => '${minsLabel(intOf(x['from']))}–${minsLabel(intOf(x['to']))}').join('، ')}',
          '${t('مجموع الأسبوع حسب الجدول', 'إجمالي الأسبوع حسب الجدول', 'Scheduled per week')}: ${h(weekMins)} ${t('ساعة', 'ساعة', 'h')}',
          '${t('الفعلي آخر 7 أيام', 'الفعلي آخر 7 أيام', 'Actual last 7 days')}: ${h(actual7)} ${t('ساعة', 'ساعة', 'h')}',
        ].join('\n');

    return ToolList(children: [
      ResultHero(
        label: slots.isEmpty
            ? t('جدول القطوعات', 'جدول الانقطاع', 'Cut schedule')
            : (schedOff ? t('حسب الجدول: الكهرباء قاطعة', 'حسب الجدول: الكهرباء مقطوعة', 'Scheduled: power OFF') : t('حسب الجدول: الكهرباء جاية', 'حسب الجدول: الكهرباء متوفرة', 'Scheduled: power ON')),
        value: slots.isEmpty ? '🔌' : (nextChange == null ? '—' : fmtDuration(nextChange.difference(now))),
        sub: slots.isEmpty
            ? t('ضيف مواعيد القطوعة بتاعة حلتك', 'أضف مواعيد الانقطاع في منطقتك', 'Add the cut times for your area')
            : nextChange == null
                ? null
                : '${schedOff ? t('بتجي', 'تعود', 'Back at') : t('بتقطع', 'تنقطع', 'Off at')} ${fmtTimeAr(nextChange)}${dayDiff(today, nextChange) > 0 ? ' — ${weekdaysAr[nextChange.weekday - 1]}' : ''}',
        colors: schedOff ? const [Color(0xFF141414), Color(0xFF3A1F0C), Color(0xFF3A1F0C)] : const [Color(0xFFD4A017), Color(0xFFB9852F), Color(0xFF3A1F0C)],
      ),
      SCard(
        title: t('هسي عندك كهرباء؟', 'هل الكهرباء متوفرة الآن؟', 'Power right now?'),
        icon: open != null ? Icons.power_off_rounded : Icons.power_rounded,
        color: open != null ? SD.red : SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (open != null)
            InfoRow(t('قاطعة من', 'مقطوعة منذ', 'Off since'), '${fmtTimeAr(open)} (${fmtDuration(now.difference(open))})', valueColor: SD.red),
          open == null
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: SD.red),
                  onPressed: () => _startCut(s),
                  icon: const Icon(Icons.power_off_rounded),
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('الكهرباء قطعت هسي', 'انقطعت الكهرباء الآن', 'Power just went off'), maxLines: 1)),
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: SD.green),
                  onPressed: () => _endCut(s),
                  icon: const Icon(Icons.power_rounded),
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('الكهرباء جات', 'عادت الكهرباء', 'Power is back'), maxLines: 1)),
                ),
          TextButton.icon(
            onPressed: () => _manualCut(s),
            icon: const Icon(Icons.edit_calendar_rounded),
            label: Text(t('سجّل قطوعة فاتت', 'تسجيل انقطاع سابق', 'Log a past cut'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
      StatGrid([
        StatChip(h(weekMins), t('ساعة/أسبوع (الجدول)', 'ساعة أسبوعيًا (الجدول)', 'h/week scheduled'), color: SD.gold, icon: Icons.event_note_rounded),
        StatChip(h(actual7), t('ساعة فعلية آخر 7 أيام', 'ساعة فعلية آخر 7 أيام', 'h actual (7 days)'), color: SD.red, icon: Icons.power_off_rounded),
        StatChip(h(todayMins), t('ساعة الليلة (الجدول)', 'ساعة اليوم (الجدول)', 'h today scheduled'), color: SD.nile, icon: Icons.today_rounded),
        StatChip('$count7', t('قطوعة آخر أسبوع', 'انقطاع آخر أسبوع', 'cuts last week'), color: SD.henna),
        StatChip(h(actual7 ~/ 7), t('متوسط اليوم (ساعة)', 'المتوسط اليومي (ساعة)', 'avg/day (h)'), color: SD.teal),
        StatChip(longest == 0 ? '—' : h(longest), t('أطول قطوعة (ساعة)', 'أطول انقطاع (ساعة)', 'longest (h)'), color: SD.purple),
      ]),
      const SizedBox(height: 14),
      if (weekMins > 0) ...[
        HpBar(weekMins / (7 * 1440),
            color: SD.red,
            left: t('نسبة القطع من الأسبوع', 'نسبة الانقطاع من الأسبوع', 'Share of the week without power'),
            right: '${fmt(weekMins * 100 / (7 * 1440), 1)}%'),
        const SizedBox(height: 14),
      ],
      SCard(
        title: t('الجدول الأسبوعي', 'الجدول الأسبوعي', 'Weekly schedule'),
        icon: Icons.calendar_view_week_rounded,
        color: SD.gold,
        trailing: IconButton(tooltip: t('ضيف', 'إضافة', 'Add'), onPressed: () => _addSlot(s), icon: const Icon(Icons.add_rounded)),
        child: slots.isEmpty
            ? EmptyHint(Icons.event_busy_rounded, t('ما في مواعيد لسه', 'لا توجد مواعيد بعد', 'No cut times yet'),
                action: FilledButton.icon(onPressed: () => _addSlot(s), icon: const Icon(Icons.add_rounded), label: Text(t('ضيف قطوعة', 'إضافة موعد', 'Add a slot'))))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var d = 1; d <= 7; d++)
                  if (slots.any((x) => intOf(x['wd']) == d)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${weekdaysAr[d - 1]}${d == now.weekday ? ' • ${tr('اليوم', 'today')}' : ''}',
                        style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, d == now.weekday ? SD.gold : SD.brownLight)),
                      ),
                    ),
                    for (final sl in slots.where((x) => intOf(x['wd']) == d))
                      HpLogTile(
                        icon: Icons.power_off_rounded,
                        color: SD.red,
                        title: '${minsLabel(intOf(sl['from']))} – ${minsLabel(intOf(sl['to']))}',
                        sub: '${h(slotMinutes(sl))} ${t('ساعة', 'ساعة', 'h')}',
                        onTap: () => _addSlot(s, sl),
                        onDelete: () => _delSlot(s, sl),
                      ),
                  ],
              ]),
      ),
      SCard(
        title: t('التنبيه', 'التنبيه', 'Alerts'),
        icon: Icons.notifications_active_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HpSwitch(
            t('نبّهني قبل القطوعة', 'نبّهني قبل الانقطاع', 'Alert me before each cut'),
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
            sub: t('بيتكرر كل أسبوع', 'يتكرر أسبوعيًا', 'Repeats every week'),
          ),
          if (cfg['notify'] == true) ...[
            HpStepper(
              label: t('قبلها بـ', 'قبلها بـ', 'Minutes before'),
              value: intOf(cfg['before'], 15),
              unit: t('د', 'د', 'min'),
              min: 5,
              max: 120,
              step: 5,
              onChanged: (v) {
                _setCfg(s, {'before': v});
                _reschedule(s);
                setState(() {});
              },
            ),
            HpSwitch(t('ونبّهني لما ترجع', 'ونبّهني عند عودتها', 'Also alert when it should be back'), cfg['back'] == true, (v) {
              _setCfg(s, {'back': v});
              _reschedule(s);
              setState(() {});
            }),
          ],
        ]),
      ),
      SCard(
        title: t('القطوعات الفعلية', 'الانقطاعات الفعلية', 'Actual cuts'),
        icon: Icons.history_rounded,
        color: SD.nile,
        child: log.isEmpty
            ? EmptyHint(Icons.power_rounded, t('سجّل القطوعات عشان تعرف الفرق بين الجدول والواقع', 'سجّل الانقطاعات لمقارنة الجدول بالواقع', 'Log cuts to compare the schedule with reality'))
            : Column(children: [
                for (final e in log.take(40))
                  () {
                    final a = DateTime.tryParse(e['s'] as String? ?? '') ?? now, b = DateTime.tryParse(e['e'] as String? ?? '') ?? now;
                    return HpLogTile(
                      icon: Icons.power_off_rounded,
                      color: SD.red,
                      title: fmtDateAr(a),
                      sub: '${fmtTimeAr(a)} – ${fmtTimeAr(b)}',
                      value: fmtDuration(b.difference(a)),
                      onDelete: () {
                        s.setData('cuts_log', _log(s)..removeWhere((x) => x['id'] == e['id']));
                        setState(() {});
                      },
                    );
                  }(),
              ]),
      ),
      NoteBox(t('المواعيد بتوقيت المكان المختار في التطبيق. قبل القطوعة: اشحن التلفون والباوربانك واملأ الموية، وافصل الأجهزة الحساسة عشان رجعة الكهرباء.',
          'المواعيد بتوقيت المكان المختار في التطبيق. قبل الانقطاع: اشحن الهاتف والبطارية الاحتياطية واملأ الماء، وافصل الأجهزة الحساسة تحسبًا لعودة التيار.',
          'Times use the app\'s selected place. Before a cut: charge phone and power bank, store water, and unplug sensitive devices to protect them when power returns.'),
          kind: NoteKind.tip),
      ShareBar(summary),
    ]);
  }
}
