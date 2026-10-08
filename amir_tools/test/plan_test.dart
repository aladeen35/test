import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/plan/basket_tool.dart';
import 'package:amir_tools/tools/plan/meal_tool.dart';
import 'package:amir_tools/tools/plan/plan_common.dart';
import 'package:amir_tools/tools/plan/study_tool.dart';

const _ids = {'savings_goals', 'sadaqa', 'basket_compare', 'meal_plan', 'trip_plan', 'study_plan'};

void _seed(AppState s) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  String d(int off) => dk(today.add(Duration(days: off)));
  s.setData('savings_goals_list', [
    {
      'id': 'g1',
      'name': 'عمرة الوالدة إن شاء الله في رمضان الجاي Umrah for mum next Ramadan',
      'emoji': '🕋',
      'target': 987654321,
      'start': 1000000,
      'cur': 'SDG',
      'deadline': d(400),
      'created': d(-90),
      'color': 2,
      'tx': [
        {'id': 't1', 'a': 250000000, 'd': d(-60), 'note': 'من مرتب الشهر Very long salary note for the deposit entry'},
        {'id': 't2', 'a': -5000000, 'd': d(-10), 'note': ''},
      ],
      'ms': [25],
    },
    {'id': 'g2', 'name': 'Laptop', 'emoji': '💻', 'target': 900, 'start': 0, 'cur': '\$', 'created': d(-5), 'color': 4, 'tx': [], 'ms': []},
  ]);
  s.setData('sadaqa_cfg', {'mode': 'pct', 'income': 123456789, 'pct': 2.5, 'cur': 'SDG'});
  s.setData('sadaqa_log', [
    {'id': 's1', 'a': 99999999, 'cat': 'family', 'to': 'خالتي في الأبيض وأولادها الصغار My aunt in El Obeid and kids', 'note': 'ملاحظة طويلة جدًا', 'd': d(0)},
    {'id': 's2', 'a': 5000, 'cat': 'mosque', 'to': '', 'note': '', 'd': dk(DateTime(now.year, now.month - 1, 3))},
  ]);
  s.setData('basket_compare', {
    'shops': ['دكان عم أحمد في الحلة الجديدة Uncle Ahmed corner shop', 'السوق المركزي', 'Hypermarket', 'Shop 4', 'Shop 5'],
    'cur': 'SDG',
    'items': [
      {'id': 'i1', 'n': 'لبن بودرة نيدو كبير جدًا Very long milk powder item', 'q': 2, 'u': 'علبة', 'p': [123456789, 120000, null, 130000, 99999]},
      {'id': 'i2', 'n': 'سكر', 'q': 5, 'u': 'كيلو', 'p': [1500, 1400, 1450, 1600, 1550]},
      {'id': 'i3', 'n': 'Oil', 'q': 1, 'u': 'liter', 'p': [null, null, null, null, null]},
    ],
  });
  final ws = weekStart(today);
  s.setData('meal_plan_weeks', {
    dk(ws): {'d0_b': 'ful', 'd0_l': 'asida_taqalia', 'd0_d': 'c_x', 'd1_l': 'molokhia', 'd6_d': 'salata_aswad'},
  });
  s.setData('meal_plan_custom', [
    {'id': 'c_x', 'name': 'مديدة الحلبة بتاعت حبوبتي الطويلة Grandma long helba porridge', 'ings': ['حلبة', 'دقيق', 'سكر'], 'cost': 123456789},
  ]);
  s.setData('meal_plan_cfg', {'budget': 50000, 'cur': 'SDG', 'costs': {'ful': 3000, 'molokhia': 9000}});
  s.setData('trip_plan_list', [
    {
      'id': 'tp1',
      'name': 'رحلة العمرة والزيارة للأهل في جدة والرياض Umrah and family visit',
      'cur': 'SAR',
      'start': d(10),
      'end': d(24),
      'stops': [
        {'id': 'st1', 'place': 'جدة — مطار الملك عبدالعزيز الدولي King Abdulaziz Intl', 'from': d(10), 'to': d(14), 'tr': 'plane', 'ref': 'ABC123XYZ-LONGREF', 'notes': 'ملاحظة'},
        {'id': 'st2', 'place': 'Riyadh', 'from': d(15), 'tr': 'bus', 'ref': '', 'notes': ''},
      ],
      'days': {d(10): 'الوصول والسكن ثم العمرة بالليل Arrival, check-in, Umrah at night with a long description'},
      'budget': {
        'transport': {'plan': 123456789, 'spent': 99999999},
        'food': {'plan': 1000, 'spent': 1500},
      },
      'docs': [
        {'id': 'd1', 'n': 'الجواز (صالح 6 أشهر على الأقل) Passport valid for at least six months', 'done': true},
        {'id': 'd2', 'n': 'Visa', 'done': false},
      ],
    },
  ]);
  s.setData('study_plan', {
    'subjects': [
      {'id': 'm1', 'n': 'الرياضيات المتخصصة والإحصاء التطبيقي Advanced mathematics & statistics', 'c': 1, 'diff': 3, 'exam': d(6)},
      {'id': 'm2', 'n': 'Chemistry', 'c': 5, 'diff': 2, 'exam': d(12)},
      {'id': 'm3', 'n': 'عربي', 'c': 3, 'diff': 1},
    ],
    'weekly': [
      for (var wd = 1; wd <= 7; wd++) {'id': 'w$wd', 'sub': 'm1', 'wd': wd, 'm': 17 * 60, 'dur': 60},
      {'id': 'w8', 'sub': 'm2', 'wd': today.weekday, 'm': 20 * 60 + 30, 'dur': 90},
    ],
    'sessions': [
      {'id': 'x1', 'sub': 'm1', 'd': d(0), 'm': 16 * 60, 'dur': 60, 'done': true, 'auto': true},
      {'id': 'x2', 'sub': 'm2', 'd': d(1), 'm': 16 * 60, 'dur': 60, 'done': false, 'auto': true},
      {'id': 'x3', 'sub': 'm1', 'd': d(-1), 'm': 16 * 60, 'dur': 45, 'done': false, 'auto': true},
    ],
    'doneW': ['w1@${d(-3)}'],
  });
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('أدوات التخطيط مسجّلة ومترجمة', () {
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

  test('مقارنة السلة: الأرخص والتقسيمة والأسعار الناقصة', () {
    final items = [
      {'q': 2, 'p': [10, 12, 9]},
      {'q': 1, 'p': [5, 4, null]},
      {'q': 3, 'p': [1, 2, 1.5]},
    ];
    final r = BasketResult.compute(items, 3);
    expect(r.totals, [28, 34, 22.5]);
    expect(r.missing, [0, 0, 1]);
    expect(r.bestShop, 0); // المتجر 3 ناقص صنفًا
    expect(r.cheapestPerItem, [2, 1, 0]);
    expect(r.splitTotal, 18 + 4 + 3);
    expect(r.savings, 3);
    final empty = BasketResult.compute([
      {'q': 1, 'p': []}
    ], 2);
    expect(empty.bestShop, isNull);
    expect(empty.pricedItems, 0);
  });

  test('خطة المراجعة: توزيع حسب الصعوبة وقبل الامتحان', () {
    final from = DateTime(2026, 10, 1);
    final subs = [
      {'id': 'a', 'diff': 3, 'exam': '2026-10-08'},
      {'id': 'b', 'diff': 1, 'exam': '2026-10-15'},
      {'id': 'c', 'diff': 2},
    ];
    final out = generateRevision(subs, from, perDay: 2, dur: 60, startMin: 600, gap: 0);
    // من 1 حتى 14 أكتوبر = 14 يومًا × 2
    expect(out.length, 28);
    expect(out.any((e) => e['sub'] == 'c'), isFalse);
    // لا جلسات للمادة a في يوم امتحانها أو بعده
    expect(out.where((e) => e['sub'] == 'a' && (e['d'] as String).compareTo('2026-10-08') >= 0), isEmpty);
    // اليوم السابق للامتحان أول جلسة لمادته
    expect(out.firstWhere((e) => e['d'] == '2026-10-07')['sub'], 'a');
    expect(out.firstWhere((e) => e['d'] == '2026-10-14')['sub'], 'b');
    // المادة الصعبة تأخذ جلسات أكثر قبل امتحانها
    final before = out.where((e) => (e['d'] as String).compareTo('2026-10-08') < 0);
    expect(before.where((e) => e['sub'] == 'a').length, greaterThanOrEqualTo(before.where((e) => e['sub'] == 'b').length));
    expect(out[1]['m'], 660);
    expect(generateRevision([{'id': 'x', 'diff': 2}], from), isEmpty);
  });

  test('بداية الأسبوع السبت', () {
    expect(weekStart(DateTime(2026, 10, 8)).weekday, DateTime.saturday);
    expect(weekStart(DateTime(2026, 10, 10)), DateTime(2026, 10, 10));
  });

  for (final lang in Lang.values) {
    for (final width in [360.0, 420.0]) {
      testWidgets('أدوات التخطيط تُفتح وتُمرَّر بلا أخطاء أو فيضان — ${lang.name} @$width', (tester) async {
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
          try {
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
              for (var i = 0; i < 16; i++) {
                final lv = find.byType(Scrollable).first;
                await tester.drag(lv, const Offset(0, -500), warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 50));
              }
              // افتح ورقة الإضافة/التعديل للتأكد من تخطيطها
              if (seeded) {
                tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
                await tester.pump(const Duration(seconds: 1));
                final target = switch (tool.id) {
                  'sadaqa' => find.byIcon(Icons.volunteer_activism_rounded).first,
                  'meal_plan' => find.text('＋').first,
                  'study_plan' => find.byIcon(Icons.add_rounded).first,
                  _ => find.byType(MiniAction).first,
                };
                await tester.ensureVisible(target);
                await tester.pump(const Duration(seconds: 1));
                await tester.tap(target);
                await tester.pump(const Duration(seconds: 1));
                if (find.byType(BottomSheet).evaluate().isEmpty) failures.add('$cur: sheet did not open');
                await tester.drag(find.byType(BottomSheet), const Offset(0, -400), warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 100));
              }
              await tester.pumpWidget(const SizedBox());
              await tester.pump(const Duration(seconds: 5));
            }
          } catch (e) {
            failures.add('$cur: exception $e');
          } finally {
            FlutterError.onError = orig;
          }
          expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
        }
      });
    }
  }
}
