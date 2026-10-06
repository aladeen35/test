import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';

/// أدوات مشتركة لمجلد «plus»

/// سلسلة نقاط لرسم خطي (x متزايد)
class ChartSeries {
  final List<Offset> points;
  final Color color;
  final String label;
  const ChartSeries(this.points, this.color, this.label);
}

/// خط مرجعي أفقي (حدّ طبيعي مثلًا)
class ChartGuide {
  final double y;
  final Color color;
  final String label;
  const ChartGuide(this.y, this.color, this.label);
}

/// رسم بياني خطي بسيط مع خطوط مرجعية ومفتاح ألوان
class PlusLineChart extends StatelessWidget {
  final List<ChartSeries> series;
  final List<ChartGuide> guides;
  final String? startLabel, endLabel;
  final double height;
  const PlusLineChart({super.key, required this.series, this.guides = const [], this.startLabel, this.endLabel, this.height = 190});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = Theme.of(context).colorScheme.onSurface;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // الرسم دائمًا من اليسار لليمين (الزمن)
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LinePainter(
              [for (final s in series) ChartSeries(s.points, readable(context, s.color), s.label)],
              [for (final g in guides) ChartGuide(g.y, readable(context, g.color), g.label)],
              fg.withValues(alpha: dark ? .55 : .5),
            ),
          ),
        ),
      ),
      if (startLabel != null || endLabel != null)
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            Expanded(child: Text(startLabel ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
            Expanded(
                child: Text(endLabel ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
          ]),
        ),
      if (series.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(spacing: 14, runSpacing: 4, children: [
            for (final s in series)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 14, height: 4, color: readable(context, s.color)),
                const SizedBox(width: 6),
                Text(s.label, style: const TextStyle(fontSize: 12)),
              ]),
          ]),
        ),
    ]);
  }
}

class _LinePainter extends CustomPainter {
  final List<ChartSeries> series;
  final List<ChartGuide> guides;
  final Color axis;
  _LinePainter(this.series, this.guides, this.axis);

  void _text(Canvas c, String s, Offset at, Color color, {bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(right ? at.dx - tp.width : at.dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final s in series) ...s.points];
    if (pts.isEmpty) return;
    var minY = pts.map((p) => p.dy).reduce(math.min), maxY = pts.map((p) => p.dy).reduce(math.max);
    for (final g in guides) {
      minY = math.min(minY, g.y);
      maxY = math.max(maxY, g.y);
    }
    final padY = (maxY - minY).abs() < 1e-9 ? (maxY.abs() * .1 + 1) : (maxY - minY) * .08;
    minY -= padY;
    maxY += padY;
    final minX = pts.map((p) => p.dx).reduce(math.min), maxX = pts.map((p) => p.dx).reduce(math.max);
    const left = 34.0, right = 8.0, top = 8.0, bottom = 8.0;
    final w = size.width - left - right, h = size.height - top - bottom;
    Offset map(Offset p) {
      final x = maxX == minX ? left + w / 2 : left + w * (p.dx - minX) / (maxX - minX);
      final y = top + h * (1 - (p.dy - minY) / (maxY - minY));
      return Offset(x, y);
    }

    final gridP = Paint()
      ..color = axis.withValues(alpha: .18)
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final y = top + h * k / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridP);
      final v = maxY - (maxY - minY) * k / 4;
      _text(canvas, fmt(v, v.abs() < 10 ? 1 : 0), Offset(left - 4, y), axis, right: true);
    }
    // خطوط مرجعية متقطعة
    for (final g in guides) {
      final y = map(Offset(minX, g.y)).dy;
      final p = Paint()
        ..color = g.color.withValues(alpha: .75)
        ..strokeWidth = 1.3;
      for (var x = left; x < size.width - right; x += 9) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, size.width - right), y), p);
      }
      if (g.label.isNotEmpty) _text(canvas, g.label, Offset(size.width - right - 2, y - 8), g.color, right: true);
    }
    for (final s in series) {
      if (s.points.isEmpty) continue;
      final line = Paint()
        ..color = s.color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < s.points.length; i++) {
        final o = map(s.points[i]);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, line);
      final dot = Paint()..color = s.color;
      for (final p in s.points) {
        canvas.drawCircle(map(p), s.points.length > 20 ? 2.4 : 3.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}

/// اختيار تاريخ ووقت معًا
Future<DateTime?> pickDateTime(BuildContext context, DateTime initial, {DateTime? first}) async {
  final d = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 1)),
    cancelText: t('خلاص', 'إلغاء', 'Cancel'),
    confirmText: t('تمام', 'موافق', 'OK'),
  );
  if (d == null || !context.mounted) return null;
  final tm = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    cancelText: t('خلاص', 'إلغاء', 'Cancel'),
    confirmText: t('تمام', 'موافق', 'OK'),
  );
  return DateTime(d.year, d.month, d.day, tm?.hour ?? initial.hour, tm?.minute ?? initial.minute);
}

/// نص قصير داخل رقاقة ملوّنة (تصنيف)
class TagPill extends StatelessWidget {
  final String text;
  final Color color;
  const TagPill(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = readable(context, color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withValues(alpha: .5))),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c)),
    );
  }
}

/// ورقة سفلية بقائمة نص قابلة للنسخ/المشاركة (تقرير)
Future<void> showReportDialog(BuildContext context, String title, String text, Widget shareBar) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      minChildSize: .4,
      builder: (ctx, sc) => ListView(controller: sc, padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 30), children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SelectableText(text, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
        const SizedBox(height: 12),
        shareBar,
      ]),
    ),
  );
}
