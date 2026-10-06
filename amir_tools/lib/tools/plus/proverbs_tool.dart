import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/data.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../../services/prayer.dart';
import '../life/life_common.dart';
import 'proverbs_data.dart';

const _kFavs = 'proverbs_favs';

/// تطبيع النص العربي للبحث
String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[ً-ْـ]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي');

String meaningOf(Proverb p) => t(p.sd, p.ar, p.en);

class ProverbsTool extends StatefulWidget {
  const ProverbsTool({super.key});
  @override
  State<ProverbsTool> createState() => _ProverbsToolState();
}

class _ProverbsToolState extends State<ProverbsTool> {
  final q = TextEditingController();
  bool favsOnly = false;
  int? random;
  final _rnd = math.Random();

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  List<String> _favs(AppState s) => List<String>.from(s.getData<List>(_kFavs) ?? []);

  void _toggleFav(AppState s, Proverb p) {
    final f = _favs(s);
    if (f.contains(p.text)) {
      f.remove(p.text);
    } else {
      f.add(p.text);
      s.awardDaily('proverb_fav', 2, t('حفظت مثل', 'حفظ مثل', 'Saved a proverb'));
    }
    s.setData(_kFavs, f);
  }

  String _shareText(Proverb p) => '«${p.text}»\n${t('المعنى', 'المعنى', 'Meaning')}: ${meaningOf(p)}${isEn ? '' : '\n${p.en}'}\n— ${t('مثل سوداني', 'مثل سوداني', 'Sudanese proverb')}';

  void _share(AppState s, Proverb p) {
    s.awardDaily('proverb_share', 3, t('شاركت مثل', 'مشاركة مثل', 'Shared a proverb'));
    SharePlus.instance.share(ShareParams(text: '${_shareText(p)}\n\n— ${tr('من تطبيق أدوات أمير', 'via Amir Tools app')} 🇸🇩'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favs = _favs(s);
    // نفس اختيار الصفحة الرئيسية
    final todayIdx = dateToJdn(sudanNow()) % sudaneseProverbs.length;
    final today = allProverbs[todayIdx];
    final query = _norm(q.text.trim());
    final list = [
      for (var i = 0; i < allProverbs.length; i++)
        if ((!favsOnly || favs.contains(allProverbs[i].text)) &&
            (query.isEmpty || _norm('${allProverbs[i].text} ${allProverbs[i].sd} ${allProverbs[i].ar} ${allProverbs[i].en}').contains(query)))
          i,
    ];

    return ToolList(children: [
      ResultHero(label: '📜 ${t('مثل الليلة', 'مثل اليوم', 'Proverb of the day')}', value: today.text, sub: meaningOf(today)),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(onPressed: () => _share(s, today), icon: const Icon(Icons.share_rounded), label: Text(t('شارك مثل الليلة', 'شارك مثل اليوم', 'Share it'), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              var r = _rnd.nextInt(allProverbs.length);
              if (r == random && allProverbs.length > 1) r = (r + 1) % allProverbs.length;
              s.awardDaily('proverb_random', 2, t('قريت مثل', 'قراءة مثل', 'Read a proverb'));
              setState(() => random = r);
            },
            icon: const Icon(Icons.casino_rounded),
            label: Text(t('مثل عشوائي', 'مثل عشوائي', 'Random'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      if (random != null) _card(s, random!, favs, highlight: true),
      TextField(
        controller: q,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: t('فتّش في الأمثال والمعاني', 'ابحث في الأمثال والمعاني', 'Search proverbs & meanings'),
          suffixIcon: q.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () => setState(q.clear),
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        PickChip('${t('الكل', 'الكل', 'All')} (${allProverbs.length})', !favsOnly, () => setState(() => favsOnly = false), color: SD.gold),
        PickChip('${t('المفضلة', 'المفضلة', 'Favorites')} (${favs.length})', favsOnly, () => setState(() => favsOnly = true), color: SD.red),
      ]),
      const SizedBox(height: 10),
      if (list.isEmpty)
        EmptyHint(favsOnly ? Icons.favorite_border_rounded : Icons.search_off_rounded,
            favsOnly ? t('ما حفظت أمثال لسه — دوس ♡', 'لم تحفظ أمثالًا بعد — اضغط ♡', 'No favorites yet — tap ♡') : t('ما لقينا حاجة', 'لا توجد نتائج', 'No results')),
      for (final i in list) _card(s, i, favs, today: i == todayIdx),
      NoteBox(
          t('الأمثال من التراث الشعبي السوداني، وممكن تلقى ليها روايات وألفاظ مختلفة شوية من منطقة لمنطقة.',
              'الأمثال من التراث الشعبي السوداني، وقد تختلف ألفاظها ورواياتها قليلًا من منطقة لأخرى.',
              'These proverbs are from Sudanese folk heritage; wording may vary slightly from region to region.'),
          kind: NoteKind.info),
    ]);
  }

  Widget _card(AppState s, int i, List<String> favs, {bool highlight = false, bool today = false}) {
    final p = allProverbs[i];
    final fav = favs.contains(p.text);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .7);
    return SCard(
      color: highlight ? SD.orange : SD.gold,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (highlight || today)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(highlight ? '🎲 ${t('مثل عشوائي', 'مثل عشوائي', 'Random proverb')}' : '⭐ ${t('مثل الليلة', 'مثل اليوم', 'Proverb of the day')}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: readable(context, SD.orange))),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Text(p.text,
              textDirection: TextDirection.rtl,
              textAlign: isEn ? TextAlign.left : TextAlign.start,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.5, color: dark ? SD.goldLight : SD.brown)),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Text(meaningOf(p), style: TextStyle(height: 1.5, color: muted)),
        ),
        if (!isEn)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
            child: Text(p.en, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: muted.withValues(alpha: .6))),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(
            tooltip: t('انسخ', 'نسخ', 'Copy'),
            visualDensity: VisualDensity.compact,
            onPressed: () => copyText(_shareText(p)),
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
          IconButton(
            tooltip: t('شارك', 'مشاركة', 'Share'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _share(s, p),
            icon: const Icon(Icons.share_rounded, size: 20),
          ),
          IconButton(
            tooltip: fav ? t('شيلو من المفضلة', 'إزالة من المفضلة', 'Unfavorite') : t('ضيفو للمفضلة', 'إضافة للمفضلة', 'Favorite'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _toggleFav(s, p),
            icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: fav ? readable(context, SD.red) : null),
          ),
        ]),
      ]),
    );
  }
}
