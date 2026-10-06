import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/format.dart';
import '../../services/prayer.dart';
import 'adhkar_data.dart';

class AdhkarTool extends StatefulWidget {
  const AdhkarTool({super.key});
  @override
  State<AdhkarTool> createState() => _AdhkarToolState();
}

class _AdhkarToolState extends State<AdhkarTool> {
  late String _setId;
  AdhkarSet get _set => adhkarSets.firstWhere((x) => x.id == _setId, orElse: () => adhkarSets.first);
  set _set(AdhkarSet v) => _setId = v.id;
  String _autoReason = '';
  double _fontScale = 1;
  bool _showDone = true;

  /// counts[setId] = list of counts per dhikr (اليوم فقط)
  Map<String, List<int>> _counts = {};
  String _day = '';

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _fontScale = (s.getData<num>('adhkar_font') ?? 1).toDouble();
    _set = _autoSelect(s);
    _load(s);
  }

  AdhkarSet _autoSelect(AppState s) {
    try {
      final now = DateTime.now();
      final pt = s.timesFor(sudanNow());
      if (now.isBefore(pt['fajr']!)) {
        _autoReason = t('هسي ليل، اخترنا ليك أذكار النوم', 'الوقت ليل، فاخترنا لك أذكار النوم', "It's night, so we picked the sleep adhkar");
        return sleepAdhkar;
      }
      if (now.isBefore(pt['asr']!)) {
        _autoReason = t('الوقت صباح (بعد الفجر)، اخترنا ليك أذكار الصباح', 'الوقت صباح (بعد الفجر)، فاخترنا لك أذكار الصباح', "It's morning (after Fajr), so we picked the morning adhkar");
        return morningAdhkar;
      }
      if (now.isBefore(pt['isha']!.add(const Duration(hours: 1)))) {
        _autoReason = t('الوقت مساء (بعد العصر)، اخترنا ليك أذكار المساء', 'الوقت مساء (بعد العصر)، فاخترنا لك أذكار المساء', "It's evening (after Asr), so we picked the evening adhkar");
        return eveningAdhkar;
      }
      _autoReason = t('الليل دخل، اخترنا ليك أذكار النوم', 'حلّ الليل، فاخترنا لك أذكار النوم', 'Night has fallen, so we picked the sleep adhkar');
      return sleepAdhkar;
    } catch (_) {
      final h = sudanNow().hour;
      _autoReason = t('اخترنا حسب الساعة', 'اخترنا حسب الساعة', 'Picked by the time of day');
      if (h >= 4 && h < 15) return morningAdhkar;
      if (h >= 15 && h < 21) return eveningAdhkar;
      return sleepAdhkar;
    }
  }

  void _load(AppState s) {
    _day = AppState.dayKey(DateTime.now());
    final raw = s.getData<Map>('adhkar_progress');
    _counts = {};
    if (raw != null && raw['day'] == _day) {
      final m = raw['c'] as Map? ?? {};
      m.forEach((k, v) => _counts[k as String] = (v as List).map((e) => (e as num).toInt()).toList());
    }
    for (final set in adhkarSets) {
      final l = _counts[set.id];
      if (l == null || l.length != set.items.length) _counts[set.id] = List.filled(set.items.length, 0);
    }
  }

  void _save() {
    context.read<AppState>().setData('adhkar_progress', {'day': _day, 'c': _counts});
  }

  List<String> _doneToday(AppState s) {
    final raw = s.getData<Map>('adhkar_done_today');
    if (raw == null || raw['day'] != _day) return [];
    return List<String>.from(raw['ids'] ?? []);
  }

  void _tap(int i) {
    final s = context.read<AppState>();
    if (AppState.dayKey(DateTime.now()) != _day) _load(s);
    final c = _counts[_set.id]!;
    final target = _set.items[i].count;
    if (c[i] >= target) return;
    setState(() => c[i]++);
    if (c[i] >= target) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    _save();
    _checkComplete(s);
  }

  void _checkComplete(AppState s) {
    final c = _counts[_set.id]!;
    for (var i = 0; i < c.length; i++) {
      if (c[i] < _set.items[i].count) return;
    }
    final done = _doneToday(s);
    if (done.contains(_set.id)) return;
    done.add(_set.id);
    s.setData('adhkar_done_today', {'day': _day, 'ids': done});
    s.bump('adhkar_done');
    final hist = Map<String, dynamic>.from(s.getData<Map>('adhkar_history') ?? {});
    hist[_set.id] = ((hist[_set.id] as num?) ?? 0).toInt() + 1;
    s.setData('adhkar_history', hist);
    s.awardDaily('adhkar_${_set.id}', 30, tr('إكمال ${_set.name}', 'Completed ${_set.name}'));
    HapticFeedback.heavyImpact();
    toast(t('ما شاء الله! كمّلت ${_set.name} 🤲 تقبّل الله', 'ما شاء الله! أكملت ${_set.name} 🤲 تقبّل الله', 'MashaAllah! You completed the ${_set.name} 🤲 May Allah accept it'), icon: Icons.verified_rounded);
  }

  void _resetSet() {
    setState(() => _counts[_set.id] = List.filled(_set.items.length, 0));
    _save();
  }

  String _shareText() {
    final b = StringBuffer('${_set.emoji} ${_set.name}\n\n');
    for (final d in _set.items) {
      if (d.title != null) b.writeln('【${d.title}】');
      b.writeln(d.text);
      b.writeln('(${timesAr(d.count)})${d.source != null ? ' — ${d.source}' : ''}');
      b.writeln();
    }
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final c = _counts[_set.id]!;
    final doneCount = c.fold<int>(0, (a, b) => a + b);
    final total = _set.total;
    final itemsDone = [for (var i = 0; i < c.length; i++) if (c[i] >= _set.items[i].count) i].length;
    final progress = total == 0 ? 0.0 : doneCount / total;
    final doneToday = _doneToday(s);
    final hist = s.getData<Map>('adhkar_history') ?? {};
    final color = switch (_set.id) { 'morning' => SD.gold, 'evening' => SD.henna, 'sleep' => SD.indigo, _ => SD.green };

    return ToolList(children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final set in adhkarSets)
          ChoiceChip(
            avatar: Text(set.emoji),
            label: Text(set.name),
            selected: set.id == _set.id,
            onSelected: (_) => setState(() => _set = set),
          ),
      ]),
      const SizedBox(height: 8),
      if (_autoReason.isNotEmpty) Text('⏰ $_autoReason', style: TextStyle(color: cs.onSurface.withValues(alpha: .7), fontSize: 12.5)),
      const SizedBox(height: 10),
      ResultHero(
        label: '${_set.emoji} ${_set.name}',
        value: '${(progress * 100).round()}${tr('٪', '%')}',
        sub: '${tr('$itemsDone من ${_set.items.length} أذكار مكتملة', '$itemsDone of ${_set.items.length} done')} • $doneCount / $total ${tr('تكرار', 'reps')}${doneToday.contains(_set.id) ? '\n${t('كمّلتها النهارده ✓', 'أكملتها اليوم ✓', 'Completed today ✓')}' : ''}',
        colors: [color, SD.coffee],
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(value: progress, minHeight: 12, color: color, backgroundColor: color.withValues(alpha: .15)),
      ),
      const SizedBox(height: 10),
      NoteBox(_set.intro, kind: NoteKind.tip),
      StatGrid([
        StatChip('${doneToday.length}/4', t('أوراد النهارده', 'أوراد اليوم', "Today's sets"), color: SD.green, icon: Icons.today_rounded),
        StatChip('${s.counter('adhkar_done')}', tr('مرات الإكمال الكلية', 'Total completions'), color: SD.gold, icon: Icons.emoji_events_rounded),
        StatChip('${(hist[_set.id] as num?) ?? 0}', tr('إكمال ${_set.name.replaceFirst('أذكار ', '')}', '${_set.name} done'), color: SD.nile, icon: Icons.history_rounded),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.text_fields_rounded, size: 20),
        Expanded(
          child: Slider(
            value: _fontScale,
            min: .8,
            max: 1.8,
            divisions: 10,
            label: tr('حجم الخط', 'Font size'),
            onChanged: (v) => setState(() => _fontScale = v),
            onChangeEnd: (v) => s.setData('adhkar_font', v),
          ),
        ),
        IconButton(
          tooltip: _showDone ? t('اخفي المكتمل', 'أخفِ المكتمل', 'Hide completed') : tr('أظهر المكتمل', 'Show completed'),
          onPressed: () => setState(() => _showDone = !_showDone),
          icon: Icon(_showDone ? Icons.visibility_rounded : Icons.visibility_off_rounded),
        ),
        IconButton(
          tooltip: tr('ابدأ من جديد', 'Start over'),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(t('تبدأ من الأول؟', 'هل تبدأ من جديد؟', 'Start over?')),
                content: Text(t('حنصفّر عدّادات ${_set.name} بتاعة النهارده.', 'سيتم تصفير عدّادات ${_set.name} لهذا اليوم.', "This resets today's ${_set.name} counters.")),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('لا', 'No'))),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('أيوه صفّر', 'نعم، صفّر', 'Yes, reset'))),
                ],
              ),
            );
            if (ok == true) _resetSet();
          },
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ]),
      for (var i = 0; i < _set.items.length; i++)
        if (_showDone || c[i] < _set.items[i].count) _dhikrCard(i, _set.items[i], c[i], color),
      if (itemsDone == _set.items.length)
        NoteBox(t('الحمد لله، كمّلت الورد كله. ربنا يتقبّل ويحفظك 🤲', 'الحمد لله، أكملت الورد كله. تقبّل الله منك وحفظك 🤲', 'Alhamdulillah, you finished the whole set. May Allah accept it and protect you 🤲'), kind: NoteKind.tip),
      const SizedBox(height: 6),
      ShareBar(_shareText),
      NoteBox(tr('النصوص منقولة من القرآن الكريم وكتب الأذكار المعتمدة (مثل حصن المسلم). عدد التكرار حسب الوارد، والتخريج المختصر مذكور تحت كل ذكر حيث ثبت.', 'Texts are taken from the Holy Qur\'an and trusted adhkar books (such as Hisn al-Muslim) and kept in Arabic. Repetition counts follow the narrations; a short source is shown under each dhikr where authenticated.')),
    ]);
  }

  Widget _dhikrCard(int i, Dhikr d, int n, Color color) {
    final cs = Theme.of(context).colorScheme;
    final done = n >= d.count;
    final p = n / d.count;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: done ? .62 : 1,
      child: SCard(
        color: done ? SD.green : color,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _tap(i),
          onLongPress: () => copyText(d.text),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              CircleAvatar(radius: 13, backgroundColor: color.withValues(alpha: .18), child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.w800))),
              const SizedBox(width: 8),
              Expanded(child: Text(d.title ?? '', style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, color)))),
              if (done) const Icon(Icons.check_circle_rounded, color: SD.green),
            ]),
            if (d.note != null) ...[
              const SizedBox(height: 6),
              Text(d.note!, style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: .7))),
            ],
            const SizedBox(height: 8),
            Text(d.text, textAlign: TextAlign.justify, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 19 * _fontScale, height: 1.9, color: cs.onSurface)),
            if (d.source != null) ...[
              const SizedBox(height: 4),
              Text('«${d.source}»', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: .6))),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: p, minHeight: 8, color: done ? SD.green : color, backgroundColor: color.withValues(alpha: .12)),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                onPressed: done ? null : () => _tap(i),
                style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                child: Text(done ? t('تمام ✓', 'تم ✓', 'Done ✓') : '$n / ${d.count}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
            if (!done && d.count > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(t('باقي ${d.count - n} — اضغط على البطاقة في أي حتة للعد', 'متبقٍ ${d.count - n} — اضغط في أي مكان على البطاقة للعد', '${d.count - n} left — tap anywhere on the card to count'), style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: .55))),
              ),
          ]),
        ),
      ),
    );
  }
}

/// نص مختصر لعدد المرات
String timesAr(int n) => isEn
    ? (n == 1 ? 'once' : n == 2 ? 'twice' : '${fmt(n, 0)} times')
    : n == 1 ? 'مرة' : n == 2 ? 'مرتين' : '${fmt(n, 0)} مرات';
