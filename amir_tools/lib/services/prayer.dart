import 'dart:math' as math;

/// مواقيت الصلاة والقبلة — حساب محلي كامل (منقول من خوارزمية PrayTimes)
/// التوقيت المعتمد: السودان UTC+2 (Africa/Khartoum، بلا توقيت صيفي)
const sudanOffset = Duration(hours: 2);

/// يحوّل لحظة زمنية مطلقة إلى «ساعة الحائط» في السودان (للعرض فقط)
DateTime toSudan(DateTime t) => t.toUtc().add(sudanOffset);

/// التاريخ الحالي في السودان
DateTime sudanNow() => toSudan(DateTime.now());

class PrayerMethod {
  final String id, name;
  final double fajr;
  final double? isha;
  final int? ishaMinutes;
  const PrayerMethod(this.id, this.name, this.fajr, {this.isha, this.ishaMinutes});
}

const prayerMethods = [
  PrayerMethod('egypt', 'الهيئة المصرية العامة للمساحة (المعتمدة في السودان)', 19.5, isha: 17.5),
  PrayerMethod('mwl', 'رابطة العالم الإسلامي', 18, isha: 17),
  PrayerMethod('makkah', 'أم القرى', 18.5, ishaMinutes: 90),
  PrayerMethod('karachi', 'جامعة العلوم الإسلامية بكراتشي', 18, isha: 18),
];

const prayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
const prayerNames = {'fajr': 'الفجر', 'sunrise': 'الشروق', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء'};
const fardKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;
double _sin(double d) => math.sin(_rad(d));
double _cos(double d) => math.cos(_rad(d));
double _tan(double d) => math.tan(_rad(d));
double _asin(double x) => _deg(math.asin(x));
double _acos(double x) => _deg(math.acos(x.clamp(-1.0, 1.0)));
double _atan2(double y, double x) => _deg(math.atan2(y, x));
double _acot(double x) => _deg(math.atan(1 / x));
double _fix(double a, double b) {
  a = a - b * (a / b).floorToDouble();
  return a < 0 ? a + b : a;
}

double _julian(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + b - 1524.5;
}

({double decl, double eqt}) _sun(double jd) {
  final d = jd - 2451545.0;
  final g = _fix(357.529 + 0.98560028 * d, 360);
  final q = _fix(280.459 + 0.98564736 * d, 360);
  final l = _fix(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g), 360);
  final e = 23.439 - 0.00000036 * d;
  final ra = _fix(_atan2(_cos(e) * _sin(l), _cos(l)) / 15, 24);
  return (decl: _asin(_sin(e) * _sin(l)), eqt: q / 15 - ra);
}

/// مواقيت يوم معيّن (سنة/شهر/يوم بتوقيت السودان) — تُعاد كلحظات مطلقة (UTC)
Map<String, DateTime> prayerTimes(int y, int m, int d, double lat, double lng,
    {String method = 'egypt', bool hanafi = false, Map<String, int> adjust = const {}}) {
  final pm = prayerMethods.firstWhere((x) => x.id == method, orElse: () => prayerMethods.first);
  final jd = _julian(y, m, d) - lng / (15 * 24);

  double midDay(double t) => _fix(12 - _sun(jd + t).eqt, 24);
  double angleTime(double angle, double t, {bool ccw = false}) {
    final decl = _sun(jd + t).decl;
    final noon = midDay(t);
    final tt = _acos((-_sin(angle) - _sin(decl) * _sin(lat)) / (_cos(decl) * _cos(lat))) / 15;
    return noon + (ccw ? -tt : tt);
  }

  double asrTime(int factor, double t) {
    final decl = _sun(jd + t).decl;
    return angleTime(-_acot(factor + _tan((lat - decl).abs())), t);
  }

  var t = <String, double>{'fajr': 5, 'sunrise': 6, 'dhuhr': 12, 'asr': 13, 'maghrib': 18, 'isha': 18};
  for (var i = 0; i < 2; i++) {
    final p = t.map((k, v) => MapEntry(k, v / 24));
    final maghrib = angleTime(0.833, p['maghrib']!);
    t = {
      'fajr': angleTime(pm.fajr, p['fajr']!, ccw: true),
      'sunrise': angleTime(0.833, p['sunrise']!, ccw: true),
      'dhuhr': midDay(p['dhuhr']!),
      'asr': asrTime(hanafi ? 2 : 1, p['asr']!),
      'maghrib': maghrib,
      'isha': pm.ishaMinutes != null ? maghrib + pm.ishaMinutes! / 60 : angleTime(pm.isha!, p['isha']!),
    };
  }

  final base = DateTime.utc(y, m, d);
  return {
    for (final k in prayerKeys)
      k: base.add(Duration(seconds: (((t[k]! - lng / 15) * 60 + (adjust[k] ?? 0)) * 60).round())),
  };
}

/// اتجاه القبلة بالدرجات من الشمال الجغرافي
double qiblaBearing(double lat, double lng) {
  const kLat = 21.4225, kLng = 39.8262;
  final dl = kLng - lng;
  return _fix(_atan2(_sin(dl), _cos(lat) * _tan(kLat) - _sin(lat) * _cos(dl)), 360);
}

/// المسافة إلى الكعبة بالكيلومتر
double distanceToKaaba(double lat, double lng) {
  const r = 6371.0, kLat = 21.4225, kLng = 39.8262;
  final a = math.pow(_sin((kLat - lat) / 2), 2) + _cos(lat) * _cos(kLat) * math.pow(_sin((kLng - lng) / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}
