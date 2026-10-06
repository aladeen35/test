import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'duas_data.dart';

class DuasTool extends StatefulWidget {
  const DuasTool({super.key});
  @override
  State<DuasTool> createState() => _DuasToolState();
}

class _DuasToolState extends State<DuasTool> {
  final q = TextEditingController();

  /// null = الكل، 'fav' = المفضلة، أو اسم التصنيف
  String? filter;

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  List<String> _favs(AppState s) => List<String>.from(s.getData<List>('duas_favs') ?? const []);

  void _toggleFav(AppState s, String id) {
    final f = _favs(s);
    f.contains(id) ? f.remove(id) : f.add(id);
    s.setData('duas_favs', f);
    setState(() {});
  }

  String _shareText(Dua d) => '${d.when}\n\n${d.text}\n\n[${d.source}]${isEn ? '\n\n${d.meaning}' : ''}';

  bool _match(Dua d, String query) {
    if (query.isEmpty) return true;
    final nq = stripTashkeel(query.toLowerCase());
    final hay = stripTashkeel('${d.text} ${d.whenAr} ${d.srcAr} ${d.cat.label}').toLowerCase();
    final en = '${d.whenEn} ${d.meaning} ${d.srcEn} ${d.cat.label}'.toLowerCase();
    return hay.contains(nq) || en.contains(query.toLowerCase());
  }

  void _counter(Dua d) {
    showModalBottomSheet(context: context, showDragHandle: true, isScrollControlled: true, builder: (_) => _CounterSheet(d));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favs = _favs(s);
    final query = q.text.trim();
    final list = duas.where((d) {
      if (filter == 'fav' && !favs.contains(d.id)) return false;
      if (filter != null && filter != 'fav' && d.cat.name != filter) return false;
      return _match(d, query);
    }).toList();

    return ToolList(children: [
      TextField(
        controller: q,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: t('فتّش في الأدعية…', 'ابحث في الأدعية…', 'Search duas…'),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  onPressed: () => setState(q.clear),
                  icon: const Icon(Icons.clear_rounded),
                ),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        ChoiceChip(label: Text(tr('الكل', 'All')), selected: filter == null, onSelected: (_) => setState(() => filter = null)),
        ChoiceChip(
          avatar: const Icon(Icons.star_rounded, size: 16),
          label: Text('${tr('المفضلة', 'Favorites')} (${favs.length})'),
          selected: filter == 'fav',
          onSelected: (_) => setState(() => filter = filter == 'fav' ? null : 'fav'),
        ),
        for (final c in DuaCat.values)
          ChoiceChip(
            avatar: Icon(c.icon, size: 16),
            label: Text(c.label),
            selected: filter == c.name,
            onSelected: (_) => setState(() => filter = filter == c.name ? null : c.name),
          ),
      ]),
      const SizedBox(height: 12),
      if (list.isEmpty)
        NoteBox(
          filter == 'fav'
              ? t('لسه ما ضفت أدعية للمفضلة — اضغط ⭐ جنب أي دعاء.', 'لم تُضف أدعية للمفضلة بعد — اضغط ⭐ بجانب أي دعاء.', 'No favorites yet — tap ⭐ on any dua.')
              : t('ما لقينا حاجة', 'لا توجد نتائج', 'No results'),
          kind: NoteKind.tip,
        ),
      for (final d in list)
        _DuaCard(
          d,
          fav: favs.contains(d.id),
          onFav: () => _toggleFav(s, d.id),
          onCopy: () {
            copyText(_shareText(d));
            s.awardDaily('duas_copy', 3, t('نسخت دعاء', 'نسخ دعاء', 'Copied a dua'));
          },
          onShare: () => SharePlus.instance.share(ShareParams(text: '${_shareText(d)}\n\n— ${tr('من تطبيق أدوات أمير', 'via Amir Tools app')}')),
          onCount: () => _counter(d),
        ),
      NoteBox(
        t('النصوص دي من القرآن ومن الأحاديث الصحيحة والحسنة المشهورة، ومكتوب جنب كل واحد مصدره. المعنى الإنجليزي تقريبي للفهم بس.',
            'النصوص من القرآن الكريم ومن الأحاديث الصحيحة والحسنة المشهورة، مع ذكر المصدر لكل منها. المعنى الإنجليزي تقريبي للفهم فقط.',
            'Texts are from the Qur\'an and well-known authentic (sahih/hasan) hadith, each with its source. English meanings are approximate, for understanding only.'),
      ),
    ]);
  }
}

class _DuaCard extends StatelessWidget {
  final Dua d;
  final bool fav;
  final VoidCallback onFav, onCopy, onShare, onCount;
  const _DuaCard(this.d, {required this.fav, required this.onFav, required this.onCopy, required this.onShare, required this.onCount});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SCard(
      title: d.when,
      icon: d.cat.icon,
      color: d.quran ? SD.green : SD.coffee,
      trailing: IconButton(
        tooltip: tr('المفضلة', 'Favorite'),
        onPressed: onFav,
        icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: readable(context, SD.gold)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: SelectableText(
            d.quran ? '﴿${d.text}﴾' : '«${d.text}»',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 19, height: 1.9, fontWeight: FontWeight.w600, color: dark ? SD.cream : SD.brownDeep),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: SD.gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
            child: Text(d.source, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: readable(context, SD.goldDeep))),
          ),
          if (d.repeat > 1) Text('× ${d.repeat}', style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.teal))),
        ]),
        if (isEn) ...[
          const SizedBox(height: 8),
          Text(d.meaning, style: TextStyle(color: muted, fontSize: 13.5, height: 1.45, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('نسخ', 'Copy'))),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('شارك', 'مشاركة', 'Share'))),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onCount,
              icon: const Icon(Icons.touch_app_rounded, size: 18),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('عدّاد', 'عدّاد', 'Counter'))),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// عدّاد بسيط على طريقة السبحة
class _CounterSheet extends StatefulWidget {
  final Dua d;
  const _CounterSheet(this.d);
  @override
  State<_CounterSheet> createState() => _CounterSheetState();
}

class _CounterSheetState extends State<_CounterSheet> {
  int n = 0;

  void _tap() {
    HapticFeedback.lightImpact();
    setState(() => n++);
    final s = context.read<AppState>();
    s.bump('dua_count');
    if (widget.d.repeat > 1 && n == widget.d.repeat) {
      HapticFeedback.heavyImpact();
      s.awardDaily('dua_${widget.d.id}', 5, t('كمّلت الدعاء', 'إتمام الدعاء', 'Completed a dua'));
      toast(t('تمّ ✓ تقبّل الله', 'تمّ ✓ تقبّل الله', 'Done ✓ May Allah accept'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.d.repeat;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(widget.d.text, maxLines: 4, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.7)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _tap,
            child: Container(
              width: 170,
              height: 170,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [SD.brownLight, SD.brownDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                border: Border.all(color: SD.gold, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$n', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: SD.goldLight)),
                    if (goal > 1) Text('/ $goal', style: const TextStyle(fontSize: 18, color: SD.cream)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: () => setState(() => n = 0), icon: const Icon(Icons.refresh_rounded), label: Text(t('صفّر', 'تصفير', 'Reset'))),
        ]),
      ),
    );
  }
}
