import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../tools/registry.dart';
import '../core/i18n.dart';

/// غلاف كل أداة: خلفية مزخرفة، عنوان، نجمة المفضلة
class ToolPage extends StatefulWidget {
  final ToolDef tool;
  const ToolPage(this.tool, {super.key});

  static Future<void> open(BuildContext context, String id) async {
    final t = toolById(id);
    if (t == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ToolPage(t)));
  }

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().useTool(widget.tool.id, widget.tool.name));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fav = s.isFav(widget.tool.id);
    return SudanBackground(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          titleSpacing: 0,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: widget.tool.color.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
              child: Icon(widget.tool.icon, color: widget.tool.color),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(widget.tool.name, overflow: TextOverflow.ellipsis)),
            if (widget.tool.sudan) ...[const SizedBox(width: 8), const FlagStrip(width: 24, height: 16)],
          ]),
          actions: [
            IconButton(
              tooltip: fav ? t('شيلها من المفضلة', 'إزالة من المفضلة', 'Remove from favorites') : t('أضفها للمفضلة', 'إضافة إلى المفضلة', 'Add to favorites'),
              icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded, color: fav ? SD.gold : null, size: 30),
              onPressed: () {
                s.toggleFav(widget.tool.id);
                toast(fav ? t('اتشالت من المفضلة', 'أُزيلت من المفضلة', 'Removed from favorites') : t('اتضافت للمفضلة ⭐', 'أُضيفت إلى المفضلة ⭐', 'Added to favorites ⭐'));
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(top: false, child: widget.tool.builder(context)),
      ),
    );
  }
}
