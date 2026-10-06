import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
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

const _planets = [
  ('عطارد', '☿️', 0.2408467, SD.orange),
  ('الزُّهرة', '♀️', 0.61519726, SD.gold),
  ('المريخ', '🔴', 1.8808158, SD.red),
  ('المشتري', '🪐', 11.862615, SD.henna),
  ('زحل', '🪐', 29.447498, SD.coffee),
  ('أورانوس', '🔵', 84.016846, SD.teal),
  ('نبتون', '🔷', 164.79132, SD.indigo),
];

const _zodiac = [
  // (شهر البداية، يوم البداية، الاسم، الرمز)
  (1, 20, 'الدلو', '♒'),
  (2, 19, 'الحوت', '♓'),
  (3, 21, 'الحمل', '♈'),
  (4, 20, 'الثور', '♉'),
  (5, 21, 'الجوزاء', '♊'),
  (6, 21, 'السرطان', '♋'),
  (7, 23, 'الأسد', '♌'),
  (8, 23, 'العذراء', '♍'),
  (9, 23, 'الميزان', '♎'),
  (10, 23, 'العقرب', '♏'),
  (11, 22, 'القوس', '♐'),
  (12, 22, 'الجدي', '♑'),
];

const _chinese = ['الفأر', 'الثور', 'النمر', 'الأرنب', 'التنين', 'الأفعى', 'الحصان', 'الماعز', 'القرد', 'الديك', 'الكلب', 'الخنزير'];

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
    final t = s.getData<int>('age_time');
    if (t != null) birthTime = TimeOfDay(hour: t ~/ 60, minute: t % 60);
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
    if (y < 1928) return 'الجيل الأعظم (Greatest Generation)';
    if (y <= 1945) return 'الجيل الصامت (Silent Generation) 1928–1945';
    if (y <= 1964) return 'جيل الطفرة (Baby Boomers) 1946–1964';
    if (y <= 1980) return 'الجيل إكس (Gen X) 1965–1980';
    if (y <= 1996) return 'جيل الألفية (Millennials / Gen Y) 1981–1996';
    if (y <= 2012) return 'جيل زد (Gen Z) 1997–2012';
    if (y <= 2024) return 'جيل ألفا (Gen Alpha) 2013–2024';
    return 'جيل بيتا (Gen Beta) 2025+';
  }

  (String, String) _season(int m) => switch (m) {
        12 || 1 || 2 => ('الشتاء ❄️', 'برد الشتاء ونسمة الشمال — موسم الدفا والشاي باللبن'),
        11 => ('بداية الشتاء 🍂', 'الجو بقى يبرد والحصاد شغّال'),
        3 || 4 || 5 || 6 => ('الصيف ☀️', 'حر السودان المعروف وموسم الهبوب والليمون بالنعناع'),
        7 || 8 || 9 => ('الخريف 🌧️', 'موسم المطر في السودان — الأرض خضراء والوديان مليانة'),
        _ => ('نهاية الخريف 🌾', 'آخر المطر وبداية موسم الحصاد'),
      };

  (String, String) _zodiacOf(DateTime d) {
    var r = (_zodiac.last.$3, _zodiac.last.$4); // الجدي افتراضيًا
    for (final z in _zodiac) {
      if (d.month > z.$1 || (d.month == z.$1 && d.day >= z.$2)) r = (z.$3, z.$4);
    }
    // قبل 20 يناير = الجدي
    if (d.month == 1 && d.day < 20) r = ('الجدي', '♑');
    return r;
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
      out.add(('${fmt(d, 0)} يوم', b.add(Duration(days: d))));
    }
    for (final w in [500, 1000, 2000, 3000, 4000]) {
      out.add(('${fmt(w, 0)} أسبوع', b.add(Duration(days: w * 7))));
    }
    for (final m in [100, 250, 500, 750, 1000]) {
      out.add(('${fmt(m, 0)} شهر', DateTime(b.year, b.month + m, b.day, b.hour, b.minute)));
    }
    for (final h in [100000, 250000, 500000]) {
      out.add(('${fmt(h, 0)} ساعة', b.add(Duration(hours: h))));
    }
    for (final mi in [1000000, 10000000, 20000000, 30000000]) {
      out.add(('${fmt(mi, 0)} دقيقة', b.add(Duration(minutes: mi))));
    }
    for (final s in [100000000, 500000000, 1000000000, 1500000000, 2000000000]) {
      out.add(('${fmt(s, 0)} ثانية${s == 1000000000 ? ' (مليار!)' : ''}', b.add(Duration(seconds: s))));
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
      '🎂 حاسبة العمر',
      'تاريخ الميلاد: ${fmtDateAr(birth!)}${birthTime != null ? ' — ${fmtTimeAr(_birthInstant)}' : ''}',
      'العمر: ${a.y} سنة و${a.m} شهر و${a.d} يوم',
      'يعني: ${fmt(el.inDays, 0)} يوم = ${fmt(el.inHours, 0)} ساعة = ${fmt(el.inMinutes, 0)} دقيقة',
      if (h != null) 'الميلاد بالهجري: $h',
      'بالقبطي: ${copticText(birth!)}',
      'العيد الجاي: ${fmtDateAr(nb)} (بعد ${daysBetween(now, nb)} يوم)',
      'عمرك على المريخ: ${fmt(el.inSeconds / (365.25 * 86400) / 1.8808158, 2)} سنة مريخية',
    ].join('\n');
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: birthTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'ساعة الميلاد (لو عارفها)',
      cancelText: 'خلاص',
      confirmText: 'تمام',
    );
    if (t != null) {
      setState(() => birthTime = t);
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    return ToolList(children: [
      SCard(
        title: 'ميلادك متين؟',
        icon: Icons.cake_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DateButton(
            label: 'تاريخ الميلاد',
            value: birth,
            first: DateTime(1900),
            last: now,
            onPick: (d) {
              setState(() => birth = d);
              _save();
              s.awardDaily('age_calc', 3, 'حسبت عمرك');
            },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(birthTime == null ? 'ساعة الميلاد (اختياري)' : 'الساعة: ${fmtTimeAr(DateTime(2000, 1, 1, birthTime!.hour, birthTime!.minute))}'),
              ),
            ),
            if (birthTime != null)
              IconButton(
                tooltip: 'شيل الساعة',
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
        const NoteBox('أختار تاريخ ميلادك فوق، ونحسب ليك عمرك بالتفصيل الممل: بالثواني، بالهجري، على المريخ، والعيد الجاي… كلو 😄',
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
        const NoteBox('🎉 عيد ميلادك الليلة! كل سنة وانت طيب، ربنا يديك العمر والصحة والعافية 🎂', kind: NoteKind.tip),
      ResultHero(
        label: 'عمرك بالضبط',
        value: '${a.y} سنة',
        sub: '${a.m} شهر و ${a.d} يوم${birthTime != null ? ' و ${el.inHours % 24} ساعة' : ''}',
        colors: const [SD.henna, SD.pink, SD.purple],
      ),
      SectionTitle('العدّاد الحي', icon: Icons.timer_rounded, trailing: _liveDot()),
      StatGrid([
        StatChip(fmt(totalMonths, 0), 'شهر', color: SD.henna, icon: Icons.calendar_view_month_rounded),
        StatChip(fmt(el.inDays ~/ 7, 0), 'أسبوع', color: SD.gold, icon: Icons.view_week_rounded),
        StatChip(fmt(el.inDays, 0), 'يوم', color: SD.teal, icon: Icons.today_rounded),
        StatChip(fmt(el.inHours, 0), 'ساعة', color: SD.nile, icon: Icons.hourglass_bottom_rounded),
        StatChip(fmt(el.inMinutes, 0), 'دقيقة', color: SD.purple, icon: Icons.av_timer_rounded),
        StatChip(fmt(secs, 0), 'ثانية', color: SD.pink, icon: Icons.bolt_rounded),
      ]),
      const SizedBox(height: 6),
      Text('العمر بالكسور: ${earthYears.toStringAsFixed(8)} سنة',
          textAlign: TextAlign.center, style: TextStyle(color: muted, fontFeatures: const [FontFeature.tabularFigures()])),
      if (birthTime == null)
        Text('(من نص الليل — لو ضفت ساعة الميلاد بتبقى أدق)', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 14),
      SCard(
        title: 'عيد ميلادك الجاي',
        icon: Icons.celebration_rounded,
        color: SD.pink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _cd(toNb.inDays, 'يوم'),
            _cd(toNb.inHours % 24, 'ساعة'),
            _cd(toNb.inMinutes % 60, 'دقيقة'),
            _cd(toNb.inSeconds % 60, 'ثانية'),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: yearProg, minHeight: 10, color: SD.pink, backgroundColor: SD.pink.withValues(alpha: .12)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('قطعت ${fmt(yearProg * 100, 1)}% من سنتك الحالية', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
          ),
          InfoRow('التاريخ', fmtDateAr(nb), icon: Icons.event_rounded),
          InfoRow('يوافق يوم', weekdaysAr[nb.weekday - 1], icon: Icons.calendar_today_rounded, valueColor: SD.pink),
          InfoRow('حتكمّل', '$turning سنة', icon: Icons.cake_rounded),
          if (b.month == 2 && b.day == 29) const NoteBox('مولود في 29 فبراير! في السنين العادية بنحسب عيدك يوم 28 فبراير 😉'),
          ..._nextWeekdays(nb),
        ]),
      ),
      SCard(
        title: 'يوم ميلادك',
        icon: Icons.child_care_rounded,
        color: SD.teal,
        child: Column(children: [
          InfoRow('اتولدت يوم', weekdaysAr[b.weekday - 1], icon: Icons.wb_twilight_rounded, valueColor: SD.teal),
          InfoRow('بالهجري', hb ?? 'خارج نطاق تقويم أم القرى (1937–2077)', icon: Icons.nightlight_round),
          if (ha != null) InfoRow('عمرك بالهجري', '${ha.y} سنة و${ha.m} شهر و${ha.d} يوم', icon: Icons.mosque_rounded, valueColor: SD.green),
          InfoRow('بالقبطي', copticText(b), icon: Icons.wb_sunny_outlined, hint: 'تقويم الشهور الزراعية (توت، بابه…)'),
          InfoRow('بالإثيوبي', ethiopianText(b), icon: Icons.public_rounded),
          InfoRow('رقم اليوم في سنتها', '$dayOfYear من ${_leap(b.year) ? 366 : 365}', icon: Icons.format_list_numbered_rounded),
          InfoRow('سنة كبيسة؟', _leap(b.year) ? 'أيوه، ${b.year} كبيسة' : 'لا، ${b.year} سنة عادية', icon: Icons.event_repeat_rounded),
          InfoRow('جيلك', _generation(b.year), icon: Icons.groups_rounded),
          InfoRow('موسم ميلادك', season.$1, hint: season.$2, icon: Icons.thermostat_rounded, valueColor: SD.henna),
        ]),
      ),
      SCard(
        title: 'عمرك في الكواكب',
        icon: Icons.public_rounded,
        color: SD.indigo,
        child: Column(children: [
          for (final p in _planets) _planetRow(p, earthYears, bi),
          InfoRow('بالأيام المريخية (سول)', fmt(secs / 88775.244, 1), icon: Icons.brightness_3_rounded, hint: 'السول = 24 ساعة و39 دقيقة و35 ثانية'),
          InfoRow('لفّات حول الشمس', fmt(earthYears, 3), icon: Icons.sync_rounded),
          InfoRow('مسافة سفرك مع الأرض حول الشمس', '${fmt(earthYears * 940, 0)} مليون كم', icon: Icons.rocket_launch_rounded, hint: 'حوالي 940 مليون كم كل سنة'),
          InfoRow('أقمار كاملة (بدر) شفتها', fmt(days / 29.530589, 0), icon: Icons.brightness_2_rounded),
        ]),
      ),
      SCard(
        title: 'حياتك بالأرقام',
        icon: Icons.favorite_rounded,
        color: SD.red,
        child: Column(children: [
          const NoteBox('الأرقام دي تقديرية (متوسطات عامة) للتسلية والمعلومة، مش قياس طبي.', kind: NoteKind.warn),
          InfoRow('دقات قلبك', '≈ ${fmt(minutes * 80, 0)}', icon: Icons.monitor_heart_rounded, hint: 'على متوسط 80 دقة في الدقيقة', valueColor: SD.red),
          InfoRow('أنفاسك', '≈ ${fmt(minutes * 16, 0)}', icon: Icons.air_rounded, hint: 'حوالي 16 نفس في الدقيقة'),
          InfoRow('الدم الضخّه قلبك', '≈ ${fmt(minutes * 5 / 1000, 0)} ألف لتر', icon: Icons.bloodtype_rounded, hint: 'حوالي 5 لتر في الدقيقة'),
          InfoRow('نمت حوالي', '${fmt(earthYears / 3, 1)} سنة', icon: Icons.bedtime_rounded, hint: 'لو تلت عمرك نوم (${fmt(el.inHours / 3, 0)} ساعة)'),
          InfoRow('رمشة عين', '≈ ${fmt(minutes * 2 / 3 * 15, 0)}', icon: Icons.remove_red_eye_rounded, hint: '15 رمشة في الدقيقة وانت صاحي'),
          InfoRow('وجبات أكلتها', '≈ ${fmt(days * 3, 0)}', icon: Icons.restaurant_rounded, hint: '3 وجبات في اليوم — فطور وغدا وعشا'),
          InfoRow('شعرك طوّل', '≈ ${fmt(totalMonths * 1.25 / 100, 1)} متر', icon: Icons.content_cut_rounded, hint: 'لو ما حلقته أبدًا (حوالي 1.25 سم في الشهر)'),
          InfoRow('جُمَع عشتها', fmt(_countWeekday(b, now, DateTime.friday), 0), icon: Icons.mosque_rounded, valueColor: SD.green),
          InfoRow('رمضانات عاصرتها', '≈ ${fmt(ha?.y ?? (days / 354.367).floor(), 0)}', icon: Icons.nights_stay_rounded),
          InfoRow('أيام 29 فبراير عشتها', fmt(_leapDaysLived(b, now), 0), icon: Icons.event_available_rounded),
        ]),
      ),
      SCard(
        title: 'محطات عمرك',
        icon: Icons.flag_rounded,
        color: SD.gold,
        child: Column(children: [for (final m in _milestones()) _milestoneRow(m, now)]),
      ),
      SCard(
        title: 'عمرك في تاريخ معيّن',
        icon: Icons.event_note_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DateButton(
            label: 'التاريخ (ماضي أو جاي)',
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
                InfoRow('عمرك يومها', '${x.y} سنة و${x.m} شهر و${x.d} يوم', valueColor: SD.nile),
                InfoRow('بالأيام', fmt(daysBetween(b, atDate!), 0)),
                InfoRow(atDate!.isAfter(now) ? 'باقي ليهو' : 'فات عليهو', '${fmt(daysBetween(now, atDate!).abs(), 0)} يوم'),
              ]);
            }),
          ],
        ]),
      ),
      SCard(
        title: 'معلومة فلكية بس',
        icon: Icons.stars_rounded,
        color: SD.red,
        child: NoteBox(
          'البرج حسب التاريخ: ${zod.$1} ${zod.$2}\n'
          'الحيوان في التقويم الصيني: $chinese (${b.month <= 2 ? 'تقريبي لأن رأس السنة الصينية بين يناير وفبراير' : 'حسب السنة'})\n\n'
          'التنجيم وادّعاء معرفة الحظ والمستقبل من الأبراج كذب وشرك ومحرّم شرعًا؛ نعرضها للمعلومة الفلكية فقط ولا علاقة لها بشخصيتك أو مستقبلك.',
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
        padding: const EdgeInsets.only(top: 10),
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
          const Text('مباشر', style: TextStyle(color: SD.red, fontWeight: FontWeight.w700, fontSize: 12)),
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
      '${p.$2} على ${p.$1}',
      '${fmt(age, 2)} سنة',
      hint: 'سنتها = ${fmt(p.$3 * 365.25, 1)} يوم أرضي • عيدك الجاي هناك: ${next.year > 9999 ? '—' : fmtDateAr(next, weekday: false)}',
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
      hint: past ? 'فات من ${fmt(-dd, 0)} يوم ✓' : (dd == 0 ? 'الليلة! 🎉' : 'باقي ${fmt(dd, 0)} يوم'),
      valueColor: past ? SD.green : (soon ? SD.pink : SD.gold),
    );
  }
}
