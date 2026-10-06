import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import 'khatma_data.dart';
import 'more_common.dart';

class KhatmaTool extends StatefulWidget {
  const KhatmaTool({super.key});
  @override
  State<KhatmaTool> createState() => _KhatmaToolState();
}

class _KhatmaToolState extends State<KhatmaTool> {
  // إعداد خطة جديدة
  int mode = 0; // 0 بالأيام، 1 بتاريخ، 2 بمقدار يومي
  int days = 30;
  DateTime? endDate;
  int dailyPages = 20;
  final nameC = TextEditingController(), daysC = TextEditingController(), pagesC = TextEditingController(), startC = TextEditingController();
  final reachC = TextEditingController();

  @override
  void dispose() {
    for (final c in [nameC, daysC, pagesC, startC, reachC]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get today => mDateOnly(DateTime.now());

  Map<String, dynamic>? _plan(AppState s) {
    final p = s.getData<Map>('khatma_plan');
    return p == null ? null : Map<String, dynamic>.from(p);
  }

  List<Map> _history(AppState s) => List<Map>.from(s.getData<List>('khatma_history') ?? []);

  /// آخر يوم في رمضان (الحالي أو القادم)
  DateTime? _ramadanEnd(AppState s) {
    try {
      final h = toHijri(today, shift: s.hijriShift);
      final y = h.m <= 9 ? h.y : h.y + 1;
      return mDateOnly(fromHijri(y, 9, hijriMonthLength(y, 9), shift: s.hijriShift));
    } catch (_) {
      return null;
    }
  }

  int get _startPage => (parseNum(startC.text, 1).round()).clamp(1, quranPages);

  /// عدد أيام الخطة حسب طريقة الإعداد
  int get _planDays {
    final remaining = quranPages - _startPage + 1;
    return switch (mode) {
      0 => days.clamp(1, 3650),
      1 => endDate == null ? 30 : math.max(1, mDaysBetween(today, endDate!) + 1),
      _ => (remaining / math.max(1, dailyPages)).ceil(),
    };
  }

  void _startPlan(AppState s) {
    final d = _planDays;
    final sp = _startPage;
    s.setData('khatma_plan', {
      'name': nameC.text.trim(),
      'start': mkey(today),
      'end': mkey(today.add(Duration(days: d - 1))),
      'sp': sp - 1,
      'page': sp - 1,
      'log': <String, dynamic>{},
      'undo': <List>[],
    });
    s.award(10, t('بداية ختمة جديدة', 'بدء ختمة جديدة', 'Started a new khatma'));
    toast(t('بسم الله — الختمة بدت، ربنا يعينك 🤲', 'بسم الله — بدأت الختمة، أعانك الله 🤲', 'Bismillah — your khatma has started 🤲'));
    setState(() {});
  }

  /// تسجيل تقدّم: الصفحة الجديدة التي وصلها القارئ
  void _setPage(AppState s, Map<String, dynamic> p, int newPage) {
    final old = (p['page'] as num).toInt();
    newPage = newPage.clamp(0, quranPages);
    if (newPage == old) return;
    final delta = newPage - old;
    final k = mkey(today);
    final log = Map<String, dynamic>.from(p['log'] ?? {});
    final before = (log[k] as num?)?.toInt() ?? 0;
    log[k] = math.max(0, before + delta);
    final undo = List<List>.from((p['undo'] as List?) ?? [])..add([k, old, newPage]);
    p['page'] = newPage;
    p['log'] = log;
    p['undo'] = undo.length > 30 ? undo.sublist(undo.length - 30) : undo;
    s.setData('khatma_plan', p);
    if (delta > 0) {
      HapticFeedback.lightImpact();
      s.bump('khatma_pages', delta);
      s.awardDaily('khatma_log', 10, t('ورد الختمة', 'ورد الختمة', 'Khatma reading'));
      final need = _todayNeed(p, old - before);
      if (before < need && before + delta >= need) {
        s.awardDaily('khatma_wird', 15, t('كمّلت ورد اليوم', 'إتمام ورد اليوم', "Finished today's portion"));
        toast(t('ما شاء الله! كمّلت وردك الليلة 🌟', 'ما شاء الله! أتممت ورد اليوم 🌟', "Masha'Allah! Today's portion is done 🌟"));
      }
    }
    if (newPage >= quranPages) _finish(s, p);
    setState(() {});
  }

  void _undo(AppState s, Map<String, dynamic> p) {
    final undo = List<List>.from((p['undo'] as List?) ?? []);
    if (undo.isEmpty) return;
    final last = undo.removeLast();
    final k = last[0] as String, old = (last[1] as num).toInt(), nw = (last[2] as num).toInt();
    final log = Map<String, dynamic>.from(p['log'] ?? {});
    log[k] = math.max(0, ((log[k] as num?)?.toInt() ?? 0) - (nw - old));
    p['page'] = old;
    p['log'] = log;
    p['undo'] = undo;
    s.setData('khatma_plan', p);
    setState(() {});
  }

  void _finish(AppState s, Map<String, dynamic> p) {
    final start = mParseKey(p['start']) ?? today;
    final h = _history(s)
      ..insert(0, {
        'n': p['name'] ?? '',
        's': p['start'],
        'e': mkey(today),
        'plan': p['end'],
        'd': mDaysBetween(start, today) + 1,
      });
    s.setData('khatma_history', h.take(50).toList());
    s.setData('khatma_plan', null);
    s.bump('khatma_done');
    s.award(100, t('ختمة كاملة 🎉', 'ختمة كاملة 🎉', 'Completed khatma 🎉'));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('🎉 مبروك الختمة!', '🎉 مبارك الختمة!', '🎉 Khatma complete!')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t('ختمت القرآن في ${mDaysBetween(start, today) + 1} يوم. تقبّل الله منك.', 'ختمت القرآن في ${mDaysBetween(start, today) + 1} يومًا. تقبّل الله منك.',
              'You completed the Qur\'an in ${mDaysBetween(start, today) + 1} days. May Allah accept it.')),
          const SizedBox(height: 10),
          const Text('اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ، وَاجْعَلْهُ لِي إِمَامًا وَنُورًا وَهُدًى وَرَحْمَةً',
              textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, height: 1.7)),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(t('آمين', 'آمين', 'Ameen')))],
      ),
    );
  }

  /// ورد اليوم المطلوب (صفحات) بحيث تنتهي في الموعد — من صفحة بداية اليوم
  int _todayNeed(Map p, int dayStartPage) {
    final end = mParseKey(p['end']) ?? today;
    final remDays = math.max(1, mDaysBetween(today, end) + 1);
    return ((quranPages - dayStartPage) / remDays).ceil().clamp(1, quranPages);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = _plan(s);
    return p == null ? _setup(s) : _progress(s, p);
  }

  /* ───────────── الإعداد ───────────── */
  Widget _setup(AppState s) {
    final ram = _ramadanEnd(s);
    final d = _planDays;
    final remaining = quranPages - _startPage + 1;
    final perDay = remaining / d;
    final hist = _history(s);
    return ToolList(children: [
      ResultHero(
        label: t('ختمة القرآن — خطّط ختمتك', 'ختمة القرآن — خطّط لختمتك', 'Qur\'an khatma — plan your reading'),
        value: '${fmt(perDay, 1)} ${t('صفحة/يوم', 'صفحة/يوم', 'pages/day')}',
        sub: '$d ${t('يوم', 'يومًا', 'days')} • ${t('تختم', 'الختم', 'Finish')} ${fmtDateAr(today.add(Duration(days: d - 1)))}',
        colors: const [Color(0xFF007229), Color(0xFF0E5C3A), Color(0xFF3A1F0C)],
      ),
      SCard(
        title: t('خطة جديدة', 'خطة جديدة', 'New plan'),
        icon: Icons.menu_book_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم الختمة (اختياري)', 'اسم الختمة (اختياري)', 'Khatma name (optional)'), hintText: t('ختمة رمضان', 'ختمة رمضان', 'Ramadan khatma'))),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(t('بالأيام', 'بالأيام', 'Days'))),
              ButtonSegment(value: 1, label: Text(t('لحدي تاريخ', 'حتى تاريخ', 'By date'))),
              ButtonSegment(value: 2, label: Text(t('ورد يومي', 'ورد يومي', 'Daily'))),
            ],
            selected: {mode},
            onSelectionChanged: (v) => setState(() => mode = v.first),
          ),
          const SizedBox(height: 12),
          if (mode == 0) ...[
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final n in [3, 7, 10, 15, 20, 29, 30, 40, 60, 90])
                ChoiceChip(
                  label: Text('$n ${tr('يوم', 'd')}'),
                  selected: days == n,
                  onSelected: (_) => setState(() {
                    days = n;
                    daysC.clear();
                  }),
                ),
            ]),
            const SizedBox(height: 10),
            NumField(t('أو عدد أيام تاني', 'أو عدد أيام آخر', 'Or custom days'), daysC, decimal: false, suffix: tr('يوم', 'days'), onChanged: (v) {
              final n = parseNum(v).round();
              if (n > 0) setState(() => days = n);
            }),
          ],
          if (mode == 1) ...[
            MDateButton(
              label: t('تختم يوم', 'تاريخ الختم', 'Finish by'),
              value: endDate,
              first: today,
              last: today.add(const Duration(days: 3650)),
              color: SD.green,
              onPick: (d) => setState(() => endDate = d),
            ),
            const SizedBox(height: 8),
            if (ram != null)
              OutlinedButton.icon(
                onPressed: () => setState(() => endDate = ram),
                icon: const Icon(Icons.nightlight_round),
                label: Text('${t('لحدي آخر رمضان', 'حتى نهاية رمضان', 'Until the end of Ramadan')} (${fmtDateAr(ram, weekday: false)})'),
              ),
          ],
          if (mode == 2) ...[
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final (n, label) in [
                (2, t('صفحتين', 'صفحتان', '2 pages')),
                (4, t('4 صفحات', '4 صفحات', '4 pages')),
                (5, t('5 صفحات', '5 صفحات', '5 pages')),
                (10, t('حزب', 'حزب', '1 hizb')),
                (20, t('جزء', 'جزء', '1 juz')),
                (40, t('جزئين', 'جزءان', '2 juz')),
                (60, t('3 أجزاء', '3 أجزاء', '3 juz')),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: dailyPages == n,
                  onSelected: (_) => setState(() {
                    dailyPages = n;
                    pagesC.clear();
                  }),
                ),
            ]),
            const SizedBox(height: 10),
            NumField(t('أو عدد صفحات في اليوم', 'أو عدد صفحات يوميًا', 'Or pages per day'), pagesC, decimal: false, onChanged: (v) {
              final n = parseNum(v).round();
              if (n > 0) setState(() => dailyPages = n);
            }),
          ],
          const SizedBox(height: 6),
          NumField(t('بادي من صفحة', 'البدء من صفحة', 'Start from page'), startC, decimal: false, hint: '1', onChanged: (_) => setState(() {})),
          InfoRow(t('مدة الختمة', 'مدة الختمة', 'Duration'), '$d ${t('يوم', 'يومًا', 'days')}', icon: Icons.date_range_rounded),
          InfoRow(t('ورد اليوم', 'الورد اليومي', 'Daily portion'), '${fmt(perDay, 1)} ${t('صفحة', 'صفحة', 'pages')}', icon: Icons.auto_stories_rounded, valueColor: SD.green),
          InfoRow(t('يعني بالأجزاء', 'بالأجزاء', 'In juz'), '${fmt(perDay / 20, 2)} ${t('جزء', 'جزء', 'juz')} • ${fmt(perDay / 10, 1)} ${t('حزب', 'حزب', 'hizb')}', icon: Icons.layers_rounded),
          InfoRow(t('بعد كل صلاة', 'بعد كل صلاة', 'After each prayer'), '${fmt(perDay / 5, 1)} ${t('صفحة', 'صفحة', 'pages')}', icon: Icons.mosque_rounded,
              hint: t('لو قسّمت الورد على الخمس صلوات', 'إذا قسّمت الورد على الصلوات الخمس', 'Split over the five prayers')),
          InfoRow(t('الوقت التقريبي', 'الوقت التقريبي', 'Approx. time'), '${fmt(perDay * 2, 0)} ${t('دقيقة/يوم', 'دقيقة/يوم', 'min/day')}', icon: Icons.timer_outlined,
              hint: t('بحساب دقيقتين للصفحة تقريبًا', 'بمعدل دقيقتين للصفحة تقريبًا', 'At roughly 2 minutes per page')),
          InfoRow(t('تختم يوم', 'تاريخ الختم', 'Finish date'), fmtDateAr(today.add(Duration(days: d - 1))), icon: Icons.flag_rounded),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => _startPlan(s), icon: const Icon(Icons.play_arrow_rounded), label: Text(t('يلا نبدأ الختمة', 'ابدأ الختمة', 'Start the khatma'))),
        ]),
      ),
      NoteBox(
          t('ختمة في 30 يوم = جزء في اليوم = 4 صفحات بعد كل صلاة. المصحف 604 صفحة، 30 جزء، 60 حزب.',
              'الختمة في 30 يومًا = جزء يوميًا = 4 صفحات بعد كل صلاة. المصحف 604 صفحات، 30 جزءًا، 60 حزبًا.',
              'A 30-day khatma = 1 juz a day = 4 pages after each prayer. The Mushaf has 604 pages, 30 juz, 60 hizb.'),
          kind: NoteKind.tip),
      if (hist.isNotEmpty) _historyCard(s, hist),
    ]);
  }

  /* ───────────── المتابعة ───────────── */
  Widget _progress(AppState s, Map<String, dynamic> p) {
    final start = mParseKey(p['start']) ?? today;
    final end = mParseKey(p['end']) ?? today;
    final sp = (p['sp'] as num?)?.toInt() ?? 0;
    final page = (p['page'] as num).toInt();
    final log = Map<String, dynamic>.from(p['log'] ?? {});
    final readToday = (log[mkey(today)] as num?)?.toInt() ?? 0;
    final totalDays = mDaysBetween(start, end) + 1;
    final dayIdx = (mDaysBetween(start, today) + 1).clamp(1, 100000);
    final remDays = mDaysBetween(today, end) + 1;
    final overdue = remDays <= 0;
    final remPages = quranPages - page;
    final need = _todayNeed(p, page - readToday);
    final todayLeft = math.max(0, need - readToday);
    final progress = page / quranPages;
    final expectedEndToday = (sp + (quranPages - sp) * math.min(dayIdx, totalDays) / totalDays).round();
    final diff = page - expectedEndToday;
    final pace = (page - sp) / dayIdx;
    final projected = pace > 0 ? today.add(Duration(days: (remPages / pace).ceil() - (readToday > 0 ? 1 : 0))) : null;
    final cur = math.max(1, page);
    final from = math.min(quranPages, page + 1), to = math.min(quranPages, page + todayLeft);
    final undo = (p['undo'] as List?) ?? [];
    final name = (p['name'] as String?) ?? '';

    // آخر 7 أيام
    final bars = <(String, double)>[];
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final short = weekdaysAr[d.weekday - 1];
      bars.add((i == 0 ? tr('اليوم', 'Today') : (isEn ? short.substring(0, 3) : short.replaceFirst('ال', '')), ((log[mkey(d)] as num?) ?? 0).toDouble()));
    }

    return ToolList(children: [
      SCard(
        color: SD.green,
        child: Column(children: [
          if (name.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          MoreRing(
            progress: progress,
            color: SD.green,
            size: 210,
            stroke: 16,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📖', style: TextStyle(fontSize: 28)),
              Text('$page', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: readable(context, SD.green))),
              Text('${t('من', 'من', 'of')} $quranPages ${t('صفحة', 'صفحة', 'pages')}', style: const TextStyle(fontSize: 12.5)),
              Text('${fmt(progress * 100, 1)}%', style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold)),
            ]),
          ),
          const SizedBox(height: 10),
          Text('${t('الجزء', 'الجزء', 'Juz')} ${juzOfPage(cur)} • ${t('الحزب', 'الحزب', 'Hizb')} ${hizbOfPage(cur)} • ${t('سورة', 'سورة', 'Surah')} ${surahAtPage(cur)}',
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            overdue
                ? t('الموعد فات — ما مشكلة، كمّل وربنا يتقبّل', 'انتهى الموعد المحدد — لا بأس، أكمل وتقبّل الله', 'The target date passed — no worries, keep going')
                : diff >= 0
                    ? t('ماشي تمام ${diff > 0 ? '— متقدّم $diff صفحة' : ''} 👌', 'أنت على المسار${diff > 0 ? ' — متقدم بـ$diff صفحة' : ''} 👌', 'On track${diff > 0 ? ' — $diff pages ahead' : ''} 👌')
                    : t('متأخر ${-diff} صفحة عن الخطة', 'متأخر ${-diff} صفحة عن الخطة', '${-diff} pages behind plan'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, overdue || diff < 0 ? SD.henna : SD.green)),
          ),
        ]),
      ),
      SCard(
        title: t('ورد الليلة', 'ورد اليوم', "Today's portion"),
        icon: Icons.today_rounded,
        color: SD.teal,
        trailing: Text('$readToday/$need', style: const TextStyle(fontWeight: FontWeight.w800)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LinearProgressIndicator(value: (readToday / need).clamp(0, 1).toDouble(), minHeight: 10, borderRadius: BorderRadius.circular(8), color: SD.teal),
          const SizedBox(height: 10),
          if (todayLeft > 0 && page < quranPages)
            Text(
              '${t('اقرا من صفحة', 'اقرأ من صفحة', 'Read from page')} $from (${surahAtPage(from)}) ${t('لحدي صفحة', 'إلى صفحة', 'to page')} $to (${surahAtPage(to)})',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            )
          else
            Text(t('✅ كمّلت ورد الليلة — أي زيادة بتقرّب الختمة', '✅ أتممت ورد اليوم — كل زيادة تقرّب الختمة', "✅ Today's portion is done — extra reading brings the finish closer"),
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: readable(context, SD.green))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            _quick(s, p, page, 1, t('+ صفحة', '+ صفحة', '+1 page')),
            _quick(s, p, page, 2, t('+ صفحتين', '+ صفحتان', '+2 pages')),
            _quick(s, p, page, 10, t('+ حزب', '+ حزب', '+1 hizb')),
            _quick(s, p, page, 20, t('+ جزء', '+ جزء', '+1 juz')),
            if (todayLeft > 0)
              ActionChip(
                avatar: const Icon(Icons.done_all_rounded, color: SD.green, size: 20),
                label: Text(t('قريت الورد كلو (+$todayLeft)', 'قرأت الورد كاملًا (+$todayLeft)', 'Read it all (+$todayLeft)')),
                onPressed: () => _setPage(s, p, page + todayLeft),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: NumField(t('وصلت لحدي صفحة', 'وصلت إلى صفحة', 'I reached page'), reachC, decimal: false, hint: '${math.min(quranPages, page + 1)}')),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton(
                onPressed: () {
                  final v = parseNum(reachC.text).round();
                  if (v < 0 || v > quranPages) return toast(t('الصفحة من 1 لـ 604', 'رقم الصفحة من 1 إلى 604', 'Page must be 1–604'));
                  _setPage(s, p, v);
                  reachC.clear();
                  FocusScope.of(context).unfocus();
                },
                child: Text(tr('حفظ', 'Save')),
              ),
            ),
          ]),
          if (undo.isNotEmpty)
            TextButton.icon(onPressed: () => _undo(s, p), icon: const Icon(Icons.undo_rounded), label: Text(t('تراجع عن آخر تسجيل', 'تراجع عن آخر تسجيل', 'Undo last entry'))),
        ]),
      ),
      StatGrid([
        StatChip('$dayIdx/$totalDays', t('اليوم', 'اليوم', 'Day'), color: SD.green, icon: Icons.calendar_today_rounded),
        StatChip(overdue ? '0' : '$remDays', t('أيام فاضلة', 'أيام متبقية', 'Days left'), color: SD.teal, icon: Icons.hourglass_bottom_rounded),
        StatChip('$remPages', t('صفحات فاضلة', 'صفحات متبقية', 'Pages left'), color: SD.nile, icon: Icons.auto_stories_rounded),
        StatChip('$need', t('المطلوب/يوم', 'المطلوب يوميًا', 'Needed/day'), color: SD.gold, icon: Icons.flag_rounded),
        StatChip(fmt(pace, 1), t('معدلك/يوم', 'معدلك اليومي', 'Your pace/day'), color: SD.purple, icon: Icons.speed_rounded),
        StatChip(fmt(remPages / 20, 1), t('أجزاء فاضلة', 'أجزاء متبقية', 'Juz left'), color: SD.henna, icon: Icons.layers_rounded),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: t('متين بتختم؟', 'متى تختم؟', 'When will you finish?'),
        icon: Icons.event_available_rounded,
        color: SD.indigo,
        child: Column(children: [
          InfoRow(t('الموعد المخطط', 'الموعد المخطط', 'Planned date'), fmtDateAr(end), icon: Icons.flag_rounded),
          InfoRow(t('بمعدلك الحالي', 'بمعدلك الحالي', 'At your current pace'), projected == null ? '—' : fmtDateAr(projected), icon: Icons.trending_up_rounded,
              valueColor: projected == null ? null : (projected.isAfter(end) ? SD.henna : SD.green),
              hint: projected == null ? t('سجّل قرايتك عشان نحسب', 'سجّل قراءتك لنحسب', 'Log some reading to project') : null),
          InfoRow(t('بديت يوم', 'تاريخ البدء', 'Started'), fmtDateAr(start), icon: Icons.play_circle_outline_rounded),
          const SizedBox(height: 8),
          MDateButton(
            label: t('غيّر موعد الختم', 'تغيير موعد الختم', 'Change target date'),
            value: end,
            first: today,
            last: today.add(const Duration(days: 3650)),
            color: SD.indigo,
            onPick: (d) {
              p['end'] = mkey(d);
              s.setData('khatma_plan', p);
              setState(() {});
            },
          ),
        ]),
      ),
      SCard(
        title: t('آخر 7 أيام (صفحات)', 'آخر 7 أيام (صفحات)', 'Last 7 days (pages)'),
        icon: Icons.bar_chart_rounded,
        color: SD.teal,
        child: MiniBars(bars, goal: need.toDouble(), color: SD.teal),
      ),
      SCard(
        title: t('الأجزاء الـ30', 'الأجزاء الثلاثون', 'The 30 juz'),
        icon: Icons.grid_view_rounded,
        color: SD.gold,
        child: Column(children: [
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var j = 1; j <= 30; j++) _juzCell(s, p, j, page),
            ],
          ),
          const SizedBox(height: 8),
          Text(t('دوس على جزء عشان تسجّل إنك وصلت آخرو', 'اضغط على جزء لتسجيل الوصول إلى نهايته', 'Tap a juz to mark it as finished'), style: const TextStyle(fontSize: 11.5)),
        ]),
      ),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmCancel(s),
            icon: const Icon(Icons.close_rounded),
            label: Text(t('الغي الختمة', 'إلغاء الختمة', 'Cancel khatma')),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      ShareBar(() => [
            '📖 ${name.isNotEmpty ? name : t('ختمتي', 'ختمتي', 'My khatma')}',
            '${t('وصلت صفحة', 'وصلت إلى صفحة', 'Reached page')} $page/$quranPages (${fmt(progress * 100, 1)}%) — ${t('الجزء', 'الجزء', 'Juz')} ${juzOfPage(cur)}',
            '${t('اليوم', 'اليوم', 'Day')} $dayIdx/$totalDays • ${t('الختم', 'الختم', 'Finish')}: ${fmtDateAr(end)}',
          ].join('\n')),
      const SizedBox(height: 12),
      if (_history(s).isNotEmpty) _historyCard(s, _history(s)),
      const NoteBox('﴿وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا﴾ — «اقرؤوا القرآن فإنه يأتي يوم القيامة شفيعًا لأصحابه»', kind: NoteKind.tip),
      NoteBox(t('أرقام الصفحات حسب مصحف المدينة (604 صفحة). بدايات الأحزاب تقريبية.', 'أرقام الصفحات وفق مصحف المدينة (604 صفحات). بدايات الأحزاب تقريبية.',
          'Page numbers follow the Madinah Mushaf (604 pages). Hizb boundaries are approximate.')),
    ]);
  }

  Widget _quick(AppState s, Map<String, dynamic> p, int page, int n, String label) => ActionChip(
        avatar: const Icon(Icons.add_rounded, color: SD.teal, size: 18),
        label: Text(label),
        onPressed: page >= quranPages ? null : () => _setPage(s, p, page + n),
      );

  Widget _juzCell(AppState s, Map<String, dynamic> p, int j, int page) {
    final startP = juzStartPage(j), endP = j == 30 ? quranPages : juzStartPage(j + 1) - 1;
    final done = page >= endP;
    final current = !done && page >= startP - 1;
    final c = done ? SD.green : (current ? SD.gold : Theme.of(context).colorScheme.onSurface.withValues(alpha: .25));
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(t('تسجّل إنك وصلت آخر الجزء $j (صفحة $endP)؟', 'هل تريد تسجيل الوصول إلى نهاية الجزء $j (صفحة $endP)؟', 'Mark progress up to the end of juz $j (page $endP)?')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('لا', 'لا', 'No'))),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('أيوه', 'نعم', 'Yes'))),
            ],
          ),
        );
        if (ok == true) _setPage(s, p, endP);
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withValues(alpha: done ? .85 : .15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c, width: current ? 2 : 1),
        ),
        child: Text('$j', style: TextStyle(fontWeight: FontWeight.w800, color: done ? Colors.white : null)),
      ),
    );
  }

  Future<void> _confirmCancel(AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('تلغي الختمة؟', 'إلغاء الختمة؟', 'Cancel this khatma?')),
        content: Text(t('حيضيع التقدّم الحالي.', 'سيُحذف التقدّم الحالي.', 'Current progress will be lost.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('لا خليها', 'تراجع', 'Keep it'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('أيوه الغيها', 'نعم، ألغِها', 'Yes, cancel'))),
        ],
      ),
    );
    if (ok == true) {
      s.setData('khatma_plan', null);
      setState(() {});
    }
  }

  Widget _historyCard(AppState s, List<Map> hist) => SCard(
        title: t('ختماتك السابقة', 'الختمات السابقة', 'Completed khatmas'),
        icon: Icons.history_rounded,
        color: SD.coffee,
        trailing: Text('${hist.length} 🏅', style: const TextStyle(fontWeight: FontWeight.w800)),
        child: Column(children: [
          for (final h in hist.take(20))
            InfoRow(
              (h['n'] as String?)?.isNotEmpty == true ? h['n'] : '${t('ختمة', 'ختمة', 'Khatma')} ${fmtDateAr(mParseKey(h['e']) ?? today, weekday: false)}',
              '${h['d']} ${t('يوم', 'يومًا', 'days')}',
              icon: Icons.check_circle_rounded,
              valueColor: SD.green,
              hint: '${fmtDateAr(mParseKey(h['s']) ?? today, weekday: false)} → ${fmtDateAr(mParseKey(h['e']) ?? today, weekday: false)}',
            ),
        ]),
      );
}
