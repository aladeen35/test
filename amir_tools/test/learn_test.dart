import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/services/prayer.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/learn/learn_common.dart';
import 'package:amir_tools/tools/learn/hifz_logic.dart';
import 'package:amir_tools/tools/learn/last_third_tool.dart';
import 'package:amir_tools/tools/learn/fidya_tool.dart';
import 'package:amir_tools/tools/learn/sd_certificate_tool.dart';
import 'package:amir_tools/tools/learn/flashcards_tool.dart';
import 'package:amir_tools/tools/learn/times_table_tool.dart';

const _ids = ['hifz', 'last_third', 'fidya', 'sd_certificate', 'flashcards', 'times_table'];

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('الحفظ', () {
    test('بدايات الأجزاء صحيحة ومجموع الصفحات 604', () {
      const starts = [1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];
      for (var j = 1; j <= 30; j++) {
        expect(hJuzStart(j), starts[j - 1], reason: 'juz $j');
        expect(hJuzOf(starts[j - 1]), j);
        if (j > 1) expect(hJuzOf(starts[j - 1] - 1), j - 1);
      }
      var total = 0;
      for (var j = 1; j <= 30; j++) {
        total += juzPageCount(j);
      }
      expect(total, 604);
    });

    test('الترتيب يغطي 604 صفحة بلا تكرار', () {
      for (final fwd in [true, false]) {
        for (final st in [0, 66, 113]) {
          final seq = hifzSequence(st, fwd);
          expect(seq.length, 604);
          expect(seq.toSet().length, 604);
        }
      }
      final back = hifzSequence(113, false);
      expect(back.first, 604);
      expect(back.take(3), [604, 603, 602]);
      expect(hifzSequence(0, true).take(3), [1, 2, 3]);
    });

    test('الورد بالأسطر يكمل الصفحات', () {
      final seq = hifzSequence(113, false);
      final p = nextPortion(seq, {}, 10, 25);
      expect(p.first.page, 604);
      expect(p.first.from, 11);
      expect(p.first.to, 15);
      expect(p[1].page, 603);
      expect(p[1].to, 15);
      expect(p.last.page, 602);
      expect(p.last.to, 5);
      final r = applyPortion(p);
      expect(r.completed, [604, 603]);
      expect(r.partial, 5);
    });

    test('خطة المراجعة', () {
      final today = DateTime(2026, 10, 7);
      final mem = <int, DateTime>{
        for (var p = 582; p <= 600; p++) p: DateTime(2026, 8, 1),
        for (var p = 601; p <= 604; p++) p: DateTime(2026, 10, 6),
      };
      final r = reviewFor(mem, today, perDay: 5);
      expect(r.recent, [601, 602, 603, 604]);
      expect(r.oldTotal, 19);
      expect(r.cycleDays, 4);
      expect(r.old.length, lessThanOrEqualTo(5));
      // كل القديم يغطّى في دورة كاملة
      final seen = <int>{};
      for (var i = 0; i < r.cycleDays; i++) {
        seen.addAll(reviewFor(mem, today.add(Duration(days: i)), perDay: 5).old);
      }
      expect(seen.length, 19);
      expect(pageRanges([582, 583, 584, 600, 601]), [(30, 582, 584), (30, 600, 601)]);
      expect(hifzDaysLeft(0, 0, 15, 7), 604);
      expect(hifzDaysLeft(604, 0, 15, 7), 0);
    });

    test('السلسلة', () {
      final today = DateTime(2026, 10, 7);
      expect(hifzStreak({'2026-10-07', '2026-10-06', '2026-10-04'}, today, lDk), 2);
      expect(hifzStreak({'2026-10-06', '2026-10-05'}, today, lDk), 2);
      expect(hifzStreak({}, today, lDk), 0);
    });
  });

  test('الثلث الأخير: من المغرب إلى الفجر', () {
    Map<String, DateTime> tf(DateTime d) => prayerTimes(d.year, d.month, d.day, 15.5, 32.56);
    final n = nightOf(tf, DateTime(2026, 10, 7));
    expect(n.length.inHours, inInclusiveRange(10, 12));
    expect(n.lastThird.isAfter(n.mid), isTrue);
    expect(n.fajr.difference(n.lastThird).inSeconds, closeTo(n.length.inSeconds / 3, 2));
    expect(n.mid.difference(n.start).inSeconds, closeTo(n.length.inSeconds / 2, 2));
    final fajr = tf(DateTime(2026, 10, 7))['fajr']!;
    expect(currentEvening(tf, DateTime(2026, 10, 7), fajr.subtract(const Duration(hours: 1))), DateTime(2026, 10, 6));
    expect(currentEvening(tf, DateTime(2026, 10, 7), fajr.add(const Duration(hours: 1))), DateTime(2026, 10, 7));
  });

  test('الفدية', () {
    expect(feedCost(30, FeedMeasure.mudd, 1000, 0).kg, closeTo(18, 1e-9));
    expect(feedCost(30, FeedMeasure.mudd, 1000, 0).cost, closeTo(18000, 1e-6));
    expect(feedCost(10, FeedMeasure.halfSaa, 100, 0).kg, closeTo(16, 1e-9));
    expect(feedCost(60, FeedMeasure.meal, 0, 500).cost, 30000);
  });

  test('الشهادة السودانية: الإلزامية + أفضل 3', () {
    final subs = [
      const CertSubject('isl', 90, true),
      const CertSubject('ar', 80, true),
      const CertSubject('en', 70, true),
      const CertSubject('math', 60, true),
      const CertSubject('phy', 95, false),
      const CertSubject('chem', 50, false),
      const CertSubject('bio', 85, false),
      const CertSubject('cs', 75, false),
    ];
    final r = certCompute(subs);
    expect(r.counted.toSet(), {'isl', 'ar', 'en', 'math', 'phy', 'bio', 'cs'});
    expect(r.sum, 555);
    expect(r.pct, closeTo(555 / 7, 1e-9));
    expect(certGrade(r.pct), 'B');
    final need = certNeeded(r, subs, 90);
    expect(need.extra, closeTo(75, 1e-9));
    expect(need.possible, isTrue);
    expect(certNeeded(r, subs, 70).extra, 0);
    expect(certNeeded(r, subs, 100).possible, isTrue);
    final partial = certCompute([const CertSubject('a', 100, true)]);
    expect(partial.missing, 6);
    expect(certNeeded(partial, [const CertSubject('a', 100, true)], 100).possible, isTrue);
  });

  test('لايتنر والاستيراد', () {
    final today = DateTime(2026, 10, 7);
    var c = <String, dynamic>{'id': 'x', 'f': 'a', 'b': 'b', 'x': 1};
    c = leitnerAnswer(c, true, today);
    expect(c['x'], 2);
    expect(c['d'], '2026-10-09');
    c = leitnerAnswer(c, true, today);
    c = leitnerAnswer(c, true, today);
    c = leitnerAnswer(c, true, today);
    c = leitnerAnswer(c, true, today);
    expect(c['x'], 5);
    c = leitnerAnswer(c, false, today);
    expect(c['x'], 1);
    expect(c['r'], 5);
    expect(c['w'], 1);
    expect(cardDue(c, today), isFalse);
    expect(cardDue(c, today.add(const Duration(days: 1))), isTrue);
    final p = parseCards('Apple | تفاحة\n\nbad line\nCat|كديس | قط\nDog\tكلب');
    expect(p, [('Apple', 'تفاحة'), ('Cat', 'كديس | قط'), ('Dog', 'كلب')]);
    expect(deckToText('D', [{'f': 'a', 'b': 'b'}]), '🗂️ D\na | b');
  });

  test('جدول الضرب: 4 اختيارات مختلفة فيها الإجابة', () {
    final rnd = math.Random(1);
    for (var a = 1; a <= 12; a++) {
      for (var b = 1; b <= 12; b++) {
        final c = ttChoices(a, b, rnd);
        expect(c.length, 4);
        expect(c.toSet().length, 4);
        expect(c, contains(a * b));
        expect(c.every((x) => x > 0), isTrue);
      }
    }
    expect(ttStars(10, 10), 3);
    expect(ttStars(7, 10), 2);
    expect(ttStars(5, 10), 1);
    expect(ttStars(2, 10), 0);
  });

  test('الأدوات مسجّلة ومترجمة', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => _ids.contains(t.id)).toList();
      expect(mine.length, _ids.length);
      if (l == Lang.en) {
        for (final t in mine) {
          expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
        }
      }
    }
    appLang = Lang.sd;
  });

  for (final width in [320.0, 411.0]) {
    for (final lang in Lang.values) {
      testWidgets('أدوات القراية تُفتح دون أخطاء — ${lang.name} @$width', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        final today = lToday();
        s.setData('hifz_mem', {
          for (var p = 582; p <= 600; p++) '$p': lDk(lAddDays(today, -40)),
          for (var p = 601; p <= 604; p++) '$p': lDk(lAddDays(today, -1)),
          for (var p = 562; p <= 570; p++) '$p': lDk(lAddDays(today, -60)),
        });
        s.setData('hifz_partial', 4);
        s.setData('hifz_cfg', {'dir': 'back', 'start': 113, 'unit': 'lines', 'amount': 7, 'notify': 330});
        s.setData('hifz_log', {
          lDk(lAddDays(today, -1)): {'l': 7, 'p': [601], 'pp': 0, 'from': 601, 'to': 601},
          lDk(lAddDays(today, -2)): {'l': 7, 'p': [], 'pp': 0, 'from': 602, 'to': 602},
        });
        s.setData('sd_certificate_data', {
          'track': 'sci',
          'target': '95',
          'subjects': {
            'sci': [
              {'id': 'a', 'k': 'islamic', 'c': true, 'm': 92},
              {'id': 'b', 'k': 'arabic', 'c': true, 'm': 81.5},
              {'id': 'c', 'k': 'english', 'c': true, 'm': 77},
              {'id': 'd', 'k': 'math_sp', 'c': true, 'm': 68},
              {'id': 'e', 'k': 'physics', 'c': false, 'm': 88},
              {'id': 'f', 'k': 'chemistry', 'c': false, 'm': 59},
              {'id': 'g', 'n': 'مادة باسم طويل جدًا جدًا للتجربة فقط Very long subject name', 'c': false, 'm': 99},
              {'id': 'h', 'k': 'computer', 'c': false, 'm': null},
            ],
          },
        });
        s.setData('times_table_best', {'score': 18, 'total': 20, 'streak': 12, 'games': 5});
        s.setData('times_table_hist', [
          {'d': lDk(today), 'r': 9, 'n': 10, 's': 3},
        ]);
        tester.view.physicalSize = Size(width * 2.6, 2340 * 12);
        tester.view.devicePixelRatio = 2.6;
        addTearDown(tester.view.reset);
        final failures = <String>[];
        final orig = FlutterError.onError;
        String? cur;
        FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
        addTearDown(() => FlutterError.onError = orig);

        Future<void> pumpTool(String id, {Future<void> Function()? then}) async {
          cur = id;
          final tool = allTools.firstWhere((t) => t.id == id);
          await tester.pumpWidget(ChangeNotifierProvider.value(
            value: s,
            child: MaterialApp(
              locale: Locale(lang == Lang.en ? 'en' : 'ar'),
              theme: buildTheme(Brightness.dark),
              home: Directionality(
                textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl,
                child: Scaffold(body: Builder(builder: tool.builder)),
              ),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          if (then != null) await then();
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        }

        for (final id in _ids) {
          await pumpTool(id);
        }
        // الحالات الأخرى
        for (final tab in [1, 2]) {
          s.setData('fidya_in', {'tab': tab, 'm': tab, 'start': lDk(today)});
          await pumpTool('fidya');
        }
        s.setData('sd_certificate_data', {'track': 'arts'});
        await pumpTool('sd_certificate');
        await pumpTool('last_third', then: () async {
          await tester.tap(find.descendant(of: find.byType(SegmentedButton<bool>), matching: find.byType(Text)).last);
          await tester.pump();
        });
        // البطاقات: افتح مجموعة وذاكر
        await pumpTool('flashcards', then: () async {
          await tester.tap(find.byType(InkWell).first);
          await tester.pump();
          await tester.tap(find.byIcon(Icons.all_inclusive_rounded));
          await tester.pump();
          await tester.tap(find.byIcon(Icons.flip_rounded));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.check_rounded));
          await tester.pump();
        });
        // جدول الضرب: اللعبة
        await pumpTool('times_table', then: () async {
          await tester.tap(find.byType(SegmentedButton<int>).first);
          await tester.pump();
          final segs = find.descendant(of: find.byType(SegmentedButton<int>).first, matching: find.byType(Text));
          await tester.tap(segs.last);
          await tester.pump();
          await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
          await tester.pump();
          await tester.tap(find.descendant(of: find.byType(Wrap).last, matching: find.byType(FilledButton)).first);
          await tester.pump(const Duration(seconds: 2));
          await tester.tap(find.byIcon(Icons.stop_circle_outlined));
          await tester.pump(const Duration(seconds: 2));
        });
        FlutterError.onError = orig;
        expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
      });
    }
  }
}
