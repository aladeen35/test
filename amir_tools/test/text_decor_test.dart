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
import 'package:amir_tools/tools/media/text_decor.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await l.load();
  }

  await load('Tajawal', ['assets/fonts/Tajawal-Regular.ttf', 'assets/fonts/Tajawal-Medium.ttf', 'assets/fonts/Tajawal-Bold.ttf', 'assets/fonts/Tajawal-ExtraBold.ttf']);
  final f = File('${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-dl/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (f.existsSync()) await load('MaterialIcons', [f.path]);
}

void main() {
  group('Unicode math alphanumerics', () {
    test('bold / italic / bold italic', () {
      expect(mathBold.apply('Bold 9'), '𝐁𝐨𝐥𝐝 𝟗');
      expect(mathItalic.apply('Italic'), '𝐼𝑡𝑎𝑙𝑖𝑐');
      expect(mathItalic.apply('h'), 'ℎ'); // hole U+210E
      expect(mathBoldItalic.apply('Ab'), '𝑨𝒃');
    });
    test('script with holes', () {
      expect(mathScript.apply('Script'), '𝒮𝒸𝓇𝒾𝓅𝓉');
      expect(mathScript.apply('BEFHILMR'), 'ℬℰℱℋℐℒℳℛ');
      expect(mathScript.apply('ego'), 'ℯℊℴ');
      expect(mathScript.apply('A'), '𝒜');
      expect(mathBoldScript.apply('Script'), '𝓢𝓬𝓻𝓲𝓹𝓽');
    });
    test('fraktur with holes', () {
      expect(mathFraktur.apply('Fraktur'), '𝔉𝔯𝔞𝔨𝔱𝔲𝔯');
      expect(mathFraktur.apply('CHIRZ'), 'ℭℌℑℜℨ');
      expect(mathFraktur.apply('A'), '𝔄');
    });
    test('double-struck with holes', () {
      expect(mathDouble.apply('Double'), '𝔻𝕠𝕦𝕓𝕝𝕖');
      expect(mathDouble.apply('CHNPQRZ'), 'ℂℍℕℙℚℝℤ');
      expect(mathDouble.apply('0 9'), '𝟘 𝟡');
    });
    test('mono / sans bold / fullwidth', () {
      expect(mathMono.apply('Mono'), '𝙼𝚘𝚗𝚘');
      expect(mathSansBold.apply('Sans'), '𝗦𝗮𝗻𝘀');
      expect(fullwidthText('Full'), 'Ｆｕｌｌ');
    });
    test('enclosed / small caps / upside-down', () {
      expect(circled('Circle 10'), 'Ⓒⓘⓡⓒⓛⓔ ①⓪');
      expect(negCircled('ci'), '🅒🅘');
      expect(squared('SQ'), '🅂🅀');
      expect(smallCaps('Small'), 'ꜱᴍᴀʟʟ');
      expect(upsideDown('text'), 'ʇxǝʇ');
    });
    test('combining marks and untouched characters', () {
      expect(combining('ab', '̶'), 'a̶b̶');
      expect(mathBold.apply('سلام!'), 'سلام!');
      expect(mathScript.apply('a-b'), '𝒶-𝒷');
    });
  });

  group('Arabic decoration', () {
    test('kashida only between joining letters', () {
      expect(arabicStretch('محمد'), 'مـحـمـد');
      expect(arabicStretch('دار'), 'دار'); // د and ا never join forward
      expect(arabicStretch('ورد'), 'ورد');
      expect(arabicStretch('سارة'), 'سـارة');
      expect(arabicStretch('بيت', level: 3), 'بـــيـــت');
      expect(arabicStretch('سلام'), 'سـلام'); // keeps the لا ligature
      expect(arabicStretch('شيء'), 'شـيء'); // no kashida before hamza
      expect(arabicStretch('عمر علي'), 'عـمـر عـلـي');
    });
    test('marks and fillers', () {
      expect(arabicStretch('بت', kashidaMarks: const ['ّ'], level: 2), 'بـّـت');
      expect(arabicStretch('بت', between: '♡'), 'بـ♡ـت');
      expect(arabicStretch('بَت'), 'بَـت'); // existing harakat stay on their letter
    });
    test('mirrored frames for RTL text', () {
      const f = DecorFrame('x', '★彡', '彡★');
      expect(f.wrap('abc'), '★彡 abc 彡★');
      expect(f.wrap('نص', rtl: true), '★彡 نص 彡★');
      const g = DecorFrame('y', '꧁༺', '༻꧂');
      expect(g.wrap('نص', rtl: true), '꧂༺ نص ༻꧁');
      expect(decorDir('مرحبا Hi'), TextDirection.rtl);
      expect(decorDir('꧁ Hi ꧂'), TextDirection.ltr);
    });
    test('catalog sizes', () {
      expect(decorFrames.length, greaterThanOrEqualTo(25));
      expect(decorFrames.map((f) => f.id).toSet().length, decorFrames.length);
      expect(decorSeparators.length, greaterThanOrEqualTo(10));
    });
  });

  group('Text tool decorate tab renders without overflow', () {
    setUpAll(() async {
      tzdata.initializeTimeZones();
      await _loadFonts();
    });
    for (final lang in Lang.values) {
      testWidgets('text — ${lang.name}', timeout: const Timeout(Duration(minutes: 2)), (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final tool = allTools.firstWhere((x) => x.id == 'text');
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: s,
          child: MaterialApp(locale: Locale(lang == Lang.en ? 'en' : 'ar'), theme: buildTheme(Brightness.dark), home: Scaffold(body: Builder(builder: tool.builder))),
        ));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.auto_awesome_rounded).first);
        await tester.pump();
        // بطاقة «ركّب زخرفتك» قريبة من الأعلى: نسخ (نقاط يومية) ثم مفضّلة
        await tester.enterText(find.byType(TextField).first, 'Ameer');
        await tester.pump();
        final copy = find.byIcon(Icons.copy_rounded).first;
        await tester.ensureVisible(copy);
        await tester.pump();
        await tester.tap(copy);
        await tester.pump();
        final favsBefore = s.getData<List>('text_decor_favs');
        await tester.tap(find.byIcon(Icons.star_border_rounded).first);
        await tester.pump();
        final favsAfter = s.getData<List>('text_decor_favs');
        await tester.tap(find.byIcon(Icons.casino_rounded));
        await tester.pump();
        // الرجوع لتبويب الأدوات ثم للزخرفة
        final list = find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(find.byIcon(Icons.handyman_rounded), -300, scrollable: list);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.handyman_rounded));
        await tester.pump();
        final speakBtn = find.byIcon(Icons.volume_up_rounded).evaluate().length;
        await tester.tap(find.byIcon(Icons.auto_awesome_rounded).first);
        await tester.pump();
        // تمرير القائمة كاملة لبناء كل البطاقات بنصوص مختلفة
        for (final txt in ['', 'محمد أحمد عمر', 'Hello World 2026', 'Ameer مرحبا']) {
          await tester.enterText(find.byType(TextField).first, txt);
          await tester.pump();
          for (var i = 0; i < 25; i++) {
            await tester.drag(find.byType(ListView).first, const Offset(0, -900));
            await tester.pump();
          }
          for (var i = 0; i < 30; i++) {
            await tester.drag(find.byType(ListView).first, const Offset(0, 900));
            await tester.pump();
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
        expect(favsBefore, isNull);
        expect(favsAfter, hasLength(1));
        expect(speakBtn, 1);
      });
    }
  });
}
