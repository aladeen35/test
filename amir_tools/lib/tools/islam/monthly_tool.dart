import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../../services/prayer.dart';

class _Row {
  final DateTime date; // تاريخ اليوم (ميلادي، بتقويم المكان المختار)
  final CalDate hijri;
  final Map<String, DateTime> t; // ساعة الحائط في المكان المختار
  _Row(this.date, this.hijri, this.t);
  DateTime get imsak => t['fajr']!.subtract(const Duration(minutes: 10));
  Duration get dayLen => t['maghrib']!.difference(t['sunrise']!);
  Duration get fastLen => t['maghrib']!.difference(t['fajr']!);
}

class MonthlyTool extends StatefulWidget {
  const MonthlyTool({super.key});
  @override
  State<MonthlyTool> createState() => _MonthlyToolState();
}

class _MonthlyToolState extends State<MonthlyTool> {
  late City _city;
  late int _year, _month;
  late int _hYear;
  bool _ramadan = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _city = s.city;
    final now = sudanNow();
    _year = now.year;
    _month = now.month;
    final h = _safeHijri(now, s.hijriShift);
    _hYear = h?.y ?? 1448;
    // لو رمضان فات السنة دي، اعرض الجاي
    if (h != null && h.m > 9) _hYear++;
    _ramadan = h?.m == 9 || h?.m == 8;
  }

  /// ساعة الحائط في المدينة المختارة في الجدول (قد تختلف عن مكان التطبيق)
  DateTime _wall(DateTime v) {
    if (_city.tz.isNotEmpty) {
      try {
        return v.toUtc().add(tz.getLocation(_city.tz).timeZone(v.millisecondsSinceEpoch).offset);
      } catch (_) {}
    }
    return toSudan(v);
  }

  /// فرق التوقيت عن UTC كنص (UTC+3)
  String _utcLabel() {
    Duration off;
    try {
      off = _city.tz.isNotEmpty ? tz.getLocation(_city.tz).timeZone(DateTime.now().millisecondsSinceEpoch).offset : placeOffset(DateTime.now());
    } catch (_) {
      off = placeOffset(DateTime.now());
    }
    final m = off.inMinutes;
    final sign = m < 0 ? '−' : '+';
    final h = m.abs() ~/ 60, mm = m.abs() % 60;
    return 'UTC$sign$h${mm == 0 ? '' : ':${two(mm)}'}';
  }

  CalDate? _safeHijri(DateTime d, int shift) {
    try {
      return toHijri(d, shift: shift);
    } catch (_) {
      return null;
    }
  }

  List<_Row> _rows(AppState s) {
    final days = <DateTime>[];
    if (_ramadan) {
      try {
        final start = fromHijri(_hYear, 9, 1, shift: s.hijriShift);
        final len = hijriMonthLength(_hYear, 9);
        for (var i = 0; i < len; i++) {
          final d = start.add(Duration(days: i));
          days.add(DateTime(d.year, d.month, d.day));
        }
      } catch (_) {}
    } else {
      final n = DateTime(_year, _month + 1, 0).day;
      for (var d = 1; d <= n; d++) {
        days.add(DateTime(_year, _month, d));
      }
    }
    return [
      for (final d in days)
        _Row(
          d,
          _safeHijri(d, s.hijriShift) ?? const CalDate(0, 1, 0),
          prayerTimes(d.year, d.month, d.day, _city.lat, _city.lng, method: s.prayerMethod, hanafi: s.hanafi, adjust: s.prayerAdjust)
              .map((k, v) => MapEntry(k, _wall(v))),
        ),
    ];
  }

  String _dur(Duration d) => tr('${d.inHours}س ${two(d.inMinutes % 60)}د', '${d.inHours}h ${two(d.inMinutes % 60)}m');

  String _shareText(List<_Row> rows) {
    final b = StringBuffer();
    b.writeln(_ramadan
        ? tr('🌙 إمساكية رمضان $_hYear هـ — ${_city.name}', '🌙 Ramadan $_hYear AH timetable — ${_city.name}')
        : tr('🕌 مواقيت ${monthsAr[_month - 1]} $_year — ${_city.name}', '🕌 Prayer times, ${monthsAr[_month - 1]} $_year — ${_city.name}'));
    b.writeln(_ramadan
        ? tr('اليوم | التاريخ | الإمساك | الفجر | الظهر | العصر | المغرب(الإفطار) | العشاء', 'Day | Date | Imsak | Fajr | Dhuhr | Asr | Maghrib (Iftar) | Isha')
        : tr('اليوم | الهجري | الفجر | الشروق | الظهر | العصر | المغرب | العشاء', 'Day | Hijri | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha'));
    for (final r in rows) {
      final pt = r.t;
      if (_ramadan) {
        b.writeln('${r.hijri.d} | ${r.date.day}/${r.date.month} | ${fmtTimeAr(r.imsak)} | ${fmtTimeAr(pt['fajr']!)} | ${fmtTimeAr(pt['dhuhr']!)} | ${fmtTimeAr(pt['asr']!)} | ${fmtTimeAr(pt['maghrib']!)} | ${fmtTimeAr(pt['isha']!)}');
      } else {
        b.writeln('${r.date.day} | ${r.hijri.d} ${hijriMonths[r.hijri.m - 1]} | ${fmtTimeAr(pt['fajr']!)} | ${fmtTimeAr(pt['sunrise']!)} | ${fmtTimeAr(pt['dhuhr']!)} | ${fmtTimeAr(pt['asr']!)} | ${fmtTimeAr(pt['maghrib']!)} | ${fmtTimeAr(pt['isha']!)}');
      }
    }
    b.write(t('(الأوقات تقريبية بالتوقيت المحلي لـ${_city.name}، احتاط دقيقتين)', '(الأوقات تقريبية بالتوقيت المحلي لـ${_city.name}، احتط بدقيقتين)',
        '(Approximate times in ${_city.name} local time; allow a couple of minutes)'));
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final rows = _rows(s);
    final today = sudanNow();
    // المكان الحالي للتطبيق (أي مكان في العالم) + المدينة المختارة هنا + مدن السودان كخيارات سريعة
    final cityOptions = <City>[
      if (!cities.any((c) => c.id == s.city.id)) s.city,
      if (_city.id != s.city.id && !cities.any((c) => c.id == _city.id)) _city,
      ...cities,
    ];
    final selected = cityOptions.firstWhere((c) => c.id == _city.id, orElse: () => cityOptions.first);

    _Row? longest, shortest, earliestFajr, latestFajr;
    var totalFast = 0;
    for (final r in rows) {
      if (longest == null || r.dayLen > longest.dayLen) longest = r;
      if (shortest == null || r.dayLen < shortest.dayLen) shortest = r;
      int mins(DateTime x) => x.hour * 60 + x.minute;
      if (earliestFajr == null || mins(r.t['fajr']!) < mins(earliestFajr.t['fajr']!)) earliestFajr = r;
      if (latestFajr == null || mins(r.t['fajr']!) > mins(latestFajr.t['fajr']!)) latestFajr = r;
      totalFast += r.fastLen.inMinutes;
    }
    final avgFast = rows.isEmpty ? Duration.zero : Duration(minutes: totalFast ~/ rows.length);
    final todayRow = rows.where((r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day).firstOrNull;

    return ToolList(children: [
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, label: Text(tr('شهر ميلادي', 'Calendar month')), icon: const Icon(Icons.calendar_month_rounded)),
          ButtonSegment(value: true, label: Text(tr('إمساكية رمضان', 'Ramadan timetable')), icon: const Icon(Icons.nightlight_round)),
        ],
        selected: {_ramadan},
        onSelectionChanged: (v) => setState(() => _ramadan = v.first),
      ),
      const SizedBox(height: 12),
      SCard(
        title: tr('المدينة والفترة', 'Place and period'),
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: Column(children: [
          DropdownButtonFormField<City>(
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('المدينة', 'City'), prefixIcon: const Icon(Icons.location_city_rounded)),
            items: [
              for (final c in cityOptions)
                DropdownMenuItem(
                    value: c,
                    child: Text('${c.inSudan ? '' : '${flagOf(c.country)} '}${c.name}${c.state.isEmpty ? '' : ' — ${c.state}'}', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (c) => setState(() => _city = c ?? _city),
          ),
          const SizedBox(height: 10),
          if (_ramadan)
            Row(children: [
              IconButton.filledTonal(onPressed: () => setState(() => _hYear--), icon: const Icon(Icons.chevron_left_rounded), tooltip: tr('السابق', 'Previous')),
              Expanded(child: Text(tr('رمضان $_hYear هـ', 'Ramadan $_hYear AH'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              IconButton.filledTonal(onPressed: () => setState(() => _hYear++), icon: const Icon(Icons.chevron_right_rounded), tooltip: tr('التالي', 'Next')),
            ])
          else
            Row(children: [
              IconButton.filledTonal(
                onPressed: () => setState(() {
                  _month--;
                  if (_month < 1) {
                    _month = 12;
                    _year--;
                  }
                }),
                tooltip: tr('السابق', 'Previous'),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _year = today.year;
                    _month = today.month;
                  }),
                  child: Text('${monthsAr[_month - 1]} $_year', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() {
                  _month++;
                  if (_month > 12) {
                    _month = 1;
                    _year++;
                  }
                }),
                tooltip: tr('التالي', 'Next'),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
        ]),
      ),
      if (rows.isEmpty)
        NoteBox(t('التاريخ دا برّه مدى التقويم الهجري المتاح (1356–1500 هـ). جرّب سنة تانية.', 'هذا التاريخ خارج مدى التقويم الهجري المتاح (1356–1500 هـ). جرّب سنة أخرى.',
            'This date is outside the supported Hijri range (1356–1500 AH). Try another year.'), kind: NoteKind.warn)
      else ...[
        if (_ramadan)
          ResultHero(
            label: tr('رمضان $_hYear هـ في ${_city.name}', 'Ramadan $_hYear AH in ${_city.name}'),
            value: tr('${rows.length} يوم', '${rows.length} days'),
            sub: t('من ${fmtDateAr(rows.first.date)}\nلحدي ${fmtDateAr(rows.last.date)}\nمتوسط الصيام ${_dur(avgFast)}',
                'من ${fmtDateAr(rows.first.date)}\nإلى ${fmtDateAr(rows.last.date)}\nمتوسط الصيام ${_dur(avgFast)}',
                'From ${fmtDateAr(rows.first.date)}\nto ${fmtDateAr(rows.last.date)}\nAverage fast ${_dur(avgFast)}'),
            colors: const [SD.indigo, SD.coffee],
          )
        else if (todayRow != null)
          ResultHero(
            label: '${t('النهارده', 'اليوم', 'Today')} ${fmtDateAr(todayRow.date)}',
            value: '${todayRow.hijri.d} ${hijriMonths[todayRow.hijri.m - 1]}',
            sub: '${prayerNames['fajr']} ${fmtTimeAr(todayRow.t['fajr']!)} • ${prayerNames['maghrib']} ${fmtTimeAr(todayRow.t['maghrib']!)} • ${tr('النهار', 'Daylight')} ${_dur(todayRow.dayLen)}',
            colors: const [SD.green, SD.coffee],
          ),
        _table(rows, today, cs),
        const SizedBox(height: 12),
        SectionTitle(tr('خلاصة الفترة', 'Period summary'), icon: Icons.insights_rounded),
        StatGrid([
          StatChip(_dur(longest!.dayLen), '${tr('أطول نهار', 'Longest day')} (${longest.date.day}/${longest.date.month})', color: SD.gold, icon: Icons.wb_sunny_rounded),
          StatChip(_dur(shortest!.dayLen), '${tr('أقصر نهار', 'Shortest day')} (${shortest.date.day}/${shortest.date.month})', color: SD.nile, icon: Icons.brightness_3_rounded),
          StatChip(_dur(avgFast), _ramadan ? tr('متوسط ساعات الصيام', 'Average fasting hours') : tr('متوسط فجر→مغرب', 'Average Fajr→Maghrib'), color: SD.henna, icon: Icons.timelapse_rounded),
          StatChip(fmtTimeAr(earliestFajr!.t['fajr']!), '${t('أبدر فجر', 'أبكر فجر', 'Earliest Fajr')} (${earliestFajr.date.day}/${earliestFajr.date.month})', color: SD.teal, icon: Icons.alarm_rounded),
          StatChip(fmtTimeAr(latestFajr!.t['fajr']!), '${tr('أأخر فجر', 'Latest Fajr')} (${latestFajr.date.day}/${latestFajr.date.month})', color: SD.indigo, icon: Icons.alarm_on_rounded),
          StatChip('${rows.length}', tr('عدد الأيام', 'Days'), color: SD.green, icon: Icons.calendar_view_month_rounded),
        ]),
        const SizedBox(height: 12),
        SCard(
          title: tr('معلومات الحساب', 'Calculation details'),
          icon: Icons.info_outline_rounded,
          color: SD.teal,
          child: Column(children: [
            InfoRow(tr('طريقة الحساب', 'Calculation method'), prayerMethods.firstWhere((m) => m.id == s.prayerMethod, orElse: () => prayerMethods.first).name),
            InfoRow(tr('مذهب العصر', 'Asr juristic method'), s.hanafi ? tr('الحنفي (ظل المثلين)', 'Hanafi (shadow ×2)') : tr('الجمهور (ظل المثل)', 'Standard (shadow ×1)')),
            InfoRow(tr('الإحداثيات', 'Coordinates'), '${_city.lat.toStringAsFixed(3)}°, ${_city.lng.toStringAsFixed(3)}°'),
            InfoRow(tr('التوقيت', 'Time zone'), '${_city.tz.isEmpty ? tr('توقيت الجهاز', 'Device time') : _city.tz} (${_utcLabel()})'),
            InfoRow(tr('تعديل الهجري', 'Hijri adjustment'), '${s.hijriShift > 0 ? '+' : ''}${s.hijriShift} ${tr('يوم', 'day(s)')}'),
            if (_ramadan) InfoRow(tr('الإمساك', 'Imsak'), t('قبل الفجر بـ 10 دقايق (احتياط)', 'قبل الفجر بـ 10 دقائق (احتياطًا)', '10 minutes before Fajr (precaution)')),
          ]),
        ),
        ShareBar(() => _shareText(rows)),
        NoteBox(
            _ramadan
                ? tr('بداية رمضان ونهايته بالرؤية الشرعية، والتواريخ هنا تقديرية حسب تقويم أم القرى مع تعديلك. الإمساك احتياط مستحب، والصيام الواجب يبدأ مع أذان الفجر.',
                    'Ramadan begins and ends with the moon sighting; dates here are estimates from the Umm al-Qura calendar plus your adjustment. Imsak is a recommended precaution; the obligatory fast starts at the Fajr adhan.')
                : t('المواقيت محسوبة فلكيًا وتقريبية؛ احتاط دقيقتين، والمعتمد أذان مسجد منطقتك.', 'المواقيت محسوبة فلكيًا وتقريبية؛ احتط بدقيقتين، والمعتمد أذان مسجد منطقتك.',
                    'Times are calculated astronomically and approximate; allow a couple of minutes and follow your local mosque\'s adhan.'),
            kind: NoteKind.warn),
      ],
    ]);
  }

  Widget _table(List<_Row> rows, DateTime today, ColorScheme cs) {
    final headers = _ramadan
        ? isEn
            ? ['Ramadan', 'Date', 'Imsak', 'Fajr', 'Dhuhr', 'Asr', 'Iftar', 'Isha', 'Fast']
            : ['رمضان', 'التاريخ', 'الإمساك', 'الفجر', 'الظهر', 'العصر', 'الإفطار', 'العشاء', 'الصيام']
        : isEn
            ? ['Day', 'Hijri', 'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Daylight']
            : ['اليوم', 'الهجري', 'الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء', 'النهار'];
    TextStyle hs = const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: SD.gold);
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SD.gold.withValues(alpha: .4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 42,
          dataRowMinHeight: 38,
          dataRowMaxHeight: 46,
          columnSpacing: 14,
          horizontalMargin: 12,
          headingRowColor: WidgetStatePropertyAll(SD.coffee.withValues(alpha: .25)),
          columns: [for (final h in headers) DataColumn(label: Text(h, style: hs))],
          rows: [
            for (final r in rows)
              () {
                final isToday = r.date.year == today.year && r.date.month == today.month && r.date.day == today.day;
                final isFri = r.date.weekday == DateTime.friday;
                final pt = r.t;
                final cells = _ramadan
                    ? [
                        '${r.hijri.d}',
                        '${weekdaysAr[r.date.weekday - 1]} ${r.date.day}/${r.date.month}',
                        fmtTimeAr(r.imsak),
                        fmtTimeAr(pt['fajr']!),
                        fmtTimeAr(pt['dhuhr']!),
                        fmtTimeAr(pt['asr']!),
                        fmtTimeAr(pt['maghrib']!),
                        fmtTimeAr(pt['isha']!),
                        _dur(r.fastLen),
                      ]
                    : [
                        '${weekdaysAr[r.date.weekday - 1]} ${r.date.day}',
                        r.hijri.y == 0 ? '—' : '${r.hijri.d} ${hijriMonths[r.hijri.m - 1]}',
                        fmtTimeAr(pt['fajr']!),
                        fmtTimeAr(pt['sunrise']!),
                        fmtTimeAr(pt['dhuhr']!),
                        fmtTimeAr(pt['asr']!),
                        fmtTimeAr(pt['maghrib']!),
                        fmtTimeAr(pt['isha']!),
                        _dur(r.dayLen),
                      ];
                return DataRow(
                  color: WidgetStatePropertyAll(isToday
                      ? SD.green.withValues(alpha: .3)
                      : isFri
                          ? SD.gold.withValues(alpha: .08)
                          : null),
                  cells: [
                    for (var i = 0; i < cells.length; i++)
                      DataCell(Text(cells[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isToday || i == 0 || (_ramadan && (i == 2 || i == 6)) ? FontWeight.w800 : FontWeight.w500,
                            color: _ramadan && i == 6 ? SD.henna : (_ramadan && i == 2 ? SD.nileLight : cs.onSurface),
                          ))),
                  ],
                );
              }(),
          ],
        ),
      ),
    );
  }
}
