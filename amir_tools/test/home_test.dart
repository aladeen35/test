import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';

const _ids = {'shopping', 'bills', 'building', 'farming'};

void _seed(AppState s) {
  final now = DateTime.now();
  s.setData('shopping_lists', [
    {
      'id': 'l1',
      'name': 'السوق الكبير لآخر الشهر Monthly market run',
      'cur': 'SDG',
      'items': [
        {'id': 'a', 'n': 'لبن بودرة نيدو كبير جدًا Very long milk powder item name', 'q': 2, 'u': 'can', 'p': 123456789, 'done': false},
        {'id': 'b', 'n': 'سكر', 'q': 5, 'u': 'kg', 'p': 1500, 'done': true},
        {'id': 'c', 'n': 'Soap', 'q': 1, 'u': 'pc', 'p': 0, 'done': false},
      ],
    },
    {'id': 'l2', 'name': 'الخضار', 'cur': 'USD', 'items': []},
  ]);
  s.setData('bills_list', [
    {'id': 'b1', 'name': 'كهرباء البيت الكبير في أم درمان Electricity', 'cat': 'power', 'a': 98765432, 'cur': 'SDG', 'freq': 'm', 'day': 5, 'remind': 3, 'notify': true},
    {'id': 'b2', 'name': 'Rent', 'cat': 'rent', 'a': 300, 'cur': 'USD', 'freq': 'm', 'day': 28, 'remind': 5, 'notify': true},
    {'id': 'b3', 'name': 'رسوم المدرسة', 'cat': 'school', 'a': 1200000, 'cur': 'SDG', 'freq': 'y', 'month': now.month, 'day': 15, 'remind': 10, 'notify': false},
  ]);
  s.setData('bills_paid', [
    {'id': 'p1', 'bill': 'b2', 'name': 'Rent', 'cat': 'rent', 'period': '${now.year}-${now.month.toString().padLeft(2, '0')}', 'a': 300, 'cur': 'USD', 'd': '${now.year}-01-01'},
  ]);
  s.setData('building_in', {'pBrick': '120', 'pCement': '45000', 'pSand': '30000', 'pGravel': '50000', 'pSteel': '2500000'});
  s.setData('farming_in', {'price': '90000', 'seedPrice': '2000', 'ureaPrice': '60000', 'dapPrice': '80000', 'plough': '30000', 'labor': '50000', 'harvest': '40000', 'area': '1000'});
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('أدوات البيت مسجّلة ومترجمة', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => _ids.contains(t.id)).toList();
      expect(mine.length, _ids.length);
      for (final t in mine) {
        expect(t.cat, ToolCat.home);
        if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
      }
    }
    appLang = Lang.sd;
  });

  for (final lang in Lang.values) {
    for (final width in [360.0, 420.0]) {
      testWidgets('أدوات البيت تُفتح وتُمرَّر بلا أخطاء أو فيضان — ${lang.name} @$width', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        for (final seeded in [false, true]) {
          if (seeded) _seed(s);
          tester.view.physicalSize = Size(width * 3, 2340);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final failures = <String>[];
          final orig = FlutterError.onError;
          String? cur;
          FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
          for (final tool in allTools.where((t) => _ids.contains(t.id))) {
            cur = '${tool.id}${seeded ? ' (data)' : ''}';
            await tester.pumpWidget(ChangeNotifierProvider.value(
              value: s,
              child: MaterialApp(
                locale: Locale(lang == Lang.en ? 'en' : 'ar'),
                theme: buildTheme(Brightness.dark),
                builder: (c, child) => Directionality(textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl, child: child!),
                home: Scaffold(body: Builder(builder: tool.builder)),
              ),
            ));
            await tester.pump(const Duration(milliseconds: 50));
            for (var i = 0; i < 14; i++) {
              final lv = find.byType(Scrollable).first;
              await tester.drag(lv, const Offset(0, -500), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 50));
            }
            // افتح ورقة الإضافة/التعديل للتأكد من تخطيطها
            if (tool.id == 'bills' || (tool.id == 'shopping' && seeded)) {
              await tester.drag(find.byType(Scrollable).first, const Offset(0, 8000), warnIfMissed: false);
              await tester.pump(const Duration(seconds: 1));
              final target = tool.id == 'bills' ? find.byIcon(Icons.add_rounded).first : find.byType(ListTile).first;
              await tester.tap(target, warnIfMissed: false);
              await tester.pump(const Duration(seconds: 1));
              if (find.byType(BottomSheet).evaluate().isEmpty) failures.add('$cur: sheet did not open');
              await tester.drag(find.byType(BottomSheet), const Offset(0, -400), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 100));
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 5));
          }
          FlutterError.onError = orig;
          expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
        }
      });
    }
  }
}
