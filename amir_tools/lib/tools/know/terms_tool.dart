import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show EmptyHint, PickChip;
import 'know_common.dart';
import 'terms_data.dart';

/// بحث في المصطلحات الرسمية (عربي/إنجليزي/الشرح) مع توحيد العربية
List<OTerm> searchTerms(String q) {
  final n = normAr(q);
  if (n.isEmpty) return const [];
  final hits = <(int, OTerm)>[];
  for (final o in officialTerms) {
    final ar = normAr(o.ar), en = o.en.toLowerCase();
    int? sc;
    if (ar == n || en == n) {
      sc = 0;
    } else if (ar.contains(n) || en.contains(n)) {
      sc = 1;
    } else if (normAr(o.expAr).contains(n) || o.expEn.toLowerCase().contains(n)) {
      sc = 2;
    }
    if (sc != null) hits.add((sc, o));
  }
  hits.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final h in hits) h.$2];
}

String termShareText(OTerm o) => [
      '📑 ${o.ar} — ${o.en}',
      o.exp,
      '💡 ${o.tip}',
    ].join('\n');

class TermsTool extends StatefulWidget {
  const TermsTool({super.key});
  @override
  State<TermsTool> createState() => _TermsToolState();
}

class _TermsToolState extends State<TermsTool> {
  final _search = TextEditingController();
  String _q = '';
  String _cat = 'all';
  String? _open;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _q.trim();
    final list = q.isNotEmpty
        ? searchTerms(q)
        : (_cat == 'all' ? officialTerms : officialTerms.where((o) => o.cat == _cat).toList());

    return ToolList(children: [
      StatGrid([
        StatChip('${officialTerms.length}', t('مصطلح', 'مصطلحًا', 'Terms'), color: SD.gold, icon: Icons.description_rounded),
        StatChip('${termCats.length}', t('مجال', 'مجالات', 'Areas'), color: SD.nile, icon: Icons.category_rounded),
        StatChip('${list.length}', t('معروض', 'معروض', 'Shown'), color: SD.green, icon: Icons.visibility_rounded),
      ]),
      const SizedBox(height: 14),
      KnowSearch(
        _search,
        t('فتّش: كفالة، IBAN، مخالصة…', 'ابحث: كفالة، IBAN، مخالصة…', 'Search: sponsor, IBAN, clearance…'),
        (v) => setState(() {
          _q = v;
          if (v.trim().length > 1) s.awardDaily('official_terms_search', 2, tr('البحث في المصطلحات الرسمية', 'Searched official terms'));
        }),
      ),
      const SizedBox(height: 10),
      if (q.isEmpty)
        Wrap(spacing: 6, runSpacing: 6, children: [
          PickChip('📚 ${t('الكل', 'الكل', 'All')}', _cat == 'all', () => setState(() => _cat = 'all'), color: SD.gold),
          for (final c in termCats) PickChip('${c.emoji} ${c.name}', _cat == c.key, () => setState(() => _cat = c.key), color: c.color),
        ]),
      const SizedBox(height: 12),
      if (list.isEmpty) EmptyHint(Icons.search_off_rounded, t('ما لقينا المصطلح دا', 'لم يُعثر على المصطلح', 'Term not found')),
      for (final o in list) _card(context, o),
      const SizedBox(height: 6),
      NoteBox(
          t('الشرح دا مبسّط وعام؛ الأنظمة والمدد والرسوم بتختلف من بلد لبلد ومن وقت لوقت. راجع الجهة الرسمية أو محامي مرخّص قبل أي قرار.',
              'الشرح مبسّط وعام؛ تختلف الأنظمة والمدد والرسوم بين الدول وتتغير مع الوقت. راجع الجهة الرسمية أو محاميًا مرخّصًا قبل أي قرار.',
              'Explanations are simplified and general; rules, deadlines and fees differ by country and change over time. Check the official authority or a licensed lawyer before deciding.'),
          kind: NoteKind.warn),
      const ReviewedLine('official_terms'),
    ]);
  }

  Widget _card(BuildContext context, OTerm o) {
    final cat = termCats.firstWhere((c) => c.key == o.cat);
    final open = _open == o.en;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .7);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cat.color.withValues(alpha: .45))),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _open = open ? null : o.en),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEn ? o.en : o.ar, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: readable(context, SD.gold))),
                  Text(isEn ? o.ar : o.en,
                      textDirection: isEn ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600)),
                ]),
              ),
              Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: muted),
            ]),
            const SizedBox(height: 6),
            Text(o.exp, maxLines: open ? null : 2, overflow: open ? null : TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.5)),
            if (open) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: SD.green.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.lightbulb_rounded, size: 18, color: readable(context, SD.green)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(o.tip, style: const TextStyle(fontSize: 13.5, height: 1.45))),
                ]),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Flexible(child: TagPill(cat.name, cat.color)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: tr('نسخ', 'Copy'),
                  onPressed: () => copyText(termShareText(o)),
                  icon: const Icon(Icons.copy_rounded, size: 19),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: t('بلّغ عن خطأ', 'إبلاغ عن خطأ', 'Report error'),
                  onPressed: () => reportOutdated('official_terms', '${o.ar} / ${o.en}'),
                  icon: const Icon(Icons.flag_outlined, size: 19),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: t('شارك', 'مشاركة', 'Share'),
                  onPressed: () => shareTermText(o),
                  icon: const Icon(Icons.share_rounded, size: 19),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  void shareTermText(OTerm o) {
    context.read<AppState>().awardDaily('official_terms_share', 2, tr('مشاركة مصطلح', 'Shared a term'));
    shareKnowText(termShareText(o));
  }
}
