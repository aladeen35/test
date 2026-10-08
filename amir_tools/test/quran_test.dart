import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/quran/quran_common.dart';
import 'package:amir_tools/tools/quran/quran_store.dart';
import 'package:amir_tools/tools/quran/hadith_tool.dart';
import 'package:amir_tools/tools/quran/share_cards_tool.dart';
import 'package:amir_tools/tools/quran/hajj_data.dart';

const _ids = {'quran_search', 'hadith', 'share_cards', 'hajj_umrah'};

/// عيّنة بصيغة quran-api الحقيقية (ara-quransimple.min.json)
const _quranSample = '{"quran":['
    '{"chapter":1,"verse":1,"text":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"},'
    '{"chapter":1,"verse":2,"text":"الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"},'
    '{"chapter":2,"verse":1,"text":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الم"},'
    '{"chapter":2,"verse":2,"text":"ذَٰلِكَ الْكِتَابُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِلْمُتَّقِينَ"},'
    '{"chapter":2,"verse":153,"text":"يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ"},'
    '{"chapter":9,"verse":1,"text":"بَرَاءَةٌ مِنَ اللَّهِ وَرَسُولِهِ"}'
    ']}';

/// عيّنة بصيغة hadith-api الحقيقية
const _hadithAr = '{"metadata":{"name":"Forty Hadith of an-Nawawi","sections":{"0":"","1":"Forty Hadith of an-Nawawi"},'
    '"section_details":{"1":{"hadithnumber_first":1,"hadithnumber_last":42}}},'
    '"hadiths":[{"hadithnumber":1,"arabicnumber":1,"text":"إنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى","grades":[],"reference":{"book":1,"hadith":1}},'
    '{"hadithnumber":2,"arabicnumber":2,"text":"","grades":[],"reference":{"book":1,"hadith":2}},'
    '{"hadithnumber":3,"arabicnumber":3,"text":"بُنِيَ الْإِسْلَامُ عَلَى خَمْسٍ","grades":[{"name":"Al-Albani","grade":"Sahih"}],"reference":{"book":1,"hadith":3}}]}';
const _hadithEn = '{"metadata":{"name":"Forty Hadith of an-Nawawi","sections":{"0":"","1":"Forty Hadith of an-Nawawi"}},'
    '"hadiths":[{"hadithnumber":1,"arabicnumber":1,"text":"Actions are according to intentions, and everyone will get what was intended.","grades":[],"reference":{"book":1,"hadith":1}},'
    '{"hadithnumber":2,"arabicnumber":2,"text":"Also on the authority of Umar who said: While we were one day sitting with the Messenger of Allah a very long English text follows here to test wrapping inside the card widget","grades":[{"name":"Al-Albani","grade":"Sahih"}],"reference":{"book":1,"hadith":2}},'
    '{"hadithnumber":3,"arabicnumber":3,"text":"Islam has been built on five.","grades":[{"name":"Al-Albani","grade":"Sahih"}],"reference":{"book":1,"hadith":3}}]}';

