import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../tools/registry.dart';
import 'tool_page.dart';

/// بلاطة أداة بطابع الجلد والذهب: أيقونة ملوّنة، الاسم، وصف قصير، علم للأدوات السودانية، نجمة للمفضلة
class ToolTile extends StatelessWidget {
  final ToolDef tool;
  const ToolTile(this.tool, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fav = s.isFav(tool.id);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ToolPage.open(context, tool.id),
        onLongPress: () {
          s.toggleFav(tool.id);
          toast(fav ? 'اتشالت من المفضلة' : '«${tool.name}» اتضافت للمفضلة ⭐');
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark ? const [Color(0xFF8A5528), Color(0xFF5E361B)] : const [Color(0xFFFFFBF2), Color(0xFFF6E4C3)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SD.gold.withValues(alpha: dark ? .7 : .8), width: 1.3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .35 : .1), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Stack(children: [
            if (tool.sudan) const Positioned(top: 6, left: 6, child: FlagStrip(width: 15, height: 10)),
            if (fav) const Positioned(top: 3, right: 4, child: Icon(Icons.star_rounded, size: 15, color: SD.goldLight)),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color.lerp(tool.color, Colors.white, .12)!, Color.lerp(tool.color, Colors.black, .3)!],
                        begin: Alignment.topRight, end: Alignment.bottomLeft),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SD.goldLight.withValues(alpha: .75), width: 1.2),
                    boxShadow: [BoxShadow(color: tool.color.withValues(alpha: .4), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(tool.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 6),
                Text(tool.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.15, color: dark ? SD.cream : SD.brownDeep)),
                const SizedBox(height: 1),
                Text(tool.sub,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: (dark ? SD.goldLight : SD.brown).withValues(alpha: .75))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// شبكة بلاطات: 4 في الصف على الهواتف و5 على الشاشات الأعرض
class ToolGrid extends StatelessWidget {
  final List<ToolDef> tools;
  const ToolGrid(this.tools, {super.key});

  static int columnsFor(double width) => width >= 560 ? 6 : width >= 400 ? 5 : 4;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = columnsFor(c.maxWidth);
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: cols >= 5 ? .66 : .74,
          ),
          itemBuilder: (_, i) => ToolTile(tools[i]),
        );
      });
}
