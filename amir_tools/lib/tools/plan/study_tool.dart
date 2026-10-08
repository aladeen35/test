import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'plan_common.dart';
import 'study_notify.dart';

String _diffName(int d) => switch (d) {
      1 => t('ساهلة', 'سهلة', 'Easy'),
      3 => t('صعبة', 'صعبة', 'Hard'),
      _ => t('وسط', 'متوسطة', 'Medium'),
    };

String fmtMins(int m) => fmtTimeAr(DateTime(2000, 1, 1, (m ~/ 60) % 24, m % 60));

/// يوزّع جلسات المراجعة من [from] حتى الامتحانات، بأوزان الصعوبة وقرب الامتحان.
/// منطق خالص قابل للاختبار.
List<Map<String, dynamic>> generateRevision(List<Map<String, dynamic>> subjects, DateTime from,
    {int perDay = 3, int dur = 60, int startMin = 16 * 60, int gap = 15, int maxDays = 120}) {
  final withExam = [
    for (final s in subjects)
      if (parseDk(s['exam']) != null && parseDk(s['exam'])!.isAfter(from)) s
  ];
  if (withExam.isEmpty || perDay <= 0) return [];
  final last = withExam.map((s) => parseDk(s['exam'])!).reduce((a, b) => a.isAfter(b) ? a : b);
  final assigned = <String, int>{};
  final out = <Map<String, dynamic>>[];
  for (var d = from; d.isBefore(last) && dayDiff(from, d) < maxDays; d = DateTime(d.year, d.month, d.day + 1)) {
    final cands = [for (final s in withExam) if (parseDk(s['exam'])!.isAfter(d)) s];
    if (cands.isEmpty) continue;
    final today = <String>[];
    // اليوم السابق للامتحان: الأولوية لمادته
    for (final s in cands) {
      if (dayDiff(d, parseDk(s['exam'])!) == 1 && today.length < perDay) today.add('${s['id']}');
    }
    while (today.length < perDay) {
      Map<String, dynamic>? best;
      var bestScore = -1.0;
      final pool = cands.where((s) => !today.contains('${s['id']}')).toList();
      for (final s in (pool.isEmpty ? cands : pool)) {
        final days = dayDiff(d, parseDk(s['exam'])!);
        final diff = intOf(s['diff'], 2).clamp(1, 3);
        final score = diff * (1 + 7 / (days < 1 ? 1 : days)) / ((assigned['${s['id']}'] ?? 0) + 1);
        if (score > bestScore) {
          bestScore = score;
          best = s;
        }
      }
      if (best == null) break;
      today.add('${best['id']}');
      assigned['${best['id']}'] = (assigned['${best['id']}'] ?? 0) + 1;
    }
    for (var k = 0; k < today.length; k++) {
      out.add({'id': 'r${dk(d)}_$k', 'sub': today[k], 'd': dk(d), 'm': startMin + k * (dur + gap), 'dur': dur, 'done': false, 'auto': true});
    }
  }
  return out;
}

class StudyPlanTool extends StatefulWidget {
  const StudyPlanTool({super.key});
  @override
  State<StudyPlanTool> createState() => _StudyPlanToolState();
}

