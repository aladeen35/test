import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../tools/registry.dart';
import 'bundles.dart';
import 'category_screen.dart';
import 'shell.dart';
import 'tool_tile.dart';
import '../core/i18n.dart';

/// العِدّة: كل الأدوات مع البحث والحزم وأقسام قابلة للطي
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});
  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _q = TextEditingController();
  final _keys = <ToolCat, GlobalKey>{};
  final _scroll = ScrollController();
  ToolBundle? _bundle;

  @override
  void initState() {
    super.initState();
    Shell.toolsFilter.addListener(_onFilter);
    if (Shell.toolsFilter.value != null) WidgetsBinding.instance.addPostFrameCallback((_) => _onFilter());
  }

  /// يقبل اسم تصنيف (ToolCat.name) أو اسم حزمة (ToolBundle.name)
  void _onFilter() {
    final v = Shell.toolsFilter.value;
    if (v == null || !mounted) return;
    Shell.toolsFilter.value = null;
    final cat = catByName(v);
    final b = ToolBundle.byName(v) ?? (cat == null ? null : bundleOf(cat));
    if (b == null) return;
    if (cat != null) CatSection.setCollapsed(context.read<AppState>(), cat, false);
    setState(() {
      _bundle = b;
      _q.clear();
    });
    if (cat != null) WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(cat));
  }

  /// القائمة كسولة: نتقدّم صفحةً صفحة حتى يُبنى القسم المطلوب ثم نُظهره
  Future<void> _scrollTo(ToolCat cat) async {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(0);
    for (var i = 0; i < 40 && mounted; i++) {
      final c = _keys[cat]?.currentContext;
      if (c != null && c.mounted) {
        await Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        return;
      }
      final p = _scroll.position;
      if (p.pixels >= p.maxScrollExtent) return;
      _scroll.jumpTo((p.pixels + p.viewportDimension * .8).clamp(0, p.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  void dispose() {
    Shell.toolsFilter.removeListener(_onFilter);
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final q = _q.text.trim();
    final visible = allTools.where((x) => !x.hidden).length;
    final scheme = Theme.of(context).colorScheme;
    final results = q.isEmpty ? const <ToolDef>[] : allTools.where((x) => toolMatches(x, q)).toList();
    final bundles = _bundle == null ? ToolBundle.values : [_bundle!];
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 120),
      children: [
        Center(child: GoldText(t('العِدّة كلها', 'كل الأدوات', 'All tools'), size: 34)),
        Center(
            child: Text(
                t('$visible أداة في جيبك — ضغطة طويلة على أي أداة تضيفها للمفضلة', '$visible أداة في جيبك — اضغط مطولًا على أي أداة لإضافتها إلى المفضلة',
                    '$visible tools in your pocket — long-press any tool to add it to favorites'),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface.withValues(alpha: .75), fontSize: 13))),
        const GoldDivider(),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: t('فتّش عن أداة… (مثلًا: دولار، عمر، قبلة)', 'ابحث عن أداة… (مثلًا: دولار، عمر، قبلة)', 'Search tools… (e.g. dollar, age, qibla)'),
                prefixIcon: const Icon(Icons.search_rounded, color: SD.gold),
                suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_q.clear)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const ViewToggleButton(),
        ]),
        const SizedBox(height: 10),
        if (q.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(t('لقينا ${results.length}', 'النتائج: ${results.length}', '${results.length} result${results.length == 1 ? '' : 's'}'),
                style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold)),
          ),
          if (results.isEmpty)
            Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(t('ما لقينا حاجة بالاسم دا 🤔', 'لا توجد نتائج بهذا الاسم 🤔', 'Nothing found 🤔'), textAlign: TextAlign.center)))
          else
            ToolCollection(results),
        ] else ...[
          SizedBox(
            height: 44,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              _chip(null, tr('الكل', 'All'), Icons.apps_rounded),
              for (final b in ToolBundle.values) _chip(b, b.label, b.icon),
            ]),
          ),
          const SizedBox(height: 12),
          for (final b in bundles) ...[
            if (_bundle == null)
              _bundleHeader(b)
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () => CategoryScreen.open(context, b), child: BundleBanner(b, count: b.tools.length)),
              ),
            for (final c in b.cats) _section(c),
          ],
        ],
      ],
    );
  }

  Widget _section(ToolCat c) {
    final tools = allTools.where((x) => !x.hidden && x.cat == c).toList();
    if (tools.isEmpty) return const SizedBox.shrink();
    return CatSection(key: _keys.putIfAbsent(c, GlobalKey.new), cat: c, tools: tools, collapsible: true);
  }

  Widget _bundleHeader(ToolBundle b) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _bundle = b),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(gradient: LinearGradient(colors: b.colors), shape: BoxShape.circle, border: Border.all(color: SD.gold)),
              child: Icon(b.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: GoldText(b.label, size: 24, align: TextAlign.start)),
            Text(toolCountText(b.tools.length), style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold, fontSize: 13)),
          ]),
        ),
      );

  Widget _chip(ToolBundle? b, String label, IconData icon) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          selected: _bundle == b,
          onSelected: (_) => setState(() => _bundle = b),
          avatar: Icon(icon, size: 18, color: _bundle == b ? SD.brownDeep : SD.gold),
          label: Text(label),
          selectedColor: SD.gold,
          labelStyle: TextStyle(fontWeight: FontWeight.w800, color: _bundle == b ? SD.brownDeep : null),
          showCheckmark: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}
