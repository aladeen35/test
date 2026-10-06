import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/data.dart';
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/plus/vitals_tool.dart';
import 'package:amir_tools/tools/plus/sizes_tool.dart';
import 'package:amir_tools/tools/plus/proverbs_data.dart';

const _ids = {'vitals', 'child_growth', 'sizes', 'proverbs'};

void _seed(AppState s) {
  final now = DateTime.now();
  s.setData('vitals_entries', [
    for (var i = 0; i < 20; i++)
      {'id': 'g$i', 'k': 'g', 't': now.subtract(Duration(hours: 12 * (20 - i))).millisecondsSinceEpoch, 'v': 80.0 + i * 12, 'c': ['fast', 'pre', 'post2', 'rand'][i % 4], if (i.isEven) 'n': 'note with a fairly long description text here'},
    for (var i = 0; i < 20; i++)
      {'id': 'b$i', 'k': 'bp', 't': now.subtract(Duration(hours: 12 * (20 - i))).millisecondsSinceEpoch, 's': 110 + i * 4, 'd': 70 + i * 3, 'p': 55 + i * 3, 'n': 'after walking'},
  ]);
  s.setData('child_growth_kids', [
    {
      'id': 'k1', 'name': 'Mohammed Abdelrahman Elkhalifa', 'sex': 'm', 'birth': '2025-01-15', 'color': 2,
      'm': [
        {'id': 'm1', 'd': '2025-01-15', 'w': 3.2, 'h': 50.0, 'hc': 34.5},
        {'id': 'm2', 'd': '2025-03-15', 'w': 5.4, 'h': 57.5},
        {'id': 'm3', 'd': '2025-07-20', 'w': 7.6, 'h': 66.0, 'hc': 42.0},
        {'id': 'm4', 'd': '2026-09-01', 'w': 11.1, 'h': 82.0, 'hc': 47.0},
      ],
      'vac': [
        {'id': 'v1', 'd': '2025-03-15', 'text': 'Pentavalent dose 1 + polio + rotavirus + pneumococcal, written on the card'},
        {'id': 'v2', 'd': '2027-01-15', 'text': 'Booster'},
      ],
    },
    {'id': 'k2', 'name': 'Sara', 'sex': 'f', 'birth': '2020-05-02', 'color': 7, 'm': [], 'vac': []},
  ]);
  s.setData('proverbs_favs', [allProverbs[3].text]);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('التصنيفات الطبية', () {
    expect(classifyGlucose(85, 'fast').normal, isTrue);
    expect(classifyGlucose(110, 'fast').normal, isFalse);
    expect(classifyGlucose(126, 'fast').alert, 0);
    expect(classifyGlucose(60, 'fast').alert, 1);
    expect(classifyGlucose(50, 'rand').alert, 2);
    expect(classifyGlucose(139, 'post2').normal, isTrue);
    expect(classifyGlucose(150, 'post2').normal, isFalse);
    expect(classifyBp(118, 78).normal, isTrue);
    expect(classifyBp(125, 78).normal, isFalse);
    expect(classifyBp(185, 100).alert, 2);
    expect(classifyBp(150, 125).alert, 2);
    expect(ringDiameterFromUs(7), closeTo(17.32, .01));
    expect(ringEuFromDiameter(ringDiameterFromUs(7)), closeTo(54.4, .1));
  });

  test('الأمثال: قائمة الصفحة الرئيسية أولًا وبنفس الترتيب', () {
    for (var i = 0; i < sudaneseProverbs.length; i++) {
      expect(allProverbs[i].text, sudaneseProverbs[i].$1);
    }
    expect(allProverbs.map((p) => p.text).toSet().length, allProverbs.length);
    expect(allProverbs.length, greaterThanOrEqualTo(40));
  });

  test('أدوات plus مسجّلة ومترجمة', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => _ids.contains(t.id)).toList();
      expect(mine.length, _ids.length);
      for (final t in mine) {
        if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
      }
    }
    appLang = Lang.sd;
  });

  for (final lang in Lang.values) {
    for (final seeded in [false, true]) {
      for (final width in [360.0, 415.0]) {
        testWidgets('أدوات plus — ${lang.name} ${seeded ? 'ببيانات' : 'فارغة'} ${width.toInt()}dp', (tester) async {
          SharedPreferences.setMockInitialValues({});
          final s = await AppState.load();
          s.lang = lang;
          if (seeded) _seed(s);
          tester.view.physicalSize = Size(width * 2.6, 2340);
          tester.view.devicePixelRatio = 2.6;
          addTearDown(tester.view.reset);
          final failures = <String>[];
          final orig = FlutterError.onError;
          String? cur;
          FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
          addTearDown(() => FlutterError.onError = orig);
          final tools = allTools.where((t) => _ids.contains(t.id)).toList();
          for (final tool in tools) {
            // كل تبويبات المقاسات / وضعي السكر والضغط
            final variants = tool.id == 'sizes' ? 4 : 1;
            for (var v = 0; v < variants; v++) {
              if (tool.id == 'sizes') s.setData('sizes_tab', v);
              cur = '${tool.id}#$v';
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
              // تمرير لأسفل لبناء كل العناصر
              for (var k = 0; k < 12; k++) {
                final lv = find.byType(Scrollable);
                if (lv.evaluate().isEmpty) break;
                await tester.drag(lv.first, const Offset(0, -600), warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 30));
              }
              if (tool.id == 'vitals') {
                // وضع الضغط
                await tester.drag(find.byType(Scrollable).first, const Offset(0, 20000), warnIfMissed: false);
                await tester.pump();
                await tester.tap(find.byIcon(Icons.monitor_heart_rounded).first, warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 50));
                for (var k = 0; k < 12; k++) {
                  await tester.drag(find.byType(Scrollable).first, const Offset(0, -600), warnIfMissed: false);
                  await tester.pump(const Duration(milliseconds: 30));
                }
              }
              await tester.pumpWidget(const SizedBox());
              await tester.pump(const Duration(seconds: 5));
            }
          }
          FlutterError.onError = orig;
          expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
        });
      }
    }
  }
}
