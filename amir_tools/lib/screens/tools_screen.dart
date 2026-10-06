import 'package:flutter/material.dart';
import '../core/pattern.dart';
import '../core/theme.dart';
import '../tools/registry.dart';
import 'shell.dart';
import 'tool_tile.dart';
import '../core/i18n.dart';

/// العِدّة: كل الأدوات مع البحث والتصنيفات
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});
  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _q = TextEditingController();
  String? _cat;

  @override
  void initState() {
    super.initState();
    Shell.toolsFilter.addListener(_onFilter);
  }

  void _onFilter() {
    if (Shell.toolsFilter.value != null) {
      setState(() => _cat = Shell.toolsFilter.value);
      Shell.toolsFilter.value = null;
    }
  }

  @override
  void dispose() {
    Shell.toolsFilter.removeListener(_onFilter);
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final list = allTools
        .where((t) => (!t.hidden || q.isNotEmpty) && (_cat == null || t.cat.name == _cat) && (q.isEmpty || '${t.name} ${t.sub} ${t.keywords}'.toLowerCase().contains(q.toLowerCase())))
        .toList();
    final groups = <ToolCat, List<ToolDef>>{};
    for (final t in list) {
      groups.putIfAbsent(t.cat, () => []).add(t);
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 120),
      children: [
        Center(child: GoldText(t('العِدّة كلها', 'كل الأدوات', 'All tools'), size: 34)),
        Center(child: Text(t('${allTools.where((x) => !x.hidden).length} أداة في جيبك — ضغطة طويلة على أي أداة تضيفها للمفضلة', '${allTools.where((x) => !x.hidden).length} أداة في جيبك — اضغط مطولًا على أي أداة لإضافتها إلى المفضلة', '${allTools.where((x) => !x.hidden).length} tools in your pocket — long-press any tool to add it to favorites'),
            textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .75), fontSize: 13))),
        const GoldDivider(),
        TextField(
          controller: _q,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: t('فتّش عن أداة… (مثلًا: دولار، عمر، قبلة)', 'ابحث عن أداة… (مثلًا: دولار، عمر، قبلة)', 'Search tools… (e.g. dollar, age, qibla)'),
            prefixIcon: const Icon(Icons.search_rounded, color: SD.gold),
            suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_q.clear)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _chip(null, tr('الكل', 'All'), Icons.apps_rounded),
            for (final c in ToolCat.values) _chip(c.name, c.label, c.icon),
          ]),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(t('ما لقينا حاجة بالاسم دا 🤔', 'لا توجد نتائج بهذا الاسم 🤔', 'Nothing found 🤔'))))
        else
          for (final e in groups.entries) GoldFrame(title: e.key.label, child: ToolGrid(e.value)),
      ],
    );
  }

  Widget _chip(String? id, String label, IconData icon) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          selected: _cat == id,
          onSelected: (_) => setState(() => _cat = id),
          avatar: Icon(icon, size: 18, color: _cat == id ? SD.brownDeep : SD.gold),
          label: Text(label),
          selectedColor: SD.gold,
          labelStyle: TextStyle(fontWeight: FontWeight.w800, color: _cat == id ? SD.brownDeep : null),
          showCheckmark: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}
