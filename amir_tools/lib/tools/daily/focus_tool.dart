import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'alarm.dart';
import 'daily_common.dart';

enum _Phase { focus, short, long }

const _lines = [
  'شدّ حيلك يا زول، الشغلة دي بتخلص 💪',
  'قليل دايم ولا كتير منقطع ✨',
  'الموبايل خليهو بعيد شوية… التركيز ذهب 🪙',
  'الصبر مفتاح الفرج 🔑',
  'شوية شوية بنوصل — ما في عجلة 🐢',
  'ركّز هسي، وبعدين اشرب ليك كباية شاي ☕',
  'انت قدرها، والله قدرها 🔥',
  'ابدأ بالبسملة وربنا يوفقك 🤲',
  'جلسة واحدة كمان وتبقى بطل 🏆',
  'العقل زي الأرض، كل ما تزرع فيهو بيطلّع 🌱',
];

class FocusTool extends StatefulWidget {
  const FocusTool({super.key});
  @override
  State<FocusTool> createState() => _FocusToolState();
}

class _FocusToolState extends State<FocusTool> {
  int focusMin = 25, shortMin = 5, longMin = 15, longEvery = 4;
  bool autoStart = false;
  _Phase phase = _Phase.focus;
  int cycle = 0; // جلسات مكتملة في الدورة الحالية
  Duration left = const Duration(minutes: 25);
  DateTime? endAt;
  Timer? _t;
  int lineIdx = 0;
  final taskC = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final c = s.getData<Map>('focus_cfg');
    if (c != null) {
      focusMin = c['f'] ?? 25;
      shortMin = c['s'] ?? 5;
      longMin = c['l'] ?? 15;
      longEvery = c['e'] ?? 4;
      autoStart = c['a'] ?? false;
    }
    left = _len(phase);
    lineIdx = DateTime.now().minute % _lines.length;
  }

  @override
  void dispose() {
    _t?.cancel();
    keepAwake(false);
    Alarm.stop();
    taskC.dispose();
    super.dispose();
  }

  void _saveCfg() => context.read<AppState>().setData('focus_cfg', {'f': focusMin, 's': shortMin, 'l': longMin, 'e': longEvery, 'a': autoStart});

  Duration _len(_Phase p) => Duration(minutes: switch (p) { _Phase.focus => focusMin, _Phase.short => shortMin, _Phase.long => longMin });

  (String, Color, IconData) _meta(_Phase p) => switch (p) {
        _Phase.focus => ('وقت التركيز', SD.henna, Icons.psychology_rounded),
        _Phase.short => ('راحة قصيرة', SD.teal, Icons.local_cafe_rounded),
        _Phase.long => ('راحة طويلة', SD.nile, Icons.self_improvement_rounded),
      };

  bool get running => endAt != null;

  void _start() {
    setState(() => endAt = DateTime.now().add(left));
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    keepAwake(true);
  }

  void _pause() {
    _t?.cancel();
    _t = null;
    setState(() {
      left = endAt!.difference(DateTime.now());
      endAt = null;
    });
    keepAwake(false);
  }

  void _tick() {
    if (!mounted) return;
    final l = endAt!.difference(DateTime.now());
    if (l <= Duration.zero) {
      _t?.cancel();
      _t = null;
      endAt = null;
      keepAwake(false);
      _complete();
    } else {
      setState(() => left = l);
    }
  }

  Map<String, dynamic> get _stats => Map<String, dynamic>.from(context.read<AppState>().getData<Map>('focus_stats') ?? {});

  void _complete({bool skipped = false}) {
    final s = context.read<AppState>();
    if (phase == _Phase.focus) {
      if (!skipped) {
        final st = _stats;
        final k = dkey(DateTime.now());
        final today = Map<String, dynamic>.from(st[k] ?? {'n': 0, 'm': 0});
        today['n'] = (today['n'] as num) + 1;
        today['m'] = (today['m'] as num) + focusMin;
        st[k] = today;
        // نحتفظ بآخر 60 يوم بس
        final keys = st.keys.toList()..sort();
        for (final old in keys.take(keys.length > 60 ? keys.length - 60 : 0)) {
          st.remove(old);
        }
        s.setData('focus_stats', st);
        final log = List<Map>.from(s.getData<List>('focus_log') ?? []);
        log.insert(0, {'t': DateTime.now().millisecondsSinceEpoch, 'm': focusMin, 'task': taskC.text.trim()});
        s.setData('focus_log', log.take(40).toList());
        s.bump('focus_sessions');
        s.award(10, 'جلسة تركيز $focusMin دقيقة');
        Alarm.ring('أحسنت! خلصت جلسة التركيز، خد ليك راحة');
        toast('🎯 جلسة كاملة! +10 نقاط');
      }
      cycle++;
      phase = cycle % longEvery == 0 ? _Phase.long : _Phase.short;
    } else {
      if (!skipped) Alarm.ring('الراحة خلصت، يلا نرجع للشغل');
      if (phase == _Phase.long) cycle = 0;
      phase = _Phase.focus;
      lineIdx = (lineIdx + 1) % _lines.length;
    }
    setState(() => left = _len(phase));
    if (autoStart && !skipped) _start();
  }

  void _reset() {
    _t?.cancel();
    _t = null;
    keepAwake(false);
    setState(() {
      endAt = null;
      left = _len(phase);
    });
  }

  Widget _stepper(String label, int v, int min, int max, ValueChanged<int> on, {String unit = 'د'}) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        IconButton.filledTonal(onPressed: v > min ? () => on(v - 1) : null, icon: const Icon(Icons.remove_rounded)),
        SizedBox(width: 56, child: Text('$v $unit', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        IconButton.filledTonal(onPressed: v < max ? () => on(v + 1) : null, icon: const Icon(Icons.add_rounded)),
      ]);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final m = _meta(phase);
    final total = _len(phase);
    final shown = Duration(seconds: (left.inMilliseconds / 1000).ceil());
    final st = Map<String, dynamic>.from(s.getData<Map>('focus_stats') ?? {});
    final now = DateTime.now();
    final today = Map<String, dynamic>.from(st[dkey(now)] ?? {'n': 0, 'm': 0});
    var streak = 0;
    for (var i = (today['n'] as num) > 0 ? 0 : 1; i < 60; i++) {
      final d = st[dkey(now.subtract(Duration(days: i)))];
      if (d != null && (d['n'] as num) > 0) {
        streak++;
      } else {
        break;
      }
    }
    var weekN = 0, weekM = 0;
    final bars = <Bar>[];
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final e = st[dkey(d)];
      final n = (e?['n'] as num?)?.toInt() ?? 0;
      weekN += n;
      weekM += (e?['m'] as num?)?.toInt() ?? 0;
      bars.add(Bar(i == 0 ? 'الليلة' : shortDays[d.weekday - 1], n.toDouble(), color: i == 0 ? SD.henna : SD.gold));
    }
    final log = List<Map>.from(s.getData<List>('focus_log') ?? []);
    final todayLog = log.where((e) => dkey(DateTime.fromMillisecondsSinceEpoch(e['t'])) == dkey(now)).toList();

    return ToolList(children: [
      SCard(
        color: m.$2,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(m.$3, color: m.$2),
            const SizedBox(width: 8),
            Text(m.$1, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: m.$2)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < longEvery; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < cycle ? SD.henna : SD.henna.withValues(alpha: .15),
                  border: Border.all(color: SD.henna.withValues(alpha: .5)),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text('الجلسة ${cycle + (phase == _Phase.focus ? 1 : 0)} من $longEvery قبل الراحة الطويلة', style: const TextStyle(fontSize: 12)),
          ),
          ProgressRing(
            progress: 1 - left.inMilliseconds / total.inMilliseconds,
            color: m.$2,
            size: 230,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(clock(shown),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
              Text(running ? 'بتخلص ${fmtTimeAr(endAt!)}' : (left == total ? 'جاهز؟' : 'واقف'), style: const TextStyle(fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),
          Text(_lines[lineIdx], textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SD.gold)),
          const SizedBox(height: 12),
          if (phase == _Phase.focus)
            TextField(
              controller: taskC,
              decoration: const InputDecoration(labelText: 'بتشتغل على شنو؟ (اختياري)', prefixIcon: Icon(Icons.edit_note_rounded)),
            ),
          const SizedBox(height: 12),
          Row(children: [
            IconButton.filledTonal(tooltip: 'صفّر', onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded)),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: running ? SD.red : m.$2),
                onPressed: running ? _pause : _start,
                icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(running ? 'وقّف شوية' : (phase == _Phase.focus ? 'يلا نركّز' : 'ابدأ الراحة')),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'تخطّي',
              onPressed: () {
                _t?.cancel();
                _t = null;
                endAt = null;
                keepAwake(false);
                _complete(skipped: true);
              },
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ]),
        ]),
      ),
      SectionTitle('إنجازك', icon: Icons.insights_rounded),
      StatGrid([
        StatChip('${today['n']}', 'جلسات الليلة', color: SD.henna, icon: Icons.check_circle_rounded),
        StatChip(fmtDuration(Duration(minutes: (today['m'] as num).toInt())), 'تركيز الليلة', color: SD.gold, icon: Icons.timer_rounded),
        StatChip('$streak', 'أيام ورا بعض', color: SD.orange, icon: Icons.local_fire_department_rounded),
        StatChip('$weekN', 'جلسات الأسبوع', color: SD.teal, icon: Icons.date_range_rounded),
        StatChip(fmtDuration(Duration(minutes: weekM)), 'تركيز الأسبوع', color: SD.nile, icon: Icons.hourglass_full_rounded),
        StatChip('${s.counter('focus_sessions')}', 'كل الجلسات', color: SD.green, icon: Icons.emoji_events_rounded),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: 'آخر 7 أيام',
        icon: Icons.bar_chart_rounded,
        color: SD.gold,
        child: BarChart(bars, color: SD.gold, valueText: (v) => v == 0 ? '' : fmt(v, 0)),
      ),
      if (todayLog.isNotEmpty)
        SCard(
          title: 'جلسات الليلة',
          icon: Icons.list_alt_rounded,
          color: SD.henna,
          child: Column(children: [
            for (final e in todayLog)
              InfoRow(
                (e['task'] as String?)?.isNotEmpty == true ? e['task'] : 'جلسة تركيز',
                '${e['m']} د',
                icon: Icons.check_rounded,
                hint: 'خلصت ${fmtTimeAr(DateTime.fromMillisecondsSinceEpoch(e['t']))}',
              ),
          ]),
        ),
      SCard(
        title: 'الإعدادات',
        icon: Icons.settings_rounded,
        color: SD.nile,
        child: Column(children: [
          _stepper('مدة التركيز', focusMin, 5, 120, (v) {
            setState(() {
              focusMin = v;
              if (!running && phase == _Phase.focus) left = _len(phase);
            });
            _saveCfg();
          }),
          _stepper('راحة قصيرة', shortMin, 1, 30, (v) {
            setState(() {
              shortMin = v;
              if (!running && phase == _Phase.short) left = _len(phase);
            });
            _saveCfg();
          }),
          _stepper('راحة طويلة', longMin, 5, 60, (v) {
            setState(() {
              longMin = v;
              if (!running && phase == _Phase.long) left = _len(phase);
            });
            _saveCfg();
          }),
          _stepper('راحة طويلة كل', longEvery, 2, 8, (v) {
            setState(() => longEvery = v);
            _saveCfg();
          }, unit: 'جلسات'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ابدأ المرحلة الجاية براها'),
            value: autoStart,
            onChanged: (v) {
              setState(() => autoStart = v);
              _saveCfg();
            },
          ),
          Wrap(spacing: 8, children: [
            for (final p in const [(25, 5, 15, 'كلاسيكي 25/5'), (50, 10, 20, 'طويل 50/10'), (15, 3, 10, 'خفيف 15/3')])
              ActionChip(
                label: Text(p.$4),
                onPressed: () {
                  setState(() {
                    focusMin = p.$1;
                    shortMin = p.$2;
                    longMin = p.$3;
                    if (!running) left = _len(phase);
                  });
                  _saveCfg();
                },
              ),
          ]),
        ]),
      ),
      const NoteBox('طريقة بومودورو: ركّز 25 دقيقة بدون موبايل ولا ونسة، بعدها 5 دقايق راحة، وكل 4 جلسات خد راحة طويلة. كل جلسة كاملة بتديك 10 نقاط 🎯',
          kind: NoteKind.tip),
    ]);
  }
}
