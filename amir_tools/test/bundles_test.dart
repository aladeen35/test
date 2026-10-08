import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/screens/bundles.dart';
import 'package:amir_tools/screens/category_screen.dart';
import 'package:amir_tools/screens/home_screen.dart';
import 'package:amir_tools/screens/shell.dart';
import 'package:amir_tools/screens/tools_screen.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await l.load();
  }

  await load('Tajawal', ['assets/fonts/Tajawal-Regular.ttf', 'assets/fonts/Tajawal-Medium.ttf', 'assets/fonts/Tajawal-Bold.ttf', 'assets/fonts/Tajawal-ExtraBold.ttf']);
  await load('Lalezar', ['assets/fonts/Lalezar-Regular.ttf']);
  final f = File('${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-dl/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (f.existsSync()) await load('MaterialIcons', [f.path]);
}

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await _loadFonts();
  });

  test('كل تصنيف مربوط بحزمة صراحةً، ولا تصنيف في حزمتين', () {
    for (final c in ToolCat.values) {
      expect(catBundles.containsKey(c), isTrue, reason: 'التصنيف ${c.name} غير مربوط بحزمة');
    }
    final seen = <ToolCat>[for (final b in ToolBundle.values) ...b.declaredCats];
    expect(seen.toSet().length, seen.length);
  });

  test('كل أداة ظاهرة تقع في حزمة واحدة بالضبط', () {
    final visible = allTools.where((x) => !x.hidden).map((x) => x.id).toList();
    final inBundles = [for (final b in ToolBundle.values) ...b.tools.map((x) => x.id)];
    expect(inBundles..sort(), visible..sort());
    for (final b in ToolBundle.values) {
      expect(b.tools, isNotEmpty, reason: 'حزمة فارغة: ${b.name}');
    }
  });

  test('البحث يطبّع العربية ويطابق الكلمات المفتاحية', () {
    appLang = Lang.sd;
    expect(normalizeSearch('أَحْمَد إبراهيم مكتبة'), 'احمد ابراهيم مكتبه');
    final cur = toolById('currency')!;
    expect(toolMatches(cur, ''), isTrue);
    expect(toolMatches(cur, cur.name), isTrue);
    expect(toolMatches(cur, 'zzzz_no_such'), isFalse);
    expect(newTools.every((x) => newToolIds.contains(x.id)), isTrue);
  });

  for (final width in [320.0, 415.0]) {
    for (final lang in Lang.values) {
      testWidgets('الحزم والعِدّة بلا فيضان — ${lang.name} @${width.toInt()}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        // مفضلات وأخيرة وأدوات جديدة حتى تظهر كل الأقسام
        for (final x in allTools.where((x) => !x.hidden).take(8)) {
          s.useTool(x.id, x.name);
        }
        tester.view.physicalSize = Size(width * 3, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final bad = <String>{};
        final orig = FlutterError.onError;
        var cur = '';
        FlutterError.onError = (d) {
          final m = d.exceptionAsString();
          final loc = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(d.toString())?.group(0) ?? '?';
          bad.add('$cur: ${m.split('\n').first} @ $loc');
        };
        addTearDown(() => FlutterError.onError = orig);
        Widget wrap(Widget w) => ChangeNotifierProvider.value(
              value: s,
              child: MaterialApp(
                locale: Locale(lang == Lang.en ? 'en' : 'ar'),
                theme: buildTheme(Brightness.dark),
                builder: (c, child) => Directionality(textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl, child: child!),
                home: Scaffold(body: w),
              ),
            );
        Future<void> scrollAll() async {
          for (var i = 0; i < 30; i++) {
            final sc = find.byType(Scrollable);
            if (sc.evaluate().isEmpty) break;
            await tester.drag(sc.first, const Offset(0, -600), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 30));
          }
        }

        try {
          for (final view in ['grid', 'list']) {
            s.setData('ui_view', view);
            for (final (id, w) in <(String, Widget)>[
              ('home', const HomeScreen()),
              ('tools', const ToolsScreen()),
              for (final b in ToolBundle.values) ('bundle_${b.name}', CategoryScreen(b)),
            ]) {
              cur = '$id/$view';
              await tester.pumpWidget(wrap(w));
              await tester.pump(const Duration(milliseconds: 100));
              await scrollAll();
              await tester.pumpWidget(const SizedBox());
              await tester.pump(const Duration(seconds: 2));
            }
          }
          // اختيار حزمة عبر Shell.toolsFilter (اسم تصنيف) وطيّ قسم
          cur = 'tools/filter';
          s.setData('ui_view', 'grid');
          await tester.pumpWidget(wrap(const ToolsScreen()));
          await tester.pump();
          for (final c in ToolCat.values.where((c) => allTools.any((x) => !x.hidden && x.cat == c))) {
            Shell.toolsFilter.value = c.name;
            for (var i = 0; i < 30; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            expect(Shell.toolsFilter.value, isNull);
            expect(find.text(c.label), findsWidgets, reason: c.name);
          }
          Shell.toolsFilter.value = ToolBundle.money.name;
          await tester.pump(const Duration(milliseconds: 400));
          final head = find.descendant(of: find.byType(CatSection), matching: find.text(ToolCat.money.label)).first;
          await tester.ensureVisible(head);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(head);
          await tester.pump(const Duration(milliseconds: 300));
          expect(CatSection.collapsedCats(s), contains(ToolCat.money.name));
          // بحث مسطّح
          cur = 'tools/search';
          await tester.enterText(find.byType(TextField).first, toolById('currency')!.name);
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text(toolById('currency')!.name), findsWidgets);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        } finally {
          FlutterError.onError = orig;
        }
        expect(bad, isEmpty, reason: bad.join('\n'));
      });
    }
  }
}
