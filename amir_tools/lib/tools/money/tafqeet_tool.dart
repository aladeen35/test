import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// صيغ اسم العملة حسب العدد: مفرد، مثنى، جمع (3–10)، تمييز (11–99)
class _Unit {
  final String one, two, few, many;
  const _Unit(this.one, this.two, this.few, this.many);
}

const _units = {
  'SDG': (_Unit('جنيه سوداني', 'جنيهان سودانيان', 'جنيهات سودانية', 'جنيهًا سودانيًا'), _Unit('قرش', 'قرشان', 'قروش', 'قرشًا'), 'Sudanese Pounds', 'Piastres'),
  'USD': (_Unit('دولار أمريكي', 'دولاران أمريكيان', 'دولارات أمريكية', 'دولارًا أمريكيًا'), _Unit('سنت', 'سنتان', 'سنتات', 'سنتًا'), 'US Dollars', 'Cents'),
  'SAR': (_Unit('ريال سعودي', 'ريالان سعوديان', 'ريالات سعودية', 'ريالًا سعوديًا'), _Unit('هللة', 'هللتان', 'هللات', 'هللة'), 'Saudi Riyals', 'Halalas'),
  'AED': (_Unit('درهم إماراتي', 'درهمان إماراتيان', 'دراهم إماراتية', 'درهمًا إماراتيًا'), _Unit('فلس', 'فلسان', 'فلوس', 'فلسًا'), 'UAE Dirhams', 'Fils'),
};
const _curNames = {'SDG': '🇸🇩 جنيه سوداني', 'USD': '🇺🇸 دولار', 'SAR': '🇸🇦 ريال سعودي', 'AED': '🇦🇪 درهم'};

const _ones = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة'];
const _teens = ['عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'];
const _tens = ['', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
const _hundreds = ['', 'مائة', 'مائتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة'];

String _below1000(int n) {
  final parts = <String>[];
  if (n >= 100) parts.add(_hundreds[n ~/ 100]);
  final r = n % 100;
  if (r > 0) {
    if (r < 10) {
      parts.add(_ones[r]);
    } else if (r < 20) {
      parts.add(_teens[r - 10]);
    } else {
      parts.add(r % 10 == 0 ? _tens[r ~/ 10] : '${_ones[r % 10]} و${_tens[r ~/ 10]}');
    }
  }
  return parts.join(' و');
}

/// العدد بالحروف العربية (حتى ما قبل التريليون)
String arabicWords(int n) {
  if (n == 0) return 'صفر';
  const scales = [
    (1000000000, 'مليار', 'ملياران', 'مليارات'),
    (1000000, 'مليون', 'مليونان', 'ملايين'),
    (1000, 'ألف', 'ألفان', 'آلاف'),
  ];
  final parts = <String>[];
  var rest = n;
  for (final (v, one, two, few) in scales) {
    final c = rest ~/ v;
    rest %= v;
    if (c == 0) continue;
    if (c == 1) {
      parts.add(one);
    } else if (c == 2) {
      parts.add(two);
    } else if (c <= 10) {
      parts.add('${_below1000(c)} $few');
    } else {
      parts.add('${_below1000(c)} $one');
    }
  }
  if (rest > 0) parts.add(_below1000(rest));
  return parts.join(' و');
}

String _withUnit(int n, _Unit u) {
  if (n == 1) return '${u.one} واحد';
  if (n == 2) return u.two;
  final l2 = n % 100;
  final name = (l2 >= 3 && l2 <= 10) ? u.few : (l2 >= 11 ? u.many : u.one);
  return '${arabicWords(n)} $name';
}

const _enOnes = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
const _enTens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

String _en1000(int n) {
  final p = <String>[];
  if (n >= 100) p.add('${_enOnes[n ~/ 100]} Hundred');
  final r = n % 100;
  if (r > 0) p.add(r < 20 ? _enOnes[r] : '${_enTens[r ~/ 10]}${r % 10 > 0 ? '-${_enOnes[r % 10]}' : ''}');
  return p.join(' and ');
}

String englishWords(int n) {
  if (n == 0) return 'Zero';
  final p = <String>[];
  for (final (v, name) in [(1000000000, 'Billion'), (1000000, 'Million'), (1000, 'Thousand')]) {
    if (n >= v) {
      p.add('${_en1000(n ~/ v)} $name');
      n %= v;
    }
  }
  if (n > 0) p.add(_en1000(n));
  return p.join(' ');
}

/// تفقيط المبالغ للشيكات والفواتير
class TafqeetTool extends StatefulWidget {
  const TafqeetTool({super.key});
  @override
  State<TafqeetTool> createState() => _TafqeetToolState();
}

class _TafqeetToolState extends State<TafqeetTool> {
  final _c = TextEditingController(text: '1250750.50');
  String _cur = 'SDG';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = parseNum(_c.text);
    final whole = v.floor();
    final frac = ((v - whole) * 100).round();
    final (main, sub, enMain, enSub) = _units[_cur]!;
    final tooBig = whole >= 1000000000000;
    final ar = tooBig
        ? 'الرقم كبير شديد 😅'
        : 'فقط ${whole == 0 && frac > 0 ? '' : _withUnit(whole, main)}${frac > 0 ? '${whole > 0 ? ' و' : ''}${_withUnit(frac, sub)}' : ''} لا غير';
    final en = tooBig ? '—' : 'Only ${englishWords(whole)} $enMain${frac > 0 ? ' and ${englishWords(frac)} $enSub' : ''} Only';

    return ToolList(children: [
      SCard(
        title: 'أكتب المبلغ',
        icon: Icons.edit_rounded,
        color: SD.coffee,
        child: Column(children: [
          NumField('المبلغ', _c, onChanged: (_) => setState(() {}), hint: 'مثلًا 1250750.50'),
          SegmentedButton<String>(
            segments: [for (final e in _curNames.entries) ButtonSegment(value: e.key, label: Text(e.value.split(' ').first))],
            selected: {_cur},
            onSelectionChanged: (s) => setState(() => _cur = s.first),
          ),
          const SizedBox(height: 6),
          Text(_curNames[_cur]!, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
      ResultHero(label: 'المبلغ بالحروف', value: fmt(v, 2), sub: ar),
      SCard(
        title: 'للشيك والفاتورة',
        icon: Icons.receipt_long_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SelectableText(ar, style: const TextStyle(fontSize: 18, height: 1.8, fontWeight: FontWeight.w700)),
          const Divider(),
          Directionality(textDirection: TextDirection.ltr, child: SelectableText(en, style: const TextStyle(fontSize: 15, height: 1.6))),
          const SizedBox(height: 10),
          InfoRow('الرقم بالأرقام العربية', toArabicDigits(fmt(v, 2))),
          InfoRow('الجزء الصحيح', arabicWords(whole)),
          if (frac > 0) InfoRow('الكسر (${sub.many})', arabicWords(frac)),
          InfoRow('عدد الخانات', '${whole.toString().length} خانة'),
        ]),
      ),
      ShareBar(() => '$ar\n$en'),
      const NoteBox('راجع النص قبل ما تكتبو في الشيك — الصياغة على الطريقة المتّبعة في البنوك («فقط … لا غير»).', kind: NoteKind.tip),
    ]);
  }
}
