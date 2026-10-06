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
import 'package:amir_tools/tools/deen/inheritance_engine.dart';
import 'package:amir_tools/tools/deen/fast_calendar.dart';
import 'package:amir_tools/tools/deen/duas_data.dart';

const _ids = ['inheritance', 'fasting', 'duas'];

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('المواريث', () {
    test('زوج + بنتان + أم ← عول إلى 13', () {
      final r = computeInheritance(const Heirs(husband: true, daughters: 2, mother: true));
      expect(r.unsupported, isNull);
      expect(r.awl, isTrue);
      expect(r.base, 12);
      expect(r.awlTo, 13);
      expect(r.shareOf('husband'), Frac(3, 13));
      expect(r.shareOf('daughters'), Frac(8, 13));
      expect(r.eachOf('daughters'), Frac(4, 13));
      expect(r.shareOf('mother'), Frac(2, 13));
    });

    test('زوجة + ابن + بنت', () {
      final r = computeInheritance(const Heirs(wives: 1, sons: 1, daughters: 1));
      expect(r.shareOf('wife'), Frac(1, 8));
      expect(r.shareOf('sons'), Frac(7, 12));
      expect(r.shareOf('daughters'), Frac(7, 24));
      expect(r.awl || r.radd, isFalse);
    });

    test('العُمَريّة: زوج + أم + أب', () {
      final r = computeInheritance(const Heirs(husband: true, mother: true, father: true));
      expect(r.shareOf('husband'), Frac(1, 2));
      expect(r.shareOf('mother'), Frac(1, 6));
      expect(r.shareOf('father'), Frac(1, 3));
    });

    test('العُمَريّة الثانية: زوجة + أم + أب', () {
      final r = computeInheritance(const Heirs(wives: 1, mother: true, father: true));
      expect(r.shareOf('wife'), Frac(1, 4));
      expect(r.shareOf('mother'), Frac(1, 4));
      expect(r.shareOf('father'), Frac(1, 2));
    });

    test('زوجة + أم + أخوان شقيقان', () {
      final r = computeInheritance(const Heirs(wives: 1, mother: true, fullBrothers: 2));
      expect(r.shareOf('wife'), Frac(1, 4));
      expect(r.shareOf('mother'), Frac(1, 6));
      expect(r.shareOf('fullBrothers'), Frac(7, 12));
      expect(r.eachOf('fullBrothers'), Frac(7, 24));
    });

    test('بنت + أخت شقيقة ← عصبة مع الغير', () {
      final r = computeInheritance(const Heirs(daughters: 1, fullSisters: 1));
      expect(r.shareOf('daughters'), Frac(1, 2));
      expect(r.shareOf('fullSisters'), Frac(1, 2));
      expect(r.row('fullSisters')!.term, 'تعصيب مع الغير');
    });

    test('الرد: أم + بنت', () {
      final r = computeInheritance(const Heirs(mother: true, daughters: 1));
      expect(r.radd, isTrue);
      expect(r.shareOf('daughters'), Frac(3, 4));
      expect(r.shareOf('mother'), Frac(1, 4));
    });

    test('الرد مع زوج: زوج + بنت', () {
      final r = computeInheritance(const Heirs(husband: true, daughters: 1));
      expect(r.shareOf('husband'), Frac(1, 4));
      expect(r.shareOf('daughters'), Frac(3, 4));
    });

    test('بنت + بنت ابن ← السدس تكملة الثلثين، والباقي للأخ', () {
      final r = computeInheritance(const Heirs(daughters: 1, sonsDaughters: 1, fullBrothers: 1));
      expect(r.shareOf('daughters'), Frac(1, 2));
      expect(r.shareOf('sonsDaughters'), Frac(1, 6));
      expect(r.shareOf('fullBrothers'), Frac(1, 3));
    });

    test('الحجب: الأب يحجب الإخوة والجد', () {
      final r = computeInheritance(const Heirs(father: true, grandfather: true, fullBrothers: 2, matSiblings: 1));
      expect(r.row('fullBrothers')!.blocked, isTrue);
      expect(r.row('grandfather')!.blocked, isTrue);
      expect(r.row('matSiblings')!.blocked, isTrue);
      expect(r.shareOf('father'), Frac.one);
    });

    test('الإخوة لأم الثلث والأم السدس', () {
      final r = computeInheritance(const Heirs(husband: true, mother: true, matSiblings: 2, patBrothers: 1));
      expect(r.shareOf('husband'), Frac(1, 2));
      expect(r.shareOf('mother'), Frac(1, 6));
      expect(r.shareOf('matSiblings'), Frac(1, 3));
      expect(r.shareOf('patBrothers'), Frac.zero);
    });

    test('الأب مع البنت: السدس والباقي', () {
      final r = computeInheritance(const Heirs(father: true, daughters: 1));
      expect(r.shareOf('daughters'), Frac(1, 2));
      expect(r.shareOf('father'), Frac(1, 2));
    });

    test('الحالات غير المدعومة', () {
      expect(computeInheritance(const Heirs(grandfather: true, fullBrothers: 1)).unsupported, Unsupported.grandfatherSiblings);
      expect(computeInheritance(const Heirs(husband: true, mother: true, grandfather: true, fullSisters: 1)).unsupported, Unsupported.akdariyya);
      expect(computeInheritance(const Heirs(husband: true, mother: true, matSiblings: 2, fullBrothers: 1)).unsupported, Unsupported.mushtaraka);
      expect(computeInheritance(const Heirs()).unsupported, Unsupported.noHeirs);
      // الجد مع الإخوة لكن مع ابن: الإخوة محجوبون، فلا إشكال
      expect(computeInheritance(const Heirs(grandfather: true, fullBrothers: 1, sons: 1)).unsupported, isNull);
    });

    test('الوصية بحد أقصى الثلث بعد الديون', () {
      final e = netEstate(1000, 100, 300, 500);
      expect(e.bequest, 200);
      expect(e.net, 400);
      expect(e.capped, isTrue);
    });

    test('مجموع الأنصبة = 1 في حالات متنوعة', () {
      const cases = [
        Heirs(wives: 2, sons: 2, daughters: 3, father: true, mother: true),
        Heirs(husband: true, fullSisters: 2, mother: true),
        Heirs(wives: 1, daughters: 2, sonsSons: 1, sonsDaughters: 2),
        Heirs(husband: true, patGrandmother: true, matGrandmother: true, patSisters: 1, fullSisters: 1),
        Heirs(daughters: 1, fullSisters: 1, patBrothers: 2),
      ];
      for (final h in cases) {
        final r = computeInheritance(h);
        final total = r.rows.fold<Frac>(Frac.zero, (a, x) => a + x.share) + r.unallocated;
        expect(total, Frac.one, reason: r.rows.map((x) => '${x.key}=${x.share}').join(', '));
      }
    });
  });

  group('الصيام', () {
    test('الأيام المحرمة لا تُقترح', () {
      // نمر على سنة هجرية كاملة
      final start = DateTime(2026, 1, 1);
      for (var i = 0; i < 400; i++) {
        final f = fastDay(DateTime(start.year, start.month, start.day + i), 0);
        final h = toHijri(f.date);
        if ((h.m == 10 && h.d == 1) || (h.m == 12 && h.d >= 10 && h.d <= 13)) {
          expect(f.forbidden, isNotNull);
          expect(f.suggested, isFalse);
        }
        if (h.m == 9) expect(f.suggested, isFalse);
        if (h.m == 12 && h.d == 9) expect(f.types, contains(FastType.arafah));
        if (h.m == 1 && h.d == 10) expect(f.types, contains(FastType.ashura));
      }
    });

    test('المناسبات القادمة', () {
      final occ = nextOccasions(DateTime(2026, 10, 6), 0);
      expect(occ.keys, containsAll([FastType.arafah, FastType.ashura, FastType.shawwal, FastType.bid]));
      expect(toHijri(occ[FastType.arafah]!).m, 12);
      expect(toHijri(occ[FastType.shawwal]!).d, 2);
    });
  });

  test('معرّفات الأدعية فريدة', () {
    final ids = duas.map((d) => d.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final lang in Lang.values) {
    for (final width in [360.0, 415.0]) {
      testWidgets('أدوات الدين تُفتح دون أخطاء — ${lang.name} @$width', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        // بيانات تجريبية لعرض كل الأقسام
        s.setData('inheritance_input', {
          'estate': '120000',
          'funeral': '2000',
          'debts': '5000',
          'wasiyya': '90000',
          'cur': 'SAR',
          'male': true,
          'c': {'wives': 2, 'sons': 1, 'daughters': 2, 'mother': 1, 'father': 1, 'fullBrothers': 3, 'matSiblings': 2, 'patGrandmother': 1},
        });
        s.setData('fasting_log', ['2026-10-01', '2026-10-05', '2026-09-28']);
        s.setData('fasting_qada', {'owed': 6, 'made': ['2026-09-10', '2026-09-11']});
        s.setData('fasting_remind', ['mon_thu', 'arafah']);
        s.setData('duas_favs', ['istikhara']);
        tester.view.physicalSize = Size(width * 2.6, 2340 * 12);
        tester.view.devicePixelRatio = 2.6;
        addTearDown(tester.view.reset);
        final failures = <String>[];
        final orig = FlutterError.onError;
        String? cur;
        FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
        addTearDown(() => FlutterError.onError = orig);
        final tools = allTools.where((t) => _ids.contains(t.id)).toList();
        expect(tools.length, _ids.length);
        for (final tool in tools) {
          cur = tool.id;
          if (lang == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(tool.name), isFalse);
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
          // التأكد من أن الشاشة بُنيت حتى آخرها
          if (tool.id == 'inheritance') expect(find.byType(ShareBar), findsOneWidget);
          if (tool.id == 'fasting') expect(find.byType(StatGrid), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        }
        // حالة غير مدعومة في المواريث
        s.setData('inheritance_input', {'male': false, 'c': {'husband': 1, 'mother': 1, 'grandfather': 1, 'fullSisters': 1}});
        cur = 'inheritance(akdariyya)';
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: s,
          child: MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: Builder(builder: toolById('inheritance')!.builder))),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining(lang == Lang.en ? 'Akdariyya' : 'الأكدرية'), findsWidgets);
        await tester.pumpWidget(const SizedBox());
        FlutterError.onError = orig;
        expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
      });
    }
  }
}
