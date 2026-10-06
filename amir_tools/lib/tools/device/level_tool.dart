import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// ميزان الموية: فقاعة وزوايا الميلان مع معايرة
class LevelTool extends StatefulWidget {
  const LevelTool({super.key});
  @override
  State<LevelTool> createState() => _LevelToolState();
}

class _LevelToolState extends State<LevelTool> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _pitch = 0, _roll = 0, _p0 = 0, _r0 = 0;
  bool _edge = false, _was = false, _noSensor = false;

  @override
  void initState() {
    super.initState();
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((e) {
        final p = math.atan2(e.y, math.sqrt(e.x * e.x + e.z * e.z)) * 180 / math.pi;
        final r = math.atan2(-e.x, math.sqrt(e.y * e.y + e.z * e.z)) * 180 / math.pi;
        setState(() {
          _pitch = _pitch + .25 * (p - _pitch);
          _roll = _roll + .25 * (r - _roll);
        });
        final ok = _isLevel;
        if (ok && !_was) HapticFeedback.mediumImpact();
        _was = ok;
      }, onError: (_) => setState(() => _noSensor = true));
    } catch (_) {
      _noSensor = true;
    }
  }

  double get _px => _pitch - _p0;
  double get _rx => _roll - _r0;
  bool get _isLevel => _edge ? (_rx.abs() < .5) : (_px.abs() < .7 && _rx.abs() < .7);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isLevel ? SD.green : SD.gold;
    return ToolList(children: [
      if (_noSensor) const NoteBox('الحسّاس ما متاح في الجهاز دا.', kind: NoteKind.warn),
      SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('على السطح (مسطّح)')), ButtonSegment(value: true, label: Text('على الحرف (واقف)'))],
        selected: {_edge},
        onSelectionChanged: (v) => setState(() => _edge = v.first),
      ),
      const SizedBox(height: 16),
      Center(
        child: SizedBox(
          width: 260,
          height: _edge ? 90 : 260,
          child: CustomPaint(painter: _BubblePainter(_edge ? 0 : _px, _rx, color, _edge)),
        ),
      ),
      const SizedBox(height: 16),
      ResultHero(
        label: _isLevel ? 'مستوي تمام ✓' : 'لسه مايل',
        value: _edge ? '${fmt(_rx.abs(), 1)}°' : '${fmt(_px.abs(), 1)}° / ${fmt(_rx.abs(), 1)}°',
        sub: _edge ? 'الميلان' : 'أمامي / جانبي',
        colors: _isLevel ? const [SD.green, Color(0xFF004D1C)] : null,
      ),
      SCard(
        title: 'التفاصيل',
        icon: Icons.straighten_rounded,
        child: Column(children: [
          InfoRow('الميلان الأمامي', '${fmt(_px, 1)}°'),
          InfoRow('الميلان الجانبي', '${fmt(_rx, 1)}°'),
          InfoRow('الفرق على متر واحد (جانبي)', '${fmt(math.tan(_rx.abs() * math.pi / 180) * 100, 1)} سم', hint: 'مفيد للبلاط والرفوف'),
          InfoRow('النسبة المئوية للميل', '${fmt(math.tan(_rx.abs() * math.pi / 180) * 100, 1)}%'),
        ]),
      ),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _p0 = _pitch;
              _r0 = _roll;
            }),
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('صفّر (معايرة)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () => setState(() => _p0 = _r0 = 0), child: const Text('رجّع الأصل'))),
      ]),
      const NoteBox('للمعايرة: ختّ التلفون على سطح مستوي معروف واضغط «صفّر».', kind: NoteKind.tip),
    ]);
  }
}

class _BubblePainter extends CustomPainter {
  final double pitch, roll;
  final Color color;
  final bool edge;
  _BubblePainter(this.pitch, this.roll, this.color, this.edge);

  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final bg = Paint()..color = SD.goldLight.withValues(alpha: .12);
    final line = Paint()
      ..color = SD.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rr = edge
        ? RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height), const Radius.circular(45))
        : RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height), Radius.circular(s.width / 2));
    c.drawRRect(rr, bg);
    c.drawRRect(rr, line);
    c.drawCircle(ctr, 26, line);
    if (!edge) {
      c.drawLine(Offset(ctr.dx, 10), Offset(ctr.dx, s.height - 10), line..strokeWidth = .8);
      c.drawLine(Offset(10, ctr.dy), Offset(s.width - 10, ctr.dy), line);
    } else {
      c.drawLine(Offset(ctr.dx - 30, 8), Offset(ctr.dx - 30, s.height - 8), line..strokeWidth = 1.5);
      c.drawLine(Offset(ctr.dx + 30, 8), Offset(ctr.dx + 30, s.height - 8), line);
    }
    final maxD = s.width / 2 - 26;
    final dx = (roll / 20).clamp(-1.0, 1.0) * maxD;
    final dy = edge ? 0.0 : (pitch / 20).clamp(-1.0, 1.0) * maxD;
    final b = ctr + Offset(-dx, dy);
    c.drawCircle(b, 22, Paint()..shader = RadialGradient(colors: [Colors.white, color]).createShader(Rect.fromCircle(center: b, radius: 22)));
  }

  @override
  bool shouldRepaint(_BubblePainter o) => true;
}
