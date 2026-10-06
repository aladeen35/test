import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// مقياس الضوضاء (ديسيبل تقريبي) مع رسم حي
class NoiseTool extends StatefulWidget {
  const NoiseTool({super.key});
  @override
  State<NoiseTool> createState() => _NoiseToolState();
}

class _NoiseToolState extends State<NoiseTool> {
  StreamSubscription<NoiseReading>? _sub;
  final _hist = <double>[];
  double _cur = 0, _min = double.infinity, _max = 0, _sum = 0;
  int _n = 0;
  String? _err;

  Future<void> _start() async {
    if (kIsWeb) return setState(() => _err = 'المقياس شغّال في تطبيق الموبايل بس');
    final st = await Permission.microphone.request();
    if (!st.isGranted) return setState(() => _err = 'محتاجين إذن المايك عشان نقيس');
    try {
      _sub = NoiseMeter().noise.listen((r) {
        final v = r.meanDecibel;
        if (!v.isFinite) return;
        setState(() {
          _err = null;
          _cur = v;
          _min = math.min(_min, v);
          _max = math.max(_max, v);
          _sum += v;
          _n++;
          _hist.add(v);
          if (_hist.length > 120) _hist.removeAt(0);
        });
      }, onError: (_) => setState(() => _err = 'حصلت مشكلة في المايك'));
      setState(() {});
    } catch (_) {
      setState(() => _err = 'حصلت مشكلة في المايك');
    }
  }

  void _stop() {
    _sub?.cancel();
    setState(() => _sub = null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  (String, Color) _label(double v) {
    if (v < 30) return ('هدوء تام 🤫', SD.green);
    if (v < 50) return ('هادئ — زي البيت بالليل', SD.green);
    if (v < 65) return ('ونسة عادية', SD.teal);
    if (v < 80) return ('زحمة شارع', SD.gold);
    if (v < 90) return ('عالي — ركشة أو مولّد قريب', SD.orange);
    if (v < 100) return ('عالي شديد — خطر مع الوقت', SD.red);
    return ('خطر على السمع ⚠️ — بعّد طوالي', SD.red);
  }

  @override
  Widget build(BuildContext context) {
    final running = _sub != null;
    final (lbl, col) = _label(_cur);
    return ToolList(children: [
      if (_err != null) NoteBox(_err!, kind: NoteKind.warn),
      ResultHero(label: running ? lbl : 'اضغط ابدأ عشان نقيس', value: running ? '${fmt(_cur, 0)} dB' : '— dB', colors: running ? [col, SD.brownDeep] : null),
      SizedBox(height: 120, child: CustomPaint(painter: _ChartPainter(List.of(_hist)), size: const Size(double.infinity, 120))),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: running ? _stop : _start,
        icon: Icon(running ? Icons.stop_rounded : Icons.mic_rounded),
        label: Text(running ? 'وقّف' : 'ابدأ القياس'),
      ),
      const SizedBox(height: 12),
      if (_n > 0)
        StatGrid([
          StatChip(fmt(_min, 0), 'أقل', color: SD.green),
          StatChip(fmt(_sum / _n, 0), 'المتوسط', color: SD.gold),
          StatChip(fmt(_max, 0), 'أعلى', color: SD.red),
        ]),
      SCard(
        title: 'مقارنات',
        icon: Icons.hearing_rounded,
        child: const Column(children: [
          InfoRow('همس', '30 dB'),
          InfoRow('ونسة عادية', '60 dB'),
          InfoRow('زحمة السوق العربي', '70–80 dB'),
          InfoRow('ركشة / مولّد كهرباء', '85–95 dB'),
          InfoRow('مكبرات صوت الحفلات', '100–110 dB'),
          InfoRow('الأذى يبدأ مع التعرض الطويل', 'من 85 dB'),
        ]),
      ),
      const NoteBox('القراءة تقريبية حسب مايك التلفون وما بتعتبر جهاز قياس معتمد.', kind: NoteKind.info),
    ]);
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> v;
  _ChartPainter(this.v);
  @override
  void paint(Canvas c, Size s) {
    final bg = Paint()..color = SD.gold.withValues(alpha: .08);
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(16)), bg);
    if (v.length < 2) return;
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = s.width * i / 119;
      final y = s.height - (v[i].clamp(20, 120) - 20) / 100 * s.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    c.drawPath(path, Paint()..color = SD.gold..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_) => true;
}
