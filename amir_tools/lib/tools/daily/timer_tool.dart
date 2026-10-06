import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'alarm.dart';
import 'daily_common.dart';

class _Preset {
  final String name, emoji, done;
  final int secs;
  final Color color;
  const _Preset(this.name, this.emoji, this.secs, this.done, this.color);
}

const _presets = [
  _Preset('كباية شاي', '☕', 180, 'الشاي جاهز! أشرب بالعافية ☕', SD.henna),
  _Preset('جبنة', '🫖', 300, 'الجبنة استوت — صبّ للجماعة', SD.coffee),
  _Preset('بيضة مسلوقة', '🥚', 600, 'البيض استوى — خليهو في موية باردة شوية', SD.gold),
  _Preset('قيلولة', '😴', 1200, 'قوم يا زول! القيلولة خلصت', SD.indigo),
  _Preset('رز', '🍚', 1200, 'الرز استوى — طفّي النار', SD.teal),
  _Preset('فول', '🫘', 1800, 'الفول استوى — جيب الزيت والشمار والجبنة 😋', SD.green),
  _Preset('عجين يخمّر', '🍞', 3600, 'العجين خمّر — يلا أخبز', SD.orange),
];

class TimerTool extends StatefulWidget {
  const TimerTool({super.key});
  @override
  State<TimerTool> createState() => _TimerToolState();
}

class _TimerToolState extends State<TimerTool> {
  int tab = 0;
  Timer? _tick;

  // ساعة الإيقاف
  final _sw = Stopwatch();
  final List<Duration> laps = [];

  // العد التنازلي
  Duration total = const Duration(minutes: 3);
  Duration left = const Duration(minutes: 3);
  DateTime? endAt;
  String label = 'كباية شاي', doneMsg = 'الشاي جاهز! أشرب بالعافية ☕', emoji = '☕';
  Color cdColor = SD.henna;
  final minC = TextEditingController(), secC = TextEditingController();

  bool get cdRunning => endAt != null;

