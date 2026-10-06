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
import 'package:amir_tools/tools/work/salary_tool.dart' show saudiEos;

const _ids = {'salary', 'documents', 'phrasebook', 'invoice'};

String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, Object> _seeded(String mode) {
  final now = DateTime.now();
  final state = {
    'x_salary_cfg': {
      'basic': '12500', 'housing': '3125', 'transport': '1000', 'other': '750', 'gosi': '9.75', 'fixed': '200',
      'hours': '8', 'otH': '20', 'otR': '1.5', 'genDays': '21', 'mode': mode, 'cur': 'SAR', 'law': 'sa', 'reason': 'resign',
      'start': '2014-03-15', 'end': null, 'incH': true, 'incT': true, 'incO': false,
    },
    'x_documents_list': [
      {'id': 'a', 'type': 'passport', 'person': '', 'label': '', 'no': 'P01234567', 'notes': 'Renew at the Sudanese embassy in Riyadh, bring 2 photos', 'remind': 60, 'exp': _d(now.add(const Duration(days: 12)))},
      {'id': 'b', 'type': 'iqama', 'person': 'Mohamed Abdelrahman Osman', 'label': '', 'no': '', 'notes': '', 'remind': 30, 'exp': _d(now.subtract(const Duration(days: 40)))},
      {'id': 'c', 'type': 'custom', 'person': 'أمي', 'label': 'A very long custom document name that should ellipsize', 'no': '', 'notes': '', 'remind': 30, 'exp': _d(now.add(const Duration(days: 900)))},
      {'id': 'd', 'type': 'carreg', 'person': '', 'label': '', 'no': '', 'notes': '', 'remind': 30, 'exp': _d(now)},
    ],
    'x_invoice_profile': {'name': 'Ameer Electronics & Mobile Accessories Trading Est.', 'phone': '+966 55 123 4567', 'addr': 'Al Batha, Riyadh, Saudi Arabia', 'cur': 'SAR'},
    'x_invoice_draft': {
      'items': [
        {'n': 'Samsung Galaxy charger 25W fast charging original', 'q': 3, 'p': 89.5},
        {'n': 'كفر جوال', 'q': 120, 'p': 12345.75},
      ],
      'disc': 10, 'discPct': true, 'vat': 15, 'notes': 'Warranty 6 months', 'customer': 'Abdelmoneim Mohamed Ahmed', 'no': null, 'date': _d(now),
    },
    'x_invoice_next': 12,
    'x_invoice_history': [
      {'items': [{'n': 'x', 'q': 1, 'p': 5}], 'disc': 0, 'discPct': false, 'vat': 0, 'notes': '', 'customer': 'Very long customer name here for testing', 'no': 11, 'date': _d(now), 'cur': 'SAR'},
    ],
    'x_phrasebook_favs': ['travel_0', 'sos_3'],
  };
  return {'amir_state': jsonEncode(state)};
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('Saudi end-of-service rules', () {
    // 3 years, wage 10000, contract end → 1.5 months
    expect(saudiEos(3, 10000, 'end').award, closeTo(15000, 1e-6));
    // 8 years: 5×0.5 + 3×1 = 5.5 months
    expect(saudiEos(8, 10000, 'end').award, closeTo(55000, 1e-6));
    // resignation: <2 → 0, 3y → 1/3, 8y → 2/3, 12y → full
    expect(saudiEos(1.9, 10000, 'resign').award, 0);
    expect(saudiEos(3, 10000, 'resign').award, closeTo(5000, 1e-6));
    expect(saudiEos(8, 10000, 'resign').award, closeTo(55000 * 2 / 3, 1e-6));
    expect(saudiEos(12, 10000, 'resign').award, closeTo(95000, 1e-6));
    expect(saudiEos(12, 10000, 'art80').award, 0);
  });

  test('work tools registered and translated', () {
    for (final l in Lang.values) {
      appLang = l;
      final mine = allTools.where((t) => _ids.contains(t.id)).toList();
      expect(mine.length, _ids.length);
      for (final t in mine) {
        expect(t.cat, ToolCat.work);
        if (l == Lang.en) {
          expect(RegExp(r'[؀-ۿ]').hasMatch(t.name + t.sub), isFalse, reason: t.id);
        }
      }
    }
    appLang = Lang.sd;
  });

  for (final seeded in ['', 'net', 'eos']) {
    for (final lang in Lang.values) {
      testWidgets('work tools open cleanly — ${lang.name}${seeded.isEmpty ? '' : ' (with data, salary=$seeded)'}', (tester) async {
        SharedPreferences.setMockInitialValues(seeded.isEmpty ? {} : _seeded(seeded));
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
          final scroll = find.byType(Scrollable).first;
          for (var i = 0; i < 12; i++) {
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
}
