import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';

/// محوّل المقاسات — جداول تحويل قياسية منشورة على نطاق واسع (تقريبية؛ تختلف حسب الماركة)

// ───── الأحذية (للكبار) ─────
/// مقاس UK → EU (الجدول الشائع)
final _shoeUkEu = <double, double>{
  2.5: 35, 3: 35.5, 3.5: 36, 4: 37, 4.5: 37.5, 5: 38, 5.5: 38.5, 6: 39, 6.5: 40, 7: 40.5, 7.5: 41,
  8: 42, 8.5: 42.5, 9: 43, 9.5: 44, 10: 44.5, 10.5: 45, 11: 46, 11.5: 46.5, 12: 47, 12.5: 48, 13: 48.5,
};

class ShoeRow {
  final double uk, eu;
  const ShoeRow(this.uk, this.eu);
  double get usMen => uk + 1;
  double get usWomen => uk + 2.5;

  /// طول القدم التقريبي بالسنتيمتر
  double get cm => ((22.1 + (uk - 2.5) * 0.846) * 10).roundToDouble() / 10;
  double col(int i) => switch (i) { 0 => eu, 1 => usMen, 2 => usWomen, 3 => uk, _ => cm };
}

final shoeRows = [for (final e in _shoeUkEu.entries) ShoeRow(e.key, e.value)];
List<String> get shoeCols => ['EU', t('US رجالي', 'US رجالي', 'US men'), t('US نسائي', 'US نسائي', 'US women'), 'UK', t('سم', 'سم', 'cm')];

// ───── الملابس ─────
const _letters = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

/// قمصان رجالي: (الياقة إنش US/UK، الياقة سم EU، الصدر سم)
const _menShirts = [
  ('13.5–14', '34–35', '81–86'),
  ('14–14.5', '36–37', '86–94'),
  ('15–15.5', '38–39', '96–102'),
  ('16–16.5', '41–42', '104–109'),
  ('17–17.5', '43–44', '112–117'),
  ('18–18.5', '45–46', '119–124'),
  ('19–19.5', '47–48', '127–132'),
];

/// فساتين نسائي: (US، UK، EU)
const _womenDresses = [
  ('0–2', '4–6', '32–34'),
  ('4–6', '8–10', '36–38'),
  ('8–10', '12–14', '40–42'),
  ('12–14', '16–18', '44–46'),
  ('16', '20', '48'),
  ('18', '22', '50'),
  ('20', '24', '52'),
];

// ───── الأطفال حسب العمر ─────
/// (العمر بالشهور من، إلى، طول/مقاس EU، مقاس US)
const _kids = [
  (0, 3, '56–62', '0–3M'),
  (3, 6, '62–68', '3–6M'),
  (6, 9, '68–74', '6–9M'),
  (9, 12, '74–80', '9–12M'),
  (12, 18, '80–86', '12–18M'),
  (18, 24, '86–92', '18–24M'),
  (24, 36, '92–98', '2T–3T'),
  (36, 48, '98–104', '3T–4T'),
  (48, 60, '104–110', '4T–5'),
  (60, 72, '110–116', '5–6'),
  (72, 84, '116–122', '6–7'),
  (84, 96, '122–128', '7–8'),
  (96, 108, '128–134', '8'),
  (108, 120, '134–140', '10'),
  (120, 132, '140–146', '10–12'),
  (132, 144, '146–152', '12'),
  (144, 156, '152–158', '14'),
  (156, 168, '158–164', '14–16'),
];

String kidAge(int from, int to) {
  if (to <= 24) return isEn ? '$from–$to months' : '$from–$to ${t('شهر', 'شهرًا', '')}';
  return isEn ? '${from ~/ 12}–${to ~/ 12} years' : '${from ~/ 12}–${to ~/ 12} ${t('سنة', 'سنوات', '')}';
}

// ───── الخواتم (US/كندا و ISO 8653 الأوروبي) ─────
/// القطر الداخلي بالملم من مقاس US
double ringDiameterFromUs(double us) => 11.63 + 0.8128 * us;
double ringUsFromDiameter(double d) => (d - 11.63) / 0.8128;

