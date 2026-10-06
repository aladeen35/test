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
import 'package:amir_tools/screens/tool_tile.dart';
import 'package:amir_tools/screens/home_screen.dart';
import 'package:amir_tools/screens/tools_screen.dart';
import 'package:amir_tools/screens/prayer_screen.dart';
import 'package:amir_tools/screens/points_screen.dart';
import 'package:amir_tools/screens/settings_screen.dart';
import 'package:amir_tools/screens/onboarding.dart';

/// يحمّل خطوط التطبيق الحقيقية حتى يكون كشف تجاوز النصوص واقعيًا
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
  final mi = Directory('${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-dl/flutter'}/bin/cache/artifacts/material_fonts');
  final f = File('${mi.path}/MaterialIcons-Regular.otf');
  if (f.existsSync()) await load('MaterialIcons', [f.path]);
}

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await _loadFonts();
  });

  for (final lang in Lang.values) {
    testWidgets('لا تجاوز للنصوص — ${lang.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final s = await AppState.load();
      s.lang = lang;
      // هاتف صغير شائع: 360×780 نقطة
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final bad = <String>{};
      final orig = FlutterError.onError;
      String cur = '';
      FlutterError.onError = (d) {
        final m = d.exceptionAsString();
        if (m.contains('overflowed')) {
          final loc = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(d.toString())?.group(0) ?? '?';
          bad.add('$cur: ${m.split('\n').first} @ $loc');
        }
      };
      addTearDown(() => FlutterError.onError = orig);
      Widget wrap(Widget w) => ChangeNotifierProvider.value(
            value: s,
            child: MaterialApp(locale: Locale(lang == Lang.en ? 'en' : 'ar'), theme: buildTheme(Brightness.dark), home: Scaffold(body: w)),
          );
      // الشاشات الرئيسية
      for (final (id, w) in <(String, Widget)>[
        ('home', const HomeScreen()),
        ('tools_screen', const ToolsScreen()),
        ('prayer_screen', const PrayerScreen()),
        ('points_screen', const PointsScreen()),
        ('settings_screen', const SettingsScreen()),
        ('onboarding', const Onboarding()),
      ]) {
        cur = id;
        await tester.pumpWidget(wrap(w));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      }
      // بلاطات الأدوات
      cur = 'tiles';
      await tester.pumpWidget(wrap(SingleChildScrollView(child: ToolGrid(allTools))));
      await tester.pump();
      for (final tool in allTools) {
        cur = tool.id;
        await tester.pumpWidget(wrap(Builder(builder: tool.builder)));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      }
      FlutterError.onError = orig;
      // ignore: avoid_print
      print('[${lang.name}] ${bad.length} overflow(s):\n${bad.join('\n')}');
      expect(bad, isEmpty, reason: 'نصوص تتجاوز إطاراتها');
    });
  }
}
