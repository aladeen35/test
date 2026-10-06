import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import 'daily_common.dart';

/// حاسبة العمر — تفاصيل كثيرة وعدّاد حي
class AgeTool extends StatefulWidget {
  const AgeTool({super.key});
  @override
  State<AgeTool> createState() => _AgeToolState();
}

class _Ymd {
  final int y, m, d;
  const _Ymd(this.y, this.m, this.d);
}

int _dim(int y, int m) => DateTime(y, m + 1, 0).day;
bool _leap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

/// فرق تقويمي بالسنوات والشهور والأيام
_Ymd _diff(DateTime a, DateTime b) {
  var y = b.year - a.year, m = b.month - a.month, d = b.day - a.day;
  if (d < 0) {
    m--;
    d += _dim(b.year, b.month - 1);
  }
  if (m < 0) {
    y--;
    m += 12;
  }
  return _Ymd(y, m, d);
}

const _planetsData = [
  ('عطارد', 'Mercury', '☿️', 0.2408467, SD.orange),
  ('الزُّهرة', 'Venus', '♀️', 0.61519726, SD.gold),
  ('المريخ', 'Mars', '🔴', 1.8808158, SD.red),
  ('المشتري', 'Jupiter', '🪐', 11.862615, SD.henna),
  ('زحل', 'Saturn', '🪐', 29.447498, SD.coffee),
  ('أورانوس', 'Uranus', '🔵', 84.016846, SD.teal),
  ('نبتون', 'Neptune', '🔷', 164.79132, SD.indigo),
];

/// (الاسم حسب اللغة، الرمز، طول السنة بالسنين الأرضية، اللون)
List<(String, String, double, Color)> get _planets => [for (final p in _planetsData) (tr(p.$1, p.$2), p.$3, p.$4, p.$5)];

const _zodiac = [
  // (شهر البداية، يوم البداية، الاسم، الرمز)
  (1, 20, 'الدلو', '♒', 'Aquarius'),
  (2, 19, 'الحوت', '♓', 'Pisces'),
  (3, 21, 'الحمل', '♈', 'Aries'),
  (4, 20, 'الثور', '♉', 'Taurus'),
  (5, 21, 'الجوزاء', '♊', 'Gemini'),
  (6, 21, 'السرطان', '♋', 'Cancer'),
  (7, 23, 'الأسد', '♌', 'Leo'),
  (8, 23, 'العذراء', '♍', 'Virgo'),
  (9, 23, 'الميزان', '♎', 'Libra'),
  (10, 23, 'العقرب', '♏', 'Scorpio'),
  (11, 22, 'القوس', '♐', 'Sagittarius'),
  (12, 22, 'الجدي', '♑', 'Capricorn'),
];

List<String> get _chinese => isEn
    ? const ['Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake', 'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig']
    : const ['الفأر', 'الثور', 'النمر', 'الأرنب', 'التنين', 'الأفعى', 'الحصان', 'الماعز', 'القرد', 'الديك', 'الكلب', 'الخنزير'];

class _AgeToolState extends State<AgeTool> {
  DateTime? birth;
  TimeOfDay? birthTime;
  DateTime? atDate;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final b = s.getData<String>('age_birth');
    if (b != null) birth = DateTime.tryParse(b);
    final tm = s.getData<int>('age_time');
    if (tm != null) birthTime = TimeOfDay(hour: tm ~/ 60, minute: tm % 60);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && birth != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _save() {
    final s = context.read<AppState>();
    s.setData('age_birth', birth == null ? null : dkey(birth!));
    s.setData('age_time', birthTime == null ? null : birthTime!.hour * 60 + birthTime!.minute);
  }

  DateTime get _birthInstant =>
      DateTime(birth!.year, birth!.month, birth!.day, birthTime?.hour ?? 0, birthTime?.minute ?? 0);

  DateTime _birthdayIn(int y) {
    final b = birth!;
    if (b.month == 2 && b.day == 29 && !_leap(y)) return DateTime(y, 2, 28, birthTime?.hour ?? 0, birthTime?.minute ?? 0);
    return DateTime(y, b.month, b.day, birthTime?.hour ?? 0, birthTime?.minute ?? 0);
  }

