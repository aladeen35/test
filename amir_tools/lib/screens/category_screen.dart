import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../tools/registry.dart';
import 'bundles.dart';
import 'tool_tile.dart';

/// صفحة حزمة: لافتة، بحث داخل الحزمة، وأقسام لكل تصنيف
class CategoryScreen extends StatefulWidget {
  final ToolBundle bundle;
  const CategoryScreen(this.bundle, {super.key});

  static Future<void> open(BuildContext context, ToolBundle b) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(b)));

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final b = widget.bundle;
    final all = b.tools;
    final q = _q.text.trim();
    final shown = all.where((x) => toolMatches(x, q)).toList();
    return SudanBackground(
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: const [ViewToggleButton(), SizedBox(width: 6)],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              BundleBanner(b, count: all.length),
              const SizedBox(height: 12),
              TextField(
                controller: _q,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '${t('فتّش في', 'ابحث في', 'Search in')} ${b.label}…',
                  prefixIcon: const Icon(Icons.search_rounded, color: SD.gold),
                  suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_q.clear)),
                ),
              ),
              const SizedBox(height: 14),
              if (shown.isEmpty)
                Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(t('ما لقينا حاجة بالاسم دا 🤔', 'لا توجد نتائج بهذا الاسم 🤔', 'Nothing found 🤔'), textAlign: TextAlign.center)))
              else
                for (final c in b.cats)
                  if (shown.any((x) => x.cat == c)) CatSection(cat: c, tools: shown.where((x) => x.cat == c).toList()),
            ],
          ),
        ),
      ),
    );
  }
}

/// لافتة الحزمة: أيقونة كبيرة، الاسم، عدد الأدوات وأسماء التصنيفات
class BundleBanner extends StatelessWidget {
  final ToolBundle bundle;
  final int count;
  const BundleBanner(this.bundle, {super.key, required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: bundle.colors, begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SD.gold, width: 1.6),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: SD.goldLight, width: 1.4),
            ),
            child: Icon(bundle.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bundle.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Lalezar', fontSize: 24, height: 1.2, color: SD.goldLight)),
              Text(toolCountText(count), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 2),
              Text(bundle.cats.map((c) => c.label).join(' • '),
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ]),
      );
}

String toolCountText(int n) => t('$n أداة', '$n أداة', n == 1 ? '1 tool' : '$n tools');

/// قسم تصنيف داخل إطار ذهبي: رأس بالاسم والعدد، ويمكن طيّه إن طُلب
class CatSection extends StatelessWidget {
  final ToolCat cat;
  final List<ToolDef> tools;

  /// يمكن طيّه (يُحفظ في بيانات التطبيق)
  final bool collapsible;
  const CatSection({super.key, required this.cat, required this.tools, this.collapsible = false});

  static List<String> collapsedCats(AppState s) => List<String>.from(s.getData<List>('ui_collapsed') ?? const []);

  static void setCollapsed(AppState s, ToolCat c, bool v) {
    final l = collapsedCats(s)..remove(c.name);
    if (v) l.add(c.name);
    s.setData('ui_collapsed', l);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final collapsed = collapsible && collapsedCats(s).contains(cat.name);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final head = Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: bundleOf(cat).colors),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: SD.goldLight.withValues(alpha: .7)),
        ),
        child: Icon(cat.icon, size: 18, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(cat.label,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Lalezar', fontSize: 19, height: 1.2, color: dark ? SD.goldLight : SD.brown)),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        decoration: BoxDecoration(color: SD.gold.withValues(alpha: .22), borderRadius: BorderRadius.circular(12)),
        child: Text('${tools.length}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: dark ? SD.goldLight : SD.brown)),
      ),
      if (collapsible)
        AnimatedRotation(
          turns: collapsed ? 0 : .5,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.expand_more_rounded, color: SD.gold),
        ),
    ]);
    return GoldFrame(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (collapsible)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setCollapsed(s, cat, !collapsed),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: head),
          )
        else
          head,
        if (!collapsed) ...[const SizedBox(height: 10), ToolCollection(tools)],
      ]),
    );
  }
}
