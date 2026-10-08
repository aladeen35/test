import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart' show flagOf;
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../life/life_common.dart';
import 'know_common.dart';

/// نوع المناسبة
enum HolKind { official, islamic, personal }

class HolItem {
  final String id, name;
  final DateTime date;
  final HolKind kind;
  final String? note;
  const HolItem(this.id, this.name, this.date, this.kind, {this.note});
}

/// عطلة ثابتة بالتاريخ الميلادي
class _Fixed {
  final int m, d;
  final String sd, ar, en;
  const _Fixed(this.m, this.d, this.sd, this.ar, this.en);
}

/// الدول المدعومة بقوائم ثابتة (فقط ما نحن متأكدون منه)
const holidayCountries = ['SD', 'SA', 'AE', 'EG', 'QA', 'KW', 'XX'];

String countryName(String c) => switch (c) {
      'SD' => t('السودان', 'السودان', 'Sudan'),
      'SA' => t('السعودية', 'السعودية', 'Saudi Arabia'),
      'AE' => t('الإمارات', 'الإمارات', 'UAE'),
      'EG' => t('مصر', 'مصر', 'Egypt'),
      'QA' => t('قطر', 'قطر', 'Qatar'),
      'KW' => t('الكويت', 'الكويت', 'Kuwait'),
      _ => t('بلد تاني', 'دولة أخرى', 'Other country'),
    };

const _fixed = <String, List<_Fixed>>{
  'SD': [
    _Fixed(1, 1, 'عيد الاستقلال', 'عيد الاستقلال', 'Independence Day'),
    _Fixed(1, 7, 'عيد الميلاد المجيد (الأقباط)', 'عيد الميلاد المجيد (الأقباط)', 'Coptic Christmas'),
    _Fixed(12, 25, 'عيد الميلاد المجيد', 'عيد الميلاد المجيد', 'Christmas Day'),
  ],
  'SA': [
    _Fixed(2, 22, 'يوم التأسيس', 'يوم التأسيس', 'Founding Day'),
    _Fixed(9, 23, 'اليوم الوطني السعودي', 'اليوم الوطني السعودي', 'Saudi National Day'),
  ],
  'AE': [
    _Fixed(12, 2, 'اليوم الوطني الإماراتي', 'اليوم الوطني الإماراتي', 'UAE National Day'),
  ],
  'EG': [
    _Fixed(1, 7, 'عيد الميلاد المجيد', 'عيد الميلاد المجيد', 'Coptic Christmas'),
    _Fixed(1, 25, 'ثورة 25 يناير وعيد الشرطة', 'ثورة 25 يناير وعيد الشرطة', '25 January Revolution & Police Day'),
    _Fixed(4, 25, 'عيد تحرير سيناء', 'عيد تحرير سيناء', 'Sinai Liberation Day'),
    _Fixed(5, 1, 'عيد العمال', 'عيد العمال', 'Labour Day'),
    _Fixed(6, 30, 'ذكرى ثورة 30 يونيو', 'ذكرى ثورة 30 يونيو', '30 June Revolution'),
    _Fixed(7, 23, 'عيد ثورة 23 يوليو', 'عيد ثورة 23 يوليو', '23 July Revolution Day'),
    _Fixed(10, 6, 'عيد القوات المسلحة (6 أكتوبر)', 'عيد القوات المسلحة (6 أكتوبر)', 'Armed Forces Day (6 October)'),
  ],
  'QA': [
    _Fixed(12, 18, 'اليوم الوطني القطري', 'اليوم الوطني القطري', 'Qatar National Day'),
  ],
  'KW': [
    _Fixed(2, 25, 'العيد الوطني الكويتي', 'العيد الوطني الكويتي', 'Kuwait National Day'),
    _Fixed(2, 26, 'عيد التحرير', 'عيد التحرير', 'Liberation Day'),
  ],
};

/// المناسبات الإسلامية: (الشهر، اليوم، المعرّف)
const _islamic = [(1, 1, 'hijri_new_year'), (3, 12, 'mawlid'), (9, 1, 'ramadan'), (10, 1, 'eid_fitr'), (12, 9, 'arafah'), (12, 10, 'eid_adha')];

String islamicName(String id) => switch (id) {
      'hijri_new_year' => t('رأس السنة الهجرية', 'رأس السنة الهجرية', 'Islamic New Year'),
      'mawlid' => t('المولد النبوي الشريف', 'المولد النبوي الشريف', "Prophet's Birthday (Mawlid)"),
      'ramadan' => t('أول رمضان', 'بداية شهر رمضان', 'Start of Ramadan'),
      'eid_fitr' => t('عيد الفطر', 'عيد الفطر', 'Eid al-Fitr'),
      'arafah' => t('يوم عرفة', 'يوم عرفة', 'Day of Arafah'),
      'eid_adha' => t('عيد الضحية (الأضحى)', 'عيد الأضحى', 'Eid al-Adha'),
      _ => id,
    };

