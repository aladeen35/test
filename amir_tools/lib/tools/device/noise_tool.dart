import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/i18n.dart';
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
    if (kIsWeb) return setState(() => _err = t('المقياس شغّال في تطبيق الموبايل بس', 'المقياس يعمل في تطبيق الجوال فقط', 'The meter works in the mobile app only'));
    final st = await Permission.microphone.request();
    if (!st.isGranted) return setState(() => _err = t('محتاجين إذن المايك عشان نقيس', 'نحتاج إذن الميكروفون للقياس', 'Microphone permission is needed to measure'));
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
      }, onError: (_) => setState(() => _err = _micErr));
      setState(() {});
    } catch (_) {
      setState(() => _err = _micErr);
    }
  }

  String get _micErr => t('حصلت مشكلة في المايك', 'حدثت مشكلة في الميكروفون', 'Microphone error');

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
    if (v < 30) return (t('هدوء تام 🤫', 'هدوء تام 🤫', 'Total silence 🤫'), SD.green);
    if (v < 50) return (t('هادئ — زي البيت بالليل', 'هادئ — مثل البيت ليلاً', 'Quiet — like home at night'), SD.green);
    if (v < 65) return (t('ونسة عادية', 'محادثة عادية', 'Normal conversation'), SD.teal);
    if (v < 80) return (t('زحمة شارع', 'زحمة الشارع', 'Busy street'), SD.gold);
    if (v < 90) return (t('عالي — ركشة أو مولّد قريب', 'مرتفع — دراجة نارية أو مولّد قريب', 'Loud — motorbike or generator nearby'), SD.orange);
    if (v < 100) return (t('عالي شديد — خطر مع الوقت', 'مرتفع جداً — خطر مع طول التعرض', 'Very loud — harmful over time'), SD.red);
    return (t('خطر على السمع ⚠️ — بعّد طوالي', 'خطر على السمع ⚠️ — ابتعد فوراً', 'Hearing danger ⚠️ — move away now'), SD.red);
  }

  @override
  Widget build(BuildContext context) {
    final running = _sub != null;
    final (lbl, col) = _label(_cur);
    return ToolList(children: [
      if (_err != null) NoteBox(_err!, kind: NoteKind.warn),
      ResultHero(label: running ? lbl : t('اضغط ابدأ عشان نقيس', 'اضغط ابدأ للقياس', 'Tap Start to measure'), value: running ? '${fmt(_cur, 0)} dB' : '— dB', colors: running ? [col, SD.brownDeep] : null),
      SizedBox(height: 120, child: CustomPaint(painter: _ChartPainter(List.of(_hist)), size: const Size(double.infinity, 120))),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: running ? _stop : _start,
        icon: Icon(running ? Icons.stop_rounded : Icons.mic_rounded),
        label: Text(running ? t('وقّف', 'إيقاف', 'Stop') : tr('ابدأ القياس', 'Start measuring')),
      ),
      const SizedBox(height: 12),
      if (_n > 0)
        StatGrid([
          StatChip(fmt(_min, 0), tr('أقل', 'Min'), color: SD.green),
          StatChip(fmt(_sum / _n, 0), tr('المتوسط', 'Average'), color: SD.gold),
          StatChip(fmt(_max, 0), tr('أعلى', 'Max'), color: SD.red),
        ]),
      SCard(
        title: tr('مقارنات', 'Comparisons'),
        icon: Icons.hearing_rounded,
        child: Column(children: [
          InfoRow(tr('همس', 'Whisper'), '30 dB'),
          InfoRow(t('ونسة عادية', 'محادثة عادية', 'Normal conversation'), '60 dB'),
          InfoRow(t('زحمة السوق', 'زحمة السوق', 'Busy market'), '70–80 dB'),
          InfoRow(t('ركشة / مولّد كهرباء', 'دراجة نارية / مولّد كهرباء', 'Motorbike / generator'), '85–95 dB'),
          InfoRow(t('مكبرات صوت الحفلات', 'مكبرات صوت الحفلات', 'Party speakers'), '100–110 dB'),
          InfoRow(tr('الأذى يبدأ مع التعرض الطويل', 'Damage with long exposure'), tr('من 85 dB', 'from 85 dB')),
        ]),
      ),
      NoteBox(
          t('القراءة تقريبية حسب مايك التلفون وما بتعتبر جهاز قياس معتمد.', 'القراءة تقريبية بحسب ميكروفون الهاتف ولا تُعدّ جهاز قياس معتمداً.',
              "Readings are approximate, depend on the phone's mic, and aren't a certified meter."),
          kind: NoteKind.info),
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