/// المقاس الأوروبي = المحيط الداخلي بالملم
double ringEuFromDiameter(double d) => d * math.pi;

class SizesTool extends StatefulWidget {
  const SizesTool({super.key});
  @override
  State<SizesTool> createState() => _SizesToolState();
}

class _SizesToolState extends State<SizesTool> {
  int shoeSys = 0;
  int shoeIdx = 9;
  int clothes = 0; // 0 رجالي، 1 نسائي
  int letter = 2;
  int ringMode = 1; // 0 ملم، 1 US، 2 EU
  int kidIdx = 6;
  final footC = TextEditingController(), ringC = TextEditingController(text: '7');

  @override
  void dispose() {
    footC.dispose();
    ringC.dispose();
    super.dispose();
  }

  String _n(double v) => fmt(v, 1);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tab = s.getData<int>('sizes_tab') ?? 0;
    final tabs = [
      (t('الجزم', 'الأحذية', 'Shoes'), Icons.ice_skating_rounded),
      (t('الهدوم', 'الملابس', 'Clothes'), Icons.checkroom_rounded),
      (t('الخواتم', 'الخواتم', 'Rings'), Icons.diamond_rounded),
      (t('الأطفال', 'الأطفال', 'Kids'), Icons.child_care_rounded),
    ];
    return ToolList(children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (var i = 0; i < tabs.length; i++)
          ChoiceChip(
            avatar: Icon(tabs[i].$2, size: 18),
            label: Text(tabs[i].$1),
            selected: tab == i,
            selectedColor: SD.gold.withValues(alpha: .3),
            onSelected: (_) => s.setData('sizes_tab', i),
          ),
      ]),
      const SizedBox(height: 12),
      ...switch (tab) { 0 => _shoes(), 1 => _clothes(), 2 => _rings(), _ => _kidsView() },
      NoteBox(
          t('المقاسات بتختلف من ماركة لماركة ومن بلد لبلد — الجداول دي تقريبية من جداول التحويل المنشورة. الأحسن تشوف جدول مقاسات المحل أو الماركة نفسها وتجرّب قبل ما تشتري.',
              'تختلف المقاسات بين الماركات والبلدان — هذه الجداول تقريبية من جداول التحويل الشائعة. الأفضل مراجعة جدول مقاسات المتجر أو الماركة نفسها والتجربة قبل الشراء.',
              'Sizes vary by brand and country — these are approximate, from widely published conversion charts. Always check the specific brand or store size chart and try before buying.'),
          kind: NoteKind.warn),
    ]);
  }

  // ───── الأحذية ─────
  List<Widget> _shoes() {
    final r = shoeRows[shoeIdx];
    final foot = parseNum(footC.text);
    ShoeRow? rec;
    if (foot > 0) {
      for (final x in shoeRows) {
        if (x.cm >= foot) {
          rec = x;
          break;
        }
      }
    }
    return [
      SCard(
        title: t('حوّل مقاس الجزمة', 'تحويل مقاس الحذاء', 'Convert shoe size'),
        icon: Icons.swap_horiz_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: _drop<int>(
                t('النظام', 'النظام', 'System'),
                shoeSys,
                [for (var i = 0; i < 5; i++) (i, shoeCols[i])],
                (v) => setState(() => shoeSys = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _drop<int>(
                t('المقاس', 'المقاس', 'Size'),
                shoeIdx,
                [for (var i = 0; i < shoeRows.length; i++) (i, _n(shoeRows[i].col(shoeSys)))],
                (v) => setState(() => shoeIdx = v),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          StatGrid([
            for (var i = 0; i < 5; i++)
              if (i != shoeSys) StatChip(_n(r.col(i)), shoeCols[i], color: [SD.nile, SD.green, SD.pink, SD.indigo, SD.coffee][i]),
          ], columns: 2),
        ]),
      ),
      SCard(
        title: t('من طول رجلك', 'من طول القدم', 'From foot length'),
        icon: Icons.straighten_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(t('طول القدم (من الكعب لأطول صباع)', 'طول القدم (من الكعب لأطول إصبع)', 'Foot length (heel to longest toe)'), footC,
              suffix: t('سم', 'سم', 'cm'), onChanged: (_) => setState(() {})),
          if (foot > 0)
            rec == null
                ? NoteBox(t('الطول دا برّه الجدول', 'هذا الطول خارج الجدول', 'This length is outside the chart'))
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    InfoRow('EU', _n(rec.eu), icon: Icons.check_circle_rounded, valueColor: SD.green),
                    InfoRow(shoeCols[1], _n(rec.usMen)),
                    InfoRow(shoeCols[2], _n(rec.usWomen)),
                    InfoRow('UK', _n(rec.uk)),
                  ]),
          Text(
              t('قيس رجلك آخر اليوم وانت واقف، وخُد الرجل الأطول. لو بين مقاسين خُد الأكبر.',
                  'قِس قدمك في آخر اليوم وأنت واقف، واعتمد القدم الأطول. إن كنت بين مقاسين فاختر الأكبر.',
                  'Measure at the end of the day while standing, use the longer foot. Between two sizes? Pick the larger.'),
              style: const TextStyle(fontSize: 12.5)),
        ]),
      ),
      SCard(
        title: t('الجدول الكامل', 'الجدول الكامل', 'Full chart'),
        icon: Icons.table_chart_rounded,
        color: SD.nile,
        child: _SizeTable(shoeCols, [for (final x in shoeRows) [for (var i = 0; i < 5; i++) _n(x.col(i))]], highlight: shoeIdx,
            onTap: (i) => setState(() => shoeIdx = i)),
      ),
    ];
  }

  // ───── الملابس ─────
  List<Widget> _clothes() {
    final men = clothes == 0;
    final headers = men
        ? [t('الحرف', 'الحرف', 'Letter'), t('الياقة US/UK (إنش)', 'الياقة US/UK (إنش)', 'Collar US/UK (in)'), t('الياقة EU (سم)', 'الياقة EU (سم)', 'Collar EU (cm)'), t('الصدر (سم)', 'الصدر (سم)', 'Chest (cm)')]
        : [t('الحرف', 'الحرف', 'Letter'), 'US', 'UK', 'EU'];
    final rows = [
      for (var i = 0; i < _letters.length; i++)
        men ? [_letters[i], _menShirts[i].$1, _menShirts[i].$2, _menShirts[i].$3] : [_letters[i], _womenDresses[i].$1, _womenDresses[i].$2, _womenDresses[i].$3],
    ];
    return [
      SegmentedButton<int>(
        segments: [
          ButtonSegment(value: 0, icon: const Icon(Icons.man_rounded), label: Text(t('قمصان رجالي', 'قمصان رجالية', "Men's shirts"), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ButtonSegment(value: 1, icon: const Icon(Icons.woman_rounded), label: Text(t('فساتين نسائي', 'فساتين نسائية', "Women's dresses"), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
        selected: {clothes},
        onSelectionChanged: (v) => setState(() => clothes = v.first),
      ),
      const SizedBox(height: 12),
      SCard(
        title: t('اختار المقاس', 'اختر المقاس', 'Pick a size'),
        icon: Icons.checkroom_rounded,
        color: men ? SD.nile : SD.pink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < _letters.length; i++) PickChip(_letters[i], letter == i, () => setState(() => letter = i), color: men ? SD.nile : SD.pink),
          ]),
          const SizedBox(height: 8),
          for (var c = 1; c < headers.length; c++) InfoRow(headers[c], rows[letter][c]),
        ]),
      ),
      SCard(
        title: t('الجدول الكامل', 'الجدول الكامل', 'Full chart'),
        icon: Icons.table_chart_rounded,
        color: SD.coffee,
        child: _SizeTable(headers, rows, highlight: letter, onTap: (i) => setState(() => letter = i)),
      ),
      NoteBox(
          men
              ? t('قمصان الرجال بتتقاس بمحيط الرقبة (الياقة) والصدر. الأرقام مدى تقريبي.', 'تُقاس القمصان الرجالية بمحيط الرقبة (الياقة) والصدر. الأرقام مدى تقريبي.',
                  "Men's shirts are sized by neck (collar) and chest. Numbers are approximate ranges.")
              : t('القاعدة الشائعة: UK = US + 4، و EU = US + 32 تقريبًا.', 'القاعدة الشائعة: UK = US + 4، و EU = US + 32 تقريبًا.',
                  'Common rule of thumb: UK = US + 4, EU ≈ US + 32.'),
          kind: NoteKind.tip),
    ];
  }

  // ───── الخواتم ─────
  List<Widget> _rings() {
    final v = parseNum(ringC.text);
    double? d;
    if (v > 0) {
      d = switch (ringMode) { 0 => v, 1 => ringDiameterFromUs(v), _ => v / math.pi };
      if (d < 10 || d > 30) d = null;
    }
    final usList = [for (var u = 3.0; u <= 13; u += .5) u];
    final nearest = d == null ? -1 : usList.indexWhere((u) => (u - ringUsFromDiameter(d!)).abs() <= .25);
    return [
      SCard(
        title: t('حوّل مقاس الخاتم', 'تحويل مقاس الخاتم', 'Convert ring size'),
        icon: Icons.diamond_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0, label: Text(t('قطر ملم', 'قطر ملم', 'Ø mm'), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const ButtonSegment(value: 1, label: Text('US')),
              const ButtonSegment(value: 2, label: Text('EU')),
            ],
            selected: {ringMode},
            onSelectionChanged: (x) => setState(() {
              // تحويل القيمة الحالية للنظام الجديد
              if (d != null) {
                ringC.text = switch (x.first) { 0 => fmt(d, 1), 1 => fmt((ringUsFromDiameter(d) * 4).round() / 4, 2), _ => fmt(ringEuFromDiameter(d), 0) };
              }
              ringMode = x.first;
            }),
          ),
          const SizedBox(height: 12),
          NumField(
              switch (ringMode) {
                0 => t('القطر الداخلي', 'القطر الداخلي', 'Inner diameter'),
                1 => t('مقاس أمريكي', 'المقاس الأمريكي', 'US size'),
                _ => t('مقاس أوروبي', 'المقاس الأوروبي', 'EU size'),
              },
              ringC,
              suffix: ringMode == 0 ? t('ملم', 'ملم', 'mm') : null,
              onChanged: (_) => setState(() {})),
          if (d == null)
            NoteBox(t('اكتب رقم صحيح', 'أدخل رقمًا صحيحًا', 'Enter a valid number'))
          else ...[
            InfoRow(t('القطر الداخلي', 'القطر الداخلي', 'Inner diameter'), '${fmt(d, 1)} ${t('ملم', 'ملم', 'mm')}', icon: Icons.circle_outlined),
            InfoRow(t('المحيط الداخلي', 'المحيط الداخلي', 'Inner circumference'), '${fmt(ringEuFromDiameter(d), 1)} ${t('ملم', 'ملم', 'mm')}', icon: Icons.loop_rounded),
            InfoRow(t('مقاس أمريكي (US)', 'المقاس الأمريكي (US)', 'US size'), fmt((ringUsFromDiameter(d) * 4).round() / 4, 2), icon: Icons.flag_rounded, valueColor: SD.nile),
            InfoRow(t('مقاس أوروبي (EU)', 'المقاس الأوروبي (EU)', 'EU size (ISO)'), fmt(ringEuFromDiameter(d), 0), icon: Icons.euro_rounded, valueColor: SD.green),
          ],
          Text(
              t('طريقة القياس: لفّ خيط على صباعك، علّم مكان التلاقي وقيس الطول بالملم = المحيط = المقاس الأوروبي. أو قيس القطر الداخلي لخاتم بيجيك.',
                  'طريقة القياس: لُفّ خيطًا حول إصبعك، علّم نقطة التقاء الطرفين وقِس الطول بالملم = المحيط = المقاس الأوروبي. أو قِس القطر الداخلي لخاتم يناسبك.',
                  'How to measure: wrap a string around your finger, mark where it meets and measure in mm = circumference = EU size. Or measure the inner diameter of a ring that fits.'),
              style: const TextStyle(fontSize: 12.5)),
        ]),
      ),
      SCard(
        title: t('الجدول الكامل', 'الجدول الكامل', 'Full chart'),
        icon: Icons.table_chart_rounded,
        color: SD.nile,
        child: _SizeTable(
          ['US', t('القطر ملم', 'القطر ملم', 'Ø mm'), 'EU'],
          [for (final u in usList) [fmt(u, 1), fmt(ringDiameterFromUs(u), 1), fmt(ringEuFromDiameter(ringDiameterFromUs(u)), 0)]],
          highlight: nearest,
          onTap: (i) => setState(() {
            ringMode = 1;
            ringC.text = fmt(usList[i], 1);
          }),
        ),
      ),
    ];
  }

  // ───── الأطفال ─────
  List<Widget> _kidsView() {
    final k = _kids[kidIdx];
    return [
      SCard(
        title: t('مقاس الطفل حسب العمر', 'مقاس الطفل حسب العمر', "Kids' size by age"),
        icon: Icons.child_care_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _drop<int>(t('العمر', 'العمر', 'Age'), kidIdx, [for (var i = 0; i < _kids.length; i++) (i, kidAge(_kids[i].$1, _kids[i].$2))],
              (v) => setState(() => kidIdx = v)),
          const SizedBox(height: 10),
          InfoRow(t('مقاس أوروبي = الطول (سم)', 'المقاس الأوروبي = الطول (سم)', 'EU size = height (cm)'), k.$3, icon: Icons.height_rounded, valueColor: SD.green),
          InfoRow(t('مقاس أمريكي', 'المقاس الأمريكي', 'US size'), k.$4, icon: Icons.flag_rounded, valueColor: SD.nile),
          InfoRow(t('بريطاني (UK)', 'بريطاني (UK)', 'UK'), kidAge(k.$1, k.$2), icon: Icons.label_rounded, hint: t('بالعمر مباشرة', 'بالعمر مباشرة', 'labelled by age')),
        ]),
      ),
      SCard(
        title: t('الجدول الكامل', 'الجدول الكامل', 'Full chart'),
        icon: Icons.table_chart_rounded,
        color: SD.coffee,
        child: _SizeTable(
          [t('العمر', 'العمر', 'Age'), t('EU / الطول', 'EU / الطول', 'EU / height'), 'US'],
          [for (final x in _kids) [kidAge(x.$1, x.$2), x.$3, x.$4]],
          highlight: kidIdx,
          onTap: (i) => setState(() => kidIdx = i),
        ),
      ),
      NoteBox(
          t('الأطفال بيختلفوا كتير — اشتري بالطول والوزن مش بالعمر بس. المقاس الأوروبي معناه طول الطفل بالسنتي.',
              'يختلف الأطفال كثيرًا — اشترِ حسب الطول والوزن لا العمر فقط. المقاس الأوروبي يعني طول الطفل بالسنتيمتر.',
              'Children vary a lot — buy by height and weight, not only age. The EU size means the child\'s height in cm.'),
          kind: NoteKind.tip),
    ];
  }

  Widget _drop<T>(String label, T value, List<(T, String)> items, ValueChanged<T> onChanged) => InputDecorator(
        decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 4, 8, 4)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            items: [for (final it in items) DropdownMenuItem(value: it.$1, child: Text(it.$2, maxLines: 1, overflow: TextOverflow.ellipsis))],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );
}

/// جدول مقاسات بسيط مع إبراز صف
class _SizeTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final int highlight;
  final ValueChanged<int>? onTap;
  const _SizeTable(this.headers, this.rows, {this.highlight = -1, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hl = readable(context, SD.gold);
    Widget cell(String s, {bool head = false, bool on = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(s,
                maxLines: head ? 2 : 1,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: head ? 12 : 13.5, fontWeight: head || on ? FontWeight.w800 : FontWeight.w500, color: on ? hl : null)),
          ),
        );
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(horizontalInside: BorderSide(color: SD.gold.withValues(alpha: .2))),
      children: [
        TableRow(
          decoration: BoxDecoration(color: SD.gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(8)),
          children: [for (final h in headers) cell(h, head: true)],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: i == highlight ? BoxDecoration(color: SD.gold.withValues(alpha: .18)) : null,
            children: [
              for (final c in rows[i])
                TableRowInkWell(onTap: onTap == null ? null : () => onTap!(i), child: cell(c, on: i == highlight)),
            ],
          ),
      ],
    );
  }
}
