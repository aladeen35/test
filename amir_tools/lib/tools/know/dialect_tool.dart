import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show EmptyHint, PickChip;
import 'dialect_data.dart';
import 'know_common.dart';

String dWordId(DWord w) => '${w.cat}|${w.word}';

/// كلمة اليوم: ثابتة لليوم نفسه
DWord wordOfDay(DateTime d) {
  final n = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024)).inDays;
  return dialectWords[(n * 37) % dialectWords.length];
}

/// بحث في القاموس: [reverse] = البحث بالمعنى (فصحى/إنجليزي) للوصول للكلمة السودانية
List<DWord> searchDialect(String q, {bool reverse = false}) {
  final n = normAr(q);
  if (n.isEmpty) return const [];
  final hits = <(int, DWord)>[];
  for (final w in dialectWords) {
    final word = normAr(w.word), msa = normAr(w.msa), en = w.en.toLowerCase(), ex = normAr(w.ex);
    int? score;
    if (reverse) {
      if (msa == n || en == n) {
        score = 0;
      } else if (msa.split(RegExp(r'[\s/،,()]+')).contains(n) || en.split(RegExp(r'[\s/,()]+')).contains(n)) {
        score = 1;
      } else if (msa.contains(n) || en.contains(n)) {
        score = 2;
      }
    } else {
      if (word == n) {
        score = 0;
      } else if (word.startsWith(n)) {
        score = 1;
      } else if (word.contains(n)) {
        score = 2;
      } else if (msa.contains(n) || en.contains(n)) {
        score = 3;
      } else if (ex.contains(n)) {
        score = 4;
      }
    }
    if (score != null) hits.add((score, w));
  }
  hits.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final h in hits) h.$2];
}

String dialectShareText(DWord w) => [
      '🇸🇩 ${t('كلمة سودانية', 'كلمة من اللهجة السودانية', 'Sudanese word')}: ${w.word}',
      '• ${tr('بالفصحى', 'MSA')}: ${w.msa}',
      '• English: ${w.en}',
      '• ${tr('مثال', 'Example')}: «${w.ex}»',
    ].join('\n');

class DialectTool extends StatefulWidget {
  const DialectTool({super.key});
  @override
  State<DialectTool> createState() => _DialectToolState();
}

class _DialectToolState extends State<DialectTool> {
  final _search = TextEditingController();
  String _q = '';
  String _cat = 'all';
  bool _reverse = false;
  int _limit = 40;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> _favs(AppState s) => List<String>.from(s.getData<List>('sd_dialect_favs') ?? const []);

  void _toggleFav(AppState s, DWord w) {
    final f = _favs(s);
    final id = dWordId(w);
    if (f.contains(id)) {
      f.remove(id);
    } else {
      f.add(id);
      s.awardDaily('sd_dialect_fav', 2, tr('حفظ كلمة سودانية', 'Saved a Sudanese word'));
    }
    s.setData('sd_dialect_favs', f);
  }