  @override
  void initState() {
    super.initState();
    final last = context.read<AppState>().getData<int>('timer_last');
    if (last != null && last > 0) {
      total = left = Duration(seconds: last);
      label = 'مؤقت مخصّص';
      emoji = '⏳';
      doneMsg = 'الوقت خلص!';
      cdColor = SD.nile;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    keepAwake(false);
    Alarm.stop();
    minC.dispose();
    secC.dispose();
    super.dispose();
  }

  void _ensureTick() {
    final need = _sw.isRunning || cdRunning;
    if (need && _tick == null) {
      _tick = Timer.periodic(const Duration(milliseconds: 47), (_) => _onTick());
    } else if (!need) {
      _tick?.cancel();
      _tick = null;
    }
    keepAwake(need);
  }

  void _onTick() {
    if (!mounted) return;
    if (cdRunning) {
      left = endAt!.difference(DateTime.now());
      if (left <= Duration.zero) {
        left = Duration.zero;
        endAt = null;
        _ensureTick();
        _finished();
      }
    }
    setState(() {});
  }

  void _finished() {
    Alarm.ring(doneMsg.replaceAll(RegExp(r'[^؀-ۿ\s!،]'), ''));
    context.read<AppState>().awardDaily('timer_done', 3, 'مؤقت خلص');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$emoji  $label', textAlign: TextAlign.center),
        content: Text(doneMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Alarm.stop();
              Navigator.pop(c);
              setState(() => left = total);
            },
            child: const Text('تمام'),
          ),
          FilledButton(
            onPressed: () {
              Alarm.stop();
              Navigator.pop(c);
              _startCd(total);
            },
            child: const Text('أعده تاني'),
          ),
        ],
      ),
    ).then((_) => Alarm.stop());
  }

  void _startCd(Duration d) {
    if (d <= Duration.zero) return;
    setState(() {
      left = d;
      endAt = DateTime.now().add(d);
    });
    _ensureTick();
  }

  void _pauseCd() {
    setState(() {
      left = endAt!.difference(DateTime.now());
      endAt = null;
    });
    _ensureTick();
  }

  void _resetCd() {
    setState(() {
      endAt = null;
      left = total;
    });
    _ensureTick();
  }

  void _choose(_Preset p) {
    setState(() {
      total = left = Duration(seconds: p.secs);
      label = p.name;
      doneMsg = p.done;
      emoji = p.emoji;
      cdColor = p.color;
      endAt = null;
    });
    _startCd(total);
  }

  void _custom() {
    final m = parseNum(minC.text).round(), sec = parseNum(secC.text).round();
    final d = Duration(minutes: m, seconds: sec);
    if (d <= Duration.zero) {
      toast('أكتب الدقايق أو الثواني الأول');
      return;
    }
    context.read<AppState>().setData('timer_last', d.inSeconds);
    setState(() {
      total = left = d;
      label = 'مؤقت مخصّص';
      emoji = '⏳';
      doneMsg = 'الوقت خلص!';
      cdColor = SD.nile;
    });
    FocusScope.of(context).unfocus();
    _startCd(d);
  }

  void _add(Duration d) {
    setState(() {
      total += d;
      if (cdRunning) {
        endAt = endAt!.add(d);
      } else {
        left += d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('ساعة الإيقاف'), icon: Icon(Icons.timer_rounded)),
          ButtonSegment(value: 1, label: Text('العد التنازلي'), icon: Icon(Icons.hourglass_bottom_rounded)),
        ],
        selected: {tab},
        onSelectionChanged: (v) => setState(() => tab = v.first),
      ),
      const SizedBox(height: 14),
      if (tab == 0) ..._stopwatch() else ..._countdown(),
      if (_sw.isRunning || cdRunning)
        const NoteBox('الشاشة حتفضل شغالة طول ما المؤقت شغال 💡', kind: NoteKind.tip),
    ]);
  }

  /* ───────── ساعة الإيقاف ───────── */
  List<Widget> _stopwatch() {
    final el = _sw.elapsed;
    final lapTimes = <Duration>[for (var i = 0; i < laps.length; i++) laps[i] - (i == 0 ? Duration.zero : laps[i - 1])];
    Duration? best, worst;
    if (lapTimes.length >= 2) {
      best = lapTimes.reduce((a, b) => a < b ? a : b);
      worst = lapTimes.reduce((a, b) => a > b ? a : b);
    }
    final currentLap = el - (laps.isEmpty ? Duration.zero : laps.last);
    return [
      SCard(
        color: SD.gold,
        child: Column(children: [
          ProgressRing(
            progress: (el.inMilliseconds % 60000) / 60000,
            color: SD.gold,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(clock(el, cs: true),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
              if (laps.isNotEmpty)
                Text('اللفة ${laps.length + 1}: ${clock(currentLap, cs: true)}',
                    style: const TextStyle(color: SD.gold, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sw.isRunning
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => laps.add(_sw.elapsed));
                      }
                    : (el > Duration.zero
                        ? () => setState(() {
                              _sw.reset();
                              laps.clear();
                            })
                        : null),
                icon: Icon(_sw.isRunning ? Icons.flag_rounded : Icons.restart_alt_rounded),
                label: Text(_sw.isRunning ? 'لفّة' : 'صفّر'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _sw.isRunning ? SD.red : SD.green),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _sw.isRunning ? _sw.stop() : _sw.start());
                  _ensureTick();
                },
                icon: Icon(_sw.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(_sw.isRunning ? 'وقّف' : (el > Duration.zero ? 'واصل' : 'يلا ابدأ')),
              ),
            ),
          ]),
        ]),
      ),
      if (laps.isNotEmpty) ...[
        StatGrid([
          StatChip('${laps.length}', 'لفّات', color: SD.nile, icon: Icons.flag_rounded),
          StatChip(best == null ? '—' : clock(best, cs: true), 'أسرع لفّة', color: SD.green, icon: Icons.bolt_rounded),
          StatChip(worst == null ? '—' : clock(worst, cs: true), 'أبطأ لفّة', color: SD.red, icon: Icons.slow_motion_video_rounded),
        ]),
        const SizedBox(height: 10),
        SCard(
          title: 'اللفّات',
          icon: Icons.format_list_numbered_rounded,
          color: SD.nile,
          trailing: Text('المتوسط ${clock(Duration(microseconds: laps.last.inMicroseconds ~/ laps.length), cs: true)}',
              style: const TextStyle(fontSize: 12)),
          child: Column(children: [
            for (var i = laps.length - 1; i >= 0; i--)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: lapTimes[i] == best
                      ? SD.green.withValues(alpha: .12)
                      : (lapTimes[i] == worst ? SD.red.withValues(alpha: .10) : null),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  SizedBox(width: 44, child: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  Expanded(
                    child: Text(clock(lapTimes[i], cs: true),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: lapTimes[i] == best ? SD.green : (lapTimes[i] == worst ? SD.red : null),
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
                  if (lapTimes[i] == best) const Text('الأسرع ', style: TextStyle(color: SD.green, fontSize: 11)),
                  if (lapTimes[i] == worst) const Text('الأبطأ ', style: TextStyle(color: SD.red, fontSize: 11)),
                  Text('المجموع ${clock(laps[i], cs: true)}', style: const TextStyle(fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
                ]),
              ),
          ]),
        ),
        ShareBar(() => [
              '⏱️ ساعة الإيقاف — الزمن الكلي ${clock(el, cs: true)}',
              for (var i = 0; i < laps.length; i++) 'لفة ${i + 1}: ${clock(lapTimes[i], cs: true)} (المجموع ${clock(laps[i], cs: true)})',
            ].join('\n')),
      ],
    ];
  }

  /* ───────── العد التنازلي ───────── */
  List<Widget> _countdown() {
    final prog = total.inMilliseconds == 0 ? 0.0 : left.inMilliseconds / total.inMilliseconds;
    final shown = Duration(milliseconds: (left.inMilliseconds / 1000).ceil() * 1000);
    return [
      SCard(
        color: cdColor,
        child: Column(children: [
          Text('$emoji  $label', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cdColor)),
          const SizedBox(height: 10),
          ProgressRing(
            progress: prog,
            color: cdColor,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(clock(shown),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
              Text(cdRunning ? 'بيخلص ${fmtTimeAr(endAt!)}' : 'من ${clock(total)}', style: const TextStyle(fontSize: 12.5)),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
            for (final m in [1, 5])
              ActionChip(label: Text('+$m د'), avatar: const Icon(Icons.add_rounded, size: 16), onPressed: () => _add(Duration(minutes: m))),
            ActionChip(label: const Text('+30 ث'), avatar: const Icon(Icons.add_rounded, size: 16), onPressed: () => _add(const Duration(seconds: 30))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(onPressed: _resetCd, icon: const Icon(Icons.restart_alt_rounded), label: const Text('صفّر')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: cdRunning ? SD.red : SD.green),
                onPressed: cdRunning ? _pauseCd : () => _startCd(left > Duration.zero ? left : total),
                icon: Icon(cdRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(cdRunning ? 'وقّف' : 'يلا ابدأ'),
              ),
            ),
          ]),
        ]),
      ),
      SectionTitle('جاهزات سودانية', icon: Icons.local_cafe_rounded),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in _presets)
          ActionChip(
            avatar: Text(p.emoji),
            label: Text('${p.name} ${p.secs ~/ 60} د'),
            backgroundColor: p.color.withValues(alpha: .12),
            side: BorderSide(color: p.color.withValues(alpha: .4)),
            onPressed: () => _choose(p),
          ),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: 'وقت على كيفك',
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: Column(children: [
          Row(children: [
            Expanded(child: NumField('دقايق', minC, decimal: false, hint: '0')),
            const SizedBox(width: 10),
            Expanded(child: NumField('ثواني', secC, decimal: false, hint: '0')),
          ]),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(onPressed: _custom, icon: const Icon(Icons.play_circle_rounded), label: const Text('شغّل المؤقت')),
          ),
        ]),
      ),
      const NoteBox('لمن الوقت يخلص الجوال بيهتز ويطلع صوت ويقول ليك. خلي التطبيق مفتوح عشان المنبّه يشتغل.'),
    ];
  }
}