/// نص مصحف وهمي كامل البنية (114 سورة) للاختبار — ليس نصًا قرآنيًا
List<Ayah> _fakeQuran() => [
      for (var s = 1; s <= 114; s++)
        for (var a = 1; a <= (s == 2 ? 30 : 5); a++)
          Ayah(s, a, s == 2 && a == 3 ? 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ نَصٌّ طَوِيلٌ لِلِاخْتِبَارِ فَقَطْ يَتَكَرَّرُ كَثِيرًا ' * 4 : 'نَصُّ اخْتِبَارٍ رَقْمُ $a فِي السُّورَةِ $s'),
    ];

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('التطبيع والبحث', () {
    test('حذف التشكيل وتوحيد الحروف', () {
      expect(normalizeArabic('الرَّحْمَٰنِ'), 'الرحمن');
      expect(normalizeArabic('إِنَّ آمَنُوا أُولَٰئِكَ ٱلصّـــلاة'), 'ان امنوا اولئك الصلاه');
      expect(normalizeArabic('مُوسَىٰ'), 'موسي');
      expect(normalizeArabic('لَا رَيْبَ ۛ فِيهِ'), 'لا ريب فيه');
    });

    test('مواضع التظليل تعود للنص الأصلي', () {
      const s = 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ';
      final r = matchRanges(s, 'الصابرين');
      expect(r.length, 1);
      expect(s.substring(r.first.$1, r.first.$2), 'الصَّابِرِينَ');
      expect(matchRanges(s, 'الله').length, 1);
      expect(matchRanges(s, 'xyz'), isEmpty);
    });
  });

  group('قراءة الملفات', () {
    test('ملف quran-api مع حذف البسملة الملصقة', () {
      final l = parseQuranEdition(_quranSample, stripBasmala: true);
      expect(l.length, 6);
      expect(l.first.text, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'); // الفاتحة: البسملة آية
      expect(l[2].surah, 2);
      expect(l[2].text, 'الم');
      expect(l.last.text, startsWith('بَرَاءَةٌ'));
      final raw = parseQuranEdition(_quranSample);
      expect(raw[2].text, contains('بِسْمِ'));
    });

    test('صيغ بديلة: خريطة بالسور', () {
      final m = parseQuranEdition(jsonEncode({
        '1': {'1': 'a', '2': 'b'},
        '2': ['c', 'd', 'e'],
      }));
      expect(m.length, 5);
      expect(m[3].surah, 2);
      expect(m[3].ayah, 2);
      expect(m[3].text, 'd');
    });

    test('ملف hadith-api والدمج', () {
      final b = parseHadithEdition(_hadithAr);
      expect(b.name, 'Forty Hadith of an-Nawawi');
      expect(b.hadiths.length, 3);
      expect(b.sections[1], 'Forty Hadith of an-Nawawi');
      expect(b.hadiths[2].grades.single.name, 'Al-Albani');
      final m = mergeHadith([_hadithAr, _hadithEn]);
      expect(m.items.length, 3);
      expect(m.items[1].ar, isEmpty);
      expect(m.items[1].en, startsWith('Also'));
      expect(m.items[2].grades.length, 1); // بلا تكرار
      expect(m.items[0].norm, contains('انما الاعمال بالنيات'));
      final share = hadithShareText(hadithCollections.first, 3, m.items[2].ar, m.items[2].en, m.items[2].grades);
      expect(share, contains('المصدر: الأربعون النووية، رقم 3'));
      expect(share, contains('Al-Albani: Sahih'));
    });

    test('بحث المخزن', () {
      final st = QuranStore.instance;
      st.debugLoad(parseQuranEdition(_quranSample, stripBasmala: true));
      final (r, n) = st.search('الصابرين');
      expect(n, 1);
      expect(r.single.ayah, 153);
      expect(ayahRef(2, 153), '(سورة البقرة: 153)');
      expect(ayahRef(2, 1, 5), '(سورة البقرة: 1–5)');
    });
  });

  test('البطاقات: كل نص له مرجع', () {
    for (final l in Lang.values) {
      appLang = l;
      for (final (_, c) in [...dhikrChoices(), ...duaChoices()]) {
        expect(c.valid, isTrue, reason: c.text);
      }
      expect(dhikrChoices(), isNotEmpty);
      expect(duaChoices(), isNotEmpty);
      expect(umrahSteps.length, 7);
      expect(miqats.length, 5);
    }
    appLang = Lang.sd;
  });

  test('أسماء الأدوات مترجمة', () {
    appLang = Lang.en;
    final mine = allTools.where((t) => _ids.contains(t.id)).toList();
    expect(mine.length, 4);
    for (final t in mine) {
      expect(RegExp(r'[؀-ۿ]').hasMatch(t.name), isFalse, reason: t.id);
      expect(RegExp(r'[؀-ۿ]').hasMatch(t.sub), isFalse, reason: t.id);
    }
    appLang = Lang.sd;
  });

  for (final dataLoaded in [false, true]) {
    for (final lang in Lang.values) {
      testWidgets('أدوات القرآن والحديث — ${lang.name}${dataLoaded ? ' (مع بيانات)' : ''}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        if (dataLoaded) {
          QuranStore.instance.debugLoad(_fakeQuran());
          QuranStore.instance.debugLoadTafsir('muyassar', _fakeQuran());
          QuranStore.instance.debugLoadTafsir('saheeh', _fakeQuran());
          debugPutCache(hadithCollections.first.cacheName('ara'), _hadithAr);
          debugPutCache(hadithCollections.first.cacheName('eng'), _hadithEn);
          s.setData('hadith_favs', [
            {'b': 'nawawi', 'n': 3, 'ar': 'بُنِيَ الْإِسْلَامُ عَلَى خَمْسٍ', 'en': 'Islam has been built on five.', 'g': [['Al-Albani', 'Sahih']]},
            for (var i = 0; i < 4; i++) {'b': 'bukhari', 'n': 7000 + i, 'ar': 'نص طويل ' * 30, 'en': 'long text ' * 30, 'g': []},
          ]);
          s.setData('hajj_umrah_done', ['u_prep', 'u_ihram', 'h_8']);
          s.setData('quran_search_last', [2, 3]);
        } else {
          await tester.runAsync(() => QuranStore.instance.deleteText());
        }
        tester.view.physicalSize = const Size(860, 2340);
        tester.view.devicePixelRatio = 2.6;
        addTearDown(tester.view.reset);
        final failures = <String>[];
        final orig = FlutterError.onError;
        String? cur;
        FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
        addTearDown(() => FlutterError.onError = orig);

        Future<void> pump(ToolDef tool) async {
          await tester.pumpWidget(ChangeNotifierProvider.value(
            value: s,
            child: MaterialApp(
              locale: Locale(lang == Lang.en ? 'en' : 'ar'),
              builder: (c, child) => Directionality(textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl, child: child!),
              theme: buildTheme(Brightness.dark),
              home: Scaffold(body: Builder(builder: tool.builder)),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
          await tester.pump(const Duration(milliseconds: 50));
        }

        Future<void> tapText(String txt) async {
          final f = find.text(txt);
          if (f.evaluate().isEmpty) return;
          await tester.ensureVisible(f.first);
          await tester.pump();
          final hit = tester.getCenter(f.first);
          final h = tester.view.physicalSize.height / tester.view.devicePixelRatio;
          if (hit.dy > h - 40) await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
          await tester.pump();
          await tester.tap(f.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
          await tester.pump(const Duration(milliseconds: 400));
        }

        for (final tool in allTools.where((t) => _ids.contains(t.id))) {
          cur = tool.id;
          await pump(tool);
          if (dataLoaded) {
           try {
            switch (tool.id) {
              case 'quran_search':
                await tester.enterText(find.byType(TextField).first, 'الصابرين');
                await tester.pump(const Duration(milliseconds: 500));
                if (find.textContaining('سورة البقرة').evaluate().isEmpty) failures.add('no search results');
                // افتح ورقة الآية
                await tester.tap(find.textContaining('سورة البقرة').first, warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 100));
                await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
                await tester.pump(const Duration(milliseconds: 600));
                await tapText('التفسير الميسّر');
                await tapText('تفسير الجلالين');
                await tester.tapAt(const Offset(10, 10));
                await tester.pump(const Duration(milliseconds: 600));
                await tapText(tr('السور', 'Surahs'));
                await tapText('سورة البقرة');
                await tapText(t('الملفات', 'الملفات', 'Files'));
              case 'hadith':
                await tapText(t('افتح واقرأ', 'افتح واقرأ', 'Open & read'));
                await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 800)));
                await tester.pump(const Duration(milliseconds: 300));
                if (find.textContaining('Actions are according', findRichText: true).evaluate().isEmpty) failures.add('hadith reader empty: spinner=${find.byType(CircularProgressIndicator).evaluate().length} open=${find.text(t('افتح واقرأ', 'افتح واقرأ', 'Open & read')).evaluate().length} cards=${find.byType(Card).evaluate().length}');
                await tester.enterText(find.byType(TextField).first, 'الاسلام');
                await tester.pump(const Duration(milliseconds: 500));
              case 'share_cards':
                for (final src in [tr('آية', 'Ayah'), tr('دعاء', 'Dua'), tr('ذكر', 'Dhikr')]) {
                  await tapText(src);
                  for (final d in cardDesigns) {
                    await tapText(d.name);
                  }
                }
                await tapText(t('ستوري 9:16', 'قصة 9:16', 'Story 9:16'));
              case 'hajj_umrah':
                for (final tab in [tr('العمرة', 'Umrah'), tr('الحج', 'Hajj'), t('تنبيهات', 'تنبيهات', 'Rules')]) {
                  await tapText(tab);
                  if (tab != t('تنبيهات', 'تنبيهات', 'Rules')) {
                    final steps = tab == tr('العمرة', 'Umrah') ? umrahSteps : hajjSteps;
                    for (final st in steps) {
                      await tapText(st.title());
                    }
                  }
                }
            }
           } catch (e) {
            failures.add('$cur: interaction failed: $e');
           }
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        }
        FlutterError.onError = orig;
        expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
      }, timeout: const Timeout(Duration(minutes: 3)));
    }
  }
}