class _StudyPlanToolState extends State<StudyPlanTool> {
  @override
  void initState() {
    super.initState();
    // تجديد نافذة الأسبوعين للتنبيهات عند فتح الأداة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (_d(s)['notify'] == true) StudyNotifications.reschedule(s);
    });
  }

  Map<String, dynamic> _d(AppState s) => Map<String, dynamic>.from(s.getData<Map>('study_plan') ?? const {});
  void _set(AppState s, Map<String, dynamic> patch, {bool resched = false}) {
    s.setData('study_plan', {..._d(s), ...patch});
    if (resched && _d(s)['notify'] == true) StudyNotifications.reschedule(s);
  }

  List<Map<String, dynamic>> _subs(AppState s) => mapList(_d(s)['subjects']);
  Map<String, dynamic>? _sub(AppState s, String? id) {
    for (final x in _subs(s)) {
      if (x['id'] == id) return x;
    }
    return null;
  }

  Future<void> _editSubject([Map<String, dynamic>? sb]) async {
    final s = context.read<AppState>();
    final nC = TextEditingController(text: sb?['n'] ?? '');
    var color = intOf(sb?['c'], _subs(s).length);
    var diff = intOf(sb?['diff'], 2);
    DateTime? exam = parseDk(sb?['exam']);
    final today = todayPlace();
    final ok = await lifeSheet<bool>(
      context,
      sb == null ? t('مادة جديدة', 'مادة جديدة', 'New subject') : t('عدّل المادة', 'تعديل المادة', 'Edit subject'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nC, decoration: InputDecoration(labelText: t('اسم المادة', 'اسم المادة', 'Subject name'), hintText: t('رياضيات، كيمياء، إنجليزي…', 'رياضيات، كيمياء…', 'Maths, chemistry…'))),
        const SizedBox(height: 12),
        Text(t('صعوبتها عليك', 'درجة الصعوبة', 'Difficulty'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [
          for (final v in [1, 2, 3]) PickChip(_diffName(v), diff == v, () => set(() => diff = v), color: [SD.green, SD.gold, SD.red][v - 1]),
        ]),
        const SizedBox(height: 12),
        LifeDateButton(label: t('يوم الامتحان', 'تاريخ الامتحان', 'Exam date'), value: exam, clearable: true, first: today, last: DateTime(today.year + 2), color: SD.red, onPick: (d) => set(() => exam = d)),
        const SizedBox(height: 12),
        ColorDots(color, (v) => set(() => color = v)),
        const SizedBox(height: 16),
        sheetButtons(ctx, onSave: () {
          if (nC.text.trim().isEmpty) return toast(t('أكتب اسم المادة', 'اكتب اسم المادة', 'Enter the subject name'));
          Navigator.pop(ctx, true);
        }, onDelete: sb == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final name = nC.text.trim();
    nC.dispose();
    if (!mounted || ok == null) return;
    final l = _subs(s);
    if (ok == false && sb != null) {
      if (!await confirmAsk(context, t('تمسح المادة؟', 'حذف المادة؟', 'Delete subject?'), t('حصصها وجلساتها بتتمسح معاها', 'ستُحذف حصصها وجلساتها أيضًا', 'Its sessions will be removed too'))) return;
      l.removeWhere((x) => x['id'] == sb['id']);
      final d = _d(s);
      _set(s, {
        'subjects': l,
        'weekly': mapList(d['weekly']).where((x) => x['sub'] != sb['id']).toList(),
        'sessions': mapList(d['sessions']).where((x) => x['sub'] != sb['id']).toList(),
      }, resched: true);
      return;
    }
    final data = {'n': name, 'c': color, 'diff': diff, 'exam': exam == null ? null : dk(exam!)};
    if (sb == null) {
      l.add({'id': newId(), ...data});
    } else {
      final i = l.indexWhere((x) => x['id'] == sb['id']);
      if (i >= 0) l[i] = {...l[i], ...data};
    }
    _set(s, {'subjects': l});
  }

  Future<int?> _pickTime(int init, String help) async {
    final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: init ~/ 60, minute: init % 60), helpText: help);
    return r == null ? null : r.hour * 60 + r.minute;
  }

  Future<void> _editSlot([Map<String, dynamic>? w]) async {
    final s = context.read<AppState>();
    final subs = _subs(s);
    if (subs.isEmpty) return toast(t('أضف مادة أول', 'أضف مادة أولًا', 'Add a subject first'));
    var sub = (w?['sub'] as String?) ?? '${subs.first['id']}';
    var wd = intOf(w?['wd'], todayPlace().weekday);
    var m = intOf(w?['m'], 17 * 60);
    var dur = intOf(w?['dur'], 60);
    final ok = await lifeSheet<bool>(
      context,
      w == null ? t('حصة أسبوعية', 'حصة أسبوعية', 'Weekly session') : t('عدّل الحصة', 'تعديل الحصة', 'Edit session'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final x in subs) PickChip('${x['n']}', sub == x['id'], () => set(() => sub = '${x['id']}'), color: palette(intOf(x['c']))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 1; i <= 7; i++) PickChip(shortDaysL[i - 1], wd == i, () => set(() => wd = i), color: SD.nile),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final v = await _pickTime(m, t('بداية الحصة', 'وقت البداية', 'Start time'));
            if (v != null) set(() => m = v);
          },
          icon: const Icon(Icons.schedule_rounded),
          label: Text('${t('الوقت', 'الوقت', 'Time')}: ${fmtMins(m)}'),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in [30, 45, 60, 90, 120]) PickChip('$v ${t('د', 'د', 'min')}', dur == v, () => set(() => dur = v), color: SD.teal),
        ]),
        const SizedBox(height: 16),
        sheetButtons(ctx, onSave: () => Navigator.pop(ctx, true), onDelete: w == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    if (!mounted || ok == null) return;
    final l = mapList(_d(s)['weekly']);
    if (ok == false && w != null) {
      l.removeWhere((x) => x['id'] == w['id']);
    } else {
      final data = {'sub': sub, 'wd': wd, 'm': m, 'dur': dur};
      if (w == null) {
        l.add({'id': newId(), ...data});
      } else {
        final i = l.indexWhere((x) => x['id'] == w['id']);
        if (i >= 0) l[i] = {...l[i], ...data};
      }
    }
    l.sort((a, b) => (intOf(a['wd']) * 2000 + intOf(a['m'])).compareTo(intOf(b['wd']) * 2000 + intOf(b['m'])));
    _set(s, {'weekly': l}, resched: true);
  }

  Future<void> _generate() async {
    final s = context.read<AppState>();
    final subs = _subs(s);
    if (!subs.any((x) => parseDk(x['exam']) != null && parseDk(x['exam'])!.isAfter(todayPlace()))) {
      return toast(t('حدّد يوم امتحان لمادة على الأقل', 'حدّد تاريخ امتحان لمادة واحدة على الأقل', 'Set an exam date for at least one subject'));
    }
    final g = Map<String, dynamic>.from(_d(s)['gen'] as Map? ?? const {});
    var perDay = intOf(g['perDay'], 3), dur = intOf(g['dur'], 60), start = intOf(g['start'], 16 * 60);
    var fromTomorrow = g['tomorrow'] == true;
    final ok = await lifeSheet<bool>(
      context,
      t('اعمل لي خطة مراجعة', 'إنشاء خطة مراجعة', 'Build a revision plan'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('جلسات في اليوم', 'عدد الجلسات يوميًا', 'Sessions per day'), style: const TextStyle(fontWeight: FontWeight.w700)),
        Wrap(spacing: 6, children: [for (final v in [1, 2, 3, 4, 5]) PickChip('$v', perDay == v, () => set(() => perDay = v), color: SD.nile)]),
        const SizedBox(height: 10),
        Text(t('مدة الجلسة', 'مدة الجلسة', 'Session length'), style: const TextStyle(fontWeight: FontWeight.w700)),
        Wrap(spacing: 6, children: [for (final v in [30, 45, 60, 90]) PickChip('$v ${t('د', 'د', 'min')}', dur == v, () => set(() => dur = v), color: SD.teal)]),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final v = await _pickTime(start, t('بداية أول جلسة', 'بداية أول جلسة', 'First session starts'));
            if (v != null) set(() => start = v);
          },
          icon: const Icon(Icons.schedule_rounded),
          label: Text('${t('تبدأ', 'تبدأ', 'Starts')}: ${fmtMins(start)}'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: fromTomorrow,
          onChanged: (v) => set(() => fromTomorrow = v),
          title: Text(t('أبدأ من بكرة', 'البدء من الغد', 'Start tomorrow')),
        ),
        Text(t('الخطة بتدي المواد الصعبة والامتحانات القريبة جلسات أكتر، واليوم القبل الامتحان لمادته. الجلسات القديمة التلقائية الما اتعملت بتتبدّل.',
            'تمنح الخطة المواد الأصعب والامتحانات الأقرب جلسات أكثر، واليوم السابق لكل امتحان لمادته. تُستبدل الجلسات التلقائية غير المنجزة.',
            'Harder subjects and nearer exams get more sessions; the day before each exam goes to that subject. Unfinished auto sessions are replaced.'),
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 14),
        sheetButtons(ctx, onSave: () => Navigator.pop(ctx, true)),
      ]),
    );
    if (ok != true || !mounted) return;
    final today = todayPlace();
    final from = fromTomorrow ? today.add(const Duration(days: 1)) : today;
    final keep = mapList(_d(s)['sessions']).where((x) => x['auto'] != true || x['done'] == true || (parseDk(x['d']) ?? today).isBefore(from)).toList();
    final gen = generateRevision(subs, from, perDay: perDay, dur: dur, startMin: start);
    final keepIds = keep.map((e) => e['id']).toSet();
    _set(s, {
      'sessions': [...keep, ...gen.where((e) => !keepIds.contains(e['id']))],
      'gen': {'perDay': perDay, 'dur': dur, 'start': start, 'tomorrow': fromTomorrow},
    }, resched: true);
    s.awardDaily('study_plan_gen', 5, tr('خطة مذاكرة', 'Study plan'));
    toast(t('اتعملت ${gen.length} جلسة ✓', 'أُنشئت ${gen.length} جلسة ✓', '${gen.length} sessions created ✓'));
  }

  void _toggleSession(AppState s, Map<String, dynamic> x) {
    final l = mapList(_d(s)['sessions']);
    final i = l.indexWhere((e) => e['id'] == x['id']);
    if (i < 0) return;
    final done = l[i]['done'] != true;
    l[i] = {...l[i], 'done': done};
    _set(s, {'sessions': l});
    if (done) {
      s.awardDaily('study_done', 5, tr('مذاكرة', 'Study session'));
      s.bump('study_sessions');
      HapticFeedback.selectionClick();
    }
  }

  void _toggleWeekly(AppState s, String key) {
    final l = List<String>.from((_d(s)['doneW'] as List?)?.map((e) => '$e') ?? const <String>[]);
    final done = !l.contains(key);
    if (done) {
      l.add(key);
    } else {
      l.remove(key);
    }
    _set(s, {'doneW': l.length > 500 ? l.sublist(l.length - 500) : l});
    if (done) {
      s.awardDaily('study_done', 5, tr('مذاكرة', 'Study session'));
      s.bump('study_sessions');
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final data = _d(s);
    final subs = _subs(s);
    final weekly = mapList(data['weekly']);
    final sessions = mapList(data['sessions']);
    final doneW = List<String>.from((data['doneW'] as List?)?.map((e) => '$e') ?? const <String>[]);
    final today = todayPlace();
    final todayKey = dk(today);

    // اليوم: الحصص الأسبوعية + جلسات الخطة
    final todayItems = <(String sub, int m, int dur, bool done, VoidCallback toggle)>[
      for (final w in weekly)
        if (intOf(w['wd']) == today.weekday && _sub(s, w['sub']) != null)
          ('${w['sub']}', intOf(w['m']), intOf(w['dur'], 60), doneW.contains('${w['id']}@$todayKey'), () => _toggleWeekly(s, '${w['id']}@$todayKey')),
      for (final x in sessions)
        if (x['d'] == todayKey && _sub(s, x['sub']) != null) ('${x['sub']}', intOf(x['m']), intOf(x['dur'], 60), x['done'] == true, () => _toggleSession(s, x)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    // الإحصاءات: دقائق منجزة لكل مادة
    final mins = <String, int>{};
    final weeklyById = {for (final w in weekly) '${w['id']}': w};
    for (final k in doneW) {
      final w = weeklyById[k.split('@').first];
      if (w != null) mins['${w['sub']}'] = (mins['${w['sub']}'] ?? 0) + intOf(w['dur'], 60);
    }
    for (final x in sessions) {
      if (x['done'] == true) mins['${x['sub']}'] = (mins['${x['sub']}'] ?? 0) + intOf(x['dur'], 60);
    }
    final totalMins = mins.values.fold(0, (a, b) => a + b);
    final maxMins = mins.values.fold(0, (a, b) => b > a ? b : a);
    final weeklyMins = weekly.fold(0, (a, w) => a + intOf(w['dur'], 60));

    final upcoming = sessions.where((x) => (x['d'] as String? ?? '').compareTo(todayKey) > 0 && _sub(s, x['sub']) != null).toList()
      ..sort((a, b) => ('${a['d']}${intOf(a['m']).toString().padLeft(4, '0')}').compareTo('${b['d']}${intOf(b['m']).toString().padLeft(4, '0')}'));
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final x in upcoming) {
      if (byDay.length >= 14 && !byDay.containsKey(x['d'])) break;
      byDay.putIfAbsent('${x['d']}', () => []).add(x);
    }
    final pastPlan = sessions.where((x) => (x['d'] as String? ?? '').compareTo(todayKey) <= 0).toList();
    final pastDone = pastPlan.where((x) => x['done'] == true).length;

    final exams = [for (final x in subs) if (parseDk(x['exam']) != null) x]..sort((a, b) => '${a['exam']}'.compareTo('${b['exam']}'));
    final nextExam = exams.where((x) => !parseDk(x['exam'])!.isBefore(today)).firstOrNull;

    String summary() {
      final b = StringBuffer('📚 ${t('جدول المذاكرة', 'جدول المذاكرة', 'Study plan')}\n');
      if (exams.isNotEmpty) {
        b.writeln('\n${t('الامتحانات', 'الامتحانات', 'Exams')}:');
        for (final x in exams) {
          final d = parseDk(x['exam'])!;
          b.writeln('• ${x['n']}: ${fmtDateAr(d)} (${daysWord(dayDiff(today, d))})');
        }
      }
      if (weekly.isNotEmpty) {
        b.writeln('\n${t('الجدول الأسبوعي', 'الجدول الأسبوعي', 'Weekly timetable')}:');
        for (final w in weekly) {
          b.writeln('• ${weekdaysAr[intOf(w['wd'], 1) - 1]} ${fmtMins(intOf(w['m']))} — ${_sub(s, w['sub'])?['n'] ?? ''} (${intOf(w['dur'], 60)} ${t('د', 'د', 'min')})');
        }
      }
      b.writeln('\n${t('ساعات منجزة', 'ساعات منجزة', 'Hours done')}: ${fmt(totalMins / 60, 1)}');
      return b.toString().trim();
    }

    return ToolList(children: [
      ResultHero(
        label: nextExam == null ? t('جدول المذاكرة', 'جدول المذاكرة', 'Study planner') : '${t('الامتحان الجاي', 'الامتحان القادم', 'Next exam')}: ${nextExam['n']}',
        value: nextExam == null ? '📚' : daysWord(dayDiff(today, parseDk(nextExam['exam'])!)),
        sub: nextExam == null
            ? t('أضف موادك ومواعيد امتحاناتك', 'أضف موادك ومواعيد امتحاناتك', 'Add your subjects and exam dates')
            : '${fmtDateAr(parseDk(nextExam['exam'])!)} · ${fmt(totalMins / 60, 1)} ${t('ساعة مذاكرة منجزة', 'ساعة مذاكرة منجزة', 'study hours done')}',
        colors: const [SD.indigo, SD.nile, SD.teal],
      ),
      SCard(
        title: t('المواد والامتحانات', 'المواد والامتحانات', 'Subjects & exams'),
        icon: Icons.menu_book_rounded,
        color: SD.indigo,
        trailing: IconButton(onPressed: () => _editSubject(), icon: const Icon(Icons.add_rounded), tooltip: t('مادة جديدة', 'مادة جديدة', 'New subject')),
        child: subs.isEmpty
            ? EmptyHint(Icons.school_outlined, t('أضف موادك وحدّد يوم امتحان كل مادة.', 'أضف موادك وحدّد تاريخ امتحان كل مادة.', 'Add your subjects and each exam date.'),
                action: FilledButton.icon(onPressed: () => _editSubject(), icon: const Icon(Icons.add_rounded), label: Text(t('أضف مادة', 'أضف مادة', 'Add subject'))))
            : Column(children: [
                for (final x in subs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _editSubject(x),
                    leading: CircleAvatar(backgroundColor: palette(intOf(x['c'])), radius: 14),
                    title: Text('${x['n']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      [
                        _diffName(intOf(x['diff'], 2)),
                        if (parseDk(x['exam']) != null) '${t('الامتحان', 'الامتحان', 'Exam')} ${fmtShort(parseDk(x['exam'])!)}',
                        '${fmt((mins['${x['id']}'] ?? 0) / 60, 1)} ${t('س', 'س', 'h')}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: parseDk(x['exam']) == null
                        ? null
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 96),
                            child: Tag(daysWord(dayDiff(today, parseDk(x['exam'])!)),
                                color: dayDiff(today, parseDk(x['exam'])!) <= 3 ? SD.red : (dayDiff(today, parseDk(x['exam'])!) <= 10 ? SD.orange : SD.green)),
                          ),
                  ),
              ]),
      ),
      SCard(
        title: t('مذاكرة الليلة', 'جلسات اليوم', "Today's sessions"),
        icon: Icons.today_rounded,
        color: SD.green,
        trailing: todayItems.isEmpty ? null : Tag('${todayItems.where((e) => e.$4).length}/${todayItems.length}', color: SD.green),
        child: todayItems.isEmpty
            ? Text(t('ما في جلسات الليلة — أضف حصص أسبوعية أو اعمل خطة مراجعة.', 'لا جلسات اليوم — أضف حصصًا أسبوعية أو أنشئ خطة مراجعة.', 'No sessions today — add weekly sessions or build a revision plan.'))
            : Column(children: [
                for (final e in todayItems)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: e.$4,
                    onChanged: (_) => e.$5(),
                    activeColor: palette(intOf(_sub(s, e.$1)?['c'])),
                    title: Text('${_sub(s, e.$1)?['n'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, decoration: e.$4 ? TextDecoration.lineThrough : null)),
                    subtitle: Text('${fmtMins(e.$2)} · ${e.$3} ${t('دقيقة', 'دقيقة', 'min')}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ]),
      ),
      SCard(
        title: t('الجدول الأسبوعي', 'الجدول الأسبوعي', 'Weekly timetable'),
        icon: Icons.calendar_view_week_rounded,
        color: SD.nile,
        trailing: IconButton(onPressed: () => _editSlot(), icon: const Icon(Icons.add_rounded), tooltip: t('حصة جديدة', 'حصة جديدة', 'New session')),
        child: weekly.isEmpty
            ? Text(t('أضف حصص ثابتة كل أسبوع (مثلًا: السبت 5 العصر رياضيات).', 'أضف حصصًا ثابتة أسبوعيًا.', 'Add fixed weekly sessions (e.g. Saturday 5 PM maths).'))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var wd = 1; wd <= 7; wd++)
                  if (weekly.any((w) => intOf(w['wd']) == wd))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(
                          width: 48,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(shortDaysL[wd - 1], style: TextStyle(fontWeight: FontWeight.w800, color: wd == today.weekday ? SD.gold : null)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Wrap(spacing: 6, runSpacing: 6, children: [
                            for (final w in weekly.where((w) => intOf(w['wd']) == wd))
                              ActionChip(
                                backgroundColor: palette(intOf(_sub(s, w['sub'])?['c'])).withValues(alpha: .18),
                                label: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 190),
                                  child: Text('${fmtMins(intOf(w['m']))} ${_sub(s, w['sub'])?['n'] ?? '?'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                                ),
                                onPressed: () => _editSlot(w),
                              ),
                          ]),
                        ),
                      ]),
                    ),
                Text('${t('مجموع الأسبوع', 'مجموع الأسبوع', 'Weekly total')}: ${fmt(weeklyMins / 60, 1)} ${t('ساعة', 'ساعة', 'hours')}', style: const TextStyle(fontSize: 12)),
              ]),
      ),
      SCard(
        title: t('خطة المراجعة', 'خطة المراجعة', 'Revision plan'),
        icon: Icons.auto_awesome_rounded,
        color: SD.purple,
        trailing: TextButton(onPressed: _generate, child: Text(t('اعملها', 'إنشاء', 'Build'))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (byDay.isEmpty)
            Text(t('حدّد مواعيد الامتحانات ودوس «اعملها» — بنوزّع ليك المراجعة على الأيام حسب صعوبة كل مادة.',
                'حدّد مواعيد الامتحانات واضغط «إنشاء» لتوزيع المراجعة حسب صعوبة كل مادة.', 'Set exam dates and tap «Build» to spread revision by difficulty.'))
          else
            for (final day in byDay.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Text(fmtDateAr(parseDk(day.key)!), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold)),
              ),
              for (final x in day.value)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: x['done'] == true,
                  onChanged: (_) => _toggleSession(s, x),
                  title: Text('${_sub(s, x['sub'])?['n'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  secondary: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text('${fmtMins(intOf(x['m']))} · ${intOf(x['dur'], 60)}${t('د', 'د', 'm')}', style: const TextStyle(fontSize: 12))),
                  ),
                ),
            ],
          if (pastPlan.isNotEmpty) ...[
            const SizedBox(height: 8),
            PercentBar(t('الالتزام بالخطة لحدي الليلة', 'الالتزام بالخطة حتى اليوم', 'Plan adherence so far'), pastDone / pastPlan.length, '$pastDone/${pastPlan.length}', color: SD.purple),
          ],
          if (sessions.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () async {
                  if (!await confirmAsk(context, t('تمسح خطة المراجعة؟', 'حذف خطة المراجعة؟', 'Clear revision plan?'), t('الجلسات المنجزة بتفضل في الإحصائيات', 'تبقى الجلسات المنجزة في الإحصاءات', 'Completed sessions stay in stats'))) return;
                  _set(s, {'sessions': sessions.where((x) => x['done'] == true).toList()}, resched: true);
                },
                icon: const Icon(Icons.delete_sweep_rounded),
                label: Text(t('امسح الخطة', 'مسح الخطة', 'Clear plan')),
              ),
            ),
        ]),
      ),
      SCard(
        title: t('الإحصائيات', 'الإحصاءات', 'Stats'),
        icon: Icons.bar_chart_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StatGrid([
            StatChip(fmt(totalMins / 60, 1), t('ساعة منجزة', 'ساعة منجزة', 'Hours done'), color: SD.teal),
            StatChip('${subs.length}', t('مادة', 'مادة', 'Subjects'), color: SD.indigo),
            StatChip('${s.counter('study_sessions')}', t('جلسة كمّلتها', 'جلسة مكتملة', 'Sessions done'), color: SD.green),
          ]),
          const SizedBox(height: 8),
          for (final x in subs)
            PercentBar('${x['n']}', maxMins == 0 ? 0 : (mins['${x['id']}'] ?? 0) / maxMins, '${fmt((mins['${x['id']}'] ?? 0) / 60, 1)} ${t('س', 'س', 'h')}', color: palette(intOf(x['c']))),
        ]),
      ),
      SCard(
        title: t('التنبيهات', 'التنبيهات', 'Reminders'),
        icon: Icons.notifications_active_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: data['notify'] == true,
            title: Text(t('نبّهني في وقت المذاكرة', 'نبّهني في وقت الجلسات', 'Remind me at session times')),
            subtitle: Text(t('الحصص الأسبوعية + جلسات الخطة في الأسبوعين الجايين', 'الحصص الأسبوعية وجلسات الخطة للأسبوعين القادمين', 'Weekly sessions + plan sessions for the next 2 weeks'), style: const TextStyle(fontSize: 12)),
            onChanged: (v) async {
              _set(s, {'notify': v});
              if (v) {
                await StudyNotifications.requestPermission();
                final c = await StudyNotifications.reschedule(s);
                if (StudyNotifications.supported) toast(t('اتجدول $c تنبيه ✓', 'جُدول $c تنبيه ✓', '$c reminders scheduled ✓'));
              } else {
                await StudyNotifications.cancel(s);
              }
            },
          ),
          if (!StudyNotifications.supported)
            Text(t('التنبيهات بتشتغل في أندرويد وآيفون بس', 'التنبيهات متاحة على أندرويد وآيفون فقط', 'Reminders work on Android and iOS only'), style: const TextStyle(fontSize: 12))
          else if (data['notify'] == true)
            TextButton.icon(onPressed: StudyNotifications.test, icon: const Icon(Icons.notifications_rounded), label: Text(t('جرّب تنبيه', 'تنبيه تجريبي', 'Test reminder'))),
        ]),
      ),
      if (subs.isNotEmpty) ShareBar(summary),
      const SizedBox(height: 8),
      NoteBox(
        t('ذاكر على دفعات (25–50 دقيقة) مع راحة قصيرة، وراجع بأسئلة الامتحانات القديمة، ونوم كويس قبل الامتحان أحسن من سهر الليل كلو.',
            'ذاكر على فترات (25–50 دقيقة) مع استراحات قصيرة، وتدرّب على أسئلة الامتحانات السابقة، والنوم الجيد قبل الامتحان أفضل من السهر.',
            'Study in blocks (25–50 min) with short breaks, practise past papers, and sleep well before exams rather than pulling all-nighters.'),
        kind: NoteKind.tip,
      ),
    ]);
  }
}