  String _generation(int y) {
    if (y < 1928) return tr('الجيل الأعظم (Greatest Generation)', 'Greatest Generation');
    if (y <= 1945) return tr('الجيل الصامت (Silent Generation) 1928–1945', 'Silent Generation 1928–1945');
    if (y <= 1964) return tr('جيل الطفرة (Baby Boomers) 1946–1964', 'Baby Boomers 1946–1964');
    if (y <= 1980) return tr('الجيل إكس (Gen X) 1965–1980', 'Gen X 1965–1980');
    if (y <= 1996) return tr('جيل الألفية (Millennials / Gen Y) 1981–1996', 'Millennials / Gen Y 1981–1996');
    if (y <= 2012) return tr('جيل زد (Gen Z) 1997–2012', 'Gen Z 1997–2012');
    if (y <= 2024) return tr('جيل ألفا (Gen Alpha) 2013–2024', 'Gen Alpha 2013–2024');
    return tr('جيل بيتا (Gen Beta) 2025+', 'Gen Beta 2025+');
  }

  (String, String) _season(int m) => switch (m) {
        12 || 1 || 2 => (
            tr('الشتاء ❄️', 'Winter ❄️'),
            t('برد الشتاء ونسمة الشمال — موسم الدفا والشاي باللبن', 'برد الشتاء ونسيم الشمال — موسم الدفء والشاي بالحليب', 'Cool northerly breeze — the season of warmth and milk tea (Sudan seasons)')
          ),
        11 => (tr('بداية الشتاء 🍂', 'Early winter 🍂'), t('الجو بقى يبرد والحصاد شغّال', 'بدأ الجو يبرد والحصاد جارٍ', 'Weather cooling down and harvest under way (Sudan seasons)')),
        3 || 4 || 5 || 6 => (
            tr('الصيف ☀️', 'Summer ☀️'),
            t('حر السودان المعروف وموسم الهبوب والليمون بالنعناع', 'حرّ السودان المعروف وموسم العواصف الترابية والليمون بالنعناع', "Sudan's famous heat, haboob dust storms and lemon-mint season")
          ),
        7 || 8 || 9 => (
            t('الخريف 🌧️', 'موسم الأمطار 🌧️', 'Rainy season 🌧️'),
            t('موسم المطر في السودان — الأرض خضراء والوديان مليانة', 'موسم المطر في السودان — الأرض خضراء والأودية ممتلئة', 'Rainy season in Sudan — green land and full valleys')
          ),
        _ => (t('نهاية الخريف 🌾', 'نهاية موسم الأمطار 🌾', 'End of rainy season 🌾'), tr('آخر المطر وبداية موسم الحصاد', 'Last rains and start of the harvest')),
      };

  (String, String) _zodiacOf(DateTime d) {
    var z0 = _zodiac.last; // الجدي افتراضيًا
    for (final z in _zodiac) {
      if (d.month > z.$1 || (d.month == z.$1 && d.day >= z.$2)) z0 = z;
    }
    // قبل 20 يناير = الجدي
    if (d.month == 1 && d.day < 20) z0 = _zodiac.last;
    return (tr(z0.$3, z0.$5), z0.$4);
  }

  int _countWeekday(DateTime from, DateTime to, int wd) {
    final days = daysBetween(from, to);
    if (days <= 0) return 0;
    var n = (days ~/ 7);
    final rem = days % 7;
    for (var i = 0; i < rem; i++) {
      if (from.add(Duration(days: days - rem + i)).weekday == wd) n++;
    }
    return n;
  }

  int _leapDaysLived(DateTime from, DateTime to) {
    var n = 0;
    for (var y = from.year; y <= to.year; y++) {
      if (!_leap(y)) continue;
      final f = DateTime(y, 2, 29);
      if (!f.isBefore(dateOnly(from)) && !f.isAfter(dateOnly(to))) n++;
    }
    return n;
  }

  _Ymd? _hijriAge(int shift) {
    try {
      final hb = toHijri(birth!, shift: shift);
      final ht = toHijri(DateTime.now(), shift: shift);
      var y = ht.y - hb.y, m = ht.m - hb.m, d = ht.d - hb.d;
      if (d < 0) {
        m--;
        final pm = ht.m == 1 ? 12 : ht.m - 1;
        final py = ht.m == 1 ? ht.y - 1 : ht.y;
        d += hijriMonthLength(py, pm);
      }
      if (m < 0) {
        y--;
        m += 12;
      }
      return _Ymd(y, m, d);
    } catch (_) {
      return null;
    }
  }

