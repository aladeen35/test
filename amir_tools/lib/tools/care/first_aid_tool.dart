import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'care_common.dart';
import 'first_aid_data.dart';

/// نص الموضوع كاملًا للمشاركة
String firstAidText(FaTopic f) {
  final b = StringBuffer('🩹 ${f.name}\n');
  var n = 0;
  for (final s in f.steps) {
    final x = tr(s.$1, s.$2);
    if (x.startsWith('#')) {
      n = 0;
      b.writeln('\n▪ ${x.substring(1)}');
    } else {
      b.writeln('${++n}. $x');
    }
  }
  b.writeln('\n🚑 ${t('اتصل بالإسعاف لو:', 'اتصل بالإسعاف إذا:', 'Call emergency services if:')}');
  for (final s in f.callWhen) {
    b.writeln('• ${tr(s.$1, s.$2)}');
  }
  if (f.donts.isNotEmpty) {
    b.writeln('\n⛔ ${t('ما تعمل:', 'لا تفعل:', "Don't:")}');
    for (final s in f.donts) {
      b.writeln('• ${tr(s.$1, s.$2)}');
    }
  }
  b.writeln('\n${tr('المصدر', 'Source')}: IFRC 2020 / WHO / Red Cross');
  return b.toString().trim();
}

class FirstAidTool extends StatefulWidget {
  /// يفتح موضوعًا مباشرة (للاختبار أو الروابط)
  final String? initialTopic;
  const FirstAidTool({super.key, this.initialTopic});
  @override
  State<FirstAidTool> createState() => _FirstAidToolState();
}

class _FirstAidToolState extends State<FirstAidTool> {
  final _q = TextEditingController();
  late String? _open = widget.initialTopic;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final big = s.getData<bool>('first_aid_big') == true;
    final open = firstAidTopics.where((f) => f.id == _open).firstOrNull;
    if (open != null) return _detail(s, open, big);
    final list = firstAidTopics.where((f) => f.matches(_q.text.trim())).toList();
    return ToolList(children: [
      NoteBox(
        t('في الخطر: اتصل بالإسعاف أول حاجة. الدليل دا للمساعدة لحدي ما يجي الإسعاف وما بغني عن دورة إسعافات أولية.',
            'في الخطر: اتصل بالإسعاف أولًا. هذا الدليل للمساعدة حتى وصول الإسعاف ولا يغني عن دورة إسعافات أولية معتمدة.',
            "In danger: call emergency services first. This guide helps until help arrives and doesn't replace a certified first aid course."),
        kind: NoteKind.danger,
      ),
      TextField(
        controller: _q,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: t('فتّش: حرق، شرقة، عقرب…', 'ابحث: حرق، اختناق، عقرب…', 'Search: burn, choking, scorpion…'),
          suffixIcon: _q.text.isEmpty ? null : IconButton(onPressed: () => setState(_q.clear), icon: const Icon(Icons.close_rounded)),
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: big,
        onChanged: (v) => s.setData('first_aid_big', v),
        secondary: const Icon(Icons.format_size_rounded),
        title: Text(t('خط كبير', 'خط كبير', 'Large text')),
      ),
      if (list.isEmpty) NoteBox(t('ما لقينا حاجة بالكلمة دي', 'لا نتائج لهذه الكلمة', 'No results for that word')),
      for (final f in list)
        Card(
          child: CTile(
            icon: f.icon,
            color: f.color,
            title: f.name,
            sub: tr(f.steps.firstWhere((x) => !x.$1.startsWith('#')).$1, f.steps.firstWhere((x) => !x.$1.startsWith('#')).$2),
            onTap: () {
              s.awardDaily('first_aid_read', 5, t('قريت دليل الإسعافات', 'قراءة دليل الإسعافات', 'Read the first aid guide'));
              s.bump('first_aid_topics');
              setState(() => _open = f.id);
            },
            actions: const [Icon(Icons.chevron_right_rounded)],
          ),
        ),
      const SizedBox(height: 8),
      _sources(),
    ]);
  }

  Widget _sources() => SCard(
        title: t('المصادر', 'المصادر', 'Sources'),
        icon: Icons.menu_book_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final x in faSources)
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $x', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12.5))),
          const SizedBox(height: 4),
          const ReviewedLine(toolId: 'first_aid'),
        ]),
      );

  Widget _detail(AppState s, FaTopic f, bool big) {
    final fs = big ? 20.0 : 15.0;
    var n = 0;
    final rows = <Widget>[];
    for (final st in f.steps) {
      final x = tr(st.$1, st.$2);
      if (x.startsWith('#')) {
        n = 0;
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(x.substring(1), style: TextStyle(fontSize: fs + 2, fontWeight: FontWeight.w800, color: readable(context, f.color))),
        ));
        continue;
      }
      n++;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: big ? 36 : 28,
            height: big ? 36 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
            child: Text('$n', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: big ? 18 : 14)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(x, style: TextStyle(fontSize: fs, height: 1.5))),
        ]),
      ));
    }
    Widget box(String title, IconData icon, Color c, List<(String, String)> items) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(18), border: Border.all(color: c, width: 1.6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(icon, color: readable(context, c)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontSize: fs + 1, fontWeight: FontWeight.w800, color: readable(context, c)))),
            ]),
            const SizedBox(height: 8),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: TextStyle(fontSize: fs, fontWeight: FontWeight.w900)),
                  Expanded(child: Text(tr(i.$1, i.$2), style: TextStyle(fontSize: fs, height: 1.45))),
                ]),
              ),
          ]),
        );
    return ToolList(children: [
      Row(children: [
        IconButton(
          tooltip: t('رجوع', 'رجوع', 'Back'),
          onPressed: () => setState(() => _open = null),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(child: Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: big ? 24 : 20, fontWeight: FontWeight.w800))),
        IconButton(
          tooltip: t('خط كبير', 'خط كبير', 'Large text'),
          onPressed: () => s.setData('first_aid_big', !big),
          icon: Icon(big ? Icons.text_decrease_rounded : Icons.text_increase_rounded),
        ),
      ]),
      const SizedBox(height: 8),
      box(t('🚑 اتصل بالإسعاف لو…', '🚑 اتصل بالإسعاف إذا…', '🚑 Call emergency services when…'), Icons.emergency_rounded, SD.red, f.callWhen),
      SCard(
        title: t('الخطوات', 'الخطوات', 'Steps'),
        icon: f.icon,
        color: f.color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
      ),
      if (f.donts.isNotEmpty) box(t('⛔ ما تعمل', '⛔ لا تفعل', "⛔ Don't"), Icons.block_rounded, SD.orange, f.donts),
      ShareBar(() => firstAidText(f)),
      const SizedBox(height: 12),
      NoteBox(
        t('الأرقام المحلية للإسعاف في أداة «أرقام الطوارئ». الدليل ما بغني عن التدريب العملي.', 'أرقام الإسعاف المحلية في أداة «أرقام الطوارئ». هذا الدليل لا يغني عن التدريب العملي.',
            "Local ambulance numbers are in the «Emergency Numbers» tool. This guide doesn't replace hands-on training."),
      ),
      _sources(),
    ]);
  }
}
