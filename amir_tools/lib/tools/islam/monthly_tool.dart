import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../../services/prayer.dart';

class _Row {
  final DateTime date; // تاريخ اليوم (ميلادي، تقويم السودان)
  final CalDate hijri;
  final Map<String, DateTime> t; // ساعة الحائط في السودان
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
              .map((k, v) => MapEntry(k, toSudan(v))),
        ),
    ];
  }

  String _dur(Duration d) => '${d.inHours}س ${two(d.inMinutes % 60)}د';

  String _shareText(List<_Row> rows) {
    final b = StringBuffer();
    b.writeln(_ramadan ? '🌙 إمساكية رمضان $_hYear هـ — ${_city.name}' : '🕌 مواقيت ${monthsAr[_month - 1]} $_year — ${_city.name}');
    b.writeln(_ramadan ? 'اليوم | التاريخ | الإمساك | الفجر | الظهر | العصر | المغرب(الإفطار) | العشاء' : 'اليوم | الهجري | الفجر | الشروق | الظهر | العصر | المغرب | العشاء');
    for (final r in rows) {
      final t = r.t;
      if (_ramadan) {
        b.writeln('${r.hijri.d} | ${r.date.day}/${r.date.month} | ${fmtTimeAr(r.imsak)} | ${fmtTimeAr(t['fajr']!)} | ${fmtTimeAr(t['dhuhr']!)} | ${fmtTimeAr(t['asr']!)} | ${fmtTimeAr(t['maghrib']!)} | ${fmtTimeAr(t['isha']!)}');
      } else {
        b.writeln('${r.date.day} | ${r.hijri.d} ${hijriMonths[r.hijri.m - 1]} | ${fmtTimeAr(t['fajr']!)} | ${fmtTimeAr(t['sunrise']!)} | ${fmtTimeAr(t['dhuhr']!)} | ${fmtTimeAr(t['asr']!)} | ${fmtTimeAr(t['maghrib']!)} | ${fmtTimeAr(t['isha']!)}');
      }
    }
    b.write('(الأوقات تقريبية بتوقيت السودان، احتاط دقيقتين)');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final rows = _rows(s);
    final today = sudanNow();
    final cityOptions = <City>[if (s.city.name.contains('موقعي')) s.city, ...cities];
    final selected = cityOptions.firstWhere((c) => c.name == _city.name, orElse: () => cityOptions.first);

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
        segments: const [
          ButtonSegment(value: false, label: Text('شهر ميلادي'), icon: Icon(Icons.calendar_month_rounded)),
          ButtonSegment(value: true, label: Text('إمساكية رمضان'), icon: Icon(Icons.nightlight_round)),
        ],
        selected: {_ramadan},
        onSelectionChanged: (v) => setState(() => _ramadan = v.first),
      ),
      const SizedBox(height: 12),
      SCard(
        title: 'المدينة والفترة',
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: Column(children: [
          DropdownButtonFormField<City>(
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المدينة', prefixIcon: Icon(Icons.location_city_rounded)),
            items: [for (final c in cityOptions) DropdownMenuItem(value: c, child: Text('${c.name} — ${c.state}', overflow: TextOverflow.ellipsis))],
            onChanged: (c) => setState(() => _city = c ?? _city),
          ),
          const SizedBox(height: 10),
          if (_ramadan)
            Row(children: [
              IconButton.filledTonal(onPressed: () => setState(() => _hYear--), icon: const Icon(Icons.chevron_right_rounded)),
              Expanded(child: Text('رمضان $_hYear هـ', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              IconButton.filledTonal(onPressed: () => setState(() => _hYear++), icon: const Icon(Icons.chevron_left_rounded)),
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
                icon: const Icon(Icons.chevron_right_rounded),
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
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ]),
        ]),
      ),
      if (rows.isEmpty)
        const NoteBox('التاريخ دا برّه مدى التقويم الهجري المتاح (1356–1500 هـ). جرّب سنة تانية.', kind: NoteKind.warn)
      else ...[
        if (_ramadan)
          ResultHero(
            label: 'رمضان $_hYear هـ في ${_city.name}',
            value: '${rows.length} يوم',
            sub: 'من ${fmtDateAr(rows.first.date)}\nلحدي ${fmtDateAr(rows.last.date)}\nمتوسط الصيام ${_dur(avgFast)}',
            colors: const [SD.indigo, SD.coffee],
          )
        else if (todayRow != null)
          ResultHero(
            label: 'النهارده ${fmtDateAr(todayRow.date)}',
            value: '${todayRow.hijri.d} ${hijriMonths[todayRow.hijri.m - 1]}',
            sub: 'الفجر ${fmtTimeAr(todayRow.t['fajr']!)} • المغرب ${fmtTimeAr(todayRow.t['maghrib']!)} • النهار ${_dur(todayRow.dayLen)}',
            colors: const [SD.green, SD.coffee],
          ),
        _table(rows, today, cs),
        const SizedBox(height: 12),
        const SectionTitle('خلاصة الفترة', icon: Icons.insights_rounded),
        StatGrid([
          StatChip(_dur(longest!.dayLen), 'أطول نهار (${longest.date.day}/${longest.date.month})', color: SD.gold, icon: Icons.wb_sunny_rounded),
          StatChip(_dur(shortest!.dayLen), 'أقصر نهار (${shortest.date.day}/${shortest.date.month})', color: SD.nile, icon: Icons.brightness_3_rounded),
          StatChip(_dur(avgFast), _ramadan ? 'متوسط ساعات الصيام' : 'متوسط فجر→مغرب', color: SD.henna, icon: Icons.timelapse_rounded),
          StatChip(fmtTimeAr(earliestFajr!.t['fajr']!), 'أبدر فجر (${earliestFajr.date.day}/${earliestFajr.date.month})', color: SD.teal, icon: Icons.alarm_rounded),
          StatChip(fmtTimeAr(latestFajr!.t['fajr']!), 'أأخر فجر (${latestFajr.date.day}/${latestFajr.date.month})', color: SD.indigo, icon: Icons.alarm_on_rounded),
          StatChip('${rows.length}', 'عدد الأيام', color: SD.green, icon: Icons.calendar_view_month_rounded),
        ]),
        const SizedBox(height: 12),
        SCard(
          title: 'معلومات الحساب',
          icon: Icons.info_outline_rounded,
          color: SD.teal,
          child: Column(children: [
            InfoRow('طريقة الحساب', prayerMethods.firstWhere((m) => m.id == s.prayerMethod, orElse: () => prayerMethods.first).name),
            InfoRow('مذهب العصر', s.hanafi ? 'الحنفي (ظل المثلين)' : 'الجمهور (ظل المثل)'),
            InfoRow('الإحداثيات', '${_city.lat.toStringAsFixed(3)}°, ${_city.lng.toStringAsFixed(3)}°'),
            InfoRow('التوقيت', 'السودان (UTC+2)'),
            InfoRow('تعديل الهجري', '${s.hijriShift > 0 ? '+' : ''}${s.hijriShift} يوم'),
            if (_ramadan) const InfoRow('الإمساك', 'قبل الفجر بـ 10 دقايق (احتياط)'),
          ]),
        ),
        ShareBar(() => _shareText(rows)),
        NoteBox(
            _ramadan
                ? 'بداية رمضان ونهايته بالرؤية الشرعية، والتواريخ هنا تقديرية حسب تقويم أم القرى مع تعديلك. الإمساك احتياط مستحب، والصيام الواجب يبدأ مع أذان الفجر.'
                : 'المواقيت محسوبة فلكيًا وتقريبية؛ احتاط دقيقتين، والمعتمد أذان مسجد منطقتك.',
            kind: NoteKind.warn),
      ],
    ]);
  }

  Widget _table(List<_Row> rows, DateTime today, ColorScheme cs) {
    final headers = _ramadan
        ? ['رمضان', 'التاريخ', 'الإمساك', 'الفجر', 'الظهر', 'العصر', 'الإفطار', 'العشاء', 'الصيام']
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
                final t = r.t;
                final cells = _ramadan
                    ? [
                        '${r.hijri.d}',
                        '${weekdaysAr[r.date.weekday - 1]} ${r.date.day}/${r.date.month}',
                        fmtTimeAr(r.imsak),
                        fmtTimeAr(t['fajr']!),
                        fmtTimeAr(t['dhuhr']!),
                        fmtTimeAr(t['asr']!),
                        fmtTimeAr(t['maghrib']!),
                        fmtTimeAr(t['isha']!),
                        _dur(r.fastLen),
                      ]
                    : [
                        '${weekdaysAr[r.date.weekday - 1]} ${r.date.day}',
                        r.hijri.y == 0 ? '—' : '${r.hijri.d} ${hijriMonths[r.hijri.m - 1]}',
                        fmtTimeAr(t['fajr']!),
                        fmtTimeAr(t['sunrise']!),
                        fmtTimeAr(t['dhuhr']!),
                        fmtTimeAr(t['asr']!),
                        fmtTimeAr(t['maghrib']!),
                        fmtTimeAr(t['isha']!),
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
