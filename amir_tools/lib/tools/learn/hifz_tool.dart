import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../more/khatma_data.dart';
import 'hifz_logic.dart';
import 'learn_common.dart';
import 'learn_notify.dart';

/// حفظ القرآن ومراجعته
class HifzTool extends StatefulWidget {
  const HifzTool({super.key});
  @override
  State<HifzTool> createState() => _HifzToolState();
}

class _HifzToolState extends State<HifzTool> {
  /* ── التخزين ── */
  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('hifz_cfg') ?? const {});
  void _setCfg(AppState s, String k, dynamic v) => s.setData('hifz_cfg', {..._cfg(s), k: v});

  bool _fwd(AppState s) => _cfg(s)['dir'] == 'fwd';
  int _startSurah(AppState s) => lInt(_cfg(s)['start'], _fwd(s) ? 0 : 113).clamp(0, 113);
  bool _pagesUnit(AppState s) => _cfg(s)['unit'] == 'pages';
  int _amount(AppState s) => lInt(_cfg(s)['amount'], _pagesUnit(s) ? 1 : 5);
  int _linesPerDay(AppState s) => _pagesUnit(s) ? _amount(s) * hifzLinesPerPage : _amount(s);
  int _dpw(AppState s) => lInt(_cfg(s)['dpw'], 6).clamp(1, 7);
  int _revPerDay(AppState s) => lInt(_cfg(s)['rev'], 10).clamp(1, 40);
  int? _notifyMin(AppState s) => _cfg(s)['notify'] is num ? lInt(_cfg(s)['notify']) : null;

  Map<int, DateTime> _mem(AppState s) {
    final raw = s.getData<Map>('hifz_mem') ?? const {};
    final out = <int, DateTime>{};
    raw.forEach((k, v) {
      final p = int.tryParse('$k');
      final d = lParseDk(v is String ? v : null);
      if (p != null && p >= 1 && p <= quranPages && d != null) out[p] = d;
    });
    return out;
  }

  void _saveMem(AppState s, Map<int, DateTime> m) => s.setData('hifz_mem', {for (final e in m.entries) '${e.key}': lDk(e.value)});
  int _partial(AppState s) => lInt(s.getData<num>('hifz_partial')).clamp(0, hifzLinesPerPage - 1);
  Map<String, dynamic> _log(AppState s) => Map<String, dynamic>.from(s.getData<Map>('hifz_log') ?? const {});
  Set<String> _revDone(AppState s) => Set<String>.from(s.getData<List>('hifz_rev') ?? const []);

  /* ── الإجراءات ── */
  void _markToday(AppState s, List<PortionPart> parts) {
    if (parts.isEmpty) return;
    final today = lToday();
    final mem = _mem(s);
    final r = applyPortion(parts);
    for (final p in r.completed) {
      mem[p] = today;
    }
    final log = _log(s);
    log[lDk(today)] = {'l': _linesPerDay(s), 'p': r.completed, 'pp': _partial(s), 'from': parts.first.page, 'to': parts.last.page};
    _saveMem(s, mem);
    s.setData('hifz_partial', r.partial);
    s.setData('hifz_log', log);
    s.awardDaily('hifz_new', 15, tr('ورد الحفظ', 'Hifz portion'));
    if (r.completed.isNotEmpty) s.bump('hifz_pages', r.completed.length);
    toast(t('ما شاء الله! ربنا يثبّتو في صدرك 🌿', 'ما شاء الله! ثبّته الله في صدرك 🌿', 'Masha’Allah! May Allah make it firm in your heart 🌿'));
  }

  void _undoToday(AppState s) {
    final k = lDk(lToday());
    final log = _log(s);
    final e = log[k];
    if (e is! Map) return;
    final mem = _mem(s);
    for (final p in (e['p'] as List? ?? const [])) {
      if (p is num) mem.remove(p.toInt());
    }
    log.remove(k);
    _saveMem(s, mem);
    s.setData('hifz_partial', lInt(e['pp']));
    s.setData('hifz_log', log);
  }

  void _toggleRev(AppState s) {
    final k = lDk(lToday());
    final d = _revDone(s);
    if (d.contains(k)) {
      d.remove(k);
    } else {
      d.add(k);
      s.awardDaily('hifz_rev', 10, tr('مراجعة الحفظ', 'Hifz review'));
    }
    final l = d.toList()..sort();
    s.setData('hifz_rev', l.length > 400 ? l.sublist(l.length - 400) : l);
  }

  Future<void> _pickReminder(AppState s) async {
    final cur = _notifyMin(s) ?? 5 * 60 + 30;
    final r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
      helpText: t('وكت التذكير', 'وقت التذكير', 'Reminder time'),
    );
    if (r == null || !mounted) return;
    final m = r.hour * 60 + r.minute;
    _setCfg(s, 'notify', m);
    await _schedule(s, m);
  }

  Future<void> _schedule(AppState s, int? m) async {
    if (!LearnNotifications.supported) {
      if (m != null) toast(t('التنبيهات بتشتغل في الموبايل بس', 'التنبيهات تعمل على الهاتف فقط', 'Reminders work on phones only'));
      return;
    }
    if (m != null) await LearnNotifications.requestPermission();
    await LearnNotifications.scheduleHifz(
        m, t('يلا على وردك الجديد ومراجعة اليوم 📖', 'حان وقت وردك الجديد ومراجعة اليوم 📖', 'Time for your new portion and today’s review 📖'));
  }

  /* ── نصوص ── */
  String _partText(PortionPart x) {
    final sur = surahAtPage(x.page);
    final lines = x.fullPage
        ? t('الصفحة كاملة', 'الصفحة كاملة', 'full page')
        : '${t('السطور', 'الأسطر', 'lines')} ${x.from}–${x.to}';
    return '${tr('ص', 'p.')} ${x.page} · $sur · $lines';
  }

  String _rangeText((int, int, int) r) =>
      '${tr('ج', 'Juz')} ${r.$1}: ${r.$2 == r.$3 ? '${tr('ص', 'p.')} ${r.$2}' : '${tr('ص', 'pp.')} ${r.$2}–${r.$3}'}';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = lToday();
    final todayK = lDk(today);
    final mem = _mem(s);
    final memSet = mem.keys.toSet();
    final partial = _partial(s);
    final fwd = _fwd(s);
    final seq = hifzSequence(_startSurah(s), fwd);
    final lpd = _linesPerDay(s);
    final log = _log(s);
    final doneToday = log[todayK] is Map;
    final portion = nextPortion(seq, memSet, partial, lpd);
    final pages = memSet.length;
    final frac = (pages * hifzLinesPerPage + partial) / (quranPages * hifzLinesPerPage);
    final streak = hifzStreak(log.keys.toSet(), today, lDk);
    final daysLeft = hifzDaysLeft(pages, partial, lpd.toDouble(), _dpw(s));
    final finish = daysLeft <= 0 ? null : lAddDays(today, daysLeft + (doneToday ? 1 : 0) - 1);
    final fullJuz = [for (var j = 1; j <= 30; j++) j].where((j) {
      for (var p = hJuzStart(j); p <= juzEndPage(j); p++) {
        if (!memSet.contains(p)) return false;
      }
      return true;
    }).length;
    final plan = reviewFor(mem, today, perDay: _revPerDay(s));
    final revDone = _revDone(s).contains(todayK);
    final revCount = _revDone(s).length;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ToolList(children: [
      ResultHero(
        label: t('المحفوظ لحدّي هسي', 'المحفوظ حتى الآن', 'Memorized so far'),
        value: '$pages / $quranPages',
        sub: '${fmt(frac * 100, 1)}% · ${t('حوالي', 'نحو', 'about')} ${fmt(pages / 20, 1)} ${t('جزء', 'جزء', 'juz')}',
      ),
      SCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LBar(t('التقدّم في المصحف', 'التقدّم في المصحف', 'Progress through the mushaf'), frac, '${fmt(frac * 100, 1)}%', color: SD.green, height: 14),
          const SizedBox(height: 10),
          StatGrid([
            StatChip('$streak', t('أيام ورا بعض', 'أيام متتالية', 'Day streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
            StatChip('$fullJuz', t('جزء كامل', 'جزء مكتمل', 'Full juz'), color: SD.nile, icon: Icons.menu_book_rounded),
            StatChip(
              daysLeft < 0 ? '—' : (daysLeft == 0 ? '✓' : lDays(daysLeft)),
              t('فاضل للختم', 'المتبقي للختم', 'To complete'),
              color: SD.purple,
              icon: Icons.flag_rounded,
            ),
          ]),
          if (finish != null) ...[
            const SizedBox(height: 10),
            InfoRow(t('تاريخ الختم المتوقّع', 'تاريخ الإتمام المتوقّع', 'Estimated completion'), fmtDateAr(finish), icon: Icons.event_available_rounded),
            Text(
              t('بمعدّل $lpd سطر في اليوم و${_dpw(s)} أيام حفظ في الأسبوع', 'بمعدّل $lpd سطرًا يوميًا و${_dpw(s)} أيام حفظ أسبوعيًا',
                  'At $lpd lines per study day, ${_dpw(s)} days a week'),
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
            ),
          ],
        ]),
      ),

      /* ── ورد اليوم ── */
      SCard(
        title: t('الورد الجديد بتاع الليلة', 'الورد الجديد لليوم', "Today's new portion"),
        icon: Icons.auto_stories_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (pages >= quranPages)
            NoteBox(t('ما شاء الله، ختمت حفظ القرآن كامل! ركّز على المراجعة 🌟', 'ما شاء الله، أتممت حفظ القرآن كاملًا! ركّز على المراجعة 🌟',
                'Masha’Allah, you have memorized the whole Qur’an! Keep reviewing 🌟'), kind: NoteKind.tip)
          else if (doneToday) ...[
            NoteBox(
                '${t('خلّصت ورد اليوم ✓', 'أتممت ورد اليوم ✓', "Today's portion done ✓")} — '
                '${t('الورد الجاي', 'الورد التالي', 'Next')}: ${portion.isEmpty ? '—' : _partText(portion.first)}',
                kind: NoteKind.tip),
            OutlinedButton.icon(
              onPressed: () => _undoToday(s),
              icon: const Icon(Icons.undo_rounded),
              label: Text(t('رجّع تسجيل اليوم', 'تراجع عن تسجيل اليوم', "Undo today's entry")),
            ),
          ] else ...[
            for (final x in portion)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.bookmark_rounded, color: readable(context, SD.green), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_partText(x), style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4))),
                ]),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _markToday(s, portion),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(t('حفظت ورد اليوم', 'أتممت حفظ ورد اليوم', "I memorized today's portion"), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          if (partial > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t('في نص صفحة: حافظ $partial سطر من صفحة ${portion.isEmpty ? '' : portion.first.page}', 'صفحة غير مكتملة: $partial سطرًا محفوظة',
                    'Page in progress: $partial lines memorized'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
        ]),
      ),

      /* ── المراجعة ── */
      SCard(
        title: t('مراجعة الليلة', 'مراجعة اليوم', "Today's review"),
        icon: Icons.replay_circle_filled_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (mem.isEmpty)
            NoteBox(t('لسه ما في محفوظ للمراجعة. سجّل وردك أو علّم الصفحات الحافظها من «الأجزاء» تحت.',
                'لا يوجد محفوظ للمراجعة بعد. سجّل وردك أو حدّد الصفحات المحفوظة من «الأجزاء» بالأسفل.',
                'Nothing to review yet. Log a portion or mark pages you already know under “Juz” below.'))
          else ...[
            Text(t('القريب (كل يوم)', 'الحفظ القريب (يوميًا)', 'Recent (daily)'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            if (plan.recent.isEmpty)
              Text(t('ما في حفظ جديد في آخر 7 أيام', 'لا حفظ جديد في آخر 7 أيام', 'No new pages in the last 7 days'), style: const TextStyle(fontSize: 13))
            else
              _chips(context, [for (final r in pageRanges(plan.recent)) _rangeText(r)], SD.green),
            const SizedBox(height: 10),
            Text(t('القديم (بالدور)', 'المحفوظ القديم (دوري)', 'Older (rotating)'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            if (plan.old.isEmpty)
              Text(t('كل محفوظك لسه قريب', 'كل محفوظك ما زال قريبًا', 'All your pages are still recent'), style: const TextStyle(fontSize: 13))
            else ...[
              _chips(context, [for (final r in pageRanges(plan.old)) _rangeText(r)], SD.nile),
              const SizedBox(height: 6),
              Text(
                t('اليوم ${plan.dayInCycle} من دورة ${plan.cycleDays} يوم — بتراجع كل القديم (${plan.oldTotal} صفحة) كل ${plan.cycleDays} يوم',
                    'اليوم ${plan.dayInCycle} من دورة ${plan.cycleDays} يومًا — يُراجع كل القديم (${plan.oldTotal} صفحة) كل ${plan.cycleDays} يومًا',
                    'Day ${plan.dayInCycle} of a ${plan.cycleDays}-day cycle — all ${plan.oldTotal} older pages are reviewed every ${plan.cycleDays} days'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: revDone,
              onChanged: (_) => _toggleRev(s),
              title: Text(t('راجعت مراجعة اليوم', 'أتممت مراجعة اليوم', "I finished today's review"), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${t('أيام المراجعة المسجّلة', 'أيام المراجعة المسجّلة', 'Review days logged')}: $revCount'),
            ),
            const Divider(),
            Text(t('جدول الأيام الجاية', 'جدول الأيام القادمة', 'Coming days'), style: const TextStyle(fontWeight: FontWeight.w800)),
            for (var i = 1; i <= 5; i++) _futureRow(context, mem, lAddDays(today, i), s),
          ],
        ]),
      ),

      /* ── الأجزاء ── */
      SCard(
        title: t('الأجزاء (اضغط لتعليم الصفحات)', 'الأجزاء (اضغط لتحديد الصفحات)', 'Juz (tap to mark pages)'),
        icon: Icons.grid_view_rounded,
        color: SD.gold,
        child: LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 500 ? 6 : 5;
          const gap = 6.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (var j = 1; j <= 30; j++) _juzTile(context, s, j, memSet, w, dark),
          ]);
        }),
      ),

      /* ── الخطة ── */
      SCard(
        title: t('خطتك', 'الخطة', 'Your plan'),
        icon: Icons.tune_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('الاتجاه', 'اتجاه الحفظ', 'Direction'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          lSegmented<bool>(
            items: [(false, t('من الناس لورا', 'من الناس تنازليًا', 'An-Nas backwards')), (true, t('من الفاتحة لقدّام', 'من الفاتحة تصاعديًا', 'From Al-Fatiha'))],
            value: fwd,
            onChanged: (v) => s.setData('hifz_cfg', {..._cfg(s), 'dir': v ? 'fwd' : 'back', 'start': v ? 0 : 113}),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: ValueKey('start_${_startSurah(s)}_$fwd'),
            initialValue: _startSurah(s),
            isExpanded: true,
            decoration: InputDecoration(labelText: t('تبدأ من سورة', 'البداية من سورة', 'Start from surah')),
            items: [
              for (var i = 0; i < 114; i++)
                DropdownMenuItem(value: i, child: Text('${i + 1}. ${surahNames[i]} (${tr('ص', 'p.')} ${surahStartPage[i]})', maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => v == null ? null : _setCfg(s, 'start', v),
          ),
          const SizedBox(height: 10),
          Text(t('مقدار الورد', 'مقدار الورد اليومي', 'Daily amount'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          lSegmented<bool>(
            items: [(false, t('بالسطور', 'بالأسطر', 'Lines')), (true, t('بالصفحات', 'بالصفحات', 'Pages'))],
            value: _pagesUnit(s),
            onChanged: (v) => s.setData('hifz_cfg', {..._cfg(s), 'unit': v ? 'pages' : 'lines', 'amount': v ? 1 : 5}),
          ),
          LStepper(
            _pagesUnit(s) ? t('صفحات في اليوم', 'صفحات يوميًا', 'Pages per day') : t('سطور في اليوم', 'أسطر يوميًا', 'Lines per day'),
            _amount(s),
            (v) => _setCfg(s, 'amount', v),
            min: 1,
            max: _pagesUnit(s) ? 20 : 60,
          ),
          LStepper(t('أيام الحفظ في الأسبوع', 'أيام الحفظ أسبوعيًا', 'Study days per week'), _dpw(s), (v) => _setCfg(s, 'dpw', v), min: 1, max: 7),
          LStepper(t('صفحات المراجعة القديمة يوميًا', 'صفحات مراجعة القديم يوميًا', 'Older review pages per day'), _revPerDay(s), (v) => _setCfg(s, 'rev', v),
              min: 1, max: 40),
          const Divider(),
          lSwitch(
            t('ذكّرني كل يوم', 'تذكير يومي', 'Daily reminder'),
            _notifyMin(s) != null,
            (v) async {
              if (v) {
                await _pickReminder(s);
              } else {
                _setCfg(s, 'notify', null);
                await _schedule(s, null);
              }
            },
            sub: _notifyMin(s) == null
                ? t('تنبيه بورد الحفظ والمراجعة', 'تنبيه بورد الحفظ والمراجعة', 'A nudge for your portion and review')
                : '${t('الساعة', 'الساعة', 'At')} ${fmtTimeAr(DateTime(2000, 1, 1, _notifyMin(s)! ~/ 60, _notifyMin(s)! % 60))}',
          ),
          if (_notifyMin(s) != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _pickReminder(s),
                icon: const Icon(Icons.schedule_rounded),
                label: Text(t('غيّر الوكت', 'تغيير الوقت', 'Change time')),
              ),
            ),
        ]),
      ),

      /* ── السجل ── */
      if (log.isNotEmpty)
        SCard(
          title: t('سجل الحفظ', 'سجل الحفظ', 'Memorization log'),
          icon: Icons.history_rounded,
          color: SD.teal,
          child: Column(children: [
            for (final k in (log.keys.toList()..sort((a, b) => b.compareTo(a))).take(14))
              if (log[k] is Map && lParseDk(k) != null)
                InfoRow(
                  fmtDateAr(lParseDk(k)!),
                  '${lInt((log[k] as Map)['l'])} ${t('سطر', 'سطرًا', 'lines')}',
                  hint: '${tr('ص', 'p.')} ${(log[k] as Map)['from'] ?? ''} → ${(log[k] as Map)['to'] ?? ''}',
                ),
          ]),
        ),
      ShareBar(() => _summary(s, pages, frac, streak, finish, plan)),
      const SizedBox(height: 12),
      NoteBox(
          t('ترتيب «من الناس لورا» بيمشي سورة سورة لحدي الفاتحة، وكل سورة بتتحفظ من أولها. الصفحات حسب مصحف المدينة (604 صفحة، 15 سطر).',
              'ترتيب «من الناس تنازليًا» يسير سورةً سورة حتى الفاتحة، وكل سورة تُحفظ من أولها. الصفحات وفق مصحف المدينة (604 صفحات، 15 سطرًا).',
              '“An-Nas backwards” goes surah by surah towards Al-Fatiha, each surah from its beginning. Pages follow the Madani mushaf (604 pages, 15 lines).')),
      NoteBox(
          t('المراجعة أهم من الحفظ الجديد: القريب كل يوم، والقديم بالدور. لو الورد تقيل عليك قلّل السطور وثبّت.',
              'المراجعة أهم من الجديد: القريب يوميًا والقديم دوريًا. إن ثقل الورد فقلّل الأسطر وثبّت الحفظ.',
              'Review matters more than new memorization: recent pages daily, older ones in rotation. If it feels heavy, reduce the lines.'),
          kind: NoteKind.tip),
    ]);
  }

  Widget _chips(BuildContext context, List<String> items, Color c) => Wrap(spacing: 6, runSpacing: 6, children: [
        for (final x in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: readable(context, c).withValues(alpha: .4)),
            ),
            child: Text(x, style: TextStyle(fontWeight: FontWeight.w700, color: readable(context, c), fontSize: 13)),
          ),
      ]);

  Widget _futureRow(BuildContext context, Map<int, DateTime> mem, DateTime day, AppState s) {
    final p = reviewFor(mem, day, perDay: _revPerDay(s));
    final parts = [
      if (p.recent.isNotEmpty) '${t('قريب', 'قريب', 'recent')} ${p.recent.length}',
      for (final r in pageRanges(p.old)) _rangeText(r),
    ];
    return InfoRow(lShort(day), parts.isEmpty ? '—' : parts.join(' · '), hint: weekdaysAr[day.weekday - 1]);
  }

  Widget _juzTile(BuildContext context, AppState s, int j, Set<int> memSet, double w, bool dark) {
    final total = juzPageCount(j);
    var have = 0;
    for (var p = hJuzStart(j); p <= juzEndPage(j); p++) {
      if (memSet.contains(p)) have++;
    }
    final f = have / total;
    final c = f >= 1 ? SD.green : (f > 0 ? SD.gold : SD.brownLight);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openJuz(s, j),
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: f >= 1 ? .3 : .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: readable(context, c).withValues(alpha: .5)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text('$j', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: f, minHeight: 5, color: readable(context, c), backgroundColor: c.withValues(alpha: .15)),
          ),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text('$have/$total', style: const TextStyle(fontSize: 11))),
        ]),
      ),
    );
  }

  Future<void> _openJuz(AppState s, int j) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        final mem = _mem(s);
        final a = hJuzStart(j), b = juzEndPage(j);
        void setAll(bool v) {
          final m = _mem(s);
          for (var p = a; p <= b; p++) {
            if (v) {
              m.putIfAbsent(p, () => lAddDays(lToday(), -30));
            } else {
              m.remove(p);
            }
          }
          _saveMem(s, m);
          setSt(() {});
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${t('الجزء', 'الجزء', 'Juz')} $j · ${tr('ص', 'pp.')} $a–$b', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  t('علّم الصفحات الكنت حافظها من قبل (بتدخل في المراجعة القديمة)', 'حدّد الصفحات المحفوظة سابقًا (تدخل في مراجعة القديم)',
                      'Mark pages you already know (they join the older review)'),
                  style: const TextStyle(fontSize: 12.5)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (var p = a; p <= b; p++)
                  FilterChip(
                    label: Text('$p'),
                    tooltip: surahAtPage(p),
                    selected: mem.containsKey(p),
                    onSelected: (v) {
                      final m = _mem(s);
                      v ? m[p] = lAddDays(lToday(), -30) : m.remove(p);
                      _saveMem(s, m);
                      setSt(() {});
                    },
                  ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setAll(false), child: Text(t('امسح الكل', 'إلغاء الكل', 'Clear all'), maxLines: 1, overflow: TextOverflow.ellipsis))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: () => setAll(true), child: Text(t('حافظو كلو', 'محفوظ كله', 'All memorized'), maxLines: 1, overflow: TextOverflow.ellipsis))),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  String _summary(AppState s, int pages, double frac, int streak, DateTime? finish, ReviewPlan plan) {
    final b = StringBuffer()
      ..writeln('📖 ${t('خطة حفظ القرآن', 'خطة حفظ القرآن', 'Qur’an memorization plan')}')
      ..writeln('${t('المحفوظ', 'المحفوظ', 'Memorized')}: $pages / $quranPages ${t('صفحة', 'صفحة', 'pages')} (${fmt(frac * 100, 1)}%)')
      ..writeln('${t('الورد', 'الورد اليومي', 'Daily portion')}: ${_amount(s)} ${_pagesUnit(s) ? t('صفحة', 'صفحة', 'page(s)') : t('سطر', 'سطرًا', 'lines')}')
      ..writeln('${t('أيام ورا بعض', 'أيام متتالية', 'Streak')}: $streak');
    if (finish != null) b.writeln('${t('الختم المتوقّع', 'الإتمام المتوقّع', 'Expected completion')}: ${fmtDateAr(finish)}');
    if (plan.recent.isNotEmpty || plan.old.isNotEmpty) {
      b.writeln('${t('مراجعة اليوم', 'مراجعة اليوم', "Today's review")}: ${[for (final r in pageRanges([...plan.recent, ...plan.old])) _rangeText(r)].join('، ')}');
    }
    return b.toString().trim();
  }
}
