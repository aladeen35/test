import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('معرّفات الأدوات فريدة وكلها مترجمة', () {
    for (final l in Lang.values) {
      appLang = l;
      final ids = allTools.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'تكرار في المعرّفات');
      for (final t in allTools) {
        expect(t.name.trim(), isNotEmpty);
        if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(t.name), isFalse, reason: 'اسم غير مترجم: ${t.id}');
      }
    }
    appLang = Lang.sd;
    // ignore: avoid_print
    print('عدد الأدوات: ${allTools.length}');
  });

  for (final lang in Lang.values) {
    testWidgets('كل الأدوات تُفتح دون أخطاء — ${lang.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final s = await AppState.load();
      s.lang = lang;
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final failures = <String>[];
      final orig = FlutterError.onError;
      String? cur;
      FlutterError.onError = (d) {
        final m = d.exceptionAsString();
        if (!m.contains('overflowed')) failures.add('$cur: ${m.split('\n').first}');
      };
      addTearDown(() => FlutterError.onError = orig);
      for (final tool in allTools) {
        cur = tool.id;
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: s,
          child: MaterialApp(
            locale: Locale(lang == Lang.en ? 'en' : 'ar'),
            theme: buildTheme(Brightness.dark),
            home: Scaffold(body: Builder(builder: tool.builder)),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      }
      FlutterError.onError = orig;
      expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
    });
  }
}
