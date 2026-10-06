import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../../services/prayer.dart';

/// لحظة مطلقة من «ساعة حائط» المكان المختار
DateTime _sd(int y, int m, int d, [int h = 0, int mi = 0]) {
  final wall = DateTime.utc(y, m, d, h, mi);
  return wall.subtract(placeOffset(wall));
}

class _Occ {
  final String name, emoji, note;
  final Color color;
  final DateTime at, prev; // لحظات مطلقة
  final bool islamic, national;
  final String? userId;
  final Duration span; // مدة المناسبة (للتعرّف على «اليوم»)
  _Occ(this.name, this.emoji, this.color, this.at, this.prev,
      {this.note = '', this.islamic = false, this.national = false, this.userId, this.span = const Duration(days: 1)});
}

class OccasionsTool extends StatefulWidget {
  const OccasionsTool({super.key});
  @override
  State<OccasionsTool> createState() => _OccasionsToolState();
}

class _OccasionsToolState extends State<OccasionsTool> {
  Timer? _timer;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// أول حدوث لم ينتهِ بعد، والذي قبله
  (DateTime, DateTime)? _nextOf(DateTime Function(int k) at, int base, Duration span) {
    final now = DateTime.now();
    DateTime? prev;
    for (var k = base - 1; k <= base + 2; k++) {
      DateTime t;
      try {
        t = at(k);
      } catch (_) {
        continue;
      }
      if (t.add(span).isAfter(now)) {
        return (t, prev ?? t.subtract(const Duration(days: 354)));
      }
      prev = t;
    }
    return null;
  }