/// المناسبات الإسلامية المحسوبة من [from] لمدة [days] يومًا (تقويم أم القرى + تعديل الرؤية)
List<HolItem> islamicOccasions(DateTime from, {int shift = 0, int days = 400}) {
  final start = DateTime(from.year, from.month, from.day);
  final end = start.add(Duration(days: days));
  final hy = toHijri(start, shift: shift).y;
  final out = <HolItem>[];
  for (var y = hy - 1; y <= hy + 2; y++) {
    for (final (m, d, id) in _islamic) {
      try {
        final g = fromHijri(y, m, d, shift: shift);
        final gd = DateTime(g.year, g.month, g.day);
        if (!gd.isBefore(start) && !gd.isAfter(end)) {
          out.add(HolItem('$id-$y', islamicName(id), gd, HolKind.islamic,
              note: '${d.toString()} ${hijriMonths[m - 1]} $y ${tr('هـ', 'AH')}${id == 'ramadan' ? ' • ${t('مناسبة، ما عطلة', 'مناسبة وليست عطلة', 'Occasion, not a holiday')}' : ''}'));
        }
      } catch (_) {}
    }
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

/// العطل الثابتة القادمة لدولة
List<HolItem> fixedHolidays(String country, DateTime from, {int days = 400}) {
  final start = DateTime(from.year, from.month, from.day);
  final end = start.add(Duration(days: days));
  final out = <HolItem>[];
  for (final f in _fixed[country] ?? const <_Fixed>[]) {
    for (var y = start.year; y <= end.year; y++) {
      final d = DateTime(y, f.m, f.d);
      if (!d.isBefore(start) && !d.isAfter(end)) out.add(HolItem('$country-${f.m}-${f.d}-$y', t(f.sd, f.ar, f.en), d, HolKind.official));
    }
  }
  return out;
}

/// المناسبات الشخصية القادمة
List<HolItem> personalHolidays(List<Map> raw, DateTime from, {int days = 400}) {
  final start = DateTime(from.year, from.month, from.day);
  final end = start.add(Duration(days: days));
  final out = <HolItem>[];
  for (final m in raw) {
    final d = parseDk(m['date'] as String?);
    if (d == null) continue;
    final name = '${m['name'] ?? ''}';
    if (m['yearly'] == true) {
      for (var y = start.year; y <= end.year; y++) {
        final dd = DateTime(y, d.month, d.month == 2 && d.day == 29 && daysInMonth(y, 2) == 28 ? 28 : d.day);
        if (!dd.isBefore(start) && !dd.isAfter(end)) out.add(HolItem('${m['id']}-$y', name, dd, HolKind.personal, note: '${m['id']}'));
      }
    } else if (!d.isBefore(start)) {
      out.add(HolItem('${m['id']}', name, d, HolKind.personal, note: '${m['id']}'));
    }
  }
  return out;
}

String countdownText(int n) {
  if (n == 0) return t('الليلة!', 'اليوم!', 'Today!');
  if (n == 1) return t('بكرة', 'غدًا', 'Tomorrow');
  return t('بعد $n يوم', 'بعد $n يومًا', 'in $n days');
}

class HolidaysTool extends StatefulWidget {
  const HolidaysTool({super.key});
  @override
  State<HolidaysTool> createState() => _HolidaysToolState();
}

class _HolidaysToolState extends State<HolidaysTool> {
  int _filter = 0; // 0 الكل، 1 الرسمية والإسلامية، 2 الشخصية

  String _country(AppState s) {
    final saved = s.getData<String>('holidays_country');
    if (saved != null && holidayCountries.contains(saved)) return saved;
    final c = s.city.country.toUpperCase();
    return holidayCountries.contains(c) ? c : 'XX';
  }

  List<Map> _personal(AppState s) => List<Map>.from(s.getData<List>('holidays_personal') ?? const []);

  Future<void> _add(AppState s) async {
    final name = TextEditingController();
    DateTime? date = todayPlace().add(const Duration(days: 7));
    var yearly = true;
    final ok = await lifeSheet<bool>(
      context,
      t('ضيف مناسبة شخصية', 'إضافة مناسبة شخصية', 'Add a personal holiday'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: name,
          autofocus: true,
          decoration: InputDecoration(labelText: t('اسم المناسبة (عيد ميلاد، ذكرى زواج…)', 'اسم المناسبة (عيد ميلاد، ذكرى زواج…)', 'Name (birthday, anniversary…)')),
        ),
        const SizedBox(height: 10),
        LifeDateButton(
          label: t('التاريخ', 'التاريخ', 'Date'),
          value: date,
          first: DateTime(1950),
          last: DateTime(todayPlace().year + 5, 12, 31),
          onPick: (d) => set(() => date = d),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: yearly,
          onChanged: (v) => set(() => yearly = v),
          title: Text(t('بتتكرر كل سنة', 'تتكرر سنويًا', 'Repeats every year')),
        ),
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.add_rounded),
          label: Text(t('ضيف', 'إضافة', 'Add')),
        ),
      ]),
    );
    final n = name.text.trim();
    name.dispose();
    if (ok != true || n.isEmpty || date == null) return;
    final l = _personal(s)..add({'id': newId(), 'name': n, 'date': dk(date!), 'yearly': yearly});
    s.setData('holidays_personal', l);
    s.award(3, tr('إضافة مناسبة', 'Added a holiday'));
  }

  void _delete(AppState s, String id) {
    final l = _personal(s)..removeWhere((m) => m['id'] == id);
    s.setData('holidays_personal', l);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final country = _country(s);
    final today = todayPlace();
    final personal = _personal(s);
    final official = fixedHolidays(country, today);
    final islamic = islamicOccasions(today, shift: s.hijriShift);
    final mine = personalHolidays(personal, today);
    final all = <HolItem>[
      if (_filter != 2) ...official,
      if (_filter != 2) ...islamic,
      if (_filter != 1) ...mine,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final next = all.where((h) => !(h.kind == HolKind.islamic && h.id.startsWith('ramadan'))).firstOrNull ?? all.firstOrNull;
    final in30 = all.where((h) => dayDiff(today, h.date) <= 30).length;
    final in90 = all.where((h) => dayDiff(today, h.date) <= 90).length;

    return ToolList(children: [
      if (next != null)
        ResultHero(
          label: '${t('الجاية', 'المناسبة القادمة', 'Next up')}: ${next.name}',
          value: countdownText(dayDiff(today, next.date)),
          sub: '${fmtDateAr(next.date)}${next.note != null && next.kind == HolKind.islamic ? '\n${next.note}' : ''}',
        ),
      SCard(
        title: t('البلد', 'الدولة', 'Country'),
        icon: Icons.flag_rounded,
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in holidayCountries)
            PickChip('${c == 'XX' ? '🌍' : flagOf(c)} ${countryName(c)}', c == country, () => s.setData('holidays_country', c), color: SD.nile),
        ]),
      ),
      StatGrid([
        StatChip('${official.length + islamic.where((h) => !h.id.startsWith('ramadan')).length}', t('رسمية ودينية في السنة', 'رسمية ودينية خلال سنة', 'Official & religious (12 mo)'), color: SD.gold, icon: Icons.event_rounded),
        StatChip('$in30', t('خلال 30 يوم', 'خلال 30 يومًا', 'Within 30 days'), color: SD.green, icon: Icons.timelapse_rounded),
        StatChip('$in90', t('خلال 3 شهور', 'خلال 3 أشهر', 'Within 3 months'), color: SD.nile, icon: Icons.date_range_rounded),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('الكل', 'الكل', 'All')))),
            ButtonSegment(value: 1, label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('العامة', 'العامة', 'Public')))),
            ButtonSegment(value: 2, label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('حقّتي', 'الشخصية', 'Mine')))),
          ],
          selected: {_filter},
          onSelectionChanged: (v) => setState(() => _filter = v.first),
        ),
      ),
      const SizedBox(height: 12),
      SCard(
        title: t('الجاي في السنة دي', 'القادم خلال سنة', 'Coming up (next 12 months)'),
        icon: Icons.celebration_rounded,
        trailing: IconButton(
          tooltip: t('ضيف مناسبة', 'إضافة مناسبة', 'Add holiday'),
          onPressed: () => _add(s),
          icon: const Icon(Icons.add_circle_rounded, color: SD.gold),
        ),
        child: all.isEmpty
            ? EmptyHint(Icons.event_busy_rounded, t('ما في مناسبات — ضيف مناسبة شخصية', 'لا توجد مناسبات — أضف مناسبة شخصية', 'Nothing here — add a personal holiday'))
            : Column(children: [for (final h in all) _row(context, s, h, today)]),
      ),
      OutlinedButton.icon(
        onPressed: () => _add(s),
        icon: const Icon(Icons.add_rounded),
        label: Text(t('ضيف مناسبة شخصية', 'إضافة مناسبة شخصية', 'Add a personal holiday')),
      ),
      const SizedBox(height: 10),
      if (country == 'SD')
        NoteBox(
            t('العطل الإسلامية الرسمية في السودان: عيد الفطر، عيد الضحية، رأس السنة الهجرية والمولد النبوي. عدد أيام العطلة بيتحدد كل سنة بقرار حكومي.',
                'العطل الإسلامية الرسمية في السودان: عيد الفطر، عيد الأضحى، رأس السنة الهجرية والمولد النبوي. ويُحدَّد عدد أيام العطلة سنويًا بقرار حكومي.',
                "Sudan's Islamic public holidays: Eid al-Fitr, Eid al-Adha, Islamic New Year and the Prophet's Birthday. The number of days off is set each year by government decision."),
            kind: NoteKind.info)
      else
        NoteBox(
            country == 'XX'
                ? t('للبلد دا بنعرض المناسبات الإسلامية المحسوبة بس. راجع الإعلانات الرسمية لبلدك لمعرفة العطل الرسمية وعدد أيامها.',
                    'لهذه الدولة نعرض المناسبات الإسلامية المحسوبة فقط. راجع الإعلانات الرسمية لدولتك لمعرفة العطل الرسمية وعدد أيامها.',
                    'For this country we only show computed Islamic occasions. Check your government\'s official announcements for public holidays and their length.')
                : t('عرضنا العطل الوطنية الثابتة المعروفة بس، مع المناسبات الإسلامية المحسوبة. أيّ المناسبات الإسلامية عطلة رسمية وكم يوم — دا بيختلف من بلد لبلد؛ راجع الإعلان الرسمي.',
                    'نعرض العطل الوطنية الثابتة المعروفة فقط مع المناسبات الإسلامية المحسوبة. أيّ المناسبات الإسلامية تُعد عطلة رسمية وكم يومًا يختلف بين الدول؛ راجع الإعلان الرسمي.',
                    'We show only well-known fixed national days plus computed Islamic occasions. Which Islamic occasions are public holidays, and for how many days, varies by country — check the official announcement.'),
            kind: NoteKind.warn),
      NoteBox(
          t('التواريخ الهجرية محسوبة بتقويم أم القرى (مع تعديل الرؤية من الضبط) — الموعد الفعلي بيعتمد على رؤية الهلال وإعلان الجهات الرسمية، وممكن يفرق يوم. الحكومات ممكن تنقل أو تمدد العطل.',
              'التواريخ الهجرية محسوبة وفق تقويم أم القرى (مع تعديل الرؤية من الإعدادات) — يعتمد الموعد الفعلي على رؤية الهلال وإعلان الجهات الرسمية وقد يختلف بيوم. وقد تنقل الحكومات العطل أو تمددها.',
              'Hijri dates are computed with the Umm al-Qura calendar (plus your sighting adjustment in Settings). Actual dates depend on moon sighting and official announcements and may differ by a day. Governments may move or extend holidays.'),
          kind: NoteKind.warn),
      ShareBar(() => [
            '📅 ${t('العطل والمناسبات الجاية', 'العطل والمناسبات القادمة', 'Upcoming holidays')} — ${countryName(country)}',
            for (final h in all.take(15)) '• ${h.name}: ${fmtDateAr(h.date, weekday: false)} (${countdownText(dayDiff(today, h.date))})',
          ].join('\n')),
      const SizedBox(height: 10),
      ReviewedLine('holidays', item: countryName(country)),
    ]);
  }

  Widget _row(BuildContext context, AppState s, HolItem h, DateTime today) {
    final n = dayDiff(today, h.date);
    final (c, ic) = switch (h.kind) {
      HolKind.official => (SD.green, Icons.flag_rounded),
      HolKind.islamic => (SD.gold, Icons.nightlight_round),
      HolKind.personal => (SD.pink, Icons.favorite_rounded),
    };
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: muted.withValues(alpha: .15)))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)),
          child: Icon(ic, size: 20, color: readable(context, c)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(fmtDateAr(h.date), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12.5)),
            if (h.kind == HolKind.islamic && h.note != null)
              Text(h.note!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: (n <= 7 ? SD.henna : c).withValues(alpha: .15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(countdownText(n), style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, n <= 7 ? SD.henna : c))),
          ),
        ),
        if (h.kind == HolKind.personal)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: t('امسح', 'حذف', 'Delete'),
            onPressed: () async {
              if (await confirmAsk(context, t('نمسحها؟', 'تأكيد الحذف', 'Delete?'), h.name, ok: t('امسح', 'حذف', 'Delete'))) _delete(s, h.note ?? '');
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
      ]),
    );
  }
}
