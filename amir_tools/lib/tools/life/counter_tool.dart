import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/prayer.dart' show toPlace;
import '../daily/daily_common.dart' show Bar, BarChart, ProgressRing;
import 'life_common.dart';

/// العدّاد: عدّادات متعددة بأسماء (جوالات، زوار، لفّات…)
class CounterTool extends StatefulWidget {
  const CounterTool({super.key});
  @override
  State<CounterTool> createState() => _CounterToolState();
}

List<(String, String, String, String)> get _ideas => const [
      ('🌾', 'جوالات', 'أجولة', 'Sacks'),
      ('🚶', 'زوار', 'الزوار', 'Visitors'),
      ('🔢', 'عدد', 'عدد', 'Count'),
      ('🐑', 'غنم', 'أغنام', 'Sheep'),
      ('🏃', 'لفّات', 'لفّات', 'Laps'),
      ('📦', 'كراتين', 'كراتين', 'Boxes'),
      ('🧱', 'طوب', 'طوب', 'Bricks'),
      ('🚗', 'عربات', 'سيارات', 'Cars'),
    ];

class _CounterToolState extends State<CounterTool> {
  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('counter_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('counter_list', l);
  bool _haptic(AppState s) => s.getData<bool>('counter_haptic') ?? true;

  Map<String, dynamic>? _sel(AppState s, List<Map<String, dynamic>> l) {
    if (l.isEmpty) return null;
    final id = s.getData<String>('counter_sel');
    return l.firstWhere((x) => x['id'] == id, orElse: () => l.first);
  }

  void _add(String name, [int color = 0]) {
    final s = context.read<AppState>();
    final id = newId();
    final l = _list(s)..add({'id': id, 'name': name, 'v': 0, 'step': 1, 'color': color, 'goal': null, 'days': <String, dynamic>{}, 'resets': <Map>[]});
    _save(s, l);
    s.setData('counter_sel', id);
    setState(() {});
  }

  void _mutate(String id, void Function(Map<String, dynamic>) f) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == id);
    if (i < 0) return;
    f(l[i]);
    _save(s, l);
    setState(() {});
  }

  void _bump(Map<String, dynamic> c, int by) {
    final s = context.read<AppState>();
    final before = intOf(c['v']);
    final after = before + by;
    final goal = c['goal'] == null ? null : intOf(c['goal']);
    _mutate(c['id'], (x) {
      x['v'] = after;
      final days = Map<String, dynamic>.from((x['days'] as Map?) ?? const {});
      final k = dk(todayPlace());
      days[k] = intOf(days[k]) + by;
      final keys = days.keys.toList()..sort();
      for (final old in keys.take(keys.length > 60 ? keys.length - 60 : 0)) {
        days.remove(old);
      }
      x['days'] = days;
    });
    if (_haptic(s)) {
      by > 0 ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick();
    }
    if (goal != null && goal > 0 && before < goal && after >= goal) {
      if (_haptic(s)) HapticFeedback.heavyImpact();
      toast(t('🎯 وصلت الهدف: $goal ${c['name']}!', '🎯 وصلت إلى الهدف: $goal ${c['name']}!', '🎯 Goal reached: $goal ${c['name']}!'));
      s.awardDaily('counter_goal_${c['id']}', 5, tr('هدف العدّاد', 'Counter goal'));
    }
  }

  void _reset(Map<String, dynamic> c) {
    final prev = intOf(c['v']);
    if (prev == 0) return;
    _mutate(c['id'], (x) {
      x['v'] = 0;
      final r = mapList(x['resets'])..insert(0, {'t': DateTime.now().millisecondsSinceEpoch, 'v': prev});
      x['resets'] = r.take(30).toList();
    });
    if (_haptic(context.read<AppState>())) HapticFeedback.mediumImpact();
    undoSnack(t('اتصفّر العدّاد (كان $prev)', 'تم التصفير (كان $prev)', 'Counter reset (was $prev)'), () {
      _mutate(c['id'], (x) {
        x['v'] = prev;
        final r = mapList(x['resets']);
        if (r.isNotEmpty) r.removeAt(0);
        x['resets'] = r;
      });
    });
  }

  Future<void> _settings(Map<String, dynamic> c) async {
    final s = context.read<AppState>();
    final nameC = TextEditingController(text: '${c['name']}');
    final goalC = TextEditingController(text: c['goal'] == null ? '' : '${c['goal']}');
    final valC = TextEditingController(text: '${intOf(c['v'])}');
    var color = intOf(c['color']);
    final ok = await lifeSheet<bool>(
      context,
      t('ضبط العدّاد', 'إعدادات العدّاد', 'Counter settings'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nameC, decoration: InputDecoration(labelText: t('الاسم', 'الاسم', 'Name'))),
        const SizedBox(height: 10),
        NumField(t('الهدف (اختياري)', 'الهدف (اختياري)', 'Goal (optional)'), goalC, decimal: false, hint: t('فاضي = بلا هدف', 'فارغ = بدون هدف', 'Empty = no goal')),
        NumField(t('القيمة الحالية', 'القيمة الحالية', 'Current value'), valC, decimal: false),
        Text(t('اللون', 'اللون', 'Color'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ColorDots(color, (v) => set(() => color = v)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: SD.red),
              onPressed: () => Navigator.pop(ctx, false),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(t('امسحو', 'حذف', 'Delete')),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('احفظ', 'حفظ', 'Save'))),
          ),
        ]),
      ]),
    );
    final name = nameC.text.trim(), goal = parseNum(goalC.text).round(), val = parseNum(valC.text, intOf(c['v']).toDouble()).round();
    nameC.dispose();
    goalC.dispose();
    valC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false) {
      if (!await confirmAsk(context, t('نمسح العدّاد؟', 'حذف العدّاد؟', 'Delete counter?'), '${c['name']}')) return;
      final l = _list(s);
      final i = l.indexWhere((x) => x['id'] == c['id']);
      if (i < 0) return;
      final removed = l.removeAt(i);
      _save(s, l);
      setState(() {});
      undoSnack(t('اتمسح العدّاد', 'حُذف العدّاد', 'Counter deleted'), () {
        final l2 = _list(s);
        l2.insert(i.clamp(0, l2.length), removed);
        _save(s, l2);
        s.setData('counter_sel', removed['id']);
        if (mounted) setState(() {});
      });
      return;
    }
    _mutate(c['id'], (x) {
      if (name.isNotEmpty) x['name'] = name;
      x['goal'] = goal > 0 ? goal : null;
      x['v'] = val;
      x['color'] = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = _list(s);
    final c = _sel(s, l);

    final selector = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final x in l)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: PickChip('${x['name']} · ${intOf(x['v'])}', x['id'] == c?['id'], () {
              s.setData('counter_sel', x['id']);
              setState(() {});
            }, color: palette(x['color'])),
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: Text(t('عدّاد جديد', 'عدّاد جديد', 'New counter')),
          onPressed: () async {
            final n = (await askText(context, t('اسم العدّاد', 'اسم العدّاد', 'Counter name'), hint: t('جوالات، زوار…', 'أجولة، زوار…', 'Sacks, visitors…')))?.trim() ?? '';
            if (n.isNotEmpty) _add(n, l.length % lifePalette.length);
          },
        ),
      ]),
    );

    if (c == null) {
      return ToolList(children: [
        SCard(
          title: t('العدّاد', 'العدّاد', 'Tally counter'),
          icon: Icons.exposure_plus_1_rounded,
          color: SD.indigo,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('عدّ أي حاجة: جوالات في الدونكي، زوار في المناسبة، لفّات في الرياضة… اختار واحد من دول أو أعمل عدّادك.',
                'عُدّ أي شيء: الأجولة، الزوار، اللفّات… اختر أحد الاقتراحات أو أنشئ عدّادك.',
                'Count anything: sacks, guests, laps… pick a suggestion or make your own.')),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _ideas.length; i++)
                ActionChip(avatar: Text(_ideas[i].$1), label: Text(t(_ideas[i].$2, _ideas[i].$3, _ideas[i].$4)), onPressed: () => _add(t(_ideas[i].$2, _ideas[i].$3, _ideas[i].$4), i)),
            ]),
            const SizedBox(height: 10),
            selector,
          ]),
        ),
      ]);
    }

    final col = palette(c['color']);
    final v = intOf(c['v']);
    final step = intOf(c['step'], 1).clamp(1, 1000000);
    final goal = c['goal'] == null ? null : intOf(c['goal']);
    final days = Map<String, dynamic>.from((c['days'] as Map?) ?? const {});
    final resets = mapList(c['resets']);
    final today = todayPlace();
    final todayCount = intOf(days[dk(today)]);
    final week = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final weekTotal = week.fold<int>(0, (a, d) => a + intOf(days[dk(d)]));

    final valueText = Text(
      fmt(v, 0),
      style: TextStyle(fontSize: v.abs() >= 100000 ? 48 : 68, fontWeight: FontWeight.w800, color: readable(context, col), height: 1.1),
    );

    return ToolList(children: [
      selector,
      const SizedBox(height: 10),
      SCard(
        color: col,
        title: '${c['name']}',
        icon: Icons.exposure_plus_1_rounded,
        trailing: IconButton(tooltip: t('الضبط', 'الإعدادات', 'Settings'), onPressed: () => _settings(c), icon: const Icon(Icons.tune_rounded)),
        child: Column(children: [
          if (goal != null && goal > 0)
            ProgressRing(
              progress: v / goal,
              color: v >= goal ? SD.teal : col,
              size: 200,
              stroke: 14,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FittedBox(child: valueText),
                Text(t('من $goal', 'من $goal', 'of $goal'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            )
          else
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: FittedBox(child: valueText)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 130,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: col,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: () => _bump(c, step),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_rounded, size: 54),
                if (step != 1) Text('$step', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 58,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), side: BorderSide(color: col, width: 1.6)),
                  onPressed: () => _bump(c, -step),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.remove_rounded, size: 30),
                    if (step != 1) Text('$step', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 58,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: SD.red,
                  side: BorderSide(color: SD.red.withValues(alpha: .6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: v == 0 ? null : () => _reset(c),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(t('صفّر', 'تصفير', 'Reset')),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text(t('الخطوة:', 'مقدار الزيادة:', 'Step:'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final st in {1, 2, 5, 10, 50, if (![1, 2, 5, 10, 50].contains(step)) step})
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: PickChip('$st', step == st, () => _mutate(c['id'], (x) => x['step'] = st), color: col),
                    ),
                  ActionChip(
                    label: Text(t('غيرو', 'أخرى', 'Other')),
                    onPressed: () async {
                      final n = parseNum(await askText(context, t('الخطوة كم؟', 'مقدار الزيادة', 'Step size'), number: true)).round();
                      if (n > 0) _mutate(c['id'], (x) => x['step'] = n);
                    },
                  ),
                ]),
              ),
            ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(t('اهتزاز مع كل دوسة', 'اهتزاز عند كل ضغطة', 'Vibrate on each tap')),
            value: _haptic(s),
            onChanged: (b) => s.setData('counter_haptic', b),
          ),
        ]),
      ),
      StatGrid([
        StatChip('${todayCount >= 0 ? '+' : ''}$todayCount', t('الليلة', 'اليوم', 'Today'), color: col, icon: Icons.today_rounded),
        StatChip('$weekTotal', t('آخر 7 أيام', 'آخر 7 أيام', 'Last 7 days'), color: SD.nile, icon: Icons.date_range_rounded),
        StatChip('${resets.length}', t('مرات التصفير', 'مرات التصفير', 'Resets'), color: SD.henna, icon: Icons.restart_alt_rounded),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: t('السجل', 'السجل', 'History'),
        icon: Icons.history_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BarChart([
            for (final d in week)
              Bar(dayDiff(d, today) == 0 ? t('الليلة', 'اليوم', 'Today') : shortDaysL[d.weekday - 1], intOf(days[dk(d)]).clamp(0, 1 << 30).toDouble(), color: col),
          ], color: col, height: 140, valueText: (x) => x == 0 ? '' : fmt(x, 0)),
          Text(t('الزيادة في كل يوم', 'مقدار الزيادة يوميًا', 'Added per day'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
          if (resets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(t('آخر التصفيرات', 'آخر عمليات التصفير', 'Recent resets'), style: const TextStyle(fontWeight: FontWeight.w800)),
            for (final r in resets.take(10))
              InfoRow(
                () {
                  final at = DateTime.fromMillisecondsSinceEpoch(intOf(r['t']));
                  return '${fmtDateAr(msDay(intOf(r['t'])), weekday: false)} · ${fmtTimeAr(toPlace(at))}';
                }(),
                fmt(intOf(r['v']), 0),
                icon: Icons.restart_alt_rounded,
              ),
          ],
        ]),
      ),
      if (l.length > 1)
        SCard(
          title: t('كل العدّادات', 'جميع العدّادات', 'All counters'),
          icon: Icons.list_alt_rounded,
          color: SD.indigo,
          child: Column(children: [
            for (final x in l)
              InfoRow('${x['name']}', fmt(intOf(x['v']), 0), icon: Icons.circle, valueColor: palette(x['color'])),
          ]),
        ),
      ShareBar(() => [for (final x in l) '${x['name']}: ${fmt(intOf(x['v']), 0)}'].join('\n')),
    ]);
  }
}
