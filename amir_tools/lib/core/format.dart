import 'package:intl/intl.dart';

/// تنسيق الأرقام بفواصل الآلاف (أرقام لاتينية كما في الواجهة)
String fmt(num? n, [int digits = 2]) {
  if (n == null || n.isNaN || n.isInfinite) return '—';
  final f = NumberFormat.decimalPatternDigits(locale: 'en_US', decimalDigits: digits);
  var s = f.format(n);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return s;
}

/// يقرأ رقمًا من نص المستخدم (يقبل الأرقام العربية والفواصل)
double parseNum(String? s, [double fallback = 0]) {
  if (s == null) return fallback;
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final t = s
      .trim()
      .split('')
      .map((c) => ar.contains(c) ? ar.indexOf(c).toString() : c)
      .join()
      .replaceAll(',', '')
      .replaceAll('٫', '.')
      .replaceAll('،', '');
  return double.tryParse(t) ?? fallback;
}

String toArabicDigits(String s) => s.replaceAllMapped(RegExp(r'\d'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]);

String fmtBytes(int b) {
  if (b < 1024) return '$b B';
  if (b < 1048576) return '${fmt(b / 1024, 0)} KB';
  return '${fmt(b / 1048576, 2)} MB';
}

/// مدة بصيغة عربية مختصرة: «3 س 12 د»
String fmtDuration(Duration d) {
  final m = d.inMinutes.abs();
  if (m >= 60 * 24) return '${m ~/ 1440} يوم ${(m % 1440) ~/ 60} س';
  if (m >= 60) return '${m ~/ 60} س ${m % 60} د';
  return '$m دقيقة';
}

String two(int n) => n.toString().padLeft(2, '0');

const weekdaysAr = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

/// «الاثنين 5 أكتوبر 2026»
String fmtDateAr(DateTime d, {bool weekday = true}) =>
    '${weekday ? '${weekdaysAr[d.weekday - 1]} ' : ''}${d.day} ${monthsAr[d.month - 1]} ${d.year}';

/// الوقت بنظام 12 ساعة: «4:22 ص»
String fmtTimeAr(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${two(d.minute)} ${d.hour < 12 ? 'ص' : 'م'}';
}
