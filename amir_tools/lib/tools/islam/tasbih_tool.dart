import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

const _presets = [
  'سُبْحَانَ اللَّهِ',
  'الْحَمْدُ لِلَّهِ',
  'اللَّهُ أَكْبَرُ',
  'لَا إِلَٰهَ إِلَّا اللَّهُ',
  'أَسْتَغْفِرُ اللَّهَ',
  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
  'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
  'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ نَبِيِّنَا مُحَمَّدٍ',
  'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
  'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
  'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
];

const _targets = [33, 99, 100, 1000, 0]; // 0 = بلا حد

class TasbihTool extends StatefulWidget {
  const TasbihTool({super.key});
  @override
  State<TasbihTool> createState() => _TasbihToolState();
}

class _TasbihToolState extends State<TasbihTool> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  String _dhikr = _presets.first;
  int _target = 33;
  int _count = 0; // عدد الجلسة الحالية
  int _rounds = 0;
  bool _vibrate = true;
  final List<_Ripple> _ripples = [];
  int _rippleId = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    final s = context.read<AppState>();
    _dhikr = s.getData<String>('tasbih_current') ?? _presets.first;
    _target = (s.getData<num>('tasbih_target') ?? 33).toInt();
    _vibrate = s.getData<bool>('tasbih_vibrate') ?? true;
    _count = (s.getData<num>('tasbih_session') ?? 0).toInt();
    _rounds = (s.getData<num>('tasbih_rounds') ?? 0).toInt();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  List<String> _custom(AppState s) => List<String>.from(s.getData<List>('tasbih_custom') ?? []);
  Map<String, int> _totals(AppState s) => (s.getData<Map>('tasbih_totals') ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
  Map<String, int> _days(AppState s) => (s.getData<Map>('tasbih_days') ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
  int _allTime(AppState s) => (s.getData<num>('tasbih_all') ?? 0).toInt();

  void _tap(TapDownDetails? d, Size box) {
    final s = context.read<AppState>();
    final pos = d?.localPosition ?? Offset(box.width / 2, box.height / 2);
    setState(() {
      _count++;
      _ripples.add(_Ripple(_rippleId++, pos));
    });
    _pulse.forward(from: 0);

    // حفظ الإحصاءات
    final totals = _totals(s)..update(_dhikr, (v) => v + 1, ifAbsent: () => 1);
    final days = _days(s);
    final key = AppState.dayKey(DateTime.now());
    days.update(key, (v) => v + 1, ifAbsent: () => 1);
    if (days.length > 40) {
      final keys = days.keys.toList()..sort((a, b) => _parseKey(a).compareTo(_parseKey(b)));
      for (final k in keys.take(days.length - 40)) {
        days.remove(k);
      }
    }
    final all = _allTime(s) + 1;
    s.setData('tasbih_totals', totals);
    s.setData('tasbih_days', days);
    s.setData('tasbih_all', all);
    s.setData('tasbih_session', _count);
    s.bump('tasbih');
    if (all % 100 == 0) s.award(3, 'تسبيح ${fmt(all, 0)} مرة');

    final hitTarget = _target > 0 && _count % _target == 0;
    if (hitTarget) {
      _rounds++;
      s.setData('tasbih_rounds', _rounds);
      if (_vibrate) HapticFeedback.heavyImpact();
      toast('تمّت $_target ✓ — الدورة رقم $_rounds، ما شاء الله', icon: Icons.verified_rounded);
    } else if (_vibrate) {
      HapticFeedback.selectionClick();
    }
  }

  DateTime _parseKey(String k) {
    final p = k.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  void _reset() {
    setState(() {
      _count = 0;
      _rounds = 0;
    });
    final s = context.read<AppState>();
    s.setData('tasbih_session', 0);
    s.setData('tasbih_rounds', 0);
  }

  void _pick(String d) {
    setState(() {
      _dhikr = d;
      _count = 0;
      _rounds = 0;
    });
    final s = context.read<AppState>();
    s.setData('tasbih_current', d);
    s.setData('tasbih_session', 0);
    s.setData('tasbih_rounds', 0);
  }

  Future<void> _addCustom() async {
    final ctrl = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ذكر جديد'),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'أكتب الذكر هنا…')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('تمام، ضيفو')),
        ],
      ),
    );
    ctrl.dispose();
    if (r == null || r.isEmpty || !mounted) return;
    final s = context.read<AppState>();
    final l = _custom(s);
    if (!l.contains(r)) l.add(r);
    s.setData('tasbih_custom', l);
    _pick(r);
  }

  void _removeCustom(String d) {
    final s = context.read<AppState>();
    s.setData('tasbih_custom', _custom(s)..remove(d));
    if (_dhikr == d) _pick(_presets.first);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final totals = _totals(s);
    final days = _days(s);
    final now = DateTime.now();
    final today = days[AppState.dayKey(now)] ?? 0;
    var week = 0;
    final last7 = <int>[];
    for (var i = 6; i >= 0; i--) {
      final v = days[AppState.dayKey(now.subtract(Duration(days: i)))] ?? 0;
      last7.add(v);
      week += v;
    }
    var streak = 0;
    for (var i = 0; i < 40; i++) {
      if ((days[AppState.dayKey(now.subtract(Duration(days: i)))] ?? 0) > 0) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    final allTime = _allTime(s);
    final inRound = _target > 0 ? _count % _target : _count;
    final progress = _target > 0 ? inRound / _target : 0.0;
    final custom = _custom(s);
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ToolList(children: [
      SCard(
        color: SD.green,
        child: Column(children: [
          Text(_dhikr, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, height: 1.7, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('مجموعو عندك: ${fmt(totals[_dhikr] ?? 0, 0)} مرة', style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: .6))),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (ctx, bc) {
            final size = math.min(bc.maxWidth, 290.0);
            return SizedBox(
              width: size,
              height: size,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _tap(d, Size(size, size)),
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _target > 0 ? progress : null,
                      strokeWidth: 10,
                      color: SD.gold,
                      backgroundColor: SD.gold.withValues(alpha: .15),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Transform.scale(scale: 1 - .05 * math.sin(_pulse.value * math.pi), child: child),
                    child: Container(
                      width: size - 34,
                      height: size - 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [SD.green, Color(0xFF004D1C)]),
                        border: Border.all(color: SD.gold, width: 3),
                        boxShadow: [BoxShadow(color: SD.green.withValues(alpha: .4), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(fmt(_count, 0), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                        const SizedBox(height: 6),
                        Text(_target > 0 ? '$inRound / $_target' : 'بلا حد ∞', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
                        if (_rounds > 0) Text('الدورات: $_rounds', style: const TextStyle(color: SD.sand, fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('اضغط هنا', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      ]),
                    ),
                  ),
                  for (final r in _ripples)
                    _RippleWidget(
                      key: ValueKey(r.id),
                      at: r.pos,
                      area: size,
                      onDone: () => setState(() => _ripples.removeWhere((x) => x.id == r.id)),
                    ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _count == 0 ? null : _reset, icon: const Icon(Icons.restart_alt_rounded), label: const Text('صفّر الجلسة'))),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _vibrate = !_vibrate);
                  s.setData('tasbih_vibrate', _vibrate);
                },
                icon: Icon(_vibrate ? Icons.vibration_rounded : Icons.mobile_off_rounded),
                label: Text(_vibrate ? 'الهزّاز شغّال' : 'الهزّاز مقفول'),
              ),
            ),
          ]),
        ]),
      ),
      SCard(
        title: 'الهدف',
        icon: Icons.flag_rounded,
        color: SD.gold,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in _targets)
            ChoiceChip(
              label: Text(t == 0 ? '∞ مفتوح' : '$t'),
              selected: _target == t,
              onSelected: (_) {
                setState(() => _target = t);
                s.setData('tasbih_target', t);
              },
            ),
        ]),
      ),
      SCard(
        title: 'اختار الذكر',
        icon: Icons.format_list_bulleted_rounded,
        color: SD.teal,
        trailing: IconButton(onPressed: _addCustom, icon: const Icon(Icons.add_circle_rounded, color: SD.teal), tooltip: 'ضيف ذكر'),
        child: Column(children: [
          for (final d in [..._presets, ...custom])
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              dense: true,
              selected: d == _dhikr,
              leading: Icon(d == _dhikr ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: SD.teal),
              title: Text(d, style: const TextStyle(fontSize: 15.5, height: 1.5)),
              subtitle: (totals[d] ?? 0) > 0 ? Text('المجموع: ${fmt(totals[d], 0)}') : null,
              trailing: custom.contains(d) && !_presets.contains(d)
                  ? IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _removeCustom(d))
                  : null,
              onTap: () => _pick(d),
            ),
        ]),
      ),
      const SectionTitle('إحصاءاتك', icon: Icons.insights_rounded),
      StatGrid([
        StatChip(fmt(today, 0), 'النهارده', color: SD.green, icon: Icons.today_rounded),
        StatChip(fmt(week, 0), 'آخر 7 أيام', color: SD.nile, icon: Icons.date_range_rounded),
        StatChip(fmt(allTime, 0), 'من البداية', color: SD.gold, icon: Icons.all_inclusive_rounded),
        StatChip('$streak', 'أيام متتالية', color: SD.henna, icon: Icons.local_fire_department_rounded),
        StatChip(fmt(s.counter('tasbih'), 0), 'عدّاد الإنجازات', color: SD.indigo, icon: Icons.emoji_events_rounded),
        StatChip(fmt(100 - allTime % 100, 0), 'باقي للنقاط الجاية', color: SD.teal, icon: Icons.stars_rounded),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: 'آخر 7 أيام',
        icon: Icons.bar_chart_rounded,
        color: SD.nile,
        child: SizedBox(
          height: 130,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(last7[i] == 0 ? '' : fmt(last7[i], 0), style: const TextStyle(fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Container(
                      height: 80 * (last7.reduce(math.max) == 0 ? 0 : last7[i] / last7.reduce(math.max)) + 3,
                      decoration: BoxDecoration(
                        color: i == 6 ? SD.gold : SD.nile.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(weekdaysAr[now.subtract(Duration(days: 6 - i)).weekday - 1].replaceFirst('ال', ''), style: const TextStyle(fontSize: 10)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
      if (sorted.isNotEmpty)
        SCard(
          title: 'مجموع كل ذكر',
          icon: Icons.leaderboard_rounded,
          color: SD.henna,
          child: Column(children: [
            for (final e in sorted.take(12)) InfoRow(e.key, fmt(e.value, 0)),
          ]),
        ),
      ShareBar(() => '📿 المسبحة\nالذكر: $_dhikr\nالجلسة: $_count${_target > 0 ? ' (الدورات: $_rounds × $_target)' : ''}\nالنهارده: $today\nآخر 7 أيام: $week\nمن البداية: $allTime'),
      const NoteBox('«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ» [الرعد: 28]. كل 100 تسبيحة بتديك نقاط إضافية، والأهم الأجر إن شاء الله.', kind: NoteKind.tip),
    ]);
  }
}

class _Ripple {
  final int id;
  final Offset pos;
  _Ripple(this.id, this.pos);
}

class _RippleWidget extends StatefulWidget {
  final Offset at;
  final double area;
  final VoidCallback onDone;
  const _RippleWidget({super.key, required this.at, required this.area, required this.onDone});
  @override
  State<_RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<_RippleWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))
    ..forward().whenComplete(() {
      if (mounted) widget.onDone();
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _RipplePainter(widget.at, _c.value, widget.area)),
          ),
        ),
      );
}

class _RipplePainter extends CustomPainter {
  final Offset at;
  final double t, area;
  _RipplePainter(this.at, this.t, this.area);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - t) + .5
      ..color = SD.gold.withValues(alpha: (1 - t) * .8);
    canvas.drawCircle(at, area * .45 * Curves.easeOut.transform(t), p);
  }

  @override
  bool shouldRepaint(_RipplePainter o) => o.t != t;
}
