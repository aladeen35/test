import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// أدوات مشتركة صغيرة لقسم «إضافات»

/// شريط تقدّم بعنوان وقيمة على الطرف
class XBar extends StatelessWidget {
  final String label, trailing;
  final double fraction;
  final Color color;
  final bool dim;
  const XBar(this.label, this.fraction, this.trailing, {super.key, this.color = SD.green, this.dim = false});

  @override
  Widget build(BuildContext context) {
    final c = dim ? Colors.grey : color;
    return Opacity(
      opacity: dim ? .5 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, decoration: dim ? TextDecoration.lineThrough : null)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(trailing, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, c))),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.isNaN ? 0 : fraction.clamp(0, 1).toDouble(),
              minHeight: 9,
              color: c,
              backgroundColor: c.withValues(alpha: .14),
            ),
          ),
        ]),
      ),
    );
  }
}

/// زر مقطّع قصير (حتى 3 خيارات)
class XSeg<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  const XSeg(this.items, this.value, this.onChanged, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [
            for (final (v, l) in items)
              ButtonSegment<T>(
                value: v,
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(l, maxLines: 1)),
              ),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      );
}

/// شارة رقمية صغيرة
class XBadge extends StatelessWidget {
  final String text;
  final Color color;
  const XBadge(this.text, {super.key, this.color = SD.gold});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: readable(context, color).withValues(alpha: .4)),
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: readable(context, color))),
      );
}

/// ألوان الفرق/اللاعبين
const teamColors = [SD.green, SD.nile, SD.henna, SD.purple, SD.gold, SD.teal, SD.pink, SD.orange];
