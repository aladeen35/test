import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

List<String> get _dirs => isEn
    ? const ['North', 'North-East', 'East', 'South-East', 'South', 'South-West', 'West', 'North-West']
    : const ['شمال', 'شمال شرق', 'شرق', 'جنوب شرق', 'جنوب', 'جنوب غرب', 'غرب', 'شمال غرب'];

/// البوصلة والموقع: الاتجاه بالدرجات والإحداثيات والارتفاع
class CompassTool extends StatefulWidget {
  const CompassTool({super.key});
  @override
  State<CompassTool> createState() => _CompassToolState();
}

class _CompassToolState extends State<CompassTool> {
  StreamSubscription? _a, _m;
  List<double>? _g, _mag;
  double? _heading;
  double _s = 0, _c = 1;
  Position? _pos;
  String? _posErr;

  @override
  void initState() {
    super.initState();
    try {
      _a = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((e) => _g = [e.x, e.y, e.z], onError: (_) {});
      _m = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((e) {
        _mag = [e.x, e.y, e.z];
        _compute();
      }, onError: (_) {});
    } catch (_) {}
  }

  void _compute() {
    final g = _g, m = _mag;
    if (g == null || m == null) return;
    var hx = m[1] * g[2] - m[2] * g[1], hy = m[2] * g[0] - m[0] * g[2], hz = m[0] * g[1] - m[1] * g[0];
    final nh = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (nh < .1) return;
    hx /= nh;
    hy /= nh;
    hz /= nh;
    final na = math.sqrt(g[0] * g[0] + g[1] * g[1] + g[2] * g[2]);
    final my = (g[2] / na) * hx - (g[0] / na) * hz;
    final raw = math.atan2(hy, my);
    _s += .2 * (math.sin(raw) - _s);
    _c += .2 * (math.cos(raw) - _c);
    if (mounted) setState(() => _heading = (math.atan2(_s, _c) * 180 / math.pi + 360) % 360);
  }

