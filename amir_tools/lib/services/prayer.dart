import 'dart:math' as math;
import 'package:timezone/timezone.dart' as tz;
import '../core/i18n.dart';

/// مواقيت الصلاة والقبلة — حساب محلي كامل (منقول من خوارزمية PrayTimes)
/// يعمل لأي مكان في العالم: المنطقة الزمنية للمكان المختار تُضبط في [placeTz].

/// المنطقة الزمنية (IANA) للمكان الحالي — فارغة تعني توقيت الجهاز
String placeTz = 'Africa/Khartoum';

/// فرق التوقيت عن UTC للمكان الحالي في لحظة معيّنة (مع التوقيت الصيفي)
Duration placeOffset(DateTime instant) {
  if (placeTz.isNotEmpty) {
    try {
      return tz.getLocation(placeTz).timeZone(instant.millisecondsSinceEpoch).offset;
    } catch (_) {}
  }
  return instant.toLocal().timeZoneOffset;
}

/// يحوّل لحظة زمنية مطلقة إلى «ساعة الحائط» في المكان المختار (للعرض فقط).
/// الاسم تاريخي من نسخة السودان فقط؛ يعمل الآن لأي مكان.
DateTime toSudan(DateTime t) => t.toUtc().add(placeOffset(t));
DateTime toPlace(DateTime t) => toSudan(t);

/// التاريخ والوقت الحاليان في المكان المختار
DateTime sudanNow() => toSudan(DateTime.now());
DateTime placeNow() => sudanNow();

class PrayerMethod {
  final String id, ar, en;
  final double fajr;
  final double? isha;
  final int? ishaMinutes;
  const PrayerMethod(this.id, this.ar, this.en, this.fajr, {this.isha, this.ishaMinutes});
  String get name => isEn ? en : ar;
}

const prayerMethods = [
  PrayerMethod('egypt', 'الهيئة المصرية العامة للمساحة (السودان ومصر)', 'Egyptian General Authority (Sudan, Egypt)', 19.5, isha: 17.5),
  PrayerMethod('mwl', 'رابطة العالم الإسلامي', 'Muslim World League', 18, isha: 17),
  PrayerMethod('makkah', 'أم القرى (السعودية)', 'Umm al-Qura (Saudi Arabia)', 18.5, ishaMinutes: 90),
  PrayerMethod('dubai', 'الإمارات', 'UAE (Dubai)', 18.2, isha: 18.2),
  PrayerMethod('kuwait', 'الكويت', 'Kuwait', 18, isha: 17.5),
  PrayerMethod('qatar', 'قطر', 'Qatar', 18, ishaMinutes: 90),
  PrayerMethod('turkey', 'رئاسة الشؤون الدينية التركية', 'Diyanet (Turkey)', 18, isha: 17),
  PrayerMethod('karachi', 'جامعة العلوم الإسلامية بكراتشي', 'University of Islamic Sciences, Karachi', 18, isha: 18),
  PrayerMethod('isna', 'الجمعية الإسلامية لأمريكا الشمالية', 'ISNA (North America)', 15, isha: 15),
  PrayerMethod('singapore', 'سنغافورة وماليزيا', 'Singapore / Malaysia', 20, isha: 18),
  PrayerMethod('france', 'اتحاد المنظمات الإسلامية بفرنسا', 'UOIF (France)', 12, isha: 12),
];

/// طريقة الحساب المناسبة لدولة (تُختار تلقائيًا عند تغيير المكان)
String methodForCountry(String c) => switch (c.toUpperCase()) {
      'SA' || 'YE' => 'makkah',
      'AE' => 'dubai',
      'KW' => 'kuwait',
      'QA' || 'BH' => 'qatar',
      'TR' => 'turkey',
      'PK' || 'IN' || 'BD' || 'AF' => 'karachi',
      'US' || 'CA' => 'isna',
      'SG' || 'MY' || 'ID' || 'BN' => 'singapore',
      'FR' => 'france',
      'SD' || 'EG' || 'SS' || 'LY' || 'SY' || 'IQ' || 'LB' || 'JO' || 'PS' => 'egypt',
      _ => 'mwl',
    };

const prayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
Map<String, String> get prayerNames => isEn
    ? const {'fajr': 'Fajr', 'sunrise': 'Sunrise', 'dhuhr': 'Dhuhr', 'asr': 'Asr', 'maghrib': 'Maghrib', 'isha': 'Isha'}
    : const {'fajr': 'الفجر', 'sunrise': 'الشروق', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء'};
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
