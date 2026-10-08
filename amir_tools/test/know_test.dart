import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/services/calendars.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/know/know_common.dart';
import 'package:amir_tools/tools/know/dialect_data.dart';
import 'package:amir_tools/tools/know/dialect_tool.dart';
import 'package:amir_tools/tools/know/terms_data.dart';
import 'package:amir_tools/tools/know/terms_tool.dart';
import 'package:amir_tools/tools/know/holidays_tool.dart';
import 'package:amir_tools/tools/know/links_tool.dart';
import 'package:amir_tools/tools/know/cv_model.dart';
import 'package:amir_tools/tools/know/cv_pdf.dart';
import 'package:amir_tools/tools/work/phrasebook_data.dart';

const _ids = {'sd_dialect', 'official_terms', 'cv_builder', 'holidays', 'official_links', 'phrasebook'};

final _longCv = <String, dynamic>{
  'id': 'cv1',
  'title': 'A very long CV title for testing ellipsis in chips and rows',
  'lang': 'ar',
  'tpl': 'modern',
  'name': 'محمد عبد الرحمن عثمان الطيب أحمد',
  'jobTitle': 'محاسب أول ومراجع حسابات — Senior Accountant & Auditor',
  'phone': '+966 55 123 4567',
  'email': 'mohamed.abdelrahman.osman@example.com',
  'city': 'الرياض، المملكة العربية السعودية',
  'nationality': 'سوداني',
  'birth': '1990-05-12',
  'link': 'https://www.linkedin.com/in/a-very-long-profile-name-for-testing',
  'objective': 'محاسب بخبرة تسع سنوات في الشركات التجارية والصناعية، متمكن من إعداد القوائم المالية والمراجعة الداخلية والأنظمة المحاسبية مثل SAP وOracle، أبحث عن فرصة تضيف قيمة حقيقية.',
  'exp': [
    {'title': 'محاسب أول', 'org': 'شركة النيل للتجارة والاستيراد والتصدير المحدودة', 'place': 'الرياض', 'from': '2019', 'to': 'حتى الآن', 'desc': '- إعداد القوائم المالية الشهرية\n- خفض المصروفات 18% خلال سنة\n- الإشراف على فريق من 4 محاسبين'},
    {'title': 'Accountant', 'org': 'Sudanese Kenana Sugar Company', 'place': 'Kenana', 'from': '2014', 'to': '2019', 'desc': 'Payroll for 1,200 employees\nMonthly bank reconciliations'},
  ],
  'edu': [
    {'degree': 'بكالوريوس المحاسبة', 'school': 'جامعة الخرطوم', 'year': '2013', 'note': 'جيد جدًا'},
  ],
  'skills': [
    {'n': 'SAP FI/CO', 'lvl': 5},
    {'n': 'Excel المتقدم وجداول البيانات المحورية', 'lvl': 4},
    {'n': 'المراجعة الداخلية', 'lvl': 4},
  ],
  'langs': [
    {'n': 'العربية', 'lvl': 5},
    {'n': 'English', 'lvl': 4},
  ],
  'certs': [
    {'n': 'CMA', 'org': 'IMA', 'year': '2020'},
  ],
  'refs': [
    {'n': 'أ. عبد المنعم محمد', 'role': 'المدير المالي', 'contact': '+966 50 000 0000'},
  ],
};

Map<String, Object> _seeded() {
  final en = Map<String, dynamic>.from(_longCv)
    ..['id'] = 'cv2'
    ..['lang'] = 'en'
    ..['tpl'] = 'compact'
    ..['title'] = 'English CV';
  final state = {
    'x_cv_builder_list': [_longCv, en],
    'x_cv_builder_current': 'cv1',
    'x_holidays_personal': [
      {'id': 'p1', 'name': 'A very long personal anniversary name that should ellipsize nicely', 'date': '2015-12-01', 'yearly': true},
      {'id': 'p2', 'name': 'سفر', 'date': '2027-01-20', 'yearly': false},
    ],
    'x_holidays_country': 'EG',
    'x_sd_dialect_favs': ['expr|زول', 'food|الجبنة'],
    'x_phrasebook_favs': ['travel_20', 'sos_3'],
  };
  return {'amir_state': jsonEncode(state)};
}

Future<(pw.Font, pw.Font)> _fonts() async {
  final r = pw.Font.ttf((await File('assets/fonts/Tajawal-Regular.ttf').readAsBytes()).buffer.asByteData());
  final b = pw.Font.ttf((await File('assets/fonts/Tajawal-Bold.ttf').readAsBytes()).buffer.asByteData());
  return (r, b);
}