  Future<void> _locate() async {
    setState(() => _posErr = null);
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        return setState(() => _posErr = t('ما اتدّى إذن الموقع', 'لم يُمنح إذن الموقع', 'Location permission not granted'));
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _pos = pos);
    } catch (_) {
      if (mounted) setState(() => _posErr = t('ما قدرنا نحدّد الموقع — شغّل الـ GPS', 'تعذّر تحديد الموقع — شغّل الـ GPS', "Couldn't get your location — turn on GPS"));
    }
  }

  String _dms(double v, bool lat) {
    final d = v.abs().floor();
    final mFull = (v.abs() - d) * 60;
    final mi = mFull.floor();
    final sec = (mFull - mi) * 60;
    return '$d° $mi′ ${fmt(sec, 1)}″ ${lat ? (v >= 0 ? tr('شمال', 'N') : tr('جنوب', 'S')) : (v >= 0 ? tr('شرق', 'E') : tr('غرب', 'W'))}';
  }

  @override
  void dispose() {
    _a?.cancel();
    _m?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _heading;
    final link = _pos == null ? '' : 'https://maps.google.com/?q=${_pos!.latitude},${_pos!.longitude}';
    return ToolList(children: [
      if (h == null)
        NoteBox(
            kIsWeb
                ? t('البوصلة شغّالة في تطبيق الموبايل بس.', 'البوصلة تعمل في تطبيق الجوال فقط.', 'The compass works in the mobile app only.')
                : t('حرّك التلفون شوية… لو ما اشتغلت، الجهاز ما فيهو حسّاس مغناطيسي.', 'حرّك الهاتف قليلاً… إن لم تعمل، فالجهاز لا يحتوي حسّاساً مغناطيسياً.',
                    "Move the phone a little… if nothing happens, the device has no magnetometer."),
            kind: NoteKind.info),
      Center(
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(alignment: Alignment.center, children: [
            Transform.rotate(angle: -(h ?? 0) * math.pi / 180, child: CustomPaint(size: const Size(260, 260), painter: _DialPainter(isEn))),
            const Icon(Icons.navigation_rounded, size: 64, color: SD.red),
          ]),
        ),
      ),
      ResultHero(
          label: h == null
              ? tr('الاتجاه', 'Heading')
              : t('إنت متّجه ناحية ${_dirs[((h + 22.5) % 360 ~/ 45)]}', 'أنت متّجه نحو ${_dirs[((h + 22.5) % 360 ~/ 45)]}', 'Facing ${_dirs[((h + 22.5) % 360 ~/ 45)]}'),
           value: h == null ? '—' : '${fmt(h, 0)}°'),
      SCard(
        title: tr('موقعك', 'Your location'),
        icon: Icons.location_on_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_posErr != null) NoteBox(_posErr!, kind: NoteKind.warn),
          if (_pos != null) ...[
            InfoRow(tr('خط العرض', 'Latitude'), '${fmt(_pos!.latitude, 6)}', hint: _dms(_pos!.latitude, true)),
            InfoRow(tr('خط الطول', 'Longitude'), '${fmt(_pos!.longitude, 6)}', hint: _dms(_pos!.longitude, false)),
            InfoRow(tr('الارتفاع عن البحر', 'Altitude'), '${fmt(_pos!.altitude, 0)} ${tr('م', 'm')}'),
            InfoRow(tr('دقة التحديد', 'Accuracy'), '± ${fmt(_pos!.accuracy, 0)} ${tr('م', 'm')}'),
            if (_pos!.speed > 0) InfoRow(tr('السرعة', 'Speed'), '${fmt(_pos!.speed * 3.6, 1)} ${tr('كم/س', 'km/h')}'),
            const SizedBox(height: 8),
            ShareBar(() => '${tr('موقعي', 'My location')}: $link'),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _locate, icon: const Icon(Icons.my_location_rounded), label: Text(_pos == null ? tr('حدّد موقعي', 'Locate me') : tr('حدّث الموقع', 'Refresh location'))),
        ]),
      ),
      NoteBox(
          t('بعّد التلفون من الحديد والمغنطيس، وحرّكو على شكل رقم 8 عشان البوصلة تتعاير.', 'أبعد الهاتف عن الحديد والمغناطيس، وحرّكه على شكل الرقم 8 لمعايرة البوصلة.',
              'Keep the phone away from metal and magnets, and move it in a figure-8 to calibrate the compass.'),
          kind: NoteKind.tip),
    ]);
  }
}

class _DialPainter extends CustomPainter {
  final bool en;
  _DialPainter(this.en);

  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2;
    c.drawCircle(ctr, r, Paint()..shader = const RadialGradient(colors: [SD.brownLight, SD.brown, SD.brownDeep]).createShader(Rect.fromCircle(center: ctr, radius: r)));
    c.drawCircle(ctr, r - 2, Paint()..color = SD.gold..style = PaintingStyle.stroke..strokeWidth = 3);
    for (var i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180;
      final long = i % 6 == 0;
      final p1 = ctr + Offset(math.sin(a), -math.cos(a)) * (r - 6);
      final p2 = ctr + Offset(math.sin(a), -math.cos(a)) * (r - (long ? 22 : 13));
      c.drawLine(p1, p2, Paint()..color = SD.goldLight..strokeWidth = long ? 2 : 1);
    }
    final labels = en ? const {'N': 0, 'E': 90, 'S': 180, 'W': 270} : const {'ش': 0, 'شر': 90, 'ج': 180, 'غ': 270};
    labels.forEach((lbl, d) {
      final a = d * math.pi / 180;
      final tp = TextPainter(
          text: TextSpan(text: lbl, style: TextStyle(color: d == 0 ? SD.red : SD.cream, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Tajawal')),
          textDirection: en ? TextDirection.ltr : TextDirection.rtl)
        ..layout();
      tp.paint(c, ctr + Offset(math.sin(a), -math.cos(a)) * (r - 40) - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.en != en;
}
