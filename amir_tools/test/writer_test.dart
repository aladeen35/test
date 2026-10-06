import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/writer/writer_data.dart';
import 'package:amir_tools/tools/writer/writer_editor.dart';

const _long = 'A really long English sentence that should wrap nicely without overflowing the frame at all';

void _seed(AppState s) {
  final today = dk(todayPlace());
  final yesterday = dk(todayPlace().subtract(const Duration(days: 1)));
  s.setData('writer_projects', [
    {
      'id': 'p1',
      'title': 'The Very Long Title of the Nile Story That Goes On and On Forever',
      'genre': 'folk',
      'status': 'revise',
      'emoji': '🌴',
      'color': 3,
      'logline': _long,
      'synopsis': '$_long. $_long.',
      'target': 80000,
      'deadline': dk(todayPlace().add(const Duration(days: 40))),
      'tpl': 'cat',
      'beats': [for (var i = 0; i < 15; i++) {'i': i, 'done': i < 4, 'scene': i == 1 ? 's1' : null}],
      'chars': [
        {
          'id': 'c1', 'name': 'Mohamed Ahmed Osman Elkhalifa Abdelrahim', 'role': 'hero', 'age': '34', 'look': _long,
          'traits': ['Brave', 'Self-sacrificing', 'Hot-tempered', 'Mysterious', 'Optimistic'], 'back': _long, 'goal': _long, 'fear': 'water',
          'arc': _long, 'voice': 'slow',
          'rels': [
            {'to': 'c2', 'type': 'love', 'note': _long},
            {'to': 'c3', 'type': 'enemy', 'note': ''},
          ],
        },
        {'id': 'c2', 'name': 'Fatima', 'role': 'love', 'traits': ['Witty'], 'rels': [{'to': 'c1', 'type': 'love', 'note': ''}]},
        {'id': 'c3', 'name': 'The Ogre of the Old Market', 'role': 'custom', 'roleC': 'A very long custom role name here', 'rels': [{'to': 'c4', 'type': 'mentor'}]},
        {'id': 'c4', 'name': 'Bakhita', 'role': 'mentor', 'rels': [{'to': 'c1', 'type': 'family', 'note': 'aunt'}]},
        {'id': 'c5', 'name': 'Idris', 'role': 'sidekick', 'rels': []},
      ],
      'chapters': [
        {
          'id': 'ch1', 'title': 'Dawn on the Nile with an extremely long chapter title indeed',
          'scenes': [
            {'id': 's1', 'title': 'The fisherman finds a sealed box with a brass lock', 'summary': _long, 'pov': 'c1', 'loc': 'Tuti Island at dawn', 'present': ['c1', 'c2'], 'status': 'ready', 'wc': 12},
            {'id': 's2', 'title': 'Market', 'status': 'draft', 'wc': 3400},
          ],
        },
        {
          'id': 'ch2', 'title': 'Haboob',
          'scenes': [
            for (var i = 0; i < 6; i++) {'id': 'x$i', 'title': 'Scene $i', 'status': ['idea', 'draft', 'review', 'ready'][i % 4], 'wc': 100 * i},
          ],
        },
        {'id': 'ch3', 'title': '', 'scenes': []},
      ],
      'notes': [
        {'id': 'n1', 'kind': 'place', 'title': 'Tuti Island', 'body': _long, 'tags': ['nile', 'island', 'a-very-long-tag-name-here']},
        {'id': 'n2', 'kind': 'lore', 'title': 'The ogre legend', 'body': 'Old tale', 'tags': []},
        {'id': 'n3', 'kind': 'research', 'title': 'Boat types', 'body': '', 'tags': ['boats']},
      ],
    },
    {'id': 'p2', 'title': 'Short poem', 'genre': 'poetry', 'status': 'idea', 'target': 0, 'chars': [], 'chapters': [], 'notes': [], 'beats': []},
  ]);
  s.setData('writer_current', 'p1');
  s.setData('writer_txt_s1', 'The river was quiet that morning. Nobody saw the box.');
  s.setData('writer_stats', {
    'goal': 500,
    'days': {today: 620, yesterday: 300},
  });
}

