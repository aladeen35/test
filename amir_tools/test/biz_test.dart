import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/core/widgets.dart';
import 'package:amir_tools/services/calendars.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/biz/shop_tool.dart';
import 'package:amir_tools/tools/biz/udhiya_tool.dart';
import 'package:amir_tools/tools/life/life_common.dart';

const _ids = ['wedding_budget', 'shop_ledger', 'month_budget', 'udhiya'];

void _seed(AppState s, {bool aqiqa = false}) {
  final today = todayPlace();
  final d = dk(today);
  final m = mk(today.year, today.month);
  s.setData('wedding_budget_data', {
    'cur': 'ج.س',
    'couple': 'محمد عبد الرحمن وفاطمة الزهراء',
    'date': dk(today.add(const Duration(days: 45))),
    'cats': [
      {
        'id': 'shayla',
        'key': 'shayla',
        'planned': 2500000,
        'pays': [
          {'id': 'p1', 'a': 1500000, 'by': 'أبو العريس الحاج عبد الرحمن', 'note': 'دفعة أولى للشيلة والعطور والتياب', 'd': d},
          {'id': 'p2', 'a': 1200000, 'by': 'العريس', 'note': '', 'd': d},
        ],
      },
      {'id': 'mahr', 'key': 'mahr', 'planned': 1000000, 'pays': []},
      {
        'id': 'x1',
        'key': 'custom',
        'name': 'الكوافير والتصوير والفيديو والزفة الكبيرة',
        'planned': 999999999,
        'pays': [
          {'id': 'p3', 'a': 123456789, 'by': 'الخال', 'note': 'نقطة', 'd': d},
        ],
      },
    ],
  });
  s.setData('shop_ledger_data', {
    'cur': 'SDG',
    'products': [
      {'id': 'a', 'name': 'سكر كنانة كيلو — كرتونة كبيرة جداً', 'cost': 2800, 'price': 3200, 'qty': 2, 'min': 5},
      {'id': 'b', 'name': 'Sunflower cooking oil 3 litre jerrycan premium', 'cost': 18500, 'price': 21000, 'qty': 40, 'min': 3},
      {'id': 'c', 'name': 'شاي', 'cost': 1500, 'price': 1400, 'qty': 0, 'min': 3},
    ],
    'sales': [
      {'id': 's1', 'pid': 'a', 'name': 'سكر كنانة كيلو — كرتونة كبيرة جداً', 'q': 12, 'price': 3200, 'cost': 2800, 'd': d, 't': 1},
      {'id': 's2', 'pid': 'b', 'name': 'Sunflower cooking oil 3 litre jerrycan premium', 'q': 300, 'price': 21000, 'cost': 18500, 'd': d, 't': 2},
    ],
  });
  s.setData('month_budget_data', {
    'cur': 'ج.س',
    'months': {
      m: {
        'income': 850000,
        'env': [
          {'id': 'food', 'key': 'food', 'v': 30, 'pct': true},
          {'id': 'rent', 'key': 'rent', 'v': 200000, 'pct': false},
          {'id': 'saving', 'key': 'saving', 'v': 5, 'pct': true},
          {'id': 'z', 'key': 'custom', 'name': 'علاج الوالدة ومتابعة الدكتور في المستشفى', 'v': 0, 'pct': false},
        ],
        'spend': [
          {'id': 'x1', 'env': 'food', 'a': 240000, 'note': 'سوق الخضار والعدس والزيت والسكر لكل الشهر', 'd': d},
          {'id': 'x2', 'env': 'rent', 'a': 250000, 'note': '', 'd': d},
          {'id': 'x3', 'env': 'z', 'a': 30000, 'note': '', 'd': d},
        ],
      },
      '2025-01': {'income': 500000, 'env': [], 'spend': []},
    },
  });
  s.setData('udhiya_input', {
    'mode': aqiqa ? 'aqiqa' : 'udhiya',
    'animal': 'cow',
    'price': '4500000',
    'partners': '9',
    'meat': '120',
    'aqPrice': '350000',
    'gender': 'boy',
    'babies': 2,
    'birth': d,
    'cur': 'ج.س',
  });
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('حسابات الدكان', () {
    test('الهامش والزيادة', () {
      expect(marginPct(80, 100), closeTo(20, 1e-9));
      expect(markupPct(80, 100), closeTo(25, 1e-9));
      expect(priceForMargin(80, 20), closeTo(100, 1e-9));
      expect(priceForMargin(80, 100).isNaN, isTrue);
    });
  });

  group('عيد الأضحى', () {
    test('العيد القادم يوافق 10 ذو الحجة', () {
      final r = nextAdha(DateTime(2026, 10, 7), 0);
      final h = toHijri(r.eid);
      expect(h.m, 12);
      expect(h.d, 10);
      expect(r.eid.isAfter(DateTime(2026, 10, 7)), isTrue);
      // عيد 1447 هـ (مايو 2026) فات، فالقادم في 1448 هـ
      expect(r.hYear, 1448);
    });
    test('في أيام التشريق يبقى نفس العيد', () {
      final eid = fromHijri(1447, 12, 10);
      final r = nextAdha(eid.add(const Duration(days: 2)), 0);
      expect(r.hYear, 1447);
      final after = nextAdha(eid.add(const Duration(days: 5)), 0);
      expect(after.hYear, 1448);
    });
  });

  test('الأسماء مترجمة', () {
    for (final l in Lang.values) {
      appLang = l;
      final tools = allTools.where((t) => _ids.contains(t.id)).toList();
      expect(tools.length, _ids.length);
      for (final t in tools) {
        if (l == Lang.en) {
          expect(RegExp(r'[؀-ۿ]').hasMatch(t.name), isFalse, reason: t.id);
          expect(RegExp(r'[؀-ۿ]').hasMatch(t.sub), isFalse, reason: t.id);
        }
      }
    }
    appLang = Lang.sd;
  });

  for (final lang in Lang.values) {
    for (final width in [320.0, 360.0, 415.0]) {
      for (final seeded in [false, true]) {
        testWidgets('أدوات البيزنس — ${lang.name} @$width ${seeded ? 'بيانات' : 'فاضي'}', (tester) async {
          SharedPreferences.setMockInitialValues({});
          final s = await AppState.load();
          s.lang = lang;
          if (seeded) _seed(s);
          tester.view.physicalSize = Size(width * 2.6, 2340 * 14);
          tester.view.devicePixelRatio = 2.6;
          addTearDown(tester.view.reset);
          final failures = <String>[];
          final orig = FlutterError.onError;
          String? cur;
          FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
          addTearDown(() => FlutterError.onError = orig);

          Future<void> pump(ToolDef tool, String label) async {
            cur = label;
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
            await tester.pump(const Duration(milliseconds: 100));
            expect(find.byType(ShareBar), findsWidgets, reason: label);
            // افتح كل البنود القابلة للتوسيع
            final tiles = find.byType(ExpansionTile);
            for (var i = 0; i < tiles.evaluate().length; i++) {
              await tester.tap(tiles.at(i), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 300));
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 3));
          }

          for (final tool in allTools.where((t) => _ids.contains(t.id))) {
            await pump(tool, tool.id);
          }
          if (seeded) {
            _seed(s, aqiqa: true);
            await pump(toolById('udhiya')!, 'udhiya(aqiqa)');
            s.setData('udhiya_input', {'animal': 'sheep', 'price': '300000'});
            await pump(toolById('udhiya')!, 'udhiya(sheep)');
          }
          FlutterError.onError = orig;
          expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
        });
      }
    }
  }

  for (final lang in [Lang.en, Lang.sd]) {
    testWidgets('النوافذ تفتح دون تجاوز — ${lang.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final s = await AppState.load();
      s.lang = lang;
      _seed(s);
      tester.view.physicalSize = const Size(320 * 2.6, 2340 * 14);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final failures = <String>[];
      final orig = FlutterError.onError;
      String? cur;
      FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
      addTearDown(() => FlutterError.onError = orig);
      Future<void> open(String id, Finder f, String label, {Finder? pre}) async {
        cur = label;
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: s,
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: Directionality(
              textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl,
              child: Scaffold(body: Builder(builder: toolById(id)!.builder)),
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        if (pre != null) {
          await tester.tap(pre.first, warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        expect(f, findsWidgets, reason: label);
        await tester.tap(f.first, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet).evaluate().isNotEmpty || find.byType(AlertDialog).evaluate().isNotEmpty, isTrue, reason: label);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      }

      final en = lang == Lang.en;
      await open('wedding_budget', find.byTooltip(en ? 'Add item' : 'بند جديد'), 'wedding add');
      await open('wedding_budget', find.byTooltip(en ? 'Edit' : 'عدّل'), 'wedding edit');
      await open('wedding_budget', find.text(en ? 'Add payment' : 'سجّل دفعة'), 'wedding pay', pre: find.byType(ExpansionTile));
      await open('shop_ledger', find.byTooltip(en ? 'New product' : 'صنف جديد'), 'shop add');
      await open('shop_ledger', find.byTooltip(en ? 'Edit' : 'عدّل'), 'shop edit');
      await open('shop_ledger', find.byIcon(Icons.point_of_sale_rounded), 'shop sell');
      await open('shop_ledger', find.byIcon(Icons.add_box_rounded), 'shop restock');
      await open('month_budget', find.byTooltip(en ? 'Edit' : 'عدّل'), 'env edit');
      await open('month_budget', find.byIcon(Icons.add_rounded), 'env add');
      await open('month_budget', find.text(en ? 'Set income' : 'أكتب الدخل').evaluate().isEmpty ? find.byIcon(Icons.account_balance_wallet_rounded) : find.text(en ? 'Set income' : 'أكتب الدخل'), 'income');
      FlutterError.onError = orig;
      expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
    });
  }
}
