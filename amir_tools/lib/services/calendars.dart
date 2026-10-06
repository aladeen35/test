/// التقاويم: الهجري (الحسابي مع تعديل الرؤية)، القبطي، الإثيوبي — عبر رقم اليوم اليولياني (JDN)
/// كلها حسابات محلية دون إنترنت.
library;

import 'package:hijri/hijri_calendar.dart';

class CalDate {
  final int y, m, d;
  const CalDate(this.y, this.m, this.d);
  @override
  String toString() => '$d/$m/$y';
}

const hijriMonths = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
const copticMonths = ['توت', 'بابه', 'هاتور', 'كيهك', 'طوبة', 'أمشير', 'برمهات', 'برمودة', 'بشنس', 'بؤونة', 'أبيب', 'مسرى', 'النسيء'];
const ethiopianMonths = ['مسكرم', 'تقمت', 'هدار', 'تاهساس', 'تر', 'يكاتيت', 'مجابيت', 'ميازيا', 'جنبوت', 'سني', 'هملي', 'نهاسي', 'باجمي'];

int _fdiv(int a, int b) => (a / b).floor();

/// ميلادي ← JDN (عند الظهر)
int gregorianToJdn(int y, int m, int d) {
  final a = _fdiv(14 - m, 12);
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d + _fdiv(153 * mm + 2, 5) + 365 * yy + _fdiv(yy, 4) - _fdiv(yy, 100) + _fdiv(yy, 400) - 32045;
}

DateTime jdnToGregorian(int j) {
  final a = j + 32044;
  final b = _fdiv(4 * a + 3, 146097);
  final c = a - _fdiv(146097 * b, 4);
  final d = _fdiv(4 * c + 3, 1461);
  final e = c - _fdiv(1461 * d, 4);
  final m = _fdiv(5 * e + 2, 153);
  final day = e - _fdiv(153 * m + 2, 5) + 1;
  final month = m + 3 - 12 * _fdiv(m, 10);
  final year = 100 * b + d - 4800 + _fdiv(m, 10);
  return DateTime(year, month, day);
}

int dateToJdn(DateTime d) => gregorianToJdn(d.year, d.month, d.day);

/* ── الهجري (تقويم أم القرى عبر حزمة hijri، مع تعديل الرؤية من الإعدادات) ── */
CalDate toHijri(DateTime g, {int shift = 0}) {
  final h = HijriCalendar.fromDate(DateTime(g.year, g.month, g.day).add(Duration(days: shift)));
  return CalDate(h.hYear, h.hMonth, h.hDay);
}

DateTime fromHijri(int y, int m, int d, {int shift = 0}) =>
    HijriCalendar().hijriToGregorian(y, m, d).subtract(Duration(days: shift));

/// عدد أيام الشهر الهجري
int hijriMonthLength(int y, int m) => HijriCalendar().getDaysInMonth(y, m);

String hijriText(DateTime g, {int shift = 0}) {
  final h = toHijri(g, shift: shift);
  return '${h.d} ${hijriMonths[h.m - 1]} ${h.y} هـ';
}

/* ── القبطي والإثيوبي (نفس البنية مع اختلاف البداية) ── */
const _copticEpoch = 1825030;
const _ethiopicEpoch = 1724221;

int _fixedToJdn(int epoch, int y, int m, int d) => epoch - 1 + 365 * (y - 1) + _fdiv(y, 4) + 30 * (m - 1) + d;

CalDate _jdnToFixed(int epoch, int j) {
  final r = (j - epoch) % 1461;
  final n = (r % 365) + 365 * _fdiv(r, 1460);
  final y = 4 * _fdiv(j - epoch, 1461) + _fdiv(r, 365) - _fdiv(r, 1460) + 1;
  return CalDate(y, _fdiv(n, 30) + 1, (n % 30) + 1);
}

CalDate toCoptic(DateTime g) => _jdnToFixed(_copticEpoch, dateToJdn(g));
CalDate toEthiopian(DateTime g) => _jdnToFixed(_ethiopicEpoch, dateToJdn(g));
DateTime fromCoptic(int y, int m, int d) => jdnToGregorian(_fixedToJdn(_copticEpoch, y, m, d));
DateTime fromEthiopian(int y, int m, int d) => jdnToGregorian(_fixedToJdn(_ethiopicEpoch, y, m, d));

String copticText(DateTime g) {
  final c = toCoptic(g);
  return '${c.d} ${copticMonths[c.m - 1]} ${c.y} ش';
}

String ethiopianText(DateTime g) {
  final e = toEthiopian(g);
  return '${e.d} ${ethiopianMonths[e.m - 1]} ${e.y} (إثيوبي)';
}
