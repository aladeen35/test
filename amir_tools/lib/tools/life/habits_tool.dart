import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../daily/daily_common.dart' show Bar, BarChart, ProgressRing;
import '../money/money_common.dart' show MiniTable;
import 'life_common.dart';

/// عادة مقترحة: (إيموجي، سوداني، فصحى، إنجليزي، أيام في الأسبوع)
typedef _Sug = (String, String, String, String, int);

List<_Sug> get _suggestions => const [
      ('🕌', 'صلاة الضحى', 'صلاة الضحى', 'Duha prayer', 7),
      ('📖', 'قراية جزء', 'قراءة جزء من القرآن', 'Read one juz\' of Qur\'an', 7),
      ('📿', 'أذكار الصباح والمسا', 'أذكار الصباح والمساء', 'Morning & evening adhkar', 7),
      ('🏃', 'رياضة', 'ممارسة الرياضة', 'Exercise', 4),
      ('🚶', 'مشي نص ساعة', 'المشي نصف ساعة', 'Walk 30 minutes', 5),
      ('💧', 'موية كفاية', 'شرب كمية كافية من الماء', 'Drink enough water', 7),
      ('😴', 'نوم بدري', 'النوم المبكر', 'Sleep early', 6),
      ('🛍️', 'ما تشتري حاجة ما محتاجها', 'لا تشترِ ما لا تحتاجه', 'No impulse buying', 7),
      ('💰', 'وفّر قروش كل يوم', 'ادّخار مبلغ يومي', 'Save a little every day', 7),
      ('📚', 'قراية 10 صفحات', 'قراءة 10 صفحات', 'Read 10 pages', 5),
      ('🤝', 'كلّم زول من أهلك', 'صلة الرحم باتصال', 'Call a relative', 3),
      ('📵', 'ساعة بلا موبايل', 'ساعة بدون هاتف', 'One phone-free hour', 7),
      ('🌙', 'صيام الاتنين والخميس', 'صيام الاثنين والخميس', 'Fast Mondays & Thursdays', 2),
      ('🚭', 'بلا سجاير', 'الامتناع عن التدخين', 'No smoking', 7),
      ('🍬', 'قلّل السكر في الشاي', 'تقليل السكر', 'Less sugar', 7),
      ('🧹', 'رتّب البيت', 'ترتيب المنزل', 'Tidy up the house', 3),
    ];

const _emojis = ['✅', '🕌', '📖', '📿', '🏃', '🚶', '💧', '😴', '🛍️', '💰', '📚', '🤝', '📵', '🌙', '🚭', '🍬', '🧹', '🥗', '🍎', '🧘', '✍️', '🎯', '🌱', '💪', '☕', '🦷', '💊', '🎓', '🧠', '❤️'];

class HabitsTool extends StatefulWidget {
  const HabitsTool({super.key});
  @override
  State<HabitsTool> createState() => _HabitsToolState();
}

class _HabitsToolState extends State<HabitsTool> {
  /// العادة المعروضة في الخريطة الحرارية (null = الكل)
  String? _heatId;

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('habits_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('habits_list', l);

  Set<String> _done(Map h) => Set<String>.from((h['done'] as List?) ?? const []);

  int _streak(Set<String> done, DateTime today) {
    var d = done.contains(dk(today)) ? today : today.subtract(const Duration(days: 1));
    var n = 0;
    while (done.contains(dk(d)) && n < 1000) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  int _best(Set<String> done) {
    final days = done.map(parseDk).whereType<DateTime>().toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && dayDiff(prev, d) == 1) ? run + 1 : 1;
      best = math.max(best, run);
      prev = d;
    }
    return best;
  }

  int _countIn(Set<String> done, DateTime today, int days) {
    var n = 0;
    for (var i = 0; i < days; i++) {
      if (done.contains(dk(DateTime(today.year, today.month, today.day - i)))) n++;
    }
    return n;
  }

  double _weekPct(Map h, DateTime today) => (_countIn(_done(h), today, 7) / math.max(1, intOf(h['target'], 7))).clamp(0, 1).toDouble();
  double _monthPct(Map h, DateTime today) =>
      (_countIn(_done(h), today, 30) / math.max(1, intOf(h['target'], 7) * 30 / 7)).clamp(0, 1).toDouble();