const _labels = ['story', 'cast', 'plot', 'world', 'ideas', 'stats'];

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('عدّ الكلمات والتصدير والإحصائيات', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppState.load();
    _seed(s);
    final st = WStore(s);
    expect(wordCount('  hello   world\nمرحبا  '), 3);
    expect(wordCount(''), 0);
    expect(readMinutes(401), 3);
    expect(projectWords(st.current), 12 + 3400 + 1500);
    final md = compileManuscript(st, st.current!, markdown: true);
    expect(md, contains('## '));
    expect(md, contains('Nobody saw the box.'));
    expect(md.indexOf('Dawn on the Nile'), lessThan(md.indexOf('Haboob')));
    expect(compileCharacters(st.current!), contains('Fatima'));
    expect(st.streak, 2);
    expect(st.today, 620);
    st.addWords(30);
    st.addWords(-50);
    expect(st.today, 650);
    expect(s.counter('words_written'), 30);
    for (final l in Lang.values) {
      appLang = l;
      final w = genWhatIf();
      expect(w.trim(), isNotEmpty);
      if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(w), isFalse);
      expect(genName(sudanese: true, female: true).split(' ').length, greaterThanOrEqualTo(3));
    }
    appLang = Lang.sd;
    expect(wPrompts.length, greaterThanOrEqualTo(40));
    expect(wTemplate('hero')!.beats.length, 12);
    expect(wTemplate('cat')!.beats.length, 15);
    expect(wTemplate('kish')!.beats.length, 4);
    expect(wTemplate('freytag')!.beats.length, 5);
  });

  test('الأداة مسجّلة ومترجمة', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => t.id == 'writer').toList();
      expect(mine.length, 1);
      if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(mine.first.name + mine.first.sub), isFalse);
    }
    appLang = Lang.sd;
  });

  for (final lang in Lang.values) {
    for (final seeded in [false, true]) {
      for (final width in [360.0, 415.0]) {
        testWidgets('مساعد الكاتب — ${lang.name} ${seeded ? 'ببيانات' : 'فارغ'} ${width.toInt()}dp', (tester) async {
          SharedPreferences.setMockInitialValues({});
          final s = await AppState.load();
          s.lang = lang;
          if (seeded) _seed(s);
          tester.view.physicalSize = Size(width * 2.6, 2340);
          tester.view.devicePixelRatio = 2.6;
          addTearDown(tester.view.reset);
          final failures = <String>[];
          final orig = FlutterError.onError;
          String? cur;
          FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
          addTearDown(() => FlutterError.onError = orig);
          final tool = allTools.firstWhere((t) => t.id == 'writer');
          Widget app(Widget home) => ChangeNotifierProvider.value(
                value: s,
                child: MaterialApp(
                  locale: Locale(lang == Lang.en ? 'en' : 'ar'),
                  theme: buildTheme(Brightness.dark),
                  home: Directionality(
                    textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl,
                    child: home,
                  ),
                ),
              );
          for (var tab = 0; tab < 6; tab++) {
            cur = _labels[tab];
            s.setData('writer_tab', tab);
            await tester.pumpWidget(app(Scaffold(body: Builder(builder: tool.builder))));
            await tester.pump(const Duration(milliseconds: 50));
            final lists = find.descendant(of: find.byType(TabBarView), matching: find.byType(ListView));
            for (var k = 0; k < 14; k++) {
              if (lists.evaluate().isEmpty) break;
              await tester.drag(lists.first, const Offset(0, -600), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 30));
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
          }
          if (seeded) {
            // ورقة الشخصية
            cur = 'char-sheet';
            s.setData('writer_tab', 1);
            await tester.pumpWidget(app(Scaffold(body: Builder(builder: tool.builder))));
            await tester.pump(const Duration(milliseconds: 50));
            await tester.tap(find.text('Mohamed Ahmed Osman Elkhalifa Abdelrahim').first, warnIfMissed: false);
            await tester.pumpAndSettle();
            expect(find.byType(BottomSheet), findsOneWidget);
            for (var k = 0; k < 6; k++) {
              final sc = find.byType(SingleChildScrollView);
              if (sc.evaluate().isEmpty) break;
              await tester.drag(sc.last, const Offset(0, -600), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 30));
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
            // ورقة المشهد
            cur = 'scene-sheet';
            s.setData('writer_tab', 2);
            await tester.pumpWidget(app(Scaffold(body: Builder(builder: tool.builder))));
            await tester.pump(const Duration(milliseconds: 50));
            expect(find.byType(CustomPaint), findsWidgets);
            await tester.tap(find.text('The fisherman finds a sealed box with a brass lock').first, warnIfMissed: false);
            await tester.pumpAndSettle();
            expect(find.byType(BottomSheet), findsOneWidget);
            for (var k = 0; k < 6; k++) {
              final sc = find.byType(SingleChildScrollView);
              if (sc.evaluate().isEmpty) break;
              await tester.drag(sc.last, const Offset(0, -600), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 30));
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
            // المحرر: كتابة نص وحفظ تلقائي
            cur = 'editor';
            await tester.pumpWidget(app(SceneEditor(state: s, projectId: 'p1', chapterId: 'ch1', sceneId: 's1')));
            await tester.pump();
            await tester.enterText(find.byType(TextField), 'one two three four five six seven eight nine ten eleven twelve thirteen');
            await tester.pump(const Duration(seconds: 2));
            expect(s.getData<String>('writer_txt_s1'), startsWith('one two'));
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
          }
          FlutterError.onError = orig;
          expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
        });
      }
    }
  }
}
