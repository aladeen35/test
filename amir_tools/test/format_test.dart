import 'package:flutter_test/flutter_test.dart';
import 'package:amir_tools/core/format.dart';
import 'package:amir_tools/tools/money/tafqeet_tool.dart';

void main() {
  test('fmt', () {
    expect(fmt(1234567.891, 2), '1,234,567.89');
    expect(fmt(1200.0, 2), '1,200');
    expect(parseNum('١٬٢٣٤'), 0); // فاصلة عربية غير مدعومة → 0
    expect(parseNum('1,250.5'), 1250.5);
  });
  test('tafqeet', () {
    expect(arabicWords(1250750), 'مليون ومائتان وخمسون ألفًا وسبعمائة وخمسون');
    expect(arabicWords(100000), 'مائة ألف');
    expect(arabicWords(21), 'واحد وعشرون');
    expect(arabicWords(3000), 'ثلاثة آلاف');
    expect(arabicWords(11000), 'أحد عشر ألفًا');
    expect(arabicWords(2000000), 'مليونان');
    expect(englishWords(1250750), 'One Million Two Hundred and Fifty Thousand Seven Hundred and Fifty');
    print(arabicWords(1250750));
  });
}
