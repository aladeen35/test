import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../../services/prayer.dart';

enum Cal {
  greg('ميلادي', Icons.calendar_today_rounded, SD.nile),
  hijri('هجري', Icons.nightlight_round, SD.green),
  coptic('قبطي', Icons.church_rounded, SD.henna),
  eth('إثيوبي', Icons.public_rounded, SD.teal);

  final String label;
  final IconData icon;
  final Color color;
  const Cal(this.label, this.icon, this.color);
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
    if (y == -99999) return (null, 'أكتب السنة');
    if (d < 1) return (null, 'أكتب اليوم صاح');
    final max = _maxDay(y);
    if (d > max) return (null, 'الشهر دا فيهو $max يوم بس');
    try {
      switch (_src) {
        case Cal.greg:
          if (y < 1 || y > 9999) return (null, 'السنة لازم بين 1 و 9999');
          return (DateTime(y, _m, d), null);
        case Cal.hijri:
          if (y < 1356 || y > 1500) return (null, 'التحويل الهجري متاح من 1356 لحدي 1500 هـ');
          return (fromHijri(y, _m, d, shift: _shift), null);
        case Cal.coptic:
          return (fromCoptic(y, _m, d), null);
        case Cal.eth:
          return (fromEthiopian(y, _m, d), null);
      }
    } catch (_) {
      return (null, 'التاريخ دا ما بنقدر نحوّلو');
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
        title: 'حوّل من',
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
            SizedBox(width: 80, child: NumField('اليوم', _dCtrl, decimal: false, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<int>(
                  initialValue: _m.clamp(1, _monthNames.length),
                  key: ValueKey('m_${_src.name}_$_m'),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الشهر'),
                  items: [for (var i = 0; i < _monthNames.length; i++) DropdownMenuItem(value: i + 1, child: Text('${i + 1}. ${_monthNames[i]}'))],
                  onChanged: (v) => setState(() => _m = v ?? _m),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 92, child: NumField('السنة', _yCtrl, decimal: false, onChanged: (_) => setState(() {}))),
          ]),
          Wrap(spacing: 8, children: [
            ActionChip(
              avatar: const Icon(Icons.today_rounded, size: 18),
              label: const Text('النهارده'),
              onPressed: () => _switchSource(_src, today),
            ),
            if (g != null) ...[
              ActionChip(label: const Text('− يوم'), onPressed: () => _switchSource(_src, g.subtract(const Duration(days: 1)))),
              ActionChip(label: const Text('+ يوم'), onPressed: () => _switchSource(_src, g.add(const Duration(days: 1)))),
            ],
          ]),
        ]),
      ),
      if (err != null) NoteBox(err, kind: NoteKind.warn),
      if (g != null) ..._results(g, today, cs),
      SCard(
        title: 'تعديل الهجري (الرؤية)',
        icon: Icons.visibility_rounded,
        color: SD.green,
        child: Column(children: [
          Row(children: [
            IconButton.filledTonal(onPressed: _shift > -2 ? () => setState(() => _shift--) : null, icon: const Icon(Icons.remove_rounded)),
            Expanded(
              child: Text('${_shift > 0 ? '+' : ''}$_shift يوم', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            IconButton.filledTonal(onPressed: _shift < 2 ? () => setState(() => _shift++) : null, icon: const Icon(Icons.add_rounded)),
          ]),
          if (_shift != s.hijriShift)
            TextButton.icon(
              onPressed: () {
                s.hijriShift = _shift;
                toast('اتحفظ التعديل لكل التطبيق ✓');
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('احفظ التعديل لكل التطبيق'),
            ),
          const NoteBox(
              'الهجري هنا حسب تقويم أم القرى. الشهر الهجري 29 أو 30 يوم، وبدايته الشرعية بالرؤية، فممكن يختلف يوم في السودان. لو التاريخ ما مطابق للإعلان الرسمي عدّلو من هنا.',
              kind: NoteKind.info),
        ]),
      ),
    ]);
  }

  Widget _todayCard(DateTime today) {
    final h = _hijriSafe(today);
    return ResultHero(
      label: 'النهارده في كل التقاويم',
      value: weekdaysAr[today.weekday - 1],
      sub: [
        '🗓️ ${fmtDateAr(today, weekday: false)} م',
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
        ? 'النهارده'
        : diff > 0
            ? 'بعد ${fmt(diff, 0)} يوم'
            : 'قبل ${fmt(-diff, 0)} يوم';
    int? hLen;
    if (hd != null) {
      try {
        hLen = hijriMonthLength(hd.y, hd.m);
      } catch (_) {}
    }
    final summary = [
      'اليوم: ${weekdaysAr[g.weekday - 1]}',
      'ميلادي: ${fmtDateAr(g, weekday: false)} م',
      if (h != null) 'هجري: $h',
      'قبطي: ${copticText(g)}',
      'إثيوبي: ${ethiopianText(g)}',
      'اليوم اليولياني: $jdn',
      'من النهارده: $diffText',
    ].join('\n');

    return [
      ResultHero(label: 'التاريخ المحوّل', value: weekdaysAr[g.weekday - 1], sub: diffText, colors: [_src.color, SD.coffee]),
      SCard(
        title: 'في كل التقاويم',
        icon: Icons.calendar_view_month_rounded,
        color: SD.gold,
        child: Column(children: [
          InfoRow('الميلادي', '${fmtDateAr(g, weekday: false)} م', icon: Cal.greg.icon, valueColor: _src == Cal.greg ? SD.gold : null, hint: '${g.day}/${g.month}/${g.year}'),
          InfoRow('الهجري', h ?? 'برّه المدى المتاح', icon: Cal.hijri.icon, valueColor: _src == Cal.hijri ? SD.gold : null, hint: hd != null ? '${hd.d}/${hd.m}/${hd.y}' : null),
          InfoRow('القبطي', copticText(g), icon: Cal.coptic.icon, valueColor: _src == Cal.coptic ? SD.gold : null, hint: '${cop.d}/${cop.m}/${cop.y} — تقويم الشهداء'),
          InfoRow('الإثيوبي', ethiopianText(g), icon: Cal.eth.icon, valueColor: _src == Cal.eth ? SD.gold : null, hint: '${eth.d}/${eth.m}/${eth.y}'),
        ]),
      ),
      SCard(
        title: 'تفاصيل زيادة',
        icon: Icons.info_outline_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow('اليوم', weekdaysAr[g.weekday - 1], icon: Icons.event_rounded),
          InfoRow('الفرق من النهارده', diffText, icon: Icons.compare_arrows_rounded,
              hint: diff.abs() >= 7 ? '≈ ${fmt(diff.abs() / 7, 1)} أسبوع • ${fmt(diff.abs() / 30.4375, 1)} شهر • ${fmt(diff.abs() / 365.2425, 2)} سنة' : null),
          InfoRow('رقم اليوم اليولياني (JDN)', '$jdn', icon: Icons.tag_rounded),
          InfoRow('ترتيب اليوم في السنة', '$doy من $yearLen', icon: Icons.format_list_numbered_rounded),
          InfoRow('الأسبوع (ISO)', '$isoWeek', icon: Icons.view_week_rounded),
          InfoRow('السنة الميلادية', _isLeap(g.year) ? 'كبيسة (366 يوم)' : 'بسيطة (365 يوم)', icon: Icons.calendar_month_rounded),
          if (hd != null && hLen != null) InfoRow('الشهر الهجري (${hijriMonths[hd.m - 1]})', '$hLen يوم', icon: Icons.nightlight_round, hint: 'حسب أم القرى'),
          InfoRow('السنة القبطية', cop.y % 4 == 3 ? 'كبيسة (النسيء 6 أيام)' : 'بسيطة (النسيء 5 أيام)', icon: Icons.church_rounded),
          if (hd != null) InfoRow('الأيام الباقية في الشهر الهجري', '${(hLen ?? 30) - hd.d}', icon: Icons.hourglass_bottom_rounded),
        ]),
      ),
      ShareBar(() => summary),
      const SizedBox(height: 12),
    ];
  }
}
