import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../../services/prayer.dart';

/// لحظة مطلقة من «ساعة حائط» السودان
DateTime _sd(int y, int m, int d, [int h = 0, int mi = 0]) => DateTime.utc(y, m, d, h, mi).subtract(sudanOffset);

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

    islamic('رمضان المبارك', '🌙', SD.indigo, 9, 1, note: 'أول أيام الصيام', span: const Duration(days: 29));
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
      out.add(_Occ('ليلة السابع والعشرين (تقديرًا لليلة القدر)', '✨', SD.gold, lq.$1, lq.$2,
          note: 'تبدأ مع مغرب 26 رمضان. ليلة القدر تُتحرّى في العشر الأواخر خاصة الأوتار', islamic: true, span: const Duration(hours: 12)));
    }
    islamic('عيد الفطر', '🎉', SD.green, 10, 1, note: '1 شوال — كل عام وانتو بخير');
    islamic('يوم عرفة', '🤲', SD.henna, 12, 9, note: '9 ذو الحجة — صيامه لغير الحاج');
    islamic('عيد الأضحى', '🐑', SD.green, 12, 10, note: '10 ذو الحجة');
    islamic('رأس السنة الهجرية', '🗓️', SD.teal, 1, 1, note: '1 محرم');
    islamic('يوم عاشوراء', '🌿', SD.nile, 1, 10, note: '10 محرم — يُستحب صيامه ويوم قبله');
    islamic('المولد النبوي', '🕌', SD.gold, 3, 12, note: '12 ربيع الأول حسب المشهور');

    void national(String name, String emoji, int m, int d, int since, String note) {
      final r = _nextOf((y) => _sd(y, m, d), now.year, const Duration(days: 1));
      if (r != null) {
        final n = toSudan(r.$1).year - since;
        out.add(_Occ('$name (الذكرى $n)', emoji, SD.red, r.$1, r.$2, note: note, national: true));
      }
    }

    national('عيد الاستقلال', '🇸🇩', 1, 1, 1956, '1 يناير 1956 — رفع العلم في الخرطوم');
    national('ذكرى ثورة أكتوبر', '✊', 10, 21, 1964, '21 أكتوبر 1964');
    national('ذكرى انتفاضة أبريل', '✊', 4, 6, 1985, '6 أبريل 1985');
    national('ذكرى ثورة ديسمبر', '✊', 12, 19, 2018, '19 ديسمبر 2018');

    for (final e in _userEvents(s)) {
      final parts = (e['date'] as String).split('-').map(int.parse).toList();
      final h = (e['h'] as num?)?.toInt() ?? 0, mi = (e['mi'] as num?)?.toInt() ?? 0;
      final yearly = e['yearly'] == true;
      final created = DateTime.fromMillisecondsSinceEpoch((e['created'] as num).toInt());
      if (yearly) {
        final r = _nextOf((y) => _sd(y, parts[1], parts[2], h, mi), now.year, const Duration(days: 1));
        if (r != null) {
          out.add(_Occ(e['name'], e['emoji'] ?? '⭐', SD.purple, r.$1, r.$2, userId: e['id'], note: 'يتكرر كل سنة • الأصل ${parts[2]}/${parts[1]}/${parts[0]}'));
        }
      } else {
        final at = _sd(parts[0], parts[1], parts[2], h, mi);
        out.add(_Occ(e['name'], e['emoji'] ?? '⭐', SD.pink, at, created.isBefore(at) ? created : at.subtract(const Duration(days: 30)), userId: e['id']));
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('مناسبة جديدة', style: TextStyle(fontFamily: 'Lalezar', fontSize: 22)),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'اسم المناسبة', hintText: 'مثلاً: عرس ود خالي')),
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
                label: Text(time == null ? 'الساعة' : fmtTimeAr(DateTime(2000, 1, 1, time!.hour, time!.minute))),
                onPressed: () async {
                  final t = await showTimePicker(context: ctx, initialTime: time ?? const TimeOfDay(hour: 9, minute: 0));
                  if (t != null) setM(() => time = t);
                },
              ),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: yearly,
              onChanged: (v) => setM(() => yearly = v),
              title: const Text('بتتكرر كل سنة (زي عيد ميلاد)'),
            ),
            FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: const Text('تمام، ضيفها')),
          ]),
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok != true) return;
    if (name.isEmpty) {
      toast('أكتب اسم المناسبة');
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
    toast('اتضافت ✓');
  }

  void _delete(String id) {
    final s = context.read<AppState>();
    final l = _userEvents(s)..removeWhere((e) => e['id'] == id);
    s.setData('occasions_events', l);
  }

  String _countdown(Duration d) {
    if (d.isNegative) return 'هسي 🎉';
    final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60, sec = d.inSeconds % 60;
    return days > 0 ? '$days يوم  ${two(h)}:${two(m)}:${two(sec)}' : '${two(h)}:${two(m)}:${two(sec)}';
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
          label: '${next.emoji} أقرب مناسبة: ${next.name}',
          value: _countdown(next.at.difference(now)),
          sub: _dateText(s, next.at),
          colors: [next.color, SD.coffee],
        ),
      StatGrid([
        StatChip('${upcoming.length}', 'مناسبة جاية', color: SD.gold, icon: Icons.event_available_rounded),
        StatChip('$in30', 'خلال 30 يوم', color: SD.green, icon: Icons.date_range_rounded),
        StatChip('${_userEvents(s).length}', 'مناسباتك', color: SD.purple, icon: Icons.person_rounded),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in const [('all', 'الكل'), ('islam', 'إسلامية'), ('sudan', 'وطنية'), ('mine', 'حقّتي')])
          ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)),
        ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: const Text('ضيف مناسبة'), onPressed: _add),
      ]),
      const SizedBox(height: 12),
      if (list.isEmpty) const NoteBox('ما في مناسبات هنا. ضيف مناسبتك بالزر الفوق 👆', kind: NoteKind.info),
      for (final o in list) _card(s, o, now, cs),
      ShareBar(() => [
            '📅 المناسبات الجاية:',
            for (final o in upcoming.take(10)) '${o.emoji} ${o.name}: ${fmtDateAr(toSudan(o.at))} — ${o.at.isBefore(now) ? 'النهارده' : 'باقي ${o.at.difference(now).inDays} يوم'}',
          ].join('\n')),
      const NoteBox(
          'التواريخ الإسلامية تقديرية حسب تقويم أم القرى مع تعديل الهجري في الإعدادات؛ والمعتمد إعلان الرؤية الرسمي في السودان، فممكن تختلف يوم.',
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
              tooltip: 'امسح',
              onPressed: () => _delete(o.userId!),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              ongoing ? (o.span.inDays > 1 ? 'جاري هسي ✓ ربنا يتقبّل' : 'النهارده! 🎉') : (left.isNegative ? 'فاتت' : _countdown(left)),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: o.color, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          if (!left.isNegative) Text('${fmt(left.inHours, 0)} ساعة', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: .6))),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: p, minHeight: 8, color: o.color, backgroundColor: o.color.withValues(alpha: .12)),
        ),
        const SizedBox(height: 4),
        Text(
          '${(p * 100).toStringAsFixed(1)}٪ من المسافة من آخر مرة${!left.isNegative && left.inDays >= 7 ? ' • ≈ ${fmt(left.inDays / 7, 1)} أسبوع' : ''}',
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