  String? _hijriBirth(int shift) {
    try {
      return hijriText(birth!, shift: shift);
    } catch (_) {
      return null;
    }
  }

  List<(String, DateTime)> _milestones() {
    final b = _birthInstant;
    final out = <(String, DateTime)>[];
    for (final d in [1000, 5000, 10000, 12345, 15000, 20000, 25000, 30000]) {
      out.add((tr('${fmt(d, 0)} يوم', '${fmt(d, 0)} days'), b.add(Duration(days: d))));
    }
    for (final w in [500, 1000, 2000, 3000, 4000]) {
      out.add((tr('${fmt(w, 0)} أسبوع', '${fmt(w, 0)} weeks'), b.add(Duration(days: w * 7))));
    }
    for (final m in [100, 250, 500, 750, 1000]) {
      out.add((tr('${fmt(m, 0)} شهر', '${fmt(m, 0)} months'), DateTime(b.year, b.month + m, b.day, b.hour, b.minute)));
    }
    for (final h in [100000, 250000, 500000]) {
      out.add((tr('${fmt(h, 0)} ساعة', '${fmt(h, 0)} hours'), b.add(Duration(hours: h))));
    }
    for (final mi in [1000000, 10000000, 20000000, 30000000]) {
      out.add((tr('${fmt(mi, 0)} دقيقة', '${fmt(mi, 0)} minutes'), b.add(Duration(minutes: mi))));
    }
    for (final s in [100000000, 500000000, 1000000000, 1500000000, 2000000000]) {
      out.add((tr('${fmt(s, 0)} ثانية${s == 1000000000 ? ' (مليار!)' : ''}', '${fmt(s, 0)} seconds${s == 1000000000 ? ' (a billion!)' : ''}'), b.add(Duration(seconds: s))));
    }
    out.sort((a, c) => a.$2.compareTo(c.$2));
    return out.where((e) => e.$2.year <= b.year + 100).toList();
  }

