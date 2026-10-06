import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'writer_common.dart';
import 'writer_data.dart';
import 'writer_paint.dart';

/// تبويب الإحصائيات: الهدف اليومي، السلسلة، الأسبوع، وجلسة الكتابة المركّزة
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});
  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  Timer? _tick;
  int _len = 25;

  Map<String, dynamic> _sprint(AppState s) => Map<String, dynamic>.from(s.getData<Map>('writer_sprint') ?? const {});

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _len = intOf(_sprint(s)['min'], 25);
    if (_sprint(s)['end'] != null) _startTick();
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      final sp = _sprint(s);
      final end = sp['end'];
      if (end is! num) {
        _tick?.cancel();
        return;
      }
      if (DateTime.now().millisecondsSinceEpoch >= end) {
        _finish(s, done: true);
      } else {
        setState(() {});
      }
    });
  }

  void _start(AppState s) {
    final st = WStore(s);
    s.setData('writer_sprint', {
      'end': DateTime.now().add(Duration(minutes: _len)).millisecondsSinceEpoch,
      'min': _len,
      'w0': st.today,
      'd0': dk(todayPlace()),
    });
    _startTick();
  }

  void _finish(AppState s, {required bool done}) {
    _tick?.cancel();
    final sp = _sprint(s);
    final st = WStore(s);
    final written = sp['d0'] == dk(todayPlace()) ? st.today - intOf(sp['w0']) : st.today;
    s.setData('writer_sprint', {'min': _len, 'last': written});
    if (done) {
      s.award(10, t('خلصت جلسة كتابة', 'إتمام جلسة كتابة', 'Finished a writing sprint'));
      s.bump('writer_sprints');
      toast(t('⏰ الجلسة خلصت! كتبت $written كلمة', '⏰ انتهت الجلسة! كتبت $written كلمة', '⏰ Sprint over! You wrote $written words'));
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _customGoal(WStore st) async {
    final v = await askText(context, t('هدفك اليومي (كلمات)', 'الهدف اليومي (كلمات)', 'Daily goal (words)'), initial: '${st.dailyGoal}', number: true);
    if (v == null) return;
    final n = parseNum(v).round();
    if (n > 0) st.dailyGoal = n;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = WStore(s);
    final goal = st.dailyGoal;
    final today = st.today;
    final now = todayPlace();
    final week = [
      for (var i = 6; i >= 0; i--)
        (shortDay(now.subtract(Duration(days: i))), st.wordsOn(now.subtract(Duration(days: i)))),
    ];
    final projects = st.projects;
    final total = projects.fold<int>(0, (a, p) => a + projectWords(p));
    final sp = _sprint(s);
    final end = sp['end'];
    final running = end is num;
    final left = running ? Duration(milliseconds: (end.toInt() - DateTime.now().millisecondsSinceEpoch).clamp(0, 1 << 31)) : Duration.zero;
    final sprintWords = running ? (sp['d0'] == dk(now) ? today - intOf(sp['w0']) : today) : intOf(sp['last']);
    return ToolList(children: [
      ResultHero(
        label: t('كلمات النهارده', 'كلمات اليوم', 'Words today'),
        value: fmt(today, 0),
        sub: goal > 0
            ? (today >= goal
                ? t('🎉 حققت هدفك ($goal)', '🎉 حققت هدفك ($goal)', '🎉 Goal reached ($goal)')
                : '${t('فاضل', 'متبقٍ', 'Left')} ${fmt(goal - today, 0)} ${tr('من', 'of')} $goal')
            : null,
        colors: const [SD.purple, SD.indigo, SD.brownDeep],
      ),
      if (goal > 0) ...[WProgress(today / goal, color: today >= goal ? SD.green : SD.purple), const SizedBox(height: 14)],
      StatGrid([
        StatChip(fmt(st.week, 0), t('الأسبوع', 'هذا الأسبوع', 'This week'), color: SD.nile, icon: Icons.date_range_rounded),
        StatChip('${st.streak}', t('أيام ورا بعض', 'أيام متتالية', 'Day streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
        StatChip(fmt(total, 0), t('كل الكلمات', 'إجمالي الكلمات', 'Total words'), color: SD.purple, icon: Icons.notes_rounded),
        StatChip('${projects.length}', t('مشاريع', 'مشاريع', 'Projects'), color: SD.teal, icon: Icons.collections_bookmark_rounded),
        StatChip(fmt(s.counter('words_written'), 0), t('كتبتها هنا', 'كُتبت هنا', 'Written here'), color: SD.green, icon: Icons.edit_rounded),
        StatChip('${s.counter('writer_sprints')}', t('جلسات', 'جلسات', 'Sprints'), color: SD.henna, icon: Icons.timer_rounded),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('آخر 7 أيام', 'آخر 7 أيام', 'Last 7 days'),
        icon: Icons.bar_chart_rounded,
        color: SD.purple,
        child: WeekBars(week, goal),
      ),
      SCard(
        title: t('جلسة كتابة مركّزة', 'جلسة كتابة مركّزة', 'Writing sprint'),
        icon: Icons.timer_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                running ? '${two(left.inMinutes)}:${two(left.inSeconds % 60)}' : '${two(_len)}:00',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: readable(context, SD.henna), fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
          Text(
            running
                ? '${t('كتبت في الجلسة', 'كتبت في الجلسة', 'Written this sprint')}: $sprintWords'
                : (sp['last'] != null ? '${t('الجلسة الفاتت', 'الجلسة السابقة', 'Last sprint')}: $sprintWords ${tr('كلمة', 'words')}' : t('اكتب بدون توقف لحدي ما الوقت يخلص.', 'اكتب دون توقف حتى ينتهي الوقت.', 'Write without stopping until time is up.')),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (!running)
            Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
              for (final m in const [15, 25, 45]) PickChip('$m ${tr('د', 'min')}', _len == m, () => setState(() => _len = m), color: SD.henna),
            ]),
          const SizedBox(height: 10),
          running
              ? OutlinedButton.icon(
                  onPressed: () => _finish(s, done: false),
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(t('وقّف الجلسة', 'إيقاف الجلسة', 'Stop sprint')),
                )
              : FilledButton.icon(
                  onPressed: () => _start(s),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(t('ابدأ الجلسة', 'ابدأ الجلسة', 'Start sprint')),
                ),
          const SizedBox(height: 6),
          Text(
            t('افتح أي مشهد واكتب — الكلمات بتتحسب براها.', 'افتح أي مشهد واكتب — تُحتسب الكلمات تلقائيًا.', 'Open any scene and write — words are counted automatically.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5),
          ),
        ]),
      ),
      SCard(
        title: t('الهدف اليومي', 'الهدف اليومي', 'Daily goal'),
        icon: Icons.flag_rounded,
        color: SD.green,
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final g in const [250, 500, 1000, 1500, 2000]) PickChip('$g', goal == g, () => st.dailyGoal = g, color: SD.green),
          ActionChip(avatar: const Icon(Icons.edit_rounded, size: 16), label: Text(t('غيرو', 'مخصص', 'Custom')), onPressed: () => _customGoal(st)),
        ]),
      ),
      NoteBox(
        t('الكلمات بتتحسب لما تزيد نص المشهد (المسح ما بنقّص العداد). بتاخد نقاط لما تكتب كل يوم ولما تحقق هدفك.',
            'تُحتسب الكلمات عند زيادة نص المشهد (الحذف لا يُنقص العداد). تحصل على نقاط عند الكتابة يوميًا وعند تحقيق الهدف.',
            'Words count when a scene grows (deleting does not reduce the tally). You earn points for writing daily and hitting your goal.'),
        kind: NoteKind.tip,
      ),
    ]);
  }
}

String shortDay(DateTime d) => isEn ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1] : const ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'][d.weekday - 1];
