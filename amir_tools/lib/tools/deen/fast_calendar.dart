import '../../core/i18n.dart';
import '../../services/calendars.dart';
import 'deen_common.dart';

/// أنواع صيام التطوع المسنونة
enum FastType {
  monThu('mon_thu'),
  bid('bid'),
  arafah('arafah'),
  ashura('ashura'),
  shawwal('shawwal');

  final String id;
  const FastType(this.id);

  String get label => switch (this) {
        FastType.monThu => tr('الاثنين والخميس', 'Monday & Thursday'),
        FastType.bid => tr('الأيام البيض (13–15)', 'White days (13–15)'),
        FastType.arafah => tr('يوم عرفة', 'Day of Arafah'),
        FastType.ashura => tr('تاسوعاء وعاشوراء', 'Tasu\'a & Ashura'),
        FastType.shawwal => tr('ستّ من شوال', 'Six days of Shawwal'),
      };

  static FastType? byId(String id) {
    for (final f in values) {
      if (f.id == id) return f;
    }
    return null;
  }
}

/// حالة يوم معيّن
class FastDay {
  final DateTime date;
  final CalDate hijri;

  /// يحرم صومه (العيدان وأيام التشريق)
  final String? forbidden;
  final bool ramadan;
  final List<FastType> types;
  const FastDay(this.date, this.hijri, this.forbidden, this.ramadan, this.types);

  bool get suggested => forbidden == null && !ramadan && types.isNotEmpty;

  /// وصف قصير لنوع اليوم
  String describe() {
    if (forbidden != null) return forbidden!;
    if (ramadan) return tr('رمضان (صيام فريضة)', 'Ramadan (obligatory fast)');
    final parts = <String>[];
    for (final t in types) {
      parts.add(switch (t) {
        FastType.monThu => date.weekday == DateTime.monday ? tr('الاثنين', 'Monday') : tr('الخميس', 'Thursday'),
        FastType.bid => tr('من الأيام البيض', 'White day'),
        FastType.arafah => tr('يوم عرفة', 'Day of Arafah'),
        FastType.ashura => hijri.d == 9 ? tr('تاسوعاء', 'Tasu\'a (9 Muharram)') : tr('عاشوراء', 'Ashura (10 Muharram)'),
        FastType.shawwal => tr('من ستّ شوال', 'Shawwal fast'),
      });
    }
    return parts.join(' • ');
  }
}

/// يحسب حالة اليوم حسب التقويم الهجري مع تعديل الرؤية [shift]
FastDay fastDay(DateTime d, int shift) {
  final date = DateTime(d.year, d.month, d.day);
  final h = toHijri(date, shift: shift);
  String? forbidden;
  if (h.m == 10 && h.d == 1) forbidden = tr('عيد الفطر — يحرم صومه', 'Eid al-Fitr — fasting forbidden');
  if (h.m == 12 && h.d == 10) forbidden = tr('عيد الأضحى — يحرم صومه', 'Eid al-Adha — fasting forbidden');
  if (h.m == 12 && h.d >= 11 && h.d <= 13) forbidden = tr('من أيام التشريق — لا يُصام', 'Day of Tashriq — do not fast');
  final ramadan = h.m == 9;
  final types = <FastType>[];
  if (forbidden == null && !ramadan) {
    if (h.m == 12 && h.d == 9) types.add(FastType.arafah);
    if (h.m == 1 && (h.d == 9 || h.d == 10)) types.add(FastType.ashura);
    if (h.m == 10 && h.d >= 2) types.add(FastType.shawwal);
    if (h.d >= 13 && h.d <= 15) types.add(FastType.bid);
    if (date.weekday == DateTime.monday || date.weekday == DateTime.thursday) types.add(FastType.monThu);
  }
  return FastDay(date, h, forbidden, ramadan, types);
}

/// الأيام المسنونة القادمة (بدءًا من [from]) لمدة [days] يومًا
List<FastDay> upcomingFasts(DateTime from, int shift, {int days = 30}) => [
      for (var i = 0; i < days; i++) fastDay(addDays(from, i), shift),
    ].where((f) => f.suggested).toList();

/// أول يوم قادم لكل مناسبة كبيرة (عرفة، عاشوراء، بداية ست شوال، الأيام البيض)
Map<FastType, DateTime> nextOccasions(DateTime from, int shift) {
  final r = <FastType, DateTime>{};
  for (var i = 0; i < 400 && r.length < 4; i++) {
    final f = fastDay(addDays(from, i), shift);
    for (final t in f.types) {
      if (t == FastType.monThu || r.containsKey(t)) continue;
      // ست شوال: نعرض أول يوم مسموح (2 شوال)، أو اليوم إن كنّا داخلها
      r[t] = f.date;
    }
  }
  return r;
}
