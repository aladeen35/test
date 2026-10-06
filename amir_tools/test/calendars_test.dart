import 'package:flutter_test/flutter_test.dart';
import 'package:amir_tools/services/calendars.dart';

void main() {
  test('هجري أم القرى', () {
    final h = toHijri(DateTime(2026, 10, 5));
    expect([h.y, h.m, h.d], [1448, 4, 24]);
    final r = toHijri(DateTime(2025, 3, 1));
    expect([r.y, r.m, r.d], [1446, 9, 1]);
    expect(fromHijri(1446, 9, 1), DateTime(2025, 3, 1));
  });
  test('قبطي وإثيوبي', () {
    final c = toCoptic(DateTime(2026, 9, 11));
    expect([c.y, c.m, c.d], [1743, 1, 1]);
    final e = toEthiopian(DateTime(2026, 10, 5));
    expect([e.y, e.m, e.d], [2019, 1, 25]);
    expect(fromEthiopian(2019, 1, 1), DateTime(2026, 9, 11));
  });
}
