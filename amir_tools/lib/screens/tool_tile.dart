import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../tools/registry.dart';
import 'bundles.dart';
import 'tool_page.dart';
import '../core/i18n.dart';

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
        onLongPress: () => toggleFavWithToast(s, tool),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark ? const [Color(0xFF8A5528), Color(0xFF5E361B)] : const [Color(0xFFFFFBF2), Color(0xFFF6E4C3)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SD.gold.withValues(alpha: dark ? .7 : .8), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .35 : .1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (tool.sudan) const Positioned(top: 6, left: 6, child: FlagStrip(width: 15, height: 10)),
              if (fav) const Positioned(top: 3, right: 4, child: Icon(Icons.star_rounded, size: 15, color: SD.goldLight)),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color.lerp(tool.color, Colors.white, .12)!, Color.lerp(tool.color, Colors.black, .3)!],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SD.goldLight.withValues(alpha: .75), width: 1.2),
                            boxShadow: [BoxShadow(color: tool.color.withValues(alpha: .4), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Icon(tool.icon, color: Colors.white, size: 24),
                        ),
                        if (isNewTool(tool.id)) const Positioned(bottom: -6, child: NewBadge()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FitWordsText(
                      tool.name,
                      maxSize: 12.5,
                      minSize: 9,
                      maxLines: 2,
                      style: TextStyle(fontWeight: FontWeight.w800, height: 1.15, color: dark ? SD.cream : SD.brownDeep),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      tool.sub,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.5, color: (dark ? SD.goldLight : SD.brown).withValues(alpha: .75)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شبكة بلاطات: 4 في الصف على الهواتف و5 على الشاشات الأعرض
class ToolGrid extends StatelessWidget {
  final List<ToolDef> tools;
  const ToolGrid(this.tools, {super.key});

  static int columnsFor(double width) => width >= 560
      ? 6
      : width >= 400
      ? 5
      : 4;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
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
          // ارتفاع ثابت يسع الأيقونة وسطرين للاسم والوصف مهما ضاق العرض
          mainAxisExtent: 122,
        ),
        itemBuilder: (_, i) => ToolTile(tools[i]),
      );
    },
  );
}

/// نص يصغّر خطه إن كانت أطول كلمة لا تسع العرض، بدل كسر الكلمة في نصفها
class FitWordsText extends StatelessWidget {
  final String text;
  final double maxSize, minSize;
  final int maxLines;
  final TextStyle style;
  const FitWordsText(this.text, {super.key, required this.maxSize, required this.minSize, required this.maxLines, required this.style});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final dir = Directionality.of(context);
      double widest(double size) {
        var w = 0.0;
        for (final word in text.split(RegExp(r'\s+'))) {
          final tp = TextPainter(
            text: TextSpan(
              text: word,
              style: DefaultTextStyle.of(context).style.merge(style).copyWith(fontSize: size),
            ),
            textDirection: dir,
            maxLines: 1,
          )..layout();
          if (tp.width > w) w = tp.width;
        }
        return w;
      }

      var size = maxSize;
      while (size > minSize && widest(size) > c.maxWidth) {
        size -= .5;
      }
      return Text(
        text,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(fontSize: size),
      );
    },
  );
}

void toggleFavWithToast(AppState s, ToolDef tool) {
  final fav = s.isFav(tool.id);
  s.toggleFav(tool.id);
  toast(fav ? t('اتشالت من المفضلة', 'أُزيلت من المفضلة', 'Removed from favorites') : '«${tool.name}» ${t('اتضافت للمفضلة', 'أُضيفت إلى المفضلة', 'added to favorites')} ⭐');
}

/// شارة «جديد» الذهبية الصغيرة
class NewBadge extends StatelessWidget {
  const NewBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [SD.goldLight, SD.gold]),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: SD.brownDeep.withValues(alpha: .6), width: .8),
    ),
    child: Text(
      t('جديد', 'جديد', 'NEW'),
      maxLines: 1,
      style: const TextStyle(fontSize: 8.5, height: 1.2, fontWeight: FontWeight.w900, color: SD.brownDeep),
    ),
  );
}

/// طريقة العرض المحفوظة: شبكة أو قائمة
bool listViewMode(AppState s) => s.getData<String>('ui_view') == 'list';

/// زر تبديل العرض (شبكة/قائمة) — يُحفظ في بيانات التطبيق
class ViewToggleButton extends StatelessWidget {
  const ViewToggleButton({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = listViewMode(s);
    return IconButton(
      tooltip: list ? t('عرض شبكة', 'عرض شبكي', 'Grid view') : t('عرض قائمة', 'عرض قائمة', 'List view'),
      icon: Icon(list ? Icons.grid_view_rounded : Icons.view_list_rounded, color: SD.gold),
      onPressed: () => s.setData('ui_view', list ? 'grid' : 'list'),
    );
  }
}

/// مجموعة أدوات تُعرض شبكة أو قائمة حسب اختيار المستخدم
class ToolCollection extends StatelessWidget {
  final List<ToolDef> tools;
  const ToolCollection(this.tools, {super.key});
  @override
  Widget build(BuildContext context) {
    final list = listViewMode(context.watch<AppState>());
    if (!list) return ToolGrid(tools);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tools.length; i++) ...[if (i > 0) const SizedBox(height: 8), ToolRow(tools[i])],
      ],
    );
  }
}

/// صف أداة في عرض القائمة: أيقونة، الاسم والوصف، نجمة المفضلة
class ToolRow extends StatelessWidget {
  final ToolDef tool;
  const ToolRow(this.tool, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fav = s.isFav(tool.id);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ToolPage.open(context, tool.id),
        onLongPress: () => toggleFavWithToast(s, tool),
        child: Ink(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 2, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: dark ? const [Color(0xFF8A5528), Color(0xFF5E361B)] : const [Color(0xFFFFFBF2), Color(0xFFF6E4C3)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SD.gold.withValues(alpha: dark ? .6 : .75), width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color.lerp(tool.color, Colors.white, .12)!, Color.lerp(tool.color, Colors.black, .3)!], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SD.goldLight.withValues(alpha: .75), width: 1.1),
                ),
                child: Icon(tool.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tool.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: dark ? SD.cream : SD.brownDeep),
                          ),
                        ),
                        if (tool.sudan) ...[const SizedBox(width: 6), const FlagStrip(width: 15, height: 10)],
                        if (isNewTool(tool.id)) ...[const SizedBox(width: 6), const NewBadge()],
                      ],
                    ),
                    Text(
                      tool.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: (dark ? SD.goldLight : SD.brown).withValues(alpha: .8)),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: fav ? t('شيلها من المفضلة', 'إزالة من المفضلة', 'Remove from favorites') : t('أضفها للمفضلة', 'إضافة إلى المفضلة', 'Add to favorites'),
                icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded, color: fav ? SD.gold : SD.gold.withValues(alpha: .6)),
                onPressed: () => toggleFavWithToast(s, tool),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف أفقي من بلاطات الأدوات (للمستخدمة مؤخرًا والجديدة)
class ToolStrip extends StatelessWidget {
  final List<ToolDef> tools;
  const ToolStrip(this.tools, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 122,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: tools.length,
      separatorBuilder: (_, _) => const SizedBox(width: 9),
      itemBuilder: (_, i) => SizedBox(width: 86, child: ToolTile(tools[i])),
    ),
  );
}