  List<_Occ> _build(AppState s) {
    final out = <_Occ>[];
    final now = sudanNow();
    int hy;
    try {
      hy = toHijri(now, shift: s.hijriShift).y;
    } catch (_) {
      hy = 1448;
    }
    DateTime hAt(int y, int m, int d) {
      final g = fromHijri(y, m, d, shift: s.hijriShift);
      return _sd(g.year, g.month, g.day);
    }

    void islamic(String name, String emoji, Color c, int m, int d, {String note = '', Duration span = const Duration(days: 1)}) {
      final r = _nextOf((y) => hAt(y, m, d), hy, span);
      if (r != null) out.add(_Occ(name, emoji, c, r.$1, r.$2, note: note, islamic: true, span: span));
    }

    islamic(tr('رمضان المبارك', 'Ramadan'), '🌙', SD.indigo, 9, 1, note: tr('أول أيام الصيام', 'First day of fasting'), span: const Duration(days: 29));
    // ليلة القدر: تبدأ مع مغرب يوم 26 رمضان
    final lq = _nextOf((y) {
      final g = fromHijri(y, 9, 26, shift: s.hijriShift);
      try {
        return s.timesFor(DateTime(g.year, g.month, g.day))['maghrib']!;
      } catch (_) {
        return _sd(g.year, g.month, g.day, 18);
      }
    }, hy, const Duration(hours: 12));
    if (lq != null) {
      out.add(_Occ(tr('ليلة السابع والعشرين (تقديرًا لليلة القدر)', 'The 27th night (estimated Laylat al-Qadr)'), '✨', SD.gold, lq.$1, lq.$2,
          note: tr('تبدأ مع مغرب 26 رمضان. ليلة القدر تُتحرّى في العشر الأواخر خاصة الأوتار',
              'Starts at Maghrib on 26 Ramadan. Laylat al-Qadr is sought in the last ten nights, especially the odd ones'),
          islamic: true,
          span: const Duration(hours: 12)));
    }
    islamic(tr('عيد الفطر', 'Eid al-Fitr'), '🎉', SD.green, 10, 1, note: t('1 شوال — كل عام وانتو بخير', '1 شوال — كل عام وأنتم بخير', '1 Shawwal — Eid Mubarak'));
    islamic(tr('يوم عرفة', 'Day of Arafah'), '🤲', SD.henna, 12, 9, note: tr('9 ذو الحجة — صيامه لغير الحاج', '9 Dhul-Hijjah — fasting is for non-pilgrims'));
    islamic(tr('عيد الأضحى', 'Eid al-Adha'), '🐑', SD.green, 12, 10, note: tr('10 ذو الحجة', '10 Dhul-Hijjah'));
    islamic(tr('رأس السنة الهجرية', 'Islamic New Year'), '🗓️', SD.teal, 1, 1, note: tr('1 محرم', '1 Muharram'));
    islamic(tr('يوم عاشوراء', 'Day of Ashura'), '🌿', SD.nile, 1, 10, note: tr('10 محرم — يُستحب صيامه ويوم قبله', '10 Muharram — recommended to fast it and the day before'));
    islamic(tr('المولد النبوي', "Prophet's Birthday (Mawlid)"), '🕌', SD.gold, 3, 12, note: tr('12 ربيع الأول حسب المشهور', '12 Rabi al-Awwal, per the common view'));

    void national(String name, String emoji, int m, int d, int since, String note) {
      final r = _nextOf((y) => _sd(y, m, d), now.year, const Duration(days: 1));
      if (r != null) {
        final n = toSudan(r.$1).year - since;
        out.add(_Occ(tr('$name (الذكرى $n)', '$name (${_ordinal(n)} anniversary)'), emoji, SD.red, r.$1, r.$2, note: note, national: true));
      }
    }

    national(tr('عيد الاستقلال', 'Sudan Independence Day'), '🇸🇩', 1, 1, 1956, tr('1 يناير 1956 — رفع العلم في الخرطوم', '1 January 1956 — flag raised in Khartoum'));
    national(tr('ذكرى ثورة أكتوبر', 'October Revolution'), '✊', 10, 21, 1964, tr('21 أكتوبر 1964', '21 October 1964'));
    national(tr('ذكرى انتفاضة أبريل', 'April Uprising'), '✊', 4, 6, 1985, tr('6 أبريل 1985', '6 April 1985'));
    national(tr('ذكرى ثورة ديسمبر', 'December Revolution'), '✊', 12, 19, 2018, tr('19 ديسمبر 2018', '19 December 2018'));

    for (final e in _userEvents(s)) {
      final parts = (e['date'] as String).split('-').map(int.parse).toList();
      final h = (e['h'] as num?)?.toInt() ?? 0, mi = (e['mi'] as num?)?.toInt() ?? 0;
      final yearly = e['yearly'] == true;
      final created = DateTime.fromMillisecondsSinceEpoch((e['created'] as num).toInt());
      if (yearly) {
        final r = _nextOf((y) => _sd(y, parts[1], parts[2], h, mi), now.year, const Duration(days: 1));
        if (r != null) {
          out.add(_Occ(e['name'], e['emoji'] ?? '⭐', SD.purple, r.$1, r.$2,
              userId: e['id'], note: tr('يتكرر كل سنة • الأصل ${parts[2]}/${parts[1]}/${parts[0]}', 'Repeats yearly • original ${parts[2]}/${parts[1]}/${parts[0]}')));
        }
      } else {
        final at = _sd(parts[0], parts[1], parts[2], h, mi);
        out.add(_Occ(e['name'], e['emoji'] ?? '⭐', SD.pink, at, created.isBefore(at) ? created : at.subtract(const Duration(days: 30)), userId: e['id']));
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  String _ordinal(int n) {
    final suf = (n % 100 >= 11 && n % 100 <= 13) ? 'th' : switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
    return '$n$suf';
  }

  List<Map> _userEvents(AppState s) => List<Map>.from(s.getData<List>('occasions_events') ?? []);

  Future<void> _add() async {
    final s = context.read<AppState>();
    final nameCtrl = TextEditingController();
    var date = sudanNow().add(const Duration(days: 7));
    TimeOfDay? time;
    var yearly = false;
    var emoji = '⭐';
    const emojis = ['⭐', '🎂', '💍', '🎓', '✈️', '🏠', '🤲', '💼', '⚽', '🎁'];
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr('مناسبة جديدة', 'New occasion'), style: const TextStyle(fontFamily: 'Lalezar', fontSize: 22)),
            const SizedBox(height: 10),
            TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: tr('اسم المناسبة', 'Occasion name'), hintText: t('مثلاً: عرس ود خالي', 'مثلًا: زفاف ابن خالي', "e.g. My cousin's wedding"))),
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: [
              for (final e in emojis)
                ChoiceChip(label: Text(e, style: const TextStyle(fontSize: 18)), selected: emoji == e, onSelected: (_) => setM(() => emoji = e)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_rounded),
                  label: Text(fmtDateAr(date)),
                  onPressed: () async {
                    final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(1900), lastDate: DateTime(2100));
                    if (d != null) setM(() => date = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule_rounded),
                label: Text(time == null ? tr('الساعة', 'Time') : fmtTimeAr(DateTime(2000, 1, 1, time!.hour, time!.minute))),
                onPressed: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: time ?? const TimeOfDay(hour: 9, minute: 0));
                  if (picked != null) setM(() => time = picked);
                },
              ),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: yearly,
              onChanged: (v) => setM(() => yearly = v),
              title: Text(t('بتتكرر كل سنة (زي عيد ميلاد)', 'تتكرر كل سنة (مثل عيد الميلاد)', 'Repeats every year (like a birthday)')),
            ),
            FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('تمام، ضيفها', 'أضفها', 'Add it'))),
          ]),
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok != true) return;
    if (name.isEmpty) {
      toast(t('أكتب اسم المناسبة', 'اكتب اسم المناسبة', 'Enter the occasion name'));
      return;
    }
    final l = _userEvents(s)
      ..add({
        'id': '${DateTime.now().microsecondsSinceEpoch}',
        'name': name,
        'emoji': emoji,
        'date': '${date.year}-${date.month}-${date.day}',
        'h': time?.hour ?? 0,
        'mi': time?.minute ?? 0,
        'yearly': yearly,
        'created': DateTime.now().millisecondsSinceEpoch,
      });
    s.setData('occasions_events', l);
    toast(t('اتضافت ✓', 'تمت الإضافة ✓', 'Added ✓'));
  }

  void _delete(String id) {
    final s = context.read<AppState>();
    final l = _userEvents(s)..removeWhere((e) => e['id'] == id);
    s.setData('occasions_events', l);
  }

  String _countdown(Duration d) {
    if (d.isNegative) return t('هسي 🎉', 'الآن 🎉', 'Now 🎉');
    final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60, sec = d.inSeconds % 60;
    return days > 0 ? '$days ${tr('يوم', 'd')}  ${two(h)}:${two(m)}:${two(sec)}' : '${two(h)}:${two(m)}:${two(sec)}';
  }

  String _dateText(AppState s, DateTime at) {
    final w = toSudan(at);
    final g = DateTime(w.year, w.month, w.day);
    String h;
    try {
      h = hijriText(g, shift: s.hijriShift);
    } catch (_) {
      h = '';
    }
    final time = (w.hour != 0 || w.minute != 0) ? ' • ${fmtTimeAr(w)}' : '';
    return '${fmtDateAr(g)}$time${h.isEmpty ? '' : '\n$h'}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final all = _build(s);
    final list = all.where((o) => switch (_filter) {
          'islam' => o.islamic,
          'sudan' => o.national,
          'mine' => o.userId != null,
          _ => true,
        }).toList();
    final upcoming = all.where((o) => o.at.add(o.span).isAfter(now)).toList();
    final next = upcoming.isEmpty ? null : upcoming.first;
    final in30 = upcoming.where((o) => o.at.difference(now).inDays < 30).length;

    return ToolList(children: [
      if (next != null)
        ResultHero(
          label: '${next.emoji} ${tr('أقرب مناسبة', 'Next occasion')}: ${next.name}',
          value: _countdown(next.at.difference(now)),
          sub: _dateText(s, next.at),
          colors: [next.color, SD.coffee],
        ),
      StatGrid([
        StatChip('${upcoming.length}', t('مناسبة جاية', 'مناسبة قادمة', 'Upcoming'), color: SD.gold, icon: Icons.event_available_rounded),
        StatChip('$in30', tr('خلال 30 يوم', 'Within 30 days'), color: SD.green, icon: Icons.date_range_rounded),
        StatChip('${_userEvents(s).length}', tr('مناسباتك', 'Yours'), color: SD.purple, icon: Icons.person_rounded),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in [
          ('all', tr('الكل', 'All')),
          ('islam', tr('إسلامية', 'Islamic')),
          ('sudan', t('وطنية', 'وطنية', 'Sudanese national')),
          ('mine', t('حقّتي', 'الخاصة بي', 'Mine')),
        ])
          ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)),
        ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('ضيف مناسبة', 'أضف مناسبة', 'Add occasion')), onPressed: _add),
      ]),
      const SizedBox(height: 12),
      if (list.isEmpty) NoteBox(t('ما في مناسبات هنا. ضيف مناسبتك بالزر الفوق 👆', 'لا توجد مناسبات هنا. أضف مناسبتك بالزر في الأعلى 👆', 'No occasions here. Add yours with the button above 👆'), kind: NoteKind.info),
      for (final o in list) _card(s, o, now, cs),
      ShareBar(() => [
            t('📅 المناسبات الجاية:', '📅 المناسبات القادمة:', '📅 Upcoming occasions:'),
            for (final o in upcoming.take(10))
              '${o.emoji} ${o.name}: ${fmtDateAr(toSudan(o.at))} — ${o.at.isBefore(now) ? t('النهارده', 'اليوم', 'today') : t('باقي ${o.at.difference(now).inDays} يوم', 'بعد ${o.at.difference(now).inDays} يومًا', 'in ${o.at.difference(now).inDays} days')}',
          ].join('\n')),
      NoteBox(
          t('التواريخ الإسلامية تقديرية حسب تقويم أم القرى مع تعديل الهجري في الإعدادات؛ والمعتمد إعلان الرؤية الرسمي في بلدك، فممكن تختلف يوم.',
              'التواريخ الإسلامية تقديرية حسب تقويم أم القرى مع تعديل الهجري في الإعدادات؛ والمعتمد إعلان الرؤية الرسمي في بلدك، فقد تختلف يومًا.',
              'Islamic dates are estimates from the Umm al-Qura calendar plus your Hijri adjustment in settings; the official moon-sighting announcement in your country prevails, so they may differ by a day.'),
          kind: NoteKind.warn),
    ]);
  }

  Widget _card(AppState s, _Occ o, DateTime now, ColorScheme cs) {
    final left = o.at.difference(now);
    final ongoing = left.isNegative && o.at.add(o.span).isAfter(now);
    final total = o.at.difference(o.prev).inSeconds;
    final p = total <= 0 ? 1.0 : (now.difference(o.prev).inSeconds / total).clamp(0.0, 1.0);
    return SCard(
      color: o.color,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: o.color.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
            child: Text(o.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(_dateText(s, o.at), style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: .7), height: 1.4)),
            ]),
          ),
          if (o.userId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: t('امسح', 'احذف', 'Delete'),
              onPressed: () => _delete(o.userId!),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              ongoing
                  ? (o.span.inDays > 1 ? t('جاري هسي ✓ ربنا يتقبّل', 'جارٍ الآن ✓ تقبّل الله', 'Happening now ✓ May Allah accept') : t('النهارده! 🎉', 'اليوم! 🎉', 'Today! 🎉'))
                  : (left.isNegative ? t('فاتت', 'انقضت', 'Passed') : _countdown(left)),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: o.color, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          if (!left.isNegative) Text(tr('${fmt(left.inHours, 0)} ساعة', '${fmt(left.inHours, 0)} h'), style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: .6))),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: p, minHeight: 8, color: o.color, backgroundColor: o.color.withValues(alpha: .12)),
        ),
        const SizedBox(height: 4),
        Text(
          tr('${(p * 100).toStringAsFixed(1)}٪ من المسافة من آخر مرة${!left.isNegative && left.inDays >= 7 ? ' • ≈ ${fmt(left.inDays / 7, 1)} أسبوع' : ''}',
              '${(p * 100).toStringAsFixed(1)}% of the way since last time${!left.isNegative && left.inDays >= 7 ? ' • ≈ ${fmt(left.inDays / 7, 1)} weeks' : ''}'),
          style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: .55)),
        ),
        if (o.note.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(o.note, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: .7))),
        ],
      ]),
    );
  }
}
