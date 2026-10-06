import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/prayer.dart';

const _kLng = 39.8262;

String compassName(double deg) {
  const names = ['الشمال', 'شمال شرق', 'الشرق', 'جنوب شرق', 'الجنوب', 'جنوب غرب', 'الغرب', 'شمال غرب'];
  return names[((deg % 360) / 45).round() % 8];
}

class QiblaTool extends StatefulWidget {
  const QiblaTool({super.key});
  @override
  State<QiblaTool> createState() => _QiblaToolState();
}

class _QiblaToolState extends State<QiblaTool> {
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  Timer? _watchdog;
  List<double>? _g; // متجه الجاذبية (مُنعّم)
  List<double>? _m; // المجال المغناطيسي (مُنعّم)
  double? _heading; // اتجاه الجهاز من الشمال المغناطيسي
  double _sinS = 0, _cosS = 1;
  bool _sensorsFailed = false;
  bool _aligned = false;
  double _field = 0;
  double _tilt = 0;
  bool _locating = false;
  double _minField = 1e9, _maxField = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _sensorsFailed = false;
    if (kIsWeb) {
      _sensorsFailed = true;
      return;
    }
    try {
      _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) => _g = _lp(_g, [e.x, e.y, e.z], .15),
        onError: (_) => _fail(),
        cancelOnError: true,
      );
      _magSub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) {
          _m = _lp(_m, [e.x, e.y, e.z], .15);
          _compute();
        },
        onError: (_) => _fail(),
        cancelOnError: true,
      );
      _watchdog = Timer(const Duration(seconds: 4), () {
        if (_heading == null) _fail();
      });
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (!mounted) return;
    _stop();
    setState(() => _sensorsFailed = true);
  }

  void _stop() {
    _accSub?.cancel();
    _magSub?.cancel();
    _watchdog?.cancel();
    _accSub = null;
    _magSub = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  List<double> _lp(List<double>? prev, List<double> cur, double a) =>
      prev == null ? cur : [for (var i = 0; i < 3; i++) prev[i] + a * (cur[i] - prev[i])];

  /// حساب الاتجاه مع تعويض الميلان (نفس فكرة getRotationMatrix في أندرويد)
  void _compute() {
    final g = _g, m = _m;
    if (g == null || m == null) return;
    final ax = g[0], ay = g[1], az = g[2];
    final ex = m[0], ey = m[1], ez = m[2];
    var hx = ey * az - ez * ay, hy = ez * ax - ex * az, hz = ex * ay - ey * ax;
    final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (normH < .1) return; // الجهاز قريب من السقوط الحر أو قريب من القطب
    hx /= normH;
    hy /= normH;
    hz /= normH;
    final normA = math.sqrt(ax * ax + ay * ay + az * az);
    final nax = ax / normA, naz = az / normA;
    final my = naz * hx - nax * hz;
    final az0 = math.atan2(hy, my) * 180 / math.pi;
    final raw = (az0 + 360) % 360;
    // تنعيم دائري لتفادي القفزة عند 0/360
    const k = .2;
    _sinS += k * (math.sin(raw * math.pi / 180) - _sinS);
    _cosS += k * (math.cos(raw * math.pi / 180) - _cosS);
    final h = (math.atan2(_sinS, _cosS) * 180 / math.pi + 360) % 360;
    _field = math.sqrt(ex * ex + ey * ey + ez * ez);
    if (_field > 0) {
      _minField = math.min(_minField, _field);
      _maxField = math.max(_maxField, _field);
    }
    _tilt = math.acos((naz).clamp(-1.0, 1.0)) * 180 / math.pi;
    _watchdog?.cancel();
    if (!mounted) return;
    final c = context.read<AppState>().city;
    final d = ((qiblaBearing(c.lat, c.lng) - h + 540) % 360) - 180;
    final ok = d.abs() <= 3;
    if (ok && !_aligned) HapticFeedback.heavyImpact();
    _aligned = ok;
    setState(() => _heading = h);
  }

  Future<void> _useGps() async {
    final s = context.read<AppState>();
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        toast('الـ GPS مقفول، افتحو من الإعدادات وجرّب تاني');
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        toast('ما ادّيتنا إذن الموقع، حنستخدم المدينة المختارة');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 20)));
      s.setGps(pos.latitude, pos.longitude);
      toast('تمام، حدّدنا موقعك ✓');
    } catch (_) {
      toast('ما قدرنا نجيب الموقع هسي، جرّب في مكان مفتوح');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final c = s.city;
    final bearing = qiblaBearing(c.lat, c.lng);
    final dist = distanceToKaaba(c.lat, c.lng);
    final heading = _heading;
    double? diff;
    if (heading != null) {
      diff = ((bearing - heading + 540) % 360) - 180; // موجب = لف يمين (مع عقارب الساعة)
    }
    final aligned = diff != null && diff.abs() <= 3;
    final fieldBad = heading != null && (_field < 20 || _field > 70);
    final flightKm = dist;
    final walkDays = dist / 30; // ~30 كم في اليوم مشيًا
    final dLng = _kLng - c.lng;

    return ToolList(children: [
      ResultHero(
        label: 'اتجاه القبلة من ${c.name}',
        value: '${fmt(bearing, 1)}°',
        sub: 'من الشمال الجغرافي ناحية ${compassName(bearing)} • المسافة للكعبة ${fmt(dist, 0)} كم',
        colors: const [SD.green, SD.coffee],
      ),
      SCard(
        color: aligned ? SD.green : SD.gold,
        child: Column(children: [
          if (heading != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (aligned ? SD.green : SD.gold).withValues(alpha: .15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: aligned ? SD.green : SD.gold.withValues(alpha: .5)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(aligned ? Icons.check_circle_rounded : (diff! > 0 ? Icons.rotate_right_rounded : Icons.rotate_left_rounded),
                    color: aligned ? SD.green : SD.gold),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    aligned
                        ? 'انت في الاتجاه الصح ✓'
                        : 'لِف ${diff > 0 ? 'يمين' : 'شمال'} ${fmt(diff.abs(), 0)}°',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: aligned ? SD.green : cs.onSurface),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(builder: (ctx, bc) {
            final size = math.min(bc.maxWidth, 320.0);
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _DialPainter(
                  heading: heading ?? 0,
                  qibla: bearing,
                  aligned: aligned,
                  live: heading != null,
                  onSurface: cs.onSurface,
                  surface: cs.surface,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          if (heading != null)
            Text('اتجاه جوالك: ${fmt(heading, 0)}° (${compassName(heading)})', style: const TextStyle(fontWeight: FontWeight.w700))
          else if (_sensorsFailed)
            const NoteBox(
                'البوصلة ما شغّالة في الجهاز دا (أو انت فاتح من المتصفح). ما في مشكلة: اعرف الشمال بأي بوصلة أو بالشمس، وبعدين لف من الشمال مع عقارب الساعة بالزاوية المكتوبة فوق.',
                kind: NoteKind.warn)
          else
            const Padding(padding: EdgeInsets.all(8), child: Text('بنجهّز البوصلة… ثبّت الجوال شوية')),
        ]),
      ),
      if (heading != null)
        StatGrid([
          StatChip('${fmt(_field, 0)} µT', 'شدة المجال', color: fieldBad ? SD.red : SD.teal, icon: Icons.sensors_rounded),
          StatChip('${fmt(_tilt, 0)}°', 'ميلان الجوال', color: _tilt > 35 ? SD.orange : SD.nile, icon: Icons.screen_rotation_alt_rounded),
          StatChip(aligned ? 'تمام' : '${fmt(diff!.abs(), 0)}°', 'الفرق', color: aligned ? SD.green : SD.gold, icon: Icons.explore_rounded),
        ]),
      if (fieldBad)
        const NoteBox('المجال المغناطيسي غريب (الطبيعي تقريبًا 25–65 µT). ابعد من الحديد والكهربا والسماعات وغطا الجوال المغناطيسي، وسوي معايرة.', kind: NoteKind.danger),
      if (heading != null && _tilt > 35) const NoteBox('خلي الجوال مسطّح (موازي للأرض) عشان القراءة تكون أدق.', kind: NoteKind.warn),
      SCard(
        title: 'تفاصيل الموقع والقبلة',
        icon: Icons.place_rounded,
        color: SD.nile,
        trailing: TextButton.icon(
          onPressed: _locating ? null : _useGps,
          icon: _locating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded),
          label: const Text('موقعي'),
        ),
        child: Column(children: [
          InfoRow('المدينة', c.name, icon: Icons.location_city_rounded),
          InfoRow('الإحداثيات', '${c.lat.toStringAsFixed(4)}°, ${c.lng.toStringAsFixed(4)}°', icon: Icons.pin_drop_rounded),
          InfoRow('زاوية القبلة', '${fmt(bearing, 2)}° من الشمال', icon: Icons.navigation_rounded, hint: 'باتجاه عقارب الساعة'),
          InfoRow('الاتجاه العام', compassName(bearing), icon: Icons.explore_rounded),
          InfoRow('الزاوية من الشرق', '${fmt((bearing - 90).abs(), 1)}° ${bearing < 90 ? 'ناحية الشمال' : 'ناحية الجنوب'}', icon: Icons.wb_sunny_rounded,
              hint: 'مفيدة لو عارف الشرق (مطلع الشمس تقريبًا)'),
          InfoRow('المسافة للكعبة (خط مستقيم)', '${fmt(flightKm, 0)} كم', icon: Icons.straighten_rounded),
          InfoRow('بالميل', '${fmt(flightKm * 0.621371, 0)} ميل', icon: Icons.social_distance_rounded),
          InfoRow('بالطيارة (≈ 800 كم/س)', fmtDuration(Duration(minutes: (flightKm / 800 * 60).round())), icon: Icons.flight_rounded),
          InfoRow('مشي على الأقدام (≈ 30 كم/يوم)', '${fmt(walkDays, 0)} يوم', icon: Icons.directions_walk_rounded),
          InfoRow('فرق خط الطول مع مكة', '${fmt(dLng.abs(), 2)}° ${dLng > 0 ? 'شرقك' : 'غربك'}', icon: Icons.public_rounded,
              hint: 'كل درجة ≈ 4 دقايق فرق في الشمس'),
          InfoRow('إحداثيات الكعبة', '21.4225°, 39.8262°', icon: Icons.mosque_rounded),
        ]),
      ),
      if (heading != null && _maxField > 0)
        InfoRow('مدى قراءات المجال منذ الفتح', '${fmt(_minField, 0)} – ${fmt(_maxField, 0)} µT', icon: Icons.tune_rounded),
      const SizedBox(height: 8),
      const NoteBox(
          'المعايرة: حرّك الجوال في الهوا على شكل رقم 8 (∞) مرتين تلاتة، وابعد من الحديد والعربات والتلفزيونات. البوصلة بتقيس الشمال المغناطيسي، والفرق عن الشمال الجغرافي في السودان صغير (درجات قليلة).',
          kind: NoteKind.tip),
      const NoteBox(
          'الزاوية محسوبة بدقة على الدائرة العظمى (أقصر طريق) من إحداثيات المدينة. البوصلة في الجوال تقريبية؛ لو في مسجد قريب فاتجاه محرابه هو المعتمد إن شاء الله.',
          kind: NoteKind.info),
      ShareBar(() =>
          '🕋 اتجاه القبلة من ${c.name}\nالزاوية: ${fmt(bearing, 1)}° من الشمال (${compassName(bearing)})\nالمسافة للكعبة: ${fmt(dist, 0)} كم'),
    ]);
  }
}

class _DialPainter extends CustomPainter {
  final double heading, qibla;
  final bool aligned, live;
  final Color onSurface, surface;
  _DialPainter({required this.heading, required this.qibla, required this.aligned, required this.live, required this.onSurface, required this.surface});

  double _r(double d) => d * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final accent = aligned ? SD.green : SD.gold;

    // خلفية القرص
    canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [surface, Color.lerp(surface, SD.coffee, .35)!]).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = accent);
    canvas.drawCircle(c, r - 10, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = SD.gold.withValues(alpha: .4));

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_r(-heading)); // القرص يلف عكس اتجاه الجوال

    // تدريجات
    for (var a = 0; a < 360; a += 5) {
      final major = a % 30 == 0;
      final p = Paint()
        ..color = onSurface.withValues(alpha: major ? .8 : .35)
        ..strokeWidth = major ? 2.5 : 1;
      final dir = Offset(math.sin(_r(a.toDouble())), -math.cos(_r(a.toDouble())));
      canvas.drawLine(dir * (r - 12), dir * (r - (major ? 26 : 19)), p);
    }
    // الحروف
    const labels = {0: 'ش', 90: 'ق', 180: 'ج', 270: 'غ'};
    labels.forEach((a, t) {
      final dir = Offset(math.sin(_r(a.toDouble())), -math.cos(_r(a.toDouble())));
      _text(canvas, t, dir * (r - 44), a == 0 ? SD.red : onSurface, 20, bold: true, rotate: _r(heading));
    });
    for (var a = 30; a < 360; a += 30) {
      if (a % 90 == 0) continue;
      final dir = Offset(math.sin(_r(a.toDouble())), -math.cos(_r(a.toDouble())));
      _text(canvas, '$a', dir * (r - 40), onSurface.withValues(alpha: .6), 11, rotate: _r(heading));
    }

    // خط القبلة + علامة الكعبة
    final qd = Offset(math.sin(_r(qibla)), -math.cos(_r(qibla)));
    canvas.drawLine(Offset.zero, qd * (r - 60), Paint()
      ..color = accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    final kPos = qd * (r - 60);
    canvas.save();
    canvas.translate(kPos.dx, kPos.dy);
    canvas.rotate(_r(heading));
    final kr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 30, height: 30), const Radius.circular(4));
    canvas.drawRRect(kr, Paint()..color = SD.black);
    canvas.drawRect(Rect.fromLTWH(-15, -8, 30, 5), Paint()..color = SD.gold);
    canvas.drawRRect(kr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent);
    canvas.restore();
    canvas.restore();

    // مؤشر الجوال الثابت (أعلى)
    final tri = Path()
      ..moveTo(c.dx, c.dy - r - 2)
      ..lineTo(c.dx - 12, c.dy - r + 20)
      ..lineTo(c.dx + 12, c.dy - r + 20)
      ..close();
    canvas.drawPath(tri, Paint()..color = live ? accent : onSurface.withValues(alpha: .3));
    // سهم الجوال
    canvas.drawLine(c, Offset(c.dx, c.dy - r + 70), Paint()
      ..color = onSurface.withValues(alpha: .25)
      ..strokeWidth = 2);
    canvas.drawCircle(c, 9, Paint()..color = accent);
    canvas.drawCircle(c, 4, Paint()..color = surface);
  }

  void _text(Canvas canvas, String t, Offset at, Color color, double size, {bool bold = false, double rotate = 0}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontFamily: 'Tajawal')),
      textDirection: TextDirection.rtl,
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(rotate);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.heading != heading || o.qibla != qibla || o.aligned != aligned || o.live != live || o.surface != surface;
}