  void _share(DWord w) {
    context.read<AppState>().awardDaily('sd_dialect_share', 3, tr('مشاركة كلمة سودانية', 'Shared a Sudanese word'));
    SharePlus.instance.share(ShareParams(text: '${dialectShareText(w)}\n\n— ${tr('من تطبيق أدوات أمير', 'via Ameer Tools app')} 🇸🇩'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favs = _favs(s);
    final q = _q.trim();
    final List<DWord> list;
    if (q.isNotEmpty) {
      list = searchDialect(q, reverse: _reverse);
    } else if (_cat == 'fav') {
      list = dialectWords.where((w) => favs.contains(dWordId(w))).toList();
    } else if (_cat == 'all') {
      list = dialectWords;
    } else {
      list = dialectWords.where((w) => w.cat == _cat).toList();
    }
    final shown = list.take(_limit).toList();
    final wod = wordOfDay(DateTime.now());

    return ToolList(children: [
      _wordOfDay(context, s, wod, favs.contains(dWordId(wod))),
      StatGrid([
        StatChip('${dialectWords.length}', t('كلمة وتعبير', 'كلمة وتعبير', 'Words & phrases'), color: SD.gold, icon: Icons.menu_book_rounded),
        StatChip('${dialectCats.length}', t('تصنيف', 'تصنيفًا', 'Categories'), color: SD.nile, icon: Icons.category_rounded),
        StatChip('${favs.length}', t('محفوظة', 'محفوظة', 'Saved'), color: SD.henna, icon: Icons.star_rounded),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('من السوداني', 'من السودانية', 'From Sudanese')))),
            ButtonSegment(value: true, label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('للسوداني', 'إلى السودانية', 'To Sudanese')))),
          ],
          selected: {_reverse},
          onSelectionChanged: (v) => setState(() {
            _reverse = v.first;
            _limit = 40;
          }),
        ),
      ),
      const SizedBox(height: 10),
      KnowSearch(
        _search,
        _reverse
            ? t('اكتب المعنى بالفصحى أو الإنجليزي…', 'اكتب المعنى بالفصحى أو الإنجليزية…', 'Type a meaning in Arabic or English…')
            : t('فتّش عن كلمة أو معنى…', 'ابحث عن كلمة أو معنى…', 'Search a word or meaning…'),
        (v) => setState(() {
          _q = v;
          _limit = 40;
          if (v.trim().length > 1) s.awardDaily('sd_dialect_search', 2, tr('البحث في قاموس اللهجة', 'Searched the dialect dictionary'));
        }),
      ),
      const SizedBox(height: 10),
      if (q.isEmpty)
        Wrap(spacing: 6, runSpacing: 6, children: [
          PickChip('📚 ${t('الكل', 'الكل', 'All')}', _cat == 'all', () => setState(() => _cat = 'all'), color: SD.gold),
          PickChip('⭐ ${t('المحفوظة', 'المفضلة', 'Saved')} (${favs.length})', _cat == 'fav', () => setState(() => _cat = 'fav'), color: SD.gold),
          for (final c in dialectCats) PickChip('${c.emoji} ${c.name}', _cat == c.key, () => setState(() => _cat = c.key), color: c.color),
        ]),
      const SizedBox(height: 10),
      Text(
        q.isEmpty
            ? t('${list.length} كلمة', '${list.length} كلمة', '${list.length} words')
            : t('لقينا ${list.length} نتيجة', 'وُجدت ${list.length} نتيجة', '${list.length} results'),
        style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
      ),
      const SizedBox(height: 8),
      if (list.isEmpty)
        EmptyHint(
          _cat == 'fav' && q.isEmpty ? Icons.star_border_rounded : Icons.search_off_rounded,
          _cat == 'fav' && q.isEmpty
              ? t('دوس النجمة جنب أي كلمة عشان تحفظها هنا', 'اضغط النجمة بجانب أي كلمة لحفظها هنا', 'Tap the star on any word to save it here')
              : t('ما لقينا الكلمة دي — جرّب كلمة تانية أو غيّر الاتجاه', 'لا توجد نتائج — جرّب كلمة أخرى أو غيّر الاتجاه', 'No results — try another word or switch direction'),
        ),
      for (final w in shown) _card(context, s, w, favs.contains(dWordId(w))),
      if (list.length > shown.length)
        OutlinedButton.icon(
          onPressed: () => setState(() => _limit += 60),
          icon: const Icon(Icons.expand_more_rounded),
          label: Text(t('ورّيني أكتر (${list.length - shown.length})', 'عرض المزيد (${list.length - shown.length})', 'Show more (${list.length - shown.length})')),
        ),
      const SizedBox(height: 8),
      NoteBox(
          t('الكلمات دي شائعة في وسط السودان، وبعضها بيختلف نطقو أو معناهو من منطقة لمنطقة.',
              'هذه كلمات شائعة في وسط السودان، وقد يختلف نطق بعضها أو معناه من منطقة لأخرى.',
              'These words are common in central Sudan; pronunciation or meaning may vary by region.'),
          kind: NoteKind.info),
      const ReviewedLine('sd_dialect'),
    ]);
  }

  Widget _wordOfDay(BuildContext context, AppState s, DWord w, bool fav) {
    final cat = dialectCats.firstWhere((c) => c.key == w.cat);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8A5528), Color(0xFF5A3418), Color(0xFF3A1F0C)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SD.gold, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: SD.goldLight, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(t('كلمة اليوم', 'كلمة اليوم', 'Word of the day'),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SD.goldLight, fontWeight: FontWeight.w800)),
          ),
          Flexible(child: Text('${cat.emoji} ${cat.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SD.cream, fontSize: 12.5))),
        ]),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(w.word, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
        ),
        Text(isEn ? w.en : w.msa, textAlign: TextAlign.center, style: const TextStyle(color: SD.goldLight, fontSize: 16, fontWeight: FontWeight.w700)),
        if (!isEn) Text(w.en, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: TextStyle(color: SD.cream.withValues(alpha: .85), fontSize: 13)),
        if (isEn) Text(w.msa, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: SD.cream.withValues(alpha: .85), fontSize: 13)),
        const SizedBox(height: 6),
        Text('«${w.ex}»', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: SD.cream, fontStyle: FontStyle.italic)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            tooltip: tr('نسخ', 'Copy'),
            onPressed: () => copyText(dialectShareText(w)),
            icon: const Icon(Icons.copy_rounded, color: SD.goldLight),
          ),
          IconButton(
            tooltip: t('شارك', 'مشاركة', 'Share'),
            onPressed: () => _share(w),
            icon: const Icon(Icons.share_rounded, color: SD.goldLight),
          ),
          IconButton(
            tooltip: tr('المفضلة', 'Favorite'),
            onPressed: () => _toggleFav(s, w),
            icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: SD.goldLight),
          ),
        ]),
      ]),
    );
  }

  Widget _card(BuildContext context, AppState s, DWord w, bool fav) {
    final cat = dialectCats.firstWhere((c) => c.key == w.cat);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .7);
    final title = _reverse ? (isEn ? w.en : w.msa) : w.word;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cat.color.withValues(alpha: .45))),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(title, style: TextStyle(fontSize: _reverse ? 15.5 : 20, fontWeight: FontWeight.w800, color: readable(context, _reverse ? SD.nile : SD.gold))),
            ),
            const SizedBox(width: 6),
            Flexible(child: TagPill('${cat.emoji} ${cat.name}', cat.color)),
          ]),
          if (_reverse)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                Icon(Icons.subdirectory_arrow_left_rounded, size: 18, color: readable(context, SD.gold)),
                const SizedBox(width: 4),
                Expanded(child: Text(w.word, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: readable(context, SD.gold)))),
              ]),
            ),
          const SizedBox(height: 4),
          if (!_reverse || isEn) _line(Icons.translate_rounded, tr('بالفصحى', 'MSA'), w.msa, muted, TextDirection.rtl),
          if (!_reverse || !isEn) _line(Icons.language_rounded, 'English', w.en, muted, TextDirection.ltr),
          _line(Icons.format_quote_rounded, tr('مثال', 'Example'), w.ex, muted, TextDirection.rtl, italic: true),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: tr('نسخ', 'Copy'),
              onPressed: () => copyText(dialectShareText(w)),
              icon: const Icon(Icons.copy_rounded, size: 19),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: t('شارك', 'مشاركة', 'Share'),
              onPressed: () => _share(w),
              icon: const Icon(Icons.share_rounded, size: 19),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: tr('المفضلة', 'Favorite'),
              onPressed: () => _toggleFav(s, w),
              icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: fav ? SD.gold : null),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _line(IconData icon, String label, String text, Color muted, TextDirection dir, {bool italic = false}) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 16, color: muted)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w700, color: muted, fontSize: 13)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              textDirection: dir,
              textAlign: isEn ? TextAlign.left : TextAlign.right,
              style: TextStyle(fontSize: 14.5, fontStyle: italic ? FontStyle.italic : FontStyle.normal),
            ),
          ),
        ]),
      );
}
