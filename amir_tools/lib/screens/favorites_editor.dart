import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../tools/registry.dart';
import '../core/i18n.dart';

/// ترتيب المفضلة وإضافة/حذف أدوات
class FavoritesEditor extends StatelessWidget {
  const FavoritesEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favs = s.favorites.map(toolById).whereType<ToolDef>().toList();
    final others = allTools.where((t) => !t.hidden && !s.isFav(t.id)).toList();
    return SudanBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(t('مفضلاتك', 'المفضلة', 'Favorites'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
          NoteBox(t('اسحب الأدوات عشان ترتّبها — الترتيب دا بيظهر في البيت.', 'اسحب الأدوات لترتيبها — يظهر هذا الترتيب في الصفحة الرئيسية.', 'Drag tools to reorder — this order shows on the home screen.'), kind: NoteKind.tip),
          SCard(
            title: '${tr('المفضلة', 'Favorites')} (${favs.length})',
            icon: Icons.star_rounded,
            child: favs.isEmpty
                ? Padding(padding: const EdgeInsets.all(12), child: Text(t('فاضية — أضف من تحت 👇', 'فارغة — أضف من الأسفل 👇', 'Empty — add from below 👇')))
                : ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: true,
                    onReorder: s.reorderFavs,
                    children: [
                      for (final t in favs)
                        ListTile(
                          key: ValueKey(t.id),
                          leading: CircleAvatar(backgroundColor: t.color, child: Icon(t.icon, color: Colors.white, size: 20)),
                          title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: SD.red), onPressed: () => s.toggleFav(t.id)),
                        ),
                    ],
                  ),
          ),
          SCard(
            title: t('أضف للمفضلة', 'إضافة إلى المفضلة', 'Add to favorites'),
            icon: Icons.add_circle_outline,
            color: SD.green,
            child: Column(children: [
              for (final t in others)
                ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 16, backgroundColor: t.color, child: Icon(t.icon, color: Colors.white, size: 16)),
                  title: Text(t.name),
                  subtitle: Text(t.cat.label, style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(icon: const Icon(Icons.add_circle, color: SD.green), onPressed: () => s.toggleFav(t.id)),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
