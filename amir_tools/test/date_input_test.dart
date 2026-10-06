import 'package:amir_tools/core/date_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// يحاكي كتابة المستخدم حرفًا حرفًا
String typeAll(String keys) {
  const f = DateSlashFormatter();
  var v = TextEditingValue.empty;
  for (final ch in keys.split('')) {
    final next = ch == '<' ? v.text.substring(0, v.text.length - 1) : v.text + ch;
    v = f.formatEditUpdate(v, TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length)));
  }
  return v.text;
}

void main() {
  test('الفاصلة تُكتب تلقائيًا', () {
    expect(typeAll('0'), '0');
    expect(typeAll('06'), '06/');
    expect(typeAll('0610'), '06/10/');
    expect(typeAll('06102026'), '06/10/2026');
    expect(typeAll('061020261'), '06/10/2026');
  });
  test('الأرقام العربية تتحوّل', () => expect(typeAll('٠٦١٠٢٠٢٦'), '06/10/2026'));
  test('الحذف يتجاوز الفاصلة', () {
    expect(typeAll('06<'), '0');
    expect(typeAll('0610<'), '06/1');
    expect(typeAll('061<'), '06');
  });
  test('التحليل', () {
    expect(DateSlashFormatter.parse('06/10/2026'), DateTime(2026, 10, 6));
    expect(DateSlashFormatter.parse('31/02/2026'), isNull);
    expect(DateSlashFormatter.parse('06/10/26'), isNull);
  });
}
