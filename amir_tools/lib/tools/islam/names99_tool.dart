import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/pattern.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// أسماء الله الحسنى — القائمة المشهورة من رواية الترمذي
const names99 = [
  'الرحمن', 'الرحيم', 'الملك', 'القدوس', 'السلام', 'المؤمن', 'المهيمن', 'العزيز', 'الجبار', 'المتكبر',
  'الخالق', 'البارئ', 'المصور', 'الغفار', 'القهار', 'الوهاب', 'الرزاق', 'الفتاح', 'العليم', 'القابض',
  'الباسط', 'الخافض', 'الرافع', 'المعز', 'المذل', 'السميع', 'البصير', 'الحكم', 'العدل', 'اللطيف',
  'الخبير', 'الحليم', 'العظيم', 'الغفور', 'الشكور', 'العلي', 'الكبير', 'الحفيظ', 'المقيت', 'الحسيب',
  'الجليل', 'الكريم', 'الرقيب', 'المجيب', 'الواسع', 'الحكيم', 'الودود', 'المجيد', 'الباعث', 'الشهيد',
  'الحق', 'الوكيل', 'القوي', 'المتين', 'الولي', 'الحميد', 'المحصي', 'المبدئ', 'المعيد', 'المحيي',
  'المميت', 'الحي', 'القيوم', 'الواجد', 'الماجد', 'الواحد', 'الأحد', 'الصمد', 'القادر', 'المقتدر',
  'المقدم', 'المؤخر', 'الأول', 'الآخر', 'الظاهر', 'الباطن', 'الوالي', 'المتعالي', 'البر', 'التواب',
  'المنتقم', 'العفو', 'الرؤوف', 'مالك الملك', 'ذو الجلال والإكرام', 'المقسط', 'الجامع', 'الغني', 'المغني', 'المانع',
  'الضار', 'النافع', 'النور', 'الهادي', 'البديع', 'الباقي', 'الوارث', 'الرشيد', 'الصبور',
];

class Names99Tool extends StatefulWidget {
  const Names99Tool({super.key});
  @override
  State<Names99Tool> createState() => _Names99ToolState();
}

class _Names99ToolState extends State<Names99Tool> {
  String _q = '';

  String _norm(String s) => s.replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll(RegExp(r'[ً-ٟ]'), '');

  @override
  Widget build(BuildContext context) {
    final list = [for (var i = 0; i < names99.length; i++) (i + 1, names99[i])].where((e) => _q.isEmpty || _norm(e.$2).contains(_norm(_q))).toList();
    return ToolList(children: [
      NoteBox(
          t('قال رسول الله ﷺ: «إنّ لله تسعةً وتسعين اسمًا، مائةً إلا واحدًا، من أحصاها دخل الجنة» — متفق عليه. والقائمة دي هي المشهورة من رواية الترمذي.',
              'قال رسول الله ﷺ: «إنّ لله تسعةً وتسعين اسمًا، مائةً إلا واحدًا، من أحصاها دخل الجنة» — متفق عليه. وهذه القائمة هي المشهورة من رواية الترمذي.',
              'The Prophet ﷺ said: «إنّ لله تسعةً وتسعين اسمًا، مائةً إلا واحدًا، من أحصاها دخل الجنة» — Allah has ninety-nine names; whoever learns them enters Paradise (al-Bukhari and Muslim). This is the well-known list narrated by al-Tirmidhi.'),
          kind: NoteKind.info),
      TextField(
        onChanged: (v) => setState(() => _q = v),
        decoration: InputDecoration(hintText: t('فتّش عن اسم…', 'ابحث عن اسم…', 'Search a name (Arabic)…'), prefixIcon: const Icon(Icons.search_rounded)),
      ),
      const SizedBox(height: 12),
      GoldFrame(
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            for (final (n, name) in list)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _show(n, name),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SD.gold.withValues(alpha: .7)),
                    color: SD.gold.withValues(alpha: .08),
                  ),
                  child: Stack(children: [
                    PositionedDirectional(top: 4, end: 8, child: Text('$n', style: const TextStyle(fontSize: 11, color: SD.gold))),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: FittedBox(child: GoldText(name, size: 22)),
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
      Center(child: Text(tr('${names99.length} اسمًا', '${names99.length} names'), style: const TextStyle(fontWeight: FontWeight.w700))),
    ]);
  }

  void _show(int n, String name) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr('الاسم رقم $n', 'Name no. $n'), style: const TextStyle(color: SD.gold)),
            const SizedBox(height: 10),
            GoldText(name, size: 46),
            const SizedBox(height: 10),
            const Text('جلّ جلاله', style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          actions: [
            TextButton(onPressed: () => copyText(name), child: Text(tr('انسخ', 'Copy'))),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(t('تمام', 'حسنًا', 'OK'))),
          ],
        ),
      );
}