  void _toggle(String id, DateTime d) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((h) => h['id'] == id);
    if (i < 0) return;
    final h = l[i];
    final done = List<String>.from((h['done'] as List?) ?? const []);
    final k = dk(d);
    final adding = !done.contains(k);
    adding ? done.add(k) : done.remove(k);
    done.sort();
    if (done.length > 420) done.removeRange(0, done.length - 420);
    h['done'] = done;
    _save(s, l);
    if (adding) {
      HapticFeedback.lightImpact();
      s.awardDaily('habit_$id', 5, '${tr('عادة', 'Habit')}: ${h['name']}');
      final today = todayPlace();
      final st = _streak(done.toSet(), today);
      if (st >= 7) {
        final s7 = List<String>.from(s.getData<List>('habits_s7') ?? const []);
        if (!s7.contains(id)) {
          s7.add(id);
          s.setData('habits_s7', s7);
          s.bump('habit_streak7');
          toast(t('🔥 أسبوع كامل ورا بعض في «${h['name']}»! عافي منك', '🔥 أسبوع كامل متواصل في «${h['name']}»! أحسنت',
              '🔥 7-day streak on “${h['name']}”! Well done'));
        }
      }
      if (dk(d) == dk(today) && l.every((x) => _done(x).contains(dk(today)))) {
        toast(t('🎉 كمّلت كل عاداتك الليلة! يا سلام', '🎉 أنجزت جميع عاداتك اليوم! رائع', '🎉 All habits done today! Amazing'));
      }
    }
    setState(() {});
  }

  Future<void> _edit([Map<String, dynamic>? h, _Sug? sug]) async {
    final s = context.read<AppState>();
    final nameC = TextEditingController(text: h?['name'] ?? (sug == null ? '' : t(sug.$2, sug.$3, sug.$4)));
    final remC = TextEditingController(text: h?['rem'] ?? '');
    var emoji = (h?['emoji'] as String?) ?? sug?.$1 ?? '✅';
    var color = intOf(h?['color'], _list(s).length % lifePalette.length);
    var target = intOf(h?['target'], sug?.$5 ?? 7);
    final ok = await lifeSheet<bool>(
      context,
      h == null ? t('عادة جديدة', 'عادة جديدة', 'New habit') : t('عدّل العادة', 'تعديل العادة', 'Edit habit'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: nameC,
          autofocus: h == null && sug == null,
          decoration: InputDecoration(labelText: t('اسم العادة', 'اسم العادة', 'Habit name'), hintText: t('مثلًا: قراية جزء', 'مثلًا: قراءة جزء', 'e.g. Read 10 pages')),
        ),
        const SizedBox(height: 14),
        Text(t('الشكل', 'الرمز', 'Icon'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final e in _emojis)
            InkWell(
              onTap: () => set(() => emoji = e),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: e == emoji ? palette(color).withValues(alpha: .3) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: e == emoji ? palette(color) : Colors.transparent, width: 2),
                ),
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        Text(t('اللون', 'اللون', 'Color'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ColorDots(color, (v) => set(() => color = v)),
        const SizedBox(height: 14),
        Text(
          '${t('الهدف', 'الهدف', 'Target')}: ${target == 7 ? t('كل يوم', 'يوميًا', 'every day') : t('$target أيام في الأسبوع', '$target أيام أسبوعيًا', '$target days a week')}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Slider(value: target.toDouble(), min: 1, max: 7, divisions: 6, label: '$target', onChanged: (v) => set(() => target = v.round())),
        Row(children: [
          Expanded(
            child: TextField(
              controller: remC,
              decoration: InputDecoration(
                labelText: t('وقت التذكير (اختياري)', 'وقت التذكير (اختياري)', 'Reminder time (optional)'),
                hintText: t('بعد الفجر، 9:00 م…', 'بعد الفجر، 9:00 م…', 'After Fajr, 9:00 PM…'),
              ),
            ),
          ),
          IconButton(
            tooltip: t('اختار ساعة', 'اختيار الوقت', 'Pick time'),
            icon: const Icon(Icons.schedule_rounded),
            onPressed: () async {
              final tm = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 21, minute: 0));
              if (tm != null) {
                final now = DateTime.now();
                set(() => remC.text = fmtTimeAr(DateTime(now.year, now.month, now.day, tm.hour, tm.minute)));
              }
            },
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          if (h != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسحها', 'حذف', 'Delete')),
              ),
            ),
          if (h != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم العادة', 'اكتب اسم العادة', 'Enter a habit name'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save')),
            ),
          ),
        ]),
      ]),
    );
    final name = nameC.text.trim(), rem = remC.text.trim();
    nameC.dispose();
    remC.dispose();
    if (!mounted || ok == null) return;
    final l = _list(s);
    if (ok == false && h != null) {
      if (!await confirmAsk(context, t('نمسح العادة؟', 'حذف العادة؟', 'Delete habit?'),
          t('حيتمسح «${h['name']}» مع كل سجلها.', 'سيُحذف «${h['name']}» مع كامل سجله.', '“${h['name']}” and its history will be deleted.'))) {
        return;
      }
      final idx = l.indexWhere((x) => x['id'] == h['id']);
      if (idx < 0) return;
      final removed = l.removeAt(idx);
      _save(s, l);
      undoSnack(t('اتمسحت العادة', 'حُذفت العادة', 'Habit deleted'), () {
        final l2 = _list(s)..insert(math.min(idx, _list(s).length), removed);
        _save(s, l2);
      });
      setState(() {});
      return;
    }
    if (h == null) {
      l.add({'id': newId(), 'name': name, 'emoji': emoji, 'color': color, 'target': target, 'rem': rem, 'created': dk(todayPlace()), 'done': <String>[]});
      s.award(2, tr('عادة جديدة', 'New habit'));
    } else {
      final idx = l.indexWhere((x) => x['id'] == h['id']);
      if (idx >= 0) l[idx] = {...l[idx], 'name': name, 'emoji': emoji, 'color': color, 'target': target, 'rem': rem};
    }
    _save(s, l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = _list(s);
    final today = todayPlace();
    final tk = dk(today);
    final doneToday = l.where((h) => _done(h).contains(tk)).length;
    final p = l.isEmpty ? 0.0 : doneToday / l.length;
    final bestCur = l.isEmpty ? 0 : l.map((h) => _streak(_done(h), today)).reduce(math.max);
    final weekAvg = l.isEmpty ? 0.0 : l.map((h) => _weekPct(h, today)).reduce((a, b) => a + b) / l.length;
    final monthAvg = l.isEmpty ? 0.0 : l.map((h) => _monthPct(h, today)).reduce((a, b) => a + b) / l.length;
    final checks30 = l.fold<int>(0, (a, h) => a + _countIn(_done(h), today, 30));
    final existing = l.map((h) => h['name']).toSet();

    return ToolList(children: [
      SCard(
        color: SD.green,
        child: Column(children: [
          ProgressRing(
            progress: p,
            color: p >= 1 ? SD.teal : SD.green,
            size: 180,
            stroke: 14,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🌱', style: TextStyle(fontSize: 26)),
              Text('$doneToday/${l.length}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: readable(context, SD.green))),
              Text(t('عادات الليلة', 'عادات اليوم', 'today'), style: const TextStyle(fontSize: 12.5)),
            ]),
          ),
          const SizedBox(height: 10),
          Text(
            l.isEmpty
                ? t('لسه ما عندك عادات — ابدا بواحدة صغيرة', 'لا توجد عادات بعد — ابدأ بعادة صغيرة', 'No habits yet — start with a small one')
                : p >= 1
                    ? t('كمّلت كل حاجة الليلة 👏 عافي منك', 'أنجزت كل شيء اليوم 👏', 'Everything done today 👏')
                    : t('فاضل ليك ${l.length - doneToday} — يلا شد حيلك', 'متبقٍ ${l.length - doneToday} — واصل', '${l.length - doneToday} left — keep going'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add_rounded), label: Text(t('ضيف عادة', 'إضافة عادة', 'Add habit'))),
        ]),
      ),
      if (l.isNotEmpty)
        StatGrid([
          StatChip('$bestCur', t('أطول سلسلة هسي', 'أطول سلسلة حالية', 'Best current streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
          StatChip('${fmt(weekAvg * 100, 0)}%', t('إنجاز الأسبوع', 'إنجاز الأسبوع', 'This week'), color: SD.green, icon: Icons.date_range_rounded),
          StatChip('${fmt(monthAvg * 100, 0)}%', t('إنجاز الشهر', 'إنجاز الشهر', 'Last 30 days'), color: SD.nile, icon: Icons.calendar_month_rounded),
        ]),
      if (l.isNotEmpty) const SizedBox(height: 12),
      for (final h in l) _habitCard(h, today),
      if (l.isNotEmpty) ...[
        SCard(
          title: t('خريطة آخر 30 يوم', 'خريطة آخر 30 يومًا', 'Last 30 days'),
          icon: Icons.grid_on_rounded,
          color: SD.teal,
          trailing: Text(t('$checks30 مرة', '$checks30 مرة', '$checks30 check-ins'), style: const TextStyle(fontSize: 12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: PickChip(t('الكل', 'الكل', 'All'), _heatId == null, () => setState(() => _heatId = null), color: SD.teal),
                ),
                for (final h in l)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: PickChip('${h['emoji']} ${h['name']}', _heatId == h['id'], () => setState(() => _heatId = h['id']), color: palette(h['color'])),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            _heatmap(l, today),
            const SizedBox(height: 6),
            Text(t('كل ما اللون أغمق كل ما أنجزت أكتر', 'كلما كان اللون أغمق كان الإنجاز أكبر', 'Darker = more done'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
          ]),
        ),
        SCard(
          title: t('الأسبوع', 'الأسبوع', 'This week'),
          icon: Icons.bar_chart_rounded,
          color: SD.green,
          child: BarChart([
            for (var i = 6; i >= 0; i--)
              () {
                final d = DateTime(today.year, today.month, today.day - i);
                final n = l.where((h) => _done(h).contains(dk(d))).length;
                return Bar(i == 0 ? t('الليلة', 'اليوم', 'Today') : shortDaysL[d.weekday - 1], n.toDouble(),
                    color: n == l.length ? SD.teal : SD.green);
              }(),
          ], maxValue: l.length.toDouble(), color: SD.green, valueText: (v) => v == 0 ? '' : fmt(v, 0)),
        ),
        SCard(
          title: t('التقرير', 'التقرير', 'Report'),
          icon: Icons.insights_rounded,
          color: SD.nile,
          child: MiniTable(
            [t('العادة', 'العادة', 'Habit'), '🔥', t('الأحسن', 'الأفضل', 'Best'), t('الأسبوع', 'الأسبوع', 'Week'), t('الشهر', 'الشهر', 'Month')],
            [
              for (final h in l)
                [
                  '${h['emoji']} ${h['name']}',
                  '${_streak(_done(h), today)}',
                  '${_best(_done(h))}',
                  '${fmt(_weekPct(h, today) * 100, 0)}%',
                  '${fmt(_monthPct(h, today) * 100, 0)}%',
                ],
            ],
            color: SD.nile,
          ),
        ),
      ],
      SCard(
        title: t('عادات مقترحة', 'عادات مقترحة', 'Suggested habits'),
        icon: Icons.auto_awesome_rounded,
        color: SD.gold,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final sg in _suggestions)
            if (!existing.contains(t(sg.$2, sg.$3, sg.$4)))
              ActionChip(
                avatar: Text(sg.$1),
                label: Text(t(sg.$2, sg.$3, sg.$4)),
                backgroundColor: SD.gold.withValues(alpha: .10),
                side: BorderSide(color: SD.gold.withValues(alpha: .4)),
                onPressed: () => _edit(null, sg),
              ),
        ]),
      ),
      NoteBox(
        t('السر في الاستمرار مش الكترة: ابدا بعادة أو اتنين صغار، وما تكسر السلسلة يومين ورا بعض. لو فاتك يوم سجّلو من الدواير فوق.',
            'سرّ النجاح في الاستمرار لا الكثرة: ابدأ بعادة أو اثنتين صغيرتين، ولا تقطع السلسلة يومين متتاليين. يمكنك تسجيل الأيام الفائتة من الدوائر.',
            'Consistency beats quantity: start with one or two small habits and never miss two days in a row. Tap the circles to log missed days.'),
        kind: NoteKind.tip,
      ),
    ]);
  }

  Widget _habitCard(Map<String, dynamic> h, DateTime today) {
    final c = palette(h['color']);
    final done = _done(h);
    final st = _streak(done, today);
    final target = intOf(h['target'], 7);
    final wk = _countIn(done, today, 7);
    final rem = (h['rem'] as String?) ?? '';
    final todayDone = done.contains(dk(today));
    return SCard(
      color: c,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          InkWell(
            onTap: () => _toggle(h['id'], today),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: todayDone ? c : c.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c, width: 2),
              ),
              child: todayDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 30) : Text('${h['emoji']}', style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${h['name']}', style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
              Text(
                [
                  target == 7 ? t('كل يوم', 'يوميًا', 'Daily') : t('$target أيام/أسبوع', '$target أيام/أسبوع', '$target days/week'),
                  if (rem.isNotEmpty) '⏰ $rem',
                ].join(' · '),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
              ),
            ]),
          ),
          if (st > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: SD.orange.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)),
              child: Text('🔥 $st', style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.orange))),
            ),
          IconButton(tooltip: t('عدّل', 'تعديل', 'Edit'), onPressed: () => _edit(h), icon: const Icon(Icons.more_vert_rounded)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 6; i >= 0; i--)
            Expanded(child: _dayDot(h['id'], DateTime(today.year, today.month, today.day - i), done, c, i == 0)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (wk / target).clamp(0, 1).toDouble(), minHeight: 7, color: c, backgroundColor: c.withValues(alpha: .14)),
            ),
          ),
          const SizedBox(width: 10),
          Text(t('$wk/$target الأسبوع', '$wk/$target هذا الأسبوع', '$wk/$target this week'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _dayDot(String id, DateTime d, Set<String> done, Color c, bool isToday) {
    final on = done.contains(dk(d));
    return InkWell(
      onTap: () => _toggle(id, d),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(children: [
          Text(isToday ? t('الليلة', 'اليوم', 'Today') : shortDaysL[d.weekday - 1],
              style: TextStyle(fontSize: 10.5, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500)),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? c : Colors.transparent,
              border: Border.all(color: on ? c : c.withValues(alpha: .45), width: isToday ? 2.4 : 1.4),
            ),
            child: on
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text('${d.day}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _heatmap(List<Map<String, dynamic>> l, DateTime today) {
    final vals = <double>[];
    final sel = _heatId == null ? null : l.where((h) => h['id'] == _heatId).firstOrNull;
    for (var i = 29; i >= 0; i--) {
      final k = dk(DateTime(today.year, today.month, today.day - i));
      if (sel != null) {
        vals.add(_done(sel).contains(k) ? 1 : 0);
      } else {
        final n = l.where((h) => _done(h).contains(k)).length;
        vals.add(l.isEmpty ? 0 : n / l.length);
      }
    }
    final color = sel == null ? SD.teal : palette(sel['color']);
    final start = DateTime(today.year, today.month, today.day - 29);
    // الأسبوع يبدأ السبت: السبت=0 … الجمعة=6
    final offset = (start.weekday + 1) % 7;
    final rows = ((offset + 30) / 7).ceil();
    final headers = [for (final w in [6, 7, 1, 2, 3, 4, 5]) shortDaysL[w - 1]];
    return LayoutBuilder(builder: (ctx, cons) {
      final cell = cons.maxWidth / 7;
      return SizedBox(
        width: cons.maxWidth,
        height: 20 + rows * cell,
        child: CustomPaint(
          painter: _HeatPainter(
            vals: vals,
            start: start,
            offset: offset,
            headers: headers,
            color: color,
            on: Theme.of(ctx).colorScheme.onSurface,
            rtl: Directionality.of(ctx) == TextDirection.rtl,
          ),
        ),
      );
    });
  }
}

class _HeatPainter extends CustomPainter {
  final List<double> vals;
  final DateTime start;
  final int offset;
  final List<String> headers;
  final Color color, on;
  final bool rtl;
  _HeatPainter({required this.vals, required this.start, required this.offset, required this.headers, required this.color, required this.on, required this.rtl});

  void _text(Canvas c, String s, Offset center, double size, Color col, {FontWeight w = FontWeight.w600}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: col, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 7;
    double colX(int col) => (rtl ? 6 - col : col) * cell;
    for (var c = 0; c < 7; c++) {
      _text(canvas, headers[c], Offset(colX(c) + cell / 2, 9), 10, on.withValues(alpha: .65));
    }
    for (var i = 0; i < vals.length; i++) {
      final pos = offset + i;
      final col = pos % 7, row = pos ~/ 7;
      final r = Rect.fromLTWH(colX(col) + 3, 20 + row * cell + 3, cell - 6, cell - 6);
      final v = vals[i].clamp(0.0, 1.0);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = on.withValues(alpha: .06));
      if (v > 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = color.withValues(alpha: .25 + .75 * v));
      }
      final d = DateTime(start.year, start.month, start.day + i);
      final isToday = i == vals.length - 1;
      if (isToday) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(8)),
            Paint()
              ..color = SD.gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
      _text(canvas, '${d.day}', r.center, math.min(12, cell * .3), v > .5 ? Colors.white : on.withValues(alpha: .7),
          w: isToday ? FontWeight.w800 : FontWeight.w600);
    }
  }

  @override
  bool shouldRepaint(covariant _HeatPainter old) => true;
}