  String _summary(AppState s) {
    if (birth == null) return '';
    final now = DateTime.now();
    final a = _diff(birth!, now);
    final el = now.difference(_birthInstant);
    final h = _hijriBirth(s.hijriShift);
    var nb = _birthdayIn(now.year);
    if (!nb.isAfter(now)) nb = _birthdayIn(now.year + 1);
    return [
      tr('🎂 حاسبة العمر', '🎂 Age calculator'),
      '${tr('تاريخ الميلاد', 'Date of birth')}: ${fmtDateAr(birth!)}${birthTime != null ? ' — ${fmtTimeAr(_birthInstant)}' : ''}',
      tr('العمر: ${a.y} سنة و${a.m} شهر و${a.d} يوم', 'Age: ${a.y} years, ${a.m} months, ${a.d} days'),
      t('يعني: ${fmt(el.inDays, 0)} يوم = ${fmt(el.inHours, 0)} ساعة = ${fmt(el.inMinutes, 0)} دقيقة', 'أي: ${fmt(el.inDays, 0)} يوم = ${fmt(el.inHours, 0)} ساعة = ${fmt(el.inMinutes, 0)} دقيقة',
          'That is: ${fmt(el.inDays, 0)} days = ${fmt(el.inHours, 0)} hours = ${fmt(el.inMinutes, 0)} minutes'),
      if (h != null) '${tr('الميلاد بالهجري', 'Hijri birth date')}: $h',
      '${tr('بالقبطي', 'Coptic')}: ${copticText(birth!)}',
      t('العيد الجاي: ${fmtDateAr(nb)} (بعد ${daysBetween(now, nb)} يوم)', 'عيد الميلاد القادم: ${fmtDateAr(nb)} (بعد ${daysBetween(now, nb)} يوم)',
          'Next birthday: ${fmtDateAr(nb)} (in ${daysBetween(now, nb)} days)'),
      tr('عمرك على المريخ: ${fmt(el.inSeconds / (365.25 * 86400) / 1.8808158, 2)} سنة مريخية', 'Age on Mars: ${fmt(el.inSeconds / (365.25 * 86400) / 1.8808158, 2)} Martian years'),
    ].join('\n');
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: birthTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: t('ساعة الميلاد (لو عارفها)', 'وقت الميلاد (إن كنت تعرفه)', 'Birth time (if you know it)'),
      cancelText: t('خلاص', 'إلغاء', 'Cancel'),
      confirmText: t('تمام', 'موافق', 'OK'),
    );
    if (picked != null) {
      setState(() => birthTime = picked);
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    return ToolList(children: [
      SCard(
        title: t('ميلادك متين؟', 'متى ميلادك؟', 'When were you born?'),
        icon: Icons.cake_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DateButton(
            label: tr('تاريخ الميلاد', 'Date of birth'),
            value: birth,
            first: DateTime(1900),
            last: now,
            onPick: (d) {
              setState(() => birth = d);
              _save();
              s.awardDaily('age_calc', 3, t('حسبت عمرك', 'حسبت عمرك', 'Calculated your age'));
            },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(birthTime == null
                    ? t('ساعة الميلاد (اختياري)', 'وقت الميلاد (اختياري)', 'Birth time (optional)')
                    : '${tr('الساعة', 'Time')}: ${fmtTimeAr(DateTime(2000, 1, 1, birthTime!.hour, birthTime!.minute))}'),
              ),
            ),
            if (birthTime != null)
              IconButton(
                tooltip: t('شيل الساعة', 'أزل الوقت', 'Clear time'),
                onPressed: () {
                  setState(() => birthTime = null);
                  _save();
                },
                icon: const Icon(Icons.close_rounded),
              ),
          ]),
        ]),
      ),
      if (birth == null)
        NoteBox(
            t('أختار تاريخ ميلادك فوق، ونحسب ليك عمرك بالتفصيل الممل: بالثواني، بالهجري، على المريخ، والعيد الجاي… كلو 😄',
                'اختر تاريخ ميلادك في الأعلى، وسنحسب عمرك بكل التفاصيل: بالثواني، بالهجري، على المريخ، وعيد ميلادك القادم… كل شيء 😄',
                'Pick your birth date above and we\'ll work out your age in every detail: in seconds, in Hijri, on Mars, your next birthday… everything 😄'),
            kind: NoteKind.tip)
      else
        ..._results(s, now),
    ]);
  }

  List<Widget> _results(AppState s, DateTime now) {
    final b = birth!;
    final bi = _birthInstant;
    final a = _diff(b, now);
    final el = now.difference(bi);
    final secs = el.inSeconds;
    final minutes = secs / 60;
    final days = secs / 86400;
    final earthYears = secs / (365.25 * 86400);
    final totalMonths = a.y * 12 + a.m;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);

    // العيد الجاي
    var nb = _birthdayIn(now.year);
    final todayBirthday = nb.month == now.month && nb.day == now.day;
    if (!nb.isAfter(now)) nb = _birthdayIn(now.year + 1);
    final toNb = nb.difference(now);
    final lastB = _birthdayIn(nb.year - 1);
    final yearProg = (now.difference(lastB).inSeconds / nb.difference(lastB).inSeconds).clamp(0.0, 1.0);
    final turning = nb.year - b.year;

    final hb = _hijriBirth(s.hijriShift);
    final ha = _hijriAge(s.hijriShift);
    final season = _season(b.month);
    final zod = _zodiacOf(b);
    final chinese = _chinese[((b.year - 4) % 12 + 12) % 12];
    final dayOfYear = daysBetween(DateTime(b.year, 1, 1), b) + 1;

    return [
      if (todayBirthday)
        NoteBox(
            t('🎉 عيد ميلادك الليلة! كل سنة وانت طيب، ربنا يديك العمر والصحة والعافية 🎂', '🎉 اليوم عيد ميلادك! كل عام وأنت بخير، أطال الله عمرك في صحة وعافية 🎂',
                '🎉 Happy birthday! Wishing you a long life full of health and wellbeing 🎂'),
            kind: NoteKind.tip),
      ResultHero(
        label: tr('عمرك بالضبط', 'Your exact age'),
        value: tr('${a.y} سنة', '${a.y} years'),
        sub: tr('${a.m} شهر و ${a.d} يوم${birthTime != null ? ' و ${el.inHours % 24} ساعة' : ''}',
            '${a.m} months, ${a.d} days${birthTime != null ? ', ${el.inHours % 24} hours' : ''}'),
        colors: const [SD.henna, SD.pink, SD.purple],
      ),
      SectionTitle(tr('العدّاد الحي', 'Live counter'), icon: Icons.timer_rounded, trailing: _liveDot()),
      StatGrid([
        StatChip(fmt(totalMonths, 0), tr('شهر', 'months'), color: SD.henna, icon: Icons.calendar_view_month_rounded),
        StatChip(fmt(el.inDays ~/ 7, 0), tr('أسبوع', 'weeks'), color: SD.gold, icon: Icons.view_week_rounded),
        StatChip(fmt(el.inDays, 0), tr('يوم', 'days'), color: SD.teal, icon: Icons.today_rounded),
        StatChip(fmt(el.inHours, 0), tr('ساعة', 'hours'), color: SD.nile, icon: Icons.hourglass_bottom_rounded),
        StatChip(fmt(el.inMinutes, 0), tr('دقيقة', 'minutes'), color: SD.purple, icon: Icons.av_timer_rounded),
        StatChip(fmt(secs, 0), tr('ثانية', 'seconds'), color: SD.pink, icon: Icons.bolt_rounded),
      ]),
      const SizedBox(height: 6),
      Text(tr('العمر بالكسور: ${earthYears.toStringAsFixed(8)} سنة', 'Decimal age: ${earthYears.toStringAsFixed(8)} years'),
          textAlign: TextAlign.center, style: TextStyle(color: muted, fontFeatures: const [FontFeature.tabularFigures()])),
      if (birthTime == null)
        Text(t('(من نص الليل — لو ضفت ساعة الميلاد بتبقى أدق)', '(من منتصف الليل — إضافة وقت الميلاد تجعلها أدق)', '(from midnight — add your birth time for more accuracy)'),
            textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 14),
      SCard(
        title: t('عيد ميلادك الجاي', 'عيد ميلادك القادم', 'Your next birthday'),
        icon: Icons.celebration_rounded,
        color: SD.pink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _cd(toNb.inDays, tr('يوم', 'days')),
            _cd(toNb.inHours % 24, tr('ساعة', 'hours')),
            _cd(toNb.inMinutes % 60, tr('دقيقة', 'min')),
            _cd(toNb.inSeconds % 60, tr('ثانية', 'sec')),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: yearProg, minHeight: 10, color: SD.pink, backgroundColor: SD.pink.withValues(alpha: .12)),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Text(t('قطعت ${fmt(yearProg * 100, 1)}% من سنتك الحالية', 'أنهيت ${fmt(yearProg * 100, 1)}% من سنتك الحالية', "You're ${fmt(yearProg * 100, 1)}% through your current year"),
                textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
          ),
          InfoRow(tr('التاريخ', 'Date'), fmtDateAr(nb), icon: Icons.event_rounded),
          InfoRow(tr('يوافق يوم', 'Falls on'), weekdaysAr[nb.weekday - 1], icon: Icons.calendar_today_rounded, valueColor: SD.pink),
          InfoRow(t('حتكمّل', 'ستُكمل', "You'll turn"), tr('$turning سنة', '$turning'), icon: Icons.cake_rounded),
          if (b.month == 2 && b.day == 29)
            NoteBox(t('مولود في 29 فبراير! في السنين العادية بنحسب عيدك يوم 28 فبراير 😉', 'مولود في 29 فبراير! في السنوات العادية نحسب عيد ميلادك يوم 28 فبراير 😉',
                'Born on 29 February! In common years we count your birthday on 28 February 😉')),
          ..._nextWeekdays(nb),
        ]),
      ),
      SCard(
        title: tr('يوم ميلادك', 'The day you were born'),
        icon: Icons.child_care_rounded,
        color: SD.teal,
        child: Column(children: [
          InfoRow(t('اتولدت يوم', 'وُلدت يوم', 'Born on a'), weekdaysAr[b.weekday - 1], icon: Icons.wb_twilight_rounded, valueColor: SD.teal),
          InfoRow(tr('بالهجري', 'Hijri'), hb ?? tr('خارج نطاق تقويم أم القرى (1937–2077)', 'Outside the Umm al-Qura range (1937–2077)'), icon: Icons.nightlight_round),
          if (ha != null)
            InfoRow(tr('عمرك بالهجري', 'Age in Hijri years'), tr('${ha.y} سنة و${ha.m} شهر و${ha.d} يوم', '${ha.y} years, ${ha.m} months, ${ha.d} days'),
                icon: Icons.mosque_rounded, valueColor: SD.green),
          InfoRow(tr('بالقبطي', 'Coptic'), copticText(b), icon: Icons.wb_sunny_outlined, hint: tr('تقويم الشهور الزراعية (توت، بابه…)', 'The agricultural calendar (Thout, Paopi…)')),
          InfoRow(tr('بالإثيوبي', 'Ethiopian'), ethiopianText(b), icon: Icons.public_rounded),
          InfoRow(tr('رقم اليوم في سنتها', 'Day of that year'), tr('$dayOfYear من ${_leap(b.year) ? 366 : 365}', '$dayOfYear of ${_leap(b.year) ? 366 : 365}'),
              icon: Icons.format_list_numbered_rounded),
          InfoRow(tr('سنة كبيسة؟', 'Leap year?'),
              _leap(b.year) ? t('أيوه، ${b.year} كبيسة', 'نعم، ${b.year} كبيسة', 'Yes, ${b.year} is a leap year') : tr('لا، ${b.year} سنة عادية', 'No, ${b.year} is a common year'),
              icon: Icons.event_repeat_rounded),
          InfoRow(tr('جيلك', 'Your generation'), _generation(b.year), icon: Icons.groups_rounded),
          InfoRow(tr('موسم ميلادك', 'Birth season'), season.$1, hint: season.$2, icon: Icons.thermostat_rounded, valueColor: SD.henna),
        ]),
      ),
      SCard(
        title: tr('عمرك في الكواكب', 'Your age on other planets'),
        icon: Icons.public_rounded,
        color: SD.indigo,
        child: Column(children: [
          for (final p in _planets) _planetRow(p, earthYears, bi),
          InfoRow(tr('بالأيام المريخية (سول)', 'Martian days (sols)'), fmt(secs / 88775.244, 1), icon: Icons.brightness_3_rounded,
              hint: tr('السول = 24 ساعة و39 دقيقة و35 ثانية', 'A sol = 24 h 39 min 35 s')),
          InfoRow(tr('لفّات حول الشمس', 'Trips around the Sun'), fmt(earthYears, 3), icon: Icons.sync_rounded),
          InfoRow(tr('مسافة سفرك مع الأرض حول الشمس', 'Distance travelled with Earth around the Sun'), tr('${fmt(earthYears * 940, 0)} مليون كم', '${fmt(earthYears * 940, 0)} million km'),
              icon: Icons.rocket_launch_rounded, hint: tr('حوالي 940 مليون كم كل سنة', 'About 940 million km a year')),
          InfoRow(t('أقمار كاملة (بدر) شفتها', 'أقمار مكتملة (بدر) رأيتها', 'Full moons seen'), fmt(days / 29.530589, 0), icon: Icons.brightness_2_rounded),
        ]),
      ),
      SCard(
        title: tr('حياتك بالأرقام', 'Your life in numbers'),
        icon: Icons.favorite_rounded,
        color: SD.red,
        child: Column(children: [
          NoteBox(t('الأرقام دي تقديرية (متوسطات عامة) للتسلية والمعلومة، مش قياس طبي.', 'هذه الأرقام تقديرية (متوسطات عامة) للتسلية والمعلومة، وليست قياسًا طبيًا.',
              'These are rough estimates (general averages) for fun and trivia, not medical measurements.'), kind: NoteKind.warn),
          InfoRow(tr('دقات قلبك', 'Heartbeats'), '≈ ${fmt(minutes * 80, 0)}', icon: Icons.monitor_heart_rounded, hint: tr('على متوسط 80 دقة في الدقيقة', 'At an average of 80 bpm'), valueColor: SD.red),
          InfoRow(tr('أنفاسك', 'Breaths'), '≈ ${fmt(minutes * 16, 0)}', icon: Icons.air_rounded, hint: tr('حوالي 16 نفس في الدقيقة', 'About 16 breaths a minute')),
          InfoRow(t('الدم الضخّه قلبك', 'الدم الذي ضخّه قلبك', 'Blood pumped by your heart'), tr('≈ ${fmt(minutes * 5 / 1000, 0)} ألف لتر', '≈ ${fmt(minutes * 5 / 1000, 0)} thousand liters'),
              icon: Icons.bloodtype_rounded, hint: tr('حوالي 5 لتر في الدقيقة', 'About 5 liters a minute')),
          InfoRow(t('نمت حوالي', 'نمت حوالي', 'Time asleep'), tr('${fmt(earthYears / 3, 1)} سنة', '${fmt(earthYears / 3, 1)} years'), icon: Icons.bedtime_rounded,
              hint: t('لو تلت عمرك نوم (${fmt(el.inHours / 3, 0)} ساعة)', 'إن كان ثلث عمرك نومًا (${fmt(el.inHours / 3, 0)} ساعة)', 'If a third of your life is sleep (${fmt(el.inHours / 3, 0)} hours)')),
          InfoRow(tr('رمشة عين', 'Blinks'), '≈ ${fmt(minutes * 2 / 3 * 15, 0)}', icon: Icons.remove_red_eye_rounded,
              hint: t('15 رمشة في الدقيقة وانت صاحي', '15 رمشة في الدقيقة أثناء اليقظة', '15 blinks a minute while awake')),
          InfoRow(tr('وجبات أكلتها', 'Meals eaten'), '≈ ${fmt(days * 3, 0)}', icon: Icons.restaurant_rounded,
              hint: t('3 وجبات في اليوم — فطور وغدا وعشا', '3 وجبات في اليوم — فطور وغداء وعشاء', '3 meals a day — breakfast, lunch and dinner')),
          InfoRow(t('شعرك طوّل', 'طول شعرك', 'Hair grown'), tr('≈ ${fmt(totalMonths * 1.25 / 100, 1)} متر', '≈ ${fmt(totalMonths * 1.25 / 100, 1)} m'), icon: Icons.content_cut_rounded,
              hint: t('لو ما حلقته أبدًا (حوالي 1.25 سم في الشهر)', 'لو لم تحلقه أبدًا (حوالي 1.25 سم في الشهر)', 'If never cut (about 1.25 cm a month)')),
          InfoRow(t('جُمَع عشتها', 'أيام الجمعة التي عشتها', 'Fridays lived'), fmt(_countWeekday(b, now, DateTime.friday), 0), icon: Icons.mosque_rounded, valueColor: SD.green),
          InfoRow(t('رمضانات عاصرتها', 'رمضانات عاصرتها', 'Ramadans lived'), '≈ ${fmt(ha?.y ?? (days / 354.367).floor(), 0)}', icon: Icons.nights_stay_rounded),
          InfoRow(t('أيام 29 فبراير عشتها', 'أيام 29 فبراير التي عشتها', '29 Februaries lived'), fmt(_leapDaysLived(b, now), 0), icon: Icons.event_available_rounded),
        ]),
      ),
      SCard(
        title: tr('محطات عمرك', 'Life milestones'),
        icon: Icons.flag_rounded,
        color: SD.gold,
        child: Column(children: [for (final m in _milestones()) _milestoneRow(m, now)]),
      ),
      SCard(
        title: tr('عمرك في تاريخ معيّن', 'Your age on a given date'),
        icon: Icons.event_note_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DateButton(
            label: t('التاريخ (ماضي أو جاي)', 'التاريخ (ماضٍ أو قادم)', 'Date (past or future)'),
            value: atDate,
            first: b,
            last: DateTime(b.year + 150),
            color: SD.nile,
            onPick: (d) => setState(() => atDate = d),
          ),
          if (atDate != null) ...[
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final x = _diff(b, atDate!);
              return Column(children: [
                InfoRow(t('عمرك يومها', 'عمرك يومها', 'Your age then'), tr('${x.y} سنة و${x.m} شهر و${x.d} يوم', '${x.y} years, ${x.m} months, ${x.d} days'), valueColor: SD.nile),
                InfoRow(tr('بالأيام', 'In days'), fmt(daysBetween(b, atDate!), 0)),
                InfoRow(atDate!.isAfter(now) ? t('باقي ليهو', 'متبقٍ عليه', 'Days to go') : t('فات عليهو', 'مضى عليه', 'Days since'),
                    tr('${fmt(daysBetween(now, atDate!).abs(), 0)} يوم', '${fmt(daysBetween(now, atDate!).abs(), 0)} days')),
              ]);
            }),
          ],
        ]),
      ),
      SCard(
        title: t('معلومة فلكية بس', 'معلومة فلكية فقط', 'Astronomical trivia only'),
        icon: Icons.stars_rounded,
        color: SD.red,
        child: NoteBox(
          '${tr('البرج حسب التاريخ', 'Zodiac sign by date')}: ${zod.$1} ${zod.$2}\n'
          '${tr('الحيوان في التقويم الصيني', 'Chinese zodiac animal')}: $chinese (${b.month <= 2 ? tr('تقريبي لأن رأس السنة الصينية بين يناير وفبراير', 'approximate, since Chinese New Year falls between January and February') : tr('حسب السنة', 'by year')})\n\n'
          '${t('التنجيم وادّعاء معرفة الحظ والمستقبل من الأبراج كذب وشرك ومحرّم شرعًا؛ نعرضها للمعلومة الفلكية بس ولا علاقة ليها بشخصيتك أو مستقبلك.', 'التنجيم وادّعاء معرفة الحظ والمستقبل من الأبراج كذب وشرك ومحرّم شرعًا؛ نعرضها للمعلومة الفلكية فقط ولا علاقة لها بشخصيتك أو مستقبلك.', 'Astrology and claiming to know fate or the future from zodiac signs is false and shirk (forbidden in Islam); shown only as astronomical trivia, unrelated to your personality or future.')}',
          kind: NoteKind.danger,
        ),
      ),
      ShareBar(() => _summary(s)),
    ];
  }

  List<Widget> _nextWeekdays(DateTime nb) {
    final ys = [for (var i = 1; i <= 4; i++) _birthdayIn(nb.year + i)];
    return [
      Padding(
        padding: const EdgeInsetsDirectional.only(top: 10),
        child: Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
          for (final d in ys)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${d.year}: ${weekdaysAr[d.weekday - 1]}', style: const TextStyle(fontSize: 12)),
            ),
        ]),
      ),
    ];
  }

  Widget _liveDot() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: SD.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 9, color: DateTime.now().second.isEven ? SD.red : SD.red.withValues(alpha: .3)),
          const SizedBox(width: 5),
          Text(tr('مباشر', 'Live'), style: const TextStyle(color: SD.red, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );

  Widget _cd(int v, String l) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [SD.pink.withValues(alpha: .18), SD.purple.withValues(alpha: .12)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(two(v), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: SD.pink, fontFeatures: [FontFeature.tabularFigures()])),
            Text(l, style: const TextStyle(fontSize: 11.5)),
          ]),
        ),
      );

  Widget _planetRow((String, String, double, Color) p, double earthYears, DateTime bi) {
    final age = earthYears / p.$3;
    final next = bi.add(Duration(seconds: ((age.floor() + 1) * p.$3 * 365.25 * 86400).round()));
    return InfoRow(
      tr('${p.$2} على ${p.$1}', '${p.$2} On ${p.$1}'),
      tr('${fmt(age, 2)} سنة', '${fmt(age, 2)} years'),
      hint: t('سنتها = ${fmt(p.$3 * 365.25, 1)} يوم أرضي • عيدك الجاي هناك: ${next.year > 9999 ? '—' : fmtDateAr(next, weekday: false)}',
          'سنته = ${fmt(p.$3 * 365.25, 1)} يومًا أرضيًا • عيد ميلادك القادم هناك: ${next.year > 9999 ? '—' : fmtDateAr(next, weekday: false)}',
          'One year = ${fmt(p.$3 * 365.25, 1)} Earth days • next birthday there: ${next.year > 9999 ? '—' : fmtDateAr(next, weekday: false)}'),
      valueColor: p.$4,
    );
  }

  Widget _milestoneRow((String, DateTime) m, DateTime now) {
    final past = m.$2.isBefore(now);
    final dd = daysBetween(now, m.$2);
    final soon = !past && dd <= 60;
    return InfoRow(
      m.$1,
      fmtDateAr(m.$2, weekday: false),
      icon: past ? Icons.check_circle_rounded : (soon ? Icons.notifications_active_rounded : Icons.radio_button_unchecked_rounded),
      hint: past
          ? t('فات من ${fmt(-dd, 0)} يوم ✓', 'مضى منذ ${fmt(-dd, 0)} يوم ✓', '${fmt(-dd, 0)} days ago ✓')
          : (dd == 0 ? t('الليلة! 🎉', 'اليوم! 🎉', 'Today! 🎉') : t('باقي ${fmt(dd, 0)} يوم', 'متبقٍ ${fmt(dd, 0)} يوم', 'in ${fmt(dd, 0)} days')),
      valueColor: past ? SD.green : (soon ? SD.pink : SD.gold),
    );
  }
}
