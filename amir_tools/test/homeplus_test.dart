import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/homeplus/hp_common.dart';
import 'package:amir_tools/tools/homeplus/gas_tool.dart';
import 'package:amir_tools/tools/homeplus/generator_tool.dart';
import 'package:amir_tools/tools/homeplus/car_care_tool.dart';
import 'package:amir_tools/tools/homeplus/power_cuts_tool.dart';
import 'package:amir_tools/tools/homeplus/pantry_tool.dart';

const ids = ['gas', 'generator', 'car_care', 'power_cuts', 'pantry'];

void seed(AppState s) {
  final today = pToday();
  String d(int off) => dk(today.add(Duration(days: off)));
  s.setData('gas_list', [
    {'id': 'a', 'd': d(-70), 'p': 18000, 'kg': 12.5},
    {'id': 'b', 'd': d(-40), 'p': 21000, 'kg': 12.5},
    {'id': 'c', 'd': d(-8), 'p': 25000},
  ]);
  s.setData('gas_cfg', {'notify': true, 'cur': 'Sudanese pounds SDG'});
  s.setData('generator_log', [
    {'id': '1', 'k': 'run', 'd': d(-3), 'h': 6, 't': 1},
    {'id': '2', 'k': 'oil', 'd': d(-2), 't': 2},
    {'id': '3', 'k': 'run', 'd': d(-1), 'h': 7.5, 't': 3},
  ]);
  s.setData('generator_cfg', {'rating': 13.5, 'hours': 8, 'price': 2800, 'cur': 'SDG', 'oil': 150, 'kva': true, 'diesel': true, 'load': 60});
  s.setData('car_cars', [
    {
      'id': 'car1',
      'name': 'Toyota Corolla 2015 family car with a long name',
      'odo': 120500,
      'odoLog': [
        {'d': d(-60), 'km': 118000},
        {'d': d(0), 'km': 120500},
      ],
      'items': [
        {'id': 'i1', 'k': 'oil', 'km': 5000, 'mo': 6, 'lastKm': 114000, 'lastD': d(-200)},
        {'id': 'i2', 'k': 'licence', 'mo': 12, 'lastD': d(-355)},
        {'id': 'i3', 'k': 'air_filter', 'km': 15000, 'mo': 12},
        {'id': 'i4', 'k': 'custom', 'n': 'Timing belt replacement and water pump', 'km': 90000, 'lastKm': 60000, 'lastD': d(-700)},
      ],
      'hist': [
        {'id': 'h1', 'd': d(-200), 'k': 'oil', 'n': 'Engine oil', 'km': 114000, 'cost': 45000, 'note': 'Workshop in Bahri, 5W-30 synthetic oil'},
      ],
    },
  ]);
  final now = pNow();
  s.setData('cuts_slots', [
    {'id': 's1', 'wd': now.weekday, 'from': 0, 'to': 1439},
    {'id': 's2', 'wd': (now.weekday % 7) + 1, 'from': 22 * 60, 'to': 2 * 60},
  ]);
  s.setData('cuts_cfg', {'notify': true, 'back': true, 'open': now.subtract(const Duration(hours: 2)).toIso8601String()});
  s.setData('cuts_log', [
    {'id': 'l1', 's': now.subtract(const Duration(days: 1, hours: 5)).toIso8601String(), 'e': now.subtract(const Duration(days: 1)).toIso8601String()},
  ]);
  s.setData('pantry_list', [
    {'id': 'p1', 'n': 'Powdered milk large tin from the market', 'c': 'food', 'q': 2, 'u': 'tins', 'e': d(-2)},
    {'id': 'p2', 'n': 'Paracetamol', 'c': 'medicine', 'q': 1, 'e': d(4)},
    {'id': 'p3', 'n': 'Hand cream', 'c': 'cosmetics', 'q': 1, 'e': d(200)},
  ]);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('الحسابات', () {
    // ديزل 10 kW بحمل كامل ≈ 2.95 ل/س (≈0.3 ل/ك.و.س)
    expect(fuelLph(ratedKw: 10, loadFrac: 1, diesel: true), closeTo(2.95, .01));
    expect(fuelLph(ratedKw: 10, loadFrac: .25, diesel: true) / 2.5, greaterThan(.35));
    expect(fuelLph(ratedKw: 0, loadFrac: 1, diesel: false), 0);

    final st = GasStats([
      {'d': '2026-01-01', 'p': 100},
      {'d': '2026-01-31', 'p': 200},
      {'d': '2026-03-02', 'p': 300},
    ], 30);
    expect(st.intervals, [30, 30]);
    expect(st.avgDays, 30);
    expect(st.runOut, DateTime(2026, 4, 1));
    expect(st.monthlyCost, closeTo(200 * 30.44 / 30, .01));

    final iv = cutIntervals([
      {'wd': 1, 'from': 22 * 60, 'to': 2 * 60},
    ], DateTime(2026, 10, 5), 1); // الاثنين
    expect(iv.single.$1, DateTime(2026, 10, 5, 22));
    expect(iv.single.$2, DateTime(2026, 10, 6, 2));

    final du = dueOf({'k': 'oil', 'km': 5000, 'mo': 6, 'lastKm': 10000, 'lastD': '2026-01-01'}, 14000, DateTime(2026, 10, 7));
    expect(du.kmLeft, 1000);
    expect(du.overdue, isTrue); // التاريخ فات
    expect(expiryStatus(DateTime(2026, 10, 10), DateTime(2026, 10, 7)), 1);
  });

  test('مسجّلة ومترجمة', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => ids.contains(t.id)).toList();
      expect(mine.length, ids.length);
      for (final t in mine) {
        expect(t.cat, ToolCat.home);
        if (l == Lang.en) {
          expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
        }
      }
    }
    appLang = Lang.sd;
  });

  for (final width in [415.0, 320.0]) {
    for (final withData in [false, true]) {
      for (final lang in Lang.values) {
        testWidgets('homeplus — ${lang.name} — ${withData ? 'data' : 'empty'} — ${width.toInt()}dp', (tester) async {
          SharedPreferences.setMockInitialValues({});
          final s = await AppState.load();
          s.lang = lang;
          if (withData) seed(s);
          tester.view.physicalSize = Size(width * 2.6, 2340);
          tester.view.devicePixelRatio = 2.6;
          addTearDown(tester.view.reset);
          final failures = <String>[];
          final orig = FlutterError.onError;
          String? cur;
          FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
          addTearDown(() => FlutterError.onError = orig);
          for (final tool in allTools.where((t) => ids.contains(t.id))) {
            cur = tool.id;
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
            // مرّر لآخر الصفحة حتى تُبنى كل البطاقات
            for (var i = 0; i < 12; i++) {
              await tester.drag(find.byType(ListView).first, const Offset(0, -600));
              await tester.pump(const Duration(milliseconds: 30));
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 2));
          }
          FlutterError.onError = orig;
          expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
        });
      }
    }
  }
}
