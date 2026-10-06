import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../../services/prayer.dart';

enum Cal {
  greg('ميلادي', 'Gregorian', Icons.calendar_today_rounded, SD.nile),
  hijri('هجري', 'Hijri', Icons.nightlight_round, SD.green),
  coptic('قبطي', 'Coptic', Icons.church_rounded, SD.henna),
  eth('إثيوبي', 'Ethiopian', Icons.public_rounded, SD.teal);

  final String ar, en;
  final IconData icon;
  final Color color;
  const Cal(this.ar, this.en, this.icon, this.color);
  String get label => tr(ar, en);
}

class DatesTool extends StatefulWidget {
  const DatesTool({super.key});
  @override
  State<DatesTool> createState() => _DatesToolState();
}

class _DatesToolState extends State<DatesTool> {
  Cal _src = Cal.greg;
  int _d = 1, _m = 1;
  final _yCtrl = TextEditingController();
  final _dCtrl = TextEditingController();
  late int _shift;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _shift = s.hijriShift;
    final n = sudanNow();
    _d = n.day;
    _m = n.month;
    _yCtrl.text = '${n.year}';
    _dCtrl.text = '$_d';
  }

  @override
  void dispose() {
    _yCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  List<String> get _monthNames => switch (_src) {
        Cal.greg => monthsAr,
        Cal.hijri => hijriMonths,
        Cal.coptic => copticMonths,
        Cal.eth => ethiopianMonths,
      };

  int _maxDay(int y) {
    switch (_src) {
      case Cal.greg:
        return DateTime(y, _m + 1, 0).day;
      case Cal.hijri:
        try {
          return hijriMonthLength(y, _m);
        } catch (_) {
          return 30;
        }
      case Cal.coptic:
      case Cal.eth:
        return _m < 13 ? 30 : (y % 4 == 3 ? 6 : 5);
    }
  }

  /// يحوّل المدخلات إلى تاريخ ميلادي أو يرجّع رسالة خطأ
  (DateTime?, String?) _resolve() {
    final y = parseNum(_yCtrl.text, -99999).round();
    final d = parseNum(_dCtrl.text, 0).round();
    if (y == -99999) return (null, t('أكتب السنة', 'اكتب السنة', 'Enter the year'));
    if (d < 1) return (null, t('أكتب اليوم صاح', 'اكتب اليوم بشكل صحيح', 'Enter a valid day'));
    final max = _maxDay(y);
    if (d > max) return (null, t('الشهر دا فيهو $max يوم بس', 'هذا الشهر فيه $max يومًا فقط', 'This month has only $max days'));
    try {
      switch (_src) {
        case Cal.greg:
          if (y < 1 || y > 9999) return (null, t('السنة لازم بين 1 و 9999', 'يجب أن تكون السنة بين 1 و 9999', 'Year must be between 1 and 9999'));
          return (DateTime(y, _m, d), null);
        case Cal.hijri:
          if (y < 1356 || y > 1500) return (null, t('التحويل الهجري متاح من 1356 لحدي 1500 هـ', 'التحويل الهجري متاح من 1356 إلى 1500 هـ', 'Hijri conversion is available from 1356 to 1500 AH'));
          return (fromHijri(y, _m, d, shift: _shift), null);
        case Cal.coptic:
          return (fromCoptic(y, _m, d), null);
        case Cal.eth:
          return (fromEthiopian(y, _m, d), null);
      }
    } catch (_) {
      return (null, t('التاريخ دا ما بنقدر نحوّلو', 'لا يمكن تحويل هذا التاريخ', "This date can't be converted"));
    }
  }

  void _switchSource(Cal c, DateTime? current) {
    final g = current ?? DateTime.now();
    setState(() {
      _src = c;
      CalDate cd;
      try {
        cd = switch (c) {
          Cal.greg => CalDate(g.year, g.month, g.day),
          Cal.hijri => toHijri(g, shift: _shift),
          Cal.coptic => toCoptic(g),
          Cal.eth => toEthiopian(g),
        };
      } catch (_) {
        final n = DateTime.now();
        cd = c == Cal.hijri ? toHijri(n, shift: _shift) : CalDate(n.year, n.month, n.day);
      }
      _m = cd.m;
      _d = cd.d;
      _yCtrl.text = '${cd.y}';
      _dCtrl.text = '${cd.d}';
    });
  }

  String? _hijriSafe(DateTime g) {
    try {
      return hijriText(g, shift: _shift);
    } catch (_) {
      return null;
    }
  }

  bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final (g, err) = _resolve();
    final now = sudanNow();
    final today = DateTime(now.year, now.month, now.day);

    return ToolList(children: [
      _todayCard(today),
      SCard(
        title: tr('حوّل من', 'Convert from'),
        icon: Icons.swap_horiz_rounded,
        color: _src.color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<Cal>(
            showSelectedIcon: false,
            segments: [for (final c in Cal.values) ButtonSegment(value: c, label: Text(c.label, style: const TextStyle(fontSize: 12.5)))],
            selected: {_src},
            onSelectionChanged: (v) => _switchSource(v.first, g),
          ),
          const SizedBox(height: 12),
          Row(children: [
            SizedBox(width: 80, child: NumField(tr('اليوم', 'Day'), _dCtrl, decimal: false, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 10),
                child: DropdownButtonFormField<int>(
                  initialValue: _m.clamp(1, _monthNames.length),
                  key: ValueKey('m_${_src.name}_$_m'),
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('الشهر', 'Month')),
                  items: [for (var i = 0; i < _monthNames.length; i++) DropdownMenuItem(value: i + 1, child: Text('${i + 1}. ${_monthNames[i]}'))],
                  onChanged: (v) => setState(() => _m = v ?? _m),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 92, child: NumField(tr('السنة', 'Year'), _yCtrl, decimal: false, onChanged: (_) => setState(() {}))),
          ]),
          Wrap(spacing: 8, children: [
            ActionChip(
              avatar: const Icon(Icons.today_rounded, size: 18),
              label: Text(t('النهارده', 'اليوم', 'Today')),
              onPressed: () => _switchSource(_src, today),
            ),
            if (g != null) ...[
              ActionChip(label: Text(tr('− يوم', '− day')), onPressed: () => _switchSource(_src, g.subtract(const Duration(days: 1)))),
              ActionChip(label: Text(tr('+ يوم', '+ day')), onPressed: () => _switchSource(_src, g.add(const Duration(days: 1)))),
            ],
          ]),
        ]),
      ),
      if (err != null) NoteBox(err, kind: NoteKind.warn),
      if (g != null) ..._results(g, today, cs),
      SCard(
        title: tr('تعديل الهجري (الرؤية)', 'Hijri adjustment (moon sighting)'),
        icon: Icons.visibility_rounded,
        color: SD.green,
        child: Column(children: [
          Row(children: [
            IconButton.filledTonal(onPressed: _shift > -2 ? () => setState(() => _shift--) : null, icon: const Icon(Icons.remove_rounded)),
            Expanded(
              child: Text('${_shift > 0 ? '+' : ''}$_shift ${tr('يوم', _shift.abs() == 1 ? 'day' : 'days')}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            IconButton.filledTonal(onPressed: _shift < 2 ? () => setState(() => _shift++) : null, icon: const Icon(Icons.add_rounded)),
          ]),
          if (_shift != s.hijriShift)
            TextButton.icon(
              onPressed: () {
                s.hijriShift = _shift;
                toast(t('اتحفظ التعديل لكل التطبيق ✓', 'تم حفظ التعديل للتطبيق كله ✓', 'Saved for the whole app ✓'));
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(t('احفظ التعديل لكل التطبيق', 'احفظ التعديل للتطبيق كله', 'Save for the whole app')),
            ),
          NoteBox(
              t('الهجري هنا حسب تقويم أم القرى. الشهر الهجري 29 أو 30 يوم، وبدايته الشرعية بالرؤية، فممكن يختلف يوم في بلدك. لو التاريخ ما مطابق للإعلان الرسمي عدّلو من هنا.',
                  'التاريخ الهجري هنا حسب تقويم أم القرى. الشهر الهجري 29 أو 30 يومًا، وبدايته الشرعية بالرؤية، فقد يختلف يومًا في بلدك. إن لم يطابق الإعلان الرسمي فعدّله من هنا.',
                  'Hijri dates here follow the Umm al-Qura calendar. A Hijri month is 29 or 30 days and officially starts with the moon sighting, so it may differ by a day where you live. Adjust it here if it doesn\'t match the official announcement.'),
              kind: NoteKind.info),
        ]),
      ),
    ]);
  }

  Widget _todayCard(DateTime today) {
    final h = _hijriSafe(today);
    return ResultHero(
      label: t('النهارده في كل التقاويم', 'اليوم في كل التقاويم', 'Today in every calendar'),
      value: weekdaysAr[today.weekday - 1],
      sub: [
        '🗓️ ${fmtDateAr(today, weekday: false)}${tr(' م', '')}',
        if (h != null) '🌙 $h',
        '⛪ ${copticText(today)}',
        '🌍 ${ethiopianText(today)}',
      ].join('\n'),
      colors: const [SD.green, SD.coffee],
    );
  }

  List<Widget> _results(DateTime g, DateTime today, ColorScheme cs) {
    final jdn = dateToJdn(g);
    final diff = jdn - dateToJdn(today);
    final h = _hijriSafe(g);
    CalDate? hd;
    try {
      hd = toHijri(g, shift: _shift);
    } catch (_) {}
    final cop = toCoptic(g), eth = toEthiopian(g);
    final doy = jdn - gregorianToJdn(g.year, 1, 1) + 1;
    final yearLen = _isLeap(g.year) ? 366 : 365;
    final thJdn = jdn + 4 - g.weekday;
    final thursday = jdnToGregorian(thJdn);
    final isoWeek = ((thJdn - gregorianToJdn(thursday.year, 1, 1)) ~/ 7) + 1;
    final diffText = diff == 0
        ? t('النهارده', 'اليوم', 'Today')
        : diff > 0
            ? tr('بعد ${fmt(diff, 0)} يوم', 'In ${fmt(diff, 0)} days')
            : tr('قبل ${fmt(-diff, 0)} يوم', '${fmt(-diff, 0)} days ago');
    int? hLen;
    if (hd != null) {
      try {
        hLen = hijriMonthLength(hd.y, hd.m);
      } catch (_) {}
    }
    final summary = [
      '${tr('اليوم', 'Day')}: ${weekdaysAr[g.weekday - 1]}',
      '${Cal.greg.label}: ${fmtDateAr(g, weekday: false)}${tr(' م', '')}',
      if (h != null) '${Cal.hijri.label}: $h',
      '${Cal.coptic.label}: ${copticText(g)}',
      '${Cal.eth.label}: ${ethiopianText(g)}',
      '${tr('اليوم اليولياني', 'Julian day')}: $jdn',
      '${t('من النهارده', 'من اليوم', 'From today')}: $diffText',
    ].join('\n');

    return [
      ResultHero(label: tr('التاريخ المحوّل', 'Converted date'), value: weekdaysAr[g.weekday - 1], sub: diffText, colors: [_src.color, SD.coffee]),
      SCard(
        title: tr('في كل التقاويم', 'In every calendar'),
        icon: Icons.calendar_view_month_rounded,
        color: SD.gold,
        child: Column(children: [
          InfoRow(Cal.greg.label, '${fmtDateAr(g, weekday: false)}${tr(' م', '')}', icon: Cal.greg.icon, valueColor: _src == Cal.greg ? SD.gold : null, hint: '${g.day}/${g.month}/${g.year}'),
          InfoRow(Cal.hijri.label, h ?? t('برّه المدى المتاح', 'خارج المدى المتاح', 'Out of supported range'), icon: Cal.hijri.icon, valueColor: _src == Cal.hijri ? SD.gold : null, hint: hd != null ? '${hd.d}/${hd.m}/${hd.y}' : null),
          InfoRow(Cal.coptic.label, copticText(g), icon: Cal.coptic.icon, valueColor: _src == Cal.coptic ? SD.gold : null, hint: '${cop.d}/${cop.m}/${cop.y} — ${tr('تقويم الشهداء', 'Era of Martyrs')}'),
          InfoRow(Cal.eth.label, ethiopianText(g), icon: Cal.eth.icon, valueColor: _src == Cal.eth ? SD.gold : null, hint: '${eth.d}/${eth.m}/${eth.y}'),
        ]),
      ),
      SCard(
        title: t('تفاصيل زيادة', 'تفاصيل إضافية', 'More details'),
        icon: Icons.info_outline_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow(tr('اليوم', 'Weekday'), weekdaysAr[g.weekday - 1], icon: Icons.event_rounded),
          InfoRow(t('الفرق من النهارده', 'الفرق من اليوم', 'Difference from today'), diffText, icon: Icons.compare_arrows_rounded,
              hint: diff.abs() >= 7
                  ? tr('≈ ${fmt(diff.abs() / 7, 1)} أسبوع • ${fmt(diff.abs() / 30.4375, 1)} شهر • ${fmt(diff.abs() / 365.2425, 2)} سنة',
                      '≈ ${fmt(diff.abs() / 7, 1)} weeks • ${fmt(diff.abs() / 30.4375, 1)} months • ${fmt(diff.abs() / 365.2425, 2)} years')
                  : null),
          InfoRow(tr('رقم اليوم اليولياني (JDN)', 'Julian day number (JDN)'), '$jdn', icon: Icons.tag_rounded),
          InfoRow(tr('ترتيب اليوم في السنة', 'Day of year'), tr('$doy من $yearLen', '$doy of $yearLen'), icon: Icons.format_list_numbered_rounded),
          InfoRow(tr('الأسبوع (ISO)', 'Week (ISO)'), '$isoWeek', icon: Icons.view_week_rounded),
          InfoRow(tr('السنة الميلادية', 'Gregorian year'), _isLeap(g.year) ? tr('كبيسة (366 يوم)', 'Leap (366 days)') : tr('بسيطة (365 يوم)', 'Common (365 days)'), icon: Icons.calendar_month_rounded),
          if (hd != null && hLen != null) InfoRow(tr('الشهر الهجري (${hijriMonths[hd.m - 1]})', 'Hijri month (${hijriMonths[hd.m - 1]})'), tr('$hLen يوم', '$hLen days'), icon: Icons.nightlight_round, hint: tr('حسب أم القرى', 'Umm al-Qura')),
          InfoRow(tr('السنة القبطية', 'Coptic year'), cop.y % 4 == 3 ? tr('كبيسة (النسيء 6 أيام)', 'Leap (6 epagomenal days)') : tr('بسيطة (النسيء 5 أيام)', 'Common (5 epagomenal days)'), icon: Icons.church_rounded),
          if (hd != null) InfoRow(t('الأيام الباقية في الشهر الهجري', 'الأيام المتبقية في الشهر الهجري', 'Days left in Hijri month'), '${(hLen ?? 30) - hd.d}', icon: Icons.hourglass_bottom_rounded),
        ]),
      ),
      ShareBar(() => summary),
      const SizedBox(height: 12),
    ];
  }
}