/// يحمّل خطوط التطبيق الحقيقية حتى يكون كشف تجاوز النصوص واقعيًا
Future<void> _loadAppFonts() async {
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
    await _loadAppFonts();
  });

  test('know tools registered and translated', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => _ids.contains(t.id)).toList();
      expect(mine.length, _ids.length);
      for (final t in mine) {
        if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
        expect(RegExp('[a-z]').hasMatch(t.keywords) && RegExp(r'[؀-ۿ]').hasMatch(t.keywords), isTrue, reason: t.id);
      }
    }
    appLang = Lang.sd;
    expect(toolById('sd_dialect')!.cat, ToolCat.learn);
    expect(toolById('sd_dialect')!.sudan, isTrue);
    expect(toolById('holidays')!.cat, ToolCat.daily);
    for (final id in ['official_terms', 'cv_builder', 'official_links']) {
      expect(toolById(id)!.cat, ToolCat.work);
    }
  });

  test('Arabic normalization', () {
    expect(normAr('أَهْلًا'), normAr('اهلا'));
    expect(normAr('إقامة'), 'اقامه');
    expect(normAr('مستشفى'), 'مستشفي');
    expect(normAr('آيبان'), 'ايبان');
    expect(normAr('كتّر'), 'كتر');
  });

  test('dialect dictionary: size, ids, search, reverse search', () {
    expect(dialectWords.length, greaterThanOrEqualTo(300));
    final ids = dialectWords.map(dWordId).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate word ids');
    final cats = dialectCats.map((c) => c.key).toSet();
    for (final w in dialectWords) {
      expect(cats.contains(w.cat), isTrue, reason: w.word);
      expect(w.msa.isNotEmpty && w.en.isNotEmpty && w.ex.isNotEmpty, isTrue, reason: w.word);
    }
    for (final c in dialectCats) {
      expect(dialectWords.where((w) => w.cat == c.key), isNotEmpty, reason: c.key);
    }
    expect(searchDialect('زول').first.word, 'زول');
    expect(searchDialect('هسّي').first.word, 'هسي'); // diacritics stripped
    expect(searchDialect('كتر خيرك').first.word, 'كتّر خيرك');
    expect(searchDialect('grandmother').map((w) => w.word), contains('حبوبة'));
    expect(searchDialect('now', reverse: true).map((w) => w.word), contains('هسي'));
    expect(searchDialect('غدا', reverse: true).map((w) => w.word), contains('بكرة'));
    expect(searchDialect('زول', reverse: true), isNot(contains(predicate<DWord>((w) => w.word == 'زول'))));
    expect(searchDialect(''), isEmpty);
    final a = wordOfDay(DateTime(2026, 10, 8)), b = wordOfDay(DateTime(2026, 10, 8, 23));
    expect(a, same(b));
    expect(wordOfDay(DateTime(2026, 10, 9)), isNot(same(a)));
    expect(dialectShareText(a), contains(a.word));
  });

  test('official terms glossary', () {
    expect(officialTerms.length, greaterThanOrEqualTo(110));
    final cats = termCats.map((c) => c.key).toSet();
    for (final o in officialTerms) {
      expect(cats.contains(o.cat), isTrue, reason: o.ar);
      expect([o.ar, o.en, o.expAr, o.expEn, o.tipAr, o.tipEn].every((x) => x.trim().isNotEmpty), isTrue, reason: o.ar);
    }
    expect(officialTerms.map((o) => o.ar).toSet().length, officialTerms.length);
    for (final q in ['IBAN', 'swift', 'الايبان', 'كفالة', 'مخالصه', 'اقامة', 'probation', 'تأشيرة خروج وعودة']) {
      expect(searchTerms(q), isNotEmpty, reason: q);
    }
    expect(searchTerms('كفيل').first.ar, 'كفيل');
  });

  test('phrasebook expanded, ids stable', () {
    for (final c in ['travel', 'health', 'work', 'bank', 'sos']) {
      final l = phrases.where((p) => p.cat == c).toList();
      expect(l.length, greaterThanOrEqualTo(25), reason: c);
      expect(l.every((p) => p.pron.isNotEmpty), isTrue, reason: c);
    }
    final ids = phrases.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    // existing ids unchanged
    expect(phrases.firstWhere((p) => p.id == 'travel_0').en, 'Where is the check-in counter?');
    expect(phrases.firstWhere((p) => p.id == 'sos_3').en, 'I\'ve been robbed.');
    expect(phrases.firstWhere((p) => p.id == 'greet_0').sd, 'السلام عليكم');
  });

  test('holidays: fixed, Islamic and personal', () {
    final from = DateTime(2026, 10, 8);
    final sd = fixedHolidays('SD', from);
    expect(sd.map((h) => h.date), containsAll([DateTime(2027, 1, 1), DateTime(2027, 1, 7), DateTime(2026, 12, 25)]));
    expect(fixedHolidays('XX', from), isEmpty);
    expect(fixedHolidays('SA', from).map((h) => h.date), containsAll([DateTime(2027, 2, 22), DateTime(2027, 9, 23)]));
    final isl = islamicOccasions(from);
    for (final id in ['hijri_new_year', 'mawlid', 'ramadan', 'eid_fitr', 'arafah', 'eid_adha']) {
      final h = isl.firstWhere((x) => x.id.startsWith('$id-'), orElse: () => throw 'missing $id');
      expect(h.date.isBefore(from), isFalse);
      final hj = toHijri(h.date);
      final (m, d) = switch (id) {
        'hijri_new_year' => (1, 1),
        'mawlid' => (3, 12),
        'ramadan' => (9, 1),
        'eid_fitr' => (10, 1),
        'arafah' => (12, 9),
        _ => (12, 10),
      };
      expect((hj.m, hj.d), (m, d), reason: id);
    }
    // sighting shift moves the Gregorian date by a day
    final shifted = islamicOccasions(from, shift: 1).firstWhere((x) => x.id.startsWith('eid_fitr-'));
    final base = isl.firstWhere((x) => x.id.startsWith('eid_fitr-'));
    expect(base.date.difference(shifted.date).inDays.abs(), 1);
    final p = personalHolidays([
      {'id': 'a', 'name': 'x', 'date': '2010-10-20', 'yearly': true},
      {'id': 'b', 'name': 'y', 'date': '2026-01-01', 'yearly': false},
      {'id': 'c', 'name': 'z', 'date': '2026-12-01', 'yearly': false},
    ], from);
    expect(p.map((h) => h.date), containsAll([DateTime(2026, 10, 20), DateTime(2027, 10, 20), DateTime(2026, 12, 1)]));
    expect(p.any((h) => h.name == 'y'), isFalse);
  });

  test('official links are https and unique', () {
    final urls = officialLinks.map((l) => l.url).toList();
    expect(urls.toSet().length, urls.length);
    for (final l in officialLinks) {
      expect(l.url.startsWith('https://'), isTrue, reason: l.url);
      expect(l.host, isNotEmpty);
      expect(linkGroups.contains(l.group), isTrue);
    }
    expect(urls, contains('https://reliefweb.int/country/sdn'));
  });

  test('CV model & PDF (Arabic RTL + English, all templates)', () async {
    final (pct, missing) = cvCompleteness(_longCv);
    expect(pct, 1.0);
    expect(missing, isEmpty);
    expect(cvCompleteness({}).$1, 0);
    expect(cvBullets('- a\n• b\n\n c '), ['a', 'b', 'c']);
    final txt = cvPlainText(_longCv);
    expect(txt, contains('الخبرات العملية'));
    expect(txt, contains('SAP FI/CO'));
    final (r, b) = await _fonts();
    for (final lang in ['ar', 'en']) {
      for (final tpl in ['classic', 'modern', 'compact']) {
        final cv = Map<String, dynamic>.from(_longCv)
          ..['lang'] = lang
          ..['tpl'] = tpl;
        final bytes = await buildCvPdf(cv, r, b);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: '$lang/$tpl');
        expect(bytes.length, greaterThan(2000));
      }
    }
    // very long CV spans multiple pages without throwing
    final long = Map<String, dynamic>.from(_longCv)..['exp'] = [for (var i = 0; i < 25; i++) ...cvList(_longCv, 'exp')];
    final bytes = await buildCvPdf(long, r, b);
    expect(bytes.length, greaterThan(5000));
    // unsupported glyphs (emoji, CJK, Persian letters) and Arabic inside an English CV must not break export
    for (final lang in ['ar', 'en']) {
      final odd = {'lang': lang, 'name': 'أحمد 😀 Ahmed 张', 'jobTitle': 'مهندس ★ ڤيديو', 'skills': [{'n': 'برمجة 🚀', 'lvl': 4}], 'langs': [{'n': 'العربية', 'lvl': 5}]};
      expect((await buildCvPdf(odd, r, b)).length, greaterThan(1000));
    }
    // empty CV still renders
    expect((await buildCvPdf({'lang': 'en'}, r, b)).length, greaterThan(500));
  });

  for (final seeded in [false, true]) {
    for (final lang in Lang.values) {
      testWidgets('know tools open cleanly — ${lang.name}${seeded ? ' (seeded)' : ''}', (tester) async {
        SharedPreferences.setMockInitialValues(seeded ? _seeded() : {});
        final s = await AppState.load();
        s.lang = lang;
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3.0; // 360dp wide
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
          await tester.pump(const Duration(milliseconds: 50));

          // interactions per tool
          if (tool.id == 'cv_builder' && seeded) {
            for (final label in ['Experience', 'Skills', 'Languages', 'References', 'Summary']) {
              final f = find.text(lang == Lang.en ? label : _arSec(label, lang));
              if (f.evaluate().isNotEmpty) {
                await tester.tap(f.first, warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 50));
              }
            }
          }
          if (tool.id == 'sd_dialect') {
            await tester.enterText(find.byType(TextField).first, 'شاي');
            await tester.pump(const Duration(milliseconds: 50));
          }

          final scroll = find.byType(Scrollable).first;
          for (var i = 0; i < 14; i++) {
            await tester.drag(scroll, const Offset(0, -500), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 50));
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 3));
        }
        FlutterError.onError = orig;
        expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
      });
    }
  }
}

String _arSec(String en, Lang l) => switch (en) {
      'Experience' => 'الخبرات',
      'Skills' => 'المهارات',
      'Languages' => 'اللغات',
      'References' => l == Lang.sd ? 'المعرّفين' : 'المعرّفون',
      'Summary' => l == Lang.sd ? 'الملخص' : 'الملخص المهني',
      _ => en,
    };
