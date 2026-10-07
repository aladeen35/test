import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/extra/card_scores_tool.dart' show CardGame;
import 'package:amir_tools/tools/extra/domino_tool.dart' show splitTeams;
import 'package:amir_tools/tools/extra/notes_tool.dart' show wordCount;
import 'package:amir_tools/tools/extra/recorder_tool.dart' show clock, ampLevel;

const _ids = {'card_scores', 'domino', 'notes', 'img_pdf', 'recorder', 'mirror', 'travel_list'};

String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, Object> _seeded(bool over) {
  final now = DateTime.now();
  final ms = now.millisecondsSinceEpoch;
  final players = ['Abdelrahman Mohamed Osman', 'أحمد', 'Mustafa Eltayeb', 'سارة', 'Hassan', 'Fatima Abdallah', 'Omer', 'Khalid'];
  final state = {
    'x_card_scores_game': {
      'preset': 'konkan', 'low': true, 'limit': 101, 'target': 0, 'cap': 0, 'players': players,
      'rounds': [
        [10, 20, 30, 40, 50, 60, 70, 80],
        [-30, 90, 80, 70, 60, 50, 40, over ? 100 : 5],
        if (over) [0, 0, 0, 0, 0, 0, 0, 0],
      ],
      'start': ms,
    },
    'x_card_scores_history': [
      {'preset': 'hand', 'players': players, 'totals': [1, 2], 'winners': ['Abdelrahman Mohamed Osman', 'Mustafa Eltayeb'], 'rounds': 12, 't': ms},
    ],
    'x_domino_game': {
      'mode': 'solo', 'names': ['Abdelrahman Mohamed', 'Mustafa Eltayeb Ahmed', 'سارة', 'Omer'], 'target': 101,
      'rounds': [
        {'w': 0, 'p': 35},
        {'w': 1, 'p': over ? 120 : 20},
      ],
      'start': ms,
    },
    'x_domino_history': [
      {'names': ['A', 'B'], 'totals': [101, 40], 'winner': 'Very long team name for the winners', 'rounds': 5, 't': ms},
    ],
    'x_domino_split': {'names': 'أحمد\nعثمان\nMustafa Eltayeb Abdelrahman\nسارة\nHassan', 'n': 2, 'teams': [['أحمد', 'Mustafa Eltayeb Abdelrahman', 'Hassan'], ['عثمان', 'سارة']]},
    'x_notes_list': [
      {'id': 'n1', 'title': 'A very long note title that should be cut with an ellipsis at the end', 'body': 'Line one\nLine two with more words ' * 10, 'color': 2, 'pin': true, 'check': false, 'items': [], 'c': ms, 'u': ms},
      {'id': 'n2', 'title': 'مشتريات', 'body': '', 'color': 5, 'pin': false, 'check': true, 'items': [
        {'t': 'سكر', 'd': true}, {'t': 'Very long checklist item text that keeps going and going', 'd': false},
        {'t': 'c', 'd': false}, {'t': 'd', 'd': false}, {'t': 'e', 'd': false}, {'t': 'f', 'd': false},
      ], 'c': ms, 'u': ms - 86400000 * 3},
    ],
    'x_travel_list_trips': [
      {'id': 't1', 'name': 'Umrah with the whole family in Ramadan', 'tpl': 'umrah', 'date': _d(now.add(const Duration(days: 12))), 'items': [
        for (var i = 0; i < 26; i++) {'id': 'i$i', 'k': 'umrah.$i', 'd': i.isEven},
        {'id': 'x', 'n': 'Custom item with a very long description to wrap around', 'c': 'gifts', 'd': false},
      ], 'c': ms},
      {'id': 't2', 'name': 'السودان', 'tpl': 'sudan', 'date': null, 'items': [{'id': 'a', 'k': 'sudan.0', 'd': false}], 'c': ms},
    ],
    'x_img_pdf_files': [
      {'name': 'Very long document name for the certificates 2026-10-07 1530.pdf', 'path': '/nonexistent/a.pdf', 'pages': 12, 'size': 3456789, 't': ms},
    ],
    'x_recorder_list': [
      {'id': 'r1', 'name': 'Lecture: Introduction to accounting, part one (long name)', 'path': '/nonexistent/r.m4a', 'ms': 3725000, 'size': 12345678, 't': ms},
    ],
  };
  return {'amir_state': jsonEncode(state)};
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('card game logic', () {
    final g = CardGame({
      'preset': 'konkan', 'low': true, 'limit': 101, 'players': ['a', 'b', 'c'],
      'rounds': [
        [50, 60, 10],
        [60, 30, 10],
      ],
    });
    expect(g.totals, [110, 90, 20]);
    expect(g.out, [true, false, false]);
    expect(g.over, isFalse);
    expect(g.standing, [2, 1, 0]);
    final g2 = CardGame({...g.raw, 'rounds': [...g.raw['rounds'] as List, [0, 20, 5]]});
    expect(g2.over, isTrue);
    expect(g2.winners, [2]);
    final hi = CardGame({'preset': 'custom', 'low': false, 'target': 100, 'players': ['a', 'b'], 'rounds': [[60, 40], [50, 70]]});
    expect(hi.over, isTrue);
    expect(hi.winners, [0, 1]);
    final cap = CardGame({'preset': 'custom', 'low': true, 'limit': 0, 'cap': 2, 'players': ['a', 'b'], 'rounds': [[5, 1], [5, 1]]});
    expect(cap.over, isTrue);
    expect(cap.winners, [1]);
  });

  test('team split is balanced and complete', () {
    final names = [for (var i = 0; i < 11; i++) 'p$i'];
    for (var n = 2; n <= 6; n++) {
      final teams = splitTeams(names, n, math.Random(n));
      expect(teams.length, n);
      final sizes = teams.map((e) => e.length).toList();
      expect(sizes.reduce(math.max) - sizes.reduce(math.min), lessThanOrEqualTo(1));
      expect(teams.expand((e) => e).toSet(), names.toSet());
    }
  });

  test('helpers', () {
    expect(wordCount('  hello   world \n again '), 3);
    expect(wordCount(''), 0);
    expect(clock(const Duration(seconds: 65)), '01:05');
    expect(clock(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    expect(ampLevel(0), 1);
    expect(ampLevel(-160), 0);
  });

  test('extra tools registered and translated', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => _ids.contains(t.id)).toList();
      expect(mine.length, _ids.length);
      for (final t in mine) {
        expect(t.keywords, isNotEmpty);
        if (l == Lang.en) expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
      }
    }
    appLang = Lang.sd;
  });

  for (final seed in ['', 'play', 'over']) {
    for (final lang in Lang.values) {
      testWidgets('extra tools open cleanly — ${lang.name}${seed.isEmpty ? '' : ' ($seed)'}', (tester) async {
        SharedPreferences.setMockInitialValues(seed.isEmpty ? {} : _seeded(seed == 'over'));
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
          await tester.pump(const Duration(milliseconds: 50));
          final scroll = find.byType(Scrollable).first;
          for (var i = 0; i < 14; i++) {
            await tester.drag(scroll, const Offset(0, -500), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 50));
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        }
        FlutterError.onError = orig;
        expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
      });
    }
  }

  testWidgets('domino split tab and card setup render in English', (tester) async {
    SharedPreferences.setMockInitialValues(_seeded(false));
    final s = await AppState.load();
    s.lang = Lang.en;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    Future<void> open(String id) async {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: s,
        child: MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: Builder(builder: toolById(id)!.builder))),
      ));
      await tester.pump();
    }

    await open('domino');
    await tester.tap(find.text('Split teams'));
    await tester.pump();
    expect(find.text('Team 1'), findsOneWidget);
    await tester.tap(find.text('Reshuffle'));
    await tester.pump();

    // card game: open setup from the running game
    s.setData('card_scores_game', null);
    await open('card_scores');
    expect(find.text('Start game'), findsOneWidget);
    await tester.tap(find.text('Hand'));
    await tester.pump();
    await tester.ensureVisible(find.text('Start game'));
    await tester.pump();
    await tester.tap(find.text('Start game'));
    await tester.pump();
    expect(find.text('Save round'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '25');
    await tester.ensureVisible(find.text('Save round'));
    await tester.pump();
    await tester.tap(find.text('Save round'));
    await tester.pump();
    expect(CardGame(Map<String, dynamic>.from(s.getData<Map>('card_scores_game')!)).rounds.length, 1);

    // notes: create via sheet
    await open('notes');
    await tester.tap(find.text('New note'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.enterText(find.byType(TextField).first, 'Hello note');
    await tester.tap(find.text('Save'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Hello note'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
