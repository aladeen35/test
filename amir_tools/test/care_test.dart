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
import 'package:amir_tools/tools/care/care_common.dart';
import 'package:amir_tools/tools/care/elder_care_tool.dart';
import 'package:amir_tools/tools/care/emergency_data.dart';
import 'package:amir_tools/tools/care/family_health_tool.dart';
import 'package:amir_tools/tools/care/first_aid_data.dart';
import 'package:amir_tools/tools/care/first_aid_tool.dart';
import 'package:amir_tools/tools/care/vaccines_tool.dart';

const careIds = {'vaccines', 'family_health', 'elder_care', 'first_aid', 'emergency_numbers'};

void seed(AppState s) {
  final today = cToday();
  s.setData('vaccines_members', [
    {'id': 'a', 'name': 'Mohammed Abdelrahman Osman Elhassan'},
    {'id': 'b', 'name': 'حاجة فاطمة'},
  ]);
  s.setData('vaccines_records', [
    {'id': 'r1', 'm': 'a', 'name': 'Tetanus–diphtheria booster (Td/Tdap) long name test', 'kind': 'vac', 'done': '2016-01-05', 'every': 120, 'hist': ['2016-01-05']},
    {'id': 'r2', 'm': 'b', 'name': 'HbA1c', 'kind': 'chk', 'next': cKey(today.add(const Duration(days: 12))), 'every': 6, 'hist': [cKey(today)]},
    {'id': 'r3', 'm': 'b', 'name': 'Dental', 'kind': 'chk', 'every': 0},
  ]);
  s.setData('family_health_list', [
    {
      'id': 'f1', 'name': 'Mohammed Abdelrahman Osman Elhassan Ahmed', 'rel': 'father', 'birth': '1950-03-01', 'blood': 'AB−',
      'allergies': 'Penicillin, sulfa drugs, peanuts and shellfish', 'chronic': 'Type 2 diabetes, hypertension',
      'meds': [{'n': 'Metformin', 'd': '500 mg twice daily'}], 'doctor': 'Dr. Ahmed', 'doctorPhone': '+249912345678',
      'emName': 'Omar', 'emPhone': '+966500000000', 'insurance': 'INS-123456789', 'notes': 'Uses a walking stick',
    },
  ]);
  s.setData('elder_care_list', [
    {
      'id': 'e1', 'name': 'Grandmother Fatima Mohammed Ali', 'age': '82', 'notes': '',
      'meds': [
        {'id': 'm1', 'n': 'Amlodipine with a very long medicine name', 'd': '5 mg after breakfast', 'times': [480, 1260], 'notify': true},
      ],
      'appts': [
        {'id': 'a1', 'title': 'Diabetes follow-up at the big hospital', 'doctor': 'Dr. Salma', 'place': 'Omdurman Teaching Hospital', 'at': DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch, 'notify': true},
        {'id': 'a2', 'title': 'Eye check', 'doctor': '', 'place': '', 'at': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch, 'notify': false},
      ],
      'log': [
        {'d': cKey(today), 'mood': 4, 'bp': '130/85', 'sugar': '140', 'note': 'Ate well and walked in the yard'},
      ],
      'cg': [
        {'id': 'c1', 'name': 'Omar (son)', 'phone': '+249900000000', 'role': 'Son'},
      ],
      'taken': {cKey(today): ['m1_480']},
    },
  ]);
  s.setData('emergency_numbers_custom', [
    {'id': 'x', 'name': 'Nearest hospital emergency department with long name', 'phone': '+249 183 000 000'},
  ]);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('helpers', () {
    test('addMonths clamps month ends', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(addMonths(DateTime(2016, 1, 5), 120), DateTime(2026, 1, 5));
      expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
    });
    test('vaccine next due', () {
      expect(vaccineNextDue({'done': '2026-01-10', 'every': 6}), DateTime(2026, 7, 10));
      expect(vaccineNextDue({'done': '2026-01-10', 'every': 6, 'next': '2026-03-01'}), DateTime(2026, 3, 1));
      expect(vaccineNextDue({'every': 6}), isNull);
    });
    test('age', () {
      expect(ageYears(DateTime(1950, 3, 1), DateTime(2026, 2, 28)), 75);
      expect(ageYears(DateTime(1950, 3, 1), DateTime(2026, 3, 1)), 76);
    });
    test('emergency table', () {
      expect(emergencyFor('SD')!.numbers.first.number, '999');
      expect(emergencyFor('sa')!.code, 'SA');
      expect(emergencyFor('IT')!.code, 'EU');
      expect(emergencyFor('LY'), isNull);
      final codes = emergencyCountries.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
    });
    test('first aid content', () {
      for (final l in Lang.values) {
        appLang = l;
        for (final f in firstAidTopics) {
          expect(f.steps, isNotEmpty);
          expect(f.callWhen, isNotEmpty);
          expect(firstAidText(f), contains(f.name));
        }
        expect(firstAidTopics.where((f) => f.matches(l == Lang.en ? 'scorpion' : 'عقرب')), isNotEmpty);
      }
      appLang = Lang.sd;
      final ids = firstAidTopics.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
    });
    test('share texts', () {
      final m = {'name': 'X', 'blood': 'O+', 'allergies': 'Penicillin', 'meds': [{'n': 'A', 'd': '1'}]};
      expect(emergencyCardText(m), contains('O+'));
      expect(elderSummary({'name': 'Y', 'meds': [], 'appts': [], 'log': []}, cToday()), contains('Y'));
    });
  });

  test('care tools registered and translated', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => careIds.contains(t.id)).toList();
      expect(mine.length, careIds.length);
      for (final t in mine) {
        expect(t.cat, ToolCat.health);
        if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
      }
    }
    appLang = Lang.sd;
  });

  for (final seeded in [false, true]) {
    for (final lang in Lang.values) {
      testWidgets('care tools open — ${lang.name}${seeded ? ' (data)' : ''}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        if (seeded) seed(s);
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.6;
        addTearDown(tester.view.reset);
        final failures = <String>[];
        final orig = FlutterError.onError;
        String? cur;
        FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
        addTearDown(() => FlutterError.onError = orig);
        for (final tool in allTools.where((t) => careIds.contains(t.id))) {
          cur = tool.id;
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
          // scroll through the whole list so every row is laid out
          for (var i = 0; i < 12; i++) {
            final lists = find.byType(Scrollable);
            if (lists.evaluate().isEmpty) break;
            await tester.drag(lists.first, const Offset(0, -500), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 30));
          }
          if (tool.id == 'first_aid') {
            // open every topic in turn (detail view, normal & large text)
            for (final big in [false, true]) {
              s.setData('first_aid_big', big);
              for (final f in firstAidTopics) {
                cur = 'first_aid/${f.id}${big ? '/big' : ''}';
                await tester.pumpWidget(ChangeNotifierProvider.value(
                  value: s,
                  child: MaterialApp(
                    theme: buildTheme(Brightness.dark),
                    builder: (c, child) => Directionality(textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl, child: child!),
                    home: Scaffold(body: _FaHarness(f.id)),
                  ),
                ));
                await tester.pump(const Duration(milliseconds: 30));
                for (var i = 0; i < 8; i++) {
                  final lists = find.byType(Scrollable);
                  if (lists.evaluate().isEmpty) break;
                  await tester.drag(lists.first, const Offset(0, -600), warnIfMissed: false);
                  await tester.pump(const Duration(milliseconds: 20));
                }
              }
            }
          }
          // open the add/edit sheet of each data tool
          final addIcon = {'vaccines': Icons.add_circle_rounded, 'family_health': Icons.person_add_alt_1_rounded, 'elder_care': Icons.add_circle_rounded}[tool.id];
          if (seeded && addIcon != null) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(ChangeNotifierProvider.value(
              value: s,
              child: MaterialApp(theme: buildTheme(Brightness.dark), home: Scaffold(body: Builder(builder: tool.builder))),
            ));
            await tester.pump();
            cur = '${tool.id}/editor';
            await tester.ensureVisible(find.byIcon(addIcon).first);
            await tester.pump();
            await tester.tap(find.byIcon(addIcon).first);
            await tester.pumpAndSettle();
            expect(find.byType(BottomSheet), findsOneWidget, reason: tool.id);
            for (var i = 0; i < 4; i++) {
              await tester.drag(find.byType(Scrollable).last, const Offset(0, -400), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 20));
            }
          }
          if (tool.id == 'family_health' && seeded) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(ChangeNotifierProvider.value(
              value: s,
              child: MaterialApp(theme: buildTheme(Brightness.dark), home: Scaffold(body: Builder(builder: tool.builder))),
            ));
            await tester.pump();
            cur = 'family_health/card';
            await tester.ensureVisible(find.byIcon(Icons.badge_rounded).first);
            await tester.pump();
            await tester.tap(find.byIcon(Icons.badge_rounded).first);
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsOneWidget);
            for (var i = 0; i < 6; i++) {
              await tester.drag(find.byType(Scrollable).last, const Offset(0, -500), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 20));
            }
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        }
        // unknown country
        s.setPlace(const City.place('ly', 'Tripoli', '', 32.9, 13.2, country: 'LY', tz: 'Africa/Tripoli'));
        cur = 'emergency_numbers/LY';
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: s,
          child: MaterialApp(theme: buildTheme(Brightness.dark), home: Scaffold(body: Builder(builder: toolById('emergency_numbers')!.builder))),
        ));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
        FlutterError.onError = orig;
        expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
      });
    }
  }
}

/// يفتح أداة الإسعافات على موضوع معيّن
class _FaHarness extends StatefulWidget {
  final String id;
  const _FaHarness(this.id);
  @override
  State<_FaHarness> createState() => _FaHarnessState();
}

class _FaHarnessState extends State<_FaHarness> {
  @override
  Widget build(BuildContext context) => FirstAidTool(key: ValueKey(widget.id), initialTopic: widget.id);
}
